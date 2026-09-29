package api

import (
	"context"
	"fmt"
	"html"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/firebaseauth"
	"github.com/mahalflow/backend-go/internal/gateway/pg"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/mahalflow/backend-go/internal/service"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type Handler struct {
	paymentService service.PaymentService
	mahalRepo      repository.MahalRepository
	memberRepo     repository.MemberRepository
	receiptRepo    repository.ReceiptRepository
	txnRepo        repository.TransactionRepository
	auditRepo      repository.AuditLogRepository
	alertRepo      repository.AlertRepository
	refundRepo     repository.RefundRepository
	mandateRepo    repository.MandateRepository
	adminRepo      repository.AdminRepository
	pgClient       *pg.Client
	autoPayEvery   time.Duration // recurring-debit cadence for test mandates

	// Push notifications. Both optional: nil means tokens are accepted but
	// not stored, and nothing is pushed.
	deviceTokenRepo repository.DeviceTokenRepository
	push            *service.PushService

	// Firebase ID-token verification for /auth/resolve and /auth/register
	// (see SetPhoneAuth). nil = not configured.
	idVerifier    firebaseauth.Verifier
	authDevBypass bool

	// Excel member imports (SetImportBatches). nil = imports offline.
	importRepo repository.ImportBatchRepository
	// publicBaseURL is how browsers reach this API (SetPublicBaseURL).
	publicBaseURL string
}

// SetPush wires device-token storage and FCM delivery. Kept out of NewHandler
// so push stays optional and the constructor signature stays stable.
func (h *Handler) SetPush(tokens repository.DeviceTokenRepository, push *service.PushService) {
	h.deviceTokenRepo = tokens
	h.push = push
}

// pushAsync sends detached from the request, so a slow FCM round-trip never
// delays the admin's response or fails it.
func (h *Handler) pushAsync(send func(ctx context.Context, p *service.PushService)) {
	if !h.push.Enabled() {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()
		send(ctx, h.push)
	}()
}

func NewHandler(
	ps service.PaymentService,
	mhr repository.MahalRepository,
	mr repository.MemberRepository,
	rr repository.ReceiptRepository,
	tr repository.TransactionRepository,
	aur repository.AuditLogRepository,
	alr repository.AlertRepository,
	refr repository.RefundRepository,
	mndr repository.MandateRepository,
	adr repository.AdminRepository,
	pgc *pg.Client,
) *Handler {
	return &Handler{
		paymentService: ps,
		mahalRepo:      mhr,
		memberRepo:     mr,
		receiptRepo:    rr,
		txnRepo:        tr,
		auditRepo:      aur,
		alertRepo:      alr,
		refundRepo:     refr,
		mandateRepo:    mndr,
		adminRepo:      adr,
		pgClient:       pgc,
	}
}

// -------------------------------------------------------------
// 1. AUTHENTICATION & PROFILE
// -------------------------------------------------------------

// MemberStatusPending marks a self-registered member awaiting admin approval.
const MemberStatusPending = "PENDING_APPROVAL"

// normalizePhoneIN returns an Indian E.164 phone (+91XXXXXXXXXX) from loose input.
func normalizePhoneIN(raw string) string {
	var digits strings.Builder
	for _, r := range raw {
		if r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	d := digits.String()
	switch {
	case len(d) == 10:
		return "+91" + d
	case len(d) == 12 && strings.HasPrefix(d, "91"):
		return "+" + d
	case d == "":
		return ""
	default:
		return "+" + d
	}
}

// GetPendingMembers lists members awaiting approval for the admin's tenant.
func (h *Handler) GetPendingMembers(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}
	all, _, err := h.memberRepo.ListByMahal(c.Context(), tenantID, 500, 0)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	pending := make([]domain.Member, 0)
	for _, m := range all {
		if m.Status == MemberStatusPending {
			pending = append(pending, m)
		}
	}
	return c.JSON(fiber.Map{"pending": pending, "total": len(pending)})
}

// ApproveMember activates a pending member so they can transact. The
// decision can be undone for ApprovalRevertWindow (RevertMemberApproval).
func (h *Handler) ApproveMember(c *fiber.Ctx) error {
	return h.decideRegistration(c, "ACTIVE", "MEMBER_APPROVED", "Member approved and activated")
}

// RejectMember marks a pending registration REJECTED. The record is kept (not
// deleted) so the decision can be reverted; a rejected phone cannot sign in.
func (h *Handler) RejectMember(c *fiber.Ctx) error {
	return h.decideRegistration(c, MemberStatusRejected, "MEMBER_REJECTED", "Member registration rejected")
}

func (h *Handler) GetCurrentUser(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	userID := sessionSubject(c)
	userRole := sessionRole(c)
	if userID == "" || userRole == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized: authentication required"})
	}

	mahalName := "Mahal Administration"
	if h.mahalRepo != nil && tenantID != "" {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			mahalName = m.Name
		}
	}

	name := "Admin - " + mahalName
	if userRole == domain.RoleMember && h.memberRepo != nil {
		if m, err := h.memberRepo.GetByID(c.Context(), tenantID, userID); err == nil && m != nil {
			name = m.Name
		}
	} else if phone, _ := c.Locals("user_phone").(string); phone != "" && h.adminRepo != nil {
		// The admin record lives in the Mahal the token was issued for, which
		// differs from X-Tenant-ID when a SUPER_ADMIN works on another Mahal.
		home, _ := c.Locals("user_mahal_id").(string)
		if a, _ := h.adminRepo.GetByPhone(c.Context(), home, phone); a != nil && a.ID == userID {
			name = a.Name
		}
	}
	userPhone, _ := c.Locals("user_phone").(string)
	homeMahal, _ := c.Locals("user_mahal_id").(string)

	return c.JSON(fiber.Map{
		"user_id":    userID,
		"name":       name,
		"role":       userRole,
		"mahal_id":   tenantID,
		"mahal_name": mahalName,
		"phone":      userPhone,
		// home_mahal_id: the Mahal the session was issued for.
		"home_mahal_id": homeMahal,
		"status":        "ACTIVE",
	})
}

// -------------------------------------------------------------
// 2. MEMBER OPERATIONS
// -------------------------------------------------------------

func (h *Handler) GetMemberDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Query("member_id"))
	if aerr != nil {
		return aerr.send(c)
	}

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Database service unavailable"})
	}

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || member == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	mahalName := "Mahal Organization"
	var mahal *domain.Mahal
	if h.mahalRepo != nil {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			mahal = m
			mahalName = m.Name
		}
	}

	var latestReceipt *domain.Receipt
	if h.receiptRepo != nil {
		latestReceipt, _ = h.receiptRepo.GetLatestByMember(c.Context(), tenantID, member.ID)
		if latestReceipt != nil {
			h.decorateReceipt(c.Context(), latestReceipt)
		}
	}

	outstanding := member.OutstandingBalance
	advanceCredit := 0.0
	if outstanding < 0 {
		advanceCredit = -outstanding
		outstanding = 0
	}
	rate, source := effectiveMonthlyDues(member, mahal)

	return c.JSON(fiber.Map{
		"member_id":              member.ID,
		"member_name":            member.Name,
		"mahal_name":             mahalName,
		"outstanding_balance":    outstanding,
		"advance_credit":         advanceCredit,
		"last_paid_month":        member.LastPaidMonth,
		"latest_payment":         latestReceipt,
		"effective_monthly_dues": rate,
		"dues_rate_source":       source,
		"mahal_contact":          mahalContactJSON(mahal),
	})
}

// memberProfile is the member record plus what the app needs alongside it.
type memberProfile struct {
	domain.Member
	EffectiveMonthlyDues float64   `json:"effective_monthly_dues"`
	DuesRateSource       string    `json:"dues_rate_source"`
	MahalName            string    `json:"mahal_name"`
	MahalContact         fiber.Map `json:"mahal_contact"`
}

func (h *Handler) profileFor(ctx context.Context, m *domain.Member) memberProfile {
	var mahal *domain.Mahal
	if h.mahalRepo != nil {
		mahal, _ = h.mahalRepo.GetByID(ctx, m.MahalID)
	}
	rate, source := effectiveMonthlyDues(m, mahal)
	name := ""
	if mahal != nil {
		name = mahal.Name
	}
	return memberProfile{Member: *m, EffectiveMonthlyDues: rate, DuesRateSource: source, MahalName: name, MahalContact: mahalContactJSON(mahal)}
}

func (h *Handler) GetMemberProfile(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Params("id"))
	if aerr != nil {
		return aerr.send(c)
	}

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Database service unavailable"})
	}

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || member == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}
	return c.JSON(h.profileFor(c.Context(), member))
}

type CreateMemberRequest struct {
	Name                    string  `json:"name"`
	Phone                   string  `json:"phone"`
	Email                   string  `json:"email"`
	HouseName               string  `json:"house_name"`
	FamilyHead              bool    `json:"family_head"`
	FamilyMembersCount      int     `json:"family_members_count"`
	MonthlyDuesCustomAmount float64 `json:"monthly_dues_custom_amount"`
	Status                  string  `json:"status"`
}

func (h *Handler) CreateMember(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}

	var req CreateMemberRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.Name == "" || req.Phone == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Name and phone are required"})
	}
	if e := strings.TrimSpace(req.Email); e != "" && !validEmail(e) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Email is not valid"})
	}
	// Store the phone the way logins and imports look it up (+91XXXXXXXXXX).
	phone, ok := parseIndianMobile(req.Phone)
	if !ok {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Phone must be a 10-digit Indian mobile number"})
	}
	req.Phone = phone
	if other, _ := h.memberRepo.GetByPhone(c.Context(), tenantID, phone); other != nil {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "A member of this Mahal already uses that phone"})
	}

	if req.MonthlyDuesCustomAmount > mahalMaxMonthlyDues {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Monthly dues amount is out of range"})
	}
	if req.MonthlyDuesCustomAmount <= 0 {
		// The Mahal's configured default, else the historical ₹500.
		req.MonthlyDuesCustomAmount = 500.0
		if h.mahalRepo != nil {
			if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil && m.Settings.DefaultMonthlyDues > 0 {
				req.MonthlyDuesCustomAmount = m.Settings.DefaultMonthlyDues
			}
		}
	}
	if req.Status == "" {
		req.Status = "ACTIVE"
	}

	memberID := "MEM_" + uuid.New().String()[:8]
	memberCode := "M-" + strconv.FormatInt(time.Now().Unix()%10000, 10)

	member := domain.Member{
		ID:                      memberID,
		MahalID:                 tenantID,
		MemberCode:              memberCode,
		Name:                    req.Name,
		Phone:                   req.Phone,
		Email:                   strings.TrimSpace(req.Email),
		HouseName:               req.HouseName,
		FamilyHead:              req.FamilyHead,
		FamilyMembersCount:      req.FamilyMembersCount,
		MonthlyDuesCustomAmount: req.MonthlyDuesCustomAmount,
		Status:                  req.Status,
		LastPaidMonth:           time.Now().AddDate(0, -1, 0).Format("2006-01"),
		OutstandingBalance:      req.MonthlyDuesCustomAmount,
		Version:                 1,
		CreatedAt:               time.Now().UTC(),
		UpdatedAt:               time.Now().UTC(),
	}

	if err := h.memberRepo.Create(c.Context(), &member); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "MEMBER_CREATED",
			Actor:    "Mahal Administrator",
			EntityID: member.ID,
			Details:  "Registered member " + member.Name + " (" + member.Phone + ")",
		})
	}

	return c.Status(fiber.StatusCreated).JSON(member)
}

func (h *Handler) DeleteMember(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Params("id")

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}

	deleted, err := h.memberRepo.Delete(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if !deleted {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "MEMBER_DELETED",
			Actor:    "Mahal Administrator",
			EntityID: memberID,
			Details:  "Removed member ID: " + memberID,
		})
	}

	return c.JSON(fiber.Map{"status": "DELETED", "member_id": memberID})
}

type UpdateProfileRequest struct {
	Name                    string  `json:"name"`
	Phone                   string  `json:"phone"`
	Address                 string  `json:"address"`
	HouseName               string  `json:"house_name"`
	MonthlyDuesCustomAmount float64 `json:"monthly_dues_custom_amount"`
	Status                  string  `json:"status"`
	FamilyMembersCount      int     `json:"family_members_count"`
	// FamilyHead is a committee field; nil = unchanged.
	FamilyHead *bool `json:"family_head"`
	// Optional personal details: absent = unchanged, "" = cleared.
	Email    *string `json:"email"`
	Address2 *string `json:"address2"`
	City     *string `json:"city"`
	State    *string `json:"state"`
	Pincode  *string `json:"pincode"`
}

// editableMemberStatuses are the statuses the committee sets from a member
// edit form. PENDING_APPROVAL / REJECTED move only via the approval routes.
var editableMemberStatuses = map[string]bool{"ACTIVE": true, "GRACE_PERIOD": true, "SUSPENDED": true, "INACTIVE": true}

func (h *Handler) UpdateMemberProfile(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Params("id"))
	if aerr != nil {
		return aerr.send(c)
	}
	isAdmin := isAdminSession(c)

	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}
	current, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || current == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	// Members may edit their own personal details only. Phone (the login
	// identity), dues amount, status and household size are committee fields.
	updates := bson.M{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.HouseName != "" {
		updates["house_name"] = req.HouseName
	} else if req.Address != "" {
		updates["house_name"] = req.Address
	}
	if aerr := applyPersonalDetails(updates, req); aerr != nil {
		return aerr.send(c)
	}
	if isAdmin {
		if req.Phone != "" && normalizePhoneIN(req.Phone) != current.Phone {
			phone, ok := parseIndianMobile(req.Phone)
			if !ok {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Phone must be a 10-digit Indian mobile number"})
			}
			if phone != current.Phone {
				if other, _ := h.memberRepo.GetByPhone(c.Context(), tenantID, phone); other != nil && other.ID != memberID {
					return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Another member of this Mahal already uses that phone"})
				}
			}
			updates["phone"] = phone
		}
		if req.MonthlyDuesCustomAmount < 0 || req.MonthlyDuesCustomAmount > mahalMaxMonthlyDues {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Monthly dues amount is out of range"})
		}
		if req.MonthlyDuesCustomAmount > 0 {
			updates["monthly_dues_custom_amount"] = req.MonthlyDuesCustomAmount
		}
		if req.Status != "" {
			st := strings.ToUpper(strings.TrimSpace(req.Status))
			if !editableMemberStatuses[st] {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Status must be ACTIVE, GRACE_PERIOD, SUSPENDED or INACTIVE"})
			}
			updates["status"] = st
		}
		if req.FamilyMembersCount < 0 || req.FamilyMembersCount > 100 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Family members count must be between 0 and 100"})
		}
		if req.FamilyMembersCount > 0 {
			updates["family_members_count"] = req.FamilyMembersCount
		}
		if req.FamilyHead != nil {
			updates["family_head"] = *req.FamilyHead
		}
	} else if req.Phone != "" || req.MonthlyDuesCustomAmount > 0 || req.Status != "" || req.FamilyMembersCount > 0 || req.FamilyHead != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Only the committee can change phone, dues, status or family size"})
	}

	if len(updates) > 0 {
		if err := h.memberRepo.UpdateProfile(c.Context(), tenantID, memberID, updates); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	actor := "Member"
	if isAdmin {
		actor = "Mahal Administrator"
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "MEMBER_UPDATED",
			Actor:    actor,
			EntityID: memberID,
			Details:  "Updated profile for member ID: " + memberID,
		})
	}

	resp := fiber.Map{
		"status":     "UPDATED",
		"member_id":  memberID,
		"name":       req.Name,
		"updated_at": time.Now().UTC(),
	}
	if m, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID); err == nil && m != nil {
		resp["member"] = h.profileFor(c.Context(), m)
		resp["name"] = m.Name
	}
	return c.JSON(resp)
}

// -------------------------------------------------------------
// 3. PAYMENTS & RECEIPTS
// -------------------------------------------------------------

type InitDuesRequest struct {
	MemberID       string   `json:"member_id"`
	SelectedMonths []string `json:"selected_months"`
	Gateway        string   `json:"gateway"`
	IdempotencyKey string   `json:"idempotency_key"`
}

func (h *Handler) InitializeDuesPayment(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var req InitDuesRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	memberID, aerr := scopeMember(c, req.MemberID)
	if aerr != nil {
		return aerr.send(c)
	}
	req.MemberID = memberID
	// CASH commits a receipt immediately with no gateway involved: only the
	// committee, who physically received the money, may record it.
	if strings.EqualFold(req.Gateway, "CASH") && !isAdminSession(c) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Cash payments can only be recorded by the committee"})
	}

	if h.paymentService == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment engine offline"})
	}

	txn, err := h.paymentService.InitializeDuesPayment(
		c.Context(),
		tenantID,
		req.MemberID,
		req.SelectedMonths,
		req.Gateway,
		req.IdempotencyKey,
	)
	if err != nil {
		return c.Status(fiber.StatusUnprocessableEntity).JSON(fiber.Map{"error": err.Error()})
	}

	if req.Gateway == "CASH" {
		receipt, commitErr := h.paymentService.CommitSuccessfulPayment(c.Context(), txn.ID)
		if commitErr == nil && receipt != nil {
			if h.auditRepo != nil {
				_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
					MahalID:  receipt.MahalID,
					Action:   "CASH_PAYMENT_COMMITTED",
					Actor:    receipt.MemberName,
					EntityID: receipt.ReceiptNumber,
					Details:  "Paid " + strconv.FormatFloat(receipt.Amount, 'f', 2, 64) + " for months: " + strconv.Itoa(len(receipt.PaidMonths)),
				})
			}
			return c.Status(fiber.StatusCreated).JSON(fiber.Map{
				"transaction_id":   txn.ID,
				"amount":           txn.Amount,
				"currency":         txn.Currency,
				"selected_months":  txn.SelectedMonths,
				"status":           "SUCCESS",
				"receipt":          receipt,
				"gateway_order_id": "order_cash_" + txn.ID[4:12],
			})
		}
	}

	orderID := orderIDForTxn(txn)
	var paymentURL, upiIntentURL string
	if h.pgClient != nil {
		p := h.checkoutParamsForTxn(c.Context(), txn)
		paymentURL = h.signedCheckoutURL(orderID)
		if intentRes, iErr := h.pgClient.GetPaymentRequestIntentURL(c.Context(), p); iErr == nil && intentRes != nil {
			upiIntentURL = intentRes.UPIIntentURL
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"transaction_id":   txn.ID,
		"amount":           txn.Amount,
		"currency":         txn.Currency,
		"selected_months":  txn.SelectedMonths,
		"status":           txn.Status,
		"gateway_order_id": orderID,
		"payment_url":      paymentURL,
		"upi_intent_url":   upiIntentURL,
	})
}

type ConfirmPaymentRequest struct {
	TransactionID string `json:"transaction_id"`
	// GatewayPaymentID is PayU's mihpayid, returned by the mobile SDK on success.
	// Persisted so refunds work later; if empty the server resolves it from PayU.
	GatewayPaymentID string `json:"gateway_payment_id,omitempty"`
}

func (h *Handler) ConfirmPayment(c *fiber.Ctx) error {
	var req ConfirmPaymentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	txn, aerr := h.loadOwnTransaction(c, txnIDFromOrderID(req.TransactionID))
	if aerr != nil {
		return aerr.send(c)
	}
	if h.paymentService == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment engine offline"})
	}

	// The app's word that PayU succeeded is not proof of payment. With a live
	// gateway, commit only once PayU itself reports the transaction successful
	// (gatewayConfirmsSuccess also records PayU's mihpayid and payment mode).
	if txn.Status != domain.TxnSuccess {
		if ok, reason := h.gatewayConfirmsSuccess(c.Context(), txn); !ok {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status": "PENDING",
				"error":  "Payment not yet confirmed by the gateway: " + reason,
			})
		}
		// Simulated gateway: nothing to ask, so keep the SDK's mihpayid.
		if !h.pgClient.Live() && req.GatewayPaymentID != "" && h.txnRepo != nil {
			_ = h.txnRepo.SetPaymentDetails(c.Context(), txn.ID, req.GatewayPaymentID, "")
		}
	}

	receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), txn.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  receipt.MahalID,
			Action:   "PAYMENT_COMMITTED",
			Actor:    receipt.MemberName,
			EntityID: receipt.ReceiptNumber,
			Details:  "Online Payment Confirmed for amount: " + strconv.FormatFloat(receipt.Amount, 'f', 2, 64),
		})
	}

	return c.JSON(fiber.Map{
		"status":  "SUCCESS",
		"receipt": receipt,
	})
}

type InitContributionRequest struct {
	MemberID       string  `json:"member_id"`
	Amount         float64 `json:"amount"`
	Purpose        string  `json:"purpose"`
	Note           string  `json:"note"`
	Gateway        string  `json:"gateway"`
	IdempotencyKey string  `json:"idempotency_key"`
}

func (h *Handler) InitializeContribution(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var req InitContributionRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	memberID, aerr := scopeMember(c, req.MemberID)
	if aerr != nil {
		return aerr.send(c)
	}
	req.MemberID = memberID
	if strings.EqualFold(req.Gateway, "CASH") && !isAdminSession(c) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Cash payments can only be recorded by the committee"})
	}

	if h.paymentService == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment engine offline"})
	}

	txn, err := h.paymentService.InitializeContribution(
		c.Context(),
		tenantID,
		req.MemberID,
		req.Amount,
		req.Gateway,
		req.IdempotencyKey,
		service.ContributionDetails{Purpose: req.Purpose, Note: req.Note},
	)
	if err != nil {
		return c.Status(fiber.StatusUnprocessableEntity).JSON(fiber.Map{"error": err.Error()})
	}

	testMode := os.Getenv("PAYMENT_TEST_MODE")
	if testMode == "ON" || testMode == "true" || testMode == "1" || testMode == "" {
		receipt, commitErr := h.paymentService.CommitSuccessfulPayment(c.Context(), txn.ID)
		if commitErr == nil && receipt != nil {
			if h.auditRepo != nil {
				_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
					MahalID:  receipt.MahalID,
					Action:   "DONATION_COMMITTED_TEST_MODE",
					Actor:    receipt.MemberName,
					EntityID: receipt.ReceiptNumber,
					Details:  "Donation test payment of ₹" + strconv.FormatFloat(receipt.Amount, 'f', 2, 64),
				})
			}
			return c.Status(fiber.StatusCreated).JSON(fiber.Map{
				"transaction_id": txn.ID,
				"amount":         txn.Amount,
				"currency":       txn.Currency,
				"status":         "SUCCESS",
				"receipt":        receipt,
			})
		}
	}

	resp := fiber.Map{
		"transaction_id":   txn.ID,
		"amount":           txn.Amount,
		"currency":         txn.Currency,
		"status":           txn.Status,
		"purpose":          txn.Purpose,
		"gateway_order_id": orderIDForTxn(txn),
	}
	if h.pgClient != nil {
		resp["payment_url"] = h.signedCheckoutURL(orderIDForTxn(txn))
	}
	return c.Status(fiber.StatusCreated).JSON(resp)
}

func (h *Handler) GetMemberReceipts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Query("member_id"))
	if aerr != nil {
		return aerr.send(c)
	}

	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receipts, err := h.receiptRepo.GetByMemberID(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	h.decorateReceipts(c.Context(), tenantID, receipts)
	return c.JSON(fiber.Map{"receipts": receipts, "total": len(receipts)})
}

func (h *Handler) GetReceipt(c *fiber.Ctx) error {
	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receipt, aerr := h.loadOwnReceipt(c, c.Params("number"))
	if aerr != nil {
		return aerr.send(c)
	}
	h.decorateReceipt(c.Context(), receipt)
	return c.JSON(receipt)
}

func (h *Handler) VerifyReceiptIntegrity(c *fiber.Ctx) error {
	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receipt, aerr := h.loadOwnReceipt(c, c.Params("number"))
	if aerr != nil {
		return aerr.send(c)
	}

	recomputed := domain.CalculateReceiptHash(
		receipt.ReceiptNumber,
		receipt.MahalID,
		receipt.MemberID,
		receipt.Amount,
		receipt.PreviousReceiptHash,
	)

	isValid := recomputed == receipt.ReceiptHash

	return c.JSON(fiber.Map{
		"hash_version":          1, // descriptive receipt fields are not hashed
		"receipt_number":        receipt.ReceiptNumber,
		"sequence_number":       receipt.SequenceNumber,
		"stored_hash":           receipt.ReceiptHash,
		"recomputed_hash":       recomputed,
		"cryptographic_valid":   isValid,
		"previous_receipt_hash": receipt.PreviousReceiptHash,
	})
}

// -------------------------------------------------------------
// 4. AUTOPAY MANDATES
// -------------------------------------------------------------

type CreateMandateRequest struct {
	MemberID    string  `json:"member_id"`
	MaxAmount   float64 `json:"max_amount"`
	DebitAmount float64 `json:"debit_amount"` // amount charged each cycle (defaults to MaxAmount)
	Frequency   string  `json:"frequency"`    // HOURLY | DAILY | WEEKLY | MONTHLY (default MONTHLY)
	Mode        string  `json:"mode"`         // UPI | E_NACH | CARD_SI
}

// payUBillingCycle maps our frequency to a PayU SI billingCycle. HOURLY/DAILY
// use ADHOC (merchant-initiated, on-demand up to the max) because UPI AutoPay
// has no sub-daily bank cycle — our own scheduler drives the actual timing.
func payUBillingCycle(freq string) string {
	switch strings.ToUpper(freq) {
	case "MINUTELY", "HOURLY", "DAILY", "ADHOC":
		return "ADHOC"
	case "WEEKLY":
		return "WEEKLY"
	default:
		return "MONTHLY"
	}
}

// advanceDebit returns the next debit time for a frequency, from a base time.
func advanceDebit(freq string, from time.Time) time.Time {
	switch strings.ToUpper(freq) {
	case "MINUTELY":
		return from.Add(time.Minute)
	case "HOURLY":
		return from.Add(time.Hour)
	case "DAILY":
		return from.AddDate(0, 0, 1)
	case "WEEKLY":
		return from.AddDate(0, 0, 7)
	default:
		return from.AddDate(0, 1, 0)
	}
}

// isTestFrequency reports sub-monthly cadences used only for testing, where the
// 48h pre-debit gate is skipped so debits can be exercised immediately.
func isTestFrequency(freq string) bool {
	switch strings.ToUpper(freq) {
	case "MINUTELY", "HOURLY", "DAILY":
		return true
	default:
		return false
	}
}

func (h *Handler) CreateAutoPayMandate(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req CreateMandateRequest
	_ = c.BodyParser(&req)
	memberID, aerr := scopeMember(c, req.MemberID)
	if aerr != nil {
		return aerr.send(c)
	}
	req.MemberID = memberID
	if h.memberRepo != nil {
		if m, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID); err != nil || m == nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
		}
	}

	mandateID := "MND" + strings.ReplaceAll(uuid.New().String(), "-", "")[:16]
	maxAmount := req.MaxAmount
	if maxAmount <= 0 {
		maxAmount = 1000.0
	}
	debitAmount := req.DebitAmount
	if debitAmount <= 0 {
		debitAmount = maxAmount
	}
	frequency := strings.ToUpper(req.Frequency)
	if frequency == "" {
		frequency = "MONTHLY"
	}
	billingCycle := payUBillingCycle(frequency)

	startDate := time.Now().Format("2006-01-02")
	endDate := time.Now().AddDate(3, 0, 0).Format("2006-01-02")

	// PayU SI Standing Instruction specification. billingAmount is the max per
	// debit; billingRule MAX authorizes any amount up to it each cycle.
	siDetailsJSON := fmt.Sprintf(`{"billingAmount":"%.2f","billingCurrency":"INR","billingCycle":"%s","billingInterval":1,"paymentStartDate":"%s","paymentEndDate":"%s","billingRule":"MAX"}`,
		maxAmount, billingCycle, startDate, endDate)

	now := time.Now().UTC()
	mode := req.Mode
	if mode == "" {
		mode = "UPI"
	}
	mandate := &domain.Mandate{
		ID:           mandateID,
		MahalID:      tenantID,
		MemberID:     req.MemberID,
		Status:       "PENDING_AUTHORIZATION",
		MaxAmount:    maxAmount,
		DebitAmount:  debitAmount,
		Frequency:    frequency,
		RecurringDay: 1,
		Mode:         mode,
		SIDetails:    siDetailsJSON,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	var checkoutData *pg.PayUCheckoutFormData
	mandateURL := h.signedCheckoutURL(mandateID)
	if h.pgClient != nil {
		formData := h.pgClient.GeneratePayUCheckoutParams(h.checkoutParamsForMandate(c.Context(), mandate))
		checkoutData = &formData
	}

	// Persist the mandate as PENDING_AUTHORIZATION. It becomes ACTIVE once the
	// member approves the SI at the gateway (see ConfirmAutoPayMandate).
	if h.mandateRepo != nil {
		if err := h.mandateRepo.Create(c.Context(), mandate); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create the mandate"})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"mandate_id":    mandateID,
		"mahal_id":      tenantID,
		"member_id":     req.MemberID,
		"status":        "PENDING_AUTHORIZATION",
		"frequency":     frequency,
		"billing_cycle": billingCycle,
		"recurring_day": 1,
		"max_amount":    maxAmount,
		"debit_amount":  debitAmount,
		"si_details":    siDetailsJSON,
		"mandate_url":   mandateURL,
		"payu_checkout": checkoutData,
	})
}

type ConfirmMandateRequest struct {
	MandateID        string `json:"mandate_id"`
	GatewayPaymentID string `json:"gateway_payment_id,omitempty"` // PayU mihpayid from SI consent
}

// ConfirmAutoPayMandate activates a mandate after the member has approved the SI
// at the gateway. With a live gateway the consent transaction is verified with
// PayU (verify_payment on the mandate id) and PayU's own mihpayid becomes the
// AuthPayUID every recurring debit is charged against; the app-reported id is
// never trusted. With a simulated gateway (no credentials / PAYMENT_TEST_MODE)
// there is nothing to ask, as for dues confirmation.
func (h *Handler) ConfirmAutoPayMandate(c *fiber.Ctx) error {
	if h.mandateRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "AutoPay service offline"})
	}
	var req ConfirmMandateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	mandate, err := h.mandateRepo.GetByID(c.Context(), req.MandateID)
	if err != nil || mandate == nil || !canSeeMemberRecord(c, mandate.MahalID, mandate.MemberID) {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Mandate not found"})
	}
	switch mandate.Status {
	case "ACTIVE":
		resp := fiber.Map{"mandate_id": mandate.ID, "status": "ACTIVE"}
		if mandate.NextDebit != nil {
			resp["next_debit"] = mandate.NextDebit.Format("2006-01-02")
		}
		return c.JSON(resp)
	case "PENDING_AUTHORIZATION":
	default:
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Mandate is " + mandate.Status, "status": mandate.Status})
	}

	var authPayUID string
	if h.pgClient.Live() {
		d, vErr := h.pgClient.VerifyPaymentDetail(c.Context(), mandate.ID)
		if vErr != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
				"error":  "Could not confirm the mandate with the gateway; try again shortly",
				"status": "PENDING_AUTHORIZATION",
			})
		}
		if !strings.EqualFold(d.Status, "success") || d.MihPayID == "" || d.MihPayID == "Not Found" {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"error":          "Mandate not yet authorised at the gateway (status " + d.Status + ")",
				"status":         "PENDING_AUTHORIZATION",
				"gateway_status": d.Status,
			})
		}
		authPayUID = d.MihPayID
		if req.GatewayPaymentID != "" && req.GatewayPaymentID != authPayUID && h.auditRepo != nil {
			_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
				MahalID: mandate.MahalID, Action: "AUTOPAY_MANDATE_ID_MISMATCH", Actor: sessionRole(c), EntityID: mandate.ID,
				Details: "App-reported gateway id ignored; using PayU's verified mihpayid",
			})
		}
	} else {
		authPayUID = req.GatewayPaymentID
		if authPayUID == "" {
			authPayUID = "SIM_" + mandate.ID
		}
	}

	// First debit: for real (monthly/weekly) mandates, align to the recurring
	// day; for test cadences, the next interval from now.
	var next time.Time
	if isTestFrequency(mandate.Frequency) {
		next = time.Now().UTC() // due immediately so the first run-due charges
	} else {
		next = nextMonthlyDebit(mandate.RecurringDay)
	}
	if err := h.mandateRepo.Update(c.Context(), mandate.ID, bson.M{
		"status":       "ACTIVE",
		"auth_payu_id": authPayUID,
		"next_debit":   next,
	}); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not activate the mandate"})
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  mandate.MahalID,
			Action:   "AUTOPAY_MANDATE_ACTIVATED",
			Actor:    "MEMBER",
			EntityID: mandate.ID,
			Details:  fmt.Sprintf("SI mandate active. authpayuid %s, max ₹%.2f, next %s", authPayUID, mandate.MaxAmount, next.Format("2006-01-02")),
		})
	}

	return c.JSON(fiber.Map{
		"mandate_id": mandate.ID,
		"status":     "ACTIVE",
		"next_debit": next.Format("2006-01-02"),
	})
}

func (h *Handler) GetAutoPayStatus(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Query("member_id"))
	if aerr != nil {
		return aerr.send(c)
	}
	if h.mandateRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "AutoPay service offline"})
	}

	mandate, err := h.mandateRepo.GetActiveByMember(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if mandate == nil {
		return c.JSON(fiber.Map{"status": "NONE", "active": false})
	}

	resp := fiber.Map{
		"mandate_id": mandate.ID,
		"status":     mandate.Status,
		"active":     mandate.Status == "ACTIVE",
		"frequency":  mandate.Frequency,
		"amount":     mandate.DebitAmount,
		"max_amount": mandate.MaxAmount,
		"mode":       mandate.Mode,
	}
	if mandate.NextDebit != nil {
		resp["next_debit"] = mandate.NextDebit.Format("2006-01-02")
	}
	if mandate.LastDebitAt != nil {
		resp["last_debit_at"] = mandate.LastDebitAt.Format("2006-01-02")
	}
	return c.JSON(resp)
}

type RegisterTokenRequest struct {
	Token    string `json:"token"`
	MemberID string `json:"member_id"`
	Platform string `json:"platform"`
}

// RegisterDeviceToken binds a device's FCM push token to the tenant/member so
// pushes can target it. The app calls this on every launch and sign-in, so it
// is an idempotent upsert (not audit-logged: that would log every launch).
func (h *Handler) RegisterDeviceToken(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req RegisterTokenRequest
	if err := c.BodyParser(&req); err != nil || strings.TrimSpace(req.Token) == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "token is required"})
	}
	memberID, aerr := scopeMember(c, req.MemberID)
	if aerr != nil {
		return aerr.send(c)
	}
	req.MemberID = memberID
	platform := strings.ToLower(strings.TrimSpace(req.Platform))
	if platform == "" {
		platform = "android"
	}
	if h.deviceTokenRepo != nil {
		if err := h.deviceTokenRepo.Upsert(c.Context(), &repository.DeviceToken{
			Token:    strings.TrimSpace(req.Token),
			MahalID:  tenantID,
			MemberID: strings.TrimSpace(req.MemberID),
			Platform: platform,
		}); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "could not store token"})
		}
	}
	return c.JSON(fiber.Map{"status": "REGISTERED"})
}

type UnregisterTokenRequest struct {
	Token string `json:"token"`
}

// UnregisterDeviceToken stops pushes to a device (called on sign-out).
func (h *Handler) UnregisterDeviceToken(c *fiber.Ctx) error {
	var req UnregisterTokenRequest
	if err := c.BodyParser(&req); err != nil || strings.TrimSpace(req.Token) == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "token is required"})
	}
	if h.deviceTokenRepo != nil {
		if err := h.deviceTokenRepo.Delete(c.Context(), strings.TrimSpace(req.Token)); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "could not remove token"})
		}
	}
	return c.JSON(fiber.Map{"status": "UNREGISTERED"})
}

type CancelMandateRequest struct {
	MandateID string `json:"mandate_id"`
	MemberID  string `json:"member_id"`
	Reason    string `json:"reason"`
}

// CancelAutoPayMandate stops a mandate so the scheduler no longer debits it.
// Sets status CANCELLED (scheduler only charges ACTIVE). Accepts a mandate_id,
// or falls back to the member's active mandate. This is the safety switch for a
// runaway test cadence.
func (h *Handler) CancelAutoPayMandate(c *fiber.Ctx) error {
	if h.mandateRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "AutoPay service offline"})
	}
	tenantID, _ := c.Locals("tenant_id").(string)
	var req CancelMandateRequest
	_ = c.BodyParser(&req)

	var mandate *domain.Mandate
	var err error
	if req.MandateID != "" {
		mandate, err = h.mandateRepo.GetByID(c.Context(), req.MandateID)
	} else {
		memberID, aerr := scopeMember(c, req.MemberID)
		if aerr != nil {
			return aerr.send(c)
		}
		mandate, err = h.mandateRepo.GetActiveByMember(c.Context(), tenantID, memberID)
	}
	if err != nil || mandate == nil || !canSeeMemberRecord(c, mandate.MahalID, mandate.MemberID) {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Mandate not found"})
	}

	_ = h.mandateRepo.Update(c.Context(), mandate.ID, bson.M{
		"status":     "CANCELLED",
		"next_debit": nil,
	})
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  mandate.MahalID,
			Action:   "AUTOPAY_MANDATE_CANCELLED",
			Actor:    sessionRole(c),
			EntityID: mandate.ID,
			Details:  "AutoPay mandate cancelled. Reason: " + req.Reason,
		})
	}
	return c.JSON(fiber.Map{"mandate_id": mandate.ID, "status": "CANCELLED"})
}

// nextMonthlyDebit returns the next occurrence of the given day-of-month, at
// least one day in the future, clamped to valid days in the target month.
func nextMonthlyDebit(day int) time.Time {
	if day < 1 || day > 28 {
		day = 1
	}
	now := time.Now().UTC()
	candidate := time.Date(now.Year(), now.Month(), day, 0, 0, 0, 0, time.UTC)
	if !candidate.After(now) {
		candidate = candidate.AddDate(0, 1, 0)
	}
	return candidate
}

// RunDueAutoPayDebits drives the recurring AutoPay cycle: for every ACTIVE
// mandate due on or before today it sends the pre-debit notification (>=48h
// ahead) and, once notified, charges the installment via PayU si_transaction,
// then commits a receipt and rolls next_debit forward one month. It is
// idempotent per cycle and safe to call repeatedly (from a scheduler or the
// admin endpoint).
func (h *Handler) RunDueAutoPayDebits(c *fiber.Ctx) error {
	summary := h.runDueAutoPayDebits(c.Context())
	return c.JSON(summary)
}

// StartAutoPayScheduler runs the recurring-debit cycle automatically on a fixed
// interval, so AutoPay charges happen without any manual trigger. For test
// mandates the debit cadence is set to this same interval. Runs until ctx is
// cancelled; call once at startup in its own goroutine.
func (h *Handler) StartAutoPayScheduler(ctx context.Context, interval time.Duration) {
	if interval <= 0 {
		return
	}
	h.autoPayEvery = interval
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	// Run once shortly after boot so a due mandate does not wait a full interval.
	first := time.NewTimer(10 * time.Second)
	defer first.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-first.C:
			h.runDueAutoPayDebits(ctx)
		case <-ticker.C:
			h.runDueAutoPayDebits(ctx)
		}
	}
}

func (h *Handler) runDueAutoPayDebits(ctx context.Context) fiber.Map {
	result := fiber.Map{"charged": 0, "notified": 0, "failed": 0, "skipped": 0}
	if h.mandateRepo == nil || h.paymentService == nil || h.pgClient == nil {
		result["error"] = "autopay dependencies unavailable"
		return result
	}

	now := time.Now().UTC()
	// Look one debit-window ahead so pre-debit notifications go out in time.
	dueOrUpcoming, err := h.mandateRepo.FindDue(ctx, now.AddDate(0, 0, 2))
	if err != nil {
		result["error"] = err.Error()
		return result
	}

	charged, notified, failed, skipped := 0, 0, 0, 0
	for i := range dueOrUpcoming {
		m := dueOrUpcoming[i]
		if m.NextDebit == nil || m.AuthPayUID == "" {
			skipped++
			continue
		}
		amount := m.DebitAmount
		if amount <= 0 {
			amount = m.MaxAmount
		}
		amountStr := fmt.Sprintf("%.2f", amount)
		testFreq := isTestFrequency(m.Frequency)

		// Not yet due: for real cadences, pre-notify (>=48h ahead) and wait. For
		// test cadences (minutely/hourly/daily) there is no notification gate — just
		// wait until due.
		if m.NextDebit.After(now) {
			if !testFreq && m.PreDebitSentAt == nil {
				txnid := "SIPD" + strings.ReplaceAll(uuid.New().String(), "-", "")[:12]
				if err := h.pgClient.PreDebitNotify(ctx, m.AuthPayUID, txnid, amountStr); err == nil {
					sent := now
					_ = h.mandateRepo.Update(ctx, m.ID, bson.M{"pre_debit_sent_at": sent})
					notified++
				} else {
					failed++
				}
			} else {
				skipped++
			}
			continue
		}

		// Due now. Real cadences enforce the 48h gap between notification and
		// debit; test cadences skip straight to the charge.
		if !testFreq && (m.PreDebitSentAt == nil || now.Sub(*m.PreDebitSentAt) < 48*time.Hour) {
			if m.PreDebitSentAt == nil {
				txnid := "SIPD" + strings.ReplaceAll(uuid.New().String(), "-", "")[:12]
				if err := h.pgClient.PreDebitNotify(ctx, m.AuthPayUID, txnid, amountStr); err == nil {
					sent := now
					_ = h.mandateRepo.Update(ctx, m.ID, bson.M{"pre_debit_sent_at": sent})
					notified++
				} else {
					failed++
				}
			} else {
				skipped++
			}
			continue
		}

		// Create the installment transaction, then charge it at the gateway.
		txn, iErr := h.paymentService.InitializeContribution(ctx, m.MahalID, m.MemberID, amount, "PAYU", "SI_"+m.ID+"_"+m.NextDebit.Format("20060102150405"),
			service.ContributionDetails{Purpose: "AUTOPAY_DUES"})
		if iErr != nil || txn == nil {
			failed++
			continue
		}

		si, dErr := h.pgClient.RecurringDebit(ctx, m.AuthPayUID, "ORD"+txn.ID, amountStr, "Mahal AutoPay Dues", "Mahal Member", "member@mahalflow.org")
		if dErr != nil || si == nil || !si.Success {
			failed++
			_ = h.txnRepo.UpdateStatus(ctx, txn.ID, domain.TxnFailed, "")
			mahalID, memberID := m.MahalID, m.MemberID
			h.pushAsync(func(ctx context.Context, p *service.PushService) {
				p.SendToMember(ctx, mahalID, memberID, service.PushNotification{
					Kind:  service.PushKindPaymentFailed,
					Title: "AutoPay debit failed",
					Body:  "We could not collect ₹" + amountStr + " via AutoPay. Tap to pay your dues manually.",
				})
			})
			continue
		}

		_ = h.txnRepo.SetPaymentDetails(ctx, txn.ID, si.MihPayID, domain.NormalizePaymentMode(m.Mode))
		if _, cErr := h.paymentService.CommitSuccessfulPayment(ctx, txn.ID); cErr != nil {
			failed++
			continue
		}

		// Test mandates follow the scheduler cadence (e.g. every 3 min) when one
		// is configured; real cadences advance by their frequency.
		var next time.Time
		if testFreq && h.autoPayEvery > 0 {
			next = now.Add(h.autoPayEvery)
		} else {
			next = advanceDebit(m.Frequency, *m.NextDebit)
			// Never schedule the next debit in the past — catch up to just ahead of now.
			if next.Before(now) {
				next = advanceDebit(m.Frequency, now)
			}
		}
		last := now
		_ = h.mandateRepo.Update(ctx, m.ID, bson.M{
			"last_debit_at":     last,
			"next_debit":        next,
			"pre_debit_sent_at": nil,
		})
		if h.auditRepo != nil {
			_ = h.auditRepo.Create(ctx, &domain.AuditLog{
				MahalID:  m.MahalID,
				Action:   "AUTOPAY_DEBIT_EXECUTED",
				Actor:    "SCHEDULER",
				EntityID: m.ID,
				Details:  fmt.Sprintf("AutoPay debit ₹%.2f via SI. txn %s, next %s", amount, txn.ID, next.Format("2006-01-02")),
			})
		}
		charged++
	}

	result["charged"] = charged
	result["notified"] = notified
	result["failed"] = failed
	result["skipped"] = skipped
	result["scanned"] = len(dueOrUpcoming)
	return result
}

// -------------------------------------------------------------
// 5. ADMIN & GOVERNANCE
// -------------------------------------------------------------

func (h *Handler) GetAdminMembers(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	limit, _ := strconv.ParseInt(c.Query("limit", "50"), 10, 64)
	page, _ := strconv.ParseInt(c.Query("page", "1"), 10, 64)
	if limit <= 0 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	skip := (page - 1) * limit

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}

	members, total, err := h.memberRepo.ListByMahal(c.Context(), tenantID, limit, skip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"members": members,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// Complex Structured Member Queries
type MemberQueryFilter struct {
	Status           string   `json:"status"`
	OverdueOnly      bool     `json:"overdue_only"`
	FamilyHeadOnly   bool     `json:"family_head_only"`
	HouseNames       []string `json:"house_names"`
	MinOverdueAmount float64  `json:"min_overdue_amount"`
	Page             int64    `json:"page"`
	Limit            int64    `json:"limit"`
}

func (h *Handler) QueryAdminMembers(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var filter MemberQueryFilter
	if err := c.BodyParser(&filter); err != nil {
		filter = MemberQueryFilter{Page: 1, Limit: 50}
	}
	if filter.Limit <= 0 {
		filter.Limit = 50
	}
	if filter.Page <= 0 {
		pageVal, _ := strconv.ParseInt(c.Query("page", "1"), 10, 64)
		filter.Page = pageVal
	}

	skip := (filter.Page - 1) * filter.Limit
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}

	members, total, err := h.memberRepo.ListByMahal(c.Context(), tenantID, filter.Limit, skip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"protocol":       "HTTP QUERY (RFC 10008)",
		"members":        members,
		"total":          total,
		"applied_filter": filter,
		"page":           filter.Page,
		"limit":          filter.Limit,
	})
}

func (h *Handler) GetMahals(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}

	mahals, err := h.mahalRepo.ListAll(c.Context())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"mahals": mahals, "total": len(mahals)})
}

func (h *Handler) GetMahalByID(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	id := c.Params("id")
	// A Mahal admin may read only their own Mahal; SUPER_ADMIN reads any.
	if tenantID, _ := c.Locals("tenant_id").(string); sessionRole(c) != domain.RoleSuperAdmin && id != tenantID {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Mahal not found"})
	}
	mahal, err := h.mahalRepo.GetByID(c.Context(), id)
	if err != nil || mahal == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Mahal not found"})
	}
	return c.JSON(mahal)
}

func (h *Handler) GetPayments(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	limit, _ := strconv.ParseInt(c.Query("limit", "50"), 10, 64)
	page, _ := strconv.ParseInt(c.Query("page", "1"), 10, 64)
	if limit <= 0 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	skip := (page - 1) * limit

	if h.txnRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Transaction service offline"})
	}

	txns, total, err := h.txnRepo.ListAll(c.Context(), tenantID, limit, skip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	// Each payment carries its member's name so lists need no extra lookups.
	names := h.memberNames(c, tenantID, txns)
	type paymentRow struct {
		domain.Transaction
		MemberName string `json:"member_name"`
	}
	rows := make([]paymentRow, 0, len(txns))
	for _, t := range txns {
		rows = append(rows, paymentRow{Transaction: t, MemberName: names[t.MemberID]})
	}
	return c.JSON(fiber.Map{
		"payments": rows,
		"total":    total,
		"page":     page,
		"limit":    limit,
	})
}

func (h *Handler) GetSubscriptions(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	mahals, err := h.mahalRepo.ListAll(c.Context())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	type SubItem struct {
		MahalID         string                    `json:"mahal_id"`
		MahalName       string                    `json:"mahal_name"`
		Plan            string                    `json:"plan"`
		MonthlyFee      float64                   `json:"monthly_fee"`
		Status          domain.SubscriptionStatus `json:"status"`
		NextBillingDate time.Time                 `json:"next_billing_date"`
	}

	subs := make([]SubItem, 0, len(mahals))
	for _, m := range mahals {
		subs = append(subs, SubItem{
			MahalID:         m.ID,
			MahalName:       m.Name,
			Plan:            m.Subscription.Plan,
			MonthlyFee:      m.Subscription.MonthlyFee,
			Status:          m.Subscription.Status,
			NextBillingDate: m.Subscription.NextBillingDate,
		})
	}

	return c.JSON(fiber.Map{"subscriptions": subs, "total": len(subs)})
}

func (h *Handler) GetRefunds(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.refundRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Refund service offline"})
	}
	refunds, err := h.refundRepo.List(c.Context(), tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"refunds": refunds, "total": len(refunds)})
}

type RefundActionRequest struct {
	Action string  `json:"action"` // APPROVE | REJECT
	Amount float64 `json:"amount,omitempty"`
	Reason string  `json:"reason,omitempty"`
}

func (h *Handler) ProcessRefund(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	refundID := c.Params("id")
	var req RefundActionRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if req.Action != "APPROVE" && req.Action != "REJECT" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "action must be APPROVE or REJECT"})
	}

	if req.Action == "REJECT" {
		if h.refundRepo == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Refund service offline"})
		}
		r, rErr := h.refundRepo.GetByID(c.Context(), refundID)
		if rErr != nil || r == nil || r.MahalID != tenantID {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Refund request not found"})
		}
		if err := h.refundRepo.UpdateStatus(c.Context(), refundID, "REJECTED"); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
		if h.auditRepo != nil {
			_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
				MahalID:  tenantID,
				Action:   "REFUND_REJECTED",
				Actor:    "ADMIN",
				EntityID: refundID,
				Details:  "Refund request rejected. Reason: " + req.Reason,
			})
		}
		return c.JSON(fiber.Map{"status": "REJECTED", "refund_id": refundID})
	}

	// APPROVE: Trigger real programmatic refund via Payment Gateway (Spec Section 7.1)
	// refundID may be either a RefundRequest id or, for a 1-click refund, the
	// transaction id itself.
	txnID := refundID
	amount := req.Amount
	if amount <= 0 {
		amount = 500.0 // Default fallback
	}

	if h.refundRepo != nil {
		if r, rErr := h.refundRepo.GetByID(c.Context(), refundID); rErr == nil && r != nil {
			if r.MahalID != tenantID {
				return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Refund request not found", "status": "FAILED"})
			}
			if r.TransactionID != "" {
				txnID = r.TransactionID
			}
			if r.Amount > 0 {
				amount = r.Amount
			}
		}
	}

	// Load the transaction to resolve mihpayid, the order id and member details.
	var txn *domain.Transaction
	if h.txnRepo != nil {
		txn, _ = h.txnRepo.GetByID(c.Context(), txnID)
	}
	if txn == nil || txn.MahalID != tenantID {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":  "Transaction not found for refund",
			"status": "FAILED",
		})
	}
	if req.Amount <= 0 {
		amount = txn.Amount
	}

	orderID := txn.GatewayOrderID
	if orderID == "" {
		orderID = "ORD" + txn.ID
	}

	// Resolve PayU's mihpayid: persisted at capture, else ask the gateway now.
	mihpayid := txn.GatewayPaymentID
	if mihpayid == "" && h.pgClient != nil {
		if mp, _, vErr := h.pgClient.VerifyPayment(c.Context(), orderID); vErr == nil {
			mihpayid = mp
			_ = h.txnRepo.SetGatewayPaymentID(c.Context(), txn.ID, mihpayid)
		}
	}

	var pgRefund *pg.RefundResponse
	if h.pgClient != nil {
		var err error
		pgRefund, err = h.pgClient.RequestRefund(c.Context(), pg.RefundParams{
			TransactionID:    orderID,
			MihPayID:         mihpayid,
			MerchantRefundID: "MREF_" + txn.ID,
			Amount:           fmt.Sprintf("%.2f", amount),
			Description:      "MahalFlow 1-Click Instant Refund: " + req.Reason,
		})
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
				"error":   "Payment Gateway Refund Failed: " + err.Error(),
				"status":  "FAILED",
				"details": "Gateway rejected refund request",
			})
		}
	}

	refNo := "N/A"
	if pgRefund != nil && pgRefund.RefundRefNo != nil {
		refNo = *pgRefund.RefundRefNo
	}

	// Record the refund as an immutable ledger document (invariant #4: corrections
	// are new REFUND records, not edits to the original transaction/receipt).
	if h.refundRepo != nil {
		now := time.Now().UTC()
		_ = h.refundRepo.Create(c.Context(), &domain.RefundRequest{
			ID:            "RFD_" + refNo,
			MahalID:       txn.MahalID,
			TransactionID: txn.ID,
			MemberID:      txn.MemberID,
			Amount:        amount,
			Reason:        req.Reason,
			Status:        "PROCESSED",
			RequestedAt:   now,
			ProcessedAt:   &now,
		})
		// If refundID referenced an existing pending request, close it too.
		if refundID != txn.ID {
			_ = h.refundRepo.UpdateStatus(c.Context(), refundID, "APPROVED")
		}
	}
	if h.txnRepo != nil {
		_ = h.txnRepo.UpdateStatus(c.Context(), txn.ID, domain.TxnRefunded, refNo)
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "INSTANT_REFUND_EXECUTED",
			Actor:    "ADMIN",
			EntityID: refundID,
			Details:  fmt.Sprintf("Refund of ₹%.2f processed via PG. Gateway Ref: %s, Txn: %s", amount, refNo, txnID),
		})
	}

	return c.JSON(fiber.Map{
		"status":            "APPROVED",
		"refund_id":         refundID,
		"transaction_id":    txnID,
		"amount":            amount,
		"gateway_refund_id": pgRefund,
		"bank_reference_no": refNo,
		"message":           "Instant refund processed successfully via Payment Gateway",
	})
}

// -------------------------------------------------------------
// 5.1 MAHAL QR STANDEE (BharatQR & UPI Engine)
// -------------------------------------------------------------

func (h *Handler) GetMahalQRStandee(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	purpose := c.Query("purpose", "MAHAL_GENERAL_FUND")
	counter := c.Query("counter", "MAIN_GATE_STAND")

	mahalName := "Mahal Treasury"
	if h.mahalRepo != nil && tenantID != "" {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			mahalName = m.Name
		}
	}

	if h.pgClient == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway client offline"})
	}

	qrInfo := h.pgClient.GenerateQRStandee(tenantID, mahalName, 0, purpose, counter)
	return c.JSON(qrInfo)
}

type DynamicQRRequest struct {
	Amount   float64 `json:"amount"`
	Purpose  string  `json:"purpose"`
	Counter  string  `json:"counter"`
	MemberID string  `json:"member_id,omitempty"`
}

func (h *Handler) GenerateDynamicQR(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req DynamicQRRequest
	if err := c.BodyParser(&req); err != nil || req.Amount <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Valid amount > 0 required"})
	}

	mahalName := "Mahal Treasury"
	if h.mahalRepo != nil && tenantID != "" {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			mahalName = m.Name
		}
	}

	if h.pgClient == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway client offline"})
	}

	purpose := req.Purpose
	if purpose == "" {
		purpose = "MAHAL_COLLECTION"
	}
	counter := req.Counter
	if counter == "" {
		counter = "COUNTER_DESK"
	}

	qrInfo := h.pgClient.GenerateQRStandee(tenantID, mahalName, req.Amount, purpose, counter)
	return c.JSON(qrInfo)
}

func (h *Handler) GetAuditLogs(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	limit, _ := strconv.ParseInt(c.Query("limit", "50"), 10, 64)
	page, _ := strconv.ParseInt(c.Query("page", "1"), 10, 64)
	if limit <= 0 {
		limit = 50
	}
	if page <= 0 {
		page = 1
	}
	skip := (page - 1) * limit

	if h.auditRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Audit service offline"})
	}

	logs, total, err := h.auditRepo.List(c.Context(), tenantID, limit, skip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"logs":  logs,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetAlerts serves both views of the tenant's notices.
//
//   - Member view (MEMBER session, or an admin passing ?member_id=): audience
//     filtered for that member, their own dismissals removed, and each alert's
//     status reflecting *their* read state (ACTIVE = unread, ACKNOWLEDGED =
//     read). unread_count is the badge number.
//   - Admin view (admin session, no member_id): the shared alerts as stored.
func (h *Handler) GetAlerts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}

	requested := c.Query("member_id")
	if isAdminSession(c) && requested == "" {
		alerts, err := h.alertRepo.List(c.Context(), tenantID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
		for i := range alerts {
			alerts[i].Type = alerts[i].EffectiveType()
		}
		return c.JSON(fiber.Map{"alerts": alerts, "total": len(alerts)})
	}

	memberID, aerr := scopeMember(c, requested)
	if aerr != nil {
		return aerr.send(c)
	}
	alerts, unread, err := h.memberAlerts(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"alerts": alerts, "total": len(alerts), "unread_count": unread})
}

// memberAlerts returns the alerts one member should see, with Status rewritten
// to that member's read state, and how many are unread.
func (h *Handler) memberAlerts(ctx context.Context, tenantID, memberID string) ([]domain.SystemAlert, int, error) {
	alerts, err := h.alertRepo.List(ctx, tenantID)
	if err != nil {
		return nil, 0, err
	}
	states, err := h.alertRepo.ListMemberStates(ctx, tenantID, memberID)
	if err != nil {
		return nil, 0, err
	}
	var member *domain.Member
	if h.memberRepo != nil {
		member, _ = h.memberRepo.GetByID(ctx, tenantID, memberID)
	}

	out := make([]domain.SystemAlert, 0, len(alerts))
	unread := 0
	for _, a := range alerts {
		if !alertVisibleTo(a, memberID, member) {
			continue
		}
		a.Type = a.EffectiveType()
		// Recipients of a targeted alert are not shown to members.
		a.MemberIDs = nil
		st, has := states[a.ID]
		if has && st.DismissedAt != nil {
			continue
		}
		if has && st.ReadAt != nil {
			a.Status = "ACKNOWLEDGED"
		} else {
			a.Status = "ACTIVE"
			unread++
		}
		out = append(out, a)
	}
	return out, unread, nil
}

// alertVisibleTo applies an alert's audience to one member. Unknown audiences
// are hidden (fail closed) rather than broadcast.
func alertVisibleTo(a domain.SystemAlert, memberID string, member *domain.Member) bool {
	switch a.Audience {
	case "", domain.AudienceAll:
		return true
	case domain.AudienceOverdueOnly:
		// Paid-up members do not get overdue reminders.
		return !(member != nil && member.OutstandingBalance <= 0 && member.Status == "ACTIVE")
	case domain.AudienceFamilyHeads:
		return member == nil || member.FamilyHead
	case domain.AudienceMember:
		for _, id := range a.MemberIDs {
			if id == memberID {
				return true
			}
		}
		return false
	default:
		return false
	}
}

func (h *Handler) visibleAlertIDs(ctx context.Context, tenantID, memberID string) ([]string, error) {
	alerts, _, err := h.memberAlerts(ctx, tenantID, memberID)
	if err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(alerts))
	for _, a := range alerts {
		ids = append(ids, a.ID)
	}
	return ids, nil
}

// AcknowledgeAlert (admin) marks the shared alert read for the whole tenant.
func (h *Handler) AcknowledgeAlert(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	alertID := c.Params("id")
	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}
	ok, err := h.alertRepo.Acknowledge(c.Context(), tenantID, alertID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if !ok {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Alert not found"})
	}
	return c.JSON(fiber.Map{"status": "ACKNOWLEDGED", "alert_id": alertID})
}

// DismissAlert (admin) deletes the shared alert for the whole tenant.
func (h *Handler) DismissAlert(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	alertID := c.Params("id")
	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}
	ok, err := h.alertRepo.Dismiss(c.Context(), tenantID, alertID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if !ok {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Alert not found"})
	}
	return c.JSON(fiber.Map{"status": "DISMISSED", "alert_id": alertID})
}

// memberAlertTarget checks that alertID is an alert this member can see.
func (h *Handler) memberAlertTarget(c *fiber.Ctx) (tenantID, memberID, alertID string, aerr *apiError) {
	tenantID, _ = c.Locals("tenant_id").(string)
	memberID, aerr = scopeMember(c, c.Query("member_id"))
	if aerr != nil {
		return
	}
	if h.alertRepo == nil {
		aerr = &apiError{status: fiber.StatusServiceUnavailable, msg: "Alerts service offline"}
		return
	}
	// Copy: Fiber reuses the request buffer that backs Params once the
	// handler returns.
	alertID = strings.Clone(c.Params("id"))
	a, err := h.alertRepo.GetByID(c.Context(), tenantID, alertID)
	if err != nil || a == nil {
		aerr = errNotFound("Alert not found")
	}
	return
}

// AcknowledgeMemberAlert marks one alert read for the signed-in member only.
func (h *Handler) AcknowledgeMemberAlert(c *fiber.Ctx) error {
	tenantID, memberID, alertID, aerr := h.memberAlertTarget(c)
	if aerr != nil {
		return aerr.send(c)
	}
	if err := h.alertRepo.MarkReadForMember(c.Context(), tenantID, memberID, []string{alertID}); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "ACKNOWLEDGED", "alert_id": alertID})
}

// DismissMemberAlert hides one alert for the signed-in member only.
func (h *Handler) DismissMemberAlert(c *fiber.Ctx) error {
	tenantID, memberID, alertID, aerr := h.memberAlertTarget(c)
	if aerr != nil {
		return aerr.send(c)
	}
	if err := h.alertRepo.DismissForMember(c.Context(), tenantID, memberID, []string{alertID}); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "DISMISSED", "alert_id": alertID})
}

// MarkAllMemberAlertsRead marks every alert the member can see as read.
func (h *Handler) MarkAllMemberAlertsRead(c *fiber.Ctx) error {
	return h.applyToAllMemberAlerts(c, false)
}

// ClearAllMemberAlerts hides every alert the member can currently see.
func (h *Handler) ClearAllMemberAlerts(c *fiber.Ctx) error {
	return h.applyToAllMemberAlerts(c, true)
}

func (h *Handler) applyToAllMemberAlerts(c *fiber.Ctx, dismiss bool) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID, aerr := scopeMember(c, c.Query("member_id"))
	if aerr != nil {
		return aerr.send(c)
	}
	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}
	ids, err := h.visibleAlertIDs(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	status := "ALL_READ"
	if dismiss {
		status = "CLEARED"
		err = h.alertRepo.DismissForMember(c.Context(), tenantID, memberID, ids)
	} else {
		err = h.alertRepo.MarkReadForMember(c.Context(), tenantID, memberID, ids)
	}
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": status, "count": len(ids)})
}

func (h *Handler) ClearAllAlerts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.alertRepo != nil {
		if err := h.alertRepo.ClearAll(c.Context(), tenantID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}
	return c.JSON(fiber.Map{"status": "CLEARED"})
}

func (h *Handler) MarkAllAlertsRead(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.alertRepo != nil {
		if err := h.alertRepo.MarkAllRead(c.Context(), tenantID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}
	return c.JSON(fiber.Map{"status": "ALL_READ"})
}

type CreateAlertRequest struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Severity    string   `json:"severity"`
	Audience    string   `json:"audience"`   // ALL | OVERDUE_ONLY | FAMILY_HEADS | MEMBER
	MemberIDs   []string `json:"member_ids"` // MEMBER audience recipients
	Type        string   `json:"type"`       // domain.AlertType*; default by audience
}

// MaxAlertRecipients caps a MEMBER-audience alert.
const MaxAlertRecipients = 500

func (h *Handler) CreateAlert(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req CreateAlertRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	req.Title, req.Description = strings.TrimSpace(req.Title), strings.TrimSpace(req.Description)
	if req.Title == "" || req.Description == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Title and description are required"})
	}
	req.Severity = strings.ToUpper(strings.TrimSpace(req.Severity))
	switch req.Severity {
	case "":
		req.Severity = "INFO"
	case "INFO", "WARNING", "CRITICAL":
	default:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "severity must be INFO, WARNING or CRITICAL"})
	}
	req.Audience = strings.ToUpper(strings.TrimSpace(req.Audience))
	if req.Audience == "" {
		req.Audience = domain.AudienceAll
	}
	var recipients []string
	switch req.Audience {
	case domain.AudienceAll, domain.AudienceOverdueOnly, domain.AudienceFamilyHeads:
		if len(req.MemberIDs) > 0 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "member_ids is only allowed with audience MEMBER"})
		}
	case domain.AudienceMember:
		ids, aerr := h.validateRecipients(c.Context(), tenantID, req.MemberIDs)
		if aerr != nil {
			return aerr.send(c)
		}
		recipients = ids
	default:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "audience must be ALL, OVERDUE_ONLY, FAMILY_HEADS or MEMBER"})
	}
	req.Type = strings.ToUpper(strings.TrimSpace(req.Type))
	switch {
	case req.Type == "" && req.Audience == domain.AudienceOverdueOnly:
		req.Type = domain.AlertTypeDuesReminder
	case req.Type == "":
		req.Type = domain.AlertTypeAnnouncement
	case !domain.ValidAlertType(req.Type):
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "type must be DUES_REMINDER, PAYMENT_RECEIVED, ANNOUNCEMENT, EVENT or GENERAL"})
	}

	title := req.Title
	if req.Audience == domain.AudienceOverdueOnly && !strings.Contains(title, "[Dues Reminder]") {
		title = "[Dues Reminder] " + title
	}

	alert := domain.SystemAlert{
		ID:          "ALT_" + uuid.New().String()[:8],
		MahalID:     tenantID,
		Audience:    req.Audience,
		MemberIDs:   recipients,
		Type:        req.Type,
		Title:       title,
		Description: req.Description,
		Severity:    req.Severity,
		Status:      "ACTIVE",
		CreatedAt:   time.Now().UTC(),
	}
	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}
	if err := h.alertRepo.Create(c.Context(), &alert); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	if h.auditRepo != nil {
		target := req.Audience
		if req.Audience == domain.AudienceMember {
			target = fmt.Sprintf("MEMBER (%d)", len(recipients))
		}
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "ALERT_BROADCAST",
			Actor:    "Mahal Administrator",
			EntityID: alert.ID,
			Details:  "Notice (" + req.Type + ") sent to audience: " + target + " (Title: " + req.Title + ")",
		})
	}

	h.pushAsync(func(ctx context.Context, p *service.PushService) {
		n := service.PushNotification{
			Kind:  pushKindForAlert(alert.Type),
			Title: alert.Title,
			Body:  alert.Description,
			Data:  map[string]string{"alert_id": alert.ID, "severity": alert.Severity, "alert_type": alert.Type},
		}
		switch req.Audience {
		case domain.AudienceMember:
			p.SendToMembers(ctx, tenantID, recipients, n)
		case domain.AudienceOverdueOnly:
			if h.memberRepo == nil {
				return
			}
			overdue, err := h.memberRepo.GetOverdueMembers(ctx, tenantID)
			if err != nil {
				return
			}
			ids := make([]string, 0, len(overdue))
			for _, m := range overdue {
				ids = append(ids, m.ID)
			}
			p.SendToMembers(ctx, tenantID, ids, n)
		case domain.AudienceFamilyHeads:
			if h.memberRepo == nil {
				return
			}
			members, _, err := h.memberRepo.ListByMahal(ctx, tenantID, 0, 0)
			if err != nil {
				return
			}
			var ids []string
			for _, m := range members {
				if m.FamilyHead {
					ids = append(ids, m.ID)
				}
			}
			p.SendToMembers(ctx, tenantID, ids, n)
		case domain.AudienceAll:
			p.SendToMahal(ctx, tenantID, n)
		}
	})

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":     "CREATED",
		"alert":      alert,
		"audience":   req.Audience,
		"recipients": len(recipients),
	})
}

// validateRecipients checks a MEMBER-audience recipient list: non-empty,
// capped, de-duplicated, and every id a member of this tenant.
func (h *Handler) validateRecipients(ctx context.Context, tenantID string, ids []string) ([]string, *apiError) {
	seen := map[string]bool{}
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		id = strings.TrimSpace(id)
		if id != "" && !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	if len(out) == 0 {
		return nil, errBadRequest("member_ids is required for audience MEMBER")
	}
	if len(out) > MaxAlertRecipients {
		return nil, errBadRequest(fmt.Sprintf("at most %d member_ids per notice", MaxAlertRecipients))
	}
	if h.memberRepo == nil {
		return nil, &apiError{status: fiber.StatusServiceUnavailable, msg: "Member service offline"}
	}
	var unknown []string
	for _, id := range out {
		if m, err := h.memberRepo.GetByID(ctx, tenantID, id); err != nil || m == nil {
			unknown = append(unknown, id)
		}
	}
	if len(unknown) > 0 {
		return nil, errBadRequest("unknown member_ids: " + strings.Join(unknown, ", "))
	}
	return out, nil
}

func pushKindForAlert(alertType string) string {
	switch alertType {
	case domain.AlertTypeDuesReminder:
		return service.PushKindDuesReminder
	case domain.AlertTypePaymentReceived:
		return service.PushKindReceipt
	default:
		return service.PushKindAlert
	}
}

// NotifyReceiptAlert records a PAYMENT_RECEIVED notice for the member who was
// just issued receipt r (registered as a post-commit receipt hook). The id is
// derived from the receipt, so a repeated hook cannot create duplicates.
func (h *Handler) NotifyReceiptAlert(ctx context.Context, r *domain.Receipt) {
	if h.alertRepo == nil || r == nil {
		return
	}
	title := "Payment received"
	desc := fmt.Sprintf("We received ₹%.2f. Receipt %s.", r.Amount, r.ReceiptNumber)
	if r.PaymentType == "MONTHLY_DUES" && len(r.PaidMonths) > 0 {
		desc = fmt.Sprintf("We received ₹%.2f for %s. Receipt %s.", r.Amount, strings.Join(r.PaidMonths, ", "), r.ReceiptNumber)
	} else if r.Fund != "" {
		desc = fmt.Sprintf("We received your contribution of ₹%.2f (%s). Receipt %s.", r.Amount, r.Fund, r.ReceiptNumber)
	}
	_ = h.alertRepo.Create(ctx, &domain.SystemAlert{
		ID:          "ALT_RCPT_" + r.ReceiptNumber,
		MahalID:     r.MahalID,
		Audience:    domain.AudienceMember,
		MemberIDs:   []string{r.MemberID},
		Type:        domain.AlertTypePaymentReceived,
		Severity:    "INFO",
		Title:       title,
		Description: desc,
		Status:      "ACTIVE",
		CreatedAt:   time.Now().UTC(),
	})
}

// -------------------------------------------------------------
// 6. EXCEL INGESTION & BATCH JOBS
// -------------------------------------------------------------

// -------------------------------------------------------------
// 7. WEBHOOKS
// -------------------------------------------------------------

func (h *Handler) HandleRazorpayWebhook(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "PROCESSED", "acknowledged": true})
}

// HandlePGWebhook processes server-to-server callbacks from Payment Gateway (Spec v2.0 Section 12)
func (h *Handler) HandlePGWebhook(c *fiber.Ctx) error {
	// 1. Extract params from JSON or Form Post
	params := make(map[string]string)
	if strings.Contains(c.Get("Content-Type"), "application/json") {
		var jsonMap map[string]interface{}
		if err := c.BodyParser(&jsonMap); err == nil {
			for k, v := range jsonMap {
				if strVal, ok := v.(string); ok {
					params[k] = strVal
				} else if numVal, ok := v.(float64); ok {
					params[k] = fmt.Sprintf("%.0f", numVal)
				}
			}
		}
	} else {
		// Form POST
		c.Context().PostArgs().VisitAll(func(key, val []byte) {
			params[string(key)] = string(val)
		})
	}

	orderID := params["order_id"]
	if orderID == "" {
		orderID = params["txnid"]
	}
	transactionID := params["transaction_id"]
	if transactionID == "" {
		transactionID = params["mihpayid"]
	}
	respCodeStr := params["response_code"]
	receivedHash := params["hash"]
	status := strings.ToLower(params["status"])
	udf1 := params["udf1"]

	// Determine internal transaction ID
	txnID := udf1
	if txnID == "" {
		txnID = txnIDFromOrderID(orderID)
	}

	// 2. Verify the SHA-512 response hash. A callback without a hash, or on a
	// server with no salt configured, is never trusted to commit a payment.
	hashVerified := false
	if h.pgClient != nil && h.pgClient.Salt != "" && receivedHash != "" {
		if !pg.VerifyResponseHash(params, h.pgClient.Salt, receivedHash) {
			if h.alertRepo != nil {
				_ = h.alertRepo.Create(c.Context(), &domain.SystemAlert{
					ID:          "ALT_" + uuid.New().String()[:8],
					MahalID:     "SYSTEM",
					Severity:    "CRITICAL",
					Title:       "PG Webhook Hash Mismatch Detected",
					Description: fmt.Sprintf("Invalid signature for Order: %s, Txn: %s", orderID, transactionID),
					Status:      "ACTIVE",
					CreatedAt:   time.Now().UTC(),
				})
			}
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid signature hash"})
		}
		hashVerified = true
	}

	// Defence in depth: even a correctly signed callback is confirmed with the
	// gateway before money is booked (hashes can be replayed or, via the SDK
	// hash endpoint, derived).
	var webhookTxn *domain.Transaction
	if hashVerified && h.txnRepo != nil && txnID != "" {
		webhookTxn, _ = h.txnRepo.GetByID(c.Context(), txnID)
	}
	gatewayOK := false
	if webhookTxn != nil {
		if webhookTxn.Status == domain.TxnSuccess {
			gatewayOK = true
		} else {
			gatewayOK, _ = h.gatewayConfirmsSuccess(c.Context(), webhookTxn)
		}
	}

	// 3. Check response code (0 = SUCCESS or PayU status == "success")
	if respCodeStr == "0" || status == "success" || params["response_message"] == "SUCCESS" || params["response_message"] == "success" {
		if h.paymentService != nil && gatewayOK {
			receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), txnID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
			}

			// Persist PayU's mihpayid from the webhook so refunds work later.
			if h.txnRepo != nil {
				_ = h.txnRepo.SetPaymentDetails(c.Context(), txnID, params["mihpayid"], domain.NormalizePaymentMode(params["mode"]))
			}

			if h.auditRepo != nil && receipt != nil {
				_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
					MahalID:  receipt.MahalID,
					Action:   "PG_WEBHOOK_PAYMENT_COMMITTED",
					Actor:    "PG_GATEWAY_WEBHOOK",
					EntityID: receipt.ReceiptNumber,
					Details:  fmt.Sprintf("Verified webhook for Order %s, PG Txn %s, Amount: ₹%.2f", orderID, transactionID, receipt.Amount),
				})
			}

			// If called via browser redirect from PayU, return friendly HTML receipt confirmation
			if strings.Contains(c.Get("Accept"), "text/html") {
				c.Set("Content-Type", "text/html")
				html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><title>Payment Successful</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="font-family:sans-serif;text-align:center;padding:40px;background:#f0fdf4;">
  <div style="max-width:400px;margin:auto;background:white;padding:30px;border-radius:12px;box-shadow:0 4px 6px rgba(0,0,0,0.05);">
    <h2 style="color:#16a34a;margin-top:0;">Payment Received!</h2>
    <p>Receipt: <b>%s</b></p>
    <p>Amount: <b>₹%.2f</b></p>
    <p style="color:#666;font-size:13px;">You may return to the MahalFlow app.</p>
  </div>
</body>
</html>`, receipt.ReceiptNumber, receipt.Amount)
				return c.SendString(html)
			}

			return c.JSON(fiber.Map{
				"status":         "SUCCESS",
				"receipt_number": receipt.ReceiptNumber,
				"acknowledged":   true,
			})
		}
	}

	if strings.Contains(c.Get("Accept"), "text/html") {
		c.Set("Content-Type", "text/html")
		return c.SendString(`<!DOCTYPE html><html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#fef2f2;">
<h2 style="color:#dc2626;">Payment Failed or Cancelled</h2><p>Please return to app and retry.</p></body></html>`)
	}

	return c.JSON(fiber.Map{
		"status":       "FAILED_OR_IGNORED",
		"code":         respCodeStr,
		"acknowledged": true,
	})
}

// VerifyPGPaymentStatus reconciles one transaction with PayU (verify_payment)
// and commits it when PayU reports success. :id is the transaction id or its
// PayU order id ("ORD"/"ORD_" prefixed).
func (h *Handler) VerifyPGPaymentStatus(c *fiber.Ctx) error {
	txn, aerr := h.loadOwnTransaction(c, txnIDFromOrderID(c.Params("id")))
	if aerr != nil {
		return aerr.send(c)
	}
	resp := fiber.Map{"transaction_id": txn.ID, "pg_transaction_id": txn.GatewayPaymentID}

	switch txn.Status {
	case domain.TxnSuccess:
		resp["status"], resp["gateway_status"] = "SUCCESS", "success"
		if h.receiptRepo != nil && txn.ReceiptID != "" {
			if r, _ := h.receiptRepo.GetByNumberForMahal(c.Context(), txn.MahalID, txn.ReceiptID); r != nil {
				h.decorateReceipt(c.Context(), r)
				resp["receipt"] = r
			}
		}
		return c.JSON(resp)
	case domain.TxnRefunded:
		resp["status"], resp["gateway_status"] = "REFUNDED", "refunded"
		return c.JSON(resp)
	}
	if h.pgClient == nil || h.paymentService == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway client unavailable"})
	}
	if strings.EqualFold(txn.Gateway, "CASH") {
		resp["status"], resp["gateway_status"] = "PENDING", "cash"
		return c.JSON(resp)
	}

	gatewayStatus := "success" // simulated gateway: nothing to ask
	if h.pgClient.Live() {
		d, err := h.pgClient.VerifyPaymentDetail(c.Context(), orderIDForTxn(txn))
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "Could not reach the payment gateway", "status": "PENDING"})
		}
		gatewayStatus = strings.ToLower(strings.TrimSpace(d.Status))
		if gatewayStatus == "success" && h.txnRepo != nil {
			_ = h.txnRepo.SetPaymentDetails(c.Context(), txn.ID, d.MihPayID, domain.NormalizePaymentMode(d.Mode))
			resp["pg_transaction_id"] = d.MihPayID
		}
	}
	resp["gateway_status"] = gatewayStatus

	switch classifyGatewayStatus(gatewayStatus) {
	case "SUCCESS":
		receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), txn.ID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
		resp["status"], resp["receipt"] = "SUCCESS", receipt
	case "FAILED":
		if h.txnRepo != nil {
			_ = h.txnRepo.UpdateStatus(c.Context(), txn.ID, domain.TxnFailed, "")
		}
		resp["status"] = "FAILED"
	default:
		resp["status"] = "PENDING"
	}
	return c.JSON(resp)
}

// classifyGatewayStatus maps PayU's verify_payment status to ours.
func classifyGatewayStatus(s string) string {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "success", "captured":
		return "SUCCESS"
	case "failure", "failed", "dropped", "bounced", "usercancelled", "cancelled", "user_cancelled":
		return "FAILED"
	default: // pending, in progress, not found (not yet submitted)
		return "PENDING"
	}
}

// GetPayUCheckoutData returns PayU parameters and SHA-512 hash as JSON for
// frontend/mobile SDK. The order id may be ORD/ORD_-prefixed or a mandate id;
// the response always uses the canonical PayU txnid.
func (h *Handler) GetPayUCheckoutData(c *fiber.Ctx) error {
	if h.pgClient == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway client unavailable"})
	}
	params, aerr := h.loadOwnPayable(c, c.Params("orderId"))
	if aerr != nil {
		return aerr.send(c)
	}
	return c.JSON(h.pgClient.GeneratePayUCheckoutParams(params))
}

type PayUHashRequest struct {
	HashName   string `json:"hash_name"`
	HashString string `json:"hash_string"`
	HashType   string `json:"hash_type"`
	PostSalt   string `json:"post_salt"`
	// TxnID is the order / mandate id being paid (optional for V1 hashes,
	// required for V2).
	TxnID string `json:"txnid"`
}

// GeneratePayUDynamicHash answers the PayU CheckoutPro SDK's hash requests,
// but only for strings authorizeHashRequest accepts (the caller's own
// payment, allowlisted SDK commands). It is not a general signing service.
func (h *Handler) GeneratePayUDynamicHash(c *fiber.Ctx) error {
	var req PayUHashRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	if h.pgClient == nil || h.pgClient.APIKey == "" {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway not configured"})
	}
	if aerr := h.authorizeHashRequest(c, req); aerr != nil {
		return aerr.send(c)
	}
	return c.JSON(fiber.Map{
		"hash_name": req.HashName,
		"hash":      h.pgClient.GenerateDynamicHash(req.HashName, req.HashString, req.HashType, req.PostSalt),
	})
}

// RenderPayUCheckoutPage auto-submits an HTML form into PayU. It is public
// (opened in a browser / webview without the app's bearer token), so it
// requires the short-lived signature from signedCheckoutURL and shows no more
// of the payer than PayU needs: first name only, placeholder email.
func (h *Handler) RenderPayUCheckoutPage(c *fiber.Ctx) error {
	orderID := strings.Clone(strings.TrimSpace(c.Params("orderId")))
	if orderID == "" {
		return c.Status(fiber.StatusBadRequest).SendString("Missing orderId")
	}
	if !validCheckoutSignature(orderID, c.Query("exp"), c.Query("sig"), time.Now()) {
		return c.Status(fiber.StatusForbidden).SendString("This payment link is invalid or has expired. Return to the app and try again.")
	}
	if h.pgClient == nil {
		return c.Status(fiber.StatusServiceUnavailable).SendString("Payment gateway unavailable")
	}

	var p pg.PaymentRequestParams
	if isMandateID(orderID) {
		if h.mandateRepo == nil {
			return c.Status(fiber.StatusServiceUnavailable).SendString("AutoPay unavailable")
		}
		m, err := h.mandateRepo.GetByID(c.Context(), orderID)
		if err != nil || m == nil {
			return c.Status(fiber.StatusNotFound).SendString("Mandate not found")
		}
		if m.Status != "PENDING_AUTHORIZATION" {
			return c.Status(fiber.StatusConflict).SendString("This mandate is already " + m.Status)
		}
		p = h.checkoutParamsForMandate(c.Context(), m)
	} else {
		if h.txnRepo == nil {
			return c.Status(fiber.StatusServiceUnavailable).SendString("Payments unavailable")
		}
		txn, err := h.txnRepo.GetByID(c.Context(), txnIDFromOrderID(orderID))
		if err != nil || txn == nil {
			return c.Status(fiber.StatusNotFound).SendString("Transaction not found")
		}
		if txn.Status == domain.TxnSuccess || txn.Status == domain.TxnRefunded {
			return c.Status(fiber.StatusConflict).SendString("This payment is already complete")
		}
		p = h.checkoutParamsForTxn(c.Context(), txn)
	}
	p.Name = firstName(p.Name)
	p.Email = defaultPayerEmail

	formData := h.pgClient.GeneratePayUCheckoutParams(p)

	c.Set("Content-Type", "text/html; charset=utf-8")
	c.Set("Cache-Control", "no-store")
	c.Set("Referrer-Policy", "no-referrer")
	var inputs strings.Builder
	for k, v := range formData.Params {
		inputs.WriteString(fmt.Sprintf(`<input type="hidden" name="%s" value="%s" />`, html.EscapeString(k), html.EscapeString(v)))
	}

	page := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Redirecting to PayU Checkout...</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f8fafc; color: #1e293b; }
    .card { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 90%%; }
    .spinner { border: 4px solid #f3f4f6; border-top: 4px solid #10b981; border-radius: 50%%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 1rem; }
    @keyframes spin { 0%% { transform: rotate(0deg); } 100%% { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="spinner"></div>
    <h3 style="margin: 0 0 0.5rem;">Connecting to PayU...</h3>
    <p style="color: #64748b; font-size: 0.9rem; margin: 0 0 1.5rem;">Please do not refresh or press back.</p>
    <form id="payuform" action="%s" method="POST">
      %s
      <noscript><button type="submit" style="background: #10b981; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer;">Click here to proceed</button></noscript>
    </form>
  </div>
  <script>document.getElementById("payuform").submit();</script>
</body>
</html>`, html.EscapeString(formData.Action), inputs.String())

	return c.SendString(page)
}

// loadOwnTransaction loads a transaction the caller may act on: same tenant,
// and for a MEMBER session their own. Anything else is "not found".
func (h *Handler) loadOwnTransaction(c *fiber.Ctx, txnID string) (*domain.Transaction, *apiError) {
	if h.txnRepo == nil {
		return nil, &apiError{status: fiber.StatusServiceUnavailable, msg: "Transaction service offline"}
	}
	if strings.TrimSpace(txnID) == "" {
		return nil, errBadRequest("transaction_id is required")
	}
	txn, err := h.txnRepo.GetByID(c.Context(), txnID)
	if err != nil || txn == nil || !canSeeMemberRecord(c, txn.MahalID, txn.MemberID) {
		return nil, errNotFound("Transaction not found")
	}
	return txn, nil
}

// loadOwnReceipt loads a receipt by number within the request tenant; a
// MEMBER session only sees their own receipts.
func (h *Handler) loadOwnReceipt(c *fiber.Ctx, number string) (*domain.Receipt, *apiError) {
	tenantID, _ := c.Locals("tenant_id").(string)
	receipt, err := h.receiptRepo.GetByNumberForMahal(c.Context(), tenantID, number)
	if err != nil || receipt == nil || !canSeeMemberRecord(c, receipt.MahalID, receipt.MemberID) {
		return nil, errNotFound("Receipt not found")
	}
	return receipt, nil
}

// gatewayConfirmsSuccess asks PayU whether txn was actually paid, and on
// success records PayU's mihpayid and payment mode on the transaction (so the
// receipt carries the method). Without a live gateway (no key, or
// PAYMENT_TEST_MODE) there is nothing to ask and the existing test behaviour
// is kept.
func (h *Handler) gatewayConfirmsSuccess(ctx context.Context, txn *domain.Transaction) (bool, string) {
	if !h.pgClient.Live() {
		return true, ""
	}
	if strings.EqualFold(txn.Gateway, "CASH") {
		return false, "cash payments are committed by the committee"
	}
	d, err := h.pgClient.VerifyPaymentDetail(ctx, orderIDForTxn(txn))
	if err != nil {
		return false, "verification unavailable"
	}
	if !strings.EqualFold(d.Status, "success") {
		return false, "gateway status " + d.Status
	}
	if h.txnRepo != nil {
		_ = h.txnRepo.SetPaymentDetails(ctx, txn.ID, d.MihPayID, domain.NormalizePaymentMode(d.Mode))
	}
	return true, ""
}
