# Orvanna - Best-in-Class Blueprint

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\01-BEST-IN-CLASS-BLUEPRINT.md`
**Built:** 2026-06-15 | Stage 0

This is the heart of Orvanna. For each layer of an orchestrator, it names the single
best answer we found across the vendors, says why, says what Orvanna takes,
and points to where that finding lives in our own research so it is traceable, not
asserted. The moat is not any one row. The moat is owning the whole column at once.

---

## The blueprint, layer by layer

### 1. Core routing engine  ->  take from HyperSwitch
- **Why it wins:** open source (Apache-2), modern stack (Rust), and the only base you
  can start renting (Juspay-managed) and end up owning (self-host the same codebase).
- **What we take:** an ownable, open routing core as the foundation. No black box.
- **Honest gap:** the open-source build ships fewer connectors than the managed cloud,
  and self-hosting means you carry uptime. Mitigated by starting managed, then decoupling.
- **Traceability:** Factual_Orchestrator_Scoring (Connectors, Architecture tabs);
  Connector_Provider_Lists (147 open-source connectors).

### 2. Tenant isolation  ->  take from Gr4vy
- **Why it wins:** single-tenant cloud architecture. Your instance is yours. No noisy
  neighbor, your own blast radius, cleaner compliance story.
- **What we take:** a single-tenant deployment option as a first-class choice.
- **Honest gap:** single-tenant costs more to run than shared multi-tenant. It is a
  deliberate trade of dollars for isolation, offered as an option, not forced.
- **Traceability:** Defense_Cheat_Sheets (Single vs Multi-tenant tab); Gr4vy evaluation.

### 3. Connector + token breadth  ->  take from Spreedly
- **Why it wins:** the widest gateway library we found (~150 named gateways) and a
  mature tokenization / vault heritage. Breadth where it counts: real processors.
- **What we take:** the broadest practical connector library, plus tokenization done right.
- **Honest gap:** breadth is a vanity metric unless YOUR processors are in it. The model
  measures breadth by coverage of target markets, not raw count.
- **Traceability:** Connector_Provider_Lists (Spreedly ~150, region tags); Connector_Count_Comparison.

### 4. Operator surface  ->  take from Primer
- **Why it wins:** the best no-code workflow builder and unified observability. Routing
  rules and retries configured by an operator, not an engineer ticket.
- **What we take:** a best-in-class operator console: visual workflow builder + one-pane monitoring.
- **Honest gap:** Primer keeps its full connector list private; polish can hide depth.
  We take the UX idea, not their closed catalog.
- **Traceability:** Primer evaluation; What_Each_Does_Best.

### 5. Vault  ->  decoupled external vault (our locked rule)
- **Why it wins:** the vault must NOT be the same vendor as the orchestrator. You own the
  tokens, the PSP never houses them long-term, and you can switch orchestrators without
  re-vaulting every card.
- **What we take:** an external, vendor-separated vault as a hard architectural rule.
- **Honest gap:** an extra hop and an extra vendor relationship. Worth it for ownership
  and portability. (Korea needs an in-country vault answer - open item.)
- **Traceability:** Factual_Vault_Scoring (incl. Korea Vault tab); Valid_Combinations_Matrix; cross-vendor rule.

### 6. 3DS  ->  pluggable module (Netcetera / GPayments class)
- **Why it wins:** 3DS authentication should be a swappable component, not welded to one
  orchestrator. Keeps you off a single 3DS vendor and lets you meet regional mandates.
- **What we take:** 3DS as a plug-in interface. Bring your own ACS / 3DS server.
- **Honest gap:** 3DS is its own deep evaluation (the 3DS-ACS work, still ahead). This row
  is a placeholder for that future synthesis.
- **Traceability:** HyperSwitch connector list includes 3DS modules (Netcetera, GPayments,
  threedsecureio); 3DS-ACS folder (pending deep dive).

### 7. Routing intelligence  ->  smart routing + our addressable-rate insight
- **Why it wins:** every vendor does "smart routing." Our edge is the honesty layer: an
  optimizer that knows a dead subscription is unrecoverable and does NOT waste retries on
  it, while aggressively retrying genuinely live declines.
- **What we take:** an approval optimizer built on the addressable-rate principle (strip
  dead subs, retry live declines, route to the best processor per market).
- **Honest gap:** this intelligence is only as good as the signal it gets. Needs clean
  subscription-state data in production. The principle is ours and original.
- **Traceability:** the addressable approval-rate analysis and dead-sub stripping logic.

### 8. Regional infrastructure  ->  AWS multi-region, residency-aware
- **Why it wins:** scale alone never justifies a region. The triggers are (a) a law forcing
  data local, or (b) latency to a far local processor hurting approvals/UX.
- **What we take:** US-central by default; a local node only when law (e.g. PIPA in Korea)
  or latency demands it. Region as a deliberate exception, never a reflex.
- **Honest gap:** each region is real cost and ops. The model treats Korea as the one clear
  near-term candidate (biggest market, far local processors), the rest as later waves.
- **Traceability:** the AWS network brief and region logic; Defense_Cheat_Sheets (Region Traffic tab).

---

## Why this is universal and not just a clone

Any one vendor is strong in two or three of these rows and weak in the rest. HyperSwitch
gives ownership but a thinner operator surface. Gr4vy gives isolation but a narrower
catalog. Spreedly gives breadth but is gateway-and-vault, not full orchestration. Primer
gives polish but hides its catalog and is fully managed.

Orvanna's whole thesis is: **own the entire column at once.** Open ownable core +
single-tenant isolation + widest practical connectors + best operator UX + a vault you own
+ pluggable 3DS + honest routing intelligence + disciplined regional infra. Nobody on the
market sells all eight together. That combination is the differentiator and the reason it
is worth designing.

## The Mojaloop question (open)

Mojaloop is an open-source instant-payment switch built for interoperability between
banks and wallets, often at national scale. It is not a commercial card orchestrator like
the other four. Two ways it could matter to Orvanna:

1. **As an idea source:** its interoperability and settlement patterns could inform how
   Orvanna connects to real-time account-to-account rails (a future, post-card layer).
2. **As out of scope for now:** it solves a different problem (A2A / inclusion rails), so we
   could note it and keep the Stage 0 focus on card orchestration.

Recommendation: note it as a Stage 2+ rails idea, keep Stage 0 focused on the four card
orchestrators. Decide together.

---

## Open items to resolve as we move to Stage 1

- Korea: in-country vault + the direct-vs-aggregator PSP question (carries over from the eval).
- 3DS deep dive feeds Row 6.
- Whether Mojaloop's account-to-account ideas join as a future rails layer.
- Confirm the business model and pricing principle (flat, not bps) in the concept doc.
