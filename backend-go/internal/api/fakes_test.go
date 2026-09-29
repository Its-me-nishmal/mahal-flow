package api

import (
	"errors"
	"sort"
	"strings"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/firebaseauth"
	"github.com/mahalflow/backend-go/internal/repository"
	"go.mongodb.org/mongo-driver/v2/bson"
)

// In-memory repositories for handler tests. Only the behaviour the auth /
// scoping tests rely on is modelled faithfully; the rest are inert stubs.

var errNoDoc = errors.New("mongo: no documents in result")

type fakeAdmins struct{ rows []domain.Admin }

func (f *fakeAdmins) GetByPhone(_ contextT, mahalID, phone string) (*domain.Admin, error) {
	for i := range f.rows {
		if f.rows[i].Phone == phone && f.rows[i].MahalID == mahalID {
			a := f.rows[i]
			return &a, nil
		}
	}
	return nil, nil
}
func (f *fakeAdmins) ListByPhone(_ contextT, phone string) ([]domain.Admin, error) {
	var out []domain.Admin
	for _, a := range f.rows {
		if a.Phone == phone {
			out = append(out, a)
		}
	}
	return out, nil
}
func (f *fakeAdmins) Create(_ contextT, a *domain.Admin) error {
	f.rows = append(f.rows, *a)
	return nil
}
func (f *fakeAdmins) SetPasswordHash(_ contextT, id, hash string) (bool, error) {
	for i := range f.rows {
		if f.rows[i].ID == id {
			f.rows[i].PasswordHash = hash
			return true, nil
		}
	}
	return false, nil
}

type fakeMembers struct{ rows map[string]domain.Member }

func (f *fakeMembers) Create(_ contextT, m *domain.Member) error { f.rows[m.ID] = *m; return nil }
func (f *fakeMembers) GetByID(_ contextT, mahalID, id string) (*domain.Member, error) {
	m, ok := f.rows[id]
	if !ok || m.MahalID != mahalID {
		return nil, errNoDoc
	}
	return &m, nil
}
func (f *fakeMembers) GetByPhone(_ contextT, mahalID, phone string) (*domain.Member, error) {
	for _, m := range f.rows {
		if m.Phone == phone && m.MahalID == mahalID {
			mm := m
			return &mm, nil
		}
	}
	return nil, errNoDoc
}
func (f *fakeMembers) ListByMahal(_ contextT, mahalID string, _, _ int64) ([]domain.Member, int64, error) {
	var out []domain.Member
	for _, m := range f.rows {
		if m.MahalID == mahalID {
			out = append(out, m)
		}
	}
	return out, int64(len(out)), nil
}
func (f *fakeMembers) ApplyPaidMonths(contextT, string, []string, float64) error { return nil }
func (f *fakeMembers) GetMemberStats(_ contextT, mahalID string) (int64, int64, int64, float64, error) {
	var total, paid int64
	var pendingAmt float64
	for _, m := range f.rows {
		if m.MahalID != mahalID {
			continue
		}
		total++
		if m.OutstandingBalance <= 0 {
			paid++
		} else {
			pendingAmt += m.OutstandingBalance
		}
	}
	return total, paid, total - paid, pendingAmt, nil
}
func (f *fakeMembers) UpdateProfile(_ contextT, mahalID, id string, u bson.M) error {
	m, ok := f.rows[id]
	if !ok || m.MahalID != mahalID {
		return nil
	}
	// Apply the $set generically through BSON, as Mongo would.
	raw, err := bson.Marshal(m)
	if err != nil {
		return err
	}
	var doc bson.M
	if err := bson.Unmarshal(raw, &doc); err != nil {
		return err
	}
	for k, v := range u {
		doc[k] = v
	}
	raw, err = bson.Marshal(doc)
	if err != nil {
		return err
	}
	var out domain.Member
	if err := bson.Unmarshal(raw, &out); err != nil {
		return err
	}
	f.rows[id] = out
	return nil
}
func (f *fakeMembers) UpdateStatus(_ contextT, mahalID, id, status string) error {
	if m, ok := f.rows[id]; ok && m.MahalID == mahalID {
		m.Status = status
		f.rows[id] = m
	}
	return nil
}
func (f *fakeMembers) ListPhones(_ contextT, mahalID string) (map[string]bool, error) {
	out := map[string]bool{}
	for _, m := range f.rows {
		if m.MahalID == mahalID {
			out[m.Phone] = true
		}
	}
	return out, nil
}
func (f *fakeMembers) Delete(_ contextT, mahalID, id string) (bool, error) {
	m, ok := f.rows[id]
	if !ok || m.MahalID != mahalID {
		return false, nil
	}
	delete(f.rows, id)
	return true, nil
}
func (f *fakeMembers) GetOverdueMembers(contextT, string) ([]domain.Member, error) { return nil, nil }

type fakeReceipts struct{ rows []domain.Receipt }

func (f *fakeReceipts) Insert(_ contextT, r *domain.Receipt) error {
	f.rows = append(f.rows, *r)
	return nil
}
func (f *fakeReceipts) GetLatestReceipt(_ contextT, mahalID string) (*domain.Receipt, error) {
	var best *domain.Receipt
	for i := range f.rows {
		if f.rows[i].MahalID == mahalID && (best == nil || f.rows[i].SequenceNumber > best.SequenceNumber) {
			best = &f.rows[i]
		}
	}
	return best, nil
}
func (f *fakeReceipts) GetNextSequenceNumber(contextT, string) (int64, error) { return 0, nil }
func (f *fakeReceipts) AllocateAtomicReceiptSequence(contextT, string) (int64, string, error) {
	return 0, "", nil
}
func (f *fakeReceipts) UpdateLedgerHeadHash(contextT, string, int64, string) error { return nil }
func (f *fakeReceipts) GetByNumber(_ contextT, n string) (*domain.Receipt, error) {
	for i := range f.rows {
		if f.rows[i].ReceiptNumber == n {
			return &f.rows[i], nil
		}
	}
	return nil, errNoDoc
}
func (f *fakeReceipts) GetByNumberForMahal(_ contextT, mahalID, n string) (*domain.Receipt, error) {
	for i := range f.rows {
		if f.rows[i].ReceiptNumber == n && f.rows[i].MahalID == mahalID {
			r := f.rows[i] // a copy, like a Mongo decode
			return &r, nil
		}
	}
	return nil, nil
}
func (f *fakeReceipts) GetLatestByMember(_ contextT, mahalID, memberID string) (*domain.Receipt, error) {
	var best *domain.Receipt
	for i := range f.rows {
		r := &f.rows[i]
		if r.MahalID == mahalID && r.MemberID == memberID && (best == nil || r.CreatedAt.After(best.CreatedAt)) {
			best = r
		}
	}
	return best, nil
}
func (f *fakeReceipts) GetByMemberID(_ contextT, mahalID, memberID string) ([]domain.Receipt, error) {
	out := []domain.Receipt{}
	for _, r := range f.rows {
		if r.MahalID == mahalID && r.MemberID == memberID {
			out = append(out, r)
		}
	}
	return out, nil
}
func (f *fakeReceipts) GetAllByMahal(contextT, string, int64) ([]domain.Receipt, error) {
	return nil, nil
}
func (f *fakeReceipts) VerifyReceiptChain(contextT, string) (int64, int64, error) { return 0, 0, nil }

type fakeAlerts struct {
	rows   []domain.SystemAlert
	states map[string]domain.AlertMemberState
}

func (f *fakeAlerts) visible(mahalID string, a domain.SystemAlert) bool {
	return a.MahalID == mahalID || a.MahalID == ""
}
func (f *fakeAlerts) Create(_ contextT, a *domain.SystemAlert) error {
	f.rows = append(f.rows, *a)
	return nil
}
func (f *fakeAlerts) List(_ contextT, mahalID string) ([]domain.SystemAlert, error) {
	out := []domain.SystemAlert{}
	for _, a := range f.rows {
		if f.visible(mahalID, a) {
			out = append(out, a)
		}
	}
	return out, nil
}
func (f *fakeAlerts) GetByID(_ contextT, mahalID, id string) (*domain.SystemAlert, error) {
	for i := range f.rows {
		if f.rows[i].ID == id && f.visible(mahalID, f.rows[i]) {
			a := f.rows[i]
			return &a, nil
		}
	}
	return nil, nil
}
func (f *fakeAlerts) Acknowledge(_ contextT, mahalID, id string) (bool, error) {
	for i := range f.rows {
		if f.rows[i].ID == id && f.visible(mahalID, f.rows[i]) {
			f.rows[i].Status = "ACKNOWLEDGED"
			return true, nil
		}
	}
	return false, nil
}
func (f *fakeAlerts) Dismiss(_ contextT, mahalID, id string) (bool, error) {
	for i := range f.rows {
		if f.rows[i].ID == id && f.visible(mahalID, f.rows[i]) {
			f.rows = append(f.rows[:i], f.rows[i+1:]...)
			return true, nil
		}
	}
	return false, nil
}
func (f *fakeAlerts) ClearAll(contextT, string) error    { return nil }
func (f *fakeAlerts) MarkAllRead(contextT, string) error { return nil }
func (f *fakeAlerts) ListMemberStates(_ contextT, mahalID, memberID string) (map[string]domain.AlertMemberState, error) {
	out := map[string]domain.AlertMemberState{}
	for _, s := range f.states {
		if s.MahalID == mahalID && s.MemberID == memberID {
			out[s.AlertID] = s
		}
	}
	return out, nil
}
func (f *fakeAlerts) upsert(mahalID, memberID string, ids []string, dismiss bool) {
	now := time.Now()
	for _, id := range ids {
		key := id + ":" + memberID
		s := f.states[key]
		s.ID, s.AlertID, s.MahalID, s.MemberID = key, id, mahalID, memberID
		s.ReadAt = &now
		if dismiss {
			s.DismissedAt = &now
		}
		f.states[key] = s
	}
}
func (f *fakeAlerts) MarkReadForMember(_ contextT, mahalID, memberID string, ids []string) error {
	f.upsert(mahalID, memberID, ids, false)
	return nil
}
func (f *fakeAlerts) DismissForMember(_ contextT, mahalID, memberID string, ids []string) error {
	f.upsert(mahalID, memberID, ids, true)
	return nil
}

type fakeTxns struct{ rows map[string]domain.Transaction }

func (f *fakeTxns) Create(_ contextT, t *domain.Transaction) error { f.rows[t.ID] = *t; return nil }
func (f *fakeTxns) GetByID(_ contextT, id string) (*domain.Transaction, error) {
	t, ok := f.rows[id]
	if !ok {
		return nil, errNoDoc
	}
	return &t, nil
}
func (f *fakeTxns) ListAll(_ contextT, mahalID string, limit, skip int64) ([]domain.Transaction, int64, error) {
	var out []domain.Transaction
	for _, t := range f.rows {
		if t.MahalID == mahalID {
			out = append(out, t)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	total := int64(len(out))
	if skip >= total {
		return []domain.Transaction{}, total, nil
	}
	out = out[skip:]
	if limit > 0 && int64(len(out)) > limit {
		out = out[:limit]
	}
	return out, total, nil
}
func (f *fakeTxns) UpdateStatus(_ contextT, id string, st domain.PaymentStatus, receiptID string) error {
	if t, ok := f.rows[id]; ok {
		now := time.Now().UTC()
		t.Status, t.ReceiptID, t.CompletedAt = st, receiptID, &now
		f.rows[id] = t
	}
	return nil
}
func (f *fakeTxns) SetGatewayPaymentID(contextT, string, string) error { return nil }
func (f *fakeTxns) GetFinancialSummaryRange(_ contextT, mahalID string, from, to *time.Time) (repository.FinancialSummary, error) {
	var out repository.FinancialSummary
	for _, t := range f.rows {
		if t.MahalID != mahalID || t.Status != domain.TxnSuccess {
			continue
		}
		at := t.CreatedAt
		if t.CompletedAt != nil {
			at = *t.CompletedAt
		}
		if (from != nil && at.Before(*from)) || (to != nil && !at.Before(*to)) {
			continue
		}
		out.TotalCollected += t.Amount
		out.TransactionCount++
		switch t.Type {
		case "MONTHLY_DUES":
			out.DuesCollected += t.Amount
		case "CONTRIBUTION":
			out.Donations += t.Amount
		}
	}
	return out, nil
}
func (f *fakeTxns) GetByIDs(_ contextT, mahalID string, ids []string) (map[string]domain.Transaction, error) {
	out := map[string]domain.Transaction{}
	for _, id := range ids {
		if t, ok := f.rows[id]; ok && t.MahalID == mahalID {
			out[id] = t
		}
	}
	return out, nil
}
func (f *fakeTxns) CountByMember(_ contextT, mahalID, memberID string) (int64, error) {
	var n int64
	for _, t := range f.rows {
		if t.MahalID == mahalID && t.MemberID == memberID && (t.Status == domain.TxnSuccess || t.Status == domain.TxnRefunded) {
			n++
		}
	}
	return n, nil
}
func (f *fakeTxns) SetPaymentDetails(_ contextT, id, pid, mode string) error {
	if t, ok := f.rows[id]; ok {
		if pid != "" {
			t.GatewayPaymentID = pid
		}
		if mode != "" {
			t.PaymentMode = mode
		}
		f.rows[id] = t
	}
	return nil
}
func (f *fakeTxns) FindPendingOlderThan(contextT, time.Duration) ([]domain.Transaction, error) {
	return nil, nil
}
func (f *fakeTxns) FindByIDempotencyKey(contextT, string) (*domain.Transaction, error) {
	return nil, nil
}
func (f *fakeTxns) CountFailedByIP(contextT, string, time.Duration) (int64, error)     { return 0, nil }
func (f *fakeTxns) CountFailedByDevice(contextT, string, time.Duration) (int64, error) { return 0, nil }
func (f *fakeTxns) GetRecentRefundsByMahal(contextT, string, time.Time) ([]domain.Transaction, error) {
	return nil, nil
}
func (f *fakeTxns) GetTotalCollectionByMahal(contextT, string, time.Time) (float64, error) {
	return 0, nil
}
func (f *fakeTxns) GetFinancialSummary(contextT, string) (float64, float64, float64, error) {
	return 0, 0, 0, nil
}

type fakeRefunds struct {
	rows map[string]domain.RefundRequest
}

func (f *fakeRefunds) Create(_ contextT, r *domain.RefundRequest) error {
	f.rows[r.ID] = *r
	return nil
}
func (f *fakeRefunds) List(contextT, string) ([]domain.RefundRequest, error) { return nil, nil }
func (f *fakeRefunds) GetByID(_ contextT, id string) (*domain.RefundRequest, error) {
	r, ok := f.rows[id]
	if !ok {
		return nil, errNoDoc
	}
	return &r, nil
}
func (f *fakeRefunds) UpdateStatus(_ contextT, id, status string) error {
	r := f.rows[id]
	r.Status = status
	f.rows[id] = r
	return nil
}

type fakeMahals struct{ rows map[string]domain.Mahal }

func (f *fakeMahals) GetByID(_ contextT, id string) (*domain.Mahal, error) {
	m, ok := f.rows[id]
	if !ok {
		return nil, errNoDoc
	}
	return &m, nil
}
func (f *fakeMahals) Create(_ contextT, m *domain.Mahal) error { f.rows[m.ID] = *m; return nil }
func (f *fakeMahals) ListAll(contextT) ([]domain.Mahal, error) {
	out := []domain.Mahal{}
	for _, m := range f.rows {
		out = append(out, m)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out, nil
}

// fakeVerifier accepts tokens of the form "valid:<phone>".
type fakeVerifier struct{}

func (fakeVerifier) VerifyIDToken(_ contextT, tok string) (*firebaseauth.Token, error) {
	if phone, ok := strings.CutPrefix(tok, "valid:"); ok {
		return &firebaseauth.Token{UID: "uid-" + phone, PhoneNumber: phone}, nil
	}
	return nil, firebaseauth.ErrSignature
}

// Update applies a Mongo-style $set (dotted paths into sub-documents).
func (f *fakeMahals) Update(_ contextT, id string, set bson.M) (bool, error) {
	m, ok := f.rows[id]
	if !ok {
		return false, nil
	}
	raw, err := bson.Marshal(m)
	if err != nil {
		return false, err
	}
	var doc bson.M
	if err := bson.Unmarshal(raw, &doc); err != nil {
		return false, err
	}
	for k, v := range set {
		parts := strings.Split(k, ".")
		cur := doc
		for _, p := range parts[:len(parts)-1] {
			next, ok := cur[p].(bson.M)
			if !ok {
				if d, isD := cur[p].(bson.D); isD {
					next = bson.M{}
					for _, e := range d {
						next[e.Key] = e.Value
					}
				} else {
					next = bson.M{}
				}
				cur[p] = next
			}
			cur = next
		}
		cur[parts[len(parts)-1]] = v
	}
	doc["updated_at"] = time.Now().UTC()
	raw, err = bson.Marshal(doc)
	if err != nil {
		return false, err
	}
	var out domain.Mahal
	if err := bson.Unmarshal(raw, &out); err != nil {
		return false, err
	}
	f.rows[id] = out
	return true, nil
}

func (f *fakeMembers) GetNames(_ contextT, mahalID string, ids []string) (map[string]string, error) {
	out := map[string]string{}
	for _, id := range ids {
		if m, ok := f.rows[id]; ok && m.MahalID == mahalID {
			out[id] = m.Name
		}
	}
	return out, nil
}
