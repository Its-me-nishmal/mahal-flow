package memory

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type mongoMemoryStore struct {
	coll *mongo.Collection
}

func NewMemoryStore(db *mongo.Database) MemoryStore {
	return &mongoMemoryStore{coll: db.Collection("agent_feedback_memory")}
}

func (s *mongoMemoryStore) RecordFeedback(ctx context.Context, record *FeedbackRecord) error {
	if record.CreatedAt.IsZero() {
		record.CreatedAt = time.Now().UTC()
	}
	_, err := s.coll.InsertOne(ctx, record)
	return err
}

func (s *mongoMemoryStore) GetHistoricalContext(ctx context.Context, mahalID string, agentType string, limit int) ([]FeedbackRecord, error) {
	filter := bson.M{"agent_type": agentType}
	if mahalID != "" {
		filter["mahal_id"] = mahalID
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "created_at", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := s.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var records []FeedbackRecord
	if err := cursor.All(ctx, &records); err != nil {
		return nil, err
	}
	return records, nil
}

func (s *mongoMemoryStore) GetAverageReward(ctx context.Context, agentType string, action string) (float64, error) {
	filter := bson.M{
		"agent_type":   agentType,
		"action_taken": action,
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: filter}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: nil},
			{Key: "avg_reward", Value: bson.D{{Key: "$avg", Value: "$outcome.reward_score"}}},
			{Key: "count", Value: bson.D{{Key: "$sum", Value: 1}}},
		}}},
	}

	cursor, err := s.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	if !cursor.Next(ctx) {
		return 0, nil
	}

	var result struct {
		AvgReward float64 `bson:"avg_reward"`
		Count     int64   `bson:"count"`
	}
	if err := cursor.Decode(&result); err != nil {
		return 0, err
	}

	return result.AvgReward, nil
}
