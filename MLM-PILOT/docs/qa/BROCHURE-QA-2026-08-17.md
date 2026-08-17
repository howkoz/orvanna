# Quality Assurance (QA) gate: plan-brochure.html and the comp-plan link

- **Commit graded:** `afa6a3e` ("The illustrated compensation plan, and a registered class for pages that are documents")
- **Artifact graded:** `MLM-PILOT\deploy\dist\` built by `py deploy\build_dist.py`, bundle sha256 `9f40c27ee76b4baf`, served over Hypertext Transfer Protocol (HTTP) from `deploy\dist`
- **Grader:** mlm-qa. Read-only toward the product. Nothing was fixed.
- **Date:** 2026-08-17

## VERDICT: FAIL

## DEPLOY: NO

Seven HIGH defects. Two of them are false statements this commit put in front of a
reader, which my charter grades HIGH on its own. The page is close to world class in
craft and the arithmetic is watertight, but it publishes a version number, an effective
date and a supersession claim that contradict the live site, and on paper it both
misstates table totals and hides for thirty two pages the fact that Orvanna is a
demonstration.

---

## How this was graded

The Browser pane would not composite frames in this session, so screenshots through it
were unavailable. Rather than fall back to Document Object Model (DOM) inspection, which
my standing lesson says is not visual proof, I drove a real Chrome through the Chrome
DevTools Protocol (CDP): full page captures in twenty five slices at 1280 and forty one
at 375, per figure captures at 375, and the real Chrome print pipeline to Portable
Document Format (PDF) rendered back to images at 110 dots per inch. I looked at every
one of the eighteen figures on screen and on paper. Every number below that I state as
measured, I measured.

---

## Acceptance checklist

| # | Promise being tested | Evidence | Result |
|---|---|---|---|
| 1 | Build is clean, `document_page_lint` runs and passes | `py deploy/build_dist.py`: "document page lint: 1 document page(s) carry no external references"; 39 files, 1488 KB | PASS |
| 2 | Zero external references; works saved to a desktop with no network | Copied the built file to a scratch folder, loaded over `file://` with all `http://*` and `https://*` blocked at the network layer: `performance.getEntriesByType('resource')` returned `[]`, 18 figures and 22 Scalable Vector Graphics (SVG) present, full 43,344 pixel height, cover styling intact | PASS |
| 3 | Zero horizontal page overflow at 375, 768, 1024, 1280 | `documentElement.scrollWidth === clientWidth` at all four widths (375/375, 768/768, 1024/1024, 1280/1280) | PASS |
| 4 | Zero labels outside a viewBox | Walked every `<text>` `getBBox()` against its owning `viewBox` at all four widths: 0 violations | PASS |
| 5 | Contrast floor 6.30 to 1 across drawing labels | Independently recomputed, compositing alpha and resolving each SVG label against the painted shape beneath it: floor **6.30 to 1** over 1,401 text runs at 375 and 1,393 at 768, 1024 and 1280. Worst five identical at every width | PASS, claim confirmed |
| 6 | Only fixed height in the file is 16 pixels on an empty swatch | Two `height:` declarations exist: `.fig svg { height: auto }` and `.u-swatch { height: 16px }`. `.u-swatch` is used on five empty `<span aria-hidden="true">` elements | PASS, claim confirmed |
| 7 | "wide reach", "Instant Payout", "Howard" appear nowhere | 0 occurrences each. Also 0 for "Koziara" and "Unicity" | PASS |
| 8 | 35 printed pages | Chrome print pipeline, US Letter 612 by 792 points: **35 pages** | PASS, claim confirmed |
| 9 | Sticky bar is one slim row, links absolute, opens a new tab, gone on paper with no reserved space | 42.56 pixels tall at 375 and 43.66 at 1280, `position: sticky`, both links `https://orvanna.io/` with `target="_blank" rel="noopener noreferrer"`, `display:none` under `@media print` and page 1 of the PDF starts at the normal margin | PASS |
| 10 | Anchors land below the sticky bar | Navigated to `#ranks`: section top at 72 pixels, masthead bottom at 43.7, heading covered by 0 pixels | PASS |
| 11 | Console clean, no scripts | Zero console messages; zero `<script>` tags in the file | PASS |
| 12 | Table headers repeat across printed pages | Printed pages 26, 27 and 33 each open with a repeated `thead` row | PASS |
| 13 | No table split on paper | **Two tables split, and both repeat their total row on each fragment** | **FAIL, defect H3** |
| 14 | Readable in black and white | Text legibility is unchanged in greyscale, because Web Content Accessibility Guidelines (WCAG) contrast is computed from relative luminance and greyscale preserves it. Body ink on the five tints is 12.44 to 12.99 to 1 | PASS for text |
| 15 | Colour is never load-bearing (the page's own promise) | **Figure 5 distinguishes the pass branch from the fail branch by stroke colour alone.** In greyscale the five semantic colours are 1.01 to 1.26 to 1 apart, that is, indistinguishable | **FAIL, defect H5 and L3** |
| 16 | Every figure says the true thing and its labels sit where they belong | **Figures 3, 5 and 7 do not** | **FAIL, defects H5, H6, M2** |
| 17 | Phone: 375 is usable | **13 of the 16 visible figure frames scroll sideways; two of them lose their meaning entirely** | **FAIL, defect H7 and M6** |
| 18 | Pictures-only reader finishes understanding and forms no wrong impression | Coverage is complete; **four wrong impressions are available from the drawings alone** | **FAIL** |
| 19 | Cold arrival: whose plan, what it is, how to reach the site | Cover names Orvanna, subtitle states the business, sticky bar reaches the site. On paper the sticky bar is gone and no address is printed anywhere | PARTIAL, defect L6 |
| 20 | The comp-plan.html link lands and makes sense | Lands correctly; contrast 8.9 to 9.7 to 1; **its own copy is false and it opens in the same tab with no way back** | **FAIL, defects H2 and M4** |
| 21 | The worked month reconciles | Recomputed independently, see below | PASS |
| 22 | Version and effective date are safe to publish | **No** | **FAIL, defect H1** |
| 23 | Documentation truth: source comments cite the right contract section | Two comments cite section 6; the class is defined in section 5A | **FAIL, defect L5** |

---

## Arithmetic recheck of the worked month

The commit left this open. I recomputed the whole of section twelve from the cast in
Figure 6 and it holds to the cent.

- Sales Volume 2,700.00; Commissionable Volume 0.80 times that is 2,160.00. Column adds to 2,160.00.
- Ranks: M1 Team Volume 2,500.00 exactly with three active legs is Leader; M3 has two active legs and Team Volume 1,650.00, so Builder and not Leader. Correct.
- Layer one, fifteen lines: M1 nine lines to 114.00, M2 two lines to 16.00, M3 three lines to 130.00, M8 one line to 4.00. Total 264.00. Correct.
- Layer two: M3 group volume 80 plus 1,200 plus 80 plus 40 is 1,400.00, at 1.5 percent is 21.00. Correct.
- Layer three: M1's second strongest leg is the M2 leg at 520.00 with three active legs at 2.3 percent, 11.96. M3's second strongest is the M8 leg at 120.00 with two active legs at 2.0 percent, 2.40. Total 14.36. Correct.
- Company total 264.00 plus 21.00 plus 14.36 is 299.36. Correct.
- Ceiling per source: I recomputed all ten. Every one sits inside 25 percent of its own Commissionable Volume. The tightest is M10 at 9.40 against a 10.00 ceiling, then M8 at 14.80 against 20.00.
- "Where the rest of the money went": the reachable maximum really is 300.00, not 540.00, once you count only the levels that exist above each person; breakage really is 24.00 plus 12.00 equals 36.00; 300 minus 36 is 264. Correct.
- 299.36 over 2,160.00 is 13.86 percent and over 2,700.00 is 11.09 percent. Correct.

The arithmetic is the strongest part of this document. None of the defects below are
arithmetic defects.

---

## HIGH defects

### H1. The cover publishes a version, an effective date and a supersession that no source supports and that contradict the live site

**Location:** `www/plan-brochure.html` lines 448 to 450, 2078 to 2079, 2089, and the
`<meta name="description">` at line 7.

The cover carries three stamps: "Plan version 2.0", "Effective 1 September 2026",
"Supersedes version 1.3". Searching the whole repository, "1 September 2026" appears in
exactly one file, this one. "version 2.0" appears in exactly one file, this one. Nothing
else names either.

Meanwhile `www/comp-plan.html`, the canonical statement of the plan on the same site,
is stamped "Plan version 1.3" at line 612, has a whole section titled "What version 1.3
does not do" at line 1688, closes at line 2858 with "Orvanna compensation plan, version
1.3, effective month 2026-08", and says at line 724 that "Every monthly commission run
this company has ever computed carries version 1.2 or version 1.3 of that specification".
`www/staff-operations.html` records every commission run with `spec_version: 'v1.3'`.

So the site now says two different things about what version the plan is. Worse, the
brochure presents the Builder override and the second-leg bonus as in force from a named
date, while comp-plan.html presents them as part two: modelled, calibrated in a
laboratory, with "the rates as modelled", gated by a red team, not running. An effective
date converts a proposal into a commitment a reader can act on.

"Supersedes version 1.3" goes further than the two facts the commit flagged as invented.
It asserts that the live plan has been retired. Nothing retired it.

### H2. "Same plan, same rules, same numbers" on comp-plan.html is false

**Location:** `www/comp-plan.html` lines 643 to 656 (the note added by this commit).

The note says the brochure "explains the same plan" and, in its second paragraph, "Same
plan, same rules, same numbers." Three ways that is not true:

1. **Not the same version.** comp-plan.html is version 1.3; the brochure is version 2.0 effective 1 September 2026, superseding 1.3.
2. **Not the same scope.** comp-plan.html separates a running part one from a modelled part two. The brochure presents all three layers as one plan with no such line. The contents entry directly beneath this note reads "Start here: What is running, and what is only modelled". The note contradicts the entry one paragraph below it.
3. **Not the same words.** comp-plan.html says "Conductor" 155 times and "second-team bonus" 18 times. The brochure says "Conductor" zero times and "second-leg bonus" 30 times. No mapping is offered on either page.

A false claim in a document this commit touched is HIGH under my charter regardless of
the rest.

### H3. Printed tables split and repeat their total row, so printed pages state totals that contradict the rows above them

**Location:** printed pages 25 to 27; caused by `@media print` in `plan-brochure.html`
lines 386 to 390, which sets `thead { display: table-header-group }` and allows
`.tframe { break-inside: auto }` but says nothing about `tfoot`. Chrome's default
`tfoot { display: table-footer-group }` then repeats the total row on every fragment.

Observed on paper:

- **Page 25** ends with the "Step one: volume and qualification" table showing exactly two rows, M1 at 200.00 and M2 at 150.00, footed **"Totals 2,700.00 / 2,160.00"**. Two rows summing to 350.00 are footed with 2,700.00.
- **Page 26** ends with the "Step three: layer one, every level pay line" table showing exactly four rows, 12.00 plus 8.00 plus 8.00 plus 2.00, footed **"Layer one, fifteen lines / 264.00"**. Four rows summing to 30.00 are footed "fifteen lines, 264.00", and a fifth row is clipped by the page edge below the footer.

This is a document whose section is titled "A complete month, to the cent" and whose
Figure 17 caption promises "the total is simply the lines added up". On paper it prints
two pages where the total is not the lines added up. Anybody who checks the arithmetic,
which is exactly the reader this page is written for, hits this on page 25.

### H4. On paper the document carries no demonstration marker until page 33 of 35

**Location:** the only occurrences of "demonstration" before section fifteen are lines
423 and 424, inside `.masthead`, which is `display: none !important` under
`@media print`.

Printed pages 1 through 32 read as a real, effective, dated compensation plan of
"Orvanna International", complete with a version number and a supersession. The
disclosure that Orvanna is a demonstration company, that its products, members and
organisations are not real, and that no money is paid, first appears on printed page 33.
The footer repeats it on page 35.

Howard prints this and sends the PDF. The recipient reads thirty two pages before
learning what they are looking at. The cover should carry the marker; on screen the only
one is a 0.76 rem muted link in the top bar.

### H5. Figure 5 draws the failing branch of the gate onto the "YES: QUALIFIED" box, and encodes pass against fail by colour alone

**Location:** `www/plan-brochure.html` lines 945 to 946.

```
<path d="M100 198 L100 218" stroke="#0B5D3B" .../>
<path d="M240 198 L240 218" stroke="#A62020" .../>
```

Both stubs run from the bottom of "THE GATE" at y=198 to y=218. The "YES: QUALIFIED"
rectangle starts at y=220. The "NO: NOT QUALIFIED" rectangle starts at y=304 and has no
connector at all. So the red branch, the one that means "no", terminates on the green box
that means "yes". Rendered, it reads as a decision with two outcomes that both land on
"qualified".

Neither stub carries an arrowhead or a "yes" or "no" label. The only thing separating
them is stroke colour. Page 2 of this document promises, in its own words, "Nothing in
this document depends on telling those colours apart." In greyscale I measured green
`#0B5D3B` against red `#A62020` at **1.08 to 1**, that is, identical. On a black and
white print, and for a red-green colour blind reader, Figure 5 is two identical grey
lines from a question to the same answer.

This is the same class of defect as the backwards arrowheads this commit fixed in
Figure 1, in the figure that teaches the one gate the whole plan turns on.

### H6. Figure 3 files the downline and sponsor definitions under the LEVEL 2 and LEVEL 3 labels

**Location:** `www/plan-brochure.html` lines 806 to 811.

Four labels sit in one column at x=230, all left aligned to the same edge:

```
y=210  LEVEL 2                                  (green, bold, 13.5px)
y=232  A, B, C, D and E together
y=250  are your DOWNLINE.                        (grey, 12.5px)
y=290  LEVEL 3                                  (green, bold, 13.5px)
y=312  The person above YOU is your SPONSOR.     (grey, 12.5px)
```

A bold coloured line with grey lines 22 pixels beneath it, at the same left edge, is
heading-and-body. There is no other reading. So the drawing tells a stranger that
LEVEL 2 means "A, B, C, D and E together are your downline" and that LEVEL 3 means "the
person above you is your sponsor". Both are wrong: they are definitions of downline and
sponsor, unrelated to levels 2 and 3, and there is nobody drawn above YOU at all.

Figure 3 exists to teach the vocabulary. It is the one figure in the document that must
not be misread, and it teaches two wrong associations to anybody who reads the picture.
It is also the figure this commit already had to repair once.

### H7. On a phone, Figures 6 and 8 lose their meaning entirely

Measured at 375 pixels: **13 of the 16 visible figure frames scroll sideways.** Two
figures have phone layouts (`fig-narrow`); sixteen do not.

Worst affected, with the horizontal shortfall I measured:

| Figure | Drawing width in frame | Frame width | Shortfall |
|---|---|---|---|
| 6, the ten person cast | 844 | 337 | +507 |
| 3, 8, 9, 12, 13, 16, 17 | 664 | 337 | +327 |
| 10, 11, 14, 15, 18 | 604 | 337 | +267 |

I captured what a phone reader actually sees:

- **Figure 6** shows M2, M5, M6 and M9 and a diagonal line running off the right edge. **M1, the top of the organisation, is not on screen at all.** The caption text below is clipped mid word. A stranger's first sight of "the organisation every example uses" is a headless fragment of a chart with a line going nowhere.
- **Figure 8** shows only the Member and Builder columns. Leader, Director and Executive are off screen. The entire argument of the figure is the widening silhouette across five ranks, and a phone reader sees two ranks and could reasonably conclude the plan has two.
- **Figure 13** keeps its staircase shape, which is the one that survives, but the requirement text on the Leader, Director and Executive rungs is clipped, so the thresholds cannot be read.

There is no per figure scroll affordance: no shadow, no arrow, no label. The only cue is
a hairline border and the fact that text is cut. The explanation that drawings scroll
sideways sits on the contents page, thousands of pixels above the first figure that does
it.

**Ruling on the phone question:** for the eleven figures that are sequences, ledgers or
lists, sideways scrolling is acceptable. For **Figures 6 and 8 it is a defect**, because
their meaning is the whole shape and the shape can never be on screen at once. Figure 13
is borderline and I would call it MEDIUM. These are also the three figures a
pictures-only reader depends on most.

---

## MEDIUM defects

### M1. Vocabulary divergence between the two documents, with no mapping
comp-plan.html: "Conductor" 155 times, "second-team bonus" 18 times.
plan-brochure.html: "Conductor" 0 times, "second-leg bonus" 30 times.
A reader arriving from the link in H2 meets different names for the central person and
the third earning layer, having just been told it is the same plan.

### M2. Figure 7 prints a false sentence inside the drawing
`plan-brochure.html` line 1115: "Level 1 pays twice what any other level pays."
Level 1 is 10 percent. Levels 2 and 3 are 5 percent, so twice. Level 4 is 3 percent,
which is 3.33 times, and level 5 is 2 percent, which is 5 times. The figcaption states
it correctly ("level 1 is worth as much as levels 2 and 3 combined"); the drawing does
not. The pictures-only reader sees only the drawing.

### M3. Figure 1 labels the ceiling "25% of CV" where the cover and Figure 4 say 20 percent of the price
`plan-brochure.html` lines 532 and 612. Both statements are true and Figure 7
reconciles them, but Figure 1 is the headline drawing of the document and the first
thing a forwarded link shows. Its amber chip reads "Ceiling on this order, 25% of CV"
twenty three pixels below a cover stamp that says "20%". A reader who reads Figure 1 and
stops carries away 25 percent.

### M4. No return path from the brochure to comp-plan.html, and the link opens in the same tab
The comp-plan link has no `target`, so the reader leaves the canonical document. The
brochure has no site chrome by design and its only two links go to the site root, not
back to comp-plan.html. Only the browser Back button returns. Given the brochure is the
lighter of the two, sending a reader one way with no path back is the wrong direction.

### M5. Figure 16 leaves two of five layer amounts unlabelled
`plan-brochure.html` lines 1717 to 1728. M1's bar labels 114.00 and 21.00 but leaves the
39 pixel second-leg bonus segment blank (11.96). M3's 8 pixel bonus segment is blank
(2.40). Both values appear only in the caption and the right hand total. In the one
figure that shows all four checks split by layer, two of the layer amounts are not on
the drawing.

To its credit, every bar in Figure 16 is drawn to a single shared scale and I verified
it: 4.71 pixels per unit across all four members, correct to within a pixel.

### M6. Thirteen figures scroll sideways at 375 with no affordance
Covered under H7. Listed separately because the affordance problem is independent of the
two figures that break: even the eleven acceptable ones give the reader no signal that
there is more drawing to the right.

---

## LOW defects

- **L1. Figure 6, the M5 and M6 boxes collide.** `plan-brochure.html` lines 1023 and 1029: M5 spans x=22 to 202 and M6 spans x=198 to 378, a 4 pixel overlap. Rendered, the red box and the grey box are fused with no gap, while every other sibling pair in the figure has a gap. This also makes the commit's "zero overlap" wording untrue as stated, though I take that claim to have meant labels.
- **L2. Colour discipline is inverted between sections seven and eight.** Line 1344 gives the layer two section a teal (`note lit`) closing panel, the layer three colour; line 1354 gives the layer three section's "What gets paid" panel the default indigo, the layer two colour. The colour key says a colour "means the same thing every time". The key restricts the promise to drawings, so this is LOW rather than higher, but a reader does not distinguish a drawing from a tinted panel.
- **L3. The five colour key on page 2 collapses in black and white.** I computed the greyscale separation of every pair: strokes 1.01 to 1.26 to 1, tints 1.00 to 1.04 to 1. On a monochrome printer the key is five identical grey squares beside five different sentences. The document anticipates this in prose but the key itself does not degrade gracefully.
- **L4. Figure 13's Member rung has a riser stub landing on nothing.** A pale riser extends below the bottom rung of the staircase with no step beneath it.
- **L5. Two source comments cite the wrong contract section.** `deploy/build_dist.py` ("Contract section 6 names the class") and the comment added to `www/comp-plan.html` ("section 6 of docs/CORPORATE-CHROME-CONTRACT.md"). The class is defined in section 5A. Section 6 is "Out of scope, explicitly". The commit message itself says 5A and is right.
- **L6. A printed copy carries no address and no page numbers.** The sticky bar is the only route to the site and it is `no-print`. A forwarded PDF has no way back to orvanna.io on any of its 35 pages.

---

## Ruling: the pictures-only reader

**FAIL.**

Coverage passes. Reading only the eighteen drawings and the text inside them, a reader
does reach the whole plan: the order to volume to Commissionable Volume to ceiling chain,
the three layers and their rates, the vocabulary, the gate, the cast, the five level
rates, what rank reaches, the generation walk, no breakaway, the second leg and why
splitting loses, the rank ladder, the ceiling binding, the month over month loss, the
four checks, one statement and the never-pays list. That is a real achievement and the
figure architecture is genuinely good.

It fails the second half of the test, which is that no wrong impression may be available
from the drawings alone. Four are, and on a phone a fifth and sixth:

1. Figure 3 teaches that level 2 means downline and level 3 means sponsor (H6).
2. Figure 5 shows the failing branch of the qualification gate landing on the "qualified" box (H5).
3. Figure 7 states inside the drawing that level 1 pays twice what any other level pays, which is false for levels 4 and 5 (M2).
4. Figure 1 labels the ceiling 25 percent where the cover says 20 percent (M3).
5. On a phone, Figure 6 shows an organisation chart with no top (H7).
6. On a phone, Figure 8 shows a plan with two ranks (H7).

Items 1 and 2 are in the two figures whose whole job is teaching the vocabulary and the
gate. Fix those two and item 3, and the drawings-only reading is sound.

---

## Ruling: version 2.0 and effective 1 September 2026

**NOT SAFE TO PUBLISH. Remove all three stamps before this ships.**

My reasons, in order of weight:

1. **They contradict the live site.** comp-plan.html is stamped version 1.3 and effective month 2026-08. The staff console records every run at spec_version v1.3. Publishing a page that says the plan is version 2.0 effective 1 September 2026 makes the site say two different things about the same plan, and makes the older, more careful document look stale.
2. **An effective date is a commitment.** It tells a reader the plan starts paying this way on a named day two weeks from now. Nothing has committed to that. This document is forwarded to people judging whether the compensation plan is serious, and the fastest way to lose them is a date that does not happen.
3. **"Supersedes version 1.3" was not one of the two facts flagged for a ruling, and it is the boldest of the three.** It asserts a version history and the retirement of the plan that is actually running. comp-plan.html says version 1.3 is "the plan the commission engine runs".
4. **It converts a proposal into a policy.** The Builder override and the second-leg bonus are, on comp-plan.html, modelled: calibrated in a laboratory, rates "as modelled", red teamed, not live. Stamping them "effective" erases that distinction, and the brochure carries no equivalent of comp-plan.html's "What is running, and what is only modelled" section.

**What I would ship instead.** Nothing about the document needs a version number to be
excellent. Replace the three stamps with what is actually true and checkable, for
example "Demonstration document", "Illustrated companion to the compensation plan", and
"Read start to finish". If Howard wants a version, it should be the one the engine runs,
and the additional layers should be marked in the brochure as they are in comp-plan.html.
Add "Orvanna is a demonstration company" to the cover while you are there, which also
closes H4.

---

## What passed, stated plainly

This is a strong document and the failures above should not obscure it. Independently
confirmed: the contrast floor of 6.30 to 1 across 1,393 to 1,401 text runs at four
widths; zero horizontal page overflow; zero labels outside a viewBox; the single 16 pixel
fixed height on an empty swatch; genuine self-containment proven by loading the saved
file with the network blocked; 35 printed pages; the sticky bar's behaviour on screen and
its clean disappearance on paper; repeating table headers; a clean console with zero
scripts; the absence of "wide reach", "Instant Payout" and "Howard"; every bar in
Figures 1, 7, 14 and 16 drawn to a correct shared scale; and the entire worked month,
which reconciles to the cent under an independent recomputation including all ten per
source ceiling checks. The arithmetic open item from the commit message is now closed:
it is correct.

---

## Re-gate requirements

Both gates must run again on the exact artifact that ships. For this gate to pass I need:

1. H1 resolved by Howard's ruling and the stamps changed accordingly.
2. H2 resolved: the comp-plan.html note must stop saying "same plan, same rules, same numbers" while the two documents differ in version, scope and vocabulary.
3. H3 resolved: `tfoot { display: table-row-group }` under `@media print`, or the two long tables kept whole, then re-printed and re-read.
4. H4 resolved: a demonstration marker on the cover, present on paper.
5. H5 resolved: the failing branch drawn to the failing box, with a non-colour cue.
6. H6 resolved: Figure 3's four labels separated so the definitions do not read as level captions.
7. H7 resolved: phone layouts for Figures 6 and 8 at minimum.
8. M2 and M3 corrected.
9. A rendered look at every changed figure, on screen and on paper, before the re-gate.

## Standing checklist rows added by this gate

Per my charter, rows that should have caught something get written down permanently.

- **A repeating `tfoot` is a print defect.** Any printed table that may split must be checked for a total row repeating on a fragment. Grade the printed page, not the screen table.
- **A branch connector must terminate on the box it means.** For every decision figure, trace each connector to its endpoint and read the pair aloud as a sentence.
- **A promise that colour is never load-bearing is a testable claim.** Compute the greyscale separation of every pair of semantic colours and then find every place where two elements differ only by colour.
- **Labels in a shared column inherit the heading above them.** Any stack of labels at one left edge must be read as heading-and-body, whatever the author intended.
- **A demonstration marker must survive the print stylesheet.** Anything inside `no-print` does not exist on paper.
- **A figure whose meaning is its overall shape must fit the narrowest supported width.** Sideways scrolling is acceptable for sequences and ledgers, never for silhouettes.

---
---

# DELTA GATE: commit `88cea04`, 2026-08-17

- **Commit graded:** `88cea04` ("Fix round: seven HIGH closed, three rulings applied, and a lint that five things walked past")
- **Artifact graded:** `MLM-PILOT\deploy\dist\` built by `py deploy\build_dist.py`, bundle sha256 `f161d60e2f42f944`, 39 files, 1503 KB, served over Hypertext Transfer Protocol (HTTP) from `deploy\dist`
- **Grader:** mlm-qa, a fresh grader replacing the one whose session was lost. Read-only toward the product. Nothing was fixed.
- **Date:** 2026-08-17

## VERDICT: FAIL

## DEPLOY: NO

One HIGH remains. Every one of the seven HIGH defects this commit claimed to close
**is closed, and I confirmed each by looking at the rendered result**, not by reading
the source. Both wrong statements are corrected. The 20 percent ceiling is now
consistent across both documents. But the supersession this commit removed from the
cover stamps **survives in prose one page earlier in the same section**, and it points
the opposite way to the two sentences on `comp-plan.html` that say a different document
governs. That is the same defect class as the last gate's H1, and my charter grades a
false claim in a touched document HIGH on its own.

The fix is two sentences. Nothing else on this page needs to change.

---

## How this was graded

The Browser pane again would not composite frames, exactly as last session. Rather than
fall back to reading the Document Object Model (DOM), which my standing lesson says is
not visual proof, I drove a real Chrome over the Chrome DevTools Protocol (CDP). I
looked at:

- all eighteen drawings at 1280, captured per figure;
- all eighteen drawings at 375 with mobile emulation on, captured at the clipped frame
  width so the capture is what a phone reader actually sees;
- Chrome's own print output, rendered back to images at 110 dots per inch, all 35 pages
  as a contact sheet and four pages full size;
- four printed pages and two figures converted to greyscale, to test the document's own
  promise that nothing depends on telling colours apart;
- the page loaded from `file://` with every host blocked at the resolver and a dead
  proxy, to test self-containment.

Every number below that I state as measured, I measured in this session. Where a
measurement of mine turned out to be wrong I say so and withdraw it.

---

## The seven closed HIGH defects, verified one by one

| # | Claim | How I checked it | Result |
|---|---|---|---|
| 1 | Version, date, supersession stamps gone; section fifteen says so | Zero occurrences of "version 2.0", "1 September 2026", "Supersedes" in either file. Cover now carries the chips "Demonstration document" and "Read start to finish", **looked at, rendered**. Printed page 35: "This document carries no version number and no effective date. It states no start date and retires nothing." | **CLOSED**, but see HIGH D1 |
| 2 | The false sameness claim rewritten; vocabulary unified | Note **rendered and read**: it now names the one difference, that comp-plan separates a running part one from a modelled part two while the companion presents the plan whole. "Conductor" 51 in the brochure, "second-leg bonus" 30; "second-team bonus" now 0 in both files. All 44 visible-text occurrences of "Member" in the brochure individually read: every one is the rank name | **CLOSED** |
| 3 | Printed tables no longer repeat their total row | `tfoot { display: table-row-group }` present under `@media print`. **Verified on paper:** printed page 26 ends "Totals 2,700.00 / 2,160.00" directly under M10, the last row it totals. Printed page 27 carries "Layer one, fifteen lines 264.00" once, under the fifteenth line. Printed page 28 carries the ceiling table's "Totals" once. No total appears twice anywhere in 35 pages | **CLOSED** |
| 4 | Demonstration notice on printed page 1 | **Looked at printed page 1.** The notice sits directly under the cover subtitle, in a tinted panel with a rule, above the contents: "Orvanna is a demonstration company. Its products, its Conductors and the organisations shown in this document are not real, and no money is paid to anybody under this plan." Legible in greyscale | **CLOSED** |
| 5 | Qualification figure rebuilt with two labelled branches and arrowheads | **Looked at Figure 5** at 1280 and on paper in greyscale. Two stubs leave the gate, each labelled YES and NO in bold, each carrying an arrowhead, each landing on its own box. In black and white the branches are still unambiguous, because the labels carry the meaning and the colours no longer do | **CLOSED** |
| 6 | Vocabulary figure definitions moved to their own panel | **Looked at Figure 3.** LEVEL 2 and LEVEL 3 now sit on short leader lines pointing at the D and E boxes. The downline and sponsor definitions sit in a separate bordered panel on the right. Nothing reads as heading-and-body any more | **CLOSED** |
| 7 | Phone layouts for the two broken figures; scrolling frames 13 to 11 | **Looked at Figure 6 at 375:** an indented outline tree with M1 at the top, on screen, all ten Conductors present, nothing clipped. **Looked at Figure 8 at 375:** transposed to rank rows, all five ranks visible at once, the widening silhouette intact. Measured: 11 of the 14 visible frames scroll at 375, down from 13. Page overflow zero at 375, 768, 1024 and 1280 | **CLOSED**, but see MEDIUM D2 and D3 |

### The two wrong statements

- **"Level 1 pays twice what any other level pays"** is gone. Figure 7 now reads
  "Level 1 is worth as much as levels 2 and 3 combined", which is true. **CLOSED.**
- **Figure 1's ceiling label** now reads "Ceiling, 20% of the price 20.00", matching the
  cover's 20 percent and Figure 4's "20 percent of the $100.00 price". Figure 7
  reconciles the two bases on the drawing: "All five together: 25 percent of CV =
  20.00 = 20 percent of the $100.00 price". **CLOSED.**

### Earlier MEDIUM and LOW items also closed

- **M5, unlabelled bar segments in Figure 16.** Both are now labelled on leader lines
  above their segments, 11.96 and 2.40. Looked at. **CLOSED.**
- **L1, the M5 and M6 box collision in Figure 6.** Gone; every sibling pair now has a
  gap. Looked at. **CLOSED.**
- **L2, inverted colour discipline between sections seven and eight.** Section
  `layer2` now carries plain indigo panels and section `layer3` carries the teal
  `note lit`. **CLOSED.**
- **L5, wrong contract section in two source comments.** Both now cite section 5A.
  **CLOSED.**
- **L6, no address on paper.** The printed footer now reads "The demonstration site is
  at orvanna.io." on page 35. **Partly closed**; still no page numbers.

---

## HIGH defect

### D1. The supersession survived the edit. It is now a governance clause, and the two documents point at each other

**Location:** `www/plan-brochure.html`, section fifteen, printed page 34, under the
heading "HOW THE RULES CHANGE, AND WHEN". Also `www/comp-plan.html` lines 632 and 2836.

The brochure says, as the first sentence of that subsection:

> This document is the statement of the plan. Where any other page or summary disagrees
> with it, this document governs.

One printed page later, under "DOCUMENT DETAILS", the same section says:

> This document carries no version number and no effective date. It states no start date
> and retires nothing.

A document that governs over every other page does, on every point of disagreement,
retire the other page's reading. The two sentences are three inches apart on paper and
they do not agree.

It matters because **the two documents do disagree, and this commit says so in writing.**
The new link note on `comp-plan.html`, which I read rendered, states the one remaining
difference: comp-plan keeps the plan that runs today separate from the two layers that
are only modelled, and the brochure presents the plan as one piece without drawing that
line. Under the brochure's governance clause, the brochure's reading wins. That reinstates
the Builder override and the second-leg bonus as governing rules over comp-plan's
statement that they are "modelled and verified in a laboratory and are not part of the
live plan" and that "No Conductor has been paid one cent by either layer". It is the
substance of "Supersedes version 1.3" with the number taken out.

And the site now points in a circle. `comp-plan.html` says, twice:

> If a number here disagrees with a number anywhere else, the compensation plan booklet
> is the document that governs.

> Which document governs. The compensation plan booklet is the single statement of this
> plan that Conductors are given. ... where any wording differs, the booklet and its
> version stamp govern.

There is no compensation plan booklet on this site. I searched: "booklet" appears five
times, all in `comp-plan.html`, three of them as this governing document and two saying
the Builder extension "has no field name and no booklet". `plan-brochure.html` uses the
word zero times. If the booklet is meant to be the brochure, then "the booklet **and its
version stamp** govern" became unsatisfiable the moment this commit removed the version
stamp, and it is a false statement in a file this commit changed. If the booklet is meant
to be something else, then comp-plan defers to a document that does not exist while the
brochure claims the role for itself.

**Why HIGH.** My charter grades a false claim in a touched document HIGH on its own,
and `comp-plan.html` is a touched document. Beyond that, this is the surviving half of
the defect the previous gate raised as H1 and this commit reports as closed. The stamps
were removed; the prose that does the same work was not audited. Both gates have to run
again on whatever ships, so it is worth doing once and completely.

**What I would ship.** Delete "Where any other page or summary disagrees with it, this
document governs" and keep "This document is the statement of the plan" only if the
brochure also says which document draws the running-versus-modelled line. On
`comp-plan.html`, replace both "the compensation plan booklet" sentences with a name
that exists. Then re-print and re-read page 34.

---

## MEDIUM defects

### D2. The phone scroll affordance is claimed as three cues; one renders, and it does not distinguish a scrolling frame from a fitting one

**Location:** `www/plan-brochure.html`, the `@media (max-width: 559px)` block, `.figframe`.

The source names three cues and says they work "without a word": the frame is drawn, the
scrollbar is given a size and a colour so it stays visible, and the right edge is shaded
so the drawing reads as continuing. Measured at 375 with mobile emulation:

| Cue | What I measured | Verdict |
|---|---|---|
| 1 pixel border | Present on all 14 visible frames | Renders, but also on the 3 frames that do not scroll (Figures 4, 5 and 7), so it does not mean "there is more to the right" |
| Right-edge shading | On an empty band inside Figure 4's frame, mean luminance falls from 254.9 to a minimum of 252.3 out of 255. That is a contrast of about **1.02 to 1** | Does not render as a visible cue |
| Sized, coloured scrollbar | `offsetHeight - clientHeight - border` is **0 on every one of the 14 frames**. Chrome reserves no track and paints an overlay scrollbar, which is invisible until the reader has already scrolled. Real mobile Chrome and Safari behave the same way | Does not render until after the action it is meant to prompt |

The `inset -16px 0 14px -13px` shadow places its darkening about 22 to 36 pixels in from
the right edge, not at the edge, and at that offset it is a 1 percent luminance step. The
commit's "all 14 remaining frames gained a visible affordance where there had been none"
is materially overstated: what a phone reader gains is a hairline border.

I note for the record that my first probe of this looked for a pseudo-element or a
background image and found none. **That probe was wrong and I withdraw it**; the shading
is a box shadow and it is declared. It simply does not render at a visible strength.

### D3. Figure 13 still clips the rank thresholds on a phone

**Location:** Figure 13, at 375 the frame scrolls 327 pixels.

Only Figures 6 and 8 were given phone layouts. **Looked at Figure 13 at 375:** the
visible column reads "EXECUTIVE, reaches 5 le", "qualified, Team Volume 40,0",
"DIRECTOR, reaches 4 levels", "qualified, Team Volume 10,000.00+", "qualified, Team
Volume 2,500.00 or more, 3". The three ranks whose requirements a reader most wants are
the three whose requirements are cut. The staircase shape survives, which is why this is
MEDIUM and not HIGH, and the caption restates every threshold in words. The previous gate
called this borderline MEDIUM and it is unchanged.

### D4. "This version of the plan" appears eight times in a document that says it has no version

**Location:** `www/plan-brochure.html`, eight occurrences, including the section fifteen
heading **"WHAT THIS VERSION OF THE PLAN DOES NOT COVER" on printed page 34**, one page
before "This document carries no version number".

Examples: "There is no compression in this version of the plan", "There are no grace
months in this version of the plan", "This version has no rule for reversing volume",
"Not part of this version". Ruling 1 removed the stamps and rewrote section fifteen's
closing bullets, but the prose that depends on a version identity was not swept. The
phrase now has no referent, and the reader this document is written for is exactly the
reader who will ask which version.

### D5. There is still no way back from the brochure, and the brochure never mentions the document it came from

**Location:** `www/plan-brochure.html`. The whole file contains exactly two external
links, both `https://orvanna.io/`. It contains the strings "modelled", "not operating",
"laboratory", "companion" and "comp-plan" **zero times each**.

So the one document that draws the running-versus-modelled line is unreachable from the
one that does not, and the lighter document never tells the reader the heavier one
exists. This was M4 last gate and it is unchanged. It is also what makes D1 bite: the
brochure claims to govern over a page it never names.

---

## LOW defects

- **D6. The five colour key on the contents page still collapses in black and white.**
  I computed the greyscale separation of every pair, from the declared hex values, using
  Web Content Accessibility Guidelines relative luminance. Strokes: green `#0B5D3B` vs
  blue `#2A3E9E` **1.16 to 1**, teal `#0F5F6E` vs red `#A62020` **1.01 to 1**, amber
  `#7A4A06` vs red **1.01 to 1**, the whole set spanning **1.01 to 1.26 to 1**. Tints:
  **1.004 to 1.044 to 1**. On a monochrome printer the key is five identical grey squares
  beside five different sentences. The document anticipates this in prose; the key itself
  still does not degrade.
- **D7. Figure 16 is the last place where the key is colour only.** In greyscale the
  three legend swatches and the three segments of M1's bar are identical greys, and the
  mapping survives only by left-to-right order. Figure 14 solved the identical problem
  with wording, "drawn first / drawn next / drawn last", and Figure 16 did not adopt it.
  Every amount is printed on the drawing, so the arithmetic is not at risk; only the
  layer names are. **Looked at, in greyscale, both figures.**
- **D8. A true, quantified Instant Payout statement was removed and its number now
  appears nowhere.** The old anti-gaming note said that once Instant Payout is built the
  worked example returns 42.00 on a self-funded first order of 150.00, "28 cents on the
  dollar, above 20". The replacement sentence is true but qualitative. Section ten's new
  note names the conflict without naming its size. "28 percent" and "28 cents" now appear
  nowhere on the site. I would put the number back into section ten's note.
- **D9. The printed copy has no page numbers.** 35 pages, no folio on any of them. The
  site address now prints once, on page 35.
- **D10. Figure 3 opens clipped on a phone.** At 375 the first thing visible is the top
  box cut to "YO", the frontline label cut to "LEVEL 1, you", and the definitions panel
  entirely off screen. Nothing is misfiled and nothing is wrong, but the vocabulary
  figure's first impression on a phone is a cut word.
- **D11. Printed page 30 ends with roughly 45 percent white space** because Figure 18
  will not split, which is correct behaviour. It is the worst instance of a pattern that
  costs perhaps three quarters of a page across the document. Cosmetic.

---

## RULING: the pictures-only reader

### PASS.

This is the bar the page was built to and it now clears it. I re-ran the test by looking
at all eighteen drawings at 1280, then all eighteen at 375, then a sample in greyscale on
paper, reading only the drawings and the text inside them.

**Coverage** is complete, as it was last gate: the order to volume to Commissionable
Volume to ceiling chain, the three layers and their rates, the vocabulary, the gate, the
cast, the five level rates, what each rank reaches, the generation walk, no breakaway,
the second leg and why splitting loses, the rank ladder, when the ceiling binds, the
month over month loss, the four checks, one full statement, and the never-pays list.

**All six wrong readings that failed this test last gate are closed:**

| # | Last gate's wrong reading | State now |
|---|---|---|
| 1 | Figure 3 taught that level 2 means downline and level 3 means sponsor | Definitions in their own panel; LEVEL 2 and LEVEL 3 on leader lines to the boxes they name |
| 2 | Figure 5 landed the failing branch on the "qualified" box | Two labelled branches with arrowheads, each on its own box; holds in greyscale |
| 3 | Figure 7 said inside the drawing that level 1 pays twice any other level | Now "Level 1 is worth as much as levels 2 and 3 combined" |
| 4 | Figure 1 labelled the ceiling 25 percent of CV against the cover's 20 percent | Now "Ceiling, 20% of the price 20.00"; Figure 7 reconciles both bases on the drawing |
| 5 | On a phone Figure 6 showed an organisation with no top | Phone tree with M1 at the top and all ten present |
| 6 | On a phone Figure 8 showed a plan with two ranks | Phone layout with all five ranks on screen |

**No new wrong reading is available.** The nearest candidate is D7: in black and white,
Figure 16's three layer names can only be assigned by order. That mis-assigns a label,
not a fact, because every amount is printed on the drawing and the total reconciles
either way. It does not overturn the ruling.

The figure architecture is the strongest thing on this page and it is now correct.

---

## RULING: the ceiling across both documents

### CONSISTENT, in both directions. No contradiction found.

- The brochure states the ceiling as 20 percent of the price on the cover, in Figure 1,
  in Figure 4, in Figure 7 (reconciling 25 percent of Commissionable Volume to 20 percent
  of price), in Figure 14 and in Figure 18, where it prints "No order ever pays more than
  20 percent of its price, whatever the organisation looks like."
- `comp-plan.html` now states it absolutely in every place it appears: "That ceiling has
  no exception. It holds on every order, at every rank, in every shape of organisation";
  Law B reads "No order can ever pay out more than 20 percent of its price"; the layer
  diagram reads "THE CEILING: 20 PERCENT OF THE PRICE. NO ORDER CROSSES IT." I read every
  one of the 31 surviving "Instant Payout" occurrences and every "20 percent", "twenty
  percent" and "exception" in the file.
- The brochure contains "Instant Payout" zero times, so it makes no claim about it in
  either direction.
- Eleven exception statements were removed and I found **no true statement about Instant
  Payout deleted except one**, D8, the 28 cents on the dollar figure. Every other removal
  was a carve-out from the ceiling, which is exactly what the ruling required.

### The builder's judgement call on the new comp-plan note: RIGHT CALL.

The note reads: "How this sits against the 20 percent ceiling, which is one of the two
reasons it is not built. The ceiling in section four is the plan's central promise and
it has no exception: no order pays out more than 20 percent of its price. The terms above
were approved separately and have never been reconciled with that promise, and until they
are, nothing computes an Instant Payout and nobody is paid one."

I rendered it in light theme and read it on screen. It is right for four reasons:

1. **It does not edit approved terms to fit a document.** The rate, the basis and the
   caps were approved on 2026-08-15. Quietly changing them so the arithmetic stopped
   embarrassing the ceiling would have been the worse call by a distance.
2. **It flags the conflict before the reader meets it.** The stop-note at the top of
   section ten now names both open gates, and says the second is taken up at the end of
   the section. The reader hits the 30.00 arithmetic already knowing it is unreconciled.
3. **It converts an unresolved contradiction into a named build gate**, alongside refund
   recovery, and the same wording is mirrored in the not-settled table.
4. **Nothing is wrong today**, because Instant Payout computes nothing and pays nobody,
   and the note says exactly that.

The one improvement is D8: put the 28 percent back, so the reader learns the size of the
gap and not only that a gap exists.

---

## Printed findings, stated plainly

- **35 pages**, United States Letter, 612 by 792 points. Claim confirmed.
- **The demonstration notice is on page 1**, prominent, above the contents, legible in
  greyscale.
- **No total row repeats.** Verified by reading pages 25 to 29 line by line and searching
  all 35 pages for duplicate totals. The defect that would have done the most damage is
  gone.
- **Table headers repeat.** Pages 27 and 28 each open with their table's repeated header
  row.
- **No figure splits.** `.fig`, `.panel`, `.note` and `figcaption` all carry
  `break-inside: avoid`. Confirmed on a contact sheet of all 35 pages and on four pages
  at full size.
- **Tables do split**, three of them, which is correct for tables longer than a page and
  is what the print stylesheet intends. Rows never split. I record this because the
  earlier checklist row was worded "no table split", which was the wrong test.
- **The sticky bar is gone with no reserved space.** Page 1 begins at the normal margin.
- **Readable in black and white.** Four pages converted to greyscale and read. Figures 5
  and 8 in particular now carry their meaning without colour.

## Phone results, stated plainly

- Zero horizontal page overflow at 375, 768, 1024 and 1280.
- 11 of 14 visible drawing frames scroll sideways at 375, down from 13. Two at 768. None
  at 1024 or 1280.
- Figures 1, 2, 6 and 8 have purpose-built phone layouts and each one is correct: I
  looked at all four.
- Figure 13 still clips its thresholds (D3). Figure 3 opens on a cut word (D10).
- The affordance for the 11 scrolling frames is a hairline border and nothing else that
  renders (D2).

## Contrast, recomputed independently

I recomputed rather than accepting the claim. Walking every `<text>` and `<tspan>` in
every Scalable Vector Graphics (SVG) drawing, taking each label's fill, finding the
topmost painted shape whose bounding box contains the label's centre, compositing that
shape's fill and every alpha above it down through the DOM background stack to the page:

| Width | Text runs measured | Floor | Below 4.5 to 1 | Below 6.3 to 1 |
|---|---|---|---|---|
| 375 | 378 | **6.30 to 1** | 0 | 0 |
| 1280 | 368 | **6.30 to 1** | 0 | 0 |

The floor is the "when they are promoted" label in Figure 10, red `#A62020` on the red
tint `#FBE9E9`, at 6.30. The next four are grey `#4B5563` labels on the indigo and red
tints at 6.40 to 6.45. Plain panel labels composite at **6.79**. **The 6.30 claim and
the 6.79 composited claim are both confirmed by my own computation.** My run counts
fewer text nodes than the commit's 495 because I skip `<text>` elements that only wrap
`<tspan>` children, to avoid double counting.

## Other checks

| Check | Evidence | Result |
|---|---|---|
| Build clean, document page lint passes | "document page lint: 1 document page(s) carry no external references"; 39 files, 1503 KB, sha256 `f161d60e2f42f944` | PASS |
| Self-containment from `file://` with the network blocked | Copied the built file to a scratch folder, launched Chrome with `MAP * 127.0.0.1:1` and a dead proxy, loaded over `file://`: `performance.getEntriesByType('resource')` returned `[]`, 18 figures, 20 sized SVGs, full 45,150 pixel height, cover styling intact | PASS |
| Zero scripts | `document.querySelectorAll('script').length === 0` on the served page and the saved file | PASS |
| Sticky bar opens a new tab and survives being saved to a desktop | Both links `https://orvanna.io/`, absolute, `target="_blank"`, `rel="noopener noreferrer"`, still correct when loaded from `file://` | PASS |
| "wide reach", "Instant Payout", "Howard" absent from the brochure | 0, 0, 0. Also 0 for "Koziara" and "Unicity" | PASS |
| The rules and the numbers really are the same | Rank thresholds, paid depth, level rates 10/5/5/3/2, override 1.5 and 1.0, bonus 2.0/2.3/2.5, gate at 100.00 Sales Volume and the 20 percent ceiling all cross-checked between the two files | PASS, the link note's claim is true |
| Cold arrival: whose plan, what it is, how to reach the site | Cover names Orvanna International, states the business, states it is a demonstration; sticky bar reaches the site; printed footer gives orvanna.io | PASS on screen and on paper |
| comp-plan renders after the edits | Zero horizontal overflow, 20 figures, the layer diagram closes cleanly where the exception line was removed, the new note renders correctly in light theme | PASS |

---

## Re-gate requirements

Both gates must run again on the exact artifact that ships. For my gate to pass I need:

1. **D1 resolved.** The governance sentence removed or reconciled, and `comp-plan.html`'s
   two "compensation plan booklet" sentences pointed at a document that exists.
2. **D4 resolved.** The eight "this version" phrases swept, starting with the section
   fifteen heading on printed page 34.
3. Section fifteen re-printed and re-read on paper after both.
4. D2, D3 and D5 addressed or accepted with a reason on the record.

Nothing else. Items D6 to D11 are LOW and I would ship over them.

## Standing checklist rows added by this gate

- **Removing a stamp does not remove a claim.** When a version, date or supersession is
  taken off a cover, search the whole document for every sentence whose meaning depends
  on the identity that was removed: "this version", "governs", "supersedes", "effective",
  "the current". Read each one aloud against the new cover.
- **Two documents on one site may not both claim precedence.** Whenever a page asserts
  which document governs, find every other page that asserts the same thing and check
  that the arrows point the same way and at a document that exists.
- **A claimed affordance must be measured as rendered, not as declared.** A box shadow
  in the stylesheet is not a cue until its luminance step is measured; a styled scrollbar
  is not a cue until `offsetHeight - clientHeight` proves the browser reserved space for
  it.
- **A one-way link is a defect in the lighter document, not the heavier one.** If page A
  links to page B and B is the shorter read, B must name A and be able to return to it.
- **A legend of coloured swatches needs a word.** Where one figure solves greyscale with
  ordering words, every sibling figure with the same legend must adopt them.

---
---

# DELTA GATE 2: commit `3f43094`, 2026-08-17

- **Commit graded:** `3f43094` ("Final round: the governance claim goes, and an affordance that actually renders"), which also carries `f35c7cf` ("The document-page lint stops being a blocklist and becomes an allowlist")
- **Artifact graded:** `MLM-PILOT\deploy\dist\` rebuilt by `py deploy\build_dist.py`, bundle sha256 `6d987e0b6be7adf9`, 39 files, 1510 KB, served over Hypertext Transfer Protocol (HTTP) from `deploy\dist`
- **Grader:** mlm-qa. Read-only toward the product. Nothing was fixed.
- **Date:** 2026-08-17
- **Scope:** what changed, and everything my delta 1 findings touched. Per the coordinator I did not re-grade the printed total rows, the seven earlier closures or the pictures-only test except where a change could have disturbed them. Two changes could have, and I checked both: the only drawing altered is Figure 13's new phone layout, and the new caption line and edge bar add rendered ink, so I re-ran the contrast floor.

## VERDICT: PASS

## DEPLOY: YES

The HIGH is closed in both documents and in both directions. All four MEDIUMs are
closed. The affordance now renders, and it renders at the strength claimed: I sampled
it from the rendered image rather than reading the stylesheet, and it measures **9.21 to
1**, on the nail. The two deferred verifier items landed correctly, and I re-derived the
proration figures against the specification myself rather than accepting the wording.
Three LOW items remain and I would ship over all three.

---

## THE HIGH: closed, and closed both ways

`plan-brochure.html`, printed page 34, under "HOW THE RULES CHANGE, AND WHEN":

> This document explains the plan. It does not govern any other page, it settles no
> disagreement with one, and it retires nothing. Where it differs from the compensation
> plan page, that difference is not decided here.

Printed page 35, the footer:

> This document explains the three earning layers it describes. It governs nothing. It
> carries no version number and no effective date.

`comp-plan.html`, in two places, now claims the role instead of deferring to a document
that did not exist:

> There is no separate printed plan booklet, so this page, together with the version
> stamp in its footer, is the statement of the plan on this site. If a number here
> disagrees with a number anywhere else, this is the page to check it against.

> Which document governs. There is no separate printed plan booklet. This page, together
> with the version stamp in its footer, is the statement of the plan on this site.

Verified:

- **"governs" appears exactly once in 35 printed pages**, and that once is the negation.
  I searched the extracted print text of all 35 pages.
- **"booklet" no longer names a governing document.** The three remaining uses are the
  two pre-existing "the Builder extension has no field name and no booklet" rows and the
  new "There is no separate printed plan booklet" in both places. `plan-brochure.html`
  uses the word zero times.
- **The claim that no booklet is published is true.** There is an
  `ORVANNA-COMP-PLAN-BOOKLET.html` under `docs\`, but it is not in the page registry and
  I confirmed it is not in the built bundle, so it is not on the site.
- **No contradiction in either direction.** One document governs and says so; one
  explains and says it governs nothing. The brochure names the difference rather than
  resolving it, which is the correct posture for the document that does not draw the
  running-versus-modelled line.

---

## The four MEDIUMs

### D2, the affordance: CLOSED, and the root cause diagnosis is correct

The coordinator's account of the cause is right and matches what I measured last gate: an
inset box shadow on a scroll container paints under its content, and every drawing lays
an opaque ground across its whole viewBox, so the cue was covered by the thing it
described. My 1.02 to 1 measurement was the symptom of exactly that.

**I sampled the rendered pixels rather than reading the stylesheet.** Captured Figure 3's
frame at 375 with mobile emulation on and scrollbars not suppressed, then read the median
colour of each of the last sixteen pixel columns:

| Column | Sampled colour |
|---|---|
| x = 335, 336 | rgb(255, 255, 255), the drawing's own white ground |
| **x = 337 to 344** | **rgb(42, 62, 158), solid, eight columns wide** |
| x = 345 to 350 | rgb(245, 247, 250), the page band outside the frame |

Eight pixels exactly, painting **on top of** the opaque ground that used to hide it.
Computing the ratio from those two sampled values:

- Bar rgb(42, 62, 158) against the drawing's white ground: **9.21 to 1**
- Bar against the page band beside it, rgb(245, 247, 250): **8.58 to 1**

**The 9.21 to 1 claim is confirmed by pixel sampling**, and it is measured against the
surface the bar actually sits on.

The other cues, measured rather than read:

| Claim | What I measured | Verdict |
|---|---|---|
| Cue scoped to scrolling frames only | At 375: 13 visible frames, **10 scrolling, 3 fitting**. All 10 scrolling frames carry borders (top, right, bottom, left) of (1, **8**, 1, 1) with right colour rgb(42, 62, 158). All 3 fitting frames carry (1, 1, 1, 1) and no indigo. **Zero frames that fit carry the cue** | Confirmed |
| Caption line in each | `.scrollnote` computed `display: block` with a live `offsetParent` on all 10 scrolling frames and hidden on all 3 fitting frames. Text: "Scrolls sideways inside its frame", rendered upper case. Sampled from the image, ink rgb(42, 62, 158) on rgb(245, 247, 250): **8.58 to 1** | Confirmed |
| Ten pixels of reserved scrollbar on all ten frames | **10.0 pixels exactly** on all ten, with classic scrollbars. With mobile emulation on, Chrome switches to overlay scrollbars and reserves **0**, as it does on a real phone | Confirmed as styled; see the note below |
| Zero of 35 printed pages | Printed the document again: **0 occurrences** of the caption line in the extracted text of all 35 pages, and `.scrollnote { display: none }` under `@media print` | Confirmed |
| Scrolling frames down from 13 to 10 | 10 at 375 and at 559; the wide layout returns at 560 | Confirmed |
| Scoping is right | The cue is scoped by class, `.fig:not(.w340):not(.hasphone)`, not by measurement. The classes happen to be exactly correct: the 3 `.w340` figures are the 3 that fit and the 5 `.hasphone` figures are the 5 with phone layouts, and 18 minus 3 minus 5 is the 10 I measured scrolling | Correct, though it will need re-checking if a drawing is ever resized |

**Looked at it.** Figure 3 at 375 now shows a solid indigo bar down the right edge of the
frame and "SCROLLS SIDEWAYS INSIDE ITS FRAME" in indigo capitals directly above
"FIGURE 3". It is unmistakable. This is a real fix, not a re-description of the old one.

**The one note, and it does not change the verdict.** The reserved scrollbar is the one
cue that still depends on the browser: 10 pixels with classic scrollbars, 0 on a phone
using overlay scrollbars. That no longer matters, because the two cues that do the work,
the eight pixel bar and the caption line, render on a phone and I measured both there.
The claim would be exactly right if it read "ten pixels wherever the browser reserves a
track".

### D3, Figure 13 on a phone: CLOSED

**Looked at it at 375.** A fifth phone layout, `viewBox 0 0 340 460`, is the only new
drawing in this commit. Every rung's requirement is fully readable: "qualified, Team
Volume 40,000.00+, 2+ legs each holding a Leader or above" through to "enrolled, nothing
else required". The staircase indentation survives, the frame does not scroll, and
correctly it carries no cue.

### D4, "this version of the plan": CLOSED with one survivor

The heading on printed page 34 is now **"WHAT THIS DOCUMENT DOES NOT COVER"**, and three
of its four bullets read "the plan described here". Count is **8 down to 1**, not to zero.

**The survivor, printed page 34, first bullet:** "Refunds and reversals. **This version**
has no rule for reversing volume or reclaiming commission after a refund." It sits ten
lines above "This document carries no version number and no effective date". LOW, listed
below as D12, but the "down to 0" count in the hand-off is off by one and worth recording
so the next sweep does not trust it.

### D5, the return path: CLOSED

Two links, both naming the destination and saying what is there rather than selling it:

- Contents page: "There is a companion page, the Orvanna compensation plan page. It
  covers the same plan and separates what is running today from what is only modelled.
  This document does not draw that line, so read that page for it."
- Footer: "The companion page, which separates what is running today from what is only
  modelled, is the Orvanna compensation plan page."

Both are descriptive and both are honest about the one difference. On paper the companion
page is named but its address is not printed; only orvanna.io is. LOW, D13.

### D8, the restored Instant Payout figure: CLOSED, and worded better than I asked

Section ten's note now prints the gap: "The worked example above pays 42.00 on a 150.00
first order, which is 28 percent of the price against a 20 percent ceiling, eight points
over." I checked the arithmetic: 42.00 over 150.00 is 28.0 percent exactly, and 28 minus
20 is eight points.

The anti-gaming section carries it a second time and frames it correctly: "Nor does the
bound cover the approved Instant Payout terms, and **that is a fact about the bound
rather than about the ceiling** ... 28 cents on the dollar, above the 20 this bound
implies ... **It is not an exception to the ceiling: the ceiling has none.**" That is the
right sentence, and it is the one that keeps Howard's absolute ceiling intact while
naming the number.

---

## The coordinator's own change: the absolute return links

Tested as asked. `plan-brochure.html` contains **zero relative or root-relative `href` or
`src` values**; every reference is either a same-document anchor, `https://orvanna.io/`,
or `https://orvanna.io/comp-plan.html`. Copied the built file to a scratch folder and
loaded it over `file://` with every host mapped to a dead address and a dead proxy:
`performance.getEntriesByType('resource')` returned `[]`, 18 figures present, 20 sized
Scalable Vector Graphics (SVG) drawings, full 45,610 pixel height, zero scripts, and all
four links still absolute. **Nothing dies when the file is saved.**

One asymmetry, LOW, D14: the two new comp-plan links carry no `target` and no `rel`,
while the sticky bar carries `target="_blank" rel="noopener noreferrer"`. From a saved
file, clicking a return link replaces the local document in the same tab.

---

## The two deferred verifier items, checked as new content

### The proration sentence. I re-derived it rather than matching the wording.

The designer flagged that it matched wording without re-deriving. I derived it against
`docs\ORVANNA-BUILDER-PLAN-SPEC.md`.

The brochure's new sentence: "Measured across the modelled runs, 154 of the 641
Conductor-months that carried any volume were reduced on at least one layer: 24.0
percent, or roughly one in four. It is not rare. Your level pay is never among them."

| Element | Specification | Recomputed |
|---|---|---|
| 154 bind on at least one layer | Spec: "**154 bind on at least one layer**, of which 34 bind only at layer 3" | Matches |
| 641 denominator | Spec: "the 1,001 denominator includes **360 sources with zero volume that can never bind**. Against the **641 sources that have any pool at all**" | 1,001 minus 360 is 641. Matches |
| 24.0 percent | Spec: "**154 of 641 = 24.0 percent, roughly ONE IN FOUR**" | 154 / 641 = 0.240250, which is 24.0 percent. Correct |
| The unit | Spec calls them sources or member-months; comp-plan defines the unit once as a source member-month and the brochure says Conductor-months | **Carried over in comp-plan's own unit, correctly.** The brochure never says orders |
| comp-plan's sub-counts, 120 at the override layer, 83 at the bonus layer, 34 bonus-only | Spec: "120 is the count of sources whose LAYER 2 factor binds; 83 bind at layer 3 ... 34 bind only at layer 3" | Matches, and it is internally coherent: 120 + 83 minus 154 is 49 binding at both, 83 minus 49 is the 34 bonus-only |
| comp-plan's "35 of the 207 paid Conductors carry at least one reduced line" | Spec: "**35 of the 207 paid members, 17 percent**" | Matches |
| "Your level pay is never among them" | Spec: the spine "by construction is never prorated" | **True** |

Both pages also record that an earlier draft printed "120 of 1,001", which is the
self-correction the specification asks for. **The figures are right.**

### Bundles and packs added to what carries volume. Verified against the catalogue.

The brochure's new item: "Bundles and packs, $200.00 to $800.00 a month, 200 to 800 PV.
The Manager Agent bundle at $200.00 and 200 PV; the Ignition Pack at $200.00 and 200 PV;
the Momentum Pack at $400.00 and 400 PV; the Constellation Pack at $800.00 and 800 PV."

Checked against `db\migrations\019_shop_to_comp_bridge.sql`:

```
('AGT-P-001', 'Ignition Pack',      'pack', 200.00, 200.00, null),
('AGT-P-002', 'Momentum Pack',      'pack', 400.00, 400.00, null),
('AGT-P-003', 'Constellation Pack', 'pack', 800.00, 800.00, null)
```

and the Manager Agent bundle at $200.00 per `faq.html`. **All four products exist, and
every price and Personal Volume figure matches the seeded catalogue.** Each also obeys
the brochure's own rule that Personal Volume equals the price in dollars.

The incoherence is closed: the one-time example now reads "A $2,000.00 one-time purchase,
which is what the Ignition Pack costs when it is bought once rather than monthly", and
$200.00 a month over the ten-month recognition window is $2,000.00, recognised at 200
Personal Volume a month. It reconciles.

One inherited tension I record without grading, because it predates this commit and is
disclosed on the page: `comp-plan.html`'s not-settled table still says "Version 1.3 of
this plan recognises volume from the twelve individual agents only. Bundle, pack, and one
time volume is not yet part of Sales Volume", while the brochure now lists bundles and
packs under what carries volume. The brochure describes the plan whole and comp-plan
draws the running line, which is exactly the difference both pages now disclose, so the
two are consistent under their own stated division of labour.

---

## Regression checks on things a change could have disturbed

| Check | Evidence | Result |
|---|---|---|
| Build clean after rebuild | 39 files, 1510 KB, sha256 `6d987e0b6be7adf9`; document page lint, name lint, secret scan, page registry, nav drift, theme boot, chrome sheet and currency mirror all pass | PASS |
| 35 printed pages | Reprinted: **35 pages**, 612 by 792 points | PASS |
| Printed total rows still appear once | Reprinted and searched all 35 pages: "Totals" twice, once per table, each under the last row it totals; "Layer one, fifteen lines" once. No duplicate footer | PASS, not disturbed |
| Demonstration notice still on printed page 1 | Present, first tinted panel on the page | PASS |
| Contrast floor, with the new bar and caption ink added | Recomputed over every SVG label: **6.30 to 1** at both 375 (383 runs) and 1280 (368 runs), zero below 4.5, zero below 6.30. New caption line sampled from the image at **8.58 to 1** | PASS, not disturbed |
| Zero horizontal page overflow | 0 at 375, 559, 560, 768, 1024 and 1280 | PASS |
| Pictures-only test | The only drawing changed is Figure 13's new phone layout, which I looked at and which is correct and complete. No existing drawing was altered, so the ruling from delta 1 stands | PASS, undisturbed |
| Self-containment from `file://` with the network blocked | Zero resource entries, 18 figures, zero scripts | PASS |
| "wide reach", "Instant Payout", "Howard", "Koziara", "Unicity", "version 2.0", "Supersedes" in the brochure | 0 each | PASS |
| "second-team bonus" anywhere | 0 in both files | PASS |
| No em or en dashes | 0 and 0 in both files | PASS |

---

## LOW defects remaining

- **D12. One surviving "This version".** `plan-brochure.html`, printed page 34, the
  refunds bullet under "WHAT THIS DOCUMENT DOES NOT COVER". Eight down to one, not to
  zero. Change it to "The plan described here has no rule for reversing volume", matching
  the three bullets beside it.
- **D13. The companion page's address is not printed.** On paper the reader is told to
  read "the Orvanna compensation plan page" but is given only orvanna.io, not
  orvanna.io/comp-plan.html. One line in the footer would close it.
- **D14. The two return links do not open a new tab**, while the sticky bar does. From a
  saved file they replace the local document.
- **D6, D7, D9, D10, D11 from delta 1 stand**, unchanged and unaddressed: the five colour
  key still collapses in black and white (strokes 1.01 to 1.26 to 1, tints 1.004 to 1.044
  to 1, computed); Figure 16's legend is still the one place the key is colour only; the
  printed copy still has no page numbers; Figure 3 still opens on a cut word at 375; and
  printed page 30 still ends in white space. I would ship over all of them.

---

## Deploy

**YES.** Both documents are safe to publish as built at sha256 `6d987e0b6be7adf9`. The
HIGH is closed in both directions, all four MEDIUMs are closed, the affordance renders at
the strength claimed and I verified it by sampling pixels, the proration figures are
right against the specification, and the bundles and packs are real products at the
prices stated. What remains is eight LOW items, none of which misleads a reader.

`plan-brochure.html` is now the strongest document on this property. The figure
architecture is correct, the arithmetic reconciles to the cent, it prints to 35 clean
pages, it survives being saved to a desktop with no network, and a reader who looks only
at the drawings finishes with the plan and no wrong impression.

## Standing checklist rows added by this gate

- **Read every border side, not the top one.** My first probe of this affordance read
  `borderTopWidth` and reported 1 pixel where the cue was an 8 pixel `border-right`. I
  caught it and withdrew it before reporting, but the row is now permanent: when a cue is
  described as an edge, measure the edge it names.
- **An inset shadow on a scroll container is never a cue.** It paints under the content,
  and any drawing with an opaque ground will hide it. Use a border, which paints above.
- **A cue scoped by class is only as right as its classes.** When an affordance is
  applied by `:not()` selectors rather than by measured overflow, re-check the mapping
  every time a drawing is resized.
- **A count claimed as "down to zero" gets counted.** This gate's was down to one.

---
---

# DELTA GATE 3: commit `2b20e11`, 2026-08-17

- **Commit graded:** `2b20e11` ("Section 1A: where each part of the plan comes from")
- **Artifact graded:** `MLM-PILOT\deploy\dist\` rebuilt by `py deploy\build_dist.py`, bundle sha256 `b0e7a0b59cf55c93`, 39 files, 1522 KB, served over Hypertext Transfer Protocol (HTTP) from `deploy\dist`
- **Grader:** mlm-qa. Read-only toward the product. Nothing was fixed.
- **Date:** 2026-08-17
- **Scope:** a narrow delta. Section 1A and its figure, plus everything the insertion could have disturbed: figure numbering, section numbering and every cross-reference, printed pagination, the contrast floor, the phone affordance mapping, table total rows, self-containment.
- **One item not re-investigated, per the coordinator:** the two links to the compensation plan page are absolute by deliberate choice, because a relative link dies when the file is saved. I confirmed they work from a saved file and left the decision alone.

## VERDICT: PASS

## DEPLOY: YES

The section does what it was built to do, the figure does not overstate, and the phone
defect the measurement caught is genuinely fixed: I looked at the lineage figure on a
375 pixel screen and it is visible, legible and complete. Six LOW findings, all new, none
of which misleads a reader. I would ship over all six, and I would spend the two minutes
on two of them before Howard sends the link.

---

## How this was graded

The Browser pane again would not composite frames, exactly as in the two previous gates.
Rather than fall back to reading the Document Object Model (DOM), which my standing lesson
says is not visual proof, I drove a real Chrome over the Chrome DevTools Protocol (CDP).
I looked at:

- section 1A rendered at 1280 pixels, captured in four full width slices, top to bottom;
- the lineage figure at 375 pixels with mobile emulation on, captured at the clipped frame
  width so the capture is what a phone reader actually sees, at three scroll positions
  (left, middle, right), plus the whole section in seven slices at 375;
- Chrome's own print output at United States Letter, rendered back to images at 110 dots
  per inch, printed pages 3 through 8 at full size;
- printed page 5 converted to greyscale, to test the document's own promise that nothing
  depends on telling colours apart;
- the built file copied to a scratch folder and loaded over `file://` with every host
  mapped to a dead address and a dead proxy.

Every number below that I state as measured, I measured in this session.

---

## RULING 1: TONE. Does it read as a designer, or as somebody answering an accusation?

### It reads as a designer naming the tradition the work sits in. PASS, and not marginally.

This is the ruling I was asked for most, so here is the reasoning rather than the verdict
alone. I read the section on screen and on paper as a compensation specialist would, from
the kicker to the closing note, then read it a second time looking only for the shape of a
rebuttal.

**Four things make it read as engineering:**

1. **The question in the heading is a provenance question, not a denial.** "Where each
   part of this plan comes from" asks where the parts came from. A defensive section would
   have been titled around what the plan is not. Nothing in the section is phrased as the
   negation of an unstated charge.
2. **The organising device is a failure mode table**, which is an engineering artifact.
   The four columns are Mechanism, The family it comes from, The known failure mode, Why it
   is not present here. That is how a designer documents a build, and it is the same shape
   a reliability review takes.
3. **Every claim is a forward reference to evidence in this same document.** Section seven,
   sections eight and eleven, section eight, section ten. I followed all four and every one
   lands on the section that proves the claim (see Ruling 3). A rebuttal asserts; this
   cites.
4. **It flatters the reader's expertise rather than defending against it.** "Anybody who
   knows this industry should recognise every part on sight" hands the specialist the
   position of the person who already knows. That is the opposite move to a defence.

**The one place the shape comes closest to a rebuttal**, and it is worth naming so the
ruling is honest: the figcaption's last clause, "the argument for it is not that the parts
are new but that each one arrives without the abuse that family is known for." The
construction "the argument is not X but Y" concedes a counterargument. But the
counterargument it concedes is about the design, whether the parts are novel, not about an
accuser, and the sentence resolves into a design claim. It stays on the right side.

**Would a defensive reading be available to a hostile reader?** I looked for one and could
not build it without adding words that are not on the page. The section never says copy,
original, derivative, similar, unlike, competitor, accusation or any cognate. I swept for
all of them and for thirty four company names: zero occurrences (Ruling 2).

**My judgement on whether it should exist at all:** it should, and it should be exactly
where it is. Read on printed page 5, before any mechanics, it hands the specialist the
vocabulary they already own and tells them what to expect. Read after the mechanics it
would have read as a rebuttal, because by then the reader would have formed the question
the section answers. The placement is the thing that makes the tone work, and it is right.

**The one tonal note I would change**, graded LOW below as D18: the word "abuse". It
appears twice, both times in the two most-forwarded surfaces, inside the drawing and in the
figcaption. The table uses "the known failure mode" for the identical idea and is better
for it. "Abuse" is a moral word about other plan families, aimed at a reader who probably
works inside one of them. It is the only place in the section where the register leaves
engineering.

---

## RULING 2: NO COMPANY NAMED, NO COMPARISON MADE OR IMPLIED

### Confirmed. Only plan families.

Swept the section markup, the rendered text, the table, the figure's `<title>` and its 963
character `<desc>` (which a screen reader speaks, and which is therefore rendered text for
an assistive reader), and the extracted text of printed pages 5 and 6.

| Sweep | Result |
|---|---|
| Thirty four direct selling company names | **0 occurrences**, in the section and in the whole file |
| "Unicity" anywhere in the file | **0** |
| Comparison and accusation cognates: competitor, unlike, in contrast, compared to, copied, copy, stolen, steal, accus, allegat, plagiar, borrowed, similar to, resembl, imitat, clone, derivative, not a copy, knock-off, my employer, another company | **0 occurrences each**, in the section and on printed pages 5 and 6 |
| What is named instead | Five plan families only: the unilevel, generational and breakaway, the binary, standard leadership bonus structure, standard solvency discipline |

The comparisons that do appear are to families in the generic ("In a classic breakaway,
promoting a leader removes their whole group"; "Binary plans invite strategic placement"),
which is what the brief permits and what a taxonomy requires. No company, no product, no
person, no implied single target.

---

## RULING 3: DOES THE FIGURE OVERSTATE?

### No. Every protection the drawing claims is proved in this document, and I checked each one against the section it cites.

This is the check that failed an earlier round of this document, when a chart implied the
plan punished a behaviour it does not. I traced all five.

| What the drawing claims | Where it says the proof is | What that section actually says | Verdict |
|---|---|---|---|
| Volume theft is absent: "Nothing ever leaves your group here" | Section seven | "**No breakaway: developing a Builder never costs you volume**" | Claim proved |
| Placement gaming and carryover are absent: "No placement tree exists here, legs are the real sponsorship, and nothing carries over" | Sections eight and eleven | Section eight: "this plan has **no second tree to place anybody in and nothing that carries forward** from one month to the next". Section eleven: "**Nothing carries over** ... Nothing is banked, carried forward, retained or grandfathered ... **There is no carryover**" | Claim proved, both halves |
| Cliff effects are absent: "The steps here are shallow, and each one needs another active person, not a purchase" | Section eight | "The rate steps are **deliberately shallow**. Large steps at round numbers are what produce end-of-month buying to cross a threshold, and the arithmetic below shows why these steps are **never worth chasing**." Figure 13 works it: 12.00, then 9.20, then 7.50, and its caption closes "**no reason for anybody to buy anything at the end of a month to cross a threshold**" | Claim proved, including the "not a purchase" half, which I specifically went looking to break |
| Cost drift is bounded: "enforced per order inside the calculation, not reviewed afterwards" | Section ten | "the ceiling is **not a monitoring policy applied afterwards. It is the arithmetic the payments are calculated by**, so no combination of ranks, depths or organisation shapes can push an order past 20 percent" | Claim proved |
| Passivity toward development is absent: "Layers two and three pay for that, and **the spine is untouched**" | Implicit, and load-bearing | Section ten: "Level pay draws first and is **always paid in full** ... so level pay always fits and is **never reduced**" | Claim proved |

**Nothing in the drawing claims a protection the plan does not have.** The two things I did
find are not overstatements of protection; they are a broken pattern and an absolute
industry claim, and both are LOW (D16 and D17).

I also re-read the drawing as a pictures-only reader, which is this document's own bar.
Reading only the boxes and the words inside them, the reader gets: one hard ceiling
containing everything, three named modules standing on a named base, each module's origin
family, each family's known weakness, and one sentence per module saying why that weakness
is not here. No wrong reading is available from the drawing alone.

---

## RULING 4: THE PHONE

### The lineage figure is visible and legible at 375 pixels. I looked at it. CONFIRMED.

The defect the commit describes is real and is genuinely closed. The figure now carries
`class="fig w880"` with no `hasphone`, so it renders its full drawing inside a scrolling
frame rather than deferring to a phone variant that does not exist. Measured at 375 with
mobile emulation on:

| Measurement | Result |
|---|---|
| Visible Scalable Vector Graphics (SVG) inside the lineage frame | **840 by 520 pixels, rendered**, not hidden, not zero sized |
| Frame | 330 pixels of visible width against 844 of scroll width |
| Scroll cue, right border | **8 pixels**, `rgb(42, 62, 158)` |
| Caption line | `.scrollnote` computed `display: block`, reading "SCROLLS SIDEWAYS INSIDE ITS FRAME" |
| Page level horizontal overflow at 375 | **zero** |

**Then I looked, which is the part that counts.** Three captures at the clipped frame
width, at the left, middle and right scroll positions:

- **At rest**, the phone reader sees the amber ceiling frame opening on the left, its
  heading and its description, the whole of the first module (Generation overrides, layer
  two) including its complete "leaves behind" paragraph, the left edge of the second module
  cut mid word, the connector stub running down, and the unilevel spine below with its
  heading legible. **The containment reads. The standing-on reads.** Nothing suggests the
  plan has one module, because the second one is visibly cut and the indigo bar and the
  caption line both say the frame scrolls.
- **Mid scroll**, the second module (Second-leg bonus, layer three) is whole and every word
  of it readable.
- **Fully right**, the third module (The leg-count multiplier) is whole, the ceiling frame
  closes on its right edge, and the spine closes with it.

**Ruling against the standing rule** that a figure whose meaning is its overall shape must
fit the narrowest supported width: this figure passes, and I considered failing it. Its
meaning is containment and stacking, and both of those survive at rest, because the
ceiling's left edge, one whole module, the connector and the spine are all on screen at
once. That is the difference between this figure and the two that failed the rule in the
first gate: Figure 6 lost the top of its organisation and Figure 8 lost three of five
ranks, so their meaning could never be assembled. Here the meaning is present at rest and
the scroll adds detail rather than restoring sense.

---

## RULING 5: PRINT

### 37 pages, and the section lands where the commit says it does. Verified on paper.

Chrome print pipeline, United States Letter, 612 by 792 points.

| Promise | Evidence | Result |
|---|---|---|
| 37 printed pages, up from 35 | **37 pages** | Confirmed |
| Section on printed page 5 | "SECTION 1A / WHERE EACH PART OF THIS PLAN COMES FROM" opens on **page 5**, directly under section one's closing note | Confirmed |
| Before any mechanics | Section two, "The words, defined before they are used", opens on **page 7**. Nothing mechanical intervenes | Confirmed |
| The figure whole and unsplit | **Looked at printed page 5.** Ceiling frame, all three modules, connectors, spine, in-drawing closing line and the Figure 3 caption are all on page 5 | Confirmed |
| The table whole and unsplit | **Looked at printed page 6.** Header row plus all five rows, from "Layer one, the unilevel spine" to "The twenty percent ceiling", then the closing note, all on page 6 | Confirmed |
| The section takes two pages | Pages 5 and 6 | Confirmed |
| Readable in black and white | Printed page 5 converted to greyscale and read. Every box is named in words and the structure is positional, so nothing in the new figure depends on colour. The five stroke colours separate by only **1.01 to 1.26 to 1** in greyscale, computed, and the figure does not care | Confirmed |

One print defect, D19 below: printed page 6 ends with an orphaned "SECTION TWO" kicker
whose heading is on page 7. It is the **only** orphaned kicker in 37 pages; I checked all
sixteen.

---

## RULING 6: NUMBERING AND CROSS-REFERENCES

### Section numbering: intact. Every existing number and every cross-reference still valid.

I clicked all sixteen contents links in a real browser and read what landed.

| Result | Evidence |
|---|---|
| 16 of 16 links land on the correct section | Each landing section's kicker and heading match its contents entry word for word |
| Zero land one section away | Sections one through fifteen all unchanged; 1A sits between 1 and 2 |
| Zero pixels of heading covered by the sticky bar | Covered pixels equal 0 on all sixteen |
| Every prose cross-reference still correct | Swept every "section <name>" reference in the file, thirty of them, and resolved each to the section it names. **All correct**, including the four the new section adds: seven (Layer two, the Builder override), eight (Layer three, the second-leg bonus), ten (The twenty percent ceiling), and eight and eleven together |

### Figure numbering: renumbered completely, and I checked for the failure mode this creates.

The new drawing is Figure 3, so Figures 3 through 18 became 4 through 19. That is the kind
of change that leaves a stale "as Figure 6 shows" somewhere in the prose.

**It does not.** Each of the nineteen strings "Figure 1" through "Figure 19" occurs
**exactly once** in the whole file, and each of those single occurrences is inside a
`.fignum` span in its own figcaption. There is not one cross-reference to a figure number
anywhere in the body text, so there is nothing to go stale. Nineteen figures counted in the
rendered DOM at all four widths.

---

## Undisturbed checks

| Check | Evidence | Result |
|---|---|---|
| Build clean | 39 files, 1522 KB, sha256 `b0e7a0b59cf55c93`; document page lint, stamp assertion, name lint, secret scan, page registry, nav drift, theme boot, chrome sheet, chrome css and currency mirror all pass | PASS |
| **Contrast floor 6.30 to 1 across drawing labels, recomputed** | Recomputed independently: walked every `<text>` and `<tspan>` in every visible SVG, took each label's fill, found the topmost painted shape whose bounding box contains the label's centre, composited that shape's fill and every alpha above it down through the DOM background stack. **Floor 6.30 to 1** at 375 (420 runs), 768, 1024 and 1280 (405 runs each). **Zero below 4.5, zero below 6.30** at every width | PASS, claim confirmed |
| No new contrast pair introduced | The new figure's worst label is "LEAVES BEHIND", grey `#4B5563` on the indigo tint `#E8ECF9`, at **6.40**. That exact pair already existed on pre-existing labels ("Commissionable Volume, 0.80 x" and "reaches 2 levels"), and the floor is still the pre-existing red-on-red-tint label at 6.30 | PASS, claim confirmed |
| Section 1A's own Hypertext Markup Language (HTML) text contrast | Composited every text-bearing element in the section against its real background stack: 39 elements, **floor 7.29 to 1** (the "Section 1A" kicker). Zero below 4.5 | PASS |
| Zero horizontal page overflow | Document scrollWidth equals clientWidth at 375, 768, 1024 and 1280 | PASS |
| Zero labels outside a viewBox | Walked every `<text>` bounding box against its owning viewBox across 26 SVGs at all four widths: **0 violations**. The new figure alone: 37 labels, 0 outside | PASS |
| Zero overlap | Pairwise bounding box test across every label pair in the new figure: **0 overlaps**. Across the whole document the only hits are 1 to 2.7 pixel grazes between adjacent lines of pre-existing figures, which are ascender and descender box artifacts, not visual collisions | PASS |
| Print overflow | No drawing clipped or split on any printed page; `.fig` and `figcaption` carry `break-inside: avoid` | PASS |
| Total rows still appear once each | Reprinted all 37 pages and searched every one. "Totals" on pages 28 and 30, **once each**, each directly under the last row it totals. "Layer one, fifteen lines" once, on page 29. The third "Totals" on page 36 is prose, not a footer. **No total appears twice anywhere** | PASS, not disturbed |
| Zero external references with the network blocked | Copied the built file to a scratch folder, launched Chrome with `MAP * 127.0.0.1:1` and a dead proxy, loaded over `file://`: `performance.getEntriesByType('resource')` returned an empty array, **19 figures**, 26 SVGs, zero scripts, full 48,093 pixel height, section 1A present, its drawing rendering at full width. All four links still absolute | PASS |
| Scroll affordance on exactly the frames that scroll | At 375: **11 frames scroll, 8 do not**. All 11 scrolling frames carry the 8 pixel `rgb(42, 62, 158)` right border and a `display: block` scrollnote. **All 8 non-scrolling frames carry the 1 pixel grey border and no note.** Zero false positives, zero false negatives. Up from 10 scrolling, because the new figure correctly joins them | PASS |
| Forbidden words absent | "wide reach", "Instant Payout", "Howard", "Koziara", "Unicity", "version 2.0", "Supersedes", "second-team bonus": **0 each**, in the source and in the extracted text of all 37 printed pages | PASS |
| No em or en dashes | **0 and 0** in the whole file and in all 37 printed pages | PASS |
| Console clean, zero scripts | One network 404 for `/favicon.ico`, which Chrome requests on its own and which the page does not reference. Zero page-originated messages, zero `<script>` tags | PASS |
| Figure accessibility | The new SVG carries `role="img"`, `aria-labelledby="f2at f2ad"`, an 83 character `<title>` and a 963 character `<desc>` that walks the whole assembly. **Zero duplicate element identifiers in the file** | PASS |
| Return links | Both compensation plan links now carry `target="_blank" rel="noopener noreferrer"`, which closes delta 2's LOW D14 | Closed |

---

## LOW defects, all new to this commit

### D16. The fifth table row is not the same kind of row as the other four

**Location:** the "The twenty percent ceiling" row, and the ceiling block in the drawing.

For four of the five parts, the named failure belongs to the family the mechanism comes
from: the unilevel is passive toward development, breakaway steals volume, binary invites
placement gaming, leadership bonuses cliff. For the ceiling, the named failure is **cost
drift in plans that do not have the mechanism**: the cell reads "Cost drift. **Uncapped
plans** see the payout ratio creep upward". Nothing is untrue, but the column header
promises "The known failure mode" of the family in the previous column, and solvency
discipline's known failure mode is not cost drift. The figure's own `<title>` says "each
with its known failure **removed**", and for the ceiling nothing was removed.

A specialist reading five parallel rows will notice the fifth is not parallel. One sentence
fixes it: name the failure mode of weak caps rather than of no caps, for example a cap that
is a target reviewed after the month rather than arithmetic applied per order, which is
exactly what the "why it is not present here" cell already argues against.

### D17. "Every professionally administered plan has one" is the one sentence a specialist can falsify from memory

**Location:** the drawing, "Standard solvency discipline. Every professionally administered
plan has one." And the table, "Caps and payout governors are ordinary practice in **every**
professionally administered plan."

A hard per-order payout ceiling is not universal. The common practice is a target payout
ratio managed after the fact, which is precisely the cost drift the same cell describes.
The section's whole strength is that everything in it is checkable, and this is the only
absolute industry claim in it. "Ordinary practice in professionally administered plans"
says the same thing and cannot be contradicted. Recommend dropping the word "every" in both
places.

### D18. "Abuse" is the only word in the section that leaves the engineering register

**Location:** the drawing's closing line, "each part arrives with its best-known **abuse**
absent from the arithmetic", and the figcaption, "each one arrives without the **abuse**
that family is known for". Two occurrences, both in the surfaces most likely to be
screenshotted and forwarded.

The table says "the known failure mode" for the identical idea. "Abuse" is a moral word
about other plan families, read by somebody who probably works inside one. It does not make
the section defensive, which is why this is LOW and not higher, but it is the one place
where a reader could feel judged rather than informed. Swap both to "failure mode" and the
section is uniform with its own table.

### D19. Printed page 6 ends with an orphaned "SECTION TWO" kicker, the only one in 37 pages

**Location:** print stylesheet. `h2` carries `break-after: avoid` but `.kicker` does not.

I checked all sixteen section kickers on paper. Fifteen sit with their headings. Only
section two is split: page 6 ends with "SECTION TWO" and page 7 opens with "THE WORDS,
DEFINED BEFORE THEY ARE USED" carrying no number. The insertion of section 1A is what
pushed it across the boundary, so this commit caused it, and the gap in the stylesheet is
what allowed it. One declaration closes it: `.kicker { break-after: avoid; page-break-after:
avoid; }` in the print block. Cosmetic, but this page is going to a professional and it is
a two minute fix.

### D20. The ceiling block is the one block in the drawing whose closing sentence does not negate

**Location:** the drawing, the payout ceiling block.

Every other block ends by explicitly saying the failure is not here: "Nothing ever leaves
your group here", "nothing carries over", "The steps here are shallow", "the spine is
untouched". The ceiling block ends "Cost drift. **It** is enforced per order inside the
calculation, not reviewed afterwards." The pronoun means the ceiling, but the nearest noun
is cost drift, so the sentence momentarily reads as though cost drift is what is enforced.
The drawing's header is "LEAVES BEHIND", which is itself readable in two directions, and
this is the one block where the sentence beneath it does not settle the direction. Replace
"It is enforced" with "The ceiling is enforced" and the ambiguity is gone.

### D21. At 768 pixels the lineage figure scrolls with no affordance, joining two figures that already did

**Location:** the scroll cue is scoped to a maximum width of 559 pixels.

Measured: at 768, three figure frames scroll (Figures 1, 3 and 7, all `w880` against a
narrower content column), and **none of the three carries the cue**, because the cue only
exists below 560 pixels. At 1024 and 1280, none scroll. This is a pre-existing pattern and
the new figure is one more instance of it, not a new class of defect. Page level overflow at
768 is still zero. I record it because the previous gate counted "two at 768" and the
correct number is now three.

---

## LOW defects carried over, unchanged

D6, D7, D9, D10, D11, D12 and D13 from the previous gates all stand and are unaddressed:
the five colour key on the contents page still collapses in black and white (strokes 1.01
to 1.26 to 1, recomputed this session); Figure 17 (formerly 16) is still the one legend
that is colour only; the printed copy still has no page numbers, now across 37 of them;
Figure 4 (formerly 3) still opens on a cut word at 375; the one surviving "This version" in
the refunds bullet is still there; and the companion page's full address is still not
printed. **D14 is now closed**: both compensation plan links carry `target="_blank"` and
`rel="noopener noreferrer"`.

---

## Deploy

**YES.** Safe to publish as built at sha256 `b0e7a0b59cf55c93`, and safe for Howard to send
to a compensation specialist.

The section reads as a designer naming the tradition, not as a defence. It names five plan
families and no company, and makes no comparison to one. Every protection the drawing
claims is proved in a section of this same document, and I followed all five. The figure is
visible and legible on a phone, which is the defect the measurement caught and which I
confirmed with my own eyes at three scroll positions. On paper it is 37 pages, the section
opens on page 5 before any mechanics, and both the figure and the table are whole. Every
section number and every cross-reference survived, and the figure renumbering left nothing
stale because the document never cites a figure by number.

If two things are changed before the link goes out, make them D17 (drop "every" from the
two absolute industry claims) and D19 (one declaration so the section two kicker stops
being orphaned on paper). Neither is a gate condition.

## Standing checklist rows added by this gate

- **Inserting a figure renumbers every figure after it.** Before passing any commit that
  adds a drawing, count every occurrence of "Figure N" in the file and prove each number
  occurs exactly the number of times it should. A body-text citation of a figure number is
  the failure this creates, and it is silent.
- **Inserting a section repaginates everything after it.** Re-print and re-check the orphan
  and widow behaviour of every heading, kicker and table, not only the new one. The commit
  changes pages it never touched.
- **A parallel table must be parallel in every row.** When a table's column header promises
  one relationship, read the last row against the first and confirm it is the same kind of
  claim. The row that breaks the pattern is usually the one about the mechanism the author
  is proudest of.
- **An absolute claim about the industry is a claim, and it is the easiest one to falsify.**
  "Every professionally administered plan", "the most common", "the oldest": each needs to
  be either provable or softened, because the reader who checks it is the reader the
  document was written for.
- **A section written to pre-empt a reaction gets read twice**, once for what it says and
  once for the shape it takes. Cite-and-prove is a designer's shape. Assert-and-deny is a
  defendant's shape. Rule on the shape, not on the sentences.

---

# Re-gate, 2026-08-17 17:47: the two fixes named above, commit `dccf12e`

- **Commit graded:** `dccf12e` ("The two the gate said to fix before the link goes out")
- **Artifact graded:** `MLM-PILOT\deploy\dist\plan-brochure.html`, built by `py deploy\build_dist.py`, bundle sha256 `e27cd32fa0c9ebe3`, served over Hypertext Transfer Protocol (HTTP) and printed through Chrome's own print pipeline
- **Scope:** deliberately narrow. Only the two fixes, and any regression they caused. The document was not re-graded.
- **Grader:** mlm-qa. Read-only toward the product. Nothing was fixed.

## VERDICT: FAIL

## DEPLOY: NO

Both fixes are half-landed. Neither failure is a wrong number and neither is expensive to
close, but each is exactly the thing the fix set out to remove, still present.

- **Fix 1 closed one of the two places D17 named.** D17 above reads, word for word,
  "Recommend dropping the word 'every' in **both** places." The table row was corrected.
  The drawing was not. Printed page 5 still reads "Standard solvency discipline. **Every
  professionally administered plan has one.**" That is the same claim in a stronger form,
  one page before the row that was softened.
- **Fix 2 removed the text orphan and left a rule orphan in its place.** The kicker's
  decorative rule is drawn by `.kicker::before`, which is a block inside the kicker.
  `break-after: avoid` stops a break after the kicker but not one inside it, so the break
  simply moved up by one box: the teal rule now stays behind on the previous page and the
  kicker text goes over. Printed pages 6 and 35 each end with a short teal dash labelling
  blank paper, and two of the sixteen section openers now start with no rule above them
  while the other fourteen have one.

## How this was graded

The Browser pane again refused to composite frames, as at every previous gate of this
document. I drove a real Chrome over the Chrome DevTools Protocol (CDP) and used
`Page.printToPDF` at US Letter, and I printed the **passed** commit `2b20e11` the same way
so every claim below is a measured before-and-after rather than a recollection.

## Acceptance checklist

| # | What the brief asked me to confirm | Evidence | Result |
|---|---|---|---|
| 1 | The new sentence renders | Printed page 5 of the after build, table row four: "Caps and payout governors are long-standing practice in this industry." Read on paper at 200 dots per inch | PASS |
| 2 | It is true as written and needs no defending | "Long-standing practice in this industry" asserts prevalence over time, not universality. Nothing falsifies it by counterexample | PASS |
| 3 | The old absolute is gone from the whole file | **No.** `Every professionally administered plan has one` survives in the Figure 2 drawing, source line 835, printed page 5 at y=335 | **FAIL, defect R1** |
| 4 | Nothing else in that row or table shifted | The row is character-identical outside the replaced clause, and no other content line in the file changed. Confirmed by `git diff 2b20e11..dccf12e`: two hunks only | PASS |
| 5 | The SECTION TWO orphan is gone | Page 6 of the before build ended on the kicker at y=712; page 7 of the after build opens with the kicker and its heading together | PASS |
| 6 | The document is still 37 printed pages | Chrome print pipeline, US Letter 612 by 792 points: before **37**, after **37** | PASS |
| 7 | No new orphan or widow appeared anywhere | Every one of the 37 page boundaries checked in both builds. Zero kicker orphans and zero heading orphans remain, and every page break falls between whole paragraphs, whole bullets or whole table rows. **But two decorative rules are now stranded** | PARTIAL, defect R2 |
| 8 | Nothing that must stay whole now splits | 31 of 37 printed pages are byte-identical to the passed build at 110 dots per inch. The 6 that changed (6, 7, 8, 35, 36, 37) were read on paper one by one: the lineage table, the terms table, the glossary table, Figure 4, the "Stated in one sentence" panel, the Team Volume panel and the legal panel are each whole on a single page | PASS |

## Two findings the prior gate got wrong, recorded for the record

- **The Section Two orphan was not the only one.** D19 states "It is the **only** orphaned
  kicker in 37 pages; I checked all sixteen." Measured on the printed before build, page 35
  also ended on the "SECTION FIFTEEN" kicker with "LEGAL NOTICE AND INCOME DISCLOSURE"
  overleaf. There were two. The one rule closed both, so the fix did more good than it was
  credited for, but the prior count was wrong.
- **The count of sixteen section kickers was right.** Sections one through fifteen plus
  section 1A is sixteen, and the file carries eighteen kickers in all once the cover and
  the contents kicker are counted. The error in D19 was the orphan count, not this one.

## Defects

### R1. MEDIUM. Half of D17 shipped, and the stronger half is the half that stayed

**Location:** `www/plan-brochure.html` line 835, the Figure 2 drawing. Printed page 5.

The corrected table row and the uncorrected drawing sit one page apart and describe the
same mechanism. The drawing is the surface most likely to be screenshotted and forwarded,
which the prior gate said about a different word in D18. As written, the drawing asserts
that a hard per-order payout ceiling is universal, which is the claim D17 established is
not true. The commit message states the absolute "now reads long-standing practice in this
industry", which is true of the table and not of the document.

Closing it is two `<text>` lines in the drawing.

### R2. MEDIUM. The break rule moved the orphan up one box instead of removing it

**Location:** `www/plan-brochure.html` print block, the `.kicker` declaration added by this
commit.

Measured across both builds by locating every short teal rule near the left margin and
asking whether a kicker follows it on the same page:

| Build | Rules that label a kicker | Rules stranded with nothing under them |
|---|---|---|
| `2b20e11`, passed | 18 of 18 | 0 |
| `dccf12e`, this commit | 16 of 18 | **2**, on printed pages 6 and 35 |

On page 35 the stranded dash sits above roughly a third of a blank page. On pages 7 and 36
the section opener begins flush at y=42 with no rule, against y=64 to y=70 and a rule at
every other section opener in the document.

**Verified remedy, one declaration.** I copied the built file to a scratch folder, added
`break-inside: avoid; page-break-inside: avoid;` to the same `.kicker` rule, and printed it
through the identical pipeline. Result: 37 pages, zero kicker orphans, and 18 of 18 rules
travelling with their kicker. That is the state the fix was aiming at. The remedy was tested
on a scratch copy only; the product was not touched.

## Standing checklist rows added by this re-gate

- **A finding that names two locations is not closed until both are closed.** When a defect
  cites "both places", grade it by re-reading every location it named, not by reading the
  commit message. Half a fix reads as a whole fix in a diff.
- **A print break rule fixes the box, not the ink.** After adding any `break-after` or
  `break-before` declaration, check the fixed element's pseudo-elements, borders and rules
  as well as its text. `break-after: avoid` does not hold an element together internally;
  `break-inside: avoid` is usually needed beside it, and the tell is a decorative mark left
  alone at the foot of a page.
- **Print the previous build too.** Grading pagination against memory of a prior report is
  how the second orphan survived a gate that said there was one. Printing both builds and
  comparing page images makes the unchanged pages provable and shrinks the reading to the
  pages that actually moved.

---

# Re-gate 2, 2026-08-17 18:0x: commit `33db578`

- **Commit graded:** `33db578` ("Close both halves, and the reason I missed one")
- **Artifact graded:** `MLM-PILOT\deploy\dist\plan-brochure.html`, bundle sha256 `65e2102f3246a2ef`, printed through Chrome's own pipeline over the Chrome DevTools Protocol (CDP) at US Letter, against the `2b20e11` baseline printed the same way
- **Scope:** the two fixes and any regression. The document was not re-graded.

## VERDICT: FAIL

## DEPLOY: NO

Both fixes are now correctly and completely closed. Every number the coordinator asked me
to prove came out at the predicted value. One new widow appeared, caused by the remedy I
myself recommended, and I did not catch it when I tested that remedy. It is one line to
close and it is the last thing standing between this document and the link.

## The six confirmations requested

| # | Asked | Measured | Result |
|---|---|---|---|
| 1 | 37 pages, unchanged | baseline **37**, this commit **37** | PASS |
| 2 | Zero kicker orphans, including page 35 | baseline had **2** (pages 6 and 35); this commit has **0** | PASS |
| 3 | 18 of 18 rules travelling with their kicker | **18 of 18**, zero stranded, the number the remedy predicted | PASS |
| 4 | The absolute gone from rendered text in both locations | Printed text of all 37 pages: `professionally administered` **0**, `Every professionally` **0**, `ordinary practice` **0**. Markup-stripped source: **0** each. Page 5 now reads "Standard solvency discipline. Long-standing practice in this industry.", page 6 "Caps and payout governors are long-standing practice in this industry." The figure's accessibility description never carried the claim | PASS |
| 5 | Nothing else in the figure or the row shifted | `git diff dccf12e..33db578` is two Scalable Vector Graphics (SVG) `<text>` lines and one style declaration. SVG text is absolutely positioned, so no reflow is possible; the ceiling panel is otherwise pixel-unchanged | PASS |
| 6 | No new orphan or widow, nothing that must stay whole splits | Zero splits: no figure, table or panel touches a page edge in either build. **One new widow**, defect R3 | **FAIL** |

## R3. LOW. A one-word widow at the page 8 to 9 boundary

**Location:** the section three lead paragraph. Printed pages 8 and 9.

Holding the kicker together moved the section three opener down by about 22 points, which
pushed the last word of its lead paragraph across the boundary. Page 8 now ends
"...Commissionable Volume, which is the only one any commission is calculated" and page 9
opens with the single word **"from."** alone above Figure 3. In the passed baseline that
paragraph was whole at the foot of page 8.

A one-word line alone at the top of a page is the most recognisable typographic fault there
is, and this document is going to a professional. It is the same class of defect as the
kicker orphan that was worth fixing before the link went out, so it gets the same treatment.

**Verified remedy, one declaration, tested properly this time.** I printed three candidates
through the identical pipeline and audited each one for page count, kicker orphans, rule
census, splits and widows across all 37 boundaries:

| Candidate | Pages | Kicker orphans | Rules | Splits | Widows |
|---|---|---|---|---|---|
| `33db578` as it stands | 37 | 0 | 18/18 | 0 | **"from." on page 9** |
| `p, li { orphans: 2; widows: 2 }` | 37 | 0 | 18/18 | 0 | **unchanged**, Chrome's default is already 2 |
| `p, li { orphans: 3; widows: 3 }` | **38** | 0 | 18/18 | 0 | closed, at the cost of a page |
| **`.lead { break-inside: avoid; page-break-inside: avoid; }`** | **37** | **0** | **18/18** | **0** | **closed** |

The last one is the answer. The whole section three opener, rule, kicker, heading and lead
paragraph, travels to page 9 as a unit; only pages 8, 9 and 10 change; the page count holds
at 37. Tested on a scratch copy only. The product was not touched.

## My own miss, recorded

I recommended `break-inside: avoid` on `.kicker` in the previous re-gate and reported it as
verified. It was verified for the three things I measured (page count, kicker orphans, rule
census) and not for the fourth (widows), and the widow was already present in my scratch
print. The coordinator applied a remedy I under-tested.

## Standing checklist rows added by this re-gate

- **A recommended remedy is graded to the same standard as a shipped fix.** Before reporting
  any pagination remedy as verified, run the full boundary audit on it: page count, kicker
  orphans, rule census, split blocks and widows at all boundaries. Measuring only the thing
  the remedy targets is how a remedy ships a new defect.
- **Every pagination change gets a widow scan, not just an orphan scan.** The scan: for each
  page, take the first text line, and flag any body-size line under 200 points wide starting
  at the left margin. It found this in one pass and would have found it in the last one.
- **Search rendered text, not source, on this document.** Its drawing labels are split
  across `<text>` elements, so a phrase can be plainly visible on the page and absent from
  the file as a searchable string. Strip markup, or read the printed Portable Document
  Format (PDF) text, before claiming any wording is gone.
