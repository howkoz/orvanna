-- Lab 004: plan 'unilevel_v13', the baseline reimplemented through the lab interface
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 4.1; the plan itself is exactly
--       docs\COMP-PLAN-SPEC.md v1.3. Requires db\lab\001 and 002.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV).
--
-- This is a REIMPLEMENTATION of app.fn_run_commission's computation over the
-- lab's derived inputs, not a call into it. The point of the exercise is the
-- L1 parity proof: this code, reading the derived tree of the IDENTITY
-- scenario, must reproduce a real finalized run line for line to the cent.
-- Where the engine reads app tables, this reads the run-scoped lab snapshots
-- (lab.member_volumes, lab.run_level_map); the arithmetic, the flag order,
-- the rounding points, and the stable ORDER BYs are copied deliberately.
--
-- Differences from the engine, each on purpose:
--   1. Rates come from the run's plan_params ({"rates": [...]}), stored
--      verbatim on the run row, so a changed parameter is a NEW run, never an
--      edit (spec 1.1). The rates array doubles as the max-depth filter,
--      exactly as the engine's inline rate table does.
--   2. Output goes to lab.plan_run_results / lab.plan_run_lines in the
--      four-plan contract shape (rank_label free text, plan_metrics JSON,
--      reason on every line).
--   3. Rank paid depths still come from app.ranks (read-only), the same
--      source of truth the engine uses; duplicating that table into lab
--      would be a second copy to keep in step forever.

create or replace function lab.fn_plan_unilevel(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_params jsonb;
begin
    select r.plan_params into v_params
    from lab.plan_runs r
    where r.id = p_run_id;

    if v_params is null or jsonb_typeof(v_params -> 'rates') <> 'array' then
        raise exception
            'lab.fn_plan_unilevel: run % plan_params must carry a "rates" array', p_run_id;
    end if;

    -- Level rate table from the run parameters (level = 1-based position).
    drop table if exists pg_temp.tmp_lab_uni_rates;
    create temp table tmp_lab_uni_rates on commit drop as
    select t.ord::int as level, (t.val)::numeric(6,4) as rate
    from jsonb_array_elements_text(v_params -> 'rates') with ordinality as t(val, ord);

    -- One staging row per derived member: SV, CV, TV, qualification, rank,
    -- paid depth. The same staged-flags evaluation order as the engine
    -- (Builder, Leader, Director, Executive; final rank = highest flag).
    drop table if exists pg_temp.tmp_lab_uni_calc;
    create temp table tmp_lab_uni_calc on commit drop as
    with vols as (
        -- SV from the run's volume snapshot; CV = round half up (0.80 x SV, 2),
        -- once per member-month. Plan-independent by contract (spec 1.2).
        select mv.member_id,
               mv.sv,
               (round(0.80 * mv.sv, 2))::numeric(12,2) as cv
        from lab.member_volumes mv
        where mv.run_id = p_run_id
    ),
    tv_agg as (
        -- TV: subtree SV excluding self, from the derived-tree level map,
        -- ALL levels (full depth, engine design decision a).
        select lm.ancestor_id as member_id,
               sum(v.sv)      as tv
        from lab.run_level_map lm
        join vols v on v.member_id = lm.descendant_id
        where lm.run_id = p_run_id
        group by lm.ancestor_id
    ),
    base as (
        select v.member_id,
               v.sv,
               v.cv,
               (coalesce(t.tv, 0))::numeric(14,2) as tv,
               (v.sv >= 100.00)                   as qualified
        from vols v
        left join tv_agg t on t.member_id = v.member_id
    ),
    legs as (
        select lm.ancestor_id   as member_id,
               lm.descendant_id as child_id
        from lab.run_level_map lm
        where lm.run_id = p_run_id
          and lm.level = 1
    ),
    active_leg_counts as (
        -- A leg is ACTIVE when its frontline member is qualified this month.
        select l.member_id,
               count(*) as n_active_legs
        from legs l
        join base c on c.member_id = l.child_id
        where c.qualified
        group by l.member_id
    ),
    flags_bl as (
        select b.member_id,
               b.sv,
               b.cv,
               b.tv,
               b.qualified,
               coalesce(al.n_active_legs, 0)                        as n_active_legs,
               (b.qualified and coalesce(al.n_active_legs, 0) >= 2) as builder_flag,
               (b.qualified and b.tv >= 2500.00
                and coalesce(al.n_active_legs, 0) >= 3)             as leader_flag
        from base b
        left join active_leg_counts al on al.member_id = b.member_id
    ),
    leg_members as (
        select l.member_id, l.child_id, l.child_id as leg_member_id
        from legs l
        union all
        select l.member_id, l.child_id, lm.descendant_id
        from legs l
        join lab.run_level_map lm
          on lm.run_id = p_run_id
         and lm.ancestor_id = l.child_id
    ),
    director_leg_counts as (
        select lmem.member_id,
               count(distinct lmem.child_id) as n_legs_with_builder_plus
        from leg_members lmem
        join flags_bl f on f.member_id = lmem.leg_member_id
        where f.builder_flag or f.leader_flag
        group by lmem.member_id
    ),
    flags_d as (
        select f.*,
               (f.qualified and f.tv >= 10000.00
                and coalesce(dl.n_legs_with_builder_plus, 0) >= 2) as director_flag
        from flags_bl f
        left join director_leg_counts dl on dl.member_id = f.member_id
    ),
    executive_leg_counts as (
        select lmem.member_id,
               count(distinct lmem.child_id) as n_legs_with_leader_plus
        from leg_members lmem
        join flags_d f on f.member_id = lmem.leg_member_id
        where f.leader_flag or f.director_flag
        group by lmem.member_id
    ),
    flags_e as (
        select f.*,
               (f.qualified and f.tv >= 40000.00
                and coalesce(el.n_legs_with_leader_plus, 0) >= 2) as executive_flag
        from flags_d f
        left join executive_leg_counts el on el.member_id = f.member_id
    ),
    ranked as (
        select f.member_id,
               f.sv,
               f.cv,
               f.tv,
               f.qualified,
               f.n_active_legs,
               case
                   when f.executive_flag then 'executive'
                   when f.director_flag  then 'director'
                   when f.leader_flag    then 'leader'
                   when f.builder_flag   then 'builder'
                   else 'member'
               end as rank_code
        from flags_e f
    )
    select r.member_id,
           r.sv,
           r.cv,
           r.tv,
           r.qualified,
           r.n_active_legs,
           r.rank_code,
           rk.paid_depth
    from ranked r
    join app.ranks rk on rk.rank_code = r.rank_code;

    -- Commission lines: one per (qualified earner, descendant source) within
    -- the earner's paid depth, rate by level, source qualification irrelevant,
    -- no compression, no zero-CV lines, rounded AT THE LINE. Stable ORDER BY
    -- copied from the engine so reruns are byte-identical, row order included.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id,
           lm.ancestor_id,
           lm.descendant_id,
           lm.level,
           src.cv,
           rt.rate,
           round(rt.rate * src.cv, 2),
           'unilevel_level_pay'
    from lab.run_level_map lm
    join pg_temp.tmp_lab_uni_calc earner on earner.member_id = lm.ancestor_id
    join pg_temp.tmp_lab_uni_calc src    on src.member_id    = lm.descendant_id
    join pg_temp.tmp_lab_uni_rates rt    on rt.level         = lm.level
    where lm.run_id = p_run_id
      and earner.qualified
      and lm.level <= earner.paid_depth
      and src.cv > 0
    order by lm.ancestor_id, lm.level, lm.descendant_id;

    -- Per-member results, zero-volume members included. total_earned is the
    -- sum of the member's rounded lines, never re-rounded. plan_metrics keys
    -- for this plan: tv, n_active_legs, paid_depth.
    insert into lab.plan_run_results
        (run_id, member_id, sv, cv, qualified, rank_label, plan_metrics, total_earned)
    select p_run_id,
           c.member_id,
           c.sv,
           c.cv,
           c.qualified,
           c.rank_code,
           jsonb_build_object('tv',            c.tv,
                              'n_active_legs', c.n_active_legs,
                              'paid_depth',    c.paid_depth),
           coalesce(e.total_earned, 0.00)
    from pg_temp.tmp_lab_uni_calc c
    left join (
        select l.earner_id, sum(l.amount) as total_earned
        from lab.plan_run_lines l
        where l.run_id = p_run_id
        group by l.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    drop table if exists pg_temp.tmp_lab_uni_calc;
    drop table if exists pg_temp.tmp_lab_uni_rates;
end;
$$;

revoke execute on function lab.fn_plan_unilevel(bigint) from public;
