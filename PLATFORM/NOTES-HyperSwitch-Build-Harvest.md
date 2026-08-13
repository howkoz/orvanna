# NOTES - Harvest of the old HYPERSWITCH-BUILD folder

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\NOTES-HyperSwitch-Build-Harvest.md`
**Swept:** 2026-06-15 (full folder inventory, ~130 items reviewed)
**Source folder:** `...\ORCHESTRATOR\HYPERSWITCH-BUILD`

## What this is

`HYPERSWITCH-BUILD` is an EARLIER version of this exact venture: a "productize HyperSwitch + a
reporting layer" effort. The white-label doc even uses the placeholder monogram "HK". It is
proto-Orvanna. **Orvanna is the cleaned-up successor**, the rename + Globex persona is what removed
the IP problem this old folder still carries.

## The rule for using it

| Rule | Why |
|------|-----|
| Re-derive, do not copy | Even the "generic" docs were authored as Unicity work-product. Rebuild the same facts from the PUBLIC HyperSwitch repo and docs so Orvanna's provenance stays 100% public + original. |
| Keep the reporting layer ORIGINAL | The old folder's reporting/recon is built on Unicity's owned "Payment Ops V2". Orvanna's version must be original (started in `14B-RECONCILIATION-MODEL.md`). Never reuse the V2 mapping. |
| Unicity data stays out | Real transaction CSVs, the Juspay quote, meeting recaps, Unicity-branded demos: confidential, leave them where they are. |
| Check the employment agreement first | This folder was built around Unicity's owned V2 asset and Unicity reference data. Confirm work-product terms before leaning on any of it. |
| Log every re-derive | Each item we re-derive gets a line in the IP hygiene log (tracker GAP-IP) with its public source. |

---

## A. CLEAN, re-derive from PUBLIC HyperSwitch (safe)

| Item | Where it is now | Re-derives into |
|------|-----------------|-----------------|
| White-label rebrand checklist (which HS repos to re-skin, Apache 2.0 terms, CSS override, attribution, legal checklist) | `03-white-label/REBRAND_CHECKLIST.md` | `11` console re-skin + `15` build plan |
| Local dev stack (HS router + control-center + Postgres + Redis ONLY, drop the V2 portal service) | `02-deployment/docker-compose.yml`, `README_DEPLOY.md` | `15` build plan / sandbox (live one already at `C:\hs`) |
| Provider + capability catalogs (payin, payout, 3DS, fraud, core features) | `09-providers/*.md` | `04` / `07` / `09` / `10` as public reference |
| Generic routing model + flow diagrams | `HyperSwitch Routing Features.md`, routing-model PDF, `16 - flows/*.jam` | `07` routing engine |
| Competitive landscape baseline (Stripe/Adyen/Spreedly/Primer/Gr4vy/ProcessOut) | `99-research/COMPETITIVE_LANDSCAPE.md` | tracker GAP-C1 competitor matrix |
| HyperSwitch security/compliance posture (HS-side facts only) | `06-security-compliance/SECURITY_POSTURE.md` | `13` security model |
| Demo-script + roadmap templates (structure only) | `07-demo-script/DEMO_SCRIPT.md`, `00-strategy/ROADMAP.md` | demo + program structure |
| HS licensing/feature research (community vs enterprise, SaaS-only modules, 3DS2 DDC, cost-observability vs routing) | `_KNOWLEDGE-LIBRARY/topics/*.md` | tracker OPEN-1 (open vs managed) + `09`/`07` |

## B. V2 TRAP, rebuild ORIGINAL (do not reuse)

| Item | Where | Why it is a trap |
|------|-------|------------------|
| Reporting schema mapping (HS Postgres -> "Payment Ops V2" fact tables) | `04-reporting-module/SCHEMA_MAPPING.md` | Built on Unicity's owned V2 analytics layer. Orvanna reporting/recon must be original (14B + GAP-R2). |
| Product architecture (stack = HS + Payment Ops V2) | `01-architecture/01_PRODUCT_ARCHITECTURE.md` | Leans on V2 as the differentiator. Orvanna's stack is modeled fresh (04). |
| Exec summary + pricing (bundle = HS + V2 + services; Unicity reference deployment; "26 yrs domain knowledge") | `00-strategy/00_EXECUTIVE_SUMMARY.md`, `08-pricing-models/PRICING.md` | Lean on Unicity-owned assets and reference data. Inspiration only; Orvanna sets its own concept (02) and pricing (17). |

## C. KEEP OUT, Unicity confidential (never into Orvanna)

| Group | Where |
|-------|-------|
| Real processor transaction CSVs + their analyses | `100 - excess-info/14-US-CA-EU-Case-Study/` |
| Juspay quote spreadsheets, inputs, cheat sheet, contract Q&A, email drafts | `100 - excess-info/11-hyperswitch-quote/`, `_0-LATEST/02-stakeholder-pack`, `_0-LATEST/03-juspay-q-and-a` |
| Internal meeting recaps | `100 - excess-info/10-meeting-recap/`, `_0-LATEST/01-strategy-and-status` |
| Unicity-branded demos + flows | `HyperSwitch for Unicity.html`, `HyperSwitch-CFO-Risk-Demo.html`, `Unicity Payment Flow ...pdf`, `hyperswitch.mp4` |
| The whole live-engagement snapshot | `_0-LATEST/` (entirely Unicity-contextualized) |

---

## Harvest plan (when, not now)

1. **Now (done):** this manifest + tracker row, so the find is captured and nothing is missed.
2. **At `11` console re-skin and `15` build plan:** re-derive the Table A items into Orvanna, in
   Orvanna's voice, from the PUBLIC HyperSwitch repo/docs, stripped of V2 and any Unicity reference.
   Log each in the IP hygiene log (GAP-IP) with its public source.
3. **Reporting/recon:** stays original (14B + GAP-R2), never the V2 mapping in Table B.
4. **Before any of it:** confirm the employment-agreement work-product terms.

## Provenance note

Complete sweep on 2026-06-15. About 45 items are public-HyperSwitch reusable (Table A), the rest are
V2-trap (Table B) or Unicity keep-out (Table C). The old folder is a map to mine, not a thing to clone.
