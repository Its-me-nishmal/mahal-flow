// Package whatsapp provides a thin client for the Meta WhatsApp Business Cloud API.
//
// The client is designed to be safe to construct unconditionally: when credentials
// are absent it reports Enabled() == false and every send becomes a logged no-op
// returning ErrDisabled. Callers must treat notification failures as non-fatal —
// nothing in the payment or ledger path should depend on a message going out.
package whatsapp

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// ErrDisabled is returned by every send when credentials are not configured.
var ErrDisabled = errors.New("whatsapp: client disabled (missing credentials)")

// Client talks to the Meta Graph API for a single WhatsApp sender number.
type Client struct {
	BaseURL       string
	APIVersion    string
	PhoneNumberID string
	WABAID        string
	AccessToken   string
	AppSecret     string
	DryRun        bool
	HTTPClient    *http.Client
}

// Config parameters to initialize the WhatsApp client.
type Config struct {
	BaseURL       string
	APIVersion    string
	PhoneNumberID string
	WABAID        string
	AccessToken   string
	AppSecret     string
	DryRun        bool
	Timeout       time.Duration
}

// NewClient creates a client. It never fails: an unconfigured client is valid
// and simply disabled, so callers can wire it in before credentials exist.
func NewClient(cfg Config) *Client {
	timeout := cfg.Timeout
	if timeout == 0 {
		timeout = 15 * time.Second
	}

	baseURL := strings.TrimRight(cfg.BaseURL, "/")
	if baseURL == "" {
		baseURL = "https://graph.facebook.com"
	}

	apiVersion := strings.Trim(cfg.APIVersion, "/")
	if apiVersion == "" {
		apiVersion = "v21.0"
	}

	return &Client{
		BaseURL:       baseURL,
		APIVersion:    apiVersion,
		PhoneNumberID: cfg.PhoneNumberID,
		WABAID:        cfg.WABAID,
		AccessToken:   cfg.AccessToken,
		AppSecret:     cfg.AppSecret,
		DryRun:        cfg.DryRun,
		HTTPClient:    &http.Client{Timeout: timeout},
	}
}

// Enabled reports whether the client has the minimum credentials to send.
func (c *Client) Enabled() bool {
	return c != nil && c.AccessToken != "" && c.PhoneNumberID != ""
}

// Status returns a short human-readable reason for the current mode, for logging.
func (c *Client) Status() string {
	switch {
	case c == nil:
		return "nil client"
	case c.AccessToken == "" && c.PhoneNumberID == "":
		return "disabled: WHATSAPP_ACCESS_TOKEN and WHATSAPP_PHONE_NUMBER_ID unset"
	case c.AccessToken == "":
		return "disabled: WHATSAPP_ACCESS_TOKEN unset"
	case c.PhoneNumberID == "":
		return "disabled: WHATSAPP_PHONE_NUMBER_ID unset"
	case c.DryRun:
		return "enabled (dry-run: messages logged, not sent)"
	default:
		return "enabled"
	}
}

// ----------------------------------------------------------------------
// 1. RESPONSE MODELS
// ----------------------------------------------------------------------

// SendResult is the accepted-message envelope returned by the Graph API.
type SendResult struct {
	MessageID     string `json:"message_id"`
	WAID          string `json:"wa_id"`
	MessageStatus string `json:"message_status"`
	DryRun        bool   `json:"dry_run,omitempty"`
}

type graphSendResponse struct {
	MessagingProduct string `json:"messaging_product"`
	Contacts         []struct {
		Input string `json:"input"`
		WAID  string `json:"wa_id"`
	} `json:"contacts"`
	Messages []struct {
		ID            string `json:"id"`
		MessageStatus string `json:"message_status"`
	} `json:"messages"`
}

// APIError is a structured Graph API error. Code 131047 (re-engagement required)
// and 131026 (undeliverable) are expected in normal operation, not bugs.
type APIError struct {
	Code      int    `json:"code"`
	Subcode   int    `json:"error_subcode"`
	Type      string `json:"type"`
	Message   string `json:"message"`
	Details   string `json:"details"`
	FBTraceID string `json:"fbtrace_id"`
	HTTPS     int    `json:"-"`
}

func (e *APIError) Error() string {
	if e.Details != "" {
		return fmt.Sprintf("whatsapp api error [%d/%d]: %s (%s)", e.Code, e.Subcode, e.Message, e.Details)
	}
	return fmt.Sprintf("whatsapp api error [%d/%d]: %s", e.Code, e.Subcode, e.Message)
}

// IsRetryable reports whether resending later could plausibly succeed.
// Auth, template and re-engagement failures are permanent for this attempt.
func (e *APIError) IsRetryable() bool {
	switch e.Code {
	case 190, // access token expired / invalid
		131047,                                         // re-engagement required (outside 24h window)
		131026,                                         // message undeliverable (not on WhatsApp)
		132000, 132001, 132005, 132007, 132012, 132015: // template errors
		return false
	case 4, 80007, 130429, 131048, 131056: // rate limits & throttling
		return true
	}
	return e.HTTPS >= 500
}

// IsTokenExpired reports the specific case worth alerting an operator about.
func (e *APIError) IsTokenExpired() bool { return e.Code == 190 }

// ----------------------------------------------------------------------
// 2. SEND METHODS
// ----------------------------------------------------------------------

// TemplateParam is one positional {{n}} substitution in a template body.
type TemplateParam struct {
	Text string
}

// SendTemplate sends an approved message template. This is the only message
// type that reaches a recipient outside the 24-hour customer service window,
// so all proactive notifications (dues reminders, receipts) must use it.
func (c *Client) SendTemplate(ctx context.Context, to, templateName, langCode string, params []TemplateParam) (*SendResult, error) {
	if !c.Enabled() {
		return nil, ErrDisabled
	}

	normalized, err := NormalizePhone(to)
	if err != nil {
		return nil, err
	}

	if langCode == "" {
		langCode = "en_US"
	}

	template := map[string]interface{}{
		"name":     templateName,
		"language": map[string]string{"code": langCode},
	}

	if len(params) > 0 {
		bodyParams := make([]map[string]string, 0, len(params))
		for _, p := range params {
			bodyParams = append(bodyParams, map[string]string{"type": "text", "text": p.Text})
		}
		template["components"] = []map[string]interface{}{
			{"type": "body", "parameters": bodyParams},
		}
	}

	return c.send(ctx, map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                normalized,
		"type":              "template",
		"template":          template,
	})
}

// SendText sends a free-form text message. This only reaches the recipient
// inside an open 24-hour customer service window (i.e. after they message the
// business first); outside it the API accepts the call and then fails delivery
// asynchronously with code 131047. Prefer SendTemplate for anything proactive.
func (c *Client) SendText(ctx context.Context, to, body string) (*SendResult, error) {
	if !c.Enabled() {
		return nil, ErrDisabled
	}

	normalized, err := NormalizePhone(to)
	if err != nil {
		return nil, err
	}

	return c.send(ctx, map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                normalized,
		"type":              "text",
		"text":              map[string]interface{}{"preview_url": false, "body": body},
	})
}

// MarkRead marks an inbound message as read (the blue ticks). Best effort.
func (c *Client) MarkRead(ctx context.Context, messageID string) error {
	if !c.Enabled() {
		return ErrDisabled
	}
	_, err := c.send(ctx, map[string]interface{}{
		"messaging_product": "whatsapp",
		"status":            "read",
		"message_id":        messageID,
	})
	return err
}

func (c *Client) send(ctx context.Context, payload map[string]interface{}) (*SendResult, error) {
	if c.DryRun {
		return &SendResult{MessageID: "dryrun", MessageStatus: "dry_run", DryRun: true}, nil
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("whatsapp: marshal payload: %w", err)
	}

	endpoint := fmt.Sprintf("%s/%s/%s/messages", c.BaseURL, c.APIVersion, c.PhoneNumberID)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.AccessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("whatsapp: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("whatsapp: read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		var errEnvelope struct {
			Error APIError `json:"error"`
		}
		if json.Unmarshal(respBody, &errEnvelope) == nil && errEnvelope.Error.Message != "" {
			apiErr := errEnvelope.Error
			apiErr.HTTPS = resp.StatusCode
			return nil, &apiErr
		}
		return nil, fmt.Errorf("whatsapp: status %d: %s", resp.StatusCode, string(respBody))
	}

	var parsed graphSendResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return nil, fmt.Errorf("whatsapp: parse response: %w", err)
	}

	result := &SendResult{}
	if len(parsed.Messages) > 0 {
		result.MessageID = parsed.Messages[0].ID
		result.MessageStatus = parsed.Messages[0].MessageStatus
	}
	if len(parsed.Contacts) > 0 {
		result.WAID = parsed.Contacts[0].WAID
	}
	if result.MessageID == "" {
		return nil, errors.New("whatsapp: response contained no message id")
	}

	return result, nil
}

// ----------------------------------------------------------------------
// 3. WEBHOOK VERIFICATION
// ----------------------------------------------------------------------

// VerifySignature validates the X-Hub-Signature-256 header on an inbound
// webhook against the app secret. Returns false when the app secret is unset,
// so an unconfigured deployment rejects rather than trusts unsigned payloads.
func (c *Client) VerifySignature(header string, body []byte) bool {
	if c == nil || c.AppSecret == "" {
		return false
	}

	sig := strings.TrimPrefix(header, "sha256=")
	if sig == "" {
		return false
	}

	expected, err := hex.DecodeString(sig)
	if err != nil {
		return false
	}

	mac := hmac.New(sha256.New, []byte(c.AppSecret))
	mac.Write(body)
	return hmac.Equal(expected, mac.Sum(nil))
}

// SignatureConfigured reports whether inbound webhook signatures can be checked.
func (c *Client) SignatureConfigured() bool {
	return c != nil && c.AppSecret != ""
}
