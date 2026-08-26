package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/mahalflow/backend-go/internal/agent"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/rs/zerolog/log"
)

func main() {
	isDev := os.Getenv("ENV") != "production"
	logger.InitLogger("mahalflow-agent-worker", isDev)

	log.Info().Msg("Starting MahalFlow Autonomous Agent Worker Daemon")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Initializing Orchestrator
	orchestrator := agent.NewOrchestrator()
	orchestrator.Start(ctx)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	<-sigChan
	log.Info().Msg("Received termination signal, shutting down Agent Workers...")
	cancel()
	time.Sleep(1 * time.Second)
	log.Info().Msg("Agent Worker Daemon terminated successfully")
}
