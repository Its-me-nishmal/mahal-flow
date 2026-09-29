// Command setpassword sets or resets a committee admin's web-admin password.
//
//	go run ./cmd/setpassword --phone 9847123456 --password 'long-secret-pass'
//	go run ./cmd/setpassword --phone 9847123456            # prompts on stdin
//	go run ./cmd/setpassword --phone 9847123456 --mahal MH_001_CALICUT
//	go run ./cmd/setpassword --phone 9000000000 --create --name "Ops" --mahal MH_001_CALICUT --role SUPER_ADMIN
//
// It connects with the same MONGO_URI / DB_NAME the API uses (environment or
// a .env in the working directory) and prints the target before writing.
// --mahal is required when the phone administers more than one Mahal.
// The password may also come from MAHALFLOW_ADMIN_PASSWORD, which keeps it
// out of shell history.
package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/api"
	"github.com/mahalflow/backend-go/internal/config"
	"github.com/mahalflow/backend-go/internal/database"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
)

func main() {
	phoneFlag := flag.String("phone", "", "admin phone (10-digit Indian mobile or E.164)")
	password := flag.String("password", "", "new password (else MAHALFLOW_ADMIN_PASSWORD, else prompt)")
	mahal := flag.String("mahal", "", "Mahal ID (required if the phone is an admin of several Mahals, or with --create)")
	create := flag.Bool("create", false, "create the admin record if none exists")
	name := flag.String("name", "", "admin display name (with --create)")
	role := flag.String("role", domain.RoleMahalAdmin, "MAHAL_ADMIN or SUPER_ADMIN (with --create)")
	flag.Parse()

	phone := api.NormalizePhoneIN(*phoneFlag)
	if phone == "" {
		fail("--phone is required")
	}

	pw := *password
	if pw == "" {
		pw = os.Getenv("MAHALFLOW_ADMIN_PASSWORD")
	}
	if pw == "" {
		fmt.Fprint(os.Stderr, "New password: ")
		line, _ := bufio.NewReader(os.Stdin).ReadString('\n')
		pw = strings.TrimRight(line, "\r\n")
	}
	if len(pw) < api.MinPasswordLength {
		fail(fmt.Sprintf("password must be at least %d characters", api.MinPasswordLength))
	}

	cfg := config.Load()
	fmt.Fprintf(os.Stderr, "Target: %s / db %s\n", redact(cfg.MongoURI), cfg.DBName)
	db, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil || db == nil {
		fail(fmt.Sprintf("connect MongoDB: %v", err))
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	repo := repository.NewAdminRepository(db.DB)

	admins, err := repo.ListByPhone(ctx, phone)
	if err != nil {
		fail(fmt.Sprintf("look up admin: %v", err))
	}
	var matches []domain.Admin
	for _, a := range admins {
		if *mahal == "" || a.MahalID == *mahal {
			matches = append(matches, a)
		}
	}

	hash, err := api.HashPassword(pw)
	if err != nil {
		fail(fmt.Sprintf("hash password: %v", err))
	}

	switch {
	case len(matches) == 1:
		a := matches[0]
		ok, err := repo.SetPasswordHash(ctx, a.ID, hash)
		if err != nil || !ok {
			fail(fmt.Sprintf("update admin %s: %v", a.ID, err))
		}
		fmt.Printf("Password set for %s (%s, %s, %s)\n", a.ID, a.Name, a.MahalID, a.EffectiveRole())

	case len(matches) > 1:
		ids := make([]string, 0, len(matches))
		for _, a := range matches {
			ids = append(ids, a.MahalID)
		}
		fail("phone is an admin of several Mahals; pass --mahal (one of: " + strings.Join(ids, ", ") + ")")

	case *create:
		if *mahal == "" || strings.TrimSpace(*name) == "" {
			fail("--create needs --mahal and --name")
		}
		r := strings.ToUpper(strings.TrimSpace(*role))
		if r != domain.RoleMahalAdmin && r != domain.RoleSuperAdmin {
			fail("--role must be MAHAL_ADMIN or SUPER_ADMIN")
		}
		now := time.Now().UTC()
		a := &domain.Admin{
			ID:                "ADM_" + strings.ReplaceAll(uuid.New().String(), "-", "")[:10],
			MahalID:           *mahal,
			Name:              strings.TrimSpace(*name),
			Phone:             phone,
			Role:              r,
			PasswordHash:      hash,
			PasswordUpdatedAt: &now,
			CreatedAt:         now,
		}
		if err := repo.Create(ctx, a); err != nil {
			fail(fmt.Sprintf("create admin: %v", err))
		}
		fmt.Printf("Created %s (%s, %s, %s) with password\n", a.ID, a.Name, a.MahalID, r)

	default:
		fail("no admin with phone " + phone + " (use --create --mahal ID --name NAME to add one)")
	}
}

func redact(uri string) string {
	u, err := url.Parse(uri)
	if err != nil {
		return "(unparseable URI)"
	}
	u.User = nil
	u.RawQuery = ""
	return u.String()
}

func fail(msg string) {
	fmt.Fprintln(os.Stderr, "setpassword:", msg)
	os.Exit(1)
}
