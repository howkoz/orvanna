-- Lab 015: watched accounts, per-run snapshots, and deltas that explain
--          themselves (phase L3, part two)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 section 10 and section 8 rulings (question 8:
--       watchlist soft cap 10, warning only; question 11: the named
--       baseline, default = same month, identity scenario, unilevel v1.3,
--       overridable per run). Requires db\lab\014.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV), Team Volume
-- (TV), Group Volume (GV), JavaScript Object Notation (JSON).
--
-- DELTA SEMANTICS, stated precisely (spec 10.2 implemented):
--   Lines are joined across the run and its baseline BY MEMBER CODE (codes
--   are stable across runs and base conventions; ids are run-scoped).
--   PER-SOURCE lines (source_member_id set: unilevel, matrix, stairstep
--   overrides) decompose EXACTLY into the six named buckets:
--     from_added_members     amounts on sources absent from the BASELINE
--                            derived member set (scenario-added)
--     from_removed_members   minus baseline amounts on sources absent from
--                            THIS run's derived member set
--     from_reach_gained      amounts on common-tree sources with no
--                            baseline line
--     from_reach_lost        minus baseline amounts on common-tree sources
--                            with no line now
--     from_level_shift       both lines, different levels: now minus before
--     from_same_level_change both lines, same level: now minus before
--   AGGREGATE lines (source null: binary pay leg, stairstep differential)
--   do not decompose per source; the snapshot says so instead of
--   pretending: decomposable false, aggregate_delta, basis_before and
--   basis_after, and the basis member sets' movements (pay-leg members for
--   binary; non-breakaway group members for stairstep), labeled movement,
--   not attribution.
--   THE INVARIANT, enforced in code: bucket sum plus aggregate_delta equals
--   delta_earned to the cent, always (every line of both runs falls in
--   exactly one bucket). A violation aborts the run loudly.
--   Stairstep is the mixed case by construction (per-source overrides plus
--   an aggregate differential): its snapshot carries BOTH parts and the
--   invariant spans them; decomposable is false because the differential
--   part cannot be attributed. Flagged for the architect as the honest
--   reading of 10.2's plan classification.
--
-- BASELINE RESOLUTION: the run's named baseline_run_id wins; otherwise the
-- latest COMPLETE run of (same period, IDENTITY scenario, unilevel_v13).
-- Cross-plan deltas against the default are permitted by the ruling but
-- rarely meaningful; the proof fixtures and sweep name plan-matched
-- baselines explicitly, which question 11 exists to allow. No baseline
-- resolvable: snapshot written with null delta and {"no_baseline": true}.

-- ---------------------------------------------------------------------------
-- The snapshot table (spec 10.1). Run-scoped, so it freezes with its run.
-- ---------------------------------------------------------------------------
create table lab.watch_snapshots (
    id                           bigint generated always as identity primary key,
    run_id                       bigint not null references lab.plan_runs (id),
    member_ref                   text not null,
    earnings                     numeric(12,2) not null,
    rank_label                   text not null,
    paid_depth                   int,
    sv                           numeric(12,2) not null,
    shape_volume                 jsonb not null,
    contributing_downline_count  int,
    baseline_run_id              bigint references lab.plan_runs (id),
    delta_earned                 numeric(12,2),
    delta_components             jsonb not null,
    constraint watch_snapshots_run_member_key unique (run_id, member_ref)
);

alter table lab.watch_snapshots enable row level security;

create trigger watch_snapshots_freeze
    before insert or update or delete on lab.watch_snapshots
    for each row execute function lab.enforce_run_child_freeze();

do $$
declare
    r text;
begin
    foreach r in array array['anon', 'authenticated', 'app_demo_reader'] loop
        if exists (select 1 from pg_roles where rolname = r) then
            execute format('revoke all on lab.watch_snapshots from %I', r);
        end if;
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- Watchlist soft cap (ruled default, question 8): warn past 10 active
-- watched accounts, never refuse.
-- ---------------------------------------------------------------------------
create or replace function lab.warn_watchlist_cap()
returns trigger
language plpgsql
as $$
declare
    n int;
begin
    select count(*) into n from lab.watchlist where active;
    if n > 10 then
        raise notice
            'lab.watchlist: % active watched accounts exceeds the soft cap of 10; the trajectory views stop being readable (COMP-LAB-SPEC section 8 question 8)',
            n;
    end if;
    return null;
end;
$$;

create trigger watchlist_soft_cap
    after insert or update on lab.watchlist
    for each row execute function lab.warn_watchlist_cap();

-- ---------------------------------------------------------------------------
-- lab.fn_basis_member_codes(p_run_id, p_member_id)
-- The member set behind an aggregate basis, as a SORTED code array
-- (deterministic): binary = the pay leg's placed members; stairstep = the
-- member's non-breakaway group (descendants reachable without crossing a
-- breakaway); null for per-source plans.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_basis_member_codes(p_run_id bigint, p_member_id bigint)
returns text[]
language plpgsql
stable
as $$
declare
    v_plan    text;
    v_pay_slot int;
    v_codes   text[];
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
    end if;

    return null;
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_write_watch_snapshots(p_run_id)
-- One snapshot per active watched account present in the run's derived
-- tree. Runs while the run is 'running' (the freeze admits no later write).
-- ---------------------------------------------------------------------------
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

    -- Baseline: named, else the ruled default.
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
            continue;   -- not present in this run's derived tree (spec 10.1)
        end if;

        select * into v_res
        from lab.plan_run_results pr
        where pr.run_id = p_run_id and pr.member_id = v_member;

        -- Plan-shaped snapshot fields (spec 10.1 table).
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
                v_paid_depth := 7;   -- flat by ruling
            when 'stairstep_breakaway' then
                v_shape := jsonb_build_object('gv',      v_res.plan_metrics -> 'gv',
                                              'bracket', v_res.plan_metrics -> 'bracket');
                v_paid_depth := null;
        end case;

        -- Contributing downline count (spec 10.1): per-source plans count
        -- distinct sources; aggregate plans count the basis members.
        if v_run.plan_code in ('unilevel_v13', 'matrix_3x7') then
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

        -- The six buckets, joined by source code (per-source lines only).
        with now_lines as (
            select sd.member_code as source_code, l.level, l.amount
            from lab.plan_run_lines l
            join lab.derived_members sd
              on sd.run_id = l.run_id and sd.member_id = l.source_member_id
            where l.run_id = p_run_id and l.earner_id = v_member
              and l.source_member_id is not null
        ),
        base_lines as (
            select sd.member_code as source_code, l.level, l.amount
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
            full join base_lines b on b.source_code = n.source_code
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

        -- The aggregate part (binary pay leg, stairstep differential).
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

        -- THE INVARIANT: buckets plus aggregate delta must equal the delta
        -- to the cent, always.
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

-- ---------------------------------------------------------------------------
-- lab.fn_execute_plan v4: unchanged except the snapshot write lands after
-- the plan computation and before completion (while still 'running', so the
-- freeze admits it).
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
        raise exception
            'lab.fn_execute_plan: run % has no derived member set', p_run_id;
    end if;
    if not exists (select 1 from lab.member_volumes v where v.run_id = p_run_id) then
        raise exception
            'lab.fn_execute_plan: run % has no volume snapshot', p_run_id;
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

-- ---------------------------------------------------------------------------
-- lab.fn_run_plan v2: one more DEFAULTED parameter, the named baseline run
-- (spec section 8 question 11 permits a run to name its baseline; the
-- fixture and sweep runs use it for plan-matched baselines). The five-
-- parameter signature of record still works; the old function is dropped so
-- the call is never ambiguous. Flagged for the architect's ratification the
-- way the fifth parameter was.
-- ---------------------------------------------------------------------------
drop function if exists lab.fn_run_plan(date, text, jsonb, text, text);

create function lab.fn_run_plan(p_period date,
                                p_plan_code text,
                                p_params jsonb,
                                p_placement_strategy text,
                                p_scenario_code text default 'IDENTITY',
                                p_baseline_run_id bigint default null)
returns bigint
language plpgsql
as $$
declare
    v_period       date;
    v_scenario_id  bigint;
    v_order_source text;
    v_run_id       bigint;
begin
    v_period := (date_trunc('month', p_period))::date;

    select s.id into v_scenario_id
    from lab.scenarios s
    where s.scenario_code = p_scenario_code
      and s.status = 'locked';

    if not found then
        raise exception
            'lab.fn_run_plan: no LOCKED scenario with code ''%'' (a run may reference only a locked scenario)',
            p_scenario_code;
    end if;

    select case
               when count(*) = 0 then 'no_orders'
               when count(*) filter (where o.demo_order_id is not null) = 0 then 'seeded_orders'
               when count(*) filter (where o.demo_order_id is null) = 0 then 'bridged_orders'
               else 'seeded_and_bridged_orders'
           end
    into v_order_source
    from app.orders o
    where o.volume_month = v_period
      and o.status = 'completed';

    insert into lab.plan_runs
        (scenario_id, plan_code, plan_params, placement_strategy, period,
         status, order_source, baseline_run_id, notes)
    values
        (v_scenario_id, p_plan_code, p_params, p_placement_strategy, v_period,
         'running', v_order_source, p_baseline_run_id,
         'lab run: plan ' || p_plan_code
         || coalesce(', strategy ' || p_placement_strategy, '')
         || ', scenario ' || p_scenario_code
         || ', period ' || to_char(v_period, 'YYYY-MM'))
    returning id into v_run_id;

    perform lab.fn_derive_members(v_run_id);
    perform lab.fn_snapshot_volumes(v_run_id);
    perform lab.fn_execute_plan(v_run_id);

    return v_run_id;
end;
$$;

revoke execute on function lab.fn_basis_member_codes(bigint, bigint)   from public;
revoke execute on function lab.fn_write_watch_snapshots(bigint)        from public;
revoke execute on function lab.fn_execute_plan(bigint)                 from public;
revoke execute on function lab.fn_run_plan(date, text, jsonb, text, text, bigint) from public;

-- ---------------------------------------------------------------------------
-- lab.fn_load_mini_base(p_run_id): proof-fixture support. Loads the spec
-- section 6 five-member mini tree as the run's BASE member set (ids 1..5,
-- LAB- codes, volumes as sv_override), so scenario proofs replay the REAL
-- mutation machinery over the exact tree the spec hand-computed. Callable
-- only while the run is 'running' (the freeze enforces it).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_load_mini_base(p_run_id bigint)
returns void
language plpgsql
as $$
begin
    insert into lab.derived_members
        (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id, sv_override)
    values
        (p_run_id, 1, 'LAB-M1', null, date '2026-01-01', null, 200.00),
        (p_run_id, 2, 'LAB-M2', 1,    date '2026-01-02', null, 150.00),
        (p_run_id, 3, 'LAB-M3', 1,    date '2026-01-03', null, 100.00),
        (p_run_id, 4, 'LAB-M4', 1,    date '2026-01-04', null, 100.00),
        (p_run_id, 5, 'LAB-M5', 2,    date '2026-01-05', null,  50.00);
end;
$$;

revoke execute on function lab.fn_load_mini_base(bigint) from public;

-- ---------------------------------------------------------------------------
-- lab.fn_run_mini_fixture(...): proof-fixture support. One mini-base run,
-- end to end, through the SAME machinery census runs use: register the run,
-- load the mini base, REPLAY the scenario's mutations, snapshot volumes,
-- execute. Returns the run id. order_source 'hand_fixture' by construction.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_run_mini_fixture(p_scenario_code text,
                                                   p_plan_code text,
                                                   p_params jsonb,
                                                   p_placement_strategy text,
                                                   p_period date,
                                                   p_baseline_run_id bigint,
                                                   p_tag text)
returns bigint
language plpgsql
as $$
declare
    v_scenario_id bigint;
    v_run_id      bigint;
begin
    select s.id into v_scenario_id
    from lab.scenarios s
    where s.scenario_code = p_scenario_code and s.status = 'locked';
    if not found then
        raise exception
            'lab.fn_run_mini_fixture: no LOCKED scenario with code ''%''', p_scenario_code;
    end if;

    insert into lab.plan_runs
        (scenario_id, plan_code, plan_params, placement_strategy, period,
         status, order_source, baseline_run_id, notes)
    values
        (v_scenario_id, p_plan_code, p_params, p_placement_strategy,
         (date_trunc('month', p_period))::date,
         'running', 'hand_fixture', p_baseline_run_id, p_tag)
    returning id into v_run_id;

    perform lab.fn_load_mini_base(v_run_id);
    perform lab.fn_replay_mutations(v_run_id);
    perform lab.fn_snapshot_volumes(v_run_id);
    perform lab.fn_execute_plan(v_run_id);

    return v_run_id;
end;
$$;

revoke execute on function lab.fn_run_mini_fixture(text, text, jsonb, text, date, bigint, text) from public;
