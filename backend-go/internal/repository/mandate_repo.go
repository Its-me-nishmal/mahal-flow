package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// MandateRepository persists PayU Standing Instruction (AutoPay) mandates.
type MandateRepository interface {
	Create(ctx context.Context, m *domain.Mandate) error
	GetByID(ctx context.Context, id string) (*domain.Mandate, error)
	// GetActiveByMember returns the member's current ACTIVE or PENDING mandate, if any.
	GetActiveByMember(ctx context.Context, mahalID, memberID string) (*domain.Mandate, error)
	// FindDue returns ACTIVE mandates whose next_debit is at or before the cutoff.
	FindDue(ctx context.Context, cutoff time.Time) ([]domain.Mandate, error)
	Update(ctx context.Context, id string, fields bson.M) error
}

type mongoMandateRepo struct {
	coll *mongo.Collection
}

func NewMandateRepository(db *mongo.Database) MandateRepository {
	return &mongoMandateRepo{coll: db.Collection("mandates")}
}

func (r *mongoMandateRepo) Create(ctx context.Context, m *domain.Mandate) error {
	_, err := r.coll.InsertOne(ctx, m)
	return err
}

func (r *mongoMandateRepo) GetByID(ctx context.Context, id string) (*domain.Mandate, error) {
	var m domain.Mandate
	if err := r.coll.FindOne(ctx, bson.M{"_id": id}).Decode(&m); err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &m, nil
}

func (r *mongoMandateRepo) GetActiveByMember(ctx context.Context, mahalID, memberID string) (*domain.Mandate, error) {
	filter := bson.M{
		"mahal_id":  mahalID,
		"member_id": memberID,
		"status":    bson.M{"$in": bson.A{"ACTIVE", "PENDING_AUTHORIZATION"}},
	}
	opts := options.FindOne().SetSort(bson.D{{Key: "created_at", Value: -1}})
	var m domain.Mandate
	if err := r.coll.FindOne(ctx, filter, opts).Decode(&m); err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &m, nil
}

func (r *mongoMandateRepo) FindDue(ctx context.Context, cutoff time.Time) ([]domain.Mandate, error) {
	filter := bson.M{
		"status":     "ACTIVE",
		"next_debit": bson.M{"$lte": cutoff},
	}
	cursor, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var out []domain.Mandate
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (r *mongoMandateRepo) Update(ctx context.Context, id string, fields bson.M) error {
	fields["updated_at"] = time.Now().UTC()
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": fields})
	return err
}
