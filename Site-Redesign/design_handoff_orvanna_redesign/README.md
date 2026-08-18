# Handoff: Orvanna visual system, member office and operations console

## Overview

A redesign of orvanna.io covering three surfaces:

1. **Marketing home page** — restructured, with a live "working now" log in the hero.
2. **Member office** (`portal/`) — five tabs collapsed into one page organised around the three questions a member signs in with.
3. **Staff operations console** (`staff-operations.html`) — twelve equal panels reorganised into one queue ranked by consequence.

It also replaces the logo mark and sets a single visual system (colour, type, rules, motion) for all of them.

Three live layout bugs on the current site are documented in **Bugs to fix first** below. Those are not design changes; they are broken output and should be fixed regardless of whether the redesign proceeds.

## About the design files

`Orvanna Review.dc.html` in this bundle is a **design reference written in HTML** — a prototype of intended look and behaviour, not production code to copy. It is one long canvas containing every option explored, newest at the top, each with a visible id badge (`8a`, `7a`, `6a`…). Those ids are the vocabulary used throughout this document.

The task is to **recreate these designs inside the existing orvanna.io codebase** — static HTML, hand-written CSS in `css/`, vanilla JS in `js/` and `portal/js/app.js` — using its established patterns. Do not introduce a framework, a build step, or a CSS library for this work. The prototype uses inline styles because of the tool it was authored in; the real implementation should put these values in the existing stylesheets as custom properties.

The prototype will not render standalone outside the design tool (it depends on that tool's runtime and a design-system stylesheet). Read it as a specification alongside this document; every value you need is written here.

## Fidelity

**High fidelity.** Colours, type sizes, tracking, rule weights, spacing and interaction behaviour are all final and are listed exactly below. Recreate them precisely. The one deliberately loose element is the founder photograph (`assets/hk.jpg`, printed grayscale) and the fact that all figures shown are synthetic demo data.

---

## Design tokens

Zero border radius everywhere. No box shadows anywhere. Rules and alignment do all the organising.

### Colour

Two grounds — warm paper for reading surfaces, ink for bands and app chrome.

| Token | Value | Use |
| --- | --- | --- |
| `--paper` | `#eae4d9` | Page ground |
| `--paper-raised` | `#f1ede6` | Panel that must separate from the ground (hero right column, the gate stat) |
| `--ink` | `#1b1917` | Text on paper; ground for bands, sidebars, footers |
| `--ink-raised` | `#232019` | The one panel inside an ink band that must separate |
| `--ink-rule` | `#4a453f` | Rules inside ink |
| `--body` | `#4b453d` | Body copy on paper |
| `--quiet` | `#6b645a` | Secondary copy, captions |
| `--faint` | `#8a8278` | Column headings, kickers, metadata |
| `--disabled` | `#b6ae9f` | Disabled borders and labels |
| `--accent` | `#ec3013` | The one accent: primary action, the accent bar of the mark, the single "needs a human" row |
| `--accent-deep` | `#a3220b` | Accent at paragraph and kicker size on paper (contrast) |
| `--accent-mid` | `#b52309` | Accent numerals and labels on paper |
| `--accent-on-ink` | `#ff6a4a` | Accent on the ink ground |
| `--on-ink-hi` | `#f8f7f5` | Headlines on ink |
| `--on-ink-body` | `#c9c6c1` | Body on ink |
| `--on-ink-quiet` | `#8f8981` | Metadata on ink |
| `--rule-strong` | `2px solid #1b1917` | Between major sections |
| `--rule-hair` | `1px solid rgba(27,25,23,.25)` | Between cells inside a section |
| `--rule-row` | `1px solid rgba(27,25,23,.22)` | Table rows |
| `--tint-accent` | `rgba(236,48,19,.06)` – `.08` | Row/cell highlight for an item needing action |

Contrast rule that must hold: `--accent` is used for fills, large numerals and interface chrome, never for paragraph text on paper — use `--accent-deep` there.

### Type

`Archivo` for everything, already the site's face. Weights used: 400, 600, 700, 800.

| Role | Size / line-height / tracking / weight |
| --- | --- |
| Marketing hero h1 | 66px / 0.96 / −0.035em / 800, max-width 12ch, `text-wrap:balance` |
| App h1 | 40px / 1.0 / −0.035em / 800 |
| Section h2 | 26–34px / 1.05 / −0.03em / 800 |
| Card h3 | 22px / 1.15 / −0.02em / 800 |
| Display stat | 34–44px / 1.0 / −0.035em / 800 |
| Band stat | 36–40px / 1.0 / −0.035em / 800 |
| Lead body | 17px / 1.55 / 400, max-width 47ch |
| Body | 15–16px / 1.55 / 400 |
| Small body | 12.5–13px / 1.4–1.5 / 400 |
| Kicker | 10.5–11px / 1 / 0.20–0.22em / 700, uppercase |
| Table column head | 9.5px / 1 / 0.14em / 600, uppercase |
| Table cell | 13.5px / 1.2 / 400; numerals 700 |
| Button / pill label | 11–12.5px / 1 / 0.10em / 700, uppercase |
| Severity badge | 9.5px / 1 / 0.12em / 700, uppercase |

Body copy must not go below 15px on marketing pages or 12.5px for captions. The current site's 13.44px body and 0.84rem/0.14em nav are both too small and too loose — that is the single biggest reason it reads as unfinished.

Every numeric surface (member office, operations console, all tables) sets `font-variant-numeric: tabular-nums`, and every numeric column is right-aligned.

### Spacing

Page gutter: 32px in app surfaces, 38px on marketing. Section padding: 28–30px top, 32–34px bottom. Table row padding: 13–15px vertical. Grid gaps: 12–16px. Sidebar width: 252px. Prototype canvas widths: 1180px (marketing), 1280px (app).

### Motion

One keyframe set. Everything respects `prefers-reduced-motion: reduce` by disabling the animation entirely.

```css
@keyframes orvTurn {
  0%,16%   { transform: rotate(0deg); }
  25%,41%  { transform: rotate(90deg); }
  50%,66%  { transform: rotate(180deg); }
  75%,91%  { transform: rotate(270deg); }
  100%     { transform: rotate(360deg); }
}
@keyframes orvSpin { to { transform: rotate(360deg); } }
```

- **Quarter turn** (`orvTurn`, or a single 90° step with `transition: transform .8s cubic-bezier(.2,.9,.2,1)`): the nav mark's behaviour. Fire it **on an event** — an agent completing a job, the working log advancing — not on a timer.
- **Spin** (`orvSpin 1.15s linear infinite`): the loading state on the checkout hand-off screen only. Never in the nav.
- **First-paint entrance**: 600ms scale-and-rotate in, once per session, then never again.
- The mark is still by default. Anything that moves permanently trains people to stop looking at it.

---

## The logo

Replaces the hexagon-and-nodes mark. Four rectangles in 90° rotational symmetry — an ensemble handing work around a central gap.

Base geometry, `viewBox="0 0 64 64"`:

```html
<svg viewBox="0 0 64 64">
  <rect x="32" y="10" width="22" height="10" fill="#ec3013"/>  <!-- top, accent -->
  <rect x="44" y="32" width="10" height="22" fill="#1b1917"/>  <!-- right -->
  <rect x="10" y="44" width="22" height="10" fill="#1b1917"/>  <!-- bottom -->
  <rect x="10" y="10" width="10" height="22" fill="#1b1917"/>  <!-- left -->
</svg>
```

Three optical sizes — the bars thicken and the gap widens as the mark shrinks, so it stays a pinwheel at favicon size. Ship three files, not one scaled file:

| Size | Bar long edge / short edge | Inset |
| --- | --- | --- |
| ≥ 30px | 22 / 10 | 10 |
| 20–29px | 25–26 / 12–13 | 7–8 |
| ≤ 16px | 29 / 15–16 | 4–5 |

On ink, the three structural bars are `--paper` (`#eae4d9`) or `#f8fafc` and the accent bar is `--accent-on-ink`. Only one bar is ever accented.

The wordmark is **set, not drawn**: `ORVANNA`, Archivo 800, `letter-spacing:-0.02em` at 17–20px, `-0.01em` at 13–15px. Do not letterspace it, and do not ship letterforms as paths — that is why the current logo can never match the site's headlines.

Delete the `<rect width="460" height="100" fill="#FFFFFF"/>` from any exported primary SVG so the mark can sit on any ground.

---

## Bugs to fix first

Independent of the redesign. All three are visible in production today.

1. **Home page overlap.** The "One platform underneath" cards collide with the team paragraph — text sits on top of the three cells. Suspect an absolutely-positioned or negative-margin section.
2. **Checkout overlap and a missing step.** "Billing address" (step 2) is overlapped by the "Full name" label, and the visible step sequence reads 1, 2, 4 — step 3 Activation is missing from the flow the shopper sees.
3. **A scroll reveal that never fires.** The closing "Start the conversation" section renders at roughly one third opacity. Author reveals as `opacity:1` by default and have the observer *remove* a class, so a missed intersection fails visible rather than invisible.

Two more, one line each: the PV meter renders "800 / 100 PV" with the fill past its track (cap at 100%, relabel "Qualified month met · 800 PV"), and the checkout order summary is a scroll region nested inside the page scroll (let the rail grow and stick instead).

---

## Screens

### 6a — Home page

**Purpose:** explain what Orvanna sells and get a visitor into the catalog.

**Layout**, top to bottom, 1180px canvas, everything flush left:

1. **Nav.** Height ~58px, 15px 34px padding, `--rule-strong` bottom. Mark (28px) + wordmark, then seven links (`600 12.5px/1`, `0.04em`, `--quiet`; active is `--ink` with a 2px `--accent` bottom border), then right-aligned "Sign in" and a solid `--ink` primary button. Under 900px this must become a real disclosure menu — today eleven controls wrap and centre-pack, which is why the bar changes height between pages.
2. **Hero**, `grid-template-columns: 1.2fr 2px 0.8fr`. Left: kicker, h1 (66px, max 12ch), lead (17px, max 47ch), two buttons, then a three-cell stat strip above a `--rule-strong` top border (44px numerals, 11px/0.14em labels, 1px hair rules between cells). Right column is `--paper-raised`: "WORKING NOW" kicker, a live indicator, then five log rows separated by `--rule-row` — agent name (700 13px), what it did (400 13px), elapsed time (600 10px/0.12em, right, nowrap). **This column replaces the dead space that currently makes the hero feel empty; it is also what drives the nav mark's quarter turn.**
3. **Three pillars.** Section head, then three equal cells with 1px hair rules between: numbered kicker (`01 / DOMAIN AGENTS`, `--accent-deep`), h3, body, price line.
4. **Story band**, ink ground, `1.1fr 0.9fr`. Left: kicker, 44px headline, body, then a `2px --ink-rule` top border with the pull quote at 30px 800 in `--accent-on-ink`. Right: two stacked cells, "GATE ONE · THE VERIFIER" and "GATE TWO · QUALITY ASSURANCE". This is the only ink band on the page — it is where the drama is spent.
5. **Technology.** Three cells; each kicker is preceded by an 11px square, filled `--accent` for the shipped one and outlined for the two that are direction.
6. **Team**, `360px 1fr`. Left: `assets/hk.jpg`, `object-fit:cover`, `filter:grayscale(1) contrast(1.06)`. Right: kicker, 40px h2, body, then a two-column roster list with 2px top border and `--rule-row` rows, name left / role right, then an outlined button.
7. **Close.** Full-bleed `--accent` field, `1.15fr 0.85fr`, 46px headline left, body plus two buttons right (white solid + white outline). This is the one place the accent runs as a field.
8. **Footer.** Ink, five columns (four link lists plus a brand block with the mark, address and a live "X is working right now" line), then a 1px rule and the synthetic-data disclaimer.

**Copy:** taken from the current site, tightened. Headline "An ensemble that never clocks out" replaces "An ensemble of intelligent agents, working around the clock" — the current one wraps its last word onto its own line and tints it, which is the wrong solution to a measure problem.

### 7a — Member office

**Purpose:** answer, in this order: *am I qualified this month, what will I be paid, what do I do next.*

**Structural change:** the five tabs (`data-tab` team/volume/rank/statement/company in `portal/index.html`) become **one page with anchors**. The sidebar keeps the same six entries but they scroll rather than swap panels. Nothing in the data model changes — `app.js` already computes every number below.

**Layout:** `grid-template-columns: 252px 1fr`.

**Sidebar** (ink, 22px 20px padding, 24–26px gaps): mark + wordmark + `DEMO` pill; a rule, then "SIGNED IN AS", display name (17px 800), member code (600 12px/0.06em), and a paper-on-ink rank pill (`LEADER · PAID TO LEVEL 5`); a period control showing the month and an `OPEN`/`LOCKED` state in `--accent-on-ink`, with a line stating the day of the month and that nothing is final until the run closes; the nav as a 1px-gapped stack where the active item is a paper block with ink text; site links pushed to the bottom.

**Topbar:** kicker (`MEMBER OFFICE · AUGUST 2026`), h1 "Your month so far", right-aligned outlined + solid buttons.

**The answer band** (ink, three cells, the third on `--ink-raised`):

- *AM I QUALIFIED?* — "Yes" at 40px beside `250.00 SV`, a full-width paper meter, and a line naming the date it cleared and how much came from customer orders. **The meter caps at 100%** — never render a ratio above one.
- *WHAT WILL I BE PAID?* — `$412.80` at 40px, an outlined `PROVISIONAL · NOT A STATEMENT` pill, and a line saying it recomputes from today's orders and what last month closed at.
- *WHAT TO DO NEXT* — kicker in `--accent-on-ink`, then two rows, each an 11px square (filled `--accent-on-ink` for the blocking item, outlined for the informational one) beside a bold consequence and an explanation. This cell is the redesign's whole point: it is derived from data `app.js` already has (`legStats`, `RANK_REQS`) but never states as an instruction.

**Then, on one scroll:**

- **01 The month in volume** — four cells: Personal Volume, Customer Volume, Sales Volume (on `--paper-raised`, kicker in `--accent-deep`, with a `2.5× THE LINE` note), Team Volume. 34px numerals, 12.5px explanation under each.
- **02 Rank runway** — current rank pill → next rank pill (2px dashed, "1 RULE SHORT"), then one row per requirement: label left, `6,420 / 10,000` right, and a 7px progress bar underneath (`--accent` when short, `--ink` when met, track `#dcd4c6`). Closing note that the figures are derived in the browser from the same public views the engine used.
- **03 Your frontline** — a disc row (13px squares, ink for active, `--accent` for inactive) with "3 OF 4 LEGS ACTIVE", then a table: member code, sales volume (right), highest rank in the leg (right). The inactive leg is the only tinted row on the page: `rgba(236,48,19,.07)` with a 2px `--accent` bottom border, its code suffixed `· NOT ACTIVE` in `--accent-mid`.
- **04 July statement** — `LOCKED · RUN 6` pill in the heading, then a five-column table (level, source, basis, rate, paid) and a total row with the figure at 24px 800. Note that a reduced line prints its reason on the line.
- **05 Six closed months** — six bars, height as a percentage of the best month, latest in `--accent`, month labels beneath, then three summary rows (paid every month since, best month, rank held since).
- **Footer strip**, ink: synthetic-data note left, "figures for an open month are provisional" right.

### 8a — Staff operations console

**Purpose:** state what a human must touch today, ranked by consequence.

**Structural change:** the twelve panels of `staff-operations.html` are re-ordered by *whether they demand an action*. The attention queue stops being panel six and becomes the page. Everything that is merely true (schedule, seven-day view, run history, runs board, member drill, house ledger) drops below it as evidence. Subscription management folds into the queue as row actions.

**Layout:** same `252px 1fr` shell and the same sidebar treatment as 7a, with a `TEST` pill, a two-item console switch (`OPERATIONS` active / `PHONE ORDERS`), an "ON THIS PAGE" list of the six blocks with the first in `--accent-on-ink`, and a member-drill field labelled "Member number only".

**Topbar:** kicker with today's date, h1 "*N* things need a human today" where N is the live open count, and on the right the cleared count plus `PREVIEW THE RUN` (outlined) and `RUN NOW` (solid ink).

**Band** (ink, three cells, the middle on `--ink-raised`): NEXT BILLING RUN as a countdown with the schedule beneath; MONEY WAITING ON A DECISION, kicker in `--accent-on-ink`, the sum of open rows, with "falls as you clear them"; AUGUST, LIVE with the provisional total, members on track, and what last month closed at.

**01 Attention queue** — the page's centre. Columns: `118px 1fr 116px 168px` = severity badge, what happened (700 14px) plus reference (400 12.5px `--quiet`), at stake (right, 700 14px), one action button. Three severities, in this order:

| Severity | Badge | Rows in the mock |
| --- | --- | --- |
| `ACT NOW` | white on `--accent` | expired card pausing a subscription in 2 days; chargeback with a deadline |
| `DECIDE` | white on `--ink` | third hard decline; suspected duplicate order; tax exemption mismatch |
| `BEFORE CLOSE` | outlined, `1px #6b645a`, text `--body`, transparent fill | superseded run trail needs a note; two rows classed as both member and system fault |

`ACT NOW` rows carry a `rgba(236,48,19,.06)` background. Cleared rows drop to `opacity:.42`, strike through the title, swap the badge to the outlined treatment with a `#8a8278` border, and the button label becomes `CLEARED · UNDO`. Under the table: a line stating that every action is server enforced and audited against the operator's member number, and that clearing a row records that a human looked — it does not move money.

**02 Retry queue** — by decline class, four rows (51 insufficient funds, 05 do not honor, 54 expired card, 41/43 lost or stolen) with orders, value, and next attempt, where "MEMBER MUST ACT" is the only `--accent-mid` cell and "NEVER RETRIED" is deliberately plain. Totals row at 17px 800. Note that member fault and system fault are counted separately.

**03 The next seven days** — a 2px-bordered seven-cell strip; each cell has a weekday, date, a 5px status bar and a label. Today is an inverted ink cell with an `--accent-on-ink` bar; the day carrying a deadline is tinted `rgba(236,48,19,.08)` with an `--accent` bar. Beneath it, "RUN NOW · PREVIEW FIRST, ALWAYS" with an explanation and two buttons, the second (`ACCEPT`) disabled until a preview exists.

**04 Runs board** — month, run number, total payout, members paid, state. The superseded run stays visible with a struck-through month and figure and a `SUPERSEDED` state in `--accent-mid`. Note: a rerun that hides its predecessor is indistinguishable from a rewrite of history.

**05 House ledger** — four rows (GW-000 is not a member; unclaimed commission; activation fees; refunds against closed runs, negative in `--accent-mid` and parenthesised), then a 2px-bordered `--paper-raised` box headed "WHY THIS IS NOT A DASHBOARD" stating that every block here demands an action, states a deadline, or is evidence for one of the two.

**Footer strip**, ink: test-mode and audit note left, "schedule and run state are read from the server" right.

### Superseded options in the same file

`1b` (shop catalog) and `1c` (checkout) show the same structural fixes — a promoted pack, the twelve agents as a dense list, a sticky PV rail, and a four-step checkout with no nested scroll — but in the **old dark palette**. Use them for structure and interaction only; take colour from this document. The shop and checkout still need a pass in the new palette.

---

## Interactions and behaviour

### Attention queue (8a) — the only stateful piece

State: `done`, a map of row id → boolean. Everything else derives:

- open count = rows where `!done[id]` → drives the h1
- money at stake = sum of `amount` over open rows → drives the band figure
- cleared label = `"{cleared} of {total} cleared"`
- per row: badge style, row opacity, title strike-through, button label

Clicking a row's action toggles `done[id]`; clicking again undoes it. In production this posts to the audit log and re-reads server state rather than trusting local state — the row is a record that a human looked, not a money movement.

### Nav mark quarter turn (6a)

The mark holds a rotation of `90° × n` where `n` is the number of log advances this session, with `transition: transform .8s cubic-bezier(.2,.9,.2,1)`. In production, increment on a real event (job completed, log row appended). Disable under reduced motion.

### Working log (6a)

Five rows, newest first, each `{agent, note, elapsed}`. Rotates as new records arrive. In the prototype it advances every 2.8s from a fixed pool; in production it should read the orchestration log and cap at five rows.

### Hover and focus (all surfaces)

- Table rows in a queue or catalog: `background: rgba(236,48,19,.05)` on hover.
- Solid accent buttons: one step deeper on hover; outlined buttons take a `--tint-accent` fill.
- Keyboard focus everywhere: `outline: 2px solid var(--accent); outline-offset: 2px`. Never the browser default.
- Progress meters: `transition: width .35s ease`, and always `min(100%, …)`.

### Responsive

Both app surfaces are designed at 1280px. Below ~1080px the `252px` sidebar becomes a top bar and the two-column blocks stack; tables keep their columns but drop the least important one (highest rank, next attempt) before they scroll. The marketing nav needs the disclosure menu described in 6a. No design below 390px.

---

## Assets

| File | Notes |
| --- | --- |
| `assets/logo-mark-*.svg` | **To be cut** from the geometry above, at three optical sizes, plus a 16px favicon. Not in this bundle — the geometry is the spec. |
| `assets/logo-final-primary.svg` | Existing file, included. Its baked-in white `<rect>` has been removed in this copy. Superseded by the new mark. |
| `assets/logo-header-dark.svg` | Existing file, included. Superseded by the new mark. |
| `assets/hk.jpg` | Existing founder photograph, included. Rendered `grayscale(1) contrast(1.06)`, `object-fit:cover`. |

No icon set is required by these three screens: every symbol is a rectangle, a square or a rule. If icons are added later, the site already standardises on Lucide.

## Files

| File | What it is |
| --- | --- |
| `Orvanna Review.dc.html` | The full design canvas — turns 8 → 1, newest first. Read `8a`, `7a`, `6a` for the three screens; `5a`–`5d` for the palette study; `2a`–`3d` for the logo directions; `4a`–`4e` for motion; the `REVIEW` section for the written critique of the current site. |
| `TRIAGE.md` | What is a token change, what is a markup change, and what is a real rebuild — mapped to the actual files in `howkoz/orvanna.io`. Start here. |
| `assets/` | The three existing assets used by the mocks. |
| `screenshots/` | Target images at 2× — `6a-home-page.png`, `7a-member-office.png`, `8a-operations-console.png`, and `4e-mark-in-place-and-sizes.png` (the mark in both bars plus its 64/32/16px drawings). Check the token pass against these. |

Source repository this was designed against: `howkoz/orvanna.io@main`, tree `cb13f5395592`.
