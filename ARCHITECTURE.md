# 🏗️ MahalFlow Architecture Deep Dive

## 1. Domain Driven Hexagonal Architecture

MahalFlow backend follows a clean, decoupled architecture:
- **`cmd/api`**: Entrypoint initializing configs, database connections, repositories, services, Fiber router, and middleware.
- **`internal/domain`**: Pure Go models (`Member`, `Transaction`, `Receipt`, `Mahal`, `AuditLog`) with zero external dependencies.
- **`internal/repository`**: Data access interfaces and MongoDB implementations utilizing compound indexes and atomic updates.
- **`internal/service`**: Financial business logic, contiguous month validations, cryptographic hash calculations, and multi-document ACID transactions.
- **`internal/api`**: Fiber HTTP handlers, JSON request decoding, response mappings, and middleware.

---

## 2. Cryptographic Ledger & Hash Chaining

The ledger guarantees mathematical proof of immutability. Each receipt is created with:
$$\text{ReceiptHash} = \text{SHA256}(\text{ReceiptNumber} + \text{MahalID} + \text{MemberID} + \text{Amount} + \text{PreviousReceiptHash})$$

```
[Genesis Receipt]
  Hash: SHA256(GV1MH001... | Prev: 0000000000000000000000000000000000000000000000000000000000000000)
       ▲
       │ (PreviousReceiptHash)
[Receipt #2]
  Hash: SHA256(GV1MH002... | Prev: [Genesis Hash])
       ▲
       │ (PreviousReceiptHash)
[Receipt #3]
  Hash: SHA256(GV1MH003... | Prev: [Receipt #2 Hash])
```

---

## 3. High-Concurrency Monotonic Sequences

To prevent race conditions during high-volume dues collection:
- Dedicated **`counters`** collection with unique compound index `{ mahal_id: 1, counter_type: 1 }`.
- Uses atomic `FindOneAndUpdate` with `$inc: { seq: 1 }, Upsert: true`.
- Zero sequence collisions even with 100+ concurrent requests per second.

---

## 4. Multi-Tenant Boundary Isolation

- **Tenant Header**: `X-Tenant-ID` (e.g. `MH_001_CALICUT`).
- Middleware extracts and verifies tenant context before dispatching to handlers.
- All database queries explicitly filter by `mahal_id`. Cross-tenant record queries return HTTP 404.
