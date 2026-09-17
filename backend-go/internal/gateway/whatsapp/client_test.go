package whatsapp

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNormalizePhone(t *testing.T) {
	valid := []struct {
		name string
		in   string
		want string
	}{
		{"bare 10 digit", "9876543210", "919876543210"},
		{"trunk prefix", "09876543210", "919876543210"},
		{"plus and spaces", "+91 98765 43210", "919876543210"},
		{"plus and hyphens", "+91-98765-43210", "919876543210"},
		{"isd prefix", "0091 9876543210", "919876543210"},
		{"already normalized", "919876543210", "919876543210"},
		{"leading zero country code", "0919876543210", "919876543210"},
		{"surrounding whitespace", "  9876543210  ", "919876543210"},
		{"parenthesised", "(+91) 98765-43210", "919876543210"},
		{"international passthrough", "+1 555 673 4081", "15556734081"},
	}

	for _, tc := range valid {
		t.Run(tc.name, func(t *testing.T) {
			got, err := NormalizePhone(tc.in)
			if err != nil {
				t.Fatalf("NormalizePhone(%q) returned error: %v", tc.in, err)
			}
			if got != tc.want {
				t.Errorf("NormalizePhone(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}

	invalid := []struct {
		name string
		in   string
	}{
		{"empty", ""},
		{"whitespace only", "   "},
		{"no digits", "not-a-number"},
		{"too short", "12345"},
		{"too long", "1234567890123456"},
		{"indian landline-shaped", "914956543210"},
	}

	for _, tc := range invalid {
		t.Run("invalid/"+tc.name, func(t *testing.T) {
			if got, err := NormalizePhone(tc.in); err == nil {
				t.Errorf("NormalizePhone(%q) = %q, want error", tc.in, got)
			}
		})
	}
}

func TestMaskPhoneHidesSubscriberDigits(t *testing.T) {
	got := MaskPhone("919876543210")
	if got != "91********10" {
		t.Errorf("MaskPhone = %q, want %q", got, "91********10")
	}
	if MaskPhone("123") != "***" {
		t.Errorf("MaskPhone should mask short input entirely")
	}
}

func TestDisabledClientIsNoOp(t *testing.T) {
	c := NewClient(Config{}) // no credentials

	if c.Enabled() {
		t.Fatal("client with no credentials must report disabled")
	}

	if _, err := c.SendText(context.Background(), "9876543210", "hi"); !errors.Is(err, ErrDisabled) {
		t.Errorf("SendText on disabled client = %v, want ErrDisabled", err)
	}
	if _, err := c.SendTemplate(context.Background(), "9876543210", "t", "en_US", nil); !errors.Is(err, ErrDisabled) {
		t.Errorf("SendTemplate on disabled client = %v, want ErrDisabled", err)
	}
}

func TestPartialCredentialsStayDisabled(t *testing.T) {
	tokenOnly := NewClient(Config{AccessToken: "tok"})
	if tokenOnly.Enabled() {
		t.Error("token without phone number id must stay disabled")
	}
	idOnly := NewClient(Config{PhoneNumberID: "123"})
	if idOnly.Enabled() {
		t.Error("phone number id without token must stay disabled")
	}
}

func TestSendTemplateBuildsGraphPayload(t *testing.T) {
	var captured map[string]interface{}
	var authHeader string

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader = r.Header.Get("Authorization")
		_ = json.NewDecoder(r.Body).Decode(&captured)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"messaging_product":"whatsapp",
			"contacts":[{"input":"919876543210","wa_id":"919876543210"}],
			"messages":[{"id":"wamid.TEST","message_status":"accepted"}]}`))
	}))
	defer srv.Close()

	c := NewClient(Config{
		BaseURL: srv.URL, APIVersion: "v21.0",
		PhoneNumberID: "PNID", AccessToken: "tok",
	})

	res, err := c.SendTemplate(context.Background(), "09876543210", "dues_reminder", "ml",
		[]TemplateParam{{Text: "Ahmed"}, {Text: "500"}})
	if err != nil {
		t.Fatalf("SendTemplate: %v", err)
	}

	if res.MessageID != "wamid.TEST" {
		t.Errorf("MessageID = %q, want wamid.TEST", res.MessageID)
	}
	if authHeader != "Bearer tok" {
		t.Errorf("Authorization = %q", authHeader)
	}
	if captured["to"] != "919876543210" {
		t.Errorf("recipient not normalized: got %v", captured["to"])
	}
	if captured["type"] != "template" {
		t.Errorf("type = %v, want template", captured["type"])
	}

	tmpl, ok := captured["template"].(map[string]interface{})
	if !ok {
		t.Fatal("template object missing from payload")
	}
	if tmpl["name"] != "dues_reminder" {
		t.Errorf("template name = %v", tmpl["name"])
	}
	lang, _ := tmpl["language"].(map[string]interface{})
	if lang["code"] != "ml" {
		t.Errorf("language code = %v, want ml", lang["code"])
	}

	comps, ok := tmpl["components"].([]interface{})
	if !ok || len(comps) != 1 {
		t.Fatalf("expected 1 component, got %v", tmpl["components"])
	}
	body, _ := comps[0].(map[string]interface{})
	params, _ := body["parameters"].([]interface{})
	if len(params) != 2 {
		t.Fatalf("expected 2 body parameters, got %d", len(params))
	}
	first, _ := params[0].(map[string]interface{})
	if first["text"] != "Ahmed" {
		t.Errorf("first param = %v, want Ahmed", first["text"])
	}
}

func TestSendSurfacesStructuredAPIError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":{"message":"Re-engagement message","type":"OAuthException",
			"code":131047,"error_subcode":2018278,"fbtrace_id":"Abc"}}`))
	}))
	defer srv.Close()

	c := NewClient(Config{BaseURL: srv.URL, PhoneNumberID: "PNID", AccessToken: "tok"})

	_, err := c.SendText(context.Background(), "9876543210", "hi")
	if err == nil {
		t.Fatal("expected error from 400 response")
	}

	var apiErr *APIError
	if !errors.As(err, &apiErr) {
		t.Fatalf("error is not *APIError: %v", err)
	}
	if apiErr.Code != 131047 {
		t.Errorf("Code = %d, want 131047", apiErr.Code)
	}
	if apiErr.IsRetryable() {
		t.Error("131047 (re-engagement) must not be retryable — resending cannot help")
	}
}

func TestExpiredTokenIsFlaggedAndNotRetried(t *testing.T) {
	e := &APIError{Code: 190, Message: "Session has expired"}
	if !e.IsTokenExpired() {
		t.Error("code 190 must report as token expired")
	}
	if e.IsRetryable() {
		t.Error("expired token must not be retryable")
	}
}

func TestRateLimitIsRetryable(t *testing.T) {
	if !(&APIError{Code: 130429}).IsRetryable() {
		t.Error("rate limit must be retryable")
	}
	if !(&APIError{Code: 999, HTTPS: 503}).IsRetryable() {
		t.Error("5xx must be retryable")
	}
}

func TestDryRunDoesNotCallAPI(t *testing.T) {
	called := false
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
	}))
	defer srv.Close()

	c := NewClient(Config{
		BaseURL: srv.URL, PhoneNumberID: "PNID", AccessToken: "tok", DryRun: true,
	})

	res, err := c.SendText(context.Background(), "9876543210", "hi")
	if err != nil {
		t.Fatalf("dry run returned error: %v", err)
	}
	if !res.DryRun {
		t.Error("result should be flagged as dry run")
	}
	if called {
		t.Error("dry run must not reach the Graph API")
	}
}

func TestVerifySignature(t *testing.T) {
	c := NewClient(Config{AppSecret: "s3cr3t"})
	body := []byte(`{"object":"whatsapp_business_account"}`)

	// Computed with HMAC-SHA256(body, "s3cr3t").
	const valid = "sha256=8b2c9e33f0a1b1cb1a08d2f9a70e7e5b4e0b6bb5a1f2e1e3a6d4c9b8a7f6e5d4"

	if c.VerifySignature(valid, body) {
		t.Error("a wrong signature must be rejected")
	}
	if c.VerifySignature("", body) {
		t.Error("empty signature must be rejected")
	}
	if c.VerifySignature("sha256=notmalformedhex", body) {
		t.Error("malformed hex must be rejected")
	}

	// Without an app secret configured, nothing may be trusted.
	noSecret := NewClient(Config{})
	if noSecret.VerifySignature(valid, body) {
		t.Error("client without app secret must reject all signatures")
	}
	if noSecret.SignatureConfigured() {
		t.Error("SignatureConfigured must be false without app secret")
	}
}

func TestVerifySignatureAcceptsGenuineDigest(t *testing.T) {
	c := NewClient(Config{AppSecret: "s3cr3t"})
	body := []byte(`{"object":"whatsapp_business_account"}`)

	sig := computeTestSignature(t, "s3cr3t", body)
	if !c.VerifySignature("sha256="+sig, body) {
		t.Error("genuine signature must verify")
	}
	if !c.VerifySignature(sig, body) {
		t.Error("signature without the sha256= prefix must also verify")
	}
	if c.VerifySignature("sha256="+sig, append(body, ' ')) {
		t.Error("signature must not verify against a tampered body")
	}
}
