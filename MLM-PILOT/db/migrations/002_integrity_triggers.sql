-- Migration 002: integrity triggers
-- Purpose: (1) sponsor cycle-check trigger on app.members: walking up from any
--          member's sponsor must reach a root (null sponsor), never loop back.
--          (2) immutability trigger: reject UPDATE and DELETE on
--          app.commission_lines and app.run_member_results when their run's
--          status is 'final'.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)

-- ---------------------------------------------------------------------------
-- Sponsor cycle check.
-- Fires before INSERT, and before UPDATE of sponsor_id. Walks the sponsor
-- chain upward; if it re-encounters the member being written, the write is a
-- cycle and is rejected. A step cap guards against walking a pre-existing
-- corrupt chain forever.
-- ---------------------------------------------------------------------------
create or replace function app.check_sponsor_cycle()
returns trigger
language plpgsql
as $$
declare
    cur       bigint;
    steps     integer := 0;
    max_steps constant integer := 1000000;
begin
    if new.sponsor_id is null then
        return new;  -- a root member; nothing to walk
    end if;

    if new.sponsor_id = new.id then
        raise exception 'sponsor cycle: member % cannot sponsor themselves', new.id;
    end if;

    cur := new.sponsor_id;
    while cur is not null loop
        if cur = new.id then
            raise exception 'sponsor cycle detected: member % appears in its own upline', new.id;
        end if;
        steps := steps + 1;
        if steps > max_steps then
            raise exception 'sponsor chain exceeded % steps walking up from member %; possible pre-existing cycle', max_steps, new.id;
        end if;
        select m.sponsor_id into cur from app.members m where m.id = cur;
        if not found then
            exit;  -- sponsor row does not exist; the foreign key raises its own error
        end if;
    end loop;

    return new;
end;
$$;

create trigger members_sponsor_cycle_check
    before insert or update of sponsor_id on app.members
    for each row
    execute function app.check_sponsor_cycle();

-- ---------------------------------------------------------------------------
-- Immutability of finalized runs.
-- Statements are receipts: once a run is 'final', its commission_lines and
-- run_member_results rows can never be updated or deleted. A rerun is a NEW
-- run row; the old run flips to 'superseded' with its lines untouched.
-- The check reads the run status through OLD.run_id, so re-pointing a row at
-- a different run cannot dodge the guard.
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

    if v_status = 'final' then
        raise exception '% on %.% is not allowed: run % is final (statements are immutable)',
            tg_op, tg_table_schema, tg_table_name, old.run_id;
    end if;

    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;

create trigger commission_lines_immutable_when_final
    before update or delete on app.commission_lines
    for each row
    execute function app.reject_write_when_run_final();

create trigger run_member_results_immutable_when_final
    before update or delete on app.run_member_results
    for each row
    execute function app.reject_write_when_run_final();
