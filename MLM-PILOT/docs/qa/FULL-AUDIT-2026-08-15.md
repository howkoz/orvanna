# Full Quality Assurance Audit, every surface

> Run 2026-08-15 by mlm-qa. Plain path:
> `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\FULL-AUDIT-2026-08-15.md`
> Scope: everything shipped on 2026-08-15 went to production with no gate, so the
> whole property is treated as unreviewed.

## Verdict: FAIL

Two HIGH defects. The build is a long way from sloppy: 9,700 elements were measured
for computed contrast and 9,690 of them pass, the compliance sweep is clean, and the
checkout changes Howard asked about are real and correct. The failure is two colour
decisions and a set of stale copy lines that now say things the product no longer does.

Acronym key: Personal Volume (PV), Sales Volume (SV), Team Volume (TV), 3-D Secure
(3DS), Web Content Accessibility Guidelines (WCAG), Strong Customer Authentication
(SCA), Software Development Kit (SDK), Application Programming Interface (API).

---

## How contrast was measured

Never by eye. A harness walked every element carrying a text node on the live site,
read `getComputedStyle`, and composited the full ancestor stack: every `background-color`
alpha, every gradient stop of every `background-image` (the glass panels are gradients,
so ignoring them would have overstated every ratio by about 1.1), and cumulative
element `opacity` applied to both text and backdrop. Gradient-clipped text
(`background-clip: text`) is scored on its worst stop. Large text is 24px, or 18.66px
at weight 700 or more.

The live site was first proved byte-identical to `deploy/dist` after line-ending
normalisation for all 13 shipped files, so auditing the live rail audits this source.

### Totals

| Surface | Elements scanned | Failures | Worst passing ratio |
|---|---|---|---|
| `www/index.html` | 74 | 0 | 5.61:1 |
| `www/team.html` | 98 | 0 | 5.61:1 |
| `www/login.html` | 8 | 0 | 5.61:1 |
| `www/product.html` | 50 | 0 | 5.61:1 |
| `www/shop.html`, all views plus bank-approval chrome | 286 | 0 | 5.61:1 |
| `www/shop.html` at 375 pixels | 110 | 0 | 5.61:1 |
| `www/staff.html`, all panels forced open | 108 | **3** | 5.68:1 |
| `site/` portal, dark, all five tabs | 4,568 | 0 | 4.90:1 |
| `site/` portal, light, all panels | 4,569 | **5** | 5.36:1 |

---

## Findings

### HIGH

**H1. Shop primary buttons are unreadable while disabled: 1.70:1.**
`www/css/shop.css:584` sets `.btn:disabled { opacity: 0.45 }`. Because the shop's
solid button is dark ink on cyan, dropping both layers to 45 percent collapses the
pair together.

- Declared `color: rgb(5,18,28)` on `background: rgb(34,211,238)`.
- At `opacity: 0.45` over the navy field, text composites to `rgb(12,64,79)` on a
  backdrop of `rgb(19,101,120)`.
- **Computed 1.70:1**, against 4.5:1 required. Enabled, the same button is 10.47:1.

This is not a theoretical state. Both were reproduced on the live site:
- `#checkoutButton` in the cart drawer with an empty cart: `disabled`, `opacity 0.45`,
  visible at 381x49, label "Checkout".
- `#placeOrderBtn` during every payment open, roughly two seconds each time. Recorded
  timeline while switching to priority activation: `Pay $105.00 now, test mode` →
  `Continue to card details`, `disabled`, `opacity 0.45`, status "Contacting the test
  payment service..." → `Pay $131.25 now, test mode`.

Per the standing lesson of 2026-08-14, a button whose text cannot be read is HIGH even
when the handler works. WCAG 1.4.3 does exempt inactive components; 1.70:1 is well past
where that exemption is a defensible answer.

**H2. Portal light theme: the qualification signal fails, five instances.**
`site/css/portal.css:53` restates `--cyan` for the light theme with the arithmetic
written out in a comment. `--good: #059669` (line 54) got no such treatment, and it
carries the single most important status in the member office.

Measured on the live portal with `data-theme="light"`:

| Element | Text colour | Composited backdrop | Ratio | Needs |
|---|---|---|---|---|
| `.qual-pill.qual-yes` "QUALIFIED", 12px w700 | `#059669` | `rgb(221,245,238)` = `rgba(52,211,153,0.14)` over `.stat-card` | **3.28:1** | 4.5:1 |
| `.qual-pill.qual-no` "NOT QUALIFIED", 12px w700 | `#DC2626` | `rgb(248,234,235)` = `rgba(248,113,113,0.12)` over `.stat-card` | **4.12:1** | 4.5:1 |
| `.req-item.req-met .req-icon` check mark, 16px w700 | `#059669` | `rgb(248,250,252)` | **3.60:1** | 4.5:1 |

Rules at `site/css/portal.css:300-301`. The QUALIFIED pill appears on My Volume and My
Statement; the check marks appear three times on My Rank. The dark theme passes all of
them. `.qual-no` had to be synthesised because the demonstration member is qualified,
but it is the same rule pair and fails whenever a member is not.

### MEDIUM

**M1. `www/shop.html:306` tells the shopper any card will do.**
`<p class="login-note">Demonstration checkout: any values continue, including empty
fields.</p>` renders directly beneath the real "Pay $210.00 now, test mode" button.
Under `LIVE_PAYMENTS = true` it is false: the provider's form rejects an empty or
invalid card, and `liveAfterSdk` has a whole branch for exactly that. Leftover from the
round-4 fake checkout, as the copied `login-note` class shows.

**M2. `www/shop.html:214` promises express checkout that cannot happen.**
"Express options place the order in one step." All three express buttons are
`disabled` at `www/shop.html:2328-2334`. Pressing them does nothing.

**M3. The disabled express buttons look identical to the working one.**
Measured on the live page: Apple Pay, Google Pay and PayPal are all `disabled: true`
with `effOpacity: 1`, `cursor: pointer`, no `aria-disabled`, and contrast of 19.27:1,
14.03:1 and 10.93:1 against the enabled Credit card button's 14.20:1. There is no
`.pay-btn:disabled` rule anywhere in `www/css/shop.css`. The only signal is a `title`
tooltip, which never appears on a phone. A shopper taps Apple Pay and gets silence.

**M4. `www/staff.html:149` contradicts the same page twice.**
"Key the card here, telephone order ... No bank approval is possible on this path."
That is absolute and wrong. The same page ships a full bank-approval overlay
(`challengeChrome`, line 270; `openChallengeChrome`, line 1337; `CHALLENGE_REVEAL_MS`,
line 1404) and an `awaitAuth` panel (line 182) whose entire text explains what to do
when a bank asks the cardholder to approve. Line 138 on the same screen says telephone
orders sit outside SCA so the bank "usually will not ask", which is the honest version.
An agent on a live call who read line 149 and then watched an approval window open has
been told something false by the console.

**M5. The finishing state was never applied to the staff console.**
`ROADMAP.md` records that the card-form-reappearing fix was "APPLIED TO BOTH SURFACES
per the QA rule that scope follows capability, not the brief." Only half of it was.
- Shop: `liveAfterSdk` calls `liveSetFinishing(true)` (`www/shop.html:2095`) the moment
  the card is handed over, hiding `#hyperswitchMount` and the button; cleared on every
  ending including the timeout branch at line 2283.
- Staff: `staffAfterSdk` (`www/staff.html:1558-1571`) goes straight to
  `staffPollReceipt`. There is no finishing state on the page at all; grep for
  `SetFinishing` in `www/staff.html` returns nothing. `#hsStaffMount` stays mounted and
  visible for the whole wait, and the button stays visible and merely disabled.

So the exact behaviour Howard reported ("it stops for a second back at the card entry
and then finishes at the complete page") is still live on the staff console. The
challenge-reveal half of the same round was correctly applied to both.

**M6. A keyboard user cannot reach the bank's passcode field.**
`challengeKeydown` (`www/shop.html:1750-1765`) builds its tab ring as
`stops = [ccCancel, frame]` where `frame` is `document.getElementById('orca-fullscreen')`.
That element is a `<div>` with no `tabindex`, so `.focus()` on it is a no-op.

Proven on the live page by injecting an element with the SDK's exact id and inline
style, the same technique the builder used:
- Tab from `ccCancel` → focus stays on `ccCancel`. Tab again → still `ccCancel`.
- Add `tabindex="-1"` to the same div → Tab moves to `orca-fullscreen`.

Everything else about the dialog is textbook and was verified working: `role="dialog"`,
`aria-modal="true"`, `aria-labelledby="ccTitle"`, focus moved to the cancel button on
open, Escape suppressed (`defaultPrevented` true), and all nine background controls
genuinely `disabled` rather than dimmed.

**M7. Staff primary buttons fail while disabled.**
`.btn-place:disabled` and `.btn-addline:disabled` use `opacity: 0.45`
(`www/css/staff.css:511, 737`). White on indigo `#4F46E5`:

| Button | Disabled | Enabled |
|---|---|---|
| `#placeOrderBtn` "Place order for the caller" | **3.84:1** on `rgb(39,38,116)` | 6.29:1 |
| `#createLinkBtn` "Create a payment link" | **3.72:1** on `rgb(40,43,122)` | 6.29:1 |
| `#copyLinkBtn` "Copy" | **3.72:1** on `rgb(40,43,122)` | 6.29:1 |

Less severe than H1, but `#createLinkBtn` is permanently disabled
(`PAYMENT_LINK_READY = false`), so 3.72:1 is the shipped, permanent state of the path
the console itself calls "recommended". `#placeOrderBtn` is disabled on arrival, before
a caller is looked up.

**M8. `www/shop.html:390` is stale on every receipt.**
"Payments route through the Orvanna orchestration layer in a later phase." They route
through it now. `#confirmDemoNote` beside it is correctly rewritten in live mode
(`www/shop.html:2303`); this line never is.

### LOW

| # | Finding | Location |
|---|---|---|
| L1 | "PV" used at character 706 before "Personal Volume" at 770. Confirmed rendered: "100 PV" precedes the expansion. The ROADMAP-queued touch-up is still open. | `www/product.html:80` vs `:84` |
| L2 | "ZIP" is never expanded. | `www/shop.html` billing address |
| L3 | An unknown `?sku=` silently renders a different product. `?sku=manager-agent` returned "Payment Agent | Orvanna Shop", so the address bar and the page disagree. | `www/product.html:235` |
| L4 | "Sign in to use your saved billing address" overclaims: the code fills a synthetic address on purpose (`www/shop.html:998-1006`). Only the name is the member's. | shop step 1 |
| L5 | Field borders `rgba(129,140,248,0.3)` composite to **1.60:1**, against the 3:1 that WCAG 1.4.11 asks for a control boundary. The border is the only thing marking the input. | `corporate.css` `.field` |
| L6 | At 375 pixels several controls fall under the 24x24 of WCAG 2.5.8: nav links 23px tall, Support 18px, Sign In 20px, Back to the catalog 21px, Switch 21px. The delivery radios are 16x16 but sit inside 293x122 labels, so those are fine. | nav and checkout |
| L7 | UTF-8 byte order mark at the start of the file. | `www/js/catalog.js:1` |
| L8 | `closeChallengeChrome` only replaces the status line `if (liveState.busy)`. If a challenge ever closes with `busy` false, "Your bank is asking you to approve this payment" stays on screen. Not reachable in the current flow. | `www/shop.html:1720` |

### Could not verify in this environment

The Browser pane never composited frames in this session (`document.visibilityState`
stayed `hidden`, screenshots timed out), so **the card form being visually present on
arrival at the payment step could not be confirmed**. Structurally everything is right:
the payment auto-opens behind the account step, `#hyperswitchMount` holds one live
iframe from `beta.hyperswitch.io`, the order chip shows `ORV-2026-08-1F58V0`, and the
button relabels to "Pay $105.00 now, test mode". But the SDK iframe measured
`height: 0px` throughout, which is the expected consequence of a throttled hidden page
and cannot be told apart from a real defect without a displayed browser. Per the
charter this row is unproven rather than passed. It needs one look by Howard or a run
in a visible browser.

---

## What was checked and is genuinely right

**The 2026-08-15 checkout changes, as a user.**

- *One card entry.* `#cardFields` is hidden whenever `LIVE_PAYMENTS` is true
  (`www/shop.html:1121`), verified `hidden: true` on the live page. The same fix is on
  the staff console (`www/staff.html:914`).
- *Card form present on arrival.* The payment opens behind the account step, not in
  front of the shopper: measured `payStepVisible: 0x0` while the iframe mounted and the
  button had already relabelled with the total.
- *No card form between approval and receipt.* Correct on the shop, absent on staff, see M5.
- *Amount signature.* Proven live. Cart at $105.00, switched to priority activation,
  old payment discarded, new one opened at $131.25. That is $100.00 + $25.00 = $125.00
  taxable, 5 percent = $6.25, total $131.25, correct to the cent.
- *Bank approval chrome wins the stacking contest.* Injected the SDK's frame with its
  real `z-index: 422222133323` (clamped to 2147483647). Our chrome resolves to the same
  2147483647 and is last in `<body>`, and `document.elementFromPoint` at the centre of
  the bar returns `ccTitle`, not `orca-fullscreen`. Chrome text runs 10.31:1 to 18.63:1.
- *A blank window is not a challenge.* Drove both timelines. Frictionless: frame present
  at +200ms with `opacity 0` and no chrome, removed at +700ms, chrome still hidden at
  +2000ms, shopper sees nothing. Challenge: frame still present past
  `CHALLENGE_REVEAL_MS`, opacity restored, chrome shown.
- *375 pixels.* No horizontal scroll (`scrollWidth` 375 = `clientWidth`). Summary stacks
  to one column, pay button 293x73, method buttons wrap two-up at 141x43. The only
  elements outside the viewport are the closed off-canvas drawer. Contrast at 375:
  110 elements, zero failures.

**House rules.**

- Zero em dashes and zero en dashes anywhere in `www/` or `site/`. A full code-point
  census found only middle dots, curly quotes, an ellipsis, a multiplication sign and
  one byte order mark.
- Money always two decimals, through one formatter, `fmtMoney` at
  `www/js/catalog.js:380` with `minimumFractionDigits: 2`. The portal uses the same
  shape at `site/js/app.js:59`. Every hardcoded amount in markup is two decimals.
- Acronyms expanded on first use on `index.html`, `team.html`, `staff.html`,
  `login.html` and the portal. Two exceptions, L1 and L2.
- External dependencies: exactly the three sanctioned ones. Every absolute URL in every
  shipped file resolves to `cdn.botpress.cloud` / `files.bpcontent.cloud`,
  `beta.hyperswitch.io/v1/HyperLoader.js`, or the Supabase project. Nothing else. The
  Botpress floating button is genuinely suppressed (`.bpFab { display: none !important }`
  confirmed in the live stylesheet) and the nav trigger is wired on all six surfaces.

**Direct-selling compliance.** Clean on every surface, source and rendered. Pattern
sweeps for income claims, earnings projections, fabricated social proof, instructions to
members, and cost framing returned nothing on `index`, `shop`, `staff`, `team`,
`product`, `login` and the portal. The downline rows are observations, not instructions
and not blame: "0.00 SV, 100.00 under, Leg not counted, Frontline leg, not active this
month." No member is ever shown what an unqualified downline person cost them.

**Honesty of the sign-in.** The thing that changed today is genuinely real.
`demo-login` compares against bcrypt hashes the public key cannot read
(`www/shop.html:932-1026`), the server decides every failure message so the page cannot
leak whether a code exists, the role is checked, and the copy says exactly this:
"Checked against the database, not this page." `www/login.html` matches. The one
overclaim is L4.

**Build pipeline.** `deploy/build_dist.py` rewrites the six cross-folder links, then
refuses to finish if any `../site/` or `../www/` reference survives or if any relative
link fails to resolve. Working tree clean, live bytes match.

---

## Scope follows capability: what the sweep turned up

Sweeping every surface that presents a capability rather than only the one the brief
named produced four of the eight MEDIUM findings.

| Capability | Shop | Staff | Portal | Verdict |
|---|---|---|---|---|
| One card entry under live payments | fixed | fixed | n/a | consistent |
| Challenge reveal delay, blank frame suppressed | fixed | fixed | n/a | consistent |
| Finishing state between card submit and receipt | fixed | **absent** | n/a | **M5, ROADMAP claims both** |
| Framing of what the checkout is | "any values continue" | "live TEST rail, test cards only, play money" | n/a | **M1, surfaces contradict** |
| Whether a bank approval can occur | "a window from your bank opens right here" | "No bank approval is possible on this path" | n/a | **M4, direct contradiction** |
| Disabled state of a primary button | 1.70:1, no `:disabled` rule for `.pay-btn` | 3.72 to 3.84:1 | n/a | **H1, M3, M7** |
| Status colour token in both themes | n/a | n/a | dark fine, light fails | **H2** |
| Sign-in honesty | real, honest, one overclaim | real, honest | real | near-consistent |

The staff console is the more honest document of the two on framing, and the shop is
the more complete on flow. Each one has what the other is missing.

---

## Recommended order of repair

1. H1: give the shop a real disabled treatment instead of `opacity: 0.45` on a
   light-on-dark pair. A darker cyan with the ink text kept opaque holds contrast.
2. H2: restate `--good` for the light theme the way `--cyan` already was, and check the
   result against the tinted pill background, not against white.
3. M1, M2, M8: delete or rewrite the three stale lines.
4. M5: port `liveSetFinishing` to the staff console, and correct the ROADMAP claim.
5. M4: change "No bank approval is possible on this path" to match line 138's "usually
   will not ask", which is what the code actually assumes.
6. M3, M7: a visible disabled state, `aria-disabled`, and `cursor: default`.
7. M6: set `tabindex="-1"` on the frame before focusing it.
8. The LOW list at leisure.

Nothing here is structural. The architecture, the server-side pricing mirror, the
amount signature, the resume path and the focus handling are all better than the bar
this audit was asked to hold them to.
