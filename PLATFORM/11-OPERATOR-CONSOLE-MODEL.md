# Orvanna - Operator Console Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\11-OPERATOR-CONSOLE-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F7 | Surface for the rules in `07`

> House style: PART 1 see it, PART 2 the words. The console is how a non-engineer drives the engine.

---

# PART 1 - SEE IT

## What the console shows

```
   +----------------------------------------------------------+
   |  OVERVIEW   live approval rate, retries, processor health |
   +----------------------------------------------------------+
   |  ROUTING RULES   eligibility, priority, weights (drag/edit)|
   +----------------------------------------------------------+
   |  RETRY RULES     max attempts, what counts as soft        |
   +----------------------------------------------------------+
   |  PROCESSORS      health, active/inactive toggle           |
   +----------------------------------------------------------+
   |  PAYMENT SEARCH  trace one payment end to end             |
   +----------------------------------------------------------+
```

## What an operator can do (no code)

| Action | Result | Guardrail |
|--------|--------|-----------|
| Edit a routing rule | new payments follow it after save + confirm | blocked if no eligible processor remains |
| Set a processor inactive | new payments stop going to it immediately | existing in-flight payments finish |
| Change a retry cap | recovery effort changes | sane min/max enforced |
| Search a payment | see its full trace | read-only |

## The safe-change pattern

```
   edit  ->  preview the effect  ->  save + confirm  ->  takes effect for NEW payments only
            (an invalid rule is blocked with a plain-English reason)
```

---

# PART 2 - THE WORDS

## Why the console exists (F7)

The biggest real-world risk we named is the machine going unhealthy because changes need engineers
and engineers are busy. The console removes that bottleneck: an operator can see what is happening
and change routing, retries, and processor status without writing code or filing a ticket. The
business adapts at the speed of a person, not a sprint.

## What it shows

One place for everything an operator needs: live approval rate, retries, and processor health up
top; the routing and retry rules they can edit; the list of processors with health and an
active/inactive switch; and a payment search that traces any single payment end to end. The same
data the engine and observability use, presented for a human.

## What an operator can do

- **Edit routing rules:** change eligibility, priority, or weights. The change applies to new
  payments after a save-and-confirm step.
- **Activate or deactivate a processor:** flip a processor off and new payments stop routing to it
  at once, while payments already in flight finish cleanly.
- **Tune retries:** raise or lower the retry cap and what counts as a soft decline.
- **Search and trace:** look up any payment and read its full life (which processor, token or PAN,
  3DS or not, attempts, result).

## The guardrails

Power without safety is dangerous on a live payment system, so the console enforces guardrails: a
rule that would leave a payment with no eligible processor is blocked with a plain-English reason;
changes apply only to new payments, never retroactively; retry caps have sane limits; and payment
search is read-only. The pattern is always edit, preview the effect, then save and confirm.

## Build decision (2026-06-15): leverage, do not greenfield

We will **build the console on HyperSwitch's open-source Control Center**, not from scratch.
It already provides connector configuration, routing-rule setup, and analytics (Apache-2),
and Howard has it running in the sandbox at `C:\hs`. Rebuilding a solved surface would cost
months and pull focus off Orvanna's real differentiators (ownership, the portable token,
honest routing).

| | Leverage Control Center | Build from scratch |
|---|---|---|
| Time to a working console | days | months |
| Cost | ~free, open source | high |
| Connector config + routing UI | already built | rebuild all of it |
| Risk | low | high, distracts from the real value |

How we use it, in order:
1. **Adopt** the Control Center as-is for the prototype (Stage 2).
2. **Re-skin** it to Orvanna branding for the demo and pilot (logo, colors, hide HyperSwitch naming).
3. **Extend** it over time with Orvanna-specific screens (honest-retry config, vault / token views).
4. **Reconsider a deeper build LATER, only if** the operator surface becomes a core differentiator
   (the "best operator surface" pillar we took from Primer). Not a Stage 1-2 concern.

Open check (do in the sandbox): how white-labelable is the Control Center (branding, naming)?
That tells us how cheap the re-skin really is. This feeds the build plan (`15`) and cost model (`16`).

## What this hands to the next steps

- The **routing engine** (07) executes whatever rules the console sets.
- **Observability** (14) feeds the live numbers the console shows.
- **Security** (13) governs who is allowed to make changes (roles and audit).
- The **build plan** (15) sequences the adopt / re-skin / extend work above.
