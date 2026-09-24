package repository

import (
	"context"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// AdminRepository stores committee (mahal admin) identities, keyed by phone.
// A phone found here resolves to an admin session at login.
type AdminRepository interface {
	GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Admin, error)
	Create(ctx context.Context, admin *domain.Admin) error
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

func (r *mongoAdminRepo) Create(ctx context.Context, admin *domain.Admin) error {
	_, err := r.coll.InsertOne(ctx, admin)
	return err
}
