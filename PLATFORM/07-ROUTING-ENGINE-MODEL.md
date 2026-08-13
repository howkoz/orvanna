# Orvanna - Routing Engine Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\07-ROUTING-ENGINE-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Zooms into steps 2, 6, 8 of `05` | Features F1, F3

> House style: PART 1 see it, PART 2 the words. This is the brain: how it picks a processor and
> how it recovers a decline without chasing dead customers.

---

# PART 1 - SEE IT

## How it picks a processor

```
   payment + rules + live health
            │
            ▼
   1. ELIGIBLE?   keep only processors that can do this card / country / currency / amount
            │
            ▼
   2. HEALTHY?    drop any processor currently flagged unhealthy
            │
            ▼
   3. RANK        order the rest by the operator's priority (cost, approval history, or weight)
            │
            ▼
   4. PICK        top of the list = the processor for attempt 1
```

## The recovery ladder (when an attempt is declined)

```
   attempt 1:  TOKEN at best processor      ──approved? stop, done
        │ soft decline
   attempt 2:  PAN at best processor        ──approved? stop, done
        │ soft decline
   attempt 3:  TOKEN at 2nd best processor  ──approved? stop, done
        │ soft decline
        ▼
   stop at the retry cap.   (hard decline or dead-sub stops immediately, no ladder)
```

## The rules an operator can set

| Rule type | Example | Effect |
|-----------|---------|--------|
| Eligibility | "US Visa -> processors A, B" | which processors may take this payment |
| Priority | "rank by lowest cost" | which eligible processor goes first |
| Weight / split | "70% A, 30% B" | spread volume across processors |
| Retry | "max 3 attempts, then stop" | how hard to chase a decline |
| Health | "drop a processor over 30% declines" | auto-avoid a degraded processor |

## The decline decision

| Decline class | Examples | Action | Feature |
|---------------|----------|--------|---------|
| Soft | timeout, issuer unavailable, do-not-honor | retry / reroute per the ladder | F3 |
| Hard | stolen card, closed account, no such account | stop now, no retry | F3 |
| Dead subscription | past the failed-streak limit | stop, unrecoverable | F3 |

---

# PART 2 - THE WORDS

## Selecting a processor (F1)

For each payment the engine builds a short list in four moves: keep only the processors that are
**eligible** for this card brand, country, currency, and amount; drop any that are currently
**unhealthy**; **rank** the survivors by the operator's chosen priority (lowest cost, best recent
approval history, or a fixed weight); and **pick** the top one for the first attempt. Everything
here is driven by operator rules, not code changes, so the business can re-tune routing whenever it
wants.

## The recovery ladder (F3)

When an attempt comes back declined and the decline is soft, the engine climbs a ladder rather than
giving up: the token at the best processor, then the PAN at the best processor, then the token at
the next-best processor, and so on, up to the retry cap the operator set. A success at any rung ends
the payment as a single charge. The ladder is what turns a raw decline rate into real recovered
revenue.

## The honesty layer (F3)

Recovery is only worth doing when the decline is actually recoverable. So the engine classifies
every decline:
- **Soft** declines (timeouts, temporary issuer issues, do-not-honor) are retried and rerouted.
- **Hard** declines (stolen card, closed account, no such account) stop immediately. Retrying these
  burns fees and irritates issuers, which can hurt future approvals.
- **Dead subscriptions** (past the failed-streak threshold in the data model) stop as unrecoverable.
  We do not spend attempts or fees on customers who are already gone.

This is the difference between a vanity recovery number and an honest one, and it is the original
edge Orvanna brings beyond what the connectors do on their own.

## Safety: charge once

Every rung of the ladder runs under the payment's charge-once key. No matter how many attempts or
reroutes happen, only one can ever result in a charge. That is what makes it safe to retry hard.

## Where the operator controls it

All of the above (eligibility, priority, weights, retry caps, health thresholds) is configured in
the operator console (`11`) with no engineering. The engine simply executes the active rules.

## What this hands to the next steps

- The **operator console** (11) is the surface for editing these rules.
- **Observability** (14) supplies the live health signal the engine uses in step 2.
- The **vault** (08) supplies token-then-PAN for the ladder.
