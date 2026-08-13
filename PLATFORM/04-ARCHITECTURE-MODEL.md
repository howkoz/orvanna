# Orvanna - Architecture Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\04-ARCHITECTURE-MODEL.md`
**Built:** 2026-06-15 | Stage 1 (system design) | Feeds: all features F1-F9

> House style: PART 1 see it, PART 2 the words. The star of this model is the **connector
> adapter pattern** (Howard's own insight: no one-offs, one standard underlying contract).

---

# PART 1 - SEE IT

## The whole system in one diagram

```
   Merchant app /        +================ Orvanna ==================+
   checkout  ──────────► |  API EDGE   (take instruction, return result)|
                         |     |                                        |
                         |     v                                        |
                         |  ROUTING CORE ──► retry / reroute intelligence|
                         |     |   ^                                     |
                         |     |   └──── OPERATOR CONSOLE (no-code rules) |
                         |     v                                         |
                         |  STANDARD CONNECTOR INTERFACE                 |
                         |     |  (one contract: authorize, capture,     |
                         |     |   refund, void, tokenize, status)       |
                         +=====|=========================================+
                  thin adapters|  (one small adapter per provider)
            ┌────────────┬─────┴──────┬────────────┐
            ▼            ▼            ▼            ▼
        Worldpay      Nuvei        Adyen        KSNET ...

   SIDE MODULES the core calls:
     • EXTERNAL VAULT (neutral, ours):  PAN + portable network token
     • 3DS MODULE (pluggable):          authenticate when required
     • OBSERVABILITY:                   health, traces, alerts on everything
   WRAPPER:
     • REGIONAL / RESIDENCY:  US-central by default, local node only where a law or latency needs it
```

## The components at a glance

| Component | What it does | Feature |
|-----------|--------------|---------|
| API edge | takes the pay instruction, returns the result | all |
| Routing core | picks the processor, runs the fallback cascade | F1, F3 |
| Standard connector interface | the ONE contract every provider adapter implements | F6 |
| Provider adapters | thin translators, one small one per processor | F6 |
| External vault (neutral) | holds PAN + portable network token, we control it | F2, F4 |
| 3DS module (pluggable) | authentication when a card or region requires it | F5 |
| Operator console | no-code routing rules + monitoring | F7 |
| Observability | live health, end-to-end traces, alerts | F9 |
| Regional layer | US default, local node where required | F8 |

## The big idea: the adapter pattern (no one-offs)

```
   WITHOUT it:  every new provider = a months-long custom integration into the core
   WITH it:     the core speaks ONE language; each provider gets a small adapter
                that translates that language into the provider's own API.

   Add a provider  =  write one adapter to a known contract  +  pass certification.
   The core does not change. Ever.
```

This is the same pattern the open-source core we build on (HyperSwitch) already uses: its
connectors are adapters to one shared interface.

**Honest caveat (open source vs managed):** the connector CODE is genuinely open source
(Apache-2). The self-host build ships ~90+ connectors that YOU enable yourself, no vendor
gating. The managed Cloud adds more to reach ~210+, and those extra ones are enterprise /
managed-only, NOT in the open repo. So "own it later" carries the open-source connectors plus
any managed-only ones we choose to build ourselves, which is a bounded adapter job thanks to
this very pattern. MUST VERIFY with Juspay: which of OUR processors (Worldpay, Nuvei, Trust, and
the Korea stack KSNET / NICE / Allat) are in the open-source build vs managed-only. That answer
decides what self-hosting actually includes.

---

# PART 2 - THE WORDS

## Overview

Orvanna is built in layers with one hard rule: the **core never knows the details of any
single provider.** It speaks one standard internal language. Everything provider-specific
lives in a thin adapter at the edge. That is what lets us add processors fast, swap them
freely, and keep the platform stable as it grows.

## The components

1. **API edge.** The front door. A merchant system sends a payment instruction (charge this
   stored card, this amount, this market) and gets back a clear result. It hides everything
   below it behind one simple, stable interface.

2. **Routing core.** The brain. Given the instruction, it applies the active rules (card brand,
   country, amount, processor health) and chooses the best processor. It also owns the
   fallback cascade: token first, then PAN, then an alternate processor, and the honest-retry
   logic that refuses to chase dead subscriptions. (F1, F3)

3. **Standard connector interface.** The contract. It defines a small, fixed set of operations
   every processor must support: authorize, capture, refund, void, tokenize, status. The core
   only ever calls these. It never calls a provider's API directly. (F6)

4. **Provider adapters.** The translators. One small adapter per processor. Each one takes the
   standard operations and turns them into that provider's specific API calls and back. Adding
   a provider means writing one adapter and passing certification, not rebuilding the core. (F6)

5. **External vault (neutral).** Separate from Orvanna and from any processor. It stores the
   real card number (PAN) and the portable network token, both under our control. The core
   asks the vault for a credential by reference; raw card data never lives inside the core. (F2, F4)

6. **3DS module (pluggable).** A swappable authentication step. When a card or region requires
   3DS, the core calls the configured 3DS provider through a standard interface, the same idea
   as connectors: swap the provider, the core is unchanged. (F5)

7. **Operator console.** A no-code surface where an operator sees rules, processor health, and
   recent results, and changes routing or retry behavior without engineering. (F7)

8. **Observability.** Watches everything: processor health, end-to-end traces of each payment,
   and alerts when something degrades. It is how we keep the machine healthy without surprises. (F9)

9. **Regional layer.** The wrapper. By default everything runs US-central. A local node stands
   up only where a law (residency) or latency to a far processor genuinely requires it. (F8)

## The connector adapter pattern (the spine)

The reason orchestration scales is this separation:

- **Shared, written once:** the core, the routing logic, the retry cascade, the vault calls,
  the 3DS calls, the console, observability. None of this is provider-specific.
- **Per provider, small and standardized:** one adapter that maps the six standard operations
  to that provider's API, plus its certification result.

So the "one-off" never vanishes (each provider really does have its own API), but it shrinks
from a custom integration project to a small, repeatable adapter against a known contract.
That is the difference between a platform and a pile of integrations.

This also makes the business model real: "add a market" becomes "write an adapter and certify
it," a known unit of work we can estimate, schedule, and price. (Detailed in `10-CONNECTOR-ADAPTER-MODEL.md`.)

## Boundaries (what is in the core, what is outside)

| Inside Orvanna | Outside (called by Orvanna) |
|------------------|-------------------------------|
| API edge, routing core, connector interface, adapters, console, observability | the processors themselves |
| | the external vault (separate, neutral vendor) |
| | the 3DS provider (pluggable) |
| | the AWS regional infrastructure it runs on |

Keeping the vault and 3DS OUTSIDE and pluggable is deliberate: it is what keeps us un-locked
and keeps the card data ours.

## What this model hands to the next steps

- The **payment lifecycle** (05) traces one payment through these components, step by step.
- The **data model** (06) names the things these components pass around.
- The **routing** (07), **vault** (08), **3DS** (09), **connector** (10), **console** (11),
  **infra** (12), and **observability** (14) models each zoom into one box above.
