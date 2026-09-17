package service

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/repository"
)

// fakeNotifRepo is an in-memory stand-in enforcing the same uniqueness
// constraint the Mongo unique index provides.
type fakeNotifRepo struct {
	mu      sync.Mutex
	claimed map[string]bool
	logs    map[string]*repository.NotificationLog
	sent    []string
	failed  []string
}

func newFakeRepo() *fakeNotifRepo {
	return &fakeNotifRepo{
		claimed: map[string]bool{},
		logs:    map[string]*repository.NotificationLog{},
	}
}

func (f *fakeNotifRepo) ClaimSend(ctx context.Context, l *repository.NotificationLog) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	key := l.MahalID + "|" + l.DedupeKey
	if f.claimed[key] {
		return repository.ErrNotificationAlreadySent
	}
	f.claimed[key] = true
	f.logs[l.ID] = l
	return nil
}

func (f *fakeNotifRepo) MarkSent(ctx context.Context, id, messageID string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sent = append(f.sent, messageID)
	return nil
}

func (f *fakeNotifRepo) MarkFailed(ctx context.Context, id, reason string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.failed = append(f.failed, reason)
	return nil
}

func (f *fakeNotifRepo) UpdateDeliveryStatus(ctx context.Context, messageID, status string, at time.Time) error {
	return nil
}
func (f *fakeNotifRepo) GetByMessageID(ctx context.Context, messageID string) (*repository.NotificationLog, error) {
	return nil, nil
}
func (f *fakeNotifRepo) ListByMember(ctx context.Context, mahalID, memberID string, limit int64) ([]repository.NotificationLog, error) {
	return nil, nil
}

func (f *fakeNotifRepo) sentCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.sent)
}

func (f *fakeNotifRepo) claimedLog(t *testing.T) *repository.NotificationLog {
	t.Helper()
	f.mu.Lock()
	defer f.mu.Unlock()
	for _, l := range f.logs {
		return l
	}
	t.Fatal("no notification was claimed")
	return nil
}

// countingServer stands in for the Graph API and counts real send attempts.
func countingServer(t *testing.T, hits *int) *httptest.Server {
	t.Helper()
	var mu sync.Mutex
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		*hits++
		mu.Unlock()
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"messaging_product":"whatsapp",
			"contacts":[{"input":"919876543210","wa_id":"919876543210"}],
			"messages":[{"id":"wamid.OK","message_status":"accepted"}]}`))
	}))
}

func testMember() domain.Member {
	return domain.Member{
		ID: "mem_1", Name: "Ahmed", Phone: "9876543210", OutstandingBalance: 500,
	}
}

func TestDuesReminderIsSentOnce(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	day := time.Date(2026, 9, 10, 0, 0, 0, 0, time.UTC)

	// The dunning agent re-scans hourly; simulate a full day of scans.
	for i := 0; i < 24; i++ {
		svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "ഓർമ്മിപ്പിക്കൽ", day)
	}

	if hits != 1 {
		t.Errorf("Graph API called %d times across 24 scans, want exactly 1", hits)
	}
	if repo.sentCount() != 1 {
		t.Errorf("recorded %d sends, want 1", repo.sentCount())
	}
}

func TestDuesReminderSendsAgainNextDay(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	day1 := time.Date(2026, 9, 10, 0, 0, 0, 0, time.UTC)
	day2 := day1.AddDate(0, 0, 1)

	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", day1)
	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", day2)

	if hits != 2 {
		t.Errorf("Graph API called %d times over two days, want 2", hits)
	}
}

func TestConcurrentRemindersStillSendOnce(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	day := time.Date(2026, 9, 10, 0, 0, 0, 0, time.UTC)

	var wg sync.WaitGroup
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", day)
		}()
	}
	wg.Wait()

	if hits != 1 {
		t.Errorf("Graph API called %d times from 20 concurrent handlers, want 1", hits)
	}
}

func TestReceiptDedupedByReceiptNumber(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	receipt := &domain.Receipt{
		ReceiptNumber: "MF-2026-0001", MahalID: "mahal_1", MemberID: "mem_1",
		MemberName: "Ahmed", Amount: 500, PaidMonths: []string{"2026-08"},
	}

	// A gateway webhook retry re-commits the same payment.
	svc.SendReceipt(context.Background(), receipt, "9876543210", "ml")
	svc.SendReceipt(context.Background(), receipt, "9876543210", "ml")

	if hits != 1 {
		t.Errorf("receipt sent %d times, want 1", hits)
	}
}

func TestDisabledServiceNeverSends(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	// No credentials: the whole feature must be inert.
	svc := NewNotificationService(whatsapp.NewClient(whatsapp.Config{}), repo, NotificationTemplates{})

	if svc.Enabled() {
		t.Fatal("service with no credentials must report disabled")
	}

	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", time.Now())
	svc.SendReceipt(context.Background(), &domain.Receipt{ReceiptNumber: "R1", MahalID: "m"}, "9876543210", "ml")

	if hits != 0 {
		t.Errorf("disabled service made %d API calls, want 0", hits)
	}
	if len(repo.claimed) != 0 {
		t.Errorf("disabled service claimed %d dedupe keys, want 0", len(repo.claimed))
	}
}

func TestInvalidPhoneDoesNotConsumeDedupeKey(t *testing.T) {
	hits := 0
	srv := countingServer(t, &hits)
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	bad := testMember()
	bad.Phone = "not-a-number"
	day := time.Date(2026, 9, 10, 0, 0, 0, 0, time.UTC)

	svc.SendDuesReminder(context.Background(), "mahal_1", bad, "ml", "body", day)

	if hits != 0 {
		t.Errorf("invalid phone triggered %d API calls, want 0", hits)
	}
	// The key must stay free so the member is reachable once the number is fixed.
	if len(repo.claimed) != 0 {
		t.Errorf("invalid phone consumed a dedupe key; a corrected number would then be skipped")
	}
}

func TestTemplateUsedWhenConfigured(t *testing.T) {
	var gotType string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var payload map[string]interface{}
		_ = decodeJSON(r, &payload)
		gotType, _ = payload["type"].(string)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"messages":[{"id":"wamid.OK"}]}`))
	}))
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{DuesReminder: "dues_reminder_ml"},
	)

	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", time.Now())

	if gotType != "template" {
		t.Errorf("message type = %q, want template when a template name is configured", gotType)
	}
	if log := repo.claimedLog(t); log.Template != "dues_reminder_ml" {
		t.Errorf("logged template = %q", log.Template)
	}
}

func TestFallsBackToTextWithoutTemplate(t *testing.T) {
	var gotType string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var payload map[string]interface{}
		_ = decodeJSON(r, &payload)
		gotType, _ = payload["type"].(string)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"messages":[{"id":"wamid.OK"}]}`))
	}))
	defer srv.Close()

	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		newFakeRepo(), NotificationTemplates{},
	)

	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", time.Now())

	if gotType != "text" {
		t.Errorf("message type = %q, want text when no template is configured", gotType)
	}
}

func TestSendFailureIsRecordedNotPanicked(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":{"message":"Re-engagement message","code":131047}}`))
	}))
	defer srv.Close()

	repo := newFakeRepo()
	svc := NewNotificationService(
		whatsapp.NewClient(whatsapp.Config{BaseURL: srv.URL, PhoneNumberID: "P", AccessToken: "t"}),
		repo, NotificationTemplates{},
	)

	svc.SendDuesReminder(context.Background(), "mahal_1", testMember(), "ml", "body", time.Now())

	repo.mu.Lock()
	defer repo.mu.Unlock()
	if len(repo.failed) != 1 {
		t.Fatalf("recorded %d failures, want 1", len(repo.failed))
	}
	if repo.sent != nil {
		t.Error("a failed send must not be recorded as sent")
	}
}

func TestTemplateLangCodeMapping(t *testing.T) {
	cases := map[string]string{
		"ml": "ml", "ur": "ur", "ta": "ta",
		"en": "en_US", "": "en_US",
	}
	for in, want := range cases {
		if got := templateLangCode(in); got != want {
			t.Errorf("templateLangCode(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestErrDisabledIsDistinguishable(t *testing.T) {
	c := whatsapp.NewClient(whatsapp.Config{})
	_, err := c.SendText(context.Background(), "9876543210", "x")
	if !errors.Is(err, whatsapp.ErrDisabled) {
		t.Errorf("want ErrDisabled, got %v", err)
	}
}
