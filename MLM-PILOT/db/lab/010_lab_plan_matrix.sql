-- Lab 010: plan 'matrix_3x7', draft parameters
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 section 4.3: width 3, pay levels 1 to 7 of the
--       PLACEMENT tree, rates 5/5/4/4/3/2/2 percent of source CV, earner
--       gate qualified with FLAT paid depth 7 (Howard's ruling on section 8
--       question 5: no rank ladder; the width constraint IS the plan's
--       shape). Requires db\lab\001..009.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV),
-- JavaScript Object Notation (JSON).
--
-- Structural ceiling 5+5+4+4+3+2+2 = 25 percent of CV, identical to the
-- unilevel baseline by construction; the dashboard difference is WHERE the
-- money lands (deeper and flatter; spillover past width 3 feeds depth).
--
-- Per-source pay over PLACEMENT distance: one line per (qualified earner,
-- placement-descendant source) pair within levels 1..7, amount = round half
-- up (rate x source CV, 2) at the line, reason 'matrix_level_pay',
-- source qualification irrelevant, no zero-CV lines, stable ORDER BY.
--
-- plan_metrics keys for this plan: leg_cv_0, leg_cv_1, leg_cv_2 (the three
-- placement legs' CV totals, the matrix analogue of binary's left and right
-- CV), placement_depth (the member's own depth in the placement tree).

create or replace function lab.fn_plan_matrix(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_params jsonb;
    v_depth  int;
begin
    select r.plan_params into v_params
    from lab.plan_runs r
    where r.id = p_run_id;

    if v_params is null or jsonb_typeof(v_params -> 'rates') <> 'array' then
        raise exception
            'lab.fn_plan_matrix: run % plan_params must carry a "rates" array', p_run_id;
    end if;

    if not exists (select 1 from lab.placement_map pm where pm.run_id = p_run_id) then
        raise exception
            'lab.fn_plan_matrix: run % has no placement map; placement must be derived first',
            p_run_id;
    end if;

    -- Level rate table from the run parameters; its length IS the paid
    -- depth (7 in the draft), exactly as the unilevel rates array works.
    drop table if exists pg_temp.tmp_lab_mx_rates;
    create temp table tmp_lab_mx_rates on commit drop as
    select t.ord::int as level, (t.val)::numeric(6,4) as rate
    from jsonb_array_elements_text(v_params -> 'rates') with ordinality as t(val, ord);

    select max(level) into v_depth from pg_temp.tmp_lab_mx_rates;

    -- Volumes and qualification (plan-independent by contract).
    drop table if exists pg_temp.tmp_lab_mx_calc;
    create temp table tmp_lab_mx_calc on commit drop as
    select mv.member_id,
           mv.sv,
           (round(0.80 * mv.sv, 2))::numeric(12,2) as cv,
           (mv.sv >= 100.00)                       as qualified
    from lab.member_volumes mv
    where mv.run_id = p_run_id;

    -- Placement-tree distance pairs to the paid depth. The placement level
    -- map is the placement analogue of lab.run_level_map; it is derived
    -- fresh from this run's placement_map, never from a previous run.
    drop table if exists pg_temp.tmp_lab_mx_pairs;
    create temp table tmp_lab_mx_pairs on commit drop as
    with recursive walk as (
        select pm.parent_id as ancestor_id,
               pm.member_id as descendant_id,
               1            as level
        from lab.placement_map pm
        where pm.run_id = p_run_id
          and pm.parent_id is not null

        union all

        select pm2.parent_id,
               w.descendant_id,
               w.level + 1
        from walk w
        join lab.placement_map pm2
          on pm2.run_id = p_run_id
         and pm2.member_id = w.ancestor_id
        where pm2.parent_id is not null
          and w.level < v_depth        -- pairs beyond the paid depth pay nobody
    )
    select * from walk;

    -- Lines: per placement-source, flat depth for qualified earners.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id,
           pr.ancestor_id,
           pr.descendant_id,
           pr.level,
           src.cv,
           rt.rate,
           round(rt.rate * src.cv, 2),
           'matrix_level_pay'
    from pg_temp.tmp_lab_mx_pairs pr
    join pg_temp.tmp_lab_mx_calc earner on earner.member_id = pr.ancestor_id
    join pg_temp.tmp_lab_mx_calc src    on src.member_id    = pr.descendant_id
    join pg_temp.tmp_lab_mx_rates rt    on rt.level         = pr.level
    where earner.qualified
      and src.cv > 0
    order by pr.ancestor_id, pr.level, pr.descendant_id;

    -- Leg totals: the FULL placement subtree under each of the member's
    -- three slots (full depth, like binary's leg CV: a shape metric, not a
    -- pay quantity, so the paid-depth cap does not apply to it). One
    -- recursive pass carrying the top slot, exactly the binary leg pattern.
    drop table if exists pg_temp.tmp_lab_mx_legs;
    create temp table tmp_lab_mx_legs on commit drop as
    with recursive pp as (
        select pm.parent_id as ancestor_id,
               pm.member_id as descendant_id,
               pm.slot      as top_slot
        from lab.placement_map pm
        where pm.run_id = p_run_id
          and pm.parent_id is not null

        union all

        select pp.ancestor_id,
               pm.member_id,
               pp.top_slot
        from pp
        join lab.placement_map pm
          on pm.run_id = p_run_id
         and pm.parent_id = pp.descendant_id
    )
    select pp.ancestor_id, pp.top_slot, sum(v.cv) as leg_cv
    from pp
    join pg_temp.tmp_lab_mx_calc v on v.member_id = pp.descendant_id
    group by pp.ancestor_id, pp.top_slot;

    -- Results: every member, with the three placement legs' CV totals.
    insert into lab.plan_run_results
        (run_id, member_id, sv, cv, qualified, rank_label, plan_metrics, total_earned)
    select p_run_id,
           c.member_id,
           c.sv,
           c.cv,
           c.qualified,
           case when e.total_earned > 0 then 'matrix_earner' else 'member' end,
           jsonb_build_object(
               'leg_cv_0', coalesce(l0.leg_cv, 0.00),
               'leg_cv_1', coalesce(l1.leg_cv, 0.00),
               'leg_cv_2', coalesce(l2.leg_cv, 0.00),
               'placement_depth', pm.depth),
           coalesce(e.total_earned, 0.00)
    from pg_temp.tmp_lab_mx_calc c
    join lab.placement_map pm
      on pm.run_id = p_run_id and pm.member_id = c.member_id
    left join pg_temp.tmp_lab_mx_legs l0
      on l0.ancestor_id = c.member_id and l0.top_slot = 0
    left join pg_temp.tmp_lab_mx_legs l1
      on l1.ancestor_id = c.member_id and l1.top_slot = 1
    left join pg_temp.tmp_lab_mx_legs l2
      on l2.ancestor_id = c.member_id and l2.top_slot = 2
    left join (
        select l.earner_id, sum(l.amount) as total_earned
        from lab.plan_run_lines l
        where l.run_id = p_run_id
        group by l.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    drop table if exists pg_temp.tmp_lab_mx_legs;
    drop table if exists pg_temp.tmp_lab_mx_pairs;
    drop table if exists pg_temp.tmp_lab_mx_calc;
    drop table if exists pg_temp.tmp_lab_mx_rates;
end;
$$;

revoke execute on function lab.fn_plan_matrix(bigint) from public;
