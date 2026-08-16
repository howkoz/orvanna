-- Lab 013: run-freeze fix, generated columns excluded from the archive test
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Requires: db\lab\008. Redefines lab.enforce_run_freeze only.
--
-- WHY THIS FILE EXISTS (found by the freeze probe itself, recorded
-- honestly): file 008 tested the complete-to-archived transition with
-- to_jsonb(NEW) minus 'status' equals to_jsonb(OLD) minus 'status'. In a
-- BEFORE UPDATE trigger PostgreSQL has NOT YET computed the row's STORED
-- GENERATED columns for NEW (they are computed after BEFORE triggers run),
-- so NEW's disclaimer and placement_caption serialize as null, the equality
-- always fails, and the one PERMITTED transition was refused along with the
-- forbidden ones. The freeze was therefore over-strict, never leaky: every
-- tamper probe still failed as it should, which is why this surfaced as a
-- refused LEGAL archive rather than as any accepted illegal write.
--
-- Fix: exclude the two generated columns from the comparison. An updater
-- cannot write them anyway (PostgreSQL refuses direct assignment to stored
-- generated columns), so excluding them loses no protection.
--
-- House rule kept: 008 was already applied to the live project, so it stays
-- frozen and the correction is this new numbered file.

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
       and (to_jsonb(new) - 'status' - 'disclaimer' - 'placement_caption')
         = (to_jsonb(old) - 'status' - 'disclaimer' - 'placement_caption') then
        return new;  -- the one permitted transition: hide, never edit
    end if;

    raise exception
        'lab.plan_runs: run % is % and frozen; a rerun is a NEW run, never an edit '
        '(COMP-LAB-SPEC sections 1.1 and 4; QA MEDIUM-1)',
        old.id, old.status;
end;
$$;
