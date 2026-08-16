-- Lab 108: L2 matrix worked-example proof, plus binary width-2 equivalence
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 sections 4.3 and 7 (L2: matrix, both
--       placement strategies at width 3, hand example on the section 6
--       trees). Requires db\lab\009, 010, 012 applied; scenarios PROOF-MINI
--       and PROOF-TEN from proofs 103 and 104.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).
--
-- THE HAND EXAMPLES (this build's derivation, offered to the architect as
-- the spec amendment content; the spec carries no matrix example yet):
--
-- MINI TREE (section 6 members and volumes), width 3, rates 5/5/4/4/3/2/2:
--   Placement, BOTH strategies: identical to the sponsor tree, because M1's
--   three frontline members all fit in M1's three slots and M5 lands in
--   M2's empty slot 0. Strategy A fills the sponsor's lowest open slot;
--   strategy B weighs three empty legs (ties to the lowest slot) and lands
--   identically. Spread 0.00, and HERE it is provable, unlike the binary
--   6.3 claim v1.2 corrected: no placement step ever needs spillover or a
--   non-trivial weigh-in.
--   Lines: M1 on M2 level 1, 5 percent of 120.00 = 6.00; M1 on M3 = 4.00;
--   M1 on M4 = 4.00; M1 on M5 level 2, 5 percent of 40.00 = 2.00; M2 on M5
--   level 1 = 2.00. Company = 18.00 (M1 16.00, M2 2.00) = 3.75 percent of
--   CV 480.00. The same tree pays 34.00 under unilevel v1.3: matrix's flat
--   5 percent front line versus unilevel's 10 percent is the whole story
--   on a shallow tree.
--
-- TEN-MEMBER TREE (COMP-PLAN-SPEC section 7 volumes), same parameters:
--   Placement, BOTH strategies: identical to the sponsor tree (no member
--   has more than three frontline members; every placement lands in an
--   empty sponsor slot before any weigh-in can differ; slot order follows
--   ascending processing order). Spread 0.00.
--   Lines: M1 level 1: M2 6.00, M3 4.00, M4 4.00; level 2: M5 2.00,
--   M6 6.00, M7 60.00, M8 4.00; level 3 at 4 percent: M9 9.60, M10 1.60;
--   M1 total 97.20. M2: M5 2.00, M6 6.00, M9 (level 2) 12.00 = 20.00.
--   M3: M7 60.00, M8 4.00, M10 (level 2) 2.00 = 66.00. M8: M10 2.00.
--   M5 is unqualified: its 5 percent claim on M9 (12.00) is breakage.
--   Company = 185.20 = 8.5741 percent of CV 2,160.00 (unilevel: 264.00 =
--   12.22 percent; binary A: 184.00). Flat depth 7 does not rescue rank
--   breakage because matrix has no rank gate to breach; the losses versus
--   unilevel are pure rate-shape (5 versus 10 up front).
--
-- Also in this file: BINARY WIDTH-2 EQUIVALENCE. File 009 rebuilt placement
-- as width-N; the L1 binary numbers must be unchanged through the new code
-- path, so the mini and ten-member binary fixtures re-run here at the draft
-- 0.20 and must reproduce 24.00 / 184.00 / 168.00 exactly.

-- ---------------------------------------------------------------------------
-- Fixture setup: six runs (matrix A and B on mini and ten; binary re-runs).
-- ---------------------------------------------------------------------------
do $$
declare
    v_mini bigint;
    v_ten  bigint;
    v_run  bigint;
    r      record;
begin
    select id into v_mini from lab.scenarios where scenario_code = 'PROOF-MINI';
    select id into v_ten  from lab.scenarios where scenario_code = 'PROOF-TEN';
    if v_mini is null or v_ten is null then
        raise exception 'run proofs 103 and 104 first (fixture scenarios missing)';
    end if;

    for r in
        select * from (values
            (v_mini, 'matrix_3x7', 'bfs_spill',       'L2-PROOF-MINI-MATRIX-A'),
            (v_mini, 'matrix_3x7', 'volume_balanced', 'L2-PROOF-MINI-MATRIX-B'),
            (v_ten,  'matrix_3x7', 'bfs_spill',       'L2-PROOF-TEN-MATRIX-A'),
            (v_ten,  'matrix_3x7', 'volume_balanced', 'L2-PROOF-TEN-MATRIX-B'),
            (v_mini, 'binary',     'bfs_spill',       'L2-PROOF-MINI-BINARY-A-EQUIV'),
            (v_ten,  'binary',     'bfs_spill',       'L2-PROOF-TEN-BINARY-A-EQUIV'),
            (v_ten,  'binary',     'volume_balanced', 'L2-PROOF-TEN-BINARY-B-EQUIV')
        ) as t(scenario_id, plan_code, strategy, tag)
    loop
        insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                                   period, status, order_source, notes)
        values (r.scenario_id,
                r.plan_code,
                case r.plan_code
                    when 'matrix_3x7' then
                        '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb
                    else
                        '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb
                end,
                r.strategy, date '2026-07-01', 'running', 'hand_fixture', r.tag)
        returning id into v_run;

        if r.scenario_id = v_mini then
            insert into lab.derived_members (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
            values (v_run, 10000001, 'LAB-M1', null,     date '2026-01-01', null),
                   (v_run, 10000002, 'LAB-M2', 10000001, date '2026-01-02', null),
                   (v_run, 10000003, 'LAB-M3', 10000001, date '2026-01-03', null),
                   (v_run, 10000004, 'LAB-M4', 10000001, date '2026-01-04', null),
                   (v_run, 10000005, 'LAB-M5', 10000002, date '2026-01-05', null);
            insert into lab.member_volumes (run_id, member_id, sv)
            values (v_run, 10000001, 200.00), (v_run, 10000002, 150.00),
                   (v_run, 10000003, 100.00), (v_run, 10000004, 100.00),
                   (v_run, 10000005,  50.00);
        else
            insert into lab.derived_members (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
            values (v_run, 10000001, 'LAB-M1',  null,     date '2026-01-01', null),
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
            values (v_run, 10000001,  200.00), (v_run, 10000002,  150.00),
                   (v_run, 10000003,  100.00), (v_run, 10000004,  100.00),
                   (v_run, 10000005,   50.00), (v_run, 10000006,  150.00),
                   (v_run, 10000007, 1500.00), (v_run, 10000008,  100.00),
                   (v_run, 10000009,  300.00), (v_run, 10000010,   50.00);
        end if;

        perform lab.fn_execute_plan(v_run);
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- MX1 (must return ZERO rows): mini matrix lines, strategy A, versus the
-- hand example, both directions.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes = 'L2-PROOF-MINI-MATRIX-A'
),
expected (earner_code, source_code, level, basis, rate, amount) as (
    values ('LAB-M1', 'LAB-M2', 1, 120.00::numeric, 0.0500::numeric, 6.00::numeric),
           ('LAB-M1', 'LAB-M3', 1,  80.00::numeric, 0.0500::numeric, 4.00::numeric),
           ('LAB-M1', 'LAB-M4', 1,  80.00::numeric, 0.0500::numeric, 4.00::numeric),
           ('LAB-M1', 'LAB-M5', 2,  40.00::numeric, 0.0500::numeric, 2.00::numeric),
           ('LAB-M2', 'LAB-M5', 1,  40.00::numeric, 0.0500::numeric, 2.00::numeric)
),
actual as (
    select e.member_code, s.member_code, l.level, l.basis, l.rate, l.amount
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
    where l.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- MX2 (must return ZERO rows): fixture totals for all four matrix runs and
-- the three binary equivalence re-runs, versus the hand examples and the L1
-- accepted numbers.
-- ---------------------------------------------------------------------------
with expected (tag, total_sv, total_cv, total_payout, members_paid) as (
    values ('L2-PROOF-MINI-MATRIX-A',        600.00::numeric,  480.00::numeric,  18.00::numeric, 2),
           ('L2-PROOF-MINI-MATRIX-B',        600.00::numeric,  480.00::numeric,  18.00::numeric, 2),
           ('L2-PROOF-TEN-MATRIX-A',        2700.00::numeric, 2160.00::numeric, 185.20::numeric, 4),
           ('L2-PROOF-TEN-MATRIX-B',        2700.00::numeric, 2160.00::numeric, 185.20::numeric, 4),
           ('L2-PROOF-MINI-BINARY-A-EQUIV',  600.00::numeric,  480.00::numeric,  24.00::numeric, 2),
           ('L2-PROOF-TEN-BINARY-A-EQUIV',  2700.00::numeric, 2160.00::numeric, 184.00::numeric, 3),
           ('L2-PROOF-TEN-BINARY-B-EQUIV',  2700.00::numeric, 2160.00::numeric, 168.00::numeric, 3)
),
actual as (
    select r.notes as tag, r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r
    join (select notes, max(id) as id from lab.plan_runs
          where notes like 'L2-PROOF-%' group by notes) latest
      on latest.id = r.id
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- MX3 (must return ZERO rows): ten-member matrix per-member table, strategy
-- A, and the A-equals-B placement claim (both strategies produce the
-- sponsor tree, so their placement maps must be identical).
-- ---------------------------------------------------------------------------
with run_a as (select max(id) as run_id from lab.plan_runs where notes = 'L2-PROOF-TEN-MATRIX-A'),
run_b as (select max(id) as run_id from lab.plan_runs where notes = 'L2-PROOF-TEN-MATRIX-B'),
expected_member (member_code, total_earned) as (
    values ('LAB-M1', 97.20::numeric), ('LAB-M2', 20.00::numeric),
           ('LAB-M3', 66.00::numeric), ('LAB-M4',  0.00::numeric),
           ('LAB-M5',  0.00::numeric), ('LAB-M6',  0.00::numeric),
           ('LAB-M7',  0.00::numeric), ('LAB-M8',  2.00::numeric),
           ('LAB-M9',  0.00::numeric), ('LAB-M10', 0.00::numeric)
),
actual_member as (
    select m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_a)
),
place_a as (
    select m.member_code, p.member_code as parent_code, pm.slot
    from lab.placement_map pm
    join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
    left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
    where pm.run_id = (select run_id from run_a)
),
place_b as (
    select m.member_code, p.member_code as parent_code, pm.slot
    from lab.placement_map pm
    join lab.derived_members m on m.run_id = pm.run_id and m.member_id = pm.member_id
    left join lab.derived_members p on p.run_id = pm.run_id and p.member_id = pm.parent_id
    where pm.run_id = (select run_id from run_b)
)
select 'member_diff' as check_kind, count(*) as n from (
    select * from actual_member except all select * from expected_member
    union all select * from expected_member except all select * from actual_member) x
union all
select 'placement_a_vs_b_diff', count(*) from (
    select * from place_a except all select * from place_b
    union all select * from place_b except all select * from place_a) x;
