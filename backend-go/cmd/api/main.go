package main

import (
	"context"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mahalflow/backend-go/internal/api"
	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
	"github.com/mahalflow/backend-go/internal/domain"
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
	var notifRepo repository.NotificationRepository
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
		notifRepo = repository.NewNotificationRepository(dbClient.DB)
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

	// Deliver a receipt over WhatsApp once a payment is durably committed.
	// The hook runs detached from the request and its failure cannot affect
	// the ledger or the caller's response.
	if paymentService != nil && notifRepo != nil {
		notifier := service.NewNotificationService(waClient, notifRepo, service.NotificationTemplates{
			DuesReminder: cfg.WhatsAppTemplateDues,
			Receipt:      cfg.WhatsAppTemplateReceipt,
		})
		if notifier.Enabled() {
			paymentService.SetReceiptIssuedHook(func(receipt *domain.Receipt) {
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()

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

	pgClient := pg.NewClient(pg.Config{
		BaseURL:      cfg.PGAPIURL,
		APIKey:       cfg.PGAPIKey,
		Salt:         cfg.PGSalt,
		ClientID:     cfg.PGClientID,
		ClientSecret: cfg.PGClientSecret,
		ReturnURL:    cfg.PGReturnURL,
		TestMode:     cfg.PaymentTestMode,
	})

	handler := api.NewHandler(paymentService, mahalRepo, memberRepo, receiptRepo, txnRepo, auditRepo, alertRepo, refundRepo, mandateRepo, pgClient)

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

	// Public PayU Checkout Redirect & JSON Data
	app.Get("/api/v1/payments/payu-checkout/:orderId", handler.RenderPayUCheckoutPage)
	app.Get("/api/v1/payments/payu-checkout-data/:orderId", handler.GetPayUCheckoutData)
	app.Post("/api/v1/payments/payu-generate-hash", handler.GeneratePayUDynamicHash)

	// WhatsApp Cloud API callbacks: GET is Meta's subscription handshake,
	// POST carries delivery receipts and inbound member replies.
	whatsappHandler := api.NewWhatsAppHandler(waClient, notifRepo, cfg.WhatsAppWebhookVerifyToken)
	app.Get("/api/v1/webhooks/whatsapp", whatsappHandler.VerifyWebhook)
	app.Post("/api/v1/webhooks/whatsapp", whatsappHandler.HandleWebhook)

	// Tenant-Scoped API Routes (v1) - Requires valid X-Tenant-ID
	v1 := app.Group("/api/v1", api.TenantExtractionMiddleware())

	// Auth & Profile
	v1.Get("/auth/me", api.JWTAuthMiddleware(), handler.GetCurrentUser)
	v1.Get("/members/profile/:id", handler.GetMemberProfile)
	v1.Put("/members/profile/:id", handler.UpdateMemberProfile)

	// Member Routes (Dues Portal, Contributions & Receipt Verification)
	v1.Get("/member/dashboard", handler.GetMemberDashboard)
	v1.Get("/member/receipts", handler.GetMemberReceipts)
	v1.Post("/payments/dues/initialize", handler.InitializeDuesPayment)
	v1.Post("/payments/dues/confirm", handler.ConfirmPayment)
	v1.Get("/payments/:id/status", handler.VerifyPGPaymentStatus)
	v1.Post("/payments/contribution/initialize", handler.InitializeContribution)
	v1.Get("/receipts/:number", handler.GetReceipt)
	v1.Get("/receipts/:number/verify", handler.VerifyReceiptIntegrity)

	// AutoPay Mandates
	v1.Post("/autopay/mandate/create", handler.CreateAutoPayMandate)
	v1.Get("/autopay/mandate/status", handler.GetAutoPayStatus)
	v1.Post("/autopay/mandate/confirm", handler.ConfirmAutoPayMandate)
	v1.Post("/autopay/mandate/cancel", handler.CancelAutoPayMandate)

	// Alerts for Members & Announcements
	v1.Get("/member/alerts", handler.GetAlerts)
	v1.Get("/alerts", handler.GetAlerts)

	// QR Standee (BharatQR & UPI)
	v1.Get("/mahal/qr-standee", handler.GetMahalQRStandee)
	v1.Post("/mahal/qr-standee/dynamic", handler.GenerateDynamicQR)

	// Protected Admin Routes (Requires valid JWT Token + MAHAL_ADMIN / SUPER_ADMIN Role)
	admin := v1.Group("/admin", api.JWTAuthMiddleware(), api.RequireRole("MAHAL_ADMIN", "SUPER_ADMIN"))
	admin.Get("/dashboard", handler.GetAdminDashboard)
	admin.Get("/mahals", handler.GetMahals)
	admin.Post("/mahals", handler.CreateMahal)
	admin.Get("/mahals/:id", handler.GetMahalByID)
	admin.Get("/members", handler.GetAdminMembers)
	admin.Post("/members", handler.CreateMember)
	admin.Delete("/members/:id", handler.DeleteMember)
	admin.Post("/members/query", handler.QueryAdminMembers)
	admin.Get("/payments", handler.GetPayments)
	admin.Get("/subscriptions", handler.GetSubscriptions)
	admin.Get("/refunds", handler.GetRefunds)
	admin.Post("/refunds/:id/action", handler.ProcessRefund)
	admin.Get("/qr-standee", handler.GetMahalQRStandee)
	admin.Post("/qr-standee/dynamic", handler.GenerateDynamicQR)
	admin.Get("/reports/financial", handler.GetFinancialReports)
	admin.Post("/reports/financial/query", handler.QueryFinancialReports)
	admin.Get("/gateways", handler.GetGateways)
	admin.Get("/audit-logs", handler.GetAuditLogs)
	admin.Get("/alerts", handler.GetAlerts)
	admin.Post("/alerts", handler.CreateAlert)
	admin.Post("/alerts/:id/ack", handler.AcknowledgeAlert)
	admin.Delete("/alerts/:id", handler.DismissAlert)
	admin.Delete("/alerts", handler.ClearAllAlerts)
	admin.Post("/alerts/mark-all-read", handler.MarkAllAlertsRead)
	admin.Post("/excel/upload-preview", handler.UploadExcelPreview)
	admin.Post("/excel/commit-import", handler.CommitExcelImport)
	admin.Post("/autopay/run-due", handler.RunDueAutoPayDebits)

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
