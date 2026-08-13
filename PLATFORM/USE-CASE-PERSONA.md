# Orvanna - Use-Case Persona: "Globex Wellness"

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\USE-CASE-PERSONA.md`
**Built:** 2026-06-15 | The target customer Orvanna is designed for

> **Globex Wellness is a FICTIONAL stand-in.** It uses no real company's confidential data.
> It models the TYPE of global, multi-market, subscription-heavy company Orvanna serves, so
> we can design and pitch without ever naming or exposing an employer. House style: PART 1 see
> it, PART 2 the words.

---

# PART 1 - SEE IT

## Who Globex is, at a glance

| Attribute | Globex Wellness |
|-----------|-----------------|
| What they sell | health and wellness products, direct to consumer |
| How they sell | mostly monthly autoship subscriptions, plus some one-time orders |
| Markets | ~40 countries; one very large East-Asian market, one large North-American market, and a long tail across Latin America, Europe, MENA, and the rest of APAC |
| Volume | millions of payments a year, the majority recurring |
| Cards | stored on file for autoship; expiries and reissues happen constantly |
| Money goal | keep approvals high, fees low, and never punish recurring revenue |

## A day in their pain

```
  Autoship runs        -> some stored cards decline (expired / reissued) -> lost revenue
  New market launch     -> months of custom processor integration        -> slow, costly
  Far-away processor    -> latency at checkout                            -> drop-off + lower approvals
  Processor holds tokens-> switching means re-collecting every card       -> trapped
  A processor has an outage -> no fallback                                -> sales just stop
```

## Every pain maps to an Orvanna pillar

| Globex pain | Orvanna answer |
|-------------|------------------|
| Recurring cards decline on expiry / reissue | F2 network token auto-updates + F3 honest retry |
| Months to add a processor in a new market | F6 connector adapter + certification |
| Processor holds the tokens; switching = re-collect | F4 our neutral vault, portable token |
| Latency to a far processor hurts approvals | F8 regional node where it counts |
| One processor outage = lost sales | F1 best-processor routing + F3 reroute |
| Can't change rules without engineers | F7 no-code operator console |
| Data-residency laws in some markets | F8 residency handling |
| Don't see failures until they hurt | F9 observability and health |
| 3DS mandates in some regions | F5 pluggable 3DS |

That clean 1-to-1 is the point: Orvanna is built for exactly this company.

---

# PART 2 - THE WORDS

## Who they are

Globex Wellness is a global direct-to-consumer health and wellness company. Customers sign up
and receive products on a monthly autoship subscription, with occasional one-time purchases.
The business lives on recurring revenue, so a declined renewal is not just a lost sale, it is a
lost customer relationship. Globex operates in roughly 40 markets. Its largest single market is
in East Asia, its second is in North America, and the rest spread thinly across Latin America,
Europe, the Middle East, and the rest of Asia-Pacific.

This profile is built entirely from public, general knowledge of how global subscription
commerce works. It contains no confidential figures from any real company.

## Their payment problems

1. **Recurring decline leakage.** Stored cards expire or get reissued. Each renewal cycle, a
   slice of cards decline for no reason other than stale credentials, quietly bleeding revenue.
2. **Slow market expansion.** Every new market wants a local processor. Each integration is a
   multi-month engineering project, so growth is gated by payment plumbing.
3. **Vendor lock-in on tokens.** Their current processors hold the card tokens. Leaving a
   processor would mean re-collecting cards from millions of customers, which is impossible, so
   they are effectively trapped.
4. **Latency and residency.** In their largest market the processor is far from where payments
   are decided, adding latency that hurts checkout and approvals. A couple of markets also have
   data-residency laws that their current US-central setup does not cleanly satisfy.
5. **No fallback and no visibility.** When a processor degrades, there is no automatic reroute,
   and they often learn about it from the revenue dip rather than from a dashboard.

## What they need

- One integration that reaches many processors, with smart routing and automatic fallback.
- Card credentials they OWN, portable across processors, that stay fresh automatically.
- Recovery of genuinely recoverable declines, without wasting money chasing dead subscriptions.
- The ability to add a processor or change a rule fast, without an engineering cycle each time.
- Local processing only where a law or latency truly requires it.
- Real-time health and end-to-end visibility.
- Pricing that does not tax them harder the more they grow (flat, not a percentage).

## Why Orvanna fits

Orvanna's nine features answer Globex's five problems almost one-for-one (see the Part 1 map).
The two that matter most to a subscription business:
- **Owning a portable, auto-updating token** (F2 + F4) directly attacks recurring decline leakage
  and the lock-in trap at the same time.
- **Honest retry and reroute** (F1 + F3) recovers real money on renewals without burning fees on
  customers who are already gone.

Everything else (3DS, connector certification, the no-code console, regional handling, and
observability) exists so Globex can run all of that across 40 markets without an army of engineers.

## Why we use a persona (and not a real company)

Designing for "Globex" instead of any real employer keeps Orvanna cleanly Howard's, keeps all
confidential data out, and lets the investor pitch stand on a realistic market archetype rather
than one company's private numbers. The persona is the demanding target; the ownership stays his.
