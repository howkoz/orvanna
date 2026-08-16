-- Lab 016: plan five, 'orvanna_builder' (three layers, two laws)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: docs\ORVANNA-BUILDER-PLAN-SPEC.md v1.0 (THE LAW for this plan),
--       running under the lab engine contract of COMP-LAB-SPEC.md v1.3.
--       Requires db\lab\001..015.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV), Team Volume
-- (TV), JavaScript Object Notation (JSON), Quality Assurance (QA).
--
-- THE PLAN IN ONE VIEW (spec section 1): layer 1 THE SPINE = unilevel v1.3
-- exactly (reason 'builder_spine_level_pay', line-identical to plan
-- 'unilevel_v13' on any month, a gate fixture); layer 2 BUILDER OVERRIDES =
-- gen1/gen2 on each downline Builder's group CV via the boundary-counter
-- walk with NO breakaway (groups nest; the waterfall is the ceiling, spec
-- section 3's honest consequence); layer 3 SECOND-LEG BONUS = second-
-- strongest sponsor-genealogy leg's CV at second_leg_rate x an active-leg
-- multiplier (1.00 / 1.15 / 1.25), no placement tree anywhere. Law A DECAY:
-- everything monthly-pure (already structural: every lab run computes fresh
-- from its month's snapshot). Law B THE WATERFALL: per-source pool of
-- pool_rate x CV(s), spine senior (never prorates, its 25-point maximum
-- claim equals the default pool exactly), overrides one class next, bonus
-- junior; factors and prorated pieces TRUNCATED at scale 6; a line's amount
-- is rounded half up when untouched and FLOORED to cents when any piece was
-- prorated, so paid never exceeds pool in exact arithmetic or rounded money.
--
-- ROUNDING IDENTITY (spec section 8): amount = round(rate x basis, 2) holds
-- for every line NOT touched by proration; prorated lines are floored and
-- flagged prorated = true in the earner's plan_metrics trace, a scoped
-- exception in the style of 'stairstep_differential'.
--
-- ZERO LINES: a claim prorated to 0.00 writes NO line (house decision c);
-- the claim and its zero payment remain visible in the plan_metrics traces,
-- so spec 12A(a)'s "every override claim pays 0.00" case is auditable
-- without statement noise.
--
-- SPINE-FITS ASSERTION: with the default pool_rate 0.25 the spine's maximum
-- claim exactly equals the pool (spec section 7 proof). The function
-- ASSERTS spine_claimed <= pool per source and refuses the run loudly if a
-- parameter choice (open question 1's stricter-bank alternative) breaks the
-- property, rather than silently prorating the spine.

-- ---------------------------------------------------------------------------
-- Contract surface: plan five registers in the plan_code CHECK and brings
-- four reason codes. Constraint names are the auto-generated ones from 001.
-- ---------------------------------------------------------------------------
alter table lab.plan_runs drop constraint plan_runs_plan_code_check;
alter table lab.plan_runs add constraint plan_runs_plan_code_check
    check (plan_code in ('unilevel_v13', 'binary', 'matrix_3x7',
                         'stairstep_breakaway', 'orvanna_builder'));
-- plan_runs_strategy_matches_plan is untouched: 'orvanna_builder' is not a
-- placement plan, so placement_strategy must be null, exactly like
-- stairstep (spec section 8 mapping).

alter table lab.plan_run_lines drop constraint plan_run_lines_reason_check;
alter table lab.plan_run_lines add constraint plan_run_lines_reason_check
    check (reason in ('unilevel_level_pay', 'binary_pay_leg',
                      'matrix_level_pay', 'stairstep_differential',
                      'stairstep_override_gen1', 'stairstep_override_gen2',
                      'builder_spine_level_pay', 'builder_override_gen1',
                      'builder_override_gen2', 'builder_second_leg_bonus'));

-- ---------------------------------------------------------------------------
-- lab.fn_plan_orvanna_builder(p_run_id)
-- ---------------------------------------------------------------------------
create or replace function lab.fn_plan_orvanna_builder(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_params    jsonb;
    v_gen1      numeric;
    v_gen2      numeric;
    v_slr       numeric;
    v_pool_rate numeric;
    v_mult      jsonb;
    rb          record;
    v_cand      record;
    v_cur       bigint;
    v_k         int;
    v_g1        boolean;
    v_g2        boolean;
    v_bad       bigint;
begin
    select r.plan_params into v_params
    from lab.plan_runs r where r.id = p_run_id;

    if v_params is null or jsonb_typeof(v_params -> 'spine_rates') <> 'array' then
        raise exception
            'lab.fn_plan_orvanna_builder: run % plan_params must carry a "spine_rates" array', p_run_id;
    end if;
    v_gen1      := (v_params ->> 'gen1_rate')::numeric;
    v_gen2      := (v_params ->> 'gen2_rate')::numeric;
    v_slr       := (v_params ->> 'second_leg_rate')::numeric;
    v_pool_rate := (v_params ->> 'pool_rate')::numeric;
    v_mult      := v_params -> 'leg_multipliers';
    if v_gen1 is null or v_gen2 is null or v_slr is null
       or v_pool_rate is null or v_mult is null then
        raise exception
            'lab.fn_plan_orvanna_builder: run % plan_params must carry gen1_rate, gen2_rate, '
            'second_leg_rate, pool_rate, leg_multipliers', p_run_id;
    end if;

    -- =======================================================================
    -- LAYER 1, THE SPINE: the unilevel v1.3 staged computation, verbatim
    -- from lab.fn_plan_unilevel (parity-proven at L1), reading this run's
    -- snapshots. group_cv rides along (cv + full-depth descendant cv), used
    -- by layers 2 and 3.
    -- =======================================================================
    drop table if exists pg_temp.tmp_ob_rates;
    create temp table tmp_ob_rates on commit drop as
    select t.ord::int as level, (t.val)::numeric(6,4) as rate
    from jsonb_array_elements_text(v_params -> 'spine_rates') with ordinality as t(val, ord);

    drop table if exists pg_temp.tmp_ob_calc;
    create temp table tmp_ob_calc on commit drop as
    with vols as (
        select mv.member_id,
               mv.sv,
               (round(0.80 * mv.sv, 2))::numeric(12,2) as cv
        from lab.member_volumes mv
        where mv.run_id = p_run_id
    ),
    tv_agg as (
        select lm.ancestor_id as member_id, sum(v.sv) as tv
        from lab.run_level_map lm
        join vols v on v.member_id = lm.descendant_id
        where lm.run_id = p_run_id
        group by lm.ancestor_id
    ),
    gcv_agg as (
        select lm.ancestor_id as member_id, sum(v.cv) as desc_cv
        from lab.run_level_map lm
        join vols v on v.member_id = lm.descendant_id
        where lm.run_id = p_run_id
        group by lm.ancestor_id
    ),
    base as (
        select v.member_id, v.sv, v.cv,
               (coalesce(t.tv, 0))::numeric(14,2)          as tv,
               (v.cv + coalesce(g.desc_cv, 0))::numeric(14,2) as group_cv,
               (v.sv >= 100.00)                            as qualified
        from vols v
        left join tv_agg t on t.member_id = v.member_id
        left join gcv_agg g on g.member_id = v.member_id
    ),
    legs as (
        select lm.ancestor_id as member_id, lm.descendant_id as child_id
        from lab.run_level_map lm
        where lm.run_id = p_run_id and lm.level = 1
    ),
    active_leg_counts as (
        select l.member_id, count(*) as n_active_legs
        from legs l
        join base c on c.member_id = l.child_id
        where c.qualified
        group by l.member_id
    ),
    flags_bl as (
        select b.member_id, b.sv, b.cv, b.tv, b.group_cv, b.qualified,
               coalesce(al.n_active_legs, 0)                        as n_active_legs,
               (b.qualified and coalesce(al.n_active_legs, 0) >= 2) as builder_flag_stage,
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
          on lm.run_id = p_run_id and lm.ancestor_id = l.child_id
    ),
    director_leg_counts as (
        select lmem.member_id, count(distinct lmem.child_id) as n_legs_with_builder_plus
        from leg_members lmem
        join flags_bl f on f.member_id = lmem.leg_member_id
        where f.builder_flag_stage or f.leader_flag
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
        select lmem.member_id, count(distinct lmem.child_id) as n_legs_with_leader_plus
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
        select f.member_id, f.sv, f.cv, f.tv, f.group_cv, f.qualified, f.n_active_legs,
               case
                   when f.executive_flag       then 'executive'
                   when f.director_flag        then 'director'
                   when f.leader_flag          then 'leader'
                   when f.builder_flag_stage   then 'builder'
                   else 'member'
               end as rank_code
        from flags_e f
    )
    select r.member_id, r.sv, r.cv, r.tv, r.group_cv, r.qualified, r.n_active_legs,
           r.rank_code, rk.paid_depth,
           (r.rank_code <> 'member') as builder_flag   -- Builder OR ABOVE
    from ranked r
    join app.ranks rk on rk.rank_code = r.rank_code;

    -- Spine lines: the unilevel lines verbatim, plan five's reason code.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id, lm.ancestor_id, lm.descendant_id, lm.level,
           src.cv, rt.rate, round(rt.rate * src.cv, 2), 'builder_spine_level_pay'
    from lab.run_level_map lm
    join pg_temp.tmp_ob_calc earner on earner.member_id = lm.ancestor_id
    join pg_temp.tmp_ob_calc src    on src.member_id    = lm.descendant_id
    join pg_temp.tmp_ob_rates rt    on rt.level         = lm.level
    where lm.run_id = p_run_id
      and earner.qualified
      and lm.level <= earner.paid_depth
      and src.cv > 0
    order by lm.ancestor_id, lm.level, lm.descendant_id;

    -- =======================================================================
    -- LAYER 2, THE OVERRIDE WALK (spec section 3): per Builder-or-above B,
    -- boundary counter with Builder-rank boundaries, evaluate then count,
    -- NO breakaway. Ascending builder id for a stable trace order.
    -- =======================================================================
    drop table if exists pg_temp.tmp_ob_over;
    create temp table tmp_ob_over (
        earner_id  bigint,
        builder_id bigint,
        gen        int,
        rate       numeric,
        group_cv   numeric
    ) on commit drop;

    for rb in
        select c.member_id, d.sponsor_id, c.group_cv
        from pg_temp.tmp_ob_calc c
        join lab.derived_members d
          on d.run_id = p_run_id and d.member_id = c.member_id
        where c.builder_flag
        order by c.member_id
    loop
        v_cur := rb.sponsor_id;
        v_k := 0; v_g1 := false; v_g2 := false;

        while v_cur is not null and v_k <= 1 loop
            select c.qualified, c.builder_flag, d.sponsor_id
            into v_cand
            from pg_temp.tmp_ob_calc c
            join lab.derived_members d
              on d.run_id = p_run_id and d.member_id = c.member_id
            where c.member_id = v_cur;

            if v_cand.qualified and v_k = 0 and not v_g1 then
                insert into tmp_ob_over values (v_cur, rb.member_id, 1, v_gen1, rb.group_cv);
                v_g1 := true;
            elsif v_cand.qualified and v_k = 1 and not v_g2 then
                insert into tmp_ob_over values (v_cur, rb.member_id, 2, v_gen2, rb.group_cv);
                v_g2 := true;
                exit;
            end if;

            if v_cand.builder_flag then
                v_k := v_k + 1;   -- the boundary, counted after candidacy
            end if;

            v_cur := v_cand.sponsor_id;
        end loop;
    end loop;

    -- =======================================================================
    -- LAYER 3, THE SECOND-LEG BONUS (spec section 4): legs ranked over ALL
    -- legs by leg CV descending (ties: frontline id ascending); eligibility
    -- and the multiplier count ACTIVE legs (open question 4's default).
    -- =======================================================================
    drop table if exists pg_temp.tmp_ob_legs;
    create temp table tmp_ob_legs on commit drop as
    select lm.ancestor_id  as earner_id,
           lm.descendant_id as frontline_id,
           child.group_cv   as leg_cv,        -- frontline + its whole subtree
           child.qualified  as active,
           row_number() over (partition by lm.ancestor_id
                              order by child.group_cv desc, lm.descendant_id asc) as leg_rank
    from lab.run_level_map lm
    join pg_temp.tmp_ob_calc child on child.member_id = lm.descendant_id
    where lm.run_id = p_run_id and lm.level = 1;

    drop table if exists pg_temp.tmp_ob_bonus;
    create temp table tmp_ob_bonus on commit drop as
    select e.member_id                                   as earner_id,
           sl.frontline_id                               as second_frontline_id,
           sl.leg_cv                                     as second_leg_cv,
           case when e.n_active_legs >= 4 then (v_mult ->> '4')::numeric
                when e.n_active_legs =  3 then (v_mult ->> '3')::numeric
                else (v_mult ->> '2')::numeric end       as multiplier,
           (v_slr * case when e.n_active_legs >= 4 then (v_mult ->> '4')::numeric
                         when e.n_active_legs =  3 then (v_mult ->> '3')::numeric
                         else (v_mult ->> '2')::numeric end)::numeric as eff_rate
    from pg_temp.tmp_ob_calc e
    join pg_temp.tmp_ob_legs sl
      on sl.earner_id = e.member_id and sl.leg_rank = 2
    where e.qualified
      and e.n_active_legs >= 2;

    -- =======================================================================
    -- LAW B, THE WATERFALL (spec section 7): claims per source, closed-form
    -- factors per source, truncation at scale 6, no enumeration order
    -- anywhere.
    -- =======================================================================
    drop table if exists pg_temp.tmp_ob_claims;
    create temp table tmp_ob_claims on commit drop as
    -- Layer 1: spine lines are already per-source claims (exact cents).
    select 1 as layer, l.earner_id, null::bigint as builder_id, null::int as gen,
           l.source_member_id as source_id, l.amount::numeric as claim
    from lab.plan_run_lines l
    where l.run_id = p_run_id and l.reason = 'builder_spine_level_pay'
    union all
    -- Layer 2: an override on B's group CV is identically the claims
    -- rate x CV(m) for every member m of B's group, B included.
    select 2, o.earner_id, o.builder_id, o.gen, gm.member_id,
           trunc(o.rate * c.cv, 6)
    from pg_temp.tmp_ob_over o
    join (
        select b2.builder_id, b2.builder_id as member_id
        from (select distinct builder_id from pg_temp.tmp_ob_over) b2
        union all
        select b2.builder_id, lm.descendant_id
        from (select distinct builder_id from pg_temp.tmp_ob_over) b2
        join lab.run_level_map lm
          on lm.run_id = p_run_id and lm.ancestor_id = b2.builder_id
    ) gm on gm.builder_id = o.builder_id
    join pg_temp.tmp_ob_calc c on c.member_id = gm.member_id
    where c.cv > 0
    union all
    -- Layer 3: a bonus on the second-strongest leg is identically the
    -- claims eff_rate x CV(m) for every member m of that leg.
    select 3, bz.earner_id, null, null, lgm.member_id,
           trunc(bz.eff_rate * c.cv, 6)
    from pg_temp.tmp_ob_bonus bz
    join (
        select b3.earner_id, b3.second_frontline_id as member_id
        from pg_temp.tmp_ob_bonus b3
        union all
        select b3.earner_id, lm.descendant_id
        from pg_temp.tmp_ob_bonus b3
        join lab.run_level_map lm
          on lm.run_id = p_run_id and lm.ancestor_id = b3.second_frontline_id
    ) lgm on lgm.earner_id = bz.earner_id
    join pg_temp.tmp_ob_calc c on c.member_id = lgm.member_id
    where c.cv > 0;

    drop table if exists pg_temp.tmp_ob_pool;
    create temp table tmp_ob_pool on commit drop as
    with sums as (
        select cl.source_id,
               sum(cl.claim) filter (where cl.layer = 1) as spine_claimed,
               sum(cl.claim) filter (where cl.layer = 2) as l2_claimed,
               sum(cl.claim) filter (where cl.layer = 3) as l3_claimed
        from pg_temp.tmp_ob_claims cl
        group by cl.source_id
    )
    select c.member_id as source_id,
           trunc(v_pool_rate * c.cv, 6)   as pool,
           coalesce(s.spine_claimed, 0)   as spine_claimed,
           coalesce(s.l2_claimed, 0)      as l2_claimed,
           coalesce(s.l3_claimed, 0)      as l3_claimed
    from pg_temp.tmp_ob_calc c
    left join sums s on s.source_id = c.member_id;

    -- The spine always fits (proof in spec section 7); assert it so an
    -- exotic pool_rate refuses loudly instead of silently prorating layer 1.
    select p.source_id into v_bad
    from pg_temp.tmp_ob_pool p
    where p.spine_claimed > p.pool
    limit 1;
    if v_bad is not null then
        raise exception
            'lab.fn_plan_orvanna_builder: run % source % spine claim exceeds its pool; '
            'pool_rate breaks the spine-never-prorates property (spec section 7 and '
            'open question 1); the run refuses',
            p_run_id, v_bad;
    end if;

    -- Factors: closed formulas per source (order-independence by
    -- construction), truncated at scale 6.
    alter table pg_temp.tmp_ob_pool add column f2 numeric;
    alter table pg_temp.tmp_ob_pool add column l2_paid numeric;
    alter table pg_temp.tmp_ob_pool add column f3 numeric;
    alter table pg_temp.tmp_ob_pool add column l3_paid numeric;

    update pg_temp.tmp_ob_pool p
    set f2 = case when p.l2_claimed = 0 then 1
                  else least(1, trunc((p.pool - p.spine_claimed) / p.l2_claimed, 6)) end;

    update pg_temp.tmp_ob_pool p
    set l2_paid = coalesce((select sum(case when p.f2 = 1 then cl.claim
                                            else trunc(cl.claim * p.f2, 6) end)
                            from pg_temp.tmp_ob_claims cl
                            where cl.source_id = p.source_id and cl.layer = 2), 0);

    update pg_temp.tmp_ob_pool p
    set f3 = case when p.l3_claimed = 0 then 1
                  else least(1, trunc((p.pool - p.spine_claimed - p.l2_paid)
                                      / p.l3_claimed, 6)) end;

    update pg_temp.tmp_ob_pool p
    set l3_paid = coalesce((select sum(case when p.f3 = 1 then cl.claim
                                            else trunc(cl.claim * p.f3, 6) end)
                            from pg_temp.tmp_ob_claims cl
                            where cl.source_id = p.source_id and cl.layer = 3), 0);

    -- Paid pieces per claim (for line assembly and traces).
    drop table if exists pg_temp.tmp_ob_pieces;
    create temp table tmp_ob_pieces on commit drop as
    select cl.layer, cl.earner_id, cl.builder_id, cl.gen, cl.source_id, cl.claim,
           case cl.layer
               when 1 then cl.claim
               when 2 then case when p.f2 = 1 then cl.claim else trunc(cl.claim * p.f2, 6) end
               else        case when p.f3 = 1 then cl.claim else trunc(cl.claim * p.f3, 6) end
           end as piece,
           case cl.layer
               when 1 then false
               when 2 then (p.f2 < 1)
               else        (p.f3 < 1)
           end as prorated
    from pg_temp.tmp_ob_claims cl
    join pg_temp.tmp_ob_pool p on p.source_id = cl.source_id;

    -- THE INVARIANT, asserted in exact arithmetic before any line lands:
    -- spine + layer 2 paid + layer 3 paid <= pool, per source, at scale 6.
    select p.source_id into v_bad
    from pg_temp.tmp_ob_pool p
    where p.spine_claimed + p.l2_paid + p.l3_paid > p.pool
    limit 1;
    if v_bad is not null then
        raise exception
            'lab.fn_plan_orvanna_builder: run % source % breached its pool; Law B is '
            'arithmetic, so this is a build defect and the run refuses',
            p_run_id, v_bad;
    end if;

    -- Layer 2 lines: one per (earner, builder, gen); floored when any piece
    -- prorated, half-up otherwise; zero-amount lines are not written.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id, x.earner_id, x.builder_id, null,
           x.group_cv, x.rate,
           case when x.any_pror then trunc(x.paid, 2) else round(x.paid, 2) end,
           case x.gen when 1 then 'builder_override_gen1' else 'builder_override_gen2' end
    from (
        select o.earner_id, o.builder_id, o.gen, o.rate, o.group_cv,
               sum(pc.piece) as paid, bool_or(pc.prorated) as any_pror
        from pg_temp.tmp_ob_over o
        join pg_temp.tmp_ob_pieces pc
          on pc.layer = 2 and pc.earner_id = o.earner_id
         and pc.builder_id = o.builder_id and pc.gen = o.gen
        group by o.earner_id, o.builder_id, o.gen, o.rate, o.group_cv
    ) x
    where case when x.any_pror then trunc(x.paid, 2) else round(x.paid, 2) end > 0
    order by x.earner_id, x.gen, x.builder_id;

    -- Layer 3 lines: one per earner.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id, x.earner_id, null, null,
           x.second_leg_cv, x.eff_rate,
           case when x.any_pror then trunc(x.paid, 2) else round(x.paid, 2) end,
           'builder_second_leg_bonus'
    from (
        select bz.earner_id, bz.second_leg_cv, bz.eff_rate,
               sum(pc.piece) as paid, bool_or(pc.prorated) as any_pror
        from pg_temp.tmp_ob_bonus bz
        join pg_temp.tmp_ob_pieces pc
          on pc.layer = 3 and pc.earner_id = bz.earner_id
        group by bz.earner_id, bz.second_leg_cv, bz.eff_rate
    ) x
    where case when x.any_pror then trunc(x.paid, 2) else round(x.paid, 2) end > 0
    order by x.earner_id;

    -- Results: earner-side metrics (spec section 8), the layer traces (so
    -- the verifier rebuilds every prorated amount), and the source-side
    -- waterfall record at scale 6 under the 'source' key.
    insert into lab.plan_run_results
        (run_id, member_id, sv, cv, qualified, rank_label, plan_metrics, total_earned)
    select p_run_id, c.member_id, c.sv, c.cv, c.qualified, c.rank_code,
           jsonb_build_object(
               'paid_depth',       c.paid_depth,
               'builder_flag',     c.builder_flag,
               'group_cv',         c.group_cv,
               'tv',               c.tv,
               'active_leg_count', c.n_active_legs,
               'legs', coalesce((select jsonb_agg(jsonb_build_object(
                                        'frontline_code', fd.member_code,
                                        'leg_cv', lg.leg_cv,
                                        'active', lg.active)
                                        order by lg.leg_rank)
                                 from pg_temp.tmp_ob_legs lg
                                 join lab.derived_members fd
                                   on fd.run_id = p_run_id and fd.member_id = lg.frontline_id
                                 where lg.earner_id = c.member_id), '[]'::jsonb),
               'second_leg_frontline', (select fd.member_code
                                        from pg_temp.tmp_ob_bonus bz
                                        join lab.derived_members fd
                                          on fd.run_id = p_run_id
                                         and fd.member_id = bz.second_frontline_id
                                        where bz.earner_id = c.member_id),
               'second_leg_cv',   (select bz.second_leg_cv from pg_temp.tmp_ob_bonus bz
                                   where bz.earner_id = c.member_id),
               'multiplier',      (select bz.multiplier from pg_temp.tmp_ob_bonus bz
                                   where bz.earner_id = c.member_id),
               'l2_traces', coalesce((select jsonb_agg(jsonb_build_object(
                                             'builder', bd.member_code,
                                             'gen', t.gen,
                                             'claimed', t.claimed,
                                             'paid', t.paid,
                                             'prorated', t.any_pror)
                                             order by t.gen, bd.member_code)
                                      from (select o.builder_id, o.gen,
                                                   trunc(o.rate * o.group_cv, 6) as claimed,
                                                   sum(pc.piece) as paid,
                                                   bool_or(pc.prorated) as any_pror
                                            from pg_temp.tmp_ob_over o
                                            join pg_temp.tmp_ob_pieces pc
                                              on pc.layer = 2 and pc.earner_id = o.earner_id
                                             and pc.builder_id = o.builder_id and pc.gen = o.gen
                                            where o.earner_id = c.member_id
                                            group by o.builder_id, o.gen, o.rate, o.group_cv) t
                                      join lab.derived_members bd
                                        on bd.run_id = p_run_id and bd.member_id = t.builder_id),
                                     '[]'::jsonb),
               'l3_trace', (select jsonb_build_object(
                                   'claimed', trunc(bz.eff_rate * bz.second_leg_cv, 6),
                                   'paid', (select sum(pc.piece) from pg_temp.tmp_ob_pieces pc
                                            where pc.layer = 3 and pc.earner_id = bz.earner_id),
                                   'prorated', (select bool_or(pc.prorated)
                                                from pg_temp.tmp_ob_pieces pc
                                                where pc.layer = 3 and pc.earner_id = bz.earner_id))
                            from pg_temp.tmp_ob_bonus bz
                            where bz.earner_id = c.member_id),
               'source', (select jsonb_build_object(
                                 'pool', p.pool,
                                 'spine_claimed', p.spine_claimed,
                                 'l2_claimed', p.l2_claimed,
                                 'l2_paid', p.l2_paid,
                                 'f2', p.f2,
                                 'l3_claimed', p.l3_claimed,
                                 'l3_paid', p.l3_paid,
                                 'f3', p.f3)
                          from pg_temp.tmp_ob_pool p
                          where p.source_id = c.member_id)),
           coalesce(e.total_earned, 0.00)
    from pg_temp.tmp_ob_calc c
    left join (
        select l.earner_id, sum(l.amount) as total_earned
        from lab.plan_run_lines l
        where l.run_id = p_run_id
        group by l.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    drop table if exists pg_temp.tmp_ob_pieces;
    drop table if exists pg_temp.tmp_ob_pool;
    drop table if exists pg_temp.tmp_ob_claims;
    drop table if exists pg_temp.tmp_ob_bonus;
    drop table if exists pg_temp.tmp_ob_legs;
    drop table if exists pg_temp.tmp_ob_over;
    drop table if exists pg_temp.tmp_ob_calc;
    drop table if exists pg_temp.tmp_ob_rates;
end;
$$;

revoke execute on function lab.fn_plan_orvanna_builder(bigint) from public;

-- ---------------------------------------------------------------------------
-- Dispatcher: plan five joins the CASE (fn_execute_plan v5; everything else
-- byte-identical to the 015 body).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_execute_plan(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_run   lab.plan_runs%rowtype;
    v_width int;
begin
    select * into v_run from lab.plan_runs where id = p_run_id;

    if not found then
        raise exception 'lab.fn_execute_plan: run % does not exist', p_run_id;
    end if;
    if v_run.status <> 'running' then
        raise exception
            'lab.fn_execute_plan: run % has status ''%''; only a running run may execute',
            p_run_id, v_run.status;
    end if;
    if not exists (select 1 from lab.derived_members d where d.run_id = p_run_id) then
        raise exception 'lab.fn_execute_plan: run % has no derived member set', p_run_id;
    end if;
    if not exists (select 1 from lab.member_volumes v where v.run_id = p_run_id) then
        raise exception 'lab.fn_execute_plan: run % has no volume snapshot', p_run_id;
    end if;

    update lab.plan_runs set started_at = clock_timestamp() where id = p_run_id;

    execute 'analyze lab.derived_members';
    execute 'analyze lab.member_volumes';

    perform lab.fn_build_level_map(p_run_id);
    execute 'analyze lab.run_level_map';

    if v_run.placement_strategy is not null then
        v_width := case v_run.plan_code
                       when 'binary'     then 2
                       when 'matrix_3x7' then coalesce((v_run.plan_params ->> 'width')::int, 3)
                   end;
        perform lab.fn_derive_placement_width(p_run_id, v_width);
        execute 'analyze lab.placement_map';
    end if;

    case v_run.plan_code
        when 'unilevel_v13'        then perform lab.fn_plan_unilevel(p_run_id);
        when 'binary'              then perform lab.fn_plan_binary(p_run_id);
        when 'matrix_3x7'          then perform lab.fn_plan_matrix(p_run_id);
        when 'stairstep_breakaway' then perform lab.fn_plan_stairstep(p_run_id);
        when 'orvanna_builder'     then perform lab.fn_plan_orvanna_builder(p_run_id);
    end case;

    perform lab.fn_write_watch_snapshots(p_run_id);

    update lab.plan_runs r
    set total_sv     = t.total_sv,
        total_cv     = t.total_cv,
        total_payout = t.total_payout,
        members_paid = t.members_paid,
        finished_at  = clock_timestamp(),
        status       = 'complete'
    from (
        select (coalesce(sum(pr.sv), 0))::numeric(14,2)           as total_sv,
               (coalesce(sum(pr.cv), 0))::numeric(14,2)           as total_cv,
               (coalesce(sum(pr.total_earned), 0))::numeric(14,2) as total_payout,
               count(*) filter (where pr.total_earned > 0)        as members_paid
        from lab.plan_run_results pr
        where pr.run_id = p_run_id
    ) t
    where r.id = p_run_id;
end;
$$;

revoke execute on function lab.fn_execute_plan(bigint) from public;

-- ---------------------------------------------------------------------------
-- lab.fn_basis_member_codes v2: plan five's aggregate basis is the second-
-- strongest leg (frontline from the earner's plan_metrics, plus its whole
-- subtree). Binary and stairstep branches unchanged.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_basis_member_codes(p_run_id bigint, p_member_id bigint)
returns text[]
language plpgsql
stable
as $$
declare
    v_plan     text;
    v_pay_slot int;
    v_codes    text[];
    v_front    bigint;
begin
    select r.plan_code into v_plan from lab.plan_runs r where r.id = p_run_id;

    if v_plan = 'binary' then
        select case when (pr.plan_metrics ->> 'pay_leg') = 'left' then 0 else 1 end
        into v_pay_slot
        from lab.plan_run_results pr
        where pr.run_id = p_run_id and pr.member_id = p_member_id;

        with recursive pp as (
            select pm.member_id, pm.slot as top_slot
            from lab.placement_map pm
            where pm.run_id = p_run_id and pm.parent_id = p_member_id
            union all
            select pm.member_id, pp.top_slot
            from lab.placement_map pm
            join pp on pm.parent_id = pp.member_id
            where pm.run_id = p_run_id
        )
        select coalesce(array_agg(d.member_code order by d.member_code), '{}')
        into v_codes
        from pp
        join lab.derived_members d
          on d.run_id = p_run_id and d.member_id = pp.member_id
        where pp.top_slot = v_pay_slot;
        return v_codes;

    elsif v_plan = 'stairstep_breakaway' then
        with recursive grp as (
            select d.member_id
            from lab.derived_members d
            join lab.plan_run_results pr
              on pr.run_id = p_run_id and pr.member_id = d.member_id
            where d.run_id = p_run_id
              and d.sponsor_id = p_member_id
              and not (pr.plan_metrics ->> 'breakaway')::boolean
            union all
            select d.member_id
            from lab.derived_members d
            join lab.plan_run_results pr
              on pr.run_id = p_run_id and pr.member_id = d.member_id
            join grp on d.sponsor_id = grp.member_id
            where d.run_id = p_run_id
              and not (pr.plan_metrics ->> 'breakaway')::boolean
        )
        select coalesce(array_agg(d.member_code order by d.member_code), '{}')
        into v_codes
        from grp
        join lab.derived_members d
          on d.run_id = p_run_id and d.member_id = grp.member_id;
        return v_codes;

    elsif v_plan = 'orvanna_builder' then
        select fd.member_id into v_front
        from lab.plan_run_results pr
        join lab.derived_members fd
          on fd.run_id = p_run_id
         and fd.member_code = pr.plan_metrics ->> 'second_leg_frontline'
        where pr.run_id = p_run_id and pr.member_id = p_member_id;

        if v_front is null then
            return '{}';
        end if;

        select coalesce(array_agg(d.member_code order by d.member_code), '{}')
        into v_codes
        from (
            select v_front as member_id
            union all
            select lm.descendant_id
            from lab.run_level_map lm
            where lm.run_id = p_run_id and lm.ancestor_id = v_front
        ) leg
        join lab.derived_members d
          on d.run_id = p_run_id and d.member_id = leg.member_id;
        return v_codes;
    end if;

    return null;
end;
$$;

revoke execute on function lab.fn_basis_member_codes(bigint, bigint) from public;
