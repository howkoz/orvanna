-- Lab 111: L3 proof, scenario S1 (add one recruit under M2), spec 9.5 exactly
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 section 9.5. Requires db\lab\014 and 015.
--
-- S1: one mutation, add_member under M2 (LAB-M2 in the fixture base) with
-- volume profile 100.00 SV per month. Synthetic member LAB-S1-1, id
-- 10,000,001 by the spec 9.4 rule. Acceptance (draft binary rate 0.20, per
-- the v1.2 fixture ruling):
--   unilevel after: M1 34.00 (+4.00), M2 12.00 (+8.00), company 46.00
--     (+12.00); new lines only: M2 on LAB-S1-1 level 1 = 8.00, M1 on
--     LAB-S1-1 level 2 = 4.00.
--   binary A after: M1 16.00, M2 8.00, company 24.00, EVERY delta 0.00;
--     LAB-S1-1 spills to M4.left; flushed unmatched CV rises from 200.00 to
--     360.00, flushed value at the rate from 40.00 to 72.00.
-- Watched accounts LAB-M1 and LAB-M2; baselines are the mini-base identity
-- runs created here (plan-matched, named per section 8 question 11).
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).

do $$
declare
    v_id bigint;
begin
    -- Watchlist (idempotent).
    insert into lab.watchlist (member_ref, note)
    select x.ref, 'L3 proof watch'
    from (values ('LAB-M1'), ('LAB-M2')) x(ref)
    where not exists (select 1 from lab.watchlist w where w.member_ref = x.ref);

    -- Mini-base identity baseline runs (scenario PROOF-MINI, empty list).
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01', null, 'L3-BASE-MINI-UNILEVEL');
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'binary',
        '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01', null, 'L3-BASE-MINI-BINARY-A-020');

    -- Scenario S1: draft, one mutation, lock.
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('S1', 'Spec 9.5: add a 100-volume recruit under M2', 'draft',
            'The first prescribed hand example. Base = the section 6 mini tree.')
    on conflict (scenario_code) do nothing;

    insert into lab.scenario_mutations
        (scenario_id, seq, kind, target_ref, new_sponsor_ref, volume_profile)
    select s.id, 1, 'add_member', null, 'LAB-M2', '{"sv_per_month": 100.00}'::jsonb
    from lab.scenarios s
    where s.scenario_code = 'S1' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);

    update lab.scenarios set status = 'locked'
    where scenario_code = 'S1' and status = 'draft';

    -- The S1 runs, baselines named.
    v_id := lab.fn_run_mini_fixture('S1', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-UNILEVEL'),
        'L3-PROOF-S1-UNILEVEL');
    v_id := lab.fn_run_mini_fixture('S1', 'binary',
        '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-BINARY-A-020'),
        'L3-PROOF-S1-BINARY-A');
end
$$;

-- ---------------------------------------------------------------------------
-- S1A (must return ZERO rows): the replayed derived member, exactly the
-- spec 9.4 identity: code LAB-S1-1, id 10000001, sponsor LAB-M2, SV 100.00.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L3-PROOF-S1-UNILEVEL'
),
expected (member_id, member_code, sponsor_code, sv) as (
    values (10000001::bigint, 'LAB-S1-1', 'LAB-M2', 100.00::numeric)
),
actual as (
    select d.member_id, d.member_code, sp.member_code as sponsor_code, mv.sv
    from lab.derived_members d
    join lab.derived_members sp on sp.run_id = d.run_id and sp.member_id = d.sponsor_id
    join lab.member_volumes mv on mv.run_id = d.run_id and mv.member_id = d.member_id
    where d.run_id = (select run_id from run_under_test)
      and d.app_member_id is null and d.member_id >= 10000000
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- S1B (must return ZERO rows): unilevel lines after S1, all seven, both
-- directions, and the totals (company 46.00).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L3-PROOF-S1-UNILEVEL'
),
expected (earner_code, source_code, level, basis, rate, amount) as (
    values ('LAB-M1', 'LAB-M2',   1, 120.00::numeric, 0.10::numeric, 12.00::numeric),
           ('LAB-M1', 'LAB-M3',   1,  80.00::numeric, 0.10::numeric,  8.00::numeric),
           ('LAB-M1', 'LAB-M4',   1,  80.00::numeric, 0.10::numeric,  8.00::numeric),
           ('LAB-M1', 'LAB-M5',   2,  40.00::numeric, 0.05::numeric,  2.00::numeric),
           ('LAB-M1', 'LAB-S1-1', 2,  80.00::numeric, 0.05::numeric,  4.00::numeric),
           ('LAB-M2', 'LAB-M5',   1,  40.00::numeric, 0.10::numeric,  4.00::numeric),
           ('LAB-M2', 'LAB-S1-1', 1,  80.00::numeric, 0.10::numeric,  8.00::numeric)
),
actual as (
    select e.member_code, s.member_code, l.level, l.basis, l.rate, l.amount
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
    where l.run_id = (select run_id from run_under_test)
),
expected_totals (total_sv, total_cv, total_payout, members_paid) as (
    values (700.00::numeric, 560.00::numeric, 46.00::numeric, 2)
),
actual_totals as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
)
select 'line_diff' as check_kind, count(*) as n from (
    select * from actual except all select * from expected
    union all select * from expected except all select * from actual) x
union all
select 'totals_diff', count(*) from (
    select * from actual_totals except all select * from expected_totals
    union all select * from expected_totals except all select * from actual_totals) x;

-- ---------------------------------------------------------------------------
-- S1C (must return ZERO rows): binary A after S1: totals 24.00 unchanged,
-- the recruit spilled to M4.left, and flushed CV rose to 360.00 (value at
-- the rate 72.00).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L3-PROOF-S1-BINARY-A'
),
expected_place (member_code, parent_code, slot) as (
    values ('LAB-M1',   null::text, null::int),
           ('LAB-M2',   'LAB-M1', 0),
           ('LAB-M3',   'LAB-M1', 1),
           ('LAB-M4',   'LAB-M2', 0),
           ('LAB-M5',   'LAB-M2', 1),
           ('LAB-S1-1', 'LAB-M4', 0)
),
actual_place as (
    select m.member_code, p.member_code as parent_code, pm.slot
    from lab.placement_map pm
    join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
    left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
    where pm.run_id = (select run_id from run_under_test)
),
expected_scalars (total_payout, members_paid, flushed_cv_total) as (
    values (24.00::numeric, 2, 360.00::numeric)
),
actual_scalars as (
    -- Flushed CV summed over members WITH a pay line, exactly the spec 9.5
    -- arithmetic (240.00 + 120.00): a one-legged member's strong leg is
    -- no-pay, not flush, and the QA LOW-2 rule applies (compute from
    -- lines, never from flags alone).
    select r.total_payout, r.members_paid,
           (select sum((pr.plan_metrics ->> 'flushed_cv')::numeric)
            from lab.plan_run_results pr
            where pr.run_id = r.id
              and exists (select 1 from lab.plan_run_lines l
                          where l.run_id = pr.run_id
                            and l.earner_id = pr.member_id
                            and l.reason = 'binary_pay_leg')) as flushed_cv_total
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
)
select 'placement_diff' as check_kind, count(*) as n from (
    select * from actual_place except all select * from expected_place
    union all select * from expected_place except all select * from actual_place) x
union all
select 'scalars_diff', count(*) from (
    select * from actual_scalars except all select * from expected_scalars
    union all select * from expected_scalars except all select * from actual_scalars) x;

-- ---------------------------------------------------------------------------
-- S1D (must return ZERO rows): the watch snapshots. Unilevel: M1 +4.00 all
-- in from_added_members, M2 +8.00 likewise, decomposable true. Binary: both
-- deltas 0.00, decomposable false, bases unchanged (80.00 and 40.00).
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S1-UNILEVEL'),
bin_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S1-BINARY-A'),
expected (tag, member_ref, delta_earned, decomposable, from_added, level_shift,
          aggregate_delta, basis_before, basis_after) as (
    values ('U', 'LAB-M1', 4.00::numeric, true,  4.00::numeric, 0.00::numeric, null::numeric, null::numeric, null::numeric),
           ('U', 'LAB-M2', 8.00::numeric, true,  8.00::numeric, 0.00::numeric, null, null, null),
           ('B', 'LAB-M1', 0.00::numeric, false, 0.00::numeric, 0.00::numeric, 0.00::numeric, 80.00::numeric, 80.00::numeric),
           ('B', 'LAB-M2', 0.00::numeric, false, 0.00::numeric, 0.00::numeric, 0.00::numeric, 40.00::numeric, 40.00::numeric)
),
actual as (
    select case when ws.run_id = (select id from uni_run) then 'U' else 'B' end as tag,
           ws.member_ref,
           ws.delta_earned,
           (ws.delta_components ->> 'decomposable')::boolean,
           (ws.delta_components ->> 'from_added_members')::numeric,
           (ws.delta_components ->> 'from_level_shift')::numeric,
           (ws.delta_components ->> 'aggregate_delta')::numeric,
           (ws.delta_components ->> 'basis_before')::numeric,
           (ws.delta_components ->> 'basis_after')::numeric
    from lab.watch_snapshots ws
    where ws.run_id in ((select id from uni_run), (select id from bin_run))
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;
