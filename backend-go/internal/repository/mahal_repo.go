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
	ListAll(ctx context.Context) ([]domain.Mahal, error)
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

func (r *mongoMahalRepo) ListAll(ctx context.Context) ([]domain.Mahal, error) {
	cursor, err := r.coll.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var mahals []domain.Mahal
	if err := cursor.All(ctx, &mahals); err != nil {
		return nil, err
	}
	return mahals, nil
}
