package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/mahalflow/backend-go/internal/agent"
	"github.com/mahalflow/backend-go/internal/agent/memory"
	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
	"github.com/mahalflow/backend-go/internal/gateway/whatsapp"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/mahalflow/backend-go/internal/service"
	"github.com/rs/zerolog/log"
)

func main() {
	cfg := config.Load()
	isDev := cfg.Environment != "production"
	logger.InitLogger("mahalflow-agent-worker", isDev)

	log.Info().Msg("Starting MahalFlow Autonomous Agent Worker Daemon")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	eventBus := agent.NewEventBus()

	// The worker degrades rather than fails: if MongoDB is unreachable it runs
	// with no agents, exactly as it behaved before agents were wired up.
	agents := []agent.Agent{}

	mongoDB, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Error().Err(err).Msg("MongoDB unavailable — worker starting with no agents registered")
	} else {
		defer func() {
			shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer shutdownCancel()
			_ = mongoDB.Client.Disconnect(shutdownCtx)
		}()

		memberRepo := repository.NewMemberRepository(mongoDB.DB)
		mahalRepo := repository.NewMahalRepository(mongoDB.DB)
		notifRepo := repository.NewNotificationRepository(mongoDB.DB)
		memoryStore := memory.NewMemoryStore(mongoDB.DB)

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

		notifier := service.NewNotificationService(waClient, notifRepo, service.NotificationTemplates{
			DuesReminder: cfg.WhatsAppTemplateDues,
			Receipt:      cfg.WhatsAppTemplateReceipt,
		})

		if notifier.Enabled() {
			service.SubscribeDunningNotifications(eventBus, notifier)
			log.Info().Msg("Dues reminders will be delivered over WhatsApp")
		} else {
			log.Warn().Msg("WhatsApp not configured — dunning reminders will be computed and logged but not delivered")
		}

		agents = append(agents, agent.NewDunningAgent(memberRepo, mahalRepo, memoryStore, eventBus))
	}

	orchestrator := agent.NewOrchestrator(agents...)
	orchestrator.Start(ctx)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	<-sigChan
	log.Info().Msg("Received termination signal, shutting down Agent Workers...")
	cancel()
	time.Sleep(1 * time.Second)
	log.Info().Msg("Agent Worker Daemon terminated successfully")
}
