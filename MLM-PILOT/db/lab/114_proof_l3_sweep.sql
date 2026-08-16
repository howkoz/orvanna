-- Lab 114: L3 five-recipe sweep over S1, S2, and the stack, with digests
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 sections 9.4 (determinism) and 10.2 (the
--       component invariant); coordinator's L3 item 4 (all five current
--       recipes over the two prescribed scenarios plus the stack).
--       Requires db\lab\111..113 run first.
--
-- The five recipes: unilevel v1.3; binary bfs_spill at the RULED 0.105;
-- binary volume_balanced at the RULED 0.110; matrix A; stairstep. Each runs
-- over scenarios S1, S2, and S1X on the mini base, deltas against
-- plan-matched mini-base identity baselines (named, as question 11
-- permits; the ruled rates apply to comparison runs per the v1.2 fixture
-- ruling, while the 9.5 and 10.3 hand-example proofs in files 111 and 112
-- deliberately ran binary at the draft 0.20).
-- Determinism: three duplicate runs (S1 unilevel, S2 binary A ruled, S1X
-- stairstep); the assertion covers ordered digests of derived members,
-- lines, results, AND watch snapshots.
-- Acronym key: Commissionable Volume (CV), Message Digest 5 (MD5).

do $$
declare
    v_id bigint;
    r record;
    v_base bigint;
begin
    -- Plan-matched mini-base identity baselines not yet created.
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'binary',
        '{"pay_leg_rate": 0.105, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01', null, 'L3-BASE-MINI-BINARY-A-RULED');
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'binary',
        '{"pay_leg_rate": 0.110, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'volume_balanced', date '2026-07-01', null, 'L3-BASE-MINI-BINARY-B-RULED');
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'matrix_3x7',
        '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb,
        'bfs_spill', date '2026-07-01', null, 'L3-BASE-MINI-MATRIX-A');
    v_id := lab.fn_run_mini_fixture('PROOF-MINI', 'stairstep_breakaway',
        '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
        null, date '2026-07-01', null, 'L3-BASE-MINI-STAIRSTEP');

    -- The sweep: 5 recipes x 3 scenarios, plan-matched baselines.
    for r in
        select * from (values
            ('unilevel_v13', null::text,
             '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb,
             'L3-BASE-MINI-UNILEVEL'),
            ('binary', 'bfs_spill',
             '{"pay_leg_rate": 0.105, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
             'L3-BASE-MINI-BINARY-A-RULED'),
            ('binary', 'volume_balanced',
             '{"pay_leg_rate": 0.110, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
             'L3-BASE-MINI-BINARY-B-RULED'),
            ('matrix_3x7', 'bfs_spill',
             '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb,
             'L3-BASE-MINI-MATRIX-A'),
            ('stairstep_breakaway', null,
             '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
             'L3-BASE-MINI-STAIRSTEP')
        ) as t(plan_code, strategy, params, base_tag)
    loop
        select max(id) into v_base from lab.plan_runs where notes = r.base_tag;
        v_id := lab.fn_run_mini_fixture('S1',  r.plan_code, r.params, r.strategy,
                    date '2026-07-01', v_base, 'L3-SWEEP-S1-'  || r.plan_code || coalesce('-' || r.strategy, ''));
        v_id := lab.fn_run_mini_fixture('S2',  r.plan_code, r.params, r.strategy,
                    date '2026-07-01', v_base, 'L3-SWEEP-S2-'  || r.plan_code || coalesce('-' || r.strategy, ''));
        v_id := lab.fn_run_mini_fixture('S1X', r.plan_code, r.params, r.strategy,
                    date '2026-07-01', v_base, 'L3-SWEEP-S1X-' || r.plan_code || coalesce('-' || r.strategy, ''));
    end loop;

    -- Determinism duplicates.
    v_id := lab.fn_run_mini_fixture('S1', 'unilevel_v13',
        '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb, null,
        date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-UNILEVEL'),
        'L3-SWEEP-S1-unilevel_v13');
    v_id := lab.fn_run_mini_fixture('S2', 'binary',
        '{"pay_leg_rate": 0.105, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
        'bfs_spill', date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-BINARY-A-RULED'),
        'L3-SWEEP-S2-binary-bfs_spill');
    v_id := lab.fn_run_mini_fixture('S1X', 'stairstep_breakaway',
        '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
        null, date '2026-07-01',
        (select max(id) from lab.plan_runs where notes = 'L3-BASE-MINI-STAIRSTEP'),
        'L3-SWEEP-S1X-stairstep_breakaway');
end
$$;

-- ---------------------------------------------------------------------------
-- SW1a (must return ZERO rows): SEMANTIC determinism, code-keyed, over every
-- pair of completed runs sharing (scenario, plan, params, strategy, period).
-- Keyed on member CODES and EFFECTIVE volumes (lab.member_volumes) rather
-- than internal ids, because the L1/L2 fixture runs loaded their base with
-- ids 10000001..5 while the L3 replay flow loads 1..5 (spec 9.4 makes the
-- SYNTHETIC id rule normative; base ids are a loading convention). Found
-- during this proof run: the first id-keyed draft of this assertion flagged
-- exactly those cross-convention pairs while every code-keyed digest and
-- every total agreed, which is itself evidence the replay reproduces the
-- frozen hand-inserted fixtures. Recorded honestly; the id-keyed byte-order
-- claim lives in SW1b where it belongs.
-- ---------------------------------------------------------------------------
with pairs as (
    select id, scenario_id, plan_code, plan_params, placement_strategy, period,
           total_sv, total_cv, total_payout, members_paid
    from lab.plan_runs
    where status = 'complete'
),
digests as (
    select p.*,
           (select md5(coalesce(string_agg(
                d.member_code || '|' || coalesce(sp.member_code, '') || '|' || mv.sv::text,
                E'\n' order by d.member_code), ''))
            from lab.derived_members d
            join lab.member_volumes mv on mv.run_id = d.run_id and mv.member_id = d.member_id
            left join lab.derived_members sp
              on sp.run_id = d.run_id and sp.member_id = d.sponsor_id
            where d.run_id = p.id) as members_md5,
           (select md5(coalesce(string_agg(
                e.member_code || '|' || coalesce(s.member_code, '') || '|'
                || coalesce(l.level::text, '') || '|' || l.basis::text || '|'
                || l.rate::text || '|' || l.amount::text || '|' || l.reason,
                E'\n' order by e.member_code, l.reason, coalesce(s.member_code, ''), l.level), ''))
            from lab.plan_run_lines l
            join lab.derived_members e on e.run_id = l.run_id and e.member_id = l.earner_id
            left join lab.derived_members s on s.run_id = l.run_id and s.member_id = l.source_member_id
            where l.run_id = p.id) as lines_md5,
           (select md5(coalesce(string_agg(
                d.member_code || '|' || r.sv::text || '|' || r.cv::text || '|'
                || r.qualified::text || '|' || r.rank_label || '|' || r.total_earned::text,
                E'\n' order by d.member_code), ''))
            from lab.plan_run_results r
            join lab.derived_members d on d.run_id = r.run_id and d.member_id = r.member_id
            where r.run_id = p.id) as results_md5
    from pairs p
)
select a.id as run_a, b.id as run_b, a.plan_code
from digests a
join digests b
  on b.scenario_id = a.scenario_id
 and b.plan_code = a.plan_code
 and b.plan_params = a.plan_params
 and b.placement_strategy is not distinct from a.placement_strategy
 and b.period = a.period
 and b.id > a.id
where a.members_md5 <> b.members_md5
   or a.lines_md5   <> b.lines_md5
   or a.results_md5 <> b.results_md5
   or a.total_sv     is distinct from b.total_sv
   or a.total_cv     is distinct from b.total_cv
   or a.total_payout is distinct from b.total_payout
   or a.members_paid is distinct from b.members_paid;

-- ---------------------------------------------------------------------------
-- SW1b (must return ZERO rows): BYTE-ORDER determinism for the deliberate
-- same-flow duplicate pairs (same notes tag): id-ordered digests of members,
-- lines (insertion order), and watch snapshots, components included.
-- ---------------------------------------------------------------------------
with dup_tags as (
    select notes from lab.plan_runs
    where status = 'complete' and notes like 'L3-SWEEP-%'
    group by notes having count(*) > 1
),
runs as (
    select r.id, r.notes from lab.plan_runs r
    join dup_tags t on t.notes = r.notes
    where r.status = 'complete'
),
digests as (
    select r.id, r.notes,
           (select md5(coalesce(string_agg(
                d.member_id::text || '|' || d.member_code || '|'
                || coalesce(d.sponsor_id::text, '') || '|' || coalesce(d.sv_override::text, ''),
                E'\n' order by d.member_id), ''))
            from lab.derived_members d where d.run_id = r.id) as members_md5,
           (select md5(coalesce(string_agg(
                l.earner_id::text || '|' || coalesce(l.source_member_id::text, '') || '|'
                || coalesce(l.level::text, '') || '|' || l.basis::text || '|'
                || l.rate::text || '|' || l.amount::text || '|' || l.reason,
                E'\n' order by l.id), ''))
            from lab.plan_run_lines l where l.run_id = r.id) as lines_md5,
           (select md5(coalesce(string_agg(
                w.member_ref || '|' || w.earnings::text || '|' || coalesce(w.delta_earned::text, '')
                || '|' || w.delta_components::text,
                E'\n' order by w.member_ref), ''))
            from lab.watch_snapshots w where w.run_id = r.id) as watch_md5
    from runs r
)
select a.id as run_a, b.id as run_b, a.notes
from digests a
join digests b on b.notes = a.notes and b.id > a.id
where a.members_md5 <> b.members_md5
   or a.lines_md5   <> b.lines_md5
   or a.watch_md5   <> b.watch_md5;

-- ---------------------------------------------------------------------------
-- SW2 (must return ZERO rows): the spec 10.2 invariant over EVERY snapshot
-- with a resolvable baseline: bucket sum plus aggregate delta equals
-- delta_earned to the cent.
-- ---------------------------------------------------------------------------
select ws.run_id, ws.member_ref, ws.delta_earned, ws.delta_components
from lab.watch_snapshots ws
where ws.baseline_run_id is not null
  and (  coalesce((ws.delta_components ->> 'from_added_members')::numeric, 0)
       + coalesce((ws.delta_components ->> 'from_removed_members')::numeric, 0)
       + coalesce((ws.delta_components ->> 'from_reach_gained')::numeric, 0)
       + coalesce((ws.delta_components ->> 'from_reach_lost')::numeric, 0)
       + coalesce((ws.delta_components ->> 'from_level_shift')::numeric, 0)
       + coalesce((ws.delta_components ->> 'from_same_level_change')::numeric, 0)
       + coalesce((ws.delta_components ->> 'aggregate_delta')::numeric, 0)
      ) <> ws.delta_earned;

-- ---------------------------------------------------------------------------
-- SW3: the sweep comparison record (recorded output, not an equality gate):
-- payout and delta story per scenario and recipe.
-- ---------------------------------------------------------------------------
select r.notes as tag, r.total_payout,
       round(100.0 * r.total_payout / r.total_cv, 4) as pct_of_cv,
       r.members_paid
from lab.plan_runs r
join (select notes, max(id) as id from lab.plan_runs
      where notes like 'L3-SWEEP-%' or notes like 'L3-BASE-%'
      group by notes) latest on latest.id = r.id
order by r.notes;

-- ---------------------------------------------------------------------------
-- SW4 (must equal the recorded baseline 88 / 14 / 17 / 185 / 10): isolation
-- re-check after the whole L3 apply-and-run.
-- ---------------------------------------------------------------------------
select
  (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app')                                  as app_relations,
  (select count(*) from pg_trigger t join pg_class c on c.oid = t.tgrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app' and not t.tgisinternal)           as app_triggers,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'app')                                  as app_functions,
  (select count(*) from information_schema.role_table_grants
    where table_schema = 'app')                               as app_grants,
  (select count(*) from pg_policies where schemaname = 'app') as app_policies;
