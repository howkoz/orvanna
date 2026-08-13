# Phase 1-2 Verdict: schema migrations + deterministic seed

Verifier: mlm-verifier (independent; built none of the graded artifacts).
Date: 2026-08-13.
Scope: migrations 001..005, generate_seed.py, build_seed_proof.py, and the
full db\seed\output\ pack including _manifest.txt and seed_proof.duckdb.
Method: every number below was recomputed with the verifier's OWN code
(scratch folder C:\Users\howar\AppData\Local\Temp\claude\mlm-verify-phase1\),
implemented from the specification prose, never from the builder's code.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Personal Volume (PV), Row-Level Security (RLS),
Secure Hash Algorithm 256-bit (SHA-256), Comma-Separated Values (CSV).

---

## GATE: PASS

No HIGH finding stands. Finding counts: HIGH 0, MEDIUM 2, LOW 7.

---

## 1. Worked example, recomputed independently

The verifier wrote its own implementation of COMP-PLAN-SPEC v1.1 from the
prose alone (volumes, the 100-point qualification gate, ranks with leg rules
evaluated bottom-up, paid depth, 10/5/5/3/2 percent on CV = 80 percent of SV,
round half up 2 decimals per line, no compression, earner must be qualified,
source qualification irrelevant) and ran it on the worked example input CSVs.

Comparison summary:

| What was compared | Mine | Builder's expected | Mismatches |
|---|---|---|---|
| Per-member rows (SV, CV, qualified, TV, rank, paid depth, total earned) | 10 | 10 | 0 |
| Commission lines (earner, source, level, source CV, rate, amount) | 15 | 15 | 0 |
| Company totals (SV 2,700.00, CV 2,160.00, payout 264.00, members paid 4) | 1 row | 1 row | 0 |

The specification's OWN arithmetic was also verified: payout rate 12.22
percent of CV and 9.78 percent of SV (both confirmed), the 20.00 maximum
five-level earn on one domain agent (confirmed: 8.00 + 4.00 + 4.00 + 2.40 +
1.60), and the breakage figures (M5's forgone 24.00, M2's out-of-depth 12.00,
both confirmed). The section 7 tables contain no arithmetic errors.

Rank teaching cases reproduced exactly: M1 Leader on the double boundary
(TV exactly 2,500 with 3 active legs), M3 Builder on boundary SV 100, M2
denied Builder because the M5 leg's frontline is unqualified, M8 denied
because its only leg (M10) is unqualified, and M10's 50 PV pays upline
(M8 earns 4.00) while qualifying nobody.

## 2. Determinism

generate_seed.py was copied to the scratch folder and rerun with its recorded
seed (20260813). SHA-256 of every regenerated file was compared against
_manifest.txt, and the graded on-disk files were hashed against the manifest
as well.

Result: PASS. All 14 manifest hashes match BOTH the graded on-disk files and
the scratch rerun, byte for byte. The regenerated _manifest.txt is itself
byte-identical to the graded one, and the rerun produced no extra files.

## 3. Tree and data integrity (verifier's own DuckDB queries)

All run against seed_proof.duckdb opened read-only; the graded database was
additionally proven identical, row for row, to the graded CSVs.

| Check | Result |
|---|---|
| Exactly one root; every sponsor_id resolves; no self-sponsorship | PASS |
| No sponsor cycles (all 1,000 reachable from the root by a capped walk) | PASS |
| Maximum depth 12, within the 8 to 12 band | PASS |
| Sponsor always enrolled on or before the child | PASS |
| Enrollment dates within 2024-08-01 .. 2026-07-31 (24 months) | PASS |
| Enrollment never after the member's first order | FAIL, finding M1 |
| Orders only in 2026-02 .. 2026-07; stamped first of month, midnight UTC | PASS |
| Exactly one order line per order; no orphan lines | PASS |
| Every order traces to a subscription active that month (start_month <= month < cancel_month or null): exact two-way bijection per member, product, quantity, month | PASS |
| Order line unit_price and unit_volume match the products table | PASS |
| Catalog: 6 domain agents at 100.00/100, 6 support at 50.00/50, commissionable_value null | PASS |
| Closed accounts (75): all subscriptions cancelled on or before 2026-05-01, no orders from 2026-05 onward, and every fully-churned-early member is flagged | PASS |
| Subscription sanity: quantity > 0, cancel strictly after start, start is a first-of-month within range, never before the enrollment month | PASS |

## 4. Realism bars

Qualified share (member-months with volume >= 100), computed BOTH ways:

| Denominator | Share | Inside 40 to 65? |
|---|---|---|
| All ENROLLED member-months (5,094; qualified 3,110) | 61.1 percent | yes |
| Member-months WITH ANY volume (4,588; qualified 3,110) | 67.8 percent | no |

Judgment: the engineer brief said "of member-months", whose natural reading
is all enrolled member-months (a member enrolled with zero volume that month
is still a member-month); the builder's own proof used the same denominator.
On that reading the bar PASSES at 61.1 percent, though near the top of the
band. The with-volume reading is recorded for transparency as finding L1.

Other bars: 5 members hold frontlines of 15 or more direct enrollees
(74, 64, 38, 32, 31), exceeding the "at least 3" bar. The depth histogram is
non-degenerate (members at all 12 levels; 11 levels hold 10 or more). Monthly
variance is visible: total volume grows month over month from 96,350 (2026-02)
to 141,750 (2026-07), a 1.47 ratio, with buying members growing 642 to 898.

## 5. Migrations versus SCHEMA-SPEC (static review)

Every table, column, type, constraint, and index of SCHEMA-SPEC section 1 is
present in migration 001, including: member_code unique, sponsor_id index,
tier/status/buyer_role check constraints, the one-final-run-per-period
partial unique index, the (run_id, member_id) primary key, the level 1..5
check, and rate numeric(5,4). Migration 002 implements the sponsor cycle
trigger (insert and update of sponsor_id, with a step cap) and the
finalized-run immutability trigger reading OLD.run_id. Migration 003 enables
RLS on all nine tables with no anon or authenticated policies; the
app_demo_reader definer role deviation is documented in-file and preserves
the spec's intent (tables invisible to the public API). Migration 004 seeds
exactly the five rank rows with paid depths 1..5. Migration 005 creates the
five v_demo_* views, definer-owned, filtered to final runs, exposing no email
and no internal member ids (member_code and display_name only).

Deviations and extras are findings M2 and L2 through L5 below.

## 6. Guardrails

22 text files (5 migrations, 2 seed scripts, 15 output files) plus the
seed_proof.duckdb binary were scanned. Zero Unicity terms (including internal
system and processor names), zero em or en dashes, zero non-ASCII characters.
All 1,000 emails end in @example.com and are unique; member codes all match
GW-\d{6} and are unique; display names are synthetic list combinations.
Identities are clean.

---

## Findings

### HIGH (wrong result or leak)

None.

### MEDIUM (spec drift or missing control)

**M1. 290 members have their first order timestamped before their enrollment
date.** Evidence: 290 of 1,000 members (29 percent) enrolled mid-month in a
history month while their first subscription bills from the first of that
same month, so the order (stamped the 1st, midnight UTC) predates enrolled_on
by up to 30 days. All 290 are same-month artifacts; no order falls in a
strictly earlier month. This violates the engineer brief's integrity
requirement ("enrollment ... never after a member's first order") and is a
plausibility defect (an account purchasing before it exists). It does NOT
affect month-level commission math, the qualification share, or determinism.
Suggested fix in the generator: for a member enrolled after day 1, either
start the first subscription the following month, or stamp the first month's
order at the enrollment timestamp instead of the 1st.

**M2. Finalized-run immutability can be bypassed by INSERT and by
run-repointing.** Evidence: migration 002 triggers fire on UPDATE and DELETE
only (exactly what SCHEMA-SPEC section 1 asks for) and read the run status
through OLD.run_id only. Two consequences: (a) brand-new rows can be INSERTed
into a run whose status is 'final', silently extending a supposedly immutable
statement; (b) an UPDATE of a row belonging to a non-final run can set
run_id to a final run's id, since only OLD.run_id is checked. The migration
matches the spec text, so the drift originates in SCHEMA-SPEC; but
COMP-PLAN-SPEC section 6.5 promises "finalized statements never change", and
this control does not fully deliver that. Suggested fix: extend both triggers
to INSERT (checking NEW.run_id) and, on UPDATE, check NEW.run_id in addition
to OLD.run_id.

### LOW (cosmetic)

**L1. Qualified share fails the band on the alternative denominator.**
67.8 percent of member-months with any volume, versus the 40 to 65 band;
passes at 61.1 percent on the enrolled-member-months denominator the bar
meant. Recorded for transparency; no action required unless Howard intended
the stricter reading.

**L2. v_demo_company exposes run_id, which is absent from the section 3
column table.** The same section's prose requires it (the footer data-basis
line reads "period + run id"), so this is an internal inconsistency in
SCHEMA-SPEC, not a leak: run_id identifies a run, not a member. Suggest
adding run_id to the spec's column table.

**L3. Migration 005 grants SELECT on the views to authenticated as well as
anon.** SCHEMA-SPEC says "anon gets SELECT on the views only". The exposure
surface is identical (same five views), but it is a silent extra grant.

**L4. Silent extras in migration 001.** An index on order_lines (order_id)
and a default of 'active' on members.status, neither in SCHEMA-SPEC. Both
benign and arguably improvements; listed because the brief demands every
silent extra be flagged.

**L5. spec_version wording mismatch.** SCHEMA-SPEC says commission_runs
.spec_version is "'v1.0' for this spec" while the governing comp plan is
v1.1. The migration pins nothing, so no code defect, but Phase 3 should
write 'v1.1' and the spec sentence should be corrected before it misleads
the comp engineer.

**L6. seed_proof.duckdb omits the we_subscriptions table.** Every other
worked-example table is loaded. The CSV exists and was verified consistent
(28 subscriptions map one-to-one onto the 28 orders and lines); loading it
would make the proof database self-contained.

**L7. Migration 003 swallows all exceptions when granting app_demo_reader
to the migration role.** The "when others then null" guard could mask a real
failure whose symptom would only surface later as an ALTER VIEW OWNER error
in migration 005. Narrowing the exception or logging it would fail faster.

---

## SHA-256 of the graded artifacts

```
005810122afd7e5f280635d136b5b921b57f3ad353098bf043458c6ea790abd0  db/migrations/001_app_schema_core_tables.sql
153e0db4b46ae3d7e40b8c89b941ad0368bd05cacd21ee3af4d2da23f56e6242  db/migrations/002_integrity_triggers.sql
a2bf5ed2f0ee69c5a7e9e823948c1ed66a920c58a86bab0dbdd2cb4d79c4aa68  db/migrations/003_row_level_security.sql
b411172dda0c82fcd53758bc86179940ab9cb439b06cf794c437dd83cd6911ed  db/migrations/004_ranks_seed.sql
189b7da4a3b98bdbc68a480e17b94375c96d2ea13fa8a0e0238a3a4132dca8c4  db/migrations/005_demo_views.sql
36f4b8776df8cc6d5acd72ac19dc10f4940f38a4ac05d9194c3e9d30236972b2  db/seed/generate_seed.py
62e8024afab19fc73c99f40ffead4755f932912e9d8b4018abdaa95fb7e6569d  db/seed/build_seed_proof.py
aef7e7061fe38ed54045100e2f6182e67b98070b803f47a8a8092fa6cc12bdf8  db/seed/output/_manifest.txt
ee009c4cd30f9106f8d1f4d1598d5e87d4cdf95d8b44a38535ddcb4542b214a9  db/seed/output/seed_proof.duckdb
```

The 14 data and loader files in db/seed/output/ are covered by the manifest
hashes inside _manifest.txt, each independently confirmed against disk and
against the scratch rerun (section 2).

## Gate statement

Phase 1-2 correctness gate: **PASS**. The two MEDIUM findings (M1 seed
plausibility, M2 immutability gap) should be fixed before Phase 3 finalizes
its first run, but neither produces a wrong number or leaks data today.
Verifier signature: mlm-verifier, recomputation performed independently,
2026-08-13.
