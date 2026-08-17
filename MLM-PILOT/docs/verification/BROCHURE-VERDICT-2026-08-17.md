# Verdict: the illustrated compensation plan, and the document page class

**Graded by:** mlm-verifier (independent; built none of this)
**Date:** 2026-08-17
**Commit graded:** `afa6a3e1283f068877fa91c87e02fa186c12df5b`
**Bundle:** `www/plan-brochure.html` (new), `www/comp-plan.html` (at `b48803d`, never re-gated
or deployed, plus the new brochure link), `deploy/build_dist.py`, `docs/CORPORATE-CHROME-CONTRACT.md`.

## GATE: **FAIL**
## DEPLOY: **NO**

The arithmetic is right. I recomputed the worked month line by line and it reproduces to the
cent, and every craft measurement the commit claims reproduces when I measure it myself. The
failure is not in the numbers. It is that the page states the plan's central promise without
the exception that the page it links to, shipping in the same deploy, names; and that it
prints an effective date nobody ruled, on a page whose own text says it governs over every
other page. Both are small edits. Neither is safe to forward.

Acronym key: Personal Volume (PV), Sales Volume (SV), Commissionable Volume (CV), Team Volume
(TV), Cascading Style Sheets (CSS), Scalable Vector Graphics (SVG).

---

## 1. Artifacts graded, by hash

| SHA-256 | Bytes | File |
|---|---|---|
| `509cebbdb3435ff6e8d8403f81862ffcd57a6057853f875b338c77c3f23b72ca` | 182,236 | `MLM-PILOT/www/plan-brochure.html` |
| `3549d7f6a56ffeeea3f632c4462aefa9a0b1e3b38fae1dd6ee645759a9c29a1d` | 241,585 | `MLM-PILOT/www/comp-plan.html` |
| `14ac6a0d678ad1181147ce8387d98834c8024c93f81f98c8823f57b0c267863e` | 36,602 | `MLM-PILOT/deploy/build_dist.py` |
| `8de0cfd0589b0079497f8e9ca26a5722c9dc343a6586c725f3c19af11c40e663` | 17,140 | `MLM-PILOT/docs/CORPORATE-CHROME-CONTRACT.md` |
| `e21b073733147aba3a599d573a0f88acb93892f72a62450a243ac748da0a1550` | 67,067 | `MLM-PILOT/docs/ORVANNA-BUILDER-PLAN-SPEC.md` (reference) |

Deterministic build from a cleaned `dist`: `sha256 6b869a21d5c8443d`, identical across two
consecutive runs. Working tree restored to `afa6a3e`, `git status` clean.

**Note on the reference specification.** The brief named version 1.2.1. The file on disk is
**1.2.2**. Version 1.2.2 changes no rate, no parameter, no gate and no measured result; it
corrects the exposure framing in sections 6A, 12A(e) and 13. Nothing in the recomputation
below is affected, but the version of record for this grading is 1.2.2.

---

## 2. THE ONE THING MOST NEEDED: the recomputed worked month

Recomputed independently from specification 1.2.2 sections 2 through 7 and 10 and the
ten-member fixture, at the **rates of record** (generation 1 override 0.015, generation 2
0.010, second-leg base 0.020, multipliers 1.00 / 1.15 / 1.25), not at the fixture's own draft
rates. I did not read the page's figures until after computing my own.

### 2.1 My computation

**Inputs.** CV by member: M1 160.00, M2 120.00, M3 80.00, M4 80.00, M5 40.00, M6 120.00,
M7 1,200.00, M8 80.00, M9 240.00, M10 40.00. Total CV 2,160.00. Unqualified: M5 and M10.
Ranks: M1 Leader (paid depth 3), M3 Builder (paid depth 2), all others Member (paid depth 1).

**Layer one.** Unchanged from the live unilevel plan: M1 114.00, M2 16.00, M3 130.00,
M8 4.00, company **264.00**.

**Layer two.** Builder or above this month: M1 (Leader) and M3 (Builder). For B = M3, the
group is {M3, M7, M8, M10} and group CV is 80 + 1,200 + 80 + 40 = 1,400.00. Walking up from
M3: M1 is qualified with the counter at 0, so M1 takes generation 1 at 0.015 x 1,400.00 =
**21.00**. M1 is Builder or above, so the counter becomes 1; M1 is the root, so the walk
stops and no generation 2 exists. For B = M1 there is nobody above, so no line.
Layer two total **21.00**. Per-source claims: M3 1.20, M7 18.00, M8 1.20, M10 0.60.

**Layer three.** M1's legs by CV: M3-leg 1,400.00, M2-leg 520.00, M4-leg 80.00. Second
strongest is the M2-leg at 520.00. M2, M3 and M4 are all qualified, so 3 active legs, so the
multiplier is 1.15 and the effective rate 0.023. Claim 0.023 x 520.00 = **11.96**
(per-source: M2 2.76, M5 0.92, M6 2.76, M9 5.52). M2 has one active leg only, so M2 is
ineligible. M3's legs: M7-leg 1,200.00 and M8-leg 120.00, both active, so the multiplier is
1.00 and the rate 0.020. Claim 0.020 x 120.00 = **2.40** (per-source: M8 1.60, M10 0.80).
M8 has one leg, so no bonus. Layer three total **14.36**.

**The waterfall, per source, pool = 0.25 x CV.**

| Source | CV | Pool | Spine | Layer 2 | Layer 3 | Total | Under ceiling |
|---|---|---|---|---|---|---|---|
| M1 | 160.00 | 40.00 | 0.00 | 0.00 | 0.00 | 0.00 | yes |
| M2 | 120.00 | 30.00 | 12.00 | 0.00 | 2.76 | 14.76 | yes |
| M3 | 80.00 | 20.00 | 8.00 | 1.20 | 0.00 | 9.20 | yes |
| M4 | 80.00 | 20.00 | 8.00 | 0.00 | 0.00 | 8.00 | yes |
| M5 | 40.00 | 10.00 | 6.00 | 0.00 | 0.92 | 6.92 | yes |
| M6 | 120.00 | 30.00 | 18.00 | 0.00 | 2.76 | 20.76 | yes |
| M7 | 1,200.00 | 300.00 | 180.00 | 18.00 | 0.00 | 198.00 | yes |
| M8 | 80.00 | 20.00 | 12.00 | 1.20 | 1.60 | 14.80 | yes |
| M9 | 240.00 | 60.00 | 12.00 | 0.00 | 5.52 | 17.52 | yes |
| M10 | 40.00 | 10.00 | 8.00 | 0.60 | 0.80 | 9.40 | yes |
| **Totals** | **2,160.00** | **540.00** | **264.00** | **21.00** | **14.36** | **299.36** | |

Every factor f2 and f3 is 1. **No source binds at the rates of record**, which is the
substantive difference from the published draft-rate fixture, where M10 binds exactly at
10.00 of 10.00. My M10 row lands at 9.40 of 10.00, with 0.60 unspent.

**Statements.** M1 = 114.00 + 21.00 + 11.96 = **146.96**. M2 = **16.00**. M3 = 130.00 + 2.40
= **132.40**. M8 = **4.00**. All others 0.00. Company **299.36**, which is the waterfall
column total to the cent.

**Percent of CV.** 299.36 / 2,160.00 = 0.1385925..., which is **13.8593 percent**, printing
as 13.86 percent at two decimals.

### 2.2 Claimed against recomputed

| Figure | Claimed on the page | My recomputation | Result |
|---|---|---|---|
| Layer two total | 21.00 | 21.00 | match |
| Layer three, M1 | 11.96 | 11.96 | match |
| Layer three, M3 | 2.40 | 2.40 | match |
| Layer three total | 14.36 | 14.36 | match |
| Company total | 299.36 | 299.36 | match |
| Percent of CV | 13.86 | 13.8593 | match |
| Every source under its ceiling | yes, all ten | yes, all ten, every factor 1 | match |
| Reconciles to the cent | yes | 299.36 both by source and by member | match |
| M1 statement | 146.96 | 146.96 | match |
| M3 statement | 132.40 | 132.40 | match |
| Per-source override trace | 1.20 / 18.00 / 1.20 / 0.60 | identical | match |
| Per-source bonus trace, M2 leg | 2.76 / 0.92 / 2.76 / 5.52 | identical | match |
| Per-source bonus trace, M8 leg | 1.60 / 0.80 | identical | match |
| Percent of money in the door | 11.09 | 299.36 / 2,700.00 = 11.0874 | match |
| Structural ceiling | 540.00, "a little over half" paid | 540.00; 299.36 is 55.4 percent | match |
| Reconciliation | 240.00 never existed, 36.00 breakage, 264.00 level pay, 35.36 the two layers | 21.00 + 14.36 = 35.36; 264 + 35.36 = 299.36; 540 = 240 + 36 + 264 | match |

**The recomputed worked month is correct in every line I can check. No finding.** This was
the single most damaging place a defect could sit, and there is none there.

---

## 3. Other arithmetic verified

**Figure 1.** 100.00 price, 100 PV, 100.00 SV, 0.80 x 100.00 = 80.00 CV, ceiling 0.25 x 80.00
= 20.00. Sponsor 0.10 x 80.00 = 8.00 plus 0.020 x 80.00 = 1.60, total 9.60. The person above
0.05 x 80.00 = 4.00 plus 0.015 x 80.00 = 1.20, total 5.20. Paid 14.80, unspent 5.20. All
correct, and identical to specification 12A(d), which works the same order at the same rates
and reaches the same 14.80 of a 20.00 cap with 5.20 unspent. The ceiling bar is drawn to
scale: 384 pixels for 9.60, 208 for 5.20, 208 for the unspent 5.20, all at 40 pixels per
unit.

**Figure 12.** 1,200 across two legs is 600 each at 2.0 percent, 12.00. Across three, 400
each at 2.3 percent, 9.20. Across four, 300 each at 2.5 percent, 7.50. All three correct, and
the sequence falls monotonically, so the claim that the rate step never catches the falling
basis holds. Worth recording: the page uses the **exact** values, where specification section
11's rounded coefficients (0.0100, 0.0077, 0.0063 times V) would give 12.00, 9.24 and 7.56.
The page is right and the specification's shorthand is the rounded one.

**Figure 15, the decay fixture.** A is paid 11.60 in month one (8.00 level pay plus 0.015 x
240.00 = 3.60 override) and 8.00 in month two, a fall of exactly 3.60. B is paid 17.60
(16.00 plus 0.020 x 80.00 = 1.60) then 8.00. All correct at the rates of record. **This
discharges specification section 13 presentation rule 2 exactly: the figure quotes 3.60 and
the forbidden draft-rate 9.60 appears nowhere in the file.**

**Figure 9, the generation walk.** Nadia holds Builder with group volume 1,000.00. Owen is
unqualified, so he is passed over and the counter does not move. Priya is qualified at
counter 0, takes generation 1 at 1.5 percent, 15.00, and being a Builder moves the counter to
1. Quinn is qualified at counter 1, takes generation 2 at 1.0 percent, 10.00, and being a
Builder moves the counter to 2, stopping the walk. Rosa gets nothing. This is specification
section 3's walk exactly, including the evaluate-then-count ordering and the rule that an
unqualified member neither earns nor increments.

**Every rate, threshold and rank requirement** checked against specification 1.2.2 section 5
and `DOCUMENTATION/03-COMPENSATION-PLAN.md`: level rates 10, 5, 5, 3, 2; paid depths 1 to 5
by rank; qualification at SV 100.00 or more, inclusive; Builder qualified plus 2 active legs;
Leader qualified plus TV 2,500.00 plus 3 active legs; Director qualified plus TV 10,000.00
plus 2 legs each containing a Builder or above at any depth; Executive qualified plus TV
40,000.00 plus 2 legs each containing a Leader or above; CV = 0.80 x SV; ceiling 25 percent
of CV equals 20 percent of price; six domain agents at $100.00 and 100 PV, six support agents
at $50.00 and 50 PV, named correctly; ten-month spreading of one-time purchases, which is
bridge decision 4.1, ruled 2026-08-15. **All correct. No finding.** Layer one is the live
plan's rates and gates reproduced without alteration.

---

## 4. Findings

### HIGH

**H-1. The brochure states the ceiling as absolute; the page it links to, shipping in the
same deploy, names an exception to it.**

`comp-plan.html` at `b48803d` scopes the ceiling deliberately, as part of the earlier fix
round: "Instant Payout, once built, is the one exception to this ceiling, and it is not
built", and "Everything else on this page describes the monthly run, where the ceiling
holds." That scoping appears in the page body and inside two SVG descriptions.

The brochure states the ceiling without any exception, in seven places:

- cover stamp: "20% of the price is the most any one order can ever pay"
- section one, sentence six: "No order ever pays out more than 20 percent of its price across
  all three layers combined"
- section ten body: "No order ever pays out more than 20 percent of its price, across every
  layer added together"
- figure 14 caption: "no combination of ranks, depths or organisation shapes can push an
  order past 20 percent of its price"
- figure 18: "No order ever pays more than 20 percent of its price, whatever the organisation
  looks like"
- glossary, Ceiling: "The most any single order can pay across all layers"
- section fifteen: "ceiling 20 percent of the price of every order"

Instant Payout appears zero times in the brochure. The commit message justifies that:
"Instant Payout appears nowhere, because Howard shelved it and it pays nothing."

**That justification is contradicted by this repository's own record, written the day
before.** Commit `ad10238`, the shelving commit, states in capitals: "NOT AFFECTED: Howard's
separate 2026-08-15 approval of Instant Payout at 20 percent in
DOCUMENTATION/10-INSTANT-PAYOUT-TERMS.md. **Shelving a build is not revoking an approval, and
nobody should read it as one without asking him.**" The brochure's omission reads the
shelving as a revocation, which is precisely the reading that commit forbids.

Three things make this worse rather than better:

1. The brochure claims precedence over the page that carries the exception: "This document is
   the statement of the plan. Where any other page or summary disagrees with it, this
   document governs." It therefore overrides the scoping, silently.
2. `DOCUMENTATION/03-COMPENSATION-PLAN.md` section 7A places Instant Payout in the body
   "rather than in an appendix so that nobody reads sections 5 through 7 and believes the
   plan has only three mechanisms." The brochure presents three layers as the whole plan.
3. The brochure's own section fifteen has a list titled "What this version of the plan does
   not cover", which names refunds, compression, grace months and disbursement. An approved,
   unbuilt fourth mechanism belongs on that list and is not on it.

This is the finding that fails the gate. It is also cheap: one sentence in section ten and
one line in the section fifteen list, **or** Howard's ruling that Instant Payout sits outside
version 2.0, which is the same ruling the cover already needs.

**H-2. Two cross-linked documents use different member-facing words for the same plan.**

`comp-plan.html` teaches a vocabulary on its cover: a participant is a **Conductor** (155
occurrences), their agents are an **ensemble**, a leg is a **team**, and layer three is the
**second-team bonus** (18 occurrences). The brochure calls the same participant a **member**
(36 occurrences), never says Conductor once, and calls layer three the **second-leg bonus**
(30 occurrences).

The link that `comp-plan.html` now carries to the brochure says: "Same plan, same rules,
same numbers." The numbers do agree, and I checked: the brochure's recomputed figures appear
nowhere in `comp-plan.html`, so there is no numeric contradiction between them. The words are
the problem. A reader Howard forwards the brochure to, who follows the link back, meets two
names for the person the plan is about and two names for one of its three layers, inside
thirty seconds, on the property whose job is to look serious.

Related, and on the same page: `comp-plan.html` states that the Builder plan "is identified
today only by its engineering code, `orvanna_builder`. It has no field name and no booklet.
Naming it is a decision that has not been [made]." Specification section 14 open question 7
says the same and records the default as lab-only until Howard says otherwise. The brochure
is a member-facing booklet that names both extension layers. That is not wrong in itself,
but it settles an open question by publishing rather than by ruling.

### MEDIUM

**M-2 is numbered after M-1 below; ordering here is by weight.**

**M-1. The specification's binding field-facing proration sentence is absent.**

Specification 12A(e) is normative text and it commits to an exact sentence: "your base plan
pay is never prorated; the two bonus layers share what the cap leaves, and **in a given month
about one member-month in four with any volume is reduced**." It also requires that the
realized numbers "must be CARRIED IN ANY PRESENTATION of this plan per metric 5". Version
1.2.2 of the specification exists mainly to correct that frequency upward, from a stated one
in eight to a measured one in four, because both the numerator and the denominator had been
wrong in the same flattering direction.

`comp-plan.html` carries it correctly and three times over: 154 of the 641 member-months that
carry any volume, 24.0 percent, roughly one in four.

The brochure carries the first half of the sentence and drops the frequency. Section ten
says "Your level pay is never reduced", then "on a heavily covered order they can be reduced
to nothing". I searched the whole file: **no proration frequency appears anywhere**, in any
form. The three matches for "154" are SVG coordinates.

The brochure does discharge the other half of 12A(e), the one that has teeth for a member:
"Where a bonus line has been reduced, your statement prints the amount claimed, the amount
paid, and a plain reason." That is correct and well done.

I am deliberately **not** raising the absence of specification section 13 presentation rules
1 and 3 (the cost-drift trajectory, and the development premium at 7.9, 92 and 81 times with
its participation counts). Those rules are written for a deck making a case for the plan.
Printing band earnings multiples in a member-facing document would be an earnings
representation, which this document correctly and deliberately refuses to make. Rule 3's
"wide reach" ban is honoured: the phrase appears zero times. The proration frequency is
different in kind, because it is a fact about what a member's own statement will look like.

**M-2. `document_page_lint` does not prove what the commit says it proves.**

I broke it on purpose, four ways, and confirmed each one fails the build. I then broke it
five more ways it does not catch.

*Caught, by `document_page_lint` itself:*

| Probe | Result |
|---|---|
| `<link rel="stylesheet" href="https://cdn.example.com/a.css">` | FAIL, exit 1, cited by line |
| `<link rel="stylesheet" href="css/site-chrome.css?v=...">` (cache-stamped, file exists) | FAIL, exit 1 |
| `.x { background: url(assets/logo.svg); }` | FAIL, exit 1 |
| `@import "other.css";` | FAIL, exit 1 |
| `<use href="https://cdn.example.com/s.svg#i"/>` | FAIL, exit 1 |
| `<use xlink:href="https://cdn.example.com/s.svg#i"/>` | FAIL, exit 1 |

A note on method: my first attempt at the `<link>` and `<use>` probes used a relative,
unstamped reference, and the build failed on the cache-stamp assertion and the link checker
respectively, **before** `document_page_lint` ran. That proves the build stops, but it does
not prove this lint works. The rows above are the re-probes that isolate the lint itself.

*Not caught. Each of these built and deployed with exit 0:*

| Probe | Result |
|---|---|
| `<iframe src="https://cdn.example.com/a.html">` | **passed the build** |
| `<img srcset="https://cdn.example.com/a.png 1x">` | **passed the build** |
| `<object data="https://cdn.example.com/a.svg">` | **passed the build** |
| SVG `<image href="https://cdn.example.com/a.png">` | **passed the build** |
| inline `<script>window.x=1;</script>` | **passed the build** |

Contract section 5A rule 2 names "`<script>`" and "`<img>`" without qualification. The regex
catches only their `src=` forms, so an `<img srcset>` and an inline `<script>` both slip
through, and four whole element families that fetch (`iframe`, `object`, `embed`,
`video`/`audio`/`source`) are not named at all. Each of them is exactly the silent-death
case the contract's own rationale describes: "all three uses die quietly the moment it
references anything outside itself."

*One false positive:* an **internal** `<use href="#f0t"/>`, which is entirely self-contained,
fails the build. The contract forbids only "external `<use>`". The `url(` branch already
handles this correctly with a negative lookahead for `#`; the `<use>` branch does not.

The page as shipped carries none of these, which I verified directly. Nothing is broken
today. What is smaller than advertised is the guarantee the chrome exemption was bought with,
and the next document page is where that bites.

**M-3. "What carries volume" omits the products that carry roughly half the real volume.**

Bridge decision 4.2, ruled 2026-08-16 and applied as migration 019, widened the product tier
constraint to include `bundle` and `pack` and added four products: the Manager Agent bundle
and the Ignition, Momentum and Constellation packs, at 200 to 800 PV monthly and ten times
that as a one-time purchase. They carry the parent's Personal Volume and they are
commissionable. Roughly half the real paid volume on the live site is bundles and packs.

The brochure's section three, headed "What carries volume", lists the six domain agents, the
six support agents and customer purchases, and stops. It then describes a $2,000.00 one-time
purchase spreading at 200 PV a month for ten months, without naming any product that can be
bought that way, because none of the products it has listed can be. A member reading the
section whose whole job is to enumerate what carries volume would reasonably conclude that
packs do not.

This is a completeness gap in a document that says "This document is the complete statement
of the plan", not a wrong number.

### LOW

**L-1. Two source comments cite the wrong contract section.** `deploy/build_dist.py` line 380
says "Contract section 6 names the class", and the new note in `comp-plan.html` says "section
6 of docs/CORPORATE-CHROME-CONTRACT.md". Section 6 is "Out of scope, explicitly". The class
is **section 5A**. The commit message gets it right; both artifacts get it wrong.

**L-2. The phone-scroll count is overstated.** Measured in Chrome at 375 pixels: **13 of 18
figures scroll sideways, not 16.** Figures 1 and 2 carry hand-built phone layouts. Figures 4,
5 and 7 are drawn at 340 wide and fit natively. The overstatement is in the plan's disfavour,
so it is an accuracy point rather than a defect, but it materially changes the question I was
asked to rule on.

**L-3. The 35 printed pages figure is unverified by me.** No print pipeline was available in
this environment. I confirmed every print rule the claim depends on is present and correct:
the masthead is `display: none !important` so it reserves no space, `.fig-wide` returns and
`.fig-narrow` is hidden, both scroll frames become `overflow: visible`, figure SVGs are
capped at 610 pixels against a printed column of about 695 pixels on A4 and 718 on US Letter,
narrow figures are held at 340, and dark table headers become dark ink on a light fill so a
printer that declines to fill cannot produce white on white. The page count itself I cannot
confirm, and it is the one figure in this set with a history of drift: 29 estimated, then 36
measured, then 35.

**L-4. Two segments in figure 16 are drawn but not labelled.** M1's 11.96 bonus segment (39
pixels) and M3's 2.40 bonus segment (8 pixels) carry no value label; the values appear only
in the caption and in the step-seven table. The bars are correctly to scale, at 3.25 to 3.29
pixels per unit across all four rows. This is the only place in the document where a drawing
does not name one of its own parts.

**L-5. Specification version.** Graded against 1.2.2, not the 1.2.1 named in the brief. No
consequence for any number here; recorded so nobody re-derives it.

---

## 5. Claims verified, no finding

Every one of these I measured myself rather than accepting.

**Zero external references of any kind.** Confirmed by static scan and by the live build. The
file contains zero `<link>`, `<script>`, `<img>`, `url(`, `@import`, `@font-face`, `<use>`,
`xlink:`, `data:` URI, `background-image`, `iframe`, `object`, `embed`, `video`, `audio` and
`source`. The only absolute addresses are two links to `https://orvanna.io/` in the sticky
bar, which contract 5A rule 4 requires to be absolute. The twenty `http://www.w3.org/2000/svg`
occurrences are XML namespace declarations, which are identifiers and not fetches. Zero
inline `style=` attributes.

**Contrast.** Reproduced exactly, both floors, computed from the live rendered document.

- Drawing labels: worst ratio **6.30 to 1**, on `#A62020` over `#FBE9E9` in figure 10 ("when
  they are promoted"). Zero labels below 4.5. **424 text elements** across the twenty
  drawings, matching the claimed count.
- Composited page text: worst ratio **6.79 to 1**, on the teal kicker `rgb(15,95,110)` over
  the alternate band `#F5F7FA`, computed by compositing every ancestor background onto white
  and applying alpha. Zero runs below 4.5. I counted 1,030 text runs where the claim says
  963; that is a node-counting convention difference and the floor value is what matters.

**Geometry at 375, 768, 1024 and 1280.** Measured live in Chrome at each width:

| Width | Page horizontal overflow | Unframed elements past the viewport | Labels outside a viewBox | Frames scrolling |
|---|---|---|---|---|
| 375 | 0 | 0 | 0 | 13 |
| 768 | 0 | 0 | 0 | 2 |
| 1024 | 0 | 0 | 0 | 0 |
| 1280 | 0 | 0 | 0 | 0 |

Labels outside a viewBox were measured with `getBBox()`, which is exact, on every visible
`<text>` in every drawing. My first pass used a character-width estimate and produced twenty
false positives; the exact measurement gives zero at every width.

**Zero overlap.** Screen-space rectangle comparison across every drawing found eleven
candidates. Ten are consecutive stacked lines in figure 6, fourteen pixels apart at 12.5
pixel type, overlapping by 2.6 pixels of em box while the glyphs do not touch. The eleventh
is "THE WALK GOES UP" in figure 9, which carries `transform="rotate(-90 14 212)"`; `getBBox`
reports the untransformed box, so the comparison was invalid. After rotation it sits along
x = 14 while the label it appeared to hit sits at x = 66. **No real overlaps.**

**The two defects the rendered look caught are fixed.** Figure 1's three chain arrowheads are
`212,30 212,46 228,38`, `426,30 426,46 442,38` and `640,30 640,46 656,38`: each has its only
vertical edge on the left and its apex to the right, so all three point right, matching the
order to volume to Commissionable Volume to ceiling flow. The two trunk-rail arrowheads point
right into their boxes. Figure 9's walk arrow is a chevron at the top of an upward line, and
the label says the walk goes up. Figure 3 shows zero label overlap by exact measurement.

**Sticky bar.** `position: sticky`, one row at every width tested, 43 pixels tall at 375 and
44 above it, both links absolute, `display: none !important` in print so it reserves no
space.

**Only fixed height.** One CSS height declaration in the file: `.u-swatch { width: 16px;
height: 16px }`, applied only to empty `<span>` elements in the colour key. The two logo
marks carry SVG `width`/`height` attributes, which are intrinsic sizing on a vector, not a
CSS height on a text container.

**Forbidden words.** "wide reach" 0, "Instant Payout" 0, "instant payout" 0, "Howard" 0.
Also: "Unicity" 0, em dash 0, en dash 0. Every acronym is expanded on first use and an
acronym key is printed in the contents section.

**Structure.** 18 figures, 18 figure numbers, 20 drawing SVGs (figures 1 and 2 carry a second
phone layout each), 15 numbered sections matching the contents list, 57 identifiers with no
duplicates, every drawing carrying `role="img"`, `aria-labelledby`, a `<title>` and a
`<desc>`.

**`page_registry_lint` with a fourth category present.** Probed: adding an unregistered
`pricing.html` fails the build with exit 1 and names all three registration options
including the new one. Registering it as a document page does **not** buy an escape: the same
page then fails `document_page_lint` on its external stylesheet. The registry hole the
verifier proved on 2026-08-17 stays closed.

**Determinism and restoration.** Two consecutive builds from a cleaned `dist` produce
identical bundle hashes. All probe files removed, `build_dist.py` restored from git, working
tree clean at `afa6a3e`.

**comp-plan.html corrections from the earlier failed round.** All eight verified present:
part one is sections one to fourteen and part two fifteen to twenty-four, with the divider
named on both sides; the source member-month is defined explicitly as the unit, with 1,001
units of which 641 carry volume against 1,462 separate orders; proration at 154 of 641,
24.0 percent, roughly one in four, with the retired "120 of 1,001, about one in eight" named
as wrong and why; the worst ratio printed both ways with 34.5 percent of reachable claims
called the honest one, and five Conductors losing 100 percent of their structure claims
stated beside it; 34 personally sponsored a Builder of whom 24 were also qualified, with the
reason the table uses 24; the self-funding bound scoped rather than universal; the ceiling
scoped to the monthly run with Instant Payout named as the exception (which is finding H-1);
and the per-band sample size carried as eight members a band, in the same paragraph as the
top five capturing 90.2 percent of the structure budget.

---

## 6. A limitation I am recording rather than hiding

**I could not obtain a rendered screenshot.** The browser pane in this environment does not
composite frames, so every `screenshot` call timed out. What I did instead is stronger than
static parsing and weaker than looking: I drove a real Chrome, loaded the real file, and
measured the live layout tree at four widths, using `getBBox`, `getBoundingClientRect` and
computed styles, which is how I got the exact contrast floors and the zero-overlap result.

That still leaves the gap this commit itself paid for. Its own lesson is that "geometric
verification proves a page is not broken, never that it is right", and the two defects it
found by looking were semantic, not geometric: arrowheads pointing the wrong way, and a label
laid across a node. I closed the arrowhead class by computing the direction of every
arrowhead in the file from its own geometry, and the label class by exact box measurement.
I cannot close the class nobody has named yet. **Somebody should open this page in a browser
and read it before it is forwarded.** That is thirty minutes and it has paid for itself three
times in two days.

---

## 7. The two rulings

### Ruling one: shipping version 2.0 and an effective date of 1 September 2026 without Howard's ruling

**Not acceptable. Do not ship these as they stand.**

This is not pedantry about a label. Three reasons, in ascending weight.

1. **An effective date is an operative term.** The page's own section fifteen says "Rule
   changes take effect at the start of a stated calendar month and are never applied to a
   month that has already been calculated." Printing "Effective 1 September 2026" therefore
   does not describe the plan, it **commits** the company to a date, on a page that also says
   "Where any other page or summary disagrees with it, this document governs." An invented
   sentence that governs is the one kind of sentence a writer must never produce alone.
2. **"Supersedes version 1.3" is the stronger claim, and it is the one nobody noticed.**
   Version 1.3 is the live plan. It is what the engine actually runs and what every finalized
   month was computed under. The cover announces its retirement on a named date. Nothing in
   the record retires it, and the sibling page says the opposite: that the Builder plan "has
   never been the live plan".
3. **The version number is where finding H-1 actually lives.** Whether Instant Payout is
   inside version 2.0 is exactly the unruled question, and H-1 cannot be closed without an
   answer. So this is not a cosmetic ruling deferred for tidiness; it is the same ruling the
   biggest finding is waiting on.

**Cheapest path that unblocks the page today:** replace the three cover stamps and the two
section fifteen lines with something the record supports, for example "Draft for review" and
no effective date and no supersession claim, and put the version and date question to Howard
alongside the Instant Payout question, since they are one question. That is a ten-minute
edit and it makes the page forwardable while he decides.

### Ruling two: leaving thirteen figures scrolling sideways at 375 pixels

**Acceptable. The designer's judgement was right, and I would not spend the risk.**

Corrected first: the number is **13 of 18**, not 16 (finding L-2). That matters, because
which thirteen turns out to be the whole argument.

1. **The reader's first four sections are already phone-native.** Figures 1 and 2, which carry
   the entire opening argument, have hand-built phone layouts. Figures 4, 5 and 7, which are
   volume, the qualification gate and the five level rates, are drawn 340 wide and fit. A
   reader on a phone gets the plan's core taught to them without touching a horizontal
   scrollbar.
2. **The page itself never scrolls sideways.** Measured: zero pixels of horizontal page
   overflow at 375, and zero elements extending past the viewport outside a scroll frame.
   Only the framed drawings scroll. Below 559 pixels the frame draws a visible border and
   padding specifically so the reader can see the drawing continues rather than believing it
   is cut off. That is a legible convention.
3. **No rule is lost by never scrolling.** Every drawing restates its content in a caption
   underneath, every drawing has a full `<desc>`, and the contents page says so before the
   reader hits the first one: "Some of the drawings are wider than a phone screen. Those
   scroll sideways inside their own frame, and the page itself never does."
4. **The cost is bounded.** Measured scroll extents at 375: eleven frames at 79 to 97 percent
   of their visible width, one at 150 percent. That is one to one and a half screen widths,
   not five.
5. **The risk on the other side is the one this page has already realised twice.** Hand-built
   phone layouts are where figure 1's backwards arrowheads and figure 3's label collision
   came from, and both survived every geometric check. Thirteen more hand-built layouts is
   thirteen more chances at that same defect, on a document whose value is that it is
   trustworthy. Trading a small legibility cost for a large correctness risk is the wrong
   trade.

**One condition, and it does not block anything.** Figure 17, the M1 statement at 700 by 612,
is the drawing a prospect most wants to read on a phone, because it is the one that answers
"what does a check actually look like". If exactly one more phone layout is ever built, build
that one.

---

## 8. What has to change before this deploys

Blocking:

1. **H-1.** Either add the Instant Payout exception to section ten and to the section fifteen
   "does not cover" list, or obtain Howard's ruling that Instant Payout is outside version
   2.0. Do not resolve it by reading the shelving as a revocation; commit `ad10238` forbids
   that reading by name.
2. **Ruling one.** Remove or replace the invented version number, effective date and
   supersession claim, or get them ruled.

Should ride the same round, not separately:

3. **H-2.** Reconcile the vocabulary between the two cross-linked documents, or drop "Same
   plan, same rules, same numbers" from the link, which currently promises more sameness than
   exists.
4. **M-1.** Add the specification's committed field-facing proration frequency to section ten.
5. **M-3.** Add bundles and packs to "What carries volume", or say plainly that they are
   excluded.
6. **L-1.** Correct the two "section 6" citations to "section 5A".

Separate work item, not blocking this page:

7. **M-2.** Widen `EXTERNAL_REF_RE` to cover `iframe`, `object`, `embed`, `video`, `audio`,
   `source`, `img srcset`, SVG `image`, and a bare `<script>`; and add the `#` lookahead to
   the `<use>` branch so an internal reference stops failing the build.

Re-gate scope after the fixes: the brochure only. The build machinery and the contract are
sound as graded, and `comp-plan.html` needs no change beyond H-2 and the L-1 citation.

---
---

# DELTA RE-GATE, 2026-08-17, commit `88cea04`

**Graded by:** mlm-verifier (same agent, same adversarial posture)
**Scope:** delta only, `afa6a3e` to `88cea04`. I did not re-grade the worked month or anything
else I proved clean, per the coordinator's instruction. I re-graded what changed and
everything my findings touched.

## GATE: **PASS**
## DEPLOY: **YES**

Both HIGH findings are genuinely closed, and closed the harder way rather than the cheaper
one. The version and date ruling is applied in full. The lint no longer admits any of the five
references I walked past it last round.

It is a PASS with an asterisk I want on the record: **the round's own lint fix contains a fix
that does not work, plus six more holes.** Neither touches the shipped page, which I
re-verified carries no external reference of any kind, so neither blocks the deploy. But this
is the second consecutive round in which the document-page lint was declared to prove
something it does not prove, and the shape of the pattern is why.

### Artifacts graded, by hash

| SHA-256 | Bytes | File |
|---|---|---|
| `537c8cfd76ebcee9dfda87760a378ced980991c7db160a2bdbb138b36a27de3e` | 198,465 | `MLM-PILOT/www/plan-brochure.html` |
| `a349c211e6257654cb6c931c02da2da64583d0809756c01a1d207c69f560c402` | 240,764 | `MLM-PILOT/www/comp-plan.html` |
| `457f0b6b9c8d670ac8a4fe8b765eb6e50269aa0588e824a7d042cf9b8b0e19bf` | 37,442 | `MLM-PILOT/deploy/build_dist.py` |
| `8de0cfd0589b0079497f8e9ca26a5722c9dc343a6586c725f3c19af11c40e663` | 17,140 | `MLM-PILOT/docs/CORPORATE-CHROME-CONTRACT.md` (unchanged) |

Working tree clean at `88cea04` after every probe.

---

## D1. HIGH-1, the ceiling: **CLOSED**

Howard removed the exception from `comp-plan.html` rather than adding it to the brochure. I
audited the removal three ways.

**Count.** Instant Payout occurrences in `comp-plan.html`: 42 before, **31 after**. Eleven
removed, matching the claim exactly. The brochure had zero before and has zero after.

**No exception claim survives anywhere.** I read all seven surviving uses of "except" in
`comp-plan.html` individually:

| Surviving statement | Verdict |
|---|---|
| "the base for every percentage in this plan, without exception" | about Commissionable Volume, not the ceiling. True. |
| "That ceiling has no exception. It holds on every order, at every rank, in every shape of organisation, and every mechanism that pays anybody today is settled inside it." | the new absolute claim. True, and note the precise qualifier "that pays anybody today". |
| "how these terms sit against the plan's 20 percent ceiling, which has no exception" | the new open-gate framing. True. |
| "Instant Payout is the exception to that **timing** by design: it pays on the day" | narrowed to timing. True. |
| "Instant Payout is the one exception to that **basis**: its 20 percent sits on the order price itself" | narrowed to basis. True, and the arithmetic checks: 0.20 x 150.00 = 30.00 against 0.20 x 120.00 = 24.00. |
| "The ceiling ... has no exception ... have never been reconciled with that promise" | the new note. True. |
| "how the terms sit against this plan's 20 percent ceiling, which has no exception" | honest-gaps table. True. |

I then searched for exception claims phrased **without** the word "except", which is where an
audit like this usually fails: "sits on top", "additionally carry", "can exceed", "above the
ceiling", "beyond 20", "more than 20 percent", "over 20 percent", "carve", "the monthly run
never", "describes the monthly run", "raises the ceiling", and eight more. **Zero residual
breach claims in either document.** The only two hits on "more than 20 percent" are the two
correct absolute statements.

**No true statement was removed by accident.** I read every removed line in the diff. All
eleven removals are exception claims or the scoping language that supported them, and each was
either deleted outright (the two figure captions, the two SVG descriptions, the "one carve-out"
paragraph) or replaced with a true absolute statement ("the monthly run never crosses it"
became "NO ORDER CROSSES IT"; "the ceiling on an order in the monthly commission run" became
"the ceiling on an order"). The facts that had to survive did survive: Instant Payout is still
described as approved, not built, computing nothing, paying nobody, in the honest-gaps table
and in the new note. Nothing true was lost.

**Follow-through is complete.** Three "one question is still open" statements became "two
questions", plus "the condition on Instant Payout ever" became "one of the two conditions".
Measured: "One question is still open" 2 before and 0 after, "Two questions are still open" 0
before and 2 after.

## D2. HIGH-2, the vocabulary: **CLOSED**

| Term | Brochure before to after | comp-plan before to after |
|---|---|---|
| Conductor | 0 to **51** | 155 to 154 |
| second-leg bonus | 30 to 30 | 0 to **18** |
| second-team bonus | 0 to 0 | 18 to **0** |

**I audited all 44 surviving occurrences of "Member" in the brochure individually, not by
sample.** Every one is the rank name: the glossary entry, the paid-depth ladders ("Member 1,
Builder 2, ..."), "rank above Member", the organisation-chart node labels ("M2, Member"), "a
plain Member", and the rank table rows. **Zero use "member" to mean a person.** The glossary
now carries the disambiguating line that makes this safe: "Every person this plan pays is a
Conductor. Member: The name of the first rank."

Both documents now use **leg** as the technical unit (133 and 78 occurrences) and **Team
Volume** as the defined metric. The residual "team" in `comp-plan.html` is the plain English
word in the ensemble-versus-team contrast, not a competing name for a leg.

**The link note is now true.** "Same plan, same rules, same numbers" is gone. It now reads:
"The rules and the numbers are the same. One difference worth knowing before you open it: this
page keeps the plan that runs today separate from the two layers that are only modelled, and
the companion presents the plan as one piece without drawing that line." That is the one
difference that remains, stated plainly, and stating it is the right call.

## D3. The version and date ruling: **APPLIED IN FULL**

| | Before | After |
|---|---|---|
| "version 2.0" | 4 | **0** |
| "Effective 1 September" | 3 | **0** |
| "Supersedes version 1.3" | 1 | **0** |
| "superseding version 1.3" | 1 | **0** |

Section fifteen now says it in the document's own words: "This document carries no version
number and no effective date. It states no start date and retires nothing." The footer repeats
it. The supersession claim, which I flagged although it was not among the two items sent for
ruling, is gone with the rest.

Also fixed and confirmed: the contract citation in `build_dist.py`, section 6 to **section
5A** (my L-1).

## D4. The other changes this round, spot-checked

Not in my scope, but they touch claims I graded, so I checked them.

- **The print `tfoot` defect.** `tfoot { display: table-row-group; }` is present in the print
  block. This was the one that would have been fatal: Chrome reprinting a table's totals on
  every fragment of a split table, inside the section titled "A complete month, to the cent".
  Fixed. Related to my L-3, where I flagged the printed length as the claim with a history of
  drift and said I could not verify the print pipeline. Rendering Chrome's actual print output
  is the right answer to that, and it found something real.
- **Two false statements corrected.** "Level 1 pays twice what any other level pays" is gone;
  it was false at levels 4 and 5, where 10 percent is more than three and five times the rate.
  Figure 1's ceiling label now reads "20 percent of the $100.00" instead of "25% of CV",
  matching the cover.
- **My L-2, the phone-scroll count,** is now moot in the right direction: 13 measured last
  round, **11 measured now**, with two more phone layouts added, one of them the organisation
  chart that was showing a line running to nobody.
- **My L-4, unlabelled bar segments in figure 16,** was not addressed. Still cosmetic, still
  not worth a round.

## D5. Craft claims re-measured on the changed file

The brochure changed by 366 lines, so its geometry claims are new claims. Measured live in
Chrome, not read from the commit message.

| Claim | Measured | Result |
|---|---|---|
| Contrast floor, drawing labels | **6.30 to 1** (`#A62020` on `#FBE9E9`) | reproduces |
| Contrast floor, composited page | **6.79 to 1** | reproduces |
| Drawing labels | **495** across all variants | reproduces exactly |
| Labels outside a viewBox, 375 and 1280 | **0** | reproduces |
| Real text overlaps, 375 and 1280 | **0** | reproduces |
| Page horizontal overflow, 375 and 1280 | **0** | reproduces |
| Elements past the viewport outside a scroll frame | **0** | reproduces |
| Scrolling frames at 375 | **11** of 14 visible | reproduces |
| Sticky bar at 375 | one row, 43 pixels | reproduces |
| Frames with a visible affordance | **14 of 14**, a 1 pixel `#C7CEDB` border | reproduces |
| Figures and drawing SVGs | 18 and 24 (two new phone layouts) | consistent |

The demonstration notice is now at 1.1 percent into the body, on the cover, as a stamp. It was
previously reachable only in a no-print masthead, which meant nobody printing the document
learned it was a demonstration until page 33 of 35. That was a real defect and it is fixed.

---

## D6. New findings

### NEW-1 (MEDIUM). The precedence claim survived the ruling that removed its basis.

The brochure still says, unchanged: "This document is the statement of the plan. **Where any
other page or summary disagrees with it, this document governs.**"

That sentence is inherited convention, and in this industry it is sound convention, because
the booklet that governs is the dated, versioned instrument of record. Howard's ruling stripped
the version, the date and the supersession claim from this document. The sentence that depended
on them was left behind.

It now reads oddly on its own terms and badly in combination:

- The document declares three lines earlier that it carries no version number, no effective
  date, states no start date, and retires nothing. A document with none of those governing over
  one that has them is not a claim that survives a careful reader.
- The new link note on `comp-plan.html` states in writing that the two documents differ in
  scope, and that the brochure is the one that does **not** draw the line between what runs
  today and what is only modelled. So the document claiming to govern is, by the sibling page's
  own description, the less complete of the two on exactly one axis.

This is the residue of my original H-1 rather than a new problem: last round "governs"
aggravated the ceiling contradiction; now that the ceiling is reconciled, it aggravates the
scope difference instead. It makes nothing on the page false, which is why it does not block.

**Fix, one clause:** "Where any other page or summary disagrees with it **about the three
layers it describes**, this document governs." Or delete the sentence, since a document that
retires nothing has no obvious basis for governing anything.

### NEW-2 (MEDIUM). The false-positive fix does not work.

I reported that an internal `<use href="#id">` was wrongly blocked. The pattern was rewritten
with `(?!\#)` guards and the comment states the intent correctly: "an internal
`<use href="#id">` is a same-document reference and is exactly how an inline drawing reuses a
shape, so it must be allowed."

**Re-probed: it is still blocked.** So are `<image href="#x">` and `<link href="#y">`.

Diagnosed to the character. The `url(` branch is written correctly, with the optional quote
**inside** the lookahead:

```
\burl\(\s*(?!['"]?\#)
```

The two new branches put the optional quote **outside** it:

```
<(?:use|image)\b[^>]*\b(?:xlink:)?href\s*=\s*["']?(?!\#)
```

Because `["']?` is optional, the engine matches zero characters there and then tests `(?!\#)`
against the quote character itself. A double quote is not a hash, so the lookahead passes and
the branch matches. Confirmed directly against the compiled pattern:

| Input | Should be | Actual |
|---|---|---|
| `<use href="#f0t"/>` | allowed | **BLOCKED** |
| `<use href='#f0t'/>` | allowed | **BLOCKED** |
| `<use href=#f0t/>` (unquoted) | allowed | allowed |
| `<use xlink:href="#f0t"/>` | allowed | **BLOCKED** |
| `<image href="#x"/>` | allowed | **BLOCKED** |
| `<link rel="x" href="#y">` | allowed | **BLOCKED** |
| `<use href="https://x/s.svg#i"/>` | blocked | blocked |
| `url(#grad)` and `url("#grad")` | allowed | allowed |

Only the unquoted form passes, and nobody writes SVG that way. So the document-page class still
forbids the single most useful way to shrink an inline drawing, and it rejects it with a
message saying "external reference", which is false and will send the next person hunting for a
network reference that does not exist.

**Fix:** move the optional quote inside the lookahead in both branches, matching the `url(`
branch that is already right: `["']?(?!\#)` becomes `(?!["']?\#)`.

### NEW-3 (MEDIUM). Six more ways past the lint, confirmed end to end.

You asked me to find a sixth. I found six, each built and deployed with **exit 0**:

| Probe | Result |
|---|---|
| CSS `background-image: image-set("https://cdn.example.com/a.png" 1x)` | **passed the build** |
| SVG `<feImage href="https://cdn.example.com/i.png"/>` inside a `<filter>` | **passed the build** |
| `<video poster="https://cdn.example.com/p.jpg">` | **passed the build** |
| `<audio src="https://cdn.example.com/a.mp3">` | **passed the build** |
| `<input type="image" src="https://cdn.example.com/b.png">` | **passed the build** |
| `<body background="https://cdn.example.com/bg.png">` | **passed the build** |

Sixteen candidates bypass the pattern by inspection, including `<video src>`, `<track src>`,
SVG `<pattern href>`, `<textPath href>`, `<mpath href>`, `<form action>`,
`<meta http-equiv="refresh">`, anchor `ping`, and `<link imagesrcset>` with no `href`.

Two of these are worth naming specifically because they are the ones a person would actually
write on this page. **CSS `image-set()`** is the modern sibling of `url()`, takes a bare quoted
string with no `url(` token at all, and is exactly what a designer reaches for to serve a logo
at two densities. **SVG `<feImage>`** is a genuine external image fetch inside a filter, in a
document that is 24 inline drawings.

**The finding is not the six tags. It is the shape.** Round one found five holes, the fix
enumerated eleven forbidden constructs, and round two found six more with sixteen candidates
outstanding. A blocklist of fetching elements will not converge, because HTML has dozens of
fetching attributes and CSS keeps adding resource functions.

**Recommended inversion, which does converge and which I verified.** Scan for any attribute
whose value is an absolute URL, `https?://` or protocol-relative `//`, and fail unless it is on
a short permitted list. I enumerated every absolute reference in the shipped brochure:

```
  2  href="https://orvanna.io/"          the site link, permitted by contract 5A rule 4
 22  xmlns="http://www.w3.org/2000/svg"  a namespace identifier, not a fetch
```

**Two exemptions, both closed and both already named in the contract.** That single rule would
have caught all eleven of my bypasses across both rounds, including every one of the six above,
and it needs no maintenance when the next fetching attribute is invented. Relative references
stay covered by the cache-stamp assertion and the link checker, which is what caught my
relative probes in round one before this lint ever ran. Keep the explicit `@import`,
`@font-face`, `url(` and `<script>` rules alongside it, since those are the non-URL-shaped
cases.

### LOW

**L-6. The note names the conflict without sizing it.** Section 10 prints "Total to you on that
first order: 30.00 + 12.00 = **42.00**" on a $150.00 order, and prints 42.00 again inside a
drawing. That is 28 percent, eight points above the ceiling the same page calls absolute. The
note says the two "have never been reconciled" but never prints 28 percent or the gap.
Everywhere else this document sizes its own bruises to two decimals: 34.5 percent for the worst
proration ratio, 154 of 641, 90.2 percent for the top-five concentration, 0.526315 for a
proration factor. A reader trained by twenty sections to expect the number meets the one place
it is withheld, and it is the number a hostile consultant computes first. One clause fixes it.

**L-7. The scroll affordance is a border, not a direction.** All 14 visible frames now carry a
1 pixel `#C7CEDB` edge, up from `#DDE2EB` and from nothing on some. A border says "this is a
frame"; it does not say "the drawing continues to the right". A fade at the right edge or a
one-time hint would say the second thing. Cosmetic, and my ruling that the sideways scroll is
acceptable stands and is stronger now at 11 frames than it was at 13.

---

## D7. Ruling requested: was the builder's note the right call, or should the page be silent?

**The note is the right call. Silence would have been the worst option available, and it is not
close.**

1. **The contradiction is visible on the page whether or not it is named.** Section 10 prints
   42.00 on a 150.00 order, twice, once inside a drawing. Section 4 states an absolute 20
   percent ceiling. A numerate reader does that division in his head. This document says it is
   written to survive a hostile read by a veteran compensation consultant, and that reader
   divides 42 by 150 before he finishes the section. Silence would mean the page's own
   arithmetic refutes the page's own central promise and nobody wrote it down. That is the
   precise failure mode this project has shipped before and that both gates exist to stop.
2. **The note is correctly scoped and every clause in it is verifiable.** It does not claim the
   ceiling is breached today. It says the terms were approved separately, have never been
   reconciled with the promise, nothing computes an Instant Payout, and nobody is paid one. All
   four are true. It softens neither the ceiling nor the approval, which is the narrow path
   between Howard's ruling and the standing record that the 2026-08-15 approval was not
   revoked.
3. **It reuses the document's own convention rather than inventing one.** Refund recovery was
   already a named open gate on building the mechanism. The note makes the reconciliation the
   second one, and the three "one question" to "two questions" edits make that structural
   rather than decorative. A reader meets a familiar shape, not a new apology.
4. **It was inside the builder's authority.** Howard ruled the ceiling absolute. Making the
   page not-false given that ruling is implementation of the ruling, not a new decision. A
   builder who applied the ruling and left the contradiction standing would have shipped a
   document that fails on its own arithmetic, and would have been right to be failed for it.

The one thing I would change is L-6: name the size, not just the conflict. "On the worked
example above that is 42.00 on a 150.00 order, 28 percent, eight points above the ceiling."
This document's credibility rests on the habit of printing the number that hurts, and this is
the single place it declines to.

---

## D8. Severity confirmed, as asked, on the two carried forward

Both were judged out of scope this round. Both are still absent: I re-measured.

**M-1, the specification's binding proration frequency. MEDIUM. Does not block.** Zero
occurrences of any frequency figure in the brochure. The specification makes the sentence
normative and requires the realized numbers in any presentation, and version 1.2.2 exists
because that exact figure was understated once already. The brochure carries the mechanism
("the two bonus layers share what the ceiling leaves") and the strongest member protection (the
claimed, paid and reason on every reduced line), and omits only the frequency, leaving a reader
to guess "rare" where the measurement says roughly one member-month in four with any volume is
reduced. **It does not block because nobody can be harmed by it today:** layers two and three
pay nobody, no line has ever been shaved, and the corrected number is one click away on the
linked page. **It must not survive another round.** The moment these layers are presented as
real, the brochure becomes the surface that understates the exposure, and this project's
specific failure history is documents describing behaviour the data did not have.

**M-3, bundles and packs missing from "What carries volume". MEDIUM. Does not block, but it is
the closer of the two.** Zero occurrences of bundle, pack, Ignition, Momentum, Constellation or
Manager Agent in the brochure. Unlike M-1 this is about what pays **today**: bridge decision
4.2 and migration 019 made the four products commissionable, and roughly half of real paid
volume is bundles and packs. The section headed "What carries volume" lists the twelve agents
and stops, then describes a $2,000.00 one-time purchase that none of the twelve products it
just listed can be bought as. **That incoherence is detectable by a careful reader with no
external knowledge**, which is what makes it worse than M-1 in kind even though it is the same
severity. It does not block because it is an omission rather than a false statement, and
because the page is a demonstration document that now says so on page 1. Fix is one table row.

---

## D9. Deploy

**YES.** Ship `88cea04`.

What made me fail `afa6a3e` is fixed and fixed properly: the ceiling is now one claim across
both documents with no exception surviving anywhere in either, the vocabulary is one, the
invented version and date are gone, and the arithmetic I recomputed last round is untouched by
this delta. The page carries no external reference of any kind, which I re-verified directly
rather than trusting the lint. A potentially fatal print defect that neither of us caught last
round was found and fixed by looking at real printed output, which is the third time in three
days that looking beat measuring.

Same day, not gating:

1. **NEW-1**, one clause on the precedence sentence, because Howard's ruling removed its basis
   and left the sentence.
2. **L-6**, one clause naming 28 percent in the note.

Next work item, and it should not wait for a third round:

3. **NEW-2**, the one-character fix in each of the two lookaheads, which is a fix believed done
   and not done.
4. **NEW-3**, invert the pattern to an absolute-URL scan with the two exemptions above, because
   the blocklist has now failed twice and will fail again.

Then, and I would not let these ride a third round:

5. **M-3**, one table row for bundles and packs.
6. **M-1**, one sentence carrying the proration frequency.
