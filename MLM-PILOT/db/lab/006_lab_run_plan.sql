-- Lab 006: lab.fn_run_plan, the one entry point of the plan engine interface
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 1 (four plans, one contract).
--       Requires db\lab\001 through 005.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV).
--
-- The declared entry point (spec 1.1):
--   lab.fn_run_plan(p_period date, p_plan_code text, p_params jsonb,
--                   p_placement_strategy text) returns bigint
-- plus one DEFAULTED extension parameter, p_scenario_code (default
-- 'IDENTITY'), because the v1.1 amendment made every plan read a scenario's
-- derived tree while leaving the declared four-parameter call shape in the
-- spec text. A four-argument call works exactly as declared and runs the
-- identity scenario; naming a scenario is additive. Recorded for the
-- architect as an interface note, not a deviation of behavior.
--
-- fn_execute_plan is split out so the L1 proof fixtures (hand-built derived
-- sets for the spec section 6 trees) exercise the SAME computation path as
-- census runs, bypassing only the census-derivation and volume-snapshot
-- steps that the identity and parity proofs cover on the real census.

-- ---------------------------------------------------------------------------
-- lab.fn_execute_plan(p_run_id)
-- Assumes the run row exists in status 'running' and that derived_members
-- and member_volumes are already materialized for it. Builds the derived
-- inputs that follow deterministically (level map; placement when the plan
-- needs one), dispatches to the plan implementation, writes company totals
-- (sums of already-rounded values, never re-rounded), and completes the run.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_execute_plan(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_run lab.plan_runs%rowtype;
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

    -- The run-scoped level map over the derived tree, always: every plan
    -- (and the section 5 metrics) may read tree distance.
    perform lab.fn_build_level_map(p_run_id);

    -- Placement only for placement-tree plans; the CHECK constraint on
    -- plan_runs already guarantees strategy presence matches the plan.
    if v_run.placement_strategy is not null then
        perform lab.fn_derive_placement(p_run_id);
    end if;

    case v_run.plan_code
        when 'unilevel_v13' then perform lab.fn_plan_unilevel(p_run_id);
        when 'binary'       then perform lab.fn_plan_binary(p_run_id);
        else raise exception
            'lab.fn_execute_plan: plan ''%'' arrives in phase L2 (COMP-LAB-SPEC section 7)',
            v_run.plan_code;
    end case;

    -- Company totals on the run row (spec 1.2): sums of already-rounded
    -- values; members_paid counts members with total_earned > 0.
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
-- lab.fn_run_plan(p_period, p_plan_code, p_params, p_placement_strategy
--                 [, p_scenario_code])
-- The full interface call for a CENSUS-backed run: registers the run, takes
-- the explicit snapshots (derived members, volumes), and executes.
--
-- order_source is stamped from what the period's app.orders actually
-- contain (engineer charter amendment 2026-08-16: every determinism claim
-- states its order source), so the run row itself testifies whether it was
-- proven against seeded rows, bridged rows, or both.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_run_plan(p_period date,
                                           p_plan_code text,
                                           p_params jsonb,
                                           p_placement_strategy text,
                                           p_scenario_code text default 'IDENTITY')
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

    -- What kind of order rows feed this month: seeded history, bridged live
    -- sales (demo_order_id set, migration 019), both, or none.
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
         status, order_source, notes)
    values
        (v_scenario_id, p_plan_code, p_params, p_placement_strategy, v_period,
         'running', v_order_source,
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

revoke execute on function lab.fn_execute_plan(bigint) from public;
revoke execute on function lab.fn_run_plan(date, text, jsonb, text, text) from public;
