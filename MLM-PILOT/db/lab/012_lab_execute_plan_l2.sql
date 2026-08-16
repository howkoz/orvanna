-- Lab 012: the dispatcher learns matrix and stairstep (phase L2)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 sections 1, 4.3, 4.4, 7 (L2). Requires
--       db\lab\001..011. Redefines lab.fn_execute_plan only; files 006 and
--       007 are applied history and stay frozen.
--
-- Changes against the 007 body, each named:
--   1. Placement width comes from the plan: binary places at width 2,
--      matrix at its plan_params width (draft 3), through
--      lab.fn_derive_placement_width (file 009). The plan_runs CHECK
--      already guarantees a strategy is present exactly for the two
--      placement plans.
--   2. Dispatch covers all four launch plans. Nothing "arrives in a later
--      phase" any more; an unknown plan_code cannot reach here (CHECK).
--   3. Everything else (guards, snapshot ANALYZE discipline of file 007,
--      totals, completion) is byte-identical to 007.

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
