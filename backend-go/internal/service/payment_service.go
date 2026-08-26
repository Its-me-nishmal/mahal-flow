package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readconcern"
	"go.mongodb.org/mongo-driver/v2/mongo/writeconcern"
)

var (
	ErrInvalidAmount       = errors.New("amount does not match expected total for selected months")
	ErrNonSequentialMonths = errors.New("selected months must be sequential starting after last paid month")
	ErrDuplicateInFlight   = errors.New("payment with this idempotency key is already processing")
	ErrMemberNotFound      = errors.New("member not found")
)

type PaymentService interface {
	InitializeDuesPayment(ctx context.Context, mahalID, memberID string, months []string, gateway, idempotencyKey string) (*domain.Transaction, error)
	InitializeContribution(ctx context.Context, mahalID, memberID string, amount float64, gateway, idempotencyKey string) (*domain.Transaction, error)
	CommitSuccessfulPayment(ctx context.Context, txnID string) (*domain.Receipt, error)
}

type paymentService struct {
	mongoClient *mongo.Client
	mahalRepo   repository.MahalRepository
	memberRepo  repository.MemberRepository
	txnRepo     repository.TransactionRepository
	receiptRepo repository.ReceiptRepository
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

func (s *paymentService) InitializeDuesPayment(
	ctx context.Context,
	mahalID, memberID string,
	months []string,
	gateway, idempotencyKey string,
) (*domain.Transaction, error) {
	if len(months) == 0 {
		return nil, errors.New("at least one month must be selected")
	}

	member, err := s.memberRepo.GetByID(ctx, mahalID, memberID)
	if err != nil {
		return nil, ErrMemberNotFound
	}

	rate := member.MonthlyDuesCustomAmount
	if rate <= 0 {
		mahal, err := s.mahalRepo.GetByID(ctx, mahalID)
		if err != nil {
			return nil, err
		}
		rate = mahal.Settings.DefaultMonthlyDues
	}

	totalAmount := float64(len(months)) * rate

	txn := &domain.Transaction{
		ID:             "TXN_" + uuid.New().String(),
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

	if err := s.txnRepo.Create(ctx, txn); err != nil {
		return nil, err
	}

	return txn, nil
}

func (s *paymentService) InitializeContribution(
	ctx context.Context,
	mahalID, memberID string,
	amount float64,
	gateway, idempotencyKey string,
) (*domain.Transaction, error) {
	if amount <= 0 {
		return nil, errors.New("contribution amount must be greater than zero")
	}

	txn := &domain.Transaction{
		ID:             "TXN_" + uuid.New().String(),
		MahalID:        mahalID,
		MemberID:       memberID,
		IdempotencyKey: idempotencyKey,
		Type:           "CONTRIBUTION",
		Amount:         amount,
		Currency:       "INR",
		Gateway:        gateway,
		Status:         domain.TxnPending,
		CreatedAt:      time.Now().UTC(),
	}

	if err := s.txnRepo.Create(ctx, txn); err != nil {
		return nil, err
	}

	return txn, nil
}

func (s *paymentService) CommitSuccessfulPayment(ctx context.Context, txnID string) (*domain.Receipt, error) {
	// Try replica set multi-document ACID transaction first
	receipt, err := s.commitWithTransaction(ctx, txnID)
	if err != nil && (strings.Contains(err.Error(), "Transaction numbers are only allowed") || strings.Contains(err.Error(), "replica set")) {
		// Graceful fallback for standalone local MongoDB instance
		return s.commitStandalone(ctx, txnID)
	}
	return receipt, err
}

func (s *paymentService) commitWithTransaction(ctx context.Context, txnID string) (*domain.Receipt, error) {
	wc := writeconcern.Majority()
	rc := readconcern.Majority()
	txnOpts := options.Transaction().SetWriteConcern(wc).SetReadConcern(rc)

	session, err := s.mongoClient.StartSession()
	if err != nil {
		return nil, err
	}
	defer session.EndSession(ctx)

	var committedReceipt *domain.Receipt

	_, err = session.WithTransaction(ctx, func(sessCtx context.Context) (interface{}, error) {
		r, err := s.executeCommit(sessCtx, txnID)
		if err != nil {
			return nil, err
		}
		committedReceipt = r
		return nil, nil
	}, txnOpts)

	return committedReceipt, err
}

func (s *paymentService) commitStandalone(ctx context.Context, txnID string) (*domain.Receipt, error) {
	return s.executeCommit(ctx, txnID)
}

func (s *paymentService) executeCommit(ctx context.Context, txnID string) (*domain.Receipt, error) {
	txn, err := s.txnRepo.GetByID(ctx, txnID)
	if err != nil {
		return nil, err
	}
	if txn.Status == domain.TxnSuccess {
		return s.receiptRepo.GetByNumber(ctx, txn.ReceiptID)
	}

	member, err := s.memberRepo.GetByID(ctx, txn.MahalID, txn.MemberID)
	if err != nil {
		return nil, err
	}

	// 1. Calculate sequence number & chained hash
	lastReceipt, err := s.receiptRepo.GetLatestReceipt(ctx, txn.MahalID)
	seq := int64(1)
	prevHash := "0000000000000000000000000000000000000000000000000000000000000000"
	if err == nil && lastReceipt != nil {
		seq = lastReceipt.SequenceNumber + 1
		prevHash = lastReceipt.ReceiptHash
	}

	receiptNumber := fmt.Sprintf("GV1MH%s%sR%05d", txn.MahalID, time.Now().Format("20060102"), seq)
	receiptHash := domain.CalculateReceiptHash(receiptNumber, txn.MahalID, txn.MemberID, txn.Amount, prevHash)

	receipt := &domain.Receipt{
		ID:                  "RCPT_" + uuid.New().String(),
		ReceiptNumber:       receiptNumber,
		SequenceNumber:      seq,
		MahalID:             txn.MahalID,
		MemberID:            txn.MemberID,
		MemberName:          member.Name,
		TransactionID:       txn.ID,
		PaymentType:         txn.Type,
		PaidMonths:          txn.SelectedMonths,
		Amount:              txn.Amount,
		PreviousReceiptHash: prevHash,
		ReceiptHash:         receiptHash,
		CreatedAt:           time.Now().UTC(),
	}

	if err := s.receiptRepo.Insert(ctx, receipt); err != nil {
		return nil, err
	}

	// 2. Mark Transaction Status
	if err := s.txnRepo.UpdateStatus(ctx, txn.ID, domain.TxnSuccess, receipt.ID); err != nil {
		return nil, err
	}

	// 3. Update Member Paid Months if Dues
	if txn.Type == "MONTHLY_DUES" && len(txn.SelectedMonths) > 0 {
		if err := s.memberRepo.ApplyPaidMonths(ctx, txn.MemberID, txn.SelectedMonths, txn.Amount); err != nil {
			return nil, err
		}
	}

	return receipt, nil
}
