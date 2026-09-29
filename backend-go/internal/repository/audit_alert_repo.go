package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type AuditLogRepository interface {
	Create(ctx context.Context, log *domain.AuditLog) error
	List(ctx context.Context, mahalID string, limit, skip int64) ([]domain.AuditLog, int64, error)
}

type mongoAuditRepo struct {
	coll *mongo.Collection
}

func NewAuditLogRepository(db *mongo.Database) AuditLogRepository {
	return &mongoAuditRepo{coll: db.Collection("audit_logs")}
}

func (r *mongoAuditRepo) Create(ctx context.Context, log *domain.AuditLog) error {
	if log.ID == "" {
		log.ID = "AUD_" + uuid.New().String()[:8]
	}
	if log.Timestamp.IsZero() {
		log.Timestamp = time.Now().UTC()
	}
	_, err := r.coll.InsertOne(ctx, log)
	return err
}

func (r *mongoAuditRepo) List(ctx context.Context, mahalID string, limit, skip int64) ([]domain.AuditLog, int64, error) {
	filter := bson.M{}
	if mahalID != "" {
		filter["mahal_id"] = mahalID
	}
	total, err := r.coll.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	opts := options.Find().SetLimit(limit).SetSkip(skip).SetSort(bson.D{{Key: "timestamp", Value: -1}})
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var rawLogs []bson.M
	if err := cursor.All(ctx, &rawLogs); err != nil {
		return nil, 0, err
	}

	logs := make([]domain.AuditLog, 0, len(rawLogs))
	for _, raw := range rawLogs {
		var log domain.AuditLog
		if id, ok := raw["_id"].(string); ok {
			log.ID = id
		}
		if mid, ok := raw["mahal_id"].(string); ok {
			log.MahalID = mid
		}
		if act, ok := raw["action"].(string); ok {
			log.Action = act
		}
		if ent, ok := raw["entity_id"].(string); ok {
			log.EntityID = ent
		}
		if det, ok := raw["details"].(string); ok {
			log.Details = det
		}
		if ip, ok := raw["ip_address"].(string); ok {
			log.IPAddress = ip
		}
		if ts, ok := raw["timestamp"].(time.Time); ok {
			log.Timestamp = ts
		}

		// Handle Actor whether string, map, or missing
		if actorStr, ok := raw["actor"].(string); ok {
			log.Actor = actorStr
		} else if actorMap, ok := raw["actor"].(bson.M); ok {
			if n, ok := actorMap["name"].(string); ok {
				log.Actor = n
			} else if id, ok := actorMap["id"].(string); ok {
				log.Actor = id
			} else {
				log.Actor = "Admin"
			}
		} else {
			log.Actor = "System"
		}

		logs = append(logs, log)
	}

	return logs, total, nil
}

// -------------------------------------------------------------
// Alert Repository
// -------------------------------------------------------------

type AlertRepository interface {
	Create(ctx context.Context, alert *domain.SystemAlert) error
	// List returns the tenant's alerts plus global (no mahal_id) ones.
	List(ctx context.Context, mahalID string) ([]domain.SystemAlert, error)
	// GetByID returns an alert visible to the tenant, or nil.
	GetByID(ctx context.Context, mahalID, alertID string) (*domain.SystemAlert, error)
	// Acknowledge / Dismiss change the shared alert (admin actions). Both are
	// tenant-scoped and report false when no visible alert matched.
	Acknowledge(ctx context.Context, mahalID, alertID string) (bool, error)
	Dismiss(ctx context.Context, mahalID, alertID string) (bool, error)
	ClearAll(ctx context.Context, mahalID string) error
	MarkAllRead(ctx context.Context, mahalID string) error

	// Per-member state for shared alerts (member actions never touch the
	// shared document).
	ListMemberStates(ctx context.Context, mahalID, memberID string) (map[string]domain.AlertMemberState, error)
	MarkReadForMember(ctx context.Context, mahalID, memberID string, alertIDs []string) error
	DismissForMember(ctx context.Context, mahalID, memberID string, alertIDs []string) error
}

type mongoAlertRepo struct {
	coll   *mongo.Collection
	states *mongo.Collection
}

func NewAlertRepository(db *mongo.Database) AlertRepository {
	return &mongoAlertRepo{coll: db.Collection("alerts"), states: db.Collection("alert_member_states")}
}

// tenantVisible matches alerts a tenant can see: its own plus global ones.
func tenantVisible(mahalID string) bson.M {
	return bson.M{"$or": []bson.M{
		{"mahal_id": mahalID},
		{"mahal_id": bson.M{"$exists": false}},
		{"mahal_id": ""},
	}}
}

func (r *mongoAlertRepo) GetByID(ctx context.Context, mahalID, alertID string) (*domain.SystemAlert, error) {
	filter := bson.M{"$and": []bson.M{{"_id": alertID}, tenantVisible(mahalID)}}
	var a domain.SystemAlert
	if err := r.coll.FindOne(ctx, filter).Decode(&a); err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *mongoAlertRepo) ListMemberStates(ctx context.Context, mahalID, memberID string) (map[string]domain.AlertMemberState, error) {
	cursor, err := r.states.Find(ctx, bson.M{"mahal_id": mahalID, "member_id": memberID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	var rows []domain.AlertMemberState
	if err := cursor.All(ctx, &rows); err != nil {
		return nil, err
	}
	out := make(map[string]domain.AlertMemberState, len(rows))
	for _, s := range rows {
		out[s.AlertID] = s
	}
	return out, nil
}

func (r *mongoAlertRepo) upsertMemberState(ctx context.Context, mahalID, memberID string, alertIDs []string, set bson.M) error {
	if len(alertIDs) == 0 {
		return nil
	}
	models := make([]mongo.WriteModel, 0, len(alertIDs))
	for _, id := range alertIDs {
		models = append(models, mongo.NewUpdateOneModel().
			SetFilter(bson.M{"_id": id + ":" + memberID}).
			SetUpdate(bson.M{
				"$set":         set,
				"$setOnInsert": bson.M{"alert_id": id, "mahal_id": mahalID, "member_id": memberID},
			}).
			SetUpsert(true))
	}
	_, err := r.states.BulkWrite(ctx, models)
	return err
}

func (r *mongoAlertRepo) MarkReadForMember(ctx context.Context, mahalID, memberID string, alertIDs []string) error {
	return r.upsertMemberState(ctx, mahalID, memberID, alertIDs, bson.M{"read_at": time.Now().UTC()})
}

func (r *mongoAlertRepo) DismissForMember(ctx context.Context, mahalID, memberID string, alertIDs []string) error {
	now := time.Now().UTC()
	return r.upsertMemberState(ctx, mahalID, memberID, alertIDs, bson.M{"read_at": now, "dismissed_at": now})
}

func (r *mongoAlertRepo) Create(ctx context.Context, alert *domain.SystemAlert) error {
	if alert.ID == "" {
		alert.ID = "ALT_" + uuid.New().String()[:8]
	}
	if alert.CreatedAt.IsZero() {
		alert.CreatedAt = time.Now().UTC()
	}
	if alert.Status == "" {
		alert.Status = "ACTIVE"
	}
	_, err := r.coll.InsertOne(ctx, alert)
	return err
}

func (r *mongoAlertRepo) List(ctx context.Context, mahalID string) ([]domain.SystemAlert, error) {
	filter := bson.M{}
	if mahalID != "" {
		filter["$or"] = []bson.M{
			{"mahal_id": mahalID},
			{"mahal_id": bson.M{"$exists": false}},
			{"mahal_id": ""},
		}
	}
	opts := options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(50)
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var alerts []domain.SystemAlert
	if err := cursor.All(ctx, &alerts); err != nil {
		return nil, err
	}
	if alerts == nil {
		alerts = []domain.SystemAlert{}
	}
	return alerts, nil
}

func (r *mongoAlertRepo) Acknowledge(ctx context.Context, mahalID, alertID string) (bool, error) {
	filter := bson.M{"$and": []bson.M{{"_id": alertID}, tenantVisible(mahalID)}}
	res, err := r.coll.UpdateOne(ctx, filter, bson.M{
		"$set": bson.M{"status": "ACKNOWLEDGED"},
	})
	if err != nil {
		return false, err
	}
	return res.MatchedCount > 0, nil
}

func (r *mongoAlertRepo) Dismiss(ctx context.Context, mahalID, alertID string) (bool, error) {
	filter := bson.M{"$and": []bson.M{
		{"$or": []bson.M{{"_id": alertID}, {"id": alertID}}},
		tenantVisible(mahalID),
	}}
	res, err := r.coll.DeleteOne(ctx, filter)
	if err != nil {
		return false, err
	}
	return res.DeletedCount > 0, nil
}

func (r *mongoAlertRepo) ClearAll(ctx context.Context, mahalID string) error {
	filter := bson.M{}
	if mahalID != "" {
		filter["$or"] = []bson.M{
			{"mahal_id": mahalID},
			{"mahal_id": bson.M{"$exists": false}},
			{"mahal_id": ""},
		}
	}
	_, err := r.coll.DeleteMany(ctx, filter)
	return err
}

func (r *mongoAlertRepo) MarkAllRead(ctx context.Context, mahalID string) error {
	filter := bson.M{}
	if mahalID != "" {
		filter["$or"] = []bson.M{
			{"mahal_id": mahalID},
			{"mahal_id": bson.M{"$exists": false}},
			{"mahal_id": ""},
		}
	}
	_, err := r.coll.UpdateMany(ctx, filter, bson.M{
		"$set": bson.M{"status": "ACKNOWLEDGED"},
	})
	return err
}

// -------------------------------------------------------------
// Refund & Invoice Repositories
// -------------------------------------------------------------

type RefundRepository interface {
	Create(ctx context.Context, refund *domain.RefundRequest) error
	List(ctx context.Context, mahalID string) ([]domain.RefundRequest, error)
	GetByID(ctx context.Context, refundID string) (*domain.RefundRequest, error)
	UpdateStatus(ctx context.Context, refundID, status string) error
}

type mongoRefundRepo struct {
	coll *mongo.Collection
}

func NewRefundRepository(db *mongo.Database) RefundRepository {
	return &mongoRefundRepo{coll: db.Collection("refunds")}
}

func (r *mongoRefundRepo) Create(ctx context.Context, refund *domain.RefundRequest) error {
	if refund.ID == "" {
		refund.ID = "REF_" + uuid.New().String()[:8]
	}
	if refund.RequestedAt.IsZero() {
		refund.RequestedAt = time.Now().UTC()
	}
	if refund.Status == "" {
		refund.Status = "PENDING"
	}
	_, err := r.coll.InsertOne(ctx, refund)
	return err
}

func (r *mongoRefundRepo) List(ctx context.Context, mahalID string) ([]domain.RefundRequest, error) {
	filter := bson.M{}
	if mahalID != "" {
		filter["mahal_id"] = mahalID
	}
	opts := options.Find().SetSort(bson.D{{Key: "requested_at", Value: -1}})
	cursor, err := r.coll.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var refunds []domain.RefundRequest
	if err := cursor.All(ctx, &refunds); err != nil {
		return nil, err
	}
	if refunds == nil {
		refunds = []domain.RefundRequest{}
	}
	return refunds, nil
}

func (r *mongoRefundRepo) GetByID(ctx context.Context, refundID string) (*domain.RefundRequest, error) {
	var refund domain.RefundRequest
	err := r.coll.FindOne(ctx, bson.M{"_id": refundID}).Decode(&refund)
	if err != nil {
		return nil, err
	}
	return &refund, nil
}

func (r *mongoRefundRepo) UpdateStatus(ctx context.Context, refundID, status string) error {
	now := time.Now().UTC()
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": refundID}, bson.M{
		"$set": bson.M{
			"status":       status,
			"processed_at": now,
		},
	})
	return err
}
