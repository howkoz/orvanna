# Comp Plan Lab, Phase L1 Proof Run, 2026-08-16

Builder: mlm-comp-engineer. This is BUILDER EVIDENCE under the project rule
that builder self-report closes nothing: mlm-verifier and the Quality
Assurance (QA) gate grade it after. Spec: `docs\COMP-LAB-SPEC.md` version 1.1
(all 825 lines, including the v1.1 amendment and Howard's section 8 rulings).

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Structured Query Language (SQL), Row-Level
Security (RLS), Breadth-First Search (BFS), Message Digest 5 (MD5),
JavaScript Object Notation (JSON), Quality Assurance (QA).

## Environment and what was applied

- Live project: `oiyibdczkokegaxkwulv` (the MLM Pilot Supabase project).
- Applied 2026-08-16, in order, as migrations `comp_lab_l1_001_schema`
  through `comp_lab_l1_007_analyze_snapshots`, each applied verbatim from its
  repository file `MLM-PILOT\db\lab\001..007_*.sql`.
- CLOUD POLICY followed: the lab schema is walled off and demo-invisible
  (proofs below), so applying it to the cloud project is within policy.
  NOTHING was applied to schema `app`.
- Parity month: March 2026, the first full seeded month (the month the
  spec's own calibration rule names). Real run: the unique final run for the
  period, run id 8, spec v1.3, finalized 2026-08-13.

## Order source and period snapshot (charter amendment discipline)

Every determinism claim below was proven against:

- Order source: SEEDED `app.orders` rows only. March 2026 carries 1,462
  completed orders and ZERO bridged rows (`demo_order_id` null on all).
  Every census run row independently stamped `order_source = 'seeded_orders'`
  by `lab.fn_run_plan`. The mini-tree and ten-member fixtures are stamped
  `'hand_fixture'` (volumes inserted by hand from the spec tables).
- Period snapshot: the March 2026 volume month and the 1,001-member census
  as of 2026-08-16. March is a finalized period, so the migration 021
  trigger refuses any new order row into it; each lab run additionally
  freezes its own inputs by materializing `lab.derived_members` and
  `lab.member_volumes` once per run.
- August 2026 (the bridged month) was NOT part of any L1 proof; its run is
  not final yet.

## Isolation proof (the L1 gate's schema-isolation clause): PASS

Schema `app` object inventory, captured immediately BEFORE applying the lab
and re-queried AFTER all seven files and all proof runs:

| Measure | Before | After |
|---|---|---|
| Relations in schema app | 88 | 88 |
| Non-internal triggers in app | 14 | 14 |
| Functions in app | 17 | 17 |
| Table grants in app | 185 | 185 |
| RLS policies in app | 10 | 10 |

Zero new objects, triggers, functions, grants, or policies in schema app.
The one-final-per-period index, the freeze triggers of migrations 002 and
006, and the migration 021 guard are untouched.

Further checks, all run on the live project:

| Check | Result |
|---|---|
| Cross-schema foreign keys lab to app | Exactly one: `derived_members_app_member_id_fkey` (lab.derived_members to app.members), the reference COMP-LAB-SPEC section 2.1 explicitly sanctions. Adds only internal referential-integrity bookkeeping; creates no readable surface and no write path. |
| Cross-schema foreign keys app to lab | ZERO (nothing real depends on the lab). |
| Grants in schema lab to anon, authenticated, app_demo_reader | ZERO rows. |
| Schema usage on lab for those three roles | ZERO rows (`has_schema_privilege` false for all three). |
| Lab tables with RLS off | ZERO (RLS on all ten tables, zero policies, service role only). |
| Lab functions containing INSERT, UPDATE, DELETE, or TRUNCATE against `app.*` | ZERO (grep over `pg_proc.prosrc` for every function in schema lab). |
| Status `'final'` in lab | IMPOSSIBLE, proven by attempt: the insert was refused by the CHECK constraint (probe block completed through its PASS handler). |
| The `'LAB-'` name wall | HOLDS, proven by attempt: a synthetic member row with code `GW-999999` and no census reference was refused by CHECK. |
| Run registry deletes | REFUSED by trigger, proven by attempt. |

Known interaction, recorded honestly: while lab rows exist, a TRUNCATE of
`app.members` (used only by the fresh-rebuild script
`db\comp\003_reset_app_data.sql`) would refuse loudly until lab run data is
cleared. Refusing loudly is the correct failure mode; noted in the lab
README.

## Proof a, identity: PASS

Lab run 3 = `lab.fn_run_plan('2026-03-01', 'unilevel_v13', {rates}, null)`
under the IDENTITY scenario (a real, locked scenario row with an empty
mutation list, seeded by file 001).

- Row-for-row equality of the derived member set against the `app.members`
  census on (id, member_code, sponsor_id, enrolled_on), both directions with
  EXCEPT ALL: **ZERO differences**.
- Counts: derived 1,001 = census 1,001. Synthetic or mismapped rows: 0.

## Proof b, parity: PASS

Lab run 3 (identity scenario, plan `unilevel_v13`, March 2026) against REAL
finalized run 8 (read-only, comparison not input):

- Commission lines, both directions with EXCEPT ALL on (earner, source,
  level, basis, rate, amount): **ZERO differences**. Line counts 1,630 =
  1,630.
- Company totals, value by value: total_sv 114,950.00 = 114,950.00;
  total_cv 91,960.00 = 91,960.00; total_payout **13,434.00 = 13,434.00**;
  members_paid 206 = 206.
- Member results, both directions on (member, sv, cv, qualified, rank, paid
  depth, total_earned): exactly ONE difference, the EXPLAINED census drift:
  lab carries one extra row for member GW-000 (the company retention
  account, migration 020, enrolled 2026-08-15, AFTER run 8 was finalized
  2026-08-13) with sv 0.00, cv 0.00, unqualified, rank member,
  total_earned 0.00. The assertion query proving no OTHER difference exists
  returned zero rows. Lines and totals are unaffected because the row is
  all zeros.

## Proof c, mini tree: PASS

Fixture: scenario PROOF-TEN's sibling PROOF-MINI (locked), members LAB-M1 to
LAB-M5 with ids 10000001..10000005, the spec section 6 volumes, hand-inserted
derived set and volumes (order_source `'hand_fixture'`), then the SAME
computation path as census runs (`lab.fn_execute_plan`: level map, placement,
plan, totals).

- Unilevel lines: all five lines exact, both directions zero differences
  (M1 on M2 12.00, on M3 8.00, on M4 8.00, on M5 at level 2 2.00; M2 on M5
  4.00). Totals: company **34.00** (M1 30.00, M2 4.00), SV 600.00,
  CV 480.00, two members paid. Matches spec 6.2 to the cent.
- Binary strategy A placement: M2 at M1.left, M3 at M1.right, M4 SPILLED to
  M2.left, M5 at M2.right, exact, zero differences.
- Binary strategy A lines and totals: M1 pays on pay-leg CV 80.00 = 16.00,
  M2 on 40.00 = 8.00, company **24.00** (M1 16.00, M2 8.00), two members
  paid. Matches spec 6.3 to the cent.

## Proof d, ten-member month, both placements: PASS

Fixture PROOF-TEN, members LAB-M1 to LAB-M10, COMP-PLAN-SPEC section 7
volumes.

- Strategy A ('bfs_spill'): placement tree exact against spec 6.4 including
  both spillover events (M4 to M2.left, M6 to M4.left). Company
  **184.00** = 8.52 percent of CV 2,160.00. Per-member table exact:
  M1 120.00 (pay leg 600.00), M2 40.00 (200.00), M3 24.00 (120.00), all
  others 0.00.
- Strategy B ('volume_balanced'): placement tree exact against spec 6.4
  (M4 to M3.left, the named divergence). Company **168.00**. Per-member
  exact: M1 104.00 (520.00), M2 24.00 (120.00), M3 40.00 (200.00), M2 and
  M3 trading places exactly as the spec says.
- The run output structure carries the honesty labels:
  `lab.v_placement_spread` returned the fixture pair with payout_bfs_spill
  184.00, payout_volume_balanced 168.00, **spread_a_minus_b 16.00**, the
  fixed caption "computed on a DERIVED placement; a different derivation
  gives different payouts" (a GENERATED column on every placement run row),
  and the disclaimer "WHAT-IF RUN: not a statement, pays nobody" (a
  GENERATED column on every lab run row).
- Bonus fixture validation: unilevel on the same ten members reproduced the
  COMP-PLAN-SPEC section 7 company totals exactly (payout 264.00, members
  paid 4, SV 2,700.00, CV 2,160.00), proving the fixture volumes themselves.

## Proof e, determinism: PASS

Method: MD5 digests over the FULLY ORDERED row content (lines in insertion
order by identity id; results by member; placement by member), plus value
comparison of all four company totals. Identical digests over ordered
content = identical output to the cent, row order included.

| Pair | Runs | lines_md5 | results_md5 | placement_md5 | Totals |
|---|---|---|---|---|---|
| unilevel_v13, March census | 3 and 11 | `2013ad718c42d0a33b6c9e987696eeaa` both | `589801c6edab3e4d556bfbd2d20dafe5` both | (no placement) | 13,434.00 / 206 paid, identical |
| binary bfs_spill, March census | 12 and 13 | `5e5bd3e98ed70f0d3ddd8e18f5230722` both | `71bced9b282b5aff7e56797957234d85` both | `371f94f0305946ad7df37fd7f5c492b1` both | 25,784.00 / 166 paid, identical |

The pairwise assertion query (any two completed identity-scenario March runs
with the same plan, parameters, and strategy disagreeing on any digest or
total) returned **ZERO rows**. Order source and period snapshot for this
claim: seeded orders, March 2026 snapshot, as stated at the top.

## The calibration run (spec 4.2 rule, Howard's section 8 ruling 3)

Seeded March 2026, identity scenario, draft binary parameters (rate 0.20,
cap 2,500.00):

| Plan | Strategy | Payout | Percent of CV | Calibrated pay_leg_rate (nearest 0.005) |
|---|---|---|---|---|
| unilevel_v13 | (sponsor tree) | 13,434.00 | 14.6085 | |
| binary | bfs_spill | 25,784.00 | 28.0383 | **0.105** |
| binary | volume_balanced | 24,836.00 | 27.0074 | **0.110** |

The spec's own prediction held: 20 percent UNDERSHOOTS on the shallow
ten-member tree (8.52 versus 12.22 percent of CV) and OVERSHOOTS on the
realistic-depth seeded tree (28.04 versus 14.61), because binary pays the
same CV to several ancestors as depth grows.

Census-month spread, from the run output structure: A 25,784.00 versus
B 24,836.00, spread 948.00 = 3.68 percent of A, caption attached.

SCOPE NOTE: this builder computed the calibration number and records it
here; the spec amendment that fixes it belongs to mlm-architect (this build
was instructed not to edit `docs\COMP-LAB-SPEC.md`), and the rule does not
say WHICH strategy calibrates, so both numbers are on the table
(recommendation: calibrate per strategy, since the strategies are honest
alternatives, or name bfs_spill as the anchor).

## Performance

All census runs on the 1,001-member tree, live project: unilevel 0.33 to
0.35 seconds; binary bfs_spill 1.28 to 1.44 seconds; binary volume_balanced
10.27 seconds (its leg weights re-scan placed subtrees; the 100,000-member
approach, per charter, is incremental per-node aggregates, recorded in file
003's header). Fixture runs 0.01 to 0.02 seconds.

## Deviations, findings, and flags for the architect and the gates

1. **Spec self-inconsistency found (section 6.3 versus 3.3 and 6.4), flagged
   not patched.** Section 6.3 claims strategy B coincides with strategy A on
   the five-member mini tree ("the lab must report spread 0.00 for this
   month"). By the spec's OWN section 3.3 algorithm, as hand-derived in its
   OWN section 6.4 (which this build reproduces placement-edge for
   placement-edge and cent for cent on the ten-member month), B diverges at
   M4's step on the mini tree too: M1's legs already weigh SV 150 (left)
   versus 100 (right), so M4 lands at M3.left and B pays company 32.00
   (M1 alone, on tied legs of 160.00 CV each, tie paying the left leg),
   spread A minus B = -8.00, not 0.00. The B mini run is recorded as
   INFORMATIONAL output (proof file 103, MINI5); the acceptance gates are
   the spec's A and unilevel numbers, which pass exactly. The architect
   should amend section 6.3's parenthetical.
2. **Extra-root ruling, documented in file 003 and needing ratification.**
   Spec 3.2 says "the root of the placement tree is the root of the sponsor
   tree", singular; the live census has TWO rootless members (GW-000001, the
   seed root, and GW-000, the company retention account added by migration
   020 with no downline). Rule applied: lowest-id root is the placement
   root; later rootless members are placed as if sponsored by it. On every
   seeded month this moves no money (GW-000 has zero SV; it landed at depth
   4 or 6 with zero effect on any leg it joined). Deterministic either way,
   but the architect should ratify or replace the rule before a month in
   which GW-000 carries volume (bridged months can put retained volume near
   it; note migration 020 keeps house volume in a separate table, not in
   app.orders under GW-000, so today the exposure is nil).
3. **Interface note.** `lab.fn_run_plan` implements the spec 1.1 declared
   four-parameter entry point exactly, plus a fifth DEFAULTED parameter
   `p_scenario_code default 'IDENTITY'`, because v1.1 made every plan read a
   scenario's derived tree while leaving the declared signature at four
   parameters. A four-argument call behaves exactly as declared.
4. **File 007 exists because of a real incident, recorded honestly.** The
   first census run completed and the second timed out: the run-scoped lab
   tables were freshly created, so the planner still carried empty-table
   statistics and chose a catastrophic plan once real rows existed. Fix:
   ANALYZE each snapshot table right after it is filled (transaction-safe),
   inside `lab.fn_execute_plan`. Determinism is unaffected (plans change,
   results do not; row order is fixed by the stable ORDER BYs, and the
   determinism digests above were all produced AFTER 007). File 006 was
   already applied, so per house discipline it stays frozen and 007 is a new
   numbered file redefining the one function.
5. **Lab run ledger for the graders** (lab.plan_runs on the live project):
   runs 3 and 11 unilevel March census; 12 and 13 binary A March census; 14
   binary B March census; 4 to 9 the mini and ten-member fixtures; 2 the
   archived name-wall probe. Ids 1 and 10 do not exist: identity ids burned
   by the two intentionally-refused probe inserts and the pre-007 timeout
   rollback. Nothing was deleted (deletes are impossible by trigger).
6. **Member-visible surface**: unchanged. No `v_demo_*` view touched, no
   grant added, the lab is invisible to anon, authenticated, and
   app_demo_reader. Nothing here is member-visible, so the deploy gate for
   member-visible changes is not triggered.

## What the gates should probe hardest

- Independent recomputation of the section 6 hand examples and the parity
  month (the L1 gate as specified).
- The strategy B reading (weigh-and-descend, ties left, an empty weaker leg
  is the open slot): it reproduces spec 6.4 exactly, but it is the one place
  this build had to interpret prose, and the 6.3 inconsistency shows that
  prose was fragile. Verify B against an independent hand derivation.
- The extra-root rule (finding 2) and whether it should instead exclude
  rootless zero-downline accounts from placement.
- The parity comparison's GW-000 exception logic (PAR3 in file 102): confirm
  the assertion query admits exactly the one drift row and nothing else.
- The determinism digest construction (text serialization of numeric and
  jsonb): confirm the digest cannot mask a scale-only difference the
  underlying EXCEPT-based checks would catch (the parity and fixture checks
  compare typed values, not text, and passed independently).

Every proof above: PASS. Phase L1 remains OPEN until mlm-verifier and QA
say so.
