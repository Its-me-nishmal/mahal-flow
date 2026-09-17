package api

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/repository"
)

type recordingNotifRepo struct {
	statuses []string
	ids      []string
}

func (r *recordingNotifRepo) ClaimSend(ctx contextT, l *repository.NotificationLog) error { return nil }
func (r *recordingNotifRepo) MarkSent(ctx contextT, id, messageID string) error           { return nil }
func (r *recordingNotifRepo) MarkFailed(ctx contextT, id, reason string) error            { return nil }
func (r *recordingNotifRepo) UpdateDeliveryStatus(ctx contextT, messageID, status string, at time.Time) error {
	r.ids = append(r.ids, messageID)
	r.statuses = append(r.statuses, status)
	return nil
}
func (r *recordingNotifRepo) GetByMessageID(ctx contextT, messageID string) (*repository.NotificationLog, error) {
	return nil, nil
}
func (r *recordingNotifRepo) ListByMember(ctx contextT, mahalID, memberID string, limit int64) ([]repository.NotificationLog, error) {
	return nil, nil
}

func sign(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return "sha256=" + hex.EncodeToString(mac.Sum(nil))
}

func newTestApp(secret, verifyToken string, repo repository.NotificationRepository) *fiber.App {
	wa := whatsapp.NewClient(whatsapp.Config{AppSecret: secret})
	h := NewWhatsAppHandler(wa, repo, verifyToken)

	app := fiber.New()
	app.Get("/webhook", h.VerifyWebhook)
	app.Post("/webhook", h.HandleWebhook)
	return app
}

func TestWebhookHandshakeEchoesChallenge(t *testing.T) {
	app := newTestApp("secret", "my-verify-token", nil)

	req := httptest.NewRequest("GET",
		"/webhook?hub.mode=subscribe&hub.verify_token=my-verify-token&hub.challenge=1158201444", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("status = %d, want 200", resp.StatusCode)
	}
	body, _ := io.ReadAll(resp.Body)
	if string(body) != "1158201444" {
		t.Errorf("body = %q, want the challenge echoed verbatim", string(body))
	}
}

func TestWebhookHandshakeRejectsWrongToken(t *testing.T) {
	app := newTestApp("secret", "my-verify-token", nil)

	req := httptest.NewRequest("GET",
		"/webhook?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=123", nil)
	resp, _ := app.Test(req)
	if resp.StatusCode != 403 {
		t.Errorf("status = %d, want 403 for a wrong verify token", resp.StatusCode)
	}
}

func TestWebhookHandshakeRejectedWhenTokenUnset(t *testing.T) {
	app := newTestApp("secret", "", nil)

	req := httptest.NewRequest("GET",
		"/webhook?hub.mode=subscribe&hub.verify_token=&hub.challenge=123", nil)
	resp, _ := app.Test(req)
	if resp.StatusCode != 403 {
		t.Errorf("status = %d, want 403 when no verify token is configured", resp.StatusCode)
	}
}

const statusPayload = `{"object":"whatsapp_business_account","entry":[{"id":"WABA",
"changes":[{"field":"messages","value":{"messaging_product":"whatsapp",
"statuses":[{"id":"wamid.ABC","status":"delivered","timestamp":"1789000000","recipient_id":"919876543210"}]}}]}]}`

func TestWebhookRecordsDeliveryStatus(t *testing.T) {
	repo := &recordingNotifRepo{}
	app := newTestApp("s3cr3t", "vt", repo)

	body := []byte(statusPayload)
	req := httptest.NewRequest("POST", "/webhook", strings.NewReader(string(body)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Hub-Signature-256", sign("s3cr3t", body))

	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("status = %d, want 200", resp.StatusCode)
	}
	if len(repo.statuses) != 1 || repo.statuses[0] != "delivered" {
		t.Errorf("recorded statuses = %v, want [delivered]", repo.statuses)
	}
	if len(repo.ids) != 1 || repo.ids[0] != "wamid.ABC" {
		t.Errorf("recorded ids = %v, want [wamid.ABC]", repo.ids)
	}
}

func TestWebhookRejectsBadSignature(t *testing.T) {
	repo := &recordingNotifRepo{}
	app := newTestApp("s3cr3t", "vt", repo)

	body := []byte(statusPayload)
	req := httptest.NewRequest("POST", "/webhook", strings.NewReader(string(body)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Hub-Signature-256", sign("wrong-secret", body))

	resp, _ := app.Test(req)
	if resp.StatusCode != 403 {
		t.Errorf("status = %d, want 403 for a forged signature", resp.StatusCode)
	}
	if len(repo.statuses) != 0 {
		t.Error("a forged webhook must not mutate the notification log")
	}
}

func TestWebhookRejectsWhenAppSecretUnset(t *testing.T) {
	repo := &recordingNotifRepo{}
	app := newTestApp("", "vt", repo)

	body := []byte(statusPayload)
	req := httptest.NewRequest("POST", "/webhook", strings.NewReader(string(body)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Hub-Signature-256", sign("anything", body))

	resp, _ := app.Test(req)
	if resp.StatusCode != 403 {
		t.Errorf("status = %d, want 403 when the app secret is unset", resp.StatusCode)
	}
}

func TestWebhookReturns200OnUnparseableBody(t *testing.T) {
	// Meta retries non-200 responses with backoff; a malformed event must not
	// trigger indefinite redelivery of the whole batch.
	app := newTestApp("s3cr3t", "vt", &recordingNotifRepo{})

	body := []byte(`{"object": not json`)
	req := httptest.NewRequest("POST", "/webhook", strings.NewReader(string(body)))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Hub-Signature-256", sign("s3cr3t", body))

	resp, _ := app.Test(req)
	if resp.StatusCode != 200 {
		t.Errorf("status = %d, want 200 so Meta stops retrying", resp.StatusCode)
	}
}
