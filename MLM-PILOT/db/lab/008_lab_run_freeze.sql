-- Lab 008: the run freeze, completed runs become history (QA finding MEDIUM-1)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 section 7, L2 deliverables: "extend the
--       registry discipline trigger so a run row freezes once its status is
--       'complete', mirroring the scenario freeze, closing the service-role
--       UPDATE gap QA identified" (docs\qa\LAB-L1-QA-2026-08-16.md,
--       MEDIUM-1). Requires db\lab\001 through 007.
--
-- Acronym key: Quality Assurance (QA), Structured Query Language (SQL).
--
-- WHAT FREEZES AND WHEN, stated precisely:
--   status 'running'  : the run is in flight; the engine may update it
--                       (started_at, notes, totals, and the completing
--                       status flip all happen here).
--   status 'complete' : the row is HISTORY. Exactly one further change is
--                       permitted: status to 'archived' with every other
--                       column byte-identical (archiving hides a run from
--                       the default report, it never edits one).
--   status 'archived' : fully frozen. Un-archiving would be editing
--                       history's visibility record; a new run is the way
--                       to bring numbers back.
--
-- AND THE CHILD ROWS TOO. QA named the run ROW, but a frozen registry row
-- over editable lines would be a headline over a rewritable story. The same
-- freeze therefore covers every run-scoped table (lines, results, derived
-- members, volumes, level map, placement map): once the owning run leaves
-- 'running', INSERT, UPDATE, and DELETE are all refused, including the
-- re-pointing of a row from one run to another (both the old and the new
-- owning run are checked, the migration 006 lesson). This mirrors the real
-- engine's discipline where migrations 002 and 006 freeze statement rows in
-- both directions.

-- ---------------------------------------------------------------------------
-- Run-row freeze (UPDATE guard; INSERT and DELETE stay with the existing
-- registry discipline trigger from file 001).
-- ---------------------------------------------------------------------------
create or replace function lab.enforce_run_freeze()
returns trigger
language plpgsql
as $$
begin
    if old.status = 'running' then
        return new;  -- computation in flight; the engine writes freely
    end if;

    if old.status = 'complete'
       and new.status = 'archived'
       and (to_jsonb(new) - 'status') = (to_jsonb(old) - 'status') then
        return new;  -- the one permitted transition: hide, never edit
    end if;

    raise exception
        'lab.plan_runs: run % is % and frozen; a rerun is a NEW run, never an edit '
        '(COMP-LAB-SPEC sections 1.1 and 4; QA MEDIUM-1)',
        old.id, old.status;
end;
$$;

create trigger plan_runs_freeze_completed
    before update on lab.plan_runs
    for each row execute function lab.enforce_run_freeze();

-- ---------------------------------------------------------------------------
-- Child-row freeze: no write into or out of a non-running run.
-- ---------------------------------------------------------------------------
create or replace function lab.enforce_run_child_freeze()
returns trigger
language plpgsql
as $$
declare
    v_status text;
begin
    -- The row's owning run (OLD side for UPDATE and DELETE).
    if tg_op in ('UPDATE', 'DELETE') then
        select r.status into v_status from lab.plan_runs r where r.id = old.run_id;
        if v_status is distinct from 'running' then
            raise exception
                '% on %.% is not allowed: run % is % (lab runs are immutable history once complete)',
                tg_op, tg_table_schema, tg_table_name, old.run_id, coalesce(v_status, 'missing');
        end if;
    end if;

    -- The destination run (NEW side for INSERT, and for UPDATE re-pointing).
    if tg_op in ('INSERT', 'UPDATE') then
        select r.status into v_status from lab.plan_runs r where r.id = new.run_id;
        if v_status is distinct from 'running' then
            raise exception
                '% on %.% is not allowed: run % is % (lab runs are immutable history once complete)',
                tg_op, tg_table_schema, tg_table_name, new.run_id, coalesce(v_status, 'missing');
        end if;
    end if;

    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;

create trigger plan_run_lines_freeze
    before insert or update or delete on lab.plan_run_lines
    for each row execute function lab.enforce_run_child_freeze();

create trigger plan_run_results_freeze
    before insert or update or delete on lab.plan_run_results
    for each row execute function lab.enforce_run_child_freeze();

create trigger derived_members_freeze
    before insert or update or delete on lab.derived_members
    for each row execute function lab.enforce_run_child_freeze();

create trigger member_volumes_freeze
    before insert or update or delete on lab.member_volumes
    for each row execute function lab.enforce_run_child_freeze();

create trigger run_level_map_freeze
    before insert or update or delete on lab.run_level_map
    for each row execute function lab.enforce_run_child_freeze();

create trigger placement_map_freeze
    before insert or update or delete on lab.placement_map
    for each row execute function lab.enforce_run_child_freeze();

-- ---------------------------------------------------------------------------
-- VERIFICATION: the refused-update probe lives in db\lab\107_proof_freeze.sql
-- (tamper a completed run's totals: refused; tamper its lines: refused;
-- archive it unchanged: allowed; tamper the archived row: refused).
-- ---------------------------------------------------------------------------
