package api

import (
	"context"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
)

// WhatsAppHandler serves Meta's webhook callbacks: the subscription handshake,
// per-message delivery receipts, and inbound member replies.
//
// It is kept separate from the main Handler so the WhatsApp integration can be
// mounted, or left unmounted, without touching existing route wiring.
type WhatsAppHandler struct {
	wa          *whatsapp.Client
	notifRepo   repository.NotificationRepository
	verifyToken string
}

func NewWhatsAppHandler(
	wa *whatsapp.Client,
	notifRepo repository.NotificationRepository,
	verifyToken string,
) *WhatsAppHandler {
	return &WhatsAppHandler{wa: wa, notifRepo: notifRepo, verifyToken: verifyToken}
}

// webhookPayload is the subset of Meta's envelope MahalFlow acts on.
type webhookPayload struct {
	Object string `json:"object"`
	Entry  []struct {
		ID      string `json:"id"`
		Changes []struct {
			Field string `json:"field"`
			Value struct {
				MessagingProduct string `json:"messaging_product"`
				Metadata         struct {
					DisplayPhoneNumber string `json:"display_phone_number"`
					PhoneNumberID      string `json:"phone_number_id"`
				} `json:"metadata"`
				Statuses []struct {
					ID          string `json:"id"`
					Status      string `json:"status"`
					Timestamp   string `json:"timestamp"`
					RecipientID string `json:"recipient_id"`
					Errors      []struct {
						Code    int    `json:"code"`
						Title   string `json:"title"`
						Message string `json:"message"`
					} `json:"errors"`
				} `json:"statuses"`
				Messages []struct {
					From      string `json:"from"`
					ID        string `json:"id"`
					Timestamp string `json:"timestamp"`
					Type      string `json:"type"`
					Text      struct {
						Body string `json:"body"`
					} `json:"text"`
				} `json:"messages"`
			} `json:"value"`
		} `json:"changes"`
	} `json:"entry"`
}

// VerifyWebhook handles the GET subscription handshake. Meta calls this once
// when the webhook URL is registered and expects hub.challenge echoed back
// verbatim as plain text.
func (h *WhatsAppHandler) VerifyWebhook(c *fiber.Ctx) error {
	mode := c.Query("hub.mode")
	token := c.Query("hub.verify_token")
	challenge := c.Query("hub.challenge")

	if h.verifyToken == "" {
		logger.Log.Warn().Msg("WhatsApp webhook verification attempted but WHATSAPP_WEBHOOK_VERIFY_TOKEN is unset")
		return c.SendStatus(fiber.StatusForbidden)
	}

	if mode != "subscribe" || token != h.verifyToken {
		logger.Log.Warn().Str("mode", mode).Msg("Rejected WhatsApp webhook verification: token mismatch")
		return c.SendStatus(fiber.StatusForbidden)
	}

	logger.Log.Info().Msg("WhatsApp webhook subscription verified")
	return c.SendString(challenge)
}

// HandleWebhook processes delivery statuses and inbound messages.
//
// Meta retries any non-200 response with backoff, so this always returns 200
// once the payload is authenticated: a parse failure on one event must not
// cause Meta to redeliver the entire batch indefinitely.
func (h *WhatsAppHandler) HandleWebhook(c *fiber.Ctx) error {
	body := c.Body()

	// Signature verification is mandatory. Without the app secret configured
	// the endpoint refuses everything rather than trusting unsigned callers.
	if !h.wa.SignatureConfigured() {
		logger.Log.Error().Msg(
			"Rejected WhatsApp webhook: WHATSAPP_APP_SECRET is unset, signatures cannot be verified")
		return c.SendStatus(fiber.StatusForbidden)
	}

	if !h.wa.VerifySignature(c.Get("X-Hub-Signature-256"), body) {
		logger.Log.Warn().Msg("Rejected WhatsApp webhook: invalid X-Hub-Signature-256")
		return c.SendStatus(fiber.StatusForbidden)
	}

	var payload webhookPayload
	if err := c.BodyParser(&payload); err != nil {
		logger.Log.Warn().Err(err).Msg("Could not parse WhatsApp webhook payload")
		return c.SendStatus(fiber.StatusOK)
	}

	ctx := c.Context()

	for _, entry := range payload.Entry {
		for _, change := range entry.Changes {
			for _, status := range change.Value.Statuses {
				h.applyDeliveryStatus(ctx, status.ID, status.Status, status.Timestamp)

				if len(status.Errors) > 0 {
					e := status.Errors[0]
					logger.Log.Warn().
						Str("message_id", status.ID).
						Int("code", e.Code).
						Str("title", e.Title).
						Msg("WhatsApp reported a delivery failure")
				}
			}

			for _, msg := range change.Value.Messages {
				// An inbound message opens a 24-hour window during which
				// free-form replies to this member are deliverable.
				logger.Log.Info().
					Str("from", whatsapp.MaskPhone(msg.From)).
					Str("type", msg.Type).
					Str("message_id", msg.ID).
					Msg("Inbound WhatsApp message received")
			}
		}
	}

	return c.SendStatus(fiber.StatusOK)
}

func (h *WhatsAppHandler) applyDeliveryStatus(ctx context.Context, messageID, status, timestamp string) {
	if h.notifRepo == nil || messageID == "" {
		return
	}

	// Meta sends the status timestamp as seconds since the Unix epoch, as a string.
	at := time.Now().UTC()
	if timestamp != "" {
		if secs, err := strconv.ParseInt(timestamp, 10, 64); err == nil {
			at = time.Unix(secs, 0).UTC()
		}
	}

	if err := h.notifRepo.UpdateDeliveryStatus(ctx, messageID, status, at); err != nil {
		logger.Log.Warn().Err(err).
			Str("message_id", messageID).
			Str("status", status).
			Msg("Could not record WhatsApp delivery status")
	}
}
