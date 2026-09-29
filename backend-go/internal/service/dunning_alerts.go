package service

import (
	"context"
	"fmt"
	"time"

	"github.com/mahalflow/backend-go/internal/agent"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// DunningAlertID is the per-member, per-day id of a dues reminder notice, so
// the hourly dunning scan creates at most one reminder a day per member.
func DunningAlertID(memberID string, day time.Time) string {
	return fmt.Sprintf("ALT_DUES_%s_%s", memberID, day.UTC().Format("20060102"))
}

// SubscribeDunningAlerts turns the dunning agent's MEMBER_OVERDUE events into
// in-app DUES_REMINDER notices addressed to that member only (audience
// MEMBER). Independent of WhatsApp: members see the reminder in the app even
// when WhatsApp is not configured.
func SubscribeDunningAlerts(bus *agent.EventBus, alerts repository.AlertRepository) {
	if bus == nil || alerts == nil {
		return
	}
	bus.Subscribe(agent.EventMemberOverdue, func(event agent.Event) {
		defer func() {
			if r := recover(); r != nil {
				logger.Log.Error().Interface("panic", r).Msg("Recovered from panic in dunning alert handler")
			}
		}()
		mahalID, _ := event.Payload["mahal_id"].(string)
		memberID, _ := event.Payload["member_id"].(string)
		subject, _ := event.Payload["template_subject"].(string)
		body, _ := event.Payload["template_body"].(string)
		if mahalID == "" || memberID == "" {
			return
		}
		if subject == "" {
			subject = "Monthly dues reminder"
		}
		if body == "" {
			body = "Your monthly dues are pending. Please pay at your earliest convenience."
		}
		ctx, cancel := context.WithTimeout(context.Background(), eventHandlerTimeout)
		defer cancel()
		err := alerts.Create(ctx, &domain.SystemAlert{
			ID:          DunningAlertID(memberID, time.Now()),
			MahalID:     mahalID,
			Audience:    domain.AudienceMember,
			MemberIDs:   []string{memberID},
			Type:        domain.AlertTypeDuesReminder,
			Severity:    "WARNING",
			Title:       subject,
			Description: body,
			Status:      "ACTIVE",
			CreatedAt:   time.Now().UTC(),
		})
		if err != nil && !mongo.IsDuplicateKeyError(err) {
			logger.Log.Warn().Err(err).Str("member_id", memberID).Msg("Could not record dues reminder notice")
		}
	})
}
