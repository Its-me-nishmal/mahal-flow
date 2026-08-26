# Coding Agent Rule: Go Backend Conventions

1. **Fiber Request Handling**:
   - Parse request body into strongly typed DTO struct with validation tags.
   - Extract `tenant_id` from middleware context `c.Locals("tenant_id")`.
   - Never use global variables for state or database sessions.

2. **Error Handling & Response Mapping**:
   - Return standard JSON error responses:
     `{"error": {"code": "INVALID_AMOUNT", "message": "Amount must equal selected months * rate"}}`
   - Log internal error details via `logger.Log.Error()`, but return safe user-facing error messages to the client.

3. **Logging & Tracing**:
   - Always include `correlation_id`, `tenant_id`, and `caller` fields in logs.
   - Use `logger.MaskPhone()` and `logger.MaskSecret()` when logging user or gateway payloads.

4. **MongoDB Driver v2**:
   - Use `go.mongodb.org/mongo-driver/v2/mongo`.
   - Use `bson.M` or typed structs for queries.
   - Enforce indexes at application boot time or migration stage.
