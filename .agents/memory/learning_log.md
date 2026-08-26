# Coding Agent Self-Learning & Decision Log

> **Protocol for AI Coding Agents**:
> Every time you fix a non-trivial bug, adopt a new library pattern, or receive user feedback on architecture/UI, record it here under the appropriate category. Future agent sessions will read this file to avoid repeating past mistakes.

---

## 1. Architectural Learnings & Context Retention

### Entry 001: Separation of Dues vs Voluntary Contributions
- **Context**: Mahal community members often confuse mandatory monthly dues with voluntary donations/Friday funds.
- **Rule**: Keep database models, APIs, and UI navigation separate. Dues increment `last_paid_month`; contributions are one-off and do not affect monthly dues balances.

### Entry 002: MongoDB Multi-Document ACID Transactions
- **Context**: Updating member balances and inserting receipt documents must never end up in a partial state if the network or process crashes.
- **Rule**: Use `session.WithTransaction()` in Go with `WriteConcern(majority)`.

---

## 2. Backend (Go & MongoDB) Learnings

### Entry 003: Idempotency Keys in Payment Creation
- **Context**: Flaky mobile networks can cause duplicate HTTP POST requests when tapping "Pay Now".
- **Rule**: Enforce `X-Idempotency-Key` header with unique index in MongoDB. In-flight locks are held in Redis with 120s TTL.

### Entry 004: PII Redaction
- **Context**: Phone numbers and gateway credentials cannot appear in logs.
- **Rule**: Use `logger.MaskPhone()` and `logger.MaskSecret()` in all logging interceptors.

---

## 3. Frontend (Flutter Mobile & Next.js Web) Learnings

### Entry 005: Design Token Fidelity (#146C5B Emerald)
- **Context**: The brand visual identity is `#146C5B` with subtle fintech character (not overly decorative or traditional mosque styling).
- **Rule**: Strictly adhere to `AppColors.primary` and `GoogleFonts.inter`. Use 8px spacing grid.

### Entry 006: Non-Partial Dues Selection in UI
- **Context**: Members must never be presented with an open amount input box for monthly dues.
- **Rule**: Render full month checkboxes (`[x] June ₹500`, `[x] July ₹500`), auto-calculating the exact total.

### Entry 008: 100% Stitch UI & HTML Prototype Fidelity
- **Context**: 35 pre-designed screens exist in `stitch_mahal_financial_integrity_system/`.
- **Rule**: Never design from imagination or invent layouts. The coding agent MUST inspect the specific screen folder's `screen.png` and `code.html` before creating Flutter widgets or React components to ensure pixel-perfect fidelity.

---

## 4. Git & Monorepo Workflow

### Entry 007: Conventional Commits
- **Context**: Automated changelog and version tracking require standardized commit headers (`feat(scope):`, `fix(scope):`, `chore(scope):`).
