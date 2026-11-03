package database

import (
	"context"
	"errors"
	"strings"
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

// txnIdempotencyIndex is the name of the per-tenant idempotency index.
const txnIdempotencyIndex = "mahal_id_1_idempotency_key_1"

// createIndexes creates the indexes and logs (rather than discards) failures.
// It reports whether every index was created.
func (m *MongoDB) createIndexes(ctx context.Context, collection string, models []mongo.IndexModel) bool {
	if _, err := m.DB.Collection(collection).Indexes().CreateMany(ctx, models); err != nil {
		logger.Log.Error().Err(err).Str("collection", collection).Msg("MongoDB index creation failed")
		return false
	}
	return true
}

// dropLegacyIndex removes an obsolete index. "Index not found" (code 27) is
// the normal already-migrated case and is not an error.
func (m *MongoDB) dropLegacyIndex(ctx context.Context, collection, name string) {
	err := m.DB.Collection(collection).Indexes().DropOne(ctx, name)
	if err == nil {
		logger.Log.Warn().Str("collection", collection).Str("index", name).Msg("Dropped legacy MongoDB index")
		return
	}
	var cmdErr mongo.CommandError
	if errors.As(err, &cmdErr) && (cmdErr.Code == 27 || cmdErr.Code == 26) {
		return
	}
	if strings.Contains(err.Error(), "index not found") || strings.Contains(err.Error(), "ns not found") {
		return
	}
	logger.Log.Error().Err(err).Str("collection", collection).Str("index", name).Msg("Could not drop legacy MongoDB index; drop it manually")
}

func (m *MongoDB) ensureIndexes(ctx context.Context) error {
	// 1. Transactions Collection
	txnIndexes := []mongo.IndexModel{
		{
			// Idempotency is per tenant: the same client key in two Mahals
			// must never collide (or resolve to another tenant's transaction).
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "idempotency_key", Value: 1}},
			Options: options.Index().SetUnique(true).SetName(txnIdempotencyIndex),
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
	if m.createIndexes(ctx, "transactions", txnIndexes) {
		// Only once the per-tenant index exists is it safe to drop the old
		// global unique index (which also let one tenant's key block, or
		// resolve to, another tenant's transaction).
		m.dropLegacyIndex(ctx, "transactions", "idempotency_key_1")
	}

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
	m.createIndexes(ctx, "receipts", receiptIndexes)

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
	m.createIndexes(ctx, "members", memberIndexes)

	// 4. Audit Logs Collection
	auditIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "timestamp", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "action", Value: 1}, {Key: "timestamp", Value: -1}},
		},
	}
	m.createIndexes(ctx, "audit_logs", auditIndexes)

	// 5. Alerts Collection
	alertIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "is_read", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	m.createIndexes(ctx, "alerts", alertIndexes)

	// 6. Counters Collection (Atomic Monotonic Sequences)
	counterIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "counter_type", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
	}
	m.createIndexes(ctx, "counters", counterIndexes)

	// 7. Notification Log Collection (Outbound Message Idempotency)
	// The unique (mahal_id, dedupe_key) index is load-bearing: the dunning
	// agent re-scans hourly, and this is what stops a member being messaged
	// repeatedly for the same overdue month.
	notificationIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "mahal_id", Value: 1}, {Key: "dedupe_key", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys:    bson.D{{Key: "message_id", Value: 1}},
			Options: options.Index().SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "member_id", Value: 1}, {Key: "created_at", Value: -1}},
		},
	}
	m.createIndexes(ctx, "notification_log", notificationIndexes)

	return nil
}
