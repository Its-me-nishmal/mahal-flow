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
	GetNextSequenceNumber(ctx context.Context, mahalID string) (int64, error)
	GetByNumber(ctx context.Context, receiptNumber string) (*domain.Receipt, error)
	GetByMemberID(ctx context.Context, mahalID, memberID string) ([]domain.Receipt, error)
	GetAllByMahal(ctx context.Context, mahalID string, limit int64) ([]domain.Receipt, error)
	VerifyReceiptChain(ctx context.Context, mahalID string) (int64, int64, error)
}

type mongoReceiptRepo struct {
	coll     *mongo.Collection
	counters *mongo.Collection
}

func NewReceiptRepository(db *mongo.Database) ReceiptRepository {
	return &mongoReceiptRepo{
		coll:     db.Collection("receipts"),
		counters: db.Collection("counters"),
	}
}

func (r *mongoReceiptRepo) Insert(ctx context.Context, receipt *domain.Receipt) error {
	_, err := r.coll.InsertOne(ctx, receipt)
	return err
}

func (r *mongoReceiptRepo) GetNextSequenceNumber(ctx context.Context, mahalID string) (int64, error) {
	filter := bson.M{"mahal_id": mahalID, "counter_type": "RECEIPT"}
	update := bson.M{"$inc": bson.M{"seq": int64(1)}}
	opts := options.FindOneAndUpdate().SetUpsert(true).SetReturnDocument(options.After)

	var doc struct {
		Seq int64 `bson:"seq"`
	}
	err := r.counters.FindOneAndUpdate(ctx, filter, update, opts).Decode(&doc)
	if err != nil {
		latest, lErr := r.GetLatestReceipt(ctx, mahalID)
		if lErr == nil && latest != nil {
			return latest.SequenceNumber + 1, nil
		}
		return 1, nil
	}
	return doc.Seq, nil
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

func (r *mongoReceiptRepo) GetByMemberID(ctx context.Context, mahalID, memberID string) ([]domain.Receipt, error) {
	opts := options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}})
	filter := bson.M{}
	if mahalID != "" {
		filter["mahal_id"] = mahalID
	}
	if memberID != "" {
		filter["member_id"] = memberID
	}
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var receipts []domain.Receipt
	if err := cursor.All(ctx, &receipts); err != nil {
		return nil, err
	}
	if receipts == nil {
		receipts = []domain.Receipt{}
	}
	return receipts, nil
}

func (r *mongoReceiptRepo) GetAllByMahal(ctx context.Context, mahalID string, limit int64) ([]domain.Receipt, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "sequence_number", Value: 1}}).
		SetLimit(limit)
	filter := bson.M{"mahal_id": mahalID}
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var receipts []domain.Receipt
	if err := cursor.All(ctx, &receipts); err != nil {
		return nil, err
	}
	return receipts, nil
}

func (r *mongoReceiptRepo) VerifyReceiptChain(ctx context.Context, mahalID string) (total int64, broken int64, err error) {
	receipts, err := r.GetAllByMahal(ctx, mahalID, 0)
	if err != nil {
		return 0, 0, err
	}
	total = int64(len(receipts))
	for i := 1; i < len(receipts); i++ {
		expectedPrev := receipts[i-1].ReceiptHash
		if receipts[i].PreviousReceiptHash != expectedPrev {
			broken++
		}
	}
	return total, broken, nil
}
