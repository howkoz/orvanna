# Phase 6 QA: Real TEST-MODE Payments on the Live Rail

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-14
Scope: the live payment rail behind https://orvanna.io: `shop.html` as deployed
(LIVE_PAYMENTS true, commit b9e6936), the three version 2 Edge Functions at
https://oiyibdczkokegaxkwulv.supabase.co/functions/v1/ (create-payment,
confirm-payment, list-demo-orders, with per-function scoped rate buckets), and
the HyperSwitch hosted sandbox with two dummy connectors (pretendpay_default,
stripe_test_default). This is the completeness gate defined by spec section 6.2
plus the coordinator's ten tasked rows. The security half (forged carts, forged
confirms, anon posture, pricing mirror parity) was already graded PASS by
mlm-verifier and is not repeated here. Every claim below comes from raw
Hypertext Transfer Protocol (HTTP) requests driven with curl against the public
internet, playing the card exactly the way the site's Software Development Kit
(SDK) does, plus a byte-level read of the deployed `shop.html`.

## Verdict (read this first)

**PASS.** 10 acceptance rows executed: 10 PASS, 0 FAIL. 0 HIGH defects,
1 MEDIUM defect (pre-mount framing, expected because writer package W5 is
still pending; flagged, not failed, per the coordinator's instruction),
2 LOW notes, 3 observations. Money math matched my hand computation to the
cent on every order, the decline and retry paths behave exactly as specified,
confirm-payment is provably idempotent (four byte-identical receipts), the
rate rails fire at precisely the 6th create in a minute with a Retry-After
header and polite copy, the refused call does not extend the window, and the
confirm and list buckets are untouched by a create storm.

Acronym key: QA (Quality Assurance), HTTP (Hypertext Transfer Protocol),
SDK (Software Development Kit), PV (Personal Volume), CORS (Cross-Origin
Resource Sharing), JSON (JavaScript Object Notation), IP (Internet Protocol),
UTC (Coordinated Universal Time), MD5 (Message Digest 5, the checksum used
for the byte-identity proof).

## Method note

Promises first: the ten-row checklist below was fixed, and the Row 2 money was
hand-computed, BEFORE the first create call was made. Hand math for Row 2, from
`www\js\catalog.js` (2 x Software Engineer one-time at $500.00 = $1,000.00 and
1,000 PV; 1 x Momentum Pack subscription at $400.00 and 400 PV; priority
activation $25.00; tax exempt so tax $0.00): subtotal one-time 100000 cents,
subtotal subscription 40000 cents, activation 2500 cents, tax 0, total 142500
cents ($1,425.00), PV 1,400. The create budget was planned around the 5 per
minute rail (11 create calls total, burst last). Cards were played by POSTing
to https://sandbox.hyperswitch.io/payments/{payment_id}/confirm with the
publishable key, the documented equivalent of the site's SDK card flow.

One environmental caveat, recorded honestly: order ORV-2026-08-168N5T appeared
(and later succeeded) during my session and was not created by me; another
session was driving the rail concurrently. The count-arithmetic row was
bracketed tightly enough (seconds apart, newest order number compared) that the
conclusion stands.

## Acceptance checklist

| # | Row | Evidence | Result |
|---|---|---|---|
| 1 | Happy path, subscription: 1 x Payment Agent subscription, standard activation, taxed | Order ORV-2026-08-167WGA. Server receipt: subtotal_sub_cents 10000, activation_fee_cents 0, tax_cents 500, total_cents 10500, pv_total 100, payment_status succeeded, processor status succeeded. HyperSwitch object: status succeeded, amount 10500, amount_received 10500. list-demo-orders shows the same order at total 105 dollars, 100 PV, succeeded | PASS |
| 2 | Happy path, mixed one-time + pack + priority + tax exempt, hand math first | Order ORV-2026-08-168Y3Q. Every receipt field equals the pre-computed hand math above, to the cent: 100000 / 40000 / 2500 / 0 / 142500 cents, pv_total 1400. HyperSwitch amount and amount_received both 142500 | PASS |
| 3 | Decline path with 4000 0000 0000 0002 | Order ORV-2026-08-169YHT. confirm-payment returned payment_status failed with processor error fields populated: error_code DC_08, error_message "Payment declined: Card declined". A repeat confirm returned a byte-identical receipt (diff clean) and the row stayed failed | PASS |
| 4 | Retry after decline, same cart, fresh create | Order ORV-2026-08-16AVAZ created fresh, paid with 4242, payment_status succeeded, total_cents 10500. Old declined row ORV-2026-08-169YHT still shows failed in list-demo-orders afterward | PASS |
| 5 | Idempotent confirm, 3 extra calls on Row 1's order | Four receipts total (files row1-receipt-1 through 4) share one MD5 checksum 2b7f6b65a9c2b7945fe54d465f8a7531; status succeeded throughout. Site code additionally guards double-click (liveState.busy, button disabled, client_secret reuse in liveSubmit) | PASS |
| 6 | Live site wiring, static and fetch checks | Deployed shop.html (62,039 bytes fetched from https://orvanna.io/shop.html): LIVE_PAYMENTS = true at line 865. The HyperLoader reference https://beta.hyperswitch.io/v1/HyperLoader.js appears exactly once, as LIVE_CONFIG.hyperLoaderUrl inside the live flow, loaded on demand by loadHyperLoader(); no static script tag, nothing else external. Demo path preserved: demoPlaceOrder() intact and reached only when the flag is false. Zero em or en dashes in the page (character scan). Personal Volume (PV) expanded on first rendered use (hero copy, line 50) before any bare PV. All money rendered through fmtMoney / cents helpers with two forced decimals. Express marks (Apple Pay, Google Pay, PayPal) are inline drawings labeled "Demonstration marks, not real payment brands. Nothing is charged." and in live mode are disabled with an explanatory title | PASS |
| 7 | Order number format ORV-YYYY-MM-XXXXXX, 6 base36 characters | All 10 orders I created match the regular expression ^ORV-\d{4}-\d{2}-[0-9A-Z]{6}$ (list below) | PASS |
| 8 | HyperSwitch connector cross-check | All three of my succeeded payments were handled by connector stripe_test (stripe_test_default). pretendpay_default handled none of mine. Both-on-one-connector is acceptable per the tasking; recorded as an observation, not a defect | PASS |
| 9 | Rails, run last | Burst of 6 creates inside one fresh minute bucket (15:17:03 to 15:17:19 UTC): creates 1 to 5 returned 200 with order numbers, create 6 returned 429 with header Retry-After: 42 and body "Easy does it. This demo takes a few orders per minute per visitor. Please wait a moment and try again." (plain English, no dashes, no acronyms). Immediately after the 429, confirm-payment on ORV-2026-08-167WGA returned 200 succeeded and list-demo-orders returned 200: the confirm and list buckets are scoped, not consumed by the create storm. At 15:18:02, the first create of the next minute returned 200 (ORV-2026-08-16I44W): the refused call did not extend the window. The earlier unknown-SKU probe (sku "free-agent") returned 400 with code invalid_cart, message "The cart names an item the shop does not sell.", and the bracketing list calls showed identical counts and an identical newest order number: no row was written | PASS |
| 10 | Deliverability of the demo note (framing around the card form) | During SDK mount the panel states "Test mode. Use the test card 4242 4242 4242 4242 with any future expiry date and any three digit security code. Nothing is ever charged." The confirmation view states "Test mode checkout: a test payment ran against the sandbox and nothing real was ever charged." The step-4 panel carries "Demonstration marks, not real payment brands. Nothing is charged." before mount. Framing exists before and during mount, so the row passes; its thinness before mount is defect M1 below, severity flagged per the coordinator's instruction because writer package W5 is still pending | PASS |

Spec rows outside my ten that deserve a status line: Q4's foreign-origin CORS
refusal was probed cheaply (POST with Origin https://evil.example returned 403
with no Access-Control-Allow-Origin; the https://orvanna.io control returned
200 with the correct allow headers): holds. Q6 (abandon aging to `abandoned`
after one hour) is NOT TESTABLE inside this session's window; the six unpaid
burst orders listed below are ready-made aging candidates for a later check.
Q7 (no personal data toward our functions) was verified by code reading of the
deployed page: cartPayload() sends only sku, mode, quantity, plus activation,
tax_exempt, member_code, channel; no name, address, Tax Identification value,
or card field exists in the request path.

## Defects

MEDIUM

- M1 (framing before mount, writer package W5 pending): in live mode, step 4
  initially shows the round-4 demonstration card inputs (Name on card, Card
  number, Expiry, Security code) and the line "Demonstration checkout: any
  values continue, including empty fields." until Place order is pressed and
  the real secure form replaces them. Two problems: (a) the obviously-test
  framing before mount is only the small "Nothing is charged" note, thinner
  than spec section 5's intent; (b) a stranger could type a real card number
  into those inert local inputs believing they are the payment form. The
  digits never leave the browser (the fields are not transmitted anywhere),
  so this is a framing defect, not a data leak. Suggested fix for W4/W5: when
  LIVE_PAYMENTS is true, hide the demonstration card inputs from the start,
  show the test-mode banner up front, and retire the "any values continue"
  sentence.

LOW

- L1: list-demo-orders returns total as a bare JSON number in dollars (for
  example 105, not 105.00). The page formats it through fmtMoney so every
  user-visible rendering is correct to two decimals; noted only so nobody
  ever prints the raw field.
- L2: the "Recent test orders" section renders only after a successful
  payment (called from the confirmation branch). That matches the architect's
  open-question-2 recommendation (confirmation exit placement) but means a
  visitor who never completes a payment never sees live orders. Acceptable
  as designed; recorded for completeness.

Observations (not defects)

- O1: all succeeded payments landed on connector stripe_test; the second
  connector (pretendpay_default) took no traffic in this pass.
- O2: Retry-After was 42 seconds at a 429 issued at 15:17:19, which points
  exactly at the next minute bucket (15:18:01): the header is computed, not a
  constant.
- O3: concurrent traffic (ORV-2026-08-168N5T, not mine) was active during the
  session; the coordinator should treat the order list below, not the table
  row count, as my footprint when bracketing database checksums.

## Orders created by this QA pass (for the coordinator's checksum bracket)

| Order number | Purpose | Final status when last seen |
|---|---|---|
| ORV-2026-08-167WGA | Row 1 happy path, subscription | succeeded |
| ORV-2026-08-168Y3Q | Row 2 mixed cart, tax exempt | succeeded |
| ORV-2026-08-169YHT | Row 3 decline | failed |
| ORV-2026-08-16AVAZ | Row 4 retry after decline | succeeded |
| ORV-2026-08-16GD74 | Row 9 burst 1 | created (never paid; aging candidate) |
| ORV-2026-08-16GGL2 | Row 9 burst 2 | created (never paid; aging candidate) |
| ORV-2026-08-16GJP9 | Row 9 burst 3 | created (never paid; aging candidate) |
| ORV-2026-08-16GMDT | Row 9 burst 4 | created (never paid; aging candidate) |
| ORV-2026-08-16GR4K | Row 9 burst 5 | created (never paid; aging candidate) |
| ORV-2026-08-16I44W | Row 9 post-window proof | created (never paid; aging candidate) |

Not mine, seen during the session: ORV-2026-08-168N5T (succeeded), plus the
three pre-existing baseline orders ORV-2026-08-15QO6G (processing),
ORV-2026-08-15MOGN (processing), ORV-2026-08-158WRU (succeeded).

The unknown-SKU probe and the 6th burst call wrote no rows, by proof (Row 9).

## Phase verdict

QA gate: **PASS** (10 of 10 rows). Phase 6 closes only on BOTH gates; the
verifier's security-half PASS is already on record, so from the QA side the
phase is clear to close. M1 should ride with the pending W4/W5 polish, not
block the gate.

---

# Delta: Staff Console on the Live Rail

Graded by: mlm-qa
Date: 2026-08-14 (same day, second pass)
Scope: `staff.html` wired to the same live test-payment rail as the shop
(public repo commit d628b48, source commit 829f0a3), graded headlessly with
the same curl recipe, plus a whole-property capability sweep.

Charter acknowledgment, on the record: my charter gained a standing lesson
from this round because Howard caught what my first pass missed. The shop took
real test payments while the staff console still faked them behind a "no
payment is ever taken" line, and I graded only the shop because the brief
named only the shop. The rule now and from every phase forward: SCOPE FOLLOWS
CAPABILITY, NOT THE BRIEF. When a capability goes live anywhere, every surface
that presents that capability gets its own checklist row, graded
wired-for-real, honestly-labeled-demo, or defect. Delta row 5 below is that
rule's first execution.

## Delta verdict (read this first)

**PASS.** 5 delta rows executed: 5 PASS, 0 FAIL. 0 HIGH, 0 MEDIUM, 0 LOW new
defects; 2 observations. The staff channel runs the identical server rail
(channel tag, referral capture, money math, decline truth, idempotent
confirm), the deployed staff page carries the three truth-fixed disclaimers
with the old falsehood gone, and the capability sweep found no payment
lookalike anywhere on the property that is not either on the rail or an
honestly labeled demonstration.

## Delta checklist

| # | Row | Evidence | Result |
|---|---|---|---|
| D1 | Happy path on the staff channel with a real member code | Order ORV-2026-08-1FEON7, created with channel staff_console and member_code GW-000002 (proven real: v_demo_members returns it as Kai Eastbrook). Paid 4242, confirm-payment returned payment_status succeeded, channel "staff_console", referral_code_entered "GW-000002", total_cents 10500, pv_total 100; HyperSwitch amount_received 10500. list-demo-orders shows created_by_channel staff_console for the row. Evidence limit, stated honestly: the sanitized receipt does not expose member_id, so the resolved-member link itself rests on the coordinator's database evidence (ORV-2026-08-1F9AP5, member_id 50); what I proved from outside is that the code is real, was accepted, and was kept | PASS |
| D2 | Decline on the staff channel | Order ORV-2026-08-1FFOC8, card 4000 0000 0000 0002: payment_status failed with error_code DC_08 and error_message "Payment declined: Card declined", channel staff_console. Repeat confirm returned a byte-identical receipt (cmp clean), row stayed failed | PASS |
| D3 | Member-code miss never fails the order | Order ORV-2026-08-1FGE80 created with member_code XX-999999 (proven absent: v_demo_members returns empty). Create returned 200, payment succeeded at total_cents 5250 (1 x Secretary subscription plus tax, matching hand math), and referral_code_entered "XX-999999" survives in the receipt | PASS |
| D4 | Static checks on the deployed https://orvanna.io/staff.html (53,610 bytes) | LIVE_PAYMENTS = true (line 776). Demonstration card inputs hidden in live mode: applyLiveModeDefaults() hides them at load, the radio change handler keeps them hidden, and both backToOrder() and newCall() re-apply the live defaults AFTER their radio reset, so the demo fields cannot resurface. Card on file radio disabled in live mode with its "demo" chip retained (line 127). The three truth-fixed disclaimers present: header "Payments run on the live TEST rail: test cards only, play money, no real charge is possible" (line 39), place hint "Test mode: the payment runs on the live test rail, play money only" (line 143), confirmation hint "Test mode: a test payment was processed on the sandbox rail; no real money moved" (line 185). The old "No payment is ever taken" text: zero hits. House rules: zero em or en dashes (character scan); Personal Volume (PV), Sales Volume (SV), and Team Volume (TV) expanded in the header disclaimer, which renders before any bare use; all money through fmtMoney with two forced decimals. Decline path consults server truth (staffAfterSdk always calls confirm-payment except for pure in-browser form validation), shows the processor reason, keeps the order lines, and retry is a fresh create. Server order number feeds renderConfirmationView, including the read-aloud token | PASS |
| D5 | Capability sweep, whole property (new standing rule) | All eight deployed pages fetched live and searched for payment-like markup (card fields, security code, checkout handlers, function calls, HyperLoader). Per surface: shop.html WIRED (graded above); staff.html WIRED (this delta); product.html no payment surface (prices and Add to cart only; capture happens in the shop's wired checkout); index.html no payment surface (one prose sentence about future checkout, no controls); login.html no payment surface, and its fake sign-in is an honestly labeled demonstration ("any credentials continue", "no real authentication"); portal/index.html no payment surface (DEMO MODE pill, synthetic payouts); team.html no payment surface; 404.html no payment surface. Nothing on the property looks like a payment surface while being off the rail | PASS |

## Delta findings

No new defects at any severity.

Observations

- DO1: both staff-channel succeeded payments also landed on connector
  stripe_test; pretendpay_default has still taken no traffic in any of my
  passes.
- DO2: the shared 5 per minute create bucket held comfortably; delta used 3
  create calls, spaced, bringing my session total to 14 of the 30 per hour.

## Delta orders created (extend the checksum bracket)

| Order number | Purpose | Final status when last seen |
|---|---|---|
| ORV-2026-08-1FEON7 | D1 staff happy path, GW-000002 | succeeded |
| ORV-2026-08-1FFOC8 | D2 staff decline | failed |
| ORV-2026-08-1FGE80 | D3 member-code miss | succeeded |

Seen but not mine: ORV-2026-08-1F9AP5 (the coordinator's own browser-driven
staff order, status created, aging candidate).

## Delta phase note

QA delta: **PASS** (5 of 5 rows). Combined with the original 10 of 10, the QA
gate remains PASS with the staff console now covered on equal footing with the
shop, per the standing rule that scope follows capability.
