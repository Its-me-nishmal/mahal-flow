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

### Entry 021: Single-Command Automated API & Model Validation Runner
- **Context**: Adding new routes or changing schemas must be testable in 1 second with a single command.
- **Rule**: Run `.\scripts\test_all_apis.ps1` (or `go run cmd/test-api/main.go`). It automatically validates HTTP status codes, security guards, response models, and latency across all endpoints. Whenever a developer adds a new route, add a test case to `backend-go/cmd/test-api/main.go`.

### Entry 022: RFC 10008 Structured Query Engine
- **Context**: Complex multi-field filtering and report aggregations need structured JSON bodies without leaking PII in URL search params or breaking browser caching.
- **Rule**: Use the RFC 10008 Query pattern (`POST /api/v1/.../query` with `X-HTTP-Method-Override: QUERY`). Fiber routes this to dedicated query handlers returning standardized structured query payloads.

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

### Entry 009: Material Symbols Icon Font in Next.js (Web Admin)
- **Context**: Material Symbols Outlined render as plain text (e.g. `dashboard`, `payments`) if CSS `@import` is placed after `@tailwind` or if the font stylesheet is omitted from `layout.tsx`.
- **Rule**: In `web-admin/src/app/layout.tsx`, always load the Google Fonts stylesheet link inside `<head>` with `display=block`, and ensure `@import` in `globals.css` precedes `@tailwind` with explicit `font-family: 'Material Symbols Outlined' !important;`.

---

## 4. Git & Monorepo Workflow

### Entry 007: Conventional Commits
- **Context**: Automated changelog and version tracking require standardized commit headers (`feat(scope):`, `fix(scope):`, `chore(scope):`).

---

## 5. Agent System Learnings

### Entry 009: Agent Interface Pattern
- **Context**: The multi-agent orchestrator uses a uniform `Agent` interface with `Name()`, `Run(ctx)`, and `Interval()` methods, run via goroutine tickers.
- **Rule**: Agents must respect `ctx.Done()` for graceful shutdown. Long-running work should check `ctx.Err()` periodically. The orchestrator runs each agent's `Run()` immediately on boot, then on a ticker.

### Entry 010: Event Bus for Inter-Agent Communication
- **Context**: Agents need to publish events (fraud detected, payment resolved) without tight coupling.
- **Rule**: Use a channel-based `EventBus` with `Subscribe(EventType, Handler)` and `Publish(Event)`. Handlers run in goroutines. Agents should not depend on each other directly.

### Entry 011: Self-Learning Memory Store
- **Context**: Agents need to record feedback for RLAIF-based policy refinement.
- **Rule**: `MemoryStore` interface with `RecordFeedback()`, `GetHistoricalContext()`, and `GetAverageReward()`. MongoDB-backed implementation uses aggregation pipelines for reward averaging. Feedback records include mahal_id, agent_type, context, action, outcome, and reward_score.

### Entry 012: Agent-Required Repository Methods
- **Context**: Each agent needs specific query patterns: reconciliation needs `FindPendingOlderThan`, dunning needs `GetOverdueMembers`, fraud guard needs `CountFailedByIP/Device`, crypto audit needs `VerifyReceiptChain`.
- **Rule**: When designing agents, pre-design the repository interface methods they need. Use MongoDB aggregation pipelines for complex queries (totals, averages).

---

## 6. Super Admin React (Next.js) Learnings

### Entry 013: Design Token Fidelity in Tailwind Config
- **Context**: The stitch HTML prototypes use a comprehensive Material Design 3-inspired color system with 50+ semantic tokens.
- **Rule**: Replicate ALL color tokens from the stitch `tailwind.config` into the Next.js `tailwind.config.ts`. Do not simplify or merge colors. Every token like `surface-container-low`, `primary-fixed-dim`, `on-primary-container` has a specific use case in the UI.

### Entry 014: Material Symbols vs Lucide Icons
- **Context**: The stitch prototypes use Google Material Symbols Outlined exclusively.
- **Rule**: Use `material-symbols-outlined` CSS class for all icons in the React app, not lucide-react. Import the font via Google Fonts in `globals.css`. Icons use `span.material-symbols-outlined` elements.

### Entry 015: Pixel-Perfect Stitch Fidelity
- **Context**: The 35 stitch mockups define exact HTML structures, Tailwind classes, and spacing.
- **Rule**: Before implementing any screen, read the corresponding `stitch_mahal_financial_integrity_system/<screen>/code.html`. Copy the exact Tailwind class names, card structures, table layouts, and spacing patterns. The stitch HTML IS the source of truth.

### Entry 016: Two Admin Tiers
- **Context**: Super Admin manages all Mahals platform-wide. Mahal Admin manages a single Mahal.
- **Rule**: Super Admin layout has full sidebar with Dashboard, Mahals, Members, Payments, Subscriptions, Gateways, Refunds, Reports, Audit Logs, Alerts, Settings. Mahal Admin layout has a subset: Dashboard, Members, Payments, Subscriptions, Settings. These are different layout components.

### Entry 017: Next.js App Router Route Groups
- **Context**: The super admin pages need a shared sidebar layout but login should not have it.
- **Route structure**: Use `(super-admin)` route group for all admin pages sharing the sidebar layout. Login sits outside at `/login`. The root `/` redirects to `/dashboard`.

---

## 7. Flutter Mobile App Learnings

### Entry 018: Flutter Screen Module Pattern
- **Context**: Building 22+ screens across auth, member, and admin flows required consistent patterns.
- **Rule**: Each feature gets its own directory under `lib/features/<feature>/screens/`. All screens are `StatefulWidget` with `GoogleFonts.inter()` for text. Import `AppColors` from `core/theme/app_theme.dart` — never hardcode colors. Use relative imports (`../../../core/theme/app_theme.dart`).

### Entry 019: Dart Map Type Inference Gotcha
- **Context**: `List<Map>` without explicit type parameters creates `List<Map<dynamic, dynamic>>`, causing `t["key"]!` null-assertion errors on `dynamic` values.
- **Rule**: Always declare map types explicitly: `List<Map<String, String>>` or cast values: `t["name"] as String`. Use string comparison (`t["paid"] == "true"`) instead of boolean map values to avoid type issues.

### Entry 020: Flutter Switch.activeColor Deprecation (3.41+)
- **Context**: `Switch(activeColor:)` was deprecated in Flutter 3.31+.
- **Rule**: Use `Switch(activeThumbColor:)` instead. Also prefer `.withValues(alpha:)` over `.withOpacity()` to avoid precision loss warnings.

---

## 4. Git & Monorepo Workflow
