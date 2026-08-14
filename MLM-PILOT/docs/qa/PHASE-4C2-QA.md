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
