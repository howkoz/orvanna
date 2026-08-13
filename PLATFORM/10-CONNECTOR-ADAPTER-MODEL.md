# Orvanna - Connector Adapter Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\10-CONNECTOR-ADAPTER-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F6 | See also `NOTES-Connector-Sourcing.md`

> House style: PART 1 see it, PART 2 the words. This is Howard's "no one-offs" insight, made into a
> repeatable unit of work.

---

# PART 1 - SEE IT

## The one contract every adapter implements

```
   STANDARD CONNECTOR INTERFACE  (the core only ever calls these):
     authorize · capture · refund · void · tokenize · status
```

## Anatomy of one adapter

```
   core calls "authorize"  ─►  ADAPTER for Processor X
                                 1. translate our request -> X's API shape
                                 2. send to X
                                 3. translate X's response -> our standard result
                                 4. map X's decline codes -> soft / hard
                              ◄─ standard result back to the core
```

## Bringing a new processor online

```
   1. build the adapter to the interface     (reference: HyperSwitch 90, ActiveMerchant, X's API docs)
   2. run the CERTIFICATION suite in sandbox  (authorize, capture, refund, void, decline handling)
   3. pass?  -> mark LIVE, selectable in routing
      fail?  -> stays in TEST, cannot take live traffic
```

## Where adapters come from

| Source | How we use it |
|--------|---------------|
| HyperSwitch open core (~90) | already adapters, work out of the box |
| ActiveMerchant / Omnipay | reference to PORT a new adapter (different language) |
| the processor's own API docs | source of truth for build + certification |
| managed Cloud (rented) | the long tail until owning it is worth it |

---

# PART 2 - THE WORDS

## The contract (F6)

Every processor, no matter how different its API, is reached through one fixed set of operations:
authorize, capture, refund, void, tokenize, status. The core only ever speaks this language. It
never calls a processor's API directly. That single rule is what makes the platform scale instead of
sprawl.

## What an adapter does

An adapter is a thin translator for exactly one processor. When the core calls a standard operation,
the adapter turns our request into that processor's specific API shape, sends it, turns the response
back into our standard result, and maps the processor's own decline codes into our soft-or-hard
classification (so the routing engine knows whether to retry). Nothing processor-specific leaks above
the adapter.

## Bringing a processor online is a known job

Adding a processor is not a custom project; it is a repeatable unit of work: build the adapter to the
interface, then run it through the certification suite in sandbox (authorize, capture, refund, void,
and decline handling). If it passes, it is marked live and becomes selectable in routing rules. If it
fails any required case, it stays in test status and cannot receive live traffic. Because it is a
known job, we can estimate it, schedule it, and price it, which is what makes "add a market" a
business line rather than a mystery.

## Where adapters come from (sourcing)

We are not capped at one vendor's list. The ~90 open-source connectors arrive already adapter-shaped.
Beyond them, we port new adapters using reference material (ActiveMerchant, Omnipay, the processor's
own docs), and we rent the long tail through the managed Cloud until owning a given connector is
worth the porting effort. We own every adapter we build. Full strategy in
`NOTES-Connector-Sourcing.md`.

## Certification is the quality gate

The certification suite is what keeps a sprawling connector list trustworthy. A connector is only as
good as its proven behavior on the core transaction types, so nothing reaches live traffic without
passing. This also gives us a clean, honest answer to "do you support processor X" : yes, certified,
or not yet.

## What this hands to the next steps

- The **build plan** (15) sequences which adapters to build first (ours, then high-value).
- The **cost and team model** (16) prices the per-adapter unit of work.
- **Observability** (14) watches each connector's live health.
