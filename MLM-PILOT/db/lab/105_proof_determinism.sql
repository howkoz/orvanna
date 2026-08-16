-- Lab 105: L1 determinism proof, same inputs, two runs, identical output
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 1.3 invariant 1: same period + plan +
--       params + placement strategy = identical output to the cent, row
--       order included (stable ORDER BY on every bulk insert).
--
-- DETERMINISM CLAIM, stated per the engineer charter amendment 2026-08-16:
--   Order source: SEEDED app.orders rows only. March 2026 carries 1,462
--   completed seeded orders and ZERO bridged orders (demo_order_id null on
--   every row); each run row's order_source column records 'seeded_orders'
--   independently.
--   Period snapshot: the March 2026 volume month as of 2026-08-16, frozen
--   in practice by the migration 021 trigger (March is a finalized period,
--   so no new order row can enter it) and frozen per run by the lab's own
--   snapshot discipline (derived members and volumes are materialized per
--   run and every later step reads the snapshot).
--
-- METHOD. Proof 101 already created unilevel March run 1; this script
-- creates unilevel March run 2 and TWO binary strategy-A March runs, then
-- compares each pair with MD5 digests over the FULLY ORDERED row content
-- (insertion order by identity id for lines, member order for results,
-- placement by member). Equal digests over ordered content = identical
-- output, row order included. Company totals are compared as values.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV),
-- Message Digest 5 (MD5).

-- ---------------------------------------------------------------------------
-- Create the second unilevel run and the binary strategy-A pair.
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01',
                       'unilevel_v13',
                       '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb,
                       null) as unilevel_run_2;

select lab.fn_run_plan(date '2026-03-01',
                       'binary',
                       '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
                       'bfs_spill') as binary_a_run_1;

select lab.fn_run_plan(date '2026-03-01',
                       'binary',
                       '{"pay_leg_rate": 0.20, "cap_per_member": 2500.00, "pay_leg": "weaker", "carryover": "flush", "earner_gate": "qualified", "empty_leg": "pays_zero"}'::jsonb,
                       'bfs_spill') as binary_a_run_2;

-- ---------------------------------------------------------------------------
-- DET1: for each of the four March census runs above (two unilevel, two
-- binary A), the MD5 digest of lines, results, placement, and the totals.
-- PASS = the two unilevel rows are identical in every digest and total, and
-- the two binary rows are identical in every digest and total.
-- ---------------------------------------------------------------------------
with pairs as (
    select id, plan_code, placement_strategy, order_source,
           total_sv, total_cv, total_payout, members_paid
    from lab.plan_runs
    where period = date '2026-03-01'
      and status = 'complete'
      and scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY')
      and ((plan_code = 'unilevel_v13')
           or (plan_code = 'binary' and placement_strategy = 'bfs_spill'))
),
line_digests as (
    select p.id,
           md5(coalesce(string_agg(
               l.earner_id::text || '|' || coalesce(l.source_member_id::text, '') || '|'
               || coalesce(l.level::text, '') || '|' || l.basis::text || '|'
               || l.rate::text || '|' || l.amount::text || '|' || l.reason,
               E'\n' order by l.id), '')) as lines_md5,
           count(l.id) as n_lines
    from pairs p
    left join lab.plan_run_lines l on l.run_id = p.id
    group by p.id
),
result_digests as (
    select p.id,
           md5(coalesce(string_agg(
               r.member_id::text || '|' || r.sv::text || '|' || r.cv::text || '|'
               || r.qualified::text || '|' || r.rank_label || '|'
               || r.plan_metrics::text || '|' || r.total_earned::text,
               E'\n' order by r.member_id), '')) as results_md5,
           count(r.member_id) as n_results
    from pairs p
    left join lab.plan_run_results r on r.run_id = p.id
    group by p.id
),
placement_digests as (
    select p.id,
           md5(coalesce(string_agg(
               pm.member_id::text || '|' || coalesce(pm.parent_id::text, '') || '|'
               || coalesce(pm.slot::text, '') || '|' || pm.depth::text,
               E'\n' order by pm.member_id), '')) as placement_md5
    from pairs p
    left join lab.placement_map pm on pm.run_id = p.id
    group by p.id
)
select p.id as run_id,
       p.plan_code,
       p.placement_strategy,
       p.order_source,
       p.total_sv, p.total_cv, p.total_payout, p.members_paid,
       ld.n_lines,
       rd.n_results,
       ld.lines_md5,
       rd.results_md5,
       pd.placement_md5
from pairs p
join line_digests      ld on ld.id = p.id
join result_digests    rd on rd.id = p.id
join placement_digests pd on pd.id = p.id
order by p.plan_code, p.id;

-- ---------------------------------------------------------------------------
-- DET2 (must return ZERO rows): the pairwise assertion. Any two completed
-- identity-scenario March runs with the same plan, parameters, and strategy
-- must agree on every digest and every total.
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
where a.lines_md5   <> b.lines_md5
   or a.results_md5 <> b.results_md5
   or a.total_sv     is distinct from b.total_sv
   or a.total_cv     is distinct from b.total_cv
   or a.total_payout is distinct from b.total_payout
   or a.members_paid is distinct from b.members_paid;
