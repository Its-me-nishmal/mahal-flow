package main

import (
	"context"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mahalflow/backend-go/internal/api"
	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/fcm"
	"github.com/mahalflow/backend-go/internal/gateway/firebaseauth"
	"github.com/mahalflow/backend-go/internal/gateway/pg"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/mahalflow/backend-go/internal/service"
	"github.com/rs/zerolog/log"
)

const AppVersion = "1.0.0"

func main() {
	cfg := config.Load()
	logger.InitLogger("mahalflow-api", cfg.Environment != "production")

	log.Info().Str("version", AppVersion).Msg("Starting MahalFlow Live API Server")

	// 1. Connect MongoDB
	dbClient, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Warn().Err(err).Msg("MongoDB connection pending or offline")
	}

	// 2. Initialize Repositories & Services
	var mahalRepo repository.MahalRepository
	var memberRepo repository.MemberRepository
	var txnRepo repository.TransactionRepository
	var receiptRepo repository.ReceiptRepository
	var auditRepo repository.AuditLogRepository
	var alertRepo repository.AlertRepository
	var refundRepo repository.RefundRepository
	var mandateRepo repository.MandateRepository
	var adminRepo repository.AdminRepository
	var notifRepo repository.NotificationRepository
	var deviceTokenRepo repository.DeviceTokenRepository
	var importRepo repository.ImportBatchRepository
	var paymentService service.PaymentService

	if dbClient != nil {
		mahalRepo = repository.NewMahalRepository(dbClient.DB)
		memberRepo = repository.NewMemberRepository(dbClient.DB)
		txnRepo = repository.NewTransactionRepository(dbClient.DB)
		receiptRepo = repository.NewReceiptRepository(dbClient.DB)
		auditRepo = repository.NewAuditLogRepository(dbClient.DB)
		alertRepo = repository.NewAlertRepository(dbClient.DB)
		refundRepo = repository.NewRefundRepository(dbClient.DB)
		mandateRepo = repository.NewMandateRepository(dbClient.DB)
		adminRepo = repository.NewAdminRepository(dbClient.DB)
		notifRepo = repository.NewNotificationRepository(dbClient.DB)
		deviceTokenRepo = repository.NewDeviceTokenRepository(dbClient.DB)
		importRepo = repository.NewImportBatchRepository(dbClient.DB)
		idxCtx, idxCancel := context.WithTimeout(context.Background(), 10*time.Second)
		if err := importRepo.EnsureIndexes(idxCtx); err != nil {
			log.Warn().Err(err).Msg("import_batches indexes not ensured")
		}
		idxCancel()
		paymentService = service.NewPaymentService(dbClient.Client, mahalRepo, memberRepo, txnRepo, receiptRepo)
	}

	// WhatsApp is optional: an unconfigured client reports disabled and every
	// send becomes a no-op, so the API behaves exactly as before until
	// credentials are present in the environment.
	waClient := whatsapp.NewClient(whatsapp.Config{
		BaseURL:       cfg.WhatsAppAPIURL,
		APIVersion:    cfg.WhatsAppAPIVersion,
		PhoneNumberID: cfg.WhatsAppPhoneNumberID,
		WABAID:        cfg.WhatsAppBusinessAccountID,
		AccessToken:   cfg.WhatsAppAccessToken,
		AppSecret:     cfg.WhatsAppAppSecret,
		DryRun:        cfg.WhatsAppDryRun,
	})
	log.Info().Str("whatsapp", waClient.Status()).Msg("WhatsApp gateway initialized")

	// FCM push is optional in the same way: without a service account the
	// client is disabled and every push is a no-op.
	fcmClient, fcmErr := fcm.NewClient(fcm.Config{
		ServiceAccountFile: cfg.FCMServiceAccountFile,
		ServiceAccountJSON: cfg.FCMServiceAccountJSON,
		DryRun:             cfg.FCMDryRun,
	})
	if fcmErr != nil {
		log.Warn().Err(fcmErr).Msg("FCM service account unusable; push disabled")
	}
	log.Info().Str("fcm", fcmClient.Status()).Msg("FCM push gateway initialized")
	pushService := service.NewPushService(fcmClient, deviceTokenRepo)

	// Post-commit receipt side effects (WhatsApp, push). The payment service
	// takes a single hook, so each channel registers here and one hook fans out.
	var receiptHooks []func(ctx context.Context, receipt *domain.Receipt)
	// In-app PAYMENT_RECEIVED notice for the payer. The handler is built
	// below; the hook only runs after a payment, long after startup.
	var handler *api.Handler
	if alertRepo != nil {
		receiptHooks = append(receiptHooks, func(ctx context.Context, receipt *domain.Receipt) {
			if handler != nil {
				handler.NotifyReceiptAlert(ctx, receipt)
			}
		})
	}
	if pushService.Enabled() {
		receiptHooks = append(receiptHooks, pushService.NotifyReceipt)
		log.Info().Msg("Payment receipts will be pushed to the member app")
	}

	// Deliver a receipt over WhatsApp once a payment is durably committed.
	// The hook runs detached from the request and its failure cannot affect
	// the ledger or the caller's response.
	if paymentService != nil && notifRepo != nil {
		notifier := service.NewNotificationService(waClient, notifRepo, service.NotificationTemplates{
			DuesReminder: cfg.WhatsAppTemplateDues,
			Receipt:      cfg.WhatsAppTemplateReceipt,
		})
		if notifier.Enabled() {
			receiptHooks = append(receiptHooks, func(ctx context.Context, receipt *domain.Receipt) {
				member, err := memberRepo.GetByID(ctx, receipt.MahalID, receipt.MemberID)
				if err != nil || member == nil {
					log.Warn().Err(err).Str("member_id", receipt.MemberID).
						Msg("Could not load member for receipt notification")
					return
				}

				language := ""
				if mahal, mErr := mahalRepo.GetByID(ctx, receipt.MahalID); mErr == nil && mahal != nil {
					if len(mahal.Settings.PreferredLanguages) > 0 {
						language = mahal.Settings.PreferredLanguages[0]
					}
				}

				notifier.SendReceipt(ctx, receipt, member.Phone, language)
			})
			log.Info().Msg("Payment receipts will be delivered over WhatsApp")
		}
	}
	if paymentService != nil && len(receiptHooks) > 0 {
		paymentService.SetReceiptIssuedHook(func(receipt *domain.Receipt) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			for _, hook := range receiptHooks {
				hook(ctx, receipt)
			}
		})
	}

	pgClient := pg.NewClient(pg.Config{
		BaseURL:      cfg.PGAPIURL,
		APIKey:       cfg.PGAPIKey,
		Salt:         cfg.PGSalt,
		ClientID:     cfg.PGClientID,
		ClientSecret: cfg.PGClientSecret,
		ReturnURL:    cfg.PGReturnURL,
		TestMode:     cfg.PaymentTestMode,
		InfoBaseURL:  cfg.PGInfoAPIURL,
	})

	handler = api.NewHandler(paymentService, mahalRepo, memberRepo, receiptRepo, txnRepo, auditRepo, alertRepo, refundRepo, mandateRepo, adminRepo, pgClient)
	handler.SetPush(deviceTokenRepo, pushService)
	handler.SetImportBatches(importRepo)
	handler.SetPublicBaseURL(cfg.PublicBaseURL)

	// Phone sign-in: /auth/resolve and /auth/register accept only a verified
	// Firebase ID token. The project comes from FIREBASE_PROJECT_ID or the
	// FCM service account. Without either, those routes refuse everything
	// unless AUTH_DEV_BYPASS=true (never honoured in production).
	firebaseProject := cfg.FirebaseProjectID
	if firebaseProject == "" {
		firebaseProject = fcmClient.ProjectID()
	}
	devBypass := cfg.AuthDevBypass
	if devBypass && isProduction(cfg.Environment) {
		log.Error().Msg("AUTH_DEV_BYPASS ignored: not allowed when ENV=production")
		devBypass = false
	}
	if firebaseProject != "" {
		verifier, vErr := firebaseauth.NewVerifier(firebaseProject, nil)
		if vErr != nil {
			log.Fatal().Err(vErr).Msg("Firebase ID-token verifier")
		}
		handler.SetPhoneAuth(verifier, devBypass)
		log.Info().Str("project", firebaseProject).Bool("dev_bypass", devBypass).Msg("Phone sign-in verifies Firebase ID tokens")
	} else {
		handler.SetPhoneAuth(nil, devBypass)
		if devBypass {
			log.Warn().Msg("AUTH_DEV_BYPASS=true and no Firebase project: phone sign-in trusts posted phones (development only)")
		} else {
			log.Warn().Msg("No Firebase project configured: /auth/resolve and /auth/register are disabled")
		}
	}

	// AutoPay scheduler: automatically charges due mandates on a fixed interval
	// (no manual trigger). Defaults to every 3 minutes; set AUTOPAY_INTERVAL_SECONDS=0
	// to disable. WARNING: this debits real money on ACTIVE mandates.
	autoPayInterval := 180 * time.Second
	if v := os.Getenv("AUTOPAY_INTERVAL_SECONDS"); v != "" {
		if secs, err := strconv.Atoi(v); err == nil {
			autoPayInterval = time.Duration(secs) * time.Second
		}
	}
	if autoPayInterval > 0 {
		schedulerCtx, cancelScheduler := context.WithCancel(context.Background())
		defer cancelScheduler()
		go handler.StartAutoPayScheduler(schedulerCtx, autoPayInterval)
		log.Info().Dur("interval", autoPayInterval).Msg("AutoPay scheduler started")
	}

	// 3. Initialize Fiber App
	app := fiber.New(fiber.Config{
		AppName:      "MahalFlow Core API v" + AppVersion,
		ServerHeader: "MahalFlow-Fintech-Engine",
	})

	app.Use(recover.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,PATCH,HEAD,OPTIONS",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization, X-Tenant-ID, X-Correlation-ID, X-Idempotency-Key, X-HTTP-Method-Override",
	}))
	app.Use(api.CorrelationIDMiddleware())
	app.Use(api.GlobalRateLimiterMiddleware())

	// Public Health Route
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":      "healthy",
			"version":     AppVersion,
			"database":    "connected",
			"environment": cfg.Environment,
			"timestamp":   time.Now().UTC(),
		})
	})

	// Public Auth & Webhooks
	app.Post("/api/v1/auth/login", api.StrictAuthRateLimiterMiddleware(), handler.Login)
	app.Post("/api/v1/webhooks/razorpay", handler.HandleRazorpayWebhook)
	app.Post("/api/v1/webhooks/pg", handler.HandlePGWebhook)
	app.Get("/api/v1/webhooks/pg", handler.HandlePGWebhook)

	// Public PayU checkout redirect page (opened in a browser/webview, so it
	// cannot carry the app's bearer token).
	app.Get("/api/v1/payments/payu-checkout/:orderId", handler.RenderPayUCheckoutPage)

	// WhatsApp Cloud API callbacks: GET is Meta's subscription handshake,
	// POST carries delivery receipts and inbound member replies.
	whatsappHandler := api.NewWhatsAppHandler(waClient, notifRepo, cfg.WhatsAppWebhookVerifyToken)
	app.Get("/api/v1/webhooks/whatsapp", whatsappHandler.VerifyWebhook)
	app.Post("/api/v1/webhooks/whatsapp", whatsappHandler.HandleWebhook)

	// Tenant-Scoped API Routes (v1) - Requires valid X-Tenant-ID
	v1 := app.Group("/api/v1", api.TenantExtractionMiddleware())
	api.RegisterTenantRoutes(v1, handler)

	// Graceful shutdown setup
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		if err := app.Listen(":" + cfg.Port); err != nil {
			log.Fatal().Err(err).Msg("Failed to start HTTP server")
		}
	}()

	log.Info().Str("port", cfg.Port).Msg("MahalFlow API server listening")
	<-sigChan
	log.Info().Msg("Shutting down API server gracefully...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = app.ShutdownWithContext(ctx)
}

func isProduction(env string) bool {
	e := strings.ToLower(strings.TrimSpace(env))
	return e == "production" || e == "prod"
}
