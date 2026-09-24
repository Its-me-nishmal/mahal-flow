package config

import (
	"os"

	_ "github.com/joho/godotenv/autoload"
)

type Config struct {
	Port            string
	MongoURI        string
	DBName          string
	JWTSecret       string
	RedisAddr       string
	Environment     string
	PaymentTestMode bool

	// Payment Gateway (PayU)
	PGAPIURL      string
	PGAPIKey      string
	PGSalt        string
	PGClientID    string
	PGClientSecret string
	PGReturnURL   string

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

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "mahalflow_super_secret_jwt_key_change_in_prod"
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "development"
	}

	paymentTestModeEnv := os.Getenv("PAYMENT_TEST_MODE")
	paymentTestMode := paymentTestModeEnv == "ON" || paymentTestModeEnv == "true" || paymentTestModeEnv == "1" || paymentTestModeEnv == ""

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
		Port:            port,
		MongoURI:        mongoURI,
		DBName:          dbName,
		JWTSecret:       jwtSecret,
		RedisAddr:       redisAddr,
		Environment:     env,
		PaymentTestMode: paymentTestMode,
		PGAPIURL:        pgAPIURL,
		PGAPIKey:        pgAPIKey,
		PGSalt:          pgSalt,
		PGClientID:      pgClientID,
		PGClientSecret:  pgClientSecret,
		PGReturnURL:     pgReturnURL,

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
	}
}
