# 📖 MahalFlow REST API Specification (v1.0.0)

**Base URL**: `http://localhost:8080/api/v1`  
**Authentication**: Header-based `X-Tenant-ID` scoping with optional Bearer JWT tokens.

---

## 🔑 Common Request Headers

| Header | Description | Required | Example |
| :--- | :--- | :---: | :--- |
| `Content-Type` | Payload format | Yes (for POST/PUT) | `application/json` |
| `X-Tenant-ID` | Multi-tenant Mahal identifier | Recommended | `MH_001_CALICUT` |
| `X-Correlation-ID` | End-to-end tracing ID | Optional | `CID-12345-ABCDE` |
| `X-Idempotency-Key` | Safe retry token for payment operations | Recommended | `IDEMP-PAY-98124` |

---

## 🌐 Public Routes

### 1. Health Probe
- **Method**: `GET`
- **Path**: `/health`
- **Response**: `200 OK`
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected",
  "environment": "development",
  "timestamp": "2026-08-30T08:50:00Z"
}
```

### 2. Admin Authentication
- **Method**: `POST`
- **Path**: `/api/v1/auth/login`
- **Rate Limit**: 30 requests / 1 min
- **Request Body**:
```json
{
  "phone": "+919847111222",
  "password": "adminSecretPassword"
}
```
- **Response**: `200 OK`
```json
{
  "token": "jwt_live_session_9d42...",
  "role": "MAHAL_ADMIN",
  "phone": "+919847111222",
  "expires_in": 86400
}
```

---

## 💳 Payment & Dues Operations

### 3. Initialize Dues Payment
- **Method**: `POST`
- **Path**: `/api/v1/payments/dues/initialize`
- **Request Body**:
```json
{
  "member_id": "MEM_001_9910",
  "selected_months": ["2026-08"],
  "gateway": "UPI",
  "idempotency_key": "IDEMP_PAY_001"
}
```
- **Response**: `201 Created`
```json
{
  "transaction_id": "TXN_8f7b...",
  "amount": 500.0,
  "currency": "INR",
  "selected_months": ["2026-08"],
  "status": "SUCCESS",
  "receipt": {
    "receipt_number": "GV1MHMH_001_CALICUT20260830R00012",
    "sequence_number": 12,
    "amount": 500.0,
    "previous_receipt_hash": "a4f8...",
    "receipt_hash": "e9b2...",
    "created_at": "2026-08-30T08:52:00Z"
  }
}
```

### 4. Initialize Voluntary Contribution (Donation)
- **Method**: `POST`
- **Path**: `/api/v1/payments/contribution/initialize`
- **Request Body**:
```json
{
  "member_id": "MEM_001_9910",
  "amount": 2500.0,
  "fund": "Building Expansion",
  "gateway": "RAZORPAY",
  "idempotency_key": "IDEMP_DON_001"
}
```
- **Response**: `201 Created`

### 5. Verify Cryptographic Receipt
- **Method**: `GET`
- **Path**: `/api/v1/receipts/:number/verify`
- **Response**: `200 OK`
```json
{
  "receipt_number": "GV1MHMH_001_CALICUT20260830R00012",
  "is_valid": true,
  "tamper_status": "AUTHENTIC",
  "calculated_hash": "e9b2...",
  "stored_hash": "e9b2..."
}
```

---

## 👥 Member Management (Admin)

### 6. List Members (Paginated & Filtered)
- **Method**: `GET`
- **Path**: `/api/v1/admin/members?limit=20&page=1`
- **Response**: `200 OK`
```json
{
  "members": [
    {
      "id": "MEM_001_9910",
      "member_code": "M-101",
      "name": "Nishmal P",
      "phone": "+919847111222",
      "house_name": "123, Palm Grove",
      "status": "ACTIVE",
      "last_paid_month": "2026-08",
      "outstanding_balance": 0.0
    }
  ],
  "total": 4,
  "page": 1,
  "limit": 20
}
```

### 7. Create New Member
- **Method**: `POST`
- **Path**: `/api/v1/admin/members`
- **Request Body**:
```json
{
  "name": "Zuhail Ahmed",
  "phone": "+919847999000",
  "house_name": "Darul Aman",
  "family_members_count": 4,
  "monthly_dues_custom_amount": 500,
  "status": "ACTIVE"
}
```
- **Response**: `201 Created`

---

## 📊 Analytics & Auditing

### 8. Admin Dashboard Aggregates
- **Method**: `GET`
- **Path**: `/api/v1/admin/dashboard`
- **Response**: `200 OK`
```json
{
  "total_members": 4,
  "active_members": 4,
  "total_collected": 15500.0,
  "dues_collected": 9500.0,
  "donations_collected": 6000.0,
  "pending_members": 0,
  "total_pending_dues": 0.0,
  "recent_transactions": [...]
}
```

### 9. Audit Logs Feed
- **Method**: `GET`
- **Path**: `/api/v1/admin/audit-logs?limit=50`
- **Response**: `200 OK`
```json
{
  "logs": [
    {
      "id": "AUD_8f912",
      "action": "PAYMENT_COMMITTED",
      "actor": "Nishmal P",
      "entity_id": "GV1MHMH_001_CALICUT20260830R00012",
      "details": "Paid 500.00 for months: 1",
      "timestamp": "2026-08-30T08:52:00Z"
    }
  ],
  "total": 12
}
```
