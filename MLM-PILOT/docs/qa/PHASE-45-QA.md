# Phase 4.5 QA Report: Staff Call Console

QA agent: mlm-qa (Verifier team). Builder never grades its own work; none of this was built by QA.
Date: 2026-08-14. Environment: http://localhost:9120 (console at /www/staff.html, portal at /site/).

## Method

Promises first: the acceptance checklist below was written from the ROADMAP.md Phase 4.5 entry and
the builder's claim list BEFORE any deliverable was opened. The Browser pane may be hidden, so
document-object-model presence was never accepted as visual proof. Every behavior was exercised
with real dispatched events (input, change, click, keydown) against the live page, and asserted on
the resulting document state. Per the standing computed-contrast rule, text contrast was computed
from getComputedStyle color against the effective background, resolved by ascending the element
tree and alpha-compositing every rgba layer, using the Web Content Accessibility Guidelines (WCAG)
luminance formula, floor 4.5 to 1. All live figures were checked against independent Supabase
Representational State Transfer (REST) calls made by QA with curl, never against the console's own
output. Cart math was hand-computed before it was compared.

Independent reference values (Supabase REST, period 2026-07-01):

| Member | Name | Rank | SV | TV | Statement total | Frontline |
|---|---|---|---|---|---|---|
| GW-000002 | Kai Eastbrook | Executive | 200.00 | 167,800.00 | $4,888.00 (658 rows) | 74 |
| GW-000014 | Casey Pinegrove | Member | 50.00 | 900.00 | $0.00 (0 rows) | 3 |

Hand-computed carts (tax 5 percent on subscription money plus one-time money):

- Cart A (GW-000002): Payment Agent monthly x1 plus Software Engineer one-time x2 = $100.00 per
  month plus $1,000.00 once; taxable 1,100.00; tax $55.00; total $1,155.00; 1,100 PV.
- Cart B (GW-000014): Manager Agent monthly x1 plus Tax Agent one-time x1 = $200.00 per month plus
  $1,000.00 once; tax $60.00; total $1,260.00; 1,200 PV.
- Cart C boundary (GW-000014): Quality Assurance monthly x1 = 50 PV; member Sales Volume (SV)
  50.00 plus 50 PV = exactly 100 combined; tax $2.50; total $52.50.

## Acceptance checklist

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| 1 | Lookup resolves GW-000002 WITH the GW- prefix | Typed "GW-000002", Enter; snapshot opened for GW-000002 | PASS |
| 2 | Lookup resolves GW-000002 WITHOUT the prefix | Typed bare "2"; exact match floated to top of typeahead and Enter selected GW-000002 | PASS |
| 3 | Prefix path on a second member | Typed "GW-000014"; resolved to Casey Pinegrove | PASS |
| 4 | Snapshot rank matches live data | Rank chip "Executive" (GW-000002), "Member" (GW-000014); equals rank_earned in v_demo_member_months | PASS |
| 5 | Snapshot SV matches live data | 200.00 and 50.00 rendered; equal to QA's independent pulls | PASS |
| 6 | Snapshot TV matches live data | 167,800.00 and 900.00 rendered; equal to independent pulls | PASS |
| 7 | Snapshot statement total matches live data | $4,888.00 (sum of 658 statement rows) and $0.00; equal to independent sums | PASS |
| 8 | Snapshot frontline count matches live data | 74 and 3; equal to independent v_demo_tree counts | PASS |
| 9 | Unqualified presentation for GW-000014 | "Not qualified · needs 50 PV more" with SV 50.00 | PASS |
| 10 | Qualified presentation for GW-000002 | "Qualified · 200 PV" | PASS |
| 11 | Synthesized block stable on re-lookup | GW-000002 phone (404) 555-0663, Provo Utah, card ending 1226 identical across three lookups including a full page reload; GW-000014 (702) 555-0127, Ann Arbor identical across reload | PASS |
| 12 | Synthesized block labeled demonstration data | "demonstration data" chip renders inside the verification block | PASS |
| 13 | Dropdown grouped with prices | Optgroups: Domain agents (6), Support agents (6), Bundles and packs (4); labels carry price and PV | PASS |
| 14 | 10x one-time repricing in the dropdown | Toggle to One-time relabeled Payment Agent $100.00 / mo to $1,000.00 once, Software Engineer $500.00 once, Constellation Pack $8,000.00 once; toggle back restores monthly | PASS |
| 15 | Quick order math, Cart A | Console showed $100.00 / mo, $1,000.00 one-time, tax $55.00, total $1,155.00, 1,100 PV; equals hand computation | PASS |
| 16 | Quick order math, Cart B | $200.00 / mo, $1,000.00 one-time, tax $60.00, total $1,260.00, 1,200 PV; equals hand computation; bundle "Includes Software Engineer, Secretary, Accounting" shown | PASS |
| 17 | Qualified meter arithmetic | Meter = live month SV plus order PV: 200 + 1,100 = 1,300 (A); 50 + 1,200 = 1,250 (B); 50 + 0 = 50 with "50 PV short" note on empty cart | PASS |
| 18 | Say-this line fires exactly at 100 combined | Cart C: meter read exactly "100 / 100 PV", fill 100 percent, line "This order qualifies you for the month." shown | PASS |
| 19 | Tax 5 percent | $55.00 on 1,100.00; $60.00 on 1,200.00; $2.50 on 50.00 | PASS |
| 20 | Digit tax exemption | Tax ID "TX-4" flipped label to "Tax exempt", tax $0.00, total dropped to $1,200.00; letters-only "pending" restored 5 percent; clearing restored again | PASS |
| 21 | Card-on-file default with member-specific card | Radio defaults to on-file; note showed "Visa ending 1226" (GW-000002) and "Visa ending 6286" (GW-000014); confirmation fact "Card on file, Visa ending 6286" | PASS |
| 22 | Keyed-card path to confirmation, no wallets | New-card radio revealed name, number, expiry, code fields; order placed; confirmation fact "New card, keyed during the call"; no wallet options exist on the page | PASS |
| 23 | Confirmation total in digits AND words, matching | "Your total today is $1,155.00: one thousand one hundred fifty-five dollars." and "$52.50: fifty-two dollars and fifty cents." | PASS |
| 24 | Phonetic spell-out correct for the actual number | ORV-2026-08-0CBS6G read as "O R V, then zero Charlie Bravo Sierra six Golf"; letter-for-letter correct | PASS |
| 25 | Renewal sentence only when subscriptions present, correct wording | Mixed cart: "Of that, $100.00 renews monthly...the rest is a one-time charge." Subscription-only cart: "The full $50.00 renews monthly until you cancel." | PASS |
| 26 | Activation line present | "Your agents come online within 48 hours; you will see them in your member portal." | PASS |
| 27 | Distinct order numbers across three orders | ORV-2026-08-0CBS6G, ORV-2026-08-0CCCZG, ORV-2026-08-0CCD4H; all distinct | PASS |
| 28 | Notes persist across reload, per member | Note typed for GW-000002 survived a full page reload; localStorage key orvannaStaffNotes keyed by member code | PASS |
| 29 | Notes do not bleed between members | After saving the GW-000002 note, GW-000014's notes area was empty, before and after reload | PASS |
| 30 | New call clears everything | Lookup, snapshot, notes (disabled again), order lines, tax ID, card fields, payment radio, billing mode, timer (00:00, not live), confirmation panel all reset; focus returned to lookup | PASS |
| 31 | Same caller keeps member, resets lines AND billing mode to subscription (claimed bug fix) | With mode on One-time at placement, Same caller kept GW-000002's snapshot and notes, cleared lines, reset Monthly aria-pressed true, payment back to on-file, card fields cleared, tax ID cleared, qty 1 | PASS |
| 32 | Keyboard: / focuses lookup | Dispatched "/" on body: default prevented, focus moved to lookup input; "/" typed inside the notes textarea stays in the textarea | PASS |
| 33 | Keyboard: Ctrl+Enter places the order | Dispatched Ctrl+Enter on document; order placed, confirmation shown; guard blocks it with the confirmation already open or an empty cart | PASS |
| 34 | Call timer runs on lookup, resets on New call | is-live class on select; cleared and 00:00 after New call | PASS |
| 35 | Portal header Staff link present and navigates | site/index.html carries the Staff link with the production-login title; click landed on /www/staff.html | PASS |
| 36 | Portal unbroken (regression) | Member search list populated on "7" (GW-000007, GW-000017, ...); My Volume tab switch activated tab and panel with content; footer shows 1,000 accounts, period 2026-07 | PASS |
| 37 | Production-login disclaimer present | Notice bar: "in production this sits behind a staff login...No payment is ever taken." | PASS |
| 38 | Cache-busted ?v=4.5 | corporate.css?v=4.5, staff.css?v=4.5, catalog.js?v=4.5 all requested and served 200 | PASS |
| 39 | Contrast floor 4.5 on interactive elements | 38 elements computed; every text-bearing element at or above 6.29 (see table below) | PASS |
| 40 | Zero console errors from the console | The only error in the tab is a 404 for /login.html logged BEFORE this QA session's first staff.html navigation (stale tab history from an earlier session); across the entire battery, every staff.html asset and data request returned 200 or 304 and no new error appeared | PASS |
| 41 | No horizontal scroll at 1280 | scrollWidth 1265 = clientWidth 1265; zero elements past the right edge | PASS |
| 42 | No horizontal scroll at 375; stat tiles and order table behave | Page scrollWidth 375 = clientWidth; order table wider than its wrapper but the wrapper is overflow-x auto so it scrolls inside itself; stat tiles hold a 2-column grid | PASS |
| 43 | Hygiene: no em or en dashes | Byte-level scan of staff.html, staff.css, site/index.html: none | PASS |
| 44 | Hygiene: acronyms expanded on first use | Sales Volume (SV) and Team Volume (TV) expanded; "Personal Volume (PV)" appears NOWHERE on staff.html while PV is used throughout (meter, Order PV, dropdown labels, qualification chips) | FAIL |
| 45 | Hygiene: no real personal data, no Unicity terminology, no secrets beyond the public anon key | All names synthetic, phones in the 555-01XX fictional block, only the public Supabase anon key present (same key the portal already ships) | PASS |

Rows: 45. PASS 44, FAIL 1.

## Contrast detail (worst five text-bearing interactive elements, computed)

| Element | Color on effective background | Ratio |
|---|---|---|
| Monthly segment button (active) | white on rgb(79,70,229) | 6.29 |
| Add line button | white on rgb(79,70,229) | 6.29 |
| Place order button | white on rgb(79,70,229) | 6.29 |
| Card-on-file note | rgb(148,163,184) on rgb(8,25,39) | 6.95 |
| Muted text family (chips, hints, labels, footer) | rgb(148,163,184) on rgb(6,11,24) | 7.66 |

One element computed below 4.5: the header logo anchor at 2.09, which is the browser default link
blue on an anchor that contains only the logo image and no text; no text renders at that ratio.
Logged as LOW-2, not a floor violation.

## Defects

### HIGH

None.

### MEDIUM

- M-1. Personal Volume (PV) is never expanded on staff.html. Howard's global rule (weight of the
  no-dash rule): every acronym expanded on first use in every deliverable. The page expands
  Sales Volume (SV) twice and Team Volume (TV) once, but PV, used in the meter, the Order PV row,
  every dropdown label, and both qualification chips, is bare everywhere. One-line fix: expand the
  first visible use, for example the meter label or the Order PV row, to "Personal Volume (PV)".

### LOW

- L-1. Order number collision window. The token is the millisecond-of-day in base 36 and the
  prefix carries year and month but not day (ORV-2026-08-0CBS6G). Two orders struck at the same
  millisecond of the day on different days of the same month would share a number. Distinctness
  held across the three test orders; this is a durability note for the demo, not a failure of the
  promise.
- L-2. The header logo anchor inherits the browser default link color rgb(0,0,238), ratio 2.09
  against the header. It wraps only the logo image so no text normally renders; alt-text fallback
  or focus styling would be unreadable. Cosmetic.

## Observations (not defects)

- v_demo_customer_volume has no 2026-07 rows for either test member; the console correctly shows
  Customer volume 0.00. QA verified independently that the view does hold rows for other members
  (GW-000001, GW-000003, GW-000004), so the zero is data truth, not a broken join.
- The call timer display pauses while the tab is hidden but the start timestamp is preserved, so
  the readout is correct when the tab is visible again. Consistent with the known
  requestAnimationFrame-hidden lesson.
- The stray /login.html 404 in the tab's network history predates this session (root-level
  login.html does not exist; the real file is /www/login.html). Nothing in staff.html references
  it. Whoever tested with a root-relative login link earlier may want to know.

## Verdict

PASS.

Every functional promise in the roadmap entry and the builder's claim list is delivered and
verified against independent data and hand-computed math, including the claimed Same-caller
billing-mode bug fix. The single failed row is hygiene (M-1, the unexpanded PV acronym), a
one-line label fix that should land before Howard's walk. Phase 4.5 still requires mlm-verifier's
independent PASS on the math to close.
