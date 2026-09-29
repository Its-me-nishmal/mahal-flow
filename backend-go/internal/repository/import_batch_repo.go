package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// Import batch statuses.
const (
	ImportStatusPreview    = "PREVIEW"
	ImportStatusCommitting = "COMMITTING"
	ImportStatusCommitted  = "COMMITTED"
)

// ImportBatchRepository stores parsed member-import batches between the
// preview and commit steps. Documents expire via a TTL index on expires_at.
type ImportBatchRepository interface {
	Create(ctx context.Context, b *domain.ImportBatch) error
	// Get returns the tenant's batch, or nil when unknown / expired.
	Get(ctx context.Context, mahalID, id string) (*domain.ImportBatch, error)
	// ClaimForCommit atomically moves a PREVIEW (or a COMMITTING batch whose
	// claim is older than staleAfter, i.e. a crashed commit) batch to
	// COMMITTING. It returns the batch when this caller won the claim, nil
	// otherwise.
	ClaimForCommit(ctx context.Context, mahalID, id string, staleAfter time.Duration) (*domain.ImportBatch, error)
	MarkCommitted(ctx context.Context, mahalID, id string, imported, skipped int, rows []domain.ImportRow) error
	// EnsureIndexes creates the TTL index. Safe to call repeatedly.
	EnsureIndexes(ctx context.Context) error
}

type mongoImportBatchRepo struct{ coll *mongo.Collection }

func NewImportBatchRepository(db *mongo.Database) ImportBatchRepository {
	return &mongoImportBatchRepo{coll: db.Collection("import_batches")}
}

func (r *mongoImportBatchRepo) EnsureIndexes(ctx context.Context) error {
	_, err := r.coll.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "expires_at", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0).SetName("ttl_expires_at")},
		{Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "created_at", Value: -1}}, Options: options.Index().SetName("mahal_created")},
	})
	return err
}

func (r *mongoImportBatchRepo) Create(ctx context.Context, b *domain.ImportBatch) error {
	_, err := r.coll.InsertOne(ctx, b)
	return err
}

func (r *mongoImportBatchRepo) Get(ctx context.Context, mahalID, id string) (*domain.ImportBatch, error) {
	var b domain.ImportBatch
	err := r.coll.FindOne(ctx, bson.M{"_id": id, "mahal_id": mahalID, "expires_at": bson.M{"$gt": time.Now().UTC()}}).Decode(&b)
	if err == mongo.ErrNoDocuments {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *mongoImportBatchRepo) ClaimForCommit(ctx context.Context, mahalID, id string, staleAfter time.Duration) (*domain.ImportBatch, error) {
	now := time.Now().UTC()
	filter := bson.M{
		"_id":        id,
		"mahal_id":   mahalID,
		"expires_at": bson.M{"$gt": now},
		"$or": bson.A{
			bson.M{"status": ImportStatusPreview},
			bson.M{"status": ImportStatusCommitting, "claimed_at": bson.M{"$lt": now.Add(-staleAfter)}},
		},
	}
	update := bson.M{"$set": bson.M{"status": ImportStatusCommitting, "claimed_at": now}}
	var b domain.ImportBatch
	err := r.coll.FindOneAndUpdate(ctx, filter, update, options.FindOneAndUpdate().SetReturnDocument(options.After)).Decode(&b)
	if err == mongo.ErrNoDocuments {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *mongoImportBatchRepo) MarkCommitted(ctx context.Context, mahalID, id string, imported, skipped int, rows []domain.ImportRow) error {
	now := time.Now().UTC()
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id, "mahal_id": mahalID}, bson.M{"$set": bson.M{
		"status":       ImportStatusCommitted,
		"imported":     imported,
		"skipped":      skipped,
		"rows":         rows,
		"committed_at": now,
	}})
	return err
}
