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
