// Package fcm is a thin client for the Firebase Cloud Messaging HTTP v1 API.
//
// Like the WhatsApp client it is safe to construct unconditionally: without a
// service account it reports Enabled() == false and every send returns
// ErrDisabled. Push is best-effort; nothing in the payment or ledger path may
// depend on it.
//
// Auth uses the service account's private key to mint a signed JWT, which is
// exchanged for an OAuth2 access token (cached until shortly before expiry).
// This avoids pulling the full Firebase Admin SDK into the module.
package fcm

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

// ErrDisabled is returned by every send when no service account is configured.
var ErrDisabled = errors.New("fcm: client disabled (missing service account)")

// ErrUnregistered means the device token is no longer valid (app uninstalled,
// token rotated). Callers should delete the token.
var ErrUnregistered = errors.New("fcm: device token unregistered")

const (
	scope         = "https://www.googleapis.com/auth/firebase.messaging"
	defaultAPIURL = "https://fcm.googleapis.com"
)

// Config selects the service account. JSON wins over File when both are set.
type Config struct {
	ServiceAccountFile string
	ServiceAccountJSON string
	// DryRun validates messages with FCM without delivering them.
	DryRun  bool
	Timeout time.Duration
}

type serviceAccount struct {
	ProjectID   string `json:"project_id"`
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
	TokenURI    string `json:"token_uri"`
}

// Client sends messages for one Firebase project.
type Client struct {
	projectID string
	email     string
	key       *rsa.PrivateKey
	tokenURI  string
	apiURL    string
	dryRun    bool
	http      *http.Client

	mu          sync.Mutex
	accessToken string
	expiresAt   time.Time
}

// NewClient never fails: a missing or unreadable service account yields a
// disabled client and the reason, so the server still starts.
func NewClient(cfg Config) (*Client, error) {
	timeout := cfg.Timeout
	if timeout == 0 {
		timeout = 10 * time.Second
	}
	c := &Client{apiURL: defaultAPIURL, dryRun: cfg.DryRun, http: &http.Client{Timeout: timeout}}

	raw := []byte(strings.TrimSpace(cfg.ServiceAccountJSON))
	if len(raw) == 0 && cfg.ServiceAccountFile != "" {
		b, err := os.ReadFile(cfg.ServiceAccountFile)
		if err != nil {
			return c, fmt.Errorf("fcm: read service account: %w", err)
		}
		raw = b
	}
	if len(raw) == 0 {
		return c, nil
	}

	var sa serviceAccount
	if err := json.Unmarshal(raw, &sa); err != nil {
		return c, fmt.Errorf("fcm: parse service account: %w", err)
	}
	key, err := parseKey(sa.PrivateKey)
	if err != nil {
		return c, err
	}
	if sa.ProjectID == "" || sa.ClientEmail == "" {
		return c, errors.New("fcm: service account missing project_id or client_email")
	}
	c.projectID = sa.ProjectID
	c.email = sa.ClientEmail
	c.key = key
	c.tokenURI = sa.TokenURI
	if c.tokenURI == "" {
		c.tokenURI = "https://oauth2.googleapis.com/token"
	}
	return c, nil
}

func parseKey(p string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(p))
	if block == nil {
		return nil, errors.New("fcm: service account private_key is not PEM")
	}
	k, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		if rk, err2 := x509.ParsePKCS1PrivateKey(block.Bytes); err2 == nil {
			return rk, nil
		}
		return nil, fmt.Errorf("fcm: parse private key: %w", err)
	}
	rk, ok := k.(*rsa.PrivateKey)
	if !ok {
		return nil, errors.New("fcm: private key is not RSA")
	}
	return rk, nil
}

// Enabled reports whether a service account is loaded.
func (c *Client) Enabled() bool { return c != nil && c.key != nil }

// Status is a one-word summary for startup logs.
func (c *Client) Status() string {
	switch {
	case !c.Enabled():
		return "disabled"
	case c.dryRun:
		return "dry-run (" + c.projectID + ")"
	default:
		return "live (" + c.projectID + ")"
	}
}

// Message is one push to one device.
type Message struct {
	Token string
	Title string
	Body  string
	// Data travels to the app for tap routing. FCM requires string values.
	Data map[string]string
}

// Send delivers one message and returns FCM's message name. A token FCM no
// longer recognises yields ErrUnregistered.
func (c *Client) Send(ctx context.Context, m Message) (string, error) {
	if !c.Enabled() {
		return "", ErrDisabled
	}
	token, err := c.oauthToken(ctx)
	if err != nil {
		return "", err
	}

	payload := map[string]any{
		"validate_only": c.dryRun,
		"message": map[string]any{
			"token":        m.Token,
			"notification": map[string]string{"title": m.Title, "body": m.Body},
			"data":         m.Data,
			"android": map[string]any{
				"priority": "HIGH",
				"notification": map[string]string{
					// Must match the channel the app creates at startup.
					"channel_id": "mahalflow_default",
					"icon":       "ic_stat_notification",
					"color":      "#146C5B",
				},
			},
			"apns": map[string]any{
				"payload": map[string]any{"aps": map[string]any{"sound": "default"}},
			},
		},
	}
	body, _ := json.Marshal(payload)

	endpoint := fmt.Sprintf("%s/v1/projects/%s/messages:send", c.apiURL, c.projectID)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("fcm: send: %w", err)
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))

	if resp.StatusCode == http.StatusOK {
		var ok struct {
			Name string `json:"name"`
		}
		_ = json.Unmarshal(respBody, &ok)
		return ok.Name, nil
	}

	var fe struct {
		Error struct {
			Status  string `json:"status"`
			Message string `json:"message"`
			Details []struct {
				ErrorCode string `json:"errorCode"`
			} `json:"details"`
		} `json:"error"`
	}
	_ = json.Unmarshal(respBody, &fe)
	for _, d := range fe.Error.Details {
		if d.ErrorCode == "UNREGISTERED" {
			return "", ErrUnregistered
		}
	}
	if resp.StatusCode == http.StatusNotFound {
		return "", ErrUnregistered
	}
	return "", fmt.Errorf("fcm: send failed (%d %s): %s", resp.StatusCode, fe.Error.Status, fe.Error.Message)
}

// oauthToken returns a cached access token, minting a new one via the JWT
// bearer grant when the cached one is within a minute of expiring.
func (c *Client) oauthToken(ctx context.Context) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.accessToken != "" && time.Until(c.expiresAt) > time.Minute {
		return c.accessToken, nil
	}

	now := time.Now()
	assertion, err := c.signJWT(now)
	if err != nil {
		return "", err
	}
	form := url.Values{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {assertion},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.tokenURI, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := c.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("fcm: token exchange: %w", err)
	}
	defer resp.Body.Close()
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("fcm: token exchange failed (%d): %s", resp.StatusCode, string(b))
	}
	var tr struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.Unmarshal(b, &tr); err != nil || tr.AccessToken == "" {
		return "", fmt.Errorf("fcm: token exchange: bad response")
	}
	c.accessToken = tr.AccessToken
	c.expiresAt = now.Add(time.Duration(tr.ExpiresIn) * time.Second)
	return c.accessToken, nil
}

func (c *Client) signJWT(now time.Time) (string, error) {
	enc := base64.RawURLEncoding
	header, _ := json.Marshal(map[string]string{"alg": "RS256", "typ": "JWT"})
	claims, _ := json.Marshal(map[string]any{
		"iss":   c.email,
		"scope": scope,
		"aud":   c.tokenURI,
		"iat":   now.Unix(),
		"exp":   now.Add(time.Hour).Unix(),
	})
	signing := enc.EncodeToString(header) + "." + enc.EncodeToString(claims)
	sum := sha256.Sum256([]byte(signing))
	sig, err := rsa.SignPKCS1v15(rand.Reader, c.key, crypto.SHA256, sum[:])
	if err != nil {
		return "", fmt.Errorf("fcm: sign jwt: %w", err)
	}
	return signing + "." + enc.EncodeToString(sig), nil
}
