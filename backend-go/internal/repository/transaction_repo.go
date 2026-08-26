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
