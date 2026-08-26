package main

import (
	"context"
	"fmt"
	"time"

	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/rs/zerolog/log"
	"go.mongodb.org/mongo-driver/v2/bson"
)

func main() {
	cfg := config.Load()
	logger.InitLogger("mahalflow-seeder", true)

	log.Info().Str("uri", cfg.MongoURI).Str("db", cfg.DBName).Msg("Connecting to MongoDB for Seeding...")

	dbClient, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to MongoDB")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	db := dbClient.DB

	// 1. Clean existing collections
	log.Info().Msg("Cleaning existing collections...")
	_ = db.Collection("mahals").Drop(ctx)
	_ = db.Collection("members").Drop(ctx)
	_ = db.Collection("transactions").Drop(ctx)
	_ = db.Collection("receipts").Drop(ctx)
	_ = db.Collection("audit_logs").Drop(ctx)

	// 2. Seed Mahals
	log.Info().Msg("Seeding Mahals...")
	mahals := []domain.Mahal{
		{
			ID:                 "MH_001_CALICUT",
			Name:               "Central Juma Masjid Mahal",
			RegistrationNumber: "REG/KL/2024/0912",
			Contact: domain.MahalContact{
				Email:   "committee@townmasjid.org",
				Phone:   "+919847123456",
				Address: "Main Road, Calicut, Kerala 673001",
			},
			Settings: domain.MahalSettings{
				Currency:           "INR",
				DefaultMonthlyDues: 500.0,
				DunningEnabled:     true,
				PreferredLanguages: []string{"ml", "en"},
				AutoPayAllowed:     true,
			},
			Subscription: domain.MahalSubscription{
				Plan:            "STANDARD_MONTHLY",
				MonthlyFee:      499.0,
				Status:          domain.SubActive,
				NextBillingDate: time.Now().AddDate(0, 1, 0).UTC(),
			},
			CreatedAt: time.Now().AddDate(0, -6, 0).UTC(),
			UpdatedAt: time.Now().UTC(),
		},
		{
			ID:                 "MH_002_KOCHI",
			Name:               "Al-Huda Community Center Mahal",
			RegistrationNumber: "REG/KL/2023/1104",
			Contact: domain.MahalContact{
				Email:   "admin@alhuda-kochi.org",
				Phone:   "+919847654321",
				Address: "MG Road, Kochi, Kerala 682016",
			},
			Settings: domain.MahalSettings{
				Currency:           "INR",
				DefaultMonthlyDues: 600.0,
				DunningEnabled:     true,
				PreferredLanguages: []string{"ml", "en"},
				AutoPayAllowed:     true,
			},
			Subscription: domain.MahalSubscription{
				Plan:            "PREMIUM_MONTHLY",
				MonthlyFee:      799.0,
				Status:          domain.SubGracePeriod,
				NextBillingDate: time.Now().AddDate(0, 0, 3).UTC(),
			},
			CreatedAt: time.Now().AddDate(0, -8, 0).UTC(),
			UpdatedAt: time.Now().UTC(),
		},
	}

	for _, m := range mahals {
		_, err := db.Collection("mahals").InsertOne(ctx, m)
		if err != nil {
			log.Error().Err(err).Str("id", m.ID).Msg("Failed to insert mahal")
		}
	}

	// 3. Seed Members for MH_001_CALICUT
	log.Info().Msg("Seeding Members for MH_001_CALICUT...")
	members := []domain.Member{
		{
			ID:                      "MEM_001_9910",
			MahalID:                 "MH_001_CALICUT",
			MemberCode:              "M-101",
			Name:                    "Muhammed Ameen",
			Phone:                   "+919847111222",
			HouseName:               "Darul Aman",
			FamilyHead:              true,
			FamilyMembersCount:      4,
			MonthlyDuesCustomAmount: 500.0,
			Status:                  "ACTIVE",
			LastPaidMonth:           "2026-05", // 3 months overdue (Jun, Jul, Aug)
			OutstandingBalance:      1500.0,
			Version:                 1,
			CreatedAt:               time.Now().AddDate(0, -5, 0).UTC(),
			UpdatedAt:               time.Now().UTC(),
		},
		{
			ID:                      "MEM_001_9911",
			MahalID:                 "MH_001_CALICUT",
			MemberCode:              "M-102",
			Name:                    "Abdul Rahman",
			Phone:                   "+919847333444",
			HouseName:               "Baitul Noor",
			FamilyHead:              true,
			FamilyMembersCount:      5,
			MonthlyDuesCustomAmount: 500.0,
			Status:                  "ACTIVE",
			LastPaidMonth:           "2026-08", // Fully up to date
			OutstandingBalance:      0.0,
			Version:                 1,
			CreatedAt:               time.Now().AddDate(0, -5, 0).UTC(),
			UpdatedAt:               time.Now().UTC(),
		},
		{
			ID:                      "MEM_001_9912",
			MahalID:                 "MH_001_CALICUT",
			MemberCode:              "M-103",
			Name:                    "Faisal K.V.",
			Phone:                   "+919847555666",
			HouseName:               "Green Valley",
			FamilyHead:              true,
			FamilyMembersCount:      3,
			MonthlyDuesCustomAmount: 500.0,
			Status:                  "ACTIVE",
			LastPaidMonth:           "2026-07", // 1 month overdue (Aug)
			OutstandingBalance:      500.0,
			Version:                 1,
			CreatedAt:               time.Now().AddDate(0, -4, 0).UTC(),
			UpdatedAt:               time.Now().UTC(),
		},
		{
			ID:                      "MEM_001_9913",
			MahalID:                 "MH_001_CALICUT",
			MemberCode:              "M-104",
			Name:                    "Zubair Ahmed",
			Phone:                   "+919847777888",
			HouseName:               "Al-Burooj",
			FamilyHead:              true,
			FamilyMembersCount:      6,
			MonthlyDuesCustomAmount: 500.0,
			Status:                  "ACTIVE",
			LastPaidMonth:           "2026-06", // 2 months overdue (Jul, Aug)
			OutstandingBalance:      1000.0,
			Version:                 1,
			CreatedAt:               time.Now().AddDate(0, -4, 0).UTC(),
			UpdatedAt:               time.Now().UTC(),
		},
	}

	for _, mem := range members {
		_, err := db.Collection("members").InsertOne(ctx, mem)
		if err != nil {
			log.Error().Err(err).Str("id", mem.ID).Msg("Failed to insert member")
		}
	}

	// 4. Seed Initial Cryptographic Receipts (Chained SHA-256)
	log.Info().Msg("Seeding Chained Cryptographic Receipts...")
	prevHash := "0000000000000000000000000000000000000000000000000000000000000000"

	r1Num := "GV1MH00120260515R00001"
	r1Hash := domain.CalculateReceiptHash(r1Num, "MH_001_CALICUT", "MEM_001_9910", 500.0, prevHash)

	receipt1 := domain.Receipt{
		ID:                  "RCPT_001",
		ReceiptNumber:       r1Num,
		SequenceNumber:      1,
		MahalID:             "MH_001_CALICUT",
		MemberID:            "MEM_001_9910",
		MemberName:          "Muhammed Ameen",
		TransactionID:       "TXN_HIST_01",
		PaymentType:         "MONTHLY_DUES",
		PaidMonths:          []string{"2026-05"},
		Amount:              500.0,
		PreviousReceiptHash: prevHash,
		ReceiptHash:         r1Hash,
		CreatedAt:           time.Now().AddDate(0, -3, 0).UTC(),
	}
	_, _ = db.Collection("receipts").InsertOne(ctx, receipt1)

	r2Num := "GV1MH00120260801R00002"
	r2Hash := domain.CalculateReceiptHash(r2Num, "MH_001_CALICUT", "MEM_001_9911", 1000.0, r1Hash)

	receipt2 := domain.Receipt{
		ID:                  "RCPT_002",
		ReceiptNumber:       r2Num,
		SequenceNumber:      2,
		MahalID:             "MH_001_CALICUT",
		MemberID:            "MEM_001_9911",
		MemberName:          "Abdul Rahman",
		TransactionID:       "TXN_HIST_02",
		PaymentType:         "MONTHLY_DUES",
		PaidMonths:          []string{"2026-07", "2026-08"},
		Amount:              1000.0,
		PreviousReceiptHash: r1Hash,
		ReceiptHash:         r2Hash,
		CreatedAt:           time.Now().AddDate(0, 0, -20).UTC(),
	}
	_, _ = db.Collection("receipts").InsertOne(ctx, receipt2)

	// 5. Seed Initial Audit Log
	log.Info().Msg("Seeding Initial Audit Log...")
	auditEntry := bson.M{
		"_id":         "AUD_INIT_001",
		"mahal_id":    "MH_001_CALICUT",
		"actor":       bson.M{"user_id": "SYS_SEEDER", "role": "SUPER_ADMIN"},
		"category":    "SYSTEM_INIT",
		"action":      "DATABASE_SEEDED",
		"entity_type": "database",
		"entity_id":   "mahalflow",
		"timestamp":   time.Now().UTC(),
	}
	_, _ = db.Collection("audit_logs").InsertOne(ctx, auditEntry)

	log.Info().Msg(" Database seeding completed successfully!")
	fmt.Println("=================================================")
	fmt.Println("Seeded Collections:")
	fmt.Println("• Mahals: 2 documents")
	fmt.Println("• Members: 4 documents")
	fmt.Println("• Receipts: 2 cryptographically chained receipts")
	fmt.Println("• Audit Logs: 1 entry")
	fmt.Println("=================================================")
}
