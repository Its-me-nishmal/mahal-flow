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
	Category       string
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

	tenant1 := "MH_001_CALICUT"
	tenant2 := "MH_002_KOCHI"

	fmt.Println("==================================================================")
	fmt.Println("🧪 MahalFlow Full Production Test Suite (Including RFC 10008 Query Engine)")
	fmt.Printf("🎯 Base URL: %s | Primary Tenant: %s | Secondary Tenant: %s\n", baseURL, tenant1, tenant2)
	fmt.Println("==================================================================")

	client := &http.Client{Timeout: 5 * time.Second}

	tests := []EndpointTest{
		// -------------------------------------------------------------
		// 1. CORE & HEALTH APIS
		// -------------------------------------------------------------
		{
			Name:           "1. Public Health Check",
			Category:       "CORE",
			Method:         "GET",
			Path:           "/health",
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["status"] != "healthy" || b["database"] != "connected" {
					return fmt.Errorf("expected healthy database connection")
				}
				return nil
			},
		},
		{
			Name:     "2. Member Dashboard Live Overview",
			Category: "CORE",
			Method:   "GET",
			Path:     "/api/v1/member/dashboard?member_id=MEM_001_9910",
			Headers:  map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["outstanding_balance"] == nil || b["member_name"] == nil {
					return fmt.Errorf("missing core dashboard attributes")
				}
				return nil
			},
		},

		// -------------------------------------------------------------
		// 2. CUTTING-EDGE: RFC 10008 STRUCTURED QUERY ENGINE
		// -------------------------------------------------------------
		{
			Name:     "3. RFC 10008: Structured Member Query Engine",
			Category: "RFC_10008",
			Method:   "POST",
			Path:     "/api/v1/admin/members/query",
			Headers: map[string]string{
				"X-Tenant-ID":            tenant1,
				"Content-Type":           "application/json",
				"X-HTTP-Method-Override": "QUERY",
			},
			Body: map[string]interface{}{
				"status":           "ACTIVE",
				"overdue_only":     true,
				"family_head_only": true,
				"page":             1,
				"limit":            25,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["protocol"] != "HTTP QUERY (RFC 10008)" {
					return fmt.Errorf("expected RFC 10008 protocol marker in response")
				}
				if b["members"] == nil || b["applied_filter"] == nil {
					return fmt.Errorf("missing query members or applied_filter")
				}
				return nil
			},
		},
		{
			Name:     "4. RFC 10008: Structured Financial Analytics Query",
			Category: "RFC_10008",
			Method:   "POST",
			Path:     "/api/v1/admin/reports/financial/query",
			Headers: map[string]string{
				"X-Tenant-ID":            tenant1,
				"Content-Type":           "application/json",
				"X-HTTP-Method-Override": "QUERY",
			},
			Body: map[string]interface{}{
				"from_date": "2026-01-01",
				"to_date":   "2026-08-31",
				"aggregate": "MONTHLY",
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["protocol"] != "HTTP QUERY (RFC 10008)" {
					return fmt.Errorf("expected RFC 10008 protocol marker")
				}
				return nil
			},
		},

		// -------------------------------------------------------------
		// 3. FINANCIAL INVARIANTS & EDGE CASES
		// -------------------------------------------------------------
		{
			Name:     "5. Invariant 1: Reject Non-Sequential Month Skipping",
			Category: "EDGE_CASE",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant1,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"selected_months": []string{"2026-11"}, // Skipping 2026-08, 2026-09, 2026-10!
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_SKIP_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 422, // Must be rejected with HTTP 422 Unprocessable Entity
		},
		{
			Name:     "6. Invariant 2: Reject Empty Month Selection",
			Category: "EDGE_CASE",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant1,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"selected_months": []string{}, // Empty array
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_EMPTY_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 422,
		},
		{
			Name:     "7. Invariant 3: Reject Zero/Negative Contribution",
			Category: "EDGE_CASE",
			Method:   "POST",
			Path:     "/api/v1/payments/contribution/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant1,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"amount":          -250.0, // Negative amount
				"purpose":         "Fraud attempt",
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_NEG_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 422, // Must be rejected
		},

		// -------------------------------------------------------------
		// 4. SECURITY & MULTI-TENANT ISOLATION
		// -------------------------------------------------------------
		{
			Name:     "8. Multi-Tenant Guard: Reject Cross-Tenant Access",
			Category: "SECURITY",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant2, // Tenant 2 (KOCHI)
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910", // Belongs to Tenant 1 (CALICUT)!
				"selected_months": []string{"2026-08"},
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_CROSS_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 422, // Blocked
		},
		{
			Name:     "9. Missing Tenant Header Guard (HTTP 400)",
			Category: "SECURITY",
			Method:   "GET",
			Path:     "/api/v1/admin/dashboard",
			ExpectedStatus: 400,
		},

		// -------------------------------------------------------------
		// 5. CRYPTOGRAPHIC INTEGRITY & AUTOPAY
		// -------------------------------------------------------------
		{
			Name:     "10. Cryptographic Receipt SHA-256 Chain Verification",
			Category: "CRYPTO",
			Method:   "GET",
			Path:     "/api/v1/receipts/GV1MH00120260515R00001/verify",
			Headers:  map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["cryptographic_valid"] != true {
					return fmt.Errorf("cryptographic verification failed on receipt chain")
				}
				return nil
			},
		},
		{
			Name:     "11. AutoPay e-Mandate Lifecycle Status",
			Category: "AUTOPAY",
			Method:   "GET",
			Path:     "/api/v1/autopay/mandate/status",
			Headers:  map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
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
			fmt.Printf("❌ [%s] %s: Failed to create request: %v\n", tc.Category, tc.Name, err)
			failed++
			continue
		}

		for k, v := range tc.Headers {
			req.Header.Set(k, v)
		}

		resp, err := client.Do(req)
		duration := time.Since(start)

		if err != nil {
			fmt.Printf("❌ [%s] %s -> FAILED (Network error: %v)\n", tc.Category, tc.Name, err)
			failed++
			continue
		}

		bodyBytes, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		var parsedBody map[string]interface{}
		_ = json.Unmarshal(bodyBytes, &parsedBody)

		if resp.StatusCode != tc.ExpectedStatus {
			fmt.Printf("❌ [%s] %-55s [%2dms] -> FAILED (Expected HTTP %d, got %d)\n   Body: %s\n",
				tc.Category, tc.Name, duration.Milliseconds(), tc.ExpectedStatus, resp.StatusCode, string(bodyBytes))
			failed++
			continue
		}

		if tc.ValidateModel != nil && parsedBody != nil {
			if err := tc.ValidateModel(parsedBody); err != nil {
				fmt.Printf("❌ [%s] %-55s [%2dms] -> MODEL VALIDATION FAILED: %v\n",
					tc.Category, tc.Name, duration.Milliseconds(), err)
				failed++
				continue
			}
		}

		fmt.Printf("✅ [%-9s] %-55s [%2dms] -> HTTP %d (Passed)\n",
			tc.Category, tc.Name, duration.Milliseconds(), resp.StatusCode)
		passed++
	}

	fmt.Println("==================================================================")
	fmt.Printf("📊 Complete Test Suite Summary: %d Passed | %d Failed | Total %d\n", passed, failed, len(tests))
	if failed == 0 {
		fmt.Println("🎉 ALL INVARIANTS, MULTI-TENANT & RFC 10008 QUERY ENGINE 100% VERIFIED!")
		fmt.Println("==================================================================")
		os.Exit(0)
	} else {
		fmt.Printf("⚠️ %d TEST(S) FAILED. Please review the errors above.\n", failed)
		fmt.Println("==================================================================")
		os.Exit(1)
	}
}
