package agent

import (
	"context"
	"sync"
	"time"

	"github.com/mahalflow/backend-go/internal/agent/memory"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/rs/zerolog/log"
)

const (
	fraudCheckInterval    = 30 * time.Second
	velocityWindow        = 2 * time.Minute
	maxFailedAttempts     = 3
	refundSpikeThreshold  = 0.05
)

type FraudGuardAgent struct {
	txnRepo     repository.TransactionRepository
	memoryStore memory.MemoryStore
	eventBus    *EventBus

	mu          sync.Mutex
	frozenIPs   map[string]time.Time
	frozenDevs  map[string]time.Time
}

func NewFraudGuardAgent(
	txnRepo repository.TransactionRepository,
	memoryStore memory.MemoryStore,
	eventBus *EventBus,
) Agent {
	return &FraudGuardAgent{
		txnRepo:     txnRepo,
		memoryStore: memoryStore,
		eventBus:    eventBus,
		frozenIPs:   make(map[string]time.Time),
		frozenDevs:  make(map[string]time.Time),
	}
}

func (a *FraudGuardAgent) Name() AgentType { return AgentFraudGuard }

func (a *FraudGuardAgent) Interval() time.Duration { return fraudCheckInterval }

func (a *FraudGuardAgent) Run(ctx context.Context) error {
	log.Debug().Str("agent", string(a.Name())).Msg("Running fraud anomaly scan")
	a.cleanExpiredFreezes()
	return nil
}

func (a *FraudGuardAgent) EvaluateTransaction(ctx context.Context, txn domain.Transaction, clientIP, deviceID string) (bool, string) {
	a.mu.Lock()
	defer a.mu.Unlock()

	if frozen, ok := a.frozenIPs[clientIP]; ok && time.Now().UTC().Before(frozen) {
		return true, "IP address is frozen due to fraud detection"
	}
	if frozen, ok := a.frozenDevs[deviceID]; ok && time.Now().UTC().Before(frozen) {
		return true, "Device is frozen due to fraud detection"
	}

	failedCountIP, err := a.txnRepo.CountFailedByIP(ctx, clientIP, velocityWindow)
	if err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(a.Name())).Msg("Failed to check IP velocity")
	} else if failedCountIP >= int64(maxFailedAttempts) {
		a.frozenIPs[clientIP] = time.Now().UTC().Add(30 * time.Minute)
		a.publishFraudEvent(ctx, txn, "VELOCITY_IP", clientIP)
		return true, "Velocity threshold exceeded for IP address"
	}

	failedCountDevice, err := a.txnRepo.CountFailedByDevice(ctx, deviceID, velocityWindow)
	if err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(a.Name())).Msg("Failed to check device velocity")
	} else if failedCountDevice >= int64(maxFailedAttempts) {
		a.frozenDevs[deviceID] = time.Now().UTC().Add(30 * time.Minute)
		a.publishFraudEvent(ctx, txn, "VELOCITY_DEVICE", deviceID)
		return true, "Velocity threshold exceeded for device"
	}

	if txn.Type == "CONTRIBUTION" && txn.Amount > 100000 {
		a.publishFraudEvent(ctx, txn, "HIGH_VALUE_CONTRIBUTION", "")
	}

	return false, ""
}

func (a *FraudGuardAgent) EvaluateRefundRequest(ctx context.Context, mahalID string, refundAmount float64) (bool, string) {
	monthStart := time.Now().UTC().AddDate(0, 0, -time.Now().UTC().Day()+1)
	totalCollection, err := a.txnRepo.GetTotalCollectionByMahal(ctx, mahalID, monthStart)
	if err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(a.Name())).Msg("Failed to get collection total")
		return false, ""
	}

	if totalCollection > 0 {
		refundRatio := refundAmount / totalCollection
		if refundRatio > refundSpikeThreshold {
			a.publishFraudEvent(ctx, domain.Transaction{
				MahalID: mahalID,
				Amount:  refundAmount,
			}, "REFUND_SPIKE", "")
			return true, "Refund spike detected: ratio exceeds 5% of monthly collection"
		}
	}

	return false, ""
}

func (a *FraudGuardAgent) publishFraudEvent(ctx context.Context, txn domain.Transaction, reason, identifier string) {
	a.recordFeedback(ctx, txn.MahalID, reason, txn.ID, 0.0)

	a.eventBus.Publish(Event{
		Type: EventFraudDetected,
		Payload: map[string]interface{}{
			"txn_id":      txn.ID,
			"mahal_id":    txn.MahalID,
			"member_id":   txn.MemberID,
			"amount":      txn.Amount,
			"reason":      reason,
			"identifier":  identifier,
			"frozen_at":   time.Now().UTC(),
		},
	})
}

func (a *FraudGuardAgent) cleanExpiredFreezes() {
	now := time.Now().UTC()
	for ip, expires := range a.frozenIPs {
		if now.After(expires) {
			delete(a.frozenIPs, ip)
		}
	}
	for dev, expires := range a.frozenDevs {
		if now.After(expires) {
			delete(a.frozenDevs, dev)
		}
	}
}

func (a *FraudGuardAgent) recordFeedback(ctx context.Context, mahalID, reason, txnID string, score float64) {
	record := &memory.FeedbackRecord{
		MahalID:   mahalID,
		AgentType: string(AgentFraudGuard),
		Context: map[string]interface{}{
			"txn_id": txnID,
			"reason": reason,
		},
		ActionTaken: reason,
		Outcome: memory.FeedbackOutcome{
			Converted:   score > 0.5,
			RewardScore: score,
		},
		CreatedAt: time.Now().UTC(),
	}
	if err := a.memoryStore.RecordFeedback(ctx, record); err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(AgentFraudGuard)).Msg("Failed to record fraud feedback")
	}
}
