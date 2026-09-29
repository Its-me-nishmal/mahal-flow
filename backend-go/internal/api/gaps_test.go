package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/pg"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/xuri/excelize/v2"
	"go.mongodb.org/mongo-driver/v2/bson"
)

// ---------------------------------------------------------------------------
// Extra fakes
// ---------------------------------------------------------------------------

type fakeImports struct{ rows map[string]domain.ImportBatch }

func (f *fakeImports) Create(_ contextT, b *domain.ImportBatch) error { f.rows[b.ID] = *b; return nil }
func (f *fakeImports) Get(_ contextT, mahalID, id string) (*domain.ImportBatch, error) {
	b, ok := f.rows[id]
	if !ok || b.MahalID != mahalID || !b.ExpiresAt.After(time.Now()) {
		return nil, nil
	}
	return &b, nil
}
func (f *fakeImports) ClaimForCommit(_ contextT, mahalID, id string, _ time.Duration) (*domain.ImportBatch, error) {
	b, ok := f.rows[id]
	if !ok || b.MahalID != mahalID || b.Status != repository.ImportStatusPreview {
		return nil, nil
	}
	b.Status = repository.ImportStatusCommitting
	f.rows[id] = b
	return &b, nil
}
func (f *fakeImports) MarkCommitted(_ contextT, _, id string, imported, skipped int, rows []domain.ImportRow) error {
	b := f.rows[id]
	b.Status, b.Imported, b.Skipped, b.Rows = repository.ImportStatusCommitted, imported, skipped, rows
	f.rows[id] = b
	return nil
}
func (f *fakeImports) EnsureIndexes(contextT) error { return nil }

type fakeMandates struct{ rows map[string]domain.Mandate }

func (f *fakeMandates) Create(_ contextT, m *domain.Mandate) error { f.rows[m.ID] = *m; return nil }
func (f *fakeMandates) GetByID(_ contextT, id string) (*domain.Mandate, error) {
	m, ok := f.rows[id]
	if !ok {
		return nil, nil
	}
	return &m, nil
}
func (f *fakeMandates) GetActiveByMember(_ contextT, mahalID, memberID string) (*domain.Mandate, error) {
	for _, m := range f.rows {
		if m.MahalID == mahalID && m.MemberID == memberID && (m.Status == "ACTIVE" || m.Status == "PENDING_AUTHORIZATION") {
			mm := m
			return &mm, nil
		}
	}
	return nil, nil
}
func (f *fakeMandates) FindDue(contextT, time.Time) ([]domain.Mandate, error) { return nil, nil }
func (f *fakeMandates) Update(_ contextT, id string, fields bson.M) error {
	m := f.rows[id]
	if v, ok := fields["status"].(string); ok {
		m.Status = v
	}
	if v, ok := fields["auth_payu_id"].(string); ok {
		m.AuthPayUID = v
	}
	f.rows[id] = m
	return nil
}

const testPayUKey, testPayUSalt = "TESTKEY", "TESTSALT"

func gapFixture(t *testing.T) *fixture {
	f := newFixture(t)
	f.h.SetImportBatches(&fakeImports{rows: map[string]domain.ImportBatch{}})
	f.h.mandateRepo = &fakeMandates{rows: map[string]domain.Mandate{
		"MNDAAAA": {ID: "MNDAAAA", MahalID: tenantA, MemberID: "MEM_1", Status: "PENDING_AUTHORIZATION", SIDetails: `{"billingAmount":"500.00"}`},
		"MNDBBBB": {ID: "MNDBBBB", MahalID: tenantA, MemberID: "MEM_2", Status: "PENDING_AUTHORIZATION"},
	}}
	// Simulated PayU (TestMode): nothing leaves the process.
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, TestMode: true})
	return f
}

func (f *fixture) upload(t *testing.T, bearer, filename string, content []byte) resp {
	t.Helper()
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	fw, _ := w.CreateFormFile("file", filename)
	_, _ = fw.Write(content)
	_ = w.Close()
	req := httptest.NewRequest("POST", "/api/v1/admin/excel/upload-preview", &buf)
	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Set("X-Tenant-ID", tenantA)
	req.Header.Set("Authorization", "Bearer "+bearer)
	res, err := f.app.Test(req, 10000)
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := io.ReadAll(res.Body)
	out := resp{status: res.StatusCode, body: map[string]any{}}
	_ = json.Unmarshal(raw, &out.body)
	return out
}

// ---------------------------------------------------------------------------
// 1. Excel import
// ---------------------------------------------------------------------------

func TestParseImportRowsValidation(t *testing.T) {
	records := [][]string{
		{"Name", "Phone", "House Name", "Monthly Dues", "Family Head", "Email"},
		{"Kareem", "98471 12233", "Thottathil", "500", "yes", "k@example.com"},
		{"Usman", "+91 9847445566", "", "", "no", ""},
		{"Dup in file", "9847112233", "", "", "", ""},
		{"Existing", "9111111111", "", "", "", ""},
		{"", "12345", "", "abc", "maybe", "not-an-email"},
		{"", "", "", "", "", ""}, // blank line skipped
		{"Zero prefix", "09847000001", "", "300", "", ""},
	}
	rows, err := parseImportRows(records, map[string]bool{"+919111111111": true})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 6 {
		t.Fatalf("want 6 data rows, got %d", len(rows))
	}
	want := []struct {
		status, phone string
		row           int
	}{
		{ImportRowValid, "+919847112233", 2},
		{ImportRowValid, "+919847445566", 3},
		{ImportRowDuplicate, "+919847112233", 4},
		{ImportRowDuplicate, "+919111111111", 5},
		{ImportRowInvalid, "12345", 6},
		{ImportRowValid, "+919847000001", 8},
	}
	for i, w := range want {
		if rows[i].Status != w.status || rows[i].Phone != w.phone || rows[i].Row != w.row {
			t.Errorf("row %d: want %s %s @%d, got %s %s @%d %v", i, w.status, w.phone, w.row, rows[i].Status, rows[i].Phone, rows[i].Row, rows[i].Errors)
		}
	}
	if !rows[0].FamilyHead || rows[0].MonthlyDues != 500 || rows[0].HouseName != "Thottathil" {
		t.Errorf("row 1 fields not parsed: %+v", rows[0])
	}
	if len(rows[4].Errors) < 4 {
		t.Errorf("invalid row should list every problem, got %v", rows[4].Errors)
	}
	if v, d, inv := countImportRows(rows); v != 3 || d != 2 || inv != 1 {
		t.Errorf("counts: %d %d %d", v, d, inv)
	}

	if _, err := parseImportRows([][]string{{"name", "house"}, {"a", "b"}}, nil); err == nil || !strings.Contains(err.Error(), "phone") {
		t.Errorf("missing phone column must be rejected, got %v", err)
	}
}

func TestExcelImportPreviewAndIdempotentCommit(t *testing.T) {
	f := gapFixture(t)
	admin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	csv := "name,phone,house_name,monthly_dues\nKareem,9847112233,Thottathil,500\nUsman,9847445566,,\nDup,9111111111,,\nBad,123,,\n"

	r := f.upload(t, admin, "members.csv", []byte(csv))
	if r.status != 200 {
		t.Fatalf("preview: %d %v", r.status, r.body)
	}
	if r.body["total_rows"] != 4.0 || r.body["valid_rows"] != 2.0 || r.body["duplicate_rows"] != 1.0 || r.body["invalid_rows"] != 1.0 {
		t.Fatalf("preview counts wrong: %v", r.body)
	}
	batchID, _ := r.body["batch_id"].(string)
	if batchID == "" || r.body["upload_id"] != batchID {
		t.Fatalf("batch id missing: %v", r.body)
	}
	before := len(f.members.rows)

	// Members cannot commit, other tenants cannot see the batch.
	if c := f.do(t, "POST", "/api/v1/admin/excel/commit-import", tenantA, token(t, "MEM_1", domain.RoleMember, tenantA), map[string]string{"batch_id": batchID}); c.status != 403 {
		t.Fatalf("member commit: want 403, got %d", c.status)
	}
	if c := f.do(t, "POST", "/api/v1/admin/excel/commit-import", tenantB, token(t, "ADM_B", domain.RoleMahalAdmin, tenantB), map[string]string{"batch_id": batchID}); c.status != 404 {
		t.Fatalf("cross-tenant commit: want 404, got %d %v", c.status, c.body)
	}

	c := f.do(t, "POST", "/api/v1/admin/excel/commit-import", tenantA, admin, map[string]string{"batch_id": batchID})
	if c.status != 200 || c.body["status"] != "COMPLETED" || c.body["imported"] != 2.0 || c.body["skipped"] != 2.0 {
		t.Fatalf("commit: %d %v", c.status, c.body)
	}
	if len(f.members.rows) != before+2 {
		t.Fatalf("want 2 new members, got %d", len(f.members.rows)-before)
	}
	m, _ := f.members.GetByPhone(nil, tenantA, "+919847112233")
	if m == nil || m.Status != "ACTIVE" || m.HouseName != "Thottathil" || m.MonthlyDuesCustomAmount != 500 || m.ImportBatchID != batchID {
		t.Fatalf("imported member wrong: %+v", m)
	}

	// Second commit: no-op with the original counts.
	c2 := f.do(t, "POST", "/api/v1/admin/excel/commit-import", tenantA, admin, map[string]string{"upload_id": batchID})
	if c2.status != 200 || c2.body["status"] != "ALREADY_COMMITTED" || c2.body["imported"] != 2.0 {
		t.Fatalf("second commit: %d %v", c2.status, c2.body)
	}
	if len(f.members.rows) != before+2 {
		t.Fatalf("second commit must not insert members")
	}
	if c := f.do(t, "POST", "/api/v1/admin/excel/commit-import", tenantA, admin, map[string]string{"batch_id": "IMP_nope"}); c.status != 404 {
		t.Fatalf("unknown batch: want 404, got %d", c.status)
	}
}

func TestExcelImportReadsXLSXAndRejectsLegacyXLS(t *testing.T) {
	f := gapFixture(t)
	admin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)

	x := excelize.NewFile()
	_ = x.SetSheetRow("Sheet1", "A1", &[]any{"name", "phone", "house_name", "monthly_dues"})
	_ = x.SetSheetRow("Sheet1", "A2", &[]any{"Ayesha", "9847556677", "Kunnath", 450})
	var buf bytes.Buffer
	if err := x.Write(&buf); err != nil {
		t.Fatal(err)
	}
	r := f.upload(t, admin, "members.xlsx", buf.Bytes())
	if r.status != 200 || r.body["valid_rows"] != 1.0 {
		t.Fatalf("xlsx preview: %d %v", r.status, r.body)
	}
	rows, _ := r.body["preview_rows"].([]any)
	row, _ := rows[0].(map[string]any)
	if row["phone"] != "+919847556677" || row["monthly_dues"] != 450.0 {
		t.Fatalf("xlsx row: %v", row)
	}

	ole := append([]byte{0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, make([]byte, 64)...)
	if r := f.upload(t, admin, "old.xls", ole); r.status != 400 {
		t.Fatalf("legacy xls: want 400, got %d %v", r.status, r.body)
	}
}

// ---------------------------------------------------------------------------
// 9. Month-to-date in Asia/Kolkata
// ---------------------------------------------------------------------------

func TestMonthToDateUsesKolkata(t *testing.T) {
	loc := tenantLocation()
	// 2026-09-30 19:00 UTC is 2026-10-01 00:30 IST: already October.
	now := time.Date(2026, 9, 30, 19, 0, 0, 0, time.UTC)
	from, to := monthToDate(now, loc)
	if want := time.Date(2026, 9, 30, 18, 30, 0, 0, time.UTC); !from.Equal(want) {
		t.Fatalf("MTD start: want %v, got %v", want, from.UTC())
	}
	if !to.Equal(now) {
		t.Fatalf("MTD end should be now")
	}
	// 18:00 UTC the same day is still 23:30 IST on the 30th: September.
	from, _ = monthToDate(time.Date(2026, 9, 30, 18, 0, 0, 0, time.UTC), loc)
	if want := time.Date(2026, 8, 31, 18, 30, 0, 0, time.UTC); !from.Equal(want) {
		t.Fatalf("MTD start (Sept): want %v, got %v", want, from.UTC())
	}
}

func TestAdminDashboardMTDAndReportPeriods(t *testing.T) {
	f := gapFixture(t)
	admin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	loc := tenantLocation()
	monthStart, _ := monthToDate(time.Now(), loc)
	thisMonth := monthStart.Add(time.Hour)
	lastMonth := monthStart.Add(-time.Hour)
	f.txns.rows["T_NOW"] = domain.Transaction{ID: "T_NOW", MahalID: tenantA, Type: "MONTHLY_DUES", Amount: 500, Status: domain.TxnSuccess, CompletedAt: &thisMonth}
	f.txns.rows["T_OLD"] = domain.Transaction{ID: "T_OLD", MahalID: tenantA, Type: "CONTRIBUTION", Amount: 1000, Status: domain.TxnSuccess, CompletedAt: &lastMonth}
	f.txns.rows["T_REF"] = domain.Transaction{ID: "T_REF", MahalID: tenantA, Type: "MONTHLY_DUES", Amount: 700, Status: domain.TxnRefunded, CompletedAt: &thisMonth}
	f.txns.rows["T_B"] = domain.Transaction{ID: "T_B", MahalID: tenantB, Type: "MONTHLY_DUES", Amount: 9999, Status: domain.TxnSuccess, CompletedAt: &thisMonth}

	r := f.do(t, "GET", "/api/v1/admin/dashboard", tenantA, admin, nil)
	if r.status != 200 || r.body["total_collected_mtd"] != 500.0 || r.body["total_collected_all_time"] != 1500.0 || r.body["timezone"] != "Asia/Kolkata" {
		t.Fatalf("dashboard: %d %v", r.status, r.body)
	}

	month := lastMonth.In(loc).Format("2006-01")
	r = f.do(t, "GET", "/api/v1/admin/reports/financial?month="+month, tenantA, admin, nil)
	sum, _ := r.body["summary"].(map[string]any)
	if r.status != 200 || r.body["period"] != month || sum["total_collected"] != 1000.0 || sum["donations"] != 1000.0 {
		t.Fatalf("report month: %d %v", r.status, r.body)
	}
	day := thisMonth.In(loc).Format("2006-01-02")
	r = f.do(t, "POST", "/api/v1/admin/reports/financial/query", tenantA, admin, map[string]string{"from": day, "to": day})
	sum, _ = r.body["summary"].(map[string]any)
	if r.status != 200 || r.body["period"] != "CUSTOM" || sum["total_collected"] != 500.0 {
		t.Fatalf("report custom: %d %v", r.status, r.body)
	}
	if r := f.do(t, "GET", "/api/v1/admin/reports/financial?month=2026-13", tenantA, admin, nil); r.status != 400 {
		t.Fatalf("bad month: want 400, got %d", r.status)
	}
	if r := f.do(t, "GET", "/api/v1/admin/reports/financial?from=2026-09-10&to=2026-09-01", tenantA, admin, nil); r.status != 400 {
		t.Fatalf("from after to: want 400, got %d", r.status)
	}
}

// ---------------------------------------------------------------------------
// 7/11. Alerts: MEMBER audience, type, unknown audience
// ---------------------------------------------------------------------------

func TestMemberAudienceAlertTargeting(t *testing.T) {
	f := gapFixture(t)
	admin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)

	r := f.do(t, "POST", "/api/v1/admin/alerts", tenantA, admin, map[string]any{
		"title": "Dues", "description": "Please pay", "audience": "MEMBER", "member_ids": []string{"MEM_1"}, "type": "DUES_REMINDER",
	})
	if r.status != 201 {
		t.Fatalf("create MEMBER alert: %d %v", r.status, r.body)
	}
	alertID := r.body["alert"].(map[string]any)["id"].(string)

	seen := func(member string) (bool, string) {
		res := f.do(t, "GET", "/api/v1/member/alerts", tenantA, token(t, member, domain.RoleMember, tenantA), nil)
		for _, a := range res.body["alerts"].([]any) {
			m := a.(map[string]any)
			if m["id"] == alertID {
				if _, leaked := m["member_ids"]; leaked {
					t.Errorf("recipient list must not be shown to members")
				}
				return true, m["type"].(string)
			}
		}
		return false, ""
	}
	if ok, typ := seen("MEM_1"); !ok || typ != "DUES_REMINDER" {
		t.Fatalf("recipient must see the alert with its type, got %v %q", ok, typ)
	}
	if ok, _ := seen("MEM_2"); ok {
		t.Fatalf("non-recipient must not see a MEMBER alert")
	}

	for name, body := range map[string]map[string]any{
		"unknown audience":      {"title": "x", "description": "y", "audience": "EVERYONE_PLEASE"},
		"MEMBER without ids":    {"title": "x", "description": "y", "audience": "MEMBER"},
		"other tenant's member": {"title": "x", "description": "y", "audience": "MEMBER", "member_ids": []string{"MEM_B"}},
		"unknown type":          {"title": "x", "description": "y", "type": "SPAM"},
		"ids with ALL audience": {"title": "x", "description": "y", "audience": "ALL", "member_ids": []string{"MEM_1"}},
	} {
		if r := f.do(t, "POST", "/api/v1/admin/alerts", tenantA, admin, body); r.status != 400 {
			t.Errorf("%s: want 400, got %d %v", name, r.status, r.body)
		}
	}
	n := len(f.alerts.rows)
	f.do(t, "POST", "/api/v1/admin/alerts", tenantA, admin, map[string]any{"title": "x", "description": "y", "audience": "BOGUS"})
	if len(f.alerts.rows) != n {
		t.Fatalf("an unknown audience must not be stored (it used to broadcast)")
	}

	// Default types; legacy rows get a derived type.
	r = f.do(t, "POST", "/api/v1/admin/alerts", tenantA, admin, map[string]any{"title": "Late", "description": "d", "audience": "OVERDUE_ONLY"})
	if r.body["alert"].(map[string]any)["type"] != "DUES_REMINDER" {
		t.Fatalf("OVERDUE_ONLY default type: %v", r.body)
	}
	r = f.do(t, "POST", "/api/v1/admin/alerts", tenantA, admin, map[string]any{"title": "Eid", "description": "d"})
	if r.body["alert"].(map[string]any)["type"] != "ANNOUNCEMENT" {
		t.Fatalf("default type: %v", r.body)
	}
	// A stored alert with an unrecognised audience is hidden, not broadcast.
	f.alerts.rows = append(f.alerts.rows, domain.SystemAlert{ID: "ALT_WEIRD", MahalID: tenantA, Audience: "SOMETHING", Title: "?"})
	res := f.do(t, "GET", "/api/v1/member/alerts", tenantA, token(t, "MEM_2", domain.RoleMember, tenantA), nil)
	for _, a := range res.body["alerts"].([]any) {
		if a.(map[string]any)["id"] == "ALT_WEIRD" {
			t.Fatalf("unknown stored audience must fail closed")
		}
	}
}

func TestReceiptAlertIsPerMember(t *testing.T) {
	f := gapFixture(t)
	f.h.NotifyReceiptAlert(nil, &domain.Receipt{ReceiptNumber: "R-9", MahalID: tenantA, MemberID: "MEM_2", Amount: 500, PaymentType: "MONTHLY_DUES", PaidMonths: []string{"2026-09"}})
	last := f.alerts.rows[len(f.alerts.rows)-1]
	if last.Audience != domain.AudienceMember || len(last.MemberIDs) != 1 || last.MemberIDs[0] != "MEM_2" || last.Type != domain.AlertTypePaymentReceived {
		t.Fatalf("receipt alert: %+v", last)
	}
}

// ---------------------------------------------------------------------------
// 8. Approve / reject / revert
// ---------------------------------------------------------------------------

func TestRevertApprovalRules(t *testing.T) {
	f := gapFixture(t)
	admin := token(t, "ADM_A", domain.RoleMahalAdmin, tenantA)
	f.members.rows["MEM_P1"] = domain.Member{ID: "MEM_P1", MahalID: tenantA, Name: "P1", Phone: "+919500000001", Status: MemberStatusPending}
	f.members.rows["MEM_P2"] = domain.Member{ID: "MEM_P2", MahalID: tenantA, Name: "P2", Phone: "+919500000002", Status: MemberStatusPending}
	f.members.rows["MEM_P3"] = domain.Member{ID: "MEM_P3", MahalID: tenantA, Name: "P3", Phone: "+919500000003", Status: MemberStatusPending}

	// Approve then undo.
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P1/approve", tenantA, admin, nil); r.status != 200 || r.body["revertible_until"] == nil {
		t.Fatalf("approve: %d %v", r.status, r.body)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P1/approve", tenantA, admin, nil); r.status != 409 {
		t.Fatalf("approving an active member: want 409, got %d", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P1/revert-approval", tenantA, admin, nil); r.status != 200 || f.members.rows["MEM_P1"].Status != MemberStatusPending {
		t.Fatalf("revert approve: %d %v %s", r.status, r.body, f.members.rows["MEM_P1"].Status)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P1/revert-approval", tenantA, admin, nil); r.status != 409 {
		t.Fatalf("nothing left to revert: want 409, got %d", r.status)
	}

	// Reject is a soft status now, and a rejected phone cannot sign in.
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P2/reject", tenantA, admin, nil); r.status != 200 {
		t.Fatalf("reject: %d %v", r.status, r.body)
	}
	if m, ok := f.members.rows["MEM_P2"]; !ok || m.Status != MemberStatusRejected {
		t.Fatalf("reject must keep the record as REJECTED, got %+v", m)
	}
	r := f.do(t, "POST", "/api/v1/auth/resolve", tenantA, "", map[string]string{"id_token": "valid:+919500000002"})
	if r.body["status"] != "REJECTED" || r.body["token"] != nil {
		t.Fatalf("rejected member resolve: %v", r.body)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P2/revert-approval", tenantA, admin, nil); r.status != 200 || f.members.rows["MEM_P2"].Status != MemberStatusPending {
		t.Fatalf("revert reject: %d %v", r.status, r.body)
	}

	// Approved member who has paid: no undo.
	f.do(t, "POST", "/api/v1/admin/members/MEM_P3/approve", tenantA, admin, nil)
	f.txns.rows["T_P3"] = domain.Transaction{ID: "T_P3", MahalID: tenantA, MemberID: "MEM_P3", Amount: 500, Status: domain.TxnSuccess}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P3/revert-approval", tenantA, admin, nil); r.status != 409 {
		t.Fatalf("paid member revert: want 409, got %d %v", r.status, r.body)
	}
	delete(f.txns.rows, "T_P3")

	// Outside the window: no undo.
	m := f.members.rows["MEM_P3"]
	old := time.Now().Add(-ApprovalRevertWindow - time.Minute)
	m.ApprovalDecidedAt = &old
	f.members.rows["MEM_P3"] = m
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P3/revert-approval", tenantA, admin, nil); r.status != 409 {
		t.Fatalf("expired window: want 409, got %d", r.status)
	}
	// Members cannot revert; other tenants get 404.
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P3/revert-approval", tenantA, token(t, "MEM_1", domain.RoleMember, tenantA), nil); r.status != 403 {
		t.Fatalf("member revert: want 403, got %d", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/admin/members/MEM_P3/revert-approval", tenantB, token(t, "ADM_B", domain.RoleMahalAdmin, tenantB), nil); r.status != 404 {
		t.Fatalf("cross-tenant revert: want 404, got %d", r.status)
	}
}

// ---------------------------------------------------------------------------
// 5. Receipts: new fields, old hashes still verify, refund overlay
// ---------------------------------------------------------------------------

func TestReceiptNewFieldsKeepHashChainValid(t *testing.T) {
	f := gapFixture(t)
	prev := "0000000000000000000000000000000000000000000000000000000000000000"
	oldHash := domain.CalculateReceiptHash("RCPT-OLD", tenantA, "MEM_1", 500, prev)
	newHash := domain.CalculateReceiptHash("RCPT-NEW", tenantA, "MEM_1", 250, oldHash)
	done := time.Now().UTC()
	f.receipts.rows = append(f.receipts.rows,
		// Issued before the new fields existed.
		domain.Receipt{ID: "RO", ReceiptNumber: "RCPT-OLD", MahalID: tenantA, MemberID: "MEM_1", TransactionID: "T_OLD", Amount: 500, PreviousReceiptHash: prev, ReceiptHash: oldHash},
		// Issued with them.
		domain.Receipt{ID: "RN", ReceiptNumber: "RCPT-NEW", MahalID: tenantA, MemberID: "MEM_1", TransactionID: "T_NEW", Amount: 250, PreviousReceiptHash: oldHash, ReceiptHash: newHash,
			Status: domain.ReceiptStatusSuccess, Gateway: "PAYU", PaymentMethod: "UPI", Fund: "ZAKAT", Note: "In memory"},
	)
	f.txns.rows["T_OLD"] = domain.Transaction{ID: "T_OLD", MahalID: tenantA, MemberID: "MEM_1", Gateway: "CASH", Status: domain.TxnSuccess}
	f.txns.rows["T_NEW"] = domain.Transaction{ID: "T_NEW", MahalID: tenantA, MemberID: "MEM_1", Gateway: "PAYU", Purpose: "ZAKAT", Status: domain.TxnRefunded, CompletedAt: &done}
	member := token(t, "MEM_1", domain.RoleMember, tenantA)

	for _, n := range []string{"RCPT-OLD", "RCPT-NEW"} {
		r := f.do(t, "GET", "/api/v1/receipts/"+n+"/verify", tenantA, member, nil)
		if r.status != 200 || r.body["cryptographic_valid"] != true {
			t.Fatalf("%s must still verify: %d %v", n, r.status, r.body)
		}
	}
	// The descriptive fields are not hash inputs.
	if domain.CalculateReceiptHash("RCPT-NEW", tenantA, "MEM_1", 250, oldHash) != newHash {
		t.Fatal("hash must depend only on the original fields")
	}

	r := f.do(t, "GET", "/api/v1/receipts/RCPT-NEW", tenantA, member, nil)
	if r.body["status"] != "REFUNDED" || r.body["refunded_at"] == nil || r.body["gateway"] != "PAYU" || r.body["payment_method"] != "UPI" || r.body["fund"] != "ZAKAT" || r.body["note"] != "In memory" {
		t.Fatalf("new receipt fields / refund overlay: %v", r.body)
	}
	r = f.do(t, "GET", "/api/v1/receipts/RCPT-OLD", tenantA, member, nil)
	if r.body["status"] != "SUCCESS" || r.body["gateway"] != "CASH" || r.body["payment_method"] != "CASH" {
		t.Fatalf("old receipt should get derived fields: %v", r.body)
	}
	// The stored receipt itself was never modified.
	for _, rc := range f.receipts.rows {
		if rc.ReceiptNumber == "RCPT-NEW" && rc.Status != domain.ReceiptStatusSuccess {
			t.Fatal("stored receipt must stay immutable")
		}
	}
}

func TestNormalizePaymentMode(t *testing.T) {
	for in, want := range map[string]string{"UPI": "UPI", "CC": "CARD", "dc": "CARD", "NB": "NETBANKING", "PPI": "WALLET", "": "", "CASH": "CASH"} {
		if got := domain.NormalizePaymentMode(in); got != want {
			t.Errorf("%q: want %q, got %q", in, want, got)
		}
	}
}

// ---------------------------------------------------------------------------
// 3. Order ids
// ---------------------------------------------------------------------------

func TestOrderIDNormalization(t *testing.T) {
	for in, want := range map[string]string{
		"ORDTXNabc123":  "TXNabc123",
		"ORD_TXNabc123": "TXNabc123",
		"TXNabc123":     "TXNabc123",
		" ORDTXN1 ":     "TXN1",
		"ORD":           "ORD",
	} {
		if got := txnIDFromOrderID(in); got != want {
			t.Errorf("%q: want %q, got %q", in, want, got)
		}
	}
	if orderIDForTxn(&domain.Transaction{ID: "TXN1"}) != "ORDTXN1" {
		t.Error("canonical order id is ORD+id")
	}

	f := gapFixture(t)
	member := token(t, "MEM_1", domain.RoleMember, tenantA)
	f.txns.rows["TXN_OK"] = domain.Transaction{ID: "TXN_OK", MahalID: tenantA, MemberID: "MEM_1", Amount: 500, Status: domain.TxnSuccess}
	for _, id := range []string{"TXN_OK", "ORDTXN_OK", "ORD_TXN_OK"} {
		r := f.do(t, "GET", "/api/v1/payments/"+id+"/status", tenantA, member, nil)
		if r.status != 200 || r.body["transaction_id"] != "TXN_OK" || r.body["status"] != "SUCCESS" {
			t.Fatalf("status via %s: %d %v", id, r.status, r.body)
		}
	}
	for _, id := range []string{"TXN_1", "ORDTXN_1", "ORD_TXN_1"} {
		d := f.do(t, "GET", "/api/v1/payments/payu-checkout-data/"+id, tenantA, member, nil)
		if d.status != 200 || d.body["txnid"] != "ORDTXN_1" {
			t.Fatalf("checkout data via %s must use the canonical txnid: %d %v", id, d.status, d.body)
		}
	}
}

// ---------------------------------------------------------------------------
// C. Hash endpoint restriction
// ---------------------------------------------------------------------------

func TestPayUHashEndpointRestricted(t *testing.T) {
	f := gapFixture(t)
	member := token(t, "MEM_1", domain.RoleMember, tenantA)
	hash := func(body map[string]string) resp {
		return f.do(t, "POST", "/api/v1/payments/payu-generate-hash", tenantA, member, body)
	}

	// The payment hash for the caller's own transaction, exactly as the SDK
	// builds it from GET /payments/payu-checkout-data.
	d := f.do(t, "GET", "/api/v1/payments/payu-checkout-data/ORDTXN_1", tenantA, member, nil)
	p := d.body["params"].(map[string]any)
	s := func(k string) string { v, _ := p[k].(string); return v }
	own := fmt.Sprintf("%s|%s|%s|%s|%s|%s|%s|%s|%s||||||||", s("key"), s("txnid"), s("amount"), s("productinfo"), s("firstname"), s("email"), s("udf1"), s("udf2"), s("udf3"))
	r := hash(map[string]string{"hash_name": "payment", "hash_string": own})
	if r.status != 200 || r.body["hash"] != d.body["hash"] {
		t.Fatalf("own payment hash: %d %v (want %v)", r.status, r.body, d.body["hash"])
	}

	// Tampered amount on the caller's own transaction.
	tampered := strings.Replace(own, "|500.00|", "|1.00|", 1)
	if r := hash(map[string]string{"hash_name": "payment", "hash_string": tampered}); r.status != 403 {
		t.Fatalf("tampered amount: want 403, got %d", r.status)
	}
	// Someone else's transaction (other tenant).
	other := strings.Replace(own, "ORDTXN_1", "ORDTXN_B", 1)
	if r := hash(map[string]string{"hash_name": "payment", "hash_string": other}); r.status != 403 {
		t.Fatalf("other member's transaction: want 403, got %d", r.status)
	}
	// Dangerous postservice commands.
	for _, cmd := range []string{"cancel_refund_transaction", "si_transaction", "verify_payment", "pre_debit_notification"} {
		if r := hash(map[string]string{"hash_name": cmd, "hash_string": testPayUKey + "|" + cmd + "|12345|"}); r.status != 403 {
			t.Errorf("%s: want 403, got %d", cmd, r.status)
		}
	}
	// Arbitrary strings / another merchant key.
	for _, str := range []string{"hello world", "OTHERKEY|vas_for_mobile_sdk|default|", testPayUKey + "|vas_for_mobile_sdk|default|extra"} {
		if r := hash(map[string]string{"hash_name": "x", "hash_string": str}); r.status != 403 {
			t.Errorf("%q: want 403, got %d", str, r.status)
		}
	}
	// Allowlisted SDK read commands.
	if r := hash(map[string]string{"hash_name": "vas_for_mobile_sdk", "hash_string": testPayUKey + "|vas_for_mobile_sdk|default|"}); r.status != 200 {
		t.Fatalf("vas_for_mobile_sdk: want 200, got %d %v", r.status, r.body)
	}
	// User-bound command: own credential only.
	if r := hash(map[string]string{"hash_name": "payment_related_details_for_mobile_sdk", "hash_string": testPayUKey + "|payment_related_details_for_mobile_sdk|" + testPayUKey + ":MEM_1|"}); r.status != 200 {
		t.Fatalf("own user credential: want 200, got %d", r.status)
	}
	if r := hash(map[string]string{"hash_name": "payment_related_details_for_mobile_sdk", "hash_string": testPayUKey + "|payment_related_details_for_mobile_sdk|" + testPayUKey + ":MEM_2|"}); r.status != 403 {
		t.Fatalf("someone else's user credential: want 403, got %d", r.status)
	}
	// V2: only allowlisted names for an owned txn.
	if r := hash(map[string]string{"hash_name": "anything", "hash_type": "V2", "hash_string": "x", "txnid": "ORDTXN_1"}); r.status != 403 {
		t.Fatalf("V2 unknown name: want 403, got %d", r.status)
	}
	if r := hash(map[string]string{"hash_name": "get_checkout_details", "hash_type": "V2", "hash_string": "x", "txnid": "ORDTXN_B"}); r.status != 403 {
		t.Fatalf("V2 other's txn: want 403, got %d", r.status)
	}

	// SI consent hash for the caller's own mandate, with its si_details.
	mandateData := f.do(t, "GET", "/api/v1/payments/payu-checkout-data/MNDAAAA", tenantA, member, nil)
	mp := mandateData.body["params"].(map[string]any)
	ms := func(k string) string { v, _ := mp[k].(string); return v }
	si := fmt.Sprintf("%s|%s|%s|%s|%s|%s|%s|%s|%s||||||||%s", ms("key"), ms("txnid"), ms("amount"), ms("productinfo"), ms("firstname"), ms("email"), ms("udf1"), ms("udf2"), ms("udf3"), ms("si_details"))
	if r := hash(map[string]string{"hash_name": "payment", "hash_string": si}); r.status != 200 {
		t.Fatalf("own SI hash: want 200, got %d %v", r.status, r.body)
	}
	if r := hash(map[string]string{"hash_name": "payment", "hash_string": strings.Replace(si, "MNDAAAA", "MNDBBBB", -1)}); r.status != 403 {
		t.Fatalf("other member's mandate: want 403, got %d", r.status)
	}
}

// ---------------------------------------------------------------------------
// B / D. Mandate confirm, signed checkout page, gateways
// ---------------------------------------------------------------------------

func TestSignedCheckoutPage(t *testing.T) {
	f := gapFixture(t)
	f.members.rows["MEM_1"] = domain.Member{ID: "MEM_1", MahalID: tenantA, Name: "Kareem Hassan Thottathil", Phone: "+919111111111", Status: "ACTIVE"}
	page := fiber.New()
	page.Get("/api/v1/payments/payu-checkout/:orderId", f.h.RenderPayUCheckoutPage)
	f.h.SetPublicBaseURL("http://example.test")

	link := f.h.signedCheckoutURL("ORDTXN_1")
	if !strings.HasPrefix(link, "http://example.test/api/v1/payments/payu-checkout/ORDTXN_1?") {
		t.Fatalf("link: %s", link)
	}
	get := func(path string) (int, string) {
		res, err := page.Test(httptest.NewRequest("GET", path, nil), 10000)
		if err != nil {
			t.Fatal(err)
		}
		b, _ := io.ReadAll(res.Body)
		return res.StatusCode, string(b)
	}
	if code, _ := get("/api/v1/payments/payu-checkout/ORDTXN_1"); code != 403 {
		t.Fatalf("unsigned page: want 403, got %d", code)
	}
	code, body := get(strings.TrimPrefix(link, "http://example.test"))
	if code != 200 {
		t.Fatalf("signed page: %d %s", code, body)
	}
	if strings.Contains(body, "Hassan") || !strings.Contains(body, `value="Kareem"`) {
		t.Fatalf("page must carry the first name only")
	}
	// A signature for one order does not open another.
	q := link[strings.Index(link, "?"):]
	if code, _ := get("/api/v1/payments/payu-checkout/ORDTXN_B" + q); code != 403 {
		t.Fatalf("signature reuse on another order: want 403, got %d", code)
	}
	exp := time.Now().Add(-time.Minute).Unix()
	if validCheckoutSignature("ORDTXN_1", fmt.Sprint(exp), checkoutSignature("ORDTXN_1", exp), time.Now()) {
		t.Fatal("expired signature accepted")
	}
}

func TestConfirmMandateAndGateways(t *testing.T) {
	f := gapFixture(t)
	member := token(t, "MEM_1", domain.RoleMember, tenantA)
	// Simulated gateway: activates (nothing to verify with).
	r := f.do(t, "POST", "/api/v1/autopay/mandate/confirm", tenantA, member, map[string]string{"mandate_id": "MNDAAAA"})
	if r.status != 200 || r.body["status"] != "ACTIVE" {
		t.Fatalf("confirm: %d %v", r.status, r.body)
	}
	// Idempotent; another member's mandate is not found.
	if r := f.do(t, "POST", "/api/v1/autopay/mandate/confirm", tenantA, member, map[string]string{"mandate_id": "MNDAAAA"}); r.status != 200 {
		t.Fatalf("re-confirm: %d", r.status)
	}
	if r := f.do(t, "POST", "/api/v1/autopay/mandate/confirm", tenantA, member, map[string]string{"mandate_id": "MNDBBBB"}); r.status != 404 {
		t.Fatalf("other member's mandate: want 404, got %d", r.status)
	}
	st := f.do(t, "GET", "/api/v1/autopay/mandate/status", tenantA, member, nil)
	if st.body["mandate_id"] != "MNDAAAA" || st.body["active"] != true {
		t.Fatalf("status from repo: %v", st.body)
	}

	// Live gateway that cannot be reached: must not activate on the app's word.
	f.h.pgClient = pg.NewClient(pg.Config{APIKey: testPayUKey, Salt: testPayUSalt, InfoBaseURL: "http://127.0.0.1:1", Timeout: time.Second})
	r = f.do(t, "POST", "/api/v1/autopay/mandate/confirm", tenantA, token(t, "MEM_2", domain.RoleMember, tenantA),
		map[string]string{"mandate_id": "MNDBBBB", "gateway_payment_id": "FORGED"})
	if r.status == 200 || f.h.mandateRepo.(*fakeMandates).rows["MNDBBBB"].Status == "ACTIVE" {
		t.Fatalf("unverifiable mandate must stay pending: %d %v", r.status, r.body)
	}

	gw := f.do(t, "GET", "/api/v1/admin/gateways", tenantA, token(t, "ADM_A", domain.RoleMahalAdmin, tenantA), nil)
	if gw.status != 200 {
		t.Fatalf("gateways: %d", gw.status)
	}
}

func TestGatewaysShape(t *testing.T) {
	h := &Handler{pgClient: pg.NewClient(pg.Config{BaseURL: "https://test.payu.in/_payment", APIKey: "ABCDEFGH12", Salt: "s"})}
	gws := h.gatewaysFor(nil, true)
	payu := gws[0]
	if payu["provider"] != "PAYU" || payu["status"] != "ACTIVE" || payu["mode"] != "TEST" || payu["merchant_key_masked"] != "••••GH12" || payu["autopay_enabled"] != true {
		t.Fatalf("payu: %v", payu)
	}
	raw, _ := json.Marshal(gws)
	if strings.Contains(string(raw), "ABCDEFGH12") || strings.Contains(string(raw), `"s"`) {
		t.Fatalf("secrets leaked: %s", raw)
	}
	if gws[1]["provider"] != "CASH" {
		t.Fatalf("cash row missing")
	}
	none := (&Handler{}).gatewaysFor(nil, true)
	if none[0]["status"] != "NOT_CONFIGURED" {
		t.Fatalf("unconfigured: %v", none[0])
	}
}

// ---------------------------------------------------------------------------
// 4 / 10. Profile fields, effective dues, Mahal contact
// ---------------------------------------------------------------------------

func TestProfileFieldsAndMahalContact(t *testing.T) {
	f := gapFixture(t)
	mahals := f.h.mahalRepo.(*fakeMahals)
	mahals.rows[tenantA] = domain.Mahal{ID: tenantA, Name: "Mahal A", Contact: domain.MahalContact{Phone: "+914952222222"}, Settings: domain.MahalSettings{DefaultMonthlyDues: 300}}
	member := token(t, "MEM_2", domain.RoleMember, tenantA)

	r := f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, member, map[string]string{
		"name": "Two", "email": "two@example.com", "address2": "Near masjid", "city": "Kozhikode", "state": "Kerala", "pincode": "673001",
	})
	if r.status != 200 {
		t.Fatalf("update: %d %v", r.status, r.body)
	}
	m := f.members.rows["MEM_2"]
	if m.Email != "two@example.com" || m.City != "Kozhikode" || m.State != "Kerala" || m.Pincode != "673001" || m.Address2 != "Near masjid" {
		t.Fatalf("fields not saved: %+v", m)
	}
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, member, map[string]string{"email": "nope"}); r.status != 400 {
		t.Fatalf("bad email: want 400, got %d", r.status)
	}
	if r := f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, member, map[string]string{"pincode": "12"}); r.status != 400 {
		t.Fatalf("bad pincode: want 400, got %d", r.status)
	}
	// "" clears.
	f.do(t, "PUT", "/api/v1/members/profile/MEM_2", tenantA, member, map[string]string{"city": ""})
	if f.members.rows["MEM_2"].City != "" {
		t.Fatalf("empty string should clear city")
	}

	p := f.do(t, "GET", "/api/v1/members/profile/MEM_2", tenantA, member, nil)
	if p.body["email"] != "two@example.com" || p.body["effective_monthly_dues"] != 300.0 || p.body["dues_rate_source"] != "MAHAL_DEFAULT" {
		t.Fatalf("profile: %v", p.body)
	}
	contact, _ := p.body["mahal_contact"].(map[string]any)
	if contact["phone"] != "+914952222222" || contact["whatsapp"] != "+914952222222" {
		t.Fatalf("contact: %v", p.body["mahal_contact"])
	}
	d := f.do(t, "GET", "/api/v1/member/dashboard", tenantA, member, nil)
	if d.body["effective_monthly_dues"] != 300.0 || d.body["mahal_contact"] == nil {
		t.Fatalf("dashboard: %v", d.body)
	}
}
