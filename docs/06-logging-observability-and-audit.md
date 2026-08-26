# 06 — Logging, Observability & Tamper-Evident Audit Trails

## 1. Structured JSON Logging Standard

All backend services (Go REST API and Go Worker Daemons) output structured JSON logs via `rs/zerolog` or `log/slog` to `stdout` and rotated disk storage.

### Standard Log Event Schema
```json
{
  "timestamp": "2026-08-26T13:10:00.123Z",
  "level": "info",
  "service": "mahalflow-backend-api",
  "version": "1.0.0",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "correlation_id": "req_c8912-9812-4212",
  "tenant_id": "MH_001_CALICUT",
  "user_id": "MEM_001_9910",
  "caller": "payment/service.go:142",
  "action": "PAYMENT_INTENT_CREATED",
  "duration_ms": 14.2,
  "http_status": 200,
  "meta": {
    "amount": 1500.00,
    "months_count": 3,
    "gateway": "RAZORPAY"
  },
  "message": "Payment intent created successfully for 3 months"
}
```

---

## 2. PII Sanitization & Security Masking Rules

The logger and middleware MUST enforce automated redaction before any line is written:

1. **Card / Bank Account Numbers**: Only the last 4 digits allowed (`•••• •••• •••• 4242`).
2. **Phone Numbers**: Must mask middle digits (`+91 98****1234`).
3. **Passwords, OTPs, Secret Keys**: String values for keys matching `password`, `otp`, `secret`, `authorization`, `api_key`, `webhook_secret` are replaced with `[REDACTED]`.
4. **Member Addresses**: Truncated in debug logs.

---

## 3. MongoDB Audit Log Schema (`audit_logs`)

Every financial alteration or privileged admin action is permanently logged into an append-only collection.

```json
{
  "_id": "AUD_99812481",
  "mahal_id": "MH_001_CALICUT",
  "actor": {
    "user_id": "USR_ADMIN_01",
    "role": "MAHAL_SECRETARY",
    "ip_address": "49.37.102.14",
    "user_agent": "Mozilla/5.0 ... Chrome/128"
  },
  "category": "FINANCIAL_MUTATION", // FINANCIAL_MUTATION | MEMBER_STATUS | CONFIG_CHANGE | SECURITY_EVENT
  "action": "PAYMENT_REFUND_APPROVED",
  "entity_type": "transaction",
  "entity_id": "TXN_20260803_99812",
  "before_state": {
    "status": "SUCCESS",
    "refund_status": "NONE"
  },
  "after_state": {
    "status": "REFUNDED",
    "refund_amount": 1500.00,
    "reason": "Duplicate bank debit during network timeout"
  },
  "timestamp": "2026-08-26T13:10:00Z"
}
```
**Indexes**:
- `{ "mahal_id": 1, "timestamp": -1 }`
- `{ "entity_type": 1, "entity_id": 1 }`
- `{ "category": 1, "timestamp": -1 }`

---

## 4. Observability Metrics & Alerts (Prometheus / Grafana)

The Go backend exposes `/metrics` with standard fintech operational indicators:
- `mahalflow_payment_attempts_total{gateway, status}`: Total payment attempts by gateway.
- `mahalflow_reconciliation_healing_total`: Count of transactions automatically repaired by Agent 1.
- `mahalflow_agent_dunning_conversions_total`: Reminders that successfully converted to paid dues.
- `mahalflow_db_transaction_duration_seconds`: Histogram of multi-document ACID execution times.
