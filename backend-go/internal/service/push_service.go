package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/fcm"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/rs/zerolog/log"
)

// Push kinds. They are the `type` key the app routes a tap on, so keep them
// in step with PushNotificationService in the Flutter app.
const (
	PushKindAlert         = "ALERT"
	PushKindDuesReminder  = "DUES_REMINDER"
	PushKindReceipt       = "RECEIPT"
	PushKindPaymentFailed = "PAYMENT_FAILED"
	PushKindAutoPay       = "AUTOPAY"
)

// pushConcurrency caps parallel FCM calls during a broadcast.
const pushConcurrency = 8

// PushNotification is what to show and where a tap should lead.
type PushNotification struct {
	Kind  string
	Title string
	Body  string
	// Data is merged into the FCM data payload (alert_id, severity, ...).
	Data map[string]string
}

// PushService fans a notification out to every device registered for its
// recipients. Every method is best-effort: it logs failures and never returns
// them, because no caller should fail over a push not going out.
type PushService struct {
	client *fcm.Client
	tokens repository.DeviceTokenRepository
}

func NewPushService(client *fcm.Client, tokens repository.DeviceTokenRepository) *PushService {
	return &PushService{client: client, tokens: tokens}
}

// Enabled reports whether pushes will actually be sent.
func (s *PushService) Enabled() bool {
	return s != nil && s.client.Enabled() && s.tokens != nil
}

// SendToMember pushes to every device of one member.
func (s *PushService) SendToMember(ctx context.Context, mahalID, memberID string, n PushNotification) {
	if !s.Enabled() {
		return
	}
	devices, err := s.tokens.ListByMember(ctx, mahalID, memberID)
	if err != nil {
		log.Warn().Err(err).Str("member_id", memberID).Msg("push: list member devices")
		return
	}
	s.deliver(ctx, devices, n)
}

// SendToMembers pushes to every device of the given members.
func (s *PushService) SendToMembers(ctx context.Context, mahalID string, memberIDs []string, n PushNotification) {
	if !s.Enabled() || len(memberIDs) == 0 {
		return
	}
	devices, err := s.tokens.ListByMembers(ctx, mahalID, memberIDs)
	if err != nil {
		log.Warn().Err(err).Str("mahal_id", mahalID).Msg("push: list devices")
		return
	}
	s.deliver(ctx, devices, n)
}

// SendToMahal pushes to every registered device in the Mahal.
func (s *PushService) SendToMahal(ctx context.Context, mahalID string, n PushNotification) {
	if !s.Enabled() {
		return
	}
	devices, err := s.tokens.ListByMahal(ctx, mahalID)
	if err != nil {
		log.Warn().Err(err).Str("mahal_id", mahalID).Msg("push: list mahal devices")
		return
	}
	s.deliver(ctx, devices, n)
}

// NotifyReceipt tells a member their payment is confirmed.
func (s *PushService) NotifyReceipt(ctx context.Context, r *domain.Receipt) {
	if r == nil {
		return
	}
	body := fmt.Sprintf("₹%.0f received. Receipt %s is ready.", r.Amount, r.ReceiptNumber)
	if len(r.PaidMonths) > 0 {
		body = fmt.Sprintf("₹%.0f received for %s. Receipt %s is ready.",
			r.Amount, strings.Join(r.PaidMonths, ", "), r.ReceiptNumber)
	}
	s.SendToMember(ctx, r.MahalID, r.MemberID, PushNotification{
		Kind:  PushKindReceipt,
		Title: "Payment confirmed",
		Body:  body,
		Data:  map[string]string{"receipt_number": r.ReceiptNumber},
	})
}

func (s *PushService) deliver(ctx context.Context, devices []repository.DeviceToken, n PushNotification) {
	if len(devices) == 0 {
		return
	}
	data := map[string]string{"type": n.Kind, "title": n.Title, "body": n.Body}
	for k, v := range n.Data {
		data[k] = v
	}

	var (
		wg           sync.WaitGroup
		mu           sync.Mutex
		sent, failed int
		sem          = make(chan struct{}, pushConcurrency)
	)
	for _, d := range devices {
		wg.Add(1)
		sem <- struct{}{}
		go func(d repository.DeviceToken) {
			defer wg.Done()
			defer func() { <-sem }()
			_, err := s.client.Send(ctx, fcm.Message{Token: d.Token, Title: n.Title, Body: n.Body, Data: data})
			mu.Lock()
			defer mu.Unlock()
			if err == nil {
				sent++
				return
			}
			failed++
			if errors.Is(err, fcm.ErrUnregistered) {
				// App uninstalled or token rotated: stop targeting it.
				_ = s.tokens.Delete(ctx, d.Token)
				return
			}
			log.Warn().Err(err).Str("member_id", d.MemberID).Str("kind", n.Kind).Msg("push: send failed")
		}(d)
	}
	wg.Wait()
	log.Info().Str("kind", n.Kind).Int("sent", sent).Int("failed", failed).Msg("push: delivered")
}
