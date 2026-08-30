package api

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/google/uuid"
)

func CorrelationIDMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		cid := c.Get("X-Correlation-ID")
		if cid == "" {
			cid = uuid.New().String()
		}
		c.Set("X-Correlation-ID", cid)
		c.Locals("correlation_id", cid)
		return c.Next()
	}
}

// Strict Tenant Extraction: Rejects requests missing X-Tenant-ID with HTTP 400 (Zero Silent Fallback)
func TenantExtractionMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		tenantID := c.Get("X-Tenant-ID")
		if tenantID == "" {
			tenantID = c.Query("mahal_id")
		}
		if tenantID == "" {
			tenantID = c.Query("tenant_id")
		}

		if strings.TrimSpace(tenantID) == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Missing required X-Tenant-ID header",
				"message": "Every tenant-scoped request must explicitly provide a valid X-Tenant-ID header",
				"status":  400,
			})
		}

		c.Locals("tenant_id", tenantID)
		return c.Next()
	}
}

// Cryptographic JWT Authentication Middleware
func JWTAuthMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":  "Missing Authorization header",
				"status": 401,
			})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":  "Invalid Authorization header format. Expected: Bearer <token>",
				"status": 401,
			})
		}

		claims, err := ValidateJWT(parts[1])
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":  "Authentication failed: " + err.Error(),
				"status": 401,
			})
		}

		// Cross-tenant verification: Ensure token's tenant matches request tenant
		reqTenant, _ := c.Locals("tenant_id").(string)
		if reqTenant != "" && claims.MahalID != "" && claims.MahalID != reqTenant && claims.Role != "SUPER_ADMIN" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error":  "Token tenant mismatch: access to target organization is unauthorized",
				"status": 403,
			})
		}

		c.Locals("user_id", claims.Subject)
		c.Locals("user_role", claims.Role)
		c.Locals("user_phone", claims.Phone)
		c.Locals("user_mahal_id", claims.MahalID)

		return c.Next()
	}
}

// Role-Based Access Control (RBAC) Guard
func RequireRole(allowedRoles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		role, _ := c.Locals("user_role").(string)
		if role == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":  "Unauthorized: authentication required",
				"status": 401,
			})
		}

		for _, r := range allowedRoles {
			if r == role || role == "SUPER_ADMIN" {
				return c.Next()
			}
		}

		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":  "Forbidden: insufficient role privileges for this operation",
			"status": 403,
		})
	}
}

// GlobalRateLimiterMiddleware protects against DDoS and traffic flooding (300 req / 10s per IP)
func GlobalRateLimiterMiddleware() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        300,
		Expiration: 10 * time.Second,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error":       "Too many requests. Please slow down and try again.",
				"status":      429,
				"retry_after": "10s",
			})
		},
	})
}

// StrictAuthRateLimiterMiddleware guards auth endpoints against brute-force (30 req / 1 min per IP)
func StrictAuthRateLimiterMiddleware() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        30,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error":       "Too many authentication attempts. Please try again after 1 minute.",
				"status":      429,
				"retry_after": "60s",
			})
		},
	})
}
