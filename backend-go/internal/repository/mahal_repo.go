package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MahalRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Mahal, error)
	Create(ctx context.Context, mahal *domain.Mahal) error
	ListAll(ctx context.Context) ([]domain.Mahal, error)
	// Update $sets the given fields (dotted paths allowed) on one Mahal and
	// bumps updated_at. Returns false when no Mahal has that id.
	Update(ctx context.Context, id string, set bson.M) (bool, error)
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

func (r *mongoMahalRepo) Update(ctx context.Context, id string, set bson.M) (bool, error) {
	doc := bson.M{"updated_at": time.Now().UTC()}
	for k, v := range set {
		doc[k] = v
	}
	res, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": doc})
	if err != nil {
		return false, err
	}
	return res.MatchedCount > 0, nil
}
