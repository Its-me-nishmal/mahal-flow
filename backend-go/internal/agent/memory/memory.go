package memory

import (
	"context"
	"time"
)

// FeedbackRecord represents the feedback stored for self-learning agents
type FeedbackRecord struct {
	ID          string                 `bson:"_id" json:"id"`
	MahalID     string                 `bson:"mahal_id" json:"mahal_id"`
	AgentType   string                 `bson:"agent_type" json:"agent_type"`
	Context     map[string]interface{} `bson:"context" json:"context"`
	ActionTaken string                 `bson:"action_taken" json:"action_taken"`
	Outcome     FeedbackOutcome        `bson:"outcome" json:"outcome"`
	CreatedAt   time.Time              `bson:"created_at" json:"created_at"`
}

type FeedbackOutcome struct {
	Converted     bool    `bson:"converted" json:"converted"`
	AdminOverride bool    `bson:"admin_override" json:"admin_override"`
	RewardScore   float64 `bson:"reward_score" json:"reward_score"` // 0.0 to 1.0
	Notes         string  `bson:"notes,omitempty" json:"notes,omitempty"`
}

// MemoryStore provides persistent episodic storage for continuous agent learning
type MemoryStore interface {
	RecordFeedback(ctx context.Context, record *FeedbackRecord) error
	GetHistoricalContext(ctx context.Context, mahalID string, agentType string, limit int) ([]FeedbackRecord, error)
	GetAverageReward(ctx context.Context, agentType string, action string) (float64, error)
}
