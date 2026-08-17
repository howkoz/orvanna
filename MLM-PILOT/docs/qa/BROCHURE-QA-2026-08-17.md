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
