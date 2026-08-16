# Verification Verdict: the guest tax state picker, pre-deploy delta gate

Verifier: mlm-verifier, run 2026-08-16, on commit 651ac49 (not deployed). This
verdict gates the deploy of the site AND the three function files
(`functions\_shared\tax.ts`, `functions\quote-tax\index.ts`,
`functions\create-payment\index.ts`). Instruments: repository reads, diff
traces, and command-line probes of the live rail; the Browser pane belonged to
the quality assurance agent. Per charter: I grade, I fix nothing.

## GATE: PASS. Deploy YES from the verifier's half, with one ordering note.

One MEDIUM finding, recorded at the coordinator's instruction and awaiting the
owner's ruling; it is pre-existing in mechanism and does not block this gate.
Two LOW observations. The core design holds everywhere I probed it: one
implementation, one normalization point, the code inside the amount signature,
and no path by which the browser can hand Stripe an address.

THE ORDERING NOTE: deploy the three function files BEFORE or TOGETHER WITH the
site. If the site ships first, the deployed functions ignore the unknown
`guest_state` field, so the picker visibly does nothing: the estimate label
names the picked state and the quote then answers for Illinois, which is a
transient version of the exact label-versus-figure disagreement this feature
exists to end.

## Findings

### MEDIUM

**P-M1 (recorded, awaiting the owner's ruling; does not block this gate).
The referral-code precedence can quietly override the picked state.** A guest
who picks a state AND types a referring member's code is priced from the
REFERRER's stored address; the picked state is ignored (`resolveTaxAddress`:
any attached member wins). This is the pre-existing rule, unchanged in
mechanics, now documented in the resolver's precedence comment, and it is
symmetric between quote and charge, so no wrong-amount path exists. What the
picker adds is the EXPECTATION: the page now invites a pick ("Pick a state
and the tax engine prices this order for that state") and the estimate label
names the picked state, both of which the typed referral code silently
falsifies until the server's quote answer repaints the label with the real
jurisdiction. Not newly worsened in behavior, newly visible in consequence.
Until the ruling lands, a cheap softener would be annotating or disabling the
picker while the member-code field is non-empty; that is the owner's call.

### LOW

**P-L1.** The pre-existing `onTotalsApplied` hook updates the pay button when
`clientSecret` is set and the button visible, without the `checkOnly` and
`busy` guards the new `syncPayButtonToDisplayedTotal` carries. Reaching it
wrongly requires a totals-current repaint during check-again duty, which I
could not construct from any real trigger (every renderSummary trigger either
moves the signature, which forces the other branches, or follows a reset,
which clears `clientSecret`); recorded for symmetry, not for reachability.

**P-L2.** The eight display names in the page and the eight server addresses
must stay in step by convention (both sides carry MUST-match comments naming
each other). A drifted entry fails soft (server prices Illinois, label names
the picked state until the quote corrects it), which is the right failure
direction; noted because convention is the only thing holding it.

## What was verified sound

**1. One implementation (item 1).** `GUEST_STATE_ADDRESSES` holds exactly
eight canned addresses (IL is `HOUSE_TAX_ADDRESS` itself; the other seven are
synthetic at the street and real at city, ZIP code, and state).
`guestAddressFor` is the ONLY place a code becomes an address, and it does the
trim-and-uppercase normalization once for both callers. The resolver
precedence reads exactly as briefed: member with stored address wins; member
without a ZIP code gets the house default; no member (empty code or miss)
takes the picked state; unknown code silently prices as Illinois. quote-tax
and create-payment parse `guest_state` with VERBATIM-IDENTICAL expressions
(`typeof body.guest_state === "string" ? body.guest_state.trim().slice(0, 2) : ""`)
and both pass it to the same shared resolver, so the quote-versus-charge
asymmetry this project treats as the worst class of bug cannot arise from
parsing.

**2. The signature (item 2).** `guest_state: guestTaxState()` sits in the
shop's `signaturePayload`, which doubles as the quote body, and the identical
expression sits in `liveStart`'s create payload. The picker's change event
calls `renderSummary`, which ends in `liveEnsureQuote()` then
`liveEnsureCheckout()`: a changed state re-asks the tax question and, when a
payment is already open, mismatches the recorded signature and discards and
reopens it. `#guestTaxState` is in the inert selector list, so the state
cannot move while a payment is in flight, and the `liveConfirm` signature
guard remains the last rail before the card is handed over (untouched by this
commit). `guestTaxState()` returns an empty string for a signed-in member, so
the hidden picker can never churn a member's signature. The builder's live
proof orders exist on the rail: ORV-2026-08-17DKXS and ORV-2026-08-17G6S9
both answer from confirm-payment (status processing, identical carts),
consistent with the reported discard-and-reopen experiment.

**3. No injection path (item 3).** The only client inputs that can influence
the tax destination are: `member_code` (resolved against the members table,
address from the database), and `guest_state` (trimmed, sliced to two
characters, used solely as a lookup key into the server-side Record with a
`?? HOUSE_TAX_ADDRESS` fallback; two characters forecloses every prototype
key, and a missing key falls to the house address). The street, city, and ZIP
code the guest types into the billing form never leave the page: the create
and quote payloads carry exactly items, activation, tax_id, member_code,
guest_state, channel, and return_page, and `setAddress` writes only to the
document. `tax_id` reaches Stripe as an exemption identifier, never as an
address. No client-controlled address can reach Stripe.

**4. The referral-code precedence (item 4).** Recorded as P-M1 above.

**5. syncPayButtonToDisplayedTotal (item 5).** All three totals-painting
branches of `renderSummary` now move the button with the row: the
totals-current branch through `applyServerTotals` and the `onTotalsApplied`
hook, and both estimate branches (tax-exempt and ordinary) through the new
helper with the same figure they just painted. The helper is correctly silent
before the first open (no figure on the button yet), on check-again duty, and
while busy (inert holds every amount control, so the displayed total cannot
move mid-confirm). The remaining asymmetry is P-L1 above. The hard rail at
submission time is unchanged.

**6. Guardrails (item 6).** Zero em or en dashes across all six files. New
user-facing copy carries no unexpanded acronyms (the picker copy is plain
state names; "ZIP code" is spelled as a word in server comments). No Unicity
terminology. The owner's name appears only in server-side function comments
(dated rulings and asks, the established convention in files that never ship
to the public build and are not scanned by the dist name lint); it appears in
no shipped page or script. The staff console documents its deliberate
non-participation with a dated scope note in `signaturePayload`, and the
`payments.js` change is comment-only (the engine's contract documentation now
explains why a signature field automatically joins both the quote and the
discard-reopen behavior).

## SHA-256 of the graded artifacts (at commit 651ac49)

| Artifact | SHA-256 |
| --- | --- |
| `MLM-PILOT\functions\_shared\tax.ts` | `aada150c7dcdbf3f37cfd8391f86eec17d1cfe887c4d91003833bb311614bc72` |
| `MLM-PILOT\functions\quote-tax\index.ts` | `59894e5c489de97a03cc598f44861455758e1c1e4785afe03d421549e420bf57` |
| `MLM-PILOT\functions\create-payment\index.ts` | `5d34ff1b59f05eebaf94a13cefcd7f85bf09a2812509b49863e068f099146ea0` |
| `MLM-PILOT\www\shop.html` | `2fea93f47b56074325a158faff61ac444caa86dce84b78f4f06c99da1f0e9b64` |
| `MLM-PILOT\www\staff.html` | `9a2754b852239227796aa4a656aa76389332099267e7ddbb29d83113aa608676` |
| `MLM-PILOT\www\js\payments.js` | `1e8359c4c8592dc4166b567ab1ce6708c46e7cde9ea8b945df4706bb85c6aa8d` |

## What I did NOT probe

- The picker in a real browser (change the state, watch the quote and the
  reopen): QA's half; my trace is code-level plus the builder's live order
  evidence.
- The deployed behavior of `guest_state`: the functions are not deployed, so
  no live endpoint accepts the field yet; the live rail today ignores it,
  which is exactly why the ordering note above exists.
- Whether each of the seven non-Illinois states actually returns a nonzero
  figure: that is the owner's Stripe dashboard registration per state, and
  the page correctly labels a zero as `not_collecting` versus `none due`.
- The deploy byte-compare of the three function files against the cloud once
  shipped: that obligation opens at deploy time per the standing rule, along
  with the still-open N-M1-related compare noted in the delta verdict if not
  already discharged.

---

# DATED NOTE: the discoverability delta, graded 2026-08-16 (commit c66608a)

Narrow delta gate on the owner's two discoverability catches (shop.html plus
payments.js), command-line instruments only. VERDICT: PASS. Deploy YES from
the verifier's half; the functions-first-or-together ordering note from the
main verdict above still governs, since this commit rides on the same
undeployed picker feature.

**1. The words-only seam.** The engine's `decorateTaxLabel` hook is called
after the label is built and may only replace the label string (a falsy
return keeps the engine's wording); it has no access to the signature
payload or the button, and the figure paints take `tax_cents` and
`total_cents` from the totals object, not from anything the decorator
returns. The SHOP'S SHIPPED DECORATOR IS VERIFIED PURE: it reads three
fields of the totals object and two page states, writes nothing, and builds
its replacement label from page constants only (no server strings enter the
`innerHTML` path). One LOW observation, D-L1: the words-only property is
held by convention, not construction. The engine hands the decorator the
LIVE totals object (the same reference `getServerTotals` and
`onTotalsApplied` later read) BEFORE painting the figures, so a mutating
decorator could in principle move the painted tax, the painted total, and
the button amount. No such path exists in shipped code; passing a copy, or
freezing the object, would turn the engine comment's WORDS ONLY contract
into a property. Not blocking.

**2. One control, one truth.** The picker was MOVED, not mirrored: exactly
one `guestTaxState` select and one `guestTaxStateRow` element exist in the
page (counted); the billing panel holds only a pointer comment. The engine
wiring is byte-unchanged from the version this verdict already passed:
`guest_state: guestTaxState()` appears exactly twice (signature payload and
create payload), `#guestTaxState` remains in the inert list, and the single
change listener still walks renderSummary into the quote debounce and the
discard-and-reopen. All four visibility writes are accounted for and
consistent (markup default hidden; shown on guest and on signed-out; hidden
on member sign-in; the renderSummary rule `!LIVE_PAYMENTS || accountMode
=== 'member'` covering every re-render including the undecided chooser
moment, where the figure on screen is genuinely guest-priced).

**3. One guest path, two doors.** `continueAsGuest` is a single named
function; the chooser's guest button and the new inline
"Continue as guest instead" button both bind exactly it. Refusal and
recovery travel together (`showSigninError` raises the inline button,
`hideSigninError` drops both, and both retry paths clear the previous
refusal). No second guest implementation exists.

**4. Guardrails.** Zero em or en dashes in both files; the new user-facing
copy carries no acronyms, no Unicity terminology, no owner name. A pleasant
side effect recorded for the P-M1 ledger: `guestTaxDefaultUnpicked`
excludes the typed-referral-code case, so the decorator now correctly
refuses to claim Illinois when a referral code will actually price the
order; the pre-quote estimate label still names the picked state in that
case, so P-M1 stands as recorded, awaiting the owner's ruling.

Hashes at c66608a: `MLM-PILOT\www\shop.html`
`afcb98187e8a07b585c1962c6a631ad221bf27e6a3b2f677be60896c744092bd`;
`MLM-PILOT\www\js\payments.js`
`37a123bba8fff7cc2e2bca1d59cad5a3a58140a8fc37a8aff1fdf778e1994d71`.

Not probed: the two flows in a real browser (refused sign-in to inline
guest door; picker-at-chooser visibility): QA's half.

---

# DATED SECTION: the outage-window commits, graded 2026-08-16

Scope given: commits 0367407 through 14b6cc7 (ten commits authored under the
owner's identity during the spend-limit outage, self-documented in
CLAUDE_NOTES.md): staged Plaid sandbox panel, staged multi-currency tax,
Braintree wallet enablement, sticky-summary fixes. Command-line instruments
only. Per the standing rule these owe both gates before any deploy.

## GATE: FAIL. Deploy NO from the verifier's half.

Two HIGH findings. One is a fabricated confirmation path on the live page;
the other is an ungated reversal of a ruled, verifier-passed money-path
design. The staged-currency guards themselves are well built and verified;
the failure is in what rode alongside them.

## Scope correction, before the findings

The briefed span does not match the repository. The span itself touches
THREE Edge Function files (`_shared\tax.ts`, `quote-tax\index.ts`,
`create-payment\index.ts`) and the engine (`payments.js`), not only
shop.html and shop.css. And the ungated outage window is FOURTEEN
payment-surface commits, not ten: be7656c and 94a53d9 (the billing-address
tax rewrite) and a9aaff3 and c2d10e5 (the sticky summary work named in the
briefing) sit BETWEEN my last gate (e9d2820) and the span start, ungated;
efd8f0d (a subscription schema applied to the cloud) follows the span and
owes its own gate. Everything below grades the named span and, where the
span builds directly on the ungated pre-span base, says so explicitly.

## Findings

### HIGH

**O-H1. The Plaid panel's ending fabricates a confirmation on the live
page.** Commit 14b6cc7 wires the panel's "Authorize sandbox bank payment"
button to `demoPlaceOrder(...)` UNCONDITIONALLY, on a page where
LIVE_PAYMENTS is true. The result of clicking it: the round-4 demonstration
handler renders the full confirmation view, mints a LOCAL order number in
the live ORV format (`orderNumber()` in the page), and CLEARS THE CART. No
server row exists anywhere: the order lookup on the same page will answer
"No order with that number, which means nothing was charged for it" about
the number the confirmation just displayed. The demo note's own words,
"This preview placed a demo order", are false in this project's vocabulary:
a demo order is an `app.demo_orders` row, and none was created. This is the
exact defect class the 2026-08-14 precedent (the staff console faking
payments) made a standing rule: looks real, is fake, and contradicts
another surface's truth. Fix before any deploy: the authorize ending either
stays a preview (no confirmation view, no minted order number, cart intact)
or creates a REAL demo order through create-payment.

**O-H2. The guest tax destination was rewritten from server-canned to
client-typed, ungated, reversing a ruled and verifier-passed design.** The
pre-span outage commits (be7656c, 94a53d9) made the billing State and ZIP
fields the tax destination, and the span (69d24b4, f704c00) extended it:
`guestAddressFor` now takes the client's typed street, city, and postal
text and sends them to Stripe Tax (length- and charset-sanitized only), on
BOTH quote and charge, with GB, IE, and CH added beside all fifty states.
The picker gate this file records verified the opposite property as the
design: "only the two-letter code from the allow list may influence the
destination and everything else is server-canned", and my no-injection
ruling in the main verdict above is NOT TRUE of main as it stands. A
client-typed ZIP can now steer the priced tax jurisdiction, which alters
tax_cents on a real create: client-controlled money movement inside the tax
line. Making the visible billing fields authoritative is a defensible
product choice, and the checkout-walk reasoning in the code is real; but it
reverses a ruled control without a decision record (CLAUDE_NOTES is a work
log, not the decisions folder), and it shipped ungated. Required before
deploy: the owner rules it (a dated decision entry, and this file's
no-injection claim gets a superseded marker), or the field routing reverts
to canned addresses.

### MEDIUM

**O-M1. The live rail's routing changed in the cloud during the window, and
the card-truth surfaces do not know it.** CLAUDE_NOTES documents an active
50/50 volume-split routing configuration between Braintree and
Authorize.net (`routing_loBp0KbnCzD0IADxwWbY`), probed live during the
window. If that is the current active state, roughly half of live payments
now land on a processor for which every published card promise is
unverified: TEST-CARDS.html's "one truth" matrix, the shop and staff hints,
the 2503 passcode journey, and the 2,000.00 to 3,000.00 amount rule are all
Braintree-specific. The "one truth for the challenge card" this file gated
is at best a coin-flip truth per payment under a volume split. Needs
either routing pinned back to Braintree-only for the demo, or the card
surfaces re-verified and rewritten per connector. Cloud state; my evidence
is the window's own probe log, and confirming current routing needs
dashboard or admin-key access I do not have.

**O-M2. The currency select escaped the inert lockdown and can destroy an
in-flight payment's state.** `#currencySelect` is not in `inertSelectors`
(the new billing fields are), so it stays operable during authorization.
Its change handler calls `liveResetPayment('')` whenever a payment is open
and the new currency is not USD, without checking `busy`: switching to GBP
while the card is mid-confirm clears the engine state, the order chip, AND
the resume record that liveConfirm deliberately wrote before confirm, while
the charge itself continues at the processor. A charge can then succeed
with the client holding no record of it except the lookup. No wrong amount
is possible (the payment's amount is fixed server-side), and reaching it
requires flipping currency during the authorization seconds, but the
resume-before-confirm guarantee was engineered precisely for this window.
Fix is two lines: add `#currencySelect` to the inert list, and refuse the
reset while `state.busy`.

**O-M3. One conversion rate table, hand-copied into two codebases.** The
client's `CURRENCIES` rates (shop.html) and the server's
`TAX_CURRENCY_RATES` (tax.ts) carry the same hardcoded values (0.79, 0.92,
0.88) with nothing keeping them equal. Today they match; the day one side
is edited, the displayed conversion and the quoted tax conversion disagree
by design. The engine's new `opts.formatMoney` seam is what lets the page's
converting formatter reach every engine paint, so the blast radius of a
drift is the whole checkout. Server-authoritative rates (the quote already
returns `tax_calculation_currency` and `tax_calculation_cents`) would
remove the duplication.

### LOW

**O-L1.** The GB, IE, and CH canned tax addresses are real famous addresses
(10 Downing Street, London; 1 College Green, Dublin; Bahnhofstrasse 1,
Zurich), breaking the stated synthetic-street principle ("nobody lives at 1
Demonstration Way") that the US entries still follow.

**O-L2.** The non-USD staging depends on a client-side guard
(`serverTaxQuoteAllowed`) plus the deployed functions ignoring unknown
fields; once the functions deploy, non-USD quotes go live while create
stays 409-guarded, so a GBP tax figure can be quoted for an order that
cannot be created in GBP. The currency hint says so; recorded as accepted
staging.

**O-L3.** CLAUDE_NOTES' final entry describes the Plaid ending as "a final
'nothing charged' authorization preview"; commit 14b6cc7 then made it
complete a fabricated confirmation (O-H1). The self-documentation lags its
own last commit.

## What was verified sound

- **The staged-currency guards (the notes' central claims), verified in
  code.** create-payment parses `currency` and `payment_method` defensively,
  refuses non-card with a 409 (`payment_method_staged`) and non-USD with a
  409 (`currency_staged`) BEFORE pricing and before any order insert, and
  pins its own calculateTax call to the literal "USD". quote-tax asks
  Stripe in the requested currency and converts the answer back to the USD
  cents contract through the same rate table (`displayMinorFromUsdCents` in,
  `usdCentsFromDisplayMinor` out, round-trip within rounding). The
  normalizer allow-lists exactly USD, GBP, EUR, CHF. Neither the picker
  flow, the member flow, nor any crafted body bypasses a server-side 409.
- **The Plaid panel is page-owned and creates nothing (item 2).** Zero
  external Plaid script: no plaid.com, no cdn.plaid, no link-initialize
  anywhere in the page or stylesheet; the only external scripts remain the
  two sanctioned ones (HyperLoader via the engine, Botpress). The panel
  itself makes no network call. The HIGH condition in the briefing (a new
  external script) is NOT triggered; the panel's defect is O-H1's ending,
  not its loading.
- **Wallet enablement is page and widget configuration only (item 3).** The
  page enables the Google Pay and PayPal tiles (Apple Pay stays disabled
  pending domain setup) and the engine's `mountWidget` adds the widget
  `wallets` option with `walletReturnUrl` set to the canonical return URL,
  so wallet redirects re-enter the existing resume flow. The create and
  confirm paths are unchanged; which methods actually appear is processor
  dashboard configuration. The deployed rail's behavior does not change
  until this site deploys (the routing change of O-M1 is separate cloud
  state, already live).
- **The non-USD client guards hold where I traced them.** `canOpenLivePayment`
  gates the auto-open (both the entry and the 900 millisecond re-check),
  manual submit (staged message instead), the mount label, the button sync,
  and `onTotalsApplied`; method and currency changes reset any open payment
  (the reset's own defect is O-M2); `serverTaxQuoteAllowed` keeps non-USD
  off the live quote path so the deployed Illinois-only resolver cannot
  overwrite the local estimate.
- **Guardrails (item 4).** Zero em or en dashes across the span's six code
  files. No owner name in the shipped page, stylesheet, or engine (the
  name lint also passes in the notes' own build run). New user-facing copy
  spells its terms ("ZIP / postal code", "State / region"; Open Banking and
  Automated Clearing House (ACH) appear in staff-facing hints as
  "ACH/bank-debit", the one loose acronym, in a tooltip). No Unicity
  terminology.

## SHA-256 of the graded artifacts (at 14b6cc7 = current main for these files)

| Artifact | SHA-256 |
| --- | --- |
| `MLM-PILOT\www\shop.html` | `0f552d676ca157f33a8dc1c8ab6b87987368e9f60bd54880af881e51e0ca5e8d` |
| `MLM-PILOT\www\css\shop.css` | `45b0975e4c86f7538534fb78f89776d38b7338bbeead41d6c2fd73a8793b3d23` |
| `MLM-PILOT\www\js\payments.js` | `de78388fd2208a20f2907843eed791060e71d9584e6d20b5f974728650588a3f` |
| `MLM-PILOT\functions\_shared\tax.ts` | `afa8d3864295d5acd647efcd4c4a6312c6c23717e2a3f77891724e7b21283780` |
| `MLM-PILOT\functions\create-payment\index.ts` | `6c72fe0d8f659cbb24d9af8c00b02e04d3779a9745dab469470b65308dd190b2` |
| `MLM-PILOT\functions\quote-tax\index.ts` | `aaa6bb47709dd41181dc85ed941c2f0b5921ccd152ff3900355b23d6ad6ca813` |
| `CLAUDE_NOTES.md` | `263a0cd3db62aae22e47038f3b7967a5da198ce15c4158a48caae329815edaa0` |

## What I did NOT probe

- The four pre-span commits (be7656c, 94a53d9, a9aaff3, c2d10e5) beyond
  where the span builds on them, and efd8f0d's cloud schema apply: each
  owes its own gate; O-H2 covers the pre-span tax rewrite because the span
  extends it directly.
- The current active routing configuration (O-M1): needs dashboard or
  admin-key access; my evidence is the window's own probe log.
- The wallet flows, the Plaid panel, the currency selector, and the
  sticky-summary behavior in a real browser: QA's half.
- Whether Stripe Tax actually answers correctly for GB, IE, and CH
  addresses in the sandbox account (registration state is the owner's
  dashboard).

---

## Deploy record, 2026-08-16 (appended by the deploy engineer)

This section is the deploy log for the server half this verdict authorized. It is
appended by the database engineer agent, who executed the deploy; everything above
this line is the verifier's and stands unedited.

**Route.** Supabase management tool (the command line interface has no stored
credential on this machine), functions first per the ordering note above, mirroring
the platform's existing layout: entrypoint `functions/<name>/index.ts` with sibling
`functions/_shared/` files. Sources: commit `651ac49`, which repository HEAD matched
byte for byte at deploy time for all five files involved.

**Versions.**

| Function | Version before | Version after | Files in bundle |
|---|---|---|---|
| `quote-tax` | 1 | 2 | `index.ts`, `_shared/edge.ts`, `_shared/pricing.ts`, `_shared/tax.ts` |
| `create-payment` | 7 | 8 | `index.ts`, `_shared/edge.ts`, `_shared/pricing.ts`, `_shared/tax.ts` |

Both kept `verify_jwt: true`, their existing setting. Both prior bundles carried the
pre-picker `tax.ts` (8,935 bytes) and a stale pre-connection-borrowing `edge.ts`
(28,502 bytes); this deploy refreshed both, the same wanted side effect the
2026-08-16 list-demo-orders redeploy had.

**Byte-compare: PASS, all eight files (two bundles of four).** Every file was
fetched back from the platform after deploy and its SHA-256 (Secure Hash Algorithm
256) hash compared against the repository git blob (line-feed canonical form; the
Windows working tree carries carriage-return line-feed endings from autocrlf):

| File | Bytes | SHA-256 (first 16) | Verdict |
|---|---|---|---|
| `functions/quote-tax/index.ts` | 6,644 | `59894e5c489de97a` | MATCH |
| `functions/create-payment/index.ts` | 23,957 | `5d34ff1b59f05eeb` | MATCH (equals the hash in this verdict's own table above) |
| `functions/_shared/tax.ts` | 12,787 | `aada150c7dcdbf3f` | MATCH (equals this verdict's table) |
| `functions/_shared/pricing.ts` | 8,545 | `9235559dfd0322b6` | MATCH |
| `functions/_shared/edge.ts` | 29,051 | `832db86450095598` | MATCH (both bundles) |

**Live probes, quote-tax, Origin `https://orvanna.io`, cart = one payment agent
subscription (10,000 cents taxable), all HTTP 200:**

| Probe | tax_cents | total_cents | tax_source | tax_reason | tax_jurisdiction |
|---|---|---|---|---|---|
| `guest_state: "NY"` | 888 | 10,888 | `stripe_tax` | `standard_rated` | `NY, US` |
| `guest_state: "OR"` | 0 | 10,000 | `stripe_tax` | `not_subject_to_tax` | `OR, US` |
| no `guest_state` | 1,025 | 11,025 | `stripe_tax` | `standard_rated` | `IL, US` |
| `guest_state: "ZZ"` | 1,025 | 11,025 | `stripe_tax` | `standard_rated` | `IL, US` |

Readings. New York answered 8.88 percent, the New York City combined rate as
Stripe rounds it on this amount, nonzero as required now that all 50 states are
registered. Oregon answered zero WITH its reason, and the exact Stripe
taxability_reason string is `not_subject_to_tax` (not `not_collecting`): Oregon has
no state sales tax, so this is the correct "none due" zero, and the quality
assurance copy grade should key on that exact string. The no-state fallback landed
on Illinois as contracted, now at a nonzero 10.25 percent because the mid-gate
registration turned the old `not_collecting` zero into a real Springfield figure.
The unknown code `ZZ` fell back to Illinois identically, with no error, which is
the allow-list contract working.

**Not probed here:** create-payment's `guest_state` end to end (it opens a real
HyperSwitch payment; the shared resolver is byte-identical between the two
functions, so the quoted state is by construction the charged state), and the
browser half, which is QA's.
