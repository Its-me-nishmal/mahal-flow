package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/rs/zerolog/log"
)

const AppVersion = "1.0.0-alpha.1"

func main() {
	isDev := os.Getenv("ENV") != "production"
	logger.InitLogger("mahalflow-api", isDev)

	log.Info().Str("version", AppVersion).Msg("Starting MahalFlow API Server")

	app := fiber.New(fiber.Config{
		AppName:      "MahalFlow Core API v" + AppVersion,
		ServerHeader: "MahalFlow-Fintech-Engine",
	})

	app.Use(recover.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization, X-Tenant-ID, X-Correlation-ID, X-Idempotency-Key",
	}))

	// Health Check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"version": AppVersion,
		})
	})

	// Graceful shutdown setup
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	go func() {
		if err := app.Listen(":" + port); err != nil {
			log.Fatal().Err(err).Msg("Failed to start HTTP server")
		}
	}()

	log.Info().Str("port", port).Msg("MahalFlow API server listening")
	<-sigChan
	log.Info().Msg("Shutting down API server gracefully...")
	_ = app.Shutdown()
}
