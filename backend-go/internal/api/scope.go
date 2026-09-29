package api

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
)

// apiError is a handler-level failure carrying its HTTP status. Rendered as
// {"error": msg} like every other error body in this API.
type apiError struct {
	status int
	msg    string
}

func (e *apiError) Error() string { return e.msg }

func (e *apiError) send(c *fiber.Ctx) error {
	return c.Status(e.status).JSON(fiber.Map{"error": e.msg})
}

func errBadRequest(msg string) *apiError { return &apiError{status: fiber.StatusBadRequest, msg: msg} }
func errUnauthorized(msg string) *apiError {
	return &apiError{status: fiber.StatusUnauthorized, msg: msg}
}
func errForbidden(msg string) *apiError { return &apiError{status: fiber.StatusForbidden, msg: msg} }
func errNotFound(msg string) *apiError  { return &apiError{status: fiber.StatusNotFound, msg: msg} }

// Session claims, as set by JWTAuthMiddleware.
func sessionRole(c *fiber.Ctx) string    { r, _ := c.Locals("user_role").(string); return r }
func sessionSubject(c *fiber.Ctx) string { s, _ := c.Locals("user_id").(string); return s }

func isAdminRole(role string) bool {
	return role == domain.RoleMahalAdmin || role == domain.RoleSuperAdmin
}

// isAdminSession reports whether the caller holds an admin JWT.
func isAdminSession(c *fiber.Ctx) bool { return isAdminRole(sessionRole(c)) }

// scopeMember decides which member a member-facing request acts on.
//
//   - MEMBER: always their own id from the JWT. A different client-supplied
//     id is refused (403) rather than silently swapped, so a client bug shows.
//   - MAHAL_ADMIN / SUPER_ADMIN: the requested id (required). Tenant
//     isolation comes from the tenant-filtered lookups the handlers make.
func scopeMember(c *fiber.Ctx, requested string) (string, *apiError) {
	// Clone: requested often comes from c.Params/c.Query, whose backing
	// buffer Fiber reuses after the request.
	requested = strings.Clone(strings.TrimSpace(requested))
	role := sessionRole(c)
	switch {
	case role == domain.RoleMember:
		self := sessionSubject(c)
		if self == "" {
			return "", errUnauthorized("Session has no member identity")
		}
		if requested != "" && requested != self {
			return "", errForbidden("You can only access your own records")
		}
		return self, nil
	case isAdminRole(role):
		if requested == "" {
			return "", errBadRequest("member_id is required")
		}
		return requested, nil
	default:
		return "", errUnauthorized("Unauthorized: authentication required")
	}
}

// canSeeMemberRecord reports whether the caller may read a record that belongs
// to (mahalID, memberID). Records from another tenant, and other members'
// records for a MEMBER session, are reported as not found so ids cannot be
// probed.
func canSeeMemberRecord(c *fiber.Ctx, mahalID, memberID string) bool {
	tenantID, _ := c.Locals("tenant_id").(string)
	if mahalID != tenantID {
		return false
	}
	if sessionRole(c) == domain.RoleMember {
		return memberID == sessionSubject(c)
	}
	return isAdminSession(c)
}
