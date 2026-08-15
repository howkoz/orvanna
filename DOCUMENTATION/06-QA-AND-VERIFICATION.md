# 06. Quality Assurance and Verification

The testing and verification record for the Orvanna Multi-Level Marketing (MLM) Pilot.

Written by the two graders themselves: `mlm-verifier` (correctness) and `mlm-qa`
(completeness). Neither of us built any of the product described here. That is the
whole point of us.

State of the record: **2026-08-15.**

Plain path to this file:
`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\06-QA-AND-VERIFICATION.md`

Plain path to the diagram:
`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\diagrams\qa-coverage.svg`

**Acronym key.** Quality Assurance (QA). Multi-Level Marketing (MLM). 3-D Secure,
also written three-domain secure (3DS). Row-Level Security (RLS). Personal Volume
(PV). Sales Volume (SV). Commissionable Volume (CV). Team Volume (TV). Web Content
Accessibility Guidelines (WCAG). Application Programming Interface (API). Software
Development Kit (SDK). Document Object Model (DOM). Cascading Style Sheets (CSS).
Hypertext Markup Language (HTML). Hypertext Transfer Protocol Secure (HTTPS).
Structured Query Language (SQL). Hash-based Message Authentication Code (HMAC).
Secure Hash Algorithm 256-bit (SHA-256). Coordinated Universal Time (UTC). Primary
Account Number (PAN), the long number on the front of a card. Card Verification
Value (CVV), the short code on the back. Strong Customer Authentication (SCA).
Mail Order or Telephone Order (MOTO).

---

![Quality assurance coverage and the two-gate flow](diagrams/qa-coverage.svg)

*The picture first. Green is proven twice. Amber is proven once, or proven against
something that has since changed. Red has never been proven at all. Full-size file:*
`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\diagrams\qa-coverage.svg`

---

## 1. How quality is actually gated on this project

A phase closes only when **both** independent graders return a PASS. One PASS is
not enough. Either FAIL keeps the phase open and sends a ranked defect list back
to the builder.

The prime rule underneath both gates: **the builder never grades its own work.**
Neither grader wrote a line of the product. Neither can fix anything. Both can only
report.

### Why two gates and not one

Because "correct" and "complete" are different failures, and a single grader
reliably catches only the kind it is looking for.

| | Verifier gate | Quality assurance gate |
|---|---|---|
| The question | Are the numbers right? | Is the delivery complete, and does it work? |
| Method | Recompute independently from the written rules, never from the builder's code | Write the acceptance checklist from the promises BEFORE opening any deliverable, then execute every row |
| Typical catch | A commission line off by a cent, a leaked column, a status that can be written from the wrong place | A promised page that was never built, a button whose text cannot be read, a claim on screen that the code does not honour |
| Blind spot | Will happily confirm perfect arithmetic on a feature nobody can use | Will happily tick "the page shows a total" without knowing the total is wrong |
| Output | `MLM-PILOT\docs\verification\PHASE-N-VERDICT.md`, findings plus a SHA-256 hash of what was graded | `MLM-PILOT\docs\qa\PHASE-N-QA.md`, the checklist as a table plus a ranked defect list |

The split has already earned itself twice, in opposite directions:

- On 2026-08-15 the **verifier** found that a hand-typed member code was thrown
  away on the live checkout. Every number on the page was right. The order was
  simply credited to nobody. Quality assurance was reading the same screen and
  saw nothing wrong, because nothing looked wrong.
- On 2026-08-14 **quality assurance** found that the staff console was still
  faking payments behind a "no payment is ever taken" notice while the shop next
  to it took real test payments. Nothing was mathematically incorrect. The
  property simply contradicted itself.

Neither grader alone would have found both.

### The two standing lessons that shaped the quality assurance gate

1. **Presence in the document is not visual proof (added 2026-08-14).** Howard
   caught washed-out buttons that a gate had passed. Since then every interactive
   element is scored by computing its rendered contrast from the browser's own
   computed styles, compositing every transparent layer, against the 4.5 to 1
   floor for text. A button whose text cannot be read is a HIGH defect even when
   its click handler works perfectly.
2. **Scope follows capability, not the brief (added 2026-08-14).** When a
   capability goes live anywhere, the checklist covers every surface that presents
   that capability, not only the surface the phase brief names. This is the rule
   that caught the faking staff console, and it produced half of the medium-rated
   findings in the 2026-08-15 sweep.

### Where the rule broke

The rule has no trigger that fires on accumulation. On 2026-08-15 the project
shipped fifteen commits, 723 lines of code and SQL, a processor change, a 3DS mode
change, a new payment lifecycle and roughly a thousand new credential rows, and
**not one gate document was written that day before any of it went live.** Nobody
decided to skip the gates. Each individual commit felt too small to stop for.
Fifteen of them added up to a rebuilt payment rail.

The recommended repair, from the architecture audit and endorsed here: any change
to `create-payment`, `confirm-payment`, `_shared/edge.ts`, or the payment block of
either page opens a gate obligation that stays open until both gates run, no matter
how small the change was.

---

## 2. Every phase, its verdict, and its date

Taken from the dated gate documents in `MLM-PILOT\docs\verification\` and
`MLM-PILOT\docs\qa\`. Where a document does not exist, the row says so. **A missing
document is a missing gate, not an implied pass.**

| Phase | What it covered | Verifier verdict | Quality assurance verdict | Date | Closed on both gates? |
|---|---|---|---|---|---|
| 0 | Scaffold, guardrails, team, roadmap | not gated | not gated | 2026-08-13 | No gate ran. Scaffolding only. |
| 1 and 2 | Schema, migrations, row-level security, deterministic seed of 1,000 members | **PASS** (0 HIGH, 2 MEDIUM, 7 LOW) | **PASS** | 2026-08-13 | **Yes** |
| 3 | Commission engine, ranks, commission runs, statements | **PASS** (0 HIGH, 1 MEDIUM, 4 LOW) | **PASS** (38 of 42 rows; the 4 failures were documentation) | 2026-08-13 | **Yes** |
| 4 | Corporate site, sign-in page, member portal (five tabs) | **no verifier verdict exists** | **PASS** (36 rows: 35 PASS, 1 FAIL at MEDIUM) | 2026-08-13 | **No. One gate only.** |
| 4B and 4C | The shop, product pages, portal connection points | **no verifier verdict exists** | **PASS, with one MEDIUM design question** (41 rows) | 2026-08-14 | **No. One gate only.** |
| 4C.2 | Shop round 4: catalog as single source of truth, four-step checkout | **no verifier verdict exists** | **PASS, conditional on a stale roadmap fix** (51 rows) | 2026-08-14 | **No. One gate only.** |
| 4.5 | Staff call console | **no verifier verdict exists** | **PASS** | 2026-08-14 | **No. One gate only.** |
| 5 | Public launch of orvanna.io, GitHub Pages, custom domain, HTTPS | **PASS** (0 HIGH; security and exposure half) | **PASS** (24 of 24 rows) | 2026-08-14 | **Yes** |
| 5T | Team page, roster of ten, teaser, unified cache stamps | **no verifier verdict exists** | **PASS** (31 of 31 rows), then a delta pass **PASS** (13 of 13) | 2026-08-14 | **No. One gate only.** |
| 6 | Real test-mode payments on the live rail | **PASS** (0 HIGH; both MEDIUMs fixed and re-verified same session) | **PASS** (10 of 10 rows) | 2026-08-14 | **Yes, on the rail as it stood that day.** See the warning below. |
| Office landing (retroactive gate on live code) | Rebuilt member portal home | not gated | **FAIL** (2 HIGH contrast, 5 MEDIUM, 4 LOW) | 2026-08-14 | **No. Failed, and shipped anyway by Howard's own explicit ruling that no rollback was warranted.** |
| Full audit sweep, six areas | Everything, treated as unreviewed | **FAIL** (4 HIGH, 9 MEDIUM, 6 LOW) | **FAIL** (2 HIGH, 8 MEDIUM, 8 LOW) | 2026-08-15 | **No. Both gates failed.** |
| Stripe Tax (quote-tax, record-tax, migrations 015 to 017) | Real destination-based tax on the live checkout | **no document exists** | **no document exists** | 2026-08-15 | **No gate of any kind has ever been run on this.** |

### Two warnings about that table

**The Phase 6 "CLOSED, BOTH GATES PASS" line is stale, and the roadmap still
states it as present-tense fact.** Both gates genuinely passed on 2026-08-14. Since
then the payment processor changed (four dummy simulators out, Braintree sandbox
in), the 3DS mode changed, the challenge presentation changed, the payment lifecycle
changed and checkout identity changed. The gates certify a rail that no longer
exists. An untrue certification is worse than no certification, because it stops the
check from being made.

**Phases 4, 4B, 4C, 4C.2, 4.5 and 5T were closed on the quality assurance gate
alone.** No verifier verdict was ever written for any of them. The project's own
rule says a phase closes only on both. Six phases do not meet it. This is stated
plainly because it is not visible from the roadmap, which reports them as done.

---

## 3. The test cards, in plain English

Full matrix: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\TEST-CARDS.html`

**Read this warning before that file.** `TEST-CARDS.html` carries no date, its file
timestamp is 2026-08-14 18:46, and the processor changed the next day. Of roughly
forty card rows in it, four are still true on the live rail. It describes three card
worlds (3DSecure.io, Stripe, and the HyperSwitch dummy connector) and **none of the
three is connected any more.** It is the one document in the project where following
the documentation produces a wrong conclusion within thirty seconds. It has not yet
been rebuilt.

### What is actually true on the live rail today

The processor is Braintree sandbox. Expiry `01/29` on every card. Any three-digit
security code. The passcode the sandbox itself displays on the approval screen is
`1234`.

| Card number | What it does, in plain English |
|---|---|
| `4000 0000 0000 2503` | The bank asks the shopper for a passcode, the shopper types `1234`, and the payment is **approved**. This is the only card that shows the whole journey ending in a sale, so it is the one the checkout recommends first. |
| `4000 0000 0000 2370` | The bank asks for a passcode and the **identity check fails**. The right card for testing the "we could not confirm it was you" path. |
| `4000 0000 0000 2701` | **No screen at all.** Approved silently. This is what a smooth, frictionless payment is supposed to look like. |
| `4000 1111 1111 1115` | The bank asks, the shopper answers correctly, **and the card is still declined.** See the correction below. |
| Any amount between $2,000.00 and $3,000.00 | Declines, on any card. This is a Braintree sandbox rule triggered by the **amount**, not the card. It is documented nowhere in `TEST-CARDS.html` and it is the rule most likely to make a tester believe the site is broken. It also means the specification's own worked example cart, at $2,231.25, cannot pass on the live rail. |

### The two corrections that cost real debugging time

**Correction one. `4111 1111 1111 1111` is not a three-domain secure (3DS) test
card at all.** It was recommended in the shop's own card hint for part of
2026-08-15. It is an ordinary success card. If you use it to answer the question
"is 3DS working?", the answer will always look like no, and the answer will be
wrong. The same trap exists with `4242 4242 4242 4242`, which is documented as
supporting 3DS but not enrolled in it, so no approval screen can ever appear no
matter what the site asks for. `TEST-CARDS.html` still contains a large red
instruction to use `4242 4242 4242 4242`, and that card is not valid on Braintree
at all.

**Correction two. `4000 1111 1111 1115` raises the approval screen but is a decline
card.** A tester types the correct passcode, the bank confirms the identity, and the
payment is then refused by the card. On screen that reads exactly as though the
passcode was ignored. It is not. Two separate things happened in order: the identity
check passed, then the money was refused. Any wording that tells that shopper to
"check their card details" is actively wrong.

Both mistakes were in a shipped card hint at the same time, and together they
produced a card that could never finish and a card whose success looked like a bug.
Howard found both.

### The deeper lesson behind the card table

The reason the cards changed on 2026-08-15 is that the **processor** changed, and
every processor publishes its own test numbers. The root cause of two nights of lost
configuration work was found in HyperSwitch's source rather than its documentation:
a function named `is_separate_authentication_supported()` hard-codes nine connectors
that can do external 3DS, and every dummy connector on the account returns false by
name. No setting, key, or acquirer value on our side could ever have changed that.

---

## 4. Findings ledger

Every finding raised by a gate or an audit, its severity, and its status as of
2026-08-15. Statuses marked **verified** were re-checked directly in the working
tree while writing this document. Statuses marked *not re-verified* are reported as
the audit left them, and should be treated as unknown rather than as closed.

### 4.1 The audit of 2026-08-15, six areas

On 2026-08-15, after Howard's instruction to "audit everything, make sure all is in
order, nothing sloppy", six independent audits ran across the whole property. Both
gate verdicts were FAIL.

| Area | Auditor | Document |
|---|---|---|
| Correctness and security, whole system | mlm-verifier | `MLM-PILOT\docs\verification\FULL-AUDIT-2026-08-15.md` |
| Database | mlm-db-engineer | `MLM-PILOT\docs\verification\DB-AUDIT-2026-08-15.md` |
| Completeness, contrast, every surface | mlm-qa | `MLM-PILOT\docs\qa\FULL-AUDIT-2026-08-15.md` |
| Code quality and duplication | mlm-qa | `MLM-PILOT\docs\qa\CODE-QUALITY-AUDIT-2026-08-15.md` |
| Every word the site shows a human | orvanna-writer | `MLM-PILOT\docs\qa\COPY-AUDIT-2026-08-15.md` |
| Architecture and documentation accuracy | mlm-architect | `MLM-PILOT\docs\decisions\ARCHITECTURE-AUDIT-2026-08-15.md` |

#### Verifier findings (correctness and security)

| # | Severity | Finding | Status |
|---|---|---|---|
| V-H1 | HIGH | A total that moves while the payment is being created is dropped on the floor. The card form then shows the current total while the open payment carries the old one. | **FIXED, verified.** Commit `3f30d44`. |
| V-H2 | HIGH | A hand-typed member code is silently discarded. A guest who types a sponsor's code gets an order credited to nobody. | **FIXED, verified.** An input listener now exists at `www\shop.html:1151`. |
| V-H3 | HIGH | The session token is never verified, and the shipped source comment claims it is. Hand-writing a session object opens the staff console and the member portal. | **OPEN, verified still present.** The false comment is unchanged in `www\staff.html:294` and `site\index.html:66`. |
| V-H4 | HIGH | The administrator and staff passwords went into version control in plaintext and were never rotated. | **PARTLY CLOSED, verified.** The plaintext is out of the current migration file; git history still carries it and **no rotation is recorded anywhere.** |
| V-M1 | MEDIUM | Cart edits made while the checkout is open never reach the checkout. | **FIXED, verified.** `renderAll` now calls the summary re-render. |
| V-M2 | MEDIUM | Automatic payment opening manufactures orphan orders and burns the daily rail limit. 66 percent of orders on 2026-08-15 were stuck at `created`. | **OPEN**, not re-verified. |
| V-M3 | MEDIUM | `confirm-payment` performs no authorization, and the order list publishes the last 25 order numbers to anyone. | **OPEN**, not re-verified. |
| V-M4 | MEDIUM | Specification drift in three places, none amended. | **OPEN**, not re-verified. |
| V-M5 | MEDIUM | A third-party chat script runs on the payment page. Acceptable on a test rail; must never carry to a live one. | **OPEN by design ruling.** |
| V-M6 | MEDIUM | Migration 013 is applied to production and absent from the repository. | **OPEN, verified, and now worse.** See section 4.5. |
| V-M7 | MEDIUM | Howard's real first name appears 16 times in the public build, with verbatim internal quotes. | **OPEN, verified.** Still 11 occurrences in `deploy\dist\shop.html`, 4 in `team.html`, 2 in `index.html`, 1 in `staff.html`. |
| V-M8 | MEDIUM | The rate limiter reads then increments in two statements, so concurrent requests can all pass. | **OPEN**, not re-verified. |
| V-M9 | MEDIUM | The sign-in role allow-list omits `member`, so a page asking for `member` gets "any role is acceptable". | **OPEN**, not re-verified. |
| V-L1 to V-L6 | LOW (6) | Daily limit uses session time zone not UTC; the 25-unit cap is unexplained to the shopper; a byte order mark in `catalog.js`; unrecorded reasoning for seven database advisor errors; no secret scan in the build; an orphan row if a reference write fails. | **OPEN.** The byte order mark was verified still present. |

#### Quality assurance findings (completeness, contrast, every surface)

Measurement scale, for context: 9,700 elements were scored for computed contrast
across every page and both themes. 9,690 passed.

| # | Severity | Finding | Status |
|---|---|---|---|
| Q-H1 | HIGH | Shop primary buttons are unreadable while disabled: computed **1.70 to 1** against a 4.5 to 1 floor. Reproduced live on the checkout button and on the pay button during every payment open. | **FIXED, verified.** Commit `f7329f1` replaced the fade with a real disabled treatment. |
| Q-H2 | HIGH | Portal light theme: the QUALIFIED and NOT QUALIFIED signal fails, five instances, 3.28 to 1 and 4.12 to 1. The single most important status in the member office. | **FIXED, verified.** The colour tokens were restated and re-measured at 6.72 to 1 and 5.53 to 1. |
| Q-M1 | MEDIUM | The shop tells the shopper "any values continue, including empty fields" directly beneath a real payment button. False on a live rail. | **OPEN, verified still present** at `www\shop.html:306`. |
| Q-M2 | MEDIUM | "Express options place the order in one step." All three express buttons are disabled and place nothing. | **OPEN, verified still present** at `www\shop.html:214`. |
| Q-M3 | MEDIUM | The disabled express buttons look identical to the working one. No disabled rule exists for them at all. A shopper taps Apple Pay and gets silence. | **OPEN, verified.** No `.pay-btn:disabled` rule exists in the stylesheet. |
| Q-M4 | MEDIUM | The staff console says "No bank approval is possible on this path" on a page that ships a full bank-approval overlay and contradicts itself two lines earlier. | **OPEN, verified still present** at `www\staff.html:149`. |
| Q-M5 | MEDIUM | The finishing state was applied to the shop only. The roadmap claimed both. The staff console still shows the exact flash-back-to-the-card-form bug Howard reported. | **OPEN, verified.** Zero occurrences of the finishing function in `www\staff.html`. The roadmap claim has since been corrected in prose. |
| Q-M6 | MEDIUM | A keyboard user cannot reach the bank's passcode field. The focus ring targets an element that cannot take focus. | **FIXED, verified.** Both pages now set the focus attribute before focusing. |
| Q-M7 | MEDIUM | Staff primary buttons fail while disabled, 3.72 to 1 and 3.84 to 1, including one button that is permanently disabled. | **FIXED, verified.** The staff stylesheet now uses an opaque grey rather than a fade. |
| Q-M8 | MEDIUM | The receipt says "Payments route through the Orvanna orchestration layer in a later phase." They route through it now. | **FIXED, verified.** The line is gone. |
| Q-L1 to Q-L8 | LOW (8) | PV used before it is expanded; ZIP never expanded; an unknown product code silently renders a different product; an overclaimed "saved billing address"; field borders at 1.60 to 1; six touch targets under 24 pixels at phone width; a byte order mark; an unreachable stale status line. | **OPEN.** |
| Q-unproven | Could not verify | Whether the card form is visually present on arrival could not be confirmed: the browser pane never composited a frame. Recorded as unproven rather than passed. | **STILL UNPROVEN.** Needs one look in a visible browser. |

#### Code quality findings

| # | Severity | Finding | Status |
|---|---|---|---|
| C-A1 | HIGH | Stale cache stamp. Stylesheets rewritten that day kept the old address, so a browser holding yesterday's stylesheet painted the bank-approval bar behind the payment window at the exact moment it matters. | **FIXED, verified.** The build now derives the stamp from a hash of the actual bytes. |
| C-A2 | HIGH | Seven promise chains with no failure handler. A dropped connection leaves "Finishing your order, one moment" on screen forever with nothing to press. | **PARTLY ADDRESSED**, not fully verified. Some handlers now exist; not all four poll loops were confirmed. |
| C-A3 | HIGH | The staff console can move the total after the payment is open, then read the new total aloud to a caller charged the old one. | **OPEN, verified.** The console still has no amount signature. |
| C-A4 | HIGH | Two phantom selectors defeated the staff guard that was supposed to prevent C-A3. The classes it disabled do not exist. | **FIXED, verified.** The guard now names the real classes. |
| C-A5 | MEDIUM-HIGH | Retrying a failed portal load double-binds listeners and silently breaks the light and dark toggle. | **OPEN**, not re-verified. |
| C-A6 to C-A11 | MEDIUM to LOW (6) | An uncancelled reveal timer; two different definitions of "qualified this month" in one portal; an unknown product code showing a different product; both session gates painting the protected page before ejecting; unescaped server strings in the shop only; a support-chat race repeated six times. | **OPEN**, not re-verified. |
| C-B1 | Structural | The staff console is a roughly 600-line copy of the shop's payment engine. Twenty function names are 95 to 100 percent identical. It has drifted three ways in a single day. | **OPEN.** The recommended fix, one shared payment module, is rated the highest-leverage item in the project and has not been done. |

#### Copy findings: 7 HIGH, 11 MEDIUM, 11 LOW, zero compliance findings

| # | Severity | Finding | Status |
|---|---|---|---|
| W-H1 | HIGH | "Payments route through the orchestration layer in a later phase", printed on every successful receipt. | **FIXED, verified.** |
| W-H2 | HIGH | "Any values continue, including empty fields" on a real payment step. | **OPEN, verified.** Same as Q-M1. |
| W-H3 | HIGH | "Express options place the order in one step." Both halves false. | **OPEN, verified.** Same as Q-M2. |
| W-H4 | HIGH | "No bank approval is possible on this path" on the staff console. Operationally dangerous on a live call. | **OPEN, verified.** Same as Q-M4. |
| W-H5 | HIGH | "Test mode: this is a simulated approval and no money moves." The approval is not simulated. It is a real 3DS challenge served by a sandbox issuer. | **OPEN, verified still present** at `www\shop.html:461`. |
| W-H6 | HIGH | A 73-line HTML comment containing four invented executives with full biographies ships to production, underneath a page whose entire premise is that the team is real. | **OPEN, verified still present** in `www\index.html` and in the built output. |
| W-H7 | HIGH | Nine comments quoting Howard verbatim and dating his bug reports ship to production, on files any visitor can fetch. | **OPEN, verified.** |
| W-M1 to W-M11 | MEDIUM (11) | Footer and top notice contradict each other on the same page; a false default confirmation note; PV versus SV named differently on two live surfaces; portal money carries no currency mark; a perpetual-ownership promise for hosted software; "cancel anytime" with nothing that cancels; two absolute product guarantees; a two-day build claim that is now three; member codes still carry the pre-Orvanna prefix; the portal is titled for a member and gated for an administrator; one card-hint sentence has the bank and the shopper the wrong way round. | **OPEN**, not re-verified except the member-code prefix, which is still present. |
| W-L1 to W-L11 | LOW (11) | Two em dash characters in placeholder markup (the only two on the property); a bare one-word "Declined."; a percent-style split between surfaces; slang about money on one page; a footer with two versions; inert footer links; PV before its expansion; a backdated announcement; two strong outcome claims; two disabled options handled two different ways; a hardcoded delivery promise. | **OPEN.** |

#### Database findings

| # | Severity | Finding | Status |
|---|---|---|---|
| D-F1 | HIGH | Migration 013 is applied to the live project with no file in the repository. The repository cannot rebuild the live ledger. | **OPEN, verified, and now worse.** See 4.5. |
| D-F2 | HIGH | Migration 013 was a no-operation. It asked for a descending index using a name that already existed as an ascending one, so the database silently skipped it. The ledger records an intent that did not happen. | **OPEN.** |
| D-F3 | MEDIUM | The abandon sweep is stranding rows right now: 13 orders at `created` and 3 at `processing`, all more than an hour old. | **OPEN.** |
| D-F4 | MEDIUM | No index serves the abandon sweep. It is a full table scan and grows without bound. | **OPEN.** |
| D-F5 | MEDIUM | The member code column on the sign-in table has no foreign key to the members table, although the target column is unique and would accept one. | **OPEN.** |
| D-F6 | MEDIUM | Six finalized commission runs stamped version 1.2 cannot be re-derived: the engine source was edited in place to version 1.3. For a project whose crown jewel is a recomputable commission run, this is the one auditability gap in the engine. | **OPEN.** |
| D-F7 | MEDIUM | The rate-ledger cleanup has no usable index. | **OPEN.** |
| D-F8 | MEDIUM | An abandoned order can never be corrected by the confirm path, only by the webhook. | **OPEN.** |
| D-F9, D-F10, D-F11 | LOW (3) | Migration 014 is not re-runnable; roughly 1,000 member accounts share one password hash (a deliberate, honestly documented choice); five trigger functions carry a default public execute grant, unreachable in practice. | **OPEN.** |
| D-F12, D-F13 | Information | Seven database advisor errors are the mandated architecture, not defects, recorded so nobody "fixes" them and breaks the demo; the anonymous role's storage grants are platform defaults over zero buckets. | **Recorded, no action.** |

#### Architecture and documentation findings

| Group | Count | What it is | Status |
|---|---|---|---|
| S1 to S13 | 13 | Places where the Phase 6 specification now describes something that is not true. The largest: the specification says the payment begins at the Place order press; it now opens automatically at three different moments, none of which is a button press. | **OPEN.** The specification has not been amended. |
| C1 to C3 | 3 | Places where the code should come back to the specification. The most important: tax exemption is decided in the browser and obeyed by the server, inside a design whose stated invariant is that this never happens. A caller can send "tax exempt" and legitimately reduce a $2,000.00 order by $100.00. | **OPEN**, and partly overtaken by the Stripe Tax work of the same day, which is itself ungated. |
| W1 to W17 | 17 | Statements in the roadmap that are wrong. W5 is the serious one: it certifies a payment rail that no longer exists. W17 is the cause: the document is append-only, so six sections each correct the section above them and a reader who stops early gets a confidently stated falsehood. | **PARTLY FIXED.** W9 was corrected in prose on 2026-08-15. The rest, including W5, are **OPEN**. |
| R1 to R6 | 6 | The 3DS research document now describes the opposite of the live situation in its summary, and zero cards for the live processor appear anywhere in it. | **OPEN.** |
| Test-card document | 1 large | The most dangerous document in the project: undated, points at three dead card worlds, two rows actively inverted, and the four cards the checkout itself recommends appear nowhere in it. | **OPEN.** |
| Items 1 to 34 | 34 | The deduplicated open-items list across every source. Tier 1 (owed before anything else ships) is four items: run both gates over the checkout, correct the roadmap's false statements, rebuild the test-card document, rotate the four burned keys. | **Tier 1 is entirely OPEN.** |

### 4.2 Earlier phase-gate findings

| Phase | Findings | Status |
|---|---|---|
| 1 and 2 | 0 HIGH, 2 MEDIUM, 7 LOW | Recorded at the gate; not tracked separately since. |
| 3 | 0 HIGH, 1 MEDIUM (a specification property, not an engine defect), 4 LOW documentation | Recorded at the gate. |
| 4 | 1 FAIL at MEDIUM out of 36 rows | Not re-verified. |
| 5 | 0 HIGH; 1 MEDIUM, an authoring comment naming Howard in the catalog file | **That specific comment was fixed. The same defect class then recurred at roughly ten times the volume** and is now finding V-M7 and W-H7. |
| 6 | 0 HIGH; both MEDIUMs fixed and re-verified in the same session; a backlog of 6 items banked | Backlog **OPEN**: inert card fields present pre-mount, thin pre-mount framing, the rate-limiter race, an accepted asymmetry, a list endpoint that accepts the wrong method, and raw dollar figures in a response. |
| Office landing | 2 HIGH contrast, 5 MEDIUM, 4 LOW. **Verdict FAIL.** | H1 was fixed. **M2, M3 and M4 remain open by Howard's own call.** M5, the PV versus SV naming split, is still live on the shop. |

### 4.3 The honest summary of the ledger

- Fixed and re-verified by this document: **11 findings**, including all four
  highest-severity defects the two full audits raised about the checkout itself.
- Still open at HIGH severity: **9** (listed in the summary at the end).
- Still open at MEDIUM severity: roughly **45** across the six audits.
- Still open at LOW severity: roughly **40**.
- Never gated at all: the Stripe Tax feature, and four production migrations.

Nothing in the open list can lose real money. The sandbox has no path to the real
world, the anonymous database key remains sealed and live-probed, and the finalized
commission months gained no new input. The severity ceiling on the entire open list
is embarrassment and wasted time, not loss. That ceiling holds only while the rail
stays a test rail.

### 4.4 What is genuinely right, and should not be lost in the list above

An honest ledger has to say this too, or it misleads in the other direction.

- The commission engine was recomputed independently, from the written plan rather
  than the engine's code, and matched **2,187 statement lines to the cent**, with
  zero rank disagreements and zero volume disagreements.
- The seed regenerates byte for byte.
- The money path on the server is single-sourced and cannot be skipped by either
  caller. The charged amount is compared to the stored amount as whole cents before
  any payment can be recorded as a success, and a mismatch can never be written as
  succeeded. This is the strongest control in the project and it is correctly placed
  as the last word.
- A client can never influence an amount. The request carries no prices.
- The database enforces immutability itself, not just in application code:
  a finalized run rejects writes at the trigger level.
- The anonymous key grants nothing on the application schema at all. Not a weak
  policy, no access.
- The secret sweep of the public repository is clean. The only credential in its
  history is the deliberately public demonstration password printed on the page.
- Zero em dashes and zero en dashes across the shipped site, and zero employer data
  or terminology anywhere.
- Direct-selling compliance is clean on every surface: no income claims, no earnings
  projections, no fabricated social proof, and no member is ever shown what an
  unqualified downline person cost them.

### 4.5 One finding this document raises for the first time

While re-verifying the ledger, the checked-in migration folder was compared against
the commit history. **Migrations 015, 016 and 017 are named in commit messages as
applied to production and have no file in `db\migrations\`.** The folder runs 001 to
014 with 009 and 013 already missing. Two new server functions, `quote-tax` and
`record-tax`, exist in the repository with no gate document and no specification
entry.

This is the same defect class the database audit rated HIGH four hours earlier as a
single instance. It is now four instances, and it happened after the audit that named
it. Combined with the rebuild recipe that already omits three migrations, **the
database currently cannot be reconstructed from this repository.**

---

## 5. What is NOT tested

Named plainly. An untested area that is silently omitted is worse than one that is
named, because a reader assumes coverage that does not exist.

1. **The whole 2026-08-15 checkout rebuild shipped ungated.** Fifteen commits, 723
   lines of code and SQL. A processor change, a 3DS mode change, a new payment
   lifecycle, roughly a thousand new credential rows, a new client-side
   authorization rule, and a shared-code change touching every server function
   including the webhook. Verified by its builder only. The two audits that ran
   later that day were retroactive, not gates.
2. **The Stripe Tax feature has never been gated in any way.** Two new server
   functions and three migrations, shipped after the audits closed. No verifier
   verdict, no quality assurance checklist, no specification entry.
3. **No card has ever been driven end to end on the current processor by a grader.**
   The verifier's check for amount equality on a genuinely succeeded payment was
   deferred on 2026-08-14 because that session could not drive the payment widget,
   and it has not been run since, on any rail. It is the single most important
   untested thing in the project.
4. **Nothing visual has ever been seen.** Every gate ran with the browser window
   hidden. Behaviour was proven by dispatching real events at real elements and
   reading the resulting document state, and contrast was computed rather than
   eyeballed, which is stronger than a screenshot for those questions. But no page
   has ever been rendered and looked at by a grader. Layout collapse, overlap,
   z-order in a real compositor, animation, and font rendering are all unproven.
   One row of the 2026-08-15 quality assurance audit is explicitly recorded as
   unproven for exactly this reason.
5. **No real device and no second browser.** Phone width was emulated, never a
   phone. Everything was driven in one engine.
6. **Load and concurrency are untested.** The rate limiter's read-then-increment
   race is a code-reading finding, not a measured one. Nobody has fired concurrent
   requests to see whether the ceiling holds.
7. **The database cannot be rebuilt from the repository, and nobody has tried.**
   The rebuild recipe omits three migrations that exist; four more migrations do
   not exist as files at all.
8. **Rollback is untested.** No migration has been rolled back and re-applied. One
   is known not to be re-runnable.
9. **The blocked-popup path is untested and unhandled.** The bank approval now
   appears in a popup inside the page. Nothing in the code handles the case where a
   browser blocks it, and no test covers it. The research document dismisses this in
   one line and it is now the primary path.
10. **Assistive technology is untested.** Contrast is measured and keyboard focus
    was proven by hand on one dialog. No screen reader has ever been run against any
    page. The hidden accessible table on the office landing was found by reading
    code, not by listening.
11. **The staff console has never had a verifier gate at all.** It is a roughly
    600-line copy of the shop's payment engine, it handles money, a live agent reads
    it aloud to a caller, and no correctness grader has ever looked at it.
12. **Nothing has been tested against the specification since the specification went
    stale.** Thirteen recorded divergences means a passing test against that
    document now proves less than it looks like it does.

---

## 6. The regression story of 2026-08-15, written as a lesson

### What was changed, and why it was a good idea

The shop's checkout used to create the payment when the shopper pressed Place order.
That meant a two-second wait at the worst possible moment, right at the point of
consent. Howard asked for it to be faster. The builder moved the payment creation
earlier, so that it happens automatically while the shopper is still filling in the
step above and the card form is simply already there when they arrive.

That is a genuinely good change. Howard confirmed the checkout now feels fast, which
was the entire point.

### The hazard the change created, and the defence that was built for it

A payment fixes its amount at the moment it is created. Opening it early means the
shopper can afterwards do something that moves the total, leaving a payment that
would settle at the old amount while the page shows the new one.

The builder saw this and built a defence: an amount signature covering the four
things that can move the total or the attribution (the items, the activation option,
the tax exemption, and the member code). Any change discards the open payment and
opens a fresh one. The server re-prices from scratch every time, so an amount never
originates in the browser. The design was thoughtful and the intent was right.

### The three regressions it shipped with anyway

| # | The regression | What it meant |
|---|---|---|
| 1 | **A hand-typed member code was silently discarded.** The signature included the member code, which shows the author knew it mattered. Nothing ever fired on that field, so the payment had already been created with an empty code before a single character was typed. | For a project whose entire subject is sponsor attribution, the central mechanic was silently broken. A guest who typed a sponsor's code got an order credited to nobody. |
| 2 | **A total that moved while the payment was being created was dropped on the floor.** The re-check refused to act while a create was in flight, and scheduled no retry. The button then relabelled from the current total while the open payment carried the old one. | The final receipt was still truthful, because it renders from the server. What was wrong was the figure on the button at the moment of consent. On a test rail that is a bug. On a live rail it is a consent defect. |
| 3 | **Cart edits made while the checkout was open never reached the checkout.** The cart drawer stayed reachable from the checkout and its edit handler never told the summary. | The drawer showed one total, the summary showed another, and the open payment carried a third. |

All three were regressions. All three worked before the change. Every one of them is
an instance of the exact hazard the amount signature was built to close.

### How they were found

Not by the builder, who tested the thing that was changed and found it working. By
the two gates, running later that day across the whole surface rather than the
changed part of it. The verifier found all three by reasoning about which sequences
of user actions could reach the early-return path, then constructing them.

All three were fixed the same day, in one commit, and all three fixes are verified
closed in section 4.1.

### The lesson

**A structural change verified narrowly produces regressions in the parts nobody
thought to look at.**

The builder's testing was not lazy. It was correctly aimed at the change and it
passed. The change was to *when* something happens, and moving a thing in time
breaks every assumption that quietly depended on the old ordering. Those assumptions
live in code the change never touched, which is exactly the code a narrow test does
not run.

Three corollaries worth keeping:

1. **The two-gate process is what caught this**, and it caught it in the way the
   split was designed for: a correctness grader reasoning adversarially about
   sequences, not a completeness grader ticking a screen. A single gate would have
   caught at most one of the three.
2. **The gates ran too late.** They ran after the work was live, as an audit, not
   before it as a gate. Everything found was already in production and had already
   produced 21 orphaned orders that day. Catching it is not the same as preventing
   it.
3. **Naming the hazard is not the same as closing it.** The amount signature named
   all four inputs correctly and still shipped with two of them unwired. A defence
   is worth exactly as much as its weakest wire, and nothing but an independent test
   finds the unwired one.

The same day produced the same lesson a second time, from the other direction: a
fix described in the roadmap as "APPLIED TO BOTH SURFACES per the QA rule that scope
follows capability" had in fact been applied to one surface. The rule was quoted
correctly and followed halfway. That half is still open today as finding Q-M5.

---

## 7. Recommended next tests, ranked

Ranked by what would actually reduce risk, not by how quick they are.

| # | Test | Why it is first | Effort |
|---|---|---|---|
| 1 | **Drive one card end to end on the live Braintree rail, in a visible browser, and check the amount to the cent against the stored order.** Use `4000 0000 0000 2503` with passcode `1234`. | This is the deferred verifier check from 2026-08-14, still deferred, on a processor that has since changed. It is the only test that proves the money path holds on the rail that is actually connected. It also settles the one row the last audit could not prove. | Half a day |
| 2 | **A full verifier and quality assurance gate over the checkout as a whole**, both surfaces, against the live rail. | Fifteen commits of money-path work are certified by their builder only, and the project's most-read document claims otherwise. This is the two-gate rule's entire purpose. | One day, half each |
| 3 | **Gate the Stripe Tax work.** Recompute tax independently for at least three destinations, one exempt case, and the receipt wording, and confirm the four undocumented migrations. | It shipped after the audits with no gate of any kind, it touches the amount charged, and it partly overtakes an open finding about where tax exemption is decided. | Half a day |
| 4 | **A visible-browser visual and assistive-technology pass on all seven pages**, in both themes, at phone and desktop width. | No page has ever been rendered and looked at. Contrast is measured but layout, overlap, z-order and animation are entirely unproven, and one audit row is explicitly recorded as unproven for this reason. | Half a day |
| 5 | **A verifier gate on the staff call console.** It has never had one. | Roughly 600 lines of copied payment engine, drifted three ways in a day, handling money, read aloud by an agent on a live call. The known open defect C-A3 lets it charge one amount and speak another. | Half a day |
| 6 | **Rebuild the database from the repository into a scratch project and diff it against production.** | This is the single test that proves or disproves seven separate open findings at once, including four missing migrations and a rebuild recipe that omits three more. | Half a day |
| 7 | **A concurrency test on the rate limiter and the daily ceiling.** Fire simultaneous requests and count what actually got through. | The race is a code-reading finding, not a measured one, and the daily ceiling is currently being consumed by mere browsing. | Two hours |
| 8 | **A blocked-popup test on the bank approval path.** | It is now the primary path and nothing in the code handles the failure. | One hour |
| 9 | **A copy sweep against the live rail rather than against the old one.** Every sentence on a payment screen, checked against what the code now does. | Five of the seven highest-severity copy findings are still shipping, on the highest-stakes screens the site has, and they are all leftovers from the pretend-payment era. | Two hours |
| 10 | **Rebuild the test-card document from the code**, then re-run the card matrix against it. | It is the one document that produces a wrong action within thirty seconds, and the shop points at it as authoritative. | Two hours |

### One process change, worth more than any single test

Add a trigger that fires on accumulation. Any change to the payment functions, the
shared server module, or the payment block of either page opens a gate obligation
that stays open until both gates run, regardless of how small the individual change
felt. The rule did not fail on 2026-08-15 because anyone decided to skip it. It
failed because nothing in it noticed fifteen small changes adding up to a rebuilt
payment rail.

---

## Source documents

All paths are absolute and plain.

```
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\PHASE-1-VERDICT.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\PHASE-3-VERDICT.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\PHASE-5-VERDICT.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\PHASE-6-VERDICT.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\DB-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\FULL-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-1-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-3-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-4-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-4C-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-4C2-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-45-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-5-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-5T-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\PHASE-6-QA.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\office-landing-QA-verdict.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\FULL-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\CODE-QUALITY-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\COPY-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\decisions\ARCHITECTURE-AUDIT-2026-08-15.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\decisions\2026-08-13-genealogy-representation.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\TEST-CARDS.html
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\PHASE-6-SPEC.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\COMP-PLAN-SPEC.md
C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\ROADMAP.md
```

Report only. Nothing in the product was changed to produce this document.
