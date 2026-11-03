package api

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestResolveJWTSecret(t *testing.T) {
	long := strings.Repeat("k", 40)
	// No secret is an error whatever ENV says, including unset and misspelled.
	for _, env := range []string{"", "production", "prod", "developmnt", "staging", "development"} {
		if k, err := resolveJWTSecret("", env, ""); err == nil || k != nil {
			t.Errorf("env %q without JWT_SECRET must fail, got key=%v err=%v", env, k, err)
		}
	}
	// AUTH_DEV_BYPASS alone is not enough, and neither is ENV alone.
	if _, err := resolveJWTSecret("", "production", "true"); err == nil {
		t.Error("AUTH_DEV_BYPASS must not rescue a production ENV")
	}
	if _, err := resolveJWTSecret("", "", "true"); err == nil {
		t.Error("AUTH_DEV_BYPASS must not rescue an unset ENV")
	}
	// Explicit dev opt-in yields a random per-process key, never a public default.
	a, err := resolveJWTSecret("", "development", "true")
	b, err2 := resolveJWTSecret("", "development", "true")
	if err != nil || err2 != nil || len(a) != 32 || string(a) == string(b) {
		t.Fatalf("dev opt-in: a=%x b=%x err=%v/%v", a, b, err, err2)
	}
	if _, err := resolveJWTSecret("short", "development", "true"); err == nil {
		t.Error("short secret must be rejected in every environment")
	}
	if k, err := resolveJWTSecret(long, "production", ""); err != nil || string(k) != long {
		t.Errorf("valid secret: %v", err)
	}
	// The old hardcoded defaults must not be accepted as an implicit key.
	if _, err := resolveJWTSecret("", "", ""); err == nil {
		t.Error("no implicit default secret")
	}
}

func signRaw(t *testing.T, claims map[string]any) string {
	t.Helper()
	key, err := getJWTSecret()
	if err != nil {
		t.Fatal(err)
	}
	h, _ := json.Marshal(map[string]string{"alg": "HS256", "typ": "JWT"})
	c, _ := json.Marshal(claims)
	unsigned := base64.RawURLEncoding.EncodeToString(h) + "." + base64.RawURLEncoding.EncodeToString(c)
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(unsigned))
	return unsigned + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func TestValidateJWTChecksIssuerAndAudience(t *testing.T) {
	exp := time.Now().Add(time.Hour).Unix()
	good := map[string]any{"iss": jwtIssuer, "aud": jwtAudience, "sub": "u", "role": "MEMBER", "mahal_id": "m", "exp": exp}
	if _, err := ValidateJWT(signRaw(t, good)); err != nil {
		t.Fatalf("well-formed token: %v", err)
	}
	for name, mut := range map[string]func(m map[string]any){
		"wrong issuer":   func(m map[string]any) { m["iss"] = "someone-else" },
		"wrong audience": func(m map[string]any) { m["aud"] = "other-service" },
		"no issuer":      func(m map[string]any) { delete(m, "iss") },
		"no audience":    func(m map[string]any) { delete(m, "aud") },
	} {
		c := map[string]any{}
		for k, v := range good {
			c[k] = v
		}
		mut(c)
		if _, err := ValidateJWT(signRaw(t, c)); err != ErrInvalidToken {
			t.Errorf("%s: want ErrInvalidToken, got %v", name, err)
		}
	}
	// Signed with a different key.
	tok := signRaw(t, good)
	parts := strings.Split(tok, ".")
	if _, err := ValidateJWT(parts[0] + "." + parts[1] + "." + base64.RawURLEncoding.EncodeToString([]byte("forged"))); err != ErrInvalidToken {
		t.Errorf("forged signature: %v", err)
	}
	// Issued tokens validate and the key is loaded once.
	k1, _ := getJWTSecret()
	k2, _ := getJWTSecret()
	if &k1[0] != &k2[0] {
		t.Error("secret must be loaded once and reused")
	}
}
