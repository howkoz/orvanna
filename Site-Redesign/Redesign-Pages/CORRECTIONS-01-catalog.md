# Corrections round 1 — catalog page

Compared the implemented catalog against `9a`. It is close. One bug, four unfinished items, and a few weights. Nothing here is a redesign.

## 1. The rail is rendering more than once — the only real bug

"YOUR MONTH / QUALIFIED MONTH / Nothing added yet / TOTAL PV / CHECKOUT" appears four times down the right column, once per catalog group, with fragments of its copy ("carries PV.") orphaned between repeats.

The rail is **one element, rendered once, outside the group loop.** It looks like it is being emitted inside whatever loop draws DOMAIN AGENTS / SUPPORT AGENTS / BUNDLES AND PACKS.

Correct structure:

```
<div class="shop">              <!-- grid-template-columns: 1fr 322px -->
  <div class="shop-main">       <!-- hero, promoted pack, filters, all three groups -->
  <aside class="shop-rail">     <!-- rendered ONCE, sibling of shop-main -->
</div>
```

And the rail sticks rather than scrolling away:

```css
.shop-rail { position: sticky; top: <nav height>; align-self: start; background: #f1ede6; padding: 34px 26px 40px; }
```

That single fix accounts for most of the visual gap, including the empty white area above the footer.

## 2. The rail has no ground

It is currently transparent on the page ground with a hairline separator. It should be `--paper-raised` `#f1ede6`, with `border-left: 1px solid rgba(27,25,23,.25)` on the main column. It is a panel, not a margin note.

## 3. The logo has not been swapped

Still the outlined square + letterspaced ORVANNA. The new mark is section 2 of the triage — four rectangles, geometry in README under "The logo", accent bar top-right only, wordmark set in Archivo 800 at `-0.02em` (not letterspaced). Also drop the theme toggle from the bar if the site is committing to the paper ground.

## 4. Rule weights are one step light

| Where | Should be |
| --- | --- |
| Group heading underline (DOMAIN AGENTS etc.) | `2px solid #1b1917` |
| Promoted pack band, top and bottom | `2px solid #1b1917` |
| Rail: above TOTAL PV | `2px solid #1b1917` |
| Row separators | `1px solid rgba(27,25,23,.22)` — correct already |
| Row ADD button | `2px solid #1b1917`, not 1px |

The system's premise is that rules do the organising, so a hairline where a 2px rule belongs reads as unfinished.

## 5. Small things

- **Prices:** `$100 /mo` in the list, not `$100.00 /mo`. Keep two decimals for money that is actually owed — cart lines, totals, statements — and drop them in the catalog. Every row showing `.00` adds noise to twelve identical numbers.
- **Empty state:** "Nothing added yet." plus a bare "carries PV." fragment. Should be one sentence: *"Nothing selected yet. A qualified month needs 100 PV — one domain agent gets you there."*
- **CHECKOUT while empty:** currently a pale disabled-looking box. Either solid `#1b1917` and enabled once anything is in the cart, or genuinely disabled at 45% opacity. Not a wash.
- **Promoted pack:** the price column should be divided from the copy by `border-left: 1px solid rgba(27,25,23,.25)` with 22px of padding, and the band fill is `#f1ede6`.
- **`16 ITEMS` count:** right-aligned on the filter row — correct. Keep it live with the filter.
- **Cart pill in the nav:** `2px solid #1b1917`, label `CART 1`, no red dot.

## 6. What is already right

Worth saying: the row structure, the mark column, the group order, the filter row, the promoted band's content, the copy edits and the hero measure all landed. This is a good implementation — the punch list above is finishing, not rework.
