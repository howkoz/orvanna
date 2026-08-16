# Stabilization Gate: Quality Assurance (QA) Verdict, 2026-08-16

Grader: mlm-qa. Scope: the stabilization Step 2 work (shared payment engine
`www\js\payments.js` consumed by `www\shop.html` and `www\staff.html`, the
`docs\TEST-CARDS.html` rebuild, build changes), NOT yet deployed, plus the surfaces
never QA-graded: five content pages (comp-plan, conductor, faq, library,
library-agent) and the staff refund screen. The refund ENGINE passed both gates on
2026-08-15; the SCREEN is graded here for the first time.

Method, per charter: the checklist below was written from the specs
(`docs\STABILIZATION-PLAN-2026-08-16.md` Steps 0 to 2, `ROADMAP.md`,
`docs\COMP-PLAN-SPEC.md` v1.3, and the standing charter rules) BEFORE any
deliverable was opened. Evidence was then gathered live: `www\` served locally on
port 9120, driven in the Browser pane against the REAL Edge Functions and the real
HyperSwitch plus Braintree sandbox rail. Fake money only. Everything computed, not
eyeballed: contrast ratios from computed styles with alpha compositing, amounts
recomputed to the cent, stacking proven by document.elementFromPoint, network
calls captured per request.

ENVIRONMENT LIMIT, stated up front: the sandboxed Browser pane refuses to render
the payment provider's card iframe and the bank's inner 3-D Secure (3DS) frame
(third-party frames answer 403 from the pane's origin gate; the recurring console
403s on every page are the pane blocking the Botpress chat scripts, not page
defects). So card entry THROUGH the widget was impossible here. To still test the
real rail, this QA captured each payment the PAGE created (order number plus
client secret from the page's own create-payment call) and confirmed it against
the sandbox payments API directly with the documented test cards, which is the
same call the widget itself makes; the page was then driven to resolve the
outcome through its own confirm-payment truth path. Every payment, decline, and
refund below is therefore real sandbox traffic against the live functions. What
this cannot prove is the widget's own rendering and the bank passcode
click-through; those are named as Howard's items.

Sandbox actions taken by this QA, on the record: several guest orders created and
resolved (one succeeded at $220.50, one declined at $2,646.00 by the amount rule,
one left parked in the challenge state), one staff order for GW-000002 succeeded
at $106.50, and one REAL sandbox refund of $100.00 executed on order
ORV-2026-08-1JM6CG (GW-000001, placed 2026-08-15, inside the 24 hour window) to
prove the refund button end to end. All fake money. Parked payments are left for
the abandoned-payment sweep.

Acronym key: QA = Quality Assurance. 3DS = 3-D Secure (the bank card
authentication step). PV = Personal Volume. SV = Sales Volume.
CV = Commissionable Volume. TV = Team Volume. DOM = Document Object Model.
SDK = Software Development Kit. SVG = Scalable Vector Graphics.
API = Application Programming Interface.

## The acceptance checklist (written first, graded second)

### A. One payment engine (stabilization plan Step 2 promises)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| A1 | `www\js\payments.js` exists and BOTH pages consume it; no second engine copy remains | 1,082 lines; shop.html:584 and staff.html:380 load `js/payments.js?v=5.2`; grep for the engine internals (scheduleChallengeReveal, openChallengeChrome, confirmPayment) in either page: zero hits; both pages call `window.OrvannaPayments.createPaymentEngine` (shop.html:1423, staff.html:1112) | PASS |
| A2 | Shopper and agent copy injected as strings per page, never shared literals | The engine file contains no user-facing sentences; each page passes its own copy table (shop.html:1445 to 1520, staff.html:1158 to 1201); the six outcome wordings differ per audience as designed | PASS |
| A3 | Staff console gains the finishing state | Live: on submit, mutation log shows card mount hidden AND button hidden 3 ms after the click, held until the confirmation view replaced the panel; no flash back to card entry | PASS |
| A4 | Staff console gains the six outcome messages | All six copy entries present (staff.html:1164 to 1187) including outcomeApprovedThenDeclined and outcomeChallengeDeclinedByCard; the shared classifier was live-exercised (see C4, where its session-state leak was also caught) | PASS |
| A5 | record-tax fires on staff success | Live network capture after the staff sale resolved: `record-tax` 200 fired by staff.html; also observed on the shop success | PASS |
| A6 | Challenge reveal by polling a genuine requires-customer-action state, not the timer | Code: payments.js pollPaymentStatusOnce + scheduleChallengeReveal, timer retained only as poll-error fallback. Live: fake frame with the SDK's exact id injected while a REAL payment sat at requires_customer_action; frame forced invisible at +1 ms, revealed with chrome at +651 ms only after the real status poll answered | PASS |
| A7 | Finding N-H1: checkout shows the address that actually priced the order | Signed-in half delivered: `addressTaxNote` says tax is priced from the stored address (shop.html:193, shown on sign-in). GUEST half not delivered: the guest is told "Enter your billing address below", the fields exist, and the server prices tax from the house Illinois address regardless (functions/_shared/tax.ts HOUSE_TAX_ADDRESS, state "IL"); proven live: guest order with EMPTY address fields was taxed "calculated IL, US" 10.25 percent. The entered address demonstrably affects nothing and no guest-facing note says so | FAIL (defect M1) |
| A8 | Cached script loading; challenge-cancel wired; rejection handlers; escaping helper adopted by shop | loadHyperLoader cached behind one promise (payments.js:413); cancelChallengeReveal wired into resetPayment (payments.js:999) and proven live (no stale reveal after decline reset); every chain ends in catch (pollReceipt, quote, recordTax); shop uses the shared esc (shop.html:1411) | PASS |
| A9 | Payment-link story reconciled: no live staff message points at the permanently disabled button | Softened but NOT reconciled. The honest pieces exist (linkNote says the server side is not built; the radio is disabled with the reason). But three live messages still instruct the path: the approval rules list says "Send them a payment link and stay on the line" (staff.html:194), the disabled option still carries the "recommended" chip (staff.html:202), and the panel line still opens "Create the order, then send the caller a link" (staff.html:218). The console recommends a path it cannot walk | FAIL (defect M2) |
| A10 | Both pages ship through the build; stamper covers SVG; build lint (name check, secret scan, stamp assertion) | deploy/build_dist.py: STAMPABLE_SUFFIXES now (".css",".js",".svg"), bare-SVG references get a stamp added, assert_version_stamps fails the build on any unstamped local reference, owner-name check and secret-shape scan present. Both pages carry ?v=5.2 stamped references. Running the build is the verifier's half of the gate | PASS |
| A11 | Dead raw card number inputs removed from staff.html | Grep: no card number, expiry, or security-code input remains; only the removal note (staff.html:227 to 233). The one card entry is the provider's mounted form | PASS |
| A12 | Staff-auth audit logging fix (N-M1): refusals keep the signature-verified username | NOT delivered. refund-payment still logs `actor: "anonymous"` for every auth refusal (functions/refund-payment/index.ts:511), and StaffAuthResult's failure arm carries only a code, no username field (functions/_shared/staff-auth.ts:156 onward), so a wrong_role or unknown_user refusal still discards a signature-verified username. Howard's addendum shelved the ROTATIONS, and explicitly kept this fix owed | FAIL (defect M3) |

### B. Shop guest checkout, live on the test rail

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| B1 | Tax quoted BEFORE the card | Live timing: quote-tax answered at 17,358 ms and painted "Tax calculated IL, US"; the card iframe began mounting at 17,637 ms; create-payment (opened concurrently by design) answered last and its figure governs. Staff side: quote answered ("FL, US" $6.50) before the payment was even created | PASS |
| B2 | 4242 succeeds end to end; receipt correct to the cent | Order ORV-2026-08-0VMJF6: 2 x Payment Agent $200.00, tax $20.50 = exactly 10.25 percent of $200.00, total $220.50; page resolved through confirm-payment (succeeded) and rendered ORDER PLACED with "Tax 10.25 PERCENT, IL, US", "200 PV: a qualified month"; recent-orders list shows it succeeded | PASS |
| B3 | Amount signature: activation change AFTER open yields fresh order and matching label | Live: order ORV-2026-08-0VDBSY open at $110.25; switched activation to Priority; page discarded it and opened ORV-2026-08-0VFJVK, button relabelled "Pay $137.81 now, test mode", tax $12.81 = exactly round(125.00 x 0.1025) | PASS |
| B4 | Finishing state: no flash back to card entry | Mutation log: mount hidden and button hidden 4 ms after the pay click; page went straight to the receipt | PASS |
| B5 | Decline: processor reason shown, cart preserved, retry offered | $2,646.00 cart (Braintree's documented 2000 to 3000 amount-decline rule) failed ProcessorDeclined on the rail; page showed "Declined. Your bank said: ProcessorDeclined. Nothing was charged and your cart is unchanged. Press Place order to try again with a different card."; cart badge still 3; button re-enabled. (Wording nit: the button at that moment reads "Continue to card details", not "Place order", defect L2) | PASS |
| B6 | Challenge card: full click-through attempted; chrome above bank frame; reveal logic | Real payment parked at requires_customer_action. Reveal logic: PASS (see A6). Stacking probe: chrome and frame both at the clamped maximum z-index 2147483647, chrome moved to end of body; document.elementFromPoint over the cancel button returns ccCancel and over the order number returns ccOrderNum, so the 08-15 defect stays fixed; order number ORV-2026-08-0VYUP5 displayed; cancel re-asked the server and landed in the honest waiting state. The bank's passcode screen itself cannot render in this pane: the final click-through is HOWARD'S ONE-MINUTE CONFIRMATION, and see defect H3 for WHICH card to do it with | PASS (click-through = Howard) |

### C. Staff console, same capability coverage (scope follows capability)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| C1 | Staff sign-in works with the seeded credentials | Live 401 for username "staff"; works as `Orvanna_Staff` / 2026Orvanna (migration 012 usernames). The brief's shorthand was stale, the account stands | PASS |
| C2 | Staff quick order with 4242 succeeds; finishing state present | Caller GW-000002 (Kai Eastbrook); order ORV-2026-08-0W7UWR $106.50 ($100.00 + $6.50 = exactly 6.50 percent, FL, US); finishing state engaged 3 ms after submit; confirmation view with spoken figures ("one hundred six dollars and fifty cents", phonetic order number) all matching the server receipt | PASS |
| C3 | record-tax fires on staff success | Live network capture: record-tax 200 from staff.html right after confirm-payment returned succeeded | PASS |
| C4 | Unrelated order lookup after a challenge must not inherit challenge flavor | REPRODUCED THE LEAK, live and verbatim. With this session's challenge open (real payment in requires_customer_action, chrome up), looking up UNRELATED failed order ORV-2026-08-0VW854 (a shop guest order this console never touched) returned: "The cardholder finished their bank approval, and the payment was then declined by the card itself... The order lines are kept." Both claims are session flavor, not facts about that order. Cause: runStaffLookup (staff.html:2000) feeds an arbitrary order's receipt through engine.outcomeMessage, which consults the SESSION's sawChallenge state (payments.js:886) | FAIL (defect H2) |
| C5 | Payment-link copy gone | Not gone; see A9 | FAIL (defect M2) |
| C6 | Staff decline path shows the processor reason | Same shared classifier and bankSaidPrefix as the shop path proven in B5; staff copy table carries the processor sentence in all six endings; the lookup probe in C4 displayed the live ProcessorDeclined reason text | PASS |
| C7 | Staff card hints tell the same story as the card doc | See F1: they do not | FAIL (defect H3) |

### D. Staff refund screen (first grading ever)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| D1 | Order history renders | Live: "Showing 50 of 137 orders, newest first", refreshable, Show more present, refunded amounts inline | PASS |
| D2 | Order detail loads | Live: server-priced lines, tax with jurisdiction and provenance, total, staff-gated processor reference (pay_Ufxf...), refund history table | PASS |
| D3 | Refund button on a fresh succeeded order actually fires refund-payment | PROVEN, twice, with network evidence. (1) Button on same-day order ORV-2026-08-0VMJF6: typed-confirmation flow fired refund-payment (200), processor refund FAILED because Braintree had not settled the transaction (see M4). (2) Button on ORV-2026-08-1JM6CG (about 16 hours old, settled, inside the window): refund-payment fired and SUCCEEDED, "Refunded. $100.00 has been returned to the customer, including $0.00 of tax.", history updated to refunded. The button wiring question from the refunds verdict is closed | PASS |
| D4 | Second refund attempt refused with a sane message | On the truly refunded order: HTTP 409 `already_refunded`, screen shows the server's sentence verbatim: "This order has already been refunded in full." On the failed-refund order: idempotent same answer, no second refund minted | PASS |
| D5 | The 24-hour window copy matches server behavior | There IS no user-visible window copy, by recorded owner decision (staff.html:314 comment; refund-payment header: Howard: "i can do that as a rule that i need to know"); server enforces REFUND_WINDOW_HOURS = 24 in functions/_shared/refund-rules.ts:75. No copy, so no mismatch. But the window COLLIDES with processor settlement: see defect M4 | PASS (with M4) |
| D6 | The two pre-existing em dash placeholders near staff.html lines 2132 and 2174 | Confirmed: exactly two em dashes in the file, `o.member_code || '—'` (line 2132) and the detail row fallback `'—'` (line 2174); the 2132 one was observed rendering live in the history table for guest orders | FINDING RECORDED (defect L1) |

### E. Content pages (comp-plan, conductor, faq, library, library-agent)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| E1 | Each page loads with a clean console | All five load and render; the only console errors are the pane's 403 blocks on the sanctioned third-party scripts (Botpress), an environment artifact, plus my own session's function-call noise carried in the tab buffer. No page-originated errors | PASS |
| E2 | Computed contrast sweep, worst five per page, fail below 4.5 to 1 | comp-plan: worst 5.61 (nav "soon" pill, legal line), 689 elements, ZERO below 4.5. conductor: worst 5.61, zero below. faq: all 39 answers expanded, worst 5.61, zero below. library-agent: worst 5.61, zero below. LIBRARY: FAIL, 22 text links at 1.84 to 1 (browser-default blue rgb(0,0,238) on the dark band): every agent and pack name in the grouped-items table (#groupRows inside section#groups) is a JS-injected `<a>` with no class, so the page's link styling never touches it | FAIL on library.html (defect H1) |
| E3 | Every internal link and anchor resolves | comp-plan: all 17 content anchors exist; conductor and faq anchor sets resolve; library's item links all target library-agent.html?sku=..., which renders per sku; nav targets exist in www\ | PASS |
| E4 | Terminology: Conductor consistent; PV expanded on first use per page | comp-plan (acronym key before first use), conductor (expanded at 2181 before first bare use), faq (expanded in the opening answer), library (expanded before first bare use): all correct; "Conductor" used consistently (57 uses on comp-plan alone). library-agent.html: the price cards say "100 PV A MONTH" and "1,000 PV ONCE" BEFORE the expansion sentence directly beneath them | FAIL, one page (defect L3) |
| E5 | No owner name in the five pages | Computed over rendered text on all five: no "Howard", no "Koziara" | PASS |
| E6 | comp-plan numbers match COMP-PLAN-SPEC.md v1.3 | Level rates 10, 5, 5, 3, 2 with per-level dollars 8.00, 4.00, 4.00, 2.40, 1.60 and the 20.00 ceiling ("25 percent of the volume, 20 percent of the price": both correct); CV = 80 percent; qualification 100.00; TV thresholds 2,500 / 10,000 / 40,000; paid depth 1 to 5 by rank; worked-example totals 114.00, 16.00, 130.00, 264.00 all present; Instant Payout stated four separate times as "approved, not built... Not one has ever been paid", exactly the spec's 5A.1 posture | PASS |
| E7 | No em or en dashes in the five pages | Unicode scan: zero occurrences in all five files | PASS |

### F. Documentation truth (new charter duty)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| F1 | TEST-CARDS.html claims match my own live results | Verified true: 4242 succeeds (ORV-2026-08-0VMJF6); the 2000.00 to 3000.00 amount rule declines ($2,646.00, ProcessorDeclined); expiry 01/29 accepted throughout; 4111 does reach a genuine requires_customer_action challenge state. NOT verifiable here: 1115's decline-after-approval and 4111's "then the payment succeeds" (the bank frame cannot render in this pane). THE CONTRADICTION: shop.html:1785 and staff.html:1697 were corrected this same morning against Braintree's published 3DS table and now teach 4000 0000 0000 2503 (passcode 1234), 2370, 2701, with an in-code note calling the old 4111 guidance a MISTAKE that "could never finish", while TEST-CARDS.html, rebuilt the same morning and cited by both pages as the full matrix, still headlines 4111 as "THE card for demonstrating the approval screen... then the payment succeeds" and claims "Every behaviour on this page was run end to end", though ROADMAP records that nobody has ever completed a challenge end to end. The instruction sheet and the pages it governs disagree about the single most demo-critical card | FAIL (defect H3) |
| F2 | ROADMAP's "Next small step" points at the real plan file | ROADMAP.md ends with "Execute the stabilization plan, docs\STABILIZATION-PLAN-2026-08-16.md"; the file exists at that path and is the plan of record | PASS |
| F3 | Stabilization plan Step 2 items each map to observed shipped state | Delivered and proven: extraction (A1, A2), staff finishing state (A3), six outcomes (A4), record-tax on staff (A5), poll-based reveal (A6), cached loading, cancel wiring, rejection handlers, escaping (A8), build stamps and lint (A10), raw-card-input removal (A11). Not delivered: guest half of N-H1 (A7), payment-link reconciliation (A9), N-M1 logging fix (A12). Also stale in-file claims found: staff.html:14 and :2020 still say the refund feature and screen are "PROPOSED, NOT DEPLOYED" while the engine is live and both-gates-passed (defect L4) | PASS (mapping done; misses graded in A) |

### G. Responsive spot check (mobile preset 375 x 812)

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| G1 | Shop checkout at mobile: touch targets adequate, no horizontal scroll | Document width exactly 375, no body horizontal scroll; pay button 293x73, delivery options 293x77 and larger, payment method buttons 141x43. Nav links are ~23 px tall, below the 44 px touch guideline (defect L5) | PASS |
| G2 | One content page at mobile: no horizontal scroll | comp-plan.html: document width 375; all 8 tables sit in .table-scroll wrappers with overflow-x auto, so wide tables scroll inside their own container | PASS |

### H. Accessibility beyond contrast

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| H1 | Focus trap in the challenge chrome cycles | Live against the real chrome: Tab moved ccCancel to the frame (the reveal sets tabindex -1 on it, the M6 fix), Tab again returned to ccCancel, Shift plus Tab reversed; every keydown defaultPrevented by the trap | PASS |
| H2 | Escape suppressed during a challenge | Escape defaultPrevented, chrome stayed open, focus unmoved | PASS |
| H3 | The finishing state does not strand focus | After cancel closed the chrome, focus landed on the live status element (where the outcome is written); after the decline reset, the pay button was re-enabled and reachable; the timeout path explicitly clears finishing so the check-again button cannot be hidden | PASS |

### I. Hygiene and the deploy gate

| # | Promise | Evidence | Verdict |
|---|---|---|---|
| I1 | No em or en dashes in the changed artifacts | payments.js and TEST-CARDS.html: zero; staff.html: exactly the two pre-existing placeholders (D6 / L1); shop.html and the five content pages: zero | PASS |
| I2 | Acronyms expanded on first use in changed artifacts | TEST-CARDS.html carries a full acronym key (3DS, PAN, CVV, plus a historical key); payments.js comments spell out Primary Account Number, Software Development Kit, and so on; content pages carry keys (library-agent ordering nit graded at E4) | PASS |
| I3 | No secrets, no Unicity terminology, no real personal data | The only keys in payments.js are the public anonymous key and flows using the publishable key, both public by design and already shipped; synthetic identities only (Jordan Avery, Kai Eastbrook); no Unicity terms in any graded artifact | PASS |
| I4 | Deploy gate honored: the graded work has NOT reached the live property | https://orvanna.io/js/payments.js answers 404 and the live shop.html contains zero payments.js references, so the extraction is not deployed; the gate obligation is open and this report is half of it | PASS |

Row tally: 40 graded rows, 32 PASS, 8 FAIL (A7, A9, A12, C4, C5, C7=F1, E2, E4), plus B6's bank click-through delegated to Howard.

## Defects

### HIGH

- **H1. Twenty-two unreadable links on library.html.** Every agent and pack name in
  the grouped-items table (tbody#groupRows, section#groups) renders at 1.84 to 1:
  they are JS-injected anchors with no class, so they fall back to browser-default
  link blue rgb(0,0,238) on the dark band. Computed, not eyeballed; worst on the
  page by a factor of three. This is exactly the washed-out class Howard caught on
  2026-08-14, now a permanent checklist row, and it fails it.
- **H2. The staff order lookup puts session words in the agent's mouth.** Reproduced
  live: with a challenge open for one payment, looking up an UNRELATED failed
  order returned "The cardholder finished their bank approval, and the payment was
  then declined by the card itself... The order lines are kept." Neither sentence
  is a fact about the looked-up order; both leak from the session (sawChallenge
  and the retry copy). staff.html:2000 feeds arbitrary receipts through
  engine.outcomeMessage, whose challenge branch reads session state
  (payments.js:886). The staff console's one hard rule is that the agent is never
  handed untrue approval words; this hands them exactly that. Fix shape: classify
  looked-up orders from the RECEIPT alone (a per-receipt sawChallenge override, or
  a lookup-specific message path).
- **H3. The challenge-card story is told two ways, one of them by the authoritative
  sheet.** shop.html:1785 and staff.html:1697, corrected THIS morning against
  Braintree's published 3DS table, teach 4000 0000 0000 2503 (passcode 1234),
  2370, and 2701, and the in-code note says the old 4111 recommendation "could
  never finish". docs\TEST-CARDS.html, rebuilt the SAME morning and cited by both
  pages as the full matrix, still headlines 4111 1111 1111 1111 as "THE card for
  demonstrating the approval screen... then the payment succeeds" and asserts
  "Every behaviour on this page was run end to end on the live rail", which
  ROADMAP itself contradicts (no challenge has ever been completed end to end by
  anyone). My live probes: 4111 genuinely parks at requires_customer_action, but
  its success leg is unproven and now disputed by the pages' own research. Howard
  demoing from TEST-CARDS will reach for 4111 at the exact moment the demo
  matters. One truth must win, on both surfaces and the sheet, and one completed
  challenge should settle it (see Howard's items).

### MEDIUM

- **M1. Guest checkout still implies the entered address prices the order (the
  guest half of N-H1).** The guest is told "Enter your billing address below"; the
  server prices tax from the house Illinois address regardless (HOUSE_TAX_ADDRESS
  in functions/_shared/tax.ts). Proven live: empty guest address, tax "calculated
  IL, US". The signed-in surface got the honest note; the guest surface got
  nothing. Scope follows capability: the note belongs on both.
- **M2. The payment-link copy still recommends a path the console cannot walk**
  (A9/C5): the rules list instructs "Send them a payment link and stay on the
  line" (staff.html:194), the disabled option wears a "recommended" chip
  (staff.html:202), and the panel opens with "Create the order, then send the
  caller a link" (staff.html:218), against the same panel's own "not available on
  this sandbox yet". Half-honest is still contradictory on a live console.
- **M3. Finding N-M1 is still open** (A12): every staff-auth refusal is audited as
  actor "anonymous" (functions/refund-payment/index.ts:511) and the auth result
  type has no username on the failure arm, so wrong-role and unknown-user
  refusals discard a signature-verified username. Explicitly kept "still owed" by
  Howard's addendum when the rotations were shelved.
- **M4. Same-day refunds fail against settlement, and the failure message
  contradicts itself.** A refund inside the 24 hour window on a payment Braintree
  has not yet settled fails at the processor; the screen then says "The processor
  has not settled this refund yet (failed). It will not be refunded twice." while
  the response body says settled true and status failed, and the confirmation box
  leaves both buttons disabled (agent stuck; Back to history is the only exit).
  Observed live on ORV-2026-08-0VMJF6; the same order's twin from yesterday
  (settled overnight, still inside 24 hours) refunded cleanly. The window and the
  processor's settlement clock overlap in a band of a few hours; the message
  should say "try again after the processor settles, usually overnight" rather
  than a sentence that reads as both failed and settled. (The 24 hour window as
  business policy is already on Howard's decision queue, item 9.)

### LOW

- **L1.** The two pre-existing em dash placeholders, staff.html lines 2132 and
  2174 (history member column and detail-row fallback); the 2132 one renders live
  for guest orders. Replace with "none" or similar (global no-dash rule).
- **L2.** Shop decline message says "Press Place order to try again" while the
  button at that moment reads "Continue to card details".
- **L3.** library-agent.html shows bare "PV" in the price cards ("100 PV A MONTH")
  before the expansion sentence right below them; first use must be the expanded
  form per the global rule.
- **L4.** Stale in-file status claims: staff.html:14 ("the whole refund feature is
  proposed and not deployed") and staff.html:2020 ("Added 2026-08-15. PROPOSED,
  NOT DEPLOYED") describe a refund rail that is live and both-gates-passed.
- **L5.** Mobile nav links are about 23 pixels tall, below the 44 pixel touch
  guideline (checkout controls themselves are all 43 pixels or larger).
- **L6.** payments.js comment on recordTax says it fires "deliberately AFTER the
  receipt renders", but handleReceipt calls recordTax() before hooks.onSuccess;
  fire-and-forget so behavior is fine, the comment is not.

## Items that need Howard's hands (none of mine can substitute)

1. **The one-minute challenge click-through, with the RIGHT card**: on the live
   page, run 4000 0000 0000 2503, expiry 01/29, passcode 1234 on the bank screen,
   and confirm the receipt; optionally also try 4111 1111 1111 1111 once to see
   whether its challenge can actually be finished. Whichever way it lands settles
   defect H3, and TEST-CARDS.html gets aligned to the winner.
2. **The decline card in a real browser**: 4000 1111 1111 1115 end to end (my
   environment could not render its bank frame; only the amount-rule decline was
   provable here).
3. **The settlement-window ruling** (M4, and decision-queue item 9): whether the
   refund guidance becomes "retry after settlement", the window moves, or the
   message simply tells the truth about timing.

## Verdict

**FAIL.** The engine extraction itself is genuinely good: one engine, both pages,
finishing state, six outcomes, record-tax, and the poll-based reveal all proven
live on the real rail, and the refund button question is closed with a real
succeeded refund. But the gate grades the delivery, not the effort: three HIGH
defects stand (unreadable library links, session words in the agent's mouth on
lookup, and a card instruction sheet that disagrees with the pages it governs),
and three Step 2 promises (guest address honesty, payment-link reconciliation,
N-M1) are not delivered. Per the deploy-gate rule, nothing here reaches the live
property until the HIGH defects are fixed and both gates pass on the exact
artifact being shipped. The single most important fix before deploy: make the
challenge-card story tell ONE truth across TEST-CARDS.html and both pages' hints,
proven by one completed challenge, because the payment flow is the product and
that sheet is the demo script.

---

# DELTA: the fix round re-graded, 2026-08-16 (afternoon)

Scope: commits d06468e ("Fix round: both gates' findings closed"), 7d57f43 ("The
challenge ending is proven: 2503 end-to-end verified"), and 3f8eb2e ("Failure
messages read as failures: red, at computed contrast"), graded against my eight
FAILED rows, the regression canary, and the owner's new red-failure request. Same
method as the main report: `www\` served locally, real Edge Functions, real
sandbox rail, everything computed. New sandbox traffic this round: one canary
order succeeded (ORV-2026-08-0YFX3K, $110.25), one amount-rule decline
(ORV-2026-08-0YLZB5, $2,646.00, ProcessorDeclined), one same-day refund attempt
on the canary order (refused unsettled, honest message), one challenge parked
and abandoned for the leak repro, and three signature-rotation orders from the
guest-to-member-to-guest swap test.

## Delta checklist

| # | Was | Re-check | Verdict |
|---|---|---|---|
| D-1 | HIGH 1: library links 1.84 to 1 | Computed independently in BOTH themes: dark, all 22 links exactly 9.57 to 1 (bold accent, underline); light (theme toggle, data-theme "light"), all 22 exactly 5.36 to 1. Hover (accent-soft wash composited over the panel): 8.22 to 1 dark, 4.80 to 1 light. Visited shares the same rule (`table a, table a:visited`), so no separate visited color exists to fail. Click-through: the Manager Agent link navigates to library-agent.html?sku=manager, which renders. The fix comment's own figures (9.57 / 5.36 / 8.21 / 4.81) match mine to rounding | PASS |
| D-2 | HIGH 2: lookup inherits challenge flavor | Exact original reproduction: staff session, live payment parked at requires_customer_action (card 2503), chrome open for ORV-2026-08-0Y9U5Q, then lookup of UNRELATED declined order ORV-2026-08-0VW854. Wording now: "Declined. The bank said: ProcessorDeclined." No approval sentence, no challenge flavor. The guard is engine-level (outcomeMessage consults sawChallenge only when the receipt's order_number equals the session's own order), so no future caller can reintroduce the leak. Shop lookup Check-again: looked up the in-flight order ORV-2026-08-0VYUP5, the resume view rendered, and the Check again click fired a real confirm-payment for the adopted order (it was a dead control before the fix). Residual, LOW: the decline tail "The order lines are kept; the caller can read a different card number" still reads session-ish on a looked-up order | PASS |
| D-3 | HIGH 3: two challenge-card truths | One truth now, in all three places, with per-claim evidence labels. TEST-CARDS.html: 2503 is the primary challenge card, END-TO-END VERIFIED with order ORV-2026-08-0XWV5X, which I independently confirmed server-side (succeeded, $110.25, shop channel); 4111 "also triggers a challenge, server-verified; its completed ending is likewise pending a human click-through"; 2370 and 2701 marked "Documented by Braintree; not yet run on this rail". No claim exceeds its evidence. shop.html and staff.html hints teach the same cards with the sandbox passcode (1234); the shop hint's history note even corrects its OWN earlier overclaim about 4111. Howard's-hands item 1 from the main report is closed by the owner's run | PASS |
| D-4 | MEDIUM M1: guest tax honesty | Delivered in three places and live-verified: the guest status line ("...tax on a guest order is priced from the demonstration tax address in Illinois, not from the address fields below"), the addressTaxNoteGuest hint under the fields, and the tax row hint ("estimate, from the demonstration tax address, Illinois"). Swap both directions: guest note up as guest; sign-in (GW-000002) drops it and raises the member note; switching back reverses both. The amount signature caught every switch: three fresh orders (0YF31L guest, 0YFM4R member at Florida tax, 0YFX3K guest back at Illinois 10.25 percent), no stale figure ever painted | PASS |
| D-5 | MEDIUM M2: payment-link copy | All three spots reworded: the rule now says "This sandbox cannot send a payment link yet, so stay on the line while they finish the approval on their own device"; the chip renders "not built yet" (verified in the live page); the panel line describes the path in the conditional and points at the keyed path. The old instructions survive only inside HTML comments documenting the fix | PASS |
| D-6 | MEDIUM M3 (N-M1): refusal logging | Implemented repo-side: StaffAuthResult's failure arm now carries verified_user for post-signature refusals (expired, unknown_user, wrong_role), and refund-payment audits `auth.verified_user ?? "anonymous"`. Both files mark it NOT YET DEPLOYED with the gate obligation on record, the correct posture under the deploy-gate rule. The screen makes no claim that depends on it (the browser-facing refusal message is unchanged), so nothing user-visible overstates the cloud state | PASS (deploy owes byte-compare) |
| D-7 | MEDIUM M4: same-day refund message | Reproduced live on the fresh canary order (succeeded minutes earlier, unsettled at Braintree): the refund attempt returned refund_status "failed", and the screen now says "The processor could not refund this payment because the payment has not settled on its side yet. Nothing was returned... Refunds work after the payment settles, usually overnight, so try this refund again later," with the decision-queue pointer, styled as a failure, and the Cancel button re-enabled (the box un-sticks). Server rules untouched | PASS |
| D-8 | LOW batch | staff.html em and en dashes: now ZERO in the file (both placeholders replaced). Mobile nav links: computed 24 pixels tall at the mobile preset, no horizontal scroll. library-agent.html: the first PV use now reads "200 PERSONAL VOLUME (PV) A MONTH" in the price card, expansion at first use. The decline message now names the button that exists: "Press Continue to card details to try again with a different card", live-verified in the decline run | PASS |
| D-9 | Regression canary: guest 4242 end to end | Full round on the fixed build: cart, guest, tax quoted before the card (Illinois 10.25 percent), order ORV-2026-08-0YFX3K opened, confirmed with 4242 on the rail, page resolved to ORDER PLACED with $100.00 + $10.25 = $110.25 exact, record-tax 200 fired. The passing rows keep passing | PASS |
| D-10 | NEW (owner request): failure messages read as failures | Commit 3f8eb2e. Live on the shop: a real ProcessorDeclined ending rendered the status line in rgb(252, 165, 165) with class pay-status-failure at a COMPUTED 10.35 to 1 on its band; the neutral status before the failure carried no red class, and a success clears the line entirely (the class toggles off with the message). Staff console: the same rule (.place-hint.pay-status-failure) computes the same red at 10.35 to 1 inside the status element's own container, and the neutral status stays grey; the class is set by the same shared engine path the shop's live decline just exercised. Note, LOW: by design the red covers engine-minted failure strings (the six endings plus loaderFailed); page-composed catch messages (network-failure strings) stay grey | PASS |

## Residuals carried forward (none blocking)

- LOW: the lookup decline tail "The order lines are kept..." on looked-up orders.
- LOW: page-composed network-error strings are not covered by the failure red.
- OBLIGATION: functions/_shared/staff-auth.ts and functions/refund-payment/index.ts
  are repo-ahead-of-cloud (N-M1); the deploy must carry them and byte-compare, per
  the standing rule both files now cite themselves.

## Delta verdict

**PASS.** All three HIGH defects are fixed and re-proven by the original
reproductions; all four MEDIUMs are closed (N-M1 correctly repo-side pending
deploy); the LOW batch is done; the canary passes; and the owner's red-failure
request is live on both surfaces at computed contrast. Rows re-graded: 10, all
PASS. From QA's half of the gate: **DEPLOY YES**, with the one condition already
on record: the deploy includes the two changed Edge Function files and is
byte-compared against the cloud.

---

# BRIDGE ROUND: the live shop-to-comp bridge, acceptance gate, 2026-08-16 (evening)

Scope: commit c37a5c1 ("The bridge is live"), migrations 019, 020, 021 applied
straight to production on Howard's explicit ruling. The verifier owns the
independent money recomputation (running concurrently); this gate grades the
member-facing surfaces, the staff console against a bridged order, and
documentation truth. Method note: the Browser pane refuses direct navigation to
the live https://orvanna.io origin, so the portal was graded by serving the
repo's `site\` pages locally against the SAME live database, which is faithful
for every question in scope because commit c37a5c1 touched ZERO page files (the
data is the only variable under test); the live /portal/ was separately
confirmed serving (HTTP 200). One new sandbox order was placed as the canary.

## Bridge checklist

| # | Check | Evidence | Verdict |
|---|---|---|---|
| BR-1 | Portal renders, picker works, finalized months UNCHANGED | Portal renders on live data behind the admin sign-in gate. Member picker: typeahead resolves and switches members. Spot-check against the INDEPENDENT pre-bridge references recorded in docs\qa\PHASE-45-QA.md (Supabase REST, 2026-08-14, period 2026-07-01): GW-000002 July SV 200.00 and statement 4,888.00, both identical today; GW-000014 July SV 50.00 and statement 0.00, both identical today, DESPITE GW-000014 carrying 600 of bridged August volume, so no leak into finalized display. Company tab: July run #12 payout 20,669.20, and the full finalized trend 11,906.00 / 13,434.00 / 14,636.00 / 16,507.20 / 17,749.20 / 20,669.20 exactly matches the ROADMAP finalized record. Consistent with the engineer's checksum proof; independently observed at the surface | PASS |
| BR-2 | No GW-000 house account on any member-visible surface | Picker search for "GW-000" returns ordinary members only (no house row); regex sweep for the bare house code (GW-000 followed by a non-digit) across My Business, My Volume, My Rank, My Statement, and Company rendered text: ZERO hits; Company still reads "of 1,000 accounts" (house invisible, matching the migration 020 verification that public views still return 1,000 members and one root) | PASS |
| BR-3 | August visibility honest | August is NOT shown anywhere: the period picker offers February through July 2026 only, so no surface displays bridged August volume and there is nothing to be dishonest about. Noted per the gate's instruction: absence is fine. When an August period first appears, its per-member figures must match the bridge record (GW-000003 900, GW-000014 600, GW-000001 300, GW-000002 200, plus anything bridged later) | PASS (noted) |
| BR-4 | Staff console vs a bridged order | Looked up bridged order ORV-2026-08-0W7UWR (GW-000002, staff console channel): renders fully and correctly (succeeded, $106.50, 100 PV, tax FL US $6.50, processor reference), refund history honestly empty, refund button offered with eligibility left to the server per the recorded owner decision. Nothing contradicts the bridge. Observation, not a defect: refunding a BRIDGED order now invokes decision 4.3 (remove rows and rerun before publication); the screen says nothing about that, consistent with its enforce-nothing design, and the policy covers it | PASS |
| BR-5a | Seven-decisions file exists and matches the rulings | docs\decisions\2026-08-16-bridge-seven-decisions.md: succeeded-only (4.4), creation month forever with refuse-and-report on published months plus the 021 trigger (4.5), packs one row with parent PV and never exploded (4.2, 4.6), refunds rerun-as-superseding-versioned-run after publication (4.3), one-time spread over ten months calendar-contained (4.1), unattributed volume to house GW-000 as bookkeeping never disbursement (4.7), each with Howard's quoted words where he supplied them, plus the straight-to-production ruling and the full apply/verify/idempotency/checksum outcome | PASS |
| BR-5b | The ANSWERED banners in DOCUMENTATION\09 | Seven ANSWERED banners (two dated 2026-08-15, five new dated 2026-08-16), each naming the chosen option consistently with the decision record | PASS |
| BR-5c | ROADMAP final next-step | "THE BRIDGE IS LIVE... 11 live orders bridged (2,000.00 Sales Volume, August 2026)... 1. END OF AUGUST, BY HAND: the first real commission run... 2. Then open the SUBSCRIPTION ENGINE". Matches reality and the decision record | PASS |
| BR-5d | No unqualified stale claims | TWO FOUND, one HIGH one MEDIUM, both in DOCUMENTATION (live pages are clean; grep of www\ and site\ found no stale bridge claims). See defects BR-H1 and BR-M1 | FAIL |
| BR-6 | Canary: fresh attributed payment lands succeeded | Staff order ORV-2026-08-1132GS for caller GW-000002, card 4242: confirmed server-side succeeded, $106.50, 100 PV, channel staff_console. On the record: this order is NOT yet bridged and will bridge on the next bridge run (end of August per the plan); the bridge was NOT run by QA | PASS |

## Defects

- **BR-H1 (HIGH, documentation truth).** DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md
  line 5 still reads "**Status:** design plus a dry run. **Nothing in here has
  been applied to production.**" and line 11 still says the bridge "does not
  exist". Both claims are FALSE as of this round: migrations 019, 020, 021 are
  applied to production and 11 orders are bridged, and this same round EDITED
  this same file (the ANSWERED banners) while leaving its header denying the
  whole thing. Per the charter, a false status claim in a document the round
  touched is a HIGH defect. Two-line fix.
- **BR-M1 (MEDIUM, documentation truth).** DOCUMENTATION\00-INDEX.md line 29
  still describes doc 09 as "The one missing connection: why no real purchase
  has ever paid a commission, the seven decisions Howard has to make, and a dry
  run of what today's real sales would pay." The connection exists, the seven
  decisions are made, and the dry run became a live commit. (The "never paid a
  commission" clause alone is technically true until the end-of-August run, but
  it stands unqualified inside a three-way-stale sentence.) One-line fix: real
  sales now feed the engine; the first commission run over them lands at the end
  of August.
- **BR-L1 (LOW).** www\comp-plan.html line 644 says the program is "a working
  prototype running on synthetic data". Since the bridge, August volume includes
  real test purchases, so "synthetic data" is now only mostly true; the
  sentence's real-money disclaimer ("No actual earnings... exist") remains
  accurate. Worth a clause when the page is next touched.

## Bridge round verdict

**FAIL, on documentation truth alone; every system surface passes.** The bridge
itself is clean at every surface this gate owns: finalized months render
byte-identical to the pre-bridge references, the house account is invisible
everywhere member-facing, August leaks nowhere, the staff console tells no lies
about a bridged order, and a fresh attributed canary landed succeeded and is
queued for the next bridge run. But the round's own edited documentation still
denies the round happened (BR-H1), and my charter makes that a HIGH defect that
blocks a PASS. Fix the doc 09 header and the index line (minutes of work), and
on re-inspection of those two files alone this verdict flips to PASS; nothing
else is owed from QA's half. The verifier's independent money recomputation is
the other half of the gate and is not graded here.

## Re-inspection, 2026-08-16 (later the same evening): VERDICT FLIPPED TO PASS

Commit 332eb80 fixed exactly the two files on the stated path, and only those:

- **BR-H1 CLOSED.** DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md now opens
  "**Status, corrected 2026-08-16:** **THE BRIDGE IS LIVE.**" with the decision
  record cited, migrations 019 to 021 named as applied, the bridged figures (11
  orders, 2,000.00 Sales Volume, 20 retained), the verifier verdict cited, and
  the original "design plus a dry run" line preserved as dated history rather
  than deleted. The body's old framing is now explicitly past-tense ("When this
  document was written... the bridge between them did not exist. As of
  2026-08-16 that gap is closed: real sales now feed the commission engine.").
  Documentation-truth check on the new claims themselves: the cited
  docs\verification\BRIDGE-LIVE-VERDICT-2026-08-16.md exists and reads "GATE:
  PASS... Zero findings at any severity", so no new claim exceeds its evidence.
- **BR-M1 CLOSED.** DOCUMENTATION\00-INDEX.md row 09 now reads "The connection
  that now exists... **LIVE as of 2026-08-16**: all seven of Howard's policy
  decisions ruled, migrations 019 to 021 applied, 11 real orders bridged into
  August, verifier gate PASS with zero findings. The first commission run over
  real volume happens at the end of August." Accurate on every clause.
- Hygiene on the two edited files: zero em or en dashes, acronyms carried by
  doc 09's existing key.
- **BR-L1 stands OPEN as LOW** by the coordinator's deliberate call (touching a
  live page reopens the deploy-gate cycle for one word); queued for the next
  content round. Non-blocking, on the record.

**BRIDGE ROUND FINAL VERDICT: PASS.** With the verifier's independent
recomputation already returned as GATE: PASS with zero findings, both halves of
the two-gate rule now pass on the live bridge.

---

# STATE PICKER DELTA: guest tax state picker, page mechanics, 2026-08-16 (midday)

Scope: commit 651ac49 ("Guest tax gets a state picker"), PAGE half only; the
verifier reads the server halves concurrently. NOT DEPLOYED: the live functions
still ignore guest_state, so every pick prices as Illinois on today's rail; this
gate grades the page mechanics now and marks the rate-truth rows pending the
function deploy. Method as before: `www\` served locally against the live
functions, fetch payloads captured per request, every paint of the three money
surfaces (tax row, total, pay button) logged with one timestamp by a mutation
observer so divergence between them is measurable, not eyeballed.

## State picker checklist

| # | Check | Evidence | Verdict |
|---|---|---|---|
| SP-1 | Howard's row, verbatim: "the tax should display correct before the user submits the payment" | Fresh guest checkout: the tax line rendered a real calculated figure ($10.25, "Tax calculated IL, US") before any card entry existed; before the first payment opened the button read "Continue to card details" and carried NO figure. Same-paint coherence: on the California flip, one paint at one timestamp moved tax row ($5.00), label ("estimate, for California"), total ($105.00), AND button ("Pay $105.00 now, test mode") together; the builder's syncPayButtonToDisplayedTotal is observably doing its job. Divergence hunt: a five-flip storm (NY, TX at +150 ms mid-debounce, NY at +300 ms, WA at +900 ms mid-quote, NY at +1200 ms) produced 10 paints and ZERO divergent paints (a paint where the button carries a figure not equal to the displayed total); the debounce collapsed the churn to three quotes total (IL, CA, NY; the TX and WA flips never wasted a call) and the staleness check let only the final state's answer paint. The pane offers no network throttling, so the mid-quote flip is the race that was testable; it held | PASS |
| SP-2 | Signature rotation on state change | State change after a payment opened discarded and reopened it every time: CA flip retired the IL order for fresh ORV-2026-08-17PT69; the flip storm produced exactly one further order, ORV-2026-08-17QKI3 (debounce, not one per flip). After each server answer the button label exactly matched the displayed total; DURING rotation the button correctly dropped to the no-figure "Continue to card details" rather than showing a stale amount | PASS |
| SP-3 | Signed-in behavior | Member sign-in (GW-000002): picker hidden, guest note down, member disclosure up, and the create-payment request carried guest_state EMPTY (captured: gs="" versus the guest's gs="NY"), so the hidden picker can never churn a member's signature; totals repriced from the member's stored address ("Tax calculated FL, US"). Sign-out to guest: picker back, guest copy back, member note down | PASS |
| SP-4 | Copy: three guest disclosures | All three name the picked state and the Illinois default, verified rendering: the account status ("Tax is calculated for the state you pick in the billing step, and it defaults to Illinois"), the address-panel guest note ("tax is calculated for the state you pick below, using a demonstration address in that state"), and the picker hint (which defers to the tax line as the truth: "the tax line above the total says which figure you are looking at"). Zero stale typed-address claims in the rendered page. ONE pre-deploy note, not a page defect: the picker hint's "the tax engine prices this order for that state" is true only once the functions deploy; until then the tax line's honest "calculated IL, US" breadcrumb is what keeps the surface truthful. Consequence recorded as the deploy condition below | PASS |
| SP-5 | Accessibility | Label "Tax state" wired via for=; select keyboard-focusable; #guestTaxState present in the engine's inertSelectors (the inert mechanism itself was live-proven in the main gate); computed text contrast 15.94 to 1 | PASS |
| SP-6 | Regression canary | Full guest 4242 checkout to ORDER PLACED: ORV-2026-08-17RXVM, $100.00 + $10.25 = $110.25 exact, record-tax 200 fired, and the receipt honestly names the jurisdiction that actually priced it ("Tax 10.25 PERCENT, IL, US") even though New York was picked, which is the correct pre-deploy truth-telling | PASS |

## Post-deploy rows, PENDING (re-run after the function deploy)

Updated per the coordinator mid-gate: Howard has enabled ALL 50 state
registrations in the Stripe Tax dashboard. Therefore, post-deploy:

- PD-1: per-state rates actually differ on the live rail (New York about 8.875
  percent with the New York City demonstration address, California 9.75, and
  Texas, Florida, Washington, Colorado all nonzero), and the quoted figure, the
  charged figure, and the receipt agree per state.
- PD-2: the ONLY zero reachable from the picker is Oregon, zero because no
  state sales tax exists there, with its reason carried; the wording for that
  zero gets graded against what Stripe ACTUALLY returns for a no-sales-tax
  state (the "not collected, unregistered" wording path should now be
  unreachable from the picker). ANY zero on a non-Oregon pick post-deploy is a
  DEFECT (registration lag or a wrong canned address), not expected behavior.
- PD-3: SP-1 and SP-2 sanity re-run with genuinely differing amounts, so the
  button flip is exercised by real money movement, not only by the estimate
  phase.

## State picker delta verdict

**PASS on the page mechanics; DEPLOY YES from QA's half, with one condition:**
the page and the functions must ship TOGETHER. The functions alone are harmless;
the page alone would let the picker promise per-state pricing the live rail does
not perform (SP-4's note). After that deploy, the three PD rows above re-run as
a short delta before this feature is called done.

## Post-deploy rows, RUN, 2026-08-16 (afternoon, after the atomic deploy)

Deploy graded: quote-tax v2 and create-payment v8 (byte-compared, per the
deploy record in PICKER-VERDICT-2026-08-16.md, commit 8fb24da) plus the dist
(commit b651cd9). The live origin serves the picker markup (verified: 16
guestTaxState references in https://orvanna.io/shop.html, HTTP 200); the pane
still refuses to render the live origin directly, so the rows were driven from
the repo pages against the DEPLOYED functions, which is the same server truth.
All figures below are the deployed functions' own responses, captured per
request.

| # | Check | Evidence | Verdict |
|---|---|---|---|
| PD-1 | Per-state rates genuinely differ; quote, charge, and receipt agree | On a $100.00 cart the deployed rail returned four distinct nonzero rates: Illinois 1025 cents (10.25 percent, the default), New York 888 (8.88 percent), California 875 (8.75 percent), Texas 800 (8.00 percent). The two figures the deploy engineer's server probes vouched for (NY 888 on 10000, IL fallback 1025) both reproduced exactly from the page. Each flip repainted label ("Tax calculated NY, US" and so on), row, total, and button together; 41 paints logged across the whole session, ZERO divergent (button never carried a figure different from the displayed total) | PASS |
| PD-2 | The Oregon zero, graded against what Stripe actually returns | Captured verbatim from both deployed functions: tax_cents 0, tax_jurisdiction "OR, US", tax_source "stripe_tax", tax_reason "not_subject_to_tax" (exactly the deploy probe's string). The page painted "Tax none due OR, US", total $100.00, button "Pay $100.00 now, test mode". "None due" is the honest sentence for a no-sales-tax state, and the misleading alternative ("not collected", the unregistered wording) was not painted and is now unreachable from the picker. No non-Oregon pick returned zero | PASS |
| PD-3 | Flip and rotation sanity with real money movement, charged on the live rail | The flips moved real amounts ($110.25 IL, $108.88 NY, $108.75 CA, $108.00 TX, $100.00 OR, back to $108.88 NY), each settled flip discarding and reopening the payment with a fresh order id and a button label matching the new displayed total. The loop was then closed with money: order ORV-2026-08-18MYJY, quoted 888/10888 for New York, CHARGED at the processor for exactly 10888 cents (succeeded), and receipted as "Tax 8.88 PERCENT, NY, US, $8.88, Order total $108.88" with record-tax fired. Quote equals charge equals receipt, to the cent, on a non-default state | PASS |

## Final feature verdict: the guest tax state picker

**PASS, feature complete.** Page mechanics passed pre-deploy (SP-1 to SP-6),
the atomic deploy condition was honored (functions and dist together,
byte-compared), and all three post-deploy rows now pass on the deployed rail
with real charged money. Howard's acceptance sentence is met as stated: the tax
displays correct, for the picked state, before the shopper submits the payment,
and the figure quoted is the figure charged and the figure receipted. Nothing
further is owed from QA's half on this feature.

## Incident, 2026-08-16: Howard's discoverability catch, and the permanent row it becomes

Howard found, on the live site, a defect every picker row above passed: at
checkout step 1 as a guest, the summary asserts "Tax calculated IL, US" with a
figure while the state picker sits hidden below the not-yet-completed account
step. The jurisdiction is stated as settled fact before the control that
changes it is discoverable. My rows graded the LETTER of the acceptance
sentence (the tax displays, correct, before submit) and never asked whether
the choice behind the figure was discoverable at the moment the figure first
appeared.

Per the standing rule (Howard's catches become checklist rows), the row that
should have caught this now exists permanently in the charter
(`.claude\agents\mlm-qa.md`, amended in this same commit):

> ANY USER-CHANGEABLE INPUT THAT AFFECTS A DISPLAYED PRICE MUST BE VISIBLE AT
> OR BEFORE THE FIRST DISPLAY OF THAT PRICE, ON EVERY STEP WHERE THE PRICE
> SHOWS. Companion wording row: while such an input still holds its default,
> any price label derived from it must read as a CHANGEABLE DEFAULT, not a
> settled fact.

The site-builder is moving the state control to the tax row in the summary;
when that commit lands, the placement re-grades against this row, including
the label-wording half (unpicked must read as a changeable default).

---

# DISCOVERABILITY DELTA PLUS THE OUTAGE-WINDOW COMMITS, 2026-08-16 (afternoon)

Scope grew mid-delta: an account spend-limit outage interrupted QA at the start
of the c66608a re-grade, and during the outage a separate session working with
Howard landed TEN ungated commits on main (0367407 through 14b6cc7, documented
in CLAUDE_NOTES.md) that SUPERSEDED c66608a's placement: the billing
State/region dropdown is now the tax control, tax is HELD until the address is
known, a currency selector (USD, GBP, EUR, CHF) joined the summary, a staged
page-owned Plaid sandbox panel arrived, Braintree wallet methods were enabled,
and the summary went sticky with layering fixes. Everything below is graded on
HEAD, the artifact that would actually ship. Method as always: local serve
against live functions, every request captured, every paint of the money
surfaces logged, contrast computed.

Deploy-gate note, on the record: those ten commits reached main with no gate.
They have NOT reached the live property; this delta is the QA half of their
gate (the verifier read the server halves concurrently), which restores the
standing rule before any deploy.

## Scope A: the discoverability rows (graded on HEAD)

| # | Check | Evidence | Verdict |
|---|---|---|---|
| A-1 | Permanent row: price-affecting input visible at or before the price's first display | HEAD fixes Howard's catch by WITHHOLDING the figure rather than moving the picker: at checkout step 1 the tax row reads "Tax after account and billing address" with NO amount and NO jurisdiction, and the total shown ($100.00) is the pre-tax figure whose controls (cart quantity, activation, currency) are all visible in the summary. As guest, the row reads "Tax enter State/region and postal code" until BOTH visible fields are filled; only then does a figure appear ("Tax calculated CA, US", $8.75 exact for 94105). No price is ever asserted while the input that moves it is off screen | PASS |
| A-2 | Companion wording: unfilled default reads as changeable, never settled fact | The pending labels are instructions pointing at visible controls, not facts; no jurisdiction is named before the shopper supplies one. (c66608a's "Illinois, the default, change below" wording was superseded by this stronger shape: no default figure is shown at all) | PASS |
| A-3 | Sign-in refusals hand the shopper a path, through to a mounted card form | All three refusal paths live-driven: wrong password ("That username and password do not match a demonstration account."), unknown code (same), and the staff credential, which gets its own honest sentence ("That is a staff or administrator account. Use a member code here, or continue as a guest."). Every one shows the inline "Continue as guest instead" button; clicking it landed in guest mode, and after State plus ZIP the payment opened (fresh order ORV-2026-08-1KL28V, TX $108.00) with the provider widget MOUNTED (iframe and all three SDK elements present). The dead end Howard hit ("the card input is not opening") is gone | PASS |
| A-4 | Referral-code decoration suppression | Moot by architecture on HEAD: the client-side state decoration no longer exists; only server truth is painted as "calculated". Live probe: guest with TX in the billing field plus referring code GW-000002 typed was priced by the server from the REFERRED member's stored Florida address and the row honestly said "Tax calculated FL, US" ($6.50). LOW note L-D1: in that referral case the guest hint still says tax comes "from the State/ZIP entered above", which is briefly untrue; one clause would fix it | PASS |
| A-5 | Lockstep regression flip | CA to NY after the payment opened: order rotated (ORV-2026-08-1KIMGJ to ORV-2026-08-1KJ7M4), NY answered 888 exactly, and the paint log recorded ZERO divergent paints (button never carried a figure different from the displayed total) | PASS |

## Scope B: the outage-window commits

| # | Check | Evidence | Verdict |
|---|---|---|---|
| B-1 | Plaid panel demo framing honest | The full wizard was walked end to end (institution, sign-in with any test credentials plus consent box, account choice, authorize) and fired ZERO network calls at every step, verified per step: no real Plaid Link, no bank, no payment anywhere. Panel is labeled "PLAID SANDBOX", status "Sandbox preview", shows the summary's exact total (GBP 82.95) and country GB. DEFECT M-O1 on the ENDING: authorizing renders a full "ORDER PLACED" receipt with a page-minted order number in the REAL order namespace (ORV-2026-08-0Z6SG7) that no server knows (the staff console would answer "no order with that number exists"), carrying one honest sentence ("This preview placed a demo order and did not create a real Open Banking payment or charge real money") directly followed by one FALSE sentence ("This payment ran through the Orvanna orchestration layer in test mode"), which is boilerplate from the real receipt path; nothing ran through anything, zero calls | PASS with M-O1 |
| B-2 | Currency staging can never reach a USD charge mismatch | Every guard CLAUDE_NOTES claims was verified live: switching to GBP fired ZERO server calls (the client block on non-USD live quotes holds, so the old deployed function cannot overwrite the local estimate); the row is labeled "estimate, for GB SW1A 2AA", never "calculated"; the open USD payment was DISCARDED on the switch (mount gone, chip gone); the pay button relabels "Card checkout is USD only" and clicking it fires nothing and explains honestly ("live card settlement is still guarded to USD until the order records store currency. Nothing was charged"). LOW L-O2: the currency choice persists in localStorage across visits and the page accepts a US state under GBP, painting a mixed "estimate, for California" in GBP; display-only incoherence, every money guard still held | PASS with L-O2 |
| B-3 | Wallet methods work or are honestly framed | Google Pay (and PayPal, same allow list) selected under USD: a REAL create-payment opened (ORV-2026-08-1KSKEC, CA $108.75) and the secure widget mounted; the wallet path is real wiring, not a mock, and the on-page notes say exactly what runs where. Apple Pay: disabled with the honest reason (Braintree domain setup pending). USD bank tile: disabled with the honest ACH explanation, matching the notes' follow-up correction. The wallet sheets themselves cannot render in this pane; their click-through is the standing Howard item for any wallet demo | PASS |
| B-4 | Sticky summary layering | Live with a real challenge parked (2503): body.payment-in-flight class applied, finishing status area computes z-index 25 and the sticky summary z-index 1 (commit 0367407's exact contract), challenge chrome at the clamped maximum and last in body. The pixel probe was void this round (the pane reported a zero-height viewport at that moment); the computed stack is decisive and the chrome mechanism itself carries the main gate's earlier elementFromPoint proof | PASS |
| B-5 | Standing rows: contrast, hygiene, owner name | Hygiene: zero em or en dashes and zero owner-name hits in shop.html, shop.css, payments.js at HEAD. Contrast sweep of the reworked checkout: DEFECT M-O3, the PayPal tile's wordmark spans render PayPal's light-background brand navy on the dark tile, computing 1.04 to 1 ("Pay") and 3.71 to 1 ("Pal"): the mark is the tile's only label and its first half is invisible (the logotype exemption keeps this out of HIGH; the dark-background variant of the mark is the fix). LOW L-O4: the ~50 option elements of the new State/region and currency selects compute mid-grey 109,109,109, below 4.5 against either plausible popup background; the closed select text itself passes at 15.94. Nothing else below the floor | PASS with M-O3, L-O4 |

## Defects (this delta)

- **M-O1 (MEDIUM).** The Plaid sandbox ending fabricates a receipt in the real
  order namespace and keeps one false boilerplate sentence. Two one-line fixes:
  give demo-only orders a visibly different number shape (not ORV-), and drop or
  condition the "ran through the Orvanna orchestration layer" line on the Plaid
  path. The honest sentence already present should be the only story.
- **M-O3 (MEDIUM).** PayPal wordmark tile: brand navy on the dark tile computes
  1.04 to 1; use the wordmark's dark-background variant.
- **L-D1 (LOW).** Guest hint wording is untrue while a referring member code is
  typed (server prices the referred member's stored address).
- **L-O2 (LOW).** Persisted currency accepts a US state under GBP and paints a
  mixed estimate; money guards hold throughout.
- **L-O4 (LOW).** Select option color below the floor on either plausible
  popup background.

## Delta verdict

**PASS with two MEDIUM and three LOW defects; zero HIGH. Deploy YES from QA's
half**, on these terms: the ten outage commits are hereby gated on the QA side
(the verifier's concurrent server-half read completes the pair per the standing
rule); the current HEAD is safe to deploy as-is because every money guard held
under adversarial driving (non-USD cannot quote live, cannot open a payment,
and cannot leave a stale payment behind; Plaid fires no network call at any
step). M-O1 and M-O3 are queued fixes, both one-liners, neither blocking by the
severity ladder; fixing M-O1 before the next deploy is RECOMMENDED because a
fabricated ORV- number on a receipt is the kind of thing Howard's next live
walk will catch. Howard's permanent discoverability row is graded and holds on
HEAD's stronger fix: no price is asserted before its controls are on screen.
