# Orvanna - Design Program (start to finish)

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\ROADMAP.md`
**Living checklist.** Updated as we complete each model. Started 2026-06-15.

This is the whole road from concept to a buildable, modeled platform. Every step
produces a concrete artifact: a written model, a diagram, or both. Nothing is hand-wavy.
We walk it one step at a time, you review as we go, and we adjust.

Legend: [x] done | [~] in progress | [ ] not started

---

## PHASE A - Concept (Stage 0)
- [x] `00-CHARTER.md` - why, scope, the separation rule that keeps it yours
- [x] `01-BEST-IN-CLASS-BLUEPRINT.md` - the best answer per layer, with source traceability
- [x] `02-ORVANNA-CONCEPT.md` - investor-facing concept, plain English
- [x] `USE-CASE-PERSONA.md` - "Global Customer", the fictional global company Orvanna is built
      for.  no real data. DONE 2026-06-15.

## PHASE B - System design (model it out, every step)
- [x] `03-ORVANNA-PBV-SPEC.md` - the engineering design in Purpose / Behavior / Verify
      form (your Unicon format). 9 features, each with outcomes and how we prove them.
      Built two-layer (See it / The words). DONE 2026-06-15.
- [x] `04-ARCHITECTURE-MODEL.md` - the components and their boundaries, built around the
      standard connector-adapter pattern (Howard's insight: no one-offs). DONE 2026-06-15.
- [x] `05-PAYMENT-LIFECYCLE-MODEL.md` - one payment, every step and state, with all branches
      (token fallback, 3DS, retry, stop) and the charge-once guarantee. DONE 2026-06-15.
- [x] `06-DATA-MODEL.md` - the things the system knows and how they relate; core holds
      references, vault holds secrets; one payment / many attempts / one charge. DONE 2026-06-15.
- [x] `07-ROUTING-ENGINE-MODEL.md` - how it picks a processor (eligible -> healthy -> rank ->
      pick), the recovery ladder, and the honest soft/hard/dead-sub logic. DONE 2026-06-15.
- [x] `08-VAULT-MODEL.md` - neutral external vault, PAN + portable token under our control,
      token-first/PAN-fallback, PCI boundary, vault must-have. DONE 2026-06-15.
- [x] `09-3DS-MODEL.md` - pluggable auth, frictionless vs challenge, mandates, recurring
      exemption, swap the provider without touching the flow. DONE 2026-06-15.
- [x] `10-CONNECTOR-ADAPTER-MODEL.md` - the one standard interface, adapter anatomy,
      certification gate, sourcing (own the doorway). DONE 2026-06-15.
- [x] `11-OPERATOR-CONSOLE-MODEL.md` - no-code rules + monitoring + guardrails (safe-change
      pattern, invalid rules blocked). DONE 2026-06-15.
- [x] `12-INFRASTRUCTURE-AWS-MODEL.md` - US-central default, local node only for law or
      latency, volume is never a trigger. DONE 2026-06-15.
- [x] `13-SECURITY-COMPLIANCE-MODEL.md` - PCI scope shrunk by the vault boundary, the
      protection layers, who is responsible for what. DONE 2026-06-15.
- [x] `14-OBSERVABILITY-OPS-MODEL.md` - per-payment trace, per-processor health, dashboards,
      signal-to-action, the honest 24/7 upkeep story. DONE 2026-06-15.
- [x] `14B-RECONCILIATION-MODEL.md` - money truth for BOTH the platform (us) and the merchant
      (the user). Three-way match: our event ledger vs processor settlement file vs bank deposit.
      Exception queue worked in the console; engine is its own subsystem. Leverages HyperSwitch's
      Recon module. Added 2026-06-15 during review (Howard's catch). DONE 2026-06-15.

## PHASE C - Build and business
- [ ] `15-BUILD-PLAN.md` - what to stand up first on the HyperSwitch open-source base, in
      what order, with milestones.
      DECISION (2026-06-15): operator console = leverage HyperSwitch Control Center, then
      re-skin to Orvanna and extend; do NOT build from scratch. Sequence the adopt / re-skin /
      extend work here. (See `11-OPERATOR-CONSOLE-MODEL.md` Build decision.)
- [ ] `16-COST-AND-TEAM-MODEL.md` - what it takes to build and to RUN each stage.
- [ ] `17-BUSINESS-MODEL-PRICING.md` - tiers, the flat (not bps) pricing principle, revenue.
- [ ] `18-GTM-FIRST-PILOT.md` - the first merchant, the wedge, the proof.
- [ ] `19-RISK-REGISTER.md` - every hard part, its mitigation, and who owns it.

## PHASE D - Prove it
- [ ] `20-PROTOTYPE-NOTES.md` - a working slice in the sandbox (core + one connector +
      external vault + 3DS + console).
- [ ] `Orvanna-Investor-Demo.html` - an interactive, tabbed visual the investor can click
      through in five minutes (built with the interactive-explainer pattern).

## Tooling we build alongside
- [x] **`Orvanna-Master-Map.html`** - the whole model in one screen + a live progress tracker
      (this roadmap, drawn). Open it any time to see where we are. Updates as we build. DONE 2026-06-15.
- [ ] **Orvanna synthesis skill** - a reusable skill that regenerates this model from our
      vendor evaluations (the inverse of the payment-vendor-evaluation skill). Build during Phase B.

---

## How we work it
- One step at a time, in order, unless you want to jump.
- HOUSE STYLE - every doc is one file, two layers:
    PART 1 "See it" (tables + clean flows, the whole thing at a glance) on top, for Howard.
    PART 2 "The words" (full detail, the record) below, for documentation and selling depth.
  Part 1 is a distilled view of Part 2, so they never drift. One source of truth.
  Howard reads Part 1; the depth waits in Part 2. Plain English, visuals sparse and uncluttered.
- You review each as it lands; we adjust before moving on.
- Honesty rule stays on: every "hard part" gets named, never buried.
- Separation rule stays on: public research + original design only, no company data.

## Open decisions carried in
- Mojaloop: in as a future account-to-account rails layer, or reference only? (recommend: note now, fold in at Phase C+)
- Korea: in-country vault + direct-vs-aggregator PSP question.
- HyperSwitch open vs managed connectors: self-host open source is ~90+, managed Cloud ~210+;
  the extra are managed-only (not in the open repo). CONFIRM with Juspay which of OUR processors
  (Worldpay, Nuvei, Trust, and Korea: KSNET / NICE / Allat) ship in the open-source build vs
  managed-only. Decides what "own it later" actually carries. (See `04-ARCHITECTURE-MODEL.md`.)
- Network tokens (see `NOTES-Network-Tokens.md`): leaning merchant-managed (Model B) so the
  token is ours and portable; Orvanna routing runs token-first, PAN-fallback, reroute.
  Confirm with Worldpay: does their Provisioning API make US the Token Requestor, and what
  is "Rev Boost"? Feeds the Vault (08) and Routing (07) models.
- Pacing: walk every model with your review (default), or draft a batch then review together?
