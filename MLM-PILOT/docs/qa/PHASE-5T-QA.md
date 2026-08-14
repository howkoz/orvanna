# Phase 5T QA: The Real Team Round (team.html, teaser, ?v=5.0)

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-14
Scope: the pre-deploy SOURCE at `MLM-PILOT\www\`, served locally at
http://127.0.0.1:8641 (python http.server). Round under test, ruled by Howard
today: orvanna-designer's new `www\team.html` (roster of ten, geometric marks,
two-gate figure, phase rail), Team added to every nav, the homepage's fictional
leadership section replaced by a ten-mark teaser, every cache stamp unified to
?v=5.0; orvanna-writer's final copy in all 17 team.html slots and 2 index.html
slots; and the manager's one-line authoring-comment fix in `www\js\catalog.js`.
The manager deploys only on this gate's PASS.

## Verdict (read this first)

**PASS.** 31 rows executed: 31 PASS, 0 FAIL. 0 HIGH defects, 2 MEDIUM findings
(both on surfaces this round did not build: a leftover fictional leader in the
homepage's separate "Our story" section, and the pre-existing "soon" pill's
computed contrast of 4.13 to 1), 2 LOW notes. Every promise of the round is
delivered: all ten members render with the exact names and titles, zero
placeholder brackets, zero Chief Financial Officer text, every number in the
copy is in the sanctioned set, Team is in every nav and click-navigates, the
teaser renders ten marks and links to team.html, every stamp is exactly
?v=5.0, catalog.js parses with its new byte-order mark and matches the live
baseline on all 16 items, and both new pages hold 375-pixel width with no
horizontal scroll and a clean console.

Acronym key: QA (Quality Assurance), AI (Artificial Intelligence), CIO (Chief
Information Officer), CFO (Chief Financial Officer), CSS (Cascading Style
Sheets), JS (JavaScript), SVG (Scalable Vector Graphics), HTML (Hypertext
Markup Language), PV (Personal Volume), BOM (Byte-Order Mark), DOM (Document
Object Model), URL (Uniform Resource Locator).

## Method note

Promises first: the checklist below was written from the round brief before any
file was opened. Evidence came from three layers: static reads and Python byte
scans of every file in `www\` (dash characters, BOM, placeholder brackets, CFO
text, cache stamps), git diffs against HEAD (proving login.html changed by
stamp only and catalog.js by exactly the comment line plus the BOM), and a live
browser pass against the locally served site at desktop and 375-pixel widths
(console reads, rendered-DOM queries, computed-style contrast with alpha
compositing, and a scripted click from the staff console to team.html). The
catalog spot check downloaded https://orvanna.io/js/catalog.js and compared
every price and Personal Volume (PV) field on all 16 items, not just three.

## Checklist

### A. team.html completeness (brief item 1)

| # | Item | Evidence | Grade |
|---|---|---|---|
| A1 | Page loads, zero console errors | Loaded at desktop and 375 width; read_console_messages: no console logs either time | PASS |
| A2 | Every relative href/src resolves | Server log for the whole session: zero 404s except the browser's automatic /favicon.ico probe (pages declare assets/favicon.svg, which serves 200); corporate.css?v=5.0, logo, favicon all served; styles provably applied (computed colors match the stylesheet) | PASS |
| A3 | All TEN members present, correct names and titles | Rendered text in order: Howard Koziara "Founder and Owner"; Fable "Chief Information Officer (CIO)"; mlm-architect "Chief Systems Architect"; mlm-db-engineer "Head of Data Engineering"; mlm-comp-engineer "Head of Commission Engineering"; mlm-site-builder "Head of Web Engineering"; orvanna-designer "Design Director"; orvanna-writer "Head of Content"; mlm-verifier "Head of Verification"; mlm-qa "Head of Quality Assurance". Ten of ten, exact | PASS |
| A4 | Human is the circle, agents are hexagons | Howard's mark is the only circle-based SVG (r=34 filled circle, HK monogram); Fable and all eight specialists use the hexagon polygon (points 48,6 84.4,27 ...) | PASS |
| A5 | NO Chief Financial Officer text anywhere | Case-insensitive scan for "chief financial officer" and "CFO" across all 8 www files: 0 hits | PASS |
| A6 | Zero [WRITER: brackets | Byte scan across all www files: 0 occurrences of "[WRITER" | PASS |
| A7 | Two-gate figure has real copy | Figure renders with BUILDER, VERIFIER GATE, QUALITY ASSURANCE GATE, PHASE CLOSED, BOTH MUST PASS, FAIL RETURNS A DEFECT LIST labels, plus a role="img" aria-label narrating the flow and a caption line | PASS |
| A8 | Four phase-rail cards have real copy | Phase 1-2 Foundation, Phase 3 The engine, Phase 4-5 The portal, This site The property: all four carry finished body copy, no stubs | PASS |

### B. Truth audit on the copy (brief item 2)

| # | Item | Evidence | Grade |
|---|---|---|---|
| B1 | Every quantity on team.html is sanctioned | Complete census of rendered numbers: 1,000-member (twice), roughly 24,000 orders, six months matched to the cent (twice, as "Six months of runs" and "computed to the cent"), two days August 13 to 14 2026, one human plus nine agents (and its decomposition: eight specialists plus Fable). Phase labels 1-2, 3, 4-5 trace to the roadmap. "Went live at orvanna.io the same week it was specified" verified true (Phase 5 shipped 2026-08-14). No revenue, no countries, no member counts beyond the set | PASS |
| B2 | Every quantity in the index teaser is sanctioned | Teaser section text: "One human. Nine agents.", "nine named agents", "eight specialist agents", Howard and Fable named with correct titles. Nothing else quantified | PASS |
| B3 | No invented staff count beyond ten/nine | Roster is exactly 10 rendered cards; teaser renders exactly 10 marks; copy consistently says one human plus nine agents | PASS |

### C. Nav integrity (brief item 3)

| # | Item | Evidence | Grade |
|---|---|---|---|
| C1 | Team link on index, shop, product, team | `<a class="nav-link" href="team.html">Team</a>` present in all four navs (is-active state on team.html itself); target loads 200 | PASS |
| C2 | Team link on staff console-links strip | staff.html line 32: `<a class="console-link" href="team.html">Team</a>`; scripted click navigated the browser from staff.html to team.html, title "Orvanna Team" | PASS |
| C3 | Enroll still a non-clickable "soon" pill everywhere | On index, shop, product, team the Enroll element is a SPAN (aria-disabled="true") with the soon-pill, verified in the rendered DOM; login and staff have no Enroll control | PASS |
| C4 | login.html unchanged in nav terms | git diff against HEAD: exactly one changed line, the corporate.css stamp 4.1 to 5.0; login.html has no nav and gained none | PASS |
| C5 | No dangling link to a removed leadership anchor | No page carries an href to #leadership or #leadership-old; the teaser section itself now owns id="leadership" on index.html, so even an external deep link to /#leadership lands on the real team teaser | PASS |
| C6 | Staff "Member portal" link | Still `../site/index.html` in source; confirmed this is the pre-deploy form that `deploy\build_dist.py` (lines 24 to 25) rewrites to portal/index.html at deploy time, exactly as Phase 5 verified live. Not a defect in source | PASS |

### D. Homepage teaser (brief item 4)

| # | Item | Evidence | Grade |
|---|---|---|---|
| D1 | Teaser renders ten marks | Rendered DOM query: `.teaser-marks > svg` count = 10 (HK circle plus nine hexagons, each reusing its owner's team.html mark) | PASS |
| D2 | Teaser links to team.html | `<a class="btn btn-ghost" href="team.html">Meet the team</a>` present and target serves | PASS |
| D3 | Old fictional bios absent from rendered output | Rendered-DOM text search: Liora Sen, Dorian Vesk, Maren Ostrey all absent; zero `.leader` cards render; id="leadership-old" does not exist in the DOM (comment only). Auren Vale's BIO is likewise gone; his name survives elsewhere, see finding M1 | PASS |
| D4 | Fiction preserved only inside the WRITER REFERENCE comment | The four leader cards exist solely inside the `<!-- WRITER REFERENCE ONLY ... -->` comment block, index.html lines 346 to 418 | PASS |

### E. Cache stamps (brief item 5)

| # | Item | Evidence | Grade |
|---|---|---|---|
| E1 | Every stylesheet/script reference is exactly ?v=5.0 | Grep across all six pages: corporate.css?v=5.0 on all six; shop.css?v=5.0 on shop and product; staff.css?v=5.0 on staff; catalog.js?v=5.0 on shop, product, staff. That is every versioned reference | PASS |
| E2 | No 4.x stamp anywhere | Same grep: zero ?v=4 hits; the only unversioned "catalog.js" strings are inside authoring comments and prose, not references | PASS |

### F. catalog.js (brief item 6)

| # | Item | Evidence | Grade |
|---|---|---|---|
| F1 | BOM state and parse | First three bytes are EF BB BF (UTF-8 BOM, added by the PowerShell write; git diff shows it on line 1). Browsers strip the BOM on external scripts: shop.html renders all 16 product cards, product.html?sku=payment renders title, price, and PV, staff.html loads it clean. Zero console errors on any page. Tolerable per the brief; recorded as finding L1 | PASS |
| F2 | Comment no longer names Howard | Line 7 now reads "per the house pricing rule"; grep for "Howard" in catalog.js: 0 hits (live baseline still says "per Howard's rule", confirming the change is local and pending deploy) | PASS |
| F3 | Prices and PV unchanged from live baseline | Downloaded https://orvanna.io/js/catalog.js and compared every price, priceOnce, pv, pvOnce field on ALL 16 skus (not just three): zero numeric differences. Spot rows: payment 1000/1000, manager 2000/2000, constellation 8000/8000, all MATCH | PASS |
| F4 | Only intended changes in the file | git diff against HEAD: exactly two hunks, the BOM on line 1 and the one comment line. Nothing else touched | PASS |

### G. House rules (brief item 7)

| # | Item | Evidence | Grade |
|---|---|---|---|
| G1 | Zero em dashes (U+2014) and en dashes (U+2013) | Python character scan of all six pages, catalog.js, and corporate.css: 0 and 0 in every file | PASS |
| G2 | Acronyms expanded on first use, per page, reading order | team.html: "artificial intelligence (AI)" in the intro lead precedes every bare AI; "Chief Information Officer (CIO)" at first use; "Quality Assurance (QA)" expanded in the mlm-qa card (the agent name "mlm-qa" is a proper name, and "Head of Quality Assurance" is spelled out above it). index.html: AI expanded in the hero before the teaser's uses; CIO expanded in the teaser note | PASS |
| G3 | Money format | No money values on team.html or the index teaser, as expected; the product page (regression surface) shows $100.00 and $1,000.00, two decimals | PASS |

### H. Responsive at 375 width (brief item 8)

| # | Item | Evidence | Grade |
|---|---|---|---|
| H1 | team.html: no horizontal scroll | Computed at 375x812: documentElement.scrollWidth 375 = innerWidth 375, horizontal scroll false | PASS |
| H2 | index.html: no horizontal scroll | Same check: 375 = 375, false. Shop, product, and staff also verified false while passing through | PASS |

### I. Contrast standing rule (brief item 9, computed, alpha-composited)

| # | Item | Evidence | Grade |
|---|---|---|---|
| I1 | Teaser button meets 4.5 to 1 | btn-ghost (the "Meet the team" style): rgb(226,232,240) on effective rgb(6,11,24) = 15.94 to 1. btn-solid: rgb(5,18,28) on rgb(34,211,238) = 10.47 to 1 | PASS |
| I2 | Footer links meet 4.5 to 1 | flink spans and the a.flink Team link: rgb(148,163,184) on composited rgb(5,9,20) = 7.76 to 1; footer-mail 12.79 to 1; legal line 5.68 to 1 | PASS |
| I3 | New chip/tag styles meet 4.5 to 1 | role-tag rgb(165,180,252) = 9.86 to 1; tag-human rgb(34,211,238) = 10.87 to 1; phase-num 10.87 to 1; gate-caption 7.66 to 1 | PASS |
| I4 | Worst five elements on team.html reported | soon-pill 4.13 (pre-existing, finding M2), legal 5.68, member-bio 7.66, profile-bio 7.66, phase-body 7.66. Everything new this round sits at 7.66 or better | PASS |

## Findings

### HIGH (broken or missing deliverable)

None found.

### MEDIUM (works but off-spec or fragile)

1. **M1: Fictional leader Auren Vale still renders on the homepage.** The
   round removed the fictional leadership section, but index.html's separate
   "Our story" section (id="origin", lines 143 to 184) still renders "Orvanna
   began as a four-person team", a named fictional leader "Auren Vale, who led
   that first team", and his pull quote. This now sits on the same page as
   "One human. Nine agents." and contradicts it: a reader meets a four-person
   human origin story two scrolls above the disclosure that one human and nine
   agents are the whole company. The section was not in this round's stated
   scope, so no checklist row fails, but under the truth-audit rule it is a
   flagged claim: "four-person team" is a quantity outside the sanctioned set,
   rendered on the audited page. Suggested owner: orvanna-writer, one section
   rewrite (the WRITER REFERENCE comment block is separate and fine where it
   is).
2. **M2: The "soon" pill computes below the contrast floor.** .soon-pill:
   rgb(100,116,139) at 8.8 pixels 600 weight on composited rgb(6,11,24) =
   4.13 to 1, below the 4.5 to 1 standing floor for text. Pre-existing style,
   present on every nav since the Enroll pill shipped, not introduced this
   round, and the label is a two-state status hint rather than an action
   control, which is why this is MEDIUM and not HIGH. One shade lighter (for
   example the rgb(124,138,160) used by .legal, 5.68 to 1) clears the floor.

### LOW (cosmetic, bookkeeping)

1. **L1: catalog.js now opens with a UTF-8 byte-order mark.** EF BB BF from
   the PowerShell write. Harmless in every browser tested here (all pages
   parse it, shop renders, console clean) and tolerated by the brief. Recorded
   because (a) the file is now byte-different from the live copy by more than
   the comment line, so any future byte-identity audit (like Phase 5 row H3)
   must expect it, and (b) a plain-text editor or a strict JS concatenator
   would show it as an invisible first character. Stripping it at the next
   legitimate edit keeps the file boring.
2. **L2: /favicon.ico probes 404 locally.** The browser's automatic root
   favicon request misses because the site declares assets/favicon.svg (which
   serves 200). Same behavior exists on the live origin; purely cosmetic in
   server logs.

## Out of scope, verified elsewhere

The deploy rewrite of the staff and login portal links (../site/ to portal/)
belongs to `deploy\build_dist.py` and was proven live in the Phase 5 QA report;
this round's source keeps the pre-deploy form on purpose (row C6). The portal,
shop checkout flow, and Supabase reads were untouched by this round and keep
their Phase 4C.2 and Phase 5 grades.

## Verdict

**PASS.** 31 rows: 31 PASS, 0 FAIL. The real-team round delivers everything it
promised: ten members with exact names and titles and the one-circle-among-
hexagons identity system, finished copy in all 19 writer slots with only
sanctioned numbers, Team in every nav including the staff console strip, a
ten-mark teaser replacing the fictional leadership section with the fiction
demoted to a non-rendering writer comment, every cache stamp at ?v=5.0, and a
catalog.js that parses cleanly with its new BOM, no longer names Howard, and is
numerically identical to the live baseline on all 16 items. Two MEDIUM findings
ride along for a decision, not as blockers: the Auren Vale remnant in "Our
story" (M1, the honesty ruling's loose end) and the pre-existing soon-pill
contrast (M2). The manager may deploy on this gate; the phase-close rule still
requires mlm-verifier's PASS alongside this one.

---

# DELTA: M1 and M2 fix verification (same day, 2026-08-14)

Graded by: mlm-qa. Scope: exactly the two fixes from the main pass plus the
regression edges the manager named. Fresh serve of `www\` at
http://127.0.0.1:8642, fresh console reads, fresh computed styles, fresh byte
scans. Both fixes verified against the source diff (index.html and
corporate.css are the only two files changed since the main pass).

## Delta verdict (read this first)

**PASS. M1 CLOSED. M2 CLOSED.** 13 delta rows executed: 13 PASS, 0 FAIL, no
new findings. The fictional origin story is gone from every rendered surface,
replaced by the true one-founder-nine-agents account using only sanctioned
facts, with the pull quote now the house rule itself. The pill's new color
computes 5.61 to 1 on the solid nav field and 5.50 to 1 over the strongest
glow wash by my own independent alpha-composited math (designer claimed 5.61
and 5.48; the 0.02 spread on the glow case is rounding in the wash layering),
and the border clears the 3.0 to 1 non-text floor at 3.28 and 3.26. Consoles
stay clean, stamps stay ?v=5.0, zero dashes introduced, and the #origin
section kept its heading, structure, and art untouched.

## Delta checklist

### DM1. The Our story rewrite (fix for finding M1)

| # | Item | Evidence | Grade |
|---|---|---|---|
| DM1.1 | No fictional person renders on ANY www page, comments stripped | Python scan of all six pages with `<!-- -->` blocks removed: Auren, Vale, Liora, Sen, Dorian, Vesk, Maren, Ostrey, "four-person", "four person": zero hits on every page. Confirmed again in the rendered Document Object Model (DOM): body.innerText carries none of the four names on index.html | PASS |
| DM1.2 | Every fact in the new #origin copy is sanctioned | Full census of the rendered section text: one founder ("founded by one person with a career spent in payment operations"), nine named agents, Fable the Chief Information Officer (CIO), two independent gates (verifier and quality assurance, described by function), two days August 13 to 14 2026, live at orvanna.io. No other quantity, date, revenue, or headcount appears | PASS |
| DM1.3 | Pull quote is the house rule | Rendered blockquote.pull-quote reads exactly "The builder never grades its own work." | PASS |
| DM1.4 | Acronym first-use order holds end to end on index.html | Rendered-text index positions: "artificial intelligence (AI)" at character 139 (the hero, first AI on the page); "Chief Information Officer (CIO)" at 2059 in #origin; the only bare CIO tokens sit at 2086 (inside the expansion itself) and 3663 (the teaser, now bare as the writer stated, correctly AFTER the #origin expansion). Reading order holds for both acronyms | PASS |
| DM1.5 | Homepage still contradiction-free | The page now tells one story twice: #origin (one founder, nine agents, two gates) and the teaser (one human, nine agents) agree. The four fictional leaders survive only inside the WRITER REFERENCE comment, which does not render (id="leadership-old" absent from the DOM) | PASS |

### DM2. The pill contrast fix (fix for finding M2)

| # | Item | Evidence | Grade |
|---|---|---|---|
| DM2.1 | New values actually applied | Computed styles in the live browser: .nav-link.is-soon color rgb(124,138,160) (#7C8AA0) and .soon-pill border rgba(124,138,160,0.7) on index, team, shop, AND product (the two pages that load shop.css after corporate.css) | PASS |
| DM2.2 | Text clears 4.5 to 1 on the solid nav field | Independent recompute, alpha-composited: nav glass rgba(6,11,24,0.78) over --navy #060B18 composites to rgb(6,11,24); #7C8AA0 against it = **5.61 to 1**. Matches the designer's claim exactly. (Old #64748B recomputed at 4.13, confirming the original finding) | PASS |
| DM2.3 | Text clears 4.5 to 1 over the strongest glow wash | Worst case under the nav is the indigo wash rgba(79,70,229,0.17) over navy, then the 0.78 glass over that: background rgb(8.7,13.2,31.7); #7C8AA0 against it = **5.50 to 1** (designer said 5.48; same conclusion, rounding in the wash layering). Floor is 4.5; clear | PASS |
| DM2.4 | Border clears 3.0 to 1 (non-text) | rgba(124,138,160,0.7) composited over each background, then ratioed against it: **3.28 to 1** solid, **3.26 to 1** over the glow (designer said 3.28 and 3.25). Floor for non-text user-interface parts is 3.0; clear | PASS |
| DM2.5 | No duplicate pill styles override the fix | Grep of css/shop.css and css/staff.css for "is-soon" and "soon-pill": zero hits in both. Proven functionally by DM2.1's computed values on shop and product; staff.html carries no Enroll pill at all (console-links nav), so nothing to override there | PASS |

### DR. Regression edges

| # | Item | Evidence | Grade |
|---|---|---|---|
| DR1 | index.html and team.html parse clean, zero console errors | Both pages loaded fresh from the delta server; read_console_messages after each: no console logs. Shop and product also loaded clean while proving DM2.1 (16 product cards render, catalog.js still fine). Zero 404s in the entire delta server log | PASS |
| DR2 | No em or en dashes introduced | Byte scan of all six pages and corporate.css after the fixes: 0 U+2014, 0 U+2013 everywhere | PASS |
| DR3 | Cache stamps still uniformly ?v=5.0 | Grep across all pages: zero ?v=4 hits; every corporate.css, shop.css, staff.css, catalog.js reference still ?v=5.0 | PASS |
| DR4 | #origin heading and structure unchanged, text-only edit | Rendered section: heading "From a single node", kicker present, exactly 2 body-dark paragraphs, 1 pull quote, origin-art SVG untouched. git diff since HEAD confirms the only two files changed for the delta are index.html and css/corporate.css. No horizontal scroll at 375 width on index or team | PASS |

## Delta verdict

**PASS.** 13 rows: 13 PASS, 0 FAIL. M1 closed: the fictional origin is gone
from every rendered surface and the replacement uses only sanctioned facts
with the house-rule pull quote. M2 closed: 5.61 and 5.50 to 1 for the pill
text, 3.28 and 3.26 to 1 for its border, all recomputed independently and all
above their floors. No regressions: consoles clean, stamps uniform at
?v=5.0, zero dashes, section structure intact. Cumulative state of the round:
0 HIGH, 0 MEDIUM open, 2 LOW notes standing (L1 catalog.js byte-order mark,
L2 the cosmetic /favicon.ico probe), neither blocking. The manager may deploy
on this delta.
