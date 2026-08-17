# Enrollment Incentive: costed terms for Howard to choose between

**Owner of this document:** the compensation engineer on the Orvanna build team.
**Written:** 2026-08-17.
**Status: A PROPOSAL, NOT APPROVED AND NOT BUILT.** Every query behind every number was
read-only against the live Supabase project. No migration was applied, no engine function
was changed, and no code of any kind was written for this mechanism.

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

**I have not verified my own arithmetic.** That is the standing rule for this role. Every
figure here is my query and my calculation, and mlm-verifier should recompute it
independently before Howard commits to anything that quotes it.

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

**So the recommendation in this document is not a new mechanism. It is a presentation
change plus a rate decision.** Publish the already-approved Instant Payout as a tier table,
because that is what Howard actually wants the brochure to show, and a flat percentage of
price with a capped basis renders as a tier table without any of the problems a step ladder
carries. If Howard wants it cheaper than the approved 20 percent, the honest lever is the
rate, not the shape: 10 percent on the same basis costs 2,970.00 over five measured months,
still pays on 100 percent of real enrollments, and still has no cliff.

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
| D6 | **The recovery timeline** | Enrollment, first order, instant payment to sponsor, then a cancellation or refund at month 1, 2 or 3, then the negative balance settling in the next monthly commission run. | Recovery is the gate on the whole mechanism and it is a sequence, which is the one thing a table cannot show. |

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

In this database an order carries exactly one product line. A new member who subscribes to
one 100.00 domain agent and one 50.00 support agent in the same month produces **two order
rows**. Counting rows instead of people does two things at once, and both push the answer
in the same wrong direction: it inflates the denominator, and it shatters each enrollment
into fragments of 50.00 and 100.00, so no fragment can ever reach 200.

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

### 7.2 The window, recommended from measured cancellation timing

Howard's own point is that a subscription may not be kept. So the incentive must be
recoverable when the subscription cancels shortly after enrollment, not only when the card is
charged back. I measured how quickly cancellations actually happen, across all 401 cancelled
subscriptions in the database:

| Months from subscription start to cancellation | Cancellations | Share | Running share |
|---|---|---|---|
| 1 | 53 | 13.22% | **13.22%** |
| 2 | 50 | 12.47% | **25.69%** |
| 3 | 49 | 12.22% | **37.91%** |
| 4 | 43 | 10.72% | 48.63% |
| 5 | 33 | 8.23% | 56.86% |
| 6 | 32 | 7.98% | **64.84%** |
| 7 or later | 141 | 35.16% | 100.00% |

Average months to cancellation: **6.15**.

> **RECOMMENDED WINDOW: three months.** If the new member's subscription cancels, or the
> qualifying order is refunded or charged back, within **three complete calendar months of
> the enrollment month**, the incentive is recovered in full and settled against the sponsor's
> next monthly commission run.

**Why three and not one, and not six.** One month recovers only 13.22 percent of
cancellations, which is barely worth the build. Six months recovers 64.84 percent but leaves
a sponsor's earnings reversible for half a year, which is a real thing for a person's
household budget and a real reason for a field to distrust a plan. **Three months recovers
37.91 percent of all cancellations, which is nearly three times what a one-month window
catches, and it is short enough that a sponsor can be told the rule in one sentence and
believe it.**

**Recovery is full, not prorated.** A prorated recovery needs a second formula, a second set
of rounding decisions and a second thing to explain, to reclaim a fraction of an amount that
averages 22.08 under the recommended package. It is not worth it. Inside the window the whole
amount comes back; outside it, none of it does.

**One honest caveat.** The cancellation timing above is measured across all 1,830
subscriptions, not specifically across the 269 first orders in the cohort. I did not restrict
it, because doing so would have produced a sample too small to say anything with. The window
recommendation is therefore drawn from the general cancellation curve and applied to
enrollments, which is an assumption and is labelled as one. It is the only place in this
document where a figure is used for a population slightly wider than the one it was measured
on, and it changes no cost figure anywhere.

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

---

## 9. THE RECOMMENDED PACKAGE, on one page

**NOT APPROVED. NOT BUILT.** This is a proposal for Howard to accept, amend or reject.

**The one-sentence version.** Do not build a second mechanism. Take the Instant Payout Howard
already approved on 2026-08-15, publish it in the brochure as a tier table because that is
the visible recruiting reward he is asking for, and decide only one thing: whether the rate
stays at the approved 20 percent or drops to 10 percent.

### 9.1 The terms

Terms 1 through 3 and 8 through 15 are unchanged from the approved Instant Payout package.
The terms that are new or amended are marked. Anything not marked is already Howard's own
approved policy and is repeated here only so this package can be built from one page.

| # | Term | The rule |
|---|---|---|
| 1 | **Name** | **Instant Payout**, the existing approved name. The same word in the brochure, the table, the column and the function. There is no second mechanism and no second name. |
| 2 | **Who is paid** | The **sponsor**, meaning the member who personally enrolled the buyer. |
| 3 | **What triggers it** | A **product purchase**, never the signup. Specifically the **first order ever** placed by that sponsored member, placed **within 30 days of that member's enrollment date**. One Instant Payout per member, ever. Enrolling costs nothing and pays nothing; the money exists only because a product was sold. |
| 4 | **AMENDED. What the qualifying order must contain** | The order must be the new member's **own purchase**, `buyer_role = 'member'`, and must contain **at least one subscription line**. Volume booked to the new member from their own retail customers is excluded from the basis. This is Howard's "enrolled in SaaS" rule, made precise. See section 8.3. |
| 5 | **Basis** | The **order price**, exclusive of tax and of any activation fee. Not Commissionable Volume, and not a flat amount. |
| 6 | **DECISION REQUIRED. Rate** | **A flat percentage of that price, with no rungs.** Two candidates, both costed in section 9.2: **20 percent**, which is what Howard already approved, or **10 percent**, which is closest to the numbers he proposed this week. My recommendation is 20 percent; see section 9.5. |
| 7 | **Cap per event** | The basis is capped at **250.00**. At 20 percent no single payout exceeds **50.00**; at 10 percent, **25.00**. |
| 8 | **Cap per sponsor** | At most **3** Instant Payouts to one sponsor in one calendar month, **kept in order of earliest order date**, tie-broken by member id. The tie-break is new and must be written into the specification, not left to the query. |
| 9 | **Eligibility of the payee** | The sponsor must already have at least one completed purchase of their own, `buyer_role = 'member'`, **dated on or before the recruit's first order date**. Same day counts. No monthly qualification gate applies, because qualification cannot be known at the instant. **The date reading is the amendment**, and section 5.3 explains why it had to be pinned down. |
| 10 | **No rungs, no cliffs, no interpolation question** | The payment is a continuous percentage of price up to the cap. There are no tiers, so there is no step to cross and no interpolation rule to write. A 150.00 order pays exactly half again what a 100.00 order pays. **Adding one 50.00 agent to a first order always changes the payout by the same flat percentage of that 50.00, at every size, up to the cap.** |
| 11 | **When it is paid** | At the moment the payment reaches `succeeded`, which is the only status backed by a fresh retrieve from the processor and an exact amount match. |
| 12 | **Against the rest of the plan** | **In addition** to level one pay. No commission line is suppressed. Nothing in `app.fn_run_commission` changes. |
| 13 | **Against volume** | It consumes **no volume**. Sales Volume, Commissionable Volume, Team Volume, ranks and the ten-month spreading rule are all completely untouched. |
| 14 | **AMENDED. Recovery, and it gates everything** | If the qualifying order is refunded or charged back, **or if the new member's subscription cancels, within three complete calendar months of the enrollment month**, the full amount is recovered from the sponsor's balance and settled against their next monthly commission run. Recovery is full, never prorated. **This must be built before the first Instant Payout is paid.** The subscription-cancellation trigger is the amendment; the four pieces to build are unchanged from document 10 section 7.6. |
| 15 | **Ledger** | Written to `app.commission_lines` with `payout_type = 'instant_payout'`, and a recovery as `payout_type = 'instant_payout_clawback'`, so neither ever merges silently with level pay in any existing report. |
| 16 | **No roll-up** | **Terminal at the sponsor.** It pays the sponsor and nobody above them. No level pay, no depth pay, no volume of any kind that could reach anyone further up the tree. One event produces exactly one commission line to exactly one earner. Howard's rule, 2026-08-15, unchanged. |

### 9.2 The measured cost of exactly those terms

Computed by read-only SQL applying terms 3, 7, 8 and 9 simultaneously to the real first-order
events of March through July 2026. Not scaled from any other figure. The basis used is total
first-month Sales Volume, so these numbers stay comparable with document 10; see the caveat
in section 8.3.

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
rate would break the ceiling on its own. Orvanna is not that company today, and a 9.58 times
runway is wide. But the runway is the number to watch, not the current cost.

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

### 9.5 The rate recommendation, and the honest case for the other one

> **RECOMMENDED: keep 20 percent, the rate Howard already approved on 2026-08-15.**

Four reasons.

**It is already approved, so recommending it costs nothing to decide.** Howard ruled on this
rate two days ago. Nothing measured since has weakened it: the cohort grew from document 10's
234 events to 269 under a clearer gate, the cost rose from 5,050.00 to 5,940.00, and the
combined share moved from 12.59 percent to 12.71 percent against a 20 percent ceiling. It
still fits with 7.29 points spare.

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
every attempt. That property comes from the rate being a percentage of price and holds at
both candidate rates.

> **IF HOWARD WANTS IT CHEAPER, the lever is the rate, not the shape: 10 percent of price on
> the same capped basis and the same gates. 2,970.00 over five months, 0.4246 percent of
> revenue, combined 12.2887 percent.** It pays 10.00 at 100 Sales Volume, which is exactly
> the number Howard proposed, and 20.00 at 200 against his 22.50. It still pays on 100
> percent of enrollments, still has no cliff, and still needs no new engine concept. It costs
> 202.50 more than the three-rung ladder over five months and is better on every other axis.

**What I will not do is multiply two ratios together and present the product as a
measurement.** Every figure in the table above was computed by its own query against the real
event set.

---

## 10. Side by side against the incumbent, so Howard can see what he is trading

All four packages measured on the identical 269 gated enrollments, March through July 2026.

| | **Approved Instant Payout, 20 percent** | **Same at 10 percent** | Three-rung ladder | **Howard's two-rung ladder** |
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
| Fits the 20 percent ceiling | **YES**, 7.29 points spare | **YES**, 7.71 points spare | YES | YES |
| Rate shape as order size grows | flat 20%, then declining above the cap | flat 10%, then declining | **rises 10% to 11.25%**, then declining | **rises 10% to 11.25%**, then declining |
| Cliffs | **none** | **none** | two, worth 5.00 and 12.50 | one, worth 12.50 |
| Worst marginal rate on one extra 50.00 agent | 20% | 10% | **25%** | **25%** |
| Worst single order, instant plus five levels | 40.00% of price | 30.00% of price | 31.25% | 31.25% |
| Engine work beyond the already-specified build | **none** | **none** | a tier table and a boundary rule | a tier table and a boundary rule |
| Already approved by Howard | **YES, 2026-08-15** | no, rate change | no | no |

**What Howard trades by keeping the approved package instead of his ladder:** he spends
3,732.50 more over five months, which is 0.53 points of revenue, and in exchange every
sponsor gets paid, the payout doubles at the two sizes he named, the cliff disappears, the
rising rate disappears, and no new engine concept is introduced.

**What he trades by choosing his ladder instead:** he saves 3,732.50, and 112 of 269
sponsors get nothing, which is the exact problem he set out to solve.

**The brochure table, if the approved package is kept.** This is the tiered ladder Howard
wanted. It is the approved percentage, rendered as rungs:

| Their first order | You earn, the same day |
|---|---|
| 50.00 | **10.00** |
| 100.00 | **20.00** |
| 150.00 | **30.00** |
| 200.00 | **40.00** |
| 250.00 or more | **50.00** |

One sentence underneath it: **twenty percent of your new member's first order, up to 50.00,
paid the day the payment clears.**

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

**It cannot tell you whether large subscriptions churn.** Section 6.4. Every subscription in
the database is 50.00 or 100.00. Howard's retention premise about 400 and 800 subscriptions is
untestable here, and the two sizes that can be observed run the other way.

**It does not price the tightened basis it recommends.** Section 8.3. Every cost figure uses
total first-month Sales Volume. Restricting the basis to the new member's own purchases will
lower every number in section 9.2, and by how much is unmeasured. **Re-measure before
publishing any figure from this document alongside the tightened definition.**

**It does not resolve document 10's unreproducible figure.** Section 5.3. Document 10 term 8
must be rewritten to say which reading of the sponsor-has-purchased gate it means. Until it
is, that document's 234 events and 5,050.00 and this document's 269 and 5,940.00 are both
defensible and they are not the same policy.

**It does not pay anybody.** Nothing in Orvanna moves money to a member. There is no payout
method, no bank detail, no disbursement record. This mechanism is a computed and recorded
obligation, exactly like every other mechanism in the plan.

---

## 12. What I recommend Howard actually decides, in order

1. **Accept or reject the core finding**, that his tiered enrollment incentive and the Instant
   Payout he approved on 2026-08-15 are the same mechanism, and the approved one pays more at
   every order size. If he accepts it, there is no second mechanism to build.
2. **Choose the rate: 20 percent or 10 percent.** Everything else in section 9.1 is settled.
   My recommendation is 20 percent, and section 9.5 makes the case for 10 percent honestly in
   case cost pressure changes.
3. **Rule on the "enrolled in SaaS" definition**, section 8.3, because it is the one thing he
   raised that the approved package genuinely does not cover, and because it changes who gets
   paid for four real enrollments.
4. **Approve the three-month recovery window**, section 7.2, and accept that term 14 gates
   the whole thing.
5. **Send document 10 back for one correction**, its term 8, before either document is quoted
   to anyone.
