# 07 — Validation Rules & Financial Integrity Guardrails

## 1. Zero-Trust Financial Validation Pipeline

Every incoming payment and member state modification passes through a 4-tier validation pipeline:

```
[Incoming Request]
        │
        ▼
[Tier 1: Syntax & DTO Validator] ──> (Rejects malformed formats, regex errors)
        │
        ▼
[Tier 2: Business Invariant Check] ──> (Rejects partial month dues, negative amounts)
        │
        ▼
[Tier 3: Distributed Idempotency Lock] ──> (Prevents parallel double execution)
        │
        ▼
[Tier 4: MongoDB ACID Session + Version Check] ──> (Commits or rolls back atomically)
```

---

## 2. Strict Business Invariant Rules

### Rule 1: No Partial Monthly Dues
- **Invariant**: A monthly obligation must be paid in full (e.g. ₹500).
- **Rule**: `Total_Amount == Length(Selected_Months) * Member.Monthly_Dues_Amount`.
- **Validation**: If a member owes ₹500 for June and ₹500 for July, submitting `amount: 800` is **rejected with HTTP 422 Unprocessable Entity**.

### Rule 2: Chronological Sequence (No Cherry-Picking Future Months)
- **Invariant**: A member cannot pay August 2026 if June and July 2026 remain unpaid.
- **Rule**: The selected months must form a contiguous sequence starting immediately after `member.last_paid_month`.

### Rule 3: Separation of Dues vs Voluntary Contributions
- **Invariant**: Monthly dues and voluntary donations/contributions must NEVER be mixed in a single transaction payload.
- Separate endpoints: `/api/v1/payments/dues/initialize` vs `/api/v1/payments/contribution/initialize`.

### Rule 4: Dynamic Distributed Idempotency Guard
- When a payment initiation request arrives, Go checks Redis with `SET key token NX EX 120`.
- If a matching request is currently in-flight, subsequent requests return HTTP `409 Conflict` ("Transaction currently processing, please wait").
- Once settled in MongoDB, the `idempotency_key` unique index permanently prevents duplicate transaction records.

---

## 3. Go Request Validation Structs (DTOs)

```go
package dto

type InitializeDuesPaymentRequest struct {
    SelectedMonths []string `json:"selected_months" validate:"required,min=1,dive,datetime=2006-01"`
    Gateway        string   `json:"gateway" validate:"required,oneof=RAZORPAY FEDERAL_BANK"`
    IdempotencyKey string   `json:"idempotency_key" validate:"required,uuid4"`
}

type InitializeContributionRequest struct {
    Amount         float64  `json:"amount" validate:"required,gt=0"`
    Purpose        string   `json:"purpose" validate:"required,min=3,max=100"`
    Note           string   `json:"note" validate:"omitempty,max=255"`
    Gateway        string   `json:"gateway" validate:"required,oneof=RAZORPAY FEDERAL_BANK"`
    IdempotencyKey string   `json:"idempotency_key" validate:"required,uuid4"`
}

type BulkMemberImportRow struct {
    Name        string  `json:"name" validate:"required,min=2,max=100"`
    Phone       string  `json:"phone" validate:"required,e164"`
    HouseName   string  `json:"house_name" validate:"omitempty,max=100"`
    MonthlyDues float64 `json:"monthly_dues" validate:"required,gte=0"`
    MemberCode  string  `json:"member_code" validate:"omitempty,alphanum"`
}
```
