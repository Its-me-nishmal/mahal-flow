package pg

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"
)

// Client represents a client for PayU Payment Gateway
type Client struct {
	BaseURL      string
	APIKey       string
	Salt         string
	ClientID     string
	ClientSecret string
	ReturnURL    string
	HTTPClient   *http.Client
	TestMode     bool
}

// Config parameters to initialize PG client
type Config struct {
	BaseURL      string
	APIKey       string
	Salt         string
	ClientID     string
	ClientSecret string
	ReturnURL    string
	TestMode     bool
	Timeout      time.Duration
}

// NewClient creates a new PG client instance
func NewClient(cfg Config) *Client {
	timeout := cfg.Timeout
	if timeout == 0 {
		timeout = 15 * time.Second
	}

	baseURL := strings.TrimRight(cfg.BaseURL, "/")
	if baseURL == "" {
		baseURL = "https://test.payu.in/_payment"
	}

	return &Client{
		BaseURL:      baseURL,
		APIKey:       cfg.APIKey,
		Salt:         cfg.Salt,
		ClientID:     cfg.ClientID,
		ClientSecret: cfg.ClientSecret,
		ReturnURL:    cfg.ReturnURL,
		HTTPClient: &http.Client{
			Timeout: timeout,
		},
		TestMode: cfg.TestMode,
	}
}

// ----------------------------------------------------------------------
// 1. PAYU HASH GENERATION & VERIFICATION
// ----------------------------------------------------------------------

// GeneratePayUHash generates SHA-512 hash as per PayU India Checkout Spec:
// sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||SALT)
func GeneratePayUHash(key, txnid, amount, productinfo, firstname, email, udf1, udf2, udf3, udf4, udf5, salt string) string {
	hashStr := fmt.Sprintf("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s||||||%s",
		key, txnid, amount, productinfo, firstname, email, udf1, udf2, udf3, udf4, udf5, salt)
	hasher := sha512.New()
	hasher.Write([]byte(hashStr))
	return strings.ToLower(hex.EncodeToString(hasher.Sum(nil)))
}

// GenerateDynamicHash computes hashes requested dynamically by PayU SDK
// For V1: sha512(hashString + salt)
// For V2: HMAC-SHA256(key=salt, data=hashString)
func (c *Client) GenerateDynamicHash(hashName, hashString, hashType, postSalt string) string {
	saltToUse := c.Salt
	if postSalt != "" {
		saltToUse = postSalt
	}

	if strings.EqualFold(hashType, "V2") {
		mac := hmac.New(sha256.New, []byte(saltToUse))
		mac.Write([]byte(hashString))
		return strings.ToLower(hex.EncodeToString(mac.Sum(nil)))
	}

	// Standard V1: sha512(hashString + salt)
	hasher := sha512.New()
	hasher.Write([]byte(hashString + saltToUse))
	return strings.ToLower(hex.EncodeToString(hasher.Sum(nil)))
}

// VerifyPayUResponseHash verifies reverse hash returned from PayU response/webhook:
// sha512(SALT|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key)
func VerifyPayUResponseHash(params map[string]string, salt, expectedHash string) bool {
	if expectedHash == "" {
		return false
	}
	key := params["key"]
	txnid := params["txnid"]
	amount := params["amount"]
	productinfo := params["productinfo"]
	firstname := params["firstname"]
	email := params["email"]
	udf1 := params["udf1"]
	udf2 := params["udf2"]
	udf3 := params["udf3"]
	udf4 := params["udf4"]
	udf5 := params["udf5"]
	status := params["status"]

	// Additional charges check (if PayU adds discount/charge hash prefix)
	var hashStr string
	if addCharges, ok := params["additionalCharges"]; ok && addCharges != "" {
		hashStr = fmt.Sprintf("%s|%s|%s||||||%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
			addCharges, salt, status, udf5, udf4, udf3, udf2, udf1, email, firstname, productinfo, amount, txnid, key)
	} else {
		hashStr = fmt.Sprintf("%s|%s||||||%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
			salt, status, udf5, udf4, udf3, udf2, udf1, email, firstname, productinfo, amount, txnid, key)
	}

	hasher := sha512.New()
	hasher.Write([]byte(hashStr))
	computed := strings.ToLower(hex.EncodeToString(hasher.Sum(nil)))
	return strings.EqualFold(computed, expectedHash)
}

// Legacy fallback helper for generic spec
func GenerateHash(params map[string]string, salt string) string {
	keys := make([]string, 0, len(params))
	for k := range params {
		if k == "hash" {
			continue
		}
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var sb strings.Builder
	sb.WriteString(salt)
	for _, k := range keys {
		val := strings.TrimSpace(params[k])
		if len(val) > 0 {
			sb.WriteString("|")
			sb.WriteString(val)
		}
	}
	hasher := sha512.New()
	hasher.Write([]byte(sb.String()))
	return strings.ToUpper(hex.EncodeToString(hasher.Sum(nil)))
}

// VerifyResponseHash checks PayU response hash first, falls back to generic
func VerifyResponseHash(params map[string]string, salt, expectedHash string) bool {
	if expectedHash == "" {
		return false
	}
	if VerifyPayUResponseHash(params, salt, expectedHash) {
		return true
	}
	computed := GenerateHash(params, salt)
	return strings.EqualFold(computed, expectedHash)
}

// ----------------------------------------------------------------------
// 2. DTO REQUEST & RESPONSE MODELS
// ----------------------------------------------------------------------

type PaymentRequestParams struct {
	OrderID         string
	Amount          string // e.g. "500.00"
	Currency        string // "INR"
	Description     string
	Name            string
	Email           string
	Phone           string
	City            string
	Country         string // "IND"
	ZipCode         string
	AddressLine1    string
	AddressLine2    string
	State           string
	ReturnURL       string
	ReturnURLFail   string
	ReturnURLCancel string
	ExpiryMinutes   string
	UDF1            string
	UDF2            string
	UDF3            string
	UDF4            string
	UDF5            string
	IsSI            bool
	SIDetails       string // JSON string with billingAmount, billingCycle, etc.
}

type PayUCheckoutFormData struct {
	Action      string            `json:"action"`
	Method      string            `json:"method"`
	Params      map[string]string `json:"params"`
	Hash        string            `json:"hash"`
	Key         string            `json:"key"`
	TxnID       string            `json:"txnid"`
	Amount      string            `json:"amount"`
	ProductInfo string            `json:"productinfo"`
	FirstName   string            `json:"firstname"`
	Email       string            `json:"email"`
	Phone       string            `json:"phone"`
	SURL        string            `json:"surl"`
	FURL        string            `json:"furl"`
}

type PaymentURLResponse struct {
	URL            string `json:"url"`
	UUID           string `json:"uuid"`
	ExpiryDatetime string `json:"expiry_datetime"`
	OrderID        string `json:"order_id"`
}

type IntentURLResponse struct {
	UPIIntentURL     string      `json:"upi_intent_url"`
	PaymentRequestID interface{} `json:"payment_request_id"`
	OrderID          string      `json:"order_id"`
}

type PaymentStatusResponse struct {
	TransactionID    string  `json:"transaction_id"`
	OrderID          string  `json:"order_id"`
	BankCode         string  `json:"bank_code"`
	PaymentMode      string  `json:"payment_mode"`
	PaymentChannel   string  `json:"payment_channel"`
	PaymentDatetime  string  `json:"payment_datetime"`
	ResponseCode     int     `json:"response_code"`
	ResponseMessage  string  `json:"response_message"`
	Amount           string  `json:"amount"`
	Currency         string  `json:"currency"`
	ErrorDesc        *string `json:"error_desc"`
	AuthorizationStatus *string `json:"authorization_staus"`
	Hash             string  `json:"hash"`
}

type RefundParams struct {
	TransactionID    string
	MerchantRefundID string
	Amount           string
	Description      string
}

type RefundResponse struct {
	TransactionID    string      `json:"transaction_id"`
	RefundID         interface{} `json:"refund_id"`
	RefundRefNo      *string     `json:"refund_reference_no"`
	MerchantRefundID string      `json:"merchant_refund_id"`
	MerchantOrderID  string      `json:"merchant_order_id"`
}

type QRStandeeInfo struct {
	MahalID          string  `json:"mahal_id"`
	MahalName        string  `json:"mahal_name"`
	VPA              string  `json:"vpa"`
	Amount           float64 `json:"amount,omitempty"`
	Purpose          string  `json:"purpose"`
	UPIPayload       string  `json:"upi_payload"`
	BharatQRPayload  string  `json:"bharat_qr_payload"`
	CategoryCode     string  `json:"category_code"`
	CounterLocation  string  `json:"counter_location"`
}

// ----------------------------------------------------------------------
// 3. API METHODS (HOSTED URL, INTENT URL, STATUS, REFUND)
// ----------------------------------------------------------------------

// GeneratePayUCheckoutParams builds the complete parameters and SHA512 hash for PayU India checkout
func (c *Client) GeneratePayUCheckoutParams(p PaymentRequestParams) PayUCheckoutFormData {
	productInfo := p.Description
	if productInfo == "" {
		productInfo = "Mahal Dues Contribution"
	}
	firstName := p.Name
	if firstName == "" {
		firstName = "Mahal Member"
	}
	email := p.Email
	if email == "" {
		email = "member@mahalflow.org"
	}
	phone := p.Phone
	if phone == "" {
		phone = "9900990099"
	}
	surl := p.ReturnURL
	if surl == "" {
		surl = c.ReturnURL
	}
	furl := p.ReturnURLFail
	if furl == "" {
		furl = c.ReturnURL
	}

	hash := GeneratePayUHash(c.APIKey, p.OrderID, p.Amount, productInfo, firstName, email, p.UDF1, p.UDF2, p.UDF3, p.UDF4, p.UDF5, c.Salt)

	params := map[string]string{
		"key":          c.APIKey,
		"txnid":        p.OrderID,
		"amount":       p.Amount,
		"productinfo":  productInfo,
		"firstname":    firstName,
		"email":        email,
		"phone":        phone,
		"surl":         surl,
		"furl":         furl,
		"hash":         hash,
		"service_provider": "payu_paisa",
	}
	if p.UDF1 != "" {
		params["udf1"] = p.UDF1
	}
	if p.UDF2 != "" {
		params["udf2"] = p.UDF2
	}
	if p.UDF3 != "" {
		params["udf3"] = p.UDF3
	}
	if p.UDF4 != "" {
		params["udf4"] = p.UDF4
	}
	if p.UDF5 != "" {
		params["udf5"] = p.UDF5
	}
	if p.IsSI {
		params["si"] = "1"
		if p.SIDetails != "" {
			params["si_details"] = p.SIDetails
		}
	}

	actionURL := c.BaseURL
	if actionURL == "" {
		actionURL = "https://test.payu.in/_payment"
	}

	return PayUCheckoutFormData{
		Action:      actionURL,
		Method:      "POST",
		Params:      params,
		Hash:        hash,
		Key:         c.APIKey,
		TxnID:       p.OrderID,
		Amount:      p.Amount,
		ProductInfo: productInfo,
		FirstName:   firstName,
		Email:       email,
		Phone:       phone,
		SURL:        surl,
		FURL:        furl,
	}
}

// GetPaymentRequestURL: Returns hosted checkout URL for Web/Mobile Webview
func (c *Client) GetPaymentRequestURL(ctx context.Context, p PaymentRequestParams) (*PaymentURLResponse, error) {
	if c.BaseURL == "" || c.APIKey == "" || c.TestMode {
		// Mock simulated payment execution URL for development/test mode
		mockUUID := fmt.Sprintf("sim_%d", time.Now().UnixNano())
		return &PaymentURLResponse{
			URL:            fmt.Sprintf("http://localhost:8080/api/v1/mock-checkout/%s", mockUUID),
			UUID:           mockUUID,
			ExpiryDatetime: time.Now().Add(15 * time.Minute).Format("2006-01-02 15:04:05"),
			OrderID:        p.OrderID,
		}, nil
	}

	// PayU India hosted checkout URL via app checkout portal
	checkoutURL := fmt.Sprintf("http://localhost:8080/api/v1/payments/payu-checkout/%s", p.OrderID)
	return &PaymentURLResponse{
		URL:            checkoutURL,
		UUID:           p.OrderID,
		ExpiryDatetime: time.Now().Add(30 * time.Minute).Format("2006-01-02 15:04:05"),
		OrderID:        p.OrderID,
	}, nil
}

// GetPaymentRequestIntentURL (Section 5): Returns upi_intent_url for direct UPI apps
func (c *Client) GetPaymentRequestIntentURL(ctx context.Context, p PaymentRequestParams) (*IntentURLResponse, error) {
	if c.BaseURL == "" || c.APIKey == "" || c.TestMode {
		// Generate standard UPI spec intent url for test simulation
		mockReqID := time.Now().Unix()
		upiURL := fmt.Sprintf("upi://pay?pa=mahalflow@bank&pn=MahalFlow+Treasury&am=%s&cu=INR&tr=%s&tn=Dues+for+%s",
			url.QueryEscape(p.Amount), url.QueryEscape(p.OrderID), url.QueryEscape(p.OrderID))
		return &IntentURLResponse{
			UPIIntentURL:     upiURL,
			PaymentRequestID: mockReqID,
			OrderID:          p.OrderID,
		}, nil
	}

	params := c.buildBaseParams(p)
	params["hash"] = GenerateHash(params, c.Salt)

	apiURL := c.BaseURL + "/v2/getpaymentrequestintenturl"
	respBody, err := c.postForm(ctx, apiURL, params)
	if err != nil {
		return nil, err
	}

	var res struct {
		Data  *IntentURLResponse `json:"data"`
		Error *struct {
			Code    interface{} `json:"code"`
			Message string      `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(respBody, &res); err != nil {
		return nil, fmt.Errorf("failed to parse PG response: %w", err)
	}

	if res.Error != nil {
		return nil, fmt.Errorf("PG intent error [%v]: %s", res.Error.Code, res.Error.Message)
	}

	if res.Data == nil {
		return nil, errors.New("empty intent data received from PG")
	}

	return res.Data, nil
}

// GetPaymentStatus (Section 6): Queries PG system for reconciliation
func (c *Client) GetPaymentStatus(ctx context.Context, orderID, transactionID string) (*PaymentStatusResponse, error) {
	if c.BaseURL == "" || c.APIKey == "" || c.TestMode {
		return &PaymentStatusResponse{
			TransactionID:   "SIM_" + transactionID,
			OrderID:         orderID,
			PaymentMode:     "UPI",
			PaymentChannel:  "BHIM UPI",
			PaymentDatetime: time.Now().Format("2006-01-02 15:04:05"),
			ResponseCode:    0,
			ResponseMessage: "SUCCESS",
		}, nil
	}

	params := map[string]string{
		"api_key": c.APIKey,
	}
	if orderID != "" {
		params["order_id"] = orderID
	}
	if transactionID != "" {
		params["transaction_id"] = transactionID
	}
	params["hash"] = GenerateHash(params, c.Salt)

	apiURL := c.BaseURL + "/v2/paymentstatus"
	respBody, err := c.postForm(ctx, apiURL, params)
	if err != nil {
		return nil, err
	}

	var res struct {
		Data []PaymentStatusResponse `json:"data"`
		Hash string                  `json:"hash"`
		Error *struct {
			Code    interface{} `json:"code"`
			Message string      `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(respBody, &res); err != nil {
		return nil, fmt.Errorf("failed to decode payment status response: %w", err)
	}

	if res.Error != nil {
		return nil, fmt.Errorf("PG payment status error [%v]: %s", res.Error.Code, res.Error.Message)
	}

	if len(res.Data) == 0 {
		return nil, errors.New("no transaction records found")
	}

	return &res.Data[0], nil
}

// RequestRefund (Section 7.1): Issues programmatic refund for a successful transaction
func (c *Client) RequestRefund(ctx context.Context, p RefundParams) (*RefundResponse, error) {
	if c.BaseURL == "" || c.APIKey == "" || c.TestMode {
		refNo := fmt.Sprintf("REF_%d", time.Now().Unix())
		return &RefundResponse{
			TransactionID:    p.TransactionID,
			RefundID:         time.Now().UnixNano() / 1e6,
			RefundRefNo:      &refNo,
			MerchantRefundID: p.MerchantRefundID,
			MerchantOrderID:  "ORD_" + p.TransactionID,
		}, nil
	}

	params := map[string]string{
		"api_key":            c.APIKey,
		"transaction_id":     p.TransactionID,
		"merchant_refund_id": p.MerchantRefundID,
		"amount":             p.Amount,
		"description":        p.Description,
	}
	params["hash"] = GenerateHash(params, c.Salt)

	apiURL := c.BaseURL + "/v2/refundrequest"
	respBody, err := c.postForm(ctx, apiURL, params)
	if err != nil {
		return nil, err
	}

	var res struct {
		Data  *RefundResponse `json:"data"`
		Error *struct {
			Code    interface{} `json:"code"`
			Message string      `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(respBody, &res); err != nil {
		return nil, fmt.Errorf("failed to parse PG refund response: %w", err)
	}

	if res.Error != nil {
		return nil, fmt.Errorf("PG refund error [%v]: %s", res.Error.Code, res.Error.Message)
	}

	if res.Data == nil {
		return nil, errors.New("empty refund data received from PG")
	}

	return res.Data, nil
}

// GenerateQRStandee (Section 9 & BharatQR Appendix): Generates static or dynamic QR payload for physical standee
func (c *Client) GenerateQRStandee(mahalID, mahalName string, amount float64, purpose, counter string) *QRStandeeInfo {
	if mahalName == "" {
		mahalName = "MahalFlow Treasury"
	}
	if purpose == "" {
		purpose = "MAHAL_GENERAL_FUND"
	}
	if counter == "" {
		counter = "MAIN_GATE_COUNTER"
	}

	vpa := "mahalflow." + strings.ToLower(mahalID) + "@bank"
	encodedName := url.QueryEscape(mahalName)
	encodedPurpose := url.QueryEscape(purpose)

	var upiPayload string
	if amount > 0 {
		upiPayload = fmt.Sprintf("upi://pay?pa=%s&pn=%s&am=%.2f&cu=INR&tn=%s&mc=8699",
			vpa, encodedName, amount, encodedPurpose)
	} else {
		// Static open amount QR
		upiPayload = fmt.Sprintf("upi://pay?pa=%s&pn=%s&cu=INR&tn=%s&mc=8699",
			vpa, encodedName, encodedPurpose)
	}

	// BharatQR / EMVCo Merchant-Presented QR specification string
	// Tag 00: Format Indicator (01)
	// Tag 01: Initiation Method (11=Static, 12=Dynamic)
	// Tag 26: Merchant Account Info (UPI/BharatQR)
	// Tag 52: MCC (8699 Religious Organisations)
	// Tag 53: Currency (356 = INR)
	initMethod := "11"
	if amount > 0 {
		initMethod = "12"
	}
	bharatQRPayload := fmt.Sprintf("0002010102%s26%02d0010A00000052401%02d%s5204869953033565802IN59%02d%s6007CALICUT",
		initMethod,
		len("0010A00000052401") + 2 + len(vpa),
		len(vpa), vpa,
		len(mahalName), mahalName,
	)

	return &QRStandeeInfo{
		MahalID:         mahalID,
		MahalName:       mahalName,
		VPA:             vpa,
		Amount:          amount,
		Purpose:         purpose,
		UPIPayload:      upiPayload,
		BharatQRPayload: bharatQRPayload,
		CategoryCode:    "8699 - Religious & Community Organizations",
		CounterLocation: counter,
	}
}

// ----------------------------------------------------------------------
// 4. HELPERS
// ----------------------------------------------------------------------

func (c *Client) buildBaseParams(p PaymentRequestParams) map[string]string {
	params := map[string]string{
		"api_key":     c.APIKey,
		"order_id":    p.OrderID,
		"amount":      p.Amount,
		"currency":    p.Currency,
		"description": p.Description,
		"name":        p.Name,
		"email":       p.Email,
		"phone":       p.Phone,
		"city":        p.City,
		"country":     p.Country,
		"zip_code":    p.ZipCode,
	}

	if p.Currency == "" {
		params["currency"] = "INR"
	}
	if p.Country == "" {
		params["country"] = "IND"
	}
	if p.City == "" {
		params["city"] = "Calicut"
	}
	if p.ZipCode == "" {
		params["zip_code"] = "673001"
	}

	returnURL := p.ReturnURL
	if returnURL == "" {
		returnURL = c.ReturnURL
	}
	params["return_url"] = returnURL

	if p.ReturnURLFail != "" {
		params["return_url_failure"] = p.ReturnURLFail
	}
	if p.ReturnURLCancel != "" {
		params["return_url_cancel"] = p.ReturnURLCancel
	}
	if p.AddressLine1 != "" {
		params["address_line_1"] = p.AddressLine1
	}
	if p.AddressLine2 != "" {
		params["address_line_2"] = p.AddressLine2
	}
	if p.State != "" {
		params["state"] = p.State
	}
	if p.UDF1 != "" {
		params["udf1"] = p.UDF1
	}
	if p.UDF2 != "" {
		params["udf2"] = p.UDF2
	}
	if p.UDF3 != "" {
		params["udf3"] = p.UDF3
	}

	return params
}

func (c *Client) postForm(ctx context.Context, endpoint string, params map[string]string) ([]byte, error) {
	form := url.Values{}
	for k, v := range params {
		form.Set(k, v)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed reading response body: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return body, fmt.Errorf("PG returned status %d: %s", resp.StatusCode, string(body))
	}

	return body, nil
}
