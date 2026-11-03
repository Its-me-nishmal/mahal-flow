# MahalFlow Roadmap: from Kerala pilot to global community-treasury SaaS

Date: 2026-11-03. Source: three read-only audits (Go backend, Flutter app, web-admin + docs + infra).
Caveat: auditors skimmed the largest files (handlers.go, api_service.dart, pg/client.go) and sampled screens. Treat each finding as "verify, then fix", not as proven.

## 1. Thesis

Community money (mosques, temples, churches, gurdwaras, NGOs, trusts) needs one thing: anyone can prove who collected what and where it went. MahalFlow's differentiator is a tamper-evident hash-chained receipt ledger. Recurring dues plus years of financial history give strong retention and high switching cost.

Target: multi-tenant SaaS, per-tenant monthly fee plus optional payment fee, sold first to Kerala mahals, then diaspora mosques (UK / Gulf / US), then other org types.

## 2. Current state

| Area | State |
|---|---|
| Backend (Go/Fiber/Mongo) | Feature-rich: auth, dues, contributions, autopay, refunds, receipts, reports, Excel import, WhatsApp, FCM. `go test ./...` passes. |
| Mobile (Flutter) | ~35k LOC, all screens API-backed, no mocks. Android only. 59 tests. |
| Web admin (Next.js) | 18 pages, API-backed. Read-only gateways, no plan billing, no data export. |
| Infra | Render free plan, staging-style flags, no CI, no backups, no Redis/worker deployed. |
| Product positioning | Hardcoded INR, +91, IST, "Mahal" wording, PayU only. |

## 3. P0: must fix before any real money flows (days, not weeks)

These are correctness and security defects. Some may already be live in production; check first.

1. **Fail-open test mode.** `PAYMENT_TEST_MODE` defaults ON when unset, and `render.yaml` sets it ON. With it ON, `gatewayConfirmsSuccess` returns true, so a member can call `/payments/dues/confirm` and get a receipt without paying (handlers.go ~2705). Default OFF; refuse to start in prod with it ON. Confirm the prod env value today.
2. **Forgeable JWT.** If `ENV` is unset or misspelled, the JWT secret falls back to a hardcoded default (jwt.go ~53). Hard-fail when `JWT_SECRET` is missing, regardless of `ENV`. Rotate JWT secret. Rotate PayU key/salt/client secret and WhatsApp token if `backend-go/.env` was ever shared or zipped.
3. **Ledger verification is cosmetic.** `VerifyReceiptChain` checks only `prev == prevHash` and never recomputes hashes, so a tampered amount passes. The hash also omits date, months, fund, currency and transaction id. Fix: recompute on verify, hash a canonical serialization of all fields.
4. **Refund correctness.** No guard against double refund or refunding a non-SUCCESS transaction. A partial refund flips the whole transaction. Amount is uncapped and defaults to 500. Dues and balance are not reversed, no offsetting ledger entry, DB errors swallowed after gateway success. Needs a state machine plus compensating ledger entry.
5. **Cross-tenant idempotency leak.** Unique index on `idempotency_key` is global; a duplicate returns another tenant's transaction. Make the index `(mahal_id, key)`.
6. **Non-atomic commit fallbacks.** Standalone (no-transaction) fallback and seq-1 fallback on counter error can fork the chain or partially apply writes. Require replica-set transactions; fail closed.
7. **Webhook hardening.** Compare gateway amount and currency with the stored transaction. Bad hashes currently create a global CRITICAL alert per unauthenticated POST (alert spam); rate-limit and dedupe.
8. **Mobile token leak.** `LogInterceptor` logs Bearer tokens in all builds. Gate on `kDebugMode`. Also remove `usesCleartextTraffic`, replace hardcoded localhost URLs and the const tenant `MH_001_CALICUT` with flavors / `--dart-define`.
9. **Autopay double-debit.** Scheduler runs inside the API process with no distributed lock; failures retry every 3 minutes forever; cancel does not cancel the standing instruction at PayU; debits do not advance dues months. Move to the worker with a lock, add backoff and a retry cap, call PayU cancel.
10. **Double-decrement of outstanding balance** when two PENDING dues transactions cover the same months.

## 4. P1: make it shippable and sellable (about 4 to 8 weeks)

- **Money as integers.** Replace `float64` with integer minor units end to end; per-currency exponent table (ISO 4217).
- **Auth hardening.** Web admin: httpOnly cookie plus refresh token plus `middleware.ts`; server logout/revocation; validate `iss`/`aud`; password reset; per-account lockout; admin MFA; restrict CORS; proxy-aware rate limiting (Redis-backed).
- **Tenant isolation guard.** Enforce `mahal_id` at the repository layer, not only in handlers; add a cross-tenant test suite to CI.
- **Safe reconciliation job.** Poll pending transactions, verify with the gateway before booking. Do not wire the existing agent as written (it commits without a gateway check).
- **Production infra.** Paid plan (no sleeping, so schedulers run), Redis, worker service, web-admin hosting, staging vs prod split, Mongo backups, `/health` that pings the DB plus readiness/liveness split, non-root container with healthcheck, CI (tests, lint, `govulncheck`, `flutter analyze`).
- **Observability.** Metrics, tracing, alerting on payment failures and chain-verify failures.
- **Release hardening (mobile).** Real signing keystore, final `applicationId`, R8/proguard, Crashlytics or Sentry, FCM `route` allowlist, longer Dio timeouts, retry/backoff, basic offline cache.
- **iOS.** No `ios/` directory exists. Scaffold, APNs key, Firebase plist, Info.plist, entitlements, TestFlight. Firebase phone auth on iOS needs APNs plus reCAPTCHA URL scheme.
- **Member-facing verification.** Receipt verify UI plus QR / public verify link. This is the product's differentiator; surface it.
- **Exports.** CSV/Excel/PDF for ledger, members, statements, receipts (README already claims it; code lacks it). Replace `xlsx@0.18.5`.
- **Docs cleanup.** Dedupe diverged docs, fix `file:///d:/...` links, correct Razorpay vs PayU, correct tenant-boundary description, make security and benchmark claims match evidence. Hand-check `stitch_.../system_settings/code.html:280` (`sk_live_` match, likely placeholder).
- **Data hygiene.** Delete `tmp/main` and `build-errors.log`; remove dead deps (`razorpay_flutter`, unused `flutter_riverpod`) or start using them.

## 5. P2: SaaS platform (2 to 4 months)

- **Self-serve onboarding:** signup wizard, email verification, invite flow, staff users and roles per tenant.
- **Platform billing:** plan catalog, trial, invoices, tenant dunning, plan enforcement, suspend/grace logic, usage metering.
- **Super-admin console:** tenant lifecycle, impersonation with audit, platform analytics, feature flags.
- **Per-tenant gateway config** (or Connect-style model), encrypted at rest.
- **Soft delete members** (hard delete orphans ledger rows and conflicts with audit duties); real audit actors instead of literal "ADMIN"; audit writes must not be best-effort.
- **Fund accounting:** restricted/unrestricted funds, expense and payout side, bank reconciliation.

## 6. P3: go global (4 to 9 months)

| Capability | Work |
|---|---|
| Currency | Per-tenant currency, minor units, symbol, PDF fonts for non-Latin symbols, optional FX display. |
| Gateways | Gateway abstraction in Go and app. Add Stripe (UK/US/EU), a Gulf gateway, keep PayU/Razorpay for India. Mandates beyond India SI (Stripe subscriptions, SEPA/ACH). |
| Tax receipts | India 80G, UK Gift Aid, US 501(c)(3) acknowledgements, donor tax IDs, annual statements, per-country templates. Zakat/tithe reports. |
| Localization | Arabic (RTL), Urdu, Hindi, Tamil and others; migrate to `EdgeInsetsDirectional`/`AlignmentDirectional`; per-tenant timezone; country picker and E.164 phone handling; web-admin i18n. |
| Terminology layer | Org type (mosque, temple, church, NGO) drives labels and defaults instead of hardcoded "Mahal". |
| Compliance | GDPR/DPDP export, erasure, consent, retention policy, encryption of PII at rest, optional data-residency region. |
| Auth | Reconsider SMS-only OTP for global use: cost, SMS-pumping fraud, regional deliverability. Add email login. |

## 7. Suggested sequence

- **Weeks 0 to 2:** all of P0. No pilot onboarding before items 1, 2, 3, 4 are done.
- **Weeks 2 to 8:** P1 core (integer money, auth, tenant guard, infra/CI, release hardening, exports, member verify). Onboard 1 to 3 Kerala mahals as paid or free pilots.
- **Months 3 to 4:** iOS and P2 (self-serve, platform billing). Start charging.
- **Months 5 to 9:** P3 (multi-currency, Stripe, Gift Aid, RTL). Target UK/Gulf diaspora mosques first.

## 8. Risks

- **Single founder on a payments product.** Reduce blast radius with CI, tests on the ledger and money paths, and backups.
- **Ledger credibility.** The "tamper-evident" claim is currently unproven (finding P0-3). Fix before marketing it.
- **Regulatory.** Holding or routing community funds can trigger licensing questions per country. Use gateway-hosted flows and avoid holding funds; get local advice before the UK/Gulf launch.
- **SMS cost/fraud** at global scale (see Auth).
- **Market proof.** No paying tenant yet. A real pilot outranks every item in P3.

## 9. Metrics to track

Paying tenants, MRR, payment success rate, reconciliation mismatches (target 0), chain-verify failures (target 0), p95 API latency on a real deployment (current benchmark is one tiny local run, not a capacity claim), churn.
