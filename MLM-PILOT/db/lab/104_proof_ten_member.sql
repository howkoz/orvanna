-- Lab 104: L1 binary proof on the canonical ten-member month, BOTH strategies
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 sections 3.4 and 6.4, over the COMP-PLAN-SPEC
--       section 7 tree: M1 -> M2, M3, M4; M2 -> M5, M6; M3 -> M7, M8;
--       M5 -> M9; M8 -> M10.
-- Acceptance (spec 3.4 and 6.4, draft parameters):
--       strategy A ('bfs_spill') pays 184.00 company-wide
--           (M1 120.00 on pay leg 600.00; M2 40.00 on 200.00; M3 24.00 on
--            120.00; everyone else 0.00),
--       strategy B ('volume_balanced') pays 168.00
--           (M1 104.00 on 520.00; M2 24.00 on 120.00; M3 40.00 on 200.00),
--       spread A minus B = 16.00, with M2 and M3 trading places, visible in
--       lab.v_placement_spread with the derived-placement caption.
-- Bonus cross-check: unilevel on the same fixture must reproduce the
-- COMP-PLAN-SPEC section 7 company totals (payout 264.00, members paid 4),
-- which also validates the fixture volumes themselves.
--
-- Fixture mechanics identical to proof 103 (hand-built derived set, LAB-
-- codes, ascending ids 10000001..10000010 in M1..M10 order, order_source
-- 'hand_fixture', same computation path as census runs).
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).

do $$
declare
    v_scenario_id bigint;
    v_run_a   bigint;
    v_run_b   bigint;
    v_run_uni bigint;
    v_run     bigint;
begin
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('PROOF-TEN',
            'Proof fixture: canonical ten-member month (COMP-PLAN-SPEC section 7)',
            'locked',
            'Hand-built derived set inserted by db\lab\104_proof_ten_member.sql; '
            'not replayed from mutations (replay arrives in phase L3).')
    on conflict (scenario_code) do nothing;

    select id into v_scenario_id from lab.scenarios where scenario_code = 'PROOF-TEN';

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'binary',
            '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
            'bfs_spill',
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-TEN-BINARY-A')
    returning id into v_run_a;

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'binary',
            '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
            'volume_balanced',
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-TEN-BINARY-B')
    returning id into v_run_b;

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'unilevel_v13',
            '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-TEN-UNILEVEL')
    returning id into v_run_uni;

    foreach v_run in array array[v_run_a, v_run_b, v_run_uni] loop
        insert into lab.derived_members
            (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
        values
            (v_run, 10000001, 'LAB-M1',  null,     date '2026-01-01', null),
            (v_run, 10000002, 'LAB-M2',  10000001, date '2026-01-02', null),
            (v_run, 10000003, 'LAB-M3',  10000001, date '2026-01-03', null),
            (v_run, 10000004, 'LAB-M4',  10000001, date '2026-01-04', null),
            (v_run, 10000005, 'LAB-M5',  10000002, date '2026-01-05', null),
            (v_run, 10000006, 'LAB-M6',  10000002, date '2026-01-06', null),
            (v_run, 10000007, 'LAB-M7',  10000003, date '2026-01-07', null),
            (v_run, 10000008, 'LAB-M8',  10000003, date '2026-01-08', null),
            (v_run, 10000009, 'LAB-M9',  10000005, date '2026-01-09', null),
            (v_run, 10000010, 'LAB-M10', 10000008, date '2026-01-10', null);

        insert into lab.member_volumes (run_id, member_id, sv)
        values
            (v_run, 10000001,  200.00),
            (v_run, 10000002,  150.00),
            (v_run, 10000003,  100.00),
            (v_run, 10000004,  100.00),
            (v_run, 10000005,   50.00),
            (v_run, 10000006,  150.00),
            (v_run, 10000007, 1500.00),
            (v_run, 10000008,  100.00),
            (v_run, 10000009,  300.00),
            (v_run, 10000010,   50.00);

        perform lab.fn_execute_plan(v_run);
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- TEN1 (must return ZERO rows): strategy A placement tree versus spec 6.4
-- (spillover events: M4 to M2.left, M6 to M4.left).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-A'
),
expected (member_code, parent_code, slot) as (
    values ('LAB-M1',  null::text, null::int),
           ('LAB-M2',  'LAB-M1', 0),
           ('LAB-M3',  'LAB-M1', 1),
           ('LAB-M4',  'LAB-M2', 0),
           ('LAB-M5',  'LAB-M2', 1),
           ('LAB-M6',  'LAB-M4', 0),
           ('LAB-M7',  'LAB-M3', 0),
           ('LAB-M8',  'LAB-M3', 1),
           ('LAB-M9',  'LAB-M5', 0),
           ('LAB-M10', 'LAB-M8', 0)
),
actual as (
    select m.member_code, p.member_code as parent_code, pm.slot
    from lab.placement_map pm
    join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
    left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
    where pm.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- TEN2 (must return ZERO rows): strategy B placement tree, spec 6.4's named
-- divergence (M4 to M3.left because M1's right leg carried less volume).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-B'
),
expected (member_code, parent_code, slot) as (
    values ('LAB-M1',  null::text, null::int),
           ('LAB-M2',  'LAB-M1', 0),
           ('LAB-M3',  'LAB-M1', 1),
           ('LAB-M4',  'LAB-M3', 0),
           ('LAB-M5',  'LAB-M2', 0),
           ('LAB-M6',  'LAB-M2', 1),
           ('LAB-M7',  'LAB-M3', 1),
           ('LAB-M8',  'LAB-M4', 0),
           ('LAB-M9',  'LAB-M5', 0),
           ('LAB-M10', 'LAB-M8', 0)
),
actual as (
    select m.member_code, p.member_code as parent_code, pm.slot
    from lab.placement_map pm
    join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
    left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
    where pm.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- TEN3 (must return ZERO rows): the per-member table of spec 3.4 and 6.4,
-- BOTH strategies, every member, zero earners included.
-- ---------------------------------------------------------------------------
with run_a as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-A'
),
run_b as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-B'
),
expected (strategy, member_code, total_earned) as (
    values ('A', 'LAB-M1', 120.00::numeric), ('A', 'LAB-M2',  40.00::numeric),
           ('A', 'LAB-M3',  24.00::numeric), ('A', 'LAB-M4',   0.00::numeric),
           ('A', 'LAB-M5',   0.00::numeric), ('A', 'LAB-M6',   0.00::numeric),
           ('A', 'LAB-M7',   0.00::numeric), ('A', 'LAB-M8',   0.00::numeric),
           ('A', 'LAB-M9',   0.00::numeric), ('A', 'LAB-M10',  0.00::numeric),
           ('B', 'LAB-M1', 104.00::numeric), ('B', 'LAB-M2',  24.00::numeric),
           ('B', 'LAB-M3',  40.00::numeric), ('B', 'LAB-M4',   0.00::numeric),
           ('B', 'LAB-M5',   0.00::numeric), ('B', 'LAB-M6',   0.00::numeric),
           ('B', 'LAB-M7',   0.00::numeric), ('B', 'LAB-M8',   0.00::numeric),
           ('B', 'LAB-M9',   0.00::numeric), ('B', 'LAB-M10',  0.00::numeric)
),
actual as (
    select 'A' as strategy, m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_a)
    union all
    select 'B', m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_b)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- TEN4 (must return ZERO rows): company totals for both strategies
-- (A 184.00 = 8.52 percent of CV 2160.00; B 168.00), three members paid each.
-- ---------------------------------------------------------------------------
with expected (tag, total_sv, total_cv, total_payout, members_paid) as (
    values ('L1-PROOF-TEN-BINARY-A', 2700.00::numeric, 2160.00::numeric, 184.00::numeric, 3),
           ('L1-PROOF-TEN-BINARY-B', 2700.00::numeric, 2160.00::numeric, 168.00::numeric, 3)
),
actual as (
    select r.notes as tag, r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r
    where r.id in (
        (select max(id) from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-A'),
        (select max(id) from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-B'))
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- TEN5: the A-versus-B spread and the derived-placement caption, present in
-- the run output structure (spec 3.4). Expected: one row for the fixture
-- pair, spread_a_minus_b = 16.00, caption text populated, disclaimer
-- populated.
-- ---------------------------------------------------------------------------
select s.run_id_bfs_spill,
       s.run_id_volume_balanced,
       s.payout_bfs_spill,
       s.payout_volume_balanced,
       s.spread_a_minus_b,
       s.placement_caption,
       s.disclaimer
from lab.v_placement_spread s
where s.run_id_bfs_spill      = (select max(id) from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-A')
  and s.run_id_volume_balanced = (select max(id) from lab.plan_runs where notes = 'L1-PROOF-TEN-BINARY-B');

-- ---------------------------------------------------------------------------
-- TEN6 (must return ZERO rows): the bonus fixture-validation cross-check,
-- unilevel on the same ten members versus COMP-PLAN-SPEC section 7 totals.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-TEN-UNILEVEL'
),
expected (total_sv, total_cv, total_payout, members_paid) as (
    values (2700.00::numeric, 2160.00::numeric, 264.00::numeric, 4)
),
actual as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;
