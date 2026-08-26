package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MemberRepository interface {
	GetByID(ctx context.Context, mahalID, memberID string) (*domain.Member, error)
	GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Member, error)
	ApplyPaidMonths(ctx context.Context, memberID string, paidMonths []string, amount float64) error
	GetOverdueMembers(ctx context.Context, mahalID string) ([]domain.Member, error)
	GetAllByMahal(ctx context.Context, mahalID string) ([]domain.Member, error)
	UpsertMembers(ctx context.Context, mahalID string, members []domain.Member) (inserted int, updated int, duplicates int, err error)
}

type mongoMemberRepo struct {
	coll *mongo.Collection
}

func NewMemberRepository(db *mongo.Database) MemberRepository {
	return &mongoMemberRepo{coll: db.Collection("members")}
}

func (r *mongoMemberRepo) GetByID(ctx context.Context, mahalID, memberID string) (*domain.Member, error) {
	var member domain.Member
	err := r.coll.FindOne(ctx, bson.M{"_id": memberID, "mahal_id": mahalID}).Decode(&member)
	if err != nil {
		return nil, err
	}
	return &member, nil
}

func (r *mongoMemberRepo) GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Member, error) {
	var member domain.Member
	err := r.coll.FindOne(ctx, bson.M{"phone": phone, "mahal_id": mahalID}).Decode(&member)
	if err != nil {
		return nil, err
	}
	return &member, nil
}

func (r *mongoMemberRepo) ApplyPaidMonths(ctx context.Context, memberID string, paidMonths []string, amount float64) error {
	if len(paidMonths) == 0 {
		return nil
	}
	lastPaid := paidMonths[len(paidMonths)-1]

	update := bson.M{
		"$set": bson.M{
			"last_paid_month": lastPaid,
			"updated_at":      time.Now().UTC(),
		},
		"$inc": bson.M{
			"outstanding_balance": -amount,
			"version":             1,
		},
	}

	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": memberID}, update)
	return err
}

func (r *mongoMemberRepo) GetOverdueMembers(ctx context.Context, mahalID string) ([]domain.Member, error) {
	currentMonth := time.Now().UTC().Format("2006-01")
	filter := bson.M{
		"mahal_id": mahalID,
		"status":   "ACTIVE",
		"$and": []bson.M{
			{"last_paid_month": bson.M{"$ne": currentMonth}},
			{"last_paid_month": bson.M{"$lt": currentMonth}},
		},
	}
	cursor, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var members []domain.Member
	if err := cursor.All(ctx, &members); err != nil {
		return nil, err
	}
	return members, nil
}

func (r *mongoMemberRepo) GetAllByMahal(ctx context.Context, mahalID string) ([]domain.Member, error) {
	filter := bson.M{"mahal_id": mahalID, "status": "ACTIVE"}
	cursor, err := r.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var members []domain.Member
	if err := cursor.All(ctx, &members); err != nil {
		return nil, err
	}
	return members, nil
}

func (r *mongoMemberRepo) UpsertMembers(ctx context.Context, mahalID string, members []domain.Member) (inserted int, updated int, duplicates int, err error) {
	for _, m := range members {
		m.MahalID = mahalID
		existing, findErr := r.GetByPhone(ctx, mahalID, m.Phone)
		if findErr == nil && existing != nil {
			duplicates++
			continue
		}
		if m.ID == "" {
			m.ID = "MEM_" + uuid.New().String()
		}
		m.CreatedAt = time.Now().UTC()
		m.UpdatedAt = time.Now().UTC()
		m.Version = 1
		if m.Status == "" {
			m.Status = "ACTIVE"
		}
		_, insertErr := r.coll.InsertOne(ctx, m)
		if insertErr != nil {
			err = insertErr
			return
		}
		inserted++
	}
	return
}
