-- Lab 100: L1 isolation proof (run read-only checks after applying 001..006)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 2 and section 7 L1 gate ("confirms
--       schema isolation: no grants, no writes to app, 'final' impossible in
--       lab, 'LAB-' check in place").
--
-- Recorded output lives in docs\verification\LAB-L1-PROOF-RUN-2026-08-16.md.
-- Acronym key: Row-Level Security (RLS), Structured Query Language (SQL).

-- ---------------------------------------------------------------------------
-- I1. ZERO NEW OBJECTS IN SCHEMA APP. Baseline inventory was captured on the
-- live project IMMEDIATELY BEFORE applying the lab schema (2026-08-16):
--   relations 88, non-internal triggers 14, functions 17,
--   table grants 185, RLS policies 10.
-- This query must return the SAME numbers after the lab is applied. The only
-- permitted change anywhere near app is the pair of INTERNAL referential-
-- integrity triggers Postgres attaches for the spec-sanctioned foreign key
-- lab.derived_members.app_member_id -> app.members(id); internal triggers
-- are excluded here by tgisinternal, and I2 accounts for them explicitly.
-- ---------------------------------------------------------------------------
select
  (select count(*) from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app')                                   as app_relations,
  (select count(*) from pg_trigger t
     join pg_class c on c.oid = t.tgrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app' and not t.tgisinternal)            as app_triggers,
  (select count(*) from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'app')                                   as app_functions,
  (select count(*) from information_schema.role_table_grants
    where table_schema = 'app')                                as app_grants,
  (select count(*) from pg_policies where schemaname = 'app')  as app_policies;

-- ---------------------------------------------------------------------------
-- I2. The only constraints from lab into app are the two the spec sanctions:
-- derived_members -> app.members (app_member_id) and nothing else, and NO
-- constraint points from app into lab. Expected: exactly one row, and the
-- second query returns zero rows.
-- ---------------------------------------------------------------------------
select con.conname,
       src.relname  as constrained_table,
       tgt.relname  as referenced_table
from pg_constraint con
join pg_class src on src.oid = con.conrelid
join pg_class tgt on tgt.oid = con.confrelid
join pg_namespace nsrc on nsrc.oid = src.relnamespace
join pg_namespace ntgt on ntgt.oid = tgt.relnamespace
where con.contype = 'f'
  and nsrc.nspname = 'lab'
  and ntgt.nspname = 'app';

select con.conname
from pg_constraint con
join pg_class src on src.oid = con.conrelid
join pg_class tgt on tgt.oid = con.confrelid
join pg_namespace nsrc on nsrc.oid = src.relnamespace
join pg_namespace ntgt on ntgt.oid = tgt.relnamespace
where con.contype = 'f'
  and nsrc.nspname = 'app'
  and ntgt.nspname = 'lab';

-- ---------------------------------------------------------------------------
-- I3. ZERO GRANTS on schema lab for any public-facing role (must return zero
-- rows), and no schema usage either (second query, zero rows).
-- ---------------------------------------------------------------------------
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'lab'
  and grantee in ('anon', 'authenticated', 'app_demo_reader');

select r.rolname
from pg_roles r
where r.rolname in ('anon', 'authenticated', 'app_demo_reader')
  and has_schema_privilege(r.rolname, 'lab', 'usage');

-- ---------------------------------------------------------------------------
-- I4. RLS is ON with ZERO policies on every lab table (first query lists any
-- lab table with RLS off, second lists any lab policy; both must return zero
-- rows).
-- ---------------------------------------------------------------------------
select c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'lab'
  and c.relkind = 'r'
  and not c.relrowsecurity;

select policyname, tablename from pg_policies where schemaname = 'lab';

-- ---------------------------------------------------------------------------
-- I5. NO LAB FUNCTION WRITES TO SCHEMA APP: grep every lab function body for
-- INSERT/UPDATE/DELETE/TRUNCATE targeting app.*. Must return zero rows.
-- ---------------------------------------------------------------------------
select p.proname
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'lab'
  and (   p.prosrc ~* 'insert\s+into\s+app\.'
       or p.prosrc ~* 'update\s+app\.'
       or p.prosrc ~* 'delete\s+from\s+app\.'
       or p.prosrc ~* 'truncate\s+app\.');

-- ---------------------------------------------------------------------------
-- I6. 'final' IS IMPOSSIBLE IN LAB, proven by attempting it. The DO block
-- must print 'PASS: status final was refused by the CHECK constraint'.
-- ---------------------------------------------------------------------------
do $$
begin
    insert into lab.plan_runs (scenario_id, plan_code, plan_params, period, status, order_source)
    select s.id, 'unilevel_v13', '{}'::jsonb, date '2026-01-01', 'final', 'isolation_probe'
    from lab.scenarios s where s.scenario_code = 'IDENTITY';
    raise exception 'FAIL: a lab run row accepted status final';
exception
    when check_violation then
        raise notice 'PASS: status final was refused by the CHECK constraint';
end
$$;

-- ---------------------------------------------------------------------------
-- I7. THE 'LAB-' NAME WALL HOLDS, proven by attempting to breach it: a
-- synthetic row (no app.members reference) whose code does not start with
-- 'LAB-' must be refused. Prints PASS on refusal. The probe run row it needs
-- is created in 'running' status and archived afterward (registry rows are
-- never deleted).
-- ---------------------------------------------------------------------------
do $$
declare
    v_run_id bigint;
begin
    insert into lab.plan_runs (scenario_id, plan_code, plan_params, period, status, order_source, notes)
    select s.id, 'unilevel_v13', '{"rates": [0.10]}'::jsonb, date '2026-01-01',
           'running', 'isolation_probe', 'L1-ISOLATION-NAME-WALL-PROBE'
    from lab.scenarios s where s.scenario_code = 'IDENTITY'
    returning id into v_run_id;

    begin
        insert into lab.derived_members (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
        values (v_run_id, 10000001, 'GW-999999', null, date '2026-01-01', null);
        raise exception 'FAIL: a synthetic member without the LAB- prefix was accepted';
    exception
        when check_violation then
            raise notice 'PASS: synthetic member without LAB- prefix was refused';
    end;

    update lab.plan_runs set status = 'archived', notes = notes || ' (probe archived)'
    where id = v_run_id;
end
$$;

-- ---------------------------------------------------------------------------
-- I8. Registry rows cannot be deleted (prints PASS on refusal).
-- ---------------------------------------------------------------------------
do $$
declare
    v_deleted boolean := false;
begin
    begin
        delete from lab.plan_runs where notes = 'L1-ISOLATION-NAME-WALL-PROBE (probe archived)';
        v_deleted := true;
    exception
        when raise_exception then
            raise notice 'PASS: run registry delete was refused by trigger';
    end;
    if v_deleted then
        raise exception 'FAIL: a lab run row was deleted';
    end if;
end
$$;
