package domain

import (
	"errors"
	"testing"
	"time"
)

const genesis = "0000000000000000000000000000000000000000000000000000000000000000"

func newV2Receipt(num string, seq int64, amount float64, prev string) Receipt {
	r := Receipt{
		ReceiptNumber:       num,
		SequenceNumber:      seq,
		MahalID:             "MH1",
		MemberID:            "MEM1",
		TransactionID:       "TXN" + num,
		PaymentType:         "MONTHLY_DUES",
		PaidMonths:          []string{"2026-01", "2026-02"},
		Amount:              amount,
		Currency:            "INR",
		Fund:                "",
		PreviousReceiptHash: prev,
		CreatedAt:           time.Date(2026, 1, 5, 10, 30, 0, 123_000_000, time.UTC),
		HashVersion:         ReceiptHashV2,
	}
	r.ReceiptHash = r.ComputeHash()
	return r
}

func TestToPaiseRounding(t *testing.T) {
	cases := map[float64]MoneyPaise{
		500.50: 50050,
		0.29:   29, // 0.29*100 = 28.999999999999996
		0:      0,
		-500.5: -50050,
		-0.29:  -29,
		19.99:  1999,
	}
	for in, want := range cases {
		if got := ToPaise(in); got != want {
			t.Errorf("ToPaise(%v) = %d, want %d", in, got, want)
		}
	}
}

func TestLegacyHashUnchanged(t *testing.T) {
	// A receipt with no HashVersion is verified with the legacy formula, so
	// receipts already in production keep verifying.
	prev := genesis
	h := CalculateReceiptHash("RCPT-1", "MH1", "MEM1", 500, prev)
	r := Receipt{ReceiptNumber: "RCPT-1", MahalID: "MH1", MemberID: "MEM1", Amount: 500, PreviousReceiptHash: prev, ReceiptHash: h}
	if r.EffectiveHashVersion() != ReceiptHashV1 || r.ComputeHash() != h {
		t.Fatal("legacy receipt must verify with the v1 formula")
	}
	// Legacy formula ignores the extra fields: this is exactly the weakness v2 fixes.
	r.TransactionID, r.PaidMonths = "OTHER", []string{"2030-01"}
	if r.ComputeHash() != h {
		t.Fatal("v1 hash must stay independent of v2-only fields")
	}
}

func TestV2HashCoversEveryField(t *testing.T) {
	base := newV2Receipt("RCPT-1", 1, 500, genesis)
	mutations := map[string]func(r *Receipt){
		"receipt number": func(r *Receipt) { r.ReceiptNumber = "RCPT-X" },
		"sequence":       func(r *Receipt) { r.SequenceNumber = 9 },
		"mahal":          func(r *Receipt) { r.MahalID = "MH2" },
		"member":         func(r *Receipt) { r.MemberID = "MEM2" },
		"transaction":    func(r *Receipt) { r.TransactionID = "TXN-other" },
		"payment type":   func(r *Receipt) { r.PaymentType = "CONTRIBUTION" },
		"months":         func(r *Receipt) { r.PaidMonths = []string{"2026-01"} },
		"month order":    func(r *Receipt) { r.PaidMonths = []string{"2026-02", "2026-01"} },
		"amount":         func(r *Receipt) { r.Amount = 5000 },
		"amount paise":   func(r *Receipt) { r.Amount = 500.01 },
		"currency":       func(r *Receipt) { r.Currency = "USD" },
		"date":           func(r *Receipt) { r.CreatedAt = r.CreatedAt.Add(time.Second) },
		"fund":           func(r *Receipt) { r.Fund = "ZAKAT" },
		"previous hash":  func(r *Receipt) { r.PreviousReceiptHash = "ff" + genesis[2:] },
	}
	for name, mut := range mutations {
		r := base
		r.PaidMonths = append([]string(nil), base.PaidMonths...)
		mut(&r)
		if r.ComputeHash() == base.ReceiptHash {
			t.Errorf("changing %s did not change the v2 hash", name)
		}
	}
	// Descriptive-only fields stay out of the hash.
	r := base
	r.Note, r.Gateway, r.PaymentMethod, r.Status = "hi", "PAYU", "UPI", "REFUNDED"
	if r.ComputeHash() != base.ReceiptHash {
		t.Error("descriptive fields must not affect the hash")
	}
}

func TestV2HashNoFieldBoundaryAmbiguity(t *testing.T) {
	a := newV2Receipt("A", 1, 100, genesis)
	a.MemberID, a.TransactionID = "M1", "2T"
	a.ReceiptHash = a.ComputeHash()
	b := a
	b.MemberID, b.TransactionID = "M12", "T"
	if a.ComputeHash() == b.ComputeHash() {
		t.Fatal("shifting a character between adjacent fields must change the hash")
	}
}

func TestVerifyReceiptHashesDetectsTampering(t *testing.T) {
	r1 := newV2Receipt("R1", 1, 500, genesis)
	r2 := newV2Receipt("R2", 2, 700, r1.ReceiptHash)
	r3 := newV2Receipt("R3", 3, 900, r2.ReceiptHash)
	// A legacy receipt mixed in at the head of another chain.
	l1 := Receipt{ReceiptNumber: "L1", SequenceNumber: 1, MahalID: "MH1", MemberID: "M", Amount: 100, PreviousReceiptHash: genesis}
	l1.ReceiptHash = CalculateReceiptHash("L1", "MH1", "M", 100, genesis)
	l2 := newV2Receipt("L2", 2, 50, l1.ReceiptHash)

	if total, broken := VerifyReceiptHashes([]Receipt{r1, r2, r3}); total != 3 || broken != 0 {
		t.Fatalf("clean v2 chain: total=%d broken=%d", total, broken)
	}
	if total, broken := VerifyReceiptHashes([]Receipt{l1, l2}); total != 2 || broken != 0 {
		t.Fatalf("legacy + v2 chain: total=%d broken=%d", total, broken)
	}

	// Amount changed, hash left alone: must fail (the audit finding).
	tampered := r2
	tampered.Amount = 70
	if _, broken := VerifyReceiptHashes([]Receipt{r1, tampered, r3}); broken != 1 {
		t.Fatalf("amount tamper on v2 receipt: broken=%d, want 1", broken)
	}
	// Same on a legacy receipt.
	lt := l1
	lt.Amount = 1
	if _, broken := VerifyReceiptHashes([]Receipt{lt, l2}); broken != 1 {
		t.Fatalf("amount tamper on legacy receipt: broken=%d, want 1", broken)
	}
	// Months changed on v2 (not covered by v1).
	mt := r2
	mt.PaidMonths = []string{"2030-01"}
	if _, broken := VerifyReceiptHashes([]Receipt{r1, mt, r3}); broken != 1 {
		t.Fatalf("months tamper: broken=%d, want 1", broken)
	}
	// Receipt removed: next receipt's link no longer matches.
	if _, broken := VerifyReceiptHashes([]Receipt{r1, r3}); broken != 1 {
		t.Fatalf("removed receipt: broken=%d, want 1", broken)
	}
	// Attacker recomputes the hash of the edited receipt: its successor's link breaks.
	forged := r2
	forged.Amount = 70
	forged.ReceiptHash = forged.ComputeHash()
	if _, broken := VerifyReceiptHashes([]Receipt{r1, forged, r3}); broken != 1 {
		t.Fatalf("re-hashed forgery: broken=%d, want 1", broken)
	}
	// Downgrading a v2 receipt to HashVersion 1 must not make it verify.
	down := r2
	down.HashVersion = 0
	if _, broken := VerifyReceiptHashes([]Receipt{r1, down, r3}); broken == 0 {
		t.Fatal("version downgrade went undetected")
	}
}

func TestRefundStateMachine(t *testing.T) {
	txn := Transaction{Amount: 500, Status: TxnSuccess}
	if err := CheckRefund(&txn, 200); err != nil {
		t.Fatal(err)
	}
	txn.Status, txn.RefundedAmount = TxnPartiallyRefunded, 200
	if err := CheckRefund(&txn, 300); err != nil {
		t.Fatalf("exact remainder must be allowed: %v", err)
	}
	if err := CheckRefund(&txn, 300.01); !errors.Is(err, ErrRefundExceedsRemaining) {
		t.Fatalf("over-cap: %v", err)
	}
	if err := CheckRefund(&txn, 0); !errors.Is(err, ErrRefundAmountInvalid) {
		t.Fatalf("zero: %v", err)
	}
	if err := CheckRefund(&txn, -5); !errors.Is(err, ErrRefundAmountInvalid) {
		t.Fatalf("negative: %v", err)
	}
	for _, st := range []PaymentStatus{TxnRefunded, TxnPending, TxnFailed, TxnInitialized} {
		bad := Transaction{Amount: 500, Status: st}
		if err := CheckRefund(&bad, 10); !errors.Is(err, ErrRefundNotAllowed) {
			t.Fatalf("%s must not be refundable: %v", st, err)
		}
	}
	if RefundStatusAfter(&txn, 200) != TxnPartiallyRefunded || RefundStatusAfter(&txn, 500) != TxnRefunded || RefundStatusAfter(&txn, 0) != TxnSuccess {
		t.Fatal("RefundStatusAfter")
	}
}
