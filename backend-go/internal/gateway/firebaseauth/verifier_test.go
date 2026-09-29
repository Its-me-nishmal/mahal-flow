package firebaseauth

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"testing"
	"time"
)

type staticKeys map[string]*rsa.PublicKey

func (s staticKeys) Keys(context.Context) (map[string]*rsa.PublicKey, error) { return s, nil }

func mint(t *testing.T, key *rsa.PrivateKey, kid string, cl map[string]any) string {
	t.Helper()
	h, _ := json.Marshal(map[string]string{"alg": "RS256", "kid": kid, "typ": "JWT"})
	c, _ := json.Marshal(cl)
	unsigned := base64.RawURLEncoding.EncodeToString(h) + "." + base64.RawURLEncoding.EncodeToString(c)
	digest := sha256.Sum256([]byte(unsigned))
	sig, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, digest[:])
	if err != nil {
		t.Fatal(err)
	}
	return unsigned + "." + base64.RawURLEncoding.EncodeToString(sig)
}

func validClaims(project string) map[string]any {
	now := time.Now()
	return map[string]any{
		"aud":          project,
		"iss":          "https://securetoken.google.com/" + project,
		"sub":          "uid-123",
		"iat":          now.Add(-time.Minute).Unix(),
		"exp":          now.Add(time.Hour).Unix(),
		"auth_time":    now.Add(-time.Minute).Unix(),
		"phone_number": "+919847111222",
	}
}

func TestVerifyIDToken(t *testing.T) {
	key, _ := rsa.GenerateKey(rand.Reader, 2048)
	other, _ := rsa.GenerateKey(rand.Reader, 2048)
	v := NewVerifierWithKeys("mahalflow-test", staticKeys{"k1": &key.PublicKey})
	ctx := context.Background()

	tok, err := v.VerifyIDToken(ctx, mint(t, key, "k1", validClaims("mahalflow-test")))
	if err != nil {
		t.Fatalf("valid token rejected: %v", err)
	}
	if tok.PhoneNumber != "+919847111222" || tok.UID != "uid-123" {
		t.Fatalf("claims not carried: %+v", tok)
	}

	cases := map[string]struct {
		token string
		want  error
	}{
		"garbage":       {"not.a.token", ErrMalformed},
		"wrong signer":  {mint(t, other, "k1", validClaims("mahalflow-test")), ErrSignature},
		"unknown kid":   {mint(t, key, "k9", validClaims("mahalflow-test")), ErrSignature},
		"other project": {mint(t, key, "k1", validClaims("someone-else")), ErrClaims},
		"expired":       {mint(t, key, "k1", with(validClaims("mahalflow-test"), "exp", time.Now().Add(-time.Hour).Unix())), ErrExpired},
		"future iat":    {mint(t, key, "k1", with(validClaims("mahalflow-test"), "iat", time.Now().Add(time.Hour).Unix())), ErrClaims},
		"no sub":        {mint(t, key, "k1", with(validClaims("mahalflow-test"), "sub", "")), ErrClaims},
		"no auth_time":  {mint(t, key, "k1", with(validClaims("mahalflow-test"), "auth_time", 0)), ErrClaims},
		"wrong issuer":  {mint(t, key, "k1", with(validClaims("mahalflow-test"), "iss", "https://evil.example")), ErrClaims},
	}
	for name, tc := range cases {
		if _, err := v.VerifyIDToken(ctx, tc.token); !errors.Is(err, tc.want) {
			t.Errorf("%s: got %v, want %v", name, err, tc.want)
		}
	}
}

func with(m map[string]any, k string, v any) map[string]any {
	m[k] = v
	return m
}
