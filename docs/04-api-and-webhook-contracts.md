# 04 — API & Webhook Specifications (v1)

## 1. Authentication & Base Headers

All API requests (except public auth endpoints) must include:
- `Authorization: Bearer <JWT_TOKEN>`
- `X-Tenant-ID: <MAHAL_ID>` (Mandatory for all Mahal-scoped requests)
- `X-Correlation-ID: <UUIDv4>` (For end-to-end distributed tracing)
- `X-Idempotency-Key: <UUIDv4>` (Mandatory for all `POST /payments/*` requests)

---

## 2. Core API Endpoints

### 2.1 Member App Endpoints

```
POST /api/v1/auth/otp/request
  Request:  { "phone": "+919847123456" }
  Response: { "session_id": "sess_8912", "expires_in": 300 }

POST /api/v1/auth/otp/verify
  Request:  { "session_id": "sess_8912", "otp": "123456" }
  Response: { "token": "jwt...", "refresh_token": "rt...", "member": { ... } }

GET /api/v1/member/dashboard
  Response: {
    "mahal_name": "Town Juma Masjid",
    "outstanding_amount": 1500.00,
    "pending_months": [
      { "month": "2026-06", "amount": 500.00, "name": "June 2026" },
      { "month": "2026-07", "amount": 500.00, "name": "July 2026" },
      { "month": "2026-08", "amount": 500.00, "name": "August 2026" }
    ],
    "recent_payment": {
      "amount": 500.00,
      "date": "2026-05-15",
      "receipt_number": "GV1MH00120260515R00001"
    }
  }

POST /api/v1/payments/dues/initialize
  Request: {
    "selected_months": ["2026-06", "2026-07", "2026-08"],
    "gateway": "RAZORPAY"
  }
  Response: {
    "transaction_id": "TXN_20260803_99812",
    "amount": 1500.00,
    "gateway_order_id": "order_OG981237",
    "gateway_key": "rzp_live_abc123"
  }

POST /api/v1/payments/contribution/initialize
  Request: {
    "amount": 1000.00,
    "purpose": "Friday Ramadan Fund",
    "note": "For iftar supplies"
  }
  Response: {
    "transaction_id": "TXN_20260803_99813",
    "gateway_order_id": "order_OG981238"
  }

GET /api/v1/receipts/{receipt_number}/download
  Response: PDF File (Binary Stream) with SHA-256 signature header.
```

---

### 2.2 Mahal Admin Endpoints

```
GET /api/v1/admin/dashboard
  Response: {
    "total_collected_month": 85500.00,
    "total_pending_dues": 12000.00,
    "paid_members_count": 171,
    "pending_members_count": 24,
    "subscription_status": "ACTIVE"
  }

GET /api/v1/admin/members?page=1&limit=50&search=Ameen&status=ACTIVE
  Response: {
    "members": [ ... ],
    "total": 195,
    "page": 1
  }

POST /api/v1/admin/members/bulk-import/validate
  Request: Multipart form with .xlsx / .csv
  Response: {
    "total_rows": 150,
    "valid_rows": 145,
    "invalid_rows": 5,
    "errors": [
      { "row": 12, "field": "phone", "reason": "Invalid Indian mobile number" }
    ],
    "preview": [ ... ]
  }

POST /api/v1/admin/members/bulk-import/confirm
  Request: { "batch_id": "batch_99812" }
  Response: { "imported_count": 145 }

GET /api/v1/admin/reports/financial?from=2026-01-01&to=2026-08-01&format=pdf
  Response: Generated PDF Stream
```

---

## 3. Webhook Contract Specifications

### Razorpay Webhook Handler
`POST /api/v1/webhooks/razorpay`

- **Header**: `X-Razorpay-Signature: <HMAC-SHA256>`
- **Handled Events**:
  - `payment.captured`: Triggers Go worker reconciliation, commits receipt into MongoDB.
  - `payment.failed`: Releases lock on unpaid months, logs failure code.
  - `subscription.charged`: Extends Mahal SaaS subscription.
  - `subscription.halted`: Downgrades Mahal to `GRACE_PERIOD` / `READ_ONLY`.
