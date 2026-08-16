-- Lab 118: plan five on seeded March, the calibration, and the six-recipe record
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: ORVANNA-BUILDER-PLAN-SPEC.md sections 9 (calibration budget), 12
--       (metric 5, pool pressure), 13 (layer 1 equality gate on a seeded
--       month). Requires db\lab\016 and 017.
--
-- Sequence run and recorded (session of 2026-08-16, run ids on the live
-- project noted in the proof document):
--   1. DRAFT census run (rates 0.04 / 0.02 / 0.05): 21.9712 percent of CV,
--      an increment of 7.3627 points over the 14.6085 baseline, far outside
--      the 2.0 to 4.0 budget: the census is DENSER in nested Builders than
--      section 9 guessed (333 of 1,001 sources at f2 < 1).
--   2. The section 9 one-shot rule: common factor 3.0 / 7.3627 = 0.4075;
--      gen1 0.04 -> 0.015, gen2 0.02 -> 0.010, second_leg 0.05 -> 0.020
--      (each nearest 0.005).
--   3. CALIBRATED census run twice (determinism pair): 18.9399 percent of
--      CV, increment 4.3314 points, just ABOVE the window's 4.0 ceiling:
--      proration relief is non-linear (120 sources at f2 < 1 instead of
--      333), the same cap non-linearity the binary calibration met. The
--      one-shot rule was applied exactly as written; the residue is
--      RECORDED AND DISPLAYED, never hidden, and whether to iterate the
--      rule is an architect ruling (proof document, flag 1).
-- Acronym key: Commissionable Volume (CV), Message Digest 5 (MD5).

set local statement_timeout = '300s';

-- The draft census run.
select lab.fn_run_plan(date '2026-03-01', 'orvanna_builder',
    '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
    null) as orvanna_census_draft;

-- The calibrated census runs (the determinism pair).
select lab.fn_run_plan(date '2026-03-01', 'orvanna_builder',
    '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.015, "gen2_rate": 0.010, "second_leg_rate": 0.020, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"], "calibration": "factor 0.4075 = 3.0 / 7.3627 measured increment, spec section 9, applied 2026-08-16"}'::jsonb,
    null) as orvanna_census_calibrated_1;

select lab.fn_run_plan(date '2026-03-01', 'orvanna_builder',
    '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.015, "gen2_rate": 0.010, "second_leg_rate": 0.020, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"], "calibration": "factor 0.4075 = 3.0 / 7.3627 measured increment, spec section 9, applied 2026-08-16"}'::jsonb,
    null) as orvanna_census_calibrated_2;

-- ---------------------------------------------------------------------------
-- C1 (must be zero): layer 1 equality on the seeded month: the draft run's
-- spine lines versus the lab 'unilevel_v13' March run (run 15), both
-- directions on (earner, source, level, basis, rate, amount). Substitute
-- the draft run's id for :draft_run.
-- ---------------------------------------------------------------------------
-- with spine as (
--     select earner_id, source_member_id, level, basis, rate, amount
--     from lab.plan_run_lines where run_id = :draft_run and reason = 'builder_spine_level_pay'),
-- uni as (
--     select earner_id, source_member_id, level, basis, rate, amount
--     from lab.plan_run_lines where run_id = 15)
-- select count(*) from (
--     select * from spine except all select * from uni
--     union all select * from uni except all select * from spine) x;

-- ---------------------------------------------------------------------------
-- C2: determinism (the two calibrated runs must share the ordered lines
-- digest and every total), the Law B invariant sweep (zero violations), the
-- pool-pressure record (spec metric 5), and the cap re-check at both rate
-- sets. Substitute the run ids.
-- ---------------------------------------------------------------------------
-- (Queries as executed are recorded with their outputs in
--  docs\verification\PLAN5-PROOF-RUN-2026-08-16.md.)

-- ---------------------------------------------------------------------------
-- C3: the six-recipe comparison record on seeded March (lab spec section 5
-- metrics: percent of CV, members paid, Gini over all members, top-10-percent
-- share), one row per recipe's latest run: unilevel 15, binary 28 and 29 at
-- the ruled rates, matrix 31, stairstep 34, plan five calibrated.
-- ---------------------------------------------------------------------------
with recipes (run_id, recipe) as (
    values (15, 'unilevel_v13 (baseline)'),
           (28, 'binary bfs_spill 0.105'),
           (29, 'binary volume_balanced 0.110'),
           (31, 'matrix_3x7 bfs_spill'),
           (34, 'stairstep_breakaway'),
           ((select max(id) from lab.plan_runs
             where plan_code = 'orvanna_builder' and period = date '2026-03-01'
               and status = 'complete'
               and plan_params ->> 'gen1_rate' = '0.015'), 'orvanna_builder calibrated')
),
per_run as (
    select rc.run_id, rc.recipe, pr.member_id, pr.total_earned,
           count(*) over (partition by rc.run_id) as n,
           row_number() over (partition by rc.run_id order by pr.total_earned desc, pr.member_id) as rn_desc,
           row_number() over (partition by rc.run_id order by pr.total_earned asc, pr.member_id) as rn_asc
    from recipes rc
    join lab.plan_run_results pr on pr.run_id = rc.run_id
),
gini as (
    select run_id, recipe, max(n) as n,
           round((2 * sum(rn_asc * total_earned)) / (max(n) * nullif(sum(total_earned), 0))
                 - (max(n) + 1.0) / max(n), 4) as gini,
           round(sum(total_earned) filter (where rn_desc <= ceil(0.10 * n)) /
                 nullif(sum(total_earned), 0) * 100, 2) as top10_share_pct
    from per_run
    group by run_id, recipe
)
select g.recipe, r.total_payout,
       round(100.0 * r.total_payout / r.total_cv, 4) as pct_of_cv,
       r.members_paid, g.gini, g.top10_share_pct
from gini g
join lab.plan_runs r on r.id = g.run_id
order by pct_of_cv;
