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
