# 01 — MahalFlow System Architecture & Tenancy Model

## 1. High-Level Architecture Overview

MahalFlow is designed as a distributed, high-performance financial operating system tailored for Community Mahal Management on the RayanPortal platform.

```
                                  +-----------------------------+
                                  |   Flutter Mobile App        |
                                  |   (Members & Family Heads)  |
                                  +--------------+--------------+
                                                 | HTTPS / WSS
                                                 v
+-----------------------------+   +--------------+--------------+   +-----------------------------+
|   Next.js Super Admin PWA   |-->|   Cloudflare / NGINX        |<--|   Next.js Mahal Admin Portal|
|   (RayanPortal Operations)  |   |   API Gateway & Rate Limiter|   |   (Committee Operations)    |
+-----------------------------+   +--------------+--------------+   +-----------------------------+
                                                 |
                                                 v
                                  +-----------------------------+
                                  |   Go (Golang) Fiber API     |
                                  |   - Multi-Tenant Middleware |
                                  |   - Strict RBAC Guard       |
                                  |   - Transaction Engine      |
                                  +--------------+--------------+
                                                 |
        +----------------------------------------+----------------------------------------+
        |                                        |                                        |
        v                                        v                                        v
+-------+--------------------+   +---------------+------------+   +-----------------------+-------+
|  MongoDB Primary Replica   |   |   Redis 7 (In-Memory)      |   |  Agent Worker Daemon  |       |
|  - Multi-Doc ACID Txns     |   |   - Distributed Locks      |   |  - Reconciliation     |       |
|  - Immutable Ledgers       |   |   - Idempotency Cache      |   |  - Smart Dunning      |       |
|  - Change Streams (Oplog)  |   |   - Agent Short-Term Mem   |   |  - Excel Ingest / AI  |       |
+----------------------------+   +----------------------------+   +-------------------------------+
        |                                                                 |
        +---------------------------- Change Streams --------------------+
```

---

## 2. Multi-Tenancy & Isolation Model

MahalFlow implements **Logical Partitioning with Tenant Scope Enforcement**:

1. **Platform Scope (`RayanPortal`)**:
   - Manages all registered Mahals, global billing subscriptions, multi-bank gateway credentials, and platform revenue metrics.
2. **Mahal Organization Scope (`mahal_id`)**:
   - Each Mahal is assigned a unique immutable identifier (e.g., `MH_001_CALICUT`).
   - Every single database query outside Super Admin MUST include `mahal_id: current_tenant_id` at the repository layer.
   - Cross-Mahal data leaks are prevented using database query wrappers and middleware context validation.
3. **Member User Scope (`member_id`)**:
   - Members belong to one primary Mahal (with support for family sub-profiles).
   - Can only query dues, receipts, and history linked to their `member_id` and verified phone number.

---

## 3. Role-Based Access Control (RBAC) Matrix

| Resource / Action | Super Admin | Mahal President/Sec | Mahal Accountant | Regular Member | Public / Unauth |
|---|:---:|:---:|:---:|:---:|:---:|
| **Manage Mahals & Gateways** |  | ❌ | ❌ | ❌ | ❌ |
| **SaaS Billing & Subscriptions** |  |  | ❌ | ❌ | ❌ |
| **Manage Members & Excel Import**|  |  | ❌ | ❌ | ❌ |
| **Set Dues Amount & Monthly Rules**| ❌ |  | ❌ | ❌ | ❌ |
| **View Financial Reports & Exports**|  |  |  | ❌ | ❌ |
| **Initiate Dues Payment** | ❌ |  |  |  | ❌ |
| **Download PDF Receipts** |  |  |  |  | ❌ (Needs OTP) |
| **Issue Payment Refund** |  | ❌ (Requires SuperAdmin confirmation)| ❌ | ❌ | ❌ |
| **Access Audit Trail Logs** |  |  (Mahal scoped) | ❌ | ❌ | ❌ |

---

## 4. Security & Compliance Architecture

1. **Authentication & Session Tokens**:
   - Mobile: Passwordless Phone Number + Secure OTP verification (via WhatsApp/SMS), issuing short-lived asymmetric JWTs (15 min access + 30 day refresh rotation).
   - Admin Web: Multi-Factor Authentication (MFA with TOTP) + Role-scoped Session Tokens.
2. **Zero-Knowledge Gateway Credentials**:
   - Bank API keys (Federal Bank, Razorpay) are encrypted at rest using **AES-256-GCM** with a Master Key stored in HashiCorp Vault / AWS KMS.
   - Raw secrets are NEVER returned over any API endpoint or rendered in logs.
3. **Receipt Tamper-Proof Cryptography**:
   - Every receipt document contains a cryptographic SHA-256 checksum:
     `ReceiptHash = SHA256(ReceiptNumber + MahalID + MemberID + Amount + PaidMonths + PreviousReceiptHash + SecretSalt)`
   - Creating a blockchain-style append-only integrity chain per Mahal.
