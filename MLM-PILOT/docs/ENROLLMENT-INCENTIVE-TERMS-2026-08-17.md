# Enrollment Incentive: costed terms for Howard to choose between

> ## SHELVED 2026-08-17 BY HOWARD. NOT PUBLISHED, NOT BUILT.
>
> His instruction, the same day the terms were completed: **"okay lets remove the
> instant incentive for now then"**. Nothing from this document reached the public
> compensation page, the standalone brief, the database, or the engine. There is
> nothing to unwind.
>
> **This document is preserved intact, not withdrawn.** Every figure in it was
> independently recomputed by the verifier, 47 of 47 claims reproducing exactly, so it
> remains the best costing of this mechanism that exists. If the question reopens, start
> here rather than from scratch.
>
> **What stays true regardless.** The compensation page and the brief already describe
> Instant Payout as approved but not built, paying nothing today, at zero dollars. Those
> statements were accurate before this decision and remain accurate after it, which is
> why shelving cost nothing. Had the mechanism been published as live, this instruction
> would have required a public correction instead.
>
> **The separate August approval is untouched by this.** Howard approved Instant Payout
> at 20 percent on 2026-08-15, recorded in `DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`.
> Shelving the build is not the same as revoking that approval, and nobody should read it
> as such without asking him.
>
> **Two things here are worth acting on even with the mechanism shelved**, because both
> concern documents that are quoted today:
> 1. Document 10's headline of 234 qualifying events **does not reproduce from its own
>    terms** under seven readings. Its term 8 is ambiguous and should be rewritten before
>    that document is quoted to anyone.
> 2. The launch-month exposure finding stands on its own: first orders were 76.11 percent
>    of revenue in February 2026 against 4.2456 percent across March to July. Any future
>    first-order mechanism has to be tested against a launch month, not a mature one.

**Owner of this document:** the compensation engineer on the Orvanna build team.
**Version 2, written 2026-08-17.** Version 1 was written the same day and failed the
publication gate. See the correction note below.

**Status: THE RATE IS RULED BY HOWARD, 2026-08-17. THE PACKAGE IS NOT BUILT.** Every query
behind every number was read-only against the live Supabase project. No migration was
applied, no engine function was changed, and no code of any kind was written for this
mechanism.

> ## RULING, 2026-08-17. Howard's words: **"20 with the guardrail"**.
>
> **The rate of record is 20 percent of the qualifying order price, and the 8-percent-of-
> monthly-revenue guardrail is a binding term of the same package.** They were ruled together
> in one sentence and they are one term. Term 6 and term 7 in section 9.1.
>
> **The 10 percent alternative is REJECTED.** It is recorded in section 9.6.3 with its cost,
> as a road not taken, and it is no longer live anywhere in this document.
>
> **The package is unsafe without the guardrail, and this is not a stylistic point.** At 20
> percent alone, a launch-shaped month breaches the plan's 20 percent ceiling by **6.57
> points**. The guardrail is what holds it at 19.3988 percent. **Anywhere the rate is quoted,
> the cap must be quoted beside it.** A reader who can lift "20 percent" out of this document
> without also lifting "capped at 8 percent of monthly revenue" has been handed a rate that
> breaks the plan. Section 9.5.
>
> **Still open, and the ruling did not close them:** the recovery path that gates the whole
> mechanism and does not exist in any form (term 15), and the four remaining decisions in
> section 12.

---

> ## CORRECTION NOTE, version 1 to version 2, 2026-08-17
>
> Version 1 was independently graded by mlm-verifier, which wrote its own Structured Query
> Language (SQL) from my written terms rather than checking mine, ran twenty two read-only
> queries, and reproduced **47 of 47 claims exactly**. It found no arithmetic error anywhere.
> It then **failed the document on publication safety**, with two HIGH and two MEDIUM
> findings. Its verdict is at
> `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\ENROLLMENT-INCENTIVE-VERDICT-2026-08-17.md`.
>
> **No cost figure from version 1 changed.** Every number I published survived recomputation.
> What changed is what the document tests, what it recommends, and what it proposes to print.
>
> | # | What version 1 got wrong | What version 2 does | New section |
> |---|---|---|---|
> | **HIGH-1** | The safety case was measured only in steady state. Version 1 said "Orvanna is not that company today" about a launch-shaped organisation while also stating that nobody has ever enrolled live. Those two sentences contradict each other, and the launch case is the one case that certainly happens. | Adds a launch stress test, adopts a **monthly guardrail as term 7**, and restates the rate ruling as **20 percent only with the guardrail written in, otherwise 10 percent**. | 9.6, term 7, 9.5 |
> | **HIGH-2** | The brochure table stated a basis that contradicted my own term 4, put the rule under the table instead of above it, and published the payout with neither the per-sponsor cap nor the recovery clause on the page. | Rebuilt against seven normative conditions, reproduced as binding text. | 10.1, 10.2 |
> | **MEDIUM-3** | The recovery window was argued from all 1,830 subscriptions rather than from the 269 enrollments the rule actually governs. My stated reason, that the cohort was too small, was wrong. | Re-argued on the cohort. Window moves from **three months to four complete months, run from the qualifying order date**. | 7.2 |
> | **MEDIUM-4** | Section 9.2 was headed "the cost of exactly those terms" and priced a different basis than term 4 recommends. | Section retitled, and the tightened cost of **5,160.00** is published beside the 5,940.00. | 9.2 |
> | LOW-5 | "An order carries exactly one product line" is false as a statement about the database. | Corrected and scoped to the measured window. | 3 |
> | LOW-6 | "No first order exists on live traffic" had gone stale. | Restated with the member and date. | 11 |
> | LOW-7 | Term 4 gated the payout on one table and the recovery term triggered on another, and they disagreed for four members. | Resolved, and the resolution turned out to be free. | 8.5 |
>
> **Two places where I did not simply adopt the verifier's finding, both recorded in full
> rather than quietly resolved.** Its HIGH-1 February figure of 26.62 percent prices the
> mechanism with **none of its own gates applied**, which is the same defect it correctly
> charged me with in MEDIUM-4; section 9.5 publishes the full bracket instead. And its
> MEDIUM-3 four-month recommendation had no dollar figure attached, so I computed one:
> **1,550.00**. Section 9.6 and section 7.2 show my work. **Its directional judgement was
> right in both cases and I have adopted both recommendations.**

**Acronym key, used throughout.** Sales Volume (SV). Commissionable Volume (CV). Team
Volume (TV). Personal Volume (PV). Structured Query Language (SQL). Software as a Service
(SaaS). Each is spelled out again the first time it appears in the body text.

**Sources. Every figure below came from one of these, and nothing else.**

- Read-only SQL against the live Supabase project `oiyibdczkokegaxkwulv`, run 2026-08-17:
  `app.orders`, `app.order_lines`, `app.products`, `app.members`, `app.subscriptions`,
  `app.commission_runs`, `app.commission_lines`, `app.run_member_results`
- `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`
- `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\03-COMPENSATION-PLAN.md`

**The rule I held to.** No number in this document is estimated, scaled, or inferred. Where
the data cannot support a figure, the document says so plainly instead of producing one.
Section 3 exists entirely because a number I was handed did not survive being recomputed.

**I do not verify my own arithmetic.** That is the standing rule for this role. As of version
2 that verification has happened: mlm-verifier recomputed every figure in version 1 from its
own SQL and reproduced 47 of 47 exactly. **Figures new in version 2, meaning the launch
bracket in section 9.5, the four-month recovery amount of 1,550.00, and the LOW-7 resolution
in section 8.5, are my queries and my calculations and have NOT yet been independently
recomputed.** They should be, before anything quoting them is published.

---

## 1. The headline, before any detail

Howard asked for a tiered enrollment incentive so that the compensation brochure stops
saying recruiting pays nothing. He proposed paying a sponsor 10.00 when a new member
enrolls at 100 Sales Volume and 22.50 at 200 Sales Volume, and he dropped his own original
400 and 800 rungs because, in his words, nobody keeps a subscription that size going.

**Orvanna already approved a mechanism that does this, two days ago, and it pays the
sponsor more at every single order size Howard named.**

That mechanism is Instant Payout, approved by Howard on 2026-08-15 at 20 percent of the
order price, capped at a 250.00 basis. Set the two side by side at the sizes real people
actually buy:

| The new member's first order | Howard's proposed ladder pays the sponsor | The already-approved Instant Payout pays the sponsor |
|---|---|---|
| 50.00 | **0.00** | **10.00** |
| 100.00 | 10.00 | **20.00** |
| 150.00 | 10.00 | **30.00** |
| 200.00 | 22.50 | **40.00** |
| 250.00 or more | 22.50 | **50.00** |

The approved package wins in every row. It is not close, and there is no order size anywhere
in the catalog where the ladder is the better deal for a recruiter.

**So the outcome is not a new mechanism. It is a presentation change plus one ruling that
Howard has now made.** Publish the already-approved Instant Payout as a table of worked
examples, because that is what Howard actually wants the brochure to show, and a flat
percentage of price with a capped basis renders as one without any of the problems a step
ladder carries.

**The ruling, 2026-08-17, in Howard's words: "20 with the guardrail".**

> **20 percent of the qualifying order price, capped so that total Instant Payout in any
> calendar month never exceeds 8 percent of that month's revenue, with the excess deferred
> rather than forfeited.**
>
> **The two halves are one term.** 20 percent alone breaches the plan's 20 percent ceiling by
> 6.57 points in a launch-shaped month. The guardrail holds it at 19.3988 percent and binds on
> no month this project has ever measured. Never quote the rate without the cap.

**The measured price of the ruled package is 5,160.00 over five months**, which is 0.7376
percent of revenue and takes the whole plan to 12.6018 percent against a ceiling of 20
percent.

Full reasoning in section 8, the numbered terms in section 9, and the side by side against
the incumbent in section 10.

---

## 2. Diagrams this document needs

I have not drawn these. They should be drawn before this goes to anyone other than Howard,
and they should be light-export style, meaning a white background, pale hardcoded fills and
dark hardcoded text, so they copy cleanly into Snagit.

| # | Diagram | What it must show | Why it is the one that lands |
|---|---|---|---|
| D1 | **The payout curve, four packages on one chart** | Horizontal axis: first order size from 0 to 400 in 50.00 steps. Vertical axis: dollars to the sponsor. Four lines: the approved 20 percent capped package, the recommended 10 percent capped package, Howard's two-rung ladder, and the three-rung ladder. | This single picture is the whole argument. Howard's ladder sits on the floor at 50.00, jumps, sits flat, jumps, sits flat. The two capped-percentage lines rise smoothly and then flatten at the cap. One look and the staircase problem is obvious without a word of text. |
| D2 | **The coverage bar** | 269 blocks, coloured by whether each real enrollment pays the sponsor something. One bar per package. | Makes 41.64 percent of enrollments paying zero a visible block of colour rather than a percentage nobody feels. |
| D3 | **The funnel** | 288 first orders, narrowing to 284 after the 30-day window, to 276 after the sponsor-has-purchased gate, to 269 after the three-per-sponsor cap. | Shows that the gates are cheap. They remove 19 events out of 288, not half the population. |
| D4 | **The cliff, in dollars** | Two adjacent bars at 150.00 and 200.00 for the step ladder, annotated "one more 50.00 agent, 12.50 more to the sponsor, a 25 percent marginal rate". Beside it, the same two bars for the flat percentage, annotated "10 percent either way". | This is the regulatory point and the gaming point at once, and it is invisible in a table. |
| D5 | **The ceiling stack** | A stacked bar to 20 percent of revenue: 11.86 points already paid by the plan, the incentive on top, and the remaining headroom. One stack per package. | Howard's constraint was "do not break the bank". This shows the bank. |
| D6 | **The recovery timeline** | Enrollment, first order, instant payment to sponsor, then a cancellation or refund inside the four-month window measured from the ORDER DATE, then the negative balance settling in the next monthly commission run. | Recovery is the gate on the whole mechanism and it is a sequence, which is the one thing a table cannot show. |
| **D7** | **NEW. The guardrail and the deferral queue** | Two stacked bars per month across a hypothetical launch: revenue, and 8 percent of it as an allowance line. Instant Payout fills the allowance; the overflow is drawn as a block that slides into the next month's bar and is paid there ahead of new ones. Annotate one enrollment that cancels while still queued, showing it lapse in place with no money moving in either direction. | **This is now the most important diagram in the document**, because term 7 is the load-bearing half of Howard's ruling and a deferral queue is pure sequence. It is also the only way to show that nothing is forfeited, which is the property that makes the guardrail acceptable to a field. |
| **D8** | **NEW. The two halves that cannot be separated** | One bar chart, a launch-shaped month, three bars: plan alone at 11.40 percent, plus 20 percent unguarded at 26.57 percent crossing a red ceiling line at 20, and plus 20 percent guarded at 19.40 percent sitting just under it. | Anyone who sees this once will never quote the rate without the cap, which is the single failure mode this document is most exposed to. |

---

## 3. The number I was handed, and why I did not use it

I was asked to verify rather than trust a prior measurement, so this section records what
happened when I did. It matters, because the recommendation I was asked to test was built
on top of the figure that turned out to be wrong.

**What I was told.** 457 first orders in March through July 2026. 253 of them below 100
Sales Volume, 204 in the 100 to 199 band, and **zero at 200 or above**. From that: 55
percent of enrollments would pay the sponsor nothing under Howard's ladder, and the 200 rung
would never fire at all.

**What I found.** I reproduced 457 exactly, and then found what it counts.

```
457 = every completed ORDER ROW placed in a member's first month,
      not every member who enrolled.
```

**In the March to July window, every order carries exactly one product line**, which I
verified directly: zero orders in that window have more than one line. A new member who
subscribes to one 100.00 domain agent and one 50.00 support agent in the same month
therefore produces **two order rows**. Counting rows instead of people does two things at
once, and both push the answer in the same wrong direction: it inflates the denominator, and
it shatters each enrollment into fragments of 50.00 and 100.00, so no fragment can ever
reach 200.

**Corrected in version 2:** version 1 stated one line per order as a property of the
database, and that is false. `app.orders` holds 10,351 rows against 10,353 in
`app.order_lines`, so two orders do carry more than one line, and 415 lines carry a quantity
above one, up to 3. **Both multi-line orders are in August 2026 and neither is in any
measured window, so no figure anywhere in this document is affected**, because every amount
was computed by summing line values rather than by assuming one line per order. The
explanation above is now scoped to the window it describes.

That is why the prior measurement found zero enrollments at 200 or above. It is not that
nobody enrolls at that size. It is that a 200.00 enrollment was being counted as two
separate 100.00 events.

**The measured proof, side by side, same window, same filters, same money:**

| Counting unit | Events, March to July 2026 | Their Sales Volume | Events at 200 or above |
|---|---|---|---|
| Order rows | 457 | 33,050.00 | **0** |
| **Enrollments, meaning members** | **284** | **33,050.00** | **54** |

The Sales Volume column is identical, 33,050.00 both ways, which is the check that proves
these are two views of the same money and not two different populations. The enrollment
count of 284 also independently reproduces the figure in document 10, which reached it by a
different route.

**What this changes.** Everything downstream of it.

- The 200 rung is not dead. It fires on **54 of 284 enrollments before gates, 19.01
  percent**, which is roughly one enrollment in five.
- The share paying nothing under Howard's ladder is **not 55 percent**. Measured on
  enrollments after all gates it is **41.64 percent**, in section 6.
- The recommendation I was asked to test, adding a 50 Sales Volume rung at 5.00, was
  reasoned from the claim that the top rung never fires. That premise is false, so the
  recommendation has to be re-argued from the real distribution rather than adopted. I do
  re-argue it, in section 8.4, and I do not adopt it.

**One thing in the prior measurement that survived and is worth keeping.** The observation
that an incentive which does not fire on the most common enrollment is not an incentive to
recruit is correct, and it is the single most useful sentence I was given. The most common
enrollment really is the smallest one. Howard's ladder really does pay zero on it. The
finding was right; only its size was wrong.

---

## 4. The measured baseline

### 4.1 The plan as it stands, before anything is added

Six finalized commission runs exist, February through July 2026, on the seeded 1,000-member
organisation. I read them directly from `app.commission_runs` rather than from any document.

| Period | Revenue, which equals Sales Volume | Commissionable Volume | Payout | Payout as a share of revenue | Members paid |
|---|---|---|---|---|---|
| 2026-02 | 104,450.00 | 83,560.00 | 11,906.00 | 11.40% | 179 |
| 2026-03 | 114,950.00 | 91,960.00 | 13,434.00 | 11.69% | 206 |
| 2026-04 | 124,600.00 | 99,680.00 | 14,636.00 | 11.75% | 227 |
| 2026-05 | 138,950.00 | 111,160.00 | 16,507.20 | 11.88% | 248 |
| 2026-06 | 148,500.00 | 118,800.00 | 17,749.20 | 11.95% | 261 |
| 2026-07 | 172,550.00 | 138,040.00 | 20,669.20 | 11.98% | 284 |

**Sales Volume equals revenue, with no conversion step anywhere.** I verified this rather
than assuming it: in `app.products` every one of the sixteen rows has `volume_points`
exactly equal to `price`. Note that this is sixteen products, not the twelve that document
10 checked. Four more rows now exist, the Manager Agent bundle and the Ignition, Momentum
and Constellation packs. The equality still holds on all sixteen.

**February is excluded from every model below.** 596 of the 1,000 members have their
first-ever order in February 2026, because that is the month the seeded history begins. That
is a property of the seed script, not of member behaviour. Every model runs on **March
through July 2026, five months.**

**The five-month frame, which every figure in this document is judged against:**

| Figure | Value | How it was derived |
|---|---|---|
| Revenue, March to July | **699,550.00** | 114,950 + 124,600 + 138,950 + 148,500 + 172,550 |
| Payout already made | **82,995.60** | 13,434 + 14,636 + 16,507.20 + 17,749.20 + 20,669.20 |
| Payout as a share of revenue | **11.8641%** | 82,995.60 / 699,550.00 |
| The plan's stated ceiling | **20% of revenue** | 25 percent of Commissionable Volume, and Commissionable Volume is 80 percent of revenue, so 0.25 x 0.80 = 0.20 |
| The ceiling in dollars | **139,910.00** | 0.20 x 699,550.00 |
| **Headroom available to spend** | **56,914.40, which is 8.1359 points of revenue** | 139,910.00 minus 82,995.60 |

### 4.2 What is in the database now that was not there on 2026-08-15

Three things changed between document 10 and today, and all three are worth stating because
a reader comparing the two documents will otherwise think one of us made an error.

1. **August 2026 orders now exist.** 19 orders, 3,750.00 of revenue, all carrying a
   `demo_order_id`, meaning they arrived through the shop-to-compensation bridge. Two are
   Constellation Packs at 800.00 and one is a Manager Agent at 200.00. **No commission run
   exists for August**, so these are excluded from every cost model here. They are the first
   evidence in the whole project that a pack is a thing a real person buys.
2. **`app.subscriptions` is populated.** 1,830 rows across 960 members, states `active` and
   `cancelled`. This did not exist when document 10 was written and it is what makes section
   7 of this document possible.
3. **Bundles and packs are now real product rows.** Sixteen products instead of twelve.

---

## 5. The population this would pay on, measured

### 5.1 The gates, stated so an implementer cannot misread them

I applied the three gates document 10 approved. Because the exact SQL behind document 10 is
not recorded, I state my reading of each one precisely and measure against my own reading.

| Gate | My exact reading |
|---|---|
| **The event** | A member's first order ever, defined as the earliest `volume_month` in which they have any order with `status = 'completed'`. The event's size is the total of every completed order in that month, which is that member's Sales Volume for the month. |
| **The 30-day window** | The earliest `ordered_at` date in that month is on or before `enrolled_on + 30 days`. |
| **Sponsored, non-house** | `sponsor_id is not null` and `is_house_account = false`. |
| **Sponsor has purchased** | At the moment of the recruit's first order, the sponsor has at least one completed order of their own, meaning `buyer_role = 'member'`, dated on or before that same date. Same-day counts. This is the only reading that is knowable at the instant the payment succeeds, which is the property document 10 required of this gate. |
| **Three per sponsor per month** | Within one sponsor and one calendar month, keep the first three by order date, tie-broken by member id. First come, first paid. |

**One ambiguity I am flagging rather than hiding.** The three-per-sponsor cap needs a rule
for *which* three are kept, and no document states one. I chose earliest first, because it is
deterministic and because any rule that keeps the largest three would pay a sponsor to delay
small enrollments to the following month. Whoever builds this must write the tie-break into
the specification, not leave it to the query.

### 5.2 The funnel, measured

| Stage | Enrollments remaining | Their Sales Volume | Removed at this stage |
|---|---|---|---|
| First orders, March to July 2026 | 288 | 33,350.00 | |
| After the 30-day window | 284 | 33,050.00 | 4 |
| After the sponsor-has-purchased gate | 276 | 32,300.00 | 8 |
| **After the three-per-sponsor-per-month cap** | **269** | **31,400.00** | **7** |

**The gates are cheap.** They remove 19 enrollments out of 288, which is 6.60 percent of the
population, while closing the shell-account route and bounding worst-month exposure. The
observed maximum was one sponsor with 6 first orders in a single month, and only 4
sponsor-months out of 227 exceeded three at all.

### 5.3 Document 10's figure of 234 does not reproduce, and I am saying so

Document 10 section 9.2 reports **234 qualifying events** under the same three gates, with a
capped basis of 25,250.00 and a cost of 5,050.00. I get **269 events**, a capped basis of
29,700.00, and 5,940.00.

I tried four readings of the sponsor-has-purchased gate to find the one that reproduces 234,
and none does exactly:

| Reading of "sponsor must already have a completed purchase of their own" | Events after the three-per-sponsor cap | Capped basis | Cost at 20 percent |
|---|---|---|---|
| Any completed order of the sponsor's, on or before the date | 274 | not computed | not computed |
| **Own purchase, `buyer_role = 'member'`, on or before the date (my reading)** | **269** | **29,700.00** | **5,940.00** |
| Own purchase in a **strictly earlier month** than the recruit's first month | 226 | 24,450.00 | 4,890.00 |
| Own purchase in a strictly earlier month, before the three-per-sponsor cap | 233 | 25,350.00 | 5,070.00 |

The closest candidate is the last row, 233 events at 5,070.00, against document 10's 234 at
5,050.00. It is close enough to suggest document 10 used a prior-month reading of the gate,
and far enough to prove it is not identical.

**What this means, stated plainly.** I am not claiming document 10 is wrong. I am claiming
its section 9.2 figure cannot be reproduced from the terms written in its section 9.1, which
is a defect in the specification rather than necessarily in the number. **Term 8 must be
rewritten to say which reading it means before anybody builds it.** A prior-month reading and
an on-or-before-the-date reading differ by 43 events and 1,050.00 over five months, and only
one of them is knowable at the instant the payment succeeds, which is the property document
10 says it chose the gate for.

Every figure in the rest of this document uses my stated reading and the 269-event cohort.
Where I compare against the incumbent, I recompute the incumbent on the same 269 rather than
quoting document 10's 5,050.00, so the comparison is like for like.

### 5.4 The size of a real enrollment

This is the table the whole design rests on. 269 gated enrollments, March through July 2026.

| First order size | Enrollments | Share | Running share |
|---|---|---|---|
| 50.00 | 112 | 41.64% | 41.64% |
| 100.00 | 67 | 24.91% | 66.54% |
| 150.00 | 39 | 14.50% | 81.04% |
| 200.00 | 24 | 8.92% | 89.96% |
| 250.00 | 9 | 3.35% | 93.31% |
| 300.00 | 7 | 2.60% | 95.91% |
| 350.00 | 6 | 2.23% | 98.14% |
| 400.00 | 5 | 1.86% | 100.00% |
| **Total** | **269** | **100%** | |

Check: (112 x 50) + (67 x 100) + (39 x 150) + (24 x 200) + (9 x 250) + (7 x 300) +
(6 x 350) + (5 x 400) = 5,600 + 6,700 + 5,850 + 4,800 + 2,250 + 2,100 + 2,100 + 2,000 =
**31,400.00**. It agrees with the funnel table.

**Three facts to carry into every decision below.**

- **The most common enrollment is the smallest one the catalog allows.** 41.64 percent of
  real enrollments are exactly 50.00. Any package with a floor at 100 pays nothing to four
  sponsors in ten.
- **Two thirds of enrollments are at or below 100.00.** 66.54 percent.
- **The 200 rung is real but thin.** 51 enrollments, 18.96 percent, are at 200.00 or above.

---

## 6. What Howard's ladder actually does, measured

Howard's ladder as he narrowed it: 100 Sales Volume pays 10.00, 200 Sales Volume pays 22.50,
tiers are steps, and anything below 100 pays nothing.

### 6.1 Coverage, which is the point of the whole exercise

| Measure | Value |
|---|---|
| Gated enrollments | **269** |
| Enrollments that pay the sponsor something | **157**, which is **58.36%** |
| **Enrollments that pay the sponsor nothing** | **112**, which is **41.64%** |
| Average payment across all 269 enrollments | **8.21** |
| Average payment when it does fire | **14.06** |
| Cost over five months | **2,207.50** |

**Four sponsors in every ten get nothing.** Howard's whole reason for wanting this was that
the brochure sentence "recruiting pays nothing" leaves a prospect with no visible reason to
build a team. A ladder with a floor at 100 replaces that sentence with a worse one: recruiting
pays nothing **most of the time**, and specifically it pays nothing on the enrollment a new
recruiter is most likely to actually make. The first person a brand-new member signs up is
overwhelmingly likely to buy the smallest thing on the menu. Under this ladder, that sponsor's
first taste of the business is a zero.

### 6.2 The shape problem, which is separate from the coverage problem

Effective rate by order size, measured:

| Order size | Payment | Effective rate |
|---|---|---|
| 50.00 | 0.00 | 0.00% |
| 100.00 | 10.00 | 10.00% |
| 150.00 | 10.00 | 6.67% |
| 200.00 | 22.50 | **11.25%** |
| 250.00 | 22.50 | 9.00% |
| 300.00 | 22.50 | 7.50% |
| 400.00 | 22.50 | 5.63% |

This is a sawtooth. The rate climbs to 10 percent, falls to 6.67, jumps to 11.25, then decays.
There is no sentence that describes it, which is a real problem for a brochure whose job is
to be understood.

**Where this shape sits with a regulator, stated plainly, because I was asked to.** Howard's
original four-rung proposal climbed from 10 percent at 100 Sales Volume to 15 percent at 800,
and that climb is the shape examiners look at hardest, because a rate that rises with order
size rewards loading a large first purchase onto somebody who just joined and does not yet
know what they need. **Howard's own narrowing removed almost all of that risk himself, and he
deserves the credit for it.** Dropping the 400 and 800 rungs cut the climb from 10-to-15
percent across an eight-fold size range down to 10-to-11.25 percent across a two-fold range.

What remains is small but it is not nothing, and it is worth being precise about what
actually carries the risk. It is not the 1.25 points of rate. **It is the cliff**, which is
section 6.3.

### 6.3 The cliff, in dollars

Tiers are steps, not interpolated, so I have to say what a 150.00 order pays. **It pays
10.00, the same as a 100.00 order.** The recruit spends 50 percent more and the sponsor earns
exactly the same. Then one more 50.00 agent changes everything:

| The recruit's first order | Sponsor earns | What the last 50.00 of product added |
|---|---|---|
| 150.00 | 10.00 | |
| **200.00** | **22.50** | **12.50, a 25 percent marginal rate on that 50.00 step** |

**The marginal rate at the 200 boundary is 25 percent, which is two and a half times the
headline rate of 10 percent, and it is higher than any rate anywhere else in the entire
compensation plan.** Level one pays 10 percent of Commissionable Volume, which is 8 percent
of price. This one 50.00 step pays 25 percent.

That is a direct, quantified, in-dollars incentive for a sponsor to talk a hesitant newcomer
into one more agent they did not ask for, at the exact moment that newcomer trusts the sponsor
most and knows the product least. It is the single most criticised behaviour in this industry
and the ladder builds a 12.50 bounty on it.

Interpolating instead of stepping would remove the cliff, but interpolation between 100 and
200 is just a straight line, and a straight line through those two points is a percentage.
**Which is the answer: the fix for the cliff is to stop using rungs and use a rate.**

### 6.4 The retention reason Howard dropped the top rungs, tested against the data

Howard's reason for dropping 400 and 800 was: "no one is going to keep a 400 and 800
subscription going". This is a genuine insight and it deserved a real test, so I ran one.

**The data cannot confirm it, and I will not pretend otherwise.** `app.subscriptions` holds
1,830 rows and **every one of them is at a 50.00 or 100.00 price point**. There is not one
subscription at 200, 400 or 800 anywhere in the database. Howard's claim is about a size of
subscription that has never existed here, so it can be neither confirmed nor refuted.

What the data can say is what happens at the only two sizes that do exist, and it runs the
other way:

| Subscription price | Subscriptions | Cancelled | Cancellation rate |
|---|---|---|---|
| 50.00 | 907 | 239 | **26.35%** |
| 100.00 | 923 | 162 | **17.55%** |

**The smaller subscription is the one that gets cancelled more, by nearly nine percentage
points.** That is the opposite direction from the intuition, at the only two points we can
observe. It is two data points across a two-fold range and it is being asked to speak about a
sixteen-fold range, so it is weak evidence. But it is the only evidence there is, and it does
not support the premise.

**This matters for the recommendation.** If bigger subscriptions do not in fact churn worse,
then the reason to drop the top rungs was never retention. There is still a perfectly good
reason to drop them, and it is the one in section 6.2: a rate that climbs with order size is
the shape that gets a plan examined. Howard reached the right decision. The stated reason is
untested and the unstated reason is sound.

---

## 7. Retention protection: when the money has to come back

### 7.1 Why this is one build and not two

Document 10 term 12 already makes recovery the gate on the entire Instant Payout mechanism,
and section 7.6 of that document lists the four pieces that have to be built: a reversed
state on the payment record, a member balance that may go negative, settlement inside the
monthly commission run, and an exposure cap while a balance is negative.

**None of those four pieces cares which payout formula produced the amount.** A negative
balance line carrying an amount and an order reference settles identically whether the amount
came from 20 percent of price or from a rung on a ladder. So whatever Howard chooses here,
**it is the same single build**, and it is already specified. Nothing in this document adds a
second recovery mechanism, and nothing in this document can be switched on before that one is
built.

### 7.2 The window, measured on the population the rule actually governs

**Version 1 got this wrong and the correction changes the recommendation.** Version 1
recommended three months and argued it from the general cancellation curve across all 1,830
subscriptions in the database. It stated that it had not restricted the measurement to the
269 enrollments the rule governs, and gave the reason that the cohort would be too small to
say anything with. **That reason does not hold. 269 enrollments contain 96 eventual
cancellers, which is plenty, and I have now measured them.**

**The cohort curve, measured. 269 enrollments, 96 of whom eventually cancel.**

| Months from the first order month | First cancelling | Cumulative | Share of the 96 who ever cancel | Payout recovered, at 20 percent |
|---|---|---|---|---|
| 1 | 13 | 13 | 13.54% | |
| 2 | 19 | 32 | 33.33% | 820.00 |
| 3 | 13 | 45 | 46.88% | **1,040.00** |
| **4** | **20** | **65** | **67.71%** | **1,550.00** |
| 5 | 14 | 79 | 82.29% | 1,870.00 |
| 6 | 13 | 92 | 95.83% | **2,150.00** |
| 7 to 8 | 4 | 96 | 100.00% | 2,230.00 |

**Of the 5,940.00 paid across the five months, 2,230.00 attaches to an enrollment whose
subscription eventually cancels.** That is 37.54 percent of every dollar paid, and it is the
money at risk.

**The general curve was misleading in three ways at once**, which is why version 1 reached
the wrong window:

1. It made the three-versus-six gap look like 37.91 against 64.84 percent. On the population
   the rule governs it is **46.88 against 95.83 percent**.
2. **Month four is the single largest cancellation bucket in the cohort, 20 members**, and
   the general curve does not show that at all: it shows month four as smaller than months
   one, two and three.
3. A three-month window therefore stops one month short of the biggest block of risk.

> **RECOMMENDED WINDOW, amended in version 2: FOUR complete calendar months, run from the
> QUALIFYING ORDER DATE, not from the enrollment month.** If the new member's subscription
> cancels, or the qualifying order is refunded or charged back, inside that window, the
> incentive is recovered in full and settled against the sponsor's next monthly commission
> run.

**Why four and not three.** Four clears the month-four spike. It captures **67.71 percent of
cohort cancellers against 46.88 percent at three**, and in money it recovers **1,550.00
against 1,040.00**, which is **510.00 more over five measured months**. That is the price of
the extra month, and it is worth paying.

**Why four and not six.** Six recovers 2,150.00, another 600.00 on top of four. It also
leaves a sponsor's earnings reversible for half a year, which is a real thing for a person's
household budget and a real reason for a field to distrust a plan. Four is still a sentence a
sponsor can be told and believe. **Howard should make this trade knowing its size: choosing
four over six leaves 600.00 unrecovered across five months, which is 0.09 points of revenue.**

**Why from the order date and not the enrollment month.** Under an enrollment-month window a
member who enrolls on the 1st and one who enrolls on the 30th get materially different
protection for the same money. The order date is the date the money left, and it is
unambiguous.

**One measurement caveat on my own figure, stated because it cuts against my recommendation.**
`app.subscriptions.cancel_month` is a month-grain column, so the table above is measured at
month grain while the term is written at date grain. The two cannot differ by more than one
month for any single member. Separately, **the cohort tail is right-censored**: a member whose
first order was in July 2026 has had only one month in which to cancel, so the later buckets
are understated and the true four-month capture is **lower** than 67.71 percent, not higher.
That makes the case for four rather than three stronger, not weaker.

**Recovery is full, not prorated.** A prorated recovery needs a second formula, a second set
of rounding decisions and a second thing to explain, to reclaim a fraction of an amount that
averages 22.08 under the recommended package. It is not worth it. Inside the window the whole
amount comes back; outside it, none of it does.

---

## 8. What "enrolled in SaaS" must mean, and the recommendation

### 8.1 The question Howard has not ruled on

Howard said: "the user has to be enrolled in saas to get these instant incetives". That reads
two ways and both are defensible:

- **Reading A: the new member's first order must contain a subscription line.**
- **Reading B: the sponsor must hold an active subscription of their own.**

### 8.2 What the data says about each

**Reading A is currently unmeasurable, and that is the most important thing to know about
it.** Every one of the 10,353 rows in `app.order_lines` has `billing_mode = 'sub'`. In the
269-enrollment cohort, all 434 first-month order lines are subscription lines. **A gate that
requires a subscription line would exclude exactly zero enrollments today**, not because it
is a good gate but because a non-subscription line has never existed in this database. Its
cost is 0.00 and that figure means nothing. A prior statement that every enrollment in the
100 tier carried a subscription line is true and also vacuous: so did every enrollment in
every other tier.

There is a related question underneath it that **is** measurable, and it is the one that
actually bites. Sales Volume includes purchases made by a member's retail customers and
booked to their account. In the cohort:

| Measure | Value |
|---|---|
| Enrollments with some retail customer volume in their first month | 49 of 269 |
| **Enrollments where the new member bought nothing at all themselves** | **4 of 269** |
| The cohort's own purchases | 26,450.00 |
| The cohort's retail customer volume | 4,950.00 |
| Enrollments whose **own** purchases reach 100.00 or more | **133** |
| Enrollments whose **total Sales Volume** reaches 100.00 or more | **157** |

**That last pair is a 24-enrollment swing** on nothing but the choice of basis. Four people
would be paid an enrollment incentive for a purchase they did not make.

**Reading B is buildable but is the wrong gate.** `app.subscriptions` now carries a state per
subscription, so a sponsor's active subscription is knowable at the instant. But the plan
already has a gate on the sponsor, term 8, the sponsor-has-purchased rule, and it does the
same job. Adding a second sponsor-side gate would mean an active seller who paused their own
subscription for one month loses the reward for work they actually did, which is the same
objection document 10 used to reject the previous-month qualification gate.

### 8.3 Recommendation on the definition

> **RECOMMENDED: Reading A, tightened to the new member's own purchase.**
>
> **The qualifying order must be the new member's own purchase, `buyer_role = 'member'`, and
> must contain at least one subscription line. Volume booked to the new member from their own
> retail customers does not count toward the incentive basis.**
>
> **The sponsor side keeps exactly one gate, the existing sponsor-has-purchased rule. No
> active-subscription test is added to the sponsor.**

Three reasons. **It pays for the thing Howard named.** He said enrolled in SaaS, and a
subscription line in the new member's own order is that, precisely. **It closes the
four-person hole** where somebody is paid an enrollment reward for a customer sale that
happened to land on a new account. **It keeps one gate per side**, one on the buyer and one
on the sponsor, which is a plan a person can hold in their head.

**The cost of this tightening is not modelled and I am not going to guess it.** Restricting
the basis to `buyer_role = 'member'` volume would reduce the cohort's basis from 31,400.00 to
26,450.00 before caps, but the enrollment counts, the per-sponsor cap and the tier boundaries
all shift together under that restriction and I did not run the combined query. **Every cost
figure in section 9 and section 10 is computed on total first-month Sales Volume, which is
document 10's basis, so the two documents stay comparable.** If Howard adopts the tightened
definition, the costs must be re-measured before they are published, and they will be lower,
not higher.

### 8.4 Why I do not adopt the three-rung ladder I was asked to test

I was asked to test, not adopt, a proposal to add a 50 Sales Volume rung at 5.00, keeping
100 at 10.00 and 200 at 22.50. I modelled it, and I am not recommending it.

**What it gets right.** It fixes the coverage failure completely. Every one of the 269
enrollments pays the sponsor something. That was the correct diagnosis and it is the reason
the two-rung ladder cannot ship.

**Why it is still the wrong answer.** It fixes the floor and leaves both structural problems
standing. The rate still rises, 10 percent at 100 and 11.25 percent at 200. The cliff at 200
is untouched: still 12.50 for one more 50.00 agent, still a 25 percent marginal rate, still
the highest rate anywhere in the plan. And it adds a second cliff at 100, worth 5.00.

And it buys nothing for the trouble. Measured over the same five months on the same 269
enrollments:

| Package | Cost | Coverage | Rising rate? | Cliffs? |
|---|---|---|---|---|
| Three-rung ladder, 5.00 / 10.00 / 22.50 | **2,767.50** | 100% | yes, 10% to 11.25% | two, worth 5.00 and 12.50 |
| **Flat 10 percent of price, basis capped at 250.00** | **2,970.00** | 100% | **no, flat then declining** | **none** |

**The difference is 202.50 over five months, which is 0.03 points of revenue.** For that,
the ladder keeps a rising rate, two cliffs and a shape nobody can state in a sentence. The
flat rate pays 10.00 at 100 exactly as Howard specified, pays 20.00 at 200 instead of 22.50,
pays every sponsor something, cannot be gamed by adding one item, and is describable in six
words: ten percent of their first order.

**Paying 202.50 to keep a cliff is a bad trade, so I decline it.**

### 8.5 One source of truth for "is subscribed", and why the fix is free

**The defect, found by the verifier.** Term 4 gates the payout on
`app.order_lines.billing_mode`, and term 15 triggers the clawback on a subscription
cancellation, which lives in `app.subscriptions`. Those are two different tables and they
disagree. **Four of the 269 cohort members have first-month order lines marked as
subscription lines and no row at all in `app.subscriptions`.** Under version 1's terms those
four would qualify for the payout and could never trigger the cancellation clawback: 40.00 of
structurally unrecoverable money.

**The resolution, and it costs nothing.** I checked which four members those are, and they
are **exactly the same four members that term 4's own-purchase requirement already
excludes**: GW-000651, GW-000657, GW-000696 and GW-000701, all March 2026, all 50.00 of
retail customer volume, all with zero purchases of their own.

| Cohort filter | Members |
|---|---|
| All gated enrollments | 269 |
| With a row in `app.subscriptions` | **265** |
| With a purchase of their own, meaning term 4 as amended | **265** |
| **Members in one set but not the other** | **0** |

**So adopting term 4 closes the clawback hole automatically.** Once the qualifying order must
be the new member's own purchase, every member who can be paid is a member whose
cancellation can be detected. The two sets are identical at 265, which is also the enrollment
count behind the tightened cost of 5,160.00 in section 9.2. That is not a coincidence: a
member who never bought anything never started a subscription.

> **RULE, so an implementer cannot reintroduce the gap: `app.subscriptions` is the single
> source of truth for whether a member is subscribed.** Term 4 tests it and term 15 triggers
> on it. `order_lines.billing_mode` is not consulted by either, because it is a description of
> a line rather than a record of a standing agreement, and today it carries one distinct value
> across all 10,353 rows.

The alignment above is measured on today's data and is not guaranteed by any constraint. A
foreign key or a check that ties a subscription line to a subscription row would make it
structural. That is a build note, not a term.

---

## 9. THE RULED PACKAGE, on one page

**THE RATE AND THE GUARDRAIL ARE RULED, 2026-08-17. THE PACKAGE IS NOT BUILT.** Terms 6 and 7
are Howard's decision and are policy. Terms 4, 10 and 15 carry amendments he has not yet
ruled on, listed in section 12.

**The one-sentence version.** Do not build a second mechanism: take the Instant Payout Howard
approved on 2026-08-15, pay **20 percent of the new member's own first purchase, capped so no
month's total exceeds 8 percent of that month's revenue**, and publish it in the brochure as a
table of worked examples, because that is the visible recruiting reward he is asking for.

### 9.1 The terms

Terms marked NEW or AMENDED are changes from the approved Instant Payout package. Anything
not marked is already Howard's own approved policy and is repeated here only so this package
can be built from one page. **Term numbers changed between version 1 and version 2** because
the guardrail was inserted as term 7; anything citing a term number from version 1 must be
re-checked against this table.

| # | Term | The rule |
|---|---|---|
| 1 | **Name** | **Instant Payout**, the existing approved name. The same word in the brochure, the table, the column and the function. There is no second mechanism and no second name. |
| 2 | **Who is paid** | The **sponsor**, meaning the member who personally enrolled the buyer. |
| 3 | **What triggers it** | A **product purchase**, never the signup. Specifically the **first order ever** placed by that sponsored member, placed **within 30 days of that member's enrollment date**. One Instant Payout per member, ever. Enrolling costs nothing and pays nothing; the money exists only because a product was sold. |
| 4 | **AMENDED. What the qualifying order must contain** | The order must be the new member's **own purchase**, `buyer_role = 'member'`, and must establish **at least one subscription**, tested against `app.subscriptions`, which is the single source of truth for whether a member is subscribed. Volume booked to the new member from their own retail customers is excluded from the basis. This is Howard's "enrolled in SaaS" rule, made precise. It also closes the clawback hole in section 8.5 at no cost. See sections 8.3 and 8.5. |
| 5 | **Basis** | The **order price**, exclusive of tax and of any activation fee. Not Commissionable Volume, and not a flat amount. |
| 6 | **RULED by Howard, 2026-08-17. Rate** | **20 percent of the qualifying order price. A flat percentage, with no rungs.** Howard's words: "20 with the guardrail". **This term may not be quoted, implemented or published without term 7.** The two were ruled in one sentence and the rate breaches the plan's ceiling without the cap. The 10 percent alternative is rejected and recorded in section 9.6.3. |
| **7** | **RULED by Howard, 2026-08-17. MONTHLY GUARDRAIL. Binding, not optional.** | **Total Instant Payout in any calendar month may not exceed 8 percent of that month's revenue. The excess is DEFERRED, never forfeited.** Full mechanics in section 9.1.1, which is written to be built from. **On all five measured months this binds on nothing**, the largest being July 2026 at 1.0548 percent of revenue against an 8 percent allowance. Its whole purpose is the launch case in section 9.5. |
| 8 | **Cap per event** | The basis is capped at **250.00**. At 20 percent no single payout exceeds **50.00**; at 10 percent, **25.00**. |
| 9 | **Cap per sponsor** | At most **3** Instant Payouts to one sponsor in one calendar month, **kept in order of earliest order date**, tie-broken by member id. The tie-break is new and must be written into the specification, not left to the query. |
| 10 | **AMENDED, and it is a LOOSENING with a price. Eligibility of the payee** | The sponsor must already have at least one completed purchase of their own, `buyer_role = 'member'`, **dated on or before the recruit's first order date**. Same day counts. No monthly qualification gate applies, because qualification cannot be known at the instant. **Howard must approve this as a policy change, not as a wording fix.** Against the stricter prior-month reading that document 10 most likely used, it admits **43 more enrollments and 1,050.00 more cost over five months, which is 21.5 percent more**. It is still the right rule, because it is the only reading knowable at the instant a payment succeeds, which is what an instant payout requires. But same-day counting does mean a sponsor with no history can buy one 50.00 agent that morning and qualify immediately. That is not a profitable route on their own money, since every fake enrollment loses them 40.00, but it is a route. See section 5.3. |
| 11 | **No rungs, no cliffs, no interpolation question** | The payment is a continuous percentage of price up to the cap. There are no tiers, so there is no step to cross and no interpolation rule to write. A 150.00 order pays exactly half again what a 100.00 order pays. **Adding one 50.00 agent to a first order always changes the payout by the same flat percentage of that 50.00, at every size, up to the cap.** |
| 12 | **When it is paid** | At the moment the payment reaches `succeeded`, which is the only status backed by a fresh retrieve from the processor and an exact amount match, subject to term 7. |
| 13 | **Against the rest of the plan** | **In addition** to level one pay. No commission line is suppressed. Nothing in `app.fn_run_commission` changes. |
| 14 | **Against volume** | It consumes **no volume**. Sales Volume, Commissionable Volume, Team Volume, ranks and the ten-month spreading rule are all completely untouched. |
| 15 | **AMENDED in version 2. Recovery, and it gates everything** | If the qualifying order is refunded or charged back, **or if the new member's subscription cancels, within FOUR complete calendar months of the QUALIFYING ORDER DATE**, the full amount is recovered from the sponsor's balance and settled against their next monthly commission run. Recovery is full, never prorated. **This must be built before the first Instant Payout is paid.** Version 1 said three months from the enrollment month; section 7.2 shows why both halves of that were wrong. The four pieces to build are unchanged from document 10 section 7.6. |
| 16 | **Ledger** | Written to `app.commission_lines` with `payout_type = 'instant_payout'`, a recovery as `payout_type = 'instant_payout_clawback'`, and a term 7 deferral as `payout_type = 'instant_payout_deferred'`, so none of the three ever merges silently with level pay in any existing report. |
| 17 | **No roll-up** | **Terminal at the sponsor.** It pays the sponsor and nobody above them. No level pay, no depth pay, no volume of any kind that could reach anyone further up the tree. One event produces exactly one commission line to exactly one earner. Howard's rule, 2026-08-15, unchanged. |

### 9.1.1 Term 7 in full, written to be built from

Term 7 is now load-bearing rather than advisory, so it is specified here to the level an
implementer can work from without inventing anything. Seven rules.

**Rule 1. The allowance is tested against revenue TO DATE, not against the finished month.**
An Instant Payout pays at the instant a payment succeeds, and a month's total revenue is not
known until the month ends, so a cap expressed against the finished month is not computable
when it is needed. **The test is therefore: at the instant of payout, the sum of all Instant
Payout released so far in this calendar month must not exceed 8 percent of all revenue booked
so far in this calendar month.** This is knowable at the instant, which is the same property
document 10 required when it rejected the monthly-qualification gate. Because revenue to date
only ever grows, the allowance only ever grows, so **nothing already released can become
retroactively over-cap**, and at month end the running test converges exactly on 8 percent of
the month's revenue.

**Rule 2. The excess is deferred, never forfeited.** A forfeit means a sponsor who genuinely
sold is never paid, which damages trust more than a plan that never promised the money. A
deferral bounds the company's cash exposure while every sponsor is eventually paid in full.

**Rule 3. Deferred amounts are paid oldest first, ahead of new ones.** The queue is ordered by
qualifying order date, tie-broken by member id, the same ordering term 9 uses. **Before any
new Instant Payout is released in a month, the queue is drained as far as that month's running
allowance permits.** Without this rule a long queue could starve the earliest sponsor
indefinitely while later ones are paid.

**Rule 4. Deferral cascades, and that is intended.** If the following month also binds, the
remainder carries again, and again, without limit. There is no expiry on a deferred amount and
no month in which it is written off. **A cascade is the correct behaviour and not a failure
state**: it is the mechanism absorbing a sustained launch surge over time rather than either
breaching the ceiling or refusing to pay.

**Rule 5. Deferral does NOT extend the recovery window, and this is the rule most likely to be
got wrong.** Term 15's four months run from the **qualifying order date**, never from the
payment date. A payout deferred by three months therefore carries only one month of remaining
recovery exposure when it is finally released. **If the window were run from the payment date,
deferral would silently lengthen the company's exposure every time the guardrail bound**,
which is the opposite of what a guardrail is for.

**Rule 6. A recovery trigger that fires while an amount is still queued cancels it in place.**
If the qualifying order is refunded or charged back, or the subscription cancels, inside the
term 15 window while the amount is still deferred, **the queued amount lapses: it is never
paid and nothing is clawed back, because no money ever moved.** It is recorded as
`payout_type = 'instant_payout_lapsed'` so it never merges with either a payment or a
clawback. A queued amount must never be released and then immediately reclaimed.

**Rule 7. A capped month must be visible on the statement.** In any month where the guardrail
binds, every affected sponsor's statement shows three separate figures: **the amount earned,
the amount paid, and the amount deferred, with the deferred amount carrying the qualifying
order it belongs to.** A deferred payout that a member cannot see and reconcile is exactly the
defect the compensation plan already names for a silently suppressed line, and it is the
fastest way to make a working mechanism feel like a broken one.

**What cannot be tested here, stated plainly.** Rule 1 is a running intra-month test, and
**the seeded data cannot exercise it**: every order in each of the six seeded months carries
the same `ordered_at` date, the first of the month, so each month collapses to a single
instant. Only August 2026, the 19 bridged live orders, has genuine dates across four days.
**The month-level finding that the guardrail binds on nothing in the measured window is
sound. The intra-month behaviour of rules 1 and 3 is unmeasured and unmeasurable in this
database, and must be proven by a test the implementer writes rather than by anything in this
document.**

### 9.2 The measured cost, on two bases, because the package and its headline price must match

**Version 1 headed this section "the measured cost of exactly those terms" and it was not
that.** It priced total first-month Sales Volume while term 4 recommends the new member's own
purchase. Those are two different policies and the heading claimed the opposite of what the
section did. Both are now published, and **the tightened basis is the price of the
recommended package.**

**Basis A, total first-month Sales Volume.** This is document 10's basis, kept so the two
documents stay comparable. Computed by read-only SQL applying terms 3, 8, 9 and 10
simultaneously to the real first-order events of March through July 2026. Not scaled from any
other figure.

**269 qualifying enrollments. Capped basis 29,700.00.**

| Month | Qualifying enrollments | Capped basis | **At 20 percent** | At 10 percent | Existing plan payout | Revenue |
|---|---|---|---|---|---|---|
| 2026-03 | 51 | 5,350.00 | **1,070.00** | 535.00 | 13,434.00 | 114,950.00 |
| 2026-04 | 46 | 4,200.00 | **840.00** | 420.00 | 14,636.00 | 124,600.00 |
| 2026-05 | 71 | 7,450.00 | **1,490.00** | 745.00 | 16,507.20 | 138,950.00 |
| 2026-06 | 38 | 3,600.00 | **720.00** | 360.00 | 17,749.20 | 148,500.00 |
| 2026-07 | 63 | 9,100.00 | **1,820.00** | 910.00 | 20,669.20 | 172,550.00 |
| **Total** | **269** | **29,700.00** | **5,940.00** | **2,970.00** | **82,995.60** | **699,550.00** |

Check: 1,070 + 840 + 1,490 + 720 + 1,820 = 5,940.00, which is 0.20 x 29,700.00. It agrees.

**Basis B, the new member's own purchase only. THIS IS THE PRICE OF THE PACKAGE IN SECTION
9.1**, because it is the basis term 4 recommends. Version 1 declined to compute this and said
only that it would be lower. It is now computed.

| | Basis A, total first-month Sales Volume | **Basis B, own purchases only, the recommended package** |
|---|---|---|
| Qualifying enrollments | 269 | **265** |
| Basis before the cap | 31,400.00 | **26,450.00** |
| Capped basis | 29,700.00 | **25,800.00** |
| **Cost at 20 percent** | 5,940.00 | **5,160.00** |
| **Cost at 10 percent** | 2,970.00 | **2,580.00** |
| Instant Payout as a share of revenue at 20 percent | 0.8491% | **0.7376%** |
| **Combined with the existing plan at 20 percent** | 12.7133% | **12.6018%** |

**The tightening costs 780.00 less over five months, which is 13.13 percent of the cost.** I
computed it two independent ways, once holding the event definition fixed and restricting
only the basis, and once redefining the event to require a purchase of the member's own.
**Both give the identical 265 enrollments and 5,160.00**, which is a useful sign that the
tightening is unambiguous rather than a definitional choice in disguise.

**Which figure to quote.** Quote **5,160.00** as the cost of the recommended package. Quote
5,940.00 only when comparing against document 10 or against the ladders in section 10, which
are all priced on basis A. **Every figure elsewhere in this document uses basis A unless it
says otherwise**, because that is the basis on which the four packages were compared, and
re-pricing all four on basis B would change none of the conclusions while making the
comparison with document 10 impossible.

### 9.3 Coverage: what share of real enrollments pay the sponsor something

| Package | Enrollments paying the sponsor something | Coverage | Enrollments paying zero |
|---|---|---|---|
| **Recommended, flat percentage of price** | **269 of 269** | **100.00%** | **0** |
| Three-rung ladder, 5.00 / 10.00 / 22.50 | 269 of 269 | 100.00% | 0 |
| Howard's two-rung ladder, 10.00 / 22.50 | 157 of 269 | 58.36% | **112** |

**This is the single figure that decides the shape.** A percentage of price cannot pay zero
on a completed order, because a percentage of a positive number is positive. Coverage is 100
percent by construction, not by tuning, and it stays 100 percent if the catalog ever adds a
25.00 product, which no ladder can promise.

### 9.4 Does it fit the ceiling

| Test | At 20 percent | At 10 percent |
|---|---|---|
| Instant Payout cost, five months | **5,940.00** | **2,970.00** |
| Average per qualifying enrollment | **22.08** | **11.04** |
| Instant Payout as a share of revenue | **0.8491%** | **0.4246%** |
| Existing plan as a share of revenue | 11.8641% | 11.8641% |
| **Combined** | **12.7133%** | **12.2887%** |
| **The ceiling** | **20.00%** | **20.00%** |
| **Verdict** | **IT FITS. 7.29 points of revenue remain unspent.** | **IT FITS. 7.71 points remain unspent.** |
| Worst single month | 2026-07 at **13.0334%**, 6.97 points below the ceiling | 2026-07 at **12.5061%**, 7.49 points below |
| Best single month | 2026-04 at **12.4205%** | 2026-04 at **12.0835%** |

**Every month of both candidates, measured:**

| Month | Existing plan alone | Combined at 20 percent | Combined at 10 percent |
|---|---|---|---|
| 2026-03 | 11.69% | 12.6177% | 12.1522% |
| 2026-04 | 11.75% | 12.4205% | 12.0835% |
| 2026-05 | 11.88% | 12.9523% | 12.4161% |
| 2026-06 | 11.95% | 12.4372% | 12.1947% |
| 2026-07 | 11.98% | **13.0334%** | 12.5061% |

**How far behaviour would have to shift before it stops fitting.** The headroom is 56,914.40,
which is 8.1359 points of revenue. The capped basis is today 29,700.00, which is **4.2456
percent of revenue**. For the incentive to exhaust the headroom on its own:

| Rate | Capped first-order basis would have to reach this share of revenue | Multiple of today's 4.2456 percent |
|---|---|---|
| **20 percent** | **40.6793%** | **9.58 times** |
| **10 percent** | **81.3586%** | **19.16 times** |

**This is the real safety argument and it is worth understanding rather than trusting.** The
incentive costs `rate x capped-first-order-share-of-revenue`. First orders are a small slice
of a mature organisation's money, so even a large rate on that slice is a small number
overall. **The danger is not a mature organisation, it is a young one.** In a company where
almost every order is somebody's first, that share approaches 100 percent, and a 20 percent
rate would break the ceiling on its own.

**Version 1 then said "Orvanna is not that company today", and that sentence was wrong in a
way that mattered.** It is true of the seeded thousand-member organisation every figure above
is measured on, and false of Orvanna, which has never enrolled a single member through the
live site. **Orvanna becomes that company on the day enrollment opens.** The 9.58 times runway
above is a steady-state runway and it does not describe launch. Section 9.6 is the test that
version 1 should have run and did not.

**The ceiling test that document 10 warns about, and that this package also does not fix.**
A single first order can pay the instant amount **plus** up to 20 percent through the five
levels of the ordinary plan. Measured at each order size, against that order's own price:

| First order size | At 20 percent: instant + up to 20 percent of levels | At 10 percent | Howard's ladder |
|---|---|---|---|
| 50.00 | **40.00%** | 30.00% | 20.00% |
| 100.00 | **40.00%** | 30.00% | 30.00% |
| 150.00 | **40.00%** | 30.00% | 26.67% |
| 200.00 | **40.00%** | 30.00% | **31.25%** |
| 250.00 | **40.00%** | 30.00% | 29.00% |
| 300.00 | 36.67% | 28.33% | 27.50% |
| 400.00 | 32.50% | 26.25% | 25.63% |

**The worst single first order pays 40.00 percent of its own price at the 20 percent rate,
and 30.00 percent at the 10 percent rate.** Both are double the plan's 20 percent headline.
The cap makes the figure fall away above 250.00 rather than rise, which is the right
direction, but it does not get below 20 percent at any size.

Measured rather than theoretical, across the actual 269 enrollments: the ordinary plan
actually paid **3,560.40** across all five levels on those members in their first month,
and **1,824.00** of that was level one. So the real all-in cost of a first enrollment is:

| Package | Instant + actual level pay on the cohort | As a share of the cohort's 31,400.00 of Sales Volume |
|---|---|---|
| **20 percent** | 5,940.00 + 3,560.40 = **9,500.40** | **30.26%** |
| **10 percent** | 2,970.00 + 3,560.40 = **6,530.40** | **20.80%** |
| Three-rung ladder | 2,767.50 + 3,560.40 = 6,327.90 | 20.15% |
| Howard's two-rung ladder | 2,207.50 + 3,560.40 = 5,767.90 | 18.37% |

**Howard said he was willing to give up margin on the first sale, and this table is the size
of that giving-up.** At 20 percent, roughly 30 cents of every dollar of a first order goes
back out in compensation, against 11.86 cents on an ordinary dollar. That is a deliberate
loss on the first sale, exactly as he framed it, and it is bounded to 4.24 percent of revenue
because that is all first orders are.

### 9.5 NEW in version 2. The launch stress test, and why the guardrail exists

Every figure before this point is measured in **steady state**, on a seeded organisation
where first orders are 4.25 percent of revenue. **Orvanna has never enrolled anybody through
the live site.** On the day enrollment opens, close to every order will be somebody's first
order, and that is the one shape the plan has never been tested against. This section tests
it.

#### 9.5.1 February 2026, the only launch-shaped month in the database

February 2026 is when the seeded history begins: 596 of 1,000 members place their first-ever
order, and **their Sales Volume is 104,450.00, which is 100.0000 percent of that month's
revenue.** Every dollar was somebody's first dollar. That is structurally the launch shape,
which is why it is worth running even though it is a seed artifact.

**It matters enormously how the package's own gates are applied, and I am publishing the full
bracket rather than a single number.**

| February 2026, gates applied | Enrollments | Capped basis | Basis as a share of revenue | Cost at 20 percent | **Combined at 20 percent** | Combined at 10 percent |
|---|---|---|---|---|---|---|
| **A. No gates at all** | 595 | 79,250.00 | **75.87%** | 15,850.00 | **26.5735%, BREAKS BY 6.57** | 18.9861%, fits |
| B. Plus the 30-day window | 68 | 6,750.00 | 6.46% | 1,350.00 | 12.6912%, fits | 12.0450%, fits |
| C. Plus the three-per-sponsor cap | 67 | 6,700.00 | 6.41% | 1,340.00 | 12.6817%, fits | 12.0402%, fits |
| **D. The full package as written in 9.1** | **59** | **5,950.00** | **5.70%** | **1,190.00** | **12.5381%, fits** | 11.9684%, fits |

Plan payout alone in February was 11,906.00, which is 11.3988 percent of revenue.

**Reading A is the verifier's finding and it is the alarm that had to be raised.** Reading D
is what the recommended package would actually have paid. **Neither one is a trustworthy
launch model, and the honest answer is that February cannot serve as one in either
direction.**

- **Reading A overstates it**, because it applies the rate with none of the package's own
  gates. That is the same defect the verifier correctly charged me with in MEDIUM-4, and I
  will not repeat it in the opposite direction to make a safety case look stronger.
- **Reading D understates it**, and the reason is specific to month one. The
  sponsor-has-purchased gate is nearly total in the first month of any history, because
  almost no sponsor has bought anything yet. The 30-day window also collapses February,
  because the seed backdated enrollment dates to 2024 while starting orders in 2026. Both
  gates are doing artifact work, not policy work. **In a real launch, sponsors accumulate
  purchase history within weeks and both gates stop binding, while the first-order share of
  revenue stays near 100 percent for months.**

**So the true launch exposure sits between reading D and reading A, and the database cannot
say where.** That is the honest finding, and it is why the answer is not a number but a
guardrail.

#### 9.5.2 The parametric test, which does not depend on February at all

The one thing that can be stated without any artifact is the break-even, because it is
arithmetic on the ceiling rather than a measurement of a month:

| Rate | Capped first-order share of revenue at which the ceiling breaks | Today's share, five months | February's ungated share |
|---|---|---|---|
| 20 percent | **40.68%** | 4.25% | 75.87% |
| 10 percent | **81.36%** | 4.25% | 75.87% |

**At 20 percent, any month in which capped first-order basis exceeds roughly 41 percent of
revenue breaks the plan's ceiling. A launch month is far above that. At 10 percent the
threshold is 81 percent, which even a pure launch month does not reach.** That is the whole
finding, and it holds regardless of what one believes about February.

#### 9.5.3 The guardrail, and why 8 percent is the right number

> **TERM 7: total Instant Payout in any calendar month may not exceed 8 percent of that
> month's revenue. The excess is DEFERRED to the following month, never forfeited.**

**Why deferral rather than a hard cap.** A forfeit means a sponsor who sold is not paid, which
is the one thing that destroys trust in a compensation plan faster than paying nothing at all.
A deferral means the company's monthly cash exposure is bounded while every sponsor is
eventually paid in full. Deferred amounts queue by qualifying order date and are paid ahead of
new ones.

**Why 8 and not another number. Three independent tests all land on it.**

| Test | Result |
|---|---|
| **Does it ever bind on real measured data?** | **No.** The largest of the five months is July 2026 at **1.0548 percent** of revenue; the smallest, June, is 0.4848 percent. Fully gated February is 1.1393 percent. **The guardrail has zero effect on every month this project has ever measured.** |
| **Does plan plus guardrail stay under the ceiling by construction?** | **Yes, and this is why 8 is the number.** The existing plan costs 11.8641 percent of revenue. 11.8641 + 8 = **19.8641 percent, which is under 20**. Even if the guardrail were fully spent every single month, the combined cost cannot reach the ceiling. |
| **Does it bind before the ceiling would break?** | **Yes, at both candidate rates.** An 8 percent monthly cap is reached when first-order capped basis hits **40 percent** of revenue at the 20 percent rate, and **80 percent** at the 10 percent rate. Compare those with the ceiling break-evens of 40.68 and 81.36 percent. **The guardrail binds just before the ceiling breaks, at either rate, without being tuned to do so.** |

**What it does to a launch-shaped month.** On the ungated February reading, the worst case in
the bracket, the guardrail holds the combined cost at **19.3988 percent instead of 26.5735
percent**. It converts a 6.57 point ceiling breach into a 0.60 point margin.

**What it costs today: nothing.** It binds on no month in the five-month window, on no month
of the six finalized runs, and on no reading of February except the ungated one. **It is the
cheapest insurance in this document, and it is the only thing standing between the approved
20 percent rate and the one shape in this database that breaks the plan.**

---

### 9.6 THE RATE, RULED. 20 percent, with the guardrail, as one term

> **RULED BY HOWARD, 2026-08-17: "20 with the guardrail".**
>
> **The rate of record is 20 percent of the qualifying order price. The 8-percent-of-monthly-
> revenue guardrail, term 7, is part of the same ruling and is not severable from it.**
>
> **The measured price of the ruled package is 5,160.00 over five months on the recommended
> basis, which is 0.7376 percent of revenue and takes the whole plan to 12.6018 percent
> against a ceiling of 20 percent.**

#### 9.6.1 Why the two halves cannot be separated

This is the single most important sentence in the document for anyone who reads no further.

| The package | Steady state, five measured months | A launch-shaped month |
|---|---|---|
| 20 percent **with** term 7 | 12.6018%, fits | **19.3988%, fits** |
| 20 percent **without** term 7 | 12.6018%, fits | **26.5735%, BREACHES BY 6.57 POINTS** |

**A reader who lifts "20 percent" out of this document without also lifting "capped at 8
percent of monthly revenue" has been handed a rate that breaks the plan the first month
enrollment opens.** That is why term 6 carries an instruction not to be quoted alone, why the
brochure text in section 10.2 does not state a bare rate, and why this table exists.

#### 9.6.2 The four reasons 20 percent is the right rate, given that the launch case is handled

**Version 1 recommended 20 percent unconditionally, and that was the defect.** The four
reasons below all survive checking and none of them was ever about the ceiling, which is why
they could all be right and the recommendation still be unsafe. They are the reasons to
prefer 20 percent **given** that the launch case is handled. Term 7 is what handles it.

**It was already approved, so the ruling costs nothing to decide.** Howard ruled this rate on
2026-08-15 and confirmed it on 2026-08-17. Nothing measured since has weakened it: the cohort
grew from document 10's 234 events to 269 under a clearer gate, the cost rose from 5,050.00 to
5,940.00 on the comparable basis, and the combined share moved from 12.59 percent to 12.71
percent against a 20 percent ceiling. It still fits with 7.29 points spare.

**It is the only candidate that clears Howard's actual complaint.** The brochure problem is
that recruiting has nothing visible in it. At 20 percent the most common enrollment, a 50.00
first order, pays the sponsor **10.00**. At 10 percent it pays **5.00**. Document 10 already
argued that a payment too small to feel like an event is not an incentive, and 5.00 on the
enrollment that 41.64 percent of sponsors will actually make is at the edge of that.

**Howard's own numbers are closer to 20 percent than they look.** He proposed 22.50 at 200
Sales Volume. The approved package pays **40.00** at 200. He proposed 10.00 at 100; it pays
**20.00**. His stated constraint was not to break the bank, and the measured answer is that
the bank is not close to broken: the worst month lands at 13.03 percent against a ceiling of
20 percent.

**Anything below 100 percent is self-limiting against a farmer.** At 20 percent a person
faking an enrollment with their own money spends 50.00 to collect 10.00 and loses 40.00 on
every attempt. That property comes from the rate being a percentage of price and holds at any
rate below 100 percent.

#### 9.6.3 REJECTED: 10 percent, recorded as a road not taken

Version 2 offered 10 percent as the alternative to be adopted if the guardrail were refused.
**Howard took the guardrail, so 10 percent is rejected.** It is recorded here with its
measured cost so a future reader can see it was priced rather than ignored, and it is live
nowhere else in this document.

| The rejected option | Measured value |
|---|---|
| Rate | 10 percent of the qualifying order price |
| Cost, five months, recommended basis | **2,580.00** |
| Cost, five months, comparable basis | 2,970.00 |
| As a share of revenue | 0.4246% |
| Combined with the existing plan | 12.2887% |
| Coverage of real enrollments | 100%, identical to 20 percent |
| A launch-shaped month, ungated reading | 18.9861%, fits unaided |
| Pays on the most common enrollment, a 50.00 first order | **5.00**, against 10.00 at the ruled rate |

**Why it was a serious candidate.** It was the only rate that clears a launch-shaped month
**without** any guardrail, and it pays 10.00 at 100 Sales Volume, which is exactly the number
Howard proposed himself this week.

**Why it was rejected, and the reason is Howard's own.** Taking 10 percent buys launch safety
by halving the payment on the 41.64 percent of enrollments that are the smallest order the
catalog allows, from 10.00 to 5.00. Document 10 already argued that a payment too small to
feel like an event is not an incentive, and the entire purpose of this mechanism is that
recruiting should have something visible in it. **The guardrail buys the same launch safety
without touching the payment at all, and it binds on no month this project has ever
measured.** Paying for safety with the mechanism's whole purpose was the worse of two trades
when a free one existed.

#### 9.6.4 The number to watch from the day this switches on

**It is not the cost.** It is
the **capped first-order basis as a share of that month's revenue**. It was 4.2456 percent
across the five measured months and 75.87 percent in the ungated February reading. The rate
the ceiling can carry is `headroom divided by that share`. **If that share rises past roughly
40 percent in any month, the 20 percent rate no longer fits and either the guardrail must
bind or the rate must come down.** One ratio, watched monthly, is the whole early-warning
system.

**What I will not do is multiply two ratios together and present the product as a
measurement.** Every figure in the table above was computed by its own query against the real
event set.

---

## 10. Side by side against the incumbent, so Howard can see what he is trading

All four packages measured on the identical 269 gated enrollments, March through July 2026.

**The first column is the RULED package.** The other three are the options it was chosen over,
kept as a record of what was priced. The 10 percent column is a rejected option, recorded in
section 9.6.3.

| | **RULED: 20 percent with the guardrail** | Rejected: 10 percent | Three-rung ladder | **Howard's two-rung ladder** |
|---|---|---|---|---|
| Pays on a 50.00 first order | **10.00** | 5.00 | 5.00 | **0.00** |
| Pays on a 100.00 first order | **20.00** | 10.00 | 10.00 | 10.00 |
| Pays on a 150.00 first order | **30.00** | 15.00 | 10.00 | 10.00 |
| Pays on a 200.00 first order | **40.00** | 20.00 | 22.50 | 22.50 |
| Pays on a 400.00 first order | **50.00** | 25.00 | 22.50 | 22.50 |
| **Coverage of real enrollments** | **100%** | **100%** | **100%** | **58.36%** |
| Enrollments paying zero | 0 | 0 | 0 | **112** |
| **Five-month cost** | **5,940.00** | **2,970.00** | 2,767.50 | 2,207.50 |
| Cost as a share of revenue | 0.8491% | 0.4246% | 0.3956% | 0.3156% |
| **Combined with the existing plan** | **12.7133%** | **12.2887%** | 12.2598% | 12.1797% |
| Fits the ceiling, steady state | **YES**, 7.29 points spare | YES, 7.71 points spare | YES | YES |
| **Fits the ceiling in a launch-shaped month** | **YES, 19.3988%, because of the guardrail. Without it, 26.5735% and a 6.57 point breach** | YES, 18.9861% unaided | not modelled | not modelled |
| Rate shape as order size grows | flat 20%, then declining above the cap | flat 10%, then declining | **rises 10% to 11.25%**, then declining | **rises 10% to 11.25%**, then declining |
| Cliffs | **none** | **none** | two, worth 5.00 and 12.50 | one, worth 12.50 |
| Worst marginal rate on one extra 50.00 agent | 20% | 10% | **25%** | **25%** |
| Worst single order, instant plus five levels | 40.00% of price | 30.00% of price | 31.25% | 31.25% |
| Engine work beyond the already-specified build | **the guardrail queue, section 9.1.1** | none | a tier table and a boundary rule | a tier table and a boundary rule |
| Ruled by Howard | **YES, 20 percent 2026-08-15, guardrail 2026-08-17** | **rejected 2026-08-17** | no | no |

**What Howard trades by keeping the approved package instead of his ladder:** he spends
3,732.50 more over five months, which is 0.53 points of revenue, and in exchange every
sponsor gets paid, the payout doubles at the two sizes he named, the cliff disappears, the
rising rate disappears, and no new engine concept is introduced.

**What he trades by choosing his ladder instead:** he saves 3,732.50, and 112 of 269
sponsors get nothing, which is the exact problem he set out to solve.

### 10.1 REBUILT in version 2. The seven conditions the published table must meet

**Version 1's brochure table failed the publication gate and it deserved to.** It stated a
basis that contradicted my own term 4, it put the rule underneath the table where it would be
read second or not at all, and it published the payout with neither the per-sponsor cap nor
the recovery clause anywhere on the page.

**The deeper problem, which is the one worth understanding.** A tier table is, by universal
convention, a table of **thresholds**. A reader who sees rows at 50, 100, 150 and 200 draws
two inferences without being told, and both are false here: that the rows are bands, so a
175.00 order pays the 150.00 row's 30.00 when it actually pays 35.00; and that crossing a
rung earns a jump. **The second inference is the serious one. The entire argument for
choosing a flat rate over Howard's ladder is that steps create a cliff and a 25 percent
marginal bounty on talking a newcomer into one more agent. Publishing the flat rate in the
shape of a ladder re-creates that belief in the field even though the rule does not have it,
and a sponsor's behaviour follows what they believe the plan pays.** That would be a
self-inflicted wound: diagnose the cliff as the reason to reject rungs, then draw rungs.

> **NORMATIVE. All seven conditions bind, not a selection. A table published without all
> seven is not approved by this document.**
>
> 1. **The rule goes ABOVE the table, not below it.** The reader must meet the rule before
>    they meet the rows.
> 2. **The left column is headed "Example first purchase".** Never "Tier", "Level", "Band",
>    or a range like "100 to 199". Each row is an exact amount illustrating one rule, not a
>    bracket.
> 3. **One row must be an in-between value, and it must be worked.** A 175.00 row paying
>    35.00. A single such row destroys the band reading faster than a paragraph can.
> 4. **A line stating the continuity in plain words**, saying that every amount in between
>    pays the same percentage and there are no steps to cross.
> 5. **The cap must be labelled as a cap**, because it is the one place the rule really is
>    flat.
> 6. **The basis must match term 4**: the new member's **own purchase**. Not "their first
>    order", which includes volume the new member did not buy and would overpromise on 49 of
>    269 real enrollments.
> 7. **Both limits appear on the same page as the payout**: the three-per-sponsor-per-month
>    cap, and the recovery clause in one sentence.
>
> **The words "tier", "rung", "level" and "bonus" must not appear anywhere near it.**

### 10.2 The published table, meeting all seven

This is the visible recruiting ladder Howard wanted, and it is honest.

> ## When someone you enrol makes their first purchase, you earn 20 percent of it, the day the payment clears.
>
> That is 20 percent of what your new member buys for themselves. It is paid on a purchase,
> never on the signup.
>
> | Example first purchase | You earn |
> |---|---|
> | 50.00 | 10.00 |
> | 100.00 | 20.00 |
> | **175.00** | **35.00** |
> | 200.00 | 40.00 |
> | 250.00 | 50.00 |
>
> **Every amount in between pays twenty percent too. There are no steps and nothing to
> cross.** A 175.00 purchase is in the table to show this: it pays 35.00, not the 100.00
> row's 20.00.
>
> **The most any single first purchase can pay is 50.00**, which is reached at 250.00. Above
> that the payment stays at 50.00.
>
> **Two limits, so you know them before you rely on them.** You can earn this on at most
> **three** new members in any one calendar month. And if the purchase is refunded or charged
> back, or the subscription is cancelled within four months, the amount is returned and
> settled against your next monthly commission.
>
> **In an exceptionally busy month, part of a payment may arrive the following month instead.
> Nothing is ever lost, and your statement always shows what was earned, what was paid, and
> what is still to come.**

**On that last paragraph, which is an addition arising from Howard's ruling and not one of the
seven conditions.** The seven conditions in section 10.1 were written before the guardrail
existed. The guardrail can defer a payment, and the headline sentence promises payment "the
day the payment clears". **A promise of speed that the mechanism can silently break is exactly
the failure document 10 warned about when it argued against a delayed bonus keeping the word
Instant in its name.** One sentence removes the problem, and it is deliberately worded so it
does not frighten anyone in a normal month, because in every month this project has ever
measured the guardrail binds on nothing at all.

**What is deliberately NOT on the member page:** the 8 percent figure itself. It is a company
exposure limit, not a member entitlement, and publishing a percentage nobody can act on would
add confusion without adding honesty. What the member is owed is the knowledge that a payment
can be split across months and that nothing is forfeited, which the sentence above gives them.

**What changed from version 1, and why each change is not cosmetic.** The rule moved above
the table. The 150.00 and "250.00 or more" rows were replaced by a worked 175.00 row and a
plain 250.00 row, so the table can no longer be read as bands. The basis changed from "their
first order" to what the new member buys for themselves, which is term 4 and which differs
for 49 of 269 real enrollments. The cap is now labelled as a cap rather than implied by a
"or more" row. Both limits are on the page. **A sponsor reading this cannot come away
believing that pushing a recruit from 150.00 to 200.00 earns them a jump, because the table
no longer suggests one exists.**

---

## 11. What this package does NOT solve

**It does not make the 20 percent ceiling a per-order cap.** A single first order can pay the
instant amount plus up to 20 percent through the five levels, so up to **40 percent of its own
price** at the approved rate and 30 percent at the reduced rate. The ceiling holds in
aggregate only because first orders are 4.25 percent of revenue. **The brochure must not claim
that no order can pay more than 20 percent once this exists.**

**It cannot be switched on until the recovery path exists.** Term 14 is the gate on the whole
feature. The four pieces listed in document 10 section 7.6 do not exist: no reversed payment
state, no member balance that can go negative, no settlement step in the monthly run, no
exposure cap while a balance is negative. **Nothing in this document builds any of them, and
this document adds a fifth trigger, subscription cancellation, that also has to be wired in.**

**It does not fix the enrollment funnel, because there is no enrollment funnel.** No member
has ever enrolled through the live site; enrollment is still presented as coming soon. **On
today's real live traffic this incentive would pay exactly 0.00**, under every package in
this document. That is a measured floor, not an estimate. The 1,000-member seeded organisation
is the only dataset in the project that contains first-order events.

> **RESTATED in version 2, because the evidence moved under this claim.** A first-ever order
> now does exist on live traffic: member GW-000007 placed their first completed order on
> **2026-08-17**, for 100.00, carrying `demo_order_id` 241. **It pays 0.00 only because that
> member enrolled on 2024-08-10 and therefore fails the 30-day window**, not because no first
> order exists. The conclusion is unchanged and the reason for it is now one gate thin rather
> than structurally empty. **This claim will go stale the first time somebody both enrolls and
> buys on the live site, and it should be re-checked before it is quoted again.**

**It cannot tell you whether large subscriptions churn.** Section 6.4. Every subscription in
the database is 50.00 or 100.00. Howard's retention premise about 400 and 800 subscriptions is
untestable here, and the two sizes that can be observed run the other way.

**RESOLVED in version 2: the tightened basis is now priced.** Section 9.2 basis B. 265
enrollments, 25,800.00 capped basis, **5,160.00 at 20 percent**, combined 12.6018 percent.
Version 1 declined to compute this and it was a real gap, because it meant the recommended
package and its headline price were two different policies.

**It cannot say what a real launch costs.** Section 9.5. The only launch-shaped month in the
database is February 2026, and it is a seed artifact in both directions: ungated it says
26.5735 percent, fully gated it says 12.5381 percent, and neither is trustworthy. **The true
launch exposure sits somewhere between and the data cannot say where.** That is why the answer
is term 7, a guardrail that bounds the outcome regardless, rather than a number.

**It does not model the guardrail's deferral queue, and cannot.** Term 7 defers rather than
forfeits, so in a month where it binds, some sponsors are paid late. **How late, and how large
the queue grows, depends on the launch curve, which does not exist.** No figure is given
because none can be. The properties that are certain are that no sponsor loses money, no month
exceeds 8 percent of revenue, and the plan plus a fully spent guardrail is 19.8641 percent,
which is under the ceiling by construction.

**It cannot test the guardrail's intra-month behaviour.** Section 9.1.1, rule 1, tests the
allowance against revenue to date, which is a running test. **Every order in all six seeded
months carries the same `ordered_at` date**, the first of the month, so each month collapses
to a single instant and the running test can never be exercised here. The month-level result
that the guardrail binds on nothing is sound; rules 1 and 3 must be proven by a test the
implementer writes.

**It does not resolve document 10's unreproducible figure.** Section 5.3. Document 10 term 8
must be rewritten to say which reading of the sponsor-has-purchased gate it means. Until it
is, that document's 234 events and 5,050.00 and this document's 269 and 5,940.00 are both
defensible and they are not the same policy.

**It does not pay anybody.** Nothing in Orvanna moves money to a member. There is no payout
method, no bank detail, no disbursement record. This mechanism is a computed and recorded
obligation, exactly like every other mechanism in the plan.

---

## 12. What is ruled, and what Howard still has to decide

**Ruled on 2026-08-17: the rate and the guardrail, together, as one term.** Four decisions
remain open and they are items 4 through 7 below.

1. **Accept or reject the core finding**, that his tiered enrollment incentive and the Instant
   Payout he approved on 2026-08-15 are the same mechanism, and the approved one pays more at
   every order size. Independently confirmed, and confirmed as holding at **every** price
   rather than only the five Howard named. If he accepts it, there is no second mechanism to
   build.
2. ~~Approve or reject the monthly guardrail, term 7.~~ **RULED 2026-08-17: adopted.**
3. ~~Choose the rate.~~ **RULED 2026-08-17: 20 percent, with the guardrail, as one term.
   10 percent rejected and recorded in section 9.6.3.**
4. **Rule on the "enrolled in SaaS" definition**, section 8.3. It is the one thing Howard
   raised that the approved package genuinely does not cover, it changes who gets paid for
   four real enrollments, it lowers the cost to 5,160.00, and it closes the clawback hole in
   section 8.5 for free.
5. **Approve the four-month recovery window run from the qualifying order date**, section 7.2,
   and accept that term 15 gates the whole thing. Choosing four over six leaves 600.00
   unrecovered across five measured months; that is the size of the trade.
6. **Approve term 10 as a policy loosening, not a wording fix.** It costs 1,050.00 more over
   five months than the stricter reading. Section 5.3 and term 10.
7. **Send document 10 back for one correction**, its term 8, before either document is quoted
   to anyone. Its 234 is unreproducible under **seven** independent readings, not the four
   version 1 tried.

---

## 13. Version history

| Version | Date | What changed |
|---|---|---|
| 1 | 2026-08-17 | First costed terms. Core finding that the approved Instant Payout dominates Howard's ladder at every size. 269-event cohort, 5,940.00 at 20 percent, coverage 100 versus 58.36 percent. |
| **2** | **2026-08-17** | Passed arithmetic verification 47 of 47 with no errors found. Failed the publication gate and was amended: **added the launch stress test and the monthly guardrail as term 7**, **rebuilt the brochure table against seven binding conditions**, **moved the recovery window from three months from enrollment to four months from the qualifying order date**, **published the tightened cost of 5,160.00**, priced term 10's loosening, resolved the payout-versus-clawback table conflict, and corrected three factual statements. **No cost figure from version 1 changed.** |
| **2, ruling applied** | **2026-08-17** | **Howard ruled the rate: "20 with the guardrail".** 20 percent written as the rate of record and bound inseparably to term 7; **10 percent moved from live alternative to rejected option** in section 9.6.3 with its cost recorded; **term 7 specified to build level in section 9.1.1** with seven rules covering the running allowance test, deferral, queue order, cascade, the recovery-window interaction, lapse in place, and statement visibility. **No cost figure changed.** |
