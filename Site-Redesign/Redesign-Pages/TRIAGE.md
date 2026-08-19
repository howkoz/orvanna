# Triage: token change vs. real rebuild

Answering the question directly. Mapped to files in `howkoz/orvanna.io@main`. Effort is engineering time, not design time.

---

## 0. Bug fixes — do these first, independent of everything else

| # | What | Where | Effort |
| --- | --- | --- | --- |
| 1 | "One platform underneath" cards collide with the team paragraph | `index.html` + `css/corporate.css` | S |
| 2 | Checkout: "Billing address" overlapped by "Full name"; step 3 Activation missing from the visible sequence (reads 1, 2, 4) | `shop.html` + `css/shop.css` | S–M |
| 3 | Closing section stuck at ~⅓ opacity — scroll reveal never fires | `js/site-chrome.js` or the page's own observer | S |
| 4 | PV meter renders "800 / 100 PV" with fill past its track | `js/catalog.js` (drawer + summary) | S |
| 5 | Order summary is a scroll region nested inside the page scroll | `css/shop.css` | S |
| 6 | Catalog rail renders once per group (four times) instead of once, with copy fragments orphaned between repeats | `shop.html`, `js/catalog.js` | S |
| 7 | Rank thresholds: section eleven of `comp-plan.html` is the source of truth — Leader is TV 2,500.00 + 3 active legs, Executive is TV 40,000.00 + 2 legs containing a Leader. Check any other surface that states them | site-wide | S |
| 8 | Agent count: **twelve**. The library index shows sixteen tiles because it includes packs. Any page saying "sixteen agents" is wrong — `conductor.html` gets this right today, so check the others against it | site-wide | S |
| 9 | `team.html`'s scroll-reveal script is the worst instance of bug 3: ~120 lines whose own comments admit the observer and the sweep both lose to a fast scroll, with an unconditional 2.5s deadline doing the real work. Author the reveals visible and delete the whole block | `team.html` | S |
| 10 | `orvanna-designer`'s bio names "the glow design system", which does not survive the token pass. Also drop the `.glow-a/b/c` classes — they already do nothing | `team.html`, `css/corporate.css` | S |

None of these are design decisions. Fix them before anyone argues about colour.

---

## 1. Token change — CSS only, no markup, no JS

Every one of these is a value swap in an existing stylesheet. This is where most of the visual difference actually comes from.

| Change | Files | Effort |
| --- | --- | --- |
| Ground and ink: dark `#060B18`/cyan → `--paper #eae4d9` / `--ink #1b1917` / `--accent #ec3013`. The chrome tokens are already centralised as `--chrome-*` in one `:root` — that block is the whole nav and footer repaint. | `css/site-chrome.css`, `css/corporate.css`, `css/shop.css`, `portal/css/portal.css`, `css/staff.css`, `css/staff-ops.css` | M |
| `border-radius` → 0 everywhere (currently 5px brand mark, 10px theme button, 999px pills, card radii) | all of the above | S |
| Remove the gradient top borders on cards and the two-gradient nav underline; replace with 2px `--ink` rules | `css/corporate.css`, `css/shop.css`, `portal/css/portal.css` | S |
| Body type up: 13.44px → 15–16px; nav 0.84rem/0.14em → 12.5px/0.04em; headings to the scale in README | `css/site-chrome.css`, `css/corporate.css` | S–M |
| `font-variant-numeric: tabular-nums` + right-aligned numeric columns on every table and stat | `portal/css/portal.css`, `css/staff-ops.css`, `css/shop.css` | S |
| Rule weights: hairlines → `2px solid --ink` between sections, `1px rgba(27,25,23,.25)` inside | all | S |
| Focus ring: `2px solid var(--accent)` with `2px` offset, everywhere (already correct on `.nav-theme` — generalise it) | `css/site-chrome.css` and each console sheet | S |
| Button labels flush left in wide buttons; drop centred label except in genuinely square buttons | all | S |
| Remove `backdrop-filter: blur(12px)` translucency from the bar — the new bar is opaque paper with a 2px rule | `css/site-chrome.css` | S |

**If you only do section 1, the site already stops looking basic.** Sections 2–4 are what make it feel designed.

---

## 2. Small markup change — same page structure, a few elements

| Change | Files | Effort |
| --- | --- | --- |
| New logo mark: three optical SVGs + favicon, replacing the hexagon-and-node files. Wordmark becomes *set* text (Archivo 800, −0.02em) rather than drawn paths. | `assets/`, plus the brand lockup in `css/site-chrome.css` and `login.html`'s scoped copy | S–M |
| Delete the baked-in white `<rect>` from `logo-final-primary.svg` | `assets/logo-final-primary.svg` | XS |
| Hero headline: new copy at a controlled measure, no tinted last word | `index.html` | XS |
| Mobile nav disclosure under ~900px — today eleven controls wrap and centre-pack, which is why the bar's height changes between pages | `_partials/nav.html` equivalent + `css/site-chrome.css` + `js/site-chrome.js` | M |
| Stat strip, three pillars and technology sections: card `<div>`s → ruled grid cells (same content, less chrome) | `index.html`, `css/corporate.css` | M |
| Story section: fill the empty right half with the two gates | `index.html` | S |
| Founder photograph rendered grayscale, `object-fit:cover`, at 360px in a two-column team block | `index.html`, `css/corporate.css` | S |

---

## 3. Real rebuild — new structure, new derived values, or new server work

| Change | Why it is a rebuild | Files | Effort |
| --- | --- | --- | --- |
| **Home hero "working now" log** | New data source. Needs a feed of orchestration-log records (agent, note, timestamp), capped at five rows, plus the event that drives the mark's quarter turn. Without a real feed this becomes decoration, which is worse than the empty space it replaces. | `index.html`, new JS, a read endpoint | M–L |
| **Member office: five tabs → one page** | `app.js` renders five independent panels into five `<section>`s and swaps them (`renderTeam`, `renderVolume`, `renderRank`, `renderStatement`, `renderCompany`, switched in the `case "statement":` dispatcher). One page means one render pass with anchors, and the panels have to stop owning their own loading/error states. The numbers themselves need no new maths. | `portal/index.html`, `portal/js/app.js` | L |
| **The "three answers" band** | The three headline answers are *derived*, and two of them do not exist yet: a provisional payout estimate for an open month, and a ranked "what to do next" instruction built from `legStats()` + `RANK_REQS` (currently rendered as a requirements checklist, never as an instruction). The estimate must be labelled provisional and recomputed on load, never cached. | `portal/js/app.js` | M–L |
| **Operations: twelve panels → one ranked queue** | Reordering is cheap; *ranking* is not. Each attention row needs a severity, a money-at-stake figure and exactly one action, which means the server has to expose consequence (deadline, amount, decline class) rather than just row type. Clearing a row needs an audit write. | `staff-operations.html`, its JS, server functions | L |
| **Shop catalog: 13 cards → promoted pack + dense list + sticky PV rail** | `js/catalog.js` renders a card grid; this is a different render and a different scroll relationship (rail must stick and stay in sync with the cart, rendered ONCE outside the group loop). Worth doing — the current page gives a visitor no place to start. See `9a` and `CORRECTIONS-01`. | `shop.html`, `js/catalog.js`, `css/shop.css` | M–L |
| **Compensation plan: 24 sections → one interactive page** | The teaching order changes, not the rules. Needs a rank picker and a qualification toggle driving a live level table — derived state, not copy. The long brochure stays as reference; this becomes what the nav points at. See `Comp Plan Explainer.dc.html`. | new `comp-plan.html`, small JS | M |
| **Library: chooser promoted to the top** | The ten situations already exist as static markup at the foot of `library.html`. Turning them into a chooser means one selected-state render driven by `ORVANNA.get(sku)` — the recommendation, the price, the PV and the qualification line all derive from the catalog that page already loads. The sixteen cards become an index grid. No new data. See `Library.dc.html`. | `library.html`, `css/library.css`, its inline JS | M |
| **Library marks: drop the hexagon frame** | Cheap but do it deliberately: `js/library-icons.js` wraps every glyph in one shared `HEX` polygon. Removing that constant lets the glyphs do the telling-apart. One line in that file, plus the cell styling that replaces the frame. | `js/library-icons.js`, `css/library.css` | S |
| **Conductor page: prose → three interactions** | The copy is all reusable; the structure is not. Needs three small pieces of state — a two-way switch, a seven-key checklist driving a phase label and a progress bar, and an hours slider that marks activities as fitting or not against a fixed minute budget. All derived in the page; no server, no new data. See `Conductor.dc.html`. | `conductor.html`, its inline style block, new inline JS | M |
| **Team page: proof first, roster second** | Reordering the sections is markup. The rebuild is the four-stop gate stepper (one index of state) and the nine-row expandable roster replacing the card grid. The nine marks are new SVG — lift them from `Team.dc.html` verbatim and delete the hexagon versions. See `Team.dc.html`. | `team.html`, `css/corporate.css`, new inline JS | M |
| **Printable full plan** | Drop-in, not a rebuild: save the document as `comp-plan-print.html` and register it in `DOCUMENT_PAGES`. It owns its own print geometry. See `CORRECTIONS-02`. | new file + `deploy/build_dist.py` | S |
| **Checkout in the new palette with the summary un-nested** | Palette is section 1, but the un-nesting plus the step-3 restoration touches the flow's markup and its status handling. | `shop.html`, `css/shop.css` | M |

---

## Suggested order

1. Section 0 — the five bugs. Nothing else is worth arguing about while those ship.
2. Section 1 — the token pass, all six stylesheets in one go. Biggest visible change per hour spent.
3. Section 2 — the logo and the mobile nav.
4. `7a` member office (section 3), because it is where members actually live.
5. `8a` operations queue.
6. Shop + checkout in the new palette (`9a`, then `CORRECTIONS-01`).
7. The printable plan — a drop-in file, do it any time.
8. The interactive comp plan.
9. The library chooser.
10. The conductor page.
11. The team page.
12. The working log last — it needs a real feed, and it is the one thing that is better absent than faked.

## Two things not to do

- **Do not add a framework or a build step.** The site is hand-written HTML/CSS/vanilla JS and the design assumes that. The prototype's inline styles are an artefact of the authoring tool, not a recommendation.
- **Do not keep the second accent.** The current chrome carries both `#22D3EE` and `#818CF8`. The new system is mono: one accent, used for the primary action, one field per page, and the single item that needs a human. Everything else is ink on paper.
