# AGENTS.md — MahalFlow AI Coding Agent Constitution & Memory Protocol

> **CRITICAL FOR ALL CODING AGENTS (Antigravity, Cursor, Claude Code, Copilot):**
> Read this file and `.agents/memory/learning_log.md` at the start of every session before writing or modifying code.

---

## 1. Project Essence & Unbreakable Invariants

**MahalFlow** is a Fintech-grade Multi-Tenant Financial Integrity & Community Management Platform for Mosques/Mahals.

### The 5 Unbreakable Financial Invariants
1. **Never Allow Partial Monthly Dues**:
   - A monthly obligation (e.g. ₹500/mo) is a single, atomic unit. Members select full months (`[x] Jun, [x] Jul, [x] Aug = ₹1,500`).
   - If a request attempts to pay an arbitrary amount like ₹800 against a ₹500 dues schedule, reject it with HTTP 422.
2. **Strict Chronological Sequence**:
   - Members cannot pay August 2026 if June and July 2026 are unpaid. Dues must be paid in chronological order starting after `member.last_paid_month`.
3. **Strict Separation of Dues vs Voluntary Contributions**:
   - Monthly dues and voluntary contributions/donations MUST NEVER be mixed into the same transaction or database record.
4. **Immutable Double-Entry Ledger & Receipts**:
   - Receipts and transactions are **never** `UPDATE`d or `DELETE`d. Corrections are applied via new `REFUND` or `ADJUSTMENT` documents.
   - Every receipt must contain a verifiable SHA-256 hash chained to the previous receipt in that Mahal.
5. **Multi-Tenant Isolation**:
   - Every MongoDB query outside platform SuperAdmin MUST include `{ mahal_id: current_tenant_id }`.

---

## 2. Technology Stack & Directory Layout

- **Backend (`/backend-go`)**: Go 1.22 + Fiber v2 + official MongoDB Go driver v2 + Zerolog (`rs/zerolog`).
- **Database**: MongoDB 7.0+ (with Multi-Document ACID Transactions) + Redis 7 (Distributed locks & Idempotency).
- **Mobile (`/mobile-flutter`)**: Flutter 3.x (Dart) + Riverpod 2.x + Dio + Razorpay Flutter SDK.
- **Web Admin (`/web-admin`)**: Next.js 14+ (App Router) + TypeScript + Tailwind CSS with custom design tokens.

---

## 3. Design System & UI Rules (Stitch Aligned)

- **Primary Brand Color**: `#146C5B` (Emerald/Teal)
- **Primary Dark (Pressed)**: `#0D4F43`
- **Primary Light (Surface/Tint)**: `#E8F4F1`
- **Background**: `#F7F9F8` | **Surface**: `#FFFFFF`
- **Text Primary**: `#17201D` | **Text Secondary**: `#5E6864` | **Border**: `#E3E8E6`
- **Status Badges**:
  - `ACTIVE` / `SUCCESS` -> Green (`#16834B`, bg: `#EAF7EF`)
  - `GRACE_PERIOD` / `PENDING` -> Amber (`#B77900`, bg: `#FFF5DC`)
  - `READ_ONLY` / `SUSPENDED` / `FAILED` -> Red (`#C93B3B`, bg: `#FDECEC`)
  - `REFUNDED` -> Blue (`#3478B8`, bg: `#EAF3FB`)
- **Typography**: Inter / System UI, 8px grid spacing, 10px button border radius.

---

## 4. Coding Agent Self-Learning Protocol

Whenever an AI coding agent works on this repository, it MUST adhere to this self-learning loop:

```
                  ┌──────────────────────────────────────────────┐
                  │ 1. Read AGENTS.md & .agents/memory/          │
                  │    learning_log.md before writing any code   │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │ 2. Cross-reference changes against invariants│
                  │    and existing models in internal/domain/   │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │ 3. On completing task or receiving user fix: │
                  │    Record new learnings/rules to             │
                  │    .agents/memory/learning_log.md            │
                  └──────────────────────────────────────────────┘
```

### Self-Learning Log Rules:
- If the user corrects your code, or if you discover a tricky edge case / dependency gotcha, append an entry to `.agents/memory/learning_log.md`.
- Never delete historical learning entries; categorize them under `[Architecture]`, `[Backend-Go]`, `[Flutter]`, `[Database]`, or `[UI/UX]`.
