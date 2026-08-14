# Phase 4C QA: The Shop, Portal Connection Points, and Full-Property Regression

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-14 (overnight sweep, run while Howard sleeps)
Scope: `www\shop.html` + `www\css\shop.css` (NEW, the shop), `www\index.html` (nav Shop now
live), `www\login.html`, `site\index.html` + `site\css\portal.css` (new portal site links),
regression spot checks from `docs\qa\PHASE-4-QA.md`.
Server under test: http://localhost:9120 serving the MLM-PILOT root.

## Method note (read this first)

The Browser pane was HIDDEN again this session, so no screenshots. Every behavioral claim
below was verified against the LIVE page at localhost:9120 through the document object
model (DOM), the console log, and the network request log, with real dispatched clicks,
keyboard events, and form submits on the actual elements, plus viewport emulation at
1280x800 and 375x812 for the width rows. Money math was computed independently by hand
before comparing against the page. The one place a bare synthetic click was not enough:
the portal member-picker list items select on mousedown, so a plain element.click() alone
did not choose a member until mousedown was dispatched first; a real mouse fires both, so
that is a test-method footnote, not a defect. Similarly, one quantity-increase click in a
math combo landed on a detached node after the drawer re-rendered (test artifact, noted
inline); the final math rows were computed on the real re-rendered buttons and all match.

Acronym key: DOM (Document Object Model), PV (Personal Volume), SV (Sales Volume),
CV (Commissionable Volume), QA (Quality Assurance), AI (Artificial Intelligence),
CSS (Cascading Style Sheets), JS (JavaScript), REST (Representational State Transfer),
CDN (Content Delivery Network).

## Checklist

### A. Catalog

| # | Item | Evidence | Grade |
|---|---|---|---|
| A1 | Exactly 12 cards | Live DOM census: 12 `.product` articles | PASS |
| A2 | 6 domain at $100.00 / 100 PV | Payment, Shipping, Pricing, Inventory, Marketing, Tax Agents: each "$100.00 / month", "100 PV", data-tier=domain | PASS |
| A3 | 6 support at $50.00 / 50 PV | Software Engineer, Quality Assurance, Secretary, Chief Executive, Accounting, Customer Care: each "$50.00 / month", "50 PV", data-tier=support | PASS |
| A4 | Names match the ROADMAP product concept | Domain list matches "Payment, Shipping, Pricing, ..."; support list matches "Software Engineer, Quality Assurance, Secretary, Chief Executive, Accounting, ..." | PASS |
| A5 | Tier badges | Every card carries a Domain or Support pill matching its tier; domain badges get the cyan treatment | PASS |
| A6 | Hexagon icons render | All 12 icons contain the hex polygon and have a nonzero rendered bounding box | PASS |
| A7 | Tier filter shows correct subsets | Dispatched clicks: Domain pill hides support band (6 domain cards visible), Support pill hides domain band, All restores both; aria-pressed tracks the active pill exactly | PASS |
| A8 | Add feedback fires | After a dispatched Add click: button gains is-added, "Added" label unhidden, badge increments to 1, localStorage records {"payment":1} | PASS |

### B. Cart drawer

| # | Item | Evidence | Grade |
|---|---|---|---|
| B1 | Opens on add | FAIL: after the Add click the drawer stayed closed (is-open absent, aria-hidden "true"). Feedback is the button morph plus badge bump only; the drawer opens only from the nav cart button. See defect MEDIUM 1 | FAIL |
| B2 | Opens via the nav badge | Dispatched click on #cartButton: drawer is-open, aria-hidden "false", overlay open, focus moved to the close button | PASS |
| B3 | Line items with quantity controls and remove | Each line: icon, name, money and PV meta, minus/plus group, Remove. Minus disabled at quantity 1; plus works; Remove deletes the line | PASS |
| B4 | Subtotal math combo 1 | payment x1: expected $100.00 / 100 PV, page shows $100.00 / 100 PV | PASS |
| B5 | Subtotal math combo 2 | qa x1: expected $50.00 / 50 PV, page shows $50.00 / 50 PV | PASS |
| B6 | Subtotal math combo 3 | qa1 + payment1 + engineer1: expected $200.00 / 200 PV, page shows $200.00 / 200 PV, badge 3 | PASS |
| B7 | Subtotal math combo 4 | qa2 + payment1 + engineer1 + shipping2: expected 100+100+50+200 = $450.00 / 450 PV, page shows $450.00 / 450 PV, badge 6. Then qa dec to 1 + engineer removed: expected $350.00 / 350 PV, page shows $350.00 / 350 PV, badge 4 | PASS |
| B8 | PV meter below 100 shows countdown | At 50 PV: "50 / 100 PV", fill 50%, note "50 PV more to a qualified month.", not qualified. At 0: "A qualified month needs 100 PV." | PASS |
| B9 | Flips to qualified at EXACTLY 100 | Single 100 PV item: is-qualified class set, note "Qualified month reached at 100 PV.", fill 100% | PASS |
| B10 | Caps visually at 100 percent, counter keeps counting | At 200 PV: fill width 100% (capped), counter "200 / 100 PV", note "Qualified month reached at 200 PV." Also verified at 350 and 450 | PASS |
| B11 | Escape closes | Dispatched Escape keydown: drawer and overlay closed, aria-hidden back to "true" | PASS |
| B12 | Drawer full-width at 375 | Viewport 375x812: drawer bounding width 375 = viewport width; CSS confirms width 100% under 480 | PASS |

### C. Persistence

| # | Item | Evidence | Grade |
|---|---|---|---|
| C1 | Cart and badge restore after reload | Built qa1 + payment1 + shipping2, reloaded: badge 4, all three lines back with quantities, subtotal $350.00 / 350 PV, storage {"qa":1,"payment":1,"shipping":2} | PASS |
| C2 | Order placed clears the cart | After Place order: localStorage value "{}" (no items), badge 0, drawer empty-state on next open | PASS |

### D. Checkout

| # | Item | Evidence | Grade |
|---|---|---|---|
| D1 | Empty fields succeed | All five inputs verified empty, submit dispatched: confirmation view active | PASS |
| D2 | Junk fields succeed | memberCode "GW-!!!@#$", cardName with a script tag, cardNumber "not-a-number-9999xyz", expiry "99/99", code "abcd": confirmation reached, no console error, no markup injection observed | PASS |
| D3 | Order number format ORV-2026-08-XXXX | Two live orders: ORV-2026-08-6515 and ORV-2026-08-7275, both matching ^ORV-2026-08-\d{4}$ | PASS |
| D4 | Correct totals and PV line | Order 1: lines QA x1 $50.00 + Payment x1 $100.00 + Shipping x2 $200.00, total $350.00, 350 PV (matches hand math). Order 2: $50.00, 50 PV | PASS |
| D5 | Qualified note adapts | 350 PV order: "This order carries 350 PV: a qualified month." 50 PV order: "This order carries 50 PV of the 100 PV qualified month." | PASS |
| D6 | BOTH disclaimer lines | "Demonstration checkout: no payment occurred and nothing will be charged." AND "Payments route through the Orvanna orchestration layer in a later phase." both present on the confirmation | PASS |
| D7 | Back/continue coherent | Checkout "Back to the catalog" button returns to the catalog view with the cart intact; confirmation "Back to the catalog" is an anchor to shop.html (fresh catalog, cart already cleared). Checkout button disabled on an empty cart | PASS |

### E. Cross-page wiring

| # | Item | Evidence | Grade |
|---|---|---|---|
| E1 | Corporate nav Shop link works | shop.html is now a real anchor on /www/index.html (was a dead span in Phase 4B); dispatched click landed on /www/shop.html, title "Orvanna Shop". The call-to-action "Browse the catalog" also targets shop.html | PASS |
| E2 | Shop nav Learn and Sign In work | Learn anchor to index.html present; dispatched Sign In click landed on /www/login.html | PASS |
| E3 | Sign In to login to Continue lands on /site/ | Continue with empty fields from login.html landed on /site/index.html, portal booted with live data | PASS |
| E4 | Portal "Orvanna Home" and "Shop" links exist | site\index.html header nav .site-links: "Orvanna Home" href ../www/index.html, "Shop" href ../www/shop.html | PASS |
| E5 | Both resolve 200 | In-page fetch from the portal: /www/index.html 200, /www/shop.html 200 | PASS |
| E6 | Portal header intact at 375 | Viewport 375x812: zero header elements outside the viewport, scrollWidth 375 = clientWidth 375. Member picker (192px wide input) and the full-width tab bar remain the dominant controls; the two site links are a modest 18px-tall row | PASS |
| E7 | Member search still works | Typed "Casey": 18 results, first GW-000014 Casey Pinegrove; picked it, statement switched to GW-000014 (Total earned 0.00). At 375: typed "Kai", 26 results, picked GW-000002 Kai Eastbrook | PASS |
| E8 | Tab switch still works | Company tab: July totals rendered. My Volume tab at 375: active, chart copy rendered for GW-000002 | PASS |

### F. House rules (shop.html, shop.css, both index.html files, login.html, portal.css)

| # | Item | Evidence | Grade |
|---|---|---|---|
| F1 | Zero em or en dashes | Python character scan of all six files: 0 U+2014, 0 U+2013 in every file | PASS |
| F2 | PV expanded on first use per page | shop.html hero expands "Personal Volume (PV)" before any bare "PV"; shop.css header comment expands it; index.html expands "artificial intelligence (AI)"; portal copy expands SV and CV (seen live in Company and Statement tabs); login.html and site\index.html carry no bare acronyms | PASS |
| F3 | Money 2 decimals with separators | fmtMoney uses toLocaleString en-US with forced 2 fraction digits; rendered proof: $100.00, $450.00, $350.00, and portal 20,669.20 / 172,550.00 / 138,040.00 | PASS |
| F4 | Relative paths only | All hrefs and srcs relative (index.html, shop.html, login.html, css/, assets/, ../www/, ../site/); zero file:// or drive-letter references | PASS |
| F5 | No CDN dependencies | Character scan: the only http(s) strings are SVG xmlns namespace attributes (not network requests). Live network log across the whole journey: localhost:9120 plus the sanctioned Supabase REST base only | PASS |
| F6 | Favicon on the shop page | link rel=icon assets/favicon.svg in shop.html; live fetch 200 (and the portal favicon 200) | PASS |
| F7 | Zero console errors across the ENTIRE journey | Console read after: catalog, filter, adds, drawer math, escape, reload, two checkouts (empty + junk), corporate page, login, portal with member switch and tab switches, both widths. Zero messages of any level | PASS |
| F8 | Zero horizontal scroll at 1280 | All three shop views: scrollWidth 1265 = clientWidth 1265 (fixed off-screen drawer excluded, it cannot create page scroll) | PASS |
| F9 | Zero horizontal scroll at 375 | All three shop views plus drawer open: scrollWidth 375 = clientWidth 375; portal likewise 375 = 375 | PASS |

### G. Regression spot checks (from PHASE-4-QA.md)

| # | Item | Evidence | Grade |
|---|---|---|---|
| G1 | Hero canvas still pauses when hidden | LIVE again: document.hidden true (pane hidden), window.OrvannaHero.isRunning() false | PASS |
| G2 | Login still the ONLY door from /www/index.html into /site/ | Full href census: #top, #overview x2, shop.html x2, login.html x1, mailto x2. Zero hrefs contain "site/". The portal's own two links point FROM the portal INTO www, which is allowed | PASS |
| G3 | Enroll still a styled dead link | SPAN, aria-disabled true, "soon" pill, on both index.html and shop.html | PASS |
| G4 | Portal July facts still correct | DOM: payout 20,669.20, 14.97% of CV, 284 of 1,000 paid, run #12. INDEPENDENT REST call to v_demo_company (period 2026-07-01): total_payout 20669.2, members_paid 284, run_id 12, total_cv 138040 (20669.2 / 138040 = 14.97%), status 200 | PASS |
| G5 | Journey end to end | Corporate, Shop, cart, checkout, confirmation, Sign In, login, Continue, portal, and back out via the portal's new links: every hop landed, zero console errors | PASS |
| G6 | ROADMAP currency | Refreshed tonight and accurate: Phase 4 status cell filled, the Phase 4C paragraph matches exactly what was built (drawer, PV meter, ORV order numbers, nav wiring), Phase 5 carries the login-redirect repoint flag, next step correctly reads "AWAITING: Howard's morning review of the shop." Prior report's E1 FAIL is fixed | PASS |
| G7 | Corporate metrics still 12 / 1,000 / 6 | Static markup verified; and the "12 AI agents in the catalog" tile now matches a real 12-agent shop | PASS |

## Defects

### HIGH (broken journey, wrong data, console error)

None found.

### MEDIUM (off-spec, fragile)

1. **The cart drawer does not open when an item is added (B1).** The stated promise for
   tonight was a drawer that "opens on add and via the nav badge". Live behavior: Add
   morphs the button to "Added" and bumps the nav badge, but the drawer stays closed;
   it opens only from the nav cart button. The journey is never blocked (the badge is
   always one click away), which is why this is MEDIUM, not HIGH. It may even be the
   designer's deliberate reading of the "browse continuation" research (do not interrupt
   browsing), but that is a call for Howard, not the builder or the grader. The fix, if
   Howard wants auto-open, is one line: call openDrawer() at the end of the add-to-cart
   click handler.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\shop.html` (add handler, near line 451)

### LOW (cosmetic, forward-looking)

1. **After an order the storage key holds the string "{}" instead of being removed.**
   Functionally empty (badge 0, drawer empty, restore clean), but a
   localStorage.removeItem(CART_KEY) on order placement would leave no residue.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\shop.html` (order submit handler)
2. **Order numbers are random with no uniqueness guarantee.** ORV-YYYY-MM plus a random
   4-digit number can repeat across orders. Meaningless in a demo with no order storage;
   worth a sequence or timestamp component when orders start persisting (Phase 6).
3. **Carried forward from Phase 4B:** the corporate nav "Learn" link is hard-coded
   active on index.html (cosmetic); the login redirect to ../site/ needs repointing when
   Phase 5 serves www at the domain root (now correctly recorded in the ROADMAP Phase 5
   line, so it is on the books).

## Verdict

**PASS, with one MEDIUM design question for Howard's morning review.** 41 rows executed:
40 PASS, 1 FAIL (B1, MEDIUM severity), 0 HIGH defects. The shop is solid where it
matters: the catalog is exactly the locked product concept (12 agents, two tiers, right
prices, right PV), every money figure matched independent hand math to the cent across
five cart combinations, the PV meter flips to qualified at exactly 100 and counts past
its capped bar exactly as specified, persistence survives reload and clears on order,
both checkout disclaimers are present, and the whole property, corporate site, shop,
login, portal, runs the full journey with zero console errors and zero horizontal
scroll at both widths. The portal's two new outbound links resolve and did not disturb
the header at 375. The ROADMAP is current, fixing the only failure from the prior
report.

The one open question to put in front of Howard: should the cart drawer auto-open when
an agent is added (the promise as written), or stay closed so browsing continues (the
built behavior)? One line of code either way.
