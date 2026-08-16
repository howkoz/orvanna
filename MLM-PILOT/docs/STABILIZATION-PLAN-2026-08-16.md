# Orvanna Stabilization Plan

Written 2026-08-16 by Fable (Chief Information Officer), after a four-track audit of the whole
project: front-end payment drift, server and database state, gate coverage, and the team
charters. Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\STABILIZATION-PLAN-2026-08-16.md`

Purpose: fix, resolve, and stabilize everything now open so the SUBSCRIPTION ENGINE starts on
clean ground instead of on top of accumulated drift.

Acronym key: QA = Quality Assurance. 3DS = 3-D Secure (the bank card authentication step).
PV = Personal Volume. SV = Sales Volume. CDN = Content Delivery Network. PAN = Primary Account
Number (the card number). SDK = Software Development Kit. PAT = Personal Access Token.

---

## What the audit found, in one paragraph

The server half of the project is genuinely strong and repeatedly proven: the compensation
engine recomputes to the cent, the refund rails refused all ten adversarial calls against the
live endpoint, the webhook refuses forged signatures before touching the database, and the tax
quote and the tax charge share one implementation so they cannot disagree. The instability
lives in three places: (1) the browser half, where the staff console is still a drifted copy
of the shop payment engine; (2) the gate discipline, which failed twice in one day, so the
Stripe Tax round, five new public pages, the refund staff screen, and the staff console itself
carry no current gate; and (3) the paperwork, where the most-read documents (ROADMAP, the
migrations folder, the architecture doc) now contain claims that are false in both directions.
Six credentials remain burned and unrotated, including two console passwords sitting in git
history in plaintext.

## Definition of "stable" (exit criteria for the whole plan)

1. Every live surface carries a two-gate verdict on its CURRENT form, not a stale one.
2. One payment engine, consumed by both pages. A payment change is a one-file edit.
3. Zero false claims in ROADMAP.md, DOCUMENTATION\00-INDEX.md, and the migrations folder.
4. Zero burned credentials. No plaintext passwords reachable from git history remain valid.
5. Charters match the live rail, and a written rule exists that nothing deploys until both
   gates pass on the exact artifact being shipped.

---

## Step 0: TRUTH RESET (documents match reality)

Cheapest step, done first, because every reader (human or agent) anchors on these files.

- ROADMAP.md line 50: "PHASE 6 CLOSED, BOTH GATES PASS" certifies a payment rail that no
  longer exists (the gates ran pre-Braintree). Amend in place with the history preserved.
- ROADMAP.md "STILL OPEN" block (line 728+): says "no gate has been run over today's checkout
  work". The truth is stronger: both gates RAN and both returned FAIL, then the Stripe Tax
  round changed the checkout again and THAT has no gate. Rewrite to the current truth.
- Migrations folder must answer "what is live" correctly:
  - Write the missing `023_refund_guard_fix.sql` file from the live ledger (it exists only
    inside 022 as a folded-in marker).
  - Rename `018_PROPOSED_tax_integrity_hardening.sql` and fix its header: it IS applied,
    ledger version 20260816000812.
- DOCUMENTATION corrections: 02-DATA-MODEL (five stale "018 not applied" spots),
  01-ARCHITECTURE (says seven Edge Functions, there are eight; secrets table missing
  refund-payment; limitation 2 stale on three counts), 11-REFUNDS (header says LIVE, section 5
  says nothing is applied, and it cites a filename that does not exist), 09-LINKING (present
  tense "019 has not been touched" is false, the file was edited after grading),
  06-QA-AND-VERIFICATION (two unsourced contrast measurements, the bridge FAIL missing from
  the phase table, office-landing finding H2 silently dropped from the ledger).
- Rebuild `docs\TEST-CARDS.html` for the Braintree world. The shop links to it as
  authoritative and it currently documents three dead card worlds with two rows inverted.
- Sweep Howard's name out of the public build (third recurrence) and add a build lint so it
  cannot recur: name check, secret scan, and an assertion that every local stylesheet and
  script reference carries a version stamp.

## Step 1: SECURITY FLOOR (one hour of Howard, small code)

- Rotate all six burned credentials. Howard, in the dashboards, fresh values typed straight
  into the Supabase vault, never through chat:
  1. HyperSwitch secret API key
  2. HyperSwitch payment response hash key
  3. Stripe test secret key
  4. 3DSecure.io sandbox key (rotate BEFORE any further HE_00 debugging)
  5. and 6. Admin and staff console passwords: new strong values via a fresh migration
  (bcrypt only, no plaintext in the file), with the rotation recorded.
- Remove the dead raw card number inputs from `www\staff.html` (hidden but present in the
  DOM of a live payment console; three code paths still touch them).
- Fix the staff-auth audit logging (finding N-M1): a wrong-role or unknown-user refusal
  currently logs as "anonymous", discarding a signature-verified username.
- Decide the SDK source: the live rail loads HyperLoader from a beta CDN address. Either
  confirm it as vendor-recommended or move to the stable path; record the decision.

## Step 2: ONE PAYMENT ENGINE (the highest-leverage item in the project)

Extract the shared core into `www\js\payments.js`. The audit measured it: roughly 480 lines
of executable code, byte-identical or near-identical today across the two pages. The seam is
a factory: `createPaymentEngine({channel, returnPage, mount ids, resume key, payload builder,
copy table})`. All shopper and agent copy is injected as strings, never shared literals.

Adoptions and fixes that ride along:
- Staff console gains the finishing state (Howard's own "back at the card entry" complaint,
  still live there), the six outcome messages (a caller who authenticates and is then
  declined currently hears a bare "Declined."), and the record-tax bookkeeping call (staff
  sales currently record no tax transaction).
- The frictionless flash gets its correct fix, the one already recorded as such: reveal the
  challenge window by polling the payment for a genuine requires-customer-action state,
  not by guessing on a 1400 millisecond timer.
- Finding N-H1: the checkout displays a synthetic Iowa address while the server taxes the
  member's real stored address. Show the address that actually priced the order.
- Cached script loading on both pages, the never-called challenge-reveal cancel wired in,
  promise rejection handlers on the seven bare chains, escaping helper adopted by the shop.
- Reconcile the payment-link story: three live staff messages tell the agent to use a button
  that is permanently disabled. Either build pay-by-link or fix the copy.
- Both pages consume the module, ship through the build so the stamp covers it. Extend the
  stamper to Scalable Vector Graphics assets (the redesigned logo is still cache-stale for
  returning visitors).

## Step 3: GATE EVERY LIVE SURFACE (both gates, current state)

Run once, AFTER Step 2, so the gates grade the engine that will actually live on.

- Checkout as it stands now (post Stripe Tax, post extraction): verifier plus QA.
- The Stripe Tax round itself (quote-tax, record-tax, migrations 015 to 017): never gated.
- The staff console: first verifier gate in its existence, plus QA on the refund screen,
  including proving the refund button actually fires the refund (the one live refund cannot
  distinguish button from direct call), a live already-refunded probe, and a concurrency
  probe on the refund row lock (it guards an irreversible outward transfer).
- The five new content surfaces (comp-plan, conductor, faq, library rebuild, per-agent
  pages): contrast sweep, copy audit, terminology consistency.
- A live-site stamp check to close the cache-stamp fix as verified rather than read.

## Step 4: TEAM AND RULES (so it stays fixed)

Charter amendments from the team review, one line each:
- mlm-site-builder: retarget from `site\` to `www\`, delete the "demo mode, no real
  payments, anon key only" framing, explicitly own the front-end payment engine.
- mlm-verifier: extend past Phase 5 with live-endpoint duties (deployed equals repo,
  webhook idempotency, refunds and tax on the live rail) and the tools to do them.
- mlm-qa: promote SCOPE FOLLOWS CAPABILITY, NOT THE BRIEF to a named standing rule, and add
  a documentation-truth row: every status claim in README, ROADMAP, and DOCUMENTATION gets
  re-proven against observed state before a phase closes.
- mlm-db-engineer: own Edge Function deploy discipline, every deploy byte-compared.
- mlm-architect: add integration specs (third-party rails, function contracts, secrets).
- orvanna-designer: payment-surface rules (third-party mounted fields, pre-mount states,
  decline styling, same contrast floor).
- orvanna-writer: live-money copy joins the fact-sourced list; a disclaimer that has become
  false must be corrected, not preserved.
- The one shared line, in both gate charters: NOTHING REACHES THE LIVE PROPERTY OR THE
  CLOUD PROJECT UNTIL BOTH GATES HAVE PASSED ON THE EXACT ARTIFACT BEING SHIPPED.
- Standing gate-obligation trigger: any change to `functions\`, `_shared\`, or the payment
  block of either page opens an obligation that stays open until both gates run.
- Create the Supabase personal access token so function deploys become scripted and
  byte-exact instead of hand-carried.

## Step 5: BRIDGE LIVE, then the subscription engine

The bridge (migration 019, with 020 and 021 behind it) is designed, dry-run to the cent, and
correctly unapplied. Order of operations, per the engineer's own procedure:

1. Howard answers the seven policy decisions in DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md
   section 4 (020 and 021 already encode his answers to two of them).
2. Apply 019 + 020 + 021 to a BRANCH. 021 must ship with 019 or the finalized-month rule has
   no database backstop at all (there are currently zero triggers on app.orders).
3. Fix the reset-script landmine with a documented post-reset step, re-run the dry run
   against the real bridge, then both gates, then production.
4. Ship the webhook refund-event patch (already specified in doc 11 section 14): it is the
   only mechanism that settles a pending refund without a human.
5. Decide tax reversal policy: drift is measured, currently $9.75, and grows per refund.

THEN the subscription engine opens, architect-first, on stable ground: recurring billing
against the comp engine that the bridge now feeds. The spec must answer charge day, retry
and dunning policy, card storage on the sandbox rail, cancellation, and how a recurring
order flows through the same bridge policies (P1 to P9) as a first order.

---

## Howard's decision queue (parked, none blocking Steps 0 to 4)

1. The seven bridge policy decisions (doc 09 section 4). Blocking for Step 5 only.
2. Tax reversal on refunds: build it, or accept measured drift.
3. Office landing findings M2 (zero-filled months before enrollment) and M3 (aggregate rank
   rule shown beside named individuals; compliance-adjacent, do this one first).
4. PV versus SV naming split across shop, portal, and console.
5. The "12 AI agents" corporate tile versus 16 shop items.
6. GW- member code prefix left over from the retired Globex persona.
7. Portal titled "Member Portal" while gated to the admin credential.
8. orvanna.ai forward to orvanna.io (browser step, GoDaddy).
9. The 24-hour refund window: blast-radius limit today, business policy eventually.

## Suggested sequencing and effort

| Step | Effort | Depends on |
|---|---|---|
| 0 Truth reset | about half a day | nothing |
| 1 Security floor | about an hour of Howard plus an hour of build | nothing |
| 2 One payment engine | about a day | nothing |
| 3 Gate every surface | about a day of gate runs | Step 2 |
| 4 Team and rules | about two hours | nothing (parallel) |
| 5 Bridge, then subscriptions | one to two days once decisions land | Steps 0 to 4, decision 1 |

Steps 0 and 1 stop the bleeding. Step 2 before Step 3 so the gates run once, not twice.
Step 4 runs in parallel at any point. Step 5 is the door to the subscription engine.

## Evidence base

- `docs\qa\FULL-AUDIT-2026-08-15.md`, `docs\verification\FULL-AUDIT-2026-08-15.md`
- `docs\qa\CODE-QUALITY-AUDIT-2026-08-15.md`, `docs\verification\DB-AUDIT-2026-08-15.md`
- `docs\qa\COPY-AUDIT-2026-08-15.md`, `docs\decisions\ARCHITECTURE-AUDIT-2026-08-15.md`
- `docs\verification\REFUNDS-VERDICT-2026-08-15.md`, `docs\verification\BRIDGE-DRY-RUN-VERDICT.md`
- `docs\qa\office-landing-QA-verdict.md`, `DOCUMENTATION\06-QA-AND-VERIFICATION.md`
- Fresh 2026-08-16 four-track repo audit (front end, server, gates, charters) run by the
  coordinator; findings incorporated above.

---

## Addendum 2026-08-16: Howard's ruling on Step 1

Howard's ruling, 2026-08-16: the Step 1 credential rotations are SHELVED. This is a total
demo site and only sandbox money can move, so rotating the burned sandbox credentials buys
no real risk reduction today. The code hygiene items of Step 1 fold into Step 2 and are
still owed: removal of the dead raw card number fields from `www\staff.html`, and the
staff-auth audit logging fix (finding N-M1). Revisit the rotations before any real-money
milestone; that trigger stands.
