# Quality Assurance verdict: The Builder plan, published

Commit graded: `041d79d` "The Builder plan, published: part two on the page, and a brief that stands alone"
Graded by: mlm-qa (Verifier team). The builder never grades its own work.
Date: 2026-08-17
Artifacts graded, both driven in a browser rather than read as source:

1. `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\deploy\dist\comp-plan.html`
   built with `py deploy\build_dist.py` and served from
   `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\deploy\dist`
2. `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\ORVANNA-BUILDER-PLAN-BRIEF.html`

Acronym key for this report: Quality Assurance (QA), Scalable Vector Graphics (SVG),
Cascading Style Sheets (CSS), Sales Volume (SV), Commissionable Volume (CV),
Document Object Model (DOM).

---

## VERDICT: FAIL. DO NOT DEPLOY.

One HIGH defect and five MEDIUM defects. The HIGH is a false status claim in the one
panel whose entire job is telling a reader which parts of the document are real, and
per the charter a false status claim in a touched document is HIGH on its own.

Print test: PASS. The one-page explanation genuinely fits one page on both A4 and
Letter, nothing is forced to split, and it is readable in black and white.

Deploy: NO.

---

## Acceptance checklist

Built from the release conditions and the phase brief BEFORE any deliverable was
opened, then graded against what actually rendered.

| # | Promise | Evidence | Verdict |
|---|---------|----------|---------|
| 1 | The page builds and serves | `build_dist.py` OK, 38 files, 1304 KB, bundle sha256 4df035cc767be8a8; all five lints pass | PASS |
| 2 | Sections 1 to 13 unchanged, part two added | 24 numbered sections render; 1 to 14 are part one, 15 to 24 are part two plus the moved glossary | PASS |
| 3 | Status band is second from the top | `#status` follows `#contents`, kicker "Before you start" | PASS |
| 4 | Status band tells the truth about which sections are live | Band says part one is "sections one to fifteen" and part two "sections sixteen to twenty-four". Section fifteen's rendered kicker is "Section fifteen", heading "The Builder plan in one view", which is modelled | **FAIL, H1** |
| 5 | "wide reach" appears zero times | Full innerText scan of both artifacts: 0 occurrences | PASS |
| 6 | 7.9, 92 and 81 printed separately, never as a range, each beside 24 / 44 / 90.2 | Page section 20 table and its figure strip carry all three plus "24 Conductors hold this position \| 44 earn any structure money at all \| the top 5 take 90.2 percent of it \| structure is 22.9 percent of total payout". Brief adds "The premium is not a rising ladder. The biggest multiple is the MIDDLE band at 92 times." No range form found | PASS |
| 7 | The one-bad-month exhibit sits beside the flattering fixture at equal visual weight | Section 18, one SVG, two panels each 410 x 330 units at x=20 and x=450. Bar scale identical: 11.60 renders 127.6 units, 7.80 renders 85.8 units, both 11.0 units per 1.00. Prose: "Both panels are drawn to the same scale so neither hides the other" | PASS |
| 8 | That exhibit is not behind a disclosure control | Page has exactly two `<details>`, both closed by default: "Show every commission line in the run, all fifteen" (section 12) and "How this plan compares to four other plan families" (section 20). The exhibit is in neither | PASS |
| 9 | The lapse-benefit inversion is disclosed with its bounds | Page section 18 and brief item 5: largest gain 7.44 on a 212.91 check, 3.5 percent, in a fixture built to maximise it; never new money; company payout falls 481.14 to 444.77; the two nearest generations lose 17.00 and 11.29; 120 of 1,001 orders bind; counted every run as a standing measurement | PASS |
| 10 | Diagram D10 carries an honesty strip printing all three totals inside the figure | Confirmed as SVG `<text>` inside the figure, not in the caption: "The attacker's own total:", "44.00", "39.68", "50.00", "the highest of the three", and "The part that is not a defense: the flat, undeveloped shape pays the attacker MOST". D9 additionally says leg-splitting is absent from the money-spent chart and why | PASS |
| 11 | No new diagram clips, collides, or vanishes, in either theme | 11 SVG figures in the new and status sections, 396 SVG text nodes checked geometrically against their viewBox. Two labels escape their frame and are clipped (`overflow: hidden`) | **FAIL, M2** |
| 12 | Contrast floor holds, recomputed rather than trusted | Independently computed both themes. Dark floor 5.55 HTML, 5.12 SVG. Light floor 4.510 (pre-existing chip). Lowest NEW pairs 4.731, 4.812, 4.955, all below the reported 4.96 | PASS on 4.5, **FAIL on the reported number, M6** |
| 13 | Contents entry N equals section N equals the kicker the reader sees | All 24 links clicked. Every one lands on a section whose kicker matches its number. Numbering renders 01 to 14 then 15 to 24 (`counter-reset: toc 0` and `toc 14`, `decimal-leading-zero`) | PASS |
| 14 | Un-numbered "Start here" lead-in above the list | `p.toc-lead` "Start here: What is running, and what is only modelled" targets `#status`, sits above both ordered lists, carries no counter | PASS |
| 15 | Every contents link lands with its kicker visible, not under the sticky bar | Sticky nav bottom 105px, sections carry `scroll-margin-top: 72px`; measured kicker top 157px on 23 of 24 and 199px on section 15. Zero landing failures | PASS |
| 16 | Nine-page navigation untouched | comp-plan.html nav matches index, shop, product, team and faq exactly: same eight links, same order, marks its own page active | PASS |
| 17 | Icon-only theme control still works both directions | `button.nav-theme`, no text, aria-label present. dark to light to dark, aria-label updates to match | PASS |
| 18 | Theme persists | `orvanna-theme` written to localStorage on each toggle, value tracks the applied theme | PASS |
| 19 | Console clean | Zero console messages on the page | PASS |
| 20 | 390 pixels: no sideways scrolling, wide figures in their own scroll frames | scrollWidth 390 = clientWidth. Zero elements overflow outside a scroll frame. All wide figures in `.figure` / `.fig-scroll` at `overflow-x: auto`; 19 tables all framed | PASS |
| 21 | 375 pixels: same | scrollWidth 375 = clientWidth, zero unframed overflow | PASS |
| 22 | No surviving claim that money reached a person | Both artifacts swept. Page: "0 dollars paid", "No Conductor has been paid one cent by either layer", "No real money moves at any point". Brief: "No money has been paid to anyone, by either plan", "no funds move at any point in the system", "0 live runs. No statement. Not one line for one person." | PASS |
| 23 | Brief has zero external references and works with no network | Zero `src` and `href` attributes of any kind, zero http or https URLs, zero `@import`, zero `url()`, zero external stylesheets, zero scripts. 97,298 bytes, fully inline | PASS |
| 24 | Brief prints: one-page explanation fits one page | Measured with print CSS applied and page width forced. `#onepage` is 219.9mm at A4 content width and 217.6mm at Letter content width, against 269mm and 251.4mm of content height | PASS |
| 25 | Brief prints: no table or figure splits across a break | `break-inside: avoid` on figure, table, .panel, .callout, .kstrip, .exhibit and its children, tr, thead; `thead` set to table-header-group. Tallest such elements are the Law A exhibit at 232.6mm and the sources table at 201.4mm, both under both page heights | PASS |
| 26 | Brief is readable in black and white | Greyscale contrast worst pair 5.75 HTML, 6.02 SVG. The loss and gain figure labels its columns LOSS, GAIN and no change in words with signed values, so no meaning rests on colour alone. Links forced to rgb(15,23,42) in print | PASS |
| 27 | No em or en dashes | Zero in both files | PASS |
| 28 | Acronyms expanded on first use | Page prints an acronym key in the contents band; brief prints one in its opening | PASS |
| 29 | A figure-only reader cannot come away overstating the plan's defenses | Ruled below. Yes on leg-splitting, which is the question asked. One exception elsewhere, M5 | PARTIAL |

---

## Defects

### HIGH

**H1. The status band assigns a modelled section to the operating-today column.**
Location: page, `#status`, "What is running, and what is only modelled", the panel
second from the top of the document.

What it says, verbatim:

> OPERATING TODAY. Part one, sections one to fifteen. Everything in part one of this
> brochure, sections one to fifteen, is the plan the commission engine runs. It is
> unilevel version 1.3 ... Those runs produced statements. They are the plan.

> MODELLED, NEVER PAID. Part two, sections sixteen to twenty-four.

What actually renders. Section fourteen's kicker is "Section fourteen", heading "What
version 1.3 does not do", the last section of part one. Section fifteen's kicker is
"Section fifteen", heading "The Builder plan in one view", and it opens with the part
divider "PART TWO, THE BUILDER PLAN, MODELLED". Section fifteen is the first section
of part two. It describes the three layers, the two laws, and the modelled rates.

So the band tells a reader that the modelled Builder plan's opening section is part of
the plan the commission engine runs and that produced statements, and it omits that
section from the never-paid column. Correct ranges are: part one, sections one to
fourteen; part two, sections fifteen to twenty-four.

Why it happened: the glossary moved from position 15 to position 24 this round, and
the band's ranges were not renumbered with it. This is the same numbering class that
was already caught once this round, surviving in the one panel that must not carry it.

The source specification carries the same error and contradicts itself. In
`MLM-PILOT\docs\COMP-PLAN-PAGE-CONTENT-2026-08-17.md`, line 191 says part one is
"sections one to fifteen" while line 199 says "Part two, sections fifteen to
twenty-four". Both cannot be true. Line 53 of the same file settles it: "the new part
sits between section 14 and the glossary".

Fix both the page and the specification.

### MEDIUM

**M2. Two of the new diagrams clip label text at the frame edge.**
SVG `overflow` computes to `hidden` on both, so the text is cut, not merely spilled.
Scale invariant, so it clips at every viewport width and in both themes.

- Section fifteen, "The Builder plan in one view". Label "the spine draws first",
  text-anchor middle at x=436, bounding box 381.6 to 490.4 in a viewBox 480 wide.
  10.4 units past the right edge are cut.
- Section sixteen, "Layer two: the Builder override". Label "B's group volume is the
  basis", text-anchor middle at x=52, bounding box -24.9 to 129.1. 24.9 units past the
  left edge are cut, roughly the leading "B's g", which is the part of the label that
  says whose volume it is.

This fails acceptance item 11 as written in the brief.

**M3. The headline premium is quoted to two decimal places with no per-band sample size.**
Location: page section twenty, and brief item 1.

The table prints mean pay 52.47 against 6.66 (7.9 times), 725.57 against 7.90 (92
times), 955.31 against 11.77 (81 times). The only participation figure given is "24
Conductors in the modelled population of 1,001 hold that position", which is the total
across all three bands. The page never says how many of the 24 sit in each band.

Twenty-four members split across three bands, in a population where the page itself
reports that five people take 90.2 percent of the structure budget, means the 725.57
and 955.31 band means are almost certainly computed on single-digit counts and are
plausibly driven by one member each. The first question a professional asks of a
"92 times" claim is the sample size, and the document cannot answer it. The mitigation
that IS present, the concentration strip in the same visual field, is good practice
and does not substitute for n.

Add the per-band counts to the table, in both artifacts.

**M4. "Every self-funding attack loses at least 80 percent" is stated as a universal law and is false in that form.**
Location: page section twenty-one, and brief item 8, near-identical wording.

Page: "no plan funded under a 20 percent ceiling can return more than 20 cents of
commission on a self-funded dollar, so every self-funding attack on every layer of
this plan loses at least 80 percent."
Brief: "No plan funded under a 20 percent revenue ceiling can return more than 20
cents on a self-funded dollar. Every self-funding attack loses 80 percent or more."

The bound holds only for commission generated BY the self-funded volume itself. It
does not hold for self-funded volume bought to UNLOCK pay on other people's volume,
and unlocking is precisely what the 100.00 SV gate does. The page's own section twelve
walks a month in which Conductors collect 264.00 of level pay whose eligibility rests
on their own 100.00 purchase. And section ten's own worked example returns 42.00 on a
self-funded 150.00 first order once Instant Payout is built, which is 28 cents on the
dollar, above the stated 20-cent ceiling.

Section twenty-two answers the buy-rank objection well, so the substance is defended
elsewhere. The defect is the sentence, which claims more than the arithmetic supports
and is the kind of over-general law a hired skeptic disassembles first. Narrow it to
"commission generated by the self-funded volume" and it becomes true.

**M5. Two new sections and three figures restate the ceiling absolutely without the carve-out the same document makes.**

- Section fifteen: "No order can ever pay out more than 20 percent of its price,
  whatever the rates are set to". Its figure prints "THE CEILING: 20 PERCENT OF THE
  PRICE. NO ORDER CROSSES IT."
- Section nineteen: "the most any order can ever pay is 20 percent of its price". Its
  two figures print "the ceiling. Nothing crosses it."
- Section ten: "Once Instant Payout is built, a Conductor's first order will
  additionally carry up to 20 percent of its price paid on the day, so a first order
  can pay more than 20 percent in total."

Sections four and ten do disclose the carve-out, and section four cross-references it
explicitly, so the document as a whole is honest. The defect is that the two NEW
sections and their three figures do not, and a reader who reads part two first, or who
reads only the figures, takes an absolute claim the document elsewhere qualifies. This
is the one place where the figure-only reading is overstated. One clause in each fixes it.

**M6. The reported contrast floor of 4.96 to 1 is not reproducible.**
Method: sRGB relative luminance per the standard formula, foreground alpha composited
onto the effective background resolved by walking ancestors and compositing every
non-transparent layer. Implementation sanity-checked: black on white returns 21.0000
exactly.

Light theme, lowest pairs among NEW content, all the inline cross-reference links
added this round at rgb(14,116,144):

| Location | Foreground | Background | Ratio |
|---|---|---|---|
| Section 23, "the section on Law A" | rgb(14,116,144) | rgb(238,240,255) | 4.731 |
| Section 16, "the section on Law B" | rgb(14,116,144) | rgb(254,243,199) | 4.812 |
| Section 19, "the section on Law A" | rgb(14,116,144) | rgb(244,246,251) | 4.955 |

So the true floor across new pairs is 4.73, not 4.96. The reported 4.96 is the kicker
value ("Section one" etc at rgb(14,116,144) on rgb(244,246,251), 4.96), which is not
the minimum.

Separately, the lowest pair anywhere on the page in light theme is `.chip.soon`
"approved, not built" in section ten at 4.510 (9.6px, weight 700), which is
pre-existing and outside this commit.

Dark theme, independently computed: worst HTML pair 5.55, worst SVG pair 5.12, across
1,275 HTML and 396 SVG text nodes.

Nothing breaches 4.5 to 1, so this is a record-accuracy defect, not an accessibility
failure. Correct the number wherever it is carried forward.

### LOW

**L1. Numbering style shifts for sections seven to ten.** Entries 07 to 10 read
"Earning one" through "Earning four" where every other entry reads
"Section <number in words>". Verified consistent, with no ordinal conflict: sections
one to six and eleven to twenty-four all match their entry numbers exactly. A reader
could momentarily read "Earning one" beside "07" as a mismatch. Cosmetic only.

**L2. An unsupported share claim.** Section ten: the 20 percent figure "still holds
across the plan as a whole because first orders are a small share of what the company
sells." No figure for that share appears anywhere on the page.

**L3. Tight caption leading in the section eighteen figure.** The two caption lines sit
on 12-unit leading at 12px, so their em boxes overlap by 4 units. Glyph ink does not
collide. Measured and reported for completeness; **withdrawn as a defect.**

---

## Print test result: PASS

Method: extracted every rule inside the file's `@media print` block, injected it as a
plain stylesheet so it applied to the live rendering, forced the document width to the
printable content width of each paper size, and measured in millimetres against a
100mm probe (3.779 pixels per millimetre, which is the correct 96 per inch).

Page geometry comes from the file's own `@page { size: auto; margin: 14mm 12mm; }`:

| Paper | Content width | Content height |
|---|---|---|
| A4 | 186.0mm | 269.0mm |
| Letter | 191.9mm | 251.4mm |

Results:

| Element | A4 | Letter | Fits |
|---|---|---|---|
| `#onepage`, the one-page explanation | 219.9mm | 217.6mm | YES on both, and the 219.9mm figure reproduces the number claimed in the commit |
| Law A exhibit figure | 232.6mm | 232.6mm | YES on both |
| Sources table | 201.4mm | 192.9mm | YES on both |
| `#sources` section | 258.3mm | 249.9mm | YES, and it may break internally by design |

`#onepage` carries `break-before: page`, `break-after: page` and `break-inside: avoid`,
so it starts at the top of a fresh page and, at 219.9mm against 251.4mm on the tighter
paper, genuinely occupies one page. No element carrying `break-inside: avoid` exceeds
either page height, so nothing is forced to split. `thead` is set to
`table-header-group`, so any table that does span pages repeats its header.

Black and white: greyscale contrast (Rec.601 luma, then the standard ratio) worst pair
5.75 for HTML text and 6.02 for SVG text. Nothing depends on hue: the loss and gain
figure labels its three columns LOSS, GAIN and no change in words and prints signed
values, and print CSS forces link colour to rgb(15,23,42).

No network: the file has zero `src` and zero `href` attributes of any kind, zero http
or https URLs, zero `@import`, zero `url()`, no external stylesheets and no scripts.
It is 97,298 bytes of fully inline markup, CSS and SVG.

---

## Ruling on the leg-splitting question

Asked: can a reader who looks only at the figures, never the prose, come away with an
overstated impression of the plan's defenses?

On leg-splitting specifically, no, and the correction landed properly. Diagram D10
carries the honesty strip inside the figure as SVG text, printing all three attacker
totals, 44.00, 39.68 and 50.00, naming 50.00 "the highest of the three", and stating
inside the frame: "The part that is not a defense: the flat, undeveloped shape pays
the attacker MOST, because the 10 percent frontline rate beats every development rate
in this plan." Diagram D9, the money-spent chart, explicitly says leg-splitting is
absent from it and why: "it costs the attacker nothing, so it does not belong on a
money-spent chart." A figure-only reader of these two figures gets the honest picture,
including the part that does not flatter the plan.

The status band figure is likewise honest on its own terms: layer 1 solid and labelled
"operating today, 12 live commission runs", layers 2 and 3 in outline labelled
"29 laboratory runs, 0 live runs, 0 dollars paid".

The one place a figure-only reader IS overstated is M5: three figures print the payout
ceiling as absolute ("NO ORDER CROSSES IT", "Nothing crosses it") while section ten's
prose says a first order will exceed it once Instant Payout is built. That is the only
figure-carried overstatement found, and it is a one-clause fix.

---

## What to fix before this ships

1. H1: correct the status band to "sections one to fourteen" and "sections fifteen to
   twenty-four", and correct the two contradicting lines in the content specification.
2. M2: pull "the spine draws first" left, and "B's group volume is the basis" right,
   until both bounding boxes sit inside their viewBoxes.
3. M3: print the per-band member counts beside the three multiples, in both artifacts.
4. M4: narrow the self-funding sentence to commission generated by the self-funded
   volume, in both artifacts.
5. M5: add the Instant Payout clause to sections fifteen and nineteen and to the three
   ceiling figures.
6. M6: correct the contrast floor to 4.73 wherever it is recorded.

Re-run both gates on the corrected artifact. Nothing deploys until both pass on the
exact artifact being shipped.

---

## New standing checklist rows earned this round

Per the charter rule that catches become permanent rows:

- **Row: any status, part, or section RANGE stated in prose is re-derived from the
  rendered kickers, not from the specification.** H1 shipped because the range was
  written once and never re-read against what the page renders after a renumbering.
  Grading it means listing every rendered kicker in order and checking each stated
  range's endpoints against that list.
- **Row: every SVG text node's bounding box is checked against its own viewBox, in
  every figure, because SVG overflow is hidden by default.** M2 is invisible to any
  DOM-presence check and to any contrast check. The text is present, styled, and
  readable in the DOM, and cut off on screen.
- **Row: a reported measurement floor is reproduced, not accepted, and the reproduction
  reports which specific pairs sit at the bottom.** M6 shipped because the reported
  floor was a real number from a real element, just not the minimum.
- **Row: any number presented as a mean, a rate, or a multiple is checked for a stated
  denominator on the same surface.** M3.
