package repository

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// ErrNotificationAlreadySent is returned by ClaimSend when a notification with
// the same dedupe key was already claimed. Callers must treat this as a normal
// skip, not a failure.
var ErrNotificationAlreadySent = errors.New("notification already sent for this dedupe key")

// Notification statuses through the delivery lifecycle.
const (
	NotifyStatusClaimed = "CLAIMED"
	NotifyStatusSent    = "SENT"
	NotifyStatusFailed  = "FAILED"
	NotifyStatusSkipped = "SKIPPED"
)

// NotificationLog records one outbound message attempt. The unique index on
// (mahal_id, dedupe_key) is what makes sending idempotent: the dunning agent
// runs hourly, and without this a single overdue member would be messaged
// every hour until they paid.
type NotificationLog struct {
	ID          string     `bson:"_id" json:"id"`
	MahalID     string     `bson:"mahal_id" json:"mahal_id"`
	MemberID    string     `bson:"member_id" json:"member_id"`
	Channel     string     `bson:"channel" json:"channel"`
	Kind        string     `bson:"kind" json:"kind"`
	DedupeKey   string     `bson:"dedupe_key" json:"dedupe_key"`
	Status      string     `bson:"status" json:"status"`
	MessageID   string     `bson:"message_id,omitempty" json:"message_id,omitempty"`
	Language    string     `bson:"language,omitempty" json:"language,omitempty"`
	Template    string     `bson:"template,omitempty" json:"template,omitempty"`
	MaskedPhone string     `bson:"masked_phone,omitempty" json:"masked_phone,omitempty"`
	Error       string     `bson:"error,omitempty" json:"error,omitempty"`
	CreatedAt   time.Time  `bson:"created_at" json:"created_at"`
	UpdatedAt   time.Time  `bson:"updated_at" json:"updated_at"`
	DeliveredAt *time.Time `bson:"delivered_at,omitempty" json:"delivered_at,omitempty"`
	ReadAt      *time.Time `bson:"read_at,omitempty" json:"read_at,omitempty"`
}

type NotificationRepository interface {
	// ClaimSend reserves the right to send one notification. It returns
	// ErrNotificationAlreadySent if the dedupe key is taken.
	ClaimSend(ctx context.Context, log *NotificationLog) error
	MarkSent(ctx context.Context, id, messageID string) error
	MarkFailed(ctx context.Context, id, reason string) error
	// UpdateDeliveryStatus applies an inbound webhook status callback.
	UpdateDeliveryStatus(ctx context.Context, messageID, status string, at time.Time) error
	GetByMessageID(ctx context.Context, messageID string) (*NotificationLog, error)
	ListByMember(ctx context.Context, mahalID, memberID string, limit int64) ([]NotificationLog, error)
}

type mongoNotificationRepo struct {
	coll *mongo.Collection
}

func NewNotificationRepository(db *mongo.Database) NotificationRepository {
	return &mongoNotificationRepo{coll: db.Collection("notification_log")}
}

func (r *mongoNotificationRepo) ClaimSend(ctx context.Context, log *NotificationLog) error {
	now := time.Now().UTC()
	log.CreatedAt = now
	log.UpdatedAt = now
	log.Status = NotifyStatusClaimed

	_, err := r.coll.InsertOne(ctx, log)
	if mongo.IsDuplicateKeyError(err) {
		return ErrNotificationAlreadySent
	}
	return err
}

func (r *mongoNotificationRepo) MarkSent(ctx context.Context, id, messageID string) error {
	_, err := r.coll.UpdateByID(ctx, id, bson.M{"$set": bson.M{
		"status":     NotifyStatusSent,
		"message_id": messageID,
		"updated_at": time.Now().UTC(),
	}})
	return err
}

func (r *mongoNotificationRepo) MarkFailed(ctx context.Context, id, reason string) error {
	_, err := r.coll.UpdateByID(ctx, id, bson.M{"$set": bson.M{
		"status":     NotifyStatusFailed,
		"error":      reason,
		"updated_at": time.Now().UTC(),
	}})
	return err
}

func (r *mongoNotificationRepo) UpdateDeliveryStatus(ctx context.Context, messageID, status string, at time.Time) error {
	set := bson.M{"updated_at": time.Now().UTC()}

	switch status {
	case "delivered":
		set["delivered_at"] = at
	case "read":
		set["read_at"] = at
	case "failed":
		set["status"] = NotifyStatusFailed
	}

	_, err := r.coll.UpdateOne(ctx,
		bson.M{"message_id": messageID},
		bson.M{"$set": set},
	)
	return err
}

func (r *mongoNotificationRepo) GetByMessageID(ctx context.Context, messageID string) (*NotificationLog, error) {
	var out NotificationLog
	err := r.coll.FindOne(ctx, bson.M{"message_id": messageID}).Decode(&out)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &out, nil
}

func (r *mongoNotificationRepo) ListByMember(ctx context.Context, mahalID, memberID string, limit int64) ([]NotificationLog, error) {
	if limit <= 0 {
		limit = 50
	}
	cursor, err := r.coll.Find(ctx, bson.M{"mahal_id": mahalID, "member_id": memberID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var out []NotificationLog
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	if int64(len(out)) > limit {
		out = out[:limit]
	}
	return out, nil
}
