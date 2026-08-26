# Coding Agent Rule: Financial Invariants & Integrity

1. **No Partial Dues Collection**:
   - Monthly dues must be collected in whole multiples of the month dues amount.
   - Never allow user to input an arbitrary decimal amount for monthly dues.
   - In UI: Members check full months (`☑ June 2026 ₹500`, `☑ July 2026 ₹500`).

2. **Sequential Month Constraint**:
   - When paying dues, the months selected must be sequential starting with the first unpaid month (`member.last_paid_month + 1 month`).

3. **Receipt Immutability & SHA-256 Chaining**:
   - Receipts are append-only.
   - Always hash the receipt using `CalculateReceiptHash(receiptNum, mahalID, memberID, amount, prevHash)`.
   - Never provide a route or method to edit or delete a receipt.

4. **Idempotency Requirement**:
   - Every payment initiation endpoint must require and validate `X-Idempotency-Key` (UUIDv4).
