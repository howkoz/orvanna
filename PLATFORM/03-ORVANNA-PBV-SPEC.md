# Orvanna - Engineering Design (Purpose / Behavior / Verify)

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\03-ORVANNA-PBV-SPEC.md`
**Built:** 2026-06-15 | Stage 1 (system design) | No code, outcomes and verification only

> **House style:** this doc has two layers. **PART 1 - See it** is the whole spec in tables
> and flows (read this). **PART 2 - The words** is the full Purpose/Behavior/Verify detail
> (the record). Part 1 is a view of Part 2, so they never disagree.

---

# PART 1 - SEE IT

**What Orvanna does, in one line:** take a payment, send it to the best processor, using
a card token we own, authenticate if needed, and recover real declines without chasing dead
customers.

## The nine features at a glance

| # | Feature | What it does (plain) | The win |
|---|---------|----------------------|---------|
| F1 | Best-processor routing | picks the processor most likely to approve, at lowest cost | higher approvals, lower fees |
| F2 | Token-first, PAN-fallback | charges the network token, falls back to the card number | best auth rate, we hold the data |
| F3 | Honest retry + reroute | retries real declines, ignores dead customers | real recovery, no wasted fees |
| F4 | Our own neutral vault | holds the PAN + a portable token we control | own our data, switch providers freely |
| F5 | Pluggable 3DS | swappable authentication step | meet mandates, no vendor lock-in |
| F6 | Add / certify a connector | standard adapter + certification suite | repeatable expansion |
| F7 | No-code operator console | operators change rules, no engineers | adapt fast and safely |
| F8 | Regional + data residency | US by default, local node only when required | comply without overbuilding |
| F9 | Observability + health | see every processor and payment live | fix it before it costs approvals |

## One payment, end to end

```
  Shopper checkout
        |
        v
  +---------------+   rules: brand, country, amount, processor health
  | ROUTE (F1)    |----------------> pick the best processor
  +------+--------+
         v
  +---------------+   pull from our neutral vault (F4)
  | GET CREDENTIAL|--> network token FIRST  --> (PAN only if needed)
  +------+--------+
         v
  +---------------+   only if the card or region requires it
  | 3DS (F5)      |--> frictionless  or  challenge
  +------+--------+
         v
  +---------------+
  | AUTHORIZE     |--> approved? --> DONE
  +------+--------+        |
         | declined        v
         v            record + trace every step (F9)
  +---------------+
  | RETRY/REROUTE |  soft decline -> retry token, then PAN, then another processor (F2,F3)
  | (F2, F3)      |  hard decline -> stop.    dead subscription -> stop.
  +---------------+
```

## What Orvanna is NOT (so nobody asks)

| Not this | Because |
|----------|---------|
| A fraud scorer | it plugs INTO fraud/3DS providers; it does not score fraud itself |
| A card vault itself | the vault is a separate neutral provider; Orvanna orchestrates, it does not store cards |
| A processor / acquirer | it routes TO processors; it does not acquire or settle funds |
| A billing / subscription engine | it charges when told to; the subscription logic lives upstream |

---

# PART 2 - THE WORDS

## Overview

Orvanna is a payment orchestrator. It receives a payment instruction, chooses the best
processor for that card and market, charges using a portable network token held in a neutral
vault we control (falling back to the card number only when needed), runs 3DS when required,
and recovers genuine declines by retrying or rerouting, while never chasing subscriptions that
are truly dead. Every step is observable end to end.

## Non-goals

- **Not a fraud engine** - Orvanna integrates fraud and 3DS providers; it does not produce fraud scores.
- **Not the card vault** - card data lives in a separate, neutral vault that Orvanna calls; Orvanna never stores raw cards.
- **Not a processor or acquirer** - Orvanna routes to processors; it does not acquire, clear, or settle funds.
- **Not a billing or subscription system** - Orvanna charges on instruction; subscription scheduling and state live upstream.

## Features

- [F1 - Route a payment to the best processor](#f1---route-a-payment-to-the-best-processor)
- [F2 - Token-first charging with PAN fallback](#f2---token-first-charging-with-pan-fallback)
- [F3 - Decline retry and reroute](#f3---decline-retry-and-reroute)
- [F4 - External merchant-owned vault](#f4---external-merchant-owned-vault)
- [F5 - Pluggable 3DS](#f5---pluggable-3ds)
- [F6 - Add and certify a new connector](#f6---add-and-certify-a-new-connector)
- [F7 - No-code operator console](#f7---no-code-operator-console)
- [F8 - Regional routing and data residency](#f8---regional-routing-and-data-residency)
- [F9 - Observability and health](#f9---observability-and-health)

---

### F1 - Route a payment to the best processor

**Purpose**: Send each payment to the processor most likely to approve it at the lowest cost
for that card, country, and amount, so approvals rise and fees fall.

**Behavior**:
1. A payment request arrives -> Orvanna selects a processor using the active routing rules (card brand, country, amount, currency, processor health).
2. Two processors are equally eligible -> Orvanna picks per the operator-set priority (cost, approval history, or weight).
3. The preferred processor is unhealthy or down -> Orvanna skips it and selects the next eligible processor.
4. No rule matches the payment -> Orvanna uses the default processor for that market.

**Verify**:
1. Covers B1, B4
   - In the operator console, send a test payment for a US Visa with a matching rule, then with no rule.
   - Confirm it lands on the rule-defined processor, and with no rule, on the market default.
2. Covers B2
   - Set two processors eligible with a cost priority; send a payment.
   - Confirm the cheaper processor is chosen.
3. Covers B3
   - Mark the preferred processor unhealthy; send a payment.
   - Confirm it routes to the next eligible processor.

---

### F2 - Token-first charging with PAN fallback

**Purpose**: Charge with the portable network token first (higher approval, auto-updated by
the card networks), and fall back to the real card number only when needed, so we get the best
auth rate without any processor having to hold our card data.

**Behavior**:
1. A stored card is charged -> Orvanna pulls the network token from the vault and sends it to the chosen processor.
2. The processor or issuer is not token-ready, or the token is declined for a token-specific reason -> Orvanna pulls the PAN from the vault and retries the same charge with the PAN.
3. The underlying card was reissued or re-dated -> the network token still works, because the networks keep it current (no Account Updater batch needed).
4. A charge succeeds on the token -> the result and token reference are recorded; the PAN is never exposed to the processor unless fallback was used.

**Verify**:
1. Covers B1, B4
   - Charge a stored, token-enabled card.
   - Confirm the processor request carried the network token (not the PAN) and approved.
2. Covers B2
   - Charge a card whose issuer is flagged not-token-ready.
   - Confirm Orvanna retried with the PAN and recorded it as a PAN fallback.
3. Covers B3
   - Use a test card that has been reissued.
   - Confirm the same token still charges with no manual card update.

---

### F3 - Decline retry and reroute

**Purpose**: Recover genuinely recoverable declines by retrying or rerouting, while never
wasting attempts or fees on customers who are truly gone, so recovery is real, not vanity.

**Behavior**:
1. A charge is declined for a soft reason (timeout, issuer temporarily unavailable, do-not-honor) -> Orvanna retries per the rules (same processor, then an alternate processor).
2. A charge is declined for a hard reason (closed account, stolen card, no such account) -> Orvanna stops; no retry.
3. A subscription has reached the dead-streak threshold (for example three consecutive failed months) -> Orvanna marks it unrecoverable and does not retry further.
4. A retry on an alternate processor approves -> the success is recorded against that processor and the customer is charged once only.

**Verify**:
1. Covers B1, B4
   - Force a soft decline on the primary processor.
   - Confirm Orvanna retries, reroutes, and produces a single successful charge (no double charge).
2. Covers B2
   - Force a hard decline (stolen-card code).
   - Confirm no retry is attempted.
3. Covers B3
   - Feed a subscription already at the dead-streak threshold.
   - Confirm Orvanna does not retry and flags it unrecoverable.

---

### F4 - External merchant-owned vault

**Purpose**: Keep the card number and the portable network token in a neutral vault we control,
so we own our payment data and can use it across any processor without re-collecting cards.

**Behavior**:
1. A customer provides a card for the first time -> the PAN is stored in the neutral external vault and a portable network token is provisioned under our control.
2. Orvanna needs to charge -> it requests the token (or PAN) from the vault by reference; the raw card never lives inside Orvanna.
3. We switch or add a processor -> the same vault token is presented to the new processor; no card is re-collected.
4. The vault provisions the token -> it is registered under our Token Requestor control, not an acquirer's, so it stays portable.

**Verify**:
1. Covers B1, B4
   - Store a new card.
   - Confirm the PAN is in the vault, a network token was provisioned, and it is registered to us, not an acquirer.
2. Covers B2
   - Trigger a charge.
   - Confirm Orvanna retrieved the credential by reference and held no raw PAN itself.
3. Covers B3
   - Add a second processor and charge the same stored card.
   - Confirm no re-collection of the card was needed.

---

### F5 - Pluggable 3DS

**Purpose**: Run 3DS authentication through a swappable provider when a card or region requires
it, so we meet mandates and lift approvals without being locked to one 3DS vendor.

**Behavior**:
1. A payment needs 3DS (region mandate or risk rule) -> Orvanna invokes the configured 3DS provider before authorizing.
2. The 3DS check returns frictionless success -> Orvanna authorizes with the authentication result attached.
3. The 3DS check requires a challenge -> the shopper completes the challenge, then Orvanna authorizes.
4. The 3DS provider is swapped in configuration -> payments route through the new provider with no change to the rest of the flow.

**Verify**:
1. Covers B1, B2
   - Send a payment that triggers 3DS in a frictionless scenario.
   - Confirm authentication ran and the authorization carried the result.
2. Covers B3
   - Send a payment that triggers a challenge.
   - Confirm the challenge completes and the charge authorizes after.
3. Covers B4
   - Change the configured 3DS provider.
   - Confirm payments authenticate through the new provider with no other change.

---

### F6 - Add and certify a new connector

**Purpose**: Bring a new processor online through a standard adapter and certification path, so
expanding coverage is a known, repeatable job instead of a custom build each time.

**Behavior**:
1. A new processor is needed -> a connector adapter is configured against the standard connector interface.
2. The adapter is ready -> it runs the certification suite (auth, capture, refund, void, decline handling) in sandbox.
3. The certification passes -> the connector is marked live and becomes selectable in routing rules.
4. The certification fails a case -> the connector stays in test status and cannot receive live traffic.

**Verify**:
1. Covers B1, B2
   - Configure a sandbox connector and run the certification suite.
   - Confirm each required transaction type passes.
2. Covers B3
   - Mark a passing connector live.
   - Confirm it appears as a routing option.
3. Covers B4
   - Run a connector with a deliberately failing case.
   - Confirm it cannot receive live traffic.

---

### F7 - No-code operator console

**Purpose**: Let an operator change routing, retry, and processor priority without engineering,
so the business can adapt quickly and safely.

**Behavior**:
1. An operator opens the console -> current routing rules, processor health, and recent results are visible in one place.
2. An operator edits a routing rule -> the change takes effect for new payments after a save-and-confirm step.
3. An operator sets a processor to inactive -> new payments stop routing to it immediately.
4. An operator builds an invalid rule (no eligible processor) -> the console blocks the save and explains why.

**Verify**:
1. Covers B1
   - Open the console.
   - Confirm rules, health, and recent results are visible together.
2. Covers B2, B3
   - Change a rule and deactivate a processor; send test payments.
   - Confirm new payments follow the change and avoid the inactive processor.
3. Covers B4
   - Attempt to save a rule with no eligible processor.
   - Confirm the save is blocked with a clear reason.

---

### F8 - Regional routing and data residency

**Purpose**: Process and store data in the right place, US-central by default and a local node
only where a law or customer latency requires it, so we meet residency rules without standing up
regions we do not need.

**Behavior**:
1. A payment originates in a market with no residency law -> it processes through the US-central deployment.
2. A payment originates in a market with a residency law (for example Korea) -> it processes and stores required data in that market's local node.
3. A market has a far local processor hurting speed -> routing can use the local node to cut latency, by configuration.
4. No local node exists for a market -> traffic falls back to US-central and the gap is logged for review.

**Verify**:
1. Covers B1, B4
   - Send payments from a no-law market.
   - Confirm US-central handling, and with no local node, confirm the fallback is logged.
2. Covers B2
   - Send a payment from a residency-law market that has a local node.
   - Confirm required data stayed in-region.
3. Covers B3
   - Enable local-node routing for a latency market.
   - Confirm latency-sensitive traffic uses the local node.

---

### F9 - Observability and health

**Purpose**: Show the health of every processor and the path of every payment in real time, so
problems are seen and fixed before they cost approvals (the upkeep risk we named openly).

**Behavior**:
1. A processor's decline rate or latency crosses a threshold -> Orvanna flags it and can auto-deprioritize it in routing.
2. A payment moves through the system -> each step (route, token, 3DS, authorize, retry) is recorded and traceable end to end.
3. An operator views the dashboard -> live approval rates, retries, and processor health are visible by market and processor.
4. A failure spikes -> an alert fires to the on-call owner.

**Verify**:
1. Covers B1
   - Drive a processor's decline rate past the threshold.
   - Confirm it is flagged and deprioritized.
2. Covers B2
   - Trace one payment.
   - Confirm every step is recorded and linkable.
3. Covers B3, B4
   - Open the dashboard and trigger a failure spike.
   - Confirm health is visible by market and processor, and an alert fires.

---

## Where each feature is detailed next (Phase B models)

| Feature | Detailed in |
|---------|-------------|
| F1, F3 | `07-ROUTING-ENGINE-MODEL.md` |
| F2, F4 | `08-VAULT-MODEL.md` + `NOTES-Network-Tokens.md` |
| F5 | `09-3DS-MODEL.md` |
| F6 | `10-CONNECTOR-ADAPTER-MODEL.md` |
| F7 | `11-OPERATOR-CONSOLE-MODEL.md` |
| F8 | `12-INFRASTRUCTURE-AWS-MODEL.md` |
| F9 | `14-OBSERVABILITY-OPS-MODEL.md` |
