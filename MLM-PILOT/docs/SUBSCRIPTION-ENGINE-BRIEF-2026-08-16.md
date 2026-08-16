# Subscription Engine Brief
As of 2026-08-16. Author: mlm-architect. Status: BRIEF, not the final specification.
Decisions here are argued and dated but nothing is locked until Howard rules; every
open question carries a recommended default so nothing blocks.

Plain path:
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\SUBSCRIPTION-ENGINE-BRIEF-2026-08-16.md`

Howard's direction, 2026-08-16, in his own words: the example documents are idea
sources, not requirements ("i am not saying use everything in the examples but just
to get an idea"); in-house is fine if it is the stabler choice ("if you feel it is
better to build inhouse this has to be something stable"); and the hard requirement:
"this subscription engine needs to be able to do retries but logical based on decline
messages". Decline-code-aware retries are the centerpiece of this brief, section 3.

## Acronym key

| Short form | Spelled out |
|---|---|
| AI | Artificial Intelligence |
| API | Application Programming Interface |
| CIT | Customer Initiated Transaction, the cardholder is present and acting |
| MIT | Merchant Initiated Transaction, the merchant charges a stored credential with no cardholder present |
| MLM | Multi-Level Marketing |
| PV | Personal Volume |
| SV | Sales Volume |
| CV | Commissionable Volume |
| TV | Team Volume |
| SaaS | Software as a Service |
| UTC | Coordinated Universal Time |
| 3DS | 3-D Secure, the card network step that asks the shopper's bank to confirm identity |
| CVV | Card Verification Value, the three digit code on the card |
| NSF | Non-Sufficient Funds |

## 0. Where we actually stand

`app.subscriptions` holds 1,820 seeded rows and a clean month model (start month
inclusive, cancel month exclusive). The compensation plan already defines the
subscription semantics: on the first day of each month every active subscription
generates one order for that volume month. But **nothing has ever charged a
subscription.** The seed generator wrote the orders directly; the live checkout
(`functions\create-payment\index.ts`) opens every payment with `confirm: false`, no
customer object, no stored credential, and no mention of future use. Verified by
reading the file on 2026-08-16: **no card is stored anywhere, on our side or at the
orchestrator, and each payment is a fresh card entry.** That single fact shapes
everything in section 2.

---

## 1. What the examples teach

Both documents are back-office user guides from the DataTrax and InfoTrax
BackOffice lineage, roughly 2002 era, read page by page on 2026-08-16.
`autoship-rules.pdf` is 8 pages; `autoship-rules2.pdf` is 17 pages. They describe
direct-selling Autoship template mechanics, not modern SaaS billing. **Neither
document contains a retry schedule, a dunning sequence, or a decline-reason
taxonomy.** The closest they come is a batch card authorization report that prints
"a short description of why the payment was not authorized" for a human to read
(rules2, pages 15 to 17). So the retry engine in section 3 is built from our own
rail's evidence and from published card-network practice, and is attributed as such,
not laundered through the examples.

What the examples do teach, rule by rule. DS marks a rule that is direct-selling
specific (autoship feeds volume); generic SaaS billing rules carry no mark.

| # | Rule found | Source | Verdict | Why |
|---|---|---|---|---|
| E1 | An autoship is a stored TEMPLATE (items, quantities, payment type, dates), separate from the orders it generates | rules1 p.1, p.6 to 8 | **Keep** | Exactly our `app.subscriptions` versus `app.orders` split; the examples confirm the shape we already have. |
| E2 | Generation is a deliberate BATCH RUN an operator triggers with a period, then confirms, then gets a report | rules1 p.2 to 4; rules2 p.9 to 12 | **Keep** | Matches this project's whole culture: versioned runs, human trigger, printed evidence. Renewal billing becomes a run, like a commission run. Section 5. |
| E3 | Idempotency by period: a template generates at most once per period, enforced by "last run period must be less than the entered period" | rules1 p.2, p.5; rules2 p.9 | **Keep** | The 2002 version of our bridge's `(demo_order_id, volume_month)` unique pair. One billing per subscription per month, enforced structurally. |
| E4 | An EDIT REPORT previews exactly which templates will generate before anything runs, excluding ones already generated this period | rules2 p.7 | **Keep** | This is a dry run before the batch. We already do this for the bridge; the billing run gets the same preview discipline. |
| E5 | Batch number equals day of month, to spread generation load across the month (DS: also spreads warehouse shipments) | rules1 p.8; rules2 p.3 | **Discard for v1** | Load spreading matters for warehouses and for real card traffic at scale. We have no shipping, about 1,800 subscriptions, and a comp plan whose months bill on day 1. First of month for everyone, per the existing specification. Revisit only if anniversary billing is ever wanted (open question Q1). |
| E6 | Frequency: generate every N periods, or every N days under the next-run-date method | rules1 p.8 | **Discard for v1** | Every Orvanna product is monthly. A frequency column is speculative generality; the month model already in `app.subscriptions` is sufficient. |
| E7 | Start and end dates gate generation; end defaults to 10 years out; a template whose end date passed goes inactive automatically | rules1 p.5, p.8 | **Adapt** | We keep start month and exclusive cancel month, which are stronger (no day-of-month arithmetic). The auto-deactivation idea survives as: cancel month reached means the engine simply stops selecting it, no status flip needed. |
| E8 | Statuses include active, inactive (pause), deleted, and an autoship can be UNDELETED by re-entering a status | rules1 p.4, p.8; rules2 p.8 | **Adapt** | Pause and resume are worth having (section 3 state machine). Undelete becomes: cancellation is a dated fact, not a row deletion, so "undelete" is just clearing or moving the cancel month. We never delete rows anyway, by house rule. |
| E9 | Bonus Protect (also called Business Protect): a special template that only generates an order if the distributor's personal qualifying volume for their rank has NOT been met this period (DS) | rules1 p.1 to 2; rules2 p.1 | **Discard, with respect** | The single most interesting DS rule in either document: an insurance autoship that tops a member up to qualification. But it is self-purchase whose only purpose is maintaining qualification, which is exactly the pay-to-play pattern our own comp plan specification (section 3 design note) says regulators criticize. Recorded here so the idea is not lost; not building it. |
| E10 | Bonus Protect runs only at end of month, after real volume is known (DS) | rules2 p.3 | **Discard with E9** | Correct sequencing if you build E9: you cannot know a shortfall until the month is nearly over. Noted because it shows the examples understood run-order dependencies. |
| E11 | Recommended payment types for autoship are credit cards and bank drafts; payment type is stored per template | rules2 p.6 | **Adapt** | Card only on our rail. The durable idea is that the payment credential is a property of the subscription, which is precisely the mandate or token discussed in section 2. |
| E12 | Bank draft orders are HELD for a payment-type-specific number of days before release: one subroutine holds 0 days, another 10 days | rules2 p.14 | **Keep the principle** | The first appearance anywhere in the examples of per-payment-behavior timing rules. Generalized honestly: different failure classes get different clocks. That principle, upgraded from payment type to decline code, is the retry engine. |
| E13 | Batch Credit Card Authorization: one batch job attempts every unauthorized card payment and prints a report listing each failure WITH the reason | rules2 p.15 to 17 | **Keep the germ, replace the mechanism** | This is 2002's retry engine: re-run everything, let a human read the reasons. Our version reads the reason FIRST and lets the reason decide whether and when to retry. Section 3. |
| E14 | A payment-versus-invoice discrepancy inside a tolerance (example given: 10 percent) releases without manager approval; over it, a manager must approve | rules2 p.1 | **Discard** | Exists because checks and freight made totals fuzzy. Our rail refuses any mismatch: succeeded requires an exact integer cent match. A tolerance would be a downgrade. |
| E15 | Price recalculation: a batch task updates template prices and volumes to current catalog values without generating orders, and the generation report prints "value before recalc" | rules1 p.5, p.2 | **Adapt** | Renewals should bill at the CURRENT catalog price, and any change from the prior month should be visible in the run report, not silent. The before-and-after note is a good audit habit worth copying. |
| E16 | The next-run-date is computed ONCE from date plus batch number; changing the batch number afterwards does not recompute it, the operator must update it by hand | rules2 p.3 to 4 | **Keep as a warning** | A documented footgun: derived-but-then-manual state drifts. Our billing date must always be DERIVED from period arithmetic, never a stored copy an operator forgets to update. |

**Summary of the harvest.** The examples validate our template-versus-order split,
give us the run discipline and the per-period idempotency rule, contribute the
pause and preview ideas, and hand us two genuinely good principles: failure-class-
specific clocks (E12) and reason-on-the-report (E13). They contain nothing on
decline taxonomy, cadence, proration, or card update flows, so those come from the
rail and from industry practice, stated as such.

---

## 2. Build versus buy

**Recommendation, 2026-08-16: build in-house, small and boring, on the rails we
already trust.** The argument is specific to this stack, not a general preference.

**Why the vendor path is mostly closed anyway.** Hosted billing products (Stripe
Billing, Recurly, Chargebee, and kin) want to own the payment rail: they charge
cards through their own gateway credentials and their own vault. Our demonstration
deliberately runs HyperSwitch hosted sandbox orchestrating a Braintree sandbox
connector, with test cards and no path to a real bank. A billing vendor cannot
drive that rail, and pointing one at a real gateway would break the "no real money
by construction" property that is the project's spine. It would also break the
$0 per month stack rule. The only vendor-shaped option that fits is HyperSwitch
itself, which is not a billing engine but does carry the one primitive we lack:
stored credentials.

**The single biggest constraint, named plainly: today no card is stored anywhere.**
`create-payment` opens each payment with `confirm: false` and no customer identity;
the shopper types the card into HyperSwitch's frame; nothing survives the payment.
Recurring charging therefore requires one of exactly two paths, and the brief owes
both honestly:

**Path A, real stored credentials through HyperSwitch mandates.** HyperSwitch's
public API supports a customer object plus `setup_future_usage: off_session` on the
first Customer Initiated Transaction (CIT), returning a payment method token or
mandate that later Merchant Initiated Transactions (MIT) can charge with
`off_session: true` and no cardholder present. Braintree appears in HyperSwitch's
published connector matrix with card mandate support. **What I could not verify
from the repository alone, stated plainly:** whether the HOSTED sandbox account we
actually use has mandates enabled, whether the Braintree sandbox connector
`mca_eE4v07QwkYUSyF55vrUC` accepts off-session confirms, and how the first
payment's 3DS outcome is carried onto later MITs. Nothing in our functions has
ever sent a customer identifier or a setup flag, so the rail's real behavior is
unknown until a spike test runs: one CIT with the setup flag, then one server-side
MIT against the returned credential. That spike is the first task of Phase S2 and
its outcome decides whether Path A is real on our rail.

**Path B, simulated renewals.** The billing run creates the renewal order and then
resolves its payment outcome from a deterministic simulation table instead of a
processor call: each subscription in the demo data is assigned an outcome script
(succeeds; declines code 2001 then recovers on retry two; hard-declines 2013; and
so on). No card, no processor, fully reproducible, and every retry path provable
on demand, which a real sandbox cannot promise because sandbox behavior can change
under us.

**Recommendation between them: both, in that order reversed.** Phase S1 ships the
engine on Path B, because the state machine, the classification table, the run
discipline, and the bridge integration are the actual product and none of them
need a card. Phase S2 attempts Path A on the sandbox and, if the spike passes,
real test-card renewals become one more outcome source feeding the same engine.
If the spike fails, the demonstration still proves everything with Path B and the
brief's honesty holds: the engine is real, the money is simulated, exactly as the
site already says about itself. In-house is also the stability answer Howard asked
for: every dependency in Path B is Postgres, which is the most stable component we
own, and the discipline (versioned runs, immutability, recomputation) is the one
already proven twice in this project.

---

## 3. The retry engine

The hard requirement, and the section Howard will read hardest. The rule that
governs everything here: **the decline reason decides the retry, never a blind
schedule.** A schedule without classification retries stolen cards (which card
networks fine you for) and gives up on empty accounts two days before payday.

### 3.1 What our rail actually surfaces

Evidence from the code, not assumption. `retrieveAndApplyPaymentTruth` in
`functions\_shared\edge.ts` already stores, per payment: the orchestrator status
(seventeen values mapped), the connector `error_code` and `error_message`, and our
own refined reason (`declined`, `declined_after_authentication`,
`authentication_failed`, `authentication_error`, `cancelled`, `expired`,
`amount_mismatch`, and the rest). On a Braintree decline, the connector error code
is Braintree's processor response code. **Classification input is therefore:
connector error code first, orchestrator status second, our refined reason third.**
An unrecognized code is classified ambiguous, never soft, so an unknown decline can
never earn itself an aggressive retry schedule.

### 3.2 The classification table

Three classes plus two special lanes. Braintree's sandbox is amount-triggered:
a transaction whose dollar amount is 2000.00 through 2999.99 declines with the
processor response code equal to the whole dollar amount (2001.00 declines with
code 2001), and 3000.00 answers processor network unavailable. That is what lets
the demo PROVE each row below on the real rail. (From Braintree's published
sandbox documentation; to be re-proven on our rail in Phase S2, since none of it
is verifiable from the repository.)

**Hard declines: NO retry, ever. Subscription moves to card_update_required.**
Retrying these is useless at best and network-sanctioned at worst (Visa's
category 1 "issuer will never approve" codes carry per-attempt fines when
retried).

| Braintree code | Meaning | Why no retry |
|---|---|---|
| 2005 | Invalid credit card number | The credential is wrong. Time will not fix arithmetic. |
| 2006 | Invalid expiration date | Same: bad data, not bad timing. |
| 2007 | No account | The account behind the card does not exist. |
| 2009 | No such issuer | The card number references a bank that is not real. |
| 2012 | Processor declined, possible lost card | Network rule: do not retry, do not tell the shopper why in detail. |
| 2013 | Processor declined, possible stolen card | Same, and the strongest case in the table. |
| 2014 | Processor declined, fraud suspected | Same. |
| 2047 | Call issuer, pick up card | The issuer wants the plastic back. Terminal. |
| 2004 | Expired card | Permanent for THIS credential, fully recoverable with a new one, so it is the card_update flow's front door rather than a retry candidate. |

**The cancellation lane, stricter than hard.** Two codes are not payment failures
at all, they are the cardholder speaking:

| Braintree code | Meaning | Action |
|---|---|---|
| 2017 | Cardholder stopped billing | Treat as a cancellation request for THIS subscription, effective immediately: set the cancel month, notify, never retry. Retrying a stop instruction is how merchants earn chargebacks and network penalties. |
| 2018 | Cardholder stopped all billing | Same, for every subscription the member holds. |

**Soft declines: scheduled retries, cadence in 3.3.** These are "not now", not
"not ever".

| Code or condition | Meaning | Retry posture |
|---|---|---|
| 2001 | Insufficient funds | The classic. Retry on the schedule; money arrives on paydays, which is why the schedule spans days, not minutes. |
| 2002 | Limit exceeded | Card limit; resets with the cycle. Same schedule. |
| 2003 | Cardholder activity limit exceeded | Velocity limit; usually clears within a day. Same schedule. |
| 3000 | Processor network unavailable | Transient infrastructure. One immediate retry (minutes, not days), then the normal schedule; it does not consume a scheduled attempt if the immediate retry succeeds. |
| Our own `processor_unreachable` outcome | We could not reach HyperSwitch at all | Same as 3000: infrastructure trouble is not a card fact, and it never counts against the card. |

**Ambiguous declines: limited retries with backoff, then escalate to the member.**
The issuer said no and declined to say why. Industry treatment (Visa category 2,
"issuer cannot approve at this time") allows retries but caps them; the cap that
matters is at most 15 attempts in 30 days across all categories, and we stay far
under it.

| Code | Meaning | Posture |
|---|---|---|
| 2000 | Do not honor, the generic no | Two scheduled retries with backoff. If both fail, stop guessing and ask the member: dunning contact, then card_update_required. |
| 2038 | Processor declined, no further detail | Same as 2000. |
| 2044 / 2046 | Declined, call issuer / contact bank | One retry only, then straight to member contact: the issuer has explicitly asked for a human conversation and a machine cannot have it. |
| 2015 / 2019 / 2024 | Transaction not allowed / invalid transaction / card type not enabled | Zero retries, but not card fraud either: these smell like OUR configuration. Flag `needs_human` on the run report; do not burn attempts on a merchant-side misconfiguration. |
| 2016 | Duplicate transaction | Never retry as-is: the processor thinks it already saw this charge. Investigate before anything else; a retry here is how double charges happen. |
| Anything unrecognized | Unknown code | Ambiguous posture, and the code is printed loudly on the run report, echoing E13: the reason always reaches a human. |

### 3.3 The cadence, and where it comes from

The examples offer no cadence (section 1), so this is reasoned from the plan's own
calendar and stated industry practice, not copied from anywhere. Two fixed points
anchor it: renewals bill on day 1 of the month (comp plan specification, section 1),
and the commission run happens after month end with policy P3 refusing late
arrivals into a finalized month. So the whole retry story must fit inside one
calendar month, and it comfortably can:

| Day of month | Event | Notes |
|---|---|---|
| 1 | Billing run: the renewal charge attempt | Success books the volume immediately. |
| 2 | Retry 1 (soft and ambiguous) | Catches transient holds fast. |
| 4 | Retry 2 | Two-day spacing: same-day retries against NSF are wasted attempts. |
| 8 | Retry 3 (soft only; ambiguous has now escalated) | Spans a weekly pay cycle. |
| 8 | Dunning notice 1 to the member | "Your renewal has not gone through, update your card." |
| 15 | Retry 4, the payday retry | Mid-month paydays are the single best recovery moment for NSF; industry dunning data consistently shows day 14 to 16 spikes. |
| 15 | Dunning notice 2 | Firmer copy, card update link. |
| 22 | Retry 5, final | Last chance inside the month. |
| 26 | Suspension | Unpaid subscription moves to suspended; the member keeps portal access but the month's PV from this subscription is gone (section 4.3). |
| month end | Commission run | Sees only what actually succeeded, per policy P1. |

Maximum five attempts for a pure soft decline (billing day plus four retries),
three for ambiguous (billing day plus two), one for 2044/2046, zero for hard.
Every count is far inside the 15-in-30-days network ceiling, deterministic, and
computable from the period alone: given a period and a decline class, anyone can
reproduce the exact retry dates, which is what makes the verifier able to grade a
billing month the way it already grades a commission month.

### 3.4 The state machine

```mermaid
stateDiagram-v2
    [*] --> active: subscription created (checkout or seed)
    active --> past_due: billing attempt declined (soft or ambiguous)
    active --> card_update_required: hard decline on billing day
    active --> canceled: member cancels, or code 2017/2018
    past_due --> in_retry: retry scheduled per class
    in_retry --> active: a retry succeeds, volume books
    in_retry --> past_due: retry declined, attempts remain
    in_retry --> dunning: soft attempts exhausted, or ambiguous escalation
    in_retry --> card_update_required: hard decline on any retry
    dunning --> active: payday retry or member-fixed card succeeds
    dunning --> suspended: day 26, nothing recovered
    card_update_required --> active: member completes a NEW checkout card entry (fresh CIT with 3DS)
    card_update_required --> suspended: month ends without an update
    suspended --> active: member pays again (new CIT); next month forward, no back-billing
    suspended --> canceled: two consecutive unpaid months
    canceled --> [*]
```

Transitions not drawn are forbidden. In particular: nothing returns to `active`
except a genuine `succeeded` payment (same evidentiary bar as the checkout: fresh
retrieve, exact amount); `canceled` is terminal (a returning member is a NEW
subscription row, exactly as a payment retry is a new order number); and
`suspended` never moves backward into the retry states, because its retries are
spent.

### 3.5 The invariant: a retry never runs 3-D Secure interactively

A renewal retry is a Merchant Initiated Transaction. There is no shopper at a
screen, so there is nobody to answer a bank challenge. Therefore, stated as an
invariant the verifier can test: **no payment created by the billing or retry run
ever carries an interactive authentication request, and any such payment that
comes back `requires_customer_action` is immediately classified as failed with
reason authentication_required, never parked waiting for a shopper who does not
exist.**

What this means on our rail, concretely. Today's `create-payment` hardcodes
`authentication_type: "three_ds"` because provoking the challenge is the shop
demo's whole point. The renewal path must NOT reuse that body: an MIT is sent
without the interactive authentication request, leaning on the credential
established at the first CIT (Path A), where 3DS DID run, with a cardholder
present, once, at checkout. If the sandbox nevertheless demands interactive
authentication on an off-session charge, that is a mandate problem, not a retry
problem: the attempt fails, the classification is authentication_required, and the
subscription goes to card_update_required, whose exit is precisely a new
cardholder-present checkout where 3DS runs properly. Under Path B simulation the
invariant is trivially held and explicitly asserted in the run report anyway, so
the discipline survives the simulation era and is already tested when real
charging arrives.

### 3.6 Proving it on the demo

Because Braintree's sandbox keys declines to the dollar amount, each class is
provable on the real rail, with one honest wrinkle: our totals are server-priced
from a catalog whose prices step in fifty dollar units, and tax rides on top, so
arbitrary code amounts like 2001.00 are not reachable from the public cart.
Two workable levers, both test-mode only: bill against a member whose tax
destination answers zero (Illinois already does, observed in the live data), and
give the staff console a demonstration-only "exact amount" override so an operator
on a call can provoke exactly 2001.00, 2013.00, or 3000.00 and walk a viewer
through the resulting path. The override never exists on the public shop.

---

## 4. How a renewal order flows

### 4.1 Through the same bridge, changed nowhere

A successful renewal charge produces a `succeeded` row in `app.demo_orders`
carrying the member and the subscription's items, exactly the artifact the shop
produces today. From there the EXISTING bridge design (migration 019, policies P1
through P9) does everything: P1 admits only `succeeded`; P2 books it to the
member; P3 stamps the volume month; P5 keeps packs whole; P7 makes re-running the
bridge harmless; P9 keeps the activation fee non-commissionable (renewals carry no
activation fee anyway). The engine, per the bridge's own design idea, never learns
renewals exist: it sees ordinary completed orders. **The subscription engine
writes checkouts, the bridge translates, the commission engine computes. Three
boxes, one direction, no new coupling.**

One deliberate difference from the shop path: a renewal is created by the billing
run, not by a shopper, so its volume month is the PERIOD BEING BILLED, assigned by
the run, not derived from the row's creation timestamp. A retry that succeeds on
day 15 still belongs to the month it renews. This is policy P3's spirit applied
from the other end, and it needs stating because the shop path derives month from
`created_at` while the renewal path must not.

### 4.2 Late success and the month boundary

The cadence ends on day 26 and the commission run happens after month end, so in
the normal case every outcome is settled before the run. If a payment
nevertheless succeeds after suspension (a webhook straggler), P3 already refuses a
finalized month, and the rule here is the same one Howard set for the bridge:
nothing moves silently. The late money buys the NEXT month, the subscription
reactivates forward, and no back-billing into closed history ever occurs.

### 4.3 What a failed renewal does to qualification, worked example

Hand-computed, three members, one month. Rates: level 1 pays 10 percent of CV,
CV is 80 percent of SV, qualification gate is SV at or above 100.

Setup: Carol sponsors Beth, Beth sponsors Ann (and one other qualified frontline
leg, Dan, so Beth holds Builder, paid depth 2, when both legs are active). All
subscriptions are one Domain Agent, $100.00 and 100 PV monthly.

Month where everything renews: Ann SV 100, CV 80.00. Beth earns 10 percent of
80.00 from Ann at level 1, 8.00. Carol, if qualified and ranked for depth 2,
earns 5 percent of Ann's 80.00, 4.00, plus her level 1 on Beth.

Same month, but Ann's renewal declines with 2001 on day 1 and every retry through
day 22 fails; day 26 the subscription suspends:

1. **Ann**: SV 0, below the 100 gate, not qualified, earns nothing herself (she
   also loses nothing she would have earned from below if she has no downline).
2. **Beth**: loses the 8.00 line from Ann, and worse: Ann's leg is no longer an
   active leg. If Dan alone remains, Beth has one active leg, fails Builder's two
   active leg requirement, drops to Member, paid depth 1. Any level 2 lines Beth
   had been earning vanish with the depth.
3. **Carol**: loses her level 2 line on Ann's volume, and if her own rank rested
   on Beth's leg containing a Builder, that rank test now fails too.

One declined card, three statements changed, entirely through rules that already
exist: the engine recomputes ranks from scratch monthly, so the subscription
engine does not touch qualification at all. It merely decides which orders exist,
and the plan does the rest. If instead the payday retry on day 15 succeeds, Ann's
order books to the month per 4.1 and every figure above is identical to the
everything-renewed case: a recovered retry is invisible in the statement, which is
exactly right.

The examples' Bonus Protect (E9) exists precisely to prevent this cascade, which
is why it was popular and why regulators dislike it. We let the cascade happen,
because it is the honest arithmetic of the plan, and it makes a genuinely good
demonstration: the retry engine visibly protecting an upline's month by
recovering a downline's card is the best possible advertisement for
decline-aware retries.

---

## 5. Determinism and audit

**Renewal billing is a versioned batch, with the same discipline as a commission
run.** One row per attempt at a period: run identifier, period, engine version,
status running then final then superseded, started and finished stamps, and
totals. Attempts and outcomes hang off the run. Once final, immutable, enforced
the same way finalized commission rows already are. A rerun is a new run row;
nothing is edited in place. The billing run for a period is recomputable by the
verifier: given the subscriptions active in the period, the classification table,
and the outcome record (simulated script or processor summaries), an independent
recomputation must reproduce every retry date, every state transition, and every
resulting order to the cent. Section 3.3's arithmetic was designed backward from
that requirement.

**The scheduler question, named honestly: this project has NO scheduler of any
kind.** Nothing runs on a clock today. The abandonment sweep runs when other
functions happen to call it; rate ledger cleanup fires on a two percent random
chance inside requests. That was fine while every action had a human or a shopper
in front of it. Renewals on day 1 and retries on days 2, 4, 8, 15, 22 need a
clock. Three real options: `pg_cron` inside Supabase Postgres (supported on the
platform, keeps the clock next to the data, one migration to enable); an external
trigger (a scheduled job at the repository host calling an Edge Function with a
shared secret, which adds a second platform to trust); or hand-run from the staff
console (zero new machinery, but a demonstration that only bills when Howard
remembers is not a subscription engine). Recommended default: `pg_cron` ticks
which do nothing but open or advance a billing run, so the schedule is a
convenience and the run remains a first-class, hand-runnable, replayable object;
plus a simulated clock in Phase S1 that can play a whole month in seconds, which
the verifier and the demo both need regardless of the real scheduler chosen.

---

## 6. Phasing, each phase with the standard two-gate close

Both gates every time: the verifier recomputes independently (correctness gate)
and quality assurance walks the acceptance list end to end (QA gate). No phase
closes on the builder's word, which is the lesson this project has now paid for
twice.

**Phase S1: schema, state machine, simulated clock.** The subscription state
column and transitions, the classification table as data, the billing run tables,
the retry scheduler arithmetic, Path B outcome scripts, and the month-in-seconds
simulated clock. Deliverable: a full simulated month where seeded subscriptions
bill, decline per script, retry per class, recover or suspend, and flow through
the bridge into a commission run whose statements the verifier matches to the
cent, including the worked example in 4.3 reproduced exactly. Gate matter:
verifier recomputes the whole month; QA proves pause, cancel, code 2017, and the
never-interactive-3DS assertion on every simulated attempt.

**Phase S2: real charging on the sandbox.** First task is the Path A spike from
section 2 (CIT with setup flag, then off-session MIT), timeboxed; its result is
written up either way. If it passes: renewal charges become real sandbox MITs,
and the amount-triggered decline amounts prove one live path per class from
section 3.2's table. If it fails: the failure is documented with the exact API
answers, Path B remains the engine's outcome source, and the phase still closes
by proving the classification against amount-triggered declines fired through the
staff console's exact-amount override. Gate matter: verifier confirms no renewal
payment ever carried an interactive authentication request and every state
transition matches a fresh processor retrieve; QA runs the decline matrix on the
live rail.

**Phase S3: dunning and the member-facing surfaces.** Dunning notices rendered
in the member portal (this project sends no real email, so the notice IS the
portal surface, plus the staff console banner for the call scenario), the card
update flow (a new cardholder-present checkout that re-establishes the
credential and reactivates per the state machine), the subscription management
page (pause, resume, cancel, retry history with reasons in plain words), and the
billing run report for staff, which is E4 and E13 made real: preview before,
reasons after. Gate matter: verifier checks the state machine end to end against
the database triggers; QA plays a member through decline, notice, card update,
recovery, and sees their statement unharmed.

---

## 7. Open questions for Howard, each with a recommended default

| # | Question | Recommended default, so nothing blocks |
|---|---|---|
| Q1 | Billing day: first of month for all, or anniversary of signup? | **First of month.** The comp plan specification already says it, calendar month containment (Howard's 2026-08-15 ruling) already assumes it, and the whole retry cadence fits one month because of it. Anniversary billing would put retries astride the month boundary and reopen P3. |
| Q2 | The month a member first subscribes mid-month: charge at checkout and again on day 1, or does checkout cover the first period? | **Checkout covers the current calendar month as period one; first renewal on day 1 of the next month. No proration.** The examples have no proration and neither does our catalog; a part-month price would break PV equals dollars, the plan's one invariant. |
| Q3 | After dunning fails, suspend forever or auto-cancel? | **Suspend at day 26, auto-cancel after two consecutive unpaid months.** Suspension preserves an easy comeback; an unbounded suspended pool slowly turns the roster into fiction. |
| Q4 | Pause and skip: offer both? | **Pause only, one month at a time (matches E8's inactive status).** Skip is pause wearing a different label; two words for one behavior is how support tickets are born. A paused month simply bills nothing and the PV consequences of section 4.3 apply, stated on the page when the member pauses. |
| Q5 | Retry caps: adopt 3.3's counts (five soft, three ambiguous, one call-issuer, zero hard)? | **Yes.** Far under the network's 15 in 30 days ceiling, deterministic, and each number has a stated reason. Tightening later is safe; loosening later is a decision. |
| Q6 | Should a recovered decline appear anywhere member-facing? | **Yes, in their own billing history only ("payment retried and completed"), never in anyone else's view.** Honesty to the member, invisibility in the statement, which is what 4.3 shows the arithmetic already does. |
| Q7 | Build the Bonus Protect idea (E9), an insurance order when a member would miss qualification? | **No.** It is pay to play in insurance clothing and our own specification already flags the pattern. Keep the write-up in section 1 so the decision is on record with its reason. |
| Q8 | Scheduler: pg_cron, external trigger, or manual? | **pg_cron ticks that only advance a run, everything hand-runnable without it.** One new moving part, inside the platform we already trust, and the run object stays the source of truth. |
| Q9 | Card update entry point: portal only, or staff console too? | **Both.** The staff console mission is a member on the phone, and "your card declined, let me take a new one" is the single most common such call in subscription commerce. |

---

## What this brief deliberately did not do

No schema, no SQL, no code, per its charter: those belong to the specification
that follows Howard's rulings on section 7. The retry classification is written
to become a data table, not logic, so the specification can carry it forward
unchanged. And nothing here touches the six finalized months: the billing engine
creates future orders only, and every guard that already protects history keeps
protecting it.
