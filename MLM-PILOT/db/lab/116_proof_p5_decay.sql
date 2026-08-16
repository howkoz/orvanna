-- Lab 116: plan five Law A fixture, the DECAY two-month example (spec section 6)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: ORVANNA-BUILDER-PLAN-SPEC.md section 6. Requires db\lab\016 and 017.
--
-- The fixture: A sponsors B; B sponsors C and D; everyone one domain agent
-- (SV 100.00, CV 80.00). Month one: B is a BUILDER (two active legs), A
-- earns 17.60 = spine 8.00 + generation 1 override 9.60 on B's group CV
-- 240.00; B earns 20.00 = spine 16.00 + second-leg bonus 4.00 (legs tie,
-- frontline id makes D's leg second). Month two: C lapses (SV 0), B is NOT
-- a Builder, A earns 8.00: THE SHRINKAGE IS EXACTLY THE 9.60 OVERRIDE, and
-- the watched-account machinery attributes it: from_reach_lost on the
-- override line, everything else zero (the spec's promised attribution,
-- which is what the 017 pairing key exists to deliver).
--
-- Mechanics: scenario 'DECAY' carries one set_volume mutation on LAB-C with
-- the per-month map {"2026-08": 0.00} (July absent from the map = no
-- override; 0.00 is a lawful multiple of 50.00), so ONE scenario serves
-- both months and the decay is pure Law A, not a data edit. The month-two
-- run names the month-one run as its baseline (question 11 machinery used
-- month-over-month). Acronym key: Sales Volume (SV), Commissionable Volume (CV).

do $$
declare
    v_scenario_id bigint;
    v_run1 bigint;
    v_run2 bigint;
    v_run bigint;
begin
    insert into lab.scenarios (scenario_code, name, status, notes)
    values ('DECAY', 'Plan five Law A fixture: C lapses in month two', 'draft',
            'Spec ORVANNA-BUILDER-PLAN-SPEC section 6. Base = four members A, B, C, D.')
    on conflict (scenario_code) do nothing;

    insert into lab.scenario_mutations (scenario_id, seq, kind, target_ref, volume_profile)
    select s.id, 1, 'set_volume', 'LAB-C', '{"2026-08": 0.00}'::jsonb
    from lab.scenarios s
    where s.scenario_code = 'DECAY' and s.status = 'draft'
      and not exists (select 1 from lab.scenario_mutations m where m.scenario_id = s.id);

    update lab.scenarios set status = 'locked'
    where scenario_code = 'DECAY' and status = 'draft';

    select id into v_scenario_id from lab.scenarios where scenario_code = 'DECAY';

    insert into lab.watchlist (member_ref, note)
    select x.ref, 'Plan five DECAY fixture watch'
    from (values ('LAB-A'), ('LAB-B')) x(ref)
    where not exists (select 1 from lab.watchlist w where w.member_ref = x.ref);

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'orvanna_builder',
            '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
            null, date '2026-07-01', 'running', 'hand_fixture', 'P5-PROOF-DECAY-M1')
    returning id into v_run1;

    foreach v_run in array array[v_run1] loop
        insert into lab.derived_members
            (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id, sv_override)
        values (v_run, 1, 'LAB-A', null, date '2026-01-01', null, 100.00),
               (v_run, 2, 'LAB-B', 1,    date '2026-01-02', null, 100.00),
               (v_run, 3, 'LAB-C', 2,    date '2026-01-03', null, 100.00),
               (v_run, 4, 'LAB-D', 2,    date '2026-01-04', null, 100.00);
        perform lab.fn_replay_mutations(v_run);
        perform lab.fn_snapshot_volumes(v_run);
        perform lab.fn_execute_plan(v_run);
    end loop;

    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, baseline_run_id, notes)
    values (v_scenario_id, 'orvanna_builder',
            '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
            null, date '2026-08-01', 'running', 'hand_fixture', v_run1, 'P5-PROOF-DECAY-M2')
    returning id into v_run2;

    foreach v_run in array array[v_run2] loop
        insert into lab.derived_members
            (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id, sv_override)
        values (v_run, 1, 'LAB-A', null, date '2026-01-01', null, 100.00),
               (v_run, 2, 'LAB-B', 1,    date '2026-01-02', null, 100.00),
               (v_run, 3, 'LAB-C', 2,    date '2026-01-03', null, 100.00),
               (v_run, 4, 'LAB-D', 2,    date '2026-01-04', null, 100.00);
        perform lab.fn_replay_mutations(v_run);
        perform lab.fn_snapshot_volumes(v_run);
        perform lab.fn_execute_plan(v_run);
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- P5-T3 (every count must be 0): both months' per-member totals, and the
-- month-two watched rows: A delta -9.60 ENTIRELY from_reach_lost
-- (decomposable true, no aggregate lines either month for A); B delta
-- -12.00 = -8.00 reach_lost (C's spine line gone) + -4.00 aggregate (the
-- bonus gone with the second active leg).
-- ---------------------------------------------------------------------------
with m1 as (select max(id) as id from lab.plan_runs where notes = 'P5-PROOF-DECAY-M1'),
m2 as (select max(id) as id from lab.plan_runs where notes = 'P5-PROOF-DECAY-M2'),
exp_member (tag, member_code, total_earned) as (
    values ('M1', 'LAB-A', 17.60::numeric), ('M1', 'LAB-B', 20.00::numeric),
           ('M1', 'LAB-C',  0.00::numeric), ('M1', 'LAB-D',  0.00::numeric),
           ('M2', 'LAB-A',  8.00::numeric), ('M2', 'LAB-B',  8.00::numeric),
           ('M2', 'LAB-C',  0.00::numeric), ('M2', 'LAB-D',  0.00::numeric)
),
act_member as (
    select case when pr.run_id = (select id from m1) then 'M1' else 'M2' end,
           m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id in ((select id from m1), (select id from m2))
),
exp_watch (member_ref, delta_earned, reach_lost, aggregate_delta, decomposable) as (
    values ('LAB-A', -9.60::numeric, -9.60::numeric, null::numeric, true),
           ('LAB-B', -12.00::numeric, -8.00::numeric, -4.00::numeric, false)
),
act_watch as (
    select ws.member_ref, ws.delta_earned,
           (ws.delta_components ->> 'from_reach_lost')::numeric,
           (ws.delta_components ->> 'aggregate_delta')::numeric,
           (ws.delta_components ->> 'decomposable')::boolean
    from lab.watch_snapshots ws
    where ws.run_id = (select id from m2)
)
select 'decay_member_diff' as check_kind, count(*) as n from (
    select * from act_member except all select * from exp_member
    union all select * from exp_member except all select * from act_member) x
union all
select 'decay_watch_diff', count(*) from (
    select * from act_watch except all select * from exp_watch
    union all select * from exp_watch except all select * from act_watch) x;
