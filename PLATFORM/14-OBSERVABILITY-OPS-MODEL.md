# Orvanna - Observability and Operations Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\14-OBSERVABILITY-OPS-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F9 | The honest answer to the "keep it healthy" risk

> House style: PART 1 see it, PART 2 the words. This model exists because the single biggest
> real-world risk we named is the machine going unhealthy when nobody is watching.

---

# PART 1 - SEE IT

## What gets watched

```
   every payment ─► a full TRACE (route, token/PAN, 3DS, attempts, result)
   every processor ─► live HEALTH (approval rate, latency, error rate)
   the whole system ─► the BIG NUMBERS (approval %, recovery %, volume by market)
```

## From signal to action

```
   metric crosses a threshold
        │
        ├─► auto: deprioritize a degrading processor in routing (F1)
        └─► alert: page the on-call owner
   nothing waits for a human to notice a dip in revenue first.
```

## The three things it answers

| Question | Answered by |
|----------|-------------|
| "What happened to THIS payment?" | the end-to-end trace |
| "Is processor X healthy right now?" | live health metrics |
| "How are we doing overall?" | dashboards by market and processor |

---

# PART 2 - THE WORDS

## Why this model is not optional (F9)

Howard named the real failure mode of platforms like this: the company gets busy, upkeep slips, and
problems are discovered from a revenue dip instead of a dashboard. Observability is the direct answer.
It makes the health of every processor and the path of every payment visible in real time, so a
problem is seen and acted on before it costs approvals.

## The three layers of visibility

1. **Per-payment trace.** Each payment records every step: which processor, token or PAN, 3DS or not,
   how many attempts, and the final result. Any single payment can be reconstructed end to end, which
   is what makes support and debugging fast and honest.
2. **Per-processor health.** Approval rate, latency, and error rate are tracked live for every
   processor and every connector. This is the same signal the routing engine uses to avoid a
   degrading processor.
3. **System dashboards.** The big numbers (approval rate, recovery rate, volume) broken down by
   market and processor, so the business can see how it is doing at a glance.

## From signal to action

Watching is not enough; the system has to act. When a metric crosses a threshold, two things can
happen: the routing engine can automatically deprioritize a degrading processor so payments stop
flowing to it, and an alert pages the on-call owner. The goal is that nothing important waits for a
human to happen to notice it.

## The human side (operations)

Tooling reduces the upkeep burden but does not remove it. There still has to be an owner who watches
the alerts, reviews the trends, and keeps the connectors and certifications current. This model makes
that job small and clear instead of large and vague, but it is real, and the cost and risk models
treat staffing it as a funded commitment, not an afterthought. That honesty is the whole point: a
platform stays healthy only when someone is genuinely responsible for it.

## What this hands to the next steps

- The **operator console** (11) presents these numbers to a human.
- The **cost and team model** (16) funds the on-call ownership this implies.
- The **risk register** (19) carries "upkeep under-resourced" as a named, owned risk.
