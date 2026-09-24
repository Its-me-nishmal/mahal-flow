package repository

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// DeviceToken is one app install's FCM registration. The token itself is the
// _id: FCM tokens are globally unique, and keying on them means a phone that
// switches member (sign out, sign in as someone else) moves its single row
// instead of leaving a stale one that would push the old member's notices.
type DeviceToken struct {
	Token     string    `bson:"_id" json:"token"`
	MahalID   string    `bson:"mahal_id" json:"mahal_id"`
	MemberID  string    `bson:"member_id" json:"member_id"`
	Platform  string    `bson:"platform" json:"platform"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}

type DeviceTokenRepository interface {
	// Upsert binds a token to a member, moving it if it was bound elsewhere.
	Upsert(ctx context.Context, t *DeviceToken) error
	Delete(ctx context.Context, token string) error
	ListByMember(ctx context.Context, mahalID, memberID string) ([]DeviceToken, error)
	ListByMahal(ctx context.Context, mahalID string) ([]DeviceToken, error)
	ListByMembers(ctx context.Context, mahalID string, memberIDs []string) ([]DeviceToken, error)
}

type mongoDeviceTokenRepo struct {
	coll *mongo.Collection
}

func NewDeviceTokenRepository(db *mongo.Database) DeviceTokenRepository {
	coll := db.Collection("device_tokens")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, _ = coll.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "mahal_id", Value: 1}, {Key: "member_id", Value: 1}},
	})
	return &mongoDeviceTokenRepo{coll: coll}
}

func (r *mongoDeviceTokenRepo) Upsert(ctx context.Context, t *DeviceToken) error {
	now := time.Now().UTC()
	_, err := r.coll.UpdateOne(ctx,
		bson.M{"_id": t.Token},
		bson.M{
			"$set": bson.M{
				"mahal_id":   t.MahalID,
				"member_id":  t.MemberID,
				"platform":   t.Platform,
				"updated_at": now,
			},
			"$setOnInsert": bson.M{"created_at": now},
		},
		options.Update().SetUpsert(true),
	)
	return err
}

// Delete is keyed on the token alone: only the device holding it can present
// it, and a dead token must be removable from the send path without a tenant.
func (r *mongoDeviceTokenRepo) Delete(ctx context.Context, token string) error {
	_, err := r.coll.DeleteOne(ctx, bson.M{"_id": token})
	return err
}

func (r *mongoDeviceTokenRepo) ListByMember(ctx context.Context, mahalID, memberID string) ([]DeviceToken, error) {
	return r.find(ctx, bson.M{"mahal_id": mahalID, "member_id": memberID})
}

func (r *mongoDeviceTokenRepo) ListByMahal(ctx context.Context, mahalID string) ([]DeviceToken, error) {
	return r.find(ctx, bson.M{"mahal_id": mahalID})
}

func (r *mongoDeviceTokenRepo) ListByMembers(ctx context.Context, mahalID string, memberIDs []string) ([]DeviceToken, error) {
	if len(memberIDs) == 0 {
		return nil, nil
	}
	return r.find(ctx, bson.M{"mahal_id": mahalID, "member_id": bson.M{"$in": memberIDs}})
}

func (r *mongoDeviceTokenRepo) find(ctx context.Context, filter bson.M) ([]DeviceToken, error) {
	cur, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	var out []DeviceToken
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}
