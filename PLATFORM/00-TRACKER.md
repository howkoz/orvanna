# 00-TRACKER - Orvanna Status Register

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\00-TRACKER.md`
**Last updated:** 2026-06-15

This is the ONE place to see where everything stands: what is approved, what is built and waiting on
you, what is still a gap, and what needs a rethink. It stands in for a ticketing system for this venture.

> **The rule: Claude maintains this file.** Every time we build, decide, or change something, Claude
> updates the row and adds a changelog line. You read it, you do not maintain it. When you bless a
> BUILT item, say so and it flips to APPROVED. When you spot a new gap, it goes in section 4.

## Status words

| Word | Means |
|------|-------|
| APPROVED | you reviewed it and locked it |
| BUILT | the artifact exists, waiting for your review |
| IN PROGRESS | being worked right now |
| GAP | identified, not built yet |
| RETHINK | something exists but may be wrong, reconsider before trusting it |
| DEFERRED | real, intentionally pushed to later (reason noted) |

## 1. At a glance

```
   Built and locked:   17 models   +   6 decisions
   Open punch list:    17 GAP   |   4 RETHINK   |   1 DEFERRED
```

The open punch list (section 4) is the part to watch. Most of it came from the independent review
in `HOWARD-FEEDBACK\FEEDBACK-2026-06-15-1.md`, triaged below with my disposition.

---

## 2. Decisions locked (APPROVED)

| ID | Decision | Status | Where |
|----|----------|--------|-------|
| DEC-1 | Orvanna is Howard's; Unicity is use-case only (Globex persona) | APPROVED | 00-CHARTER |
| DEC-2 | Phased managed-first (Juspay-managed now, self-host later if a funded owner exists) | APPROVED | 02 / roadmap |
| DEC-3 | Decoupled neutral vault; orchestrator vendor is never the vault vendor | APPROVED | 08 |
| DEC-4 | Network tokens lean merchant-managed (Model B). Direction set, PROOF still pending (see GAP-T1) | APPROVED (direction) | NOTES-Network-Tokens |
| DEC-5 | Operator console = leverage HyperSwitch Control Center, re-skin and extend, not from scratch | APPROVED | 11 |
| DEC-6 | Codename Orvanna (public brand still open) | APPROVED | _START-HERE |

---

## 3. Models built (Phase A + Phase B)

| ID | Model | Status | Where |
|----|-------|--------|-------|
| 00 | Charter | APPROVED | 00-CHARTER.md |
| 01 | Best-in-class blueprint | BUILT | 01-BEST-IN-CLASS-BLUEPRINT.md |
| 02 | Concept (investor) | BUILT | 02-ORVANNA-CONCEPT.md |
| P | Use-case persona (Globex) | APPROVED | USE-CASE-PERSONA.md |
| 03 | PBV spec (9 features) | BUILT | 03-ORVANNA-PBV-SPEC.md |
| 04 | Architecture model | BUILT | 04-ARCHITECTURE-MODEL.md |
| 05 | Payment lifecycle | BUILT (see GAP-ASYNC) | 05-PAYMENT-LIFECYCLE-MODEL.md |
| 06 | Data model | BUILT | 06-DATA-MODEL.md |
| 07 | Routing engine | BUILT (see GAP-DEC, GAP-MIC) | 07-ROUTING-ENGINE-MODEL.md |
| 08 | Vault + tokens | BUILT (see GAP-VLT) | 08-VAULT-MODEL.md |
| 09 | 3DS model | BUILT (see GAP-3DS) | 09-3DS-MODEL.md |
| 10 | Connector adapter | BUILT (see GAP-CEB) | 10-CONNECTOR-ADAPTER-MODEL.md |
| 11 | Operator console | BUILT (see GAP-CON) | 11-OPERATOR-CONSOLE-MODEL.md |
| 12 | Infra + AWS | BUILT (see OPEN-KR) | 12-INFRASTRUCTURE-AWS-MODEL.md |
| 13 | Security + PCI | BUILT (see GAP-P1) | 13-SECURITY-COMPLIANCE-MODEL.md |
| 14 | Observability + ops | BUILT | 14-OBSERVABILITY-OPS-MODEL.md |
| 14B | Reconciliation | BUILT (see GAP-R2) | 14B-RECONCILIATION-MODEL.md |

Demos: `Orvanna-Master-Map.html`, `Orvanna-Global-Demo.html`, `Orvanna-Flows.html` (6 tabs). All BUILT.

---

## 4. Open punch list (gaps, rethinks, deferrals)

P0 = fix before any hard pitch. P1 = settle before build planning. P2 = hygiene so the work stays clean.

| ID | Item | Pri | Status | Source | Next artifact / where it lands |
|----|------|-----|--------|--------|-------------------------------|
| GAP-T1 | Token portability PROOF (TRID owner, Visa/MC support, acceptance, fees, fallback) | P0 | GAP | P0-1 | `TOKEN-PORTABILITY-PROOF.md` (scaffold now, close after vendor calls) |
| GAP-P1 | PAN-fallback PCI data path: vault proxy vs direct retrieval vs relay vs none | P0 | GAP | P0-2 | `PAN-FALLBACK-PCI-BOUNDARY.md` then update 13 |
| GAP-C1 | Competitor matrix, broader 2026 set (Yuno, IXOPAY/TokenEx, BR-DGE, CellPoint, APEXX, Payrails, Paydock) | P0 | GAP | P0-3 | `COMPETITOR-MATRIX-2026.md` |
| FIX-1 | Soften "nobody sells all eight" to "we have not found one vendor that combines all eight in this exact ownership model" | P0 | RETHINK | P0-4 | edit 01 + 02 |
| GAP-B1 | Orvanna product boundary: what we own beyond HyperSwitch (answers "why not just HyperSwitch?") | P0 | GAP | P0-5 | `ORVANNA-PRODUCT-BOUNDARY.md` |
| OPEN-1 | Managed-vs-ownable connectors transition plan (which rented, which owned, when they move) | P0 | GAP | P0-6 / roadmap | confirm with Juspay; folds into 15/16 |
| RETHINK-1 | First pilot too broad; cut to one market / one processor / one vault path / one payment type / one metric / one rollback | P0 | RETHINK | P0-7 | `FIRST-PILOT-THIN-SLICE.md` |
| GAP-COST | Cost and team model (on-call, compliance, cert, support, incident, cloud) | P0 | GAP | P0-8 / roadmap | `16-COST-AND-TEAM-MODEL.md` |
| GAP-ASYNC | Async payment event model: webhooks, pending states, delayed capture, async 3DS, timeouts, reversals, duplicate callbacks, idempotency, final-state rules | P1 | GAP (NEXT) | P1-1 / Howard | `ASYNC-PAYMENT-EVENT-MODEL.md` |
| GAP-R2 | Reconciliation depth: disputes + processor settlement reports (base model done in 14B) | P1 | GAP | P1-2 | extend 14B |
| GAP-DEC | Decline-code normalization matrix by processor; token-declines split from issuer-declines | P1 | GAP | P1-3 | extend 07 or new doc |
| GAP-MIC | Merchant input contract for honest retry (subscription status, failed-streak, lifecycle): required vs optional | P1 | GAP | P1-4 | extend 07 or new doc |
| GAP-CON | Console guardrail depth: approval workflow, preview impact, rollback, rule versioning, audit, permission tiers, emergency freeze | P1 | GAP | P1-5 | extend 11 |
| GAP-3DS | 3DS decision matrix (CIT vs MIT, exemptions, liability shift, challenge fail, abandoned, regional mandates, stored-credential) + result contract | P1 | GAP | P1-6 | extend 09 |
| GAP-VLT | Vault vendor shortlist: capabilities, TRID model, fees, processor compatibility, regions, PCI responsibility | P1 | GAP | P1-7 | new doc (ties GAP-T1) |
| OPEN-KR | Korea fact pack: law (PIPA), data classes, vault options, local PSP path, latency hypothesis, cost | P1 | GAP | P1-8 / roadmap | new doc |
| GAP-CEB | Per-connector effort bands (easy/medium/hard) + certification + ongoing maintenance cost | P1 | GAP | P1-9 | extend 10 |
| GAP-FRD | Fraud/risk input interface: risk-provider contract or merchant risk-input fields | P1 | GAP | P1-10 | extend 07 / 09 |
| DISC-1 | Label claims as proven / assumption / design goal / open question across the docs | P2 | RETHINK | P2-1 | pass over docs |
| PRIN-1 | Keep demos behind the proof docs, not ahead of them | P2 | RETHINK (adopted as a working rule) | P2-3 | standing rule |
| DEF-MOJO | Mojaloop as future account-to-account rails only, until the card core is proven | P2 | DEFERRED | P2-4 / roadmap | revisit Phase C+ |
| GAP-IP | IP hygiene log (source, date, public link, "no confidential data" check). Will record every HYPERSWITCH-BUILD re-derive (HARVEST) | P2 | GAP | P2-5 | `IP-HYGIENE-LOG.md` (cheap) |
| HARVEST | Re-derive public-HyperSwitch assets from the old HYPERSWITCH-BUILD folder (rebrand checklist, deploy stack, provider catalogs, routing, competitive, HS security posture). RE-DERIVE from public sources, do NOT copy; reporting/V2 + Unicity data stay out | P1 | GAP (scheduled for 11 + 15) | Howard / old folder | `NOTES-HyperSwitch-Build-Harvest.md` |

**Non-issue (closed):** P2-2 "old Claude paths are noisy" - expected, ignore unless a path is a live instruction. No action.

---

## 5. Changelog (newest first)

- **2026-06-15** Howard confirmed his employment agreement is clear for this venture; the work-product check is satisfied, no longer an open concern.
- **2026-06-15** Swept the old `HYPERSWITCH-BUILD` folder (it is proto-Orvanna, ~130 items). Full inventory and disposition in `NOTES-HyperSwitch-Build-Harvest.md`: ~45 public-HyperSwitch items to re-derive at the build plan, the reporting/V2 layer to rebuild original, Unicity data left out. Added as HARVEST in the punch list.
- **2026-06-15** Created this tracker. Triaged `FEEDBACK-2026-06-15-1.md` into the punch list above (24 points; incorporated all but one, which was a non-issue).
- **2026-06-15** Built `14B-RECONCILIATION-MODEL.md` + Flows tab 6 (Reconciliation) + Master Map box. Resolves the base of feedback P1-2; remaining depth tracked as GAP-R2.
- **2026-06-15** Fixed the demo animation freeze (resilient visibility-aware ticker) and added a Reset button to every flow tab. Saved the lesson to memory for all future demos.
- **2026-06-15** Built Phase A (00, 01, 02, persona) and Phase B (03-14), the Master Map, and the Global + Flows demos. Paused before Phase C for your review.

---

## How to use this with Claude

- Ask "what's open?" -> read section 4.
- Ask "what did we change?" -> read section 5.
- Bless a BUILT item -> tell Claude, it flips to APPROVED.
- New gap or worry -> tell Claude, it adds a row.
- New feedback file in `HOWARD-FEEDBACK\` -> Claude triages it into section 4 and logs it in section 5.
