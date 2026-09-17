package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/rs/zerolog"
)

// Notification kinds recorded in the notification log.
const (
	NotifyKindDuesReminder = "DUES_REMINDER"
	NotifyKindReceipt      = "RECEIPT"
)

// sendTimeout bounds a single outbound message so a slow Graph API cannot
// pin an agent goroutine indefinitely.
const sendTimeout = 20 * time.Second

// NotificationTemplates names the approved WhatsApp templates to use. An empty
// name means "no approved template yet": the service then falls back to a
// free-form text message, which only reaches members inside an open 24-hour
// window. That keeps the feature usable during development and while Meta
// template approval is pending, without changing any calling code later —
// approval only requires setting the corresponding env var.
type NotificationTemplates struct {
	DuesReminder string
	Receipt      string
}

// NotificationService turns domain events into outbound member messages.
//
// Every method is best-effort by construction: failures are logged and
// swallowed, never returned into a payment or ledger path. A disabled
// WhatsApp client makes the whole service an explicit no-op.
type NotificationService struct {
	wa        *whatsapp.Client
	notifRepo repository.NotificationRepository
	templates NotificationTemplates
}

func NewNotificationService(
	wa *whatsapp.Client,
	notifRepo repository.NotificationRepository,
	templates NotificationTemplates,
) *NotificationService {
	return &NotificationService{wa: wa, notifRepo: notifRepo, templates: templates}
}

// Enabled reports whether messages can actually go out.
func (s *NotificationService) Enabled() bool {
	return s != nil && s.wa.Enabled() && s.notifRepo != nil
}

// SendDuesReminder messages one overdue member. dedupeDay scopes the dedupe key
// so a member receives at most one reminder per day no matter how often the
// dunning agent re-scans.
func (s *NotificationService) SendDuesReminder(
	ctx context.Context,
	mahalID string,
	member domain.Member,
	language, body string,
	dedupeDay time.Time,
) {
	if !s.Enabled() {
		return
	}

	dedupeKey := fmt.Sprintf("%s:%s:%s", NotifyKindDuesReminder, member.ID, dedupeDay.Format("2006-01-02"))

	s.dispatch(ctx, dispatchRequest{
		MahalID:   mahalID,
		MemberID:  member.ID,
		Phone:     member.Phone,
		Kind:      NotifyKindDuesReminder,
		DedupeKey: dedupeKey,
		Language:  language,
		Template:  s.templates.DuesReminder,
		TemplateParams: []whatsapp.TemplateParam{
			{Text: member.Name},
			{Text: formatAmount(member.OutstandingBalance)},
		},
		FallbackText: body,
	})
}

// SendReceipt messages a member their receipt after a successful payment.
// The receipt number is the dedupe key, so a webhook retry or reconciliation
// re-run cannot produce a duplicate message.
func (s *NotificationService) SendReceipt(ctx context.Context, receipt *domain.Receipt, phone, language string) {
	if !s.Enabled() || receipt == nil {
		return
	}

	months := ""
	if len(receipt.PaidMonths) > 0 {
		months = strings.Join(receipt.PaidMonths, ", ")
	}

	fallback := fmt.Sprintf(
		"Payment received. Receipt %s for %s. Thank you, %s.",
		receipt.ReceiptNumber, formatAmount(receipt.Amount), receipt.MemberName,
	)
	if months != "" {
		fallback = fmt.Sprintf(
			"Payment received for %s. Receipt %s for %s. Thank you, %s.",
			months, receipt.ReceiptNumber, formatAmount(receipt.Amount), receipt.MemberName,
		)
	}

	s.dispatch(ctx, dispatchRequest{
		MahalID:   receipt.MahalID,
		MemberID:  receipt.MemberID,
		Phone:     phone,
		Kind:      NotifyKindReceipt,
		DedupeKey: NotifyKindReceipt + ":" + receipt.ReceiptNumber,
		Language:  language,
		Template:  s.templates.Receipt,
		TemplateParams: []whatsapp.TemplateParam{
			{Text: receipt.MemberName},
			{Text: formatAmount(receipt.Amount)},
			{Text: receipt.ReceiptNumber},
		},
		FallbackText: fallback,
	})
}

type dispatchRequest struct {
	MahalID        string
	MemberID       string
	Phone          string
	Kind           string
	DedupeKey      string
	Language       string
	Template       string
	TemplateParams []whatsapp.TemplateParam
	FallbackText   string
}

// dispatch claims the dedupe key first, then sends. Claiming before sending
// means a crash mid-send can at worst drop a message — never duplicate one.
func (s *NotificationService) dispatch(ctx context.Context, req dispatchRequest) {
	log := logger.Log.With().
		Str("component", "notification").
		Str("kind", req.Kind).
		Str("mahal_id", req.MahalID).
		Str("member_id", req.MemberID).
		Logger()

	// Validate the number before burning a dedupe key on it.
	normalized, err := whatsapp.NormalizePhone(req.Phone)
	if err != nil {
		log.Warn().Err(err).Msg("Skipping notification: member phone is not a valid number")
		return
	}

	entry := &repository.NotificationLog{
		ID:          uuid.NewString(),
		MahalID:     req.MahalID,
		MemberID:    req.MemberID,
		Channel:     "WHATSAPP",
		Kind:        req.Kind,
		DedupeKey:   req.DedupeKey,
		Language:    req.Language,
		Template:    req.Template,
		MaskedPhone: whatsapp.MaskPhone(normalized),
	}

	if err := s.notifRepo.ClaimSend(ctx, entry); err != nil {
		if errors.Is(err, repository.ErrNotificationAlreadySent) {
			log.Debug().Str("dedupe_key", req.DedupeKey).Msg("Notification already sent, skipping")
			return
		}
		log.Error().Err(err).Msg("Could not claim notification slot, skipping send")
		return
	}

	sendCtx, cancel := context.WithTimeout(ctx, sendTimeout)
	defer cancel()

	var result *whatsapp.SendResult
	if req.Template != "" {
		result, err = s.wa.SendTemplate(sendCtx, normalized, req.Template, templateLangCode(req.Language), req.TemplateParams)
	} else {
		// No approved template configured yet; only lands inside an open window.
		result, err = s.wa.SendText(sendCtx, normalized, req.FallbackText)
	}

	if err != nil {
		s.recordFailure(ctx, entry.ID, err, log)
		return
	}

	if err := s.notifRepo.MarkSent(ctx, entry.ID, result.MessageID); err != nil {
		log.Warn().Err(err).Msg("Message sent but marking it sent failed")
	}

	log.Info().
		Str("message_id", result.MessageID).
		Str("masked_phone", entry.MaskedPhone).
		Bool("dry_run", result.DryRun).
		Bool("templated", req.Template != "").
		Msg("Member notification sent")
}

func (s *NotificationService) recordFailure(ctx context.Context, entryID string, err error, log zerolog.Logger) {
	var apiErr *whatsapp.APIError
	if errors.As(err, &apiErr) {
		switch {
		case apiErr.IsTokenExpired():
			log.Error().Err(err).Msg(
				"WhatsApp access token rejected — refresh WHATSAPP_ACCESS_TOKEN (dashboard tokens expire after 24h)")
		case apiErr.Code == 131047:
			log.Info().Err(err).Msg(
				"Outside the 24h window and no approved template configured — set WHATSAPP_TEMPLATE_* to reach this member")
		default:
			log.Warn().Err(err).Int("code", apiErr.Code).Bool("retryable", apiErr.IsRetryable()).
				Msg("WhatsApp send failed")
		}
	} else {
		log.Warn().Err(err).Msg("WhatsApp send failed")
	}

	if mErr := s.notifRepo.MarkFailed(ctx, entryID, err.Error()); mErr != nil {
		log.Warn().Err(mErr).Msg("Could not record notification failure")
	}
}

// templateLangCode maps the dunning agent's language codes onto the locale
// codes Meta uses when a template is registered.
func templateLangCode(lang string) string {
	switch lang {
	case "ml":
		return "ml"
	case "ur":
		return "ur"
	case "ta":
		return "ta"
	case "", "en":
		return "en_US"
	default:
		return lang
	}
}

func formatAmount(amount float64) string {
	return fmt.Sprintf("%.2f", amount)
}
