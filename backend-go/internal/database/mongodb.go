package database

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/logger"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type MongoDB struct {
	Client *mongo.Client
	DB     *mongo.Database
}

func Connect(uri, dbName string) (*MongoDB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	serverAPI := options.ServerAPI(options.ServerAPIVersion1)
	opts := options.Client().ApplyURI(uri).SetServerAPIOptions(serverAPI).SetMaxPoolSize(100)

	client, err := mongo.Connect(opts)
	if err != nil {
		return nil, err
	}

	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	db := client.Database(dbName)
	logger.Log.Info().Str("database", dbName).Msg("Successfully connected to MongoDB replica set")

	mongoDB := &MongoDB{
		Client: client,
		DB:     db,
	}

	if err := mongoDB.ensureIndexes(context.Background()); err != nil {
		logger.Log.Warn().Err(err).Msg("Warning: Some MongoDB indexes could not be automatically ensured")
	}

	return mongoDB, nil
}

func (m *MongoDB) ensureIndexes(ctx context.Context) error {
	// 1. Transactions Collection
	txnIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "idempotency_key", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "status", Value: 1}, {Key: "created_at", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "type", Value: 1}, {Key: "status", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "member_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}, {Key: "created_at", Value: 1}},
		},
	}
	_, _ = m.DB.Collection("transactions").Indexes().CreateMany(ctx, txnIndexes)

	// 2. Receipts Collection
	receiptIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "receipt_number", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "sequence_number", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "sequence_number", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "member_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "member_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("receipts").Indexes().CreateMany(ctx, receiptIndexes)

	// 3. Members Collection
	memberIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "phone", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "status", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "outstanding_balance", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("members").Indexes().CreateMany(ctx, memberIndexes)

	// 4. Audit Logs Collection
	auditIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "timestamp", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "action", Value: 1}, {Key: "timestamp", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("audit_logs").Indexes().CreateMany(ctx, auditIndexes)

	// 5. Alerts Collection
	alertIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "is_read", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("alerts").Indexes().CreateMany(ctx, alertIndexes)

	// 6. Counters Collection (Atomic Monotonic Sequences)
	counterIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "counter_type", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
	}
	_, _ = m.DB.Collection("counters").Indexes().CreateMany(ctx, counterIndexes)

	return nil
}
