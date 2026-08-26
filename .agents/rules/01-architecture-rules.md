# Coding Agent Rule: Architecture & Multi-Tenancy

1. **Strict Multi-Tenancy**:
   - Every database query for Mahal-level data MUST include `mahal_id`.
   - Never expose cross-Mahal aggregated metrics to non-SuperAdmin roles.
   - Any query missing `mahal_id` is considered a critical security bug.

2. **Clean Layered Architecture (Go Backend)**:
   - `internal/domain/`: Pure entities, value objects, domain logic (no DB or HTTP dependencies).
   - `internal/repository/`: MongoDB data access, queries, transactions.
   - `internal/service/`: Business workflows, invariant validation, orchestration.
   - `internal/api/`: Fiber route handlers, request DTO validation, HTTP response mapping.
   - `internal/gateway/`: Third-party payment gateway clients (Razorpay, Federal Bank).

3. **Database Transactions**:
   - Any operation touching multiple collections (e.g. creating receipt + updating member balance + logging audit) MUST execute inside `session.WithTransaction(ctx, ...)`.
