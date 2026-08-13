# Orvanna - Charter (a universal orchestrator)

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA`

**Name:** Orvanna (the universal orchestrator model)
**Started:** 2026-06-15
**Owner:** Howard Koziara (personal venture concept)
**Status:** Stage 0 - concept and design

---

## What this is

Orvanna is a single, best-in-class orchestrator model that combines the strongest
ideas we found across every vendor we evaluated, into one coherent design that is
OURS. Not a clone of any one product. A synthesis: the best routing core, the best
isolation model, the broadest connector library, the best operator surface, a vault
you own, pluggable 3DS, honest routing intelligence, and a region strategy driven by
law and latency, not vanity.

This folder will grow to hold the concept doc, the architecture, the staged build
plan, and eventually the vault and 3DS extensions.

## Why we are building it

1. To prove, to ourselves and to Howard's family, that this can be built.
2. Because an investor Howard trusts wants a concept that encompasses all of this,
   and has the will but not the technical depth. We supply the depth.
3. Because we have already done the expensive research. This is synthesis, not a
   new investigation.

## The separation principle (read this first, it protects you)

Orvanna is built from PUBLIC vendor research and our OWN original design thinking.

- IN: publicly documented vendor capabilities, public architecture patterns, the
  design principles we reasoned out together, and original design work.
- OUT: Unicity's internal data. No payment volumes, no approval rates, no DuckDB,
  no company-confidential numbers go into this model or any investor material.

The principles we learned are portable and yours. The company's data is not. Built
this way, Orvanna is cleanly, unambiguously yours to show anyone. It costs us
nothing, because the model stands on public research plus original design.

**Ownership and use-case stance (locked 2026-06-15):** Orvanna is Howard's, not
Unicity's. Unicity is used only as the USE CASE archetype - a textbook global, multi-market,
subscription-heavy company that must process everywhere - and possibly a future customer, but
NEVER the owner. The design is built for that generic TYPE of company, modeled with a stand-in
persona (not Unicity's name or numbers). Guardrails to keep it cleanly Howard's:
- Build on Howard's own time and devices, not company resources.
- Use a generic company profile; keep Unicity's confidential volumes, rates, and contracts OUT.
- Howard should read his employment agreement (IP-assignment / moonlighting / non-compete) before
  going deep, since payment ops is adjacent to his day job. (Claude is not a lawyer; this is a
  protect-yourself flag, not legal advice.)
- Keep the provenance trail: public research + original design only.

## What we are synthesizing

The four commercial orchestrators we evaluated in depth:

- HyperSwitch (Juspay)
- Gr4vy
- Spreedly
- Primer

A fifth folder exists in our directory: **Mojaloop**. It is a different category
(an open-source instant-payment switch / interoperability layer, more national-rails
than commercial orchestrator). Decision pending: fold its interoperability ideas in
as a future account-to-account rails layer, or keep it as a reference. See the blueprint.

## Staged roadmap

- **Stage 0 (now): Concept + design.** Charter, best-in-class blueprint, the Orvanna
  concept doc (investor-facing), then the engineering spec. Plain-English, investor-ready.
- **Stage 1: Architecture.** Component diagram, data flow, the vault-decoupling and
  3DS-pluggable design, the AWS region strategy.
- **Stage 2: Build plan.** What to stand up first on the HyperSwitch open-source base,
  in what order, with what team and cost.
- **Stage 3: Prototype.** A working slice (open core + one connector + external vault +
  3DS + console) running in the sandbox.
- **Later: Vault model and 3DS model** get their own best-in-class designs, then merge
  into the full Orvanna platform concept.

## How this folder is organized

| File | Purpose |
|------|---------|
| `00-CHARTER.md` | This file. The why, the scope, the rules. |
| `01-BEST-IN-CLASS-BLUEPRINT.md` | The heart: best answer per layer, with source traceability. |
| `02-ORVANNA-CONCEPT.md` | The central concept doc, investor-facing (plain English). |
| `03-ORVANNA-PBV-SPEC.md` | (next) The engineering design in Purpose / Behavior / Verify form. |
| (later) architecture, build plan, prototype notes | Added as stages progress. |

## Sources (our own prior work we are standing on)

- `_VENDOR-CALL-PREP\.LATEST\` - factual scoring, connector + region lists, cheat sheets.
- `ORCHESTRATOR\HYPERSWITCH-BUILD\` - the HyperSwitch base and sandbox.
- The decoupled-vault rule and the AWS region logic developed across recent sessions.

All public-research and original-design derived. No company-confidential data carried in.
