package domain

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
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
	ID                 string            `bson:"_id" json:"id"`
	Name               string            `bson:"name" json:"name"`
	RegistrationNumber string            `bson:"registration_number" json:"registration_number"`
	Contact            MahalContact      `bson:"contact" json:"contact"`
	Settings           MahalSettings     `bson:"settings" json:"settings"`
	Subscription       MahalSubscription `bson:"subscription" json:"subscription"`
	CreatedAt          time.Time         `bson:"created_at" json:"created_at"`
	UpdatedAt          time.Time         `bson:"updated_at" json:"updated_at"`
}

type MahalContact struct {
	Email string `bson:"email" json:"email"`
	Phone string `bson:"phone" json:"phone"`
	// WhatsApp is the committee's WhatsApp number when it differs from Phone.
	WhatsApp string `bson:"whatsapp,omitempty" json:"whatsapp,omitempty"`
	Address  string `bson:"address" json:"address"`
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
	ID                      string  `bson:"_id" json:"id"`
	MahalID                 string  `bson:"mahal_id" json:"mahal_id"`
	MemberCode              string  `bson:"member_code" json:"member_code"`
	Name                    string  `bson:"name" json:"name"`
	Phone                   string  `bson:"phone" json:"phone"`
	HouseName               string  `bson:"house_name" json:"house_name"`
	FamilyHead              bool    `bson:"family_head" json:"family_head"`
	FamilyMembersCount      int     `bson:"family_members_count" json:"family_members_count"`
	MonthlyDuesCustomAmount float64 `bson:"monthly_dues_custom_amount" json:"monthly_dues_custom_amount"`
	Status                  string  `bson:"status" json:"status"`
	// Personal details the member (or committee) can edit on the profile.
	Email    string `bson:"email,omitempty" json:"email,omitempty"`
	Address2 string `bson:"address2,omitempty" json:"address2,omitempty"`
	City     string `bson:"city,omitempty" json:"city,omitempty"`
	State    string `bson:"state,omitempty" json:"state,omitempty"`
	Pincode  string `bson:"pincode,omitempty" json:"pincode,omitempty"`
	// ApprovalDecision / ApprovalDecidedAt record the committee's last
	// approve (ACTIVE) or reject (REJECTED) of a self-registration, so the
	// decision can be reverted for a short window.
	ApprovalDecision  string     `bson:"approval_decision,omitempty" json:"approval_decision,omitempty"`
	ApprovalDecidedAt *time.Time `bson:"approval_decided_at,omitempty" json:"approval_decided_at,omitempty"`
	// ImportBatchID is set on members created by an Excel import.
	ImportBatchID      string    `bson:"import_batch_id,omitempty" json:"import_batch_id,omitempty"`
	LastPaidMonth      string    `bson:"last_paid_month" json:"last_paid_month"` // YYYY-MM
	OutstandingBalance float64   `bson:"outstanding_balance" json:"outstanding_balance"`
	Version            int64     `bson:"version" json:"version"`
	CreatedAt          time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt          time.Time `bson:"updated_at" json:"updated_at"`
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
	// Purpose is the fund a contribution goes to (e.g. ZAKAT, BUILDING_FUND);
	// Note is the member's free-text message. Both copied onto the receipt.
	Purpose string `bson:"purpose,omitempty" json:"purpose,omitempty"`
	Note    string `bson:"note,omitempty" json:"note,omitempty"`
	// PaymentMode is the instrument PayU reported (UPI, CARD, NETBANKING,
	// WALLET) or CASH; empty when unknown.
	PaymentMode string     `bson:"payment_mode,omitempty" json:"payment_mode,omitempty"`
	ReceiptID   string     `bson:"receipt_id,omitempty" json:"receipt_id,omitempty"`
	CreatedAt   time.Time  `bson:"created_at" json:"created_at"`
	CompletedAt *time.Time `bson:"completed_at,omitempty" json:"completed_at,omitempty"`
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

	// Descriptive fields, copied from the transaction when the receipt is
	// issued. They are deliberately NOT part of the hash input
	// (CalculateReceiptHash), so receipts issued before these existed keep
	// verifying. Status is SUCCESS at issue; API reads report REFUNDED once
	// the transaction is refunded (the stored receipt is never modified).
	Status        string     `bson:"status,omitempty" json:"status,omitempty"`                 // SUCCESS | REFUNDED
	Gateway       string     `bson:"gateway,omitempty" json:"gateway,omitempty"`               // PAYU | PAYU_SI | CASH
	PaymentMethod string     `bson:"payment_method,omitempty" json:"payment_method,omitempty"` // UPI | CARD | NETBANKING | WALLET | CASH
	Fund          string     `bson:"fund,omitempty" json:"fund,omitempty"`
	Note          string     `bson:"note,omitempty" json:"note,omitempty"`
	RefundedAt    *time.Time `bson:"-" json:"refunded_at,omitempty"`
}

// Receipt statuses.
const (
	ReceiptStatusSuccess  = "SUCCESS"
	ReceiptStatusRefunded = "REFUNDED"
)

// NormalizePaymentMode maps PayU's `mode` (CC, DC, NB, UPI, PPI, ...) and our
// own gateway names to the receipt's payment_method vocabulary.
func NormalizePaymentMode(mode string) string {
	switch m := strings.ToUpper(strings.TrimSpace(mode)); m {
	case "":
		return ""
	case "UPI", "UPI_INTENT", "UPI_COLLECT", "INTENT":
		return "UPI"
	case "CC", "DC", "CARD", "CREDITCARD", "DEBITCARD", "EMI", "CARD_SI":
		return "CARD"
	case "NB", "NETBANKING", "NET_BANKING", "E_NACH", "ENACH":
		return "NETBANKING"
	case "PPI", "WALLET", "CASH_CARD":
		return "WALLET"
	case "CASH":
		return "CASH"
	default:
		return m
	}
}

// MoneyPaise represents an integer minor-unit monetary amount (1 INR = 100 Paise) to eliminate floating-point rounding errors
type MoneyPaise int64

// ToPaise converts a currency amount to integer Paise (e.g. 500.50 -> 50050)
func ToPaise(amount float64) MoneyPaise {
	return MoneyPaise(int64(amount*100.0 + 0.5))
}

// ToRupees converts integer Paise back to standard currency amount (e.g. 50050 -> 500.50)
func (p MoneyPaise) ToRupees() float64 {
	return float64(p) / 100.0
}

// CalculateReceiptHash computes the SHA-256 hash for blockchain-like integrity using exact minor-unit paise
func CalculateReceiptHash(receiptNum, mahalID, memberID string, amount float64, prevHash string) string {
	paise := ToPaise(amount)
	payload := fmt.Sprintf("%s:%s:%s:%d:%s", receiptNum, mahalID, memberID, paise, prevHash)
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
	ID       string `bson:"_id" json:"id"`
	MahalID  string `bson:"mahal_id,omitempty" json:"mahal_id,omitempty"`
	Audience string `bson:"audience,omitempty" json:"audience,omitempty"` // ALL | OVERDUE_ONLY | FAMILY_HEADS | MEMBER
	// MemberIDs are the recipients of a MEMBER-audience alert.
	MemberIDs []string `bson:"member_ids,omitempty" json:"member_ids,omitempty"`
	// Type categorises the alert for the app (see AlertType* constants).
	Type        string    `bson:"type,omitempty" json:"type,omitempty"`
	Severity    string    `bson:"severity" json:"severity"` // CRITICAL | WARNING | INFO
	Title       string    `bson:"title" json:"title"`
	Description string    `bson:"description" json:"description"`
	Status      string    `bson:"status" json:"status"` // ACTIVE | ACKNOWLEDGED | RESOLVED
	CreatedAt   time.Time `bson:"created_at" json:"created_at"`
}

// Alert audiences.
const (
	AudienceAll         = "ALL"
	AudienceOverdueOnly = "OVERDUE_ONLY"
	AudienceFamilyHeads = "FAMILY_HEADS"
	AudienceMember      = "MEMBER"
)

// Alert types.
const (
	AlertTypeDuesReminder    = "DUES_REMINDER"
	AlertTypePaymentReceived = "PAYMENT_RECEIVED"
	AlertTypeAnnouncement    = "ANNOUNCEMENT"
	AlertTypeEvent           = "EVENT"
	AlertTypeGeneral         = "GENERAL"
)

// ValidAlertType reports whether t is one of the alert types.
func ValidAlertType(t string) bool {
	switch t {
	case AlertTypeDuesReminder, AlertTypePaymentReceived, AlertTypeAnnouncement, AlertTypeEvent, AlertTypeGeneral:
		return true
	}
	return false
}

// EffectiveType is Type, or a best guess for alerts stored before types existed.
func (a *SystemAlert) EffectiveType() string {
	if ValidAlertType(a.Type) {
		return a.Type
	}
	if a.Audience == AudienceOverdueOnly || strings.Contains(a.Title, "[Dues Reminder]") {
		return AlertTypeDuesReminder
	}
	return AlertTypeGeneral
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

// Admin roles carried in the session JWT.
const (
	RoleMahalAdmin = "MAHAL_ADMIN"
	RoleSuperAdmin = "SUPER_ADMIN"
	RoleMember     = "MEMBER"
)

// Admin is a committee member who manages a Mahal. Two ways in:
//   - mobile: Firebase-verified phone OTP resolved against Phone (/auth/resolve)
//   - web-admin: Phone + password checked against PasswordHash (/auth/login)
//
// PasswordHash is a bcrypt hash set with `go run ./cmd/setpassword`; an admin
// without one cannot use password login. Role defaults to MAHAL_ADMIN when
// empty (records created before roles existed).
type Admin struct {
	ID                string     `bson:"_id" json:"id"`
	MahalID           string     `bson:"mahal_id" json:"mahal_id"`
	Name              string     `bson:"name" json:"name"`
	Phone             string     `bson:"phone" json:"phone"`
	Role              string     `bson:"role,omitempty" json:"role,omitempty"`
	PasswordHash      string     `bson:"password_hash,omitempty" json:"-"`
	PasswordUpdatedAt *time.Time `bson:"password_updated_at,omitempty" json:"-"`
	CreatedAt         time.Time  `bson:"created_at" json:"created_at"`
}

// EffectiveRole is Role, defaulting to MAHAL_ADMIN. Anything unrecognised is
// also treated as MAHAL_ADMIN so a typo can never escalate to SUPER_ADMIN.
func (a *Admin) EffectiveRole() string {
	if a.Role == RoleSuperAdmin {
		return RoleSuperAdmin
	}
	return RoleMahalAdmin
}

// AlertMemberState is one member's private read / dismiss state for a
// tenant-wide alert. Alerts are shared by every member of a Mahal, so a
// member acknowledging or dismissing one must not change it for anyone else.
type AlertMemberState struct {
	ID          string     `bson:"_id" json:"id"` // alertID + ":" + memberID
	AlertID     string     `bson:"alert_id" json:"alert_id"`
	MahalID     string     `bson:"mahal_id" json:"mahal_id"`
	MemberID    string     `bson:"member_id" json:"member_id"`
	ReadAt      *time.Time `bson:"read_at,omitempty" json:"read_at,omitempty"`
	DismissedAt *time.Time `bson:"dismissed_at,omitempty" json:"dismissed_at,omitempty"`
}

// Mandate is a PayU Standing Instruction (recurring AutoPay authorization).
// It is created PENDING_AUTHORIZATION, becomes ACTIVE once the member approves
// the SI at the gateway (capturing AuthPayUID, PayU's mihpayid for the consent
// transaction), and is charged on each cycle via the si_transaction API.
type Mandate struct {
	ID             string     `bson:"_id" json:"mandate_id"`
	MahalID        string     `bson:"mahal_id" json:"mahal_id"`
	MemberID       string     `bson:"member_id" json:"member_id"`
	Status         string     `bson:"status" json:"status"` // PENDING_AUTHORIZATION | ACTIVE | PAUSED | CANCELLED | FAILED
	MaxAmount      float64    `bson:"max_amount" json:"max_amount"`
	DebitAmount    float64    `bson:"debit_amount" json:"debit_amount"`
	Frequency      string     `bson:"frequency" json:"frequency"` // MONTHLY
	RecurringDay   int        `bson:"recurring_day" json:"recurring_day"`
	Mode           string     `bson:"mode" json:"mode"` // UPI | E_NACH | CARD_SI
	AuthPayUID     string     `bson:"auth_payu_id,omitempty" json:"auth_payu_id,omitempty"`
	SIDetails      string     `bson:"si_details,omitempty" json:"si_details,omitempty"`
	NextDebit      *time.Time `bson:"next_debit,omitempty" json:"next_debit,omitempty"`
	LastDebitAt    *time.Time `bson:"last_debit_at,omitempty" json:"last_debit_at,omitempty"`
	PreDebitSentAt *time.Time `bson:"pre_debit_sent_at,omitempty" json:"pre_debit_sent_at,omitempty"`
	CreatedAt      time.Time  `bson:"created_at" json:"created_at"`
	UpdatedAt      time.Time  `bson:"updated_at" json:"updated_at"`
}

// ImportBatch is a parsed Excel/CSV member import awaiting (or after) commit.
// Stored in import_batches with a TTL on ExpiresAt.
type ImportBatch struct {
	ID          string      `bson:"_id" json:"batch_id"`
	MahalID     string      `bson:"mahal_id" json:"mahal_id"`
	Filename    string      `bson:"filename" json:"filename"`
	Status      string      `bson:"status" json:"status"` // PREVIEW | COMMITTING | COMMITTED
	Rows        []ImportRow `bson:"rows" json:"preview_rows"`
	Total       int         `bson:"total" json:"total_rows"`
	Valid       int         `bson:"valid" json:"valid_rows"`
	Duplicate   int         `bson:"duplicate" json:"duplicate_rows"`
	Invalid     int         `bson:"invalid" json:"invalid_rows"`
	Imported    int         `bson:"imported" json:"imported"`
	Skipped     int         `bson:"skipped" json:"skipped"`
	CreatedBy   string      `bson:"created_by" json:"-"`
	CreatedAt   time.Time   `bson:"created_at" json:"created_at"`
	CommittedAt *time.Time  `bson:"committed_at,omitempty" json:"committed_at,omitempty"`
	ExpiresAt   time.Time   `bson:"expires_at" json:"expires_at"`
}

// ImportRow is one spreadsheet data row after validation.
type ImportRow struct {
	Row                int      `bson:"row" json:"row"`
	Name               string   `bson:"name" json:"name"`
	Phone              string   `bson:"phone" json:"phone"`
	HouseName          string   `bson:"house_name" json:"house_name"`
	MonthlyDues        float64  `bson:"monthly_dues" json:"monthly_dues"`
	FamilyHead         bool     `bson:"family_head" json:"family_head"`
	FamilyMembersCount int      `bson:"family_members_count" json:"family_members_count"`
	Email              string   `bson:"email,omitempty" json:"email,omitempty"`
	MemberCode         string   `bson:"member_code,omitempty" json:"member_code,omitempty"`
	Status             string   `bson:"status" json:"status"` // VALID | DUPLICATE | INVALID
	Errors             []string `bson:"errors,omitempty" json:"errors"`
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
