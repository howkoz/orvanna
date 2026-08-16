# Verification Verdict: the 2026-08-16 stabilization work, pre-deploy gate

Verifier: mlm-verifier, run 2026-08-16. Scope: commits 1b5b961 through 873ab2d,
not yet deployed. Artifacts: the shared payment engine `www\js\payments.js`, the
refactored `www\shop.html` and `www\staff.html`, `deploy\build_dist.py` and its
new gates, `docs\TEST-CARDS.html`, the truth-reset document edits (ROADMAP.md,
migration 018 rename, 023 pointer, DOCUMENTATION 01, 02, 06, 09, 11), and the
charter edits under `.claude\agents\`. Per charter: I grade, I fix nothing. The
Browser pane belonged to the quality assurance (QA) agent throughout; every live
probe below was made from the command line.

## GATE: PASS

Zero HIGH findings. Three MEDIUM, three LOW. The engine extraction is sound: the
amount-signature architecture holds at every path I could trace to the money, the
challenge-reveal poll is proven to work against the live sandbox (it is not
silently riding its fallback timer), the build gates all pass and one was
negative-tested, all five truth-reset spot-audits verified against primary
sources including the live migration ledger, and no Edge Function source changed
in the range, so no deploy drift question opens.

The PASS carries one loud condition: finding M1 must be reconciled before or
immediately after deploy, because the property currently ships two contradictory
truths about its own test cards, and the contradiction sits in the exact class of
defect the truth reset existed to end. M1 escalates to HIGH if the interactive
click-through (QA or Howard) shows either recommended card failing its promised
ending.

## Findings

### MEDIUM

**M1. The pages and the test-card document contradict each other on the demo's
most-used fact, and I proved half of the contradiction wrong against the live
rail.**
- `docs\TEST-CARDS.html` (rewritten this range, commit 82ad3d0 "test cards tell
  the truth") says card 4111 1111 1111 1111 is THE challenge card on the current
  Braintree rail, "verified 2026-08-15 on the live rail, not copied from a
  vendor page", and never mentions 2503, 2370, or 2701.
- `www\shop.html` (card hint, around line 1786) and `www\staff.html` (status
  text, around line 1697) tell every shopper and agent to use 4000 0000 0000
  2503, 2370, and 2701, and the shop's comment states "4111 1111 1111 1111 is
  not a 3-D Secure test card at all", attributing the claim to Braintree's
  published table.
- Timeline from git: ROADMAP's verified-cards block landed 08-15 12:18 (commit
  0a05221, 4111 verified challenging live); the pages' 2503 rewrite landed 26
  minutes later (commit f036027, 12:44) sourced from a published table; today's
  TEST-CARDS rewrite realigned the document to the 12:18 story while the pages
  kept the 12:44 story. ROADMAP never mentions 2503 anywhere in its history.
- My live probes today (sanctioned test-rail writes, details in the probe log
  below): BOTH cards park at `requires_customer_action` with a `next_action` of
  `redirect_inside_popup` on confirm. So the comment's claim that 4111 raises no
  challenge is false on today's rail, and the 2503 hint is at least half true
  (the challenge does appear).
- What nobody has on record: either card COMPLETING its challenge on the
  Braintree rail. ROADMAP itself says the 08-15 verification payment "was left
  parked at requires_customer_action". So TEST-CARDS' banner "every behaviour on
  this page was run end to end" overclaims for the "then the payment succeeds"
  halves, and the pages' "passcode 1234 and then approves" claim for 2503 has no
  recorded run at all. One reconciliation click-through, then align all three
  surfaces (pages, TEST-CARDS, ROADMAP) to whatever it shows.

**M2. The shop's manual payment-open path never records the amount signature,
and the safety re-check then destroys and recreates its own payment.**
`www\staff.html` records the opening signature (line 1675,
`engine.setOpenedFor(openingSignature)`); `www\shop.html`'s `liveStart` (lines
1723 to 1768) never does. The auto-open path sets it before calling `liveStart`
(line 1677), but the manual path in `liveSubmit` (line 1717) calls `liveStart`
bare. Reachable case: any decline runs `resetPayment`, which nulls the recorded
signature; the shopper presses the button to retry; the payment opens; the
trailing `liveEnsureCheckout` at the end of `liveMountCheckout` (line 1839, the
H1 re-check from the 2026-08-15 audit) compares a null recorded signature
against the live one, mismatches, and 900 milliseconds later discards the
payment it just opened and creates a second one. Consequences per retry: a
duplicate order row in the demo ledger, one extra token of the five-creates-a-
minute rate limit, and the secure card form wiped while the shopper may already
be typing into it. No amount wrongness: the discarded payment is discarded, and
the server reprices the replacement. Fix is one line in `liveStart`, mirroring
the staff page.

**M3. The staff order lookup can dress an unrelated order's decline in
challenge wording taken from the current session.** The engine's six-ending
builder reads `state.sawChallenge` when a receipt carries no authentication
fields (`payments.js` line 886), which is correct for the session's own
payment. The shop's lookup knows this and clears the flag before rendering a
looked-up order (`shop.html` line 2188). The staff lookup does not:
`runStaffLookup` (`staff.html` line 2000) passes any looked-up failed order to
`engine.outcomeMessage` with the flag as-is. Reachable case: an attempt that
raised a bank approval and then timed out leaves `checkOnly` true and
`sawChallenge` true with all controls re-enabled; the agent looks up a
DIFFERENT caller's failed order; if that receipt is old-shape (no
authentication object, no reason), the agent reads out "The cardholder finished
their bank approval, and the payment was then declined by the card itself"
about an order that never saw an approval screen. This is the exact probe the
extraction agent flagged for this gate. Fix mirrors the shop's one line.

### LOW

**L1.** `www\staff.html` line 470 keeps a private `esc` helper byte-identical to
`OrvannaPayments.esc` instead of aliasing the engine's copy the way the shop
does (`shop.html` line 1411). Harmless today, drift risk tomorrow, and the one
duplicate definition the orphan sweep found.

**L2.** In the shop's lookup flow, looking up an order that is still in flight
renders the "Check again" button (`resumeApply`, line 2106) without setting
`liveState.orderNumber`, and the button's click handler (line 2153) silently
returns when that field is empty. A dead control in the recovery flow; the
shopper can still re-run the lookup itself.

**L3.** `payments.js` `closeChallengeChrome` (lines 605 to 611): when focus is
successfully returned to the control it came from, the function returns early
and the page's `onChallengeClose` hook never fires. On the shop that hook
re-shows the payment area; in the early-return case the area was already
visible, so the miss is cosmetic, but the hook contract ("fires on close") is
not what the code does.

**Reported, not counted against this gate (per the coordinator's briefing,
separately graded):** the two pre-existing em-dash placeholder glyphs in the
staff refund screen, `staff.html` lines 2132 and 2174, are still present.

## What was verified sound (the positives, with evidence)

**1. Server-totals authority and the amount signature (charter item a).** No
path reaches confirm with a stale amount. Both pages carry the last guard
directly in front of `confirmPayment` (shop 1858, staff 1739): a signature
mismatch discards the payment instead of charging it. Every amount-moving
control is in the inert lockdown while a payment is in flight (real `disabled`,
not styling). Quote answers are stamped with the signature they were asked
under and dropped when stale (`payments.js` 392); server totals are stamped at
open (staff 1682, engine 291); `applyServerTotals` is the only place a
calculated figure reaches a page; both pay buttons quote the server figure
when one exists. The one wrinkle in this machinery is M2, which destroys a
CORRECT payment, never keeps a stale one.

**2. The challenge-reveal poll (charter item b), proven live.** The exact call
`payments.js` makes (GET `https://sandbox.hyperswitch.io/payments/{id}` with
the publishable key in `api-key` and the payment's client secret as a query
parameter) returned HTTP 200 with a readable `status` field against a real
payment. Controls: unknown payment identifier gives 404 (not 401, so
publishable-key auth is genuinely accepted); wrong client secret gives 400;
missing key gives 400. The 1400 millisecond timer is therefore genuinely the
poll-error fallback, not the silent carrier of the feature, and the 10 second
hard cap prevents a real challenge from being trapped invisible. No finding.

**3. Rejection handlers (charter item d).** Every promise chain was traced to a
terminus that clears busy state: `liveStart` and `liveStaffStart` catches, the
validation and hand-over branches of both `AfterSdk` functions, both pages'
`onCheckError` hooks, the engine's timeout branch, `resumeConfirm` and
`abandonAttempt` catches, the quote catch, and `recordTax`'s try/catch. The
engine's `pollReceipt` always lands in `onCheckError` on failure (audit finding
A2 honored).

**4. Page wiring (charter item 2).** Grep sweep over roughly forty
engine-owned symbols: zero orphan references, zero duplicate definitions except
L1. Both script tags carry `?v=5.2` stamps in source and receive content-hash
stamps in the build. `js/catalog.js` untouched in this range (last change
93c826c, before the range).

**5. The build (charter item 3).** `py MLM-PILOT\deploy\build_dist.py` exits 0:
stamp `?v=89beb088fc37` applied to 23 references and added to 28 bare Scalable
Vector Graphics references, stamp assertion passes, name lint passes, secret
scan passes, 34 files. Dist-versus-source: `js/payments.js` is byte-identical
modulo stamps; `shop.html` identical modulo stamps; `staff.html` identical
modulo stamps plus the one declared portal-link rewrite (`../site/index.html`
to `portal/index.html`), which is the build's documented job. Negative test:
`name_lint` pointed at a scratch folder containing a planted owner-name leak
correctly failed the build with exit 1.

**6. Truth reset spot-audit (charter item 4), five of five verified against
primary sources.**
- Migration 018 header: claims live ledger version 20260816000812 named
  `tax_integrity_hardening`. Read back from the production
  `supabase_migrations.schema_migrations` table: exact match.
- 023 pointer: claims versions 20260816011917 (`refunds_022`) and
  20260816012057 (`refund_guard_fix_023`) in the live ledger: both exact
  matches. Claims the folded-in fix is marked "around line 199" of
  `022_refunds.sql`: the marker comment is at exactly line 199.
- ROADMAP's corrected gate-history block: claims both 2026-08-15 full audits
  returned FAIL. `docs\qa\FULL-AUDIT-2026-08-15.md` reads "Verdict: FAIL";
  `docs\verification\FULL-AUDIT-2026-08-15.md` reads "GATE VERDICT: FAIL",
  four HIGH. Match.
- DOCUMENTATION 06 bridge row: claims GATE: FAIL on two HIGH narrative errors
  with the money arithmetic passing. `BRIDGE-DRY-RUN-VERDICT.md` reads "GATE:
  FAIL", "documentation-correction FAIL", claims 3 and 4 recomputed PASS to
  the cent. Match.
- DOCUMENTATION 09 hash correction: I recomputed the Secure Hash Algorithm
  256-bit (SHA-256) digest of `019_shop_to_comp_bridge.sql` myself:
  `cf8c9f15d182edd73c0f3dc4e05ce58b45fb9387aaa500a19a62054e51cb8439`, matching
  the document's `cf8c9f15...` claim; the graded-file hash `ce919b36...` it
  cites is recorded verbatim in `BRIDGE-DRY-RUN-VERDICT.md` line 37. Match.

**7. Live posture unchanged (charter item 5).** `git diff --name-only
1b5b961^..873ab2d` touches nothing under `functions\` or `_shared\`; the last
commit to touch `MLM-PILOT\functions` is 2f45c77, before this range. No deploy
drift question opens from this work.

**8. Guardrails (charter item 6).** No em or en dashes in `payments.js`,
`shop.html`, or `TEST-CARDS.html`; the two in `staff.html` are the known
pre-existing pair reported above. Acronyms expanded in user-facing copy:
Personal Volume (PV) at `shop.html` line 54, Personal Volume and Sales Volume
(SV) at `staff.html` line 98, and TEST-CARDS carries a full acronym key (3-D
Secure, Primary Account Number, Card Verification Value, Access Control
Server, Bank Identification Number). Zero Unicity terminology in the graded
artifacts. Owner name absent outside the allowlist, now enforced by the build
lint and negative-tested. The charter edits themselves (deploy-gate rule in
both gate charters, documentation-truth checklist row in QA's) are consistent
with each other and with this run's scope.

## Probe log, side effects disclosed

Sanctioned test-rail writes (fake money, sandbox, per charter and coordinator
briefing): three orders created through the live `create-payment` Edge Function
with Origin `https://orvanna.io` (one response discarded to a transcription
error, then ORV-2026-08-0V992A and ORV-2026-08-0VETBW). The latter two were
confirmed server-side with cards 4111 1111 1111 1111 and 4000 0000 0000 2503
respectively to settle M1; both parked at `requires_customer_action` and were
left there, which is the state the abandoned-order sweep exists to collect.
One read-only Structured Query Language query was run against the production
migration ledger. Nothing else was written anywhere.

## SHA-256 of the graded artifacts

| Artifact | SHA-256 |
| --- | --- |
| `MLM-PILOT\www\js\payments.js` | `2d8e405391ab51d32d9f0c18352622c98856c5ddcd3596fe171f278f455abc09` |
| `MLM-PILOT\www\shop.html` | `7b3860bdc33dad471a41efbb5defc61487d393d37db31a1003e2f09dfef6abd0` |
| `MLM-PILOT\www\staff.html` | `af8c7e810bb015b10c498b297f038fad2525bd706227fede9ff05f8dc50bdcd6` |
| `MLM-PILOT\deploy\build_dist.py` | `248798e028eb0c5ee7d6c57aa1ccbd14a70494e1e8423ca6baab19a93fd746e7` |
| `MLM-PILOT\docs\TEST-CARDS.html` | `6df4058d904773525f8598b79e1e5bfacf576012c9c93398c24f64044549fbae` |
| `MLM-PILOT\ROADMAP.md` | `967ebbe113b0e0a1f1182edebbf370106de1fd7c1fbe146cc55797cb4b2ef9ab` |
| `MLM-PILOT\db\migrations\018_tax_integrity_hardening.sql` | `97a1eeba59e8dce3148882c6e2d9f45ff2e352ee5943a4968a5632dc12f0ed34` |
| `MLM-PILOT\db\migrations\023_refund_guard_fix_POINTER.md` | `b1646cbdc62cffa672f4b67bb9446fd060332a6eb1ea0c76f45bd0ee9337d153` |
| `DOCUMENTATION\01-ARCHITECTURE.md` | `de9b1e0951cfd5f8aff13168beba1b96e2a5f48334d48a00ce30755cfa01f47b` |
| `DOCUMENTATION\02-DATA-MODEL.md` | `d2c16d2c0a59b42b68fef92d17f379673ed0494dac7883942cadf9f98fe6c6aa` |
| `DOCUMENTATION\06-QA-AND-VERIFICATION.md` | `2c2f9210afb79b5d00ed51794e9c83b5c5ece67c81faa2cc44d30467398ee3f9` |
| `DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md` | `cb04af94964785aa60e03c9fcea8becde85e856fb907ba6a15d68b6469db35ad` |
| `DOCUMENTATION\11-REFUNDS.md` | `715100ca6a3fdae2053d3b2921c2e703377c8b5f9d5db8a3482949583d0d72e7` |
| `.claude\agents\mlm-verifier.md` | `38ee5666abc5a7b026b3dd164ddc07df1d605445fa2d76fcd26fd3f213a021ca` |
| `.claude\agents\mlm-qa.md` | `aef5bea055bcece44371c300380f11a5cd78d5b261f81848e6dd26720c5c0afd` |

## What I did NOT probe

- The interactive challenge click-through: completing either card's bank
  approval screen (the passcode-1234 claim for 2503, the approval ending for
  4111). Belongs to QA and Howard; it is also the probe that settles M1.
- Byte-comparison of the DEPLOYED Edge Functions against the repo: not
  triggered, since nothing under `functions\` changed in this range; the
  standing live-rail duty next fires when one does.
- The resume flows in a real browser (storage across a genuine bank redirect,
  new-tab return): traced by reading only.
- The `record-tax` bookkeeping call actually firing on a success: traced by
  reading only; no successful payment was completed in this run.
- The Botpress third-party script contents, and the HyperLoader script body.
- The five agent charters I did not quote (architect, comp engineer, database
  engineer, site builder, designer, writer): diffed for scope, not graded line
  by line.
