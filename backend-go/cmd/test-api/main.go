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
	fmt.Println("🧪 MahalFlow Invariant, Edge Case & Multi-Tenant Test Engine")
	fmt.Printf("🎯 Base URL: %s | Primary Tenant: %s | Secondary Tenant: %s\n", baseURL, tenant1, tenant2)
	fmt.Println("==================================================================")

	client := &http.Client{Timeout: 5 * time.Second}

	tests := []EndpointTest{
		// -------------------------------------------------------------
		// CATEGORY 1: HAPPY PATH CORE APIS
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
		{
			Name:     "3. Valid Sequential Dues Payment Initialization",
			Category: "CORE",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant1,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"selected_months": []string{"2026-08"}, // Valid next sequential month after 2026-07
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["amount"].(float64) != 500.0 {
					return fmt.Errorf("expected amount 500.0, got %v", b["amount"])
				}
				return nil
			},
		},

		// -------------------------------------------------------------
		// CATEGORY 2: FINANCIAL INVARIANTS & EDGE CASES
		// -------------------------------------------------------------
		{
			Name:     "4. Invariant 1: Reject Non-Sequential Month Skipping",
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
			ValidateModel: func(b map[string]interface{}) error {
				if b["error"] == nil {
					return fmt.Errorf("expected error message rejecting non-sequential month")
				}
				return nil
			},
		},
		{
			Name:     "5. Invariant 2: Reject Empty Month Selection",
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
			Name:     "6. Invariant 3: Reject Zero/Negative Contribution Amount",
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
		// CATEGORY 3: MULTI-TENANT ISOLATION SECURITY
		// -------------------------------------------------------------
		{
			Name:     "7. Multi-Tenant Guard: Reject Cross-Tenant Member Access",
			Category: "SECURITY",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant2, // Tenant 2 (KOCHI)
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910", // Member belonging to Tenant 1 (CALICUT)!
				"selected_months": []string{"2026-08"},
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_CROSS_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 422, // Rejected because member does NOT exist under Tenant 2
		},
		{
			Name:     "8. Missing Tenant Header Guard (HTTP 400)",
			Category: "SECURITY",
			Method:   "GET",
			Path:     "/api/v1/admin/dashboard",
			Headers: map[string]string{
				// No X-Tenant-ID
			},
			ExpectedStatus: 400,
		},

		// -------------------------------------------------------------
		// CATEGORY 4: CRYPTOGRAPHIC SHA-256 INTEGRITY
		// -------------------------------------------------------------
		{
			Name:     "9. Cryptographic Receipt SHA-256 Chain Verification",
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
			Name:     "10. AutoPay e-Mandate Active Lifecycle",
			Category: "AUTOPAY",
			Method:   "GET",
			Path:     "/api/v1/autopay/mandate/status",
			Headers:  map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["status"] != "ACTIVE" {
					return fmt.Errorf("expected active mandate status")
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
	fmt.Printf("📊 Scenario & Edge Case Summary: %d Passed | %d Failed | Total %d\n", passed, failed, len(tests))
	if failed == 0 {
		fmt.Println("🎉 ALL FINANCIAL INVARIANTS, MULTI-TENANT & EDGE CASES 100% VERIFIED!")
		fmt.Println("==================================================================")
		os.Exit(0)
	} else {
		fmt.Printf("⚠️ %d TEST(S) FAILED. Please review the errors above.\n", failed)
		fmt.Println("==================================================================")
		os.Exit(1)
	}
}
