package api

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"
)

var (
	ErrInvalidToken = errors.New("invalid token signature or format")
	ErrExpiredToken = errors.New("token has expired")
)

type JWTClaims struct {
	Issuer    string `json:"iss"`
	Audience  string `json:"aud"`
	Subject   string `json:"sub"`
	Phone     string `json:"phone"`
	Role      string `json:"role"`
	MahalID   string `json:"mahal_id"`
	IssuedAt  int64  `json:"iat"`
	ExpiresAt int64  `json:"exp"`
}

const (
	jwtIssuer   = "mahalflow-core"
	jwtAudience = "mahalflow-clients"
	// minJWTSecretLen is the minimum HS256 key length accepted in every
	// environment.
	minJWTSecretLen = 32
)

var (
	jwtSecretOnce sync.Once
	jwtSecretKey  []byte
	jwtSecretErr  error
)

// resolveJWTSecret picks the signing key from raw env values. There is no
// public default: an empty JWT_SECRET is an error, whatever ENV says. The one
// escape hatch is ENV exactly "development" together with AUTH_DEV_BYPASS=true,
// which yields a random per-process key (tokens do not survive a restart and
// nobody can forge one).
func resolveJWTSecret(secret, env, devBypass string) ([]byte, error) {
	if secret == "" {
		if strings.ToLower(strings.TrimSpace(env)) == "development" && devBypass == "true" {
			key := make([]byte, 32)
			if _, err := rand.Read(key); err != nil {
				return nil, err
			}
			return key, nil
		}
		return nil, errors.New("JWT_SECRET is required (set a random value of at least 32 characters)")
	}
	if len(secret) < minJWTSecretLen {
		return nil, fmt.Errorf("JWT_SECRET must be at least %d characters", minJWTSecretLen)
	}
	return []byte(secret), nil
}

// InitJWT loads the signing key once. Call it at startup and treat an error as
// fatal; GenerateJWT/ValidateJWT also use it lazily so the key is read from
// the environment exactly once per process.
func InitJWT() error {
	_, err := getJWTSecret()
	return err
}

func getJWTSecret() ([]byte, error) {
	jwtSecretOnce.Do(func() {
		jwtSecretKey, jwtSecretErr = resolveJWTSecret(
			os.Getenv("JWT_SECRET"), os.Getenv("ENV"), os.Getenv("AUTH_DEV_BYPASS"))
	})
	return jwtSecretKey, jwtSecretErr
}

func GenerateJWT(userID, phone, role, mahalID string, duration time.Duration) (string, error) {
	secret, err := getJWTSecret()
	if err != nil {
		return "", err
	}

	headerJSON, _ := json.Marshal(map[string]string{
		"alg": "HS256",
		"typ": "JWT",
	})
	headerEncoded := base64.RawURLEncoding.EncodeToString(headerJSON)

	now := time.Now().UTC()
	claims := JWTClaims{
		Issuer:    jwtIssuer,
		Audience:  jwtAudience,
		Subject:   userID,
		Phone:     phone,
		Role:      role,
		MahalID:   mahalID,
		IssuedAt:  now.Unix(),
		ExpiresAt: now.Add(duration).Unix(),
	}

	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	claimsEncoded := base64.RawURLEncoding.EncodeToString(claimsJSON)

	unsignedToken := fmt.Sprintf("%s.%s", headerEncoded, claimsEncoded)

	mac := hmac.New(sha256.New, secret)
	mac.Write([]byte(unsignedToken))
	signature := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))

	return fmt.Sprintf("%s.%s", unsignedToken, signature), nil
}

func ValidateJWT(tokenStr string) (*JWTClaims, error) {
	secret, err := getJWTSecret()
	if err != nil {
		return nil, err
	}

	parts := strings.Split(tokenStr, ".")
	if len(parts) != 3 {
		return nil, ErrInvalidToken
	}

	unsignedToken := parts[0] + "." + parts[1]
	mac := hmac.New(sha256.New, secret)
	mac.Write([]byte(unsignedToken))
	expectedSignature := mac.Sum(nil)

	actualSignature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(expectedSignature, actualSignature) {
		return nil, ErrInvalidToken
	}

	claimsBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, ErrInvalidToken
	}

	var claims JWTClaims
	if err := json.Unmarshal(claimsBytes, &claims); err != nil {
		return nil, ErrInvalidToken
	}

	if claims.Issuer != jwtIssuer || claims.Audience != jwtAudience {
		return nil, ErrInvalidToken
	}

	if time.Now().UTC().Unix() > claims.ExpiresAt {
		return nil, ErrExpiredToken
	}

	return &claims, nil
}
