package api

import (
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// Mahal field limits.
const (
	mahalNameMax         = 120
	mahalRegNumberMax    = 64
	mahalAddressMax      = 500
	mahalPlanMax         = 40
	mahalMaxMonthlyDues  = 1_000_000
	mahalMaxMonthlyFee   = 1_000_000
	mahalRecentPayments  = 10
	mahalStatsMaxPayment = 50
)

// mahalIDPattern is the tenant id format: upper-case letters, digits, "_"
// and "-", 3-40 chars, starting with a letter or digit.
var mahalIDPattern = regexp.MustCompile(`^[A-Z0-9][A-Z0-9_-]{2,39}$`)

var subscriptionStatuses = map[domain.SubscriptionStatus]bool{
	domain.SubActive: true, domain.SubGracePeriod: true, domain.SubReadOnly: true, domain.SubSuspended: true,
}

func errConflict(msg string) *apiError { return &apiError{status: fiber.StatusConflict, msg: msg} }

// sessionActor names the caller for audit logs: the admin's name when the
// admin record can be found, else "<ROLE> <id>".
func (h *Handler) sessionActor(c *fiber.Ctx) string {
	sub, role := sessionSubject(c), sessionRole(c)
	phone, _ := c.Locals("user_phone").(string)
	home, _ := c.Locals("user_mahal_id").(string)
	if h.adminRepo != nil && phone != "" {
		if a, _ := h.adminRepo.GetByPhone(c.Context(), home, phone); a != nil && a.ID == sub && a.Name != "" {
			return a.Name
		}
	}
	return strings.TrimSpace(role + " " + sub)
}

// canManageMahal: SUPER_ADMIN manages any Mahal, MAHAL_ADMIN only the one
// their token is bound to (JWTAuthMiddleware already pins tenant_id to it).
func canManageMahal(c *fiber.Ctx, id string) bool {
	if sessionRole(c) == domain.RoleSuperAdmin {
		return true
	}
	tenantID, _ := c.Locals("tenant_id").(string)
	home, _ := c.Locals("user_mahal_id").(string)
	return id != "" && id == tenantID && id == home
}

// cleanText trims s and enforces a rune limit.
func cleanText(field, s string, max int) (string, *apiError) {
	s = strings.TrimSpace(s)
	if utf8.RuneCountInString(s) > max {
		return "", errBadRequest(fmt.Sprintf("%s must be at most %d characters", field, max))
	}
	return s, nil
}

// cleanContactPhone accepts an Indian mobile (stored as +91XXXXXXXXXX) or a
// landline-style number of 10-13 digits (stored trimmed). "" clears.
func cleanContactPhone(field, raw string) (string, *apiError) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", nil
	}
	if p, ok := parseIndianMobile(raw); ok {
		return p, nil
	}
	digits := 0
	for _, r := range raw {
		switch {
		case r >= '0' && r <= '9':
			digits++
		case strings.ContainsRune(" +-()", r):
		default:
			return "", errBadRequest(field + " is not a valid phone number")
		}
	}
	if digits < 10 || digits > 13 {
		return "", errBadRequest(field + " is not a valid phone number")
	}
	return raw, nil
}

// MahalContactInput / MahalSettingsInput / MahalSubscriptionInput carry
// optional fields: nil = unchanged (update) or default (create).
type MahalContactInput struct {
	Email    *string `json:"email"`
	Phone    *string `json:"phone"`
	WhatsApp *string `json:"whatsapp"`
	Address  *string `json:"address"`
}

type MahalSettingsInput struct {
	DefaultMonthlyDues *float64 `json:"default_monthly_dues"`
	DunningEnabled     *bool    `json:"dunning_enabled"`
	AutoPayAllowed     *bool    `json:"autopay_allowed"`
}

type MahalSubscriptionInput struct {
	Status     *string  `json:"status"`
	Plan       *string  `json:"plan"`
	MonthlyFee *float64 `json:"monthly_fee"`
}

type MahalInput struct {
	ID                 string                  `json:"id"`
	Name               *string                 `json:"name"`
	RegistrationNumber *string                 `json:"registration_number"`
	Contact            *MahalContactInput      `json:"contact"`
	Settings           *MahalSettingsInput     `json:"settings"`
	Subscription       *MahalSubscriptionInput `json:"subscription"`
}

// mahalSet validates in and returns the $set document (dotted bson paths)
// plus the changed field names for the audit log.
func mahalSet(in MahalInput) (bson.M, []string, *apiError) {
	set := bson.M{}
	var fields []string
	put := func(key string, v any) { set[key] = v; fields = append(fields, key) }

	if in.Name != nil {
		name, aerr := cleanText("name", *in.Name, mahalNameMax)
		if aerr != nil {
			return nil, nil, aerr
		}
		if name == "" {
			return nil, nil, errBadRequest("name is required")
		}
		put("name", name)
	}
	if in.RegistrationNumber != nil {
		reg, aerr := cleanText("registration_number", *in.RegistrationNumber, mahalRegNumberMax)
		if aerr != nil {
			return nil, nil, aerr
		}
		put("registration_number", reg)
	}
	if ct := in.Contact; ct != nil {
		if ct.Email != nil {
			e := strings.TrimSpace(*ct.Email)
			if e != "" && !validEmail(e) {
				return nil, nil, errBadRequest("contact email is not valid")
			}
			put("contact.email", e)
		}
		if ct.Phone != nil {
			p, aerr := cleanContactPhone("contact phone", *ct.Phone)
			if aerr != nil {
				return nil, nil, aerr
			}
			put("contact.phone", p)
		}
		if ct.WhatsApp != nil {
			p, aerr := cleanContactPhone("WhatsApp number", *ct.WhatsApp)
			if aerr != nil {
				return nil, nil, aerr
			}
			put("contact.whatsapp", p)
		}
		if ct.Address != nil {
			a, aerr := cleanText("address", *ct.Address, mahalAddressMax)
			if aerr != nil {
				return nil, nil, aerr
			}
			put("contact.address", a)
		}
	}
	if st := in.Settings; st != nil {
		if st.DefaultMonthlyDues != nil {
			d := *st.DefaultMonthlyDues
			if d < 0 || d > mahalMaxMonthlyDues || d != d {
				return nil, nil, errBadRequest(fmt.Sprintf("default_monthly_dues must be between 0 and %d", mahalMaxMonthlyDues))
			}
			put("settings.default_monthly_dues", d)
		}
		if st.DunningEnabled != nil {
			put("settings.dunning_enabled", *st.DunningEnabled)
		}
		if st.AutoPayAllowed != nil {
			put("settings.autopay_allowed", *st.AutoPayAllowed)
		}
	}
	if sb := in.Subscription; sb != nil {
		if sb.Status != nil {
			s := domain.SubscriptionStatus(strings.ToUpper(strings.TrimSpace(*sb.Status)))
			if !subscriptionStatuses[s] {
				return nil, nil, errBadRequest("subscription status must be ACTIVE, GRACE_PERIOD, READ_ONLY or SUSPENDED")
			}
			put("subscription.status", s)
		}
		if sb.Plan != nil {
			p, aerr := cleanText("subscription plan", *sb.Plan, mahalPlanMax)
			if aerr != nil {
				return nil, nil, aerr
			}
			put("subscription.plan", strings.ToUpper(p))
		}
		if sb.MonthlyFee != nil {
			f := *sb.MonthlyFee
			if f < 0 || f > mahalMaxMonthlyFee || f != f {
				return nil, nil, errBadRequest(fmt.Sprintf("subscription monthly_fee must be between 0 and %d", mahalMaxMonthlyFee))
			}
			put("subscription.monthly_fee", f)
		}
	}
	return set, fields, nil
}

func touchesSubscription(in MahalInput) bool {
	s := in.Subscription
	return s != nil && (s.Status != nil || s.Plan != nil || s.MonthlyFee != nil)
}

// CreateMahal registers a tenant (SUPER_ADMIN only, enforced by the route).
// id is optional (generated when blank) and must match mahalIDPattern; an id
// already in use answers 409. name is required.
func (h *Handler) CreateMahal(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	var in MahalInput
	if err := c.BodyParser(&in); err != nil {
		return errBadRequest("Invalid request body").send(c)
	}
	if in.Name == nil || strings.TrimSpace(*in.Name) == "" {
		return errBadRequest("name is required").send(c)
	}
	id := strings.ToUpper(strings.TrimSpace(in.ID))
	if id == "" {
		id = "MH_" + strings.ToUpper(strings.ReplaceAll(uuid.New().String(), "-", "")[:8])
	} else if !mahalIDPattern.MatchString(id) {
		return errBadRequest("id must be 3-40 characters: A-Z, 0-9, '_' or '-'").send(c)
	}
	set, _, aerr := mahalSet(in)
	if aerr != nil {
		return aerr.send(c)
	}
	if existing, _ := h.mahalRepo.GetByID(c.Context(), id); existing != nil {
		return errConflict("A Mahal with id " + id + " already exists").send(c)
	}

	now := time.Now().UTC()
	m := domain.Mahal{
		ID:        id,
		Settings:  domain.MahalSettings{Currency: "INR", PreferredLanguages: []string{}},
		CreatedAt: now,
		UpdatedAt: now,
		Subscription: domain.MahalSubscription{
			Status: domain.SubActive,
		},
	}
	// Apply the validated fields onto the zero record.
	str := func(k string) string { v, _ := set[k].(string); return v }
	m.Name = str("name")
	m.RegistrationNumber = str("registration_number")
	m.Contact = domain.MahalContact{Email: str("contact.email"), Phone: str("contact.phone"), WhatsApp: str("contact.whatsapp"), Address: str("contact.address")}
	if v, ok := set["settings.default_monthly_dues"].(float64); ok {
		m.Settings.DefaultMonthlyDues = v
	}
	if v, ok := set["settings.dunning_enabled"].(bool); ok {
		m.Settings.DunningEnabled = v
	}
	if v, ok := set["settings.autopay_allowed"].(bool); ok {
		m.Settings.AutoPayAllowed = v
	}
	if v, ok := set["subscription.status"].(domain.SubscriptionStatus); ok {
		m.Subscription.Status = v
	}
	m.Subscription.Plan = str("subscription.plan")
	if v, ok := set["subscription.monthly_fee"].(float64); ok {
		m.Subscription.MonthlyFee = v
	}

	if err := h.mahalRepo.Create(c.Context(), &m); err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return errConflict("A Mahal with id " + id + " already exists").send(c)
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create the Mahal"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: m.ID, Action: "MAHAL_CREATED", Actor: h.sessionActor(c), EntityID: m.ID,
			Details: "Registered Mahal " + m.Name, IPAddress: c.IP(),
		})
	}
	return c.Status(fiber.StatusCreated).JSON(m)
}

// UpdateMahal edits one Mahal. SUPER_ADMIN: any Mahal, any field.
// MAHAL_ADMIN: their own Mahal only (others answer 404), and never the
// subscription (403). Only fields present in the body change.
func (h *Handler) UpdateMahal(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	id := strings.Clone(c.Params("id"))
	if !canManageMahal(c, id) {
		return errNotFound("Mahal not found").send(c)
	}
	var in MahalInput
	if err := c.BodyParser(&in); err != nil {
		return errBadRequest("Invalid request body").send(c)
	}
	if in.ID != "" && strings.ToUpper(strings.TrimSpace(in.ID)) != id {
		return errBadRequest("The Mahal id cannot be changed").send(c)
	}
	if touchesSubscription(in) && sessionRole(c) != domain.RoleSuperAdmin {
		return errForbidden("Only a super admin can change the subscription").send(c)
	}
	set, fields, aerr := mahalSet(in)
	if aerr != nil {
		return aerr.send(c)
	}
	if existing, err := h.mahalRepo.GetByID(c.Context(), id); err != nil || existing == nil {
		return errNotFound("Mahal not found").send(c)
	}
	if len(set) > 0 {
		found, err := h.mahalRepo.Update(c.Context(), id, set)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update the Mahal"})
		}
		if !found {
			return errNotFound("Mahal not found").send(c)
		}
		if h.auditRepo != nil {
			sort.Strings(fields)
			_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
				MahalID: id, Action: "MAHAL_UPDATED", Actor: h.sessionActor(c), EntityID: id,
				Details: "Updated " + strings.Join(fields, ", "), IPAddress: c.IP(),
			})
		}
	}
	m, err := h.mahalRepo.GetByID(c.Context(), id)
	if err != nil || m == nil {
		return errNotFound("Mahal not found").send(c)
	}
	return c.JSON(m)
}

// GetMahalStats backs the Mahal details page: member counts, collections
// (month-to-date in Asia/Kolkata, and all time) and the latest payments with
// member names. Same visibility as GetMahalByID.
func (h *Handler) GetMahalStats(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	id := strings.Clone(c.Params("id"))
	if !canManageMahal(c, id) {
		return errNotFound("Mahal not found").send(c)
	}
	if m, err := h.mahalRepo.GetByID(c.Context(), id); err != nil || m == nil {
		return errNotFound("Mahal not found").send(c)
	}
	limit := int64(c.QueryInt("limit", mahalRecentPayments))
	if limit <= 0 || limit > mahalStatsMaxPayment {
		limit = mahalRecentPayments
	}

	var total, paid, pending int64
	var pendingDues float64
	if h.memberRepo != nil {
		var err error
		total, paid, pending, pendingDues, err = h.memberRepo.GetMemberStats(c.Context(), id)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load member stats"})
		}
	}

	loc := tenantLocation()
	from, _ := monthToDate(time.Now(), loc)
	mtdMonth := time.Now().In(loc).Format("2006-01")
	recent := []fiber.Map{}
	var mtdTotal, mtdDues, mtdDonations, allTime float64
	var mtdCount int64
	if h.txnRepo != nil {
		mtd, err := h.txnRepo.GetFinancialSummaryRange(c.Context(), id, &from, nil)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load collections"})
		}
		all, err := h.txnRepo.GetFinancialSummaryRange(c.Context(), id, nil, nil)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load collections"})
		}
		mtdTotal, mtdDues, mtdDonations, mtdCount = mtd.TotalCollected, mtd.DuesCollected, mtd.Donations, mtd.TransactionCount
		allTime = all.TotalCollected

		txns, _, err := h.txnRepo.ListAll(c.Context(), id, limit, 0)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load recent payments"})
		}
		names := h.memberNames(c, id, txns)
		for _, t := range txns {
			recent = append(recent, fiber.Map{
				"id": t.ID, "member_id": t.MemberID, "member_name": names[t.MemberID],
				"type": t.Type, "amount": t.Amount, "status": t.Status, "gateway": t.Gateway,
				"payment_mode": t.PaymentMode, "receipt_id": t.ReceiptID,
				"created_at": t.CreatedAt, "completed_at": t.CompletedAt,
			})
		}
	}

	return c.JSON(fiber.Map{
		"mahal_id":           id,
		"total_members":      total,
		"paid_members":       paid,
		"pending_members":    pending,
		"total_pending_dues": pendingDues,
		"collected_mtd":      mtdTotal,
		"dues_collected_mtd": mtdDues,
		"donations_mtd":      mtdDonations,
		"transactions_mtd":   mtdCount,
		"collected_all_time": allTime,
		"mtd_month":          mtdMonth,
		"timezone":           TenantTimezone,
		"recent_payments":    recent,
	})
}

// memberNames resolves the member names for txns (one query).
func (h *Handler) memberNames(c *fiber.Ctx, mahalID string, txns []domain.Transaction) map[string]string {
	if h.memberRepo == nil || len(txns) == 0 {
		return map[string]string{}
	}
	seen := map[string]bool{}
	ids := make([]string, 0, len(txns))
	for _, t := range txns {
		if t.MemberID != "" && !seen[t.MemberID] {
			seen[t.MemberID] = true
			ids = append(ids, t.MemberID)
		}
	}
	names, err := h.memberRepo.GetNames(c.Context(), mahalID, ids)
	if err != nil || names == nil {
		return map[string]string{}
	}
	return names
}
