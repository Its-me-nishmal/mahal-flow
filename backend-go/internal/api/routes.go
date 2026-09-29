package api

import "github.com/gofiber/fiber/v2"

// RegisterTenantRoutes binds every X-Tenant-ID scoped route onto r (the
// /api/v1 group behind TenantExtractionMiddleware). Kept here rather than in
// main so tests exercise the exact production auth wiring.
//
// Public (no JWT): /auth/resolve and /auth/register — they authenticate with a
// Firebase ID token instead. Everything else needs a MahalFlow JWT whose
// tenant matches X-Tenant-ID (JWTAuthMiddleware); handlers then scope member
// data to the JWT subject for MEMBER sessions.
func RegisterTenantRoutes(r fiber.Router, h *Handler) {
	auth := JWTAuthMiddleware()
	adminOnly := RequireRole("MAHAL_ADMIN", "SUPER_ADMIN")
	superOnly := RequireRole("SUPER_ADMIN")

	// Auth & profile
	r.Post("/auth/resolve", StrictAuthRateLimiterMiddleware(), h.ResolveLogin)
	r.Post("/auth/register", StrictAuthRateLimiterMiddleware(), h.RegisterSelf)
	r.Get("/auth/me", auth, h.GetCurrentUser)
	r.Post("/auth/change-password", StrictAuthRateLimiterMiddleware(), auth, adminOnly, h.ChangePassword)
	r.Get("/members/profile/:id", auth, h.GetMemberProfile)
	r.Put("/members/profile/:id", auth, h.UpdateMemberProfile)

	// Member portal: dues, contributions, receipts
	r.Get("/member/dashboard", auth, h.GetMemberDashboard)
	r.Get("/member/receipts", auth, h.GetMemberReceipts)
	r.Post("/payments/dues/initialize", auth, h.InitializeDuesPayment)
	r.Post("/payments/dues/confirm", auth, h.ConfirmPayment)
	r.Get("/payments/:id/status", auth, h.VerifyPGPaymentStatus)
	r.Post("/payments/contribution/initialize", auth, h.InitializeContribution)
	r.Get("/payments/payu-checkout-data/:orderId", auth, h.GetPayUCheckoutData)
	r.Post("/payments/payu-generate-hash", auth, h.GeneratePayUDynamicHash)
	r.Get("/receipts/:number", auth, h.GetReceipt)
	r.Get("/receipts/:number/verify", auth, h.VerifyReceiptIntegrity)

	// AutoPay mandates
	r.Post("/autopay/mandate/create", auth, h.CreateAutoPayMandate)
	r.Get("/autopay/mandate/status", auth, h.GetAutoPayStatus)
	r.Post("/autopay/mandate/confirm", auth, h.ConfirmAutoPayMandate)
	r.Post("/autopay/mandate/cancel", auth, h.CancelAutoPayMandate)

	// Notices: read state is per member
	r.Get("/member/alerts", auth, h.GetAlerts)
	r.Get("/alerts", auth, h.GetAlerts)
	r.Post("/member/alerts/mark-all-read", auth, h.MarkAllMemberAlertsRead)
	r.Post("/member/alerts/:id/ack", auth, h.AcknowledgeMemberAlert)
	r.Delete("/member/alerts/:id", auth, h.DismissMemberAlert)
	r.Delete("/member/alerts", auth, h.ClearAllMemberAlerts)

	// Push notifications
	r.Post("/notifications/register-token", auth, h.RegisterDeviceToken)
	r.Post("/notifications/unregister-token", auth, h.UnregisterDeviceToken)

	// QR standee (BharatQR & UPI)
	r.Get("/mahal/qr-standee", auth, h.GetMahalQRStandee)
	r.Post("/mahal/qr-standee/dynamic", auth, h.GenerateDynamicQR)

	// Committee (MAHAL_ADMIN / SUPER_ADMIN)
	admin := r.Group("/admin", auth, adminOnly)
	admin.Get("/dashboard", h.GetAdminDashboard)
	admin.Get("/mahals", superOnly, h.GetMahals)
	admin.Post("/mahals", superOnly, h.CreateMahal)
	admin.Get("/mahals/:id", h.GetMahalByID)
	admin.Put("/mahals/:id", h.UpdateMahal)
	admin.Get("/mahals/:id/stats", h.GetMahalStats)
	admin.Get("/members", h.GetAdminMembers)
	admin.Post("/members", h.CreateMember)
	admin.Delete("/members/:id", h.DeleteMember)
	admin.Post("/members/query", h.QueryAdminMembers)
	admin.Get("/members/pending", h.GetPendingMembers)
	admin.Post("/members/:id/approve", h.ApproveMember)
	admin.Post("/members/:id/reject", h.RejectMember)
	admin.Post("/members/:id/revert-approval", h.RevertMemberApproval)
	admin.Get("/payments", h.GetPayments)
	admin.Get("/subscriptions", superOnly, h.GetSubscriptions)
	admin.Get("/refunds", h.GetRefunds)
	admin.Post("/refunds/:id/action", h.ProcessRefund)
	admin.Get("/qr-standee", h.GetMahalQRStandee)
	admin.Post("/qr-standee/dynamic", h.GenerateDynamicQR)
	admin.Get("/reports/financial", h.GetFinancialReports)
	admin.Post("/reports/financial/query", h.QueryFinancialReports)
	admin.Get("/gateways", h.GetGateways)
	admin.Get("/audit-logs", h.GetAuditLogs)
	admin.Get("/alerts", h.GetAlerts)
	admin.Post("/alerts", h.CreateAlert)
	admin.Post("/alerts/:id/ack", h.AcknowledgeAlert)
	admin.Delete("/alerts/:id", h.DismissAlert)
	admin.Delete("/alerts", h.ClearAllAlerts)
	admin.Post("/alerts/mark-all-read", h.MarkAllAlertsRead)
	admin.Post("/excel/upload-preview", h.UploadExcelPreview)
	admin.Post("/excel/commit-import", h.CommitExcelImport)
	admin.Post("/autopay/run-due", h.RunDueAutoPayDebits)
}
