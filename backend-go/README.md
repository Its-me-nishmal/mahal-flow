# ⚡ MahalFlow Go Backend Engine

High-performance, multi-tenant fintech and ledger service built with Go (Golang) and Fiber v2.

---

## 🏗️ Architecture

```
backend-go/
├── cmd/
│   └── api/main.go          # Server entrypoint, middleware chain, route bindings
├── internal/
│   ├── api/                 # Fiber handlers, middleware, request/response DTOs
│   ├── config/              # Environment variable loading
│   ├── database/            # MongoDB connection & compound index initialization
│   ├── domain/              # Core business entities & models
│   ├── logger/              # Zerolog structured logger
│   ├── repository/          # MongoDB data access layer & atomic counters
│   └── service/             # Payment verification, receipt hash generator
├── load_test.js             # Automated 5-scenario concurrency test suite
└── security_audit.js        # Automated 10-vector security audit suite
```

---

## ⚙️ Environment Variables (`.env`)

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `8080` | HTTP server listening port |
| `ENV` | `development` | Environment mode (`development` / `production`) |
| `MONGO_URI` | `mongodb://localhost:27017` | MongoDB connection URI |
| `DB_NAME` | `mahalflow` | Primary database name |
| `PAYMENT_TEST_MODE` | `ON` | Auto-commits simulated test payments |
| `REDIS_ADDR` | `localhost:6379` | Redis address for the agent event bus |
| `JWT_SECRET` | _(dev fallback)_ | HMAC signing key — must be set in production |

### WhatsApp Business Cloud API

| Variable | Default | Description |
| :--- | :--- | :--- |
| `WHATSAPP_API_URL` | `https://graph.facebook.com` | Meta Graph API base URL |
| `WHATSAPP_API_VERSION` | `v21.0` | Graph API version segment |
| `WHATSAPP_PHONE_NUMBER_ID` | — | Sender phone number ID (Graph message endpoint path) |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | — | WABA ID — used for template management |
| `WHATSAPP_ACCESS_TOKEN` | — | Bearer token. Dashboard tokens expire in 24h; use a System User token beyond local dev |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | — | Echoed back on the Meta webhook subscription handshake |
| `WHATSAPP_APP_SECRET` | — | Validates `X-Hub-Signature-256` on inbound webhooks |

| `WHATSAPP_TEMPLATE_DUES_REMINDER` | _(empty)_ | Approved template for dues reminders; empty falls back to free-form text |
| `WHATSAPP_TEMPLATE_RECEIPT` | _(empty)_ | Approved template for payment receipts |
| `WHATSAPP_DRY_RUN` | `false` | Log messages without calling the Graph API |

> Copy `.env.example` to `.env` and fill in secrets. `.env` is gitignored — never commit it.

---

## 💬 WhatsApp Notifications

Two member notifications are wired to the WhatsApp Cloud API:

| Notification | Trigger | Dedupe key |
| :--- | :--- | :--- |
| Dues reminder | `MEMBER_OVERDUE` from the dunning agent (worker) | one per member per day |
| Payment receipt | Successful payment commit (API) | receipt number |

**The integration is inert until credentials exist.** With `WHATSAPP_ACCESS_TOKEN`
or `WHATSAPP_PHONE_NUMBER_ID` unset the client reports disabled, every send is a
no-op, and both services behave exactly as they did before. Nothing in the
payment or ledger path can fail because of a notification.

### Bringing it up

1. Set `WHATSAPP_PHONE_NUMBER_ID` and `WHATSAPP_ACCESS_TOKEN`. Sending starts
   immediately — free-form text, so it only reaches members inside an open
   24-hour window. Good enough for development against a test number.
2. Set `WHATSAPP_DRY_RUN=true` first to rehearse against real member data:
   messages are logged and counted but never sent.
3. Submit templates to Meta for approval, then set `WHATSAPP_TEMPLATE_*`.
   Delivery switches from text to templates with no code change, and reminders
   start reaching members outside the 24-hour window.
4. Set `WHATSAPP_APP_SECRET` and point Meta's webhook at
   `POST /api/v1/webhooks/whatsapp` to record delivery receipts. Until the app
   secret is set the endpoint rejects every inbound call rather than trusting
   unsigned payloads.

### Idempotency

`notification_log` carries a unique index on `(mahal_id, dedupe_key)`, and the
dedupe key is claimed *before* the send. The dunning agent re-scans hourly, so
without this a single overdue member would be messaged every hour until they
paid — enough to get the number flagged by Meta.

---

## 🚀 Running Locally

```bash
# Install dependencies
go mod download

# Run in development with Air hot-reloading
air

# Or run standard go build
go run cmd/api/main.go
```

---

## 🧪 Testing & Reliability

```bash
# 1. Type check & static analysis
go vet ./...

# 2. Concurrency & Load Benchmark (100 Workers)
node load_test.js

# 3. 10-Vector Security & Penetration Audit
node security_audit.js
```
