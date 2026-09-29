package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// AdminRepository stores committee (mahal admin) identities, keyed by phone.
// A phone found here resolves to an admin session at OTP login; phone +
// bcrypt password_hash authenticates the web-admin password login.
type AdminRepository interface {
	GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Admin, error)
	// ListByPhone returns every admin record with this phone across all
	// tenants (one person may sit on several committees).
	ListByPhone(ctx context.Context, phone string) ([]domain.Admin, error)
	Create(ctx context.Context, admin *domain.Admin) error
	// SetPasswordHash stores a new bcrypt hash for one admin record. Returns
	// false when no record has that id.
	SetPasswordHash(ctx context.Context, adminID, hash string) (bool, error)
}

type mongoAdminRepo struct {
	coll *mongo.Collection
}

func NewAdminRepository(db *mongo.Database) AdminRepository {
	return &mongoAdminRepo{coll: db.Collection("admins")}
}

func (r *mongoAdminRepo) GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Admin, error) {
	var a domain.Admin
	err := r.coll.FindOne(ctx, bson.M{"phone": phone, "mahal_id": mahalID}).Decode(&a)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *mongoAdminRepo) ListByPhone(ctx context.Context, phone string) ([]domain.Admin, error) {
	cursor, err := r.coll.Find(ctx, bson.M{"phone": phone})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var out []domain.Admin
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (r *mongoAdminRepo) Create(ctx context.Context, admin *domain.Admin) error {
	_, err := r.coll.InsertOne(ctx, admin)
	return err
}

func (r *mongoAdminRepo) SetPasswordHash(ctx context.Context, adminID, hash string) (bool, error) {
	now := time.Now().UTC()
	res, err := r.coll.UpdateOne(ctx, bson.M{"_id": adminID}, bson.M{
		"$set": bson.M{"password_hash": hash, "password_updated_at": now},
	})
	if err != nil {
		return false, err
	}
	return res.MatchedCount > 0, nil
}
