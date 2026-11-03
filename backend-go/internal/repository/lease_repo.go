package repository

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// LeaseRepository is a tiny Mongo-backed distributed lock, so a job that runs
// on a timer inside every API instance (the AutoPay scheduler) executes on one
// instance at a time.
type LeaseRepository interface {
	// Acquire takes (or renews, when owner already holds it) the named lease
	// for ttl. It returns false when another owner holds an unexpired lease.
	Acquire(ctx context.Context, name, owner string, ttl time.Duration) (bool, error)
	// Release gives the lease up early; a no-op unless owner holds it.
	Release(ctx context.Context, name, owner string) error
}

type mongoLeaseRepo struct {
	coll *mongo.Collection
}

func NewLeaseRepository(db *mongo.Database) LeaseRepository {
	return &mongoLeaseRepo{coll: db.Collection("locks")}
}

func (r *mongoLeaseRepo) Acquire(ctx context.Context, name, owner string, ttl time.Duration) (bool, error) {
	now := time.Now().UTC()
	filter := bson.M{
		"_id": name,
		"$or": bson.A{
			bson.M{"expires_at": bson.M{"$lte": now}},
			bson.M{"owner": owner},
		},
	}
	update := bson.M{"$set": bson.M{"owner": owner, "expires_at": now.Add(ttl), "acquired_at": now}}
	opts := options.FindOneAndUpdate().SetUpsert(true)
	err := r.coll.FindOneAndUpdate(ctx, filter, update, opts).Err()
	switch {
	case err == nil, err == mongo.ErrNoDocuments:
		// Matched and updated, or upserted a fresh lease.
		return true, nil
	case mongo.IsDuplicateKeyError(err):
		// The lease document exists, is unexpired and belongs to someone
		// else: the upsert tried to insert a second _id.
		return false, nil
	default:
		return false, err
	}
}

func (r *mongoLeaseRepo) Release(ctx context.Context, name, owner string) error {
	_, err := r.coll.UpdateOne(ctx,
		bson.M{"_id": name, "owner": owner},
		bson.M{"$set": bson.M{"expires_at": time.Unix(0, 0).UTC()}})
	return err
}
