-- Lab 007: analyze the run-scoped snapshots before computing over them
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Requires: db\lab\001 through 006. Redefines lab.fn_execute_plan only.
--
-- WHY THIS FILE EXISTS (found during the L1 proof run, recorded honestly):
-- the FIRST census run on the live project completed, and the SECOND timed
-- out inside the unilevel staging query. Cause: the lab's run-scoped tables
-- (derived_members, member_volumes, run_level_map, placement_map) are brand
-- new and bulk-loaded per run, so the planner was still carrying "empty
-- table" statistics from before the first run and chose a catastrophic plan
-- once real rows existed. The fix is the standard one for materialize-then-
-- read tables: ANALYZE each snapshot table right after it is filled, inside
-- the same transaction (ANALYZE is transaction-safe, unlike VACUUM), so
-- every downstream query plans against true row counts. Determinism is
-- unaffected: ANALYZE changes plans, never results, and the output contract
-- (stable ORDER BY on every insert) fixes row order independently of plans.
--
-- House rule kept: db\lab\006 was already applied to the live project, so it
-- stays frozen and this follow-up is a NEW numbered file, exactly the
-- discipline of the migrations README.

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

    -- Fresh statistics on the inputs materialized before this call.
    execute 'analyze lab.derived_members';
    execute 'analyze lab.member_volumes';

    perform lab.fn_build_level_map(p_run_id);
    execute 'analyze lab.run_level_map';

    if v_run.placement_strategy is not null then
        perform lab.fn_derive_placement(p_run_id);
        execute 'analyze lab.placement_map';
    end if;

    case v_run.plan_code
        when 'unilevel_v13' then perform lab.fn_plan_unilevel(p_run_id);
        when 'binary'       then perform lab.fn_plan_binary(p_run_id);
        else raise exception
            'lab.fn_execute_plan: plan ''%'' arrives in phase L2 (COMP-LAB-SPEC section 7)',
            v_run.plan_code;
    end case;

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
