package domain

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"
)

type SubscriptionStatus string

const (
	SubActive      SubscriptionStatus = "ACTIVE"
	SubGracePeriod SubscriptionStatus = "GRACE_PERIOD"
	SubReadOnly    SubscriptionStatus = "READ_ONLY"
	SubSuspended   SubscriptionStatus = "SUSPENDED"
)

type PaymentStatus string

const (
	TxnInitialized PaymentStatus = "INITIALIZED"
	TxnPending     PaymentStatus = "PENDING"
	TxnSuccess     PaymentStatus = "SUCCESS"
	TxnFailed      PaymentStatus = "FAILED"
	TxnRefunded    PaymentStatus = "REFUNDED"
)

// Mahal represents a Tenant organization
type Mahal struct {
	ID                 string             `bson:"_id" json:"id"`
	Name               string             `bson:"name" json:"name"`
	RegistrationNumber string             `bson:"registration_number" json:"registration_number"`
	Contact            MahalContact       `bson:"contact" json:"contact"`
	Settings           MahalSettings      `bson:"settings" json:"settings"`
	Subscription       MahalSubscription  `bson:"subscription" json:"subscription"`
	CreatedAt          time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt          time.Time          `bson:"updated_at" json:"updated_at"`
}

type MahalContact struct {
	Email   string `bson:"email" json:"email"`
	Phone   string `bson:"phone" json:"phone"`
	Address string `bson:"address" json:"address"`
}

type MahalSettings struct {
	Currency           string   `bson:"currency" json:"currency"`
	DefaultMonthlyDues float64  `bson:"default_monthly_dues" json:"default_monthly_dues"`
	DunningEnabled     bool     `bson:"dunning_enabled" json:"dunning_enabled"`
	PreferredLanguages []string `bson:"preferred_languages" json:"preferred_languages"`
	AutoPayAllowed     bool     `bson:"autopay_allowed" json:"autopay_allowed"`
}

type MahalSubscription struct {
	Plan              string             `bson:"plan" json:"plan"`
	MonthlyFee        float64            `bson:"monthly_fee" json:"monthly_fee"`
	Status            SubscriptionStatus `bson:"status" json:"status"`
	GracePeriodEndsAt *time.Time         `bson:"grace_period_ends_at,omitempty" json:"grace_period_ends_at,omitempty"`
	NextBillingDate   time.Time          `bson:"next_billing_date" json:"next_billing_date"`
}

// Member represents an individual community member
type Member struct {
	ID                     string    `bson:"_id" json:"id"`
	MahalID                string    `bson:"mahal_id" json:"mahal_id"`
	MemberCode             string    `bson:"member_code" json:"member_code"`
	Name                   string    `bson:"name" json:"name"`
	Phone                  string    `bson:"phone" json:"phone"`
	HouseName              string    `bson:"house_name" json:"house_name"`
	FamilyHead             bool      `bson:"family_head" json:"family_head"`
	FamilyMembersCount     int       `bson:"family_members_count" json:"family_members_count"`
	MonthlyDuesCustomAmount float64  `bson:"monthly_dues_custom_amount" json:"monthly_dues_custom_amount"`
	Status                 string    `bson:"status" json:"status"`
	LastPaidMonth          string    `bson:"last_paid_month" json:"last_paid_month"` // YYYY-MM
	OutstandingBalance     float64   `bson:"outstanding_balance" json:"outstanding_balance"`
	Version                int64     `bson:"version" json:"version"`
	CreatedAt              time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt              time.Time `bson:"updated_at" json:"updated_at"`
}

// Transaction represents a financial gateway attempt
type Transaction struct {
	ID               string        `bson:"_id" json:"id"`
	MahalID          string        `bson:"mahal_id" json:"mahal_id"`
	MemberID         string        `bson:"member_id" json:"member_id"`
	IdempotencyKey   string        `bson:"idempotency_key" json:"idempotency_key"`
	Type             string        `bson:"type" json:"type"` // MONTHLY_DUES | CONTRIBUTION
	Amount           float64       `bson:"amount" json:"amount"`
	Currency         string        `bson:"currency" json:"currency"`
	SelectedMonths   []string      `bson:"selected_months,omitempty" json:"selected_months,omitempty"`
	Gateway          string        `bson:"gateway" json:"gateway"`
	GatewayOrderID   string        `bson:"gateway_order_id,omitempty" json:"gateway_order_id,omitempty"`
	GatewayPaymentID string        `bson:"gateway_payment_id,omitempty" json:"gateway_payment_id,omitempty"`
	Status           PaymentStatus `bson:"status" json:"status"`
	FailureReason    string        `bson:"failure_reason,omitempty" json:"failure_reason,omitempty"`
	ReceiptID        string        `bson:"receipt_id,omitempty" json:"receipt_id,omitempty"`
	CreatedAt        time.Time     `bson:"created_at" json:"created_at"`
	CompletedAt      *time.Time    `bson:"completed_at,omitempty" json:"completed_at,omitempty"`
}

// Receipt is the immutable, cryptographically chained receipt
type Receipt struct {
	ID                  string    `bson:"_id" json:"id"`
	ReceiptNumber       string    `bson:"receipt_number" json:"receipt_number"`
	SequenceNumber      int64     `bson:"sequence_number" json:"sequence_number"`
	MahalID             string    `bson:"mahal_id" json:"mahal_id"`
	MemberID            string    `bson:"member_id" json:"member_id"`
	MemberName          string    `bson:"member_name" json:"member_name"`
	TransactionID       string    `bson:"transaction_id" json:"transaction_id"`
	PaymentType         string    `bson:"payment_type" json:"payment_type"`
	PaidMonths          []string  `bson:"paid_months,omitempty" json:"paid_months,omitempty"`
	Amount              float64   `bson:"amount" json:"amount"`
	PreviousReceiptHash string    `bson:"previous_receipt_hash" json:"previous_receipt_hash"`
	ReceiptHash         string    `bson:"receipt_hash" json:"receipt_hash"`
	PDFStorageURL       string    `bson:"pdf_storage_url,omitempty" json:"pdf_storage_url,omitempty"`
	CreatedAt           time.Time `bson:"created_at" json:"created_at"`
}

// CalculateReceiptHash computes the SHA-256 hash for blockchain-like integrity
func CalculateReceiptHash(receiptNum, mahalID, memberID string, amount float64, prevHash string) string {
	payload := fmt.Sprintf("%s:%s:%s:%.2f:%s", receiptNum, mahalID, memberID, amount, prevHash)
	hash := sha256.Sum256([]byte(payload))
	return hex.EncodeToString(hash[:])
}

// AuditLog captures auditable events with cryptographic chain integrity
type AuditLog struct {
	ID        string    `bson:"_id" json:"id"`
	MahalID   string    `bson:"mahal_id" json:"mahal_id"`
	Action    string    `bson:"action" json:"action"`
	Actor     string    `bson:"actor" json:"actor"`
	EntityID  string    `bson:"entity_id" json:"entity_id"`
	Details   string    `bson:"details,omitempty" json:"details,omitempty"`
	IPAddress string    `bson:"ip_address,omitempty" json:"ip_address,omitempty"`
	Timestamp time.Time `bson:"timestamp" json:"timestamp"`
}

// SystemAlert represents actionable system/security alerts
type SystemAlert struct {
	ID          string    `bson:"_id" json:"id"`
	MahalID     string    `bson:"mahal_id,omitempty" json:"mahal_id,omitempty"`
	Audience    string    `bson:"audience,omitempty" json:"audience,omitempty"` // ALL | OVERDUE_ONLY | FAMILY_HEADS
	Severity    string    `bson:"severity" json:"severity"` // CRITICAL | WARNING | INFO
	Title       string    `bson:"title" json:"title"`
	Description string    `bson:"description" json:"description"`
	Status      string    `bson:"status" json:"status"` // ACTIVE | ACKNOWLEDGED | RESOLVED
	CreatedAt   time.Time `bson:"created_at" json:"created_at"`
}

// RefundRequest represents a member refund dispute
type RefundRequest struct {
	ID            string     `bson:"_id" json:"id"`
	MahalID       string     `bson:"mahal_id" json:"mahal_id"`
	TransactionID string     `bson:"transaction_id" json:"transaction_id"`
	ReceiptNumber string     `bson:"receipt_number" json:"receipt_number"`
	MemberID      string     `bson:"member_id" json:"member_id"`
	MemberName    string     `bson:"member_name" json:"member_name"`
	Amount        float64    `bson:"amount" json:"amount"`
	Reason        string     `bson:"reason" json:"reason"`
	Status        string     `bson:"status" json:"status"` // PENDING | APPROVED | REJECTED | PROCESSED
	RequestedAt   time.Time  `bson:"requested_at" json:"requested_at"`
	ProcessedAt   *time.Time `bson:"processed_at,omitempty" json:"processed_at,omitempty"`
}

// SubscriptionInvoice represents SaaS billing records for a Mahal
type SubscriptionInvoice struct {
	ID          string    `bson:"_id" json:"id"`
	MahalID     string    `bson:"mahal_id" json:"mahal_id"`
	MahalName   string    `bson:"mahal_name" json:"mahal_name"`
	InvoiceNum  string    `bson:"invoice_num" json:"invoice_num"`
	Plan        string    `bson:"plan" json:"plan"`
	Amount      float64   `bson:"amount" json:"amount"`
	Status      string    `bson:"status" json:"status"` // PAID | PENDING | OVERDUE
	BillingDate time.Time `bson:"billing_date" json:"billing_date"`
	DueDate     time.Time `bson:"due_date" json:"due_date"`
}

// GatewayConfig represents configured payment processors
type GatewayConfig struct {
	ID        string    `bson:"_id" json:"id"`
	MahalID   string    `bson:"mahal_id" json:"mahal_id"`
	Provider  string    `bson:"provider" json:"provider"` // RAZORPAY | FEDERAL_BANK | CASH
	Status    string    `bson:"status" json:"status"`     // ACTIVE | INACTIVE
	IsPrimary bool      `bson:"is_primary" json:"is_primary"`
	KeyID     string    `bson:"key_id,omitempty" json:"key_id,omitempty"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
}

