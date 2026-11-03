package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readconcern"
	"go.mongodb.org/mongo-driver/v2/mongo/writeconcern"
)

var (
	ErrInvalidAmount       = errors.New("amount does not match expected total for selected months")
	ErrNonSequentialMonths = errors.New("selected months must be contiguous sequence starting from next unpaid month")
	ErrDuplicateInFlight   = errors.New("payment with this idempotency key is already processing")
	ErrMemberNotFound      = errors.New("member not found in this tenant")
	ErrInvalidMonthFormat  = errors.New("invalid month format, must be YYYY-MM")
	ErrTxnUnavailable      = errors.New("financial transactions require MongoDB replica set with ACID support")
	ErrNotCommittable      = errors.New("transaction cannot be committed in its current state")
	ErrIdempotencyConflict = errors.New("idempotency key already used for a different payment")
	errLostCommitRace      = errors.New("transaction was committed concurrently")
)

// Per-tenant serialized ledger locks to guarantee 100% linear hash chains without forking
var tenantLedgerLocks sync.Map

func getTenantLedgerLock(mahalID string) *sync.Mutex {
	val, _ := tenantLedgerLocks.LoadOrStore(mahalID, &sync.Mutex{})
	return val.(*sync.Mutex)
}

type PaymentService interface {
	InitializeDuesPayment(ctx context.Context, mahalID, memberID string, months []string, gateway, idempotencyKey string) (*domain.Transaction, error)
	InitializeContribution(ctx context.Context, mahalID, memberID string, amount float64, gateway, idempotencyKey string, details ContributionDetails) (*domain.Transaction, error)
	// CommitSuccessfulPayment books a PENDING transaction exactly once. A
	// transaction that is already SUCCESS returns its own receipt.
	CommitSuccessfulPayment(ctx context.Context, txnID string) (*domain.Receipt, error)
	// AppendRefundEntry appends an offsetting (negative amount) entry to the
	// hash chain for a refund of amount against txn. refundRef is the gateway
	// or internal reference. The original receipt is never modified.
	AppendRefundEntry(ctx context.Context, txn *domain.Transaction, amount float64, refundRef string) (*domain.Receipt, error)
	// SetAllowStandaloneCommit permits the non-atomic single-node fallback
	// when MongoDB has no replica-set transactions. Development only.
	SetAllowStandaloneCommit(allow bool)
	// SetReceiptIssuedHook registers an optional post-commit side effect
	// (e.g. sending the member their receipt). Safe to leave unset.
	SetReceiptIssuedHook(hook func(receipt *domain.Receipt))
}

// ContributionDetails is the optional description of a contribution, carried
// from the transaction onto its receipt.
type ContributionDetails struct {
	Purpose string // fund, e.g. ZAKAT, BUILDING_FUND (receipt.fund)
	Note    string // member's free-text message
}

// Limits for ContributionDetails.
const (
	MaxPurposeLength = 64
	MaxNoteLength    = 280
)

type paymentService struct {
	mongoClient *mongo.Client
	mahalRepo   repository.MahalRepository
	memberRepo  repository.MemberRepository
	txnRepo     repository.TransactionRepository
	receiptRepo repository.ReceiptRepository

	// allowStandalone enables the dev-only non-atomic commit fallback.
	allowStandalone bool
	// txRunner replaces the MongoDB transaction wrapper (tests only).
	txRunner func(ctx context.Context, fn func(ctx context.Context) (*domain.Receipt, error)) (*domain.Receipt, error)

	// onReceiptIssued is an optional side-effect hook fired after a payment is
	// durably committed. It runs in its own goroutine and its outcome is
	// ignored, so notification delivery can never influence the ledger.
	onReceiptIssued func(receipt *domain.Receipt)
}

func NewPaymentService(
	client *mongo.Client,
	mahalRepo repository.MahalRepository,
	memberRepo repository.MemberRepository,
	txnRepo repository.TransactionRepository,
	receiptRepo repository.ReceiptRepository,
) PaymentService {
	return &paymentService{
		mongoClient: client,
		mahalRepo:   mahalRepo,
		memberRepo:  memberRepo,
		txnRepo:     txnRepo,
		receiptRepo: receiptRepo,
	}
}

func getNextMonth(currentMonth string) (string, error) {
	t, err := time.Parse("2006-01", currentMonth)
	if err != nil {
		return "", fmt.Errorf("%w: %s", ErrInvalidMonthFormat, currentMonth)
	}
	next := time.Date(t.Year(), t.Month()+1, 15, 0, 0, 0, 0, time.UTC)
	return next.Format("2006-01"), nil
}

// Validates that selected months form an unbroken contiguous sequence starting immediately after lastPaidMonth
func ValidateContiguousMonths(lastPaidMonth string, selectedMonths []string) error {
	if len(selectedMonths) == 0 {
		return errors.New("at least one month must be selected")
	}

	// 1. Format check and duplicate detection
	seen := make(map[string]bool)
	for _, m := range selectedMonths {
		if _, err := time.Parse("2006-01", m); err != nil {
			return fmt.Errorf("%w: %s", ErrInvalidMonthFormat, m)
		}
		if seen[m] {
			return fmt.Errorf("duplicate month %s in selection", m)
		}
		seen[m] = true
	}

	// 2. Continuity check with lastPaidMonth
	if lastPaidMonth != "" {
		expected, err := getNextMonth(lastPaidMonth)
		if err != nil {
			return err
		}
		if selectedMonths[0] != expected {
			return fmt.Errorf("%w: first selected month %s must immediately follow last paid month %s (expected %s)",
				ErrNonSequentialMonths, selectedMonths[0], lastPaidMonth, expected)
		}
	}

	// 3. Internal sequence continuity check (e.g. 2026-06 -> 2026-07 -> 2026-08)
	for i := 1; i < len(selectedMonths); i++ {
		expected, err := getNextMonth(selectedMonths[i-1])
		if err != nil {
			return err
		}
		if selectedMonths[i] != expected {
			return fmt.Errorf("%w: month %s must immediately follow %s (expected %s)",
				ErrNonSequentialMonths, selectedMonths[i], selectedMonths[i-1], expected)
		}
	}

	return nil
}

// normalizeIdempotencyKey gives every transaction a key: callers that send
// none get a unique one, so two keyless requests can never collide on (and be
// merged through) the empty string.
func normalizeIdempotencyKey(key string) string {
	key = strings.TrimSpace(key)
	if key == "" {
		return "AUTO_" + strings.ReplaceAll(uuid.New().String(), "-", "")
	}
	return key
}

// createIdempotent inserts txn. On a duplicate (mahal_id, idempotency_key) it
// returns the earlier transaction of the SAME tenant when it is the same
// member and payment type; anything else is a conflict, never another
// tenant's data.
func (s *paymentService) createIdempotent(ctx context.Context, txn *domain.Transaction) (*domain.Transaction, error) {
	err := s.txnRepo.Create(ctx, txn)
	if err == nil {
		return txn, nil
	}
	if !mongo.IsDuplicateKeyError(err) && !strings.Contains(err.Error(), "duplicate key") {
		return nil, err
	}
	existing, fErr := s.txnRepo.FindByIDempotencyKey(ctx, txn.MahalID, txn.IdempotencyKey)
	if fErr != nil || existing == nil {
		return nil, err
	}
	if existing.MahalID != txn.MahalID || existing.MemberID != txn.MemberID || existing.Type != txn.Type {
		return nil, ErrIdempotencyConflict
	}
	return existing, nil
}

func (s *paymentService) InitializeDuesPayment(
	ctx context.Context,
	mahalID, memberID string,
	months []string,
	gateway, idempotencyKey string,
) (*domain.Transaction, error) {
	if len(months) == 0 {
		return nil, errors.New("at least one month must be selected")
	}
	idempotencyKey = normalizeIdempotencyKey(idempotencyKey)

	// 1. Strict Tenant Isolation Check
	member, err := s.memberRepo.GetByID(ctx, mahalID, memberID)
	if err != nil || member == nil {
		return nil, ErrMemberNotFound
	}

	// 2. Sequential Contiguous Months Validation
	if err := ValidateContiguousMonths(member.LastPaidMonth, months); err != nil {
		return nil, err
	}

	// 3. Exact Dues Rate Calculation using Integer Minor Units (Paise)
	rate := member.MonthlyDuesCustomAmount
	if rate <= 0 {
		mahal, err := s.mahalRepo.GetByID(ctx, mahalID)
		if err != nil {
			return nil, err
		}
		rate = mahal.Settings.DefaultMonthlyDues
	}

	// Minor-unit integer arithmetic to eliminate floating-point rounding drift
	ratePaise := domain.ToPaise(rate)
	totalPaise := domain.MoneyPaise(int64(len(months))) * ratePaise
	totalAmount := totalPaise.ToRupees()

	// PayU transactionId strict constraint: alphanumeric only, <= 25 characters, unique
	rawUUID := strings.ReplaceAll(uuid.New().String(), "-", "")
	txn := &domain.Transaction{
		ID:             "TXN" + rawUUID[:16],
		MahalID:        mahalID,
		MemberID:       memberID,
		IdempotencyKey: idempotencyKey,
		Type:           "MONTHLY_DUES",
		Amount:         totalAmount,
		Currency:       "INR",
		SelectedMonths: months,
		Gateway:        gateway,
		Status:         domain.TxnPending,
		CreatedAt:      time.Now().UTC(),
	}

	return s.createIdempotent(ctx, txn)
}

func (s *paymentService) InitializeContribution(
	ctx context.Context,
	mahalID, memberID string,
	amount float64,
	gateway, idempotencyKey string,
	details ContributionDetails,
) (*domain.Transaction, error) {
	details.Purpose = strings.TrimSpace(details.Purpose)
	details.Note = strings.TrimSpace(details.Note)
	if len([]rune(details.Purpose)) > MaxPurposeLength {
		return nil, fmt.Errorf("purpose must be at most %d characters", MaxPurposeLength)
	}
	if len([]rune(details.Note)) > MaxNoteLength {
		return nil, fmt.Errorf("note must be at most %d characters", MaxNoteLength)
	}
	if amount <= 0 {
		return nil, errors.New("contribution amount must be strictly greater than zero")
	}
	idempotencyKey = normalizeIdempotencyKey(idempotencyKey)

	// Strict Tenant Isolation Check
	member, err := s.memberRepo.GetByID(ctx, mahalID, memberID)
	if err != nil || member == nil {
		return nil, ErrMemberNotFound
	}

	// Minor unit exact conversion
	exactPaise := domain.ToPaise(amount)
	exactAmount := exactPaise.ToRupees()

	rawUUID := strings.ReplaceAll(uuid.New().String(), "-", "")
	txn := &domain.Transaction{
		ID:             "TXN" + rawUUID[:16],
		MahalID:        mahalID,
		MemberID:       memberID,
		IdempotencyKey: idempotencyKey,
		Type:           "CONTRIBUTION",
		Amount:         exactAmount,
		Currency:       "INR",
		Gateway:        gateway,
		Purpose:        details.Purpose,
		Note:           details.Note,
		Status:         domain.TxnPending,
		CreatedAt:      time.Now().UTC(),
	}

	return s.createIdempotent(ctx, txn)
}

func (s *paymentService) SetAllowStandaloneCommit(allow bool) { s.allowStandalone = allow }

func (s *paymentService) CommitSuccessfulPayment(ctx context.Context, txnID string) (*domain.Receipt, error) {
	txn, err := s.txnRepo.GetByID(ctx, txnID)
	if err != nil {
		return nil, err
	}

	var created bool
	receipt, err := s.runLedgerOp(ctx, txn.MahalID, func(c context.Context) (*domain.Receipt, error) {
		r, isNew, e := s.executeCommit(c, txnID)
		created = isNew
		return r, e
	})
	if errors.Is(err, errLostCommitRace) {
		// Another committer won; hand back that transaction's own receipt.
		if cur, gErr := s.txnRepo.GetByID(ctx, txnID); gErr == nil && cur.Status == domain.TxnSuccess {
			return s.existingReceipt(ctx, cur)
		}
	}
	if err == nil && created {
		s.fireReceiptIssued(receipt)
	}
	return receipt, err
}

// runLedgerOp runs fn as one atomic ledger write for the tenant: serialised
// in-process per Mahal, inside a replica-set transaction. Without transaction
// support it fails closed with ErrTxnUnavailable unless the explicit
// development flag allows the non-atomic fallback.
func (s *paymentService) runLedgerOp(ctx context.Context, mahalID string, fn func(ctx context.Context) (*domain.Receipt, error)) (*domain.Receipt, error) {
	lock := getTenantLedgerLock(mahalID)
	lock.Lock()
	defer lock.Unlock()

	run := s.inTransaction
	if s.txRunner != nil {
		run = s.txRunner
	}
	receipt, err := run(ctx, fn)
	if err != nil && isTxnUnsupported(err) {
		if !s.allowStandalone {
			logger.Log.Error().Err(err).Msg("MongoDB transactions unavailable; refusing non-atomic ledger write (set up a replica set)")
			return nil, fmt.Errorf("%w: %v", ErrTxnUnavailable, err)
		}
		logger.Log.Warn().Msg("Standalone MongoDB: non-atomic ledger write allowed by ALLOW_STANDALONE_COMMIT (development only)")
		return fn(ctx)
	}
	return receipt, err
}

func isTxnUnsupported(err error) bool {
	msg := err.Error()
	return strings.Contains(msg, "Transaction numbers are only allowed") || strings.Contains(msg, "replica set")
}

// SetReceiptIssuedHook registers the post-commit side effect.
func (s *paymentService) SetReceiptIssuedHook(hook func(receipt *domain.Receipt)) {
	s.onReceiptIssued = hook
}

// fireReceiptIssued runs the hook detached from the request. It recovers from
// any panic so a bug in a notification path can never take down a payment.
func (s *paymentService) fireReceiptIssued(receipt *domain.Receipt) {
	if s.onReceiptIssued == nil || receipt == nil {
		return
	}
	hook := s.onReceiptIssued
	go func() {
		defer func() {
			if r := recover(); r != nil {
				logger.Log.Error().Interface("panic", r).
					Str("receipt_number", receipt.ReceiptNumber).
					Msg("Recovered from panic in receipt-issued hook")
			}
		}()
		hook(receipt)
	}()
}

func (s *paymentService) inTransaction(ctx context.Context, fn func(ctx context.Context) (*domain.Receipt, error)) (*domain.Receipt, error) {
	wc := writeconcern.Majority()
	rc := readconcern.Majority()
	txnOpts := options.Transaction().SetWriteConcern(wc).SetReadConcern(rc)

	session, err := s.mongoClient.StartSession()
	if err != nil {
		return nil, err
	}
	defer session.EndSession(ctx)

	var out *domain.Receipt
	_, err = session.WithTransaction(ctx, func(sessCtx context.Context) (interface{}, error) {
		r, err := fn(sessCtx)
		if err != nil {
			return nil, err
		}
		out = r
		return nil, nil
	}, txnOpts)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// existingReceipt returns the receipt that belongs to an already-SUCCESS
// transaction. It never falls back to "the latest receipt of the mahal".
func (s *paymentService) existingReceipt(ctx context.Context, txn *domain.Transaction) (*domain.Receipt, error) {
	if txn.ReceiptID == "" {
		return nil, fmt.Errorf("transaction %s is SUCCESS but has no receipt recorded", txn.ID)
	}
	r, err := s.receiptRepo.GetByNumberForMahal(ctx, txn.MahalID, txn.ReceiptID)
	if err != nil {
		return nil, err
	}
	if r == nil {
		return nil, fmt.Errorf("receipt %s of transaction %s not found", txn.ReceiptID, txn.ID)
	}
	return r, nil
}

// newReceipt allocates the next ledger slot for the tenant and returns an
// unsaved, v2-hashed receipt for the caller to fill in. Counter errors abort
// the operation: there is no guessed sequence number or genesis fallback.
func (s *paymentService) allocateReceipt(ctx context.Context, mahalID string) (*domain.Receipt, error) {
	seq, prevHash, err := s.receiptRepo.AllocateAtomicReceiptSequence(ctx, mahalID)
	if err != nil {
		return nil, err
	}
	if seq <= 0 {
		return nil, fmt.Errorf("receipt sequence allocation returned %d", seq)
	}
	// Millisecond precision: it is what MongoDB stores, so the stored receipt
	// recomputes to the same v2 hash.
	now := time.Now().UTC().Truncate(time.Millisecond)
	return &domain.Receipt{
		ID:                  "RCPT_" + uuid.New().String(),
		ReceiptNumber:       fmt.Sprintf("GV1MH%s%sR%05d", mahalID, now.Format("20060102"), seq),
		SequenceNumber:      seq,
		MahalID:             mahalID,
		PreviousReceiptHash: prevHash,
		CreatedAt:           now,
		HashVersion:         domain.ReceiptHashV2,
	}, nil
}

// sealAndStore hashes and inserts the receipt and advances the ledger head.
func (s *paymentService) sealAndStore(ctx context.Context, receipt *domain.Receipt) error {
	receipt.ReceiptHash = receipt.ComputeHash()
	if err := s.receiptRepo.Insert(ctx, receipt); err != nil {
		return err
	}
	return s.receiptRepo.UpdateLedgerHeadHash(ctx, receipt.MahalID, receipt.SequenceNumber, receipt.ReceiptHash)
}

func (s *paymentService) executeCommit(ctx context.Context, txnID string) (*domain.Receipt, bool, error) {
	txn, err := s.txnRepo.GetByID(ctx, txnID)
	if err != nil {
		return nil, false, err
	}
	switch txn.Status {
	case domain.TxnSuccess:
		r, err := s.existingReceipt(ctx, txn)
		return r, false, err
	case domain.TxnPending:
	default:
		return nil, false, fmt.Errorf("%w: transaction %s is %s", ErrNotCommittable, txn.ID, txn.Status)
	}

	member, err := s.memberRepo.GetByID(ctx, txn.MahalID, txn.MemberID)
	if err != nil {
		return nil, false, err
	}

	receipt, err := s.allocateReceipt(ctx, txn.MahalID)
	if err != nil {
		return nil, false, err
	}
	receipt.MemberID = txn.MemberID
	receipt.MemberName = member.Name
	receipt.TransactionID = txn.ID
	receipt.PaymentType = txn.Type
	receipt.PaidMonths = txn.SelectedMonths
	receipt.Amount = txn.Amount
	receipt.Currency = txn.Currency
	if receipt.Currency == "" {
		receipt.Currency = "INR"
	}
	receipt.Fund = txn.Purpose
	// Descriptive only: not part of the legacy hash, and Fund/Currency above
	// are the only descriptive values the v2 hash covers.
	receipt.Status = domain.ReceiptStatusSuccess
	receipt.Gateway = ReceiptGateway(txn)
	receipt.PaymentMethod = ReceiptPaymentMethod(txn)
	receipt.Note = txn.Note

	if err := s.sealAndStore(ctx, receipt); err != nil {
		return nil, false, err
	}

	// Conditional PENDING -> SUCCESS: the atomic guard against double commit.
	won, err := s.txnRepo.MarkSuccess(ctx, txn.ID, receipt.ReceiptNumber)
	if err != nil {
		return nil, false, err
	}
	if !won {
		return nil, false, errLostCommitRace // aborts the transaction; receipt rolls back
	}

	// Update member paid months if dues. ApplyPaidMonths is idempotent for
	// months an earlier payment already covered.
	if txn.Type == "MONTHLY_DUES" && len(txn.SelectedMonths) > 0 {
		if err := s.memberRepo.ApplyPaidMonths(ctx, txn.MemberID, txn.SelectedMonths, txn.Amount); err != nil {
			return nil, false, err
		}
	}

	return receipt, true, nil
}

func (s *paymentService) AppendRefundEntry(ctx context.Context, txn *domain.Transaction, amount float64, refundRef string) (*domain.Receipt, error) {
	if domain.ToPaise(amount) <= 0 {
		return nil, domain.ErrRefundAmountInvalid
	}
	return s.runLedgerOp(ctx, txn.MahalID, func(c context.Context) (*domain.Receipt, error) {
		receipt, err := s.allocateReceipt(c, txn.MahalID)
		if err != nil {
			return nil, err
		}
		name := ""
		if m, mErr := s.memberRepo.GetByID(c, txn.MahalID, txn.MemberID); mErr == nil && m != nil {
			name = m.Name
		}
		receipt.MemberID = txn.MemberID
		receipt.MemberName = name
		receipt.TransactionID = txn.ID
		receipt.PaymentType = domain.ReceiptTypeRefund
		receipt.Amount = -domain.ToPaise(amount).ToRupees()
		receipt.Currency = txn.Currency
		if receipt.Currency == "" {
			receipt.Currency = "INR"
		}
		receipt.Fund = txn.Purpose
		receipt.Status = domain.ReceiptTypeRefund
		receipt.Gateway = ReceiptGateway(txn)
		receipt.PaymentMethod = ReceiptPaymentMethod(txn)
		receipt.Note = "Refund " + refundRef + " against " + txn.ID
		if err := s.sealAndStore(c, receipt); err != nil {
			return nil, err
		}
		return receipt, nil
	})
}

// ReceiptGateway names how a transaction was collected: CASH, PAYU_SI for an
// AutoPay installment, PAYU for any other online payment.
func ReceiptGateway(txn *domain.Transaction) string {
	switch {
	case strings.EqualFold(txn.Gateway, "CASH"):
		return "CASH"
	case strings.HasPrefix(txn.IdempotencyKey, "SI_"):
		return "PAYU_SI"
	case txn.Gateway == "":
		return ""
	default:
		return "PAYU"
	}
}

// ReceiptPaymentMethod is the instrument used: CASH for cash, else the mode
// the gateway reported (UPI / CARD / NETBANKING / WALLET), empty if unknown.
func ReceiptPaymentMethod(txn *domain.Transaction) string {
	if strings.EqualFold(txn.Gateway, "CASH") {
		return "CASH"
	}
	return domain.NormalizePaymentMode(txn.PaymentMode)
}
