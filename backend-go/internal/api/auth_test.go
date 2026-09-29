package api

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
	"golang.org/x/crypto/bcrypt"
)

const (
	tenantA = "MH_A"
	tenantB = "MH_B"
)

type fixture struct {
	app      *fiber.App
	h        *Handler
	members  *fakeMembers
	receipts *fakeReceipts
	alerts   *fakeAlerts
	txns     *fakeTxns
	refunds  *fakeRefunds
	admins   *fakeAdmins
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte("correct horse battery"), bcrypt.MinCost)
	if err != nil {
		t.Fatal(err)
	}
	f := &fixture{
		admins: &fakeAdmins{rows: []domain.Admin{
			{ID: "ADM_A", MahalID: tenantA, Name: "Admin A", Phone: "+919000000001", PasswordHash: string(hash)},
			{ID: "ADM_NOPW", MahalID: tenantA, Name: "No Password", Phone: "+919000000002"},
			{ID: "ADM_SUPER", MahalID: tenantA, Name: "Ops", Phone: "+919000000003", Role: domain.RoleSuperAdmin, PasswordHash: string(hash)},
			{ID: "ADM_MULTI_A", MahalID: tenantA, Name: "Multi", Phone: "+919000000004", PasswordHash: string(hash)},
			{ID: "ADM_MULTI_B", MahalID: tenantB, Name: "Multi", Phone: "+919000000004", PasswordHash: string(hash)},
		}},
		members: &fakeMembers{rows: map[string]domain.Member{
			"MEM_1":       {ID: "MEM_1", MahalID: tenantA, Name: "One", Phone: "+919111111111", Status: "ACTIVE", OutstandingBalance: 500, FamilyHead: true},
			"MEM_2":       {ID: "MEM_2", MahalID: tenantA, Name: "Two", Phone: "+919222222222", Status: "ACTIVE"},
			"MEM_PENDING": {ID: "MEM_PENDING", MahalID: tenantA, Name: "Pending", Phone: "+919333333333", Status: MemberStatusPending},
			"MEM_B":       {ID: "MEM_B", MahalID: tenantB, Name: "Other Mahal", Phone: "+919444444444", Status: "ACTIVE"},
		}},
		receipts: &fakeReceipts{rows: []domain.Receipt{
			{ID: "R1", ReceiptNumber: "RCPT-A-1", SequenceNumber: 1, MahalID: tenantA, MemberID: "MEM_1", Amount: 500, CreatedAt: time.Now().Add(-48 * time.Hour)},
			{ID: "R2", ReceiptNumber: "RCPT-A-2", SequenceNumber: 2, MahalID: tenantA, MemberID: "MEM_2", Amount: 900, CreatedAt: time.Now().Add(-time.Hour)},
			{ID: "R3", ReceiptNumber: "RCPT-B-1", SequenceNumber: 1, MahalID: tenantB, MemberID: "MEM_B", Amount: 700, CreatedAt: time.Now()},
		}},
		alerts: &fakeAlerts{
			rows: []domain.SystemAlert{
				{ID: "ALT_1", MahalID: tenantA, Audience: "ALL", Title: "Eid", Status: "ACTIVE"},
				{ID: "ALT_2", MahalID: tenantA, Audience: "ALL", Title: "Meeting", Status: "ACTIVE"},
				{ID: "ALT_B", MahalID: tenantB, Audience: "ALL", Title: "Elsewhere", Status: "ACTIVE"},
			},
			states: map[string]domain.AlertMemberState{},
		},
		txns: &fakeTxns{rows: map[string]domain.Transaction{
			"TXN_1": {ID: "TXN_1", MahalID: tenantA, MemberID: "MEM_1", Amount: 500, Status: domain.TxnPending},
			"TXN_B": {ID: "TXN_B", MahalID: tenantB, MemberID: "MEM_B", Amount: 500, Status: domain.TxnPending},
		}},
		refunds: &fakeRefunds{rows: map[string]domain.RefundRequest{
			"REF_B": {ID: "REF_B", MahalID: tenantB, TransactionID: "TXN_B", Status: "PENDING"},
		}},
	}
	mahals := &fakeMahals{rows: map[string]domain.Mahal{
		tenantA: {ID: tenantA, Name: "Mahal A"},
		tenantB: {ID: tenantB, Name: "Mahal B"},
	}}
	f.h = NewHandler(nil, mahals, f.members, f.receipts, f.txns, nil, f.alerts, f.refunds, nil, f.admins, nil)
	f.h.SetPhoneAuth(fakeVerifier{}, false)

	f.app = fiber.New()
	f.app.Post("/api/v1/auth/login", f.h.Login)
	v1 := f.app.Group("/api/v1", TenantExtractionMiddleware())
	RegisterTenantRoutes(v1, f.h)
	return f
}

type resp struct {
	status int
	body   map[string]any
}

func (f *fixture) do(t *testing.T, method, path, tenant, bearer string, body any) resp {
	t.Helper()
	var rd io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		rd = strings.NewReader(string(b))
	}
	req := httptest.NewRequest(method, path, rd)
	req.Header.Set("Content-Type", "application/json")
	if tenant != "" {
		req.Header.Set("X-Tenant-ID", tenant)
	}
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	res, err := f.app.Test(req, 10000)
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := io.ReadAll(res.Body)
	out := resp{status: res.StatusCode, body: map[string]any{}}
	_ = json.Unmarshal(raw, &out.body)
	return out
}

func token(t *testing.T, sub, role, mahal string) string {
	t.Helper()
	tok, err := GenerateJWT(sub, "+910000000000", role, mahal, time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	return tok
}

func claimsOf(t *testing.T, r resp) *JWTClaims {
	t.Helper()
	tok, _ := r.body["token"].(string)
	c, err := ValidateJWT(tok)
	if err != nil {
		t.Fatalf("response token invalid: %v (%v)", err, r.body)
	}
	return c
}

// --- 1. Password login ------------------------------------------------------

func TestLoginVerifiesBcryptPassword(t *testing.T) {
	f := newFixture(t)

	r := f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]string{"phone": "9000000001", "password": "correct horse battery"})
	if r.status != 200 {
		t.Fatalf("valid login: %d %v", r.status, r.body)
	}
	c := claimsOf(t, r)
	if c.Subject != "ADM_A" || c.Role != domain.RoleMahalAdmin || c.MahalID != tenantA {
		t.Fatalf("token must carry the admin record's identity, got %+v", c)
	}

	for name, body := range map[string]map[string]string{
		"wrong password":            {"phone": "9000000001", "password": "wrong"},
		"unknown phone":             {"phone": "9876543210", "password": "correct horse battery"},
		"admin without password":    {"phone": "9000000002", "password": "anything"},
		"mahal the admin is not in": {"phone": "9000000001", "password": "correct horse battery", "mahal_id": tenantB},
	} {
		r := f.do(t, "POST", "/api/v1/auth/login", "", "", body)
		if r.status != 401 || r.body["error"] != invalidCredentials {
			t.Errorf("%s: want 401 %q, got %d %v", name, invalidCredentials, r.status, r.body)
		}
		if _, ok := r.body["token"]; ok {
			t.Errorf("%s: token issued on failure", name)
		}
	}

	if r := f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]string{"phone": "9000000001"}); r.status != 400 {
		t.Errorf("missing password: want 400, got %d", r.status)
	}
	// The request can no longer pick its tenant or role.
	if r := f.do(t, "POST", "/api/v1/auth/login", tenantB, "", map[string]string{"phone": "9000000001", "password": "correct horse battery"}); claimsOf(t, r).MahalID != tenantA {
		t.Errorf("X-Tenant-ID must not choose the token tenant")
	}
}

func TestLoginSuperAdminAndMultiMahal(t *testing.T) {
	f := newFixture(t)
	r := f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]string{"phone": "9000000003", "password": "correct horse battery"})
	if r.status != 200 || claimsOf(t, r).Role != domain.RoleSuperAdmin {
		t.Fatalf("super admin login: %d %v", r.status, r.body)
	}

	r = f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]string{"phone": "9000000004", "password": "correct horse battery"})
	if r.status != 409 {
		t.Fatalf("ambiguous admin: want 409, got %d %v", r.status, r.body)
	}
	r = f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]string{"phone": "9000000004", "password": "correct horse battery", "mahal_id": tenantB})
	if r.status != 200 || claimsOf(t, r).Subject != "ADM_MULTI_B" {
		t.Fatalf("mahal_id disambiguation: %d %v", r.status, r.body)
	}
}

// --- 2. Firebase-verified resolve / register --------------------------------

func TestResolveRequiresVerifiedFirebaseToken(t *testing.T) {
	f := newFixture(t)

	// No token: refused even though the posted phone is a real member.
	if r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"phone": "+919111111111"}); r.status != 401 {
		t.Fatalf("no token: want 401, got %d %v", r.status, r.body)
	}
	// Forged token.
	if r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"id_token": "forged"}); r.status != 401 {
		t.Fatalf("bad token: want 401, got %d", r.status)
	}

	// The phone comes from the token, never the body: posting an admin's phone
	// with a member's token yields the member.
	r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{
		"id_token": "valid:+919111111111", "phone": "+919000000001",
	})
	if r.status != 200 || r.body["status"] != "ALLOWED" || r.body["role"] != domain.RoleMember {
		t.Fatalf("member resolve: %d %v", r.status, r.body)
	}
	if c := claimsOf(t, r); c.Subject != "MEM_1" || c.MahalID != tenantA {
		t.Fatalf("member token: %+v", c)
	}

	// Token in the Authorization header works too.
	r = f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "valid:+919000000001", map[string]string{})
	if r.status != 200 || r.body["role"] != domain.RoleMahalAdmin {
		t.Fatalf("admin resolve via header: %d %v", r.status, r.body)
	}

	// Pending members get no token.
	r = f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"id_token": "valid:+919333333333"})
	if r.body["status"] != "PENDING" || r.body["token"] != nil {
		t.Fatalf("pending: %v", r.body)
	}
}

func TestResolveWithoutFirebaseConfig(t *testing.T) {
	f := newFixture(t)
	f.h.SetPhoneAuth(nil, false)
	if r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"phone": "+919111111111"}); r.status != 503 {
		t.Fatalf("unconfigured: want 503, got %d", r.status)
	}

	f.h.SetPhoneAuth(nil, true) // AUTH_DEV_BYPASS
	r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"phone": "9111111111"})
	if r.status != 200 || r.body["member_id"] != "MEM_1" {
		t.Fatalf("dev bypass: %d %v", r.status, r.body)
	}
}

func TestRegisterUsesTokenPhone(t *testing.T) {
	f := newFixture(t)
	if r := f.do(t, "POST", "/api/v1/auth/register", tenantA, "", map[string]string{"phone": "+919555555555", "name": "New", "mahal_id": tenantA}); r.status != 401 {
		t.Fatalf("register without token: want 401, got %d", r.status)
	}
	r := f.do(t, "POST", "/api/v1/auth/register", tenantA, "", map[string]string{
		"id_token": "valid:+919555555555", "phone": "+919999999999", "name": "New", "mahal_id": tenantA,
	})
	if r.status != 201 {
		t.Fatalf("register: %d %v", r.status, r.body)
	}
	m, _ := f.members.GetByID(nil, tenantA, r.body["member_id"].(string))
	if m == nil || m.Phone != "+919555555555" || m.Status != MemberStatusPending {
		t.Fatalf("registered member must use the verified phone: %+v", m)
	}
}

// --- 3. Member route auth & ownership ---------------------------------------

func TestMemberRoutesRequireJWT(t *testing.T) {
	f := newFixture(t)
	paths := []struct{ method, path string }{
		{"GET", "/api/v1/member/dashboard"},
		{"GET", "/api/v1/member/receipts"},
		{"GET", "/api/v1/members/profile/MEM_1"},
		{"PUT", "/api/v1/members/profile/MEM_1"},
		{"GET", "/api/v1/member/alerts"},
		{"GET", "/api/v1/alerts"},
		{"POST", "/api/v1/member/alerts/ALT_1/ack"},
		{"POST", "/api/v1/payments/dues/initialize"},
		{"POST", "/api/v1/payments/dues/confirm"},
		{"GET", "/api/v1/payments/TXN_1/status"},
		{"POST", "/api/v1/payments/payu-generate-hash"},
		{"GET", "/api/v1/receipts/RCPT-A-1"},
		{"GET", "/api/v1/receipts/RCPT-A-1/verify"},
		{"GET", "/api/v1/autopay/mandate/status"},
		{"POST", "/api/v1/notifications/register-token"},
		{"GET", "/api/v1/mahal/qr-standee"},
	}
	for _, p := range paths {
		if r := f.do(t, p.method, p.path, tenantA, "", map[string]string{}); r.status != 401 {
			t.Errorf("%s %s without JWT: want 401, got %d", p.method, p.path, r.status)
		}
	}
}

func TestMemberSeesOnlyOwnData(t *testing.T) {
	f := newFixture(t)
	mem1 := token(t, "MEM_1", domain.RoleMember, tenantA)

	// Dashboard: defaults to the JWT subject; latest_payment is the member's
	// own receipt, not the tenant's newest (RCPT-A-2 belongs to MEM_2).
	r := f.do(t, "GET", "/api/v1/member/dashboard", tenantA, mem1, nil)
	if r.status != 200 || r.body["member_id"] != "MEM_1" {
		t.Fatalf("dashboard: %d %v", r.status, r.body)
	}
	latest, _ := r.body["latest_payment"].(map[string]any)
	if latest == nil || latest["receipt_number"] != "RCPT-A-1" {
		t.Fatalf("latest_payment must be the member's own receipt, got %v", r.body["latest_payment"])
	}

	// Asking for someone else is refused.
	for _, p := range []string{
		"/api/v1/member/dashboard?member_id=MEM_2",
		"/api/v1/member/receipts?member_id=MEM_2",
		"/api/v1/members/profile/MEM_2",
		"/api/v1/autopay/mandate/status?member_id=MEM_2",
	} {
		if r := f.do(t, "GET", p, tenantA, mem1, nil); r.status != 403 {
			t.Errorf("%s: want 403, got %d", p, r.status)
		}
	}
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, mem1, map[string]string{"name": "Hijacked"}); r.status != 403 {
		t.Errorf("update other profile: want 403, got %d", r.status)
	}
	// Members cannot change committee-owned fields on their own record.
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_1", tenantA, mem1, map[string]any{"monthly_dues_custom_amount": 1}); r.status != 403 {
		t.Errorf("member changing own dues: want 403, got %d", r.status)
	}
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_1", tenantA, mem1, map[string]string{"name": "One Updated"}); r.status != 200 {
		t.Errorf("member editing own name: want 200, got %d", r.status)
	}

	// Receipts list is the member's own.
	r = f.do(t, "GET", "/api/v1/member/receipts", tenantA, mem1, nil)
	if list, _ := r.body["receipts"].([]any); r.status != 200 || len(list) != 1 {
		t.Fatalf("receipts: %d %v", r.status, r.body)
	}

	// Cash is committee-only; transactions of others are invisible.
	if r := f.do(t, "POST", "/api/v1/payments/dues/initialize", tenantA, mem1, map[string]any{"gateway": "CASH", "selected_months": []string{"2026-09"}}); r.status != 403 {
		t.Errorf("member CASH: want 403, got %d", r.status)
	}
	mem2 := token(t, "MEM_2", domain.RoleMember, tenantA)
	if r := f.do(t, "POST", "/api/v1/payments/dues/confirm", tenantA, mem2, map[string]string{"transaction_id": "TXN_1"}); r.status != 404 {
		t.Errorf("confirm other member's txn: want 404, got %d", r.status)
	}
}

func TestTenantBoundTokens(t *testing.T) {
	f := newFixture(t)
	mem1 := token(t, "MEM_1", domain.RoleMember, tenantA)
	if r := f.do(t, "GET", "/api/v1/member/dashboard", tenantB, mem1, nil); r.status != 403 {
		t.Fatalf("tenant mismatch: want 403, got %d", r.status)
	}
	noTenant := token(t, "MEM_1", domain.RoleMember, "")
	if r := f.do(t, "GET", "/api/v1/member/dashboard", tenantA, noTenant, nil); r.status != 403 {
		t.Fatalf("token without tenant: want 403, got %d", r.status)
	}
}

func TestAdminAccessesOwnTenantMembers(t *testing.T) {
	f := newFixture(t)
	adm := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	if r := f.do(t, "GET", "/api/v1/members/profile/MEM_2", tenantA, adm, nil); r.status != 200 {
		t.Fatalf("admin reads member: %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/members/profile/MEM_B", tenantA, adm, nil); r.status != 404 {
		t.Fatalf("admin reads other tenant's member: want 404, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/member/dashboard", tenantA, adm, nil); r.status != 400 {
		t.Fatalf("admin dashboard without member_id: want 400, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/admin/mahals", tenantA, adm, nil); r.status != 403 {
		t.Fatalf("mahal admin listing all mahals: want 403, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/admin/mahals/"+tenantB, tenantA, adm, nil); r.status != 404 {
		t.Fatalf("mahal admin reading another mahal: want 404, got %d", r.status)
	}
	// A member token never reaches admin routes.
	if r := f.do(t, "GET", "/api/v1/admin/dashboard", tenantA, token(t, "MEM_1", domain.RoleMember, tenantA), nil); r.status != 403 {
		t.Fatalf("member on admin route: want 403, got %d", r.status)
	}
}

// --- 4. Receipt tenant filter -----------------------------------------------

func TestReceiptLookupIsTenantAndOwnerScoped(t *testing.T) {
	f := newFixture(t)
	adm := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	mem1 := token(t, "MEM_1", domain.RoleMember, tenantA)

	if r := f.do(t, "GET", "/api/v1/receipts/RCPT-B-1", tenantA, adm, nil); r.status != 404 {
		t.Errorf("other tenant's receipt: want 404, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/receipts/RCPT-B-1/verify", tenantA, adm, nil); r.status != 404 {
		t.Errorf("verify other tenant's receipt: want 404, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/receipts/RCPT-A-2", tenantA, adm, nil); r.status != 200 {
		t.Errorf("admin own tenant receipt: want 200, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/receipts/RCPT-A-2", tenantA, mem1, nil); r.status != 404 {
		t.Errorf("member reading another member's receipt: want 404, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/receipts/RCPT-A-1", tenantA, mem1, nil); r.status != 200 {
		t.Errorf("member own receipt: want 200, got %d", r.status)
	}
}

// --- 7. 404 for nonexistent ids ----------------------------------------------

func TestDeleteAndRefundReport404(t *testing.T) {
	f := newFixture(t)
	adm := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)

	if r := f.do(t, "DELETE", "/api/v1/admin/members/NOPE", tenantA, adm, nil); r.status != 404 {
		t.Errorf("delete missing member: want 404, got %d", r.status)
	}
	if r := f.do(t, "DELETE", "/api/v1/admin/members/MEM_B", tenantA, adm, nil); r.status != 404 {
		t.Errorf("delete other tenant's member: want 404, got %d", r.status)
	}
	if r := f.do(t, "DELETE", "/api/v1/admin/members/MEM_2", tenantA, adm, nil); r.status != 200 {
		t.Errorf("delete member: want 200, got %d", r.status)
	}
	for _, action := range []string{"REJECT", "APPROVE"} {
		if r := f.do(t, "POST", "/api/v1/admin/refunds/NOPE/action", tenantA, adm, map[string]string{"action": action}); r.status != 404 {
			t.Errorf("%s missing refund: want 404, got %d", action, r.status)
		}
		if r := f.do(t, "POST", "/api/v1/admin/refunds/REF_B/action", tenantA, adm, map[string]string{"action": action}); r.status != 404 {
			t.Errorf("%s other tenant's refund: want 404, got %d", action, r.status)
		}
	}
	if f.refunds.rows["REF_B"].Status != "PENDING" {
		t.Errorf("cross-tenant refund was modified")
	}
}

// --- Member alert state -----------------------------------------------------

func TestMemberAlertStateIsPerMember(t *testing.T) {
	f := newFixture(t)
	mem1 := token(t, "MEM_1", domain.RoleMember, tenantA)
	mem2 := token(t, "MEM_2", domain.RoleMember, tenantA)

	unread := func(tok string) float64 {
		r := f.do(t, "GET", "/api/v1/member/alerts", tenantA, tok, nil)
		if r.status != 200 {
			t.Fatalf("alerts: %d %v", r.status, r.body)
		}
		n, _ := r.body["unread_count"].(float64)
		return n
	}
	if unread(mem1) != 2 || unread(mem2) != 2 {
		t.Fatalf("both start with 2 unread")
	}

	if r := f.do(t, "POST", "/api/v1/member/alerts/ALT_1/ack", tenantA, mem1, nil); r.status != 200 {
		t.Fatalf("member ack: %d %v", r.status, r.body)
	}
	if unread(mem1) != 1 || unread(mem2) != 2 {
		t.Fatalf("ack must only affect the acting member")
	}
	if f.alerts.rows[0].Status != "ACTIVE" {
		t.Fatalf("member ack must not change the shared alert")
	}

	if r := f.do(t, "DELETE", "/api/v1/member/alerts/ALT_2", tenantA, mem1, nil); r.status != 200 {
		t.Fatalf("member dismiss: %d", r.status)
	}
	r := f.do(t, "GET", "/api/v1/member/alerts", tenantA, mem1, nil)
	if list, _ := r.body["alerts"].([]any); len(list) != 1 {
		t.Fatalf("dismissed alert still listed: %v", r.body)
	}
	if len(f.alerts.rows) != 3 {
		t.Fatalf("member dismiss must not delete the shared alert")
	}

	if r := f.do(t, "POST", "/api/v1/member/alerts/mark-all-read", tenantA, mem2, nil); r.status != 200 || unread(mem2) != 0 {
		t.Fatalf("mark-all-read: %d", r.status)
	}
	if r := f.do(t, "DELETE", "/api/v1/member/alerts", tenantA, mem2, nil); r.status != 200 {
		t.Fatalf("clear-all: %d", r.status)
	}
	r = f.do(t, "GET", "/api/v1/member/alerts", tenantA, mem2, nil)
	if list, _ := r.body["alerts"].([]any); len(list) != 0 {
		t.Fatalf("clear-all left alerts: %v", r.body)
	}

	// Another tenant's alert id is not actionable.
	if r := f.do(t, "POST", "/api/v1/member/alerts/ALT_B/ack", tenantA, mem1, nil); r.status != 404 {
		t.Fatalf("cross-tenant ack: want 404, got %d", r.status)
	}
	// Admin ack/dismiss are tenant-scoped too.
	adm := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	if r := f.do(t, "POST", "/api/v1/admin/alerts/ALT_B/ack", tenantA, adm, nil); r.status != 404 {
		t.Fatalf("admin cross-tenant ack: want 404, got %d", r.status)
	}
	if r := f.do(t, "DELETE", "/api/v1/admin/alerts/ALT_B", tenantA, adm, nil); r.status != 404 {
		t.Fatalf("admin cross-tenant dismiss: want 404, got %d", r.status)
	}
}
