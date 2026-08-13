# Phase 3 Verdict: Commission Engine on the Live Cloud Database

Grader: mlm-verifier. Date: 2026-08-13. The builder (mlm-comp-engineer) never
grades its own work; this grader built none of the engine under test and
recomputed everything independently from the specification prose alone.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Personal Volume (PV), Structured Query Language
(SQL), Comma-Separated Values (CSV), Common Table Expression (CTE),
Row-Level Security (RLS), Secure Hash Algorithm 256 (SHA-256).

## VERDICT: PASS

Zero HIGH findings. The independent recomputation matched the cloud's
finalized numbers to the cent in every month, every column, and every one of
the July top five earners. One MEDIUM observation (a spec property, not an
engine defect) and four LOW documentation items are recorded below.

## Method

1. Read COMP-PLAN-SPEC.md v1.2 and implemented the plan from the prose alone
   in an independent Python program (Decimal arithmetic, round half up, no
   code shared with the engine), working in the scratch folder
   `C:\Users\howar\AppData\Local\Temp\claude\mlm-verify-phase3\`.
2. Calibrated that program against the section 7 worked example CSVs:
   zero member mismatches, exactly 15 commission lines, company totals
   2700.00 / 2160.00 / 264.00 / 4. The independent implementation reproduces
   the spec's own contract before touching the full seed.
3. Verified the seed inputs are the graded artifacts: SHA-256 of all six seed
   CSVs matches `db\seed\output\_manifest.txt` (generator v3, seed 20260813)
   exactly.
4. Ran all six months (2026-02 through 2026-07) over the full 1,000-member
   seed and compared against the cloud's finalized totals and July top five.
5. Statically audited `db\comp\001_comp_engine.sql` line by line against the
   spec, audited design decisions a through d, and swept `db\comp\` for
   guardrail violations.

## Six-month comparison (mine vs cloud), matched to the cent

| Period | total_sv mine / cloud | total_cv mine / cloud | total_payout mine / cloud | members_paid mine / cloud | Result |
|---|---|---|---|---|---|
| 2026-02 | 104450.00 / 104450.00 | 83560.00 / 83560.00 | 12014.00 / 12014.00 | 179 / 179 | MATCH |
| 2026-03 | 114950.00 / 114950.00 | 91960.00 / 91960.00 | 13549.20 / 13549.20 | 206 / 206 | MATCH |
| 2026-04 | 124600.00 / 124600.00 | 99680.00 / 99680.00 | 14763.20 / 14763.20 | 227 / 227 | MATCH |
| 2026-05 | 138950.00 / 138950.00 | 111160.00 / 111160.00 | 16507.20 / 16507.20 | 248 / 248 | MATCH |
| 2026-06 | 148500.00 / 148500.00 | 118800.00 / 118800.00 | 17749.20 / 17749.20 | 261 / 261 | MATCH |
| 2026-07 | 172550.00 / 172550.00 | 138040.00 / 138040.00 | 20669.20 / 20669.20 | 284 / 284 | MATCH |

## July top five earners (mine vs cloud), matched on every field

| Member | Rank mine / cloud | SV mine / cloud | TV mine / cloud | Earned mine / cloud | Result |
|---|---|---|---|---|---|
| GW-000002 | executive / executive | 200.00 / 200.00 | 167800.00 / 167800.00 | 4888.00 / 4888.00 | MATCH |
| GW-000001 | director / director | 300.00 / 300.00 | 172250.00 / 172250.00 | 2936.80 / 2936.80 | MATCH |
| GW-000003 | executive / executive | 750.00 / 750.00 | 79450.00 / 79450.00 | 2680.80 / 2680.80 | MATCH |
| GW-000019 | director / director | 200.00 / 200.00 | 20900.00 / 20900.00 | 1035.60 / 1035.60 | MATCH |
| GW-000033 | director / director | 550.00 / 550.00 | 18400.00 / 18400.00 | 809.20 / 809.20 | MATCH |

July context from the recomputation: rank distribution member 925, builder 62,
leader 7, director 4, executive 2; qualified members 640; 2,187 commission
lines by my count (sources with CV above zero only, same rule as engine
decision c). GW-000001 holding director rather than executive despite TV
172,250.00 is correct: the executive rank needs two legs each containing a
leader or higher, and only one of GW-000001's legs contains one.

## Findings

### HIGH

None.

### MEDIUM

1. Spec property surfaced by live data: a member can hold Leader rank while
   UNQUALIFIED, because the spec's rank table gives Leader (and Director and
   Executive) no personal SV requirement, only TV and leg tests. In the live
   seed this actually happens every month: GW-000011 holds Leader with SV
   0.00 in all six months, GW-000037 with SV 50.00 in all six, GW-000279 with
   SV 50.00 from May onward. The engine and my recomputation agree exactly
   (this is NOT an engine defect, and no money moves: the earner-qualified
   filter pays them nothing). Flagged because the public demo will display
   "Leader" for a member with zero personal volume, which may not be the
   intended optics; a personal qualification gate on Leader and above is a
   one-line spec decision for Howard. Suggest adding it to the spec's open
   questions list.

### LOW

1. Stale version strings in documentation: `db\comp\README.md` says the
   contract is spec v1.1 (header and "How the engine works" step 1) and its
   deviation 3 says the run row's spec_version literal is 'v1.1', but
   `001_comp_engine.sql` line 106 actually writes 'v1.2' (correctly, per the
   v1.2 spec header). `002_worked_example_test.sql` line 1 also cites v1.1.
   The math is identical between v1.1 and v1.2 so nothing computes wrong;
   the documents should be brought in line with the code.
2. Stale README open question 3: it reports that migration 006 does not exist
   on disk. Both `db\migrations\006_immutability_hardening.sql` and
   `007_customers.sql` now exist, and the schema spec's immutability
   paragraph (final AND superseded runs frozen) matches what 006 is described
   to deliver. The open question should be marked resolved.
3. Design decision c is not airtight in theory: the CV above zero filter
   suppresses lines "paying 0.00 on nothing", but a line can still round to
   0.00 on something when rate times CV is below 0.005 (for example CV 0.20
   at the 2 percent level). Impossible with the v1 catalog (minimum unit
   volume 50.00, so minimum CV 40.00), so this is a note for the future
   per-product CV world, not a present defect.
4. Schema spec staleness (owned by Phase 2 docs, noted for completeness):
   SCHEMA-SPEC.md still says commission_runs.spec_version is "'v1.0' for
   this spec" while the engine writes 'v1.2'.

## Static audit of 001_comp_engine.sql against the spec

- Rank evaluation order: flags compute Builder, then Leader, then Director
  (containment tests builder_flag OR leader_flag), then Executive
  (containment tests leader_flag OR director_flag); final rank is the highest
  flag. This is exactly the spec section 4 declared non-circular order.
  CORRECT.
- Leg containment definitions: a leg is the frontline child plus that child's
  whole subtree (leg_members CTE); an active leg requires the frontline child
  itself to be qualified (active_leg_counts joins on the child only).
  CORRECT.
- Earner-qualified filter: `and earner.qualified` at line 315 blocks every
  line for unqualified earners; confirmed by the worked example M5 case and
  by the three live unqualified Leaders earning 0.00. CORRECT.
- Source-qualification irrelevance: no filter on the source side; an
  unqualified member's CV pays upline (worked example M10 paying M8, M3, M1).
  CORRECT.
- No compression: level is plain snapshot tree distance from run_level_map;
  no skipping of unqualified intermediates anywhere. CORRECT.
- Rounding points: exactly two, CV once per member-month
  (`round(0.80 * sv, 2)`) and amount once per line
  (`round(rt.rate * src.cv, 2)`); totals are sums of rounded values, never
  re-rounded. Postgres round(numeric) is half away from zero, identical to
  the spec's half up for these non-negative quantities. CORRECT.
- Deterministic ORDER BYs: level map insert orders by (ancestor, descendant),
  unique per run; lines by (earner, level, source), unique because level is
  functionally determined by the pair; results by member_id, unique. Identity
  ids and row order reproduce byte for byte. CORRECT.
- members_paid: count of members with total_earned above zero, matching the
  worked example's "members paid 4". CORRECT.
- fn_finalize_run: only a 'running' run can finalize; prior finals of the
  period flip to 'superseded' BEFORE the new final is set, so the partial
  unique index never sees two finals; level maps of superseded runs are
  deleted per the decision document; statement rows are never touched.
  CORRECT.
- Privilege hygiene: EXECUTE revoked from public on both functions;
  run_level_map has RLS enabled with no policies. CORRECT.

## Design decisions a through d: audited, none disputed

- a. Level map to FULL depth, not capped at 5: REQUIRED, not merely
  defensible. The seed tree is 12 levels deep and TV is defined over the
  whole subtree; a 5-level cap would have corrupted TV. My full-subtree TV
  matched the cloud everywhere, which also confirms the engine really did
  store full depth.
- b. is_active as SV at or above 100.00: matches the v1.1/v1.2 single gate;
  the schema spec's old "sv >= 50" note is acknowledged stale in the schema
  spec itself. Confirmed by worked example M5 (SV 50.00, not active).
- c. Lines only where source CV above zero: money-neutral (a suppressed line
  would pay 0.00 and members_paid counts earnings above zero). Accepted, with
  the theoretical rounding nit recorded as LOW finding 3.
- d. Staged-flag containment for Director and Executive: I implemented BOTH
  readings of the spec's "contains a Builder (or higher)" wording, the
  engine's staged flags AND a final-rank reading, and they produced identical
  results in the worked example and in every one of the six live months. The
  structural argument also holds: any member whose final rank exceeds their
  staged flags necessarily has flagged members strictly below them inside the
  same leg, so no leg is ever miscounted. Not disputed.

## Known context, verified but NOT re-flagged as new findings

- Customer orders have no exported subscription rows: confirmed in the seed
  (member-role orders reconcile 1:1 with active member subscriptions every
  month: 995, 1062, 1134, 1236, 1285, 1501 for February through July;
  customer-role orders, 322 through 745, have no subscription counterpart by
  design). Every order in the CSV satisfies the buyer_role/customer_id
  pairing rule.
- The reset script `003_reset_app_data.sql` gained app.customers at deploy,
  with an inline comment explaining why. The truncate list is complete and
  correctly keeps app.ranks.

## Guardrails sweep of db\comp

Clean. No em dashes (U+2014), no en dashes (U+2013), and no employer-specific
terms in any file under `db\comp\`. ("Unilevel" is generic MLM vocabulary,
not an employer term.)

## SHA-256 of the graded engine files

| File | SHA-256 |
|---|---|
| db\comp\001_comp_engine.sql | 4cead4e479a3c879f82af28584abe027068083980710cb047a4dc3e68724400c |
| db\comp\002_worked_example_test.sql | ef18a47735792f602626a76adfd4f21fb8244f9cad16030f46c468d4e1c6dd28 |
| db\comp\003_reset_app_data.sql | f74739890e551f114d3a1dfe61106ff72261fa708b8bcf07eab424670c6e4fb8 |
| db\comp\README.md | ce512d47322a22858b15760b0b03633e274e5eec9a99a58bd045192a81a6b2b2 |

Seed inputs verified against `db\seed\output\_manifest.txt` (generator v3,
seed 20260813): all six data CSV hashes match the manifest exactly.

## Bottom line

The engine's cloud output is independently reproducible to the cent across
all six months from the spec prose and the seed CSVs alone. PASS, with one
MEDIUM spec-design observation for Howard (unqualified Leaders are possible
and present in the data) and four LOW documentation cleanups.
