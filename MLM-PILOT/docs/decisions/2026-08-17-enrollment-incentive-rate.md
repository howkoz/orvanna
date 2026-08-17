# Decision: the enrollment incentive rate, and the launch guardrail

**Date:** 2026-08-17
**Decided by:** Howard, in four words: **"20 with the guardrail"**
**Status:** **SUPERSEDED THE SAME DAY. SHELVED, NOT BUILT, NOT PUBLISHED.**

> **SHELVED 2026-08-17, by Howard, hours after the ruling below.** His words: **"okay
> lets remove the instant incentive for now then"**.
>
> The ruling recorded here was real and is left standing as written, because a decision
> that was made and then shelved is still a decision, and the reasoning behind it is the
> part worth keeping. Nothing was published, nothing was built, and no engine or database
> change was ever made, so shelving required no unwinding.
>
> **If the question reopens, this ruling is the starting point, not a blank page.** The
> rate was 20 percent bound to an 8-percent-of-monthly-revenue guardrail, and the
> guardrail exists because the launch-month exposure cannot be pinned to a number from
> the available data. That reasoning does not expire.
>
> **Untouched by this:** Howard's separate 2026-08-15 approval of Instant Payout at 20
> percent, recorded in `DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`. Shelving a build is
> not revoking an approval.

Acronym key: Sales Volume (SV), Structured Query Language (SQL).

---

## What was decided

**The rate of record for the enrollment incentive is 20 percent of the qualifying
order price, and the 8-percent-of-monthly-revenue guardrail is a binding term of the
same package.** They are one term. The rate may never be quoted without the cap.

The 10 percent alternative was considered and rejected. It also fits and also covers
every enrollment, at half the cost, and it needs no guardrail. It was rejected because
Howard had already said he was willing to give up margin on the first sale, and this
is where that money buys the most recruiting.

---

## How the question arose

Howard asked for a tiered enrollment incentive so a prospect has a visible reason to
build a team, because the brochure's "recruiting pays nothing" sentence leaves them
with none. His ladder was 100 SV = 10.00, 200 = 22.50, 400 = 50.00, 800 = 120.00,
which he narrowed himself to 100 and 200 on the grounds that nobody keeps an 800
subscription going.

**The finding that reframed it: his ladder and the Instant Payout he approved on
2026-08-15 are the same mechanism, and the approved one pays the sponsor more at
every real order size.** 50.00 pays 10.00 against nothing, 100.00 pays 20.00 against
10.00, 150.00 pays 30.00 against 10.00, 200.00 pays 40.00 against 22.50, and 250.00
or above pays 50.00 against 22.50. So the work was a presentation change, publishing
the approved package as a tier table, and a rate decision. Not an engine build.

---

## Why the guardrail exists

**The safety case had never tested a launch.** February 2026 sits in the same database
and the costing excluded it. In February the capped first-order basis was **76.11
percent of revenue**, against 4.2456 percent across March to July.

That is not a hypothetical. Nobody has enrolled live yet, so the day enrollment opens,
February is the month Orvanna gets. The launch case is the one case that certainly
happens.

> **CORRECTION, same day, and it does not change the ruling.** This record first stated
> the February breach as a fact: 26.62 percent, missing the ceiling by 6.62 points. The
> compensation engineer then showed that figure applies **none of the package's own
> gates**, which is the same defect the verifier had charged the engineer with
> elsewhere. The honest picture is a bracket, not a point:
>
> | February 2026, combined plan cost | |
> |---|---|
> | Ungated | 26.5735 percent |
> | Plus the 30-day window | 12.6912 percent |
> | Plus the per-sponsor cap | 12.6817 percent |
> | Full package as written | 12.5381 percent |
>
> **Neither end is trustworthy.** The ungated figure ignores every gate the package
> actually has. The fully gated figure is artifact-driven, because in month one no
> sponsor has any purchase history, so the sponsor-purchase gate excludes almost
> everyone for a reason that will never recur. The true launch exposure lies between
> them and **the data cannot say where.**
>
> That uncertainty is precisely the argument for a guardrail rather than a number. A cap
> is safe across the whole bracket; a rate tuned to any single point in it is not. Both
> the verifier and the engineer agree on the guardrail, and Howard's ruling stands
> unchanged.

**The guardrail: monthly Instant Payout is capped at 8 percent of that month's
revenue, and the excess is DEFERRED rather than forfeited.** Nobody loses money they
earned. It binds on nothing in the five measured months, where the largest, July,
spends 1.05 percent. It holds a February-shaped month at **19.40 percent instead of
26.62**.

Without it, the maximum rate a launch-shaped month can carry is 11.30 percent.

---

## What rides with the ruling

| Item | Ruling |
|---|---|
| Recovery window | **Four complete months from the qualifying order date**, not three, and not from the enrollment month. Three months catches 46.88 percent of eventual cancellers; month four is the largest single bucket; six catches 95.83 percent |
| Recovery trigger | Refund, chargeback, **or subscription cancellation**. Full, not prorated |
| Tier table | Honest only under seven named conditions, reproduced verbatim as normative text. As first drafted it re-created in the field exactly the cliff belief a flat rate was chosen to eliminate |
| Brochure rule line | Corrected: the qualifying basis is the new member's **own purchase**, excluding retail-customer volume. The two readings differ for 49 of 269 enrollments |
| Both limits on the page | The three-per-sponsor cap and the recovery clause must appear beside the numbers |
| Term 9 | Kept, but recorded as a **loosening rather than a clarification**: 43 more events and 1,050.00 more over five months than the prior-month reading |

---

## The evidence behind it

The costing was produced by the compensation engineer and then independently
recomputed by the verifier, which wrote its own SQL from the written terms rather than
checking the engineer's. **47 of 47 claims reproduced exactly**, and the verifier found
no arithmetic error. Both HIGH findings above came from questions the costing had not
asked, not from figures it got wrong.

Two corrections to the coordinator's own analysis are recorded here so they are not
repeated: a count of 457 was order LINES rather than people (284 enrollments on the
identical 33,050.00 of SV), and the claim that nobody enrolls at 200 or above was
false, since 54 of 284, 19.01 percent, do. Zero order ROWS reach 200, which is why the
query said otherwise and why the question was wrong rather than the query.

**Still unreproducible and blocking any quotation of document 10:** its headline of 234
qualifying events does not reproduce from its own section 9.1 terms under **seven**
readings, giving 274, 269, 233 and 226 among others. Its term 8 needs rewriting before
either document is quoted, and that document records an approval Howard already gave.

---

## Related

- Terms: `MLM-PILOT\docs\ENROLLMENT-INCENTIVE-TERMS-2026-08-17.md`
- Verdict: `MLM-PILOT\docs\verification\ENROLLMENT-INCENTIVE-VERDICT-2026-08-17.md`
- The incumbent it amends: `DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`
- The August approval it builds on: Howard, 2026-08-15, "20 on instant payout and it
  does not roll up to the upline"
