package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// Fakes embed the repository interface so only the methods under test exist.

type fakeTxnRepo struct {
	repository.TransactionRepository
	rows        map[string]domain.Transaction
	createErr   error
	markLose    bool
	markCalls   int
	idemLookups []string // mahalID/key pairs asked for
}

func (f *fakeTxnRepo) Create(_ context.Context, t *domain.Transaction) error {
	if f.createErr != nil {
		return f.createErr
	}
	f.rows[t.ID] = *t
	return nil
}
func (f *fakeTxnRepo) GetByID(_ context.Context, id string) (*domain.Transaction, error) {
	t, ok := f.rows[id]
	if !ok {
		return nil, mongo.ErrNoDocuments
	}
	return &t, nil
}
func (f *fakeTxnRepo) FindByIDempotencyKey(_ context.Context, mahalID, key string) (*domain.Transaction, error) {
	f.idemLookups = append(f.idemLookups, mahalID+"/"+key)
	for _, t := range f.rows {
		if t.MahalID == mahalID && t.IdempotencyKey == key {
			tt := t
			return &tt, nil
		}
	}
	return nil, mongo.ErrNoDocuments
}
func (f *fakeTxnRepo) MarkSuccess(_ context.Context, id, receipt string) (bool, error) {
	f.markCalls++
	t := f.rows[id]
	if f.markLose || t.Status != domain.TxnPending {
		return false, nil
	}
	t.Status, t.ReceiptID = domain.TxnSuccess, receipt
	f.rows[id] = t
	return true, nil
}

type fakeMemberRepo struct {
	repository.MemberRepository
	applied [][]string
}

func (f *fakeMemberRepo) GetByID(_ context.Context, mahalID, id string) (*domain.Member, error) {
	return &domain.Member{ID: id, MahalID: mahalID, Name: "Member"}, nil
}
func (f *fakeMemberRepo) ApplyPaidMonths(_ context.Context, _ string, months []string, _ float64) error {
	f.applied = append(f.applied, months)
	return nil
}

type fakeReceiptRepo struct {
	repository.ReceiptRepository
	rows     map[string]domain.Receipt // by number
	seq      int64
	prev     string
	allocErr error
	head     string
}

func (f *fakeReceiptRepo) AllocateAtomicReceiptSequence(context.Context, string) (int64, string, error) {
	if f.allocErr != nil {
		return 0, "", f.allocErr
	}
	f.seq++
	return f.seq, f.prev, nil
}
func (f *fakeReceiptRepo) Insert(_ context.Context, r *domain.Receipt) error {
	f.rows[r.ReceiptNumber] = *r
	return nil
}
func (f *fakeReceiptRepo) UpdateLedgerHeadHash(_ context.Context, _ string, _ int64, h string) error {
	f.head, f.prev = h, h
	return nil
}
func (f *fakeReceiptRepo) GetByNumberForMahal(_ context.Context, mahalID, n string) (*domain.Receipt, error) {
	if r, ok := f.rows[n]; ok && r.MahalID == mahalID {
		return &r, nil
	}
	return nil, nil
}
func (f *fakeReceiptRepo) GetLatestReceipt(context.Context, string) (*domain.Receipt, error) {
	return nil, errors.New("GetLatestReceipt must not be used to answer for a transaction")
}

func newTestService() (*paymentService, *fakeTxnRepo, *fakeMemberRepo, *fakeReceiptRepo) {
	tr := &fakeTxnRepo{rows: map[string]domain.Transaction{}}
	mr := &fakeMemberRepo{}
	rr := &fakeReceiptRepo{rows: map[string]domain.Receipt{}, prev: "0000000000000000000000000000000000000000000000000000000000000000"}
	return &paymentService{txnRepo: tr, memberRepo: mr, receiptRepo: rr}, tr, mr, rr
}

func pendingDues(id string) domain.Transaction {
	return domain.Transaction{
		ID: id, MahalID: "MH1", MemberID: "MEM1", Type: "MONTHLY_DUES", Amount: 1000, Currency: "INR",
		SelectedMonths: []string{"2026-03", "2026-04"}, Gateway: "PAYU", Status: domain.TxnPending, CreatedAt: time.Now(),
	}
}

func TestCommitIssuesVerifiableV2Receipt(t *testing.T) {
	s, tr, mr, rr := newTestService()
	tr.rows["T1"] = pendingDues("T1")

	r, created, err := s.executeCommit(context.Background(), "T1")
	if err != nil || !created {
		t.Fatalf("commit: created=%v err=%v", created, err)
	}
	if r.HashVersion != domain.ReceiptHashV2 || r.Currency != "INR" || r.TransactionID != "T1" {
		t.Fatalf("receipt: %+v", r)
	}
	stored := rr.rows[r.ReceiptNumber]
	if stored.ComputeHash() != stored.ReceiptHash {
		t.Fatal("stored receipt must recompute to its own hash")
	}
	// Tampering with the stored amount must now be detected.
	stored.Amount = 1
	if stored.ComputeHash() == stored.ReceiptHash {
		t.Fatal("amount tamper undetected")
	}
	if tr.rows["T1"].Status != domain.TxnSuccess || tr.rows["T1"].ReceiptID != r.ReceiptNumber {
		t.Fatalf("txn not marked: %+v", tr.rows["T1"])
	}
	if len(mr.applied) != 1 {
		t.Fatal("dues must be applied once")
	}
}

func TestCommitAlreadySuccessReturnsOwnReceiptNotLatest(t *testing.T) {
	s, tr, mr, rr := newTestService()
	own := domain.Receipt{ReceiptNumber: "R-OWN", MahalID: "MH1", TransactionID: "T1"}
	later := domain.Receipt{ReceiptNumber: "R-LATER", MahalID: "MH1", TransactionID: "T2", SequenceNumber: 9}
	rr.rows["R-OWN"], rr.rows["R-LATER"] = own, later
	done := pendingDues("T1")
	done.Status, done.ReceiptID = domain.TxnSuccess, "R-OWN"
	tr.rows["T1"] = done

	r, created, err := s.executeCommit(context.Background(), "T1")
	if err != nil || created || r.ReceiptNumber != "R-OWN" {
		t.Fatalf("want own receipt, got %+v created=%v err=%v", r, created, err)
	}
	if len(mr.applied) != 0 || tr.markCalls != 0 {
		t.Fatal("a repeat commit must not touch the member or the transaction")
	}

	// SUCCESS with a missing receipt is an error, never "the latest one".
	done.ReceiptID = "R-MISSING"
	tr.rows["T1"] = done
	if _, _, err := s.executeCommit(context.Background(), "T1"); err == nil {
		t.Fatal("missing receipt must be an error")
	}
	done.ReceiptID = ""
	tr.rows["T1"] = done
	if _, _, err := s.executeCommit(context.Background(), "T1"); err == nil {
		t.Fatal("no receipt id must be an error")
	}
}

func TestCommitRefusesNonPendingStates(t *testing.T) {
	s, tr, _, _ := newTestService()
	for _, st := range []domain.PaymentStatus{domain.TxnFailed, domain.TxnRefunded, domain.TxnPartiallyRefunded, domain.TxnInitialized} {
		x := pendingDues("T1")
		x.Status = st
		tr.rows["T1"] = x
		if _, _, err := s.executeCommit(context.Background(), "T1"); !errors.Is(err, ErrNotCommittable) {
			t.Errorf("%s: want ErrNotCommittable, got %v", st, err)
		}
	}
}

func TestCommitIsConditionalOnPending(t *testing.T) {
	s, tr, mr, _ := newTestService()
	tr.rows["T1"] = pendingDues("T1")
	tr.markLose = true // another committer flipped PENDING -> SUCCESS first
	if _, _, err := s.executeCommit(context.Background(), "T1"); !errors.Is(err, errLostCommitRace) {
		t.Fatalf("want errLostCommitRace, got %v", err)
	}
	if len(mr.applied) != 0 {
		t.Fatal("the loser must not apply dues")
	}
}

func TestCommitCounterErrorFailsClosed(t *testing.T) {
	s, tr, _, rr := newTestService()
	tr.rows["T1"] = pendingDues("T1")
	rr.allocErr = errors.New("counter unavailable")
	if _, _, err := s.executeCommit(context.Background(), "T1"); err == nil {
		t.Fatal("a counter error must abort the commit, not fall back to seq 1 / genesis")
	}
	if len(rr.rows) != 0 || tr.rows["T1"].Status != domain.TxnPending {
		t.Fatal("nothing may be written on a counter error")
	}
}

func TestStandaloneFallbackFailsClosedUnlessAllowed(t *testing.T) {
	s, _, _, _ := newTestService()
	calls := 0
	fn := func(context.Context) (*domain.Receipt, error) {
		calls++
		return &domain.Receipt{ReceiptNumber: "X"}, nil
	}
	s.txRunner = func(context.Context, func(context.Context) (*domain.Receipt, error)) (*domain.Receipt, error) {
		return nil, errors.New("Transaction numbers are only allowed on a replica set member or mongos")
	}
	if _, err := s.runLedgerOp(context.Background(), "MH1", fn); !errors.Is(err, ErrTxnUnavailable) || calls != 0 {
		t.Fatalf("production default: err=%v calls=%d; want ErrTxnUnavailable and no write", err, calls)
	}
	s.SetAllowStandaloneCommit(true)
	if r, err := s.runLedgerOp(context.Background(), "MH1", fn); err != nil || r == nil || calls != 1 {
		t.Fatalf("explicit dev flag: r=%v err=%v calls=%d", r, err, calls)
	}
	// Any other error is returned untouched, never retried standalone.
	s.SetAllowStandaloneCommit(true)
	s.txRunner = func(context.Context, func(context.Context) (*domain.Receipt, error)) (*domain.Receipt, error) {
		return nil, errors.New("disk on fire")
	}
	if _, err := s.runLedgerOp(context.Background(), "MH1", fn); err == nil || calls != 1 {
		t.Fatalf("other errors must not trigger the fallback: %v calls=%d", err, calls)
	}
}

func TestIdempotentCreateIsTenantScoped(t *testing.T) {
	s, tr, _, _ := newTestService()
	dup := errors.New("E11000 duplicate key error collection: transactions")

	// The key is only used by ANOTHER tenant: it must not be returned.
	other := pendingDues("TX_OTHER")
	other.MahalID, other.IdempotencyKey = "MH_OTHER", "K1"
	tr.rows["TX_OTHER"] = other
	tr.createErr = dup
	mine := pendingDues("TX_MINE")
	mine.IdempotencyKey = "K1"
	if got, err := s.createIdempotent(context.Background(), &mine); err == nil || got != nil {
		t.Fatalf("another tenant's transaction leaked: %+v err=%v", got, err)
	}
	if len(tr.idemLookups) != 1 || tr.idemLookups[0] != "MH1/K1" {
		t.Fatalf("lookup must be scoped to the tenant, got %v", tr.idemLookups)
	}

	// Same tenant, same member and type: the earlier transaction is returned.
	first := pendingDues("TX_FIRST")
	first.IdempotencyKey = "K2"
	tr.rows["TX_FIRST"] = first
	again := pendingDues("TX_AGAIN")
	again.IdempotencyKey = "K2"
	if got, err := s.createIdempotent(context.Background(), &again); err != nil || got.ID != "TX_FIRST" {
		t.Fatalf("same-tenant duplicate: %+v err=%v", got, err)
	}

	// Same tenant but a different member must not read someone else's payment.
	stranger := pendingDues("TX_STRANGER")
	stranger.IdempotencyKey, stranger.MemberID = "K2", "MEM_OTHER"
	if _, err := s.createIdempotent(context.Background(), &stranger); !errors.Is(err, ErrIdempotencyConflict) {
		t.Fatalf("different member: want ErrIdempotencyConflict, got %v", err)
	}
}

func TestEmptyIdempotencyKeysNeverCollide(t *testing.T) {
	a, b := normalizeIdempotencyKey(""), normalizeIdempotencyKey("  ")
	if a == "" || b == "" || a == b {
		t.Fatalf("keyless requests need distinct generated keys: %q %q", a, b)
	}
	if normalizeIdempotencyKey(" abc ") != "abc" {
		t.Fatal("explicit keys are kept (trimmed)")
	}
}

func TestAppendRefundEntryIsNegativeAndChained(t *testing.T) {
	s, tr, _, rr := newTestService()
	s.txRunner = func(ctx context.Context, fn func(context.Context) (*domain.Receipt, error)) (*domain.Receipt, error) {
		return fn(ctx)
	}
	tr.rows["T1"] = pendingDues("T1")
	txn := tr.rows["T1"]
	txn.Status = domain.TxnPartiallyRefunded
	prevHead := rr.prev

	e, err := s.AppendRefundEntry(context.Background(), &txn, 250.5, "REF1")
	if err != nil {
		t.Fatal(err)
	}
	if e.Amount != -250.5 || e.PaymentType != domain.ReceiptTypeRefund || e.TransactionID != "T1" || e.PreviousReceiptHash != prevHead {
		t.Fatalf("refund entry: %+v", e)
	}
	saved := rr.rows[e.ReceiptNumber]
	if saved.ComputeHash() != e.ReceiptHash || rr.head != e.ReceiptHash {
		t.Fatal("refund entry must be hash-sealed and become the ledger head")
	}
	if _, err := s.AppendRefundEntry(context.Background(), &txn, 0, "x"); !errors.Is(err, domain.ErrRefundAmountInvalid) {
		t.Fatalf("zero amount: %v", err)
	}
}
