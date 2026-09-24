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

### Entry 023: Member Home redesigned to a custom premium visual language (deviates from Stitch)
- **Context**: The member dashboard was restyled away from `stitch_mahal_financial_integrity_system/member_dashboard/` at the product owner's explicit direction, in favour of a gradient hero header, a floating balance card and a 2x2 quick-action grid.
- **Rule**: AGENTS.md §3.1 / `.cursorrules` still require Stitch fidelity for every *other* screen. The member home (`lib/features/dashboard/screens/member_dashboard_screen.dart`) is a sanctioned exception, not a precedent. Do not "fix" it back toward `screen.png`. If the rest of the member flow is later migrated to this language, update AGENTS.md §3.1 rather than leaving the two in conflict.
- **Design tokens introduced**: `lib/core/theme/app_tokens.dart` (`AppSpacing`, `AppRadius`, `AppShadows`, `AppGradients`, `AppTextStyles`). These are opt-in — `AppTheme.lightTheme.textTheme` was deliberately left untouched so the other ~20 screens keep rendering identically. New screens should consume `AppTextStyles` instead of hand-rolling `GoogleFonts.inter(...)`.

### Entry 024: `GetLatestReceipt` is Mahal-scoped, not member-scoped (data leak)
- **Context**: `GET /member/dashboard` builds `latest_payment` from `receiptRepo.GetLatestReceipt(ctx, tenantID)`, and the repository query filters on `mahal_id` only, sorted by `sequence_number` descending. The most recent receipt in the whole Mahal is returned regardless of who owns it, so a member could see another member's amount and receipt number on their home screen.
- **Rule**: The Flutter dashboard now discards `latest_payment` when its `member_id` does not match the dashboard's `member_id` (`MemberDashboardData.fromJson`). That is a client-side mitigation only. **The backend still needs fixing**: add a `member_id` filter to `GetLatestReceipt` and pass the member id from the handler. Multi-tenant isolation (invariant 5) means `mahal_id` scoping alone is not sufficient for per-member data.

### Entry 025: `GET /autopay/mandate/status` is a non-persistent stub — do not consume it
- **Context**: The handler returns a hardcoded `{"mandate_id": "MND_849201", "status": "ACTIVE"}` with no member scoping and no persistence. Wiring the UI to it would tell every member AutoPay is active even if they never set it up, which breaks the trust principle in the design system.
- **Rule**: Until mandates are persisted and scoped server-side, AutoPay state on the member home is gated on a local per-member flag (`lib/core/storage/autopay_local_store.dart`, backed by `flutter_secure_storage`). `SetupAutoPayScreen` now pops `true` on success so the dashboard can persist it. Once the backend is real, replace the local read and delete the store.

### Entry 026: Never label a dues receipt a "Contribution"
- **Context**: The Stitch mockup shows "August 2026 Contribution" in the Latest Payment card, but the receipt may carry `payment_type: MONTHLY_DUES`.
- **Rule**: Derive the noun from `payment_type` — `MONTHLY_DUES` renders "<months> Dues", `CONTRIBUTION` renders "Mahal Contribution". Financial invariant 3 (strict separation of dues and voluntary contributions) outranks visual fidelity to a mockup's placeholder copy.

### Entry 027: Currency and month labels must not be hand-rolled
- **Context**: The dashboard printed `₹1500` (no grouping) and screens hand-rolled `const monthNames = [...]` arrays plus fabricated fallbacks like `lastPaid = "2026-07"`.
- **Rule**: Use `Inr.format()` / `Inr.spoken()` (`lib/core/utils/currency_format.dart`, `intl` with locale `en_IN` for lakh grouping) for all amounts, and `DuesPeriod` (`lib/core/utils/dues_period.dart`) to derive unpaid months from `last_paid_month`. `DuesPeriod.parseMonthKey` returns `null` on bad input — callers must render a neutral label rather than invent a period. The amount itself always comes from `outstanding_balance`, never from a month count.

### Entry 028: Amount labels must scale down, never ellipsize; verify layout at 360dp
- **Context**: On the redesigned member home, the primary CTA "Pay ₹12,50,000" overflowed its button by 4.4px at 360dp, and the quick-action tiles overflowed by 19px once a caption wrapped to two lines. `flutter analyze` reported nothing for either — overflow only appears at layout time.
- **Rule**:
  - Wrap any widget that renders a rupee amount in `FittedBox(fit: BoxFit.scaleDown)`. Never use `TextOverflow.ellipsis` on money: a truncated amount misinforms, a smaller one does not. Test with a lakh-scale value (₹12,50,000), not just ₹500.
  - Never give a card row a fixed `SizedBox(height:)` when its text can wrap. Use `IntrinsicHeight` + `CrossAxisAlignment.stretch` so a row self-sizes to its tallest child and siblings stay equal height.
  - 360dp is the narrowest supported width (docs/design.md section 36) and is the width of the SM M107F test device. Widget tests that pump at `Size(360, 800)` fail on `RenderFlex` overflow, so they catch this without a device — see `mobile-flutter/test/member_dashboard_layout_test.dart`. Add a case at `textScale: 1.3` as well.

### Entry 029: [Flutter][Backend-Go] Push notifications — payload contract and gotchas
- **Context**: FCM was initialised but notifications were never visible in the foreground, taps went nowhere, and the backend only audit-logged tokens.
- **Rule**:
  - Android never draws an FCM push while the app is in the foreground. `PushNotificationService` redraws it with `flutter_local_notifications` on channel `mahalflow_default`. That channel id, the `ic_stat_notification` drawable and the `#146C5B` colour are also hard-coded in `internal/gateway/fcm/client.go` and `AndroidManifest.xml`. Change all three together.
  - The small icon must be a white-on-transparent drawable (`res/drawable-*/ic_stat_notification.png`). A coloured launcher icon renders as a white square.
  - `flutter_local_notifications` v10+ requires core library desugaring in `android/app/build.gradle.kts`.
  - Tap routing reads FCM `data.type` (ALERT | DUES_REMINDER | RECEIPT | PAYMENT_FAILED | AUTOPAY). Kind constants live in `service/push_service.go`. The backend copies title/body into `data`, because a tray tap only delivers `data`.
  - On a cold start the tap is held until a dashboard calls `markSessionReady()`. Splash → login would otherwise replace the routed screen.
  - Push is optional, like WhatsApp: without `FCM_SERVICE_ACCOUNT_FILE`/`FCM_SERVICE_ACCOUNT_JSON` the client is disabled and every send is a no-op. `paymentService` accepts only one receipt hook, so `main.go` fans out to every channel (WhatsApp, push) from a single hook. Never call `SetReceiptIssuedHook` twice.
