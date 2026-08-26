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
	fmt.Println("🧪 MahalFlow Automated API & Route Validation Test Suite")
	fmt.Printf("🎯 Target Base URL: %s | Tenant: %s\n", baseURL, tenantID)
	fmt.Println("==================================================================")

	client := &http.Client{Timeout: 5 * time.Second}

	// 1. Health Check
	tests := []EndpointTest{
		{
			Name:           "1. Public Health Check",
			Method:         "GET",
			Path:           "/health",
			Headers:        map[string]string{},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["status"] != "healthy" {
					return fmt.Errorf("expected status 'healthy', got '%v'", b["status"])
				}
				if b["database"] != "connected" {
					return fmt.Errorf("expected database 'connected', got '%v'", b["database"])
				}
				return nil
			},
		},
		{
			Name:   "2. Member Dashboard Live Overview",
			Method: "GET",
			Path:   "/api/v1/member/dashboard?member_id=MEM_001_9910",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["member_name"] == nil {
					return fmt.Errorf("missing 'member_name' in payload")
				}
				if b["outstanding_balance"] == nil {
					return fmt.Errorf("missing 'outstanding_balance' in payload")
				}
				return nil
			},
		},
		{
			Name:   "3. Admin Operations Dashboard Metrics",
			Method: "GET",
			Path:   "/api/v1/admin/dashboard",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["total_members"] == nil || b["subscription_status"] == nil {
					return fmt.Errorf("missing 'total_members' or 'subscription_status'")
				}
				return nil
			},
		},
		{
			Name:   "4. Admin Paginated Members Directory",
			Method: "GET",
			Path:   "/api/v1/admin/members?page=1&limit=10",
			Headers: map[string]string{
				"X-Tenant-ID": tenantID,
			},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				members, ok := b["members"].([]interface{})
				if !ok || len(members) == 0 {
					return fmt.Errorf("expected non-empty members array")
				}
				return nil
			},
		},
		{
			Name:   "5. Initialize Dues Payment (Dynamic Calculation)",
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
				if b["transaction_id"] == nil {
					return fmt.Errorf("missing 'transaction_id' in response")
				}
				if b["amount"] == nil || b["amount"].(float64) <= 0 {
					return fmt.Errorf("invalid or zero 'amount' calculated")
				}
				return nil
			},
		},
		{
			Name:   "6. Initialize Voluntary Contribution",
			Method: "POST",
			Path:   "/api/v1/payments/contribution/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenantID,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"amount":          1000.0,
				"purpose":         "Friday Community Meal Fund",
				"gateway":         "RAZORPAY",
				"idempotency_key": "IDEMP_CONTRIB_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["transaction_id"] == nil || b["currency"] != "INR" {
					return fmt.Errorf("invalid contribution transaction payload")
				}
				return nil
			},
		},
		{
			Name:   "7. Missing Tenant Header Guard (Security Invariant)",
			Method: "GET",
			Path:   "/api/v1/admin/dashboard",
			Headers: map[string]string{
				// Intentionally omitting X-Tenant-ID
			},
			ExpectedStatus: 400,
			ValidateModel: func(b map[string]interface{}) error {
				errObj, ok := b["error"].(map[string]interface{})
				if !ok || errObj["code"] != "MISSING_TENANT_ID" {
					return fmt.Errorf("expected error code 'MISSING_TENANT_ID', got %v", b)
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

		if tc.ValidateModel != nil {
			if err := tc.ValidateModel(parsedBody); err != nil {
				fmt.Printf("❌ %s (%s %s) [%dms] -> MODEL VALIDATION FAILED: %v\n",
					tc.Name, tc.Method, tc.Path, duration.Milliseconds(), err)
				failed++
				continue
			}
		}

		fmt.Printf("✅ %s (%s %s) [%dms] -> HTTP %d (Model Valid)\n",
			tc.Name, tc.Method, tc.Path, duration.Milliseconds(), resp.StatusCode)
		passed++
	}

	fmt.Println("==================================================================")
	fmt.Printf("📊 Test Summary: %d Passed | %d Failed | Total %d\n", passed, failed, len(tests))
	if failed == 0 {
		fmt.Println("🎉 ALL ROUTES & API MODEL VALIDATIONS PASSED PERFECTLY!")
		fmt.Println("==================================================================")
		os.Exit(0)
	} else {
		fmt.Printf("⚠️ %d TEST(S) FAILED. Please review the errors above.\n", failed)
		fmt.Println("==================================================================")
		os.Exit(1)
	}
}
