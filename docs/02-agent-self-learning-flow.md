# 02 — Autonomous Multi-Agent System & Self-Learning Architecture

## 1. Multi-Agent Ecosystem Overview

MahalFlow embeds 5 dedicated AI agents running in an asynchronous background daemon (`backend-go/cmd/worker`), coordinating via an event bus and MongoDB Change Streams.

```
                                  +------------------------------+
                                  |    Supervisor Orchestrator   |
                                  |     (Priority Event Bus)     |
                                  +---------------+--------------+
                                                  |
         +-------------------+--------------------+--------------------+-------------------+
         |                   |                    |                    |                   |
         v                   v                    v                    v                   v
+-----------------+ +-----------------+ +-----------------+ +-----------------+ +-----------------+
| 1. Auto-Healing | | 2. Smart Dunning| | 3. Fraud/Anomaly| | 4. Excel Ingest | | 5. Cryptographic|
|  Reconciliation | |   Multilingual  | |  Detection Guard| | Cleaning Agent  | |   Audit Agent   |
|     Agent       | |      Agent      | |     Agent       | |                 | |                 |
+--------+--------+ +--------+--------+ +--------+--------+ +--------+--------+ +--------+--------+
         |                   |                    |                    |                   |
         +-------------------+--------------------+--------------------+-------------------+
                                                  |
                                                  v
                                  +------------------------------+
                                  |     Memory & Learning Engine |
                                  |  - Short-Term Working (Redis)|
                                  |  - Long-Term Vector (Chroma) |
                                  |  - RLAIF Feedback Evaluator  |
                                  +------------------------------+
```

---

## 2. Detailed Agent Specifications

### Agent 1: Auto-Healing Payment Reconciliation Agent
- **Trigger**: Runs every 5 minutes + on every webhook failure event.
- **Workflow**:
  1. Finds all transactions in `PENDING` state older than 3 minutes.
  2. Directly polls Gateway APIs (Razorpay / Federal Bank) with exponential backoff.
  3. If Gateway status = `CAPTURED` -> atomically marks transaction `SUCCESS`, generates cryptographically signed receipt, and marks due months as `PAID`.
  4. If Gateway status = `FAILED` -> marks state as `FAILED`, frees dues lock, and notifies member.
  5. If duplicate payment detected on same month -> flags for **Auto-Refund Queue** and alerts Mahal Admin.

### Agent 2: Smart Multilingual Dunning & Communication Agent
- **Trigger**: Scheduled weekly/monthly billing cycle (configurable per Mahal).
- **Features**:
  - Context-Aware Prompting: Checks member payment history, past responses, preferred language (English, Malayalam, Urdu, Tamil).
  - Time Optimization: Evaluates when the user previously completed payments (e.g., Saturday 8:00 PM) to schedule reminders for maximum conversion.
  - Conversational Understanding: If a member replies on WhatsApp "I am in hospital, will pay next month", the agent extracts intent `HARDSHIP_PAUSE`, suppresses automated dunning for 30 days, and logs a note for the committee.

### Agent 3: Fraud & Anomaly Detection Agent
- **Trigger**: Real-time evaluation on every transaction creation and refund request.
- **Rules & Heuristics**:
  - Velocity checks: >3 failed attempts from single IP/Device within 2 minutes.
  - Spikes in refund requests (>5% of monthly collection).
  - Webhook signature integrity check.
  - Auto-Action: Freezes payout routing on compromised accounts and pages Super Admin.

### Agent 4: Intelligent Excel Member Ingestion Agent
- **Trigger**: On upload of `.xlsx`/`.csv` member rosters.
- **Capabilities**:
  - Header Fuzzy Mapping: Maps variations (`Ph No`, `Contact`, `Mobile Number`, `ഫോൺ നമ്പർ`) to canonical `phone_number`.
  - Phone Sanitization: Strips `+91`, spaces, hyphens, prefixes with country code standard E.164.
  - Family Unit Clustering: Identifies duplicate house numbers/names to group into family units.
  - Validation Preview: Generates detailed summary (`120 Valid, 4 Duplicate, 2 Invalid Phone`) before committal.

### Agent 5: Cryptographic Financial Integrity & Audit Agent
- **Trigger**: Nightly 00:00 UTC batch job.
- **Verification Routine**:
  1. Calculates `Actual_Balance = Starting_Balance + Sum(Successful_Receipts) - Sum(Confirmed_Refunds)`.
  2. Verifies every single SHA-256 receipt chain link `Receipt[i].PrevHash == Hash(Receipt[i-1])`.
  3. Verifies no member has unpaid gaps when AutoPay is enabled.
  4. Emits signed Audit Certificate document to the Mahal Admin.

---

## 3. The Self-Learning Feedback Loop (RLAIF & Active Memory)

```
[Agent Action / Reminder] ──> [Admin or Member Response]
                                       │
                                       ▼
                       [Feedback Metric Calculated]
                       - Prompt Accuracy: Accepted (1.0) vs Edited (0.5) vs Rejected (0.0)
                       - Conversion Rate: Did reminder lead to payment within 48h?
                                       │
                                       ▼
                       [Reward Vector Stored in MongoDB]
                       `agent_feedback_memory` Collection
                                       │
                                       ▼
                       [Weekly Policy Refinement]
                       - Automatically adjust prompt templates
                       - Fine-tune delivery schedule heuristics
                       - Store successful negotiation examples in Vector RAG store
```

### Feedback Data Schema (`agent_feedback_memory`)
```json
{
  "_id": "66ce1234567890abcdef1234",
  "mahal_id": "MH_001_CALICUT",
  "agent_type": "SMART_DUNNING",
  "context": {
    "member_id": "MEM_9910",
    "overdue_months": 3,
    "language": "ml",
    "delivery_time": "2026-08-20T19:30:00Z"
  },
  "action_taken": "whatsapp_gentle_reminder_template_v2",
  "outcome": {
    "paid_within_48h": true,
    "admin_override": false,
    "reward_score": 1.0
  },
  "created_at": "2026-08-20T19:30:00Z"
}
```
