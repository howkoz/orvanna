# Orvanna - Infrastructure and AWS Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\12-INFRASTRUCTURE-AWS-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F8

> House style: PART 1 see it, PART 2 the words. The rule: US-central by default, a local node ONLY
> when a law or latency demands it. Scale alone never justifies a region.

---

# PART 1 - SEE IT

## The default and the exception

```
   DEFAULT:   everything runs in one US-central region.   (simple, cheap, one thing to run well)

   EXCEPTION: stand up a LOCAL node only when ONE of these is true:
        (a) a LAW forces the data to stay in-country  (residency), or
        (b) the local processor is far enough that LATENCY hurts approvals / checkout.
```

## When a region is and is not justified

| Market situation | Local node? | Why |
|------------------|-------------|-----|
| Residency law (data must stay in-country) | yes | the law forces it |
| Far local processor, latency hurting approvals | yes | speed protects revenue |
| Big volume, no law, processor reachable from US | no | volume alone is not a reason |
| Small volume, high interactive, far processor | maybe | weigh cost vs the latency gain |

## What a region actually is

```
   a "region" = a deployment of the Orvanna core (and the vault, where residency requires)
                running in that country's cloud, handling that market's payments locally.
   The operator console and reporting stay global; only processing moves.
```

---

# PART 2 - THE WORDS

## The discipline (F8)

The expensive mistake in global payments is standing up regions because a market is big. Big does
not mean local is needed. Orvanna's rule is the opposite: run everything in one US-central region
by default, and only add a local node when there is a concrete trigger. That keeps the system simple
and cheap, which is the same thing that keeps it healthy.

## The two real triggers

1. **A law (data residency).** Some countries require that payment or personal data stays inside the
   country. Where that is true, we run a local node so the required data never leaves. This is not
   optional and not about performance, it is compliance.
2. **Latency to a far local processor.** When a market's local processor sits far from where the
   payment is decided, the round trip adds delay that hurts checkout and can lower approvals. A local
   node close to that processor removes the delay. This is a revenue-protection decision, made on
   evidence, not a reflex.

Volume by itself is never a trigger. A huge market whose processor is reachable from US-central with
good speed and no residency law stays on US-central.

## What a region is, concretely

A region is a deployment of the Orvanna core in that country's cloud, handling that market's
payments locally. Where a residency law applies, the vault (or the in-scope data) is deployed locally
too. The global pieces, the operator console and reporting, stay central, so operators still see one
unified picture. Only the processing moves.

## Built to add regions, not to need them

Because the architecture is the same everywhere (one core, one connector interface), adding a region
is standing up another copy of the core, not a redesign. So we can start fully US-central, change
nothing for most of the world, and add a node market by market only where a trigger appears. The
first realistic candidate is a far, residency-sensitive market, evaluated on its own merits when the
time comes.

## What this hands to the next steps

- **Security** (13) maps which data must stay in-region under each residency law.
- The **build plan** (15) treats each region as a discrete, later, optional unit of work.
- The **cost model** (16) prices a region as a deliberate exception, not a default.
