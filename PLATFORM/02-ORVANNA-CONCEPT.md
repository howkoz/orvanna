# Orvanna - Concept (investor-facing)

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\02-ORVANNA-CONCEPT.md`
**Built:** 2026-06-15 | Stage 0 | Audience: Howard + investor (plain English, no jargon)

---

## In one line

Orvanna is a payment orchestrator that combines the single best answer from every
major orchestrator into one platform you can actually own: route any payment to any
processor, keep your card vault separate and yours, plug in 3DS, run it where the law
and your customers require, and let an operator (not an engineer) change the rules.

---

## The problem

A business that sells in many countries has to connect to many payment processors.
Each connection is months of engineering. Switching is painful. If one processor has a
bad day, sales are lost with no fallback.

A payment orchestrator sits in the middle of this. You integrate with it once, and it
connects you to many processors, routes each payment to the best one, retries failures,
and shows everything in one place.

The catch: every orchestrator on the market today forces a compromise. You get
ownership OR breadth OR isolation OR polish, never all four. Most also want to hold your
card data, and most price in a way that quietly punishes recurring and subscription
businesses (a percentage of every transaction, forever).

## The insight (earned, not assumed)

We did four deep evaluations: HyperSwitch, Gr4vy, Spreedly, Primer. The finding was
consistent: no single vendor is best at everything. Each is strong in two or three areas
and weak in the rest.

The winning move is not to pick one. It is to assemble the best answer for each layer
into one coherent platform, and to own the core so you are never locked in.

## What Orvanna is (eight pillars, plain English)

1. **An ownable, open core.** You can rent it first and own it later, on the same code.
   No black box, no trap. (Best-in-class: HyperSwitch.)
2. **Your own instance.** Not shared with strangers. Your performance and your blast
   radius are yours. (Best-in-class: Gr4vy.)
3. **The widest practical processor library.** Connect to the processors you actually
   use, anywhere you operate. (Best-in-class: Spreedly.)
4. **A console anyone can drive.** Change routing and retry rules with no code.
   (Best-in-class: Primer.)
5. **A card vault that is separate and yours.** The processor never owns your tokens, so
   you can switch processors without re-collecting a single card.
6. **3DS as a plug-in, never lock-in.** Bring your own authentication, meet regional
   mandates, swap it freely.
7. **Honest routing intelligence.** It does not waste retries on customers who are truly
   gone; it fights hard for the payments that are actually recoverable.
8. **Infrastructure that goes local only when it must.** US-central by default, with a
   local node only where a law or your customers' speed genuinely require it.

Nobody on the market sells all eight together. That combination is Orvanna.

## How it works (in plain English)

A shopper checks out. Orvanna's core decides the best processor for that card, that
country, and that amount. The card details are pulled from YOUR external vault, never
stored by the processor. If the card needs 3DS authentication, that runs through a
pluggable module. The payment goes to the chosen processor. If it fails for a reason
that is recoverable, Orvanna retries or reroutes automatically. Everything is visible
in one console. It all runs on AWS, US-central by default, with a local node only where
required (Korea is the clearest near-term example).

```
                         +---------------------------+
   Shopper  ---------->  |   Orvanna Core          |  ----> Processor A
   (checkout)            |   route + retry + decide  |  ----> Processor B
                         +---------------------------+  ----> Processor C
                              |        |        |
                  +-----------+        |        +------------+
                  |                    |                     |
          +---------------+   +-----------------+   +-------------------+
          | Operator      |   | External Vault  |   | 3DS module        |
          | console       |   | (YOUR tokens)   |   | (pluggable)       |
          | no-code rules |   +-----------------+   +-------------------+
          +---------------+
                          AWS: US-central default, local node only when law/latency demands
```

## Why it is defensible (the moat)

- **The combination.** Owning the whole column at once is something no incumbent sells.
- **Ownership.** An open core means customers are never trapped. That is the exact fear
  that makes merchants distrust closed orchestrators, and we remove it.
- **Honesty layer.** Routing that respects which declines are actually recoverable is a
  real, original edge, not a marketing line.
- **Vault separation as a principle.** Portability and trust are built into the design,
  not bolted on.

## Who it is for

Multi-market merchants, especially subscription and direct-to-consumer businesses, who
sell across many countries, want to own their payment data, are tired of building a new
integration for every processor, and refuse to be locked in. This is a real and large
segment, and one we understand from the inside.

## How it could make money (early thinking, to refine)

- **Managed tier:** hosted, supported, a monthly fee plus a small FLAT per-transaction
  fee. Flat, not a percentage. Percentage (bps) pricing punishes recurring revenue, and
  refusing to do that is itself a wedge against most incumbents.
- **Self-host tier:** a license plus support for those who want to run it themselves.
- **Add-on modules:** the vault and 3DS as separately priced pieces.
- **Services:** onboarding help and new-processor integration work.

The pricing principle, stated once and kept: never price in a way that punishes a
customer for growing their recurring revenue.

## The honest hard parts (no inflation)

- **Connector certification is real work.** Every processor integration must be built and
  certified. The open core is a head start, not a free lunch.
- **PCI and security are serious and non-negotiable.** The external-vault design helps
  shrink the burden, but compliance is a real cost and a discipline.
- **Someone must keep it healthy, 24/7.** This is the single biggest real-world risk, and
  we name it openly: platforms like this fail when the owner under-resources upkeep. The
  plan must FUND operations, not assume them.
- **Funded incumbents exist.** They have money and salespeople. Our wedge is ownership,
  honesty, and DTC-friendly pricing, not outspending them.
- **Depth in hard markets (Korea and the rest of APAC) is an open question to solve,**
  not a solved fact.

## The staged plan (how we de-risk)

- **Stage 0 (now):** this concept plus the architecture design. Cheap, proves the thinking.
- **Stage 1:** the full architecture plus a costed build plan.
- **Stage 2:** a working prototype on the open core (one processor, external vault, 3DS,
  the console) in a sandbox.
- **Stage 3:** a first real merchant pilot.

Each stage is a small bet that unlocks the next. Nobody funds the whole thing on faith.

## What we need from the investor conversation

1. Validate the concept and the customer segment.
2. Fund Stage 1 and Stage 2 (architecture and prototype): a defined, small, time-boxed scope.
3. Agree up front on who owns operations long term, because that is the thing that makes
   or breaks platforms like this.

## How this was built (so it is cleanly yours)

Orvanna is designed from public vendor research and our own original thinking. No
employer-confidential data is used in the concept or any investor material. The
principles are portable; the model is yours.

---

**Next in this folder:** `03-ORVANNA-PBV-SPEC.md` (the engineering design in Purpose /
Behavior / Verify form), then the full start-to-finish design program (see the roadmap
Howard and Claude are about to lay out), and the Orvanna synthesis skill that
regenerates this model from our evaluations.
