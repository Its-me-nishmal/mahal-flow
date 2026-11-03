package repository

import (
	"context"
	"errors"
	"time"

	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type MemberRepository interface {
	Create(ctx context.Context, member *domain.Member) error
	GetByID(ctx context.Context, mahalID, memberID string) (*domain.Member, error)
	GetByPhone(ctx context.Context, mahalID, phone string) (*domain.Member, error)
	ListByMahal(ctx context.Context, mahalID string, limit, skip int64) ([]domain.Member, int64, error)
	// ApplyPaidMonths books a dues payment idempotently: only months after the
	// member's current last_paid_month count, and the outstanding balance is
	// reduced by that share of amount only. Re-applying months that are already
	// covered (e.g. two PENDING transactions for the same months) is a no-op.
	ApplyPaidMonths(ctx context.Context, memberID string, paidMonths []string, amount float64) error
	// ReverseDuesPayment gives refunded dues back: outstanding_balance rises by
	// amount and, when rollbackTo is set, last_paid_month moves back to it but
	// only if it still equals lastMonth (a later payment depends on it
	// otherwise). Reports whether last_paid_month was rolled back.
	ReverseDuesPayment(ctx context.Context, mahalID, memberID string, amount float64, lastMonth, rollbackTo string) (rolledBack bool, err error)
	GetMemberStats(ctx context.Context, mahalID string) (totalMembers int64, paidCount int64, pendingCount int64, totalPendingAmount float64, err error)
	UpdateProfile(ctx context.Context, mahalID, memberID string, updates bson.M) error
	UpdateStatus(ctx context.Context, mahalID, memberID, status string) error
	// Delete removes one member of the tenant; false when nothing matched.
	Delete(ctx context.Context, mahalID, memberID string) (bool, error)
	GetOverdueMembers(ctx context.Context, mahalID string) ([]domain.Member, error)
	// ListPhones returns every phone registered in the tenant (any status).
	ListPhones(ctx context.Context, mahalID string) (map[string]bool, error)
	// GetNames returns id -> name for the tenant's members among ids.
	GetNames(ctx context.Context, mahalID string, ids []string) (map[string]string, error)
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

func (r *mongoMemberRepo) ListByMahal(ctx context.Context, mahalID string, limit, skip int64) ([]domain.Member, int64, error) {
	filter := bson.M{"mahal_id": mahalID}
	total, err := r.coll.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	opts := options.Find().SetLimit(limit).SetSkip(skip).SetSort(bson.D{{Key: "created_at", Value: -1}})
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var members []domain.Member
	if err := cursor.All(ctx, &members); err != nil {
		return nil, 0, err
	}

	return members, total, nil
}

// NewlyCoveredDues reports how many of paidMonths lie after lastPaidMonth and
// the share of amount (split evenly per month, in paise) that pays for them.
// It is what makes booking idempotent: months an earlier payment already
// covered contribute nothing, so the balance cannot be decremented twice.
func NewlyCoveredDues(lastPaidMonth string, paidMonths []string, amount float64) (newly int, applied float64) {
	if len(paidMonths) == 0 {
		return 0, 0
	}
	for _, m := range paidMonths {
		if m > lastPaidMonth { // YYYY-MM sorts lexicographically
			newly++
		}
	}
	perMonth := domain.ToPaise(amount) / domain.MoneyPaise(len(paidMonths))
	return newly, (perMonth * domain.MoneyPaise(newly)).ToRupees()
}

func (r *mongoMemberRepo) ApplyPaidMonths(ctx context.Context, memberID string, paidMonths []string, amount float64) error {
	if len(paidMonths) == 0 {
		return nil
	}
	lastPaid := paidMonths[len(paidMonths)-1]

	// Optimistic loop: read last_paid_month, compute what is newly covered,
	// and write only if last_paid_month is still what we read.
	for attempt := 0; attempt < 5; attempt++ {
		var cur struct {
			LastPaidMonth string `bson:"last_paid_month"`
		}
		if err := r.coll.FindOne(ctx, bson.M{"_id": memberID}).Decode(&cur); err != nil {
			return err
		}
		newly, applied := NewlyCoveredDues(cur.LastPaidMonth, paidMonths, amount)
		if newly == 0 {
			return nil // already covered by an earlier payment
		}
		newLast := lastPaid
		if cur.LastPaidMonth > newLast {
			newLast = cur.LastPaidMonth
		}
		guard := bson.M{"_id": memberID}
		if cur.LastPaidMonth == "" {
			guard["$or"] = bson.A{bson.M{"last_paid_month": ""}, bson.M{"last_paid_month": bson.M{"$exists": false}}}
		} else {
			guard["last_paid_month"] = cur.LastPaidMonth
		}
		res, err := r.coll.UpdateOne(ctx, guard, bson.M{
			"$set": bson.M{"last_paid_month": newLast, "updated_at": time.Now().UTC()},
			"$inc": bson.M{"outstanding_balance": -applied, "version": 1},
		})
		if err != nil {
			return err
		}
		if res.MatchedCount == 1 {
			return nil
		}
	}
	return errors.New("apply paid months: concurrent updates, giving up")
}

func (r *mongoMemberRepo) ReverseDuesPayment(ctx context.Context, mahalID, memberID string, amount float64, lastMonth, rollbackTo string) (bool, error) {
	res, err := r.coll.UpdateOne(ctx, bson.M{"_id": memberID, "mahal_id": mahalID}, bson.M{
		"$set": bson.M{"updated_at": time.Now().UTC()},
		"$inc": bson.M{"outstanding_balance": amount, "version": 1},
	})
	if err != nil {
		return false, err
	}
	if res.MatchedCount == 0 {
		return false, mongo.ErrNoDocuments
	}
	if rollbackTo == "" || lastMonth == "" {
		return false, nil
	}
	res, err = r.coll.UpdateOne(ctx, bson.M{"_id": memberID, "mahal_id": mahalID, "last_paid_month": lastMonth},
		bson.M{"$set": bson.M{"last_paid_month": rollbackTo}})
	if err != nil {
		return false, err
	}
	return res.MatchedCount == 1, nil
}

func (r *mongoMemberRepo) GetMemberStats(ctx context.Context, mahalID string) (totalMembers int64, paidCount int64, pendingCount int64, totalPendingAmount float64, err error) {
	filter := bson.M{"mahal_id": mahalID}
	totalMembers, err = r.coll.CountDocuments(ctx, filter)
	if err != nil {
		return 0, 0, 0, 0, err
	}

	paidFilter := bson.M{"mahal_id": mahalID, "outstanding_balance": bson.M{"$lte": 0.0}}
	paidCount, _ = r.coll.CountDocuments(ctx, paidFilter)

	pendingCount = totalMembers - paidCount

	// Calculate total positive outstanding balance only
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"mahal_id":            mahalID,
			"outstanding_balance": bson.M{"$gt": 0.0},
		}}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: nil},
			{Key: "totalPending", Value: bson.D{{Key: "$sum", Value: "$outstanding_balance"}}},
		}}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err == nil && cursor.Next(ctx) {
		var res struct {
			TotalPending float64 `bson:"totalPending"`
		}
		if err := cursor.Decode(&res); err == nil {
			totalPendingAmount = res.TotalPending
		}
	}

	return totalMembers, paidCount, pendingCount, totalPendingAmount, nil
}

func (r *mongoMemberRepo) UpdateProfile(ctx context.Context, mahalID, memberID string, updates bson.M) error {
	updates["updated_at"] = time.Now().UTC()
	_, err := r.coll.UpdateOne(
		ctx,
		bson.M{"_id": memberID, "mahal_id": mahalID},
		bson.M{"$set": updates},
	)
	return err
}

func (r *mongoMemberRepo) Create(ctx context.Context, member *domain.Member) error {
	if member.CreatedAt.IsZero() {
		member.CreatedAt = time.Now().UTC()
	}
	member.UpdatedAt = time.Now().UTC()
	_, err := r.coll.InsertOne(ctx, member)
	return err
}

func (r *mongoMemberRepo) UpdateStatus(ctx context.Context, mahalID, memberID, status string) error {
	_, err := r.coll.UpdateOne(
		ctx,
		bson.M{"_id": memberID, "mahal_id": mahalID},
		bson.M{"$set": bson.M{"status": status, "updated_at": time.Now().UTC()}},
	)
	return err
}

func (r *mongoMemberRepo) Delete(ctx context.Context, mahalID, memberID string) (bool, error) {
	res, err := r.coll.DeleteOne(ctx, bson.M{"_id": memberID, "mahal_id": mahalID})
	if err != nil {
		return false, err
	}
	return res.DeletedCount > 0, nil
}

func (r *mongoMemberRepo) GetOverdueMembers(ctx context.Context, mahalID string) ([]domain.Member, error) {
	filter := bson.M{
		"mahal_id":            mahalID,
		"outstanding_balance": bson.M{"$gt": 0.0},
		"status":              "ACTIVE",
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

func (r *mongoMemberRepo) ListPhones(ctx context.Context, mahalID string) (map[string]bool, error) {
	opts := options.Find().SetProjection(bson.M{"phone": 1})
	cursor, err := r.coll.Find(ctx, bson.M{"mahal_id": mahalID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	out := map[string]bool{}
	for cursor.Next(ctx) {
		var row struct {
			Phone string `bson:"phone"`
		}
		if err := cursor.Decode(&row); err == nil && row.Phone != "" {
			out[row.Phone] = true
		}
	}
	return out, cursor.Err()
}

func (r *mongoMemberRepo) GetNames(ctx context.Context, mahalID string, ids []string) (map[string]string, error) {
	out := map[string]string{}
	if len(ids) == 0 {
		return out, nil
	}
	opts := options.Find().SetProjection(bson.M{"name": 1})
	cursor, err := r.coll.Find(ctx, bson.M{"mahal_id": mahalID, "_id": bson.M{"$in": ids}}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	for cursor.Next(ctx) {
		var row struct {
			ID   string `bson:"_id"`
			Name string `bson:"name"`
		}
		if cursor.Decode(&row) == nil {
			out[row.ID] = row.Name
		}
	}
	return out, cursor.Err()
}
