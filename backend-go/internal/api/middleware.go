package api

import (
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

func TenantExtractionMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		tenantID := c.Get("X-Tenant-ID")
		if tenantID == "" {
			tenantID = c.Query("mahal_id")
		}
		if tenantID == "" {
			tenantID = c.Query("tenant_id")
		}
		if tenantID == "" {
			tenantID = "MH_001_CALICUT"
		}
		c.Locals("tenant_id", tenantID)
		return c.Next()
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
