-- Lab 112: L3 proof, scenario S2 (move M4 under M3), spec 10.3 exactly
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 section 10.3, the watched-account worked
--       example: one account, two plans, opposite directions. Requires
--       db\lab\111 run first (baselines and watchlist exist).
--
-- S2: one mutation, move_member LAB-M4 under LAB-M3. Acceptance (deltas
-- against the mini-base identity runs, binary at the draft 0.20 per the
-- fixture ruling):
--   unilevel: M1 26.00, M2 4.00, M3 8.00, company 38.00. Watched M1 delta
--     -4.00, ENTIRELY from_level_shift (M4's line moved from level 1, 8.00,
--     to level 2, 4.00); M2 delta 0.00, all components zero.
--   binary A: legs of M1 tie at 160.00 each, ties pay the LEFT leg: M1
--     alone earns 32.00. Watched M1 delta +16.00, decomposable false, basis
--     80.00 to 160.00, gained LAB-M2 and LAB-M5, lost LAB-M3; M2 delta
--     -8.00, basis 40.00 to 0.00 (the move took the spillover away).
-- Acronym key: Commissionable Volume (CV).

do $$
declare
    v_id bigint;
begin
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('S2', 'Spec 10.3: move M4 under M3', 'draft',
            'The second prescribed hand example. Base = the section 6 mini tree.')
    on conflict (scenario_code) do nothing;

    insert into lab.scenario_mutations
        (scenario_id, seq, kind, target_ref, new_sponsor_ref)
    select s.id, 1, 'move_member', 'LAB-M4', 'LAB-M3'
    from lab.scenarios s
    where s.scenario_code = 'S2' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);

    update lab.scenarios set status = 'locked'
    where scenario_code = 'S2' and status = 'draft';

    v_id := lab.fn_run_mini_fixture('S2', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-UNILEVEL'),
        'L3-PROOF-S2-UNILEVEL');
    v_id := lab.fn_run_mini_fixture('S2', 'binary',
        '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-BINARY-A-020'),
        'L3-PROOF-S2-BINARY-A');
end
$$;

-- ---------------------------------------------------------------------------
-- S2A (must return ZERO rows): per-member totals and company totals for
-- both plans versus spec 10.3.
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S2-UNILEVEL'),
bin_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S2-BINARY-A'),
expected_member (tag, member_code, total_earned) as (
    values ('U', 'LAB-M1', 26.00::numeric), ('U', 'LAB-M2', 4.00::numeric),
           ('U', 'LAB-M3',  8.00::numeric), ('U', 'LAB-M4', 0.00::numeric),
           ('U', 'LAB-M5',  0.00::numeric),
           ('B', 'LAB-M1', 32.00::numeric), ('B', 'LAB-M2', 0.00::numeric),
           ('B', 'LAB-M3',  0.00::numeric), ('B', 'LAB-M4', 0.00::numeric),
           ('B', 'LAB-M5',  0.00::numeric)
),
actual_member as (
    select case when pr.run_id = (select id from uni_run) then 'U' else 'B' end,
           m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id in ((select id from uni_run), (select id from bin_run))
),
expected_totals (tag, total_payout, members_paid) as (
    values ('U', 38.00::numeric, 3), ('B', 32.00::numeric, 1)
),
actual_totals as (
    select case when r.id = (select id from uni_run) then 'U' else 'B' end,
           r.total_payout, r.members_paid
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
-- S2B (must return ZERO rows): THE WATCHED SNAPSHOT TABLE of spec 10.3,
-- all four rows, deltas and components exactly, including the basis member
-- movements.
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S2-UNILEVEL'),
bin_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S2-BINARY-A'),
expected (tag, member_ref, delta_earned, decomposable, level_shift,
          aggregate_delta, basis_before, basis_after, gained, lost) as (
    values ('U', 'LAB-M1', -4.00::numeric, true,  -4.00::numeric,
            null::numeric, null::numeric, null::numeric, null::jsonb, null::jsonb),
           ('U', 'LAB-M2',  0.00::numeric, true,   0.00::numeric,
            null, null, null, null, null),
           ('B', 'LAB-M1', 16.00::numeric, false,  0.00::numeric,
            16.00::numeric, 80.00::numeric, 160.00::numeric,
            '["LAB-M2", "LAB-M5"]'::jsonb, '["LAB-M3"]'::jsonb),
           ('B', 'LAB-M2', -8.00::numeric, false,  0.00::numeric,
            -8.00::numeric, 40.00::numeric, 0.00::numeric,
            '[]'::jsonb, '["LAB-M5"]'::jsonb)
),
actual as (
    select case when ws.run_id = (select id from uni_run) then 'U' else 'B' end as tag,
           ws.member_ref,
           ws.delta_earned,
           (ws.delta_components ->> 'decomposable')::boolean,
           (ws.delta_components ->> 'from_level_shift')::numeric,
           (ws.delta_components ->> 'aggregate_delta')::numeric,
           (ws.delta_components ->> 'basis_before')::numeric,
           (ws.delta_components ->> 'basis_after')::numeric,
           ws.delta_components -> 'basis_members_gained',
           ws.delta_components -> 'basis_members_lost'
    from lab.watch_snapshots ws
    where ws.run_id in ((select id from uni_run), (select id from bin_run))
)
select 'in_actual_not_expected' as difference, d.* from (select * from actual except all select * from expected) d
union all
select 'in_expected_not_actual', d.* from (select * from expected except all select * from actual) d;

-- ---------------------------------------------------------------------------
-- S2C (must return ZERO rows): the six-bucket exactness assertion over the
-- unilevel snapshots: every other bucket of M1's row is zero (the whole
-- delta is the level shift), and M2's row is all zeros.
-- ---------------------------------------------------------------------------
with uni_run as (select max(id) as id from lab.plan_runs where notes = 'L3-PROOF-S2-UNILEVEL')
select ws.member_ref, ws.delta_components
from lab.watch_snapshots ws
where ws.run_id = (select id from uni_run)
  and (   (ws.delta_components ->> 'from_added_members')::numeric     <> 0
       or (ws.delta_components ->> 'from_removed_members')::numeric   <> 0
       or (ws.delta_components ->> 'from_reach_gained')::numeric      <> 0
       or (ws.delta_components ->> 'from_reach_lost')::numeric        <> 0
       or (ws.delta_components ->> 'from_same_level_change')::numeric <> 0);
