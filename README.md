# 🏛️ MahalFlow: Multi-Tenant Community Treasury & Fintech Platform

**MahalFlow** is a modern, high-performance, multi-tenant community treasury and financial ledger engine built for Mahals, non-profits, and faith-based community organizations. It provides transparent dues collection, automated monthly payments, fraud-proof cryptographic receipts, and real-time financial auditing.

---

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph Clients["Frontend Clients"]
        Mobile["📱 Mobile App (Flutter / Dart)<br/>• Member Dues Portal & Receipts<br/>• Admin Management & Bottom Sheets<br/>• Auto-Failover Offline Engine"]
        Web["💻 Web Admin Portal (Next.js 14 / TypeScript)<br/>• Super Admin & Multi-Mahal Control<br/>• Real-time Analytics & Tables<br/>• Statement Export (CSV/PDF)"]
    end

    subgraph API["Backend Service Layer"]
        GoAPI["⚡ Go Backend Engine (Fiber v2)<br/>• Multi-Tenant Middleware (X-Tenant-ID)<br/>• Exact-Once Idempotency Guard<br/>• SHA-256 Chained Hash Ledger<br/>• Atomic Sequence Allocator ($inc)"]
    end

    subgraph Data["Database & Storage"]
        Mongo["🍃 MongoDB Replica Set<br/>• Compound-Indexed Collections<br/>• Atomic Counter Sequences ($inc)<br/>• Real-time Audit Trail Logging"]
    end

    Mobile -->|REST / JSON| GoAPI
    Web -->|REST / JSON| GoAPI
    GoAPI -->|Connection Pool (Max 100)| Mongo
```

---

## 🚀 Key Features & Capabilities

### 1. 🛡️ Cryptographic Tamper-Evident Ledger
- Every payment generates a sequential receipt containing a **SHA-256 hash** mathematically linked to the previous receipt's hash (`PreviousReceiptHash`).
- Any manual database tampering or backdating breaks the mathematical chain and is immediately flagged during audit verification.

### 2. ⚡ Bulletproof Concurrency & Exact-Once Idempotency
- **Atomic Monotonic Sequences**: Monotonic receipt numbering guaranteed collision-free via MongoDB `$inc` counters.
- **Idempotency Engine**: Duplicate or retried payment authorizations return the original transaction with zero double-charging or duplicate entries.

### 3. 🏢 Multi-Tenant Scoping & Boundary Isolation
- Strict header-based tenant scoping (`X-Tenant-ID`) enforced across all API endpoints and database operations.
- Cross-tenant data access is strictly blocked (100% boundary isolation verified).

### 4. 📱 Modern Flutter Mobile Client
- Fluid, modern UI using **modal bottom sheets (`AppBottomSheet`)** with drag handles and keyboard insets handling.
- Integrated **shimmer skeleton loading**, **instant search bars with clear buttons**, and **pill filter chip bars with count badges**.
- Dual-role support for both **Community Members** (dues, receipts, AutoPay) and **Mahal Administrators** (member management, dues recording, live audit logs).

### 5. 💻 Next.js 14 Web Admin Portal
- Real-time dashboards displaying collections, outstanding dues, subscription mandates, and audit trails.
- Modular shared UI primitives (`ShimmerSkeleton`, `SearchBar`, `FilterTabs`, `EmptyState`).

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Backend Engine** | Go 1.22+, Fiber v2, MongoDB Go Driver v2, Zerolog |
| **Mobile Client** | Flutter 3.x, Dart, Dio, GoogleFonts (Inter) |
| **Web Admin Portal** | Next.js 14 (App Router), TypeScript, TailwindCSS, Lucide React |
| **Database** | MongoDB 7.x (Replica Set / Standalone compatible) |
| **Testing & Auditing**| Automated Node.js Benchmark Suite & 10-Vector Security Audit Suite |

---

## 🏁 Quick Start & Local Development

### 1. Backend Service (Go)
```bash
cd backend-go
go mod download
go run cmd/api/main.go
# API Server runs on http://localhost:8080
```

### 2. Web Admin Portal (Next.js)
```bash
cd web-admin
npm install
npm run dev
# Web Portal runs on http://localhost:3000
```

### 3. Mobile Application (Flutter)
```bash
cd mobile-flutter
flutter pub get
flutter run
```

---

## 📊 Automated Testing & Benchmarks

### Run Concurrency & Load Tests:
```bash
cd backend-go
node load_test.js
```

### Run Security & Penetration Audit:
```bash
cd backend-go
node security_audit.js
```

---

## 📄 License & Integrity Guarantee
MahalFlow is engineered for high-trust financial accounting. Built with ❤️ for community empowerment.
