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
	// 1. Transactions Collection - Unique Idempotency Key
	txnIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "idempotency_key", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "status", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("transactions").Indexes().CreateMany(ctx, txnIndexes)

	// 2. Receipts Collection - Unique Receipt Number & Sequence
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
			Keys: bson.D{{Key: "member_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	_, _ = m.DB.Collection("receipts").Indexes().CreateMany(ctx, receiptIndexes)

	// 3. Members Collection - Unique Phone per Mahal
	memberIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "phone", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "status", Value: 1}},
		},
	}
	_, _ = m.DB.Collection("members").Indexes().CreateMany(ctx, memberIndexes)

	return nil
}
