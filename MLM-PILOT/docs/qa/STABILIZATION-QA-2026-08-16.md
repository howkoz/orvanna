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
