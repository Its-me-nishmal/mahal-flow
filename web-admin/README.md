# 💻 MahalFlow Web Admin Portal

Modern, responsive web dashboard for Mahal administrators, treasury officers, and super admins built with **Next.js 14 (App Router)**, **TypeScript**, and **TailwindCSS**.

---

## ✨ Features

- **Treasury Overview**: Real-time dues collection analytics, donor fund allocation, and member growth charts.
- **Member Directory**: Searchable, filterable member database with profile management and payment recording.
- **Financial Statements**: Aggregated summaries and transaction ledgers with CSV/PDF export.
- **Audit & Governance**: Live immutable audit logs tracking administrative actions and cryptographic hash receipts.
- **Reusable UI Kit**:
  - `ShimmerSkeleton`: Skeleton placeholders during API hydration.
  - `SearchBar`: Real-time debounced query inputs.
  - `FilterTabs`: Status tabs with badge counts.
  - `EmptyState`: Centered illustrations for zero-result queries.

---

## 📂 App Router Structure

```
web-admin/src/
├── app/
│   ├── (super-admin)/
│   │   ├── alerts/          # System alerts & broadcast publisher
│   │   ├── audit-logs/      # Live audit trail
│   │   ├── dashboard/       # Treasury dashboard & metrics
│   │   ├── gateways/        # Payment gateway & webhook secrets config
│   │   ├── mahals/          # Multi-tenant Mahal organization registry
│   │   ├── members/         # Member management directory
│   │   ├── payments/        # Transaction ledger & receipts
│   │   ├── refunds/         # Refund processing queue
│   │   ├── reports/         # Financial reports & aggregations
│   │   └── subscriptions/   # AutoPay mandates
│   ├── layout.tsx           # Global root layout with Inter font
│   └── page.tsx             # Landing / Redirection router
├── components/
│   ├── layout/              # Sidebar, Header, Navigation
│   └── ui/                  # ShimmerSkeleton, SearchBar, FilterTabs, EmptyState
└── lib/
    └── api-client.ts        # Next.js API client with X-Tenant-ID scoping
```

---

## 🚀 Running Locally

```bash
# 1. Install dependencies
npm install

# 2. Start dev server
npm run dev

# App runs on http://localhost:3000
```
