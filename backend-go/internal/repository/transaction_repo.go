package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type TransactionRepository interface {
	Create(ctx context.Context, txn *domain.Transaction) error
	GetByID(ctx context.Context, id string) (*domain.Transaction, error)
	ListAll(ctx context.Context, mahalID string, limit, skip int64) ([]domain.Transaction, int64, error)
	UpdateStatus(ctx context.Context, id string, status domain.PaymentStatus, receiptID string) error
	SetGatewayPaymentID(ctx context.Context, id, gatewayPaymentID string) error
	FindPendingOlderThan(ctx context.Context, threshold time.Duration) ([]domain.Transaction, error)
	FindByIDempotencyKey(ctx context.Context, key string) (*domain.Transaction, error)
	CountFailedByIP(ctx context.Context, ip string, within time.Duration) (int64, error)
	CountFailedByDevice(ctx context.Context, deviceID string, within time.Duration) (int64, error)
	GetRecentRefundsByMahal(ctx context.Context, mahalID string, since time.Time) ([]domain.Transaction, error)
	GetTotalCollectionByMahal(ctx context.Context, mahalID string, since time.Time) (float64, error)
	GetFinancialSummary(ctx context.Context, mahalID string) (totalCollected, duesCollected, donations float64, err error)
	// GetFinancialSummaryRange sums SUCCESS transactions collected in
	// [from, to) (nil = unbounded). A transaction is dated by completed_at,
	// falling back to created_at for rows without one.
	GetFinancialSummaryRange(ctx context.Context, mahalID string, from, to *time.Time) (FinancialSummary, error)
	// GetByIDs returns the tenant's transactions with the given ids, keyed by id.
	GetByIDs(ctx context.Context, mahalID string, ids []string) (map[string]domain.Transaction, error)
	// CountByMember counts the member's transactions that reached SUCCESS or REFUNDED.
	CountByMember(ctx context.Context, mahalID, memberID string) (int64, error)
	// SetPaymentDetails records what the gateway reported (mihpayid, mode);
	// empty values are left unchanged.
	SetPaymentDetails(ctx context.Context, id, gatewayPaymentID, paymentMode string) error
}

// FinancialSummary is a collected-money breakdown for a period.
type FinancialSummary struct {
	TotalCollected   float64 `json:"total_collected"`
	DuesCollected    float64 `json:"dues_collected"`
	Donations        float64 `json:"donations"`
	TransactionCount int64   `json:"transaction_count"`
}

type mongoTxnRepo struct {
	coll *mongo.Collection
}

func NewTransactionRepository(db *mongo.Database) TransactionRepository {
	return &mongoTxnRepo{coll: db.Collection("transactions")}
}

func (r *mongoTxnRepo) ListAll(ctx context.Context, mahalID string, limit, skip int64) ([]domain.Transaction, int64, error) {
	filter := bson.M{}
	if mahalID != "" {
		filter["mahal_id"] = mahalID
	}
	total, err := r.coll.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}
	opts := options.Find().SetLimit(limit).SetSkip(skip).SetSort(bson.D{{Key: "created_at", Value: -1}})
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)
	var txns []domain.Transaction
	if err := cursor.All(ctx, &txns); err != nil {
		return nil, 0, err
	}
	if txns == nil {
		txns = []domain.Transaction{}
	}
	return txns, total, nil
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

// SetGatewayPaymentID persists PayU's mihpayid on a transaction so a later
// refund can be issued without re-querying the gateway.
func (r *mongoTxnRepo) SetGatewayPaymentID(ctx context.Context, id, gatewayPaymentID string) error {
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id},
		bson.M{"$set": bson.M{"gateway_payment_id": gatewayPaymentID}})
	return err
}

func (r *mongoTxnRepo) FindPendingOlderThan(ctx context.Context, threshold time.Duration) ([]domain.Transaction, error) {
	cutoff := time.Now().UTC().Add(-threshold)
	filter := bson.M{
		"status":     domain.TxnPending,
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
		"status":         domain.TxnFailed,
		"failure_reason": bson.M{"$regex": ip, "$options": "i"},
		"created_at":     bson.M{"$gte": since},
	}
	count, err := r.coll.CountDocuments(ctx, filter)
	return count, err
}

func (r *mongoTxnRepo) CountFailedByDevice(ctx context.Context, deviceID string, within time.Duration) (int64, error) {
	since := time.Now().UTC().Add(-within)
	filter := bson.M{
		"status":         domain.TxnFailed,
		"failure_reason": bson.M{"$regex": deviceID, "$options": "i"},
		"created_at":     bson.M{"$gte": since},
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

func (r *mongoTxnRepo) GetFinancialSummary(ctx context.Context, mahalID string) (totalCollected, duesCollected, donations float64, err error) {
	match := bson.M{"status": domain.TxnSuccess}
	if mahalID != "" {
		match["mahal_id"] = mahalID
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: match}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: "$type"},
			{Key: "sum", Value: bson.D{{Key: "$sum", Value: "$amount"}}},
		}}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, 0, 0, err
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var item struct {
			Type string  `bson:"_id"`
			Sum  float64 `bson:"sum"`
		}
		if err := cursor.Decode(&item); err == nil {
			totalCollected += item.Sum
			switch item.Type {
			case "MONTHLY_DUES":
				duesCollected += item.Sum
			case "CONTRIBUTION":
				donations += item.Sum
			}
		}
	}
	return totalCollected, duesCollected, donations, nil
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

func (r *mongoTxnRepo) GetFinancialSummaryRange(ctx context.Context, mahalID string, from, to *time.Time) (FinancialSummary, error) {
	var out FinancialSummary
	match := bson.M{"status": domain.TxnSuccess}
	if mahalID != "" {
		match["mahal_id"] = mahalID
	}
	if from != nil || to != nil {
		rng := bson.M{}
		if from != nil {
			rng["$gte"] = *from
		}
		if to != nil {
			rng["$lt"] = *to
		}
		match["$or"] = bson.A{
			bson.M{"completed_at": rng},
			bson.M{"completed_at": bson.M{"$exists": false}, "created_at": rng},
			bson.M{"completed_at": nil, "created_at": rng},
		}
	}
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: match}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: "$type"},
			{Key: "sum", Value: bson.D{{Key: "$sum", Value: "$amount"}}},
			{Key: "n", Value: bson.D{{Key: "$sum", Value: 1}}},
		}}},
	}
	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return out, err
	}
	defer cursor.Close(ctx)
	for cursor.Next(ctx) {
		var item struct {
			Type string  `bson:"_id"`
			Sum  float64 `bson:"sum"`
			N    int64   `bson:"n"`
		}
		if err := cursor.Decode(&item); err != nil {
			continue
		}
		out.TotalCollected += item.Sum
		out.TransactionCount += item.N
		switch item.Type {
		case "MONTHLY_DUES":
			out.DuesCollected += item.Sum
		case "CONTRIBUTION":
			out.Donations += item.Sum
		}
	}
	return out, cursor.Err()
}

func (r *mongoTxnRepo) GetByIDs(ctx context.Context, mahalID string, ids []string) (map[string]domain.Transaction, error) {
	out := map[string]domain.Transaction{}
	if len(ids) == 0 {
		return out, nil
	}
	cursor, err := r.coll.Find(ctx, bson.M{"mahal_id": mahalID, "_id": bson.M{"$in": ids}})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var txns []domain.Transaction
	if err := cursor.All(ctx, &txns); err != nil {
		return nil, err
	}
	for _, t := range txns {
		out[t.ID] = t
	}
	return out, nil
}

func (r *mongoTxnRepo) CountByMember(ctx context.Context, mahalID, memberID string) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{
		"mahal_id":  mahalID,
		"member_id": memberID,
		"status":    bson.M{"$in": bson.A{domain.TxnSuccess, domain.TxnRefunded}},
	})
}

func (r *mongoTxnRepo) SetPaymentDetails(ctx context.Context, id, gatewayPaymentID, paymentMode string) error {
	set := bson.M{}
	if gatewayPaymentID != "" {
		set["gateway_payment_id"] = gatewayPaymentID
	}
	if paymentMode != "" {
		set["payment_mode"] = paymentMode
	}
	if len(set) == 0 {
		return nil
	}
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": set})
	return err
}
