# The Comp Plan Lab, database layer (`db\lab\`)

Phases L1 through L3 of the Comp Plan Lab: the plan engine interface, all
FOUR launch plans (unilevel baseline, binary with both placement
strategies, matrix 3 by 7, stairstep-breakaway), the completed-run freeze,
SCENARIOS (the five mutation kinds, replay, stacking to depth 3, month
scoping), and WATCHED ACCOUNTS (per-run snapshots with decomposed deltas).
Built by mlm-comp-engineer, 2026-08-16, to `docs\COMP-LAB-SPEC.md` version
1.3 (THE LAW; read it before touching anything here). L1 and L2 closed both
gates 2026-08-16; L3 gates pending.

Acronym key: Multi-Level Marketing (MLM), Structured Query Language (SQL),
Sales Volume (SV), Commissionable Volume (CV), Row-Level Security (RLS),
Breadth-First Search (BFS), Quality Assurance (QA).

## The one-sentence safety model

Everything lab lives in schema `lab`; schema `lab` has ZERO grants for any
public-facing role; no lab function writes to schema `app`; the status value
`'final'` does not exist in the lab; every synthetic member code starts with
`'LAB-'`; every run row carries a generated what-if disclaimer that cannot
be edited away.

## Files, in run order

| File | What it is |
|---|---|
| `001_lab_schema.sql` | Schema `lab`, all ten tables, the discipline triggers (scenario lock and freeze, registry no-delete, locked-scenario-only runs), the IDENTITY scenario row, the `v_placement_spread` view, RLS on everything with zero policies, the zero-grant wall, and the verification queries. ISOLATION IS THE FIRST THING BUILT. |
| `002_lab_derivation.sql` | The derivation layer: `lab.fn_derive_members` (census snapshot; refuses any scenario mutation loudly until phase L3), `lab.fn_build_level_map` (run-scoped ancestor pairs over the DERIVED tree), `lab.fn_snapshot_volumes` (the month's SV per derived member, engine query shape). |
| `003_lab_placement.sql` | The derived binary placement: `lab.fn_derive_placement` implementing strategy A `'bfs_spill'` and strategy B `'volume_balanced'`, plus the leg-weight helper. Read its header for the two documented rulings (extra roots; the deliberate per-member loop). |
| `004_lab_plan_unilevel.sql` | Plan `'unilevel_v13'` through the lab interface: the real engine's computation reimplemented over the lab snapshots, rates from `plan_params`. |
| `005_lab_plan_binary.sql` | Plan `'binary'`: pay-leg pay with flush, cap, qualified gate, empty leg pays zero; per-member leg metrics in `plan_metrics`. |
| `006_lab_run_plan.sql` | `lab.fn_execute_plan` (the shared computation path) and `lab.fn_run_plan` (the spec 1.1 entry point; fifth defaulted parameter names the scenario, default IDENTITY). |
| `007_lab_analyze_snapshots.sql` | Redefines `fn_execute_plan` to ANALYZE each run-scoped snapshot after materializing it (real incident during the proof run: empty-table planner statistics; see its header). |
| `008_lab_run_freeze.sql` | Phase L2 (QA finding MEDIUM-1): completed run rows freeze (only complete-to-archived, otherwise-unchanged, is permitted), and every run-scoped child table freezes with them, both directions. |
| `009_lab_placement_width.sql` | Placement generalized to width N for the matrix; the two-slot entry point delegates at width 2 so binary is byte-identical (equivalence re-proven in proof 108). |
| `010_lab_plan_matrix.sql` | Plan `'matrix_3x7'`: placement-tree level pay, rates 5/5/4/4/3/2/2 percent, flat paid depth 7 for qualified members; three-leg CV metrics per member. |
| `011_lab_plan_stairstep.sql` | Plan `'stairstep_breakaway'`: bottom-up Group Volume (GV) with breakaway exclusion, bracket differential rounded once at the line, generation 1 and 2 overrides, and an executable monotonicity assertion recorded in the run notes. Read its header for the two interpretation flags. |
| `012_lab_execute_plan_l2.sql` | The dispatcher covers all four plans; matrix places at its plan_params width. |
| `013_lab_run_freeze_fix.sql` | Freeze fix found by the probe itself: BEFORE UPDATE triggers see stored GENERATED columns of NEW as not yet computed, so 008's archive equality test had to exclude them (over-strict, never leaky; see header). |
| `014_lab_scenario_replay.sql` | Phase L3: the mutation machinery. Effective-list flattening (root-first, seq order), replay of all five kinds with loud refusals (missing refs, root removal, cycles), the ratified remove_member roll-up, month scoping, synthetic identities per spec 9.4, `sv_override` as the one volume path, lock-time shape validation and the depth-3 stack cap. Read its five design decisions. |
| `015_lab_watch_snapshots.sql` | Phase L3: `lab.watch_snapshots` (freeze-covered), the soft-cap warning, `fn_write_watch_snapshots` (six-bucket decomposition joined by member code, aggregate basis movements, the bucket-sum-equals-delta invariant enforced in code), `fn_run_plan` v2 with the named-baseline sixth parameter, and the mini-base fixture support (`fn_load_mini_base`, `fn_run_mini_fixture`). |
| `100_proof_isolation.sql` | L1 isolation proof: app inventory unchanged, zero grants, RLS on, no writes to app, `'final'` impossible, name wall holds, no deletes. |
| `101_proof_identity.sql` | Creates the March 2026 census unilevel run and proves the identity scenario's derived set equals the census row for row. |
| `102_proof_parity.sql` | Lab unilevel versus the REAL finalized March run: every line, both totals, member results with the one explained GW-000 census-drift row. |
| `103_proof_minitree.sql` | The architect's five-member hand example: unilevel 34.00 (M1 30.00, M2 4.00), binary A 24.00 (M1 16.00, M2 8.00), plus the informational strategy B run (spec 6.3 inconsistency, see the file header). |
| `104_proof_ten_member.sql` | The canonical ten-member month: strategy A 184.00, strategy B 168.00, exact placement trees and per-member tables, the A-versus-B spread and caption, and the 264.00 unilevel cross-check. |
| `105_proof_determinism.sql` | Same inputs, two runs, identical digests over fully ordered output, for unilevel and binary A on seeded March. |
| `106_calibration_march.sql` | The spec 4.2 calibration rule on seeded March, both strategies, plus the census-month spread. |
| `107_proof_freeze.sql` | The refused-update probe: tamper a completed run and its child rows (refused), archive it (allowed), tamper the archived row (refused). |
| `108_proof_matrix_fixtures.sql` | Matrix hand examples on the mini and ten-member trees (both strategies), plus the binary width-2 equivalence re-runs at the draft 0.20 rate. |
| `109_proof_stairstep_fixtures.sql` | Stairstep hand examples: the mini tree (no breakaways) and the seven-member PROOF-STAIR breakaway chain that exercises every stairstep reason code including generation 2. |
| `110_census_l2_runs.sql` | Census March runs at the ruled binary rates (0.105 / 0.110), matrix and stairstep census runs, determinism digests, the four-plan comparison record, the cap-binding re-test, reason-code coverage, and the isolation re-check. |
| `111_proof_scenario_s1.sql` | Spec 9.5 replayed by the real machinery: LAB-S1-1 (id 10,000,001) under M2, unilevel 46.00 with deltas +4.00/+8.00 in from_added_members, binary spill to M4.left with zero deltas and flush rising to 360.00. |
| `112_proof_scenario_s2.sql` | Spec 10.3 exactly: the four watched rows, M1 losing 4.00 (pure level shift) under unilevel and doubling 16.00 to 32.00 under binary A with basis movements gained [M2, M5] lost [M3]. |
| `113_proof_stack_and_months.sql` | The stacked scenario S1X (unilevel 50.00, binary A 40.00; M1's watch row = +4.00 added minus 4.00 shifted = 0.00), month-scoped removal (July present, August gone), the depth-4 lock refusal, and the root-removal replay refusal. |
| `114_proof_l3_sweep.sql` | Five recipes (unilevel, binary A/B at ruled rates, matrix A, stairstep) over S1, S2, and the stack; SEMANTIC code-keyed determinism over every same-recipe pair plus BYTE-ORDER determinism for the same-flow duplicates; the spec 10.2 component invariant over all snapshots; the isolation re-check with the subscriptions-build attribution note. |

Recorded proof output: `..\..\docs\verification\LAB-L1-PROOF-RUN-2026-08-16.md`,
`..\..\docs\verification\LAB-L2-PROOF-RUN-2026-08-16.md`, and
`..\..\docs\verification\LAB-L3-PROOF-RUN-2026-08-16.md`.

## How to run everything, from nothing

Prerequisites: migrations 001..022 applied, the comp engine applied, the
seed loaded, the six seeded months run and finalized (see `db\README.md`).
Run as the service role or database owner; RLS blocks everyone else by
design.

1. Apply `001` through `013` in order (each is a plain SQL file; on the live
   project they were applied as migrations `comp_lab_l1_001_schema` ..
   `comp_lab_l1_007_analyze_snapshots` and `comp_lab_l2_008_run_freeze` ..
   `comp_lab_l2_013_run_freeze_fix`).
2. Run `100_proof_isolation.sql` and check every listed expectation (zero
   rows or PASS notices).
3. Run `101` then `102` (identity, then parity; 101 creates the run 102
   compares).
4. Run `103` and `104` (the fixtures; re-runnable, each rerun appends new
   runs and the checks read the latest by notes tag).
5. Run `105` then `106` (determinism pair runs, then calibration).
6. Run `107` (freeze probe), `108` and `109` (matrix and stairstep hand
   examples), then `110` (L2 census runs and the comparison record).
7. Run `111`, `112`, `113`, `114` in order (S1, S2, the stack and month
   probes, then the five-recipe sweep; 111 creates the watchlist and the
   mini-base baselines the later scripts name).

To run a plan ad hoc:

```sql
select lab.fn_run_plan(date '2026-03-01', 'unilevel_v13',
                       '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb,
                       null);

select lab.fn_run_plan(date '2026-03-01', 'binary',
                       '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00,
                         "pay_leg": "weaker", "carryover": "flush",
                         "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
                       'bfs_spill');
```

Binary months must be run under BOTH strategies (`'bfs_spill'` and
`'volume_balanced'`); `lab.v_placement_spread` then shows the pair side by
side with the derived-placement caption. A rerun with identical inputs
appends a NEW run with identical output; runs are never edited or deleted
(`'archived'` hides one from default reporting).

## Gotchas

- **Long statements**: the census binary runs take 1 to 11 seconds on 1,001
  members; management-interface sessions with an 8-second statement timeout
  need `set local statement_timeout = '180s';` in the same transaction.
- **The lab-to-app foreign key**: `lab.derived_members.app_member_id`
  references `app.members(id)` (spec-sanctioned). While lab rows exist, a
  TRUNCATE of `app.members` (fresh-rebuild script `db\comp\003`) refuses
  loudly until lab run data is cleared. That refusal is intentional.
- **Scenario mutations are phase L3**: any scenario whose effective list
  carries a mutation fails `lab.fn_derive_members` loudly. Only IDENTITY
  (and the hand-built proof fixtures) run in L1.
- **Fixture scenarios** `PROOF-MINI`, `PROOF-TEN`, and `PROOF-STAIR` are
  locked rows whose derived sets are inserted by the proof scripts, not
  replayed; they exist so the hand examples exercise the exact production
  computation path.
- **Completed runs are frozen** (files 008 and 013): tampering with a
  completed run's row or any of its run-scoped child rows is refused by
  trigger; the only permitted change is complete to archived with every
  other column untouched. Fixture scripts insert child rows only while the
  run is 'running'.
- **Stairstep appends to run notes** (the monotonicity assertion), so proof
  queries that find runs by notes tag must match by PREFIX
  (`notes like 'TAG%'`), never by equality.
- **Binary rates**: census-scale comparison runs use the RULED per-strategy
  rates (0.105 bfs_spill, 0.110 volume_balanced, spec v1.2); the section 6
  hand examples and their fixture proofs deliberately stay at the draft
  0.20. Every run records its rate in plan_params.
- **Scenario workflow**: insert the scenario as DRAFT, insert its mutations,
  then lock (the lock validates shape, profile grain, and the depth-3 cap;
  existence and cycles are checked at replay and fail the run loudly).
  Volume profiles are non-negative multiples of 50.00, either
  {"sv_per_month": X} or a per-month map.
- **Fixture base ids are 1..5** (LAB- codes, `sv_override` volumes) so the
  normative synthetic id rule (10,000,000 + ordinal) cannot collide; the
  L1/L2 fixture runs used 10000001..5 and are frozen history, which is why
  cross-run comparisons join by member CODE, never by id.
