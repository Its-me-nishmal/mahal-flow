package repository

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type MemberRepository interface {
	GetByID(ctx context.Context, mahalID, memberID string) (*domain.Member, error)
	GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Member, error)
	ApplyPaidMonths(ctx context.Context, memberID string, paidMonths []string, amount float64) error
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
