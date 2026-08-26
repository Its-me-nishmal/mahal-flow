package api

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
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

// GET /api/v1/member/dashboard
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

// GET /api/v1/admin/dashboard
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

// GET /api/v1/admin/members
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
