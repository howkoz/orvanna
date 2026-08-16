-- Lab 115: plan five gate fixture, the ten-member worked example (spec section 10)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: ORVANNA-BUILDER-PLAN-SPEC.md sections 10 and 13. Requires db\lab\016
--       and 017. Acceptance, to the cent: spine 264.00 identical to unilevel
--       (M1 114.00 over 9 lines, M2 16.00 over 2, M3 130.00 over 3, M8 4.00
--       over 1); layer 2 one line, M1 on Builder M3, basis 1,400.00 at 0.04
--       = 56.00; layer 3 M1 29.90 (basis 520.00 at 0.0575, multiplier 1.15)
--       and M3 4.40 FLOORED (pieces 4.00 + 0.40, the M10 piece prorated);
--       company 354.30 = 16.4028 percent of CV 2,160.00, four paid; and THE
--       M10 CAP-BINDING ROW: pool 10.00, spine 8.00, override piece 1.60 at
--       f2 = 1, bonus claim 2.00 at f3 = 0.200000 paying 0.40, source total
--       exactly 10.00. The Law B invariant sweep must count ZERO violations.
-- Acronym key: Commissionable Volume (CV).

do $$
declare
    v_scenario_id bigint;
    v_run bigint;
begin
    select id into v_scenario_id from lab.scenarios where scenario_code = 'PROOF-TEN';

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'orvanna_builder',
            '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
            null, date '2026-07-01', 'running', 'hand_fixture', 'P5-PROOF-TEN')
    returning id into v_run;

    insert into lab.derived_members
        (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id, sv_override)
    values
        (v_run, 1,  'LAB-M1',  null, date '2026-01-01', null,  200.00),
        (v_run, 2,  'LAB-M2',  1,    date '2026-01-02', null,  150.00),
        (v_run, 3,  'LAB-M3',  1,    date '2026-01-03', null,  100.00),
        (v_run, 4,  'LAB-M4',  1,    date '2026-01-04', null,  100.00),
        (v_run, 5,  'LAB-M5',  2,    date '2026-01-05', null,   50.00),
        (v_run, 6,  'LAB-M6',  2,    date '2026-01-06', null,  150.00),
        (v_run, 7,  'LAB-M7',  3,    date '2026-01-07', null, 1500.00),
        (v_run, 8,  'LAB-M8',  3,    date '2026-01-08', null,  100.00),
        (v_run, 9,  'LAB-M9',  5,    date '2026-01-09', null,  300.00),
        (v_run, 10, 'LAB-M10', 8,    date '2026-01-10', null,   50.00);

    perform lab.fn_replay_mutations(v_run);
    perform lab.fn_snapshot_volumes(v_run);
    perform lab.fn_execute_plan(v_run);
end
$$;

-- ---------------------------------------------------------------------------
-- P5-T1 (every count must be 0): non-spine lines, per-earner spine totals,
-- per-member table, company totals.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'P5-PROOF-TEN'
),
exp_lines (earner_code, source_code, basis, rate, amount, reason) as (
    values ('LAB-M1', 'LAB-M3', 1400.00::numeric, 0.04::numeric,   56.00::numeric, 'builder_override_gen1'),
           ('LAB-M1', null,      520.00::numeric, 0.0575::numeric, 29.90::numeric, 'builder_second_leg_bonus'),
           ('LAB-M3', null,      120.00::numeric, 0.05::numeric,    4.40::numeric, 'builder_second_leg_bonus')
),
act_lines as (
    select e.member_code, s.member_code, l.basis, l.rate, l.amount, l.reason
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    left join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
    where l.run_id = (select run_id from run_under_test)
      and l.reason <> 'builder_spine_level_pay'
),
exp_spine (earner_code, spine_total, n_lines) as (
    values ('LAB-M1', 114.00::numeric, 9::bigint), ('LAB-M2', 16.00::numeric, 2),
           ('LAB-M3', 130.00::numeric, 3), ('LAB-M8', 4.00::numeric, 1)
),
act_spine as (
    select e.member_code, sum(l.amount), count(*)
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    where l.run_id = (select run_id from run_under_test)
      and l.reason = 'builder_spine_level_pay'
    group by e.member_code
),
exp_member (member_code, total_earned) as (
    values ('LAB-M1', 199.90::numeric), ('LAB-M2', 16.00::numeric),
           ('LAB-M3', 134.40::numeric), ('LAB-M4', 0.00::numeric),
           ('LAB-M5', 0.00::numeric), ('LAB-M6', 0.00::numeric),
           ('LAB-M7', 0.00::numeric), ('LAB-M8', 4.00::numeric),
           ('LAB-M9', 0.00::numeric), ('LAB-M10', 0.00::numeric)
),
act_member as (
    select m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_under_test)
),
exp_totals (total_sv, total_cv, total_payout, members_paid) as (
    values (2700.00::numeric, 2160.00::numeric, 354.30::numeric, 4)
),
act_totals as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
)
select 'nonspine_lines_diff' as check_kind, count(*) as n from (
    select * from act_lines except all select * from exp_lines
    union all select * from exp_lines except all select * from act_lines) x
union all
select 'spine_totals_diff', count(*) from (
    select * from act_spine except all select * from exp_spine
    union all select * from exp_spine except all select * from act_spine) x
union all
select 'member_diff', count(*) from (
    select * from act_member except all select * from exp_member
    union all select * from exp_member except all select * from act_member) x
union all
select 'company_totals_diff', count(*) from (
    select * from act_totals except all select * from exp_totals
    union all select * from exp_totals except all select * from act_totals) x;

-- ---------------------------------------------------------------------------
-- P5-T2: the M10 boundary row (expected: pool 10.000000, spine 8.00, layer 2
-- claim 1.600000 at f2 = 1, layer 3 claim 2.000000 at f3 = 0.200000 paying
-- 0.400000, total_paid 10.000000, invariant_violations 0).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'P5-PROOF-TEN'
)
select m.member_code,
       pr.plan_metrics -> 'source' ->> 'pool'          as pool,
       pr.plan_metrics -> 'source' ->> 'spine_claimed' as spine,
       pr.plan_metrics -> 'source' ->> 'l2_claimed'    as l2_claimed,
       pr.plan_metrics -> 'source' ->> 'f2'            as f2,
       pr.plan_metrics -> 'source' ->> 'l3_claimed'    as l3_claimed,
       pr.plan_metrics -> 'source' ->> 'f3'            as f3,
       pr.plan_metrics -> 'source' ->> 'l3_paid'       as l3_paid,
       ((pr.plan_metrics -> 'source' ->> 'spine_claimed')::numeric
        + (pr.plan_metrics -> 'source' ->> 'l2_paid')::numeric
        + (pr.plan_metrics -> 'source' ->> 'l3_paid')::numeric) as total_paid,
       (select count(*) from lab.plan_run_results pr2
        where pr2.run_id = pr.run_id
          and (pr2.plan_metrics -> 'source' ->> 'spine_claimed')::numeric
            + (pr2.plan_metrics -> 'source' ->> 'l2_paid')::numeric
            + (pr2.plan_metrics -> 'source' ->> 'l3_paid')::numeric
            > (pr2.plan_metrics -> 'source' ->> 'pool')::numeric) as invariant_violations
from lab.plan_run_results pr
join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
where pr.run_id = (select run_id from run_under_test)
  and m.member_code = 'LAB-M10';
