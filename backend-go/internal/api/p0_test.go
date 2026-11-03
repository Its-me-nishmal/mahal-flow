package api

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/pg"
	"github.com/mahalflow/backend-go/internal/service"
	"go.mongodb.org/mongo-driver/v2/bson"
)

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

type fakePayments struct {
	txns      *fakeTxns
	commits   []string
	entries   []float64
	commitErr error
	entryErr  error
	duesInit  [][]string // months per InitializeDuesPayment call
	contribs  int
	seq       int
}

func (p *fakePayments) next() string { p.seq++; return fmt.Sprintf("TXNFAKE%03d", p.seq) }

func (p *fakePayments) InitializeDuesPayment(_ context.Context, mahalID, memberID string, months []string, gateway, key string) (*domain.Transaction, error) {
	p.duesInit = append(p.duesInit, months)
	t := domain.Transaction{ID: p.next(), MahalID: mahalID, MemberID: memberID, IdempotencyKey: key, Type: "MONTHLY_DUES",
		Amount: 500 * float64(len(months)), Currency: "INR", SelectedMonths: months, Gateway: gateway, Status: domain.TxnPending, CreatedAt: time.Now()}
	p.txns.rows[t.ID] = t
	return &t, nil
}
func (p *fakePayments) InitializeContribution(_ context.Context, mahalID, memberID string, amount float64, gateway, key string, d service.ContributionDetails) (*domain.Transaction, error) {
	p.contribs++
	t := domain.Transaction{ID: p.next(), MahalID: mahalID, MemberID: memberID, IdempotencyKey: key, Type: "CONTRIBUTION",
		Amount: amount, Currency: "INR", Gateway: gateway, Purpose: d.Purpose, Status: domain.TxnPending, CreatedAt: time.Now()}
	p.txns.rows[t.ID] = t
	return &t, nil
}
func (p *fakePayments) CommitSuccessfulPayment(_ context.Context, id string) (*domain.Receipt, error) {
	if p.commitErr != nil {
		return nil, p.commitErr
	}
	p.commits = append(p.commits, id)
	t := p.txns.rows[id]
	t.Status, t.ReceiptID = domain.TxnSuccess, "R-"+id
	p.txns.rows[id] = t
	return &domain.Receipt{ReceiptNumber: "R-" + id, MahalID: t.MahalID, MemberID: t.MemberID, Amount: t.Amount, PaidMonths: t.SelectedMonths}, nil
}
func (p *fakePayments) AppendRefundEntry(_ context.Context, txn *domain.Transaction, amount float64, ref string) (*domain.Receipt, error) {
	if p.entryErr != nil {
		return nil, p.entryErr
	}
	p.entries = append(p.entries, amount)
	return &domain.Receipt{ReceiptNumber: fmt.Sprintf("REFUND-%d", len(p.entries)), Amount: -amount}, nil
}
func (p *fakePayments) SetAllowStandaloneCommit(bool)                {}
func (p *fakePayments) SetReceiptIssuedHook(func(r *domain.Receipt)) {}

type fakeAudit struct {
	mu   sync.Mutex
	rows []domain.AuditLog
}

func (a *fakeAudit) Create(_ context.Context, l *domain.AuditLog) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.rows = append(a.rows, *l)
	return nil
}
func (a *fakeAudit) List(context.Context, string, int64, int64) ([]domain.AuditLog, int64, error) {
	return a.rows, int64(len(a.rows)), nil
}
func (a *fakeAudit) find(action string) *domain.AuditLog {
	a.mu.Lock()
	defer a.mu.Unlock()
	for i := range a.rows {
		if a.rows[i].Action == action {
			return &a.rows[i]
		}
	}
	return nil
}

// memMandates models every mandate field the scheduler touches.
type memMandates struct {
	mu   sync.Mutex
	rows map[string]domain.Mandate
	due  []string
}

func (m *memMandates) Create(_ context.Context, x *domain.Mandate) error {
	m.rows[x.ID] = *x
	return nil
}
func (m *memMandates) GetByID(_ context.Context, id string) (*domain.Mandate, error) {
	x, ok := m.rows[id]
	if !ok {
		return nil, nil
	}
	return &x, nil
}
func (m *memMandates) GetActiveByMember(_ context.Context, mahalID, memberID string) (*domain.Mandate, error) {
	for _, x := range m.rows {
		if x.MahalID == mahalID && x.MemberID == memberID && (x.Status == "ACTIVE" || x.Status == "PENDING_AUTHORIZATION") {
			y := x
			return &y, nil
		}
	}
	return nil, nil
}
func (m *memMandates) FindDue(context.Context, time.Time) ([]domain.Mandate, error) {
	var out []domain.Mandate
	for _, id := range m.due {
		out = append(out, m.rows[id])
	}
	return out, nil
}
func (m *memMandates) Update(_ context.Context, id string, f bson.M) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	x := m.rows[id]
	for k, v := range f {
		switch k {
		case "status":
			x.Status = v.(string)
		case "gateway_cancel_status":
			x.GatewayCancelStatus = v.(string)
		case "auth_payu_id":
			x.AuthPayUID = v.(string)
		case "failure_count":
			x.FailureCount = v.(int)
		case "next_debit":
			x.NextDebit = nil
			if t, ok := v.(time.Time); ok {
				x.NextDebit = &t
			}
		case "next_retry_at":
			x.NextRetryAt = nil
			if t, ok := v.(time.Time); ok {
				x.NextRetryAt = &t
			}
		case "pre_debit_sent_at":
			x.PreDebitSentAt = nil
			if t, ok := v.(time.Time); ok {
				x.PreDebitSentAt = &t
			}
		case "last_debit_at":
			t := v.(time.Time)
			x.LastDebitAt = &t
		}
	}
	m.rows[id] = x
	return nil
}

type fakeLease struct {
	allow    bool
	err      error
	acquired int
	released int
}

func (l *fakeLease) Acquire(context.Context, string, string, time.Duration) (bool, error) {
	l.acquired++
	return l.allow, l.err
}
func (l *fakeLease) Release(context.Context, string, string) error { l.released++; return nil }

// payuStub is a fake PayU postservice endpoint that counts commands.
type payuStub struct {
	mu       sync.Mutex
	calls    map[string]int
	forms    map[string]url.Values
	siOK     bool
	verify   map[string]string // txnid -> status ("" = not found)
	revokeOK bool
	refundOK bool
	srv      *httptest.Server
}

func newPayuStub() *payuStub {
	p := &payuStub{calls: map[string]int{}, forms: map[string]url.Values{}, siOK: true, revokeOK: true, refundOK: true, verify: map[string]string{}}
	p.srv = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseForm()
		cmd := r.Form.Get("command")
		p.mu.Lock()
		p.calls[cmd]++
		p.forms[cmd] = r.Form
		p.mu.Unlock()
		ok := func(b bool) string {
			if b {
				return "1"
			}
			return "0"
		}
		switch cmd {
		case "si_transaction":
			fmt.Fprintf(w, `{"status":"%s","mihpayid":"MIH1","msg":"x"}`, ok(p.siOK))
		case "upi_mandate_revoke":
			fmt.Fprintf(w, `{"status":"%s","msg":"x"}`, ok(p.revokeOK))
		case "cancel_refund_transaction":
			fmt.Fprintf(w, `{"status":"%s","msg":"x","request_id":"RQ1"}`, ok(p.refundOK))
		case "verify_payment":
			id := r.Form.Get("var1")
			st, found := p.verify[id]
			if !found || st == "" {
				fmt.Fprint(w, `{"status":1,"transaction_details":{}}`)
				return
			}
			fmt.Fprintf(w, `{"status":1,"transaction_details":{%q:{"mihpayid":"MIHV","status":%q,"mode":"UPI","amt":"1000.00"}}}`, id, st)
		default:
			fmt.Fprint(w, `{"status":"1"}`)
		}
	}))
	return p
}
func (p *payuStub) client() *pg.Client {
	return pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, InfoBaseURL: p.srv.URL, Timeout: 3 * time.Second})
}
func (p *payuStub) count(cmd string) int { p.mu.Lock(); defer p.mu.Unlock(); return p.calls[cmd] }

type p0Fixture struct {
	*fixture
	pay   *fakePayments
	audit *fakeAudit
	adm   string
	mem   string
}

func newP0(t *testing.T) *p0Fixture {
	t.Helper()
	f := gapFixture(t)
	p := &p0Fixture{fixture: f, pay: &fakePayments{txns: f.txns}, audit: &fakeAudit{}}
	f.h.paymentService = p.pay
	f.h.auditRepo = p.audit
	f.h.pgClient = pg.NewClient(pg.Config{}) // unconfigured, NOT simulated
	p.adm = token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	p.mem = token(t, "MEM_1", domain.RoleMember, tenantA)
	return p
}

// ---------------------------------------------------------------------------
// 1. Fail-open test mode
// ---------------------------------------------------------------------------

func TestConfirmNeverCommitsWithoutAGatewayThatCanProveIt(t *testing.T) {
	for name, client := range map[string]*pg.Client{
		"nil gateway":          nil,
		"unconfigured gateway": pg.NewClient(pg.Config{}),
	} {
		f := newP0(t)
		f.h.pgClient = client
		r := f.do(t, "POST", "/api/v1/payments/dues/confirm", tenantA, f.mem, map[string]string{"transaction_id": "TXN_1"})
		if r.status != 409 || len(f.pay.commits) != 0 {
			t.Fatalf("%s: want 409 and no commit, got %d %v commits=%v", name, r.status, r.body, f.pay.commits)
		}
		if f.txns.rows["TXN_1"].Status != domain.TxnPending {
			t.Fatalf("%s: transaction must stay PENDING", name)
		}
	}
	// Explicit simulation (TestMode) still works for development.
	f := newP0(t)
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	if r := f.do(t, "POST", "/api/v1/payments/dues/confirm", tenantA, f.mem, map[string]string{"transaction_id": "TXN_1"}); r.status != 200 || len(f.pay.commits) != 1 {
		t.Fatalf("simulated gateway: %d %v", r.status, r.body)
	}
}

func TestStatusEndpointNeverCommitsWithoutLiveOrSimulatedGateway(t *testing.T) {
	f := newP0(t)
	r := f.do(t, "GET", "/api/v1/payments/TXN_1/status", tenantA, f.mem, nil)
	if r.status != 503 || len(f.pay.commits) != 0 {
		t.Fatalf("want 503 and no commit, got %d %v", r.status, r.body)
	}
}

func TestContributionOnlyAutoCommitsForCashOrSimulation(t *testing.T) {
	// The old code read PAYMENT_TEST_MODE directly and treated "unset" as ON.
	t.Setenv("PAYMENT_TEST_MODE", "")
	f := newP0(t)
	body := map[string]any{"member_id": "MEM_1", "amount": 100, "gateway": "PAYU", "idempotency_key": "k1"}
	r := f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.mem, body)
	if r.status != 201 || r.body["status"] != "PENDING" || len(f.pay.commits) != 0 {
		t.Fatalf("online contribution must wait for the gateway: %d %v commits=%v", r.status, r.body, f.pay.commits)
	}
	t.Setenv("PAYMENT_TEST_MODE", "ON") // env alone must not matter any more
	r = f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.mem, body)
	if len(f.pay.commits) != 0 {
		t.Fatalf("PAYMENT_TEST_MODE env must not commit by itself: %v", r.body)
	}
	// Member cannot self-record cash; the committee can.
	cash := map[string]any{"member_id": "MEM_1", "amount": 100, "gateway": "CASH", "idempotency_key": "k2"}
	if r := f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.mem, cash); r.status != 403 {
		t.Fatalf("member cash: %d", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.adm, cash); r.status != 201 || r.body["status"] != "SUCCESS" || len(f.pay.commits) != 1 {
		t.Fatalf("admin cash: %d %v", r.status, r.body)
	}
	// Simulated gateway commits.
	f.h.pgClient = pg.NewClient(pg.Config{TestMode: true})
	body["idempotency_key"] = "k3"
	if r := f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.mem, body); r.body["status"] != "SUCCESS" || len(f.pay.commits) != 2 {
		t.Fatalf("simulated: %v", r.body)
	}
}

func TestCashCommitErrorsAreNotSwallowed(t *testing.T) {
	f := newP0(t)
	f.pay.commitErr = errors.New("ledger down")
	r := f.do(t, "POST", "/api/v1/payments/dues/initialize", tenantA, f.adm,
		map[string]any{"member_id": "MEM_1", "selected_months": []string{"2026-09"}, "gateway": "CASH", "idempotency_key": "c1"})
	if r.status != 500 || r.body["status"] == "SUCCESS" {
		t.Fatalf("cash dues commit failure: want 500, got %d %v", r.status, r.body)
	}
	r = f.do(t, "POST", "/api/v1/payments/contribution/initialize", tenantA, f.adm,
		map[string]any{"member_id": "MEM_1", "amount": 10, "gateway": "CASH", "idempotency_key": "c2"})
	if r.status != 500 {
		t.Fatalf("cash contribution commit failure: want 500, got %d %v", r.status, r.body)
	}
}

// ---------------------------------------------------------------------------
// 3. Receipt verify endpoint uses the stored hash version
// ---------------------------------------------------------------------------

func TestVerifyEndpointDetectsTamperedAmountOnV2(t *testing.T) {
	f := newP0(t)
	r := domain.Receipt{ReceiptNumber: "RCPT-V2", SequenceNumber: 7, MahalID: tenantA, MemberID: "MEM_1", TransactionID: "TXN_1",
		PaymentType: "MONTHLY_DUES", PaidMonths: []string{"2026-09"}, Amount: 500, Currency: "INR",
		PreviousReceiptHash: strings.Repeat("0", 64), CreatedAt: time.Now().UTC().Truncate(time.Millisecond), HashVersion: domain.ReceiptHashV2}
	r.ReceiptHash = r.ComputeHash()
	f.receipts.rows = append(f.receipts.rows, r)
	if res := f.do(t, "GET", "/api/v1/receipts/RCPT-V2/verify", tenantA, f.mem, nil); res.body["cryptographic_valid"] != true || res.body["hash_version"] != float64(2) {
		t.Fatalf("intact v2 receipt: %v", res.body)
	}
	f.receipts.rows[len(f.receipts.rows)-1].Amount = 5
	if res := f.do(t, "GET", "/api/v1/receipts/RCPT-V2/verify", tenantA, f.mem, nil); res.body["cryptographic_valid"] != false {
		t.Fatalf("tampered amount must fail verification: %v", res.body)
	}
}

// ---------------------------------------------------------------------------
// 4. Refunds
// ---------------------------------------------------------------------------

func seedPaidTxn(f *p0Fixture, id, typ string) {
	t := domain.Transaction{ID: id, MahalID: tenantA, MemberID: "MEM_1", Type: typ, Amount: 500, Currency: "INR",
		Gateway: "PAYU", GatewayPaymentID: "MIH_" + id, Status: domain.TxnSuccess, ReceiptID: "R-" + id, CreatedAt: time.Now()}
	if typ == "MONTHLY_DUES" {
		t.SelectedMonths = []string{"2026-09"}
	}
	f.txns.rows[id] = t
}

func refund(f *p0Fixture, t *testing.T, id string, body map[string]any) resp {
	body["action"] = "APPROVE"
	return f.do(t, "POST", "/api/v1/admin/refunds/"+id+"/action", tenantA, f.adm, body)
}

func TestRefundStateMachineAndPartialTracking(t *testing.T) {
	f := newP0(t)
	stub := newPayuStub()
	defer stub.srv.Close()
	f.h.pgClient = stub.client()
	fakeReversals = nil
	seedPaidTxn(f, "TXN_R", "MONTHLY_DUES")
	m := f.members.rows["MEM_1"]
	m.LastPaidMonth, m.OutstandingBalance = "2026-09", 0
	f.members.rows["MEM_1"] = m

	// Amount is required: no silent 500 default.
	if r := refund(f, t, "TXN_R", map[string]any{}); r.status != 400 || stub.count("cancel_refund_transaction") != 0 {
		t.Fatalf("missing amount: %d %v", r.status, r.body)
	}
	// Over the cap.
	if r := refund(f, t, "TXN_R", map[string]any{"amount": 500.01}); r.status != 422 || stub.count("cancel_refund_transaction") != 0 {
		t.Fatalf("over cap: %d %v", r.status, r.body)
	}
	// Partial refund.
	r := refund(f, t, "TXN_R", map[string]any{"amount": 200, "reason": "partial"})
	if r.status != 200 || r.body["transaction_status"] != "PARTIALLY_REFUNDED" || r.body["refunded_amount"] != float64(200) || r.body["remaining"] != float64(300) {
		t.Fatalf("partial: %d %v", r.status, r.body)
	}
	tx := f.txns.rows["TXN_R"]
	if tx.Status != domain.TxnPartiallyRefunded || tx.RefundedAmount != 200 {
		t.Fatalf("txn after partial: %+v", tx)
	}
	// Dues restored by the refunded amount; months not rolled back on a partial refund.
	if got := f.members.rows["MEM_1"]; got.OutstandingBalance != 200 || got.LastPaidMonth != "2026-09" {
		t.Fatalf("member after partial: %+v", got)
	}
	// Offsetting ledger entry appended.
	if len(f.pay.entries) != 1 || f.pay.entries[0] != 200 {
		t.Fatalf("ledger entries: %v", f.pay.entries)
	}
	// Second partial beyond the remainder is refused, exact remainder succeeds.
	if r := refund(f, t, "TXN_R", map[string]any{"amount": 300.01}); r.status != 422 {
		t.Fatalf("beyond remaining: %d", r.status)
	}
	r = refund(f, t, "TXN_R", map[string]any{"amount": 300})
	if r.status != 200 || r.body["transaction_status"] != "REFUNDED" {
		t.Fatalf("final refund: %d %v", r.status, r.body)
	}
	if got := f.members.rows["MEM_1"]; got.OutstandingBalance != 500 || got.LastPaidMonth != "2026-08" {
		t.Fatalf("member after full refund must be rolled back: %+v", got)
	}
	// Already refunded: state machine rejects, gateway untouched.
	before := stub.count("cancel_refund_transaction")
	if r := refund(f, t, "TXN_R", map[string]any{"amount": 1}); r.status != 409 || stub.count("cancel_refund_transaction") != before {
		t.Fatalf("refund of REFUNDED: %d %v", r.status, r.body)
	}
	// Distinct merchant refund tokens per step (so PayU does not dedupe step 2 away).
	if before != 2 {
		t.Fatalf("gateway refund calls: %d", before)
	}
}

func TestRefundRejectsNonSuccessAndCrossTenant(t *testing.T) {
	f := newP0(t)
	if r := refund(f, t, "TXN_1", map[string]any{"amount": 10}); r.status != 409 { // PENDING
		t.Fatalf("PENDING refund: %d %v", r.status, r.body)
	}
	if r := refund(f, t, "TXN_B", map[string]any{"amount": 10}); r.status != 404 {
		t.Fatalf("other tenant: %d", r.status)
	}
	if r := refund(f, t, "REF_B", map[string]any{"amount": 10}); r.status != 404 {
		t.Fatalf("other tenant's request: %d", r.status)
	}
}

func TestRefundGatewayFailureReleasesReservation(t *testing.T) {
	f := newP0(t)
	stub := newPayuStub()
	stub.refundOK = false
	defer stub.srv.Close()
	f.h.pgClient = stub.client()
	seedPaidTxn(f, "TXN_G", "CONTRIBUTION")
	if r := refund(f, t, "TXN_G", map[string]any{"amount": 100}); r.status != 502 {
		t.Fatalf("gateway failure: %d %v", r.status, r.body)
	}
	if tx := f.txns.rows["TXN_G"]; tx.Status != domain.TxnSuccess || tx.RefundedAmount != 0 {
		t.Fatalf("reservation must be released: %+v", tx)
	}
	if len(f.pay.entries) != 0 {
		t.Fatal("no ledger entry for a failed refund")
	}
}

func TestRefundPostGatewayFailuresAreCriticalAuditedAndActorIsReal(t *testing.T) {
	f := newP0(t)
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	seedPaidTxn(f, "TXN_C", "CONTRIBUTION")
	f.pay.entryErr = errors.New("ledger down")
	r := refund(f, t, "TXN_C", map[string]any{"amount": 500})
	if r.status != 200 {
		t.Fatalf("money already moved, response must be 200: %d %v", r.status, r.body)
	}
	w, _ := r.body["warnings"].([]any)
	if len(w) != 1 || w[0] != "ledger entry not appended" {
		t.Fatalf("warnings: %v", r.body["warnings"])
	}
	crit := f.audit.find("REFUND_LEDGER_ENTRY_FAILED")
	if crit == nil || !strings.HasPrefix(crit.Details, "CRITICAL:") {
		t.Fatalf("missing CRITICAL audit entry: %+v", crit)
	}
	done := f.audit.find("INSTANT_REFUND_EXECUTED")
	if done == nil || done.Actor == "ADMIN" || !strings.Contains(done.Actor, "ADM_A") {
		t.Fatalf("audit actor must come from the JWT, got %+v", done)
	}
	// Pending request: closed APPROVED, cannot be approved or rejected again.
	f.refunds.rows["REQ1"] = domain.RefundRequest{ID: "REQ1", MahalID: tenantA, TransactionID: "TXN_C", Status: "PENDING", Amount: 0}
	seedPaidTxn(f, "TXN_C", "CONTRIBUTION")
	f.pay.entryErr = nil
	if r := refund(f, t, "REQ1", map[string]any{"amount": 50}); r.status != 200 || f.refunds.rows["REQ1"].Status != "APPROVED" {
		t.Fatalf("approve request: %d %v", r.status, r.body)
	}
	if r := refund(f, t, "REQ1", map[string]any{"amount": 50}); r.status != 409 {
		t.Fatalf("second approval: %d", r.status)
	}
}

// ---------------------------------------------------------------------------
// 7. Webhook hardening
// ---------------------------------------------------------------------------

func payuReverseHash(p map[string]string, salt string) string {
	return pg.GenerateHash(p, salt) // the generic fallback VerifyResponseHash accepts
}

func (f *p0Fixture) webhook(t *testing.T, params map[string]string) resp {
	t.Helper()
	f.app.Post("/webhooks/pg", f.h.HandlePGWebhook)
	return f.do(t, "POST", "/webhooks/pg", "", "", params)
}

func TestWebhookBadHashAlertIsDedupedAndNeverCommits(t *testing.T) {
	f := newP0(t)
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	before := len(f.alerts.rows)
	for i := 0; i < 5; i++ {
		r := f.webhook(t, map[string]string{"txnid": "ORDTXN_1", "status": "success", "hash": "deadbeef"})
		if r.status != 401 {
			t.Fatalf("bad hash: %d", r.status)
		}
	}
	if got := len(f.alerts.rows) - before; got != 1 {
		t.Fatalf("5 unauthenticated bad-hash POSTs created %d alerts, want 1", got)
	}
	if len(f.pay.commits) != 0 {
		t.Fatal("bad hash must never commit")
	}
}

func TestAlertThrottle(t *testing.T) {
	var a alertThrottle
	if ok, n := a.allow(time.Hour); !ok || n != 0 {
		t.Fatal("first alert passes")
	}
	for i := 0; i < 3; i++ {
		if ok, _ := a.allow(time.Hour); ok {
			t.Fatal("within the window alerts are suppressed")
		}
	}
	a.last = time.Now().Add(-2 * time.Hour)
	if ok, n := a.allow(time.Hour); !ok || n != 3 {
		t.Fatalf("after the window: ok=%v suppressed=%d, want true/3", ok, n)
	}
}

func TestWebhookAmountAndCurrencyMustMatchStoredTransaction(t *testing.T) {
	f := newP0(t)
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	signed := func(amount, currency string) map[string]string {
		p := map[string]string{"txnid": "ORDTXN_1", "udf1": "TXN_1", "status": "success", "amount": amount}
		if currency != "" {
			p["currency"] = currency
		}
		p["hash"] = payuReverseHash(p, testPayUSalt)
		return p
	}
	// TXN_1 is a 500.00 INR transaction.
	if r := f.webhook(t, signed("1.00", "")); r.status != 200 || len(f.pay.commits) != 0 {
		t.Fatalf("underpaid callback must not commit: %d %v", r.status, r.body)
	}
	if f.audit.find("PG_WEBHOOK_MISMATCH") == nil {
		t.Fatal("amount mismatch must be audited")
	}
	if r := f.webhook(t, signed("500.00", "USD")); len(f.pay.commits) != 0 {
		t.Fatalf("wrong currency must not commit: %v", r.body)
	}
	if r := f.webhook(t, signed("500.00", "INR")); r.status != 200 || r.body["status"] != "SUCCESS" || len(f.pay.commits) != 1 {
		t.Fatalf("matching callback: %d %v commits=%v", r.status, r.body, f.pay.commits)
	}
}

func TestGatewayVerifyRejectsAmountMismatch(t *testing.T) {
	f := newP0(t)
	stub := newPayuStub()
	defer stub.srv.Close()
	f.h.pgClient = stub.client()
	stub.verify["ORDTXN_1"] = "success" // stub reports amt 1000.00; TXN_1 is 500
	r := f.do(t, "POST", "/api/v1/payments/dues/confirm", tenantA, f.mem, map[string]string{"transaction_id": "TXN_1"})
	if r.status != 409 || len(f.pay.commits) != 0 {
		t.Fatalf("amount mismatch at verify_payment must not commit: %d %v", r.status, r.body)
	}
	if !gatewayAmountMatches("500.00", 500) || gatewayAmountMatches("500.01", 500) || gatewayAmountMatches("x", 500) {
		t.Fatal("gatewayAmountMatches")
	}
}

// ---------------------------------------------------------------------------
// 8. AutoPay
// ---------------------------------------------------------------------------

func TestMandateAmountValidation(t *testing.T) {
	ok := func(max, debit float64) bool { return validateMandateAmounts(max, debit) == nil }
	if !ok(1000, 500) || !ok(500, 500) {
		t.Fatal("sane amounts rejected")
	}
	for _, c := range [][2]float64{{0, 0}, {-1, 5}, {1000, 0}, {500, 600}, {mahalMaxMonthlyDues + 1, 10}, {10, mahalMaxMonthlyDues + 1}} {
		if ok(c[0], c[1]) {
			t.Errorf("max=%v debit=%v must be rejected", c[0], c[1])
		}
	}
	f := newP0(t)
	r := f.do(t, "POST", "/api/v1/autopay/mandate/create", tenantA, f.mem, map[string]any{"max_amount": 500, "debit_amount": 900})
	if r.status != 400 {
		t.Fatalf("debit above max via API: %d %v", r.status, r.body)
	}
}

func TestAutopayBackoffGrowsAndCaps(t *testing.T) {
	want := []time.Duration{30 * time.Minute, time.Hour, 2 * time.Hour, 4 * time.Hour, 8 * time.Hour}
	for i, w := range want {
		if got := autopayBackoff(i + 1); got != w {
			t.Errorf("failure %d: backoff %v, want %v", i+1, got, w)
		}
	}
	if autopayBackoff(40) != autopayBackoffCap {
		t.Error("backoff must be capped")
	}
}

func cancelFixture(t *testing.T) (*p0Fixture, *memMandates) {
	f := newP0(t)
	mm := &memMandates{rows: map[string]domain.Mandate{
		"MNDACT": {ID: "MNDACT", MahalID: tenantA, MemberID: "MEM_1", Status: "ACTIVE", AuthPayUID: "AUTH1"},
	}}
	f.h.mandateRepo = mm
	return f, mm
}

func TestCancelMandateRevokesStandingInstructionAtPayU(t *testing.T) {
	f, mm := cancelFixture(t)
	stub := newPayuStub()
	defer stub.srv.Close()
	f.h.pgClient = stub.client()
	r := f.do(t, "POST", "/api/v1/autopay/mandate/cancel", tenantA, f.mem, map[string]string{"mandate_id": "MNDACT"})
	if r.status != 200 || r.body["status"] != "CANCELLED" || r.body["gateway_cancel_status"] != "CANCELLED" || stub.count("upi_mandate_revoke") != 1 {
		t.Fatalf("cancel: %d %v", r.status, r.body)
	}
	if mm.rows["MNDACT"].Status != "CANCELLED" || mm.rows["MNDACT"].GatewayCancelStatus != "CANCELLED" {
		t.Fatalf("mandate: %+v", mm.rows["MNDACT"])
	}
}

func TestCancelMandateGatewayFailureIsRecordedNotHidden(t *testing.T) {
	f, mm := cancelFixture(t)
	stub := newPayuStub()
	stub.revokeOK = false
	defer stub.srv.Close()
	f.h.pgClient = stub.client()
	r := f.do(t, "POST", "/api/v1/autopay/mandate/cancel", tenantA, f.mem, map[string]string{"mandate_id": "MNDACT"})
	if r.status != 200 || r.body["gateway_cancel_status"] != "FAILED" || r.body["warning"] == nil {
		t.Fatalf("revoke failure must be reported: %d %v", r.status, r.body)
	}
	if mm.rows["MNDACT"].Status != "CANCELLED" {
		t.Fatal("our own debits must still stop")
	}
	if f.audit.find("AUTOPAY_GATEWAY_CANCEL_FAILED") == nil {
		t.Fatal("must be audited")
	}
	// Simulated gateway: nothing to revoke.
	f2, _ := cancelFixture(t)
	f2.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	if r := f2.do(t, "POST", "/api/v1/autopay/mandate/cancel", tenantA, f2.mem, map[string]string{"mandate_id": "MNDACT"}); r.body["gateway_cancel_status"] != "SKIPPED" {
		t.Fatalf("simulated: %v", r.body)
	}
}

type debitFixture struct {
	*p0Fixture
	mm   *memMandates
	stub *payuStub
	m    domain.Mandate
	now  time.Time
}

func newDebit(t *testing.T) *debitFixture {
	f := newP0(t)
	stub := newPayuStub()
	t.Cleanup(stub.srv.Close)
	f.h.pgClient = stub.client()
	now := time.Now().UTC()
	next, sent := now.Add(-time.Hour), now.Add(-72*time.Hour)
	m := domain.Mandate{ID: "MNDD", MahalID: tenantA, MemberID: "MEM_1", Status: "ACTIVE", AuthPayUID: "AUTH1",
		DebitAmount: 1000, MaxAmount: 1000, Frequency: "MONTHLY", Mode: "UPI", NextDebit: &next, PreDebitSentAt: &sent}
	mm := &memMandates{rows: map[string]domain.Mandate{m.ID: m}, due: []string{m.ID}}
	f.h.mandateRepo = mm
	mem := f.members.rows["MEM_1"]
	mem.MonthlyDuesCustomAmount, mem.LastPaidMonth, mem.Email, mem.Name = 500, "2026-08", "m1@example.org", "Member One"
	f.members.rows["MEM_1"] = mem
	return &debitFixture{p0Fixture: f, mm: mm, stub: stub, m: m, now: now}
}

func TestAutopayDebitAdvancesDuesAndUsesMemberDetails(t *testing.T) {
	d := newDebit(t)
	got := d.h.processMandateDebit(context.Background(), d.m, d.now)
	if got != "charged" || d.stub.count("si_transaction") != 1 {
		t.Fatalf("outcome %q, si calls %d", got, d.stub.count("si_transaction"))
	}
	// 1000 = two months of the 500 rate: booked as dues for the next unpaid months.
	if len(d.pay.duesInit) != 1 || strings.Join(d.pay.duesInit[0], ",") != "2026-09,2026-10" || d.pay.contribs != 0 {
		t.Fatalf("dues months: %v contribs=%d", d.pay.duesInit, d.pay.contribs)
	}
	var1 := d.stub.forms["si_transaction"].Get("var1")
	if strings.Contains(var1, "member@mahalflow.org") || !strings.Contains(var1, "m1@example.org") || !strings.Contains(var1, "Member One") {
		t.Fatalf("payer details must come from the member: %s", var1)
	}
	mm := d.mm.rows["MNDD"]
	if mm.FailureCount != 0 || mm.NextDebit == nil || !mm.NextDebit.After(d.now) || mm.LastDebitAt == nil {
		t.Fatalf("mandate not advanced: %+v", mm)
	}
	// An amount that is not a whole number of months stays a contribution.
	d2 := newDebit(t)
	d2.m.DebitAmount = 750
	d2.h.processMandateDebit(context.Background(), d2.m, d2.now)
	if len(d2.pay.duesInit) != 0 || d2.pay.contribs != 1 {
		t.Fatalf("non-multiple amount: dues=%v contribs=%d", d2.pay.duesInit, d2.pay.contribs)
	}
}

func TestAutopayFailureBacksOffThenStops(t *testing.T) {
	d := newDebit(t)
	d.stub.siOK = false
	ctx := context.Background()
	if got := d.h.processMandateDebit(ctx, d.m, d.now); got != "failed" {
		t.Fatalf("outcome %q", got)
	}
	mm := d.mm.rows["MNDD"]
	if mm.FailureCount != 1 || mm.NextRetryAt == nil || mm.NextRetryAt.Sub(d.now) != 30*time.Minute || mm.Status != "ACTIVE" {
		t.Fatalf("after first failure: %+v", mm)
	}
	// While backing off the gateway is not touched.
	calls := d.stub.count("si_transaction")
	if got := d.h.processMandateDebit(ctx, mm, d.now.Add(10*time.Minute)); got != "skipped" || d.stub.count("si_transaction") != calls {
		t.Fatalf("during backoff: %q calls=%d", got, d.stub.count("si_transaction"))
	}
	// Each retry is a new attempt (new idempotency key) until the cap.
	cur := mm
	at := d.now
	for i := 2; i <= autopayMaxFailures; i++ {
		at = at.Add(48 * time.Hour)
		d.h.processMandateDebit(ctx, cur, at)
		cur = d.mm.rows["MNDD"]
		if cur.FailureCount != i {
			t.Fatalf("attempt %d: failure_count %d", i, cur.FailureCount)
		}
	}
	if cur.Status != "FAILED" || cur.NextDebit != nil {
		t.Fatalf("mandate must stop after %d failures: %+v", autopayMaxFailures, cur)
	}
	if got := d.stub.count("si_transaction"); got != autopayMaxFailures {
		t.Fatalf("debit attempts: %d, want %d (no endless retries)", got, autopayMaxFailures)
	}
}

func TestAutopayDuplicateAttemptNeverDebitsAgain(t *testing.T) {
	ctx := context.Background()

	// Attempt already SUCCESS (mandate just was not advanced): no debit, state advances.
	d := newDebit(t)
	d.txns.rows["TXN_DONE"] = domain.Transaction{ID: "TXN_DONE", MahalID: tenantA, MemberID: "MEM_1", Status: domain.TxnSuccess,
		IdempotencyKey: autopayIdempotencyKey(&d.m)}
	if got := d.h.processMandateDebit(ctx, d.m, d.now); got != "skipped" || d.stub.count("si_transaction") != 0 {
		t.Fatalf("SUCCESS duplicate: %q si=%d", got, d.stub.count("si_transaction"))
	}
	if d.mm.rows["MNDD"].NextDebit == nil || !d.mm.rows["MNDD"].NextDebit.After(d.now) {
		t.Fatal("mandate must advance past the already-booked cycle")
	}

	// Attempt PENDING and PayU says it succeeded: commit without a second debit.
	d = newDebit(t)
	d.txns.rows["TXN_P"] = domain.Transaction{ID: "TXN_P", MahalID: tenantA, MemberID: "MEM_1", Status: domain.TxnPending, Amount: 1000,
		IdempotencyKey: autopayIdempotencyKey(&d.m)}
	d.stub.verify["ORDTXN_P"] = "success"
	if got := d.h.processMandateDebit(ctx, d.m, d.now); got != "charged" || d.stub.count("si_transaction") != 0 || len(d.pay.commits) != 1 {
		t.Fatalf("PENDING+success: %q si=%d commits=%v", got, d.stub.count("si_transaction"), d.pay.commits)
	}

	// Attempt PENDING and PayU is still processing: wait, do not debit.
	d = newDebit(t)
	d.txns.rows["TXN_Q"] = domain.Transaction{ID: "TXN_Q", MahalID: tenantA, MemberID: "MEM_1", Status: domain.TxnPending,
		IdempotencyKey: autopayIdempotencyKey(&d.m)}
	d.stub.verify["ORDTXN_Q"] = "pending"
	if got := d.h.processMandateDebit(ctx, d.m, d.now); got != "skipped" || d.stub.count("si_transaction") != 0 {
		t.Fatalf("PENDING+pending: %q si=%d", got, d.stub.count("si_transaction"))
	}

	// Money debited but the receipt commit failed: stays PENDING for the
	// reconcile path above, CRITICAL audit, and the mandate is not advanced.
	d = newDebit(t)
	d.pay.commitErr = errors.New("ledger down")
	if got := d.h.processMandateDebit(ctx, d.m, d.now); got != "failed" || d.stub.count("si_transaction") != 1 {
		t.Fatalf("commit failure: %q", got)
	}
	if d.audit.find("AUTOPAY_COMMIT_FAILED") == nil || d.mm.rows["MNDD"].FailureCount != 0 {
		t.Fatal("commit failure after a successful debit must be CRITICAL-audited and not counted as a failed debit")
	}
}

func TestSchedulerRespectsLease(t *testing.T) {
	d := newDebit(t)
	lease := &fakeLease{allow: false}
	d.h.leaseRepo, d.h.leaseOwner = lease, "me"
	res := d.h.runDueAutoPayDebits(context.Background())
	if res["skipped_reason"] == nil || d.stub.count("si_transaction") != 0 || lease.released != 0 {
		t.Fatalf("lease held elsewhere: %v si=%d", res, d.stub.count("si_transaction"))
	}
	// Lease backend failing: fail closed, no debits.
	lease.err = errors.New("mongo down")
	if res := d.h.runDueAutoPayDebits(context.Background()); res["error"] == nil || d.stub.count("si_transaction") != 0 {
		t.Fatalf("lease error: %v", res)
	}
	// Lease granted: runs, and releases at the end.
	lease.err, lease.allow = nil, true
	res = d.h.runDueAutoPayDebits(context.Background())
	if res["charged"] != 1 || d.stub.count("si_transaction") != 1 || lease.released != 1 {
		t.Fatalf("lease granted: %v si=%d released=%d", res, d.stub.count("si_transaction"), lease.released)
	}
}

// ---------------------------------------------------------------------------
// 10. Registration dues
// ---------------------------------------------------------------------------

func TestRegisterUsesTenantDefaultDues(t *testing.T) {
	f := newP0(t)
	mh := f.h.mahalRepo.(*fakeMahals)
	m := mh.rows[tenantA]
	m.Settings.DefaultMonthlyDues = 750
	mh.rows[tenantA] = m
	r := f.do(t, "POST", "/api/v1/auth/register", tenantA, "", map[string]string{
		"id_token": "valid:+919777777777", "name": "New", "mahal_id": tenantA})
	if r.status != 201 {
		t.Fatalf("register: %d %v", r.status, r.body)
	}
	got, _ := f.members.GetByID(nil, tenantA, r.body["member_id"].(string))
	if got == nil || got.MonthlyDuesCustomAmount != 750 {
		t.Fatalf("dues rate must come from the tenant config: %+v", got)
	}
}
