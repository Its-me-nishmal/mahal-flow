package api

import (
	"github.com/gofiber/fiber/v2"
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
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "MISSING_TENANT_ID",
					"message": "X-Tenant-ID header is required for this endpoint",
				},
			})
		}
		c.Locals("tenant_id", tenantID)
		return c.Next()
	}
}
