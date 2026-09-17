package service

import (
	"context"
	"time"

	"github.com/mahalflow/backend-go/internal/agent"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
)

// eventHandlerTimeout bounds the work done for a single event.
const eventHandlerTimeout = 30 * time.Second

// SubscribeDunningNotifications connects the dunning agent's MEMBER_OVERDUE
// events to outbound WhatsApp delivery. Without this the agent computes
// reminders and discards them.
//
// EventBus dispatches each handler in its own goroutine, so this handler must
// never panic: a panic here would take down the whole worker process.
func SubscribeDunningNotifications(bus *agent.EventBus, notifier *NotificationService) {
	if bus == nil || notifier == nil || !notifier.Enabled() {
		return
	}

	bus.Subscribe(agent.EventMemberOverdue, func(event agent.Event) {
		defer func() {
			if r := recover(); r != nil {
				logger.Log.Error().Interface("panic", r).
					Msg("Recovered from panic in dunning notification handler")
			}
		}()

		mahalID, _ := event.Payload["mahal_id"].(string)
		memberID, _ := event.Payload["member_id"].(string)
		memberName, _ := event.Payload["member_name"].(string)
		phone, _ := event.Payload["member_phone"].(string)
		language, _ := event.Payload["language"].(string)
		body, _ := event.Payload["template_body"].(string)
		outstanding, _ := event.Payload["outstanding"].(float64)

		if mahalID == "" || memberID == "" || phone == "" {
			logger.Log.Warn().
				Str("mahal_id", mahalID).
				Str("member_id", memberID).
				Bool("has_phone", phone != "").
				Msg("Skipping dunning notification: incomplete event payload")
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), eventHandlerTimeout)
		defer cancel()

		// The dunning agent schedules an optimal delivery hour, but the worker
		// re-scans hourly and the dedupe key is day-scoped, so the reminder
		// goes out on the first scan of the day rather than being held in
		// memory across a restart.
		notifier.SendDuesReminder(ctx, mahalID, domain.Member{
			ID:                 memberID,
			Name:               memberName,
			Phone:              phone,
			OutstandingBalance: outstanding,
		}, language, body, time.Now().UTC())
	})
}
