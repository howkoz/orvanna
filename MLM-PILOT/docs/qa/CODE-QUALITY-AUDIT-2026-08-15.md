# Code Quality Audit, Orvanna front end

Date: 2026-08-15
Scope: `www/*.html`, `www/css/*`, `www/js/*`, `site/*`, `deploy/build_dist.py`
Brief: Howard, verbatim: "I want everything to be world class coding and clean and nothing sloppy."
Craftsmanship review. No file was edited.

Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\CODE-QUALITY-AUDIT-2026-08-15.md`

Acronym key: PV = Personal Volume. SV = Sales Volume. 3DS = 3-D Secure, the card networks'
identity check. SDK = Software Development Kit, here the HyperSwitch payment widget.
DOM = Document Object Model, the browser's live page structure. CSS = Cascading Style Sheets.

---

## The map

```
                        WHAT WOULD ACTUALLY BITE, IN ORDER

  ┌──────────────────────────────────────────────────────────────────────────┐
  │  SILENT BREAKAGE          11 findings                                     │
  │                                                                           │
  │   A1  stale ?v=5.2 stamp .... today's z-index fix may never reach a       │
  │                              returning browser                            │
  │   A2  7 fetch chains .......  no rejection handler; a dropped connection  │
  │                              freezes checkout with the button hidden      │
  │   A3  staff total moves ....  payment settles at the OLD amount           │
  │   A4  2 phantom selectors ..  the guard that would stop A3 matches nothing│
  │   A5  portal boot retry ....  double listeners; theme toggle stops working│
  │   A6..A11  reveal timer, two definitions of "qualified", silent product   │
  │            substitution, gate paints first, unescaped innerHTML, chat race│
  └──────────────────────────────────────────────────────────────────────────┘
                                     │
  ┌──────────────────────────────────▼───────────────────────────────────────┐
  │  MAINTENANCE TRAPS        duplication + build                             │
  │                                                                           │
  │   shop.html  ══════ 224 lines ══════>  staff.html                        │
  │              25 shared functions, 20 of them 95-100% identical            │
  │              ALREADY DIVERGED in 2 places, both in the shop's favour      │
  │                                                                           │
  │   Botpress trigger  ×6 byte-identical copies  (+1 silent variant)         │
  │   build_dist.py     honest, but case-blind, allowlist-free, unstamped     │
  └──────────────────────────────────────────────────────────────────────────┘
                                     │
  ┌──────────────────────────────────▼───────────────────────────────────────┐
  │  TIDINESS                 dead code + comments + naming                   │
  │                                                                           │
  │   the fake checkout is still in both files, behind `const X = true`       │
  │   the payment-link path has two handlers that provably do nothing         │
  │   4 comments say the opposite of the code beside them                     │
  └──────────────────────────────────────────────────────────────────────────┘
```

**Headline.** The comment discipline in this codebase is genuinely excellent and is the reason
this audit was fast. The problems are not carelessness; they are the residue of shipping five
rounds in two days without a consolidation pass. Two of them can lose a shopper's payment
state, one can charge the wrong amount on the staff console, and one can quietly serve
yesterday's stylesheet over today's fix.

---

## A. Silent breakage

| # | Sev | Finding | Where |
|---|-----|---------|-------|
| A1 | **HIGH** | **Stale cache-buster.** Every stylesheet and script in `www/` is still stamped `?v=5.2`. That stamp was set in commit `f48200d`; `shop.css` and `staff.css` were rewritten today by `0cf4641` (the z-index stacking fix), `ba5740d` and `5fae4f4`. The URL did not change, so a browser holding the old stylesheet keeps it. The casualty is the bank-approval chrome: with the old `z-index: 2147483000` it paints **behind** the payment widget's frame, hiding the order number, the test-mode notice and the cancel button at the exact moment they matter, which is the bug that was fixed today. ROADMAP records `Cache-Control: max-age 600` on the HTML, so the page expires in ten minutes and the CSS does not. | `www/shop.html:9,10,569`; `www/staff.html:9,10,278`; `www/index.html`, `team.html`, `product.html`, `login.html:9`. `site/` is separately at `?v=5.3` |
| A2 | **HIGH** | **Seven promise chains with no rejection handler.** `fnCall` only guarantees non-rejection on an HTTP error *status*; a transport failure still rejects. The worst case is `livePollReceipt`, entered from `liveAfterSdk` immediately after `liveSetFinishing(true)` has hidden the Place order button: a dropped connection leaves "Finishing your order, one moment" on screen forever, with nothing to press and no error. | `shop.html:2189, 2428, 2486`; `staff.html:1452, 1646, 1867, 1889`. `fnCall` at `shop.html:1443` |
| A3 | **HIGH** | **The staff console can move the total after the payment is open.** The shop closed this hazard with an amount signature (`shop.html:1568-1628`); staff.html has no equivalent. After `liveStaffStart` mounts the card form and labels the button "Take $X now", nothing is inert (`setOrderInert` runs only from `liveStaffConfirm` and `openChallengeChrome`), so the agent can add a line. `renderTotals` updates the displayed total and re-enables the button, but the payment settles at the amount fixed at creation. Then the read-aloud confirmation reads `orderMath()`, the **new** total, for a payment taken at the **old** one. On a call console that is the number the agent speaks to the caller. | `staff.html:1477-1525` (start), `1531` (inert), `823-840` (renderTotals), `1073` (confirmation math) |
| A4 | **HIGH** | **Two phantom selectors defeat the staff inert guard.** `setOrderInert` disables `.line-qty, .line-drop`. Neither class exists anywhere; the order table renders `.qty-step` and `.line-remove-btn`. So during a live payment and during a bank approval the quantity steppers and Remove buttons stay fully usable. This is the half that was supposed to prevent A3. | `staff.html:1290` vs `staff.html:795, 797, 801` |
| A5 | **MED-HIGH** | **Retrying a failed portal boot double-binds listeners and breaks the theme toggle.** `setError(teamEl, err, boot)` retries with `boot`, which calls `initTheme()` and `initTabs()` again. Each attaches a second listener. The two theme listeners each read the current attribute and flip it, so the second undoes the first: after one failed boot and a retry, the light/dark button does nothing. Tab clicks render twice. | `site/js/app.js:1459-1467`, `1420-1431`, `1433-1444` |
| A6 | **MED** | **The challenge-reveal timer is never cancelled on reset.** `liveResetPayment` and `staffResetLive` clear every other piece of live state but not `challengePendingTimer`. A pending reveal fires afterwards and opens the chrome bar with the order number already nulled, printing "Order not yet issued, not yet charged". `cancelChallengeReveal()` exists and is simply not called from either reset. | `shop.html:1467-1500` and `1801`; `staff.html:1258-1278` and `1412` |
| A7 | **MED** | **Two different definitions of "Qualified this month" in one portal.** My Statement reads `row.is_active`; My Volume and the office boards compute `sv >= 100`. Two sources of truth for the same pill. If the view's flag and the threshold ever disagree, two tabs contradict each other and nothing says which is right. | `site/js/app.js:1147` vs `997`, `220`, `430` |
| A8 | **MED** | **An unknown product code silently shows a different product.** `var product = (sku && O.get(sku)) \|\| O.PRODUCTS[0];` A typo or a stale link renders the Payment Agent under someone else's address, with its price and its PV, and no not-found state. | `www/product.html:235` |
| A9 | **MED** | **Both session gates paint the protected page first.** The gate scripts sit at the end of the document, so the whole staff console and the whole member portal render before `location.replace`. The comments claim the gate "Runs before anything else on this page". The database half of that claim is true; the rendering half is not, and a visitor sees the shell of a page they are about to be thrown out of. | `site/index.html:70-101` (comment `62-63`); `www/staff.html:291-322` (comment `292-294`) |
| A10 | **MED-LOW** | **Server strings enter innerHTML unescaped, in the shop only.** `staff.html` and `site/js/app.js` both carry an `esc()`; `shop.html` carries none. Today the values come from our own Edge Functions, so it is latent rather than open, but it is the one surface of three without the habit. | `shop.html:2313-2321` (`order_number`, `payment_status`), `2259-2260` (`it.sku`), `2299` |
| A11 | **LOW** | **Support chat race.** If the Botpress widget loads later than the twenty-second poll window, the readiness listener is never attached and a queued Support click never opens. Six identical copies of the bug. | `shop.html:2604-2615` and five siblings |

---

## B. Duplication: what was copied, and where it will drift

### B1. staff.html carries a near-verbatim copy of the shop's whole 3DS and resume layer

Twenty-five function names appear in both files. Twenty are 95 to 100 percent identical.
About 224 lines of `shop.html` are reproduced in `staff.html`.

| Copied verbatim (95-100%) | shop.html | staff.html |
|---|---|---|
| `authOf`, `reasonOf`, `transStatus` | 2071-2076 | 1582-1584 |
| `authApproved`, `authRefused`, `authBroke`, `awaitingAuthentication` | 2079-2107 | 1586-1608 |
| `nextPollDelay` + `PROCESSOR_WAIT_MS` + `AUTH_WAIT_MS` | 2176-2186 | 1633-1643 |
| `setChallengeFrameVisible`, `cancelChallengeReveal`, `CHALLENGE_REVEAL_MS`, the MutationObserver block | 1792-1829 | 1403-1437 |
| `challengeKeydown` | 1750-1765 | 1379-1391 |
| `canonicalReturnUrl` | 1422-1428 | 1219-1225 |
| `parseStore`, `resumeRead`, `resumeClear`, `RESUME_MAX_AGE_MS` | 1389-1415 | 1191-1215 |
| `round2`, `taxExempt`, the order-number regular expression | 1146, 1142, 1430 | 367, 814, 1150 |

**Genuinely diverged, and correctly so:** `openChallengeChrome` / `closeChallengeChrome`
(staff adds the waiting panel, the shop adds the finishing state), `resumeSave` (the shop
carries `total_cents`), `orderMath` (the shop has an activation fee), `renderMeter` (PV against
SV), `orderNumber` (different return shape), and the whole outcome-message wording, which is
deliberately written for two different readers. That divergence is good work and should stay.

**Where the copies will drift apart, in the order it will happen:**

1. **They already have, twice, both times in the shop's favour.** The *finishing state*
   (`shop.html:1527-1535`, applied at `2056`) exists only in the shop. ROADMAP.md, same round,
   says: "the card form used to reappear for a second between the approval finishing and the
   receipt. The finishing state now starts the moment the card is handed over" and then
   "APPLIED TO BOTH SURFACES". Only the reveal delay was applied to both. `staff.html` still
   leaves the mounted card form on screen through the settle window. The document is now
   wrong about the code. Second instance: the amount signature (A3).
2. **`CHALLENGE_REVEAL_MS` is 1400 in two files.** ROADMAP's "KNOWN AND ACCEPTED" section
   already names the two ways to finish the frictionless flash properly: raise that number, or
   poll for `requires_customer_action`. Whoever does it will change one file.
3. **The test-card hint is prose in two places** (`shop.html:1985-1990`,
   `staff.html:1512-1515`) and has already been corrected twice in a single day. The next
   processor change corrects it once.
4. **`nextPollDelay` and the two wait constants are the timing contract with the server.**
   Any change is a two-file change with nothing to notice a miss.
5. **`ORDER_NUMBER_RE` / `STAFF_ORDER_RE` are the same regular expression under two names.**
   A change to the order-number format breaks whichever file is forgotten, silently, in a
   recovery path that only runs when something has already gone wrong.

**Shape of the fix:** one `www/js/payments.js`, loaded by both pages next to `catalog.js`,
exporting the receipt readers, the poll schedule, the resume store and the challenge chrome
controller, parameterised by the few things that genuinely differ (the storage key, the
channel, the status writer, the wording table). The two pages keep their own copy, correctly,
and the shared 224 lines stop being two.

### B2. Six byte-identical copies of the Botpress trigger

The 35-line block plus its 5-line comment plus the two vendor script tags are md5-identical
across `www/index.html`, `www/shop.html`, `www/staff.html`, `www/team.html`,
`www/product.html` and `site/index.html`. `www/login.html` has neither the script nor a
Support item, which is a seventh, silent variant nobody decided on.

### B3. Portal and console utilities duplicated

`esc`, `fetchAll`, `periodLong` and the month-name array exist twice: `www/staff.html:361-379`
and `site/js/app.js:53-110`. `fetchAll` is recursive in one file and a loop in the other.
The **session gate** duplication is a different case: `staff.html:295-298` explains that the
deploy script moves the two folders apart and a shared file would need a fragile path. That
reasoning is sound and the duplication should stay. The four utilities above are not covered
by it.

### B4. Small copies

`renderBadge` (`shop.html:844-846` / `product.html:321-323`) and the add-to-cart animation
(`shop.html:681-690` / `product.html:334-345`), including the magic `220` and `1100`
millisecond values in both.

---

## C. Dead and vestigial code

| # | Finding | Where |
|---|---------|-------|
| C1 | **The whole fake checkout in the shop.** `LIVE_PAYMENTS` is `const true`. Unreachable: `demoPlaceOrder` (44 lines), `orderNumber`, the `else` branch that hides the 3DS notice and the lookup, and every `LIVE_PAYMENTS ? … : …` ternary. The `#cardFields` markup and its four inputs were **hidden** today rather than removed, which is the leftover Howard named. | `shop.html:1069`, `1241-1253`, `1263-1306`, `2335-2341`, `253-268`, `1121`, `1495-1499` |
| C2 | **The same fake checkout in the console.** `LIVE_PAYMENTS` `const true`: the demo branch of `placeOrder`, `orderNumber`, `#newCardFields` and its four inputs, which `backToOrder` and `newCall` still dutifully clear line by line, and the `if (!LIVE_PAYMENTS)` branch. | `staff.html:885`, `1040-1049`, `1060-1064`, `170-175`, `1748-1751`, `1769-1772`, `955-957` |
| C3 | **The payment-link path, half-built.** `PAYMENT_LINK_READY` is `const false`. `createLinkBtn`'s handler is `function () { if (!PAYMENT_LINK_READY) return; }` — an empty function. `copyLinkBtn` can never have anything to copy because `linkField` is never written. Keeping the panel visible with an honest "not available" note is a good product call; keeping two live click handlers that provably do nothing is not. | `staff.html:904`, `966-968`, `970-982`, `160-168` |
| C4 | **`allMet` computed and thrown away.** `buildReqList` builds a boolean by running a regular expression over its own generated HTML, and neither caller reads it. | `site/js/app.js:1086`, callers at `1123`, `1127` |
| C5 | **Selected-but-unused database columns.** `staff.html` asks `v_demo_member_months` for `cv` and `is_active`; neither is read. | `staff.html:573` vs `583-595` |
| C6 | **Unused parameter.** `livePollReceipt(attempt, startedAt)` never reads `attempt`; all four call sites pass `0`. | `shop.html:2188`, called from `1839`, `2057`, `2234` |
| C7 | **Dead CSS rule.** `.latin { font-style: normal; }` — nothing carries the class. Leftover from the Latin-filler prose round. | `www/css/corporate.css:116` |
| C8 | **Dead CSS class in markup.** `sk-line-full` has no rule anywhere. | `www/shop.html:283` |
| C9 | **Test hook on the public page.** `window.OrvannaHero = { isRunning, start, stop, drawStatic }`. | `www/index.html:665` |
| C10 | **Three layers for one behaviour.** `shop.css:745-750` zeroes transitions under reduced motion; `corporate.css:1109-1114` already applies `* { transition: none !important; animation: none !important; }` and loads first; and the JavaScript checks `reduce.matches` as well. The block's own comment admits the first of the three. | `www/css/shop.css:739-750`, `corporate.css:1109`, `shop.html:683` |
| C11 | **A global reset filed under a feature banner.** `[hidden] { display: none !important; }` sits inside a section headed "ROUND 4 (Phase 4C.2)". | `www/css/shop.css:752-758` |

---

## D. Comments

The comment culture here is the best thing in the codebase. Comments explain *why*, they name
the person who found the bug and the date, and they record what was tried and rejected. The
z-index note (`shop.css:1512-1523`), the blank-window note (`shop.html:1767-1791`) and the
amount-signature note (`shop.html:1537-1564`) are exemplary and should be left exactly as they
are. Only the following are wrong.

**D1. Contradicted by the code beside them.**

- `shop.html:891-898` and `1206-1210`: both guard with `typeof liveEnsureCheckout === 'function'`
  and both comments frame it as protection against setup order. `liveEnsureCheckout` is a
  function declaration in the same closure (`1577`), so it is hoisted and the test is always
  true. The guard is theatre.
- `shop.html:1579-1581`: "a future call during page setup would land here before `liveState`
  exists." `liveState` is a hoisted `var`; the half of the check that actually does the work is
  `!liveState`, not the `typeof`.
- `site/index.html:62-63` and `staff.html:292-294`: "Runs before anything else on this page."
  It runs after the whole document (A9). The narrower claim in the same sentence, that no
  database call is triggered, is true and worth keeping.
- `staff.html:1301`: `if (!on) applyLiveModeDefaults();` inside `setOrderInert`. Re-running the
  defaults as a side effect of un-disabling controls silently resets the payment-choice radio
  the agent may have just changed. No comment says why it is there.

**D2. Restating the code.**

- `shop.html:1620-1623`: two consecutive comments saying the same thing, one line apart.
- `shop.html:1465-1466`: "clear any in-flight payment" above a function named
  `liveResetPayment`.
- `www/js/catalog.js:405`: "migrate round-3 keys (bare sku) to sku|sub" repeats the file
  header at lines 16-18.

**D3. Stale fact.** The overview tile still reads "12 Specialist AI agents" against a catalog
of 16 purchasable items. Already on Howard's open list in ROADMAP; still on the page.
`www/index.html:57-58` vs `www/js/catalog.js:43-123`.

---

## E. Naming and consistency

| # | Finding | Where |
|---|---------|-------|
| E1 | **A role name that lies.** The **member** portal signs in as role `admin`; the console as `staff`; the shop checkout demands `member`. Three surfaces, three names, and the one called "admin" is the member portal. | `www/login.html:76-81`, `site/index.html:74, 88`, `shop.html:990` |
| E2 | **Two dialects.** `site/js/app.js` is `const`/`let` with double quotes; every `www` script is `var` with single quotes. A single `const LIVE_PAYMENTS` sits among two hundred `var`s in `shop.html:1069`, and that is the one place the difference can bite: a future top-level call above that line gets a hard ReferenceError rather than `undefined`. | `site/js/app.js` vs `www/*.html` |
| E3 | **Prefix soup.** `gate-`, `mom-`, `sl-`, `st-`, `cc-`, `lp-`, `ar-`, `aa-`, `v-`, `t-`, `p-`, `li-`, `mk`, `fig`. Each is locally sensible; there is no register saying what any of them stand for, and `st-` means "stat" in one file and "stop" in another. | `portal.css`, `staff.css`, `shop.css` |
| E4 | **One name, two contracts.** `renderMeter(prefix, pv)` in the shop takes a DOM id prefix and PV; `renderMeter(orderPv)` in the console takes PV and reads the caller's SV from closure. | `shop.html:779` vs `staff.html:842` |
| E5 | `state_` with a trailing underscore, to dodge the module-level `state`. Rename the local. | `site/js/app.js:698` |

**CSS holds up well.** No dead classes beyond C7 and C8. Every duplicated selector is a
deliberate media-query override. `min-width: 0` is applied on every grid track that needs it
(`staff.css:154-156`, `shop.css` throughout), wide content is wrapped in `overflow-x: auto`
(`#orderLinesWrap`, `.table-scroll`, `.tree-scroll`), and reduced motion is honoured on all
four sheets. At 375 pixels the layouts reflow rather than scroll, including the deliberate
"six months become six rows" swap at `portal.css:857`. Two small notes: `portal.css` has two
separate `@media (max-width: 720px)` blocks (886 and 914) that should be one, and
`staff.html:190` carries two full inline `style` declarations on a pair of `<kbd>` elements
that belong in `staff.css`.

---

## F. build_dist.py

**Credit first.** It refuses to delete a `dist` it did not build (`113-115`). It fails loudly
when an expected link is missing rather than silently skipping (`86-88`). It scans the output
for leftover `../site/` and `../www/` references (`140-148`). It resolves every relative `href`
and `src` in every page (`91-104`). That is more discipline than most static deploys have, and
the honesty question in the brief mostly answers itself: yes.

| # | Sev | Finding | Where |
|---|-----|---------|-------|
| F1 | **MED** | **The link check is case-insensitive on Windows and the host is not.** `resolved.exists()` passes for `assets/Logo.svg` against a real `assets/logo.svg` on this machine, and 404s on GitHub Pages. Compare the resolved name against the actual directory entry. | `build_dist.py:100-103` |
| F2 | **MED** | **No allowlist: the build copies whole trees.** Anything that lands in `www/` or `site/` ships to a public repository — an editor backup, a note, a screenshot, a key file. The root `.gitignore` protects the *source* repository (`HyperSwitch/`), not this copy. Nothing today leaks (see F8), but the only thing between a private file and the public repo is habit. Add a deny list (`*.md`, `*.bak`, `*~`, `.env*`, `*.key`, `*.pem`, unexpected dotfiles) and print the file manifest. | `build_dist.py:127-128` |
| F3 | **MED** | **The build rewrites a JavaScript string constant by blind text replacement.** The `login.html` rule targets `../site/index.html`, which in that file is `DOORS.admin.next` in code, not an `href`. It works, and the `next` allowlist at `login.html:97-100` still compares correctly afterwards, but the code in the repository is not the code that ships, and the guard that would catch a bad rewrite tests for *absence*, not for meaning. | `build_dist.py:24`, hitting `www/login.html:80` |
| F4 | **MED** | **Nothing stamps the cache-buster.** The build already computes a sha256 of every file and prints a bundle digest that is used for nothing. Stamping `?v=<short file hash>` into the HTML at build time would have prevented A1 outright, at a cost of roughly eight lines, and would end the manual step that has now been missed once. | `build_dist.py:156-160` |
| F5 | **LOW** | **"Reproducible" is printed, never checked.** The digest goes to stdout and nowhere else. Write it to `dist/BUILD.txt` (public and harmless) so a later run can compare and the claim becomes testable. | `build_dist.py:160-161` |
| F6 | **LOW** | 35 lines of HTML and prose embedded as Python string literals. They belong in `deploy/templates/`. | `build_dist.py:37-72` |
| F7 | **LOW** | `link_check() -> list` with no element type, in a file that otherwise annotates everything. | `build_dist.py:91` |
| F8 | — | **Leak check: clean.** The only credentials in the shipped output are the Supabase anonymous key (six copies: `shop.html:1077`, `staff.html:333` and `889`, `login.html:73`, `site/js/app.js:11`) and the HyperSwitch publishable key, both public by design, plus the demonstration password printed on the checkout panel deliberately and explained at `shop.html:138-147`. `www/assets/hk.jpg` is Howard's own photo, deliberate per the team-page ruling. No private paths, no `localhost`, no service-role key, no secret. | — |

---

## What I would delete outright

Fourteen items. Nothing here is load-bearing; every one is verified unreachable or unused.

**The superseded fake checkout (both surfaces).** `LIVE_PAYMENTS` is `const true` in both
files and has been since Phase 6 closed. Delete the flag along with the code, rather than
keeping a switch nobody can throw:

1. `shop.html:1263-1306` — `demoPlaceOrder`, 44 lines, unreachable.
2. `shop.html:1241-1253` — `orderNumber`, only ever called by the above.
3. `shop.html:253-268` — the `#cardFields` markup and its four inputs. These are the ones that
   were *hidden* today rather than removed. With them go `cardFields` (`1104`), the
   `cardFields.hidden` lines at `1121`, `1495`, `1959`, and the `walletNote` pairing.
4. `shop.html:2335-2341` — the `else` branch that hides the 3DS notice and the lookup link.
5. `staff.html:1060-1064` — the demo branch of `placeOrder`, and `orderNumber` at `1040-1049`.
6. `staff.html:170-175` — `#newCardFields` and its four inputs, plus the eight lines in
   `backToOrder` (`1748-1751`) and `newCall` (`1769-1772`) that clear fields nobody can see.
7. `staff.html:955-957` — the `if (!LIVE_PAYMENTS)` lookup-hiding branch.

**Handlers that provably do nothing.**

8. `staff.html:966-968` — `createLinkBtn`'s click handler is `if (!PAYMENT_LINK_READY) return;`
   and nothing else. Delete the handler; the disabled button and its honest note stay.
9. `staff.html:970-982` — `copyLinkBtn`'s handler. `linkField` is never written, so there is
   never anything to copy.
10. `staff.html:1290` — the strings `.line-qty, .line-drop` from the inert selector. Delete
    them and add the two that actually exist, `.qty-step` and `.line-remove-btn` (this one is
    a fix as well as a deletion; see A4).

**Computed and discarded.**

11. `site/js/app.js:1086` — the `allMet` line, and the `allMet` key from the returned object.
    No caller reads it, and it works by running a regular expression over generated HTML.
12. `shop.html:2188` — the `attempt` parameter and the `0` at all four call sites.
13. `staff.html:573` — `cv,` and `is_active,` from the column list. Neither is read.

**Dead style.**

14. `www/css/corporate.css:116` (`.latin`), `www/shop.html:283` (`sk-line-full`),
    `www/css/shop.css:745-750` (the reduced-motion block that `corporate.css:1109` already
    covers with `!important`), and `www/index.html:665` (`window.OrvannaHero`, a test hook on
    a public page).

---

## Suggested order of work

1. **A1** — bump the stamp to `?v=5.4` across `www/`, then implement **F4** so it can never
   be missed again. Ten minutes, and it is the difference between today's z-index fix
   reaching a returning visitor or not.
2. **A3 + A4** together — port the amount signature to the console and fix the two phantom
   selectors. This is the one finding that can make a call agent read a wrong number aloud.
3. **A2** — one `.catch` per chain, each writing the order number and "nothing was charged".
4. **A5, A6** — two small fixes, ten lines total.
5. **B1** — extract `www/js/payments.js`. Do this before the next 3DS change, not after.
6. The deletion list above, in one commit, with the two ROADMAP claims corrected in the same
   commit so the document stops being ahead of the code.
