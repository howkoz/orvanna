# Orvanna - Data Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\06-DATA-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Names the things the system knows (from `05`)

> House style: PART 1 see it, PART 2 the words. No raw card numbers ever live in the core; the
> core holds a REFERENCE, the vault holds the secret.

---

# PART 1 - SEE IT

## How the pieces connect

```
   CUSTOMER ──has──► CARD ──stored as──► VAULT CREDENTIAL (token + PAN, in the vault only)
      │                 ▲
      └─has─► SUBSCRIPTION (optional)     CORE only ever holds a reference to the credential
                  │
                  ▼
   PAYMENT INSTRUCTION  (charge this card, $X, market M, charge-once key)
                  │
                  ▼
   PAYMENT  ──has many──►  ATTEMPT  ──to──►  PROCESSOR  ──reached via──►  CONNECTOR (adapter)
      │                       │
   has STATE               has RESULT (approved / declined + reason)

   ROUTE RULES guide which processor a PAYMENT picks.
   TRACE EVENTS record every step of a PAYMENT.
```

## The things the system knows

| Entity | What it holds (no code, just the data) | Links to |
|--------|----------------------------------------|----------|
| Customer | id, contact, market. No card data. | Cards, Subscriptions |
| Card | brand, last 4, expiry, a vault reference. NOT the real number. | Customer, Vault credential |
| Vault credential | the network token + the PAN, registered under OUR control. Lives in the vault. | Card |
| Subscription | schedule, status, and the failed-streak count | Customer, Instructions |
| Payment instruction | amount, currency, market, card reference, charge-once key | Card, Subscription |
| Payment | the lifecycle instance and its current state | Instruction, Attempts |
| Attempt | which processor, token or PAN, when | Payment, Processor, Result |
| Processor | name, regions served, what it supports | Connector, Attempts |
| Connector (adapter) | maps the standard operations to one processor's API, certification status | Processor |
| Route rule | conditions + priority that steer selection | Payments |
| Result | approved or declined, the reason code, soft or hard | Attempt |
| Trace event | a step, a timestamp, a detail | Payment |

---

# PART 2 - THE WORDS

## The shape in one sentence

A **customer** has **cards**; a card is stored as a **vault credential** (token + PAN, held in the
neutral vault, never in the core); a **payment instruction** says "charge this card for this
amount"; a **payment** carries out that instruction and may make several **attempts** at one or
more **processors** (reached through **connectors**), each attempt producing a **result**; **route
rules** steer the choice and **trace events** record everything.

## The entities

- **Customer.** The shopper. Holds contact details and market, never card data.
- **Card.** A stored card on file. The core keeps the brand, last four, expiry, and a reference to
  the vault. It never holds the real card number.
- **Vault credential.** The actual secret: the portable network token and the PAN, both held in the
  neutral external vault and registered under our own control (so the token is portable). The core
  reaches it only by reference.
- **Subscription.** Optional. For recurring customers it holds the schedule, the status, and the
  failed-streak count that the honesty layer uses to decide when a subscription is dead.
- **Payment instruction.** One order to charge: which card, how much, which market, and a
  charge-once key that guarantees a single charge no matter how many attempts run.
- **Payment.** The living instance that moves through the states in `05`. It belongs to one
  instruction and owns its attempts.
- **Attempt.** One try at one processor, using either the token or the PAN, at a moment in time.
  A payment can have several attempts; only one can ever succeed.
- **Processor.** A payment provider, with the regions it serves and the operations it supports.
- **Connector (adapter).** The thin integration that maps our standard operations to one
  processor's API, plus whether it has passed certification.
- **Route rule.** An operator-defined condition and priority that guides which processor a payment
  selects.
- **Result.** The outcome of an attempt: approved or declined, the reason code, and whether the
  decline is soft (retryable) or hard (stop).
- **Trace event.** A recorded step in a payment's life, used for end-to-end tracing and health.

## Two design truths this encodes

1. **One payment, many attempts, one charge.** The charge-once key on the instruction is the
   guardrail that makes aggressive retrying safe.
2. **The core holds references, the vault holds secrets.** Card numbers and tokens live in the
   vault; the core only ever passes references around. That is what keeps the core out of the worst
   of PCI scope and keeps our data ours.

## What this hands to the next steps

- The **routing engine** (07) operates on payments, attempts, processors, and route rules.
- The **vault** (08) owns the vault credential and the tokenization detail.
- **Security** (13) uses the core-holds-reference boundary to define PCI scope.
