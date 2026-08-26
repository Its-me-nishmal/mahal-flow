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

	log.Info().Str("version", AppVersion).Msg("Starting MahalFlow API Server")

	// 1. Connect MongoDB
	dbClient, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Warn().Err(err).Msg("MongoDB connection pending or offline, running in mock fallback mode")
	}

	// 2. Initialize Repositories & Services
	var mahalRepo repository.MahalRepository
	var memberRepo repository.MemberRepository
	var txnRepo repository.TransactionRepository
	var receiptRepo repository.ReceiptRepository
	var paymentService service.PaymentService

	if dbClient != nil {
		mahalRepo = repository.NewMahalRepository(dbClient.DB)
		memberRepo = repository.NewMemberRepository(dbClient.DB)
		txnRepo = repository.NewTransactionRepository(dbClient.DB)
		receiptRepo = repository.NewReceiptRepository(dbClient.DB)
		paymentService = service.NewPaymentService(dbClient.Client, mahalRepo, memberRepo, txnRepo, receiptRepo)
	}

	handler := api.NewHandler(paymentService, mahalRepo, memberRepo, receiptRepo)

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
	app.Post("/api/v1/auth/login", handler.Login)
	app.Post("/api/v1/webhooks/razorpay", handler.HandleRazorpayWebhook)

	// Tenant-Scoped API Routes (v1)
	v1 := app.Group("/api/v1", api.TenantExtractionMiddleware())

	// Auth & Profile
	v1.Get("/auth/me", handler.GetCurrentUser)
	v1.Get("/members/profile/:id", handler.GetMemberProfile)
	v1.Put("/members/profile/:id", handler.UpdateMemberProfile)

	// Member Routes
	v1.Get("/member/dashboard", handler.GetMemberDashboard)
	v1.Post("/payments/dues/initialize", handler.InitializeDuesPayment)
	v1.Post("/payments/dues/confirm", handler.ConfirmPayment)
	v1.Post("/payments/contribution/initialize", handler.InitializeContribution)
	v1.Get("/receipts/:number", handler.GetReceipt)
	v1.Get("/receipts/:number/verify", handler.VerifyReceiptIntegrity)

	// AutoPay Mandates
	v1.Post("/autopay/mandate/create", handler.CreateAutoPayMandate)
	v1.Get("/autopay/mandate/status", handler.GetAutoPayStatus)

	// Admin Routes (Supports standard GET & Structured Query Engine)
	v1.Get("/admin/dashboard", handler.GetAdminDashboard)
	v1.Get("/admin/members", handler.GetAdminMembers)
	v1.Post("/admin/members/query", handler.QueryAdminMembers) // RFC 10008 Query Engine
	v1.Get("/admin/reports/financial", handler.GetFinancialReports)
	v1.Post("/admin/reports/financial/query", handler.QueryFinancialReports) // RFC 10008 Query Engine
	v1.Get("/admin/gateways", handler.GetGateways)
	v1.Get("/admin/audit-logs", handler.GetAuditLogs)
	v1.Get("/admin/alerts", handler.GetAlerts)
	v1.Post("/admin/excel/upload-preview", handler.UploadExcelPreview)
	v1.Post("/admin/excel/commit-import", handler.CommitExcelImport)

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
