# Comp Plan Lab, Phase L2 Proof Run, 2026-08-16

Builder: mlm-comp-engineer. BUILDER EVIDENCE; mlm-verifier and the Quality
Assurance (QA) gate grade it after (builder self-report closes nothing).
Spec: `docs\COMP-LAB-SPEC.md` version 1.2. Phase L1 closed the same day
(verifier PASS, QA PASS on re-inspection).

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Group Volume (GV), Structured Query Language (SQL),
Message Digest 5 (MD5), Quality Assurance (QA), Breadth-First Search (BFS).

## What was built and applied

Files `db\lab\008` through `013`, applied verbatim to the live project
`oiyibdczkokegaxkwulv` as migrations `comp_lab_l2_008_run_freeze` through
`comp_lab_l2_013_run_freeze_fix`; proof scripts `107` through `110`.
Applied files from L1 (001..007) stayed frozen; every change is a new
numbered file.

- 008: the run freeze (QA MEDIUM-1, now a spec L2 deliverable): run rows
  freeze at status 'complete' (sole permitted change: archive, all other
  columns byte-identical); PLUS the same freeze on every run-scoped child
  table (lines, results, derived members, volumes, level map, placement
  map), both directions, the migration 002/006 discipline.
- 009: placement generalized to width N (`lab.fn_derive_placement_width`);
  the two-slot entry point delegates at width 2, so binary is byte-identical
  through the new code (proven below).
- 010: plan `matrix_3x7` (placement-tree level pay, flat depth 7 for
  qualified members per Howard's accepted default).
- 011: plan `stairstep_breakaway` (bottom-up GV with breakaway exclusion,
  bracket differential rounded once at the line, generation 1 and 2
  overrides, executable monotonicity assertion).
- 012: dispatcher covers all four launch plans; matrix places at its
  plan_params width.
- 013: freeze fix found BY the probe: in a BEFORE UPDATE trigger PostgreSQL
  has not yet computed NEW's stored GENERATED columns, so 008's archive
  equality test compared old disclaimer/caption text against nulls and
  refused the one LEGAL transition. Over-strict, never leaky (every tamper
  probe still refused). 013 excludes the two generated columns, which an
  updater cannot write anyway.

## Order source and period snapshot (charter discipline)

All census claims: SEEDED `app.orders` rows only (March 2026 carries zero
bridged rows; every census run row self-stamps `order_source =
'seeded_orders'`), over the 1,001-member census of 2026-08-16, frozen by
the migration 021 trigger and the lab's per-run snapshots. Fixture runs are
stamped `'hand_fixture'`. August 2026 was not used.

## The freeze probe (the named refused-update probe): PASS

Probe run on the PROOF-MINI scenario, completed, then attacked:

| Probe | Result |
|---|---|
| F1 update a completed run's total_payout | REFUSED |
| F2 update a completed run's result row | REFUSED |
| F3 insert a line into a completed run | REFUSED |
| F4 archive the completed run (status only) | ALLOWED, the one permitted transition |
| F5 update the archived run's notes | REFUSED |

First probe attempt exposed the 008 generated-column defect (F4 wrongly
refused); after 013 the full probe passes cleanly. The failed attempt rolled
back whole (its run id 17 is burned, its rows never existed).

## Matrix worked example: PASS

The spec carries no matrix hand example yet (v1.2 leaves "hand example
appended to this spec" as an L2 amendment); the derivations in the headers
of `db\lab\108` and `109` are offered to mlm-architect as that amendment
content, and the fixtures pin them:

- MINI TREE (both strategies, provably identical placement = the sponsor
  tree, spread 0.00 for a reason that actually holds at width 3): all five
  lines exact (M1 on M2 6.00, on M3 4.00, on M4 4.00, on M5 at level 2
  2.00; M2 on M5 2.00). Company **18.00** (M1 16.00, M2 2.00) = 3.75
  percent of CV 480.00. Zero differences both directions.
- TEN-MEMBER TREE: per-member table exact (M1 97.20, M2 20.00, M3 66.00,
  M8 2.00, all others 0.00), company **185.20** = 8.5741 percent of CV,
  four members paid; strategy A and B placement maps IDENTICAL (checked row
  for row), both equal to the sponsor tree; M5's unqualified 12.00 claim on
  M9 is breakage.

## Stairstep worked examples: PASS

- MINI TREE: every differential exact (M1 8.00 on basis 480.00, M2 6.00 on
  160.00, M3 4.00, M4 4.00, all bracket_5pct), company **22.00** = 4.5833
  percent of CV, four members paid, no breakaways, no overrides. On this
  tree the four plans now read: unilevel 34.00, binary A 24.00, stairstep
  22.00, matrix 18.00.
- BREAKAWAY CHAIN (new seven-member fixture LAB-S1..S7, scenario
  PROOF-STAIR, built so every stairstep reason code fires with
  hand-checkable numbers): every line exact, both directions zero
  differences: differentials S1 8.00, S2 4.00, S3 20.00, S4 1,800.00
  (bracket 20 on basis 12,000.00 minus S5's 15-percent subtraction),
  S5 600.00, S6 2,400.00; overrides on S6's group (12,000.00 CV):
  generation 1 to S5 480.00 and generation 2 to S3 240.00 (across the S4
  boundary); on S4's group: generation 1 to S3 480.00 and NO generation 2
  (no boundary above), exactly the spec's "a breakaway found under a
  breakaway" clause. Company **6,032.00** = 24.4408 percent of CV (corrected 2026-08-16
  by the coordinator per the L2 verdict's adjudication: 6,032.00 / 24,680.00 = 24.44084...,
  fifth decimal 4, so 24.4408; originally printed 24.4409)
  24,680.00, six members paid, breakaway flags exactly S4 and S6.
- MONOTONICITY, asserted in the run output as demanded: the plan function
  computes the minimum differential over ALL members, RAISES if negative
  (the run refuses to complete), and records it on the run row; fixture
  runs carry "monotonicity asserted: minimum differential 2.0000 >= 0",
  census runs "... 0.0000 >= 0". The zero on census is a member whose
  differential rounds to exactly zero, non-negative as proven.

## Binary width-2 equivalence through the new placement code: PASS

Mini binary A 24.00, ten-member A 184.00 and B 168.00 (draft 0.20 rate),
re-run through `fn_derive_placement_width`: totals exact, zero differences
(MX2). The L1 numbers survive the generalization.

## Census runs, seeded March 2026: the comparison record

Latest completed identity-scenario run per recipe (runs 15 and 16 are the
verifier's own L1 reproduction runs; the determinism assertion confirms
they are byte-identical to this build's):

| Plan | Strategy | Rate recipe | Run | Payout | Percent of CV | Members paid |
|---|---|---|---|---|---|---|
| unilevel_v13 (baseline) | | 10/5/5/3/2 | 15 | 13,434.00 | **14.6085** | 206 |
| binary | bfs_spill | 0.20 draft | 16 | 25,784.00 | 28.0383 | 166 |
| binary | volume_balanced | 0.20 draft | 14 | 24,836.00 | 27.0074 | 145 |
| binary | bfs_spill | **0.105 ruled** | 28 | 15,129.40 | **16.4522** | 166 |
| binary | volume_balanced | **0.110 ruled** | 29 | 16,083.60 | **17.4898** | 145 |
| matrix_3x7 | bfs_spill | 5/5/4/4/3/2/2 | 31 | 15,039.20 | **16.3541** | 237 |
| matrix_3x7 | volume_balanced | 5/5/4/4/3/2/2 | 32 | 13,904.00 | **15.1196** | 240 |
| stairstep_breakaway | (sponsor tree) | 5/10/15/20, breakaway 15,000 | 34 | 21,025.60 | **22.8639** | 448 |

Shape notes the dashboard will surface: matrix pays MORE members than the
baseline (237 to 240 versus 206) at a similar size because flat depth 7 has
no rank gate; stairstep pays the MOST members by far (448: every qualified
member with any positive differential) and concentrates value in the top
brackets; binary pays the FEWEST (145 to 166: two-leg structure plus the
qualified gate).

## Cap binding, re-tested at the ruled rates (spec 4.2 v1.2 obligation)

| Run | Rate | Strategy | Capped lines | Capped remainder | Largest pay-leg CV |
|---|---|---|---|---|---|
| 12, 13, 16 | 0.20 | bfs_spill | 2 | 5,600.00 | 36,640.00 |
| 14 | 0.20 | volume_balanced | 3 | 6,268.00 | 28,520.00 |
| 28 | 0.105 | bfs_spill | 1 | 1,347.20 | 36,640.00 |
| 29 | 0.110 | volume_balanced | 2 | 1,023.60 | 28,520.00 |

The cap still binds at the ruled rates (the 36,640.00 whale leg pays
0.105 x 36,640.00 = 3,847.20, capped to 2,500.00).

**FINDING FOR THE ARCHITECT, the honest one: the ruled rates do NOT land the
calibration's own target.** Calibrated binary pays 16.4522 (A) and 17.4898
(B) percent of CV against the baseline's 14.6085: still 1.8 to 2.9 points
oversized. Cause, proven to the cent: the calibration rule is LINEAR
(pay_leg_rate scales every line proportionally) but the section 4.2 percents
it divided were CAPPED totals, and the cap is non-linear: at 0.20 the cap
withheld 5,600.00, at 0.105 only 1,347.20, so payout shrinks slower than
the rate. Verification: run 28's uncapped total = 15,129.40 + 1,347.20 =
16,476.60 = 0.525 x the uncapped 0.20 total (25,784.00 + 5,600.00 =
31,384.00), exactly. If size-parity to the cent is wanted, the calibration
must be solved on capped payouts (for strategy A, one whale line capped:
payout(r) = 120,280 x r + 2,500, giving r of about 0.0909, nearest 0.005 =
0.090); whether to iterate the rule or accept the residue is an architect
ruling, not a builder choice. Recorded here, spec untouched.

## Determinism: PASS

Pairwise assertion over ALL completed identity-scenario March runs (same
plan + parameters + strategy must agree on ordered line digest, ordered
result digest, and all four totals): **ZERO disagreements** across the
matrix pair (runs 30 and 31, lines_md5 identical), the stairstep pair (33
and 34), the L1 unilevel trio (3, 11, and the verifier's 15), the L1
binary-at-0.20 trio (12, 13, 16), and every other recipe. Order source and
snapshot as stated above.

## Reason-code coverage on the seeded month (the L2 gate's spot-check target)

Census runs 31 (matrix A), 32 (matrix B), 34 (stairstep):
`matrix_level_pay` 5,750 lines / 28,943.20; `stairstep_differential` 448
lines / 16,572.00; `stairstep_override_gen1` 2 lines / 3,560.00;
`stairstep_override_gen2` 1 line / 893.60. Every L2 reason code fires on
real census data, generation 2 included (the census has a breakaway nested
under a breakaway).

## Isolation, re-verified after everything

App inventory identical to the recorded baseline: 88 relations, 14
non-internal triggers, 17 functions, 185 grants, 10 policies. Zero new
app objects across the whole L2 apply-and-run.

## Performance

Census runs: stairstep 0.54 to 0.57 seconds; binary 1.46 to 2.45; matrix
1.93 to 2.27 (the file 007 ANALYZE discipline also cut the volume-balanced
placements from 10.27 seconds at L1 to about 2.4). Fixtures under 0.1
seconds.

## Interpretation flags for the architect (with the build's chosen readings)

1. **Override walk model** (file 011 header): per breakaway, walk up with a
   boundary counter; first qualified member at zero boundaries takes
   generation 1, first qualified member at one boundary takes generation 2,
   stop at two. Chosen because it makes the spec's parenthetical ("a
   breakaway found under a breakaway") exactly the condition under which a
   generation 2 payment exists. The PROOF-STAIR fixture pins the
   arithmetic; the verifier should hand-derive independently.
2. **Differential line columns**: a single rate-times-basis product cannot
   reproduce a differential when child brackets differ from the earner's.
   The build stores rate = earner's bracket rate, basis = own CV plus
   non-breakaway group CV, amount = the once-rounded differential, full
   decomposition recoverable from plan_metrics (gv, bracket, breakaway,
   group_cv per member). The section 1.2 invariant "amount = round(rate x
   basis, 2)" holds for every reason code EXCEPT stairstep_differential;
   the spec's own "basis = the signed net basis" wording acknowledges the
   deviation without defining it, and the architect should fix the wording.
3. **Matrix hand examples** are ready in the 108/109 headers for the "hand
   example appended to this spec" amendment; the builder did not touch the
   spec (standing instruction).
4. **Calibration residue** (the cap finding above): iterate or accept, and
   if iterated, per-strategy again.

## What the gates should probe hardest

- Independent hand recomputation of the PROOF-STAIR chain, especially the
  generation assignments (S3 receiving both a generation 1 on S4's group
  and a generation 2 on S6's group) and the bottom-up GV exclusion order
  (S4 breaks away only BECAUSE S5's group stayed; S5 keeps bracket 15 only
  because S6's group left).
- The freeze: try tampers this build did not think of (re-pointing a line's
  run_id from a running probe run into a complete run is guarded on both
  sides; verify).
- The matrix paid-depth boundary (level 7 versus 8) on a census member with
  deep placement, and the placement level map's cap (pairs beyond level 7
  are never materialized; leg metrics use a separate full-depth pass).
- The cap-residue arithmetic above, before anyone quotes "size held equal"
  from the ruled rates.

Every L2 proof above: PASS (with the 008-to-013 incident disclosed).
Phase L2 remains OPEN until mlm-verifier and QA say so.
