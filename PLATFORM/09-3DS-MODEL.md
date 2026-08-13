# Orvanna - 3DS Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\09-3DS-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F5 | Zooms into step 5 of `05`

> House style: PART 1 see it, PART 2 the words. 3DS is a plug-in, never welded to one vendor.

---

# PART 1 - SEE IT

## What 3DS is, in one line

A bank-led check that confirms the real cardholder is present. It can shift fraud liability to the
issuer and, in many regions, is legally required. Orvanna treats it as a swappable module.

## The flow

```
   payment ready to authorize
        │
        ▼
   need 3DS?  (region mandate OR risk rule)
        │ no ─────────────────────────────► authorize straight away
        │ yes
        ▼
   3DS MODULE (the configured provider)
        │
        ├─ frictionless  ─► issuer approves silently ─► authorize with the proof attached
        └─ challenge     ─► shopper confirms (app / code) ─► authorize with the proof attached
```

## Swappable, like connectors

```
   core speaks ONE 3DS interface  ─►  [adapter: provider A]   or   [adapter: provider B]
   swap the provider in config; the rest of the payment flow does not change.
```

## When it runs

| Situation | 3DS? |
|-----------|------|
| Region mandates it (for example parts of Europe) | yes |
| A risk rule asks for it | yes |
| Low-risk, no mandate | no (frictionless or skipped) |
| Merchant-initiated recurring charge (no shopper present) | usually exempt |

---

# PART 2 - THE WORDS

## Why 3DS matters (F5)

3DS (3-D Secure) is the step where the card's bank confirms the genuine cardholder is the one paying.
Two reasons it matters: in many regions it is a legal requirement, and when it succeeds it can move
the fraud liability from the merchant to the issuer, and often lifts approval rates. The cost is
friction when a challenge is shown, so we want it exactly when it helps and not otherwise.

## Pluggable, on purpose

Orvanna does not hard-wire one 3DS vendor. The core calls a single standard 3DS interface, and a
thin adapter behind it talks to the configured provider (the same idea as the connector adapters in
`10`). Swapping the 3DS provider is a configuration change; the routing, vault, and authorize steps
are untouched. This keeps us off any single 3DS vendor and lets us meet different regional rules
with different providers if needed.

## Frictionless versus challenge

When 3DS runs, most low-risk payments pass **frictionless**: the issuer approves the authentication
silently in the background and the payment continues with the proof attached. Higher-risk payments
get a **challenge**: the shopper confirms in their banking app or with a code, then the flow resumes
at authorize. Either way the authentication result rides along into the authorization.

## When it runs, and when it does not

The routing rules decide when 3DS is invoked: a region mandate, or a risk rule. Where there is no
mandate and low risk, the payment skips it or stays frictionless. Recurring charges where no shopper
is present are usually exempt, which matters a lot for a subscription business: we authenticate the
first time, then run renewals without forcing the customer back through 3DS.

## What this hands to the next steps

- The **routing engine** (07) decides when to call 3DS.
- **Security** (13) notes that authentication proof and liability shift are part of the risk posture.
- This module is its own future deep-dive area (the 3DS-ACS work), and this model is the contract it
  must satisfy.
