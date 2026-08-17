# Verification verdict: the Enrollment Incentive costed terms

**Graded by:** mlm-verifier, the independent verifier on the Orvanna build team.
**Graded on:** 2026-08-17.
**Artifact:** `MLM-PILOT\docs\ENROLLMENT-INCENTIVE-TERMS-2026-08-17.md`
Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\ENROLLMENT-INCENTIVE-TERMS-2026-08-17.md`
**SHA-256 of the graded artifact:** `dbf5f12be201b3ddc41efd17ed00e3918007dac8fa60ec47c0c4bcdc28f001c7`
**Commit graded:** `c41a7906f5a405a5c48ac15401ef4c78ba6d05d1`
**Cross-referenced document:** `DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`,
SHA-256 `5619d1d3f4eaba0e826803309da95d2d5f48f64816e9a82109edb32779ddd9cd`

**Method.** I wrote my own Structured Query Language (SQL) from the written terms and ran it
read only against Supabase project `oiyibdczkokegaxkwulv`. I did not read, copy or run the
engineer's queries, because they are not recorded. No write, no migration, no engine change,
no code. Twenty two independent queries.

**Acronym key.** Sales Volume (SV). Commissionable Volume (CV). Structured Query Language
(SQL). Row Level Security (RLS).

---

## The verdict in one picture

```
ARITHMETIC             every figure I was asked to recompute
                       ############################################  PASS  47 of 47
                       reproduced to the cent and to the decimal

PUBLICATION GATE       is this ready to go onto a public page
                       ####                                          FAIL  2 HIGH, 2 MEDIUM
```

**The document's numbers are right. Its safety case is incomplete, and the brochure table it
proposes to publish misstates its own terms.** Those are separable, and I am reporting them
separately so the good work is not thrown away with the defect.

### The finding that decides the gate, drawn to scale

Combined compensation cost as a share of revenue, against the plan's 20 percent ceiling.

```
                        0%        5%        10%       15%       20% CEILING
                        |---------|---------|---------|---------|
STEADY STATE, the five months the document measured
  plan alone            |#############################|              11.86%
  plus 20 percent       |################################|           12.71%   FITS
  plus 10 percent       |###############################|            12.29%   FITS

LAUNCH SHAPE, February 2026, the one month the document excluded
  plan alone            |#############################|              11.40%
  plus 10 percent       |################################################|    19.01%   FITS, 0.99 spare
  plus 20 percent       |####################################################|########  26.62%   BREAKS BY 6.62
                                                                      ^ceiling
```

In February 2026 every dollar of revenue was somebody's first order. That is the shape
Orvanna will be in the day enrollment opens, because Orvanna has never enrolled anybody.
The document excludes February as a seed artefact, which is correct for a steady state cost
model and wrong as the whole safety case.

---

## 1. Recomputation scoreboard

Every row below is my own number from my own query, set beside the document's claim. A tick
means they agree exactly.

### 1.1 The core claim, section 1

The claim: Howard's ladder and the approved Instant Payout are the same mechanism, and the
approved package pays the sponsor more at every order size Howard named.

| New member's first order | Ladder, claimed | Ladder, recomputed | Instant Payout at 20 percent, claimed | Recomputed | Agree |
|---|---|---|---|---|---|
| 50.00 | 0.00 | 0.00 | 10.00 | 10.00 | yes |
| 100.00 | 10.00 | 10.00 | 20.00 | 20.00 | yes |
| 150.00 | 10.00 | 10.00 | 30.00 | 30.00 | yes |
| 200.00 | 22.50 | 22.50 | 40.00 | 40.00 | yes |
| 250.00 or more | 22.50 | 22.50 | 50.00 | 50.00 | yes |

**CONFIRMED, and stronger than the document claims.** I tested the general statement, not
only the five named sizes. Instant Payout at 20 percent of the price with the basis capped at
250.00 pays `0.20 x min(price, 250)`. That is 10.00 or more at every price of 50.00 or above,
and it reaches 50.00 at 250.00 and stays there. Howard's ladder never exceeds 22.50 at any
price. There is therefore no price anywhere, in the catalog or outside it, at which the
ladder pays more. The document's sentence "there is no order size anywhere in the catalog
where the ladder is the better deal" is true and understated: it holds for every real number,
not only for the catalog.

**Consequence, which I endorse.** The recommendation really is a presentation change plus a
rate decision, not an engine build. That part of the document is sound.

### 1.2 The population, section 3

| Claim | Document | My recomputation | Agree |
|---|---|---|---|
| First orders March to July 2026, counted as order rows, after the 30 day window | 457 | 457 | yes |
| Their Sales Volume | 33,050.00 | 33,050.00 | yes |
| Order rows at 200.00 or above | 0 | 0 | yes |
| Same population counted as members | 284 | 284 | yes |
| Their Sales Volume | 33,050.00 | 33,050.00 | yes |
| Members at 200.00 or above | 54 | 54 | yes |
| Before the 30 day window, members | (funnel: 288) | 288 | yes |
| Before the 30 day window, order rows and Sales Volume | not stated | 462 rows, 33,350.00 | n/a |

**The overturn is CONFIRMED and the reconciliation is CONFIRMED.** 457 and 284 are two counts
of the identical population and the identical 33,050.00 of money. 457 counts order rows, 284
counts people. The reason the row view showed zero events at 200.00 or above is exactly as
the document says: no single order row in the March to July first order window reaches 200.00,
because a 200.00 enrollment is recorded as two rows of 100.00. I verified this directly: zero
order rows of 200.00 or more exist in that window.

**Your chart was wrong and the correction stands.** 54 of 284 is 19.0141 percent, which the
document rounds to 19.01 percent. Correct.

### 1.3 The funnel and the gates, section 5

| Stage | Document | Recomputed members | Recomputed Sales Volume | Agree |
|---|---|---|---|---|
| First orders, March to July 2026 | 288, 33,350.00 | 288 | 33,350.00 | yes |
| After the 30 day window | 284, 33,050.00 | 284 | 33,050.00 | yes |
| After the sponsor has purchased gate | 276, 32,300.00 | 276 | 32,300.00 | yes |
| After the three per sponsor per month cap | 269, 31,400.00 | 269 | 31,400.00 | yes |
| Sponsor months observed | 227 | 227 | | yes |
| Largest single sponsor month | 6 | 6 | | yes |
| Sponsor months exceeding three | 4 | 4 | | yes |

Gates remove 19 of 288, which is 6.5972 percent. The document says 6.60 percent. Correct.

### 1.4 The distribution, section 5.4

| First order size | Document | Recomputed | Agree |
|---|---|---|---|
| 50.00 | 112, 41.64% | 112, 41.6357% | yes |
| 100.00 | 67, 24.91% | 67, 24.9071% | yes |
| 150.00 | 39, 14.50% | 39, 14.4981% | yes |
| 200.00 | 24, 8.92% | 24, 8.9219% | yes |
| 250.00 | 9, 3.35% | 9, 3.3457% | yes |
| 300.00 | 7, 2.60% | 7, 2.6022% | yes |
| 350.00 | 6, 2.23% | 6, 2.2305% | yes |
| 400.00 | 5, 1.86% | 5, 1.8587% | yes |
| Total | 269, 31,400.00 | 269, 31,400.00 | yes |
| At 200.00 or above, in the 269 cohort | 51, 18.96% | 51, 18.9591% | yes |

### 1.5 Coverage, section 6.1 and section 9.3

| Claim | Document | Recomputed | Agree |
|---|---|---|---|
| Flat percentage of price, enrollments paid | 269 of 269, 100 percent | 269 of 269 | yes |
| Howard's two rung ladder, enrollments paid | 157, 58.36 percent | 157, 58.3643 percent | yes |
| Howard's two rung ladder, enrollments paying zero | 112, 41.64 percent | 112, 41.6357 percent | yes |
| Three rung ladder, enrollments paid | 269, 100 percent | 269 | yes |
| Ladder average across all 269 | 8.21 | 8.2063 | yes |
| Ladder average when it fires | 14.06 | 14.0605 | yes |

**Your 55 percent figure is overturned.** The correct figure is 41.64 percent paying zero.

### 1.6 The cost table, section 9.2

| Month | Document events | Mine | Document capped basis | Mine | Document at 20 percent | Mine | Agree |
|---|---|---|---|---|---|---|---|
| 2026-03 | 51 | 51 | 5,350.00 | 5,350.00 | 1,070.00 | 1,070.00 | yes |
| 2026-04 | 46 | 46 | 4,200.00 | 4,200.00 | 840.00 | 840.00 | yes |
| 2026-05 | 71 | 71 | 7,450.00 | 7,450.00 | 1,490.00 | 1,490.00 | yes |
| 2026-06 | 38 | 38 | 3,600.00 | 3,600.00 | 720.00 | 720.00 | yes |
| 2026-07 | 63 | 63 | 9,100.00 | 9,100.00 | 1,820.00 | 1,820.00 | yes |
| Total | 269 | 269 | 29,700.00 | 29,700.00 | 5,940.00 | 5,940.00 | yes |

At 10 percent: 2,970.00 claimed, 2,970.00 recomputed. Howard's two rung ladder: 2,207.50
claimed, 2,207.50 recomputed. Three rung ladder: 2,767.50 claimed, 2,767.50 recomputed.

### 1.7 The ceiling test, section 9.4

| Claim | Document | Recomputed | Agree |
|---|---|---|---|
| Revenue, five months | 699,550.00 | 699,550.00 | yes |
| Plan payout already made | 82,995.60 | 82,995.60 | yes |
| Plan as a share of revenue | 11.8641% | 11.86414% | yes |
| Instant Payout as a share of revenue at 20 percent | 0.8491% | 0.849117% | yes |
| Combined at 20 percent | 12.7133% | 12.71326% | yes |
| Combined at 10 percent | 12.2887% | 12.28873% | yes |
| Headroom | 56,914.40, 8.1359 points | 56,914.40, 8.13586 points | yes |
| Capped basis share of revenue | 4.2456% | 4.24558% | yes |
| Break even multiple at 20 percent | 9.58 times | 9.5817 times | yes |
| Break even multiple at 10 percent | 19.16 times | 19.1634 times | yes |
| Worst month, July 2026 | 13.0334% | 13.03340% | yes |
| Best month, April 2026 | 12.4205% | 12.42054% | yes |
| Average per qualifying enrollment at 20 percent | 22.08 | 22.0818 | yes |

Every one of the five monthly combined figures at both rates reproduces to four decimal
places. The 20 percent ceiling derivation, 25 percent of Commissionable Volume where
Commissionable Volume is 80 percent of revenue, is confirmed against the compensation plan
and against the engine: level rates in `app.commission_lines` are exactly 10, 5, 5, 3 and 2
percent, totalling 25 percent of Commissionable Volume.

**Worst single first order.** 40.00 percent of its own price at the 20 percent rate.
CONFIRMED, and confirmed as a genuine theoretical maximum rather than a rhetorical one,
because the five level rates really do sum to 20 percent of price.

**Measured all in cost on the cohort.** The ordinary plan actually paid 3,560.40 across all
five levels on the 269 members in their first month, of which 1,824.00 was level one. I
recomputed both from `app.commission_lines` joined to the finalized runs: level one 1,824.00,
level two 590.00, level three 654.00, level four 394.80, level five 97.60, total 3,560.40.
CONFIRMED exactly.

### 1.8 The churn figures, section 6.4 and section 7.2

| Claim | Document | Recomputed | Agree |
|---|---|---|---|
| Subscriptions in the database | 1,830 | 1,830 across 960 members | yes |
| Subscriptions at 200, 400 or 800 | none | none, only 50.00 and 100.00 exist | yes |
| 50.00 subscriptions | 907, 239 cancelled, 26.35% | 907, 239, 26.3506% | yes |
| 100.00 subscriptions | 923, 162 cancelled, 17.55% | 923, 162, 17.5514% | yes |
| Cancellations at month 1, 2, 3 | 53, 50, 49 | 53, 50, 49 | yes |
| Cumulative through month 3 | 37.91% | 37.9052% | yes |
| Cumulative through month 6 | 64.84% | 64.8379% | yes |
| Average months to cancellation | 6.15 | 6.1496 | yes |

**Howard's stated premise is reversed by the data, and the document is right to say so.** The
cheaper subscription cancels at 26.35 percent against 17.55 percent for the dearer one. The
document's own caveat is also right: two price points cannot speak about a sixteen fold range,
and no subscription at 200, 400 or 800 has ever existed here.

### 1.9 The vacuous subscription gate, section 8.2

| Claim | Document | Recomputed | Agree |
|---|---|---|---|
| Rows in `app.order_lines` | 10,353 | 10,353 | yes |
| Rows with `billing_mode = 'sub'` | all | 10,353 of 10,353, one distinct value | yes |
| First month order lines in the 269 cohort | 434, all subscription lines | 434, all subscription lines | yes |

**CONFIRMED. A gate requiring a subscription line excludes nobody today.** Its measured cost
is 0.00 and that figure carries no information.

### 1.10 The retail basis swing, section 8.2

| Claim | Document | Recomputed | Agree |
|---|---|---|---|
| Enrollments with some retail customer volume | 49 of 269 | 49 | yes |
| Enrollments where the new member bought nothing themselves | 4 of 269 | 4 | yes |
| Cohort own purchases | 26,450.00 | 26,450.00 | yes |
| Cohort retail customer volume | 4,950.00 | 4,950.00 | yes |
| Own purchases reaching 100.00 | 133 | 133 | yes |
| Total Sales Volume reaching 100.00 | 157 | 157 | yes |

The 24 enrollment swing is real and so are the four people who would be paid for a purchase
they did not make.

### 1.11 Document 10's 234, section 5.3

**CONFIRMED, and confirmed harder than the document confirms it.** The engineer tried four
readings. I tried seven, including three he did not try.

| Reading of the sponsor has purchased gate | My events | My capped basis | Document's claim |
|---|---|---|---|
| Any completed sponsor order on or before the date, after the cap | 274 | not computed | 274, agrees |
| Own purchase, `buyer_role = 'member'`, on or before the date, after the cap | 269 | 29,700.00 | 269 and 29,700.00, agrees |
| Own purchase in a strictly earlier month, before the cap | 233 | 25,350.00 | 233 and 25,350.00, agrees |
| Own purchase in a strictly earlier month, after the cap | 226 | 24,450.00 | 226 and 24,450.00, agrees |
| Any sponsor order in a strictly earlier month, after the cap | 231 | 24,750.00 | not tried |
| Any sponsor order in a strictly earlier month, before the cap | 238 | 25,650.00 | not tried |
| Own purchase, cap applied on the calendar month of the order date rather than the volume month | 226 | 24,450.00 | not tried |
| **Document 10 section 9.2** | **234** | **25,250.00** | **reproduced by none of the seven** |

Document 10's own section 3.1 distribution, 121 at 50.00 and 72 at 100.00 and so on to 288,
reproduces exactly from my queries, so its cohort definition is sound and only its gated
figure is unreachable. **Document 10 term 8 is genuinely ambiguous and must be rewritten
before either document is quoted.** The finding stands.

### 1.12 Other checkable statements

| Claim | Recomputed | Verdict |
|---|---|---|
| Sixteen products, every one with `volume_points` equal to `price` | 16 of 16 | CONFIRMED |
| February 2026 holds 596 first orders | 596 | CONFIRMED |
| Six finalized commission runs, all six rows of the baseline table | every figure matches to the cent | CONFIRMED |
| Revenue equals Sales Volume with no conversion | order line prices sum to `total_sv` in all six months | CONFIRMED |
| August 2026 has 19 orders and 3,750.00, all carrying a `demo_order_id` | 19 orders, 21 lines, 3,750.00, all bridged | CONFIRMED |
| August holds two Constellation Packs at 800.00 and one Manager Agent at 200.00 | 2 and 1 | CONFIRMED |
| No em dashes or en dashes; no Unicity data or terminology | zero occurrences of either | CONFIRMED |

**Result: 47 of 47 claims reproduce. I found no arithmetic error anywhere in the document.**
That is the cleanest recomputation this project has produced, and I am recording it as such.

---

## 2. Findings

### HIGH 1. The safety case is measured only in steady state, and the one launch shaped month in the database breaks the ceiling at the recommended rate

**Evidence, my own query.** February 2026 is in the same database. I measured it.

| February 2026 | Value |
|---|---|
| Revenue | 104,450.00 |
| Members placing a first order | 596 of 1,000 |
| Their Sales Volume | 104,450.00, which is **100.0000 percent of revenue** |
| Capped first order basis | 79,500.00, which is **76.1130 percent of revenue** |
| Plan payout alone | 11,906.00, 11.3988 percent |
| Plus Instant Payout at **20 percent** | 15,900.00, total 27,806.00, **26.6212 percent** |
| Plus Instant Payout at **10 percent** | 7,950.00, total 19,856.00, **19.0100 percent** |
| The ceiling | 20.0000 percent |

**At 20 percent a launch shaped month misses the ceiling by 6.62 points. At 10 percent it
clears with 0.99 points to spare.** The maximum rate a February shaped month can carry is
`8.6012 / 76.1130 = 11.30 percent`.

**Why this is HIGH and not a quibble.** The document's headline safety sentence, repeated
three times, is "IT FITS, 7.29 points of revenue remain unspent". Section 9.4 does name the
danger correctly in words: "The danger is not a mature organisation, it is a young one ... a
20 percent rate would break the ceiling on its own." It then says "Orvanna is not that
company today". **Orvanna is exactly that company.** The document itself states, in section
11, that no member has ever enrolled through the live site. The seeded thousand member
organisation is a simulation of a mature company that Orvanna has not become. On the day
enrollment opens, every order is somebody's first order, and the February row above is what
that costs.

The document had the disproof sitting in the row it excluded, and excluding February for the
cost model was correct. Not running it as the stress test was not.

**What it does not mean.** It does not mean the number is wrong or the mechanism is unsafe.
An over ceiling spend in launch month one, on a tiny absolute base, may be exactly the
acquisition cost Howard said he was willing to pay. It means the decision must be made
knowingly, and the document as written lets it be made unknowingly.

### HIGH 2. The brochure table the document proposes to publish misstates its own terms

The document proposes, in section 10, that this goes into the compensation brochure:

> | Their first order | You earn, the same day |
> | 50.00 | 10.00 | ... |
>
> One sentence underneath it: twenty percent of your new member's first order, up to 50.00,
> paid the day the payment clears.

Three defects, all on the artifact that becomes a public page.

**a. The basis in the sentence contradicts term 4.** Term 4, the document's own recommended
amendment, says the basis is the new member's **own purchase**, and that volume booked from
their retail customers is **excluded**. The brochure sentence says "your new member's first
order". Those are different quantities for 49 of 269 real enrollments and materially different
for 4 of them. A new member whose own purchase is 50.00 and whose retail customer buys 150.00
has a 200.00 first order by the brochure's wording and a 50.00 basis by term 4. The brochure
promises 40.00 and the terms pay 10.00.

**b. The table publishes the payout and hides both of its limits.** The three per sponsor per
calendar month cap and the recovery clause do not appear anywhere on the proposed page. A
compensation plan reviewer looks for exactly those two. A payout table published without its
cap and its clawback is the classic omission, and it is worse here because the recovery
clause is the gate on the entire mechanism.

**c. The rule sentence is placed underneath the table.** The table is read first and the rule
is read second, if at all.

### MEDIUM 3. The recovery window is argued from the wrong population, and the right population was computable

The document recommends a three month recovery window, and justifies it from the general
cancellation curve across all 1,830 subscriptions: 37.91 percent of cancellations caught at
three months against 64.84 percent at six. It states plainly that it did not restrict the
measurement to the 269 cohort, and gives the reason: "doing so would have produced a sample
too small to say anything with".

**That reason does not hold, and I measured the cohort.** 269 enrollments with 96 eventual
cancellers is not too small.

| Months from the first order month | Cohort members first cancelling | Cumulative | Share of the 96 who ever cancel |
|---|---|---|---|
| 1 | 13 | 13 | 13.54% |
| 2 | 19 | 32 | 33.33% |
| **3** | 13 | **45** | **46.88%** |
| 4 | 20 | 65 | 67.71% |
| 5 | 14 | 79 | 82.29% |
| **6** | 13 | **92** | **95.83%** |
| 7 to 8 | 4 | 96 | 100.00% |

**In dollars, at the 20 percent rate, on the 269 cohort.** Of the 5,940.00 paid, **2,230.00
attaches to an enrollment whose subscription eventually cancels**, which is 37.54 percent of
every dollar paid.

| Recovery window | Amount recovered | Share of the 2,230.00 at risk |
|---|---|---|
| Three months, as recommended | **1,040.00** | 46.64% |
| Six months | **2,150.00** | 96.41% |

Six months recovers **1,110.00 more over five months** than three months does, more than
doubling the recovery. The general curve made the gap look like 37.91 against 64.84. On the
population the rule actually governs it is 46.64 against 96.41, and month four is the single
largest cancellation bucket, which the general curve does not show at all.

**Two honest caveats on my own number.** The cohort tail is right censored, because a member
whose first order was in July 2026 has had only one month to cancel. Censoring understates
the later months, so the true three month capture is lower than 46.88 percent, not higher.
And the March cohort alone, which has five months of observation, gives 7 of 18 cancellers
caught at three months, which is 38.9 percent, consistent with the censored picture.

**I am not overturning three months. I am overturning the argument for it.** Three months
remains defensible on the grounds the document gives second, that six months leaves a
sponsor's earnings reversible for half a year and a field will distrust that. But Howard
should choose knowing the cost of the choice is 1,110.00 of unrecovered money in five
measured months, not the smaller gap the general curve implies.

### MEDIUM 4. Section 9.2 is headed "the measured cost of exactly those terms" and it is not the cost of those terms

Section 9.1 term 4 is an amendment: the basis becomes the new member's own purchase, retail
customer volume excluded. Section 9.2 then prices terms 3, 7, 8 and 9 on total first month
Sales Volume, which includes retail customer volume. So the recommended package and the
headline cost figure are two different policies.

The document discloses this twice, in section 8.3 and section 11, which is why this is MEDIUM
rather than HIGH. But the section heading claims the opposite of what the section does, the
commit message repeats 5,940.00 as the cost of the package, and the disclosure asks a reader
to hold a caveat across forty pages.

**I computed the number the document declined to compute.** Restricting the basis to the new
member's own purchases, `buyer_role = 'member'`, with every other gate unchanged:

| | Document's basis, total first month Sales Volume | Tightened basis, own purchases only |
|---|---|---|
| Qualifying enrollments | 269 | **265** |
| Basis before the cap | 31,400.00 | **26,450.00** |
| Capped basis | 29,700.00 | **25,800.00** |
| Cost at 20 percent | 5,940.00 | **5,160.00** |
| Cost at 10 percent | 2,970.00 | **2,580.00** |
| Combined share of revenue at 20 percent | 12.7133% | **12.6018%** |

I ran this two ways, once holding the event definition fixed and restricting only the basis,
and once redefining the event on the member's own orders. **Both give the identical answer**,
265 enrollments and 5,160.00, which is a useful sign that the tightening is unambiguous. The
document's directional claim, that the tightened figures "will be lower, not higher", is
CONFIRMED. The reduction is 780.00 over five months, 13.13 percent of the cost.

### LOW 5. The load bearing sentence "an order carries exactly one product line" is not true

`app.orders` holds 10,351 rows and `app.order_lines` holds 10,353. Two orders carry more than
one line, and the maximum line quantity is 3, not 1. Both multi line orders are in August
2026, so **no figure in the document is affected**, because every amount was computed by
summing line values rather than by assuming one line per order. But the sentence is the
explanation given for the whole 457 against 284 correction, and it should say "in the March to
July window every order carries exactly one line" rather than stating it as a property of the
database.

### LOW 6. A first ever order now exists in August 2026 through the live bridge

Section 11 says "On today's real live traffic this incentive would pay exactly 0.00" and
attributes it to no member having ever enrolled through the live site. The conclusion is
correct and I verified it. The evidence has moved, though: member GW-000007 placed their
first ever completed order on 2026-08-17, 100.00, carrying `demo_order_id` 241. It pays
nothing only because that member enrolled on 2024-08-10 and so fails the 30 day window, not
because no first order exists. The claim is now one gate thin rather than structurally empty,
and it should be restated before it goes stale.

### LOW 7. The gate and the clawback trigger read two tables that disagree

Term 4 gates on `app.order_lines.billing_mode`, and term 14 triggers recovery on a
subscription cancellation, which lives in `app.subscriptions`. Four of the 269 cohort members
have first month order lines marked `billing_mode = 'sub'` and no row at all in
`app.subscriptions`. Under the written terms those four would qualify for the payout and could
never trigger the cancellation clawback. Whoever builds this must pick one source of truth for
"is subscribed" and use it in both places.

---

## 3. Rulings on the four recommended amendments

| Amendment | Ruling | Why |
|---|---|---|
| **Term 4.** The qualifying order must be the new member's own purchase and carry a subscription line | **SAFE, and adopt it.** | It closes the four person hole where a sponsor is paid for a sale the new member did not make, it is what "enrolled in subscription software" actually means, and it costs 780.00 less over five months, which I measured at 5,160.00. The subscription line half is vacuous today, which is fine: a gate that binds on nothing now and binds correctly later is worth writing. **One condition: the brochure wording must be corrected to match it.** See HIGH 2. |
| **Term 8.** The three per sponsor cap resolved by earliest order date, tie broken by member id | **SAFE. Adopt it exactly as written.** | Deterministic, verified by me producing 269 on the first attempt from the written rule. The engineer's reasoning is right: any rule that keeps the largest three pays a sponsor to hold small enrollments back to the next month. Earliest first is also the only rule that can be applied at the instant the payment succeeds, which the mechanism requires. |
| **Term 9.** The sponsor purchase gate pinned on or before the recruit's order date, same day counting | **SAFE but it is a LOOSENING, not a clarification, and Howard must approve it as one.** | It is the only reading knowable at the instant, so it is the right rule for an instant payout. But against the prior month reading that document 10 most likely used it adds 43 events and 1,050.00 over five months, which is 21.5 percent more cost. Same day counting also means a sponsor with no history can buy one 50.00 agent that morning and qualify immediately. That is not a profitable route on the sponsor's own money, since every fake enrollment loses them 40.00, but it is a route, and it is the shell account door the gate was written to close. Approve it as a policy change with a price attached, not as a wording fix. |
| **Term 14.** Recovery over three complete calendar months, triggered by refund, chargeback or subscription cancellation, full and not prorated | **The trigger set is SAFE and correct. Full not prorated is SAFE and correct. THE WINDOW IS TOO SHORT, and the document's own concern is the reason.** | See MEDIUM 3. On the cohort the rule actually governs, three months recovers 1,040.00 of the 2,230.00 at risk and six months recovers 2,150.00. Month four is the largest cancellation bucket. And Howard's premise cuts the wrong way here: the cheaper subscription churns harder at 26.35 against 17.55 percent, and the 50.00 enrollment is 41.64 percent of the cohort, so the biggest block of exposure sits on the hardest churning product. **My recommendation is four months, not three and not six.** Four captures 67.71 percent of cohort cancellers against 46.88 at three, it clears the month four spike, and it is still a sentence a sponsor can be told and believe. **Second amendment: run the window from the qualifying order date, not from the enrollment month.** Under "enrollment month" a member who enrolls on the 1st and one who enrolls on the 30th get materially different protection for the same money. The order date is the date the money left, and it is unambiguous. |

---

## 4. Ruling on the tier table honesty question

**Question.** Is it honest to publish a flat 20 percent of price as a tier table?

**Ruling. It is honest only under conditions, and the table as drafted does not meet them.**

A tier table is, by universal convention, a table of **thresholds**. A reader who sees rows at
50, 100, 150, 200 will draw two inferences without being told, and both are false here:

1. **That the rows are bands.** A 175.00 first order looks like it lands in the 150 row and
   pays 30.00. It actually pays 35.00. The table understates every value between rungs.
2. **That crossing a rung earns a jump.** The whole argument for choosing the flat rate over
   Howard's ladder is that steps create a cliff and a 25 percent marginal bounty on talking a
   newcomer into one more agent. **Publishing the flat rate in the shape of a ladder
   re-creates that belief in the field even though the underlying rule does not have it.** The
   sponsor's behaviour follows what they believe the plan pays, not what it pays.

The second inference is the serious one, and it is a self inflicted wound: the document
correctly diagnoses the cliff as the reason to reject rungs, and then draws rungs.

**What the published table must say to be truthful.** Seven requirements. All seven, not a
selection.

1. **The rule goes above the table, not below it.** "You earn twenty percent of your new
   member's first purchase, paid the day the payment clears." The reader must meet the rule
   before they meet the rows.
2. **The left column is headed "Example first purchase", never "Tier", "Level", "Band", or a
   range like "100 to 199".** Each row is an exact amount, an illustration of one rule, not a
   bracket.
3. **One row must be an in between value, and it must be worked.** Add a row for 175.00
   paying 35.00. A single such row destroys the band reading faster than a paragraph.
4. **A line stating the continuity in plain words.** "Every amount in between pays twenty
   percent of it too. There are no steps and nothing to cross."
5. **The cap must be labelled as a cap, because it is the one place the rule really is flat.**
   "The most any single first purchase can pay is 50.00, which is reached at 250.00."
6. **The basis must match term 4.** "Your new member's own purchase." Not "their first order",
   which includes volume the new member did not buy and would overpromise on 49 of 269 real
   enrollments.
7. **Both limits appear on the same page as the payout.** The three per sponsor per calendar
   month cap, and the recovery clause in one sentence: the amount is returned if the order is
   refunded or charged back, or if the subscription cancels inside the window.

The words "tier", "rung", "level" and "bonus" must not appear anywhere near it. Under those
seven conditions a table of worked examples is honest and is genuinely the visible ladder
Howard wants. As drafted, with a rule sentence underneath, no in between row, the wrong basis
and no limits, it is not.

---

## 5. Ruling on the rate

**The engineer recommends 20 percent with 10 percent as a fallback, and claims both fit and
both cover every enrollment. I confirm the coverage claim without reservation and I confirm
the fit claim only for the steady state.**

Coverage: **both rates pay on 269 of 269 real enrollments, 100 percent, and they do so by
construction rather than by tuning.** A percentage of a positive price is positive. That is a
genuine structural property and it is the strongest argument in the whole document. Confirmed.

Fit: **20 percent fits the five measured months with 7.29 points spare, and misses the ceiling
by 6.62 points in a launch shaped month. 10 percent fits both, the second with 0.99 points to
spare.**

**MY RECOMMENDATION: keep 20 percent, but only if it is approved together with a written
launch phase guardrail. Without that guardrail, adopt 10 percent.**

Why I do not simply endorse 20 percent. The engineer's four reasons for it are all sound: it
is already approved, it is the only candidate that pays 10.00 rather than 5.00 on the 41.64
percent of enrollments that are 50.00, it is closer to Howard's own numbers than it looks, and
it is self limiting against a farmer using their own money. Every one of those survives my
checking. But all four are arguments about the size of the payment, and none is an argument
about the ceiling, and the ceiling is the only constraint Howard actually named.

Why I do not simply recommend 10 percent. It halves the payment on the most common enrollment
to 5.00, and the document's point that 5.00 is too small to feel like an event is a real one.
Buying that safety with the mechanism's whole purpose is a bad trade if a cheaper guardrail
exists, and one does.

**The guardrail I recommend, stated so it can be written as a term.** Total Instant Payout in
any calendar month may not exceed 8 percent of that month's revenue. Anything above the cap is
deferred to the following month rather than forfeited, so no sponsor loses money and the
company's monthly exposure is bounded. On the five measured months this binds on nothing at
all: the largest month, July 2026, spends 1.0547 percent of revenue. On a February shaped
month it holds the combined figure at 19.40 percent instead of 26.62 percent. **It costs
nothing today and it is the only thing standing between the approved rate and the one month
shape in this database that breaks the plan.**

**THE RISK THAT WOULD CHANGE MY ANSWER, named as asked: the capped first order share of
revenue.** It is 4.2456 percent today across five months and it was 76.1130 percent in
February 2026. The rate the ceiling can carry is `headroom / that share`. Above roughly 40.68
percent, 20 percent breaks the ceiling. Above roughly 81.36 percent, 10 percent breaks it. If
that share rises past 40 percent in any month, the rate must come down or the guardrail must
bind. **That single ratio should be a monitored number from the day this switches on, and it
is the number to put on the dashboard, not the cost.**

---

## 6. Gate

| Gate | Result |
|---|---|
| **Arithmetic verification** | **PASS.** 47 of 47 claims recomputed independently and reproduced exactly. No arithmetic error found. |
| **Publication gate** | **FAIL.** 2 HIGH, 2 MEDIUM, 3 LOW. Not ready for a public compensation page or for a decision that quotes 5,940.00 as the cost of the section 9.1 package. |

**What must happen before this document is quoted to anyone.**

1. Add the launch phase ceiling test, with the February 2026 figures, and either adopt the
   monthly guardrail or record Howard's explicit decision to accept an over ceiling launch
   spend. (HIGH 1)
2. Rewrite the brochure table against the seven conditions in section 4 above, correcting the
   basis to the new member's own purchase and adding both limits. (HIGH 2)
3. Re-argue the recovery window against the cohort curve, and consider four months from the
   qualifying order date. (MEDIUM 3)
4. Retitle section 9.2 and publish the tightened cost of 5,160.00 beside the 5,940.00, so the
   recommended package and its price are the same policy. (MEDIUM 4)
5. Send `DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md` term 8 back for rewriting. Its 234 is
   unreproducible under seven readings, not four. The document's recommendation on this point
   is correct and should be actioned.

**What I am recording as verified and reusable.** The 284 over 457 correction, the 19.01
percent at 200.00 or above, the 41.64 percent coverage gap, the 269 event cohort with its
29,700.00 capped basis, the 5,940.00 and 2,970.00 and 2,207.50 and 2,767.50 costs, the whole
monthly ceiling table, the churn reversal, the vacuous subscription gate, and the
unreproducibility of document 10's 234. Every one of those is now independently confirmed and
can be quoted with my name behind it.

**Nothing was written, changed, migrated or deployed by this verification. Read only
throughout.**
