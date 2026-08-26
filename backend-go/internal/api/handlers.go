package api

import (
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/mahalflow/backend-go/internal/service"
)

type Handler struct {
	paymentService service.PaymentService
	mahalRepo      repository.MahalRepository
	memberRepo     repository.MemberRepository
	receiptRepo    repository.ReceiptRepository
}

func NewHandler(
	ps service.PaymentService,
	mhr repository.MahalRepository,
	mr repository.MemberRepository,
	rr repository.ReceiptRepository,
) *Handler {
	return &Handler{
		paymentService: ps,
		mahalRepo:      mhr,
		memberRepo:     mr,
		receiptRepo:    rr,
	}
}

// -------------------------------------------------------------
// 1. AUTHENTICATION
// -------------------------------------------------------------

type LoginRequest struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
}

func (h *Handler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}

	return c.JSON(fiber.Map{
		"token":      "jwt_mock_token_" + uuid.New().String()[:12],
		"role":       "MAHAL_ADMIN",
		"phone":      req.Phone,
		"expires_in": 86400,
	})
}

func (h *Handler) GetCurrentUser(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	return c.JSON(fiber.Map{
		"user_id":   "USR_001_ADMIN",
		"name":      "Mahal Secretary",
		"role":      "MAHAL_ADMIN",
		"mahal_id":  tenantID,
		"status":    "ACTIVE",
	})
}

// -------------------------------------------------------------
// 2. MEMBER OPERATIONS
// -------------------------------------------------------------

func (h *Handler) GetMemberDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Query("member_id", "MEM_001_9910")

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	mahal, _ := h.mahalRepo.GetByID(c.Context(), tenantID)
	mahalName := "Central Juma Masjid Mahal"
	if mahal != nil {
		mahalName = mahal.Name
	}

	latestReceipt, _ := h.receiptRepo.GetLatestReceipt(c.Context(), tenantID)

	return c.JSON(fiber.Map{
		"member_id":           member.ID,
		"member_name":         member.Name,
		"mahal_name":          mahalName,
		"outstanding_balance": member.OutstandingBalance,
		"last_paid_month":     member.LastPaidMonth,
		"latest_payment":      latestReceipt,
	})
}

func (h *Handler) GetMemberProfile(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := c.Params("id", "MEM_001_9910")

	member, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}
	return c.JSON(member)
}

func (h *Handler) UpdateMemberProfile(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "UPDATED", "updated_at": time.Now().UTC()})
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

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"transaction_id":   txn.ID,
		"amount":           txn.Amount,
		"currency":         txn.Currency,
		"selected_months":  txn.SelectedMonths,
		"status":           txn.Status,
		"gateway_order_id": "order_mock_" + txn.ID[4:12],
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

	receipt, err := h.paymentService.CommitSuccessfulPayment(c.Context(), req.TransactionID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
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

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"transaction_id": txn.ID,
		"amount":         txn.Amount,
		"currency":       txn.Currency,
		"status":         txn.Status,
	})
}

func (h *Handler) GetReceipt(c *fiber.Ctx) error {
	receiptNumber := c.Params("number")
	receipt, err := h.receiptRepo.GetByNumber(c.Context(), receiptNumber)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Receipt not found"})
	}

	return c.JSON(receipt)
}

func (h *Handler) VerifyReceiptIntegrity(c *fiber.Ctx) error {
	receiptNumber := c.Params("number")
	receipt, err := h.receiptRepo.GetByNumber(c.Context(), receiptNumber)
	if err != nil {
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

func (h *Handler) CreateAutoPayMandate(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"mandate_id":     "MND_" + uuid.New().String()[:8],
		"mahal_id":       tenantID,
		"status":         "ACTIVE",
		"recurring_day":  1,
		"max_amount":     1000.0,
		"mandate_url":    "https://api.razorpay.com/v1/mandates/mock_auth",
	})
}

func (h *Handler) GetAutoPayStatus(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"mandate_id":    "MND_849201",
		"status":        "ACTIVE",
		"frequency":     "MONTHLY",
		"amount":        500.0,
		"next_debit":    "2026-09-01",
	})
}

// -------------------------------------------------------------
// 5. ADMIN & GOVERNANCE
// -------------------------------------------------------------

func (h *Handler) GetAdminDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	totalMembers, paidCount, pendingCount, totalPendingAmount, err := h.memberRepo.GetMemberStats(c.Context(), tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	mahal, _ := h.mahalRepo.GetByID(c.Context(), tenantID)
	subStatus := "ACTIVE"
	if mahal != nil {
		subStatus = string(mahal.Subscription.Status)
	}

	return c.JSON(fiber.Map{
		"total_members":        totalMembers,
		"paid_members":         paidCount,
		"pending_members":      pendingCount,
		"total_pending_dues":   totalPendingAmount,
		"total_collected_mtd":  85500.0,
		"subscription_status":  subStatus,
	})
}

func (h *Handler) GetAdminMembers(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	limit, _ := strconv.ParseInt(c.Query("limit", "50"), 10, 64)
	page, _ := strconv.ParseInt(c.Query("page", "1"), 10, 64)
	skip := (page - 1) * limit

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

func (h *Handler) GetFinancialReports(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"summary": fiber.Map{
			"total_collected": 184500.0,
			"dues_collected":  145000.0,
			"donations":       39500.0,
			"pending_dues":    12000.0,
		},
		"period": "2026-08",
	})
}

func (h *Handler) GetGateways(c *fiber.Ctx) error {
	return c.JSON([]fiber.Map{
		{"id": "GW_RAZORPAY", "provider": "Razorpay", "status": "ACTIVE", "is_primary": true},
		{"id": "GW_FEDERAL", "provider": "Federal Bank Direct UPI", "status": "ACTIVE", "is_primary": false},
	})
}

func (h *Handler) GetAuditLogs(c *fiber.Ctx) error {
	return c.JSON([]fiber.Map{
		{
			"id":        "AUD_001",
			"action":    "PAYMENT_COMMITTED",
			"actor":     "MEMBER_SELF",
			"entity_id": "RCPT_003",
			"timestamp": time.Now().Add(-10 * time.Minute).UTC(),
		},
		{
			"id":        "AUD_002",
			"action":    "DATABASE_SEEDED",
			"actor":     "SYS_SEEDER",
			"entity_id": "mahalflow",
			"timestamp": time.Now().Add(-2 * time.Hour).UTC(),
		},
	})
}

func (h *Handler) GetAlerts(c *fiber.Ctx) error {
	return c.JSON([]fiber.Map{
		{
			"id":        "ALT_001",
			"title":     "Monthly Dues Due in 3 Days",
			"severity":  "INFO",
			"timestamp": time.Now().UTC(),
		},
	})
}

// -------------------------------------------------------------
// 6. EXCEL INGESTION & BATCH JOBS
// -------------------------------------------------------------

func (h *Handler) UploadExcelPreview(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"filename":       "mahal_members_august_2026.xlsx",
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
