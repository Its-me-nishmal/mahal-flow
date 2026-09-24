package fcm

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

func testClient(t *testing.T, handler http.HandlerFunc) *Client {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	der, _ := x509.MarshalPKCS8PrivateKey(key)
	pemKey := string(pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: der}))

	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)

	sa, _ := json.Marshal(map[string]string{
		"project_id":   "demo",
		"client_email": "push@demo.iam.gserviceaccount.com",
		"private_key":  pemKey,
		"token_uri":    srv.URL + "/token",
	})
	c, err := NewClient(Config{ServiceAccountJSON: string(sa)})
	if err != nil {
		t.Fatal(err)
	}
	c.apiURL = srv.URL
	return c
}

func TestDisabledWithoutServiceAccount(t *testing.T) {
	c, err := NewClient(Config{})
	if err != nil || c.Enabled() {
		t.Fatalf("want disabled client, got enabled=%v err=%v", c.Enabled(), err)
	}
	if _, err := c.Send(context.Background(), Message{Token: "x"}); !errors.Is(err, ErrDisabled) {
		t.Fatalf("want ErrDisabled, got %v", err)
	}
}

func TestSendExchangesTokenOnceAndSends(t *testing.T) {
	var tokenCalls, sendCalls atomic.Int32
	c := testClient(t, func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.URL.Path == "/token":
			tokenCalls.Add(1)
			_ = r.ParseForm()
			if parts := strings.Split(r.Form.Get("assertion"), "."); len(parts) != 3 {
				t.Errorf("assertion is not a JWT: %q", r.Form.Get("assertion"))
			}
			_, _ = io.WriteString(w, `{"access_token":"at","expires_in":3600}`)
		case r.URL.Path == "/v1/projects/demo/messages:send":
			sendCalls.Add(1)
			if r.Header.Get("Authorization") != "Bearer at" {
				t.Errorf("missing bearer token")
			}
			var body struct {
				Message struct {
					Token string            `json:"token"`
					Data  map[string]string `json:"data"`
				} `json:"message"`
			}
			_ = json.NewDecoder(r.Body).Decode(&body)
			if body.Message.Token != "dev1" || body.Message.Data["type"] != "ALERT" {
				t.Errorf("unexpected payload: %+v", body)
			}
			_, _ = io.WriteString(w, `{"name":"projects/demo/messages/1"}`)
		default:
			http.NotFound(w, r)
		}
	})

	for i := 0; i < 2; i++ {
		name, err := c.Send(context.Background(), Message{Token: "dev1", Title: "t", Body: "b", Data: map[string]string{"type": "ALERT"}})
		if err != nil || name != "projects/demo/messages/1" {
			t.Fatalf("send %d: name=%q err=%v", i, name, err)
		}
	}
	if tokenCalls.Load() != 1 || sendCalls.Load() != 2 {
		t.Fatalf("token calls=%d send calls=%d, want 1 and 2", tokenCalls.Load(), sendCalls.Load())
	}
}

func TestSendMapsUnregistered(t *testing.T) {
	c := testClient(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/token" {
			_, _ = io.WriteString(w, `{"access_token":"at","expires_in":3600}`)
			return
		}
		w.WriteHeader(http.StatusNotFound)
		_, _ = io.WriteString(w, `{"error":{"status":"NOT_FOUND","message":"Requested entity was not found.","details":[{"errorCode":"UNREGISTERED"}]}}`)
	})
	if _, err := c.Send(context.Background(), Message{Token: "gone"}); !errors.Is(err, ErrUnregistered) {
		t.Fatalf("want ErrUnregistered, got %v", err)
	}
}
