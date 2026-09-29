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
	Name     string
	Category string
	Method   string
	Path     string
	// PathFn, when set, builds the path at run time (from earlier results).
	PathFn func() string
	// Auth is "member" (default for tenant routes), "admin" or "none".
	Auth           string
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

	// Every tenant route needs a MahalFlow JWT.
	//   admin:  POST /auth/login with ADMIN_PHONE + ADMIN_PASSWORD (set the
	//           password with `go run ./cmd/setpassword`), or ADMIN_TOKEN.
	//   member: MEMBER_TOKEN, else POST /auth/resolve with MEMBER_PHONE — only
	//           works against a local server started with AUTH_DEV_BYPASS=true.
	adminPhone := envOr("ADMIN_PHONE", "9847111222")
	adminPassword := os.Getenv("ADMIN_PASSWORD")
	adminToken := bearer(os.Getenv("ADMIN_TOKEN"))
	if adminToken == "" && adminPassword != "" {
		adminToken = bearer(postForToken(client, baseURL+"/api/v1/auth/login", "", map[string]string{
			"phone": adminPhone, "password": adminPassword, "mahal_id": tenant1,
		}))
	}
	memberToken := bearer(os.Getenv("MEMBER_TOKEN"))
	if memberToken == "" {
		memberToken = bearer(postForToken(client, baseURL+"/api/v1/auth/resolve", tenant1, map[string]string{
			"phone": envOr("MEMBER_PHONE", "+919847111222"),
		}))
	}
	if adminToken == "" {
		fmt.Println("⚠️  No admin token (set ADMIN_PASSWORD or ADMIN_TOKEN): admin tests will fail with 401")
	}
	if memberToken == "" {
		fmt.Println("⚠️  No member token (set MEMBER_TOKEN, or run the server with AUTH_DEV_BYPASS=true): member tests will fail with 401")
	}
	var lastOrderID string
	// Dues must start right after the member's last paid month.
	nextDueMonth := nextMonthAfter(fetchLastPaidMonth(client, baseURL, tenant1, memberToken))

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
			Name:           "2. Member Dashboard Live Overview",
			Category:       "CORE",
			Method:         "GET",
			Path:           "/api/v1/member/dashboard?member_id=MEM_001_9910",
			Headers:        map[string]string{"X-Tenant-ID": tenant1},
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
				"Authorization":          adminToken,
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
				"Authorization":          adminToken,
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
			// The tenant-1 session is refused by the JWT tenant check before
			// the request reaches the payment engine.
			ExpectedStatus: 403,
		},
		{
			Name:           "9. Missing Tenant Header Guard (HTTP 400)",
			Category:       "SECURITY",
			Method:         "GET",
			Path:           "/api/v1/admin/dashboard",
			ExpectedStatus: 400,
		},

		// -------------------------------------------------------------
		// 5. CRYPTOGRAPHIC INTEGRITY & AUTOPAY
		// -------------------------------------------------------------
		{
			Name:           "10. Cryptographic Receipt SHA-256 Chain Verification",
			Category:       "CRYPTO",
			Method:         "GET",
			Path:           "/api/v1/receipts/GV1MH00120260515R00001/verify",
			Headers:        map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["cryptographic_valid"] != true {
					return fmt.Errorf("cryptographic verification failed on receipt chain")
				}
				return nil
			},
		},
		{
			Name:           "11. AutoPay e-Mandate Lifecycle Status",
			Category:       "AUTOPAY",
			Method:         "GET",
			Path:           "/api/v1/autopay/mandate/status",
			Headers:        map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
		},
		{
			Name:     "12. PayU: Initialize Dues Payment",
			Category: "PAYU",
			Method:   "POST",
			Path:     "/api/v1/payments/dues/initialize",
			Headers: map[string]string{
				"X-Tenant-ID":  tenant1,
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"member_id":       "MEM_001_9910",
				"selected_months": []string{nextDueMonth},
				"gateway":         "PAYU",
				"idempotency_key": "IDEMP_PAYU_" + uuid.New().String()[:8],
			},
			ExpectedStatus: 201,
			ValidateModel: func(b map[string]interface{}) error {
				if b["payment_url"] == nil || b["gateway_order_id"] == nil {
					return fmt.Errorf("expected payment_url and gateway_order_id in PayU response")
				}
				lastOrderID, _ = b["gateway_order_id"].(string)
				return nil
			},
		},
		{
			Name:           "13. PayU: Checkout Data for the order from test 12",
			Category:       "PAYU",
			Method:         "GET",
			PathFn:         func() string { return "/api/v1/payments/payu-checkout-data/" + lastOrderID },
			Headers:        map[string]string{"X-Tenant-ID": tenant1},
			ExpectedStatus: 200,
			ValidateModel: func(b map[string]interface{}) error {
				if b["hash"] == nil || b["action"] == nil || b["txnid"] != lastOrderID {
					return fmt.Errorf("invalid PayU checkout payload")
				}
				return nil
			},
		},
		{
			Name:     "14. Public Auth: Login Endpoint",
			Category: "AUTH",
			Auth:     "none",
			Method:   "POST",
			Path:     "/api/v1/auth/login",
			Headers: map[string]string{
				"Content-Type": "application/json",
			},
			Body: map[string]interface{}{
				"phone":    adminPhone,
				"password": adminPassword,
				"mahal_id": tenant1,
			},
			ExpectedStatus: loginExpectation(adminPassword),
			ValidateModel: func(b map[string]interface{}) error {
				if adminPassword != "" && (b["token"] == nil || b["role"] == nil) {
					return fmt.Errorf("missing token or role in login response")
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

		path := tc.Path
		if tc.PathFn != nil {
			path = tc.PathFn()
		}
		req, err := http.NewRequest(tc.Method, baseURL+path, reqBody)
		if err != nil {
			fmt.Printf("❌ [%s] %s: Failed to create request: %v\n", tc.Category, tc.Name, err)
			failed++
			continue
		}

		for k, v := range tc.Headers {
			req.Header.Set(k, v)
		}
		if req.Header.Get("Authorization") == "" && tc.Headers["X-Tenant-ID"] != "" {
			switch tc.Auth {
			case "none":
			case "admin":
				req.Header.Set("Authorization", adminToken)
			default:
				req.Header.Set("Authorization", memberToken)
			}
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

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func bearer(tok string) string {
	if tok == "" {
		return ""
	}
	return "Bearer " + tok
}

// loginExpectation: with no password configured the login test checks that
// the server refuses a password-less login.
func loginExpectation(password string) int {
	if password == "" {
		return 400
	}
	return 200
}

// postForToken POSTs body and returns the "token" field of a 200 response.
func postForToken(client *http.Client, url, tenant string, body map[string]string) string {
	payload, _ := json.Marshal(body)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(payload))
	if err != nil {
		return ""
	}
	req.Header.Set("Content-Type", "application/json")
	if tenant != "" {
		req.Header.Set("X-Tenant-ID", tenant)
	}
	resp, err := client.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return ""
	}
	var out map[string]interface{}
	if json.NewDecoder(resp.Body).Decode(&out) != nil {
		return ""
	}
	t, _ := out["token"].(string)
	return t
}

func fetchLastPaidMonth(client *http.Client, baseURL, tenant, auth string) string {
	req, _ := http.NewRequest("GET", baseURL+"/api/v1/member/dashboard?member_id=MEM_001_9910", nil)
	req.Header.Set("X-Tenant-ID", tenant)
	req.Header.Set("Authorization", auth)
	resp, err := client.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	var out map[string]interface{}
	_ = json.NewDecoder(resp.Body).Decode(&out)
	s, _ := out["last_paid_month"].(string)
	return s
}

func nextMonthAfter(month string) string {
	t, err := time.Parse("2006-01", month)
	if err != nil {
		return time.Now().Format("2006-01")
	}
	return t.AddDate(0, 1, 0).Format("2006-01")
}
