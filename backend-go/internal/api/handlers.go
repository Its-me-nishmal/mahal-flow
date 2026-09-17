package api

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
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
	pgClient       *pg.Client
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
		pgClient:       pgc,
	}
}

// -------------------------------------------------------------
// 1. AUTHENTICATION & PROFILE
// -------------------------------------------------------------

type LoginRequest struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
	MahalID  string `json:"mahal_id"`
}

func (h *Handler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if strings.TrimSpace(req.Phone) == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Phone number is required"})
	}

	mahalID := req.MahalID
	if mahalID == "" {
		mahalID = c.Get("X-Tenant-ID")
	}
	if mahalID == "" {
		mahalID = "MH_001_CALICUT"
	}

	role := "MAHAL_ADMIN"
	userID := "USR_ADMIN_" + uuid.New().String()[:8]

	token, err := GenerateJWT(userID, req.Phone, role, mahalID, 24*time.Hour)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to generate authentication token"})
	}

	return c.JSON(fiber.Map{
		"token":      token,
		"role":       role,
		"phone":      req.Phone,
		"mahal_id":   mahalID,
		"expires_in": 86400,
	})
}

func (h *Handler) GetCurrentUser(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	userID, _ := c.Locals("user_id").(string)
	userRole, _ := c.Locals("user_role").(string)
	if userID == "" {
		userID = "USR_ADMIN_01"
	}
	if userRole == "" {
		userRole = "MAHAL_ADMIN"
	}

	mahalName := "Mahal Administration"
	if h.mahalRepo != nil && tenantID != "" {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			mahalName = m.Name
		}
	}

	return c.JSON(fiber.Map{
		"user_id":    userID,
		"name":       "Admin - " + mahalName,
		"role":       userRole,
		"mahal_id":   tenantID,
		"mahal_name": mahalName,
		"status":     "ACTIVE",
	})
}

// -------------------------------------------------------------
// 2. MEMBER OPERATIONS
// -------------------------------------------------------------

func (h *Handler) GetMemberDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Query("member_id", "MEM_001_9910")

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Database service unavailable"})
	}

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || member == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	mahalName := "Mahal Organization"
	if h.mahalRepo != nil {
		if mahal, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && mahal != nil {
			mahalName = mahal.Name
		}
	}

	var latestReceipt *domain.Receipt
	if h.receiptRepo != nil {
		latestReceipt, _ = h.receiptRepo.GetLatestReceipt(c.Context(), tenantID)
	}

	outstanding := member.OutstandingBalance
	advanceCredit := 0.0
	if outstanding < 0 {
		advanceCredit = -outstanding
		outstanding = 0
	}

	return c.JSON(fiber.Map{
		"member_id":           member.ID,
		"member_name":         member.Name,
		"mahal_name":          mahalName,
		"outstanding_balance": outstanding,
		"advance_credit":      advanceCredit,
		"last_paid_month":     member.LastPaidMonth,
		"latest_payment":      latestReceipt,
	})
}

func (h *Handler) GetMemberProfile(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Params("id", "MEM_001_9910")

	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Database service unavailable"})
	}

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || member == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}
	return c.JSON(member)
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

	if req.MonthlyDuesCustomAmount <= 0 {
		req.MonthlyDuesCustomAmount = 500.0
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

	if err := h.memberRepo.Delete(c.Context(), tenantID, memberID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
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
	Email                   string  `json:"email"`
	Address                 string  `json:"address"`
	HouseName               string  `json:"house_name"`
	MonthlyDuesCustomAmount float64 `json:"monthly_dues_custom_amount"`
	Status                  string  `json:"status"`
	FamilyMembersCount      int     `json:"family_members_count"`
	City                    string  `json:"city"`
	State                   string  `json:"state"`
	Pincode                 string  `json:"pincode"`
}

func (h *Handler) UpdateMemberProfile(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Params("id")
	if memberID == "" {
		memberID = "MEM_001_9910"
	}

	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	updates := bson.M{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Phone != "" {
		updates["phone"] = req.Phone
	}
	if req.HouseName != "" {
		updates["house_name"] = req.HouseName
	} else if req.Address != "" {
		updates["house_name"] = req.Address
	}
	if req.MonthlyDuesCustomAmount > 0 {
		updates["monthly_dues_custom_amount"] = req.MonthlyDuesCustomAmount
	}
	if req.Status != "" {
		updates["status"] = req.Status
	}
	if req.FamilyMembersCount > 0 {
		updates["family_members_count"] = req.FamilyMembersCount
	}

	if h.memberRepo != nil && len(updates) > 0 {
		if err := h.memberRepo.UpdateProfile(c.Context(), tenantID, memberID, updates); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "MEMBER_UPDATED",
			Actor:    "Mahal Administrator",
			EntityID: memberID,
			Details:  "Updated profile for member ID: " + memberID,
		})
	}

	return c.JSON(fiber.Map{
		"status":     "UPDATED",
		"member_id":  memberID,
		"name":       req.Name,
		"updated_at": time.Now().UTC(),
	})
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

	orderID := "ORD" + txn.ID
	var paymentURL, upiIntentURL string
	if h.pgClient != nil {
		memberName := "Mahal Member"
		memberEmail := "member@mahalflow.org"
		memberPhone := "9900990099"
		if h.memberRepo != nil {
			if m, mErr := h.memberRepo.GetByID(c.Context(), tenantID, req.MemberID); mErr == nil && m != nil {
				if m.Name != "" {
					memberName = m.Name
				}
				if m.Phone != "" {
					memberPhone = m.Phone
				}
			}
		}

		p := pg.PaymentRequestParams{
			OrderID:     orderID,
			Amount:      fmt.Sprintf("%.2f", txn.Amount),
			Currency:    txn.Currency,
			Description: fmt.Sprintf("Mahal Dues for %s (%d months)", memberName, len(txn.SelectedMonths)),
			Name:        memberName,
			Email:       memberEmail,
			Phone:       memberPhone,
			UDF1:        txn.ID,
			UDF2:        tenantID,
			UDF3:        req.MemberID,
		}

		if urlRes, uErr := h.pgClient.GetPaymentRequestURL(c.Context(), p); uErr == nil && urlRes != nil {
			paymentURL = urlRes.URL
		}
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
}

func (h *Handler) ConfirmPayment(c *fiber.Ctx) error {
	var req ConfirmPaymentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if h.paymentService == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment engine offline"})
	}

	receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), req.TransactionID)
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
	Gateway        string  `json:"gateway"`
	IdempotencyKey string  `json:"idempotency_key"`
}

func (h *Handler) InitializeContribution(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var req InitContributionRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
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

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"transaction_id": txn.ID,
		"amount":         txn.Amount,
		"currency":       txn.Currency,
		"status":         txn.Status,
	})
}

func (h *Handler) GetMemberReceipts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Query("member_id", "MEM_001_9910")

	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receipts, err := h.receiptRepo.GetByMemberID(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"receipts": receipts, "total": len(receipts)})
}

func (h *Handler) GetReceipt(c *fiber.Ctx) error {
	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receiptNumber := c.Params("number")
	receipt, err := h.receiptRepo.GetByNumber(c.Context(), receiptNumber)
	if err != nil || receipt == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Receipt not found"})
	}

	return c.JSON(receipt)
}

func (h *Handler) VerifyReceiptIntegrity(c *fiber.Ctx) error {
	if h.receiptRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Receipt service offline"})
	}

	receiptNumber := c.Params("number")
	receipt, err := h.receiptRepo.GetByNumber(c.Context(), receiptNumber)
	if err != nil || receipt == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Receipt not found"})
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
	MemberID  string  `json:"member_id"`
	MaxAmount float64 `json:"max_amount"`
	Mode      string  `json:"mode"` // UPI | E_NACH | CARD_SI
}

func (h *Handler) CreateAutoPayMandate(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req CreateMandateRequest
	_ = c.BodyParser(&req)

	mandateID := "MND" + strings.ReplaceAll(uuid.New().String(), "-", "")[:16]
	maxAmount := req.MaxAmount
	if maxAmount <= 0 {
		maxAmount = 1000.0
	}

	startDate := time.Now().Format("2006-01-02")
	endDate := time.Now().AddDate(3, 0, 0).Format("2006-01-02")

	// PayU SI Standing Instruction specification
	siDetailsJSON := fmt.Sprintf(`{"billingAmount":"%.2f","billingCurrency":"INR","billingCycle":"MONTHLY","billingInterval":1,"paymentStartDate":"%s","paymentEndDate":"%s","billingRule":"MAX"}`,
		maxAmount, startDate, endDate)

	var checkoutData *pg.PayUCheckoutFormData
	mandateURL := fmt.Sprintf("http://localhost:8080/api/v1/payments/payu-checkout/%s", mandateID)

	if h.pgClient != nil {
		memberName := "Mahal Member"
		memberEmail := "member@mahalflow.org"
		memberPhone := "9900990099"
		if h.memberRepo != nil && req.MemberID != "" {
			if m, mErr := h.memberRepo.GetByID(c.Context(), tenantID, req.MemberID); mErr == nil && m != nil {
				if m.Name != "" {
					memberName = m.Name
				}
				if m.Phone != "" {
					memberPhone = m.Phone
				}
			}
		}

		p := pg.PaymentRequestParams{
			OrderID:     mandateID,
			Amount:      "1.00", // Penny auth for mandate verification as per PayU AutoPay spec
			Currency:    "INR",
			Description: fmt.Sprintf("MahalFlow AutoPay Mandate for %s", memberName),
			Name:        memberName,
			Email:       memberEmail,
			Phone:       memberPhone,
			UDF1:        mandateID,
			UDF2:        tenantID,
			UDF3:        req.MemberID,
			IsSI:        true,
			SIDetails:   siDetailsJSON,
		}

		formData := h.pgClient.GeneratePayUCheckoutParams(p)
		checkoutData = &formData
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"mandate_id":     mandateID,
		"mahal_id":       tenantID,
		"member_id":      req.MemberID,
		"status":         "PENDING_AUTHORIZATION",
		"frequency":      "MONTHLY",
		"recurring_day":  1,
		"max_amount":     maxAmount,
		"si_details":     siDetailsJSON,
		"mandate_url":    mandateURL,
		"payu_checkout":  checkoutData,
	})
}

func (h *Handler) GetAutoPayStatus(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"mandate_id": "MND_849201",
		"status":     "ACTIVE",
		"frequency":  "MONTHLY",
		"amount":     500.0,
		"next_debit": "2026-09-01",
	})
}

// -------------------------------------------------------------
// 5. ADMIN & GOVERNANCE
// -------------------------------------------------------------

func (h *Handler) GetAdminDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var totalMembers, paidCount, pendingCount int64
	var totalPendingAmount, totalCollectedMTD float64

	if h.memberRepo != nil {
		totalMembers, paidCount, pendingCount, totalPendingAmount, _ = h.memberRepo.GetMemberStats(c.Context(), tenantID)
	}

	if h.txnRepo != nil {
		totalCollectedMTD, _, _, _ = h.txnRepo.GetFinancialSummary(c.Context(), tenantID)
	}

	subStatus := "ACTIVE"
	if h.mahalRepo != nil && tenantID != "" {
		if mahal, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && mahal != nil {
			subStatus = string(mahal.Subscription.Status)
		}
	}

	return c.JSON(fiber.Map{
		"total_members":       totalMembers,
		"paid_members":        paidCount,
		"pending_members":     pendingCount,
		"total_pending_dues":  totalPendingAmount,
		"total_collected_mtd": totalCollectedMTD,
		"subscription_status": subStatus,
	})
}

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
	mahal, err := h.mahalRepo.GetByID(c.Context(), id)
	if err != nil || mahal == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Mahal not found"})
	}
	return c.JSON(mahal)
}

func (h *Handler) CreateMahal(c *fiber.Ctx) error {
	if h.mahalRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Mahal service offline"})
	}
	var req domain.Mahal
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	if req.ID == "" {
		req.ID = "MH_" + uuid.New().String()[:8]
	}
	req.CreatedAt = time.Now().UTC()
	req.UpdatedAt = time.Now().UTC()
	if err := h.mahalRepo.Create(c.Context(), &req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(req)
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
	return c.JSON(fiber.Map{
		"payments": txns,
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

	if req.Action == "REJECT" {
		if h.refundRepo != nil {
			_ = h.refundRepo.UpdateStatus(c.Context(), refundID, "REJECTED")
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
	txnID := refundID
	amount := req.Amount
	if amount <= 0 {
		amount = 500.0 // Default fallback
	}

	if h.refundRepo != nil {
		if r, rErr := h.refundRepo.GetByID(c.Context(), refundID); rErr == nil && r != nil {
			if r.TransactionID != "" {
				txnID = r.TransactionID
			}
			if r.Amount > 0 {
				amount = r.Amount
			}
		}
	}

	var pgRefund *pg.RefundResponse
	if h.pgClient != nil {
		var err error
		pgRefund, err = h.pgClient.RequestRefund(c.Context(), pg.RefundParams{
			TransactionID:    txnID,
			MerchantRefundID: "MREF_" + refundID,
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

	// Update local status in DB
	if h.refundRepo != nil {
		_ = h.refundRepo.UpdateStatus(c.Context(), refundID, "APPROVED")
	}
	if h.txnRepo != nil {
		_ = h.txnRepo.UpdateStatus(c.Context(), txnID, domain.TxnRefunded, refNo)
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

func (h *Handler) GetFinancialReports(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var totalCollected, duesCollected, donations float64
	var pendingDues float64

	if h.txnRepo != nil {
		totalCollected, duesCollected, donations, _ = h.txnRepo.GetFinancialSummary(c.Context(), tenantID)
	}
	if h.memberRepo != nil {
		_, _, _, pendingDues, _ = h.memberRepo.GetMemberStats(c.Context(), tenantID)
	}

	return c.JSON(fiber.Map{
		"summary": fiber.Map{
			"total_collected": totalCollected,
			"dues_collected":  duesCollected,
			"donations":       donations,
			"pending_dues":    pendingDues,
		},
		"period": time.Now().Format("2006-01"),
	})
}

func (h *Handler) QueryFinancialReports(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var totalCollected, duesCollected, donations, pendingDues float64

	if h.txnRepo != nil {
		totalCollected, duesCollected, donations, _ = h.txnRepo.GetFinancialSummary(c.Context(), tenantID)
	}
	if h.memberRepo != nil {
		_, _, _, pendingDues, _ = h.memberRepo.GetMemberStats(c.Context(), tenantID)
	}

	return c.JSON(fiber.Map{
		"protocol": "HTTP QUERY (RFC 10008)",
		"summary": fiber.Map{
			"total_collected": totalCollected,
			"dues_collected":  duesCollected,
			"donations":       donations,
			"pending_dues":    pendingDues,
		},
		"period": time.Now().Format("2006-01"),
	})
}

func (h *Handler) GetGateways(c *fiber.Ctx) error {
	return c.JSON([]fiber.Map{
		{"id": "GW_RAZORPAY", "provider": "Razorpay Payment Gateway", "status": "ACTIVE", "is_primary": true},
		{"id": "GW_FEDERAL", "provider": "Federal Bank Direct UPI Gateway", "status": "ACTIVE", "is_primary": false},
	})
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

func (h *Handler) GetAlerts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Query("member_id")

	if h.alertRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Alerts service offline"})
	}
	alerts, err := h.alertRepo.List(c.Context(), tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	// Smart Audience Filtering for Members
	if memberID != "" && h.memberRepo != nil {
		member, _ := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
		filtered := make([]domain.SystemAlert, 0, len(alerts))
		for _, a := range alerts {
			if a.Audience == "OVERDUE_ONLY" {
				// Only include for members who have pending dues
				if member != nil && member.OutstandingBalance <= 0 && member.Status == "ACTIVE" {
					continue // Member has paid all dues up to date. Do not send overdue alert!
				}
			}
			filtered = append(filtered, a)
		}
		return c.JSON(fiber.Map{"alerts": filtered, "total": len(filtered)})
	}

	return c.JSON(fiber.Map{"alerts": alerts, "total": len(alerts)})
}

func (h *Handler) AcknowledgeAlert(c *fiber.Ctx) error {
	alertID := c.Params("id")
	if h.alertRepo != nil {
		if err := h.alertRepo.Acknowledge(c.Context(), alertID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}
	return c.JSON(fiber.Map{"status": "ACKNOWLEDGED", "alert_id": alertID})
}

func (h *Handler) DismissAlert(c *fiber.Ctx) error {
	alertID := c.Params("id")
	if h.alertRepo != nil {
		if err := h.alertRepo.Dismiss(c.Context(), alertID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}
	return c.JSON(fiber.Map{"status": "DISMISSED", "alert_id": alertID})
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
	Title       string `json:"title"`
	Description string `json:"description"`
	Severity    string `json:"severity"`
	Audience    string `json:"audience"` // ALL | OVERDUE_ONLY | FAMILY_HEADS
}

func (h *Handler) CreateAlert(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	var req CreateAlertRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	if req.Title == "" || req.Description == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Title and description are required"})
	}
	if req.Severity == "" {
		req.Severity = "INFO"
	}
	if req.Audience == "" {
		req.Audience = "ALL"
	}

	title := req.Title
	if req.Audience == "OVERDUE_ONLY" && !strings.Contains(title, "[Dues Reminder]") {
		title = "[Dues Reminder] " + title
	}

	alert := domain.SystemAlert{
		ID:          "ALT_" + uuid.New().String()[:8],
		MahalID:     tenantID,
		Audience:    req.Audience,
		Title:       title,
		Description: req.Description,
		Severity:    req.Severity,
		Status:      "ACTIVE",
		CreatedAt:   time.Now().UTC(),
	}
	if h.alertRepo != nil {
		if err := h.alertRepo.Create(c.Context(), &alert); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID:  tenantID,
			Action:   "ALERT_BROADCAST",
			Actor:    "Mahal Administrator",
			EntityID: alert.ID,
			Details:  "Broadcast notice sent to audience: " + req.Audience + " (Title: " + req.Title + ")",
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":   "CREATED",
		"alert":    alert,
		"audience": req.Audience,
	})
}

// -------------------------------------------------------------
// 6. EXCEL INGESTION & BATCH JOBS
// -------------------------------------------------------------

func (h *Handler) UploadExcelPreview(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"filename":       "mahal_members_sheet.xlsx",
		"total_rows":     150,
		"valid_rows":     148,
		"duplicate_rows": 2,
		"preview_rows": []fiber.Map{
			{"code": "M-105", "name": "Kareem Hassan", "phone": "+919847112233", "status": "VALID"},
			{"code": "M-106", "name": "Usman Tariq", "phone": "+919847445566", "status": "VALID"},
		},
	})
}

func (h *Handler) CommitExcelImport(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":          "COMPLETED",
		"imported_count":  148,
		"skipped_count":   2,
		"ingestion_batch": "BATCH_" + uuid.New().String()[:8],
	})
}

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
	if txnID == "" && strings.HasPrefix(orderID, "ORD_") {
		txnID = strings.TrimPrefix(orderID, "ORD_")
	} else if txnID == "" {
		txnID = orderID
	}

	// 2. Verify SHA-512 cryptographic hash if salt is present
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
	}

	// 3. Check response code (0 = SUCCESS or PayU status == "success")
	if respCodeStr == "0" || status == "success" || params["response_message"] == "SUCCESS" || params["response_message"] == "success" {
		if h.paymentService != nil && txnID != "" {
			receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), txnID)
			if err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
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

// VerifyPGPaymentStatus queries PG status API to reconcile transaction state
func (h *Handler) VerifyPGPaymentStatus(c *fiber.Ctx) error {
	txnID := c.Params("id")
	if txnID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Transaction ID required"})
	}

	orderID := "ORD_" + txnID
	if h.pgClient != nil {
		statusResp, err := h.pgClient.GetPaymentStatus(c.Context(), orderID, "")
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": err.Error()})
		}

		if statusResp.ResponseCode == 0 && h.paymentService != nil {
			receipt, commitErr := h.paymentService.CommitSuccessfulPayment(c.Context(), txnID)
			if commitErr == nil && receipt != nil {
				return c.JSON(fiber.Map{
					"status":  "SUCCESS",
					"receipt": receipt,
				})
			}
		}

		return c.JSON(fiber.Map{
			"status":            statusResp.ResponseMessage,
			"response_code":     statusResp.ResponseCode,
			"pg_transaction_id": statusResp.TransactionID,
		})
	}

	return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Payment gateway client unavailable"})
}

// GetPayUCheckoutData returns PayU parameters and SHA-512 hash as JSON for frontend/mobile SDK
func (h *Handler) GetPayUCheckoutData(c *fiber.Ctx) error {
	orderID := c.Params("orderId")
	if orderID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "orderId required"})
	}

	txnID := strings.TrimPrefix(orderID, "ORD_")
	txnID = strings.TrimPrefix(txnID, "ORD")
	txn, err := h.txnRepo.GetByID(c.Context(), txnID)
	if err != nil || txn == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Transaction not found"})
	}

	memberName := "Mahal Member"
	memberEmail := "member@mahalflow.org"
	memberPhone := "9900990099"
	if h.memberRepo != nil {
		if m, mErr := h.memberRepo.GetByID(c.Context(), txn.MahalID, txn.MemberID); mErr == nil && m != nil {
			if m.Name != "" {
				memberName = m.Name
			}
			if m.Phone != "" {
				memberPhone = m.Phone
			}
		}
	}

	p := pg.PaymentRequestParams{
		OrderID:     orderID,
		Amount:      fmt.Sprintf("%.2f", txn.Amount),
		Currency:    txn.Currency,
		Description: fmt.Sprintf("Mahal Payment %s", orderID),
		Name:        memberName,
		Email:       memberEmail,
		Phone:       memberPhone,
		UDF1:        txn.ID,
		UDF2:        txn.MahalID,
		UDF3:        txn.MemberID,
	}

	formData := h.pgClient.GeneratePayUCheckoutParams(p)
	return c.JSON(formData)
}

type PayUHashRequest struct {
	HashName   string `json:"hash_name"`
	HashString string `json:"hash_string"`
	HashType   string `json:"hash_type"`
	PostSalt   string `json:"post_salt"`
}

// GeneratePayUDynamicHash computes dynamic hashes requested by PayU mobile SDK
func (h *Handler) GeneratePayUDynamicHash(c *fiber.Ctx) error {
	var req PayUHashRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.HashString == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "hash_string is required"})
	}

	hash := h.pgClient.GenerateDynamicHash(req.HashName, req.HashString, req.HashType, req.PostSalt)
	return c.JSON(fiber.Map{
		"hash_name": req.HashName,
		"hash":      hash,
	})
}

// RenderPayUCheckoutPage auto-submits HTML form directly into PayU test/production gateway
func (h *Handler) RenderPayUCheckoutPage(c *fiber.Ctx) error {
	orderID := c.Params("orderId")
	if orderID == "" {
		return c.Status(fiber.StatusBadRequest).SendString("Missing orderId")
	}

	txnID := strings.TrimPrefix(orderID, "ORD_")
	txn, err := h.txnRepo.GetByID(c.Context(), txnID)
	if err != nil || txn == nil {
		return c.Status(fiber.StatusNotFound).SendString("Transaction not found")
	}

	memberName := "Mahal Member"
	memberEmail := "member@mahalflow.org"
	memberPhone := "9900990099"
	if h.memberRepo != nil {
		if m, mErr := h.memberRepo.GetByID(c.Context(), txn.MahalID, txn.MemberID); mErr == nil && m != nil {
			if m.Name != "" {
				memberName = m.Name
			}
			if m.Phone != "" {
				memberPhone = m.Phone
			}
		}
	}

	p := pg.PaymentRequestParams{
		OrderID:     orderID,
		Amount:      fmt.Sprintf("%.2f", txn.Amount),
		Currency:    txn.Currency,
		Description: fmt.Sprintf("Mahal Payment %s", orderID),
		Name:        memberName,
		Email:       memberEmail,
		Phone:       memberPhone,
		UDF1:        txn.ID,
		UDF2:        txn.MahalID,
		UDF3:        txn.MemberID,
	}

	formData := h.pgClient.GeneratePayUCheckoutParams(p)

	c.Set("Content-Type", "text/html")
	var inputs strings.Builder
	for k, v := range formData.Params {
		inputs.WriteString(fmt.Sprintf(`<input type="hidden" name="%s" value="%s" />`, k, v))
	}

	html := fmt.Sprintf(`<!DOCTYPE html>
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
</html>`, formData.Action, inputs.String())

	return c.SendString(html)
}
