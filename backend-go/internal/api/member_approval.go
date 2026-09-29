package api

import (
	"net/mail"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
	"go.mongodb.org/mongo-driver/v2/bson"
)

// MemberStatusRejected marks a self-registration the committee turned down.
// Kept as a record (not deleted) so the decision can be reverted.
const MemberStatusRejected = "REJECTED"

// ApprovalRevertWindow is how long an approve / reject can be undone.
const ApprovalRevertWindow = 10 * time.Minute

// decideRegistration applies an approve (ACTIVE) or reject (REJECTED) to a
// PENDING_APPROVAL member and records when, so it can be reverted.
func (h *Handler) decideRegistration(c *fiber.Ctx, newStatus, action, details string) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := strings.Clone(c.Params("id"))
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}
	m, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || m == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}
	if m.Status != MemberStatusPending {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Only pending registrations can be approved or rejected", "status": m.Status})
	}
	now := time.Now().UTC()
	if err := h.memberRepo.UpdateProfile(c.Context(), tenantID, memberID, bson.M{
		"status":              newStatus,
		"approval_decision":   newStatus,
		"approval_decided_at": now,
	}); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: tenantID, Action: action, Actor: sessionRole(c), EntityID: memberID, Details: details,
		})
	}
	return c.JSON(fiber.Map{
		"member_id":        memberID,
		"status":           newStatus,
		"revertible_until": now.Add(ApprovalRevertWindow),
	})
}

// RevertMemberApproval undoes a recent approve or reject, returning the member
// to PENDING_APPROVAL. Allowed only within ApprovalRevertWindow of the
// decision, only while the member's status is still that decision, and — for
// an approval — only if the member has made no payment.
func (h *Handler) RevertMemberApproval(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	memberID := strings.Clone(c.Params("id"))
	if h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Member service offline"})
	}
	m, err := h.memberRepo.GetByID(c.Context(), tenantID, memberID)
	if err != nil || m == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}
	if aerr := h.checkRevertable(c, m, time.Now()); aerr != nil {
		return aerr.send(c)
	}
	if err := h.memberRepo.UpdateProfile(c.Context(), tenantID, memberID, bson.M{
		"status":              MemberStatusPending,
		"approval_decision":   "",
		"approval_decided_at": nil,
	}); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: tenantID, Action: "MEMBER_DECISION_REVERTED", Actor: sessionRole(c), EntityID: memberID,
			Details: "Reverted " + m.ApprovalDecision + " back to pending approval",
		})
	}
	return c.JSON(fiber.Map{"member_id": memberID, "status": MemberStatusPending, "reverted": m.ApprovalDecision})
}

func (h *Handler) checkRevertable(c *fiber.Ctx, m *domain.Member, now time.Time) *apiError {
	conflict := func(msg string) *apiError { return &apiError{status: fiber.StatusConflict, msg: msg} }
	if m.ApprovalDecision == "" || m.ApprovalDecidedAt == nil || m.Status != m.ApprovalDecision {
		return conflict("This member has no recent approval or rejection to undo")
	}
	if now.Sub(*m.ApprovalDecidedAt) > ApprovalRevertWindow {
		return conflict("The undo window has passed (10 minutes)")
	}
	if m.Status == "ACTIVE" {
		if h.txnRepo != nil {
			if n, err := h.txnRepo.CountByMember(c.Context(), m.MahalID, m.ID); err != nil || n > 0 {
				return conflict("This member has already made a payment; the approval cannot be undone")
			}
		}
		if h.receiptRepo != nil {
			if r, _ := h.receiptRepo.GetLatestByMember(c.Context(), m.MahalID, m.ID); r != nil {
				return conflict("This member has already made a payment; the approval cannot be undone")
			}
		}
	}
	return nil
}

func validEmail(e string) bool {
	a, err := mail.ParseAddress(e)
	return err == nil && a.Address == e && strings.Contains(e, "@")
}

// applyPersonalDetails copies the optional profile fields present in req
// into updates, validating them. "" clears a field.
func applyPersonalDetails(updates bson.M, req UpdateProfileRequest) *apiError {
	set := func(key string, v *string, max int) *apiError {
		if v == nil {
			return nil
		}
		val := strings.TrimSpace(*v)
		if utf8.RuneCountInString(val) > max {
			return errBadRequest(key + " is too long")
		}
		updates[key] = val
		return nil
	}
	if req.Email != nil {
		if e := strings.TrimSpace(*req.Email); e != "" && !validEmail(e) {
			return errBadRequest("Email is not valid")
		}
	}
	if req.Pincode != nil {
		p := strings.TrimSpace(*req.Pincode)
		if p != "" && (len(p) != 6 || strings.Trim(p, "0123456789") != "" || p[0] == '0') {
			return errBadRequest("Pincode must be 6 digits")
		}
	}
	for _, f := range []struct {
		key string
		v   *string
		max int
	}{
		{"email", req.Email, 254},
		{"address2", req.Address2, 200},
		{"city", req.City, 100},
		{"state", req.State, 100},
		{"pincode", req.Pincode, 6},
	} {
		if aerr := set(f.key, f.v, f.max); aerr != nil {
			return aerr
		}
	}
	return nil
}
