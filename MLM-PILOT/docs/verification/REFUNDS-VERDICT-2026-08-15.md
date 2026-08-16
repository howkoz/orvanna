# Refunds gate record, 2026-08-15 into 2026-08-16

**Graders:** `mlm-verifier` (correctness) and `mlm-qa` (completeness), writing jointly.
Neither of us built any part of the refunds work.

**What is being graded:** migrations 018, 022 and 023; the `refund-payment` Edge
Function; the extension of `list-demo-orders`; the staff console order history,
order detail and refund button; and the single live refund that was performed.

**Plain path to this file:**
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\REFUNDS-VERDICT-2026-08-15.md`

**Acronym key.** Quality Assurance (QA). Multi-Level Marketing (MLM). Row-Level
Security (RLS). Application Programming Interface (API). Hypertext Transfer
Protocol (HTTP). Hash-based Message Authentication Code (HMAC). Secure Hash
Algorithm 256-bit (SHA-256). Structured Query Language (SQL). JavaScript Object
Signing and Encryption, JSON Web Token (JWT). Coordinated Universal Time (UTC).
Three-domain secure, also written 3-D Secure (3DS). Personal Volume (PV).

---

## 0. The verdict, first

| Gate | Verdict | Scope of that verdict |
|---|---|---|
| Verifier (are the numbers and the controls right?) | **PASS** | The refusal path, the state machine, the money arithmetic on the one refund performed, and the database backstops. |
| Quality assurance (is the delivery complete and does it work?) | **CONDITIONAL PASS** | The endpoint is complete and proven. The **staff screen that fronts it has not been graded at all**, and one HIGH defect was found on the checkout that produced the refunded order. |

**What that means in one sentence.** The refund *engine* is the best-evidenced
piece of work in this project, proven live rather than argued for. The refund
*screen* has never been graded, and neither has the checkout claim that a
signed-in shopper is being charged against their own address, which this gate
found to be false.

**This gate does not close the phase.** It closes the endpoint. Section 6 lists
what is still owed.

---

## 1. What was proven live, with evidence

Everything in this section was executed against the live Supabase project
`oiyibdczkokegaxkwulv` and the deployed functions during this grading session,
not read from a builder's report.

### 1.1 The migrations are applied, and the ledger says so

Queried from `supabase_migrations.schema_migrations`:

| Version | Name | Meaning |
|---|---|---|
| `20260816000812` | `tax_integrity_hardening` | Migration 018 |
| `20260816011917` | `refunds_022` | Migration 022 |
| `20260816012057` | `refund_guard_fix_023` | Migration 023 |

Migrations 019, 020 and 021 are **absent from the ledger**, which matches their
stated status of proposed and not applied. Verified, not assumed.

### 1.2 Migration 018 holds, and no historical row was altered

Both constraints exist on `app.demo_orders`:

```
demo_orders_tax_source_check
  CHECK (tax_source = ANY (ARRAY['stripe_tax','flat_mirror_5pct','flat_fallback']))
demo_orders_total_is_sum_of_parts_check
  CHECK (total_cents = subtotal_one_cents + subtotal_sub_cents
                     + activation_fee_cents + tax_cents)
```

`tax_source` is `NOT NULL` with default `'flat_fallback'`.

The "no historical row altered" claim was **tested rather than accepted**. Across
all 120 orders:

- rows with `tax_source = 'flat_fallback'`: **0**. The migration's backfill
  therefore wrote to nothing. The mix is 90 `flat_mirror_5pct` and 30 `stripe_tax`.
- rows violating the sum constraint: **0**.
- rows whose `status_updated_at` falls inside the minute migration 018 was
  applied: **0**.

The claim is true, and this is the evidence for it.

### 1.3 The migration 023 state machine holds, proven by execution

Six transitions were driven directly against the live table inside a self
rolling-back block. The block raises at the end, so **nothing was committed**;
row counts were re-read afterwards and are unchanged (1 refund row, 1 refunded
order, 14 audit rows, 0 tampered rows).

| Probe | Transition attempted | Required | Observed |
|---|---|---|---|
| A | `processing` to `refunded` | refuse | **REFUSED** |
| B | `created` to `refunded` | refuse | **REFUSED** |
| C | `refunded` to `succeeded` | refuse | **REFUSED** |
| D | `succeeded` to `refunded` | allow | **ALLOWED** |
| E | update a row in `app.demo_staff_actions` | refuse | **REFUSED** |
| F | insert a second succeeded refund on an already fully refunded order | refuse | **REFUSED** |

Probes A and B are the migration 022 defect that migration 023 closed. They are
now refused by the trigger itself, not by a constraint that happened to be narrow.

The live trigger body contains the 023 guard text
(`only a paid order can be refunded`), confirmed by reading
`pg_get_functiondef` rather than by trusting the file.

### 1.4 The lesson from the 022 defect, recorded because it generalises

**Widening a CHECK constraint can silently delete a guarantee a trigger was
leaning on.**

Migration 010's transition guard only ever tested where a row was coming *from*.
For values it had never heard of, it fell through to `return new` and relied on
the CHECK constraint to reject them. Migration 022 widened that constraint to
admit `refunded` and `partially_refunded`, which removed the thing doing the
work, and `processing` to `refunded` and `created` to `refunded` became legal.

Two properties of this failure are worth keeping:

1. **It was invisible in the diff.** Nothing in migration 022's trigger edit is
   wrong when read on its own. The defect lives in the interaction between a
   constraint in section 1 and a trigger in section 2 of the same file.
2. **It was caught by the migration's own verification block, before any refund
   existed.** The Edge Function never attempts either transition, because the
   rule module requires `succeeded` first. So this was a missing **backstop**,
   not a live hole, which is exactly the distinction the tests existed to draw.

**The rule to carry forward: when you widen a constraint, re-read every trigger
that was relying on it being narrow.** A constraint and a trigger that together
enforce one rule are a single mechanism, and editing half of a mechanism is how
this class of defect is created.

### 1.5 The functions were deployed from disk, so there is no bundle drift

`refund-payment` is live at **version 2**, `list-demo-orders` at **version 6**.

The evidence that they came from disk rather than from a pasted bundle is in the
platform's own record: both functions report an `entrypoint_path` beginning
`file:///Users/howar/Desktop/Desktop/ORVANNA/MLM-PILOT/supabase/functions/`,
whereas every function deployed by the older route reports a
`file:///tmp/user_fn_...` path. That is a machine-recorded difference, not a
claim.

All eight relevant source files were then hashed on both sides of the symbolic
link (`functions/` and `supabase/functions/`) and are **byte identical**. There
is no transcription step anywhere in this deploy.

### 1.6 The ten refusals, run against the live endpoint

Read from `app.demo_staff_actions`, ids 6 to 15, paced roughly 23 seconds apart
from 01:55:03 to 01:58:29 UTC on 2026-08-16.

| # | Audit id | What was sent | `outcome_code` | Verified how |
|---|---|---|---|---|
| 1 | 6 | no session header | `bad_signature` | see the correction in 1.7 |
| 2 | 7 | hand-written session token | `bad_signature` | audit row |
| 3 | 8 | expired staff token | `expired` | audit row |
| 4 | 9 | `Orvanna_Admin` token | `wrong_role` | audit row |
| 5 | 10 | `GW-000001` Conductor token | `wrong_role` | audit row |
| 6 | 11 | valid signature, account absent | `unknown_user` | audit row |
| 7 | 12 | order `ORV-2026-08-1SOFU3` | `outside_refund_window` | **recomputed: 26.67 hours old** |
| 8 | 13 | order `ORV-2026-08-1M229J`, `processing` | `not_refundable` | recomputed: 5.05 hours old, status `processing` |
| 9 | 14 | `ORV-2026-01-ZZZZZZ` | `order_not_found` | no such row |
| 10 | 15 | `confirm` omitted | `not_confirmed` | audit row |

**Row 7 recomputed independently.** `ORV-2026-08-1SOFU3` was created at
2026-08-14 23:17:03 UTC; the refusal was logged at 2026-08-16 01:57:20 UTC. The
age at refusal is **26.67 hours**, against a 24 hour window. The audit detail
records `order_age_hours: 26` because the function stores whole hours. The
window fired correctly and the reported 26.7 figure is accurate to one decimal.

**Rows 4 and 5 are the two that could not be tested before deploy**, because they
need the database. There are 1,002 accounts that can sign in and exactly one that
may refund. Both the member portal login and a Conductor login were refused.

**Three earlier refusals exist, ids 3 to 5 at 01:54.** They are an aborted first
run, not part of the ten. Audit ids 1 and 2 were consumed by the migration's own
rolled-back verification block. Stated so nobody reading the table later
mistakes 13 refusal rows for 13 distinct tests.

### 1.7 The success path, proven

This is the item that section 5 of the previous record called **"the single most
important untested thing in the project."** It is now tested.

| Field | Value | How verified |
|---|---|---|
| Order | `ORV-2026-08-1JSPY4` | `app.demo_orders` |
| Member | `GW-000001` (`member_id` 1, `referral_code_entered` `GW-000001`) | joined to `app.members` |
| Subscription subtotal | $100.00 (10,000 cents) | `subtotal_sub_cents` |
| Tax | $9.75 (975 cents), source `stripe_tax`, jurisdiction `CA, US` | `app.demo_orders` |
| Total | $109.75 (10,975 cents) | `total_cents` |
| Refund reference | `orvrf_1854dcb719b1bd9be0767b97` | `app.demo_order_refunds` |
| Acquirer reference | `cmVmdW5kXzdlc2V5bmE1` | `connector_refund_id` |
| Connector | `braintree` | `connector` |
| Refund status | `succeeded` | `status` |
| Amount refunded | 10,975 cents | `amount_cents` |
| Tax inside that | 975 cents | `tax_cents_returned` |
| Requested by | `Orvanna_Staff` | `requested_by`, from the verified token |
| Order state now | `refunded` | `payment_status` |

**The amount check, recomputed independently.** $100.00 taxable at the Los
Angeles combined rate of 9.750 percent is $9.75 exactly. $100.00 plus $9.75 is
$109.75. `total_cents` is 10,975 and `amount_cents` is 10,975. **The refund
returned exactly what was charged, to the cent.** This satisfies the amount
equality check that was deferred on 2026-08-14 and has been outstanding ever
since, on the processor that is actually connected.

**The tax drift measurement behaved exactly as predicted.**
`app.v_demo_tax_drift` now reads:

```
refunded_orders_with_tax_transaction  1
tax_overstated_cents                  975
tax_overstated                        9.75
```

This is the first non-zero reading, it equals the tax on the one refunded order
that carried a Stripe tax transaction, and it is the designed consequence of the
instruction not to reverse tax, not a fault. A measured known gap is a different
thing from an unknown one, and this is the difference working.

### 1.8 The public surface did not widen

Migration 022's own verification step 9.8 was executed. Exactly **seven**
relations are readable by the anonymous role:

`v_demo_company`, `v_demo_customer_volume`, `v_demo_customers`,
`v_demo_member_months`, `v_demo_members`, `v_demo_statements`, `v_demo_tree`.

No refund view, no audit table, no staff action is exposed. The refunds work
added two tables and three views and granted **none** of them to any API role.
The anonymous surface is byte for byte the same set it was before.

### 1.9 The rule module still passes

`node --experimental-strip-types functions/_shared/refund-rules.test.ts` was run
against the file that is deployed: **19 of 19 cases matched expectation.**

### 1.10 The server-side role check exists, and this is where it applies

This is finding V-H3 moving rather than closing, and it is the most misunderstood
thing in the codebase, so it is stated precisely.

`functions/_shared/staff-auth.ts` verifies the token's HMAC signature against the
key in `app.demo_auth_config`, checks the expiry, then **re-reads the role from
`app.demo_users`** and discards the token's own role claim. That is a genuine
server-side authorisation check and it now exists.

Where it runs, verified by reading every function:

| Function | Token verified? | What actually guards it |
|---|---|---|
| `refund-payment` | **Yes, on every call** | `requireStaff(client, req, ["staff"])` before anything else |
| `list-demo-orders` | **Only on the order-detail path** (`?order_number=`) | The default list path has origin and rate limit only |
| `create-payment` | No | origin allow-list, rate limit |
| `confirm-payment` | No | origin allow-list, rate limit |
| `demo-login` | No | origin allow-list, rate limit |
| `quote-tax` | No | origin allow-list, rate limit |
| `record-tax` | No | origin allow-list only |
| `payment-webhook` | No | its own signature verification |

**So the sentence now shipping on `www\staff.html` line 398 and
`site\index.html` line 71, "The real gate is the role check the server performs
on every function call", is:**

- **true** of the refund button, which is the control that moves money;
- **true** of opening a single order in the staff console;
- **false** of every other call the staff console makes;
- **false of the entire member portal**, which calls no function that verifies a
  token at all.

The previous sentence, which claimed a browser could not forge the session
token, was plainly false. The replacement is a large improvement and is still not
true as written. The honest form is: *the refund endpoint decides for itself who
you are; the rest of the property does not.*

---

## 2. New findings raised by this gate

Each was found by us during this grading session and is not in any earlier
document.

### N-H1 (HIGH). The checkout shows one address and taxes against another

**On `www\shop.html`, a signed-in member is shown a synthetic Iowa address and
charged the California rate.**

- Line 124 tells the shopper: *"Sign in to use your saved billing address, or
  continue as a guest."*
- Lines 1006 to 1012 then fill the form with `SYNTHETIC_ADDRESS`, which is
  hardcoded at line 876 as **Jordan Avery, 4821 Meridian Loop, Cedar Falls,
  Iowa 50613**. The comment beside it says so openly: *"the billing address
  stays synthetic."*
- Meanwhile `functions/_shared/tax.ts` `resolveTaxAddress` reads the member's
  real stored address out of `app.members` and sends **that** to the tax engine.

**Proven on the flagship order.** `ORV-2026-08-1JSPY4` was placed by `GW-000001`,
whose stored address is **1 Demonstration Way, Los Angeles, CA 90012**. The order
carries `tax_jurisdiction = 'CA, US'` and an effective rate of **9.750 percent**.
Iowa's rate at Cedar Falls is 7 percent. The shopper saw Iowa on screen and was
charged California.

**Why this is HIGH and not MEDIUM.** The amount charged is correct: the server
priced it, the constraint proves the parts add up, and the refund returned it to
the cent. What is wrong is that **the address displayed at the moment of consent
is not the address that determined the amount**, on a screen that explicitly
promises it is. Every earlier HIGH finding on this checkout has been of exactly
this shape, and this is the same defect wearing a new face.

The sentence at line 124 is true of the server and false of the screen. Either
show the stored address or stop promising one.

### N-M1 (MEDIUM). A refused staff action loses the identity the server verified

`functions/refund-payment/index.ts` lines 510 to 518 write **every**
authorisation failure to the audit log as `actor: "anonymous"`,
`actor_role: null`.

For `bad_signature` and `missing_token` that is correct: nobody was identified.
For **`wrong_role` and `unknown_user` it throws away a username the server had
already verified by signature.** Audit rows 9 and 10 are the proof: they record
that somebody with the wrong role tried to refund, but not that one was
`Orvanna_Admin` and the other was Conductor `GW-000001`. Those are precisely the
two events an operator would want to alert on, and in the log they are
indistinguishable from an anonymous stranger.

**This is larger than the one-line fix recorded at N-L1.** `StaffAuthResult`
carries no username on the failure branch, so closing it means changing the
result type, not deleting a fallback.

### N-M2 (MEDIUM). Migration 023 is in the live ledger with no file of its own

`db\migrations\` runs 001 to 022. There is no `023` file anywhere in the
repository, yet `refund_guard_fix_023` is in the ledger.

Its text was folded into `022_refunds.sql` instead, which is honest about it (the
inline comment says "ADDED BY MIGRATION 023"). The **final state is
reproducible**: replaying 022 as it now stands produces the fixed trigger. The
**history is not**: nothing in the repository can reproduce the broken
intermediate state that the defect was found in.

This is a milder instance of the class already rated HIGH as D-F1 and V-M6, and
of the class rated MEDIUM as D-F6 (an engine edited in place under a finalized
version stamp). It is the fourth time this project has changed applied SQL in
place rather than forward. Recording it as MEDIUM rather than HIGH because,
unlike migrations 009 and 013, the state can be rebuilt.

### N-M3 (MEDIUM). Migration 018's file states, in capitals, the opposite of the truth

The file is still named `018_PROPOSED_tax_integrity_hardening.sql`, and its
header block reads:

```
STATUS: PROPOSED. NOT APPLIED TO PRODUCTION. NOT IN THE LIVE LEDGER.
```

It has been applied, it is in production, and it is in the live ledger. A reader
opening the migrations folder to establish what is live is told the wrong answer
by both the filename and the loudest line in the file.

### N-M4 (MEDIUM). The name-in-public-build defect recurred a third time

Counted directly from the public repository's own history, across every HTML and
JavaScript file:

| Commit | Occurrences of Howard's name |
|---|---|
| `06d0c03` (before the copy fix) | 19 |
| `da5ca7c` (the copy fix) | **5** |
| `36b7b92` | 5 |
| `5e3cc0c` (the refund console) | **7** |

The clean-up removed 14 occurrences and worked. **The very next feature commit
put two back**, both in `deploy\dist\staff.html`: line 309 quotes Howard verbatim
with a date, and line 2377 quotes him verbatim again. Line 936 names him a third
time.

The four remaining occurrences are legitimate and should stay: `team.html` names
him as the real owner with a real biography, and `index.html` credits him in the
team teaser. **The defect is the internal comments, not the credits.**

This is the same finding as V-M7 and W-H7, recurring for the third recorded time
after being fixed twice. A finding that returns every time a feature ships is not
a defect, it is a missing build step. The recommendation is a lint in
`deploy\build_dist.py` that fails the build on an author name inside a comment,
which is cheaper than finding it again.

### N-L1 (LOW). A missing session header logs as `bad_signature`, not `missing_token`

Already recorded by the builder at `functions/refund-payment/index.ts` lines 166
to 179 and in section 16.0 of the design document, and **deliberately not
fixed**. Confirmed correct by reading the code: `bearerFrom` falls back to the
`Authorization` header, which on this deployment always carries the anonymous
key, which is a well-formed token that simply is not ours. So it is read, fails
the signature check, and is refused.

The refusal is correct and nothing reaches an order. What is lost is the ability
to tell "nobody was signed in" from "somebody presented a forged token". Graded
LOW on its own, but see N-M1: the two together mean the audit log's identity
column is currently the least informative part of it.

### N-L2 (LOW). `refund-payment` contradicts itself about its own deployment

The same file's header says at lines 145 to 150 that it **must be deployed
without** platform JWT verification, and at lines 175 to 179 that it **is
deployed with** `verify_jwt: true` and that this is precisely why the N-L1 fix is
safe. The platform confirms the second: `verify_jwt` is true. The first block is
stale and should be deleted, not reconciled.

---

## 3. Findings this gate closes

| Finding | Was | Now | Evidence |
|---|---|---|---|
| Deferred amount-equality check (2026-08-14, never run) | Open on every rail | **CLOSED** | Section 1.7: 10,975 cents charged, 10,975 cents refunded, recomputed from a 9.750 percent rate on a $100.00 base |
| V-H3, session token never verified anywhere | HIGH, open | **MOVED, not closed.** True for `refund-payment`, partly true for `list-demo-orders`, false everywhere else | Section 1.10, function-by-function table |
| The refunds work is "proposed, not applied, not deployed" | Stated in two documents | **FALSE as of 2026-08-16** | Ledger, function versions, live refund |

---

## 4. What was NOT proven, stated plainly

This is the part of the record that matters most, because everything above reads
like success and the gaps below are real.

1. **The staff refund screen has never been graded.** Not one row of a QA
   checklist has been run against `www\staff.html`'s order history, order detail
   or refund button. The endpoint is proven; the control that a human presses to
   reach it is not. The staff console has still never had a verifier gate of any
   kind, and it is now a copy of the payment engine **plus** a refund button.
2. **Whether the successful refund was initiated from the screen or by direct
   call is not recorded.** The audit row carries `reason_code: 'other'`, which
   both paths can produce. So even the one success does not prove the button is
   wired.
3. **`already_refunded` has never been returned by the live endpoint.** Step 7 of
   the design document's own run order, clicking refund a second time, was not
   performed: there is no audit row after the successful one. We proved the
   **database backstop** instead (probe F: a second succeeded refund row is
   refused by the partial unique index), which is the stronger of the two
   controls. But the caller-facing response is unproven, and so is the promise
   that a second click does not call the processor.
4. **Partial refunds are unreachable and untested.** `partially_refunded` exists
   in the constraint and in the trigger. No code writes it. This is by design and
   is not a defect; it is recorded so nobody reads the state machine and assumes
   coverage.
5. **The tax reversal is not built, by instruction.** Drift is measured, not
   closed, and it will grow with every refund. Currently $9.75.
6. **No clawback exists.** The refund captured a `comp_impact` snapshot, and that
   snapshot correctly reads `bridge: not_applied` because migration 019 is not
   applied, so no live sale has ever produced volume. The snapshot mechanism is
   therefore recorded as **untested in the case that matters**: nobody has yet
   seen it capture a real bridged order.
7. **Nothing visual was seen.** No page was rendered and looked at. This gate ran
   against the database and the deployed endpoints only.
8. **Concurrency on the refund path is untested.** Two staff agents clicking at
   the same instant is defended by a row lock and a partial unique index. Probe F
   proves the index rejects a duplicate; it does not prove the behaviour under
   genuinely simultaneous requests, which nobody has fired.
9. **Rollback of 022 and 023 is untested**, like every other migration in this
   project.

---

## 5. What is genuinely well built here, said because the list above is long

An honest record has to carry this too.

- **The row is written before the processor is called.** That ordering converts
  the worst failure from an untraceable double refund into an answerable
  question, and it is the single best decision in the refunds work.
- **The rules live in a pure module** that runs without a server or a database,
  which is why 19 refusal cases could be executed and proven before anything was
  deployed, and re-executed against the deployed file afterwards.
- **The refund reference is our identifier and the processor's idempotency key at
  the same time**, so a retry cannot produce two refunds at either end.
- **The audit log records refusals, not just successes**, and is append-only at
  the trigger level. Probe E confirms it.
- **The role is re-read from the database on every call** rather than trusted
  from the token, so revoking a person actually revokes them.
- **The tax gap was measured rather than hidden.** A view that reads $9.75 and
  names the exact endpoint that would close it is a better outcome than a gap
  nobody wrote down.
- **The migration's own verification block found the migration's own defect**,
  before any refund existed. That is the process working exactly as intended, and
  it is the strongest single piece of evidence in this document that the two-gate
  habit is worth its cost.

---

## 6. What is owed before this closes as a phase

1. **A QA checklist over the staff refund screen**, every row executed: history
   paging, order detail, the refund button's disabled states, the confirmation
   step, the second-click behaviour, and computed contrast on every new control.
2. **A verifier gate on the staff console as a whole.** Still never done. It is
   now roughly 600 lines of copied payment engine plus a control that moves money
   out of the business.
3. **Close N-H1**, the address shown versus the address taxed. It is on the
   checkout, at the moment of consent, and it is HIGH.
4. **Prove `already_refunded` against the live endpoint** and confirm the
   processor is not called a second time.
5. **Rename migration 018 and correct its header**, and give migration 023 a file
   of its own or record in the ledger note that it lives inside 022.
6. **Add the author-name lint to the build**, so N-M4 cannot recur a fourth time.

---

## 7. Artifacts graded, with hashes

SHA-256 of the files this verdict was formed against, at the time of grading:

```
4daa797808873f7cc9a8ccefe2e021cb5a3c28711d17aef13a42b64f47298baa  functions/refund-payment/index.ts
41417597ad533f3416bbe31655848af934ed33238c820a2cf793d1941aef014d  functions/_shared/staff-auth.ts
6c4c7d412e71f642cb131e610e5d946f366060f7137296895bbaed77d8dcd56a  functions/_shared/refund-rules.ts
be4fcbbcd9f4a1561564fa9b8d8524e0dbd9504ca1a5448af4862b6561e26e25  functions/list-demo-orders/index.ts
c26053f303388e70f3083825b6dd3e7b0e241beeac3adc6173f5f9d46039d1ad  db/migrations/022_refunds.sql
66f56081233880e5a805dc6ab6e9a7ee7e960ee554560c86ec1f14fc45bc3ba3  db/migrations/018_PROPOSED_tax_integrity_hardening.sql
535ed05ec3554fa75fc907ee85af9c1d902e9072d8cf6cb5823ab3fbcd669599  www/staff.html
c3d087d498a721df274c0e8668070db90a085ce4c88b739cf90ed2948edc41d2  www/shop.html
```

Live state at grading time: 120 demo orders (28 succeeded, 44 created, 36
abandoned, 8 failed, 3 processing, 1 refunded), 1 refund row, 14 staff action
rows, 7 relations readable by the anonymous role.

Report only. Nothing in the product was changed to produce this document, and the
one write that was attempted was rolled back and verified rolled back.
