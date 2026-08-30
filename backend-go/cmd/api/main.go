package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mahalflow/backend-go/internal/api"
	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
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
	var paymentService service.PaymentService

	if dbClient != nil {
		mahalRepo = repository.NewMahalRepository(dbClient.DB)
		memberRepo = repository.NewMemberRepository(dbClient.DB)
		txnRepo = repository.NewTransactionRepository(dbClient.DB)
		receiptRepo = repository.NewReceiptRepository(dbClient.DB)
		auditRepo = repository.NewAuditLogRepository(dbClient.DB)
		alertRepo = repository.NewAlertRepository(dbClient.DB)
		refundRepo = repository.NewRefundRepository(dbClient.DB)
		paymentService = service.NewPaymentService(dbClient.Client, mahalRepo, memberRepo, txnRepo, receiptRepo)
	}

	handler := api.NewHandler(paymentService, mahalRepo, memberRepo, receiptRepo, txnRepo, auditRepo, alertRepo, refundRepo)

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
	v1.Post("/payments/contribution/initialize", handler.InitializeContribution)
	v1.Get("/receipts/:number", handler.GetReceipt)
	v1.Get("/receipts/:number/verify", handler.VerifyReceiptIntegrity)

	// AutoPay Mandates
	v1.Post("/autopay/mandate/create", handler.CreateAutoPayMandate)
	v1.Get("/autopay/mandate/status", handler.GetAutoPayStatus)

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
