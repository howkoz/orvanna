-- Lab 109: L2 stairstep-breakaway worked-example proof
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 sections 4.4 and 7 (L2). Requires db\lab\011
--       and 012 applied; scenario PROOF-MINI from proof 103.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV),
-- Group Volume (GV).
--
-- THE HAND EXAMPLES (this build's derivation, offered to the architect as
-- the spec amendment content):
--
-- MINI TREE (section 6 members and volumes): GVs are M1 600.00, M2 200.00,
-- M3 100.00, M4 100.00, M5 50.00; nobody nears the 15,000.00 breakaway
-- threshold and every member sits in the 5 percent bracket, so every
-- differential collapses to 5 percent of own CV: M1 8.00, M2 6.00 (checked
-- longhand: 5 percent of (120.00 + 40.00) = 8.00 minus M5's bracket
-- subtraction 5 percent of 40.00 = 2.00), M3 4.00, M4 4.00; M5 is
-- unqualified so its 2.00 is breakage. Company = 22.00 = 4.5833 percent of
-- CV 480.00, four members paid, no overrides, no breakaways. On a shallow
-- low-volume tree stairstep is the STINGIEST of the four plans (unilevel
-- 34.00, binary A 24.00, matrix 18.00, stairstep 22.00), because everyone
-- is stuck in the bottom bracket and differentials cancel to 5 percent of
-- own CV.
--
-- BREAKAWAY CHAIN (new fixture, seven members, built to exercise every
-- stairstep reason code including generation 2):
--   Sponsor chain: S1 -> S2 -> S3 -> S4 -> S5 -> S6, plus S7 under S2.
--   SV: S1 200, S2 100, S3 500, S4 10,000, S5 5,000, S6 15,000, S7 50.
--   Bottom-up: S6 GV 15,000 BREAKAWAY (bracket 20). S5 GV 5,000 (S6's
--   group left), bracket 15. S4 GV 10,000 + 5,000 = 15,000 BREAKAWAY,
--   bracket 20. S3 GV 500 (S4's group left), bracket 5. S7 GV 50,
--   unqualified. S2 GV 100 + 500 + 50 = 650, bracket 5. S1 GV 850,
--   bracket 5.
--   Differentials: S6 = 0.20 x 12,000.00 = 2,400.00. S5 = 0.15 x 4,000.00
--   = 600.00. S4 = 0.20 x (8,000 + 4,000) minus 0.15 x 4,000 = 2,400.00
--   minus 600.00 = 1,800.00. S3 = 0.05 x 400.00 = 20.00. S2 = 0.05 x
--   (80 + 440) minus (0.05 x 400 + 0.05 x 40) = 26.00 minus 22.00 = 4.00.
--   S1 = 0.05 x (160 + 520) minus 0.05 x 520 = 8.00. S7 unqualified.
--   Differential total 4,832.00; minimum differential 2.00 (S7's unpaid
--   breakage quantity), no negatives: the monotonicity assertion holds.
--   Overrides: S6's group CV = 12,000.00: generation 1 to S5 (first
--   qualified above S6, zero boundaries) = 480.00; the walk passes
--   breakaway S4 (boundary), and the first qualified member beyond it, S3,
--   takes generation 2 = 240.00. S4's group CV = 12,000.00: generation 1
--   to S3 = 480.00; no boundary above S4, so no generation 2 exists for
--   it, exactly the spec's "a breakaway found under a breakaway" clause.
--   Per member: S1 8.00, S2 4.00, S3 20 + 480 + 240 = 740.00, S4 1,800.00,
--   S5 600 + 480 = 1,080.00, S6 2,400.00, S7 0.00. Company = 6,032.00 =
--   24.4409 percent of CV 24,680.00, six members paid, under the 26
--   percent stacked-breakaway ceiling of section 4.4.

-- ---------------------------------------------------------------------------
-- Fixture setup: mini stairstep run, plus the PROOF-STAIR scenario and run.
-- ---------------------------------------------------------------------------
do $$
declare
    v_mini  bigint;
    v_stair bigint;
    v_run   bigint;
begin
    select id into v_mini from lab.scenarios where scenario_code = 'PROOF-MINI';
    if v_mini is null then
        raise exception 'run proof 103 first (PROOF-MINI scenario missing)';
    end if;

    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('PROOF-STAIR',
            'Proof fixture: seven-member breakaway chain (stairstep hand example)',
            'locked',
            'Hand-built derived set inserted by db\lab\109_proof_stairstep_fixtures.sql; '
            'built to exercise breakaway, generation 1, and generation 2 override '
            'paths with hand-checkable numbers.')
    on conflict (scenario_code) do nothing;

    select id into v_stair from lab.scenarios where scenario_code = 'PROOF-STAIR';

    -- Mini tree stairstep.
    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_mini, 'stairstep_breakaway',
            '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
            null, date '2026-07-01', 'running', 'hand_fixture', 'L2-PROOF-MINI-STAIRSTEP')
    returning id into v_run;

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

    perform lab.fn_execute_plan(v_run);

    -- Breakaway chain.
    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_stair, 'stairstep_breakaway',
            '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
            null, date '2026-07-01', 'running', 'hand_fixture', 'L2-PROOF-STAIR-CHAIN')
    returning id into v_run;

    insert into lab.derived_members (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
    values (v_run, 10000001, 'LAB-S1', null,     date '2026-01-01', null),
           (v_run, 10000002, 'LAB-S2', 10000001, date '2026-01-02', null),
           (v_run, 10000003, 'LAB-S3', 10000002, date '2026-01-03', null),
           (v_run, 10000004, 'LAB-S4', 10000003, date '2026-01-04', null),
           (v_run, 10000005, 'LAB-S5', 10000004, date '2026-01-05', null),
           (v_run, 10000006, 'LAB-S6', 10000005, date '2026-01-06', null),
           (v_run, 10000007, 'LAB-S7', 10000002, date '2026-01-07', null);
    insert into lab.member_volumes (run_id, member_id, sv)
    values (v_run, 10000001,   200.00), (v_run, 10000002,   100.00),
           (v_run, 10000003,   500.00), (v_run, 10000004, 10000.00),
           (v_run, 10000005,  5000.00), (v_run, 10000006, 15000.00),
           (v_run, 10000007,    50.00);

    perform lab.fn_execute_plan(v_run);
end
$$;

-- ---------------------------------------------------------------------------
-- SS1 (must return ZERO rows): mini stairstep lines and totals versus the
-- hand example.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes like 'L2-PROOF-MINI-STAIRSTEP%'
),
expected (earner_code, basis, rate, amount, reason) as (
    values ('LAB-M1', 480.00::numeric, 0.05::numeric, 8.00::numeric, 'stairstep_differential'),
           ('LAB-M2', 160.00::numeric, 0.05::numeric, 6.00::numeric, 'stairstep_differential'),
           ('LAB-M3',  80.00::numeric, 0.05::numeric, 4.00::numeric, 'stairstep_differential'),
           ('LAB-M4',  80.00::numeric, 0.05::numeric, 4.00::numeric, 'stairstep_differential')
),
actual as (
    select e.member_code, l.basis, l.rate, l.amount, l.reason
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    where l.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes like 'L2-PROOF-MINI-STAIRSTEP%'
),
expected (total_sv, total_cv, total_payout, members_paid) as (
    values (600.00::numeric, 480.00::numeric, 22.00::numeric, 4)
),
actual as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- SS2 (must return ZERO rows): the breakaway chain, every line (differential
-- and both override generations), both directions.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes like 'L2-PROOF-STAIR-CHAIN%'
),
expected (earner_code, source_code, basis, rate, amount, reason) as (
    values ('LAB-S1', null::text,   680.00::numeric, 0.05::numeric,    8.00::numeric, 'stairstep_differential'),
           ('LAB-S2', null,         520.00::numeric, 0.05::numeric,    4.00::numeric, 'stairstep_differential'),
           ('LAB-S3', null,         400.00::numeric, 0.05::numeric,   20.00::numeric, 'stairstep_differential'),
           ('LAB-S4', null,       12000.00::numeric, 0.20::numeric, 1800.00::numeric, 'stairstep_differential'),
           ('LAB-S5', null,        4000.00::numeric, 0.15::numeric,  600.00::numeric, 'stairstep_differential'),
           ('LAB-S6', null,       12000.00::numeric, 0.20::numeric, 2400.00::numeric, 'stairstep_differential'),
           ('LAB-S5', 'LAB-S6',   12000.00::numeric, 0.04::numeric,  480.00::numeric, 'stairstep_override_gen1'),
           ('LAB-S3', 'LAB-S4',   12000.00::numeric, 0.04::numeric,  480.00::numeric, 'stairstep_override_gen1'),
           ('LAB-S3', 'LAB-S6',   12000.00::numeric, 0.02::numeric,  240.00::numeric, 'stairstep_override_gen2')
),
actual as (
    select e.member_code as earner_code,
           s.member_code as source_code,
           l.basis, l.rate, l.amount, l.reason
    from lab.plan_run_lines l
    join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
    left join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
    where l.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- SS3 (must return ZERO rows): breakaway chain per-member totals, company
-- totals, and the run-level checks (monotonicity note present; breakaway
-- flags exactly S4 and S6).
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id from lab.plan_runs where notes like 'L2-PROOF-STAIR-CHAIN%'
),
expected_member (member_code, total_earned, rank_label) as (
    values ('LAB-S1',    8.00::numeric, 'bracket_5pct'),
           ('LAB-S2',    4.00::numeric, 'bracket_5pct'),
           ('LAB-S3',  740.00::numeric, 'bracket_5pct'),
           ('LAB-S4', 1800.00::numeric, 'bracket_20pct'),
           ('LAB-S5', 1080.00::numeric, 'bracket_15pct'),
           ('LAB-S6', 2400.00::numeric, 'bracket_20pct'),
           ('LAB-S7',    0.00::numeric, 'bracket_5pct')
),
actual_member as (
    select m.member_code, pr.total_earned, pr.rank_label
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_under_test)
),
expected_totals (total_sv, total_cv, total_payout, members_paid) as (
    values (30850.00::numeric, 24680.00::numeric, 6032.00::numeric, 6)
),
actual_totals as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r where r.id = (select run_id from run_under_test)
),
expected_breakaways (member_code) as (values ('LAB-S4'), ('LAB-S6')),
actual_breakaways as (
    select m.member_code
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id = (select run_id from run_under_test)
      and (pr.plan_metrics ->> 'breakaway')::boolean
)
select 'member_diff' as check_kind, count(*) as n from (
    select * from actual_member except all select * from expected_member
    union all select * from expected_member except all select * from actual_member) x
union all
select 'totals_diff', count(*) from (
    select * from actual_totals except all select * from expected_totals
    union all select * from expected_totals except all select * from actual_totals) x
union all
select 'breakaway_diff', count(*) from (
    select * from actual_breakaways except all select * from expected_breakaways
    union all select * from expected_breakaways except all select * from actual_breakaways) x
union all
select 'monotonicity_note_missing', count(*) from (
    select 1 from lab.plan_runs r
    where r.id = (select run_id from run_under_test)
      and r.notes not like '%monotonicity asserted%') x;
