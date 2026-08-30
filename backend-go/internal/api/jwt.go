package api

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"
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

func getJWTSecret() ([]byte, error) {
	secret := os.Getenv("JWT_SECRET")
	env := strings.ToLower(os.Getenv("ENV"))
	if env == "" {
		env = strings.ToLower(os.Getenv("ENVIRONMENT"))
	}

	if env == "production" || env == "prod" {
		if secret == "" {
			log.Fatalf("FATAL SECURITY ERROR: JWT_SECRET environment variable is required in production environment.")
			return nil, errors.New("missing JWT_SECRET in production")
		}
		if len(secret) < 32 {
			log.Fatalf("FATAL SECURITY ERROR: JWT_SECRET must be at least 32 characters (256-bit entropy) in production.")
			return nil, errors.New("insecure JWT_SECRET in production")
		}
		return []byte(secret), nil
	}

	// Safe development default key
	if secret == "" {
		secret = "mahalflow_super_secret_fintech_key_2026_live_hmac256"
	}
	return []byte(secret), nil
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
		Issuer:    "mahalflow-core",
		Audience:  "mahalflow-clients",
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

	if time.Now().UTC().Unix() > claims.ExpiresAt {
		return nil, ErrExpiredToken
	}

	return &claims, nil
}
