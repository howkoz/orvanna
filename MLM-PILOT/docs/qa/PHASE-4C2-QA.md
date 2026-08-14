# Phase 4C.2 QA: Shop Round 4, Howard's Seven-Item Feedback Build

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-14 (overnight gate, run before Howard walks the shop)
Scope: `www\js\catalog.js` (NEW, single source of truth), `www\product.html` (NEW, one
template serving all 16 products), `www\shop.html` (rewritten: mode-aware cart, four-step
checkout), `www\css\shop.css` (extended), regression on untouched `www\index.html` and
`www\login.html`, plus regression spot checks from `docs\qa\PHASE-4-QA.md` and
`docs\qa\PHASE-4C-QA.md`.
Server under test: http://localhost:9120 serving the MLM-PILOT root.

## Method note (read this first)

The Browser pane was HIDDEN for this entire session (document.hidden true throughout), so
no screenshots. Every behavioral claim was verified against the LIVE pages at
localhost:9120 through the document object model (DOM), the console log, and the network
request log, with real dispatched clicks, input events, keyboard events, and form submits
on the actual elements, plus viewport emulation at 1280x800 and 375x812 for every width
row. All money and Personal Volume (PV) figures were computed by hand BEFORE comparing
against the page. Four real orders were placed end to end, one per payment method. The
round-3 cart migration was tested by seeding localStorage with the old bare-sku format
(including a ghost sku and a junk quantity) and reloading. File hygiene rows come from a
Python character scan and a repository file census. The cart was left empty at the end so
Howard starts clean.

Acronym key: PV (Personal Volume), DOM (Document Object Model), QA (Quality Assurance),
AI (Artificial Intelligence), CSS (Cascading Style Sheets), JS (JavaScript),
SVG (Scalable Vector Graphics), URL (Uniform Resource Locator).

## Checklist

### A. Product pages (feedback item 1)

| # | Item | Evidence | Grade |
|---|---|---|---|
| A1 | 16 products, each card links to product.html?sku= | Live census: 16 `.product` cards (6 domain, 6 support, 1 bundle, 3 packs); every card's icon and name link to `product.html?sku=<sku>` with the correct sku | PASS |
| A2 | Product page renders per sku | Spot-rendered payment (domain), qa (support), manager (bundle), constellation (pack): title becomes "<Name> | Orvanna Shop", correct badge, name, blurb, prices | PASS |
| A3 | Unknown sku falls back gracefully | `?sku=doesnotexist` renders the first catalog product (Payment Agent), fully functional, zero console errors | PASS |
| A4 | Missing sku falls back gracefully | `product.html` with no query renders Payment Agent the same way | PASS |
| A5 | Hexagon mark present | `#prodIcon svg polygon` (brand hexagon) rendered on every page checked | PASS |
| A6 | Tier badge | "Domain agent", "Support agent", "Bundle", "Digital pack" badges correct per tier | PASS |
| A7 | Price block + subscription toggle + add to cart | Price row, per-label, PV chip, role=switch toggle, add button all live and wired | PASS |
| A8 | Business-benefit headings with filler | Three prose panels: "How this helps your business", "What this agent does day to day" (becomes "What this pack does day to day" on packs), "Works with your team", six Latin filler paragraphs | PASS |
| A9 | Digital-delivery line | "Digital delivery: this product activates on your account, nothing ships." present in the price box | PASS |
| A10 | Bundle and pack pages list included children | Manager: Includes section visible, "3 items, one subscription", chips for Software Engineer, Secretary, Accounting, each chip linking to its own product page with its hexagon icon. Constellation: "7 items", all six domain agents plus Manager Agent | PASS |

### B. Billing modes (feedback item 2)

| # | Item | Evidence | Grade |
|---|---|---|---|
| B1 | Subscription default everywhere | Product page loads with switch aria-checked true, "Subscribe monthly", "Renews monthly. Cancel anytime."; catalog add buttons add the `sku|sub` key; shop hero states the default in copy | PASS |
| B2 | Domain one-time = $1,000.00 / 1,000 PV | Payment Agent toggled: price $1,000.00, "one time", "1,000 PV", add label "Add to cart, one time"; toggle back restores $100.00 | PASS |
| B3 | Support one-time = $500.00 / 500 PV | Quality Assurance toggled: $500.00 / 500 PV | PASS |
| B4 | Bundles and packs 10x their monthly | Manager $200.00 to $2,000.00 (2,000 PV); Constellation $800.00 to $8,000.00; catalog "Own it outright" hints show the 10x figure on all 16 cards | PASS |
| B5 | Value-framing line in subscription mode | "Full value $1,000.00. Subscribe and start for $100.00 this month." in sub mode; one-time mode flips to "Or subscribe instead: $100.00 / month at 100 PV." | PASS |
| B6 | Cart lines badge the mode | Drawer and checkout summary lines carry a "Monthly" or "One-time" badge on every line; one-time meta reads "billed once" | PASS |
| B7 | Split subtotals, mixed cart 1 and 2 | Migrated cart payment x2 + qa x1: sub $250.00, one-time row hidden, 250 PV. Plus Ignition added by card click: sub $450.00, 450 PV, badge 4. Both match hand math | PASS |
| B8 | Split subtotals, mixed cart 3 and 4 | Cart 3 (real one-time add of Marketing from its product page): one $1,000.00 + sub $450.00, 1,450 PV, badge 5. Cart 4 (executive one x2, manager sub x1, care sub x3): one $1,000.00 + sub $350.00, 1,350 PV, badge 6; quantity minus on the one-time line moved it to $500.00 / 850 PV and plus restored it. All to the cent against hand math | PASS |
| B9 | Subscription wording follows real-store patterns (feedback item 3) | Built terminology: "Subscribe monthly" / "One-time purchase" switch, "Renews monthly. Cancel anytime.", "Monthly" / "One-time" line badges, renewal sentence on confirmation. Matches the mainstream subscribe-and-save pattern (default subscription, explicit renewal disclosure, one-time alternative priced higher). The research step itself is the builder's process; QA grades the artifact it produced | PASS |

### C. Variants (feedback item 4)

| # | Item | Evidence | Grade |
|---|---|---|---|
| C1 | Manager Agent $200.00 / 200 PV | Card and product page both show $200.00 / month, 200 PV | PASS |
| C2 | Exactly three support children shown | engineer, secretary, accounting: three include chips, no more, no fewer; card lists the same three names | PASS |
| C3 | Three packs, even prices, PV = dollars | Ignition $200.00 / 200 PV, Momentum $400.00 / 400 PV, Constellation $800.00 / 800 PV, exactly as expected | PASS |
| C4 | Pack compositions coherent | Ignition = Payment + Customer Care + Secretary (100+50+50 = 200, price equals parts). Momentum = Payment + Marketing + Pricing + Engineer + QA (100x3 + 50x2 = 400). Constellation = six domain agents + Manager (600+200 = 800). Manager alone is 200 vs 150 of parts, priced above parts deliberately (the management layer is the product, documented in catalog.js) | PASS |
| C5 | Bundle filter pill works | Bundles pill shows only the bundles band (4 cards) and hides domain and support; Domain, Support, All each show exactly their bands; aria-pressed tracks the active pill | PASS |

### D. Checkout (feedback items 5, 6, 7)

| # | Item | Evidence | Grade |
|---|---|---|---|
| D1 | Account step gates the rest | On entering checkout only the chooser shows; steps 2 to 4 stay hidden until Sign in or Continue as guest | PASS |
| D2 | Sign in with anything works | Junk credentials + Continue: "Signed in as Jordan Avery. Your saved billing address is filled in below." | PASS |
| D3 | Sign-in prefills a synthetic United States address | Jordan Avery, 4821 Meridian Loop, Cedar Falls, Iowa 50613: filled into all five billing fields | PASS |
| D4 | Guest path clears the address | Switch then Continue as guest: status text changes, name and street fields empty for manual entry | PASS |
| D5 | Activation selector styled like shipping, Standard free default | Radio-card options with prices at the right edge (`.delivery-option:has(input:checked)` highlight): Standard "Access within 48 hours" FREE and checked by default; Priority "immediately" $25.00 | PASS |
| D6 | Activation recomputes totals | Standard: activation Free, total $1,417.50. Priority: $25.00, tax rises to $68.75, total $1,443.75. Both match hand math | PASS |
| D7 | Tax exactly 5 percent; base includes delivery | Cart 4: 5% of (1,000 + 350 + 0) = $67.50 shown; with Priority 5% of 1,375 = $68.75 shown. The taxable base is items PLUS the activation charge, confirmed by arithmetic | PASS |
| D8 | Tax ID: letters-only does NOT exempt | "ABCDEF": label still "Tax 5 percent", tax $68.75 unchanged | PASS |
| D9 | Tax ID: any digit exempts live | "ABC7EF" on input event: label "Tax exempt", tax $0.00, total drops to $1,375.00 without a click | PASS |
| D10 | Clearing the Tax ID restores tax | Emptied field: "Tax 5 percent", $68.75, $1,443.75 all restored | PASS |
| D11 | Four payment methods, generic marks only | Apple Pay, Google Pay, PayPal, Credit card buttons with hand-drawn inline SVG marks; "Demonstration marks, not real payment brands." note; repository census: the only image assets anywhere are favicon.svg and Orvanna logo SVGs, zero payment-brand files; grep for brand names in assets: zero hits | PASS |
| D12 | Wallets skip card fields, card reveals them | Each wallet: card fields hidden, wallet note shown ("<Method> needs no card details here."), button becomes "Place order with <Method>". Card: fields return, button "Place order" | PASS |
| D13 | Every method reaches confirmation | Four live orders: PayPal ORV-2026-08-09QXSE, Apple Pay ORV-2026-08-09RJZH, Google Pay ORV-2026-08-09RZO4, Credit card (junk field values including a script tag, no injection rendered) ORV-2026-08-09SBRI | PASS |
| D14 | Confirmation completeness | Order 1 (mixed, Priority, exempt): mode badges on lines, split subtotals ($1,000.00 one time billed today + $350.00 monthly), Priority activation $25.00, Tax exempt $0.00, order total $1,375.00, Payment method PayPal, Total PV 1,350 with "a qualified month" note, renewal sentence "renew monthly at $350.00 until cancelled.", BOTH disclaimers. Order 2 (sub-only, taxed): Tax 5 percent $2.50, total $52.50, PV note "50 PV of the 100 PV qualified month". Order 3 (one-time only): renewal sentence correctly ABSENT and monthly row absent | PASS |
| D15 | Collision-safe order number | ORV-YYYY-MM-<6 char base36 of milliseconds since midnight>: four orders, four distinct numbers, monotonic within the session; unique per millisecond (see LOW 2 for the cross-day edge) | PASS |

### E. PV meter

| # | Item | Evidence | Grade |
|---|---|---|---|
| E1 | Counts ALL modes' PV | Cart 4 meter read 1,350 / 100 PV: 1,000 of it from one-time lines; checkout meter identical | PASS |
| E2 | Qualified at exactly 100 | Single $100.00 subscription: is-qualified set, "Qualified month reached at 100 PV.", fill 100% | PASS |
| E3 | Caps at 100 percent visually, counter continues | At 250, 1,350 PV: fill width pinned at 100%, counter shows the full figure; at 50 PV: 50% fill, "50 PV more to a qualified month.", not qualified | PASS |

### F. Persistence and migration

| # | Item | Evidence | Grade |
|---|---|---|---|
| F1 | Cart survives reloads and page hops | Cart built on shop, intact on product.html (badge 3, then 5 after an add), intact back on shop with correct lines and totals; seeded cart intact after location.href reload | PASS |
| F2 | Round-3 cart migrates rather than crashes | Seeded `{"payment":2,"qa":1,"ghostsku":3,"shipping":"junk"}`: page loads clean, bare keys become `payment|sub` and `qa|sub` as Monthly lines, ghost sku and junk quantity dropped, badge 3, subtotal $250.00 / 250 PV, zero console errors; next save persists the new key format | PASS |
| F3 | Cart clears after order with the key REMOVED | After every one of the four orders: `localStorage.getItem('orvannaCart')` returned null (not "{}"), badge 0. Round 3's LOW 1 is fixed | PASS |
| F4 | Empty-cart guards | Checkout button disabled on empty cart; submit with empty cart returns to catalog | PASS |

### G. House rules (catalog.js, product.html, shop.html, shop.css)

| # | Item | Evidence | Grade |
|---|---|---|---|
| G1 | Zero em or en dashes | Python scan of all four files plus index.html, login.html, corporate.css: 0 U+2014, 0 U+2013 in every file | PASS |
| G2 | PV expanded on first use per page | shop.html: hero expands "Personal Volume (PV)" at text index 134, before the first bare "PV" at 371. catalog.js and shop.css expand it in their header comments. product.html: the price-row bare "PV" chip renders BEFORE the expansion note directly beneath it (body text index 219 vs 294). See LOW 1 | FAIL |
| G3 | Money 2 decimals with separators | fmtMoney (single shared definition in catalog.js) uses toLocaleString en-US with forced 2 fraction digits; rendered proof: $1,000.00, $1,417.50, $1,443.75, $2.50, $8,000.00 | PASS |
| G4 | Relative paths only | All hrefs and srcs relative on both new pages; zero file:// or drive-letter references in the scan | PASS |
| G5 | No network dependencies beyond localhost | Character scan: only http strings are SVG xmlns namespace attributes (not requests). Live network log across the full journey: localhost:9120 exclusively on the shop side (the portal's sanctioned Supabase call is outside this scope and was not triggered by shop pages) | PASS |
| G6 | Favicon on both pages | link rel=icon assets/favicon.svg in shop.html and product.html; live fetch 200 | PASS |
| G7 | Zero console errors across the ENTIRE journey | Console read twice (mid-journey and at the end) after: catalog, filters, product pages x7, toggles, adds, migration load, drawer math, checkout with all account paths, activation switches, tax id states, all four payment methods, four orders, corporate page, login, portal, width changes. Zero messages of any level | PASS |
| G8 | Zero horizontal scroll at 1280 | Catalog, checkout, confirmation views, drawer open, and product.html (Constellation, the widest): scrollWidth 1265 = clientWidth 1265 in every case | PASS |
| G9 | Zero horizontal scroll at 375 | Same five surfaces: scrollWidth 375 = clientWidth 375; drawer full-width 375; element census found zero boxes past the right edge | PASS |

### H. Regression (untouched pages, prior critical rows, roadmap)

| # | Item | Evidence | Grade |
|---|---|---|---|
| H1 | Corporate page loads with Shop nav intact | Title "Orvanna", nav Shop anchor live to shop.html, call-to-action also shop.html, Enroll still a dead SPAN aria-disabled | PASS |
| H2 | Login still the ONLY door into /site/ | Full href census of /www/index.html: #top, #overview x2, shop.html x2, login.html x1, mailto x2; zero hrefs contain "site/" | PASS |
| H3 | Sign In to login to Continue lands on /site/ | Dispatched Sign In click landed on login.html; empty-field submit landed on /site/index.html, portal title "Orvanna Member Portal, Demo Mode" | PASS |
| H4 | Portal header links still resolve | "Orvanna Home" ../www/index.html and "Shop" ../www/shop.html present; in-page fetches: 200, 200 (product.html also 200) | PASS |
| H5 | Hero canvas still pauses when hidden | document.hidden true, window.OrvannaHero.isRunning() false, live | PASS |
| H6 | ROADMAP currency (4C.2 status vs reality) | The Phase 4C.2 paragraph records Howard's seven items faithfully, BUT the "Next small step" section still describes round 3 as the current state: "the twelve-agent catalog", order format "ORV-YYYY-MM-XXXX", "AWAITING: Howard's morning review of the shop" with no mention that round 4 was built (16 items, catalog.js, product.html, four-step checkout, new order-number scheme). The roadmap is behind the work, same defect class as Phase 4 QA row E1 | FAIL |

## Defects

### HIGH (broken journey, wrong data, console error)

None found.

### MEDIUM (off-spec, fragile)

1. **ROADMAP is behind reality (H6).** The Phase 4C.2 paragraph correctly captures the
   seven feedback items, but the closing "Next small step" narrative still describes the
   round-3 shop (twelve-agent catalog, ORV-YYYY-MM-XXXX random order numbers) as what was
   built overnight. Reality: round 4 shipped 16 catalog items, js/catalog.js as the single
   source of truth, product.html, the mode-aware cart, and the four-step checkout. One
   edit fixes it: append the round-4 build state and this gate's result to the next-step
   paragraph. This was the exact condition placed on the Phase 4 pass; it regressed again.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\ROADMAP.md`

### LOW (cosmetic, forward-looking)

1. **product.html shows a bare "PV" before expanding it (G2).** Reading order on the
   product page: the price row renders "100 PV" (body text index 219) and the expansion
   "Every purchase carries Personal Volume (PV)..." sits one line below it (index 294).
   The house rule says expand on FIRST use. Smallest fix: say "Personal Volume (PV)" in
   the mode note or hero blurb above the price row, or move the pv-note above the price
   row. shop.html gets this right (hero expands at index 134 before any bare use).
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\product.html`
2. **Order numbers can repeat across days within a month.** The token is milliseconds
   since LOCAL midnight, so two orders at the identical millisecond-of-day on different
   days of the same month would share a number. Vastly better than round 3's random four
   digits (that defect is fixed), and meaningless while orders are not stored; fold a day
   component in when Phase 6 persists orders.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\shop.html` (orderNumber())
3. **Corporate metric tile says "12 AI agents in the catalog"; the shop now displays 16
   purchasable items.** Strictly true (12 agents; the bundle and three packs are
   compositions of those 12), but a visitor counting cards sees 16. Wording call for
   Howard: "12 AI agents" stays defensible, "16 ways to buy them" is the fuller story.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\index.html`
4. **Carried forward, already on the books:** login.html redirect to ../site/ must be
   repointed when Phase 5 serves www at the domain root (recorded on the ROADMAP Phase 5
   line); the corporate nav "Learn" link is hard-coded active (cosmetic).

## Round-3 defect disposition

| Prior defect | Status now |
|---|---|
| MEDIUM 1: drawer did not open on add (B1, PHASE-4C-QA) | FIXED and verified live: add from a card opens the drawer (is-open, aria-hidden false); the product page instead shows a toast linking to shop.html#cart, and that hash opens the drawer on arrival. Howard's design question is answered in the built behavior |
| LOW 1: storage held "{}" after an order | FIXED: key removed (null) after all four orders |
| LOW 2: random order numbers with no uniqueness guarantee | FIXED at demo scale: millisecond-of-day base36 token; cross-day edge noted as new LOW 2 |
| LOW 3: Learn link hard-coded active; Phase 5 login repoint | Unchanged, still tracked |

## Verdict

**PASS, with the ROADMAP staleness (MEDIUM) as the one condition, again.** 51 rows
executed: 49 PASS, 2 FAIL (H6 MEDIUM, G2 LOW severity), 0 HIGH defects. All seven of
Howard's feedback items are built and behave exactly as specified: 16 product pages off
one template with graceful fallback; subscription default with the 10x one-time flip
($1,000.00 / 1,000 PV on a domain agent, $500.00 / 500 PV on support, 10x on every
bundle and pack); the Manager Agent bundle with exactly three support children; three
even-priced packs with PV equal to dollars and coherent compositions; the four-step
checkout with working sign-in prefill, guest path, shipping-style activation choice that
recomputes totals, a live 5 percent tax (base includes the activation charge) with a
correct letters-versus-digits Tax ID rule, and four demonstration payment methods drawn
as generic marks with zero brand assets in the repository, each reaching a complete
confirmation. Money math matched independent hand arithmetic to the cent across four
mixed carts and four placed orders. The round-3 cart format migrates cleanly, the cart
key is properly removed after orders, and the whole property still runs corporate, shop,
login, portal with zero console errors and zero horizontal scroll at both widths.

Fix before Howard walks the shop: nothing blocking. Fix the ROADMAP paragraph the same
morning (five minutes), and take the one-line PV-expansion touch-up on product.html when
convenient.

---

## DELTA 2026-08-14: hotfix re-stamp after Howard's live catches

Graded by: mlm-qa. Short focused pass, 16 rows, on the live pages at localhost:9120
through the document object model (DOM); the Browser pane was hidden the whole session
(document.hidden true), so every claim comes from injected JavaScript reading computed
styles, real dispatched clicks and input events, the console log, and the network log.
This section applies the NEW standing charter rule for the first time: rendered contrast
computed from getComputedStyle color against the effective background, alpha-composited
up the ancestor chain, Web Content Accessibility Guidelines (WCAG) ratio formula, fail
under 4.5 to 1. One full guest order was placed and hand-checked to the cent. The cart
was cleared afterward so Howard starts clean.

### D-A. Computed contrast (new standing rule, first outing)

Checkout account step (measured live on the rendered step):

| Element | Text color | Effective background | Ratio | Grade |
|---|---|---|---|---|
| Sign in button | rgb(226,232,240) | rgb(6,11,24) | 15.94 | PASS |
| Continue as guest button | rgb(226,232,240) | rgb(6,11,24) | 15.94 | PASS |
| Back to the catalog button (#backToShop) | rgb(148,163,184) | rgb(6,11,24) | 7.66 | PASS |

Ten most important interactive elements across shop.html, product.html, login.html
(worst elements per page included; every measured element is listed or bounded below):

| Element | Ratio | Grade |
|---|---|---|
| shop: card Add to cart button | 14.20 | PASS |
| shop: card product name link | 17.94 | PASS |
| shop: filter pill, active | 10.47 | PASS |
| shop: filter pill, inactive | 12.24 | PASS |
| shop: drawer Checkout button | 10.47 | PASS |
| shop: drawer Remove button (page worst) | 7.66 | PASS |
| product: Add to cart button | 14.20 | PASS |
| product: subscription switch and label | 11.62 and 12.64 | PASS |
| login: Continue button | 10.47 | PASS |
| login: field labels (page worst pair 7.66 on back link and note) | 9.86 | PASS |

Additional elements measured, all PASS: drawer quantity buttons 12.64, drawer child
name links 12.64, Included badge 9.86, Monthly badge 9.69, nav Sign In 7.66, nav cart
12.64, Back to the catalog link 7.66, footer mail 12.79, payment method buttons 19.27,
Place order button 10.47, login inputs 15.94. Lowest ratio anywhere: 7.66, comfortably
above the 4.5 floor. The washed-out-button class of defect Howard caught live is gone
from every surface measured. One non-defect note: each product card's icon anchor still
carries the browser default link color rgb(0,0,238), but it contains zero text (only
the hexagon SVG, which draws its own stroke colors), so text contrast does not apply.

### D-B. Pack children (Howard's spec)

Cart built by real clicks: Ignition Pack x2 plus Constellation x1.

| Row | Evidence | Grade |
|---|---|---|
| Parents priced, children $0.00 with Included badge | Drawer: Ignition $400.00 / month 400 PV, Constellation $800.00 / month 800 PV; every child row $0.00 with an Included tag, indented 54 pixels under its parent | PASS |
| Parent-quantity multiplier on children | Ignition x2 children each show "x 2" (Payment Agent, Customer Care, Secretary); Constellation x1 children show no multiplier, correct for quantity one | PASS |
| Children in drawer, checkout summary, AND confirmation | All three surfaces render the same child sets: Ignition 3 children, Constellation 7 (Payment, Shipping, Pricing, Inventory, Marketing, Tax, Manager) | PASS |
| Child names link to product pages | Every child name on all three surfaces is an anchor to product.html?sku=<child>; confirmation row verified in markup (.summary-child .product-name-link) | PASS |
| Totals and PV unchanged by children, hand-checked | Hand math: 2x200 + 800 = $1,200.00 monthly, $0.00 one time, 1,200 PV. Drawer, checkout, and confirmation all show exactly that; children contribute zero everywhere | PASS |

### D-C. Reachability

| Row | Evidence | Grade |
|---|---|---|
| Root /shop.html lands right | GET /shop.html 200, lands on /www/shop.html, "Orvanna Shop", 16 cards | PASS |
| Root /product.html?sku=tax lands right | 200, lands on /www/product.html?sku=tax, "Tax Agent", Domain agent badge, $100.00, query preserved | PASS |
| Catalog cards link through | Card name link clicked through to product page in the flow; hrefs product.html?sku=<sku> on all cards | PASS |
| Cart line name clicks to product page | Real click on the drawer's Ignition Pack name landed on /www/product.html?sku=ignition with the cart intact (badge still 3) | PASS |
| All css/js includes carry ?v=4.1 | shop.html and product.html: corporate.css?v=4.1, shop.css?v=4.1, catalog.js?v=4.1, confirmed in both DOM and network log | PASS |

### D-D. Regression spot

| Row | Evidence | Grade |
|---|---|---|
| Full guest checkout | Guest chosen ("Checking out as a guest..."), billing filled, Priority activation $25.00 selected: tax 5 percent of (1,200 + 25) = $61.25 shown, order total $1,286.25. Digit Tax ID "QA9DELTA": Tax exempt $0.00, order total $1,225.00. Apple Pay: card fields hidden, button "Place order with Apple Pay". Confirmation ORV-2026-08-0B1AVB: all lines and children, Priority activation $25.00, Tax exempt, order total $1,225.00, Payment method Apple Pay, 1,200 PV qualified-month note, renewal sentence "$1,200.00 until cancelled", both disclaimers, cart key removed (null). Every figure matches hand math to the cent | PASS |
| Zero console errors | Console empty across catalog, cart build, checkout, order, and confirmation. The single 404 logged later was this QA session's own probe of root /login.html (see finding 1), not a page asset; network log shows every asset on in-scope pages at 200 or 304 | PASS |
| Zero horizontal scroll at 375 | Catalog, open drawer (drawer width exactly 375), and checkout: scrollWidth 375 = clientWidth 375. The only boxes past the right edge were the off-canvas drawer mid-transition, which adds no scroll | PASS |

### Findings (non-blocking)

1. LOW: the root-level convenience redirect covers /shop.html and /product.html but NOT
   /login.html (404) and was not asked to. In-page Sign In links are relative and resolve
   to /www/login.html, so no user journey breaks. Fold login.html and index.html into the
   redirect when Phase 5 moves www to the domain root, or skip it if the Phase 5 restructure
   makes it moot.
2. LOW: login.html's stylesheet include is corporate.css with NO ?v=4.1 stamp (shop and
   product both carry it). If a future hotfix changes corporate.css, a cached stale copy
   could serve on the login page. One-line touch when next editing login.html.
3. Catalog composition has shifted since the overnight report (Tax, Shipping, Inventory
   agents now among the domain six; Ignition = Payment + Customer Care + Secretary).
   Prices, PV, and pack math all remain internally coherent; noted so the next full gate
   grades against the current catalog.js, not the overnight one.

### Delta verdict

**PASS.** 16 rows, 16 PASS, zero HIGH or MEDIUM defects, three LOW notes. Lowest computed
contrast anywhere is 7.66 to 1 against a 4.5 floor. Pack children behave exactly to
Howard's spec on all three surfaces with totals and Personal Volume (PV) untouched by
children. Root reachability, cache stamps, and the full guest checkout all hold.

---

## DELTA 2026-08-14: content writer round 1 gate (prose replaces Latin filler)

Graded by: mlm-qa (the builder never grades its own work). Light delta gate, 12 rows, on
the content writer's round 1, which touched `www\index.html`, `www\product.html`,
`www\js\catalog.js` (a PROSE map merged in the products forEach), and `www\shop.html`
(footer text only).

Method: live document object model (DOM) at http://localhost:9120, verified with injected
JavaScript reading rendered text and computed layout, real dispatched clicks and input
events on the actual elements, the console log, and the network request log, at viewport
1280 wide and 375x812. Source files were scanned independently with a Python character
and vocabulary scan BEFORE any page was opened, and every price and Personal Volume (PV)
figure was taken from `js/catalog.js` by hand before comparing against the rendered
pages. None of the writer's own scans were trusted or reused. Two real orders were
placed end to end; the cart was left empty afterward so Howard starts clean.

### Rows

| # | Item | Evidence | Grade |
|---|---|---|---|
| DC1 | Latin filler gone, rendered | Rendered-text vocabulary scan (lorem, ipsum, dolor, amet, consectetur, and 20 more filler terms) on live index.html plus SEVEN product pages spanning every tier: payment and tax (domain), qa and secretary (support), manager (bundle), ignition and constellation (packs), plus the shop catalog view. Zero hits on every surface | PASS |
| DC2 | Latin filler gone, source | Independent Python scan of index.html, product.html, shop.html, js/catalog.js, and login.html: zero filler-vocabulary hits in any file | PASS |
| DC3 | Zero em or en dashes | Source scan: 0 U+2014 and 0 U+2013 across all five files. Rendered scan: 0 of each on index, all seven product pages, and shop. The drawer quantity control uses U+2212 (the minus sign), which is neither | PASS |
| DC4 | Product prices and PV match catalog.js | All seven product pages read live in subscription mode: payment and tax $100.00 / 100 PV, qa and secretary $50.00 / 50 PV, manager $200.00 / 200 PV, ignition $200.00 / 200 PV, constellation $800.00 / 800 PV. Every figure identical to the catalog.js entries read beforehand | PASS |
| DC5 | 10x one-time toggle still reprices | Toggle clicked on all seven pages: payment and tax to $1,000.00 / 1,000 PV, qa and secretary to $500.00 / 500 PV, manager and ignition to $2,000.00 / 2,000 PV, constellation to $8,000.00 / 8,000 PV; per-label flips to "one time"; toggling back restored the subscription price on every page | PASS |
| DC6 | Shop card prices unchanged | Live census of all 16 cards: six domain at $100.00 / 100 PV, six support at $50.00 / 50 PV, Manager and Ignition $200.00 / 200 PV, Momentum $400.00 / 400 PV, Constellation $800.00 / 800 PV; all 16 "Own it outright" hints show the correct 10x figure ($1,000.00 / $500.00 / $2,000.00 x2 / $4,000.00 / $8,000.00) | PASS |
| DC7 | Commerce journey 1: single agent | Cart cleared, then Marketing Agent added by a real click on its product page (badge 1, toast shown, stored key marketing|sub). Nav cart click landed on shop.html#cart with the drawer OPEN and the correct line: Marketing Agent, Monthly, $100.00 / month, 100 PV, quantity 1. Guest checkout, billing filled: subtotal $100.00, Standard activation free, tax 5 percent $5.00, order total $105.00, 100 PV, all matching hand math. Confirmation ORV-2026-08-0GY6IB, payment method Credit card, cart key removed (null) | PASS |
| DC8 | Commerce journey 2: bundle regression | Manager Agent added from its product page; drawer opened with Manager Agent, Monthly, $200.00 / month, 200 PV; guest checkout to confirmation ORV-2026-08-0GZJPS, order total $210.00 (200 + 10.00 tax, exact); all three bundle children on the confirmation as Software Engineer, Secretary, Accounting, each "Included $0.00"; cart key removed | PASS |
| DC9 | Zero console errors on the journeys | Console error count was captured before and after the second full journey and did not grow: both logged errors are the same pre-existing 404, root /favicon.ico from the bare-root redirect page (the known LOW from the 2026-08-14 hotfix delta; not a Sign In or asset failure). Network log: every asset on the touched pages served 200 or 304, including catalog.js?v=4.1, both stylesheets, and the logo on every page load | PASS |
| DC10 | Charter sweep of the NEW copy | No income or earnings language anywhere in the Network pillar ("Agents do not sell themselves...") or in any of the 16 prose sets in catalog.js; the only "earnings" string anywhere is the mandated disclaimer line. No testimonials from customers and no invented business numbers: the prose across all seven pages rendered ZERO digits; the only rendered figures on index are 12, 1,000, and 6, and on shop and product pages only prices and PV. Acronyms: index expands "artificial intelligence (AI)" in the hero (character 134) before any bare AI; shop hero expands PV at 134 before the first bare PV at 371. Tax Agent page carries the human-approval framing live: "it prepares, it never files on its own", "review and signature", "Your accountant stays the authority" all present in the rendered page | PASS |
| DC11 | Metrics tile | Renders "12" with the new label "Specialist AI agents, sold solo or in packs". At 1280: all three tiles exactly 166 pixels tall and 329 wide, no overflow in either axis. At 375: tiles stack single-column at full width, no overflow, no element past the right edge (the "12" tile is naturally taller there because its label wraps to two lines, which is correct stacking behavior, not a defect) | PASS |
| DC12 | Zero horizontal scroll at 375 | index.html: scrollWidth 375 = clientWidth 375, element census found zero boxes past the right edge. product.html?sku=constellation (the longest new prose): scrollWidth 375 = clientWidth 375, zero offenders. The long English prose introduced no layout break | PASS |

### Notes (non-blocking, nothing new opened by the writer)

1. Carried forward, unchanged: product.html still renders the bare "PV" chip in the price
   row before the expansion note beneath it (LOW 1 of the round-4 report). The writer's
   round did not touch that block and was not asked to.
2. Carried forward, unchanged: the bare-root /favicon.ico 404 from the root redirect page
   (hotfix delta finding 1). Not reachable from any in-page journey on the touched pages.
3. Observation, not graded as a defect: the index.html origin story carries a pull-quote
   attributed to the fictional chief executive Auren Vale and spelled-out biographical
   numbers ("four-person team", "fifteen years"). It is company narrative, not a customer
   testimonial, and contains no earnings or results claim; flagged only so Howard can
   veto the quote device if he wants the stricter reading of the no-testimonials rule.
4. Observation: the leadership bio for Maren Ostrey mentions "the audit trail behind
   every commission run". That is a statement about the audit system, sits outside the
   Network pillar and product prose the charter row names, and makes no income promise.

### Delta verdict

**PASS.** 12 rows, 12 PASS, zero defects at any severity introduced by the writer's
round. The Latin filler is fully gone from source and rendered output; every price and
PV figure on seven product pages and all 16 shop cards matches js/catalog.js exactly;
the 10x toggle reprices and restores on every tier; two complete purchase journeys ran
add-to-cart through confirmation with correct drawer lines, hand-checked totals, bundle
children intact, cart cleanup, and zero new console errors; the new copy holds the
charter (no dashes, acronyms expanded first-use per page, no income language, no
testimonials, no invented figures, human-approval framing on the Tax Agent page); and
the metrics tile and 375-wide layouts are clean. Nothing regressed.
