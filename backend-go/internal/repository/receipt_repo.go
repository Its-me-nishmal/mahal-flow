package repository

import (
	"context"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type ReceiptRepository interface {
	Insert(ctx context.Context, receipt *domain.Receipt) error
	GetLatestReceipt(ctx context.Context, mahalID string) (*domain.Receipt, error)
	GetByNumber(ctx context.Context, receiptNumber string) (*domain.Receipt, error)
}

type mongoReceiptRepo struct {
	coll *mongo.Collection
}

func NewReceiptRepository(db *mongo.Database) ReceiptRepository {
	return &mongoReceiptRepo{coll: db.Collection("receipts")}
}

func (r *mongoReceiptRepo) Insert(ctx context.Context, receipt *domain.Receipt) error {
	_, err := r.coll.InsertOne(ctx, receipt)
	return err
}

func (r *mongoReceiptRepo) GetLatestReceipt(ctx context.Context, mahalID string) (*domain.Receipt, error) {
	opts := options.FindOne().SetSort(bson.D{{Key: "sequence_number", Value: -1}})
	var receipt domain.Receipt
	err := r.coll.FindOne(ctx, bson.M{"mahal_id": mahalID}, opts).Decode(&receipt)
	if err != nil {
		return nil, err
	}
	return &receipt, nil
}

func (r *mongoReceiptRepo) GetByNumber(ctx context.Context, receiptNumber string) (*domain.Receipt, error) {
	var receipt domain.Receipt
	err := r.coll.FindOne(ctx, bson.M{"receipt_number": receiptNumber}).Decode(&receipt)
	if err != nil {
		return nil, err
	}
	return &receipt, nil
}
