package agent

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
)

type AgentType string

const (
	AgentReconciliation AgentType = "RECONCILIATION_AUTO_HEAL"
	AgentSmartDunning   AgentType = "SMART_DUNNING_COMM"
	AgentFraudGuard     AgentType = "FRAUD_ANOMALY_GUARD"
	AgentExcelIngest    AgentType = "EXCEL_DATA_INGESTION"
	AgentCryptoAudit    AgentType = "CRYPTOGRAPHIC_AUDIT"
)

// Agent defines the uniform lifecycle for autonomous MahalFlow agents
type Agent interface {
	Name() AgentType
	Run(ctx context.Context) error
	Interval() time.Duration
}

// Orchestrator coordinates agent execution, health, and event dispatching
type Orchestrator struct {
	agents []Agent
}

func NewOrchestrator(agents ...Agent) *Orchestrator {
	return &Orchestrator{agents: agents}
}

func (o *Orchestrator) Start(ctx context.Context) {
	log.Info().Int("agents_count", len(o.agents)).Msg("Starting MahalFlow Multi-Agent Orchestration Engine")

	for _, ag := range o.agents {
		go func(a Agent) {
			ticker := time.NewTicker(a.Interval())
			defer ticker.Stop()

			// Run immediately on boot
			if err := a.Run(ctx); err != nil {
				log.Error().Err(err).Str("agent", string(a.Name())).Msg("Agent run error")
			}

			for {
				select {
				case <-ctx.Done():
					log.Info().Str("agent", string(a.Name())).Msg("Stopping agent on context cancel")
					return
				case <-ticker.C:
					if err := a.Run(ctx); err != nil {
						log.Error().Err(err).Str("agent", string(a.Name())).Msg("Agent scheduled run error")
					}
				}
			}
		}(ag)
	}
}
