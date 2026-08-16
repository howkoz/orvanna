-- Lab 106: the L1 calibration run, seeded March 2026, and the census spread
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 4.2 (the deterministic calibration
--       rule, applied once at the L1 gate) and Howard's ruling on section 8
--       question 3: "accept the calibration rule's output on seeded March;
--       this spec is amended with the number the same day."
--
-- THE RULE: run March 2026 (the first full seeded month) under both plans,
-- then pay_leg_rate* = 0.20 x (unilevel percent of CV / binary percent of
-- CV), rounded to the NEAREST 0.005, recorded in the run parameters and in
-- the spec by amendment.
--
-- SCOPE NOTE, honest: this builder computes and records the number here and
-- in the proof document. The SPEC amendment itself belongs to mlm-architect
-- (this build is under instruction not to edit docs\COMP-LAB-SPEC.md), and
-- the rule does not name WHICH placement strategy calibrates, so the number
-- is computed against BOTH and flagged as an open point for the architect's
-- amendment. Runs at the calibrated rate are for AFTER that amendment.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).

-- ---------------------------------------------------------------------------
-- The strategy-B March census run (unilevel March and binary A March already
-- exist from proofs 101 and 105; the lab launch requirement is BOTH
-- strategies for every binary month, spec 3.4).
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01',
                       'binary',
                       '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
                       'volume_balanced') as binary_b_run;

-- ---------------------------------------------------------------------------
-- CAL1: percent of CV per plan on seeded March, and the calibrated rate
-- against each binary strategy, rounded to the nearest 0.005.
-- ---------------------------------------------------------------------------
with runs as (
    select r.plan_code,
           r.placement_strategy,
           max(r.id) as run_id
    from lab.plan_runs r
    where r.period = date '2026-03-01'
      and r.status = 'complete'
      and r.scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
    group by r.plan_code, r.placement_strategy
),
figures as (
    select ru.plan_code,
           ru.placement_strategy,
           pr.total_payout,
           pr.total_cv,
           round(100.0 * pr.total_payout / pr.total_cv, 4) as pct_of_cv
    from runs ru
    join lab.plan_runs pr on pr.id = ru.run_id
)
select f.plan_code,
       f.placement_strategy,
       f.total_payout,
       f.total_cv,
       f.pct_of_cv,
       case when f.plan_code = 'binary' then
            round((0.20 * (select u.pct_of_cv from figures u where u.plan_code = 'unilevel_v13')
                        / f.pct_of_cv) / 0.005) * 0.005
       end as calibrated_pay_leg_rate
from figures f
order by f.plan_code, f.placement_strategy;

-- ---------------------------------------------------------------------------
-- CAL2: the census-month A-versus-B spread, from the run output structure
-- (lab.v_placement_spread), caption and disclaimer included: the realistic-
-- depth counterpart of proof TEN5.
-- ---------------------------------------------------------------------------
select s.period,
       s.run_id_bfs_spill,
       s.run_id_volume_balanced,
       s.payout_bfs_spill,
       s.payout_volume_balanced,
       s.spread_a_minus_b,
       round(100.0 * s.spread_a_minus_b / s.payout_bfs_spill, 2) as spread_pct_of_a,
       s.placement_caption
from lab.v_placement_spread s
where s.period = date '2026-03-01'
  and s.scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
order by s.run_id_bfs_spill desc, s.run_id_volume_balanced desc
limit 1;
