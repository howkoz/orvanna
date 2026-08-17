# Corporate chrome round: verifier verdict

**Date:** 2026-08-17
**Agent:** mlm-verifier (independent; built none of this)
**Law graded against:** `MLM-PILOT/docs/CORPORATE-CHROME-CONTRACT.md`, section 7 definition of done
**Commits graded:**
- `713e3f8` One site: canonical navigation and an icon-only theme on all nine corporate pages
- `a334250` Quarantine: unattributed console changes from 2026-08-16 evening, ungated

**Acronym key:** Cascading Style Sheets (CSS), JavaScript (JS), Scalable Vector Graphics
(SVG), Hypertext Markup Language (HTML), Web Content Accessibility Guidelines (WCAG),
Personal Volume (PV), Quality Assurance (QA).

---

## GATE: FAIL

No visitor-facing defect was found. The site itself is correct and safe.
The FAIL is on evidence and on lint coverage:

1. Two of the four contrast figures I was asked to recheck do not reproduce. A reported
   measurement that cannot be reproduced is the exact failure mode this project was warned
   about, and contract section 5 makes "computed and reported" a first-class requirement.
2. No contrast artifact was committed. The numbers exist only in a commit message, so
   nobody can re-check them without redoing the work I just did.
3. The navigation drift lint has two escape hatches, one of them proven by probe: a brand
   new corporate page ships with a mangled navigation and a PASSING build.

Every remedy is small and documentary. Re-gating should be quick.

---

## 1. What I did, and how

I did not read the builders' numbers and agree with them. I recomputed.

- **Navigation:** a check script of my own (not `build_dist.py`, so a bug in the builders'
  lint could not hide inside my result) compared all nine pages against
  `www/_partials/nav.html`.
- **Lint:** six mutation probes. Each broke one page, ran the build, recorded the verdict,
  then restored the tree from git. A lint that never fails is decoration, so I made it fail.
- **Contrast:** I drove the pages in a real browser over a local server, walked every
  element carrying its own text, composited translucent backgrounds down the ancestor chain
  to an opaque colour, and applied the WCAG relative-luminance formula. **4,352 measurements
  in total: 2,176 elements per theme across the nine pages, both themes.**
- **A measurement trap I fell into and corrected, recorded so nobody repeats it:** my first
  pass flipped the theme by setting `data-theme` on the root element at runtime. On
  `conductor.html` that produced four button pairs at 1.23 to 1, which would have been a
  HIGH finding. It was false. On a genuine page load in the light theme the same buttons
  measure 15.4 to 1. **Every figure below comes from a real page load per theme, never from
  a runtime attribute flip.** I withdrew the false finding rather than report it.

Working tree was clean before and after every probe. Build bundle hash unchanged at
`67a23f23bbe813bc` before and after.

---

## 2. Claim by claim

### Claim 1: canonical navigation on all nine, character for character. VERIFIED

All nine pages match `_partials/nav.html` after stripping only the two permitted
differences. Canonical block normalizes to 1,563 characters.

| Page | Navigation matches | Active item | `aria-current="page"` | Cart |
|---|---|---|---|---|
| index.html | yes | index.html | 1 | no |
| shop.html | yes | shop.html | 1 | yes |
| product.html | yes | shop.html | 1 | yes |
| team.html | yes | team.html | 1 | no |
| faq.html | yes | none | 0 | no |
| comp-plan.html | yes | comp-plan.html | 1 | no |
| conductor.html | yes | conductor.html | 1 | no |
| library.html | yes | library.html | 1 | no |
| library-agent.html | yes | library.html | 1 | no |

`faq.html` carries no active item, correctly: the canonical navigation has no FAQ link, so
there is no item to mark. Not a defect.

Cart appears on `shop.html` and `product.html` only, and on both it sits immediately after
the theme button with nothing between them. Correct per section 2 rule 3.

No visible "Light", "Dark", "Auto" or "Theme" text inside any of the nine navigations. The
old Theme trio, the text-labelled Dark buttons and the Light/Dark words are gone.

The three sign-in pages carry no `nav-links` block at all, so the lint's exclusion is
structural as well as declared.

### Claim 2: one icon-only theme control on all nine. VERIFIED

Measured live, not read from source:

- Button is **40 by 40 pixels** on every page checked. Declared once in `corporate.css` and
  once in `library.css`; both agree.
- **Visible text is the empty string** on every page.
- **`aria-label` tracks state in both directions.** Starting dark it reads "Switch to the
  light theme"; one click gives theme `light`, label "Switch to the dark theme", storage
  `light`, sun icon hidden and moon icon shown; a second click returns to dark with the
  label and storage back. Both directions confirmed.
- **One storage key.** `orvanna-theme` is the only theme key on all nine. No page still
  references any old key.
- **Applied before first paint.** All nine carry a synchronous inline `<script>` in `<head>`
  with no `defer` and no `async`, so there is no flash of the wrong palette.

**Correction to the commit message:** it says "five old storage keys collapse to
orvanna-theme". I counted the pre-round tree and found **four** distinct keys:
`orvannaLibraryTheme` (used by two pages), `orvanna-conductor-theme`,
`orvanna-comp-plan-theme`, `orvanna-faq-theme`. `site-chrome.js`'s own comment correctly
says four. The commit message is wrong; the code is right. LOW.

Deliberate departure, noted and not treated as a defect per contract section 3: no
`prefers-color-scheme` rule survives anywhere, so the library pages no longer follow the
operating system. Dark is now the default site-wide, as the contract decided.

### Claim 3: Support works on the four pages that never had it, vendor scripts load once. VERIFIED

Live click test on `conductor.html`, `comp-plan.html`, `library.html` and
`library-agent.html`, the four pages where the widget did not previously exist:

- Support trigger present on each.
- Exactly **2** vendor scripts injected per page (the loader and its configuration file),
  carrying the `data-orvanna-support-script` marker.
- `window.botpress.open` resolves to a function on each; the widget container appears after
  the click.

Zero inline vendor script tags remain on any of the nine (comments mentioning the URLs do
not count; I stripped comments before counting real tags). `site-chrome.js` loads exactly
once per page, and its `document.querySelector('script[data-orvanna-support-script]')` guard
prevents a second injection. Builder B's removal of the shop's inline pair is correct and
leaves the shop with exactly one pair, injected by the shared module.

`staff.html` retains its own inline pair, which contract section 4 explicitly requires.

### Claim 4: contrast. PRODUCT VERIFIED, TWO REPORTED FIGURES DO NOT REPRODUCE

**My measurements. 2,176 elements per theme, both themes, every one of the nine pages.
Zero pairs below 4.5 to 1 in either theme.**

| Page | Elements measured | Dark minimum | Light minimum |
|---|---|---|---|
| index.html | 80 | 5.614 | 4.983 |
| shop.html | 192 | 5.101 | 4.863 |
| product.html | 57 | 5.614 | 4.983 |
| team.html | 110 | 5.614 | 4.983 |
| faq.html | 184 | 5.614 | 4.983 |
| comp-plan.html | 867 | 5.614 | 4.510 |
| conductor.html | 234 | 5.614 | 4.667 |
| library.html | 382 | 5.258 | 4.621 |
| library-agent.html | 70 | 5.614 | 4.834 |
| **all nine** | **2,176** | **5.101** | **4.510** |

One element is excluded and reported instead of measured: `h1.hero-title` on `index.html`
uses `background-clip: text`, so it has no `color` to measure. Its gradient runs white to
`rgb(165,180,252)` over the dark starfield hero, in both themes. That is the deliberate
dark-inside-light surface the contract names in section 5 and the commit message documents.

**The four figures I was asked to recheck, beside what I compute:**

| Claimed | My recomputation | Verdict |
|---|---|---|
| 4.51 amber on comp-plan (light) | **4.510** `#B45309` on `#FEF3C7`, the "approved, not built" chip | **CONFIRMED**, exactly |
| 4.86 accent on the shop's sunken drawer-footer block (light) | **4.863** `rgb(14,116,144)` on `rgb(241,244,250)`, the "0 / 100 PV" and "0 PV" figures | **CONFIRMED** |
| 4.73 accent on comp-plan | **not reproducible.** The lowest accent value anywhere on comp-plan is **4.955** (`rgb(14,116,144)` on `rgb(244,246,251)`, the section kickers). I also computed accent against every light surface token: paper 5.358, surface 5.048, band-b 4.955, accent-bg 4.841. Nothing on that page measures 4.73 in either theme. | **DOES NOT REPRODUCE** |
| 5.32 legal line on conductor (dark) | **5.684** `rgb(124,138,160)` on `rgb(5,9,20)`. The footer background is `rgb(5,9,20)`, not the `#0A1226` token. The pair `#7C8AA0` on `#0A1226` does equal **5.322**, so 5.32 is a real token-pair number attached to the wrong element. | **DOES NOT REPRODUCE at that location** |

**Consequence for the summary claim.** "Worst 5.32 dark" is not the worst dark pair. The
true dark floor across all nine pages is **5.101**, the shop's Checkout button
(`rgb(15,23,42)` on `rgb(124,138,160)`). "Worst 4.51 light" is correct: I measure **4.510**
and it is the comp-plan amber chip, exactly as claimed.

**On the counts.** "56 pairs on the corporate pages" is a token-pair matrix, not a coverage
figure for the rendered pages; it should not be presented as though it covered them. The
"412 elements per theme" sweep of the shop does not match my count either: `shop.html` has
937 elements in total and 192 that carry their own text. 412 is neither, so I cannot say
what was counted. Both parties' numbers are defensible under their own definitions; the
problem is that the definition was never stated.

**None of this changes the outcome for a reader.** Every one of the 4,352 pairs I measured
clears 4.5 to 1. The light theme genuinely renders on all nine. The defect is in the
evidence, not the pixels.

### Claim 5: no payment logic moved. VERIFIED, with the stated line numbers corrected

`shop.html` has exactly four diff hunks in `713e3f8`, and I read all four in full:

1. the pre-paint theme snippet added to `<head>`;
2. `aria-current="page"` added to the already-active Shop link;
3. the theme button inserted before the cart, plus a comment;
4. the inline Botpress block replaced by the `site-chrome.js` tag.

**No payment code, no cart logic, no currency logic, no checkout logic is touched.** The
claim is substantively true.

The stated line bounds are not. In new-file numbering the third hunk spans lines **47 to
71**, and the fourth begins at line **3290**. So the accurate statement is "no diff hunk
between line 72 and line 3289", not "between 50 and 3292". LOW, but it is a number stated
without being computed, in the same commit as the contrast figures.

I did not attempt to reproduce the 936-element computed-style regression. `shop.html` has
**937** elements in the browser, so a 936-element sweep excluding the root element is
consistent with what I see.

### Claim 6: the lint fails on drift. VERIFIED FOR THE NINE, TWO ESCAPE HATCHES

Six probes. Each mutated one page, ran the build, then restored the tree.

| Probe | Mutation | Build | Verdict |
|---|---|---|---|
| A | Library link deleted from `team.html` | exit 1 | lint bites |
| B | "Conductors" renamed to "Conductor" on `conductor.html` | exit 1 | lint bites |
| C | `aria-current="page"` stripped from the active item on `index.html` | exit 1 | lint bites, by its dedicated pairing check |
| D | Library and Plan swapped on `faq.html` | exit 1 | lint bites |
| E | A cart button injected into `team.html` | **exit 0** | **lint silent** |
| F | Theme `aria-label` changed on `library.html` | exit 1 | lint bites |

**Finding, MEDIUM (probe E).** `NAV_CART_RE` strips a `nav-cart` element from *any*
corporate page before comparing, not only from `shop.html` and `product.html`. Contract
section 2 rule 3 permits the cart on those two pages only. A cart added to `team.html`
ships with a passing build.

**Finding, MEDIUM (proved by a seventh probe).** The lint iterates a hardcoded
`CORPORATE_PAGES` tuple and nothing cross-checks that tuple against the HTML files actually
in the build. I created `www/pricing.html` as a copy of `faq.html` with its Library link
removed. The build printed "nav drift lint: 9 corporate pages match" and exited **0**. A new
corporate page is unlinted until somebody remembers to add it by hand, which is precisely
the memory the lint exists to replace. The build already knows what landed in `dist`; it
should assert that every root HTML page is either linted or explicitly excluded.

The lint's own docstring is honest that it flattens whitespace and drops comments, so
"character for character" in the contract means "token for token, ignoring indentation and
comments". Worth saying out loud since the contract uses the stronger phrase.

The sign-in exclusion is correct and is named in the build output.

### Claim 7: the three sign-in pages untouched by 713e3f8. VERIFIED

Compared at the blob level, not the working tree (the repository checks out with converted
line endings, so an on-disk hash comparison gives a false positive here; I mention it so the
next verifier does not chase it).

| Page | Pre-round `2b6161f` | After quarantine `a334250` | After chrome `713e3f8` |
|---|---|---|---|
| login.html | `a6bed1eed92745a4` | same | same |
| staff.html | `6c6bf34ae411d3aa` | same | same |
| staff-operations.html | `9715f9e10acca1f6` | **changed** | unchanged by the chrome commit |

`713e3f8` touched none of the three. `staff-operations.html` changed only in the quarantine
commit, which contract section 7 item 6 allows as "other work". Contract item 6 satisfied.

### House-style and project guardrails

Zero em dashes and zero en dashes in any line added by `713e3f8`. No Unicity name, data or
terminology anywhere in the new artifacts. Browser console clean, no errors, across every
page I loaded.

---

## 3. Ruling on the quarantined commit `a334250`

### The change

One line, identically, in `functions/billing-console/index.ts` and
`functions/commission-report/index.ts`:

```ts
- return Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
+ return Number.isInteger(n) && n >= 0 ? n : fallback;
```

### I checked the coordinator's analysis rather than trusting it. It holds.

**The run limit is not affected.** `parseRunLimit` is a separate function and it already
required `Number.isInteger(n)` and a range of 1 to 100000. Confirmed by reading it.

**Call sites.** I enumerated every one. Thirteen in total:

- `billing-console`: pagination `limit` and `offset`; `run_id`; `subscription_id`; `months`
  (pause length); `new_day`; `new_frequency`.
- `commission-report`: `run_id` twice; `lines_limit`, `lines_offset`, `results_limit`,
  `results_offset`.

Matches the coordinator's list exactly.

**The behavioural delta is narrow.** I worked through the input space. Empty string, null,
whole-number strings, booleans, arrays, negatives, `NaN` and `Infinity` all behave
identically before and after. **The only difference: a finite non-integer of zero or more
now returns the fallback instead of its floor.**

**Every write path is guarded, and the guard rejects the fallback.** I read them:

- `subscriptionId <= 0` refuses with `bad_subscription`, before any database call.
- `months` must be exactly 1 or 2, else `bad_months`.
- `new_day` must be 1 to 28, else `bad_day`.
- `new_frequency` must be 1, 2, 3 or 6, else `bad_frequency`.
- `run_id` on both functions refuses at `<= 0` with `bad_run_id`.

So the fallback of 0 can never reach a write. The change converts a silent wrong write into
a visible refusal. The coordinator's judgement is correct and I reach it independently.

### One behaviour genuinely changes, and it is reachable from Howard's own console

`staff-operations.html` builds the "Change billing day" control as a free **text** field,
guarded only by a range check:

```js
var v = Number(day.value());
if (!(v >= 1 && v <= 28)) { window.alert('Billing day picks run 1 to 28.'); return null; }
```

`Number("12.5")` is 12.5 and passes that range check, so a decimal reaches the server.

- **Before:** the server floored it to 12 and **changed the billing day to 12**, silently,
  on a real subscription.
- **After:** the server returns the fallback 0, the `day < 1` guard refuses, and the
  operator sees "Billing day picks run 1 to 28."

That is a real behaviour change on a live write path. It is not behaviour anyone relies on:
nobody means a fractional billing day. It replaces a silent wrong write with a refusal,
which is the direction you want. **Verdict: an improvement, as claimed.**

Separate small suggestion, out of scope for this commit: the client-side guard should test
`Number.isInteger` as well as the range, so the operator gets the message immediately
instead of after a round trip.

### Safe to deploy: YES, the code is safe

The two functions are safe to deploy on their merits. Nothing they do gets worse; one
class of silent wrong write becomes a refusal.

### The deploy-truth consequence, stated plainly

**The running cloud function was deployed before this edit and still floors.** Commit
`63bc130` "Deploy: the console lives" is timestamped 2026-08-16 19:01, and the quarantined
edits were written between 20:27 and 21:35 the same evening. The repository and the cloud
have diverged on both functions.

What that means in production **today**: a `subscription_id` of 12.9 reaching the live
billing console is still floored to 12, and pause, cancel and change-frequency all run off
that identifier. The repository holds the safer behaviour; the cloud does not. Until the two
functions redeploy, the safer code is not the code that runs.

I could not byte-compare the deployed source against the repository copy, which my charter
normally requires: the cloud project connector needs authorization and this session is
non-interactive. The divergence above rests on the commit timeline, which is unambiguous.

**`staff-operations.html` must not ride the corporate-chrome publish.** It is a sign-in area,
excluded from this round by name. It was changed by the quarantine commit and needs its own
gate, not a free pass inside a chrome deploy.

---

## 4. Findings

| # | Severity | Finding |
|---|---|---|
| C-1 | MEDIUM | "4.73 accent on comp-plan" does not reproduce. The lowest accent value on that page is 4.955, and no element in either theme measures 4.73. |
| C-2 | MEDIUM | "5.32 legal line on conductor" does not reproduce. That line measures 5.684. 5.32 is the token pair `#7C8AA0` on `#0A1226`, attached to the wrong element. The true dark floor across all nine pages is 5.101, the shop's Checkout button. |
| C-3 | MEDIUM | No contrast artifact was committed. Contract section 5 requires the pairs be computed **and reported**; they exist only in a commit message, unreproducible without redoing the sweep. |
| L-1 | MEDIUM | The lint strips a `nav-cart` element from any corporate page, not only shop and product. A cart injected into `team.html` builds clean. Proved by probe E. |
| L-2 | MEDIUM | The lint iterates a hardcoded page tuple with no assertion that it covers every HTML page in the build. A new `pricing.html` with a mangled navigation built clean and exited 0. Proved by probe. |
| D-1 | LOW | The commit message says five old storage keys; there were four. `site-chrome.js`'s own comment is correct. |
| D-2 | LOW | The shop diff bounds are stated as "between 50 and 3292"; the third hunk actually spans new lines 47 to 71 and the fourth begins at 3290. |
| D-3 | LOW | `site-chrome.js` is referenced as `?v=1` on eight pages and `?v=5.2` on the shop, a small drift between the two builders. No shipped effect: `build_dist.py` restamps every asset uniformly, so the built output is consistent. |
| N-1 | LOW | The contract says "character for character"; the lint compares token for token, ignoring indentation and comments. Reasonable, and documented in the lint, but the contract wording overstates it. |
| W-1 | withdrawn | My first pass reported four `btn-ghost` pairs on `conductor.html` at 1.23 to 1 in the light theme. **False.** It was an artifact of flipping `data-theme` at runtime instead of loading the page. On a real load they measure 15.4 to 1. Recorded so the trap is not repeated. |

No HIGH findings.

---

## 5. Contract section 7, item by item

| # | Requirement | Result |
|---|---|---|
| 1 | Canonical navigation on all nine, character for character | **PASS** |
| 2 | One icon-only theme control on all nine, both directions, one key, no flash | **PASS** |
| 3 | A light theme that genuinely renders on all nine, contrast computed and reported | **PARTIAL.** Renders and measures clean on all nine. Reporting fails: C-1, C-2, C-3. |
| 4 | Support works on all nine | **PASS** |
| 5 | `build_dist.py` fails on navigation drift and passes on the current tree | **PARTIAL.** Fails on five of six drift probes and passes clean today. Two escape hatches: L-1, L-2. |
| 6 | The three sign-in pages unchanged except by other work | **PASS** |
| 7 | Both gates PASS on the exact artifact before deploy | **this gate: FAIL** |

---

## 6. Deploy: NO

Not today, and not because the site is wrong.

- **The corporate chrome artifact is visitor-safe.** I found no defect a reader would meet.
  If it shipped this morning nothing would break.
- **But my gate is FAIL**, and the standing rule is that both gates pass on the exact
  artifact before anything reaches the live property. Close C-1, C-2, C-3, L-1 and L-2, then
  re-gate. All five are small: file the contrast sweep as an artifact with the numbers that
  actually reproduce, scope the cart exemption to two pages, and make the build assert that
  every root HTML page is either linted or explicitly excluded.
- **The two Edge Functions are safe and should redeploy** once the gate passes, because the
  cloud currently runs the weaker flooring behaviour and the repository does not.
- **`staff-operations.html` does not ride this deploy.** It is a sign-in area and needs its
  own gate.

---

## 7. Artifacts graded, SHA-256

```
1020b7ff7519633046310dd5c59e634549120596746077398e57fc4066305a45  www/index.html
21ecf0399df41f64f59c7a2b6865f1a62f99e8ee2e08dad22ca6de23e95a3a63  www/shop.html
e99b536b5046734f54bacf8536bfc62069c2aea56ba847021e3323683203e3dd  www/product.html
eb135e86ac79d71c7519b811bab8b1c75cdfbb561c6730bf6415618eb6a2c122  www/team.html
66fd5b46e2640a94e83b881623ecf01d1f97793d4d91e9231695766dabadd3c9  www/faq.html
e804da80a5621d65c1619d5cfc8022b079188a6a6877e33477ed1996137889f0  www/comp-plan.html
3eeb21f9bb14f96bc2ca90d5b937bf77c29e81885faac907b060d9f191cc1d8d  www/conductor.html
339bae6b177f0425da2e3357d5b8589dff18471619c9f7ff1566250704bcedb5  www/library.html
fef3510f47501dfd8bf91745486bbb73a0ab8e82283c13f0cd0554d6fca09f87  www/library-agent.html
b1e7e13ce2f85206ea6562bf2c7cc320c545742587e0e285c5db44e8c2e15275  www/_partials/nav.html
c84457ef725c3da78ce0a5c53fa26bcd0d722f734de7234df2eb824dbe74ed20  www/js/site-chrome.js
26f86ba871e28e18919b6a0fd3cb03b134b825e4c6cc0070cef6da1dadd34560  www/css/corporate.css
2560d399fb2626f7f14857ba5d83cf34e231f89251722734b21dd4db79bcd652  www/css/shop.css
329b03362186813679954882b0dea2cd9274e7f5ad5a24bb291e2195ad58d6ea  www/css/library.css
ced2b7db07262f4ff24d51996173ab7879ceeaf14b1508ea4ddceb3e0d303e25  deploy/build_dist.py
b095b914b859b82263a59c4d1595b3acf089ead2c668398311efd5dcd9463583  functions/billing-console/index.ts
a341b8e0d96d675d50bac1fb07d3ee8a761f63a968d341083a63d9d1a877e738  functions/commission-report/index.ts
```

Build bundle at the graded state: `sha256 67a23f23bbe813bc`, 37 files, 1178 KB. Identical
before and after every mutation probe, so the tree I graded is the tree that stands.

Report only. I fixed nothing.
