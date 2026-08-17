# Contrast sweep: the nine corporate pages, both themes

**Date:** 2026-08-17
**Produced by:** mlm-site-builder (builder A), after the verifier's findings C-1, C-2
and C-3 on commit `713e3f8`.
**Method file:** `contrast-sweep.js` beside this document. Re-runnable.
**Raw rows:** `contrast-sweep-2026-08-17.csv` beside this document.

Acronym key: Web Content Accessibility Guidelines (WCAG), success criterion (SC),
Cascading Style Sheets (CSS), quality assurance (QA), Personal Volume (PV).

---

## 1. Why this file exists

The first pass of the corporate chrome round reported its contrast figures in a commit
message and nowhere else. The verifier tried to reproduce four of them and two did not
reproduce:

| Reported then | Reproduces? | The truth |
|---|---|---|
| 4.51, the amber "approved, not built" chip on comp-plan, light | yes, exactly | **4.510** |
| 4.86, the shop's PV figures on the sunken drawer footer, light | yes | **4.863** |
| **4.73, accent on comp-plan** | **no** | The lowest accent value anywhere on that page is **4.955**. Nothing on it measures 4.73 in either theme. |
| **5.32, the legal line on conductor, dark** | **no** | That line measures **5.684**. 5.32 is a real token pair, `#7C8AA0` on `#0A1226`, attached to an element that is not painted on `#0A1226`. |

Two further corrections to the record of that round:

- **The dark floor is 5.101, not 5.32.** The lowest dark pair on the property is the
  shop's Checkout button, `rgb(15,23,42)` on `rgb(124,138,160)`, which the verifier
  reached by driving the checkout. This sweep measures pages at load and its own dark
  floor is 5.258; the two numbers are consistent, they cover different sets.
- **"Fifty-six pairs" was a token matrix, not page coverage.** It counted colour-token
  pairs, not rendered elements, and it was presented as though it covered the pages.
  This file states what was counted before it states a number.
- **Four old storage keys were retired, not five.** `orvannaLibraryTheme` (shared by the
  two library pages), `orvanna-conductor-theme`, `orvanna-comp-plan-theme` and
  `orvanna-faq-theme`. `js/site-chrome.js` said four all along; the commit message said
  five and was wrong.

The lesson, which is the actual point: **a measurement that cannot be reproduced is not
evidence.** This file exists so the next person can re-check without redoing the work.

---

## 2. How this was measured

Every figure comes from a **real page load**, in a real browser, over a local server,
with the target theme already in `localStorage` before the load. The theme was never
flipped at runtime. Both gates independently fell into that trap on 2026-08-17 and both
recorded it: flipping `data-theme` and reading immediately returns mid-transition
colours and invents defects that are not there.

For each element that carries its own text node:

1. Walk the ancestor chain and composite every background layer down to an opaque
   colour, resolving `rgba()` alpha in the standard source-over form.
2. Resolve gradient backgrounds by averaging their opaque colour stops. An element whose
   painted backdrop is a `background-image` is otherwise measured against the wrong
   colour, which is how a white gradient card once looked like a 1.65 to 1 failure.
3. Composite the text colour itself over that backdrop if it carries alpha.
4. Apply the WCAG relative-luminance formula and the standard contrast ratio.
5. Apply the correct floor: 3 to 1 for large text, which is 24 pixels or more, or 18.66
   pixels or more at weight 700 and above; 4.5 to 1 for everything else.

Excluded, and named rather than silently dropped: elements with `display:none`,
`visibility:hidden`, zero opacity or a zero-sized box; anything inside a `disabled` or
`aria-disabled` ancestor, per WCAG SC 1.4.3, which exempts inactive controls; and the
third-party chat vendor's own markup, which this project does not author.

Also excluded, and reported instead of measured: `h1.hero-title` on `index.html`. It
uses `background-clip: text` and so has no `color` to read. Its gradient runs white to
`rgb(165,180,252)` over the deliberately dark starfield hero. Measured by hand, the
palest stop computes **9.86 to 1** and the white stop **19.65 to 1**.

---

## 3. Result

**4,314 element measurements. 2,157 per theme. Zero below the floor in either theme.**

| Page | Elements per theme | Dark minimum | Light minimum |
|---|---|---|---|
| index.html | 78 | 5.684 | 5.238 |
| shop.html | 189 | 5.375 | 4.863 |
| product.html | 55 | 5.684 | 5.238 |
| team.html | 108 | 5.684 | 5.238 |
| faq.html | 182 | 5.684 | 5.497 |
| comp-plan.html | 865 | 5.614 | 4.510 |
| conductor.html | 232 | 5.614 | 4.667 |
| library.html | 380 | 5.258 | 4.621 |
| library-agent.html | 68 | 5.614 | 4.834 |
| **all nine** | **2,157** | **5.258** | **4.510** |

**Tightest pair on the property, light theme: 4.510**, the "approved, not built" chip on
the compensation plan, `rgb(180,83,9)` on `rgb(254,243,199)`. It clears the floor by
0.01, which is thin but passing, and it is a pre-existing palette value this round did
not introduce.

**Tightest pair at load, dark theme: 5.258**, the "Not yet written" tag on the library,
`rgb(124,138,160)` on `rgb(12,20,36)`.

**Tightest pair on the property, dark theme: 5.101**, the shop's Checkout button, from
the verifier's sweep, which drove the checkout flow this one does not.

The 145 rows below 6.0 to 1, which are the only ones worth arguing about, are in
`contrast-sweep-2026-08-17.csv` with their exact composited colours.

---

## 4. Surfaces that stay dark inside the light theme

These are measured against their dark backdrop in **both** themes, deliberately. The
full list and the reasoning are named in section 3 of
`docs/CORPORATE-CHROME-CONTRACT.md`.

| Surface | Where the decision is recorded |
|---|---|
| The navigation bar | `css/site-chrome.css`, contract section 3 |
| The footer | `css/site-chrome.css`, contract section 3 |
| The starfield hero on index.html | `css/corporate.css`, contract section 5 |
| The compensation plan's cover | `comp-plan.html`, its own token block |
| The bank-approval bar, the wallet and brand tiles | `css/shop.css` |

---

## 5. Reproducing this

1. Serve `MLM-PILOT/www` over a local server. A static file server is enough.
2. Open any page, open the browser console, paste `contrast-sweep.js`.
3. Call `orvannaContrastSweep()` on each page, once with `localStorage`
   `orvanna-theme` set to `dark` and once to `light`, **reloading between the two**.
4. Compare against the table in section 3.

If a figure here does not reproduce for you, that is a finding and it should be raised.
That is the whole reason the script ships beside the numbers.
