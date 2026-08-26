package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type TransactionRepository interface {
	Create(ctx context.Context, txn *domain.Transaction) error
	GetByID(ctx context.Context, id string) (*domain.Transaction, error)
	UpdateStatus(ctx context.Context, id string, status domain.PaymentStatus, receiptID string) error
	FindPendingOlderThan(ctx context.Context, threshold time.Duration) ([]domain.Transaction, error)
	FindByIDempotencyKey(ctx context.Context, key string) (*domain.Transaction, error)
	CountFailedByIP(ctx context.Context, ip string, within time.Duration) (int64, error)
	CountFailedByDevice(ctx context.Context, deviceID string, within time.Duration) (int64, error)
	GetRecentRefundsByMahal(ctx context.Context, mahalID string, since time.Time) ([]domain.Transaction, error)
	GetTotalCollectionByMahal(ctx context.Context, mahalID string, since time.Time) (float64, error)
}

type mongoTxnRepo struct {
	coll *mongo.Collection
}

func NewTransactionRepository(db *mongo.Database) TransactionRepository {
	return &mongoTxnRepo{coll: db.Collection("transactions")}
}

func (r *mongoTxnRepo) Create(ctx context.Context, txn *domain.Transaction) error {
	_, err := r.coll.InsertOne(ctx, txn)
	return err
}

func (r *mongoTxnRepo) GetByID(ctx context.Context, id string) (*domain.Transaction, error) {
	var txn domain.Transaction
	err := r.coll.FindOne(ctx, bson.M{"_id": id}).Decode(&txn)
	if err != nil {
		return nil, err
	}
	return &txn, nil
}

func (r *mongoTxnRepo) UpdateStatus(ctx context.Context, id string, status domain.PaymentStatus, receiptID string) error {
	now := time.Now().UTC()
	update := bson.M{
		"$set": bson.M{
			"status":       status,
			"receipt_id":   receiptID,
			"completed_at": now,
		},
	}
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

func (r *mongoTxnRepo) FindPendingOlderThan(ctx context.Context, threshold time.Duration) ([]domain.Transaction, error) {
	cutoff := time.Now().UTC().Add(-threshold)
	filter := bson.M{
		"status":    domain.TxnPending,
		"created_at": bson.M{"$lte": cutoff},
	}
	cursor, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var txns []domain.Transaction
	if err := cursor.All(ctx, &txns); err != nil {
		return nil, err
	}
	return txns, nil
}

func (r *mongoTxnRepo) FindByIDempotencyKey(ctx context.Context, key string) (*domain.Transaction, error) {
	var txn domain.Transaction
	err := r.coll.FindOne(ctx, bson.M{"idempotency_key": key}).Decode(&txn)
	if err != nil {
		return nil, err
	}
	return &txn, nil
}

func (r *mongoTxnRepo) CountFailedByIP(ctx context.Context, ip string, within time.Duration) (int64, error) {
	since := time.Now().UTC().Add(-within)
	filter := bson.M{
		"status":     domain.TxnFailed,
		"failure_reason": bson.M{"$regex": ip, "$options": "i"},
		"created_at": bson.M{"$gte": since},
	}
	count, err := r.coll.CountDocuments(ctx, filter)
	return count, err
}

func (r *mongoTxnRepo) CountFailedByDevice(ctx context.Context, deviceID string, within time.Duration) (int64, error) {
	since := time.Now().UTC().Add(-within)
	filter := bson.M{
		"status":     domain.TxnFailed,
		"failure_reason": bson.M{"$regex": deviceID, "$options": "i"},
		"created_at": bson.M{"$gte": since},
	}
	count, err := r.coll.CountDocuments(ctx, filter)
	return count, err
}

func (r *mongoTxnRepo) GetRecentRefundsByMahal(ctx context.Context, mahalID string, since time.Time) ([]domain.Transaction, error) {
	filter := bson.M{
		"mahal_id":   mahalID,
		"type":       "CONTRIBUTION",
		"status":     domain.TxnRefunded,
		"created_at": bson.M{"$gte": since},
	}
	cursor, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var txns []domain.Transaction
	if err := cursor.All(ctx, &txns); err != nil {
		return nil, err
	}
	return txns, nil
}

func (r *mongoTxnRepo) GetTotalCollectionByMahal(ctx context.Context, mahalID string, since time.Time) (float64, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"mahal_id":   mahalID,
			"status":     domain.TxnSuccess,
			"created_at": bson.M{"$gte": since},
		}}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: nil},
			{Key: "total", Value: bson.D{{Key: "$sum", Value: "$amount"}}},
		}}},
	}
	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)
	if !cursor.Next(ctx) {
		return 0, nil
	}
	var result struct {
		Total float64 `bson:"total"`
	}
	if err := cursor.Decode(&result); err != nil {
		return 0, err
	}
	return result.Total, nil
}
