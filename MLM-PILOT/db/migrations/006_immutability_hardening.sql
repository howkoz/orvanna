-- Migration 006: immutability hardening (finalized-run INSERT lock)
-- Purpose: extend the finalized-run immutability lock from migration 002 so
--          that INSERT is also rejected on app.commission_lines and
--          app.run_member_results whenever NEW.run_id references an
--          app.commission_runs row whose status is 'final'. Migration 002
--          rejects UPDATE and DELETE by reading the run status through
--          OLD.run_id; that alone lets a finalized statement silently GROW,
--          either by inserting brand-new rows into a final run or by
--          re-pointing a row from a non-final run at a final run (verifier
--          finding M2, Phase 1-2 verdict, 2026-08-13). The triggers below
--          close both paths by checking NEW.run_id on INSERT and on UPDATE
--          of run_id. This delivers the corrected SCHEMA-SPEC immutability
--          paragraph (2026-08-13): a finalized statement can neither change,
--          shrink, nor silently grow. Migrations 001 through 005 are
--          gate-approved history and stay untouched; hardening lands here.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)
--
-- Clarification for migration 003 (recorded here because 003 is gate-approved
-- history and is not edited): the 003 header note reading "see engineer
-- report" is a dangling pointer; no separate engineer report file exists
-- anywhere in this repository. The Row-Level Security (RLS) deviation that
-- note refers to (the definer role app_demo_reader needs one per-table RLS
-- SELECT policy because a plain GRANT is insufficient once RLS is enabled and
-- Supabase forbids BYPASSRLS roles) is documented fully inline in 003 itself.
-- That inline documentation is the complete and only record; there is no
-- missing document.

-- ---------------------------------------------------------------------------
-- Reject writes INTO a finalized run.
-- Companion to app.reject_write_when_run_final (migration 002), which guards
-- the rows a final run already owns via OLD.run_id. This function guards the
-- other direction: no new row may arrive in a final run, whether by INSERT or
-- by an UPDATE that re-points run_id. The comp engine is unaffected: it
-- writes lines while its run status is 'running' and flips the run to
-- 'final' only afterward.
-- ---------------------------------------------------------------------------
create or replace function app.reject_write_into_final_run()
returns trigger
language plpgsql
as $$
declare
    v_status text;
begin
    select r.status into v_status
    from app.commission_runs r
    where r.id = new.run_id;

    if v_status in ('final', 'superseded') then
        raise exception '% on %.% is not allowed: run % is % (statements are immutable history)',
            tg_op, tg_table_schema, tg_table_name, new.run_id, v_status;
    end if;

    return new;
end;
$$;

create trigger commission_lines_no_write_into_final
    before insert or update of run_id on app.commission_lines
    for each row
    execute function app.reject_write_into_final_run();

create trigger run_member_results_no_write_into_final
    before insert or update of run_id on app.run_member_results
    for each row
    execute function app.reject_write_into_final_run();

-- ---------------------------------------------------------------------------
-- Architect ruling 2026-08-13 (engine builder's flag): SUPERSEDED runs are
-- statement history too. A rerun replaces a final run for PAYMENT purposes,
-- but the superseded run's rows remain the auditable record of what was once
-- published and must stay frozen. Both guard functions therefore treat
-- 'final' and 'superseded' identically. The redefinition below upgrades the
-- migration 002 function in place (002 itself is gate-approved history and is
-- not edited; forward migrations may redefine functions).
-- ---------------------------------------------------------------------------
create or replace function app.reject_write_when_run_final()
returns trigger
language plpgsql
as $$
declare
    v_status text;
begin
    select r.status into v_status
    from app.commission_runs r
    where r.id = old.run_id;

    if v_status in ('final', 'superseded') then
        raise exception '% on %.% is not allowed: run % is % (statements are immutable history)',
            tg_op, tg_table_schema, tg_table_name, old.run_id, v_status;
    end if;

    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;
