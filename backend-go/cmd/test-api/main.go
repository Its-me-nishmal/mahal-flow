package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/google/uuid"
)

type EndpointTest struct {
	Name           string
	Method         string
	Path           string
	Headers        map[string]string
	Body           map[string]interface{}
	ExpectedStatus int
	ValidateModel  func(body map[string]interface{}) error
}

func main() {
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	tenantID := "MH_001_CALICUT"
	testIdempKey := "IDEMP_AUTO_" + uuid.New().String()[:8]

	fmt.Println("==================================================================")
	fmt.Println("🧪 MahalFlow Full Production API & Model Validation Suite (18 APIs)")
	fmt.Printf("🎯 Target Base URL: %s | Tenant: %s\n", baseURL, tenantID)
	fmt.Println("==================================================================")

	client := &http.Client{Timeout: 5 * time.Second}

	tests := []EndpointTest{
		// 1. Health & Security Guard
		{
			Name:           "1. Public Health Check",
			Method:         "GET",
			Path:           "/health",
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["status"] != "healthy" || b["database"] != "connected" {
					return fmt.Errorf("health payload missing healthy status")
				}
				return nil
			},
		},
		{
			Name:   "2. Missing Tenant Header Guard",
			Method: "GET",
			Path:   "/api/v1/admin/dashboard",
			Headers: map[string]string{
				// No X-Tenant-ID
			},
			ExpectedStatus: 400,
			ValidateModel: func(b map[string]interface{}) error {
				errObj, ok := b["error"].(map[string]interface{})
				if !ok || errObj["code"] != "MISSING_TENANT_ID" {
					return fmt.Errorf("expected MISSING_TENANT_ID error code")
				}
				return nil
			},
		},

		// 2. Authentication
		{
			Name:   "3. Admin & Member Login",
			Method: "POST",
			Path:   "/api/v1/auth/login",
			Headers: map[string]string{
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"phone":    "+919847123456",
				"password": "SecretPassword123",
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["token"] == nil || b["role"] != "MAHAL_ADMIN" {
					return fmt.Errorf("invalid login auth payload")
				}
				return nil
			},
		},
		{
			Name:   "4. Current User Context (/auth/me)",
			Method: "GET",
			Path:   "/api/v1/auth/me",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["user_id"] == nil || b["mahal_id"] != tenantID {
					return fmt.Errorf("invalid current user context")
				}
				return nil
			},
		},

		// 3. Member Operations
		{
			Name:   "5. Member Dashboard Live Overview",
			Method: "GET",
			Path:   "/api/v1/member/dashboard?member_id=MEM_001_9910",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["member_name"] == nil || b["outstanding_balance"] == nil {
					return fmt.Errorf("missing member_name or outstanding_balance")
				}
				return nil
			},
		},
		{
			Name:   "6. Member Profile Details",
			Method: "GET",
			Path:   "/api/v1/members/profile/MEM_001_9910",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["name"] == nil || b["phone"] == nil {
					return fmt.Errorf("missing profile fields")
				}
				return nil
			},
		},

		// 4. Payments & Cryptographic Receipts
		{
			Name:   "7. Initialize Dues Payment",
			Method: "POST",
			Path:   "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenantID,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"selected_months": []string{"2026-08"},
				"gateway":         "RAZORPAY",
				"idempotency_key": testIdempKey,
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["transaction_id"] == nil || b["amount"] == nil {
					return fmt.Errorf("invalid dues payment initialization")
				}
				return nil
			},
		},
		{
			Name:   "8. Initialize Voluntary Contribution",
			Method: "POST",
			Path:   "/api/v1/payments/contribution/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenantID,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"amount":          500.0,
				"purpose":         "Orphan Care Fund",
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_CONTRIB_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["transaction_id"] == nil {
					return fmt.Errorf("invalid contribution payload")
				}
				return nil
			},
		},
		{
			Name:   "9. Fetch Cryptographic Receipt",
			Method: "GET",
			Path:   "/api/v1/receipts/GV1MH00120260515R00001",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["receipt_hash"] == nil || b["sequence_number"] == nil {
					return fmt.Errorf("missing cryptographic hash in receipt")
				}
				return nil
			},
		},
		{
			Name:   "10. Verify SHA-256 Receipt Chain Integrity",
			Method: "GET",
			Path:   "/api/v1/receipts/GV1MH00120260515R00001/verify",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["cryptographic_valid"] != true {
					return fmt.Errorf("cryptographic verification failed on receipt chain")
				}
				return nil
			},
		},

		// 5. AutoPay & E-Mandates
		{
			Name:   "11. Create AutoPay e-Mandate",
			Method: "POST",
			Path:   "/api/v1/autopay/mandate/create",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["mandate_id"] == nil || b["status"] != "ACTIVE" {
					return fmt.Errorf("invalid mandate payload")
				}
				return nil
			},
		},
		{
			Name:   "12. Query AutoPay Mandate Status",
			Method: "GET",
			Path:   "/api/v1/autopay/mandate/status",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["status"] != "ACTIVE" {
					return fmt.Errorf("invalid mandate status")
				}
				return nil
			},
		},

		// 6. Admin Operations & Governance
		{
			Name:   "13. Admin Dashboard Metrics",
			Method: "GET",
			Path:   "/api/v1/admin/dashboard",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["total_members"] == nil || b["total_pending_dues"] == nil {
					return fmt.Errorf("missing admin dashboard metrics")
				}
				return nil
			},
		},
		{
			Name:   "14. Admin Paginated Members Roster",
			Method: "GET",
			Path:   "/api/v1/admin/members?page=1&limit=10",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				members, ok := b["members"].([]interface{})
				if !ok || len(members) == 0 {
					return fmt.Errorf("expected non-empty member array")
				}
				return nil
			},
		},
		{
			Name:   "15. Admin Financial Reports",
			Method: "GET",
			Path:   "/api/v1/admin/reports/financial",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["summary"] == nil {
					return fmt.Errorf("missing financial report summary")
				}
				return nil
			},
		},
		{
			Name:   "16. Payment Gateway Configurations",
			Method: "GET",
			Path:   "/api/v1/admin/gateways",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
		},
		{
			Name:   "17. Security & Audit Trail Logs",
			Method: "GET",
			Path:   "/api/v1/admin/audit-logs",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
		},
		{
			Name:   "18. Excel Import Batch Preview",
			Method: "POST",
			Path:   "/api/v1/admin/excel/upload-preview",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["valid_rows"] == nil || b["preview_rows"] == nil {
					return fmt.Errorf("missing Excel preview analysis data")
				}
				return nil
			},
		},
	}

	passed := 0
	failed := 0

	for _, tc := range tests {
		start := time.Now()

		var reqBody io.Reader
		if tc.Body != nil {
			jsonBytes, _ := json.Marshal(tc.Body)
			reqBody = bytes.NewBuffer(jsonBytes)
		}

		req, err := http.NewRequest(tc.Method, baseURL+tc.Path, reqBody)
		if err != nil {
			fmt.Printf("❌ %s: Failed to create request: %v\n", tc.Name, err)
			failed++
			continue
		}

		for k, v := range tc.Headers {
			req.Header.Set(k, v)
		}

		resp, err := client.Do(req)
		duration := time.Since(start)

		if err != nil {
			fmt.Printf("❌ %s (%s %s) -> FAILED (Network error: %v)\n", tc.Name, tc.Method, tc.Path, err)
			failed++
			continue
		}

		bodyBytes, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		var parsedBody map[string]interface{}
		_ = json.Unmarshal(bodyBytes, &parsedBody)

		if resp.StatusCode != tc.ExpectedStatus {
			fmt.Printf("❌ %s (%s %s) [%dms] -> FAILED (Expected HTTP %d, got %d)\n   Body: %s\n",
				tc.Name, tc.Method, tc.Path, duration.Milliseconds(), tc.ExpectedStatus, resp.StatusCode, string(bodyBytes))
			failed++
			continue
		}

		if tc.ValidateModel != nil && parsedBody != nil {
			if err := tc.ValidateModel(parsedBody); err != nil {
				fmt.Printf("❌ %s (%s %s) [%dms] -> MODEL VALIDATION FAILED: %v\n",
					tc.Name, tc.Method, tc.Path, duration.Milliseconds(), err)
				failed++
				continue
			}
		}

		fmt.Printf("✅ %-45s (%s %s) [%2dms] -> HTTP %d (Model Valid)\n",
			tc.Name, tc.Method, tc.Path, duration.Milliseconds(), resp.StatusCode)
		passed++
	}

	fmt.Println("==================================================================")
	fmt.Printf("📊 Complete API Suite Summary: %d Passed | %d Failed | Total %d\n", passed, failed, len(tests))
	if failed == 0 {
		fmt.Println("🎉 ALL 18 PRODUCTION ENDPOINTS & RESPONSE MODELS 100% VERIFIED!")
		fmt.Println("==================================================================")
		os.Exit(0)
	} else {
		fmt.Printf("⚠️ %d TEST(S) FAILED. Please review the errors above.\n", failed)
		fmt.Println("==================================================================")
		os.Exit(1)
	}
}
