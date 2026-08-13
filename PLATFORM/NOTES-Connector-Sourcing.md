# Orvanna design note - Connector Sourcing

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\NOTES-Connector-Sourcing.md`
**Captured:** 2026-06-15 | Source: Howard's question + open-source library research
**Feeds:** `04-ARCHITECTURE-MODEL.md`, `10-CONNECTOR-ADAPTER-MODEL.md`, the build plan (15)

---

# PART 1 - SEE IT

## Where connectors can come from

| Source | Language | Rough count | How we use it |
|--------|----------|-------------|---------------|
| HyperSwitch open core | Rust | ~90 | already adapters, work out of the box |
| ActiveMerchant (Shopify) | Ruby | ~100+ | reference to PORT new adapters (MIT license) |
| Omnipay | PHP | dozens | reference to PORT (MIT license) |
| Kill Bill plugins | Java | major gateways | pattern / reference |
| a gateway's own API docs | any | any | source of truth for a port |
| managed Cloud (rented) | n/a | up to 210+ | rent the long tail in Phase 1 |

## The funnel

```
   sources of "how to talk to gateway X"        one shape
   HyperSwitch 90  ─┐
   ActiveMerchant   ─┤
   Omnipay          ─┼──►  [ ONE standard connector interface ]  ──►  CORE
   gateway API docs ─┤
   our processors   ─┘
        reference material            we OWN every adapter we write
```

## The honest rules

- Other libraries are in different languages, so we PORT (re-implement), not plug in.
- Each port is bounded work, not free. The reference just shrinks it.
- Respect licenses (ActiveMerchant + Omnipay are MIT = friendly; attribute/comply).
- We do NOT need 210 owned connectors. Own the core + OUR processors; rent the long tail.

---

# PART 2 - THE WORDS

## The point

Howard's worry: self-hosting HyperSwitch only ships ~90 connectors out of the box. The answer
is that the number we own out of the box matters less than owning the DOORWAY: the standard
connector interface (the adapter pattern). Once we own that, a new connector can be sourced from
several places, and all of them end up as the same shape feeding the core.

## Sources, in detail

1. **HyperSwitch's ~90 open-source connectors.** Already adapters to the interface. Free and
   working the day we self-host. This is the base.
2. **ActiveMerchant (Ruby, MIT).** The most established open-source gateway library (~100+
   gateways), Shopify-maintained. Not importable into a Rust core, but a superb REFERENCE for how
   to talk to a given gateway, which is the expensive part of building an adapter.
3. **Omnipay (PHP, MIT).** Built on ActiveMerchant's ideas; dozens of community gateway drivers.
   Same use: reference for porting.
4. **Kill Bill plugins (Java).** An open-source billing/payment platform with a payment-plugin
   model; useful for patterns and a few gateway references.
5. **The gateway's own API docs.** Always the source of truth for a port and for certification.
6. **Managed Cloud (rented).** During Phase 1 we rent the full ~210+ catalog, so we are never
   short on coverage while we decide which connectors are worth owning.

## Why this de-risks the "only 90" worry

- We own the interface, so coverage is not capped by any one upstream.
- We grow owned coverage deliberately: OUR processors first, then high-value ones, porting from
  the reference libraries to shrink each build.
- We rent the long tail until owning it pays off. Own what matters, rent the rest.

## Honest caveats

- "100+ in ActiveMerchant" is reference value, not 100 free connectors. Porting is real work.
- Different languages mean re-implementation and re-certification per gateway.
- License compliance is required when we use another project's code as a basis.
- Exact gateway counts per library should be confirmed before we lean on any one of them.

## Open follow-ups

- Confirm which of OUR processors are in HyperSwitch's open-source ~90 (carried from `04`).
- Estimate the per-adapter porting effort (feeds the cost/team model, step 16).
- Decide the owned-vs-rented connector line for Phase 1 vs Phase 2.
