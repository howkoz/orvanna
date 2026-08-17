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

---
---

# DELTA GATE: commit `5928ff4`

**Date:** 2026-08-17, later the same day
**Agent:** mlm-verifier
**Commit graded:** `5928ff4` "Fix round: one chrome stylesheet, and four more lints so it
cannot drift back"
**Scope:** the delta only. I did not re-grade what commit `713e3f8` already proved clean,
except where my own earlier findings touched it.

## DELTA GATE: PASS

Every one of my five findings is closed, and I reproved each one myself rather than
accepting the report. Eleven of thirteen mutation probes bite, including both of the holes
I originally found. The geometry claim is correct and I measured it. The contrast artifact
is real, re-runnable, and its arithmetic reproduces.

Two new lint bypasses surfaced under harder pressure, and one reported figure is wrong
again. None of them is present in this tree as a defect a reader would meet, so they are
findings for the next round that touches the build, not blockers. I explain below why I
did not fail on the more serious of the two.

---

## 1. My five findings, reproved

| Finding | Closed? | How I proved it |
|---|---|---|
| C-1: 4.73 does not reproduce | **yes** | Corrected to 4.955 in every live location. The only surviving occurrences of 4.73 and 5.32 anywhere in the tree are inside text that documents them as wrong. |
| C-2: 5.32 does not reproduce | **yes** | Corrected to 5.684, and the dark floor recorded as 5.101. `corporate.css` rewritten. |
| C-3: no contrast artifact | **yes** | Three files committed. I recomputed all 145 rows myself, see section 4. |
| L-1: the cart lint hole | **yes** | Probe E now fails the build with a named message. |
| L-2: the page registry hole | **yes** | Probe J, my own hole, re-run by me. Now fails. |

---

## 2. Probes. Thirteen run, eleven bite

Each probe mutated one thing, ran the build, then restored the tree from git. Tree verified
clean at the end.

| Probe | Mutation | Build | Result |
|---|---|---|---|
| E | cart injected into `team.html` | exit 1 | **bites**, names the rule and the two permitted pages |
| J | new `pricing.html`, mangled navigation | exit 1 | **bites** on the page registry. My original hole is closed. |
| J2 | new `pricing.html`, navigation perfect, just unregistered | exit 1 | **bites**. The registry catches the page, not just the drift. |
| J3 | a registered page removed from source | exit 1 | build fails, but via the link checker, not the registry's own missing-page branch |
| K | active item moved from Team to Shop on `team.html` | exit 1 | **bites**: "points at shop.html, expected team.html" |
| L | active item removed entirely from `index.html` | exit 1 | **bites**: "0 active navigation items, expected exactly 1" |
| M | one token added to the pre-paint snippet on `product.html` | exit 1 | **bites** |
| N | `defer` added to the pre-paint script on `library.html` | exit 1 | **bites**, and names inline and synchronous as the requirement |
| O | `site-chrome.css` link deleted from `comp-plan.html` | exit 1 | **bites** |
| P | `.nav-link` declared in `corporate.css` | exit 1 | **bites** |
| Q | `.nav-links` declared inline in `conductor.html` | exit 1 | **bites** |
| **R** | `.some-thing, .nav-links { gap: 40px; }` in `corporate.css` | **exit 0** | **SILENT** |
| **S** | the `site-chrome.css` link wrapped in an HTML comment on `team.html` | **exit 0** | **SILENT** |
| T | descendant selector split so `.nav-links` starts a line | exit 1 | bites (safe direction) |

**Probe R, finding D-1, MEDIUM.** The chrome selector pattern anchors at the start of a line,
so it only ever inspects the FIRST selector in a comma-separated group. A chrome selector
placed anywhere after a comma is invisible to it. Grouping selectors with commas is the most
ordinary CSS there is, so this is not an exotic bypass. The single-source rule the round was
built on can be defeated by a comma.

**Probe S, finding D-2, MEDIUM.** The chrome sheet lint does a substring search over raw
HTML, comments included. A page can comment out its `site-chrome.css` link and pass. That is
precisely the incident described to me as the motivation for the lint: the window where
`shop.html` rendered its links in default browser blue because the tokens had moved and the
sheet was not yet linked. A lint that cannot catch the incident that motivated it is worth
naming plainly.

**Finding D-3, LOW.** Probe J3 shows the registry's "registered but missing from the build"
branch is unreachable in practice, because the link checker fails first on any page that
other pages link to. The build still fails, which is what matters, but that branch is
unproven.

---

## 3. Geometry, measured

Nine pages, four widths, real page loads at each width. Header height is the `.nav` element's
own box; rows are clustered on element centres.

| Width | Header height | Gap | Link font | Bar | Rows |
|---|---|---|---|---|---|
| **1280** | **69 on all nine** | 16px on all nine | 13.44px on all nine | 800 wide, or 886 on shop and product | 1 |
| 1024 | 69 on seven, **105 on shop and product** | 16px | 13.44px | 800 at x=181, or 886 at x=28 | 1 |
| 768 | **146.84 on all nine** | 16px | 13.44px | 697 at x=28 on all nine | 2 |
| 390 | **175 on all nine** | 13px | 11.52px | 335 at x=20 on all nine | 3 |

**The 69 pixel claim is correct.** Shop and product were 105 and are now 69 at 1280, and all
nine agree on height, gap, font size, plain link colour `rgb(199,208,222)` and active colour
`rgb(255,255,255)`. That is Howard's original complaint answered at his own width, measured
rather than asserted.

I also verified the 8.93 pixel arithmetic rather than restating it. At 1024 on `shop.html`,
gap 9px still gives a 105 pixel header; gap 8.93px collapses it to 69. The threshold is real,
and 8.93 is plainly not a bar anyone would ship.

### Finding D-4, LOW to MEDIUM: the narrow-width report is wrong again

"At 1024 and 390 the two cart pages still carry one extra row" is not what the tree does. I
swept twenty widths comparing `index.html` against `shop.html`:

| Width | index | shop | |
|---|---|---|---|
| 1280 to 1120 | 69 | 69 | same |
| **1080, 1024** | 69 | **105** | diverge |
| 980 | 105 | 105 | same |
| **900** | 105 | **155** | diverge |
| 860 to 600 | 146.84 | 146.84 | same |
| 500 | 138 | 138 | same |
| **430** | 138 | **185** | diverge |
| **390, 360** | 175 | 175 | **same** |
| **320** | 175 | **222** | diverge |

There are **four** divergence bands, not two. **At 390 the pages are identical**, so that
half of the claim is simply not true. And **320 pixels is not mentioned at all**, which is
the worst case: 47 extra pixels of header on the smallest phone width in common use. This is
the third time this round has put a number in a report that was not measured, and it is the
reason the coordinator was right to tell me to measure it.

### My ruling on the extra row: acceptable, it is the permitted eleventh control

1. Contract section 2 rule 3 permits the cart on shop and product as "a function of those
   pages, not chrome drift". A bar with one more control wraps one step earlier at some
   widths. That is arithmetic, not drift.
2. At the widths that answer Howard's complaint, 1280 and 768, all nine are identical. At
   390 they are identical too.
3. The alternative is a gap of 8.93 pixels or less on all nine, which I measured, and which
   would crush the bar everywhere to tidy two pages in four narrow bands.

Not a defect. But the record must say four bands including 320, not "1024 and 390".

---

## 4. The contrast artifact, checked rather than accepted

**Arithmetic.** I recomputed the contrast ratio from the stored foreground and background of
all **145** rows. Every row reproduces. Largest disagreement across the file: **0.0246**. All
145 verdicts are consistent with their stated floor. Twenty-three rows differ by more than
0.005 because the background is stored rounded to 8 bits while the ratio was taken unrounded,
the same methodological point the builder documented for the cart glyph. **Finding D-5,
LOW:** a data file whose purpose is re-checkability should regenerate its own answer exactly
from its own columns.

**Ground truth.** I re-ran my own full sweep on this commit, independently of their script:
**4,352 measurements, 2,176 per theme, all nine pages, zero below 4.5 to 1.** The per-page
minima are unchanged from my sweep of `713e3f8`, which is the useful result: consolidating
four chrome stylesheets into one changed no contrast anywhere.

| Page | Dark minimum | Light minimum |
|---|---|---|
| index.html | 5.614 | 4.983 |
| shop.html | 5.101 | 4.863 |
| product.html | 5.614 | 4.983 |
| team.html | 5.614 | 4.983 |
| faq.html | 5.614 | 4.983 |
| comp-plan.html | 5.614 | 4.510 |
| conductor.html | 5.614 | 4.667 |
| library.html | 5.258 | 4.621 |
| library-agent.html | 5.614 | 4.834 |
| **all nine** | **5.101** | **4.510** |

**Reconciling the two sets of numbers on record.** Nine of the eighteen page-and-theme minima
in the committed artifact are higher than mine, for example index light 5.238 against my
4.983, and shop dark 5.375 against my 5.101. The cause is not error. Their script skips
anything inside a `disabled` or `aria-disabled` ancestor per Web Content Accessibility
Guidelines success criterion 1.4.3, which excludes the Enroll-soon pill in the navigation and
the Checkout button while the cart is empty. Those are exactly the elements that set my
minima. **The exclusion is disclosed in their own document, with the criterion named**, so
this is a stated method difference, not a hidden one. Both readings are defensible; recorded
here so the two figures do not look like a contradiction later. Every excluded element passes
4.5 anyway when measured.

**Spot checks of the new figures, all recomputed by me, all reproduce:** hero gradient palest
stop **9.856**, white stop **19.648**; Google blue `#4285F4` on `#F8FAFC` **3.406**; the named
remedy `#1558C0` **6.294**; the word "Pay" **15.387**. The written rejection of the logotype
exemption is the right call and the reasoning survives scrutiny: the mark is `aria-hidden`
page text, governed by the 3 to 1 non-text criterion, with the accessible name carried
elsewhere.

---

## 5. The new chrome stylesheet, graded as new work

- **Deletion is complete.** The `--chrome-*` tokens are declared in `css/site-chrome.css` and
  nowhere else. No declaration survives in `corporate.css`, `library.css`, `shop.css` or any
  page.
- **No page resolves a shared chrome token to nothing.** I checked all eleven shared tokens
  at runtime on all nine pages: zero empty. The failure the coordinator warned about, the
  window where `shop.html` painted default browser blue, is not present.
- `--chrome-ind` and `--chrome-lit` resolve empty on eight pages, and that is correct: they
  are declared and used only inside `comp-plan.html`. Page-local tokens, properly scoped.
- **Link colours are identical on all nine:** plain `rgb(199,208,222)`, active
  `rgb(255,255,255)`. comp-plan no longer renders differently.
- `shop.css` changed by **comments only**. I stripped comments from both revisions and
  compared: byte identical. No commerce rule moved.

## 6. The coordinator's hand edit to `shop.html`

Graded like any other. The diff is confined to `<head>`: the shared stylesheet link added in
a commented order, and the page's own pre-paint wording replaced by the canonical block with
the payment-specific reason kept as a separate note above it. `classList.add('js')` moved
inside the canonical snippet and still runs synchronously in the head, outside the try block,
so it is applied before first paint whether or not storage throws. **No payment code, cart
code, currency code or checkout code is touched.** The edit is correct, and keeping the
page-specific reason as a separate comment is the right way to preserve it without breaking a
byte-exact lint.

## 7. Support fallback, faq, and the rest

- **Support fallback proved live.** With the vendor blocked, pressing Support sets
  `data-support-state="unavailable"`, rewrites the accessible name to "Support chat is
  unavailable. Press again to email support@orvanna.io.", and announces "The support chat did
  not load. Press Support again to email support@orvanna.io instead." through a polite live
  region. I did not observe the intermediate pending state in my probe because the failure
  was detected immediately rather than after the deadline; that is better behaviour, not
  worse.
- **The deadline is wall clock.** `Date.now() + READY_TIMEOUT_MS`, compared against
  `Date.now()`. The throttled-tab bug is genuinely fixed, not merely described.
- **`faq.html` marks Learn active**, and probes K and L prove the lint now requires the
  correct item rather than tolerating any item, or none.
- **Sign-in pages untouched by `5928ff4`.** `login.html`, `staff.html` and
  `staff-operations.html` appear nowhere in the commit.

## 8. Finding D-6, LOW: the bundle hash is not a stable artifact identity

This repository is checked out with `core.autocrlf=true`. The build hashes file bytes, so the
same commit produces a different bundle hash depending on the checkout's line endings. I hit
this myself: a line-feed-normalized tree gave `6e0b7c44e67bc265` and the byte-exact carriage
-return checkout gave `0ded97e4546ebf1e`, both from a clean `5928ff4`. Since gate verdicts
quote this hash as the identity of the thing being shipped, it should be computed over
normalized bytes.

---

## 9. Why I did not fail on D-2

I considered it seriously. D-2 lets a commented-out stylesheet link ship a page with unstyled
navigation, and that is the exact incident the lint was written for. Against that:

- The defect is **not present**. I verified at runtime, on all nine pages, that the sheet
  loads and that no chrome token resolves empty.
- Every finding I raised in the first gate is closed and independently reproved.
- D-1 and D-2 are holes I found by pressing harder than I pressed in round one. A gate that
  invents a new adversarial probe each round and fails on it can never be satisfied, which is
  its own kind of decoration.
- The round's purpose, Howard's "one site" complaint, is now measurably answered at every
  width I tested.

So: PASS, with D-1 and D-2 to be closed in the next round that touches `build_dist.py`, and
D-4 corrected in the record now rather than left standing.

---

## 10. Deploy: YES

- **The corporate chrome round deploys**, conditional on the quality assurance gate also
  passing on `5928ff4`, per the standing both-gates rule.
- **The two Edge Functions deploy**, and should. My ruling from the first gate stands: the
  `toInt` change is safe, every write path guards the fallback, and the cloud currently runs
  the weaker flooring behaviour while the repository holds the safer one. Until they
  redeploy, a `subscription_id` of 12.9 reaching the live console is still floored to 12.
- **`staff-operations.html` still does not ride this deploy.** It is a sign-in area, changed
  only by the quarantine commit, and it needs its own gate.

---

## 11. Delta findings

| # | Severity | Finding |
|---|---|---|
| D-1 | MEDIUM | The chrome CSS lint only inspects the first selector in a comma group. `.a, .nav-links { }` in `corporate.css` builds clean. Probe R. |
| D-2 | MEDIUM | The chrome sheet lint searches raw HTML including comments. A commented-out `site-chrome.css` link builds clean. Probe S. This is the incident the lint was written to prevent. |
| D-3 | LOW | The page registry's "registered but missing" branch is unreachable; the link checker fires first. Unproven code path. |
| D-4 | LOW to MEDIUM | The narrow-width report is wrong. Four divergence bands (1080 to 1024, 900, 430, 320), not two. At 390 all nine are identical. 320 is unmentioned and is the worst case at 47 extra pixels. |
| D-5 | LOW | Twenty-three of 145 rows in the contrast data do not exactly regenerate their own stated ratio from their own stored columns, up to 0.025, because the background is stored 8-bit rounded. |
| D-6 | LOW | The bundle hash is line-ending sensitive under `core.autocrlf=true`, so it is not a stable identity for the artifact being shipped. |

No HIGH findings. No MEDIUM or HIGH finding describes a defect present in this tree.

---

## 12. Artifacts graded in the delta, SHA-256

```
42c40f68b3452b83fcaeccee16dfc46d50b101dccd5534b98a31c43aad018a58  www/css/site-chrome.css
68f0c8c44e2a02795aa4adec2cc0c4488cc8bab3cf33baa9a9420f3b6d21906b  www/_partials/theme-boot.html
b3f5b5cc5eba7d57208c31ae64080c098ccc47d93050b3f8cc0003a1d81ea0fa  deploy/build_dist.py
d043422cfa5175978ab4f0dfbd4c8ff84b76fb1c325d0e63cff44c226fc21b55  www/js/site-chrome.js
e37661a45f060e350d1f10a28b21b6a5d85c494d852eb064518ef68504786fed  docs/verification/contrast-sweep.js
f95f0220f71697dc6380beab4907b966edd00d39b194010986015434398af220  docs/verification/contrast-sweep-2026-08-17.csv
```

Build bundle from a byte-exact checkout of `5928ff4`: **`sha256 0ded97e4546ebf1e`**, 38 files,
1189 KB, identical across two consecutive clean runs, so the build is deterministic. Working
tree verified clean before and after all thirteen probes.

Report only. I fixed nothing.
