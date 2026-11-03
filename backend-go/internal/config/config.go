package config

import (
	"os"
	"strings"

	_ "github.com/joho/godotenv/autoload"
)

type Config struct {
	Port        string
	MongoURI    string
	DBName      string
	JWTSecret   string
	RedisAddr   string
	Environment string
	// PaymentTestMode simulates the payment gateway: confirmations succeed
	// without money moving. Default OFF; forced OFF unless ENV is explicitly a
	// development value (see ResolveSafety).
	PaymentTestMode bool
	// AllowStandaloneCommit lets the payment service fall back to non-atomic
	// writes on a MongoDB without replica-set transactions. Development only.
	AllowStandaloneCommit bool
	// CORSOrigins is the comma-separated browser origin allowlist (CORS_ORIGINS).
	// Empty = no CORS headers at all (same-origin only).
	CORSOrigins string
	// SafetyWarnings are loud startup messages produced while resolving unsafe
	// settings; main logs them at error level.
	SafetyWarnings []string

	// Payment Gateway (PayU)
	PGAPIURL       string
	PGAPIKey       string
	PGSalt         string
	PGClientID     string
	PGClientSecret string
	PGReturnURL    string
	// PGInfoAPIURL is PayU's Merchant Web Service host (postservice:
	// verify_payment, refunds, SI). Empty = derived from PG_API_URL
	// (test.payu.in for the sandbox, info.payu.in otherwise).
	PGInfoAPIURL string
	// PublicBaseURL is how browsers reach this API (for signed checkout
	// links), e.g. https://api.example.org. Default http://localhost:<PORT>.
	PublicBaseURL string

	// WhatsApp Business Cloud API (Meta)
	WhatsAppAPIURL             string
	WhatsAppAPIVersion         string
	WhatsAppPhoneNumberID      string
	WhatsAppBusinessAccountID  string
	WhatsAppAccessToken        string
	WhatsAppWebhookVerifyToken string
	WhatsAppAppSecret          string
	WhatsAppDryRun             bool
	WhatsAppTemplateDues       string
	WhatsAppTemplateReceipt    string

	// Firebase Cloud Messaging (push). Service account from the Firebase
	// console → Project settings → Service accounts. Unset = push disabled.
	FCMServiceAccountFile string
	FCMServiceAccountJSON string
	FCMDryRun             bool

	// Firebase Authentication. /auth/resolve and /auth/register verify the
	// app's Firebase ID token against this project. Defaults to the FCM
	// service account's project_id when unset.
	FirebaseProjectID string
	// AuthDevBypass lets /auth/resolve and /auth/register trust a posted
	// phone when no ID token is sent. Local development only; refused when
	// ENV=production.
	AuthDevBypass bool
}

func Load() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "mahalflow"
	}

	// JWT_SECRET has no default: api.InitJWT refuses to start without one.
	jwtSecret := os.Getenv("JWT_SECRET")

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "development"
	}

	rawEnv := os.Getenv("ENV")
	paymentTestMode, allowStandalone, warnings := ResolveSafety(rawEnv,
		os.Getenv("PAYMENT_TEST_MODE"), os.Getenv("ALLOW_STANDALONE_COMMIT"))

	pgAPIURL := os.Getenv("PG_API_URL")
	pgAPIKey := os.Getenv("PG_API_KEY")
	pgSalt := os.Getenv("PG_SALT")
	pgClientID := os.Getenv("PG_CLIENT_ID")
	pgClientSecret := os.Getenv("PG_CLIENT_SECRET")
	pgReturnURL := os.Getenv("PG_RETURN_URL")
	if pgReturnURL == "" {
		pgReturnURL = "http://localhost:8080/api/v1/webhooks/pg"
	}

	waAPIURL := os.Getenv("WHATSAPP_API_URL")
	if waAPIURL == "" {
		waAPIURL = "https://graph.facebook.com"
	}

	waAPIVersion := os.Getenv("WHATSAPP_API_VERSION")
	if waAPIVersion == "" {
		waAPIVersion = "v21.0"
	}

	waDryRunEnv := os.Getenv("WHATSAPP_DRY_RUN")
	waDryRun := waDryRunEnv == "true" || waDryRunEnv == "1" || waDryRunEnv == "ON"

	return &Config{
		Port:                  port,
		MongoURI:              mongoURI,
		DBName:                dbName,
		JWTSecret:             jwtSecret,
		RedisAddr:             redisAddr,
		Environment:           env,
		PaymentTestMode:       paymentTestMode,
		AllowStandaloneCommit: allowStandalone,
		CORSOrigins:           CORSAllowOrigins(rawEnv, os.Getenv("CORS_ORIGINS")),
		SafetyWarnings:        warnings,
		PGAPIURL:              pgAPIURL,
		PGAPIKey:              pgAPIKey,
		PGSalt:                pgSalt,
		PGClientID:            pgClientID,
		PGClientSecret:        pgClientSecret,
		PGReturnURL:           pgReturnURL,
		PGInfoAPIURL:          os.Getenv("PG_INFO_API_URL"),
		PublicBaseURL:         publicBaseURL(port),

		WhatsAppAPIURL:             waAPIURL,
		WhatsAppAPIVersion:         waAPIVersion,
		WhatsAppPhoneNumberID:      os.Getenv("WHATSAPP_PHONE_NUMBER_ID"),
		WhatsAppBusinessAccountID:  os.Getenv("WHATSAPP_BUSINESS_ACCOUNT_ID"),
		WhatsAppAccessToken:        os.Getenv("WHATSAPP_ACCESS_TOKEN"),
		WhatsAppWebhookVerifyToken: os.Getenv("WHATSAPP_WEBHOOK_VERIFY_TOKEN"),
		WhatsAppAppSecret:          os.Getenv("WHATSAPP_APP_SECRET"),
		WhatsAppDryRun:             waDryRun,
		WhatsAppTemplateDues:       os.Getenv("WHATSAPP_TEMPLATE_DUES_REMINDER"),
		WhatsAppTemplateReceipt:    os.Getenv("WHATSAPP_TEMPLATE_RECEIPT"),

		FCMServiceAccountFile: os.Getenv("FCM_SERVICE_ACCOUNT_FILE"),
		FCMServiceAccountJSON: os.Getenv("FCM_SERVICE_ACCOUNT_JSON"),
		FCMDryRun:             os.Getenv("FCM_DRY_RUN") == "true",

		FirebaseProjectID: os.Getenv("FIREBASE_PROJECT_ID"),
		AuthDevBypass:     os.Getenv("AUTH_DEV_BYPASS") == "true",
	}
}

func publicBaseURL(port string) string {
	if v := os.Getenv("PUBLIC_BASE_URL"); v != "" {
		return v
	}
	return "http://localhost:" + port
}

// IsDevEnv reports whether env is an explicit development value. An unset or
// misspelled ENV is NOT development: unsafe conveniences stay off.
func IsDevEnv(env string) bool {
	switch strings.ToLower(strings.TrimSpace(env)) {
	case "development", "dev", "local", "test":
		return true
	}
	return false
}

func isOn(v string) bool {
	switch strings.ToLower(strings.TrimSpace(v)) {
	case "on", "true", "1", "yes":
		return true
	}
	return false
}

// ResolveSafety decides the two fail-open switches from raw env values.
//
//   - PAYMENT_TEST_MODE defaults OFF when unset. If it is ON while ENV is not
//     an explicit development value it is forced OFF and a warning is
//     returned (the process keeps running, but no free receipts).
//   - ALLOW_STANDALONE_COMMIT is honoured only in explicit development.
func ResolveSafety(rawEnv, paymentTestMode, standaloneCommit string) (testMode, standalone bool, warnings []string) {
	dev := IsDevEnv(rawEnv)
	testMode = isOn(paymentTestMode)
	if testMode && !dev {
		testMode = false
		warnings = append(warnings,
			"PAYMENT_TEST_MODE=ON ignored: ENV is not an explicit development value ("+
				"set ENV=development for local work). The payment gateway is NOT simulated; "+
				"fix the environment variable.")
	}
	standalone = isOn(standaloneCommit)
	if standalone && !dev {
		standalone = false
		warnings = append(warnings, "ALLOW_STANDALONE_COMMIT ignored: only honoured when ENV is an explicit development value.")
	}
	return testMode, standalone, warnings
}

// CORSAllowOrigins resolves the CORS allowlist. CORS_ORIGINS wins; without it
// explicit development gets the usual localhost dev servers and everything
// else gets none (no CORS headers). Never "*".
func CORSAllowOrigins(rawEnv, corsOrigins string) string {
	var out []string
	for _, o := range strings.Split(corsOrigins, ",") {
		o = strings.TrimSpace(o)
		if o != "" && o != "*" {
			out = append(out, o)
		}
	}
	if len(out) > 0 {
		return strings.Join(out, ",")
	}
	if IsDevEnv(rawEnv) {
		return "http://localhost:3000,http://localhost:5173,http://127.0.0.1:3000,http://127.0.0.1:5173"
	}
	return ""
}
