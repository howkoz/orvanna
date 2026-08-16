-- Lab 005: plan 'binary', draft parameters, told honestly
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 4.2 (parameters) and section 3
--       (derived placement). Requires db\lab\001, 002, 003.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV),
-- JavaScript Object Notation (JSON).
--
-- THE PLAN: one line per qualified earner per month, reason 'binary_pay_leg',
-- basis = pay-leg CV, amount = round half up (pay_leg_rate x basis, 2), then
-- capped at cap_per_member. Pay leg = the leg with the SMALLER total CV this
-- month (ties: LEFT leg is the pay leg). Unmatched CV in the stronger leg is
-- FLUSHED (discarded at month end; no carry ledger in lab v1, because
-- carryover makes months non-independent and the lab runs months
-- independently). An empty leg pays zero: min(left, right) with an empty leg
-- is 0 and NO line is written, mirroring the engine's no-zero-lines decision.
--
-- Parameters read from plan_params (stored verbatim on the run row):
--   pay_leg_rate   (draft 0.20)
--   cap_per_member (draft 2500.00)
-- The other section 4.2 draft parameters (pay_leg 'weaker', carryover
-- 'flush', earner gate 'qualified', empty leg 'pays zero') are STRUCTURAL in
-- this implementation and recorded in the run's parameter JSON for the
-- record; a change to any of them is new code, not a new parameter value.
--
-- WHAT plan_metrics CARRIES, per member (spec 1.2 names left and right CV;
-- the rest serve the section 5 breakage and flush reporting):
--   left_cv, right_cv    both legs' CV totals (0.00 for an empty leg)
--   pay_leg              'left' or 'right' (ties resolve left)
--   pay_leg_cv           min(left_cv, right_cv)
--   flushed_cv           the stronger leg's unmatched CV, reported per spec
--                        section 5 as 'unmatched, not breakage'
--   uncapped_amount      round(rate x pay_leg_cv, 2) before the cap
--   capped               true when the cap reduced the paid amount; the
--                        capped remainder (uncapped_amount minus the paid
--                        amount) is the recorded breakage of the cap

create or replace function lab.fn_plan_binary(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_params jsonb;
    v_rate   numeric;
    v_cap    numeric;
begin
    select r.plan_params into v_params
    from lab.plan_runs r
    where r.id = p_run_id;

    v_rate := (v_params ->> 'pay_leg_rate')::numeric;
    v_cap  := (v_params ->> 'cap_per_member')::numeric;

    if v_rate is null or v_cap is null then
        raise exception
            'lab.fn_plan_binary: run % plan_params must carry pay_leg_rate and cap_per_member',
            p_run_id;
    end if;

    if not exists (select 1 from lab.placement_map pm where pm.run_id = p_run_id) then
        raise exception
            'lab.fn_plan_binary: run % has no placement map; lab.fn_derive_placement must run first',
            p_run_id;
    end if;

    -- Per-member volumes and legs, all set-based. placement_pairs assigns
    -- every placed member to (ancestor, which top slot under that ancestor),
    -- so leg CV totals are one aggregate.
    drop table if exists pg_temp.tmp_lab_bin_calc;
    create temp table tmp_lab_bin_calc on commit drop as
    with recursive vols as (
        select mv.member_id,
               mv.sv,
               (round(0.80 * mv.sv, 2))::numeric(12,2) as cv,
               (mv.sv >= 100.00)                       as qualified
        from lab.member_volumes mv
        where mv.run_id = p_run_id
    ),
    placement_pairs as (
        -- (ancestor, descendant, the slot the descendant sits under at the
        -- ancestor). Recursive DOWN the placement tree, carrying the top
        -- slot with each step.
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
        from placement_pairs pp
        join lab.placement_map pm
          on pm.run_id = p_run_id
         and pm.parent_id = pp.descendant_id
    ),
    leg_totals as (
        select pp.ancestor_id,
               pp.top_slot,
               sum(v.cv) as leg_cv
        from placement_pairs pp
        join vols v on v.member_id = pp.descendant_id
        group by pp.ancestor_id, pp.top_slot
    )
    select v.member_id,
           v.sv,
           v.cv,
           v.qualified,
           (coalesce(l.leg_cv, 0))::numeric(14,2) as left_cv,
           (coalesce(r.leg_cv, 0))::numeric(14,2) as right_cv
    from vols v
    left join leg_totals l on l.ancestor_id = v.member_id and l.top_slot = 0
    left join leg_totals r on r.ancestor_id = v.member_id and r.top_slot = 1;

    -- Lines: qualified earners with a non-zero pay leg only. Amount rounded
    -- at the line, then capped. Stable ORDER BY for byte-identical reruns.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id,
           c.member_id,
           null,                                   -- aggregate-basis pay: no single source
           null,                                   -- and no tree level
           least(c.left_cv, c.right_cv),
           v_rate,
           least(round(v_rate * least(c.left_cv, c.right_cv), 2), v_cap),
           'binary_pay_leg'
    from pg_temp.tmp_lab_bin_calc c
    where c.qualified
      and least(c.left_cv, c.right_cv) > 0
    order by c.member_id;

    -- Results for every member, earners and non-earners alike.
    insert into lab.plan_run_results
        (run_id, member_id, sv, cv, qualified, rank_label, plan_metrics, total_earned)
    select p_run_id,
           c.member_id,
           c.sv,
           c.cv,
           c.qualified,
           case when e.total_earned > 0 then 'binary_earner' else 'member' end,
           jsonb_build_object(
               'left_cv',         c.left_cv,
               'right_cv',        c.right_cv,
               'pay_leg',         case when c.left_cv <= c.right_cv then 'left' else 'right' end,
               'pay_leg_cv',      least(c.left_cv, c.right_cv),
               'flushed_cv',      greatest(c.left_cv, c.right_cv) - least(c.left_cv, c.right_cv),
               'uncapped_amount', round(v_rate * least(c.left_cv, c.right_cv), 2),
               'capped',          (round(v_rate * least(c.left_cv, c.right_cv), 2) > v_cap)
           ),
           coalesce(e.total_earned, 0.00)
    from pg_temp.tmp_lab_bin_calc c
    left join (
        select l.earner_id, sum(l.amount) as total_earned
        from lab.plan_run_lines l
        where l.run_id = p_run_id
        group by l.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    drop table if exists pg_temp.tmp_lab_bin_calc;
end;
$$;

revoke execute on function lab.fn_plan_binary(bigint) from public;
