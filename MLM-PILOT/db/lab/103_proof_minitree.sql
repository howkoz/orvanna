-- Lab 103: L1 mini-tree proof, the architect's five-member hand-computed example
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 6: keep M1..M5 of the canonical
--       ten-member tree; sponsor tree M1 -> M2, M3, M4 and M2 -> M5.
--       Acceptance: unilevel company 34.00 (M1 30.00, M2 4.00); binary
--       strategy A company 24.00 (M1 16.00, M2 8.00).
--
-- HOW THE FIXTURE WORKS. The five members are not census members, so the
-- run's derived member set and volume snapshot are inserted BY HAND here
-- (order_source 'hand_fixture' on the run row, per the engineer charter's
-- order-source rule), then lab.fn_execute_plan runs the SAME computation
-- path census runs use: level map, placement, plan, totals. Only the
-- census-derivation and census-volume steps are bypassed, and those are
-- exactly what proofs 101 and 102 cover on the real census. Member codes
-- carry the mandatory 'LAB-' prefix (the name wall): LAB-M1 is the spec's
-- M1, and so on. Ids 10000001..10000005 ascend in M1..M5 order so the
-- ascending-id placement order equals the spec's processing order.
--
-- HONESTY NOTE, spec inconsistency flagged for the architect: section 6.3
-- claims strategy B ('volume_balanced') COINCIDES with strategy A on this
-- tree ("spread 0.00"). It does not, by the spec's own section 3.3 algorithm
-- as hand-derived in its own section 6.4: at M4's placement step M1's legs
-- already weigh SV 150 (left, M2) versus 100 (right, M3), so B descends
-- right and places M4 at M3.left, not M2.left, and B pays company 32.00
-- (M1 32.00 on tied legs of 160.00 CV each, ties paying the left leg).
-- The B run below is INFORMATIONAL output, not an acceptance gate; the
-- gates are the A and unilevel numbers above.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).

-- ---------------------------------------------------------------------------
-- Fixture setup: scenario, three runs (unilevel, binary A, binary B), the
-- hand-inserted derived set and volumes, then execution.
-- ---------------------------------------------------------------------------
do $$
declare
    v_scenario_id bigint;
    v_run_uni     bigint;
    v_run_a       bigint;
    v_run_b       bigint;
    v_run         bigint;
begin
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('PROOF-MINI',
            'Proof fixture: five-member mini tree (COMP-LAB-SPEC section 6)',
            'locked',
            'Hand-built derived set inserted by db\lab\103_proof_minitree.sql; '
            'not replayed from mutations (replay arrives in phase L3).')
    on conflict (scenario_code) do nothing;

    select id into v_scenario_id from lab.scenarios where scenario_code = 'PROOF-MINI';

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'unilevel_v13',
            '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-MINI-UNILEVEL')
    returning id into v_run_uni;

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'binary',
            '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
            'bfs_spill',
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-MINI-BINARY-A')
    returning id into v_run_a;

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'binary',
            '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
            'volume_balanced',
            date '2026-07-01', 'running', 'hand_fixture', 'L1-PROOF-MINI-BINARY-B')
    returning id into v_run_b;

    foreach v_run in array array[v_run_uni, v_run_a, v_run_b] loop
        insert into lab.derived_members
            (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
        values
            (v_run, 10000001, 'LAB-M1', null,     date '2026-01-01', null),
            (v_run, 10000002, 'LAB-M2', 10000001, date '2026-01-02', null),
            (v_run, 10000003, 'LAB-M3', 10000001, date '2026-01-03', null),
            (v_run, 10000004, 'LAB-M4', 10000001, date '2026-01-04', null),
            (v_run, 10000005, 'LAB-M5', 10000002, date '2026-01-05', null);

        insert into lab.member_volumes (run_id, member_id, sv)
        values
            (v_run, 10000001, 200.00),
            (v_run, 10000002, 150.00),
            (v_run, 10000003, 100.00),
            (v_run, 10000004, 100.00),
            (v_run, 10000005,  50.00);

        perform lab.fn_execute_plan(v_run);
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- MINI1 (must return ZERO rows): unilevel lines versus spec section 6.2,
-- every line, both directions.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-UNILEVEL'
),
expected (earner_code, source_code, level, basis, rate, amount) as (
    values
        ('LAB-M1', 'LAB-M2', 1, 120.00::numeric, 0.1000::numeric, 12.00::numeric),
        ('LAB-M1', 'LAB-M3', 1,  80.00::numeric, 0.1000::numeric,  8.00::numeric),
        ('LAB-M1', 'LAB-M4', 1,  80.00::numeric, 0.1000::numeric,  8.00::numeric),
        ('LAB-M1', 'LAB-M5', 2,  40.00::numeric, 0.0500::numeric,  2.00::numeric),
        ('LAB-M2', 'LAB-M5', 1,  40.00::numeric, 0.1000::numeric,  4.00::numeric)
),
actual as (
    select e.member_code as earner_code, s.member_code as source_code,
           l.level, l.basis, l.rate, l.amount
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
    where l.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- MINI2 (must return ZERO rows): unilevel totals. Company 34.00 = 7.08
-- percent of CV 480.00; SV 600.00; two members paid.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-UNILEVEL'
),
expected (total_sv, total_cv, total_payout, members_paid) as (
    values (600.00::numeric, 480.00::numeric, 34.00::numeric, 2)
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

-- ---------------------------------------------------------------------------
-- MINI3 (must return ZERO rows): binary strategy A placement tree versus
-- spec section 6.3: M2 at M1.left, M3 at M1.right, M4 SPILLED to M2.left,
-- M5 at M2.right.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-BINARY-A'
),
expected (member_code, parent_code, slot) as (
    values ('LAB-M1', null::text, null::int),
           ('LAB-M2', 'LAB-M1', 0),
           ('LAB-M3', 'LAB-M1', 1),
           ('LAB-M4', 'LAB-M2', 0),
           ('LAB-M5', 'LAB-M2', 1)
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
-- MINI4 (must return ZERO rows): binary strategy A lines and totals versus
-- spec section 6.3: M1 pays on pay-leg CV 80.00 -> 16.00; M2 on 40.00 ->
-- 8.00; nobody else; company 24.00, two members paid.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-BINARY-A'
),
expected (earner_code, basis, rate, amount, reason) as (
    values ('LAB-M1', 80.00::numeric, 0.2000::numeric, 16.00::numeric, 'binary_pay_leg'),
           ('LAB-M2', 40.00::numeric, 0.2000::numeric,  8.00::numeric, 'binary_pay_leg')
),
actual as (
    select e.member_code as earner_code, l.basis, l.rate, l.amount, l.reason
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    where l.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual' as difference, d.*
from (select * from expected except all select * from actual) d;

with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-BINARY-A'
),
expected (total_sv, total_cv, total_payout, members_paid) as (
    values (600.00::numeric, 480.00::numeric, 24.00::numeric, 2)
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

-- ---------------------------------------------------------------------------
-- MINI5 (INFORMATIONAL, no expected values baked in): strategy B on the mini
-- tree, actual placement and payout, recorded for the architect against the
-- section 6.3 inconsistency described in the header.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-BINARY-B'
)
select m.member_code, p.member_code as parent_code, pm.slot, pm.depth
from lab.placement_map pm
join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
where pm.run_id = (select run_id from run_under_test)
order by pm.depth, m.member_code;

with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L1-PROOF-MINI-BINARY-B'
)
select r.total_payout, r.members_paid, r.placement_caption
from lab.plan_runs r where r.id = (select run_id from run_under_test);
