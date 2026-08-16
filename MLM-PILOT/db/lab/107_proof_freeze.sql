-- Lab 107: L2 freeze proof, completed runs are immutable history
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 section 7 L2 deliverable (QA MEDIUM-1);
--       the refused-update probe the coordinator named. Requires
--       db\lab\008 applied.
--
-- Method: build a tiny probe run on the PROOF-MINI scenario (one member,
-- unilevel), complete it, then attempt every forbidden write and the one
-- permitted transition. Every FAIL raise aborts the script; a clean finish
-- with the PASS notices is the proof. Acronym key: Quality Assurance (QA).

do $$
declare
    v_scenario_id bigint;
    v_run_id      bigint;
    v_did         boolean;
begin
    select id into v_scenario_id from lab.scenarios where scenario_code = 'PROOF-MINI';
    if v_scenario_id is null then
        raise exception 'freeze probe needs the PROOF-MINI scenario (run proof 103 first)';
    end if;

    -- Build and complete the probe run.
    insert into lab.plan_runs (scenario_id, plan_code, plan_params, placement_strategy,
                               period, status, order_source, notes)
    values (v_scenario_id, 'unilevel_v13', '{"rates": [0.10]}'::jsonb, null,
            date '2026-07-01', 'running', 'hand_fixture', 'L2-PROOF-FREEZE-PROBE')
    returning id into v_run_id;

    insert into lab.derived_members (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
    values (v_run_id, 10000001, 'LAB-M1', null, date '2026-01-01', null);
    insert into lab.member_volumes (run_id, member_id, sv)
    values (v_run_id, 10000001, 100.00);

    perform lab.fn_execute_plan(v_run_id);

    -- F1: tamper the completed run row (totals): must be REFUSED.
    v_did := false;
    begin
        update lab.plan_runs set total_payout = 999999.00 where id = v_run_id;
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS F1: completed run row update refused';
    end;
    if v_did then
        raise exception 'FAIL F1: a completed run row accepted an update';
    end if;

    -- F2: tamper a completed run's results: must be REFUSED.
    v_did := false;
    begin
        update lab.plan_run_results set total_earned = 999999.00 where run_id = v_run_id;
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS F2: completed run child-row update refused';
    end;
    if v_did then
        raise exception 'FAIL F2: a completed run child row accepted an update';
    end if;

    -- F3: insert a new line into the completed run: must be REFUSED.
    v_did := false;
    begin
        insert into lab.plan_run_lines (run_id, earner_id, source_member_id, level,
                                        basis, rate, amount, reason)
        values (v_run_id, 10000001, null, null, 1.00, 0.1, 0.10, 'unilevel_level_pay');
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS F3: line insert into completed run refused';
    end;
    if v_did then
        raise exception 'FAIL F3: a completed run accepted a new line';
    end if;

    -- F4: the ONE permitted transition, complete to archived, everything
    -- else unchanged: must SUCCEED.
    update lab.plan_runs set status = 'archived' where id = v_run_id;
    raise notice 'PASS F4: complete to archived transition allowed';

    -- F5: tamper the archived row: must be REFUSED.
    v_did := false;
    begin
        update lab.plan_runs set notes = 'tampered' where id = v_run_id;
        v_did := true;
    exception when raise_exception then
        raise notice 'PASS F5: archived run row update refused';
    end;
    if v_did then
        raise exception 'FAIL F5: an archived run row accepted an update';
    end if;
end
$$;
