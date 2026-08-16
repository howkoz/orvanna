-- Lab 110: L2 census runs, determinism digests, calibrated binary, and the
--          four-plan comparison record on seeded March 2026
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 sections 4.2 (ruled per-strategy rates,
--       cap-binding re-test obligation), 4.3, 4.4, 7 (L2 gates). Requires
--       db\lab\008..012 applied and the L1 census runs present.
--
-- Order source and period snapshot (charter discipline): every census run
-- below reads SEEDED app.orders rows for March 2026 (zero bridged rows in
-- that month; each run row self-stamps order_source) over the 1,001-member
-- census of 2026-08-16, frozen by the migration 021 trigger and by the
-- lab's per-run snapshots.
--
-- Session note: run with set local statement_timeout = '300s' in interfaces
-- that default to 8 seconds; the volume-balanced census placements take
-- roughly 10 to 30 seconds.
--
-- Acronym key: Commissionable Volume (CV), Message Digest 5 (MD5).

-- ---------------------------------------------------------------------------
-- C1. Binary at the RULED per-strategy rates (spec 4.2, v1.2).
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01', 'binary',
    '{"pay_leg_rate": 0.105, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
    'bfs_spill') as binary_calibrated_a;

select lab.fn_run_plan(date '2026-03-01', 'binary',
    '{"pay_leg_rate": 0.110, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
    'volume_balanced') as binary_calibrated_b;

-- ---------------------------------------------------------------------------
-- C2. Matrix census: strategy A twice (determinism pair), strategy B once.
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01', 'matrix_3x7',
    '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb,
    'bfs_spill') as matrix_a_run_1;

select lab.fn_run_plan(date '2026-03-01', 'matrix_3x7',
    '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb,
    'bfs_spill') as matrix_a_run_2;

select lab.fn_run_plan(date '2026-03-01', 'matrix_3x7',
    '{"width": 3, "depth": 7, "rates": [0.05, 0.05, 0.04, 0.04, 0.03, 0.02, 0.02]}'::jsonb,
    'volume_balanced') as matrix_b_run;

-- ---------------------------------------------------------------------------
-- C3. Stairstep census: twice (determinism pair).
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01', 'stairstep_breakaway',
    '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
    null) as stairstep_run_1;

select lab.fn_run_plan(date '2026-03-01', 'stairstep_breakaway',
    '{"brackets": [{"min": 0, "rate": 0.05}, {"min": 1000, "rate": 0.10}, {"min": 5000, "rate": 0.15}, {"min": 15000, "rate": 0.20}], "breakaway_threshold": 15000, "override_gen1_rate": 0.04, "override_gen2_rate": 0.02}'::jsonb,
    null) as stairstep_run_2;

-- ---------------------------------------------------------------------------
-- C4 (must return ZERO rows): the determinism assertion over ALL completed
-- identity-scenario March runs, any plan: same plan + params + strategy
-- must mean identical digests and totals. Covers the new matrix and
-- stairstep pairs and re-covers the L1 pairs.
-- ---------------------------------------------------------------------------
with pairs as (
    select id, plan_code, plan_params, placement_strategy,
           total_sv, total_cv, total_payout, members_paid
    from lab.plan_runs
    where period = date '2026-03-01'
      and status = 'complete'
      and scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
),
digests as (
    select p.*,
           (select md5(coalesce(string_agg(
                l.earner_id::text || '|' || coalesce(l.source_member_id::text, '') || '|'
                || coalesce(l.level::text, '') || '|' || l.basis::text || '|'
                || l.rate::text || '|' || l.amount::text || '|' || l.reason,
                E'\n' order by l.id), ''))
            from lab.plan_run_lines l where l.run_id = p.id) as lines_md5,
           (select md5(coalesce(string_agg(
                r.member_id::text || '|' || r.sv::text || '|' || r.cv::text || '|'
                || r.qualified::text || '|' || r.rank_label || '|'
                || r.plan_metrics::text || '|' || r.total_earned::text,
                E'\n' order by r.member_id), ''))
            from lab.plan_run_results r where r.run_id = p.id) as results_md5
    from pairs p
)
select a.id as run_a, b.id as run_b, a.plan_code, a.placement_strategy
from digests a
join digests b
  on b.plan_code = a.plan_code
 and b.plan_params = a.plan_params
 and b.placement_strategy is not distinct from a.placement_strategy
 and b.id > a.id
where a.lines_md5 <> b.lines_md5
   or a.results_md5 <> b.results_md5
   or a.total_sv     is distinct from b.total_sv
   or a.total_cv     is distinct from b.total_cv
   or a.total_payout is distinct from b.total_payout
   or a.members_paid is distinct from b.members_paid;

-- ---------------------------------------------------------------------------
-- C5. THE COMPARISON RECORD: latest completed March census run per
-- (plan, strategy, rate recipe), payout percent of CV beside the baseline.
-- ---------------------------------------------------------------------------
select r.plan_code,
       r.placement_strategy,
       coalesce(r.plan_params ->> 'pay_leg_rate', '') as binary_rate,
       r.id as run_id,
       r.total_payout,
       r.total_cv,
       round(100.0 * r.total_payout / r.total_cv, 4) as pct_of_cv,
       r.members_paid
from lab.plan_runs r
join (
    select plan_code, placement_strategy, plan_params, max(id) as id
    from lab.plan_runs
    where period = date '2026-03-01'
      and status = 'complete'
      and scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
    group by plan_code, placement_strategy, plan_params
) latest on latest.id = r.id
order by r.plan_code, r.placement_strategy nulls first, r.id;

-- ---------------------------------------------------------------------------
-- C6. CAP BINDING, re-tested at the ruled rates (spec 4.2 v1.2 obligation):
-- capped line count and capped remainder at 0.20 (the L1 runs) versus the
-- calibrated rates.
-- ---------------------------------------------------------------------------
select r.id as run_id,
       r.plan_params ->> 'pay_leg_rate' as rate,
       r.placement_strategy,
       count(*) filter (where l.amount = 2500.00) as capped_lines,
       coalesce(sum((pr.plan_metrics ->> 'uncapped_amount')::numeric - l.amount)
                filter (where (pr.plan_metrics ->> 'capped')::boolean), 0) as capped_remainder
from lab.plan_runs r
join lab.plan_run_lines l on l.run_id = r.id
join lab.plan_run_results pr on pr.run_id = r.id and pr.member_id = l.earner_id
where r.plan_code = 'binary'
  and r.period = date '2026-03-01'
  and r.status = 'complete'
  and r.scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
group by r.id, r.plan_params, r.placement_strategy
order by r.id;

-- ---------------------------------------------------------------------------
-- C7. Reason-code coverage on the census (the L2 gate's seeded-month
-- spot-check target): every stairstep and matrix reason present.
-- ---------------------------------------------------------------------------
select l.reason, count(*) as n_lines, sum(l.amount) as total_amount
from lab.plan_run_lines l
where l.run_id in (
    select max(id) from lab.plan_runs
    where period = date '2026-03-01' and status = 'complete'
      and scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
      and plan_code in ('matrix_3x7', 'stairstep_breakaway')
    group by plan_code, placement_strategy)
group by l.reason
order by l.reason;

-- ---------------------------------------------------------------------------
-- C8. Isolation re-check (must equal the recorded baseline 88 relations,
-- 14 triggers, 17 functions, 185 grants, 10 policies).
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
