# 03 — MongoDB Schema Design & ACID Financial Integrity

## 1. Core Principles of Financial Integrity in MongoDB

1. **Multi-Document ACID Transactions**: Handled with `WriteConcern(w: "majority")` and `ReadConcern("majority")`.
2. **Immutable Ledgers**: `receipts` and `ledger_entries` cannot be edited or deleted once written.
3. **Idempotency Keys**: Strictly indexed to avoid duplicate billing.
4. **Optimistic Concurrency Control**: Uses `version` integer fields on member balances.

---

## 2. Collection Schemas & Indexes

### Collection: `mahals` (Tenant Document)
```json
{
  "_id": "MH_001_CALICUT",
  "name": "Town Juma Masjid Mahal",
  "registration_number": "REG/KL/2024/0912",
  "contact": {
    "email": "committee@townmasjid.org",
    "phone": "+919876543210",
    "address": "Main Road, Calicut, Kerala 673001"
  },
  "settings": {
    "currency": "INR",
    "default_monthly_dues": 500.00,
    "dunning_enabled": true,
    "preferred_languages": ["ml", "en"],
    "autopay_allowed": true
  },
  "subscription": {
    "plan": "STANDARD_MONTHLY",
    "monthly_fee": 499.00,
    "status": "ACTIVE", // ACTIVE | GRACE_PERIOD | READ_ONLY | SUSPENDED
    "grace_period_ends_at": null,
    "next_billing_date": "2026-09-01T00:00:00Z"
  },
  "gateways": {
    "primary": "RAZORPAY",
    "razorpay_account_id": "acc_razorpay_123",
    "federal_bank_vpa": "townmasjid@fednet"
  },
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-08-01T00:00:00Z"
}
```
**Indexes**:
- `{ "name": "text", "registration_number": 1 }`
- `{ "subscription.status": 1, "subscription.next_billing_date": 1 }`

---

### Collection: `members` (Community Members)
```json
{
  "_id": "MEM_001_9910",
  "mahal_id": "MH_001_CALICUT",
  "member_code": "M-104",
  "name": "Muhammed Ameen",
  "phone": "+919847123456",
  "house_name": "Darul Aman",
  "family_head": true,
  "family_members_count": 4,
  "monthly_dues_custom_amount": 500.00,
  "status": "ACTIVE", // ACTIVE | INACTIVE | DECEASED | RELOCATED
  "autopay": {
    "enabled": true,
    "mandate_id": "man_razorpay_99812",
    "max_amount": 1000.00
  },
  "last_paid_month": "2026-07", // YYYY-MM
  "outstanding_balance": 500.00,
  "version": 14,
  "created_at": "2026-01-10T00:00:00Z",
  "updated_at": "2026-08-03T10:00:00Z"
}
```
**Indexes**:
- `{ "mahal_id": 1, "phone": 1 }` (Unique)
- `{ "mahal_id": 1, "member_code": 1 }` (Unique)
- `{ "mahal_id": 1, "status": 1, "last_paid_month": 1 }`

---

### Collection: `transactions` (Gateway Attempt Tracking)
```json
{
  "_id": "TXN_20260803_99812",
  "mahal_id": "MH_001_CALICUT",
  "member_id": "MEM_001_9910",
  "idempotency_key": "IDEMP_MEM9910_202608_1722678900",
  "type": "MONTHLY_DUES", // MONTHLY_DUES | CONTRIBUTION | SAAS_SUBSCRIPTION
  "amount": 1500.00,
  "currency": "INR",
  "selected_months": ["2026-06", "2026-07", "2026-08"],
  "gateway": "RAZORPAY",
  "gateway_order_id": "order_OG981237",
  "gateway_payment_id": "pay_PH981237",
  "status": "SUCCESS", // INITIALIZED | PENDING | SUCCESS | FAILED | REFUNDED
  "failure_reason": null,
  "receipt_id": "RCPT_GV1MH00120260803R00002",
  "created_at": "2026-08-03T10:14:00Z",
  "completed_at": "2026-08-03T10:15:12Z"
}
```
**Indexes**:
- `{ "idempotency_key": 1 }` (Unique)
- `{ "mahal_id": 1, "status": 1, "created_at": -1 }`
- `{ "gateway_order_id": 1 }`

---

### Collection: `receipts` (Immutable Cryptographic Ledger)
```json
{
  "_id": "RCPT_GV1MH00120260803R00002",
  "receipt_number": "GV1MH00120260803R00002",
  "sequence_number": 2,
  "mahal_id": "MH_001_CALICUT",
  "member_id": "MEM_001_9910",
  "member_name": "Muhammed Ameen",
  "transaction_id": "TXN_20260803_99812",
  "payment_type": "MONTHLY_DUES",
  "paid_months": ["2026-06", "2026-07", "2026-08"],
  "amount": 1500.00,
  "previous_receipt_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "receipt_hash": "a8f5f167f44f4964e6c998dee827110c59828d9c6328a6f3b798782f9547d6e1",
  "pdf_storage_url": "s3://mahalflow-receipts/MH001/2026/08/GV1MH00120260803R00002.pdf",
  "created_at": "2026-08-03T10:15:12Z"
}
```
**Indexes**:
- `{ "receipt_number": 1 }` (Unique)
- `{ "mahal_id": 1, "sequence_number": 1 }` (Unique)
- `{ "member_id": 1, "created_at": -1 }`

---

## 3. Go ACID Transaction Implementation Pattern

```go
func (s *PaymentService) ProcessSuccessfulPayment(ctx context.Context, txn *domain.Transaction) error {
    wc := writeconcern.Majority()
    rc := readconcern.Majority()
    txnOpts := options.Transaction().SetWriteConcern(wc).SetReadConcern(rc)

    session, err := s.mongoClient.StartSession()
    if err != nil {
        return err
    }
    defer session.EndSession(ctx)

    _, err = session.WithTransaction(ctx, func(sessCtx mongo.SessionContext) (interface{}, error) {
        // 1. Calculate next sequence number & Previous Hash
        lastReceipt, err := s.receiptRepo.GetLatestReceipt(sessCtx, txn.MahalID)
        if err != nil && !errors.Is(err, mongo.ErrNoDocuments) {
            return nil, err
        }
        
        seq := int64(1)
        prevHash := "GENESIS_BLOCK"
        if lastReceipt != nil {
            seq = lastReceipt.SequenceNumber + 1
            prevHash = lastReceipt.ReceiptHash
        }

        // 2. Generate new receipt & SHA-256 Hash
        receipt := domain.NewReceipt(txn, seq, prevHash)
        if err := s.receiptRepo.Insert(sessCtx, receipt); err != nil {
            return nil, err
        }

        // 3. Mark transaction as SUCCESS
        if err := s.txnRepo.UpdateStatus(sessCtx, txn.ID, "SUCCESS", receipt.ID); err != nil {
            return nil, err
        }

        // 4. Update member's last_paid_month and deduct balance
        if err := s.memberRepo.ApplyPaidMonths(sessCtx, txn.MemberID, txn.SelectedMonths, txn.Amount); err != nil {
            return nil, err
        }

        // 5. Append to Audit Log
        auditLog := domain.NewAuditLog(txn.MahalID, "PAYMENT_CAPTURED", txn.ID)
        return nil, s.auditRepo.Insert(sessCtx, auditLog)
    }, txnOpts)

    return err
}
```
