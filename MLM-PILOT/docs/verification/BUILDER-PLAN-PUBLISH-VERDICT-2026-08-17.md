# Builder Plan Publish Verdict, 2026-08-17

Grader: mlm-verifier, the independent gate. I built none of this. Commit graded:
`041d79d`, "The Builder plan, published: part two on the page, and a brief that
stands alone".

Acronym key: Sales Volume (SV), Commissionable Volume (CV), Personal Volume (PV),
Team Volume (TV), Multi-Level Marketing (MLM), Quality Assurance (QA),
Structured Query Language (SQL), Portable Document Format (PDF).

## GATE: FAIL

One HIGH and four MEDIUM findings. Nothing I found breaks the arithmetic: every
figure I recomputed from the database or by hand reproduced to the cent or to the
displayed precision, and the false money claim that was caught during the build is
genuinely gone from both files. The FAIL is for one status misstatement inside the
honesty band itself, and for three number-framing defects that move in the
FLATTERING direction and that the professional reader Howard is sending this to
will find with one query. Per my hard rule I report FAIL rather than pass
something nearly right.

**DEPLOY: NO.** Six line-level edits clear every blocking finding. None of them
is a redesign and none touches a mechanism.

## Artifacts graded

| Artifact | SHA-256 |
|---|---|
| `MLM-PILOT\www\comp-plan.html` | `2f59567110461e86c51fe8e24338e94eb22d4f9ee5577fd671849c97a79110e2` |
| `DOCUMENTATION\ORVANNA-BUILDER-PLAN-BRIEF.html` | `e5190a35f7d2d43095e7df1be9e79311f035b8fb106716a3d55c059081c8f8ee` |
| `MLM-PILOT\docs\ORVANNA-BUILDER-PLAN-SPEC.md` (v1.2.1, reference) | `907b26f3b5581d43db1df855c7caccb3d575502e0a21e040e3d616e09b24815c` |

Database read directly: project `oiyibdczkokegaxkwulv`, schemas `app` and `lab`.
Census figures recomputed against lab run 86 (`orvanna_builder`, seeded March
2026, calibrated rates gen1 0.015 / gen2 0.010 / second_leg 0.020) and lab run 15
(`unilevel_v13`, same month).

---

## FINDINGS

### HIGH-1. The status band puts a MODELLED section inside "Operating today"

`comp-plan.html`, section `#status`, both panels, four occurrences across two
headings and two paragraphs:

- "Part one, sections one to fifteen" (heading and body)
- "Part two, sections sixteen to twenty-four" (heading and body)

**Recomputed from the page's own section kickers.** Part one's numbered sections
run: Section one, two, three, four, five, six, then four sections carrying the
kickers "Earning one" through "Earning four" instead of numbers, then Section
eleven, twelve, thirteen, and **Section fourteen, "What version 1.3 does not
do"**. That is the last section of part one. The first section under the
`Part two, the Builder plan, modelled` rule is **Section fifteen, "The Builder
plan in one view"**, which is modelled. Counted independently in the rendered
document object model: 26 `section.band` elements, of which 14 are part one's
numbered sections.

| Claimed by the status band | Measured on the page |
|---|---|
| Part one = sections one to fifteen | Part one = sections one to **fourteen** |
| Part two = sections sixteen to twenty-four | Part two = sections **fifteen** to twenty-four |

**Why this is HIGH and not cosmetic.** The status band exists for exactly one
purpose: telling a reader which parts run and which do not. As printed it assigns
Section fifteen, the overview of the two modelled layers, to the panel headed
"Operating today", and it does so in the first minute of the document, to a reader
whose profession is catching precisely this. It is a false statement about what is
live.

**Mitigation, stated fairly:** Section fifteen sits under a visible
"Part two, the Builder plan, modelled" rule, and every mention of layers 2 and 3
on it carries a modelled label, so a reader navigating by part name is not misled.
Only a reader navigating by number is.

**Fix:** "fifteen" to "fourteen" and "sixteen" to "fifteen", four occurrences.

### MEDIUM-1. "Order" printed where the engine's unit is SOURCE MEMBER-MONTH

Both artifacts systematically substitute "order" for the spec's source unit:

- page and brief: "Every order contributes a pool equal to 25 percent of its Commissionable Volume"
- page: "120 of 1,001 orders reach their cap, about 12 percent, roughly one order in eight"
- page: "Across 1,001 modelled orders, zero exceeded the cap"
- page: "the worst real order carries override claims at 0.56 of its pool, and zero of 1,001 orders paid over pool"
- brief: "Orders that reach their cap: 120 of 1,001"; "120 of the 1,001 modelled orders have a binding pool"

The specification, section 7, is unambiguous: "Every **source member-month** s
contributes a pool of pool_rate x CV(s)". The section 10 fixture's sources are the
ten members M1 to M10, not ten orders. The proof run says "1,001 **sources**".

**Recomputed against the database, seeded March 2026:**

| Quantity | Claimed | Measured |
|---|---|---|
| Denominator called "orders" | 1,001 | 1,001 **source member-months** (the census member count) |
| Actual orders in the volume month | (implied 1,001) | **1,462** |
| Distinct buying members | not stated | **641** |
| Members placing more than one order | not stated | **357 of 641, 56 percent** |
| Orders belonging to a multi-order member | not stated | **1,178 of 1,462, 81 percent** |

Two consequences. First, the denominator is checkable and wrong: a reader who
asks how many orders March held gets 1,462, and "of 1,001" collapses. Second, the
promise "no order ever pays more than 20 percent of its price" is enforced per
member-month, not per order. In aggregate over a member's month the 20 percent
ceiling holds exactly, and I verified zero violations across all 1,001 sources;
but inside a bound month one order can carry the whole pool while another carries
none, and 81 percent of March's orders sit in multi-order months. The ceiling is
intact. The unit and the count are not.

### MEDIUM-2. The proration frequency is understated by a third

Both artifacts print "120 of 1,001 ... about 12 percent, roughly one in eight" for
how often the ceiling bites.

**Recomputed from run 86's per-source waterfall traces:**

| Quantity | Claimed | Measured |
|---|---|---|
| Sources with layer 2 factor below 1 | 120 | **120** (exact) |
| Sources with layer 3 factor below 1 | (not printed) | **83** |
| Sources prorated on **at least one** layer | 120 | **154** |
| Sources with any pool at all (non-zero CV) | (implied 1,001) | **641** |
| Prorated share of sources that can bind | "about 12 percent, one in eight" | **154 of 641 = 24.0 percent, roughly one in four** |
| Shaved, layer 2 | 638.00 | **638.00** (exact) |
| Shaved, layer 3 | 305.68 | **305.68** (exact) |
| Cap violations | zero | **zero** (exact) |

The 120 figure is the count of sources whose LAYER 2 factor binds; 34 further
sources bind only at layer 3. Both the 1,001 denominator (which includes 360
sources with zero volume that can never bind) and the 120 numerator run in the
same direction, and that direction flatters the plan. This defect is inherited
from specification 12A(e) and red-team attack 4, which both say "120 of 1,001
sources prorate"; per my brief the specification is not automatically right, and
here it is not. It sits in the one paragraph whose declared job is to state the
exposure without softening.

### MEDIUM-3. The worst-member haircut is quoted against a denominator that cannot be cut

Both artifacts: "The worst ratio is 21 percent of that Conductor's claims."

**Recomputed.** That figure reproduces exactly, and only, when "claims" includes
the spine, which by construction is never prorated:

| Basis | Worst member | Measured ratio |
|---|---|---|
| Shaved / (spine + structure claims) | member 44: 19.24 shaved of 91.80 | **20.96 percent**, the printed 21 |
| Shaved / structure claims only | member 44: 19.24 of 55.80 | **34.5 percent** |
| Shaved / structure claims only, worst in the census | five members | **100 percent** (structure claims of 1.60 to 5.52 prorated entirely away) |

The sentence is defensible on its literal wording. It is also the more flattering
of two available readings, printed in the paragraph that legislates statement
exactness, immediately before an example (the 0.17 line, a 93 percent cut) that
contradicts the impression the 21 leaves.

### MEDIUM-4. The "24" companion is described with the qualification condition dropped

Page: "24 Conductors in the modelled population of 1,001 hold that position today,
meaning they personally sponsored at least one Builder."
Brief: "24 of 1,001 members hold that position: at least one Builder".

**Recomputed:**

| Quantity | Measured |
|---|---|
| Census members who personally sponsored at least one Builder in March | **34** |
| Of those, QUALIFIED that month (SV at least 100.00) | **24** (8 + 8 + 8 across the three bands) |

The banded premium table is right to use 24, because unqualified members cannot
earn and do not belong in an earnings comparison. The sentence describing the
number is what is wrong: it omits "and were qualified that month". Release
condition 3 makes this companion mandatory in the same breath as the multiples,
so it has to be exact. Fix is four words.

### LOW-1. Stale specification version stamp in the brief's source table

`ORVANNA-BUILDER-PLAN-BRIEF.html` line 1372: "Rates of record, multipliers, pool
rate | Orvanna Builder plan specification, **version 1.2**, section 5". The
specification is at 1.2.1, and the next row of the same table correctly cites
1.2.1. Section 5's parameters are unchanged between the two releases, so every
figure sourced to it is right; only the stamp is stale.

### LOW-2. The five-family comparison sits behind a disclosure control

`comp-plan.html` wraps "How this plan compares to four other plan families" in a
`<details>` element. The reach-refuting numbers themselves (206 against 207
against 448, Gini 0.9625 against 0.9687, top-ten share 94.25 against 95.33) are
all stated in open prose in "What this plan does NOT do", so release condition 1
is satisfied. But the full table a hostile reader will want is one click away
while the drift table directly above it is not. This is the only `<details>` in
part two.

### LOW-3. Recorded so it is not rediscovered

The red-team review prints GW-000044's generation 1 line as "claim 33.00 paid
22.47". The engine line is **22.46** (claim 33.0000, basis 2,200.00, rate 0.0150).
Neither artifact prints it, so this is not an artifact defect.

---

## WHAT I RECOMPUTED AND CONFIRMED

Every figure below was computed by me from the database or by hand from the
specification. Where I write "exact" the recomputed value equalled the published
value with no rounding slack.

### The layer 1 equality claim: CONFIRMED EXACT

Symmetric set difference of run 15's lines against run 86's
`builder_spine_level_pay` lines on (earner, source, level, basis, rate, amount),
both directions:

| Measure | Claimed | Measured |
|---|---|---|
| Lines | 1,630 | **1,630** |
| Total | 13,434.00 | **13,434.00** |
| Rows in unilevel not in builder | 0 | **0** |
| Rows in builder not in unilevel | 0 | **0** |

The production March run (`app.commission_runs` id 8, specification v1.3, final)
also totals 13,434.00 with 206 members paid, so the live plan, the lab baseline,
and the Builder plan's spine all agree.

### The status claim: CONFIRMED, both counts, directly against the database

| Claim | Measured |
|---|---|
| Twelve production commission runs | `app.commission_runs` count = **12** |
| On specification 1.2 and 1.3 | **6 on v1.2 (status superseded), 6 on v1.3 (status final)**; no other version exists |
| Across February to July 2026 | periods 2026-02 through 2026-07, two runs per month |
| "Those runs produced statements" | `app.run_member_results` holds **12,000 rows across 12 distinct runs**; `app.commission_lines` holds 22,076 rows |
| `orvanna_builder` laboratory runs | `lab.plan_runs` count = **29** |
| `orvanna_builder` live runs = zero | The `app` schema has **no plan_code column and no `orvanna_builder` row anywhere**; the plan exists only in `lab` |

### The money claim: NO SURVIVING FORM

I swept both files for every construction that could assert funds reached a
person: "real money paid", "money has been paid", "paid out real money", "funds
moved", "actually paid to", "received a payment", "paid to members / people /
anyone", "paid one dollar", "paid any amount", "has paid". Every hit is a
**negation**:

- page `#status`: "has never been the live plan, has never produced a statement, and has never paid one dollar to one person"
- page footer: "has never paid any amount to any person"
- page cover: "No real money moves at any point"
- brief status: "No money has been paid to anyone, by either plan"
- brief figure 1 description: "Neither has paid money to anyone: Orvanna is a demonstration company and no funds move at any point in the system"

Every remaining use of "paid" is arithmetic inside a modelled run ("the order pays
14.80", "207 members paid"), and the demonstration status is stated on the cover,
in the status band, and in the footer. The claim caught during the build is gone
and nothing equivalent survives.

### The development premium: CONFIRMED EXACT, independently derived

I rebuilt metric 2 from raw data: builder flags from `plan_metrics`, sponsorship
from `lab.derived_members`, banding by SV, means over qualified members.

| SV band | With a sponsored Builder | With none | Multiple claimed | Multiple measured |
|---|---|---|---|---|
| 100.00 to 149.99 | **52.47** (n = 8) | **6.66** (n = 141) | 7.9 times | **7.878** |
| 150.00 to 299.99 | **725.57** (n = 8) | **7.90** (n = 186) | 92 times | **91.84** |
| 300.00 and above | **955.31** (n = 8) | **11.77** (n = 97) | 81 times | **81.16** |

**The top band is 81, not 92. The premium is not monotone.** The claim is
correctly printed as three separate multiples in band order in both artifacts. The
sentence "up to 92 times at the top" appears nowhere in either file.

### The companions: CONFIRMED

| Companion | Claimed | Measured |
|---|---|---|
| Members earning any structure money | 44 | **44** |
| Structure budget | 3,983.12 | **3,983.12** |
| Top five of the 44 | 3,590.97 | **3,590.97** |
| Top five share | 90.2 percent | **90.15 percent** |
| Top ten share | 94.2 percent | **94.17 percent** |
| Structure-linked share | 22.9 percent | **22.869 percent** (3,983.12 of 17,417.12) |
| Members with at least one shaved line | 35 of 207 | **35 of 207** |
| Worst member shaved | 324.14 | **324.14** |
| Total shaved | 943.68 | **943.68** (638.00 + 305.68) |

Line composition of run 86: 1,630 spine lines 13,434.00, 45 generation 1 lines
2,666.75, 42 generation 2 lines 948.88, 29 bonus lines 367.49.

### The Law A exhibit: CONFIRMED, hand-recomputed from the specification

Four members at SV 100.00 / CV 80.00, A sponsors B, B sponsors C and D, calibrated
rates of record.

| Member | Month one, recomputed | Month two, recomputed | Change |
|---|---|---|---|
| A | 8.00 level pay (level 1 on B, paid depth 1) + generation 1 override 0.015 x 240.00 = **3.60** = 11.60 | 8.00, no Builder below | **-3.60** |
| B | 16.00 level pay (8.00 on C + 8.00 on D) + bonus 0.020 x 80.00 = **1.60** = 17.60 | 8.00, one active leg, ineligible | **-9.60** |

I also checked the waterfall clears at every source so no proration touches the
exhibit: source D takes spine 8.00 + override claim 1.20 + bonus claim 1.60 =
10.80 against a pool of 20.00; sources B and C take 9.20 each. Every figure the
artifacts print for this exhibit is right, and the decomposition they print for B
(8.00 of lost level pay plus the 1.60 bonus) is right.

### The draft-rate correction: CONFIRMED, and the distinction holds

| Quantity | Occurrences in `comp-plan.html` | Occurrences in the brief | Verdict |
|---|---|---|---|
| 9.60 | **1** | **1** | Both are member B's TOTAL month-over-month change, printed with its decomposition "8.00 of lost level pay on C plus the 1.60 bonus". Legitimate survival. |
| 4.00 as a Law A bonus quantity | **0** | **0** | Correct. |
| 4.00, other uses | level 2 rate of record `0.05 x 80.00 = 4.00`; the range "-4.00 to -12.40" in the GW-000294 exhibit | same | Legitimate rate-of-record quantities. |
| 0.18 | **0** as a figure (one hit is a CSS alpha value `rgba(...,0.18)`) | 0 | Correct. |
| 0.17 | 1 | 2 | Correct, and verified against the engine: GW-000044's bonus line is rate 0.0200, basis 120.00, **amount 0.17**, rate times basis 2.4000, a 92.9 percent cut. |

Both files also carry an explicit rate note explaining that the acceptance fixture
is recorded at draft rates and that the exhibit restates it at the rates of
record.

### The attack table: CONFIRMED EXACT, twice over

Hand-derived from the specification first, then checked against lab runs 95, 96,
97 (attacker is earner 1 in each).

| Arrangement | Level pay | Overrides | Bonus | Attacker total | Company |
|---|---|---|---|---|---|
| K2, two legs nested | 32.00 | 7.20 | 4.80 | **44.00** | **79.20** |
| K3, three legs | 36.00 | 0.00 | 3.68 | **39.68** | **63.68** |
| K6, six flat | 48.00 | 0.00 | 2.00 | **50.00** | **50.00** |

Hand check: K6 level pay = 6 x 0.10 x 80.00 = 48.00; bonus = 0.020 x 1.25 x 80.00
= 2.00. K3 level pay = 3 x 8.00 + 3 x 4.00 = 36.00; bonus = 0.020 x 1.15 x 160.00
= 3.68. K2 level pay = 2 x 8.00 + 4 x 4.00 = 32.00; overrides = 2 x 0.015 x 240.00
= 7.20; bonus = 0.020 x 1.00 x 240.00 = 4.80. Structure income 12.00 / 3.68 / 2.00
as printed in D10 is also right.

### The waterfall worked example: CONFIRMED

8.00 (level 1) + 4.00 (level 2) + 1.20 (generation 1 override, 0.015 x 80.00) +
1.60 (bonus, 0.020 x 80.00) = **14.80 of a 20.00 pool, 5.20 unspent**. Matches
specification 12A(d) at the rates of record. The binding case printed beside it
(pool 10.00, spine 8.00, override 1.60, bonus claimed 2.00 paid 0.40 at factor
0.200000, total exactly 10.00) matches section 10's M10 row and is correctly
labelled as recorded at draft rates.

### The drift trajectory: CONFIRMED EXACT, all six months

Recomputed as total_payout / total_cv per lab run.

| Month | Run | CV | Payout | Percent of CV, claimed and measured | Members paid |
|---|---|---|---|---|---|
| February | 106 | 83,560.00 | 15,508.27 | **18.5594** | 180 |
| March | 86 | 91,960.00 | 17,417.12 | **18.9399** | 207 |
| April | 107 | 99,680.00 | 19,061.18 | **19.1224** | 228 |
| May | 108 | 111,160.00 | 21,610.86 | **19.4412** | 249 |
| June | 109 | 118,800.00 | 23,217.51 | **19.5434** | 262 |
| July | 110 | 138,040.00 | 27,167.87 | **19.6812** | 285 |

Rise 19.6812 - 18.5594 = **1.1218 points over five month-steps, 0.224 a month**,
as printed. August (run 111: CV 1,600.00, payout 166.00, 2 members paid) is
excluded from both artifacts by name, correctly.

---

## THE RED-TEAM RELEASE CONDITIONS

| Condition | Verdict | Evidence |
|---|---|---|
| "wide reach" appears zero times | **PASS** | Zero occurrences in either file. Every "reach" hit is ordinary usage (paid depth, reaching a cap). Both artifacts state the opposite claim explicitly: "the same paid population, a far deeper premium on development" and "Anybody describing this plan as broadening participation is describing a different plan", with 206 / 207 / 448, Gini and top-ten share printed in the open. |
| Three multiples printed separately, never as a range | **PASS** | Both artifacts print 7.9, 92, 81 as three rows in band order. The brief adds "The premium is not a rising ladder. The biggest multiple is the MIDDLE band at 92 times. The top band is 81 times." No range form survives. |
| "Up to 92 times at the top" | **PASS** | Zero occurrences. Confirmed false by measurement: top band is 81.16. |
| Always with participation companions | **PASS with MEDIUM-4** | 24 / 44 / 90.2 / 94.2 are printed adjacent to the multiples in both artifacts, and inside the figure strip on the page. The 24 is described imprecisely, see MEDIUM-4. |
| 22.9 never shown alone | **PASS** | Both artifacts attach the caveat in the same paragraph. |
| GW-000294 exhibit beside the tidy fixture at equal visual weight | **PASS** | Page: one `<figure>`, left frame `x=20 y=26 w=410 h=330`, right frame `x=450 y=26 w=410 h=330`, identical; baselines both 372px long at y=300; bar scale **11.0 pixels per dollar on both sides** (8.00 to 88px, 3.60 to 39.6px, 17.60 to 193.6px, 7.80 to 85.8px). Brief: CSS grid `1fr 1fr`, identical 2px borders, `flex:1` bodies so both panels stretch equal. |
| Not hidden behind a disclosure control | **PASS** | Neither exhibit is inside a `<details>`. The only `<details>` in part two holds the plan-family comparison table, see LOW-2. Zero `<details>` in the brief. |
| 6A lapse-benefit inversion disclosed with its bounds | **PASS** | Both artifacts carry the full nineteen-member table (E +7.44, B1 to B3 +3.04, B4 +0.85, B5 -11.29, B6 -17.00, B7 -25.89, B8 +0.40, company -36.37), the factor 0.526315 to 1, the 19.999996 / 20.000000 microcent check, the bonus rising 10.60 to 15.00 on a basis falling 1,360.00 to 1,280.00, and all three bounds (cannot be farmed, never new money, near generations still lose most), plus the 120-source live-in-any-month statement and the standing metric. |

## D9 AND D10

| Requirement | Verdict | Evidence |
|---|---|---|
| D9 carries only attacks that cost cash | **PASS** | D9 ("What each attack cost and what it returned") holds exactly three rows: fund a fake Builder 300.00 for 21.20, fund an artificial second leg 100.00 for 2.00, buy rank 10,000.00 for 0.00. Caption: "Only the attacks that cost real money." |
| D9 must not imply the plan punishes leg-splitting | **PASS** | D9 carries an explicit exclusion note: "Splitting recruits across more legs is deliberately absent here: it costs the attacker nothing, so it does not belong on a money-spent chart. It is drawn on its own terms in the next figure." |
| D10 carries leg-splitting | **PASS** | D10 ("The rate step rises while the payment falls") holds the three arrangements with rate step 2.0 / 2.3 / 2.5, bonus paid 4.80 / 3.68 / 2.00, overrides 7.20 / 0.00 / 0.00, structure income 12.00 / 3.68 / 2.00. |
| Honesty strip printing 44.00 / 39.68 / 50.00 INSIDE the figure | **PASS** | The three totals and the sentence "The part that is not a defense: the flat, undeveloped shape pays the attacker MOST, because the 10 percent frontline rate beats every development rate in this plan" are `<text>` elements **inside the `<svg>`**, above `</svg>`, not in the caption. 50.00 carries the inline label "the highest of the three". |
| States the flat undeveloped shape pays the attacker most | **PASS** | Stated inside the figure, again in the body prose, and again in the brief under "The uncomfortable finding from the same test, published rather than buried". |

## DOES THE PAGE OVERSTATE THE PLAN'S DEFENCES ANYWHERE ELSE?

Ruling: **not in its mechanism claims; yes in three number framings.**

Every defensive claim I tested reproduced. Splitting strictly loses bonus and
forfeits overrides (measured). Sandbagging strictly loses (38.40 to 21.60,
measured, and the second-order-statistic argument is sound). Funding a Builder
returns 7.07 cents on the dollar (measured). Ten thousand dollars of own volume
earns 0.00 at rank Member (measured). Zero self-source lines, zero recruitment
lines, four reason codes, zero cap violations across 1,001 sources (all
re-verified by my own query, not read from the trace tables). The page also
volunteers three things it did not have to: that the attacker's own optimum is the
flat undeveloped shape, that the plan pays one more person rather than more people,
and that the retention-agent claim broke.

The overstatement is confined to how three numbers are framed, and all three lean
the same way: MEDIUM-2 makes the ceiling look like it bites half as often as it
does, MEDIUM-3 makes the worst haircut look a third the size it is against the
claims that can actually be cut, and MEDIUM-1 makes a member-month statistic read
as an order statistic. None changes a mechanism. All three are what the reader
Howard is sending this to will test first.

## CHROME CONTRACT

**PASS.** `py deploy\build_dist.py` run clean:

- stamp assertion: every local reference carries `?v=`
- **nav drift lint**: 9 corporate pages match `_partials/nav.html`
- **theme boot lint**: 9 pages carry the canonical pre-paint snippet
- **chrome sheet lint**: 9 pages load `css/site-chrome.css`
- **chrome css lint**: chrome presentation declared only in `css/site-chrome.css`
- **page registry lint**: 13 root pages, all covered
- name lint, secret scan, currency mirror: pass
- Output: 38 files, 1304 KB, bundle SHA-256 `4df035cc767be8a8`

No chrome rule was added to the page. The diff to `comp-plan.html` is
**1,186 insertions, 5 deletions**; all five deletions are body copy (cover
subtitle, the demonstration note, a section comment, the glossary section tag,
the footer legal paragraph), and grep for `site-chrome`, `<nav`, `<header`,
`<footer`, `theme-boot` in the diff returns nothing.

Console and network on `comp-plan.html` served locally: **zero console messages**;
five requests, all local, all 200 (the document, `css/site-chrome.css?v=5.2`,
`js/site-chrome.js?v=1`, two logo SVG files).

## THE BRIEF SPECIFICALLY

| Requirement | Verdict | Evidence |
|---|---|---|
| Zero external references of any kind | **PASS** | Zero `<link>`, `<script>`, `<img>`, `<iframe>`, `<object>`, `<embed>`, `<video>`, `<audio>`, `<source>`, `<use>` elements. Zero `href`, `xlink:href`, `data-src`, `poster` attributes. Zero `@import`, zero `url(`, zero `http`/`https` strings, zero protocol-relative references. Two font stacks, both system: `"Segoe UI",system-ui,-apple-system,"Helvetica Neue",Arial,sans-serif` and `Consolas,"Courier New",monospace`. |
| Renders from the file system with no network | **PASS** | Rendered and printed headless from `file:///` with no network available. All ten figures are inline SVG. |
| One-page explanation fits one printed page | **PASS, on both paper sizes** | Printed headless. **US Letter** (MediaBox 612 x 792): "Part one: the whole plan on one page" occupies **page 3 alone**; page 4 opens "Part two: the evidence". **A4** (MediaBox 594.96 x 841.92): identical, page 3 alone. 16 pages total on Letter, 15 on A4. I did not verify the commit's 219.9mm-of-251.4mm measurement and do not restate it; the pagination is the proof. |
| Two-panel exhibit symmetric | **PASS** | `.exhibit{display:grid;grid-template-columns:1fr 1fr;gap:16px}` with `.exhibit > div{border:2px solid #0F172A;display:flex;flex-direction:column}` and `.exhibit .eb{flex:1}`: equal width by grid, equal height by flex stretch, identical borders and header bars. Both exhibits print on the **same page** (page 6) on Letter and on A4. |

## HOUSE STYLE AND PROJECT GUARDRAILS

| Check | Verdict |
|---|---|
| Em dashes (U+2014) | **0** in both files, including entity forms `&mdash;` and `&#8212;` |
| En dashes (U+2013) | **0** in both files, including `&ndash;` and `&#8211;` |
| Acronyms expanded on first use | **PASS**; both files carry an acronym key, the page in the header and footer, the brief in a dedicated block and repeated in the footer |
| Zero Unicity data or terminology | **PASS**; no occurrence found |
| Generic industry language | **PASS** |

---

## WHAT MUST CHANGE BEFORE DEPLOY

Six edits. None is a redesign.

1. **HIGH-1.** In `comp-plan.html` `#status`: "sections one to fifteen" to
   "sections one to fourteen" (heading and body), and "sections sixteen to
   twenty-four" to "sections fifteen to twenty-four" (heading and body).
2. **MEDIUM-1.** Replace "order" with the engine's unit wherever the count 1,001
   is attached, in both artifacts. The honest phrasing is "1,001 member-months of
   volume" or "1,001 modelled members' monthly orders". Keep "no order pays more
   than 20 percent of its price" as the promise; drop "1,001 orders" as the
   denominator, because March held 1,462 orders from 641 buying members.
3. **MEDIUM-2.** Either print 154 of 641 (24 percent, roughly one in four) as the
   proration frequency, or keep 120 and say precisely what it counts: "120 sources
   have their override layer reduced; 34 more are reduced only at the bonus layer".
   Amend specification 12A(e) the same day, since the defect originates there.
4. **MEDIUM-3.** State the worst haircut against the claims that can be cut, or
   print both: "21 percent of that member's total claims, 34.5 percent of the
   claims the ceiling can reach, and five members lost their entire structure
   claim".
5. **MEDIUM-4.** "24 ... who personally sponsored at least one Builder **and were
   qualified that month**"; 34 members sponsored a Builder in total.
6. **LOW-1.** Brief source table: "version 1.2, section 5" to "version 1.2.1,
   section 5".

Re-run both gates on the corrected artifacts. The mechanisms, the waterfall, the
walk, the calibration honesty, the inversion disclosure, D9 and D10, the chrome,
and the brief's self-containment all pass now and do not need re-litigating; a
targeted re-check of the six edits plus a fresh `build_dist.py` run is sufficient.

## GATE: FAIL. DEPLOY: NO.

Report only. I fixed nothing.
