package api

import (
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/firebaseauth"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"
)

// SessionTTL is how long an issued MahalFlow JWT stays valid.
const SessionTTL = 24 * time.Hour

// MinPasswordLength is enforced by cmd/setpassword.
const MinPasswordLength = 10

const invalidCredentials = "Invalid phone or password"

// SetPhoneAuth wires Firebase ID-token verification for /auth/resolve and
// /auth/register. verifier may be nil (Firebase not configured): then those
// routes refuse every request unless devBypass is set, in which case a posted
// phone is trusted. devBypass must never be enabled in production.
func (h *Handler) SetPhoneAuth(verifier firebaseauth.Verifier, devBypass bool) {
	h.idVerifier = verifier
	h.authDevBypass = devBypass
}

// HashPassword returns a bcrypt hash suitable for Admin.PasswordHash.
func HashPassword(password string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(b), err
}

var (
	dummyHashOnce sync.Once
	dummyHash     []byte
)

// burnPasswordCheck spends the same time as a real bcrypt comparison, so a
// phone with no admin record (or no password) is not distinguishable by
// response time from a wrong password.
func burnPasswordCheck(password string) {
	dummyHashOnce.Do(func() {
		dummyHash, _ = bcrypt.GenerateFromPassword([]byte("mahalflow-timing-equalizer"), bcrypt.DefaultCost)
	})
	_ = bcrypt.CompareHashAndPassword(dummyHash, []byte(password))
}

type LoginRequest struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
	// MahalID is optional: only needed when one phone administers several
	// Mahals. The admin's tenant otherwise comes from their admin record.
	MahalID string `json:"mahal_id"`
}

// Login is the web-admin password login: phone + bcrypt password checked
// against the admins collection. The JWT carries the admin record's real id,
// role and tenant; nothing in the request can choose them.
func (h *Handler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	phone := normalizePhoneIN(req.Phone)
	if phone == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Phone and password are required"})
	}
	if h.adminRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Authentication service offline"})
	}

	candidates, err := h.adminRepo.ListByPhone(c.Context(), phone)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Authentication service error"})
	}

	wantMahal := strings.TrimSpace(req.MahalID)
	var matched []domain.Admin
	checked := false
	for _, a := range candidates {
		if wantMahal != "" && a.MahalID != wantMahal {
			continue
		}
		if a.PasswordHash == "" {
			continue
		}
		checked = true
		if bcrypt.CompareHashAndPassword([]byte(a.PasswordHash), []byte(req.Password)) == nil {
			matched = append(matched, a)
		}
	}
	if !checked {
		burnPasswordCheck(req.Password)
	}

	if len(matched) == 0 {
		log.Warn().Str("phone_suffix", phoneSuffix(phone)).Str("ip", c.IP()).Msg("Admin login rejected")
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": invalidCredentials})
	}
	if len(matched) > 1 {
		ids := make([]string, 0, len(matched))
		for _, a := range matched {
			ids = append(ids, a.MahalID)
		}
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{
			"error":     "This phone administers more than one Mahal. Enter the Mahal ID to continue.",
			"mahal_ids": ids,
		})
	}

	admin := matched[0]
	role := admin.EffectiveRole()
	token, err := GenerateJWT(admin.ID, admin.Phone, role, admin.MahalID, SessionTTL)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to generate authentication token"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:   admin.MahalID,
			Action:    "ADMIN_LOGIN",
			Actor:     admin.Name,
			EntityID:  admin.ID,
			Details:   "Password login (" + role + ")",
			IPAddress: c.IP(),
		})
	}

	return c.JSON(fiber.Map{
		"token":      token,
		"role":       role,
		"admin_id":   admin.ID,
		"name":       admin.Name,
		"phone":      admin.Phone,
		"mahal_id":   admin.MahalID,
		"expires_in": int(SessionTTL.Seconds()),
	})
}

// NormalizePhoneIN is the phone normalisation every admin/member lookup uses
// (+91XXXXXXXXXX for Indian numbers). Exported for cmd/setpassword.
func NormalizePhoneIN(raw string) string { return normalizePhoneIN(raw) }

func phoneSuffix(p string) string {
	if len(p) <= 4 {
		return p
	}
	return "…" + p[len(p)-4:]
}

// verifiedPhone returns the phone number the caller has proven they own.
//
// With a verifier configured the phone comes only from a valid Firebase ID
// token's phone_number claim (token in the `id_token` body field, else the
// Authorization bearer). A posted phone is used only under AUTH_DEV_BYPASS,
// and only when the body carries no id_token.
func (h *Handler) verifiedPhone(c *fiber.Ctx, bodyToken, postedPhone string) (string, *apiError) {
	bodyToken = strings.TrimSpace(bodyToken)

	// Development bypass: a posted phone with no id_token. Checked first so a
	// stale session JWT in the Authorization header cannot get in the way.
	if h.authDevBypass && bodyToken == "" && strings.TrimSpace(postedPhone) != "" {
		phone := normalizePhoneIN(postedPhone)
		log.Warn().Str("phone_suffix", phoneSuffix(phone)).Msg("AUTH_DEV_BYPASS: trusting unverified phone")
		return phone, nil
	}

	token := bodyToken
	if token == "" {
		if ah := c.Get("Authorization"); len(ah) > 7 && strings.EqualFold(ah[:7], "bearer ") {
			token = strings.TrimSpace(ah[7:])
		}
	}

	if h.idVerifier == nil {
		return "", &apiError{status: fiber.StatusServiceUnavailable, msg: "Phone sign-in is not configured on this server"}
	}
	if token == "" {
		return "", errUnauthorized("Firebase ID token is required")
	}
	tok, err := h.idVerifier.VerifyIDToken(c.Context(), token)
	if err != nil {
		log.Warn().Err(err).Str("ip", c.IP()).Msg("Firebase ID token rejected")
		return "", errUnauthorized("Phone verification failed. Please sign in again.")
	}
	phone := normalizePhoneIN(tok.PhoneNumber)
	if phone == "" {
		return "", errUnauthorized("This sign-in has no verified phone number")
	}
	return phone, nil
}

type ResolveRequest struct {
	IDToken string `json:"id_token"`
	// Phone is ignored unless the server runs with AUTH_DEV_BYPASS=true.
	Phone string `json:"phone"`
}

// ResolveLogin maps a Firebase-verified phone to an identity within the
// tenant: admin, active member, pending member, or unregistered. Only admins
// and active members receive a session token.
func (h *Handler) ResolveLogin(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req ResolveRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	phone, aerr := h.verifiedPhone(c, req.IDToken, req.Phone)
	if aerr != nil {
		return aerr.send(c)
	}

	// 1. Admin phone?
	if h.adminRepo != nil {
		if a, _ := h.adminRepo.GetByPhone(c.Context(), tenantID, phone); a != nil {
			role := a.EffectiveRole()
			token, err := GenerateJWT(a.ID, phone, role, tenantID, SessionTTL)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to generate authentication token"})
			}
			return c.JSON(fiber.Map{
				"status": "ALLOWED", "role": role,
				"admin_id": a.ID, "name": a.Name, "mahal_id": tenantID, "token": token,
				"expires_in": int(SessionTTL.Seconds()),
			})
		}
	}

	// 2. Member phone?
	if h.memberRepo != nil {
		if m, _ := h.memberRepo.GetByPhone(c.Context(), tenantID, phone); m != nil {
			if m.Status == MemberStatusPending {
				return c.JSON(fiber.Map{
					"status": "PENDING", "role": domain.RoleMember,
					"member_id": m.ID, "name": m.Name, "mahal_id": tenantID,
				})
			}
			if m.Status == MemberStatusRejected {
				return c.JSON(fiber.Map{
					"status": "REJECTED", "role": domain.RoleMember,
					"member_id": m.ID, "name": m.Name, "mahal_id": tenantID,
				})
			}
			token, err := GenerateJWT(m.ID, phone, domain.RoleMember, tenantID, SessionTTL)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to generate authentication token"})
			}
			return c.JSON(fiber.Map{
				"status": "ALLOWED", "role": domain.RoleMember,
				"member_id": m.ID, "name": m.Name, "mahal_id": tenantID, "token": token,
				"expires_in": int(SessionTTL.Seconds()),
			})
		}
	}

	// 3. Unknown — the app should collect identity and register.
	return c.JSON(fiber.Map{"status": "UNREGISTERED", "phone": phone})
}

type RegisterMemberRequest struct {
	IDToken string `json:"id_token"`
	// Phone is ignored unless the server runs with AUTH_DEV_BYPASS=true.
	Phone   string `json:"phone"`
	MahalID string `json:"mahal_id"`
	Name    string `json:"name"`
}

// RegisterSelf creates a PENDING_APPROVAL member for a Firebase-verified,
// unregistered phone. The member cannot transact until an admin approves.
func (h *Handler) RegisterSelf(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}
	var req RegisterMemberRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	phone, aerr := h.verifiedPhone(c, req.IDToken, req.Phone)
	if aerr != nil {
		return aerr.send(c)
	}
	mahalID := strings.TrimSpace(req.MahalID)
	if mahalID == "" {
		mahalID = tenantID
	}
	name := strings.TrimSpace(req.Name)
	if name == "" || mahalID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Name, phone and Mahal ID are required"})
	}

	// Confirm the Mahal exists (identity check the user does at registration).
	if h.mahalRepo != nil {
		if mh, mErr := h.mahalRepo.GetByID(c.Context(), mahalID); mErr != nil || mh == nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "No Mahal found for that ID"})
		}
	}

	// Already known? Report current state rather than duplicating.
	if existing, _ := h.memberRepo.GetByPhone(c.Context(), mahalID, phone); existing != nil {
		status := "ALLOWED"
		switch existing.Status {
		case MemberStatusPending:
			status = "PENDING"
		case MemberStatusRejected:
			status = "REJECTED"
		}
		return c.JSON(fiber.Map{"status": status, "member_id": existing.ID, "name": existing.Name})
	}

	memberID := "MEM_" + uuid.New().String()[:8]
	now := time.Now().UTC()
	member := domain.Member{
		ID:                      memberID,
		MahalID:                 mahalID,
		MemberCode:              "M-" + strconv.FormatInt(now.Unix()%100000, 10),
		Name:                    name,
		Phone:                   phone,
		MonthlyDuesCustomAmount: 500,
		Status:                  MemberStatusPending,
		LastPaidMonth:           now.AddDate(0, -1, 0).Format("2006-01"),
		OutstandingBalance:      0,
		Version:                 1,
		CreatedAt:               now,
		UpdatedAt:               now,
	}
	if err := h.memberRepo.Create(c.Context(), &member); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not register member"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  mahalID,
			Action:   "MEMBER_REGISTRATION_REQUESTED",
			Actor:    name,
			EntityID: memberID,
			Details:  "Self-registration pending approval (" + phone + ")",
		})
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "PENDING", "member_id": memberID, "name": name,
	})
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

// MaxPasswordLength is bcrypt's input limit (longer input is truncated).
const MaxPasswordLength = 72

// ChangePassword lets a signed-in admin replace their own web-admin
// password. The current password must verify against the stored bcrypt
// hash; the admin record is the one the JWT was issued for (its subject,
// phone and home Mahal), never anything from the request.
func (h *Handler) ChangePassword(c *fiber.Ctx) error {
	var req ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return errBadRequest("Invalid request body").send(c)
	}
	if req.CurrentPassword == "" || req.NewPassword == "" {
		return errBadRequest("current_password and new_password are required").send(c)
	}
	if len(req.NewPassword) < MinPasswordLength {
		return errBadRequest("New password must be at least " + strconv.Itoa(MinPasswordLength) + " characters").send(c)
	}
	if len(req.NewPassword) > MaxPasswordLength {
		return errBadRequest("New password must be at most " + strconv.Itoa(MaxPasswordLength) + " bytes").send(c)
	}
	if req.NewPassword == req.CurrentPassword {
		return errBadRequest("New password must differ from the current one").send(c)
	}
	if h.adminRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Authentication service offline"})
	}

	sub := sessionSubject(c)
	phone, _ := c.Locals("user_phone").(string)
	home, _ := c.Locals("user_mahal_id").(string)
	admin, err := h.adminRepo.GetByPhone(c.Context(), home, phone)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Authentication service error"})
	}
	if admin == nil || admin.ID != sub || admin.PasswordHash == "" {
		burnPasswordCheck(req.CurrentPassword)
		return errForbidden("Password login is not set up for this account").send(c)
	}
	if bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(req.CurrentPassword)) != nil {
		log.Warn().Str("admin_id", admin.ID).Str("ip", c.IP()).Msg("Password change rejected: wrong current password")
		return errBadRequest("Current password is incorrect").send(c)
	}
	hash, err := HashPassword(req.NewPassword)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update the password"})
	}
	ok, err := h.adminRepo.SetPasswordHash(c.Context(), admin.ID, hash)
	if err != nil || !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update the password"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: admin.MahalID, Action: "ADMIN_PASSWORD_CHANGED", Actor: admin.Name, EntityID: admin.ID,
			Details: "Admin changed their own password", IPAddress: c.IP(),
		})
	}
	return c.JSON(fiber.Map{"status": "PASSWORD_CHANGED"})
}
