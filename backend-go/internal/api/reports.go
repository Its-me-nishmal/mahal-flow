package api

import (
	"context"
	"strings"
	"time"
	_ "time/tzdata" // Asia/Kolkata must resolve even on hosts without zoneinfo

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
)

// TenantTimezone is the zone "this month" is measured in. Every Mahal is in
// India today; per-tenant zones can be added to MahalSettings when needed.
const TenantTimezone = "Asia/Kolkata"

func tenantLocation() *time.Location {
	if loc, err := time.LoadLocation(TenantTimezone); err == nil {
		return loc
	}
	return time.FixedZone("IST", 5*3600+1800)
}

// monthRange is [first instant of month, first instant of next month) in loc.
func monthRange(year int, month time.Month, loc *time.Location) (time.Time, time.Time) {
	start := time.Date(year, month, 1, 0, 0, 0, 0, loc)
	return start, start.AddDate(0, 1, 0)
}

// monthToDate is [start of now's month in loc, now].
func monthToDate(now time.Time, loc *time.Location) (from, to time.Time) {
	n := now.In(loc)
	from, _ = monthRange(n.Year(), n.Month(), loc)
	return from, now
}

// reportPeriod is a parsed ?month= / ?from=&to= filter. Nil bounds = open.
type reportPeriod struct {
	Label    string // YYYY-MM | CUSTOM | ALL_TIME
	From, To *time.Time
}

// parseReportPeriod reads month=YYYY-MM, or from/to=YYYY-MM-DD (inclusive
// days in the tenant zone). Neither = all time.
func parseReportPeriod(month, from, to string, loc *time.Location) (reportPeriod, *apiError) {
	month, from, to = strings.TrimSpace(month), strings.TrimSpace(from), strings.TrimSpace(to)
	switch {
	case month != "" && (from != "" || to != ""):
		return reportPeriod{}, errBadRequest("use either month or from/to, not both")
	case month != "":
		m, err := time.ParseInLocation("2006-01", month, loc)
		if err != nil {
			return reportPeriod{}, errBadRequest("month must be YYYY-MM")
		}
		s, e := monthRange(m.Year(), m.Month(), loc)
		return reportPeriod{Label: month, From: &s, To: &e}, nil
	case from != "" || to != "":
		p := reportPeriod{Label: "CUSTOM"}
		if from != "" {
			f, err := time.ParseInLocation("2006-01-02", from, loc)
			if err != nil {
				return reportPeriod{}, errBadRequest("from must be YYYY-MM-DD")
			}
			p.From = &f
		}
		if to != "" {
			t, err := time.ParseInLocation("2006-01-02", to, loc)
			if err != nil {
				return reportPeriod{}, errBadRequest("to must be YYYY-MM-DD")
			}
			end := t.AddDate(0, 0, 1) // inclusive day
			p.To = &end
		}
		if p.From != nil && p.To != nil && !p.From.Before(*p.To) {
			return reportPeriod{}, errBadRequest("from must be on or before to")
		}
		return p, nil
	default:
		return reportPeriod{Label: "ALL_TIME"}, nil
	}
}

func timeOrNil(t *time.Time) any {
	if t == nil {
		return nil
	}
	return t.UTC()
}

func (h *Handler) GetAdminDashboard(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)

	var totalMembers, paidCount, pendingCount int64
	var totalPendingAmount float64
	if h.memberRepo != nil {
		totalMembers, paidCount, pendingCount, totalPendingAmount, _ = h.memberRepo.GetMemberStats(c.Context(), tenantID)
	}

	loc := tenantLocation()
	from, to := monthToDate(time.Now(), loc)
	var mtd, allTime repository.FinancialSummary
	if h.txnRepo != nil {
		mtd, _ = h.txnRepo.GetFinancialSummaryRange(c.Context(), tenantID, &from, nil)
		allTime, _ = h.txnRepo.GetFinancialSummaryRange(c.Context(), tenantID, nil, nil)
	}

	subStatus := "ACTIVE"
	if h.mahalRepo != nil && tenantID != "" {
		if mahal, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && mahal != nil {
			subStatus = string(mahal.Subscription.Status)
		}
	}

	return c.JSON(fiber.Map{
		"total_members":            totalMembers,
		"paid_members":             paidCount,
		"pending_members":          pendingCount,
		"total_pending_dues":       totalPendingAmount,
		"total_collected_mtd":      mtd.TotalCollected,
		"total_collected_all_time": allTime.TotalCollected,
		"mtd_month":                from.Format("2006-01"),
		"mtd_from":                 from.UTC(),
		"mtd_to":                   to.UTC(),
		"timezone":                 TenantTimezone,
		"subscription_status":      subStatus,
	})
}

type FinancialReportQuery struct {
	Month string `json:"month" query:"month"`
	From  string `json:"from" query:"from"`
	To    string `json:"to" query:"to"`
}

func (h *Handler) GetFinancialReports(c *fiber.Ctx) error {
	return h.financialReport(c, FinancialReportQuery{Month: c.Query("month"), From: c.Query("from"), To: c.Query("to")}, false)
}

func (h *Handler) QueryFinancialReports(c *fiber.Ctx) error {
	var q FinancialReportQuery
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&q); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
		}
	}
	if q.Month == "" && q.From == "" && q.To == "" {
		q = FinancialReportQuery{Month: c.Query("month"), From: c.Query("from"), To: c.Query("to")}
	}
	return h.financialReport(c, q, true)
}

func (h *Handler) financialReport(c *fiber.Ctx, q FinancialReportQuery, query bool) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	period, aerr := parseReportPeriod(q.Month, q.From, q.To, tenantLocation())
	if aerr != nil {
		return aerr.send(c)
	}
	var sum repository.FinancialSummary
	if h.txnRepo != nil {
		var err error
		sum, err = h.txnRepo.GetFinancialSummaryRange(c.Context(), tenantID, period.From, period.To)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}
	var pendingDues float64
	if h.memberRepo != nil {
		_, _, _, pendingDues, _ = h.memberRepo.GetMemberStats(c.Context(), tenantID)
	}
	out := fiber.Map{
		"summary": fiber.Map{
			"total_collected":   sum.TotalCollected,
			"dues_collected":    sum.DuesCollected,
			"donations":         sum.Donations,
			"pending_dues":      pendingDues, // current snapshot, not period-bound
			"transaction_count": sum.TransactionCount,
		},
		"period":   period.Label,
		"from":     timeOrNil(period.From),
		"to":       timeOrNil(period.To),
		"timezone": TenantTimezone,
	}
	if query {
		out["protocol"] = "HTTP QUERY (RFC 10008)"
	}
	return c.JSON(out)
}

// GetGateways reports the payment gateways this server is actually configured
// with. Credentials live in the server environment; nothing secret is returned.
func (h *Handler) GetGateways(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	autopayAllowed := false
	if h.mahalRepo != nil {
		if m, err := h.mahalRepo.GetByID(c.Context(), tenantID); err == nil && m != nil {
			autopayAllowed = m.Settings.AutoPayAllowed
		}
	}
	return c.JSON(h.gatewaysFor(c.Context(), autopayAllowed))
}

func (h *Handler) gatewaysFor(_ context.Context, autopayAllowed bool) []fiber.Map {
	payu := fiber.Map{
		"id": "GW_PAYU", "provider": "PAYU", "display_name": "PayU India",
		"status": "NOT_CONFIGURED", "is_primary": true, "mode": "LIVE", "simulated": true,
		"merchant_key_masked": "", "supported_methods": []string{"UPI", "CARD", "NETBANKING", "WALLET"},
		"autopay_enabled": false, "si_supported": false, "managed_by": "SERVER_CONFIG",
	}
	if pc := h.pgClient; pc != nil {
		configured := pc.Configured()
		if configured {
			payu["status"] = "ACTIVE"
		}
		payu["mode"] = pc.Mode()
		payu["simulated"] = pc.TestMode || !configured
		payu["merchant_key_masked"] = pc.MaskedKey()
		payu["si_supported"] = configured
		payu["autopay_enabled"] = configured && autopayAllowed
	}
	cash := fiber.Map{
		"id": "GW_CASH", "provider": "CASH", "display_name": "Cash (committee)",
		"status": "ACTIVE", "is_primary": false, "mode": "LIVE", "simulated": false,
		"merchant_key_masked": "", "supported_methods": []string{"CASH"},
		"autopay_enabled": false, "si_supported": false, "managed_by": "SERVER_CONFIG",
	}
	return []fiber.Map{payu, cash}
}

// effectiveMonthlyDues is the member's per-month rate: their custom amount,
// else the Mahal default.
func effectiveMonthlyDues(m *domain.Member, mahal *domain.Mahal) (float64, string) {
	if m != nil && m.MonthlyDuesCustomAmount > 0 {
		return m.MonthlyDuesCustomAmount, "CUSTOM"
	}
	if mahal != nil && mahal.Settings.DefaultMonthlyDues > 0 {
		return mahal.Settings.DefaultMonthlyDues, "MAHAL_DEFAULT"
	}
	return 0, "MAHAL_DEFAULT"
}

func mahalContactJSON(mahal *domain.Mahal) fiber.Map {
	out := fiber.Map{"phone": "", "whatsapp": "", "email": ""}
	if mahal == nil {
		return out
	}
	out["phone"] = mahal.Contact.Phone
	out["email"] = mahal.Contact.Email
	wa := mahal.Contact.WhatsApp
	if wa == "" {
		wa = mahal.Contact.Phone
	}
	out["whatsapp"] = wa
	return out
}
