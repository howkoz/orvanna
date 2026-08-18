# Shop catalog rebuild: build spec

Taken from the target Howard supplied 2026-08-18. This is TRIAGE section 3,
"Shop catalog: 13 cards to promoted pack + dense list + sticky PV rail".

Read alongside `design_handoff_orvanna_redesign/README.md` for tokens and type.
Colour and type come from the README. Structure comes from here.

Target file: `MLM-PILOT/www/shop.html` (the `viewCatalog` view) and
`MLM-PILOT/www/css/shop.css`. No framework, no build step.

---

## What changes

The sixteen product cards are deleted. The catalog becomes a two-column page:
a reading column on the left and a live cart rail on the right.

```
+---------------------------------------------+---------------------+
|  kicker, headline, lead                      |  YOUR MONTH         |
|  promoted pack block                         |  running total      |
|  filter pills                    16 ITEMS    |  qualified meter    |
|  DOMAIN AGENTS      $100 per month, 100 PV   |  line items         |
|    row, row, row, row, row, row              |  TOTAL PV           |
|  SUPPORT AGENTS      $50 per month,  50 PV   |  CHECKOUT           |
|    row, row, row, row, row, row              |  footnote           |
|  BUNDLES AND PACKS  curated, one subscription|                     |
|    row, row, row, row                        |  (sticky)           |
+---------------------------------------------+---------------------+
```

Grid: left column flexible, rail 300px, 2px ink rule between them. The rail is
`position: sticky` and must obey the same guard added on 2026-08-18: withdraw
stickiness when the rail is taller than the viewport, or its bottom becomes
unreachable. See `.checkout-summary.is-tall` in `css/shop.css` for the pattern
already in the codebase.

---

## 1. Head

- Kicker `THE CATALOG`, accent-deep, 10.5px, 0.20em, 700, uppercase.
- Headline **"Staff your back office in an afternoon"**, 40 to 44px, 800,
  -0.035em, max-width about 16ch so it breaks after "in an".
- Lead, 17px, 1.55, max 47ch: "Every item is a monthly subscription carrying
  Personal Volume. Twelve agents at $100 or $50 a month, or take a pack and pay
  once for the ensemble."

Personal Volume (PV) is spelled out on first use, then PV.

## 2. Promoted pack block

One bordered box, 2px ink top rule, paper-raised fill, above the filters.

- Left: kicker `START HERE · MOST SUBSCRIBED` in accent-deep; h2 "Ignition
  Pack" at 26 to 30px 800; two-line description; then three outlined tag chips,
  one per included agent (PAYMENT, CUSTOMER CARE, SECRETARY), 11px 700 0.10em.
- A 1px hairline divides left from right.
- Right: `$200`/mo at 34px 800 with the `/mo` small and quiet; `200 PV` in
  accent-mid; `or $2,000 outright` in quiet; then a solid accent button
  **ADD THE PACK**, white label, 12.5px 700 0.10em uppercase.

Which pack is promoted comes from the catalog, not a hard-coded sku. Pick the
one flagged as most subscribed, and fall back to the cheapest pack.

## 3. Filter row

Pills: All, Domain, Support, Bundles. Active is solid ink with paper text;
the rest are outlined with a 1px hairline. Right-aligned count, "16 ITEMS",
9.5px 0.14em 600 uppercase in faint. The count reflects the active filter.

## 4. Group headers

One per group, 2px ink bottom rule:

| Group | Meta |
| --- | --- |
| DOMAIN AGENTS | $100 per month · 100 PV each |
| SUPPORT AGENTS | $50 per month · 50 PV each |
| BUNDLES AND PACKS | Curated ensembles, one subscription |

Name 12px 700 0.14em uppercase ink; meta 12.5px 400 quiet, on the same line.

## 5. The rows

Grid per row: `28px 1fr 110px 90px 96px`, 13 to 15px vertical padding,
`--rule-row` between rows.

1. **Mark** — 28px square, 1px hairline border, a single character inside at
   11px 700. Not an icon set: the design uses a letter or symbol per item.
2. **Name and line** — name 14px 700 ink; description 12.5px 400 quiet on the
   second line.
3. **Price** — `$100` 14px 700 ink, `/mo` 11px quiet. Right-aligned, tabular.
4. **PV** — `100 PV` 13px quiet, right-aligned, tabular.
5. **Action** — outlined ADD button, 11px 700 0.10em uppercase.

**In-cart state**: the row takes a `rgba(236,48,19,.06)` tint, and the button
becomes solid ink reading **REMOVE** with paper text.

Hover on a row: `background: rgba(236,48,19,.05)`.

## 6. The rail: YOUR MONTH

Sticky, paper ground, 2px ink rule on its left edge.

- Kicker `YOUR MONTH`.
- Running monthly total, `$200.00` at 34 to 40px 800, `/mo` small and quiet.
- A row: `QUALIFIED MONTH` left, `MET · 200 PV` right in accent-mid when met,
  otherwise the shortfall. **The meter caps at 100 percent** and never prints a
  ratio above one; the same defect was fixed in the drawer on 2026-08-18.
- One line of explanation: "Qualified month met. Everything above 100 PV counts
  toward rank."
- A 1px rule, then one line per cart item: name 13px 700, PV beneath in quiet,
  price right, then a quiet `REMOVE` link.
- A 1px rule, then `TOTAL PV` left and the figure right at 17px 800, tabular.
- Solid ink **CHECKOUT** button, full width, paper label.
- Footnote in quiet: "Agents are digital, nothing ships. Cancel any month."

Empty cart: keep the rail, show the qualified line at 0 PV and a single line
saying nothing has been added. Do not hide the rail; it is the page's spine.

---

## Rules that carry over

- Every numeric column is `font-variant-numeric: tabular-nums` and right
  aligned.
- Zero border radius, no box shadows.
- Focus ring `2px solid var(--accent)` with 2px offset on every control.
- Below about 1080px the rail moves under the list and stops being sticky.
  Rows keep their columns but drop PV before they scroll.
- The accent is for fills, numerals and chrome. As paragraph text on paper it
  takes the deeper form.

## Do not lose

The cart is shared with the drawer and checkout. Adding or removing from a row
must go through the same cart functions the drawer uses, so the two never
disagree, and the existing drawer keeps working.

`docs/` note: the 2026-08-18 card-tightening work applied to the deleted grid.
It does not carry over and does not need porting.
