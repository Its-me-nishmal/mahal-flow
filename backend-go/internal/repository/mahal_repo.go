package repository

import (
	"context"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MahalRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Mahal, error)
	Create(ctx context.Context, mahal *domain.Mahal) error
}

type mongoMahalRepo struct {
	coll *mongo.Collection
}

func NewMahalRepository(db *mongo.Database) MahalRepository {
	return &mongoMahalRepo{coll: db.Collection("mahals")}
}

func (r *mongoMahalRepo) GetByID(ctx context.Context, id string) (*domain.Mahal, error) {
	var mahal domain.Mahal
	err := r.coll.FindOne(ctx, bson.M{"_id": id}).Decode(&mahal)
	if err != nil {
		return nil, err
	}
	return &mahal, nil
}

func (r *mongoMahalRepo) Create(ctx context.Context, mahal *domain.Mahal) error {
	_, err := r.coll.InsertOne(ctx, mahal)
	return err
}
