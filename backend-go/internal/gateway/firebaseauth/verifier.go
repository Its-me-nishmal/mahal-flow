// Package firebaseauth verifies Firebase Authentication ID tokens server-side.
//
// It implements the checks the Firebase Admin SDK's auth.VerifyIDToken performs
// (https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library):
//
//   - header alg RS256 and a kid naming one of Google's current securetoken
//     signing certificates, and a valid RSA-SHA256 signature by that key
//   - aud == the Firebase project id, iss == https://securetoken.google.com/<project id>
//   - exp in the future, iat and auth_time in the past, sub non-empty
//
// Like the fcm package it deliberately avoids the full Admin SDK (which would
// pull in gRPC/Cloud dependencies and a newer Go toolchain than the Docker
// image ships): only the public signing certificates are fetched, and they are
// cached for as long as Google's Cache-Control allows.
package firebaseauth

import (
	"context"
	"crypto"
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
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

// CertsURL publishes the X.509 certificates that sign Firebase ID tokens.
const CertsURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

// clockSkew tolerates small clock differences between the device, Google and
// this server for iat / auth_time / exp.
const clockSkew = 5 * time.Minute

var (
	ErrMalformed = errors.New("firebaseauth: malformed ID token")
	ErrSignature = errors.New("firebaseauth: invalid ID token signature")
	ErrExpired   = errors.New("firebaseauth: ID token expired")
	ErrClaims    = errors.New("firebaseauth: ID token claims invalid")
)

// Token is the verified subset of an ID token the API relies on.
type Token struct {
	UID         string
	PhoneNumber string // E.164, only present for phone-auth sign-ins
	IssuedAt    time.Time
	ExpiresAt   time.Time
	AuthTime    time.Time
}

// Verifier checks a Firebase ID token. Handlers depend on this interface so
// tests can substitute a fake.
type Verifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*Token, error)
}

// KeySource returns the current signing keys by kid.
type KeySource interface {
	Keys(ctx context.Context) (map[string]*rsa.PublicKey, error)
}

// IDTokenVerifier is the production Verifier.
type IDTokenVerifier struct {
	projectID string
	keys      KeySource
	now       func() time.Time
}

// NewVerifier verifies tokens for projectID using Google's published certs.
func NewVerifier(projectID string, httpClient *http.Client) (*IDTokenVerifier, error) {
	if strings.TrimSpace(projectID) == "" {
		return nil, errors.New("firebaseauth: project id is required")
	}
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 10 * time.Second}
	}
	return NewVerifierWithKeys(projectID, &httpKeySource{url: CertsURL, http: httpClient}), nil
}

// NewVerifierWithKeys is NewVerifier with an explicit key source (tests).
func NewVerifierWithKeys(projectID string, keys KeySource) *IDTokenVerifier {
	return &IDTokenVerifier{projectID: projectID, keys: keys, now: time.Now}
}

// ProjectID is the project tokens must be issued for.
func (v *IDTokenVerifier) ProjectID() string { return v.projectID }

type header struct {
	Alg string `json:"alg"`
	Kid string `json:"kid"`
}

type claims struct {
	Aud         string `json:"aud"`
	Iss         string `json:"iss"`
	Sub         string `json:"sub"`
	Iat         int64  `json:"iat"`
	Exp         int64  `json:"exp"`
	AuthTime    int64  `json:"auth_time"`
	PhoneNumber string `json:"phone_number"`
}

func (v *IDTokenVerifier) VerifyIDToken(ctx context.Context, idToken string) (*Token, error) {
	parts := strings.Split(strings.TrimSpace(idToken), ".")
	if len(parts) != 3 {
		return nil, ErrMalformed
	}
	var h header
	if err := decodeSegment(parts[0], &h); err != nil {
		return nil, ErrMalformed
	}
	if h.Alg != "RS256" || h.Kid == "" {
		return nil, fmt.Errorf("%w: unexpected alg %q or missing kid", ErrMalformed, h.Alg)
	}
	var cl claims
	if err := decodeSegment(parts[1], &cl); err != nil {
		return nil, ErrMalformed
	}

	keys, err := v.keys.Keys(ctx)
	if err != nil {
		return nil, fmt.Errorf("firebaseauth: load signing keys: %w", err)
	}
	pub, ok := keys[h.Kid]
	if !ok {
		return nil, fmt.Errorf("%w: unknown kid", ErrSignature)
	}
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return nil, ErrMalformed
	}
	digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if err := rsa.VerifyPKCS1v15(pub, crypto.SHA256, digest[:], sig); err != nil {
		return nil, ErrSignature
	}

	now := v.now()
	switch {
	case cl.Aud != v.projectID:
		return nil, fmt.Errorf("%w: aud", ErrClaims)
	case cl.Iss != "https://securetoken.google.com/"+v.projectID:
		return nil, fmt.Errorf("%w: iss", ErrClaims)
	case cl.Sub == "" || len(cl.Sub) > 128:
		return nil, fmt.Errorf("%w: sub", ErrClaims)
	case cl.Exp == 0 || now.After(time.Unix(cl.Exp, 0).Add(clockSkew)):
		return nil, ErrExpired
	case time.Unix(cl.Iat, 0).After(now.Add(clockSkew)):
		return nil, fmt.Errorf("%w: iat in the future", ErrClaims)
	case cl.AuthTime == 0 || time.Unix(cl.AuthTime, 0).After(now.Add(clockSkew)):
		return nil, fmt.Errorf("%w: auth_time", ErrClaims)
	}

	return &Token{
		UID:         cl.Sub,
		PhoneNumber: cl.PhoneNumber,
		IssuedAt:    time.Unix(cl.Iat, 0),
		ExpiresAt:   time.Unix(cl.Exp, 0),
		AuthTime:    time.Unix(cl.AuthTime, 0),
	}, nil
}

func decodeSegment(seg string, out any) error {
	b, err := base64.RawURLEncoding.DecodeString(seg)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, out)
}

// httpKeySource fetches and caches Google's securetoken certificates.
type httpKeySource struct {
	url  string
	http *http.Client

	mu      sync.Mutex
	keys    map[string]*rsa.PublicKey
	expires time.Time
}

var maxAgeRe = regexp.MustCompile(`max-age=(\d+)`)

func (s *httpKeySource) Keys(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.keys != nil && time.Now().Before(s.expires) {
		return s.keys, nil
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, s.url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := s.http.Do(req)
	if err != nil {
		if s.keys != nil {
			return s.keys, nil // serve stale keys through a transient outage
		}
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		if s.keys != nil {
			return s.keys, nil
		}
		return nil, fmt.Errorf("certs endpoint returned %d", resp.StatusCode)
	}

	keys, err := ParseCertificates(body)
	if err != nil {
		return nil, err
	}
	ttl := time.Hour
	if m := maxAgeRe.FindStringSubmatch(resp.Header.Get("Cache-Control")); m != nil {
		if secs, err := strconv.Atoi(m[1]); err == nil && secs > 0 {
			ttl = time.Duration(secs) * time.Second
		}
	}
	s.keys = keys
	s.expires = time.Now().Add(ttl)
	return keys, nil
}

// ParseCertificates decodes the {kid: PEM certificate} JSON Google publishes.
func ParseCertificates(body []byte) (map[string]*rsa.PublicKey, error) {
	var raw map[string]string
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, fmt.Errorf("parse certs: %w", err)
	}
	out := make(map[string]*rsa.PublicKey, len(raw))
	for kid, certPEM := range raw {
		block, _ := pem.Decode([]byte(certPEM))
		if block == nil {
			continue
		}
		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			continue
		}
		if pub, ok := cert.PublicKey.(*rsa.PublicKey); ok {
			out[kid] = pub
		}
	}
	if len(out) == 0 {
		return nil, errors.New("parse certs: no usable RSA certificates")
	}
	return out, nil
}
