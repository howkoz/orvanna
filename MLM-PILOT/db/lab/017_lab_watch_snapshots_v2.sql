-- Lab 017: the snapshot writer learns plan five, and the pairing key learns reasons
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: ORVANNA-BUILDER-PLAN-SPEC.md section 8 (metrics shapes) with
--       COMP-LAB-SPEC.md v1.3 section 10. Requires db\lab\016. Redefines
--       lab.fn_write_watch_snapshots only.
--
-- TWO CHANGES against the 015 body, each named:
--   1. PAIRING KEY. The six-bucket decomposition joined run and baseline
--      lines by source code alone, which was unique per (earner, source)
--      for every plan through L3. Plan five breaks that: one earner can
--      hold a SPINE line and an OVERRIDE line on the same source member
--      (the source is a Builder in their downline), so the join must pair
--      on (source_code, reason) or a full join would cross-multiply rows
--      and corrupt the buckets. (source_code, reason) is unique per earner
--      for every plan including plan five: spine gives one line per source,
--      and the walk assigns generation 1 and generation 2 for one Builder
--      to DIFFERENT members. For all prior plans this change is a no-op
--      (one per-source reason per source), so no frozen result shifts.
--      Also required for the DECAY fixture's promised attribution: the
--      lapsed override must land in from_reach_lost while the spine line on
--      the same source stays a zero same-level change.
--   2. THE PLAN FIVE BRANCH. shape_volume = {group_cv, second_leg_cv,
--      active_leg_count}; paid_depth = the spine's rank-gated depth from
--      plan_metrics; contributing count = distinct sources on per-source
--      lines (spine plus overrides; the plan is per-source in the main, and
--      the aggregate bonus's members appear through the basis-movement
--      fields instead, spec 10.2 posture). The aggregate part of the delta
--      (the second-leg bonus, source null) flows through the existing
--      aggregate machinery unchanged, with fn_basis_member_codes (016)
--      supplying the second-leg member set.

create or replace function lab.fn_write_watch_snapshots(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_run          lab.plan_runs%rowtype;
    v_baseline     bigint;
    w              record;
    v_member       bigint;
    v_res          lab.plan_run_results%rowtype;
    v_base_member  bigint;
    v_base_earned  numeric;
    v_delta        numeric;
    v_shape        jsonb;
    v_paid_depth   int;
    v_contrib      int;
    v_b_added      numeric; v_b_removed numeric; v_b_gained numeric;
    v_b_lost       numeric; v_b_shift  numeric; v_b_same   numeric;
    v_has_ps       boolean;
    v_agg_now      numeric; v_agg_base numeric;
    v_basis_now    numeric; v_basis_base numeric;
    v_has_agg      boolean;
    v_set_now      text[];  v_set_base text[];
    v_components   jsonb;
    v_check        numeric;
begin
    select * into v_run from lab.plan_runs where id = p_run_id;

    v_baseline := v_run.baseline_run_id;
    if v_baseline is null then
        select max(r.id) into v_baseline
        from lab.plan_runs r
        where r.period = v_run.period
          and r.plan_code = 'unilevel_v13'
          and r.status = 'complete'
          and r.scenario_id = (select id from lab.scenarios where scenario_code = 'IDENTITY');
    end if;

    for w in select member_ref from lab.watchlist where active order by member_ref
    loop
        select d.member_id into v_member
        from lab.derived_members d
        where d.run_id = p_run_id and d.member_code = w.member_ref;
        if v_member is null then
            continue;
        end if;

        select * into v_res
        from lab.plan_run_results pr
        where pr.run_id = p_run_id and pr.member_id = v_member;

        case v_run.plan_code
            when 'unilevel_v13' then
                v_shape := jsonb_build_object('tv', v_res.plan_metrics -> 'tv');
                v_paid_depth := (v_res.plan_metrics ->> 'paid_depth')::int;
            when 'binary' then
                v_shape := jsonb_build_object('left_cv',  v_res.plan_metrics -> 'left_cv',
                                              'right_cv', v_res.plan_metrics -> 'right_cv');
                v_paid_depth := null;
            when 'matrix_3x7' then
                v_shape := jsonb_build_object('leg_cv_0', v_res.plan_metrics -> 'leg_cv_0',
                                              'leg_cv_1', v_res.plan_metrics -> 'leg_cv_1',
                                              'leg_cv_2', v_res.plan_metrics -> 'leg_cv_2');
                v_paid_depth := 7;
            when 'stairstep_breakaway' then
                v_shape := jsonb_build_object('gv',      v_res.plan_metrics -> 'gv',
                                              'bracket', v_res.plan_metrics -> 'bracket');
                v_paid_depth := null;
            when 'orvanna_builder' then
                v_shape := jsonb_build_object('group_cv',        v_res.plan_metrics -> 'group_cv',
                                              'second_leg_cv',   v_res.plan_metrics -> 'second_leg_cv',
                                              'active_leg_count', v_res.plan_metrics -> 'active_leg_count');
                v_paid_depth := (v_res.plan_metrics ->> 'paid_depth')::int;
        end case;

        if v_run.plan_code in ('unilevel_v13', 'matrix_3x7', 'orvanna_builder') then
            select count(distinct l.source_member_id) into v_contrib
            from lab.plan_run_lines l
            where l.run_id = p_run_id and l.earner_id = v_member
              and l.source_member_id is not null;
        else
            v_contrib := coalesce(array_length(lab.fn_basis_member_codes(p_run_id, v_member), 1), 0);
        end if;

        if v_baseline is null then
            insert into lab.watch_snapshots
                (run_id, member_ref, earnings, rank_label, paid_depth, sv,
                 shape_volume, contributing_downline_count, baseline_run_id,
                 delta_earned, delta_components)
            values
                (p_run_id, w.member_ref, v_res.total_earned, v_res.rank_label,
                 v_paid_depth, v_res.sv, v_shape, v_contrib, null, null,
                 jsonb_build_object('no_baseline', true));
            continue;
        end if;

        select d.member_id into v_base_member
        from lab.derived_members d
        where d.run_id = v_baseline and d.member_code = w.member_ref;

        v_base_earned := coalesce((select pr.total_earned
                                   from lab.plan_run_results pr
                                   where pr.run_id = v_baseline
                                     and pr.member_id = v_base_member), 0.00);
        v_delta := v_res.total_earned - v_base_earned;

        with now_lines as (
            select sd.member_code as source_code, l.reason, l.level, l.amount
            from lab.plan_run_lines l
            join lab.derived_members sd
              on sd.run_id = l.run_id and sd.member_id = l.source_member_id
            where l.run_id = p_run_id and l.earner_id = v_member
              and l.source_member_id is not null
        ),
        base_lines as (
            select sd.member_code as source_code, l.reason, l.level, l.amount
            from lab.plan_run_lines l
            join lab.derived_members sd
              on sd.run_id = l.run_id and sd.member_id = l.source_member_id
            where l.run_id = v_baseline and l.earner_id = v_base_member
              and l.source_member_id is not null
        ),
        pairs as (
            select coalesce(n.source_code, b.source_code) as source_code,
                   n.level  as n_level,  n.amount as n_amount,
                   b.level  as b_level,  b.amount as b_amount
            from now_lines n
            full join base_lines b
              on b.source_code = n.source_code
             and b.reason = n.reason        -- the 017 pairing key
        ),
        tagged as (
            select p.*,
                   exists (select 1 from lab.derived_members d
                           where d.run_id = v_baseline and d.member_code = p.source_code) as in_base_tree,
                   exists (select 1 from lab.derived_members d
                           where d.run_id = p_run_id and d.member_code = p.source_code)   as in_now_tree
            from pairs p
        )
        select
            coalesce(sum(n_amount) filter (where n_amount is not null and not in_base_tree), 0),
            coalesce(sum(-b_amount) filter (where b_amount is not null and not in_now_tree), 0),
            coalesce(sum(n_amount) filter (where n_amount is not null and b_amount is null and in_base_tree), 0),
            coalesce(sum(-b_amount) filter (where b_amount is not null and n_amount is null and in_now_tree), 0),
            coalesce(sum(n_amount - b_amount) filter (where n_amount is not null and b_amount is not null
                                                        and n_level is distinct from b_level), 0),
            coalesce(sum(n_amount - b_amount) filter (where n_amount is not null and b_amount is not null
                                                        and n_level is not distinct from b_level), 0),
            (count(*) > 0)
        into v_b_added, v_b_removed, v_b_gained, v_b_lost, v_b_shift, v_b_same, v_has_ps
        from tagged;

        select coalesce(sum(l.amount), 0), coalesce(max(l.basis), 0), (count(*) > 0)
        into v_agg_now, v_basis_now, v_has_agg
        from lab.plan_run_lines l
        where l.run_id = p_run_id and l.earner_id = v_member and l.source_member_id is null;

        select coalesce(sum(l.amount), 0), coalesce(max(l.basis), 0)
        into v_agg_base, v_basis_base
        from lab.plan_run_lines l
        where l.run_id = v_baseline and l.earner_id = v_base_member and l.source_member_id is null;

        v_has_agg := v_has_agg or (v_agg_base <> 0);

        v_components := jsonb_build_object(
            'decomposable', not v_has_agg,
            'from_added_members',     v_b_added,
            'from_removed_members',   v_b_removed,
            'from_reach_gained',      v_b_gained,
            'from_reach_lost',        v_b_lost,
            'from_level_shift',       v_b_shift,
            'from_same_level_change', v_b_same);

        if v_has_agg then
            v_set_now  := coalesce(lab.fn_basis_member_codes(p_run_id, v_member), '{}');
            v_set_base := coalesce(lab.fn_basis_member_codes(v_baseline, v_base_member), '{}');
            v_components := v_components || jsonb_build_object(
                'aggregate_delta', v_agg_now - v_agg_base,
                'basis_before',    v_basis_base,
                'basis_after',     v_basis_now,
                'basis_members_gained', to_jsonb((select coalesce(array_agg(x order by x), '{}')
                                                  from unnest(v_set_now) x
                                                  where x <> all (v_set_base))),
                'basis_members_lost',   to_jsonb((select coalesce(array_agg(x order by x), '{}')
                                                  from unnest(v_set_base) x
                                                  where x <> all (v_set_now))),
                'note', 'basis movement, not attribution');
        end if;

        v_check := v_b_added + v_b_removed + v_b_gained + v_b_lost
                 + v_b_shift + v_b_same
                 + case when v_has_agg then (v_agg_now - v_agg_base) else 0 end;
        if v_check <> v_delta then
            raise exception
                'lab.fn_write_watch_snapshots: run % watched % components sum % but delta is %; every line must fall in exactly one bucket',
                p_run_id, w.member_ref, v_check, v_delta;
        end if;

        insert into lab.watch_snapshots
            (run_id, member_ref, earnings, rank_label, paid_depth, sv,
             shape_volume, contributing_downline_count, baseline_run_id,
             delta_earned, delta_components)
        values
            (p_run_id, w.member_ref, v_res.total_earned, v_res.rank_label,
             v_paid_depth, v_res.sv, v_shape, v_contrib, v_baseline,
             v_delta, v_components);
    end loop;
end;
$$;

revoke execute on function lab.fn_write_watch_snapshots(bigint) from public;
