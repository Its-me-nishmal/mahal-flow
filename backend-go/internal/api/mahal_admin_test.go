package api

import (
	"context"
	"testing"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
)

func adminTok(t *testing.T, a domain.Admin) string {
	t.Helper()
	tok, err := GenerateJWT(a.ID, a.Phone, a.EffectiveRole(), a.MahalID, time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	return tok
}

func (f *fixture) admin(t *testing.T, id string) domain.Admin {
	t.Helper()
	for _, a := range f.admins.rows {
		if a.ID == id {
			return a
		}
	}
	t.Fatalf("no admin %s", id)
	return domain.Admin{}
}

func mahalOf(t *testing.T, f *fixture, id string) domain.Mahal {
	t.Helper()
	m, err := f.h.mahalRepo.GetByID(context.Background(), id)
	if err != nil || m == nil {
		t.Fatalf("mahal %s missing: %v", id, err)
	}
	return *m
}

func TestUpdateMahalScopeAndValidation(t *testing.T) {
	f := newFixture(t)
	mahalAdmin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	super := token(t, "ADM_SUPER", domain.RoleSuperAdmin, tenantA)
	member := token(t, "MEM_1", domain.RoleMember, tenantA)

	r := f.do(t, "PUT", "/api/v1/admin/mahals/"+tenantA, tenantA, mahalAdmin, map[string]any{
		"name":                "Renamed A",
		"registration_number": " REG/1 ",
		"contact":             map[string]any{"email": "office@a.example", "phone": "98470 12345", "address": "Main Road"},
		"settings":            map[string]any{"default_monthly_dues": 250, "dunning_enabled": true, "autopay_allowed": true},
	})
	if r.status != 200 {
		t.Fatalf("own mahal update = %d %v", r.status, r.body)
	}
	m := mahalOf(t, f, tenantA)
	if m.Name != "Renamed A" || m.RegistrationNumber != "REG/1" || m.Contact.Phone != "+919847012345" ||
		m.Settings.DefaultMonthlyDues != 250 || !m.Settings.DunningEnabled || !m.Settings.AutoPayAllowed || m.Contact.Address != "Main Road" {
		t.Fatalf("update not persisted: %+v", m)
	}

	// Partial update leaves other fields alone.
	if r := f.do(t, "PUT", "/api/v1/admin/mahals/"+tenantA, tenantA, mahalAdmin, map[string]any{"settings": map[string]any{"dunning_enabled": false}}); r.status != 200 {
		t.Fatalf("partial update = %d %v", r.status, r.body)
	}
	if m := mahalOf(t, f, tenantA); m.Settings.DunningEnabled || m.Settings.DefaultMonthlyDues != 250 || m.Name != "Renamed A" {
		t.Fatalf("partial update clobbered fields: %+v", m)
	}

	cases := []struct {
		name, id, tenant, tok string
		body                  map[string]any
		want                  int
	}{
		{"other tenant via own header", tenantB, tenantA, mahalAdmin, map[string]any{"name": "x"}, 404},
		{"other tenant header", tenantB, tenantB, mahalAdmin, map[string]any{"name": "x"}, 403},
		{"mahal admin subscription", tenantA, tenantA, mahalAdmin, map[string]any{"subscription": map[string]any{"status": "SUSPENDED"}}, 403},
		{"member", tenantA, tenantA, member, map[string]any{"name": "x"}, 403},
		{"empty name", tenantA, tenantA, mahalAdmin, map[string]any{"name": "  "}, 400},
		{"negative dues", tenantA, tenantA, mahalAdmin, map[string]any{"settings": map[string]any{"default_monthly_dues": -1}}, 400},
		{"bad email", tenantA, tenantA, mahalAdmin, map[string]any{"contact": map[string]any{"email": "nope"}}, 400},
		{"bad phone", tenantA, tenantA, mahalAdmin, map[string]any{"contact": map[string]any{"phone": "12ab"}}, 400},
		{"bad sub status", tenantB, tenantA, super, map[string]any{"subscription": map[string]any{"status": "FREE"}}, 400},
		{"id change", tenantA, tenantA, mahalAdmin, map[string]any{"id": "OTHER"}, 400},
		{"unknown mahal", "MH_NONE", tenantA, super, map[string]any{"name": "x"}, 404},
	}
	for _, tc := range cases {
		if r := f.do(t, "PUT", "/api/v1/admin/mahals/"+tc.id, tc.tenant, tc.tok, tc.body); r.status != tc.want {
			t.Errorf("%s: status %d, want %d (%v)", tc.name, r.status, tc.want, r.body)
		}
	}
	if m := mahalOf(t, f, tenantB); m.Name != "Mahal B" {
		t.Fatalf("mahal B changed by a refused request: %+v", m)
	}

	// SUPER_ADMIN edits another Mahal, subscription included.
	r = f.do(t, "PUT", "/api/v1/admin/mahals/"+tenantB, tenantA, super, map[string]any{
		"name":         "Mahal B2",
		"subscription": map[string]any{"status": "grace_period", "plan": "premium", "monthly_fee": 999},
	})
	if r.status != 200 || r.body["name"] != "Mahal B2" {
		t.Fatalf("super update = %d %v", r.status, r.body)
	}
	if m := mahalOf(t, f, tenantB); m.Subscription.Status != domain.SubGracePeriod || m.Subscription.Plan != "PREMIUM" || m.Subscription.MonthlyFee != 999 {
		t.Fatalf("subscription not persisted: %+v", m.Subscription)
	}
}

func TestCreateMahalValidation(t *testing.T) {
	f := newFixture(t)
	super := token(t, "ADM_SUPER", domain.RoleSuperAdmin, tenantA)
	mahalAdmin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)

	for _, tc := range []struct {
		name string
		body map[string]any
		tok  string
		want int
	}{
		{"mahal admin", map[string]any{"name": "X"}, mahalAdmin, 403},
		{"no name", map[string]any{"id": "NEW_1"}, super, 400},
		{"short id", map[string]any{"id": "AB", "name": "X"}, super, 400},
		{"bad id chars", map[string]any{"id": "NEW MAHAL", "name": "X"}, super, 400},
		{"duplicate", map[string]any{"id": tenantA, "name": "X"}, super, 409},
		{"bad dues", map[string]any{"name": "X", "settings": map[string]any{"default_monthly_dues": -5}}, super, 400},
	} {
		if r := f.do(t, "POST", "/api/v1/admin/mahals", tenantA, tc.tok, tc.body); r.status != tc.want {
			t.Errorf("%s: status %d, want %d (%v)", tc.name, r.status, tc.want, r.body)
		}
	}

	r := f.do(t, "POST", "/api/v1/admin/mahals", tenantA, super, map[string]any{
		"id": "new-mahal_7", "name": " New Mahal ",
		"contact":      map[string]any{"phone": "+91 98470 00001"},
		"settings":     map[string]any{"default_monthly_dues": 300, "autopay_allowed": true},
		"subscription": map[string]any{"plan": "standard", "monthly_fee": 499},
	})
	if r.status != 201 || r.body["id"] != "NEW-MAHAL_7" {
		t.Fatalf("create = %d %v", r.status, r.body)
	}
	m := mahalOf(t, f, "NEW-MAHAL_7")
	if m.Name != "New Mahal" || m.Settings.Currency != "INR" || m.Settings.DefaultMonthlyDues != 300 ||
		!m.Settings.AutoPayAllowed || m.Subscription.Status != domain.SubActive || m.Subscription.Plan != "STANDARD" || m.Contact.Phone != "+919847000001" {
		t.Fatalf("created mahal wrong: %+v", m)
	}
	if r := f.do(t, "POST", "/api/v1/admin/mahals", tenantA, super, map[string]any{"id": "NEW-MAHAL_7", "name": "Again"}); r.status != 409 {
		t.Fatalf("second create = %d, want 409", r.status)
	}

	// Generated id when none is given.
	r = f.do(t, "POST", "/api/v1/admin/mahals", tenantA, super, map[string]any{"name": "Auto"})
	id, _ := r.body["id"].(string)
	if r.status != 201 || !mahalIDPattern.MatchString(id) {
		t.Fatalf("auto id create = %d %v", r.status, r.body)
	}
}

func TestMahalStats(t *testing.T) {
	f := newFixture(t)
	now := time.Now().UTC()
	lastYear := now.AddDate(-1, 0, 0)
	f.txns.rows["TXN_OK"] = domain.Transaction{ID: "TXN_OK", MahalID: tenantA, MemberID: "MEM_1", Type: "MONTHLY_DUES", Amount: 500, Status: domain.TxnSuccess, CreatedAt: now, CompletedAt: &now}
	f.txns.rows["TXN_DON"] = domain.Transaction{ID: "TXN_DON", MahalID: tenantA, MemberID: "MEM_2", Type: "CONTRIBUTION", Amount: 1200, Status: domain.TxnSuccess, CreatedAt: now.Add(-time.Minute), CompletedAt: &now}
	f.txns.rows["TXN_OLD"] = domain.Transaction{ID: "TXN_OLD", MahalID: tenantA, MemberID: "MEM_1", Type: "MONTHLY_DUES", Amount: 300, Status: domain.TxnSuccess, CreatedAt: lastYear, CompletedAt: &lastYear}

	mahalAdmin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	r := f.do(t, "GET", "/api/v1/admin/mahals/"+tenantA+"/stats", tenantA, mahalAdmin, nil)
	if r.status != 200 {
		t.Fatalf("stats = %d %v", r.status, r.body)
	}
	if r.body["collected_mtd"] != 1700.0 || r.body["collected_all_time"] != 2000.0 || r.body["donations_mtd"] != 1200.0 {
		t.Fatalf("collections wrong: %v", r.body)
	}
	if r.body["total_members"] != 3.0 || r.body["timezone"] != TenantTimezone {
		t.Fatalf("member stats wrong: %v", r.body)
	}
	recent, _ := r.body["recent_payments"].([]any)
	if len(recent) != 4 { // TXN_1 (pending) included: recent activity is every attempt
		t.Fatalf("recent payments = %d: %v", len(recent), recent)
	}
	names := map[string]string{}
	for _, row := range recent {
		m := row.(map[string]any)
		names[m["id"].(string)], _ = m["member_name"].(string)
	}
	if names["TXN_OK"] != "One" || names["TXN_DON"] != "Two" {
		t.Fatalf("member names not resolved: %v", names)
	}

	// Scope: another tenant's stats are hidden from a MAHAL_ADMIN, visible to SUPER_ADMIN.
	if r := f.do(t, "GET", "/api/v1/admin/mahals/"+tenantB+"/stats", tenantA, mahalAdmin, nil); r.status != 404 {
		t.Fatalf("cross-tenant stats = %d, want 404", r.status)
	}
	super := token(t, "ADM_SUPER", domain.RoleSuperAdmin, tenantA)
	r = f.do(t, "GET", "/api/v1/admin/mahals/"+tenantB+"/stats", tenantA, super, nil)
	if r.status != 200 || r.body["total_members"] != 1.0 {
		t.Fatalf("super stats for B = %d %v", r.status, r.body)
	}
	if r := f.do(t, "GET", "/api/v1/admin/mahals/MH_NONE/stats", tenantA, super, nil); r.status != 404 {
		t.Fatalf("unknown mahal stats = %d, want 404", r.status)
	}
}

func TestPaymentsCarryMemberNames(t *testing.T) {
	f := newFixture(t)
	r := f.do(t, "GET", "/api/v1/admin/payments", tenantA, token(t, "ADM_A", domain.RoleMahalAdmin, tenantA), nil)
	rows, _ := r.body["payments"].([]any)
	if r.status != 200 || len(rows) != 1 || rows[0].(map[string]any)["member_name"] != "One" {
		t.Fatalf("payments = %d %v", r.status, r.body)
	}
}

func TestChangePassword(t *testing.T) {
	f := newFixture(t)
	tok := adminTok(t, f.admin(t, "ADM_A"))
	const oldPW, newPW = "correct horse battery", "a much longer new secret"

	for _, tc := range []struct {
		name string
		tok  string
		body map[string]any
		want int
	}{
		{"member", token(t, "MEM_1", domain.RoleMember, tenantA), map[string]any{"current_password": oldPW, "new_password": newPW}, 403},
		{"missing", tok, map[string]any{"new_password": newPW}, 400},
		{"too short", tok, map[string]any{"current_password": oldPW, "new_password": "short"}, 400},
		{"same", tok, map[string]any{"current_password": oldPW, "new_password": oldPW}, 400},
		{"wrong current", tok, map[string]any{"current_password": "wrong password!", "new_password": newPW}, 400},
		{"no password set", adminTok(t, f.admin(t, "ADM_NOPW")), map[string]any{"current_password": oldPW, "new_password": newPW}, 403},
	} {
		if r := f.do(t, "POST", "/api/v1/auth/change-password", tenantA, tc.tok, tc.body); r.status != tc.want {
			t.Errorf("%s: status %d, want %d (%v)", tc.name, r.status, tc.want, r.body)
		}
	}

	if r := f.do(t, "POST", "/api/v1/auth/change-password", tenantA, tok, map[string]any{"current_password": oldPW, "new_password": newPW}); r.status != 200 {
		t.Fatalf("change = %d %v", r.status, r.body)
	}
	if r := f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]any{"phone": "9000000001", "password": oldPW}); r.status != 401 {
		t.Fatalf("old password still works: %d", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/auth/login", "", "", map[string]any{"phone": "9000000001", "password": newPW}); r.status != 200 {
		t.Fatalf("new password login = %d %v", r.status, r.body)
	}
}

func TestAdminMemberUpdateValidation(t *testing.T) {
	f := newFixture(t)
	tok := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	for _, tc := range []struct {
		name string
		body map[string]any
		want int
	}{
		{"bad status", map[string]any{"status": "VIP"}, 400},
		{"bad phone", map[string]any{"phone": "12345"}, 400},
		{"duplicate phone", map[string]any{"phone": "9222222222"}, 409},
		{"negative dues", map[string]any{"monthly_dues_custom_amount": -1}, 400},
	} {
		if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_1", tenantA, tok, tc.body); r.status != tc.want {
			t.Errorf("%s: status %d, want %d (%v)", tc.name, r.status, tc.want, r.body)
		}
	}
	r := f.do(t, "PUT", "/api/v1/members/profile/MEM_1", tenantA, tok, map[string]any{
		"name": "One Updated", "phone": "9555555555", "status": "suspended", "family_head": false, "family_members_count": 4,
	})
	if r.status != 200 {
		t.Fatalf("update = %d %v", r.status, r.body)
	}
	m := f.members.rows["MEM_1"]
	if m.Name != "One Updated" || m.Phone != "+919555555555" || m.Status != "SUSPENDED" || m.FamilyHead || m.FamilyMembersCount != 4 {
		t.Fatalf("member not updated: %+v", m)
	}
	// Re-sending the unchanged phone is fine.
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_1", tenantA, tok, map[string]any{"phone": "+919555555555"}); r.status != 200 {
		t.Fatalf("unchanged phone = %d %v", r.status, r.body)
	}
	// A member cannot set committee fields.
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, token(t, "MEM_2", domain.RoleMember, tenantA), map[string]any{"family_head": true}); r.status != 403 {
		t.Fatalf("member family_head = %d, want 403", r.status)
	}
}

func TestCreateMemberNormalisesPhoneAndUsesMahalDefault(t *testing.T) {
	f := newFixture(t)
	tok := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	m := mahalOf(t, f, tenantA)
	m.Settings.DefaultMonthlyDues = 275
	_ = f.h.mahalRepo.Create(context.Background(), &m)

	r := f.do(t, "POST", "/api/v1/admin/members", tenantA, tok, map[string]any{"name": "New", "phone": "098470 11111"})
	if r.status != 201 || r.body["phone"] != "+919847011111" || r.body["monthly_dues_custom_amount"] != 275.0 {
		t.Fatalf("create member = %d %v", r.status, r.body)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members", tenantA, tok, map[string]any{"name": "Dup", "phone": "9847011111"}); r.status != 409 {
		t.Fatalf("duplicate phone = %d, want 409", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members", tenantA, tok, map[string]any{"name": "Bad", "phone": "12345"}); r.status != 400 {
		t.Fatalf("bad phone = %d, want 400", r.status)
	}
}
