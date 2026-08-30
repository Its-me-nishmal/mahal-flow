# ⚡ MahalFlow Performance & Load Testing Benchmarks

## 1. Benchmark Execution Environment
- **Target Engine**: Go Fiber v2 Core API (`localhost:8080`)
- **Database**: MongoDB 7.x with connection pool size = 100
- **Runner**: Node.js Automated Benchmark Suite (`load_test.js`)

---

## 2. Load Test Results Summary

| Scenario | Concurrency | Success Rate | Latency (p50 / p95 / p99) | Verification |
| :--- | :--- | :--- | :--- | :--- |
| **1. Concurrent Reads** | 100 Workers | **100.0%** (100/100) | p50: 559ms / p95: 617ms / p99: 651ms | Pass |
| **2. Concurrent Payments** | 20 Workers | **100.0%** (20/20) | p50: 104ms / p95: 117ms / p99: 117ms | Pass (100% Atomic) |
| **3. Idempotency Collision**| 25 Workers | **100.0%** (25/25) | p50: 8ms / p95: 12ms / p99: 14ms | Pass (Exact 1 Created) |
| **4. Tenant Isolation** | Cross-Tenant | **100.0%** | N/A (HTTP 404 Returned) | Pass (0 Leakage) |
| **5. Cryptographic Ledger** | Full Audit | **100.0%** | N/A | Pass (100% Valid Chain) |

---

## 3. How to Run Benchmarks
```bash
cd backend-go
node load_test.js
```
