-- Lab 113: L3 proof, the stacked scenario, month scoping, and the refusal probes
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 sections 9.1 (stacking), 9.2 (loud refusals),
--       9.4 (determinism of the flattened list), section 8 question 7
--       (depth cap 3) and question 9 (month-scoped removal). Requires
--       db\lab\111 and 112 run first.
--
-- THE STACKED SCENARIO S1X = S2's move stacked ON S1's add (parent S1,
-- own mutation move_member LAB-M4 to LAB-M3). Effective list = S1's
-- add_member then the move. Hand derivation (this build's, for the
-- verifier): sponsor tree M1 -> M2, M3; M2 -> M5, LAB-S1-1; M3 -> M4.
--   unilevel: TV(M1) 500; M1 Builder depth 2 (2 active legs M2, M3).
--     Lines: M1 on M2 12.00, M3 8.00, M5 (level 2) 2.00, LAB-S1-1 (level
--     2) 4.00, M4 (level 2) 4.00 = 30.00; M2 on M5 4.00, LAB-S1-1 8.00 =
--     12.00; M3 on M4 8.00. Company 50.00. Watched deltas versus the
--     identity mini baseline: M1 0.00 (added +4.00 exactly cancels level
--     shift -4.00, the two-bucket story in one row), M2 +8.00 (added).
--   binary A (0.20): placement M2 to M1.left, M3 to M1.right, M4 to
--     M3.left (sponsor moved), M5 to M2.left, LAB-S1-1 to M2.right. Legs:
--     M1 left {M2, M5, S1-1} = 240.00 CV, right {M3, M4} = 160.00: pay
--     160.00 -> 32.00. M2 left {M5} 40.00, right {S1-1} 80.00: pay 40.00
--     -> 8.00. Company 40.00.
-- MONTH SCOPING: scenario S-REM removes LAB-M4 from 2026-08-01 onward.
-- July run: M4 present, identity numbers (34.00). August run: M4 gone,
-- frontline empty (nothing to roll up), company 26.00 (M1 22.00: 12 + 8 +
-- 2; M2 4.00), SV 500.00, CV 400.00.
-- REFUSAL PROBES: stack depth 4 refused at lock; removing the root refused
-- at replay (the run aborts, nothing half-applied).
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV).

do $$
declare
    v_id bigint;
begin
    -- S1X: child of S1 (stack depth 2).
    insert into lab.scenarios (scenario_code, name, parent_scenario_id, status, notes)
    select 'S1X', 'Stacked: S2''s move on top of S1''s add', s.id, 'draft',
           'The L3 stacking case: effective list = S1 add_member, then move_member.'
    from lab.scenarios s
    where s.scenario_code = 'S1'
      and not exists (select 1 from lab.scenarios x where x.scenario_code = 'S1X');

    insert into lab.scenario_mutations (scenario_id, seq, kind, target_ref, new_sponsor_ref)
    select s.id, 1, 'move_member', 'LAB-M4', 'LAB-M3'
    from lab.scenarios s
    where s.scenario_code = 'S1X' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);

    update lab.scenarios set status = 'locked'
    where scenario_code = 'S1X' and status = 'draft';

    v_id := lab.fn_run_mini_fixture('S1X', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-UNILEVEL'),
        'L3-PROOF-S1X-UNILEVEL');
    v_id := lab.fn_run_mini_fixture('S1X', 'binary',
        '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-BINARY-A-020'),
        'L3-PROOF-S1X-BINARY-A');

    -- S-REM: month-scoped removal (ruled default, question 9).
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('S-REM', 'Month-scoped removal: M4 vanishes from August onward', 'draft',
            'Exercises month_from: present in July, removed in August.')
    on conflict (scenario_code) do nothing;

    insert into lab.scenario_mutations (scenario_id, seq, kind, target_ref, month_from)
    select s.id, 1, 'remove_member', 'LAB-M4', date '2026-08-01'
    from lab.scenarios s
    where s.scenario_code = 'S-REM' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);

    update lab.scenarios set status = 'locked'
    where scenario_code = 'S-REM' and status = 'draft';

    v_id := lab.fn_run_mini_fixture('S-REM', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01', null, 'L3-PROOF-SREM-JULY');
    v_id := lab.fn_run_mini_fixture('S-REM', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-08-01', null, 'L3-PROOF-SREM-AUGUST');
end
$$;

-- ---------------------------------------------------------------------------
-- ST1 (must return ZERO rows): stacked totals and per-member table, both
-- plans.
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S1X-UNILEVEL'),
bin_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S1X-BINARY-A'),
expected_member (tag, member_code, total_earned) as (
    values ('U', 'LAB-M1', 30.00::numeric), ('U', 'LAB-M2', 12.00::numeric),
           ('U', 'LAB-M3',  8.00::numeric), ('U', 'LAB-M4',  0.00::numeric),
           ('U', 'LAB-M5',  0.00::numeric), ('U', 'LAB-S1-1', 0.00::numeric),
           ('B', 'LAB-M1', 32.00::numeric), ('B', 'LAB-M2',  8.00::numeric),
           ('B', 'LAB-M3',  0.00::numeric), ('B', 'LAB-M4',  0.00::numeric),
           ('B', 'LAB-M5',  0.00::numeric), ('B', 'LAB-S1-1', 0.00::numeric)
),
actual_member as (
    select case when pr.run_id = (select id from uni_run) then 'U' else 'B' end,
           m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id in ((select id from uni_run), (select id from bin_run))
),
expected_totals (tag, total_sv, total_cv, total_payout, members_paid) as (
    values ('U', 700.00::numeric, 560.00::numeric, 50.00::numeric, 3),
           ('B', 700.00::numeric, 560.00::numeric, 40.00::numeric, 2)
),
actual_totals as (
    select case when r.id = (select id from uni_run) then 'U' else 'B' end,
           r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r
    where r.id in ((select id from uni_run), (select id from bin_run))
)
select 'member_diff' as check_kind, count(*) as n from (
    select * from actual_member except all select * from expected_member
    union all select * from expected_member except all select * from actual_member) x
union all
select 'totals_diff', count(*) from (
    select * from actual_totals except all select * from expected_totals
    union all select * from expected_totals except all select * from actual_totals) x;

-- ---------------------------------------------------------------------------
-- ST2 (must return ZERO rows): the stacked watch story: M1's unilevel delta
-- is 0.00 made of +4.00 added and -4.00 level shift, the two buckets
-- telling the two mutations apart in one row.
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S1X-UNILEVEL'),
expected (member_ref, delta_earned, from_added, level_shift) as (
    values ('LAB-M1', 0.00::numeric, 4.00::numeric, -4.00::numeric),
           ('LAB-M2', 8.00::numeric, 8.00::numeric,  0.00::numeric)
),
actual as (
    select ws.member_ref, ws.delta_earned,
           (ws.delta_components ->> 'from_added_members')::numeric,
           (ws.delta_components ->> 'from_level_shift')::numeric
    from lab.watch_snapshots ws
    where ws.run_id = (select id from uni_run)
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- ST3 (must return ZERO rows): month scoping. July: M4 present, identity
-- numbers. August: M4 gone, company 26.00 on SV 500.00.
-- ---------------------------------------------------------------------------
with july as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-SREM-JULY'),
august as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-SREM-AUGUST'),
expected (tag, n_members, m4_present, total_sv, total_payout) as (
    values ('JUL', 5::bigint, 1::bigint, 600.00::numeric, 34.00::numeric),
           ('AUG', 4::bigint, 0::bigint, 500.00::numeric, 26.00::numeric)
),
actual as (
    select case when r.id = (select id from july) then 'JUL' else 'AUG' end,
           (select count(*) from lab.derived_members d where d.run_id = r.id),
           (select count(*) from lab.derived_members d
             where d.run_id = r.id and d.member_code = 'LAB-M4'),
           r.total_sv, r.total_payout
    from lab.plan_runs r
    where r.id in ((select id from july), (select id from august))
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- ST4: refusal probes (each prints PASS or aborts the script).
-- ---------------------------------------------------------------------------
do $$
declare
    v_id bigint;
    v_did boolean;
begin
    -- Depth probe: S-D3 (child of S1X, depth 3) locks; S-D4 (depth 4) must
    -- be refused at lock.
    insert into lab.scenarios (scenario_code, name, parent_scenario_id, status)
    select 'S-D3', 'depth probe level 3', s.id, 'locked'
    from lab.scenarios s where s.scenario_code = 'S1X'
      and not exists (select 1 from lab.scenarios x where x.scenario_code = 'S-D3');
    raise notice 'PASS: depth-3 scenario locked';

    v_did := false;
    begin
        insert into lab.scenarios (scenario_code, name, parent_scenario_id, status)
        select 'S-D4', 'depth probe level 4', s.id, 'locked'
        from lab.scenarios s where s.scenario_code = 'S-D3';
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS: depth-4 lock refused (cap 3)';
    end;
    if v_did then
        raise exception 'FAIL: a depth-4 scenario stack was accepted';
    end if;

    -- Replay refusal probe: removing the root fails the run loudly and the
    -- whole run rolls back (nothing half-applied).
    insert into lab.scenarios (scenario_code, name, status)
    values ('S-BAD-ROOT', 'refusal probe: remove the root', 'draft')
    on conflict (scenario_code) do nothing;
    insert into lab.scenario_mutations (scenario_id, seq, kind, target_ref)
    select s.id, 1, 'remove_member', 'LAB-M1'
    from lab.scenarios s
    where s.scenario_code = 'S-BAD-ROOT' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);
    update lab.scenarios set status = 'locked'
    where scenario_code = 'S-BAD-ROOT' and status = 'draft';

    v_did := false;
    begin
        v_id := lab.fn_run_mini_fixture('S-BAD-ROOT', 'unilevel_v13',
            '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
            date '2026-07-01', null, 'L3-PROBE-BAD-ROOT');
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS: root removal refused loudly at replay';
    end;
    if v_did then
        raise exception 'FAIL: a root removal replayed';
    end if;
end
$$;
