# START HERE - Orvanna (for the next Claude, and for Howard)

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\_START-HERE-NEXT-CLAUDE.md`
**Last updated:** 2026-06-15

If you are a fresh Claude session: read this top to bottom, then open `ROADMAP.md`. That is enough
to pick up Orvanna and run without re-deriving anything. If you are Howard: this is the durable
record of where Orvanna stands.

---

## 1. What Orvanna is

Orvanna (codename) is Howard's PERSONAL venture: a universal payment orchestrator that combines the
single best answer from every orchestrator we evaluated (HyperSwitch, Gr4vy, Spreedly, Primer) into
one platform he can own. Built on the HyperSwitch open-source core, a decoupled neutral vault, and
pluggable 3DS.

It is NOT a Unicity project. (Was briefly codenamed "OmniRoute"; renamed to Orvanna 2026-06-15.)

## 2. The non-negotiable rules (read before doing anything)

| Rule | What it means |
|------|---------------|
| **Ownership** | Orvanna is Howard's, not his employer's. Never give it to Unicity. See `00-CHARTER.md`. |
| **Use-case only** | Unicity is used ONLY as the archetype, through a FICTIONAL persona, "Globex Wellness". Never put Unicity's name, volumes, contracts, or any confidential data into Orvanna. |
| **Clean provenance** | Build from public research + original design only. Own time and devices. (Howard to check his employment agreement before going deep.) |
| **House style** | Every doc is ONE file, TWO layers: PART 1 "See it" (tables + clean flows) on top, PART 2 "The words" below. Part 1 is a view of Part 2. |
| **Visual first** | Howard is a visual learner. Pair every explanation with a table or a clean diagram. Walls of words overwhelm him. Keep visuals sparse, plain English, no jargon. |
| **No em dashes** | Hard rule. Commas, colons, ASCII hyphens only. |
| **Momentum** | Howard fears fizzling out on solo projects. When he drifts or doubts, no judgment: reconnect him to the next SMALL step on `ROADMAP.md`. Protect the chain. He asked for this. |

(These are also in memory: `project_omniroute_*`, `feedback_visual_tabular_communication`.)

## 3. Where everything is (this folder)

| File | What it is |
|------|------------|
| `00-TRACKER.md` | **THE status register.** What is approved, built, a gap, or a rethink, plus a changelog. Claude maintains it. Read it first to see where everything stands. |
| `00-CHARTER.md` | Why, scope, ownership + separation rules |
| `01-BEST-IN-CLASS-BLUEPRINT.md` | The best answer per layer, with source traceability (the heart) |
| `02-ORVANNA-CONCEPT.md` | Investor-facing concept, plain English |
| `USE-CASE-PERSONA.md` | Globex Wellness, the fictional target customer |
| `ROADMAP.md` | THE living checklist. Phases A-D, what is done, what is next, house style, open decisions |
| `03-ORVANNA-PBV-SPEC.md` | Engineering backbone, 9 features as Purpose/Behavior/Verify |
| `04-ARCHITECTURE-MODEL.md` | Components + the connector-adapter pattern (no one-offs) |
| `05-PAYMENT-LIFECYCLE-MODEL.md` | One payment, every state and branch |
| `06` to `14` | The rest of Phase B: data, routing, vault, 3DS, connector, console, infra, security, observability |
| `NOTES-Network-Tokens.md` | The token-requestor / portability design input (Worldpay conversation) |
| `NOTES-Connector-Sourcing.md` | Where connectors come from (own the doorway) |
| `Orvanna-Master-Map.html` | Open this: the whole model in one screen + a LIVE progress tracker |
| `Orvanna-Global-Demo.html` | Interactive: world routing (US default, Korea local) + tech flow |
| `Orvanna-Flows.html` | Interactive: 5 flows (end-to-end, vault, 3DS, honest retry, connect a processor) |

## 4. Status (as of 2026-06-15)

```
   PHASE A  Concept ............... DONE  (charter, blueprint, concept, persona)
   PHASE B  System design ......... DONE  (14 models, 03-14, all two-layer)
   PHASE C  Build + business ...... NOT STARTED  <- next, step 15
   PHASE D  Prove it .............. NOT STARTED  (a global demo + a flows demo already seed it)
```

**We are PAUSED before Phase C on purpose.** Howard wanted to review all of Phase B first. Do NOT
start Phase C (the build plan, cost, pricing, GTM, risk) until he says go. The next step is
`15-BUILD-PLAN.md`. The "you are here" marker on the master map sits on 15.

## 5. What was built today (2026-06-15)

- Conceived Orvanna and wrote Phase A (charter, blueprint, investor concept, Globex persona).
- Built all of Phase B: 14 system-design models (03-14), each two-layer, plus two design notes
  (network tokens, connector sourcing).
- Built three interactive HTML artifacts to the same polish as the HyperSwitch demos:
  the Master Map (progress tracker), the Global Demo (region routing), the Flows demo (5 flows).
- Named it: chose codename **Orvanna** (was OmniRoute), confirmed orvanna.io / .ai available
  (orvanna.com is an unrelated jewelry brand, which actually helps the stealth). Public brand still open.
- Made the first build decision: the operator console will **leverage HyperSwitch's Control Center**
  (re-skin + extend), not be built from scratch. Recorded in `11` and roadmap step 15.
- Earlier in the day (vendor-call work, separate from Orvanna, lives in `_VENDOR-CALL-PREP\`):
  built `Connector_Count_Comparison.xlsx`, `Connector_Provider_Lists.xlsx` (named lists + regions),
  and a curated `.LATEST` folder of current docs.

## 6. Decisions already made (do not relitigate)

- Orvanna is Howard's; Unicity is use-case only (Globex persona).
- Phased managed-first: start on Juspay-managed HyperSwitch, decouple to self-host later if a funded
  ops owner exists. (From earlier sessions; carries.)
- Decoupled neutral vault, cross-vendor rule (orchestrator vendor != vault vendor).
- Network tokens: leaning merchant-managed so the token is ours and portable.
- Operator console: leverage HyperSwitch Control Center.
- Codename Orvanna.

## 7. Open questions to resolve (carried into Phase C)

| Question | Where |
|----------|-------|
| Which of OUR processors are in HyperSwitch's open-source ~90 vs managed-only ~210? | ask Juspay; `04` |
| Does Worldpay's provisioning API make US the token requestor? What is "Rev Boost"? | `NOTES-Network-Tokens.md` |
| Korea: in-country vault + direct-vs-aggregator PSP | `ROADMAP.md` open decisions |
| Mojaloop: fold in as a future account-to-account rails layer, or reference only? | `ROADMAP.md` |
| The real public brand name (Orvanna is the working codename) | open |

## 8. How to continue

1. Confirm Howard has reviewed Phase B (he was doing this 2026-06-15).
2. When he says go, start `15-BUILD-PLAN.md` (Phase C), two-layer, visual, plain English.
3. Walk one model at a time. Update `ROADMAP.md` (tick the box) and the master map (move the marker)
   after each. Keep the chain visible.
4. Anything new Howard decides or asks: capture it in the relevant model + the roadmap so it is not lost.
5. KEEP `00-TRACKER.md` CURRENT. Every build, decision, or change updates a row and adds a changelog
   line there. When Howard drops a new file in `HOWARD-FEEDBACK\`, triage it into the tracker's punch
   list and log it. This is his ticketing system, do not let it go stale.

That is the whole picture. Open `ROADMAP.md` and keep going.
