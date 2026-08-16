# The Comp Plan Lab, database layer (`db\lab\`)

Phase L1 of the Comp Plan Lab: the plan engine interface, the scenario
derivation layer carrying the IDENTITY scenario, the reimplemented unilevel
baseline, and the binary plan with BOTH placement strategies. Built by
mlm-comp-engineer, 2026-08-16, to `docs\COMP-LAB-SPEC.md` version 1.1 (THE
LAW; read it before touching anything here).

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
| `100_proof_isolation.sql` | L1 isolation proof: app inventory unchanged, zero grants, RLS on, no writes to app, `'final'` impossible, name wall holds, no deletes. |
| `101_proof_identity.sql` | Creates the March 2026 census unilevel run and proves the identity scenario's derived set equals the census row for row. |
| `102_proof_parity.sql` | Lab unilevel versus the REAL finalized March run: every line, both totals, member results with the one explained GW-000 census-drift row. |
| `103_proof_minitree.sql` | The architect's five-member hand example: unilevel 34.00 (M1 30.00, M2 4.00), binary A 24.00 (M1 16.00, M2 8.00), plus the informational strategy B run (spec 6.3 inconsistency, see the file header). |
| `104_proof_ten_member.sql` | The canonical ten-member month: strategy A 184.00, strategy B 168.00, exact placement trees and per-member tables, the A-versus-B spread and caption, and the 264.00 unilevel cross-check. |
| `105_proof_determinism.sql` | Same inputs, two runs, identical digests over fully ordered output, for unilevel and binary A on seeded March. |
| `106_calibration_march.sql` | The spec 4.2 calibration rule on seeded March, both strategies, plus the census-month spread. |

Recorded proof output: `..\..\docs\verification\LAB-L1-PROOF-RUN-2026-08-16.md`.

## How to run everything, from nothing

Prerequisites: migrations 001..022 applied, the comp engine applied, the
seed loaded, the six seeded months run and finalized (see `db\README.md`).
Run as the service role or database owner; RLS blocks everyone else by
design.

1. Apply `001` through `007` in order (each is a plain SQL file; on the live
   project they were applied as migrations `comp_lab_l1_001_schema` ..
   `comp_lab_l1_007_analyze_snapshots`).
2. Run `100_proof_isolation.sql` and check every listed expectation (zero
   rows or PASS notices).
3. Run `101` then `102` (identity, then parity; 101 creates the run 102
   compares).
4. Run `103` and `104` (the fixtures; re-runnable, each rerun appends new
   runs and the checks read the latest by notes tag).
5. Run `105` then `106` (determinism pair runs, then calibration).

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
- **Fixture scenarios** `PROOF-MINI` and `PROOF-TEN` are locked rows whose
  derived sets are inserted by the proof scripts, not replayed; they exist
  so the section 6 hand examples exercise the exact production computation
  path.
