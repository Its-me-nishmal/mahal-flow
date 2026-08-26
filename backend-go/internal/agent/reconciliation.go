package agent

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/agent/memory"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/rs/zerolog/log"
)

const (
	reconciliationInterval     = 5 * time.Minute
	reconciliationPendingCutoff = 3 * time.Minute
)

type ReconciliationAgent struct {
	txnRepo     repository.TransactionRepository
	receiptRepo repository.ReceiptRepository
	memberRepo  repository.MemberRepository
	mahalRepo   repository.MahalRepository
	paymentSvc  PaymentCommitter
	memoryStore memory.MemoryStore
	eventBus    *EventBus
}

type PaymentCommitter interface {
	CommitSuccessfulPayment(ctx context.Context, txnID string) (*domain.Receipt, error)
}

func NewReconciliationAgent(
	txnRepo repository.TransactionRepository,
	receiptRepo repository.ReceiptRepository,
	memberRepo repository.MemberRepository,
	mahalRepo repository.MahalRepository,
	paymentSvc PaymentCommitter,
	memoryStore memory.MemoryStore,
	eventBus *EventBus,
) Agent {
	return &ReconciliationAgent{
		txnRepo:     txnRepo,
		receiptRepo: receiptRepo,
		memberRepo:  memberRepo,
		mahalRepo:   mahalRepo,
		paymentSvc:  paymentSvc,
		memoryStore: memoryStore,
		eventBus:    eventBus,
	}
}

func (a *ReconciliationAgent) Name() AgentType { return AgentReconciliation }

func (a *ReconciliationAgent) Interval() time.Duration { return reconciliationInterval }

func (a *ReconciliationAgent) Run(ctx context.Context) error {
	log.Info().Str("agent", string(a.Name())).Msg("Starting reconciliation scan")

	txns, err := a.txnRepo.FindPendingOlderThan(ctx, reconciliationPendingCutoff)
	if err != nil {
		return err
	}

	if len(txns) == 0 {
		log.Debug().Str("agent", string(a.Name())).Msg("No pending transactions to reconcile")
		return nil
	}

	log.Info().Str("agent", string(a.Name())).Int("count", len(txns)).Msg("Found pending transactions for reconciliation")

	resolved := 0
	failed := 0

	for _, txn := range txns {
		if err := ctx.Err(); err != nil {
			return err
		}

		receipt, err := a.paymentSvc.CommitSuccessfulPayment(ctx, txn.ID)
		if err != nil {
			log.Warn().Err(err).Str("txn_id", txn.ID).Str("agent", string(a.Name())).Msg("Failed to reconcile transaction")
			failed++

			a.recordFeedback(ctx, txn.MahalID, "RECONCILIATION_FAILED", txn.ID, 0.0)
			continue
		}

		resolved++
		log.Info().
			Str("txn_id", txn.ID).
			Str("receipt_id", receipt.ID).
			Str("agent", string(a.Name())).
			Msg("Successfully reconciled transaction")

		a.recordFeedback(ctx, txn.MahalID, "RECONCILIATION_SUCCESS", txn.ID, 1.0)

		a.eventBus.Publish(Event{
			Type: EventPaymentResolved,
			Payload: map[string]interface{}{
				"txn_id":     txn.ID,
				"receipt_id": receipt.ID,
				"mahal_id":   txn.MahalID,
				"member_id":  txn.MemberID,
			},
		})
	}

	log.Info().
		Str("agent", string(a.Name())).
		Int("resolved", resolved).
		Int("failed", failed).
		Msg("Reconciliation scan complete")

	return nil
}

func (a *ReconciliationAgent) recordFeedback(ctx context.Context, mahalID, action, txnID string, score float64) {
	record := &memory.FeedbackRecord{
		MahalID:   mahalID,
		AgentType: string(AgentReconciliation),
		Context: map[string]interface{}{
			"txn_id": txnID,
		},
		ActionTaken: action,
		Outcome: memory.FeedbackOutcome{
			Converted:   score > 0.5,
			RewardScore: score,
		},
		CreatedAt: time.Now().UTC(),
	}
	if err := a.memoryStore.RecordFeedback(ctx, record); err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(a.Name())).Msg("Failed to record feedback")
	}
}
