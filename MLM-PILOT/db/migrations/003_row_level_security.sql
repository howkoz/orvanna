-- Migration 003: row-level security (RLS)
-- Purpose: enable RLS on every app.* table with NO policies for anon or
--          authenticated roles, so the published anon key can read NOTHING
--          from tables. Create the dedicated read-only definer role
--          app_demo_reader (owner of the demo views in migration 005) and
--          give it SELECT via grants plus an RLS SELECT policy per table.
--          Writes happen only through the service role, which bypasses RLS
--          by design and never ships to the browser.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)
--
-- NOTE (documented deviation, see engineer report): the schema spec says the
-- definer role "has SELECT on the underlying tables". A plain GRANT is not
-- enough once RLS is enabled, because app_demo_reader does not own the tables
-- and has no BYPASSRLS (Supabase does not allow creating such roles). Each
-- table therefore gets ONE RLS policy: SELECT, TO app_demo_reader, USING
-- (true). No policy exists for anon or authenticated, which preserves the
-- spec's intent exactly: tables are invisible to the public API.

-- ---------------------------------------------------------------------------
-- Enable RLS on every table.
-- ---------------------------------------------------------------------------
alter table app.members            enable row level security;
alter table app.products           enable row level security;
alter table app.subscriptions      enable row level security;
alter table app.orders             enable row level security;
alter table app.order_lines        enable row level security;
alter table app.ranks              enable row level security;
alter table app.commission_runs    enable row level security;
alter table app.run_member_results enable row level security;
alter table app.commission_lines   enable row level security;

-- ---------------------------------------------------------------------------
-- Dedicated read-only definer role for the demo views.
-- NOLOGIN: nobody authenticates as this role; it exists only to own the
-- v_demo_* views so their definer context can read the tables.
-- ---------------------------------------------------------------------------
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'app_demo_reader') then
        create role app_demo_reader nologin;
    end if;
end
$$;

-- Let the migration-running role administer objects owned by app_demo_reader
-- (needed for ALTER VIEW ... OWNER TO in migration 005).
do $$
begin
    execute format('grant app_demo_reader to %I', current_user);
exception
    when others then null;  -- already a member, or superuser: fine either way
end
$$;

grant usage on schema app to app_demo_reader;
grant select on all tables in schema app to app_demo_reader;

-- ---------------------------------------------------------------------------
-- RLS SELECT policies for app_demo_reader ONLY. No anon or authenticated
-- policies exist anywhere in this schema.
-- ---------------------------------------------------------------------------
create policy demo_reader_select_members            on app.members            for select to app_demo_reader using (true);
create policy demo_reader_select_products           on app.products           for select to app_demo_reader using (true);
create policy demo_reader_select_subscriptions      on app.subscriptions      for select to app_demo_reader using (true);
create policy demo_reader_select_orders             on app.orders             for select to app_demo_reader using (true);
create policy demo_reader_select_order_lines        on app.order_lines        for select to app_demo_reader using (true);
create policy demo_reader_select_ranks              on app.ranks              for select to app_demo_reader using (true);
create policy demo_reader_select_commission_runs    on app.commission_runs    for select to app_demo_reader using (true);
create policy demo_reader_select_run_member_results on app.run_member_results for select to app_demo_reader using (true);
create policy demo_reader_select_commission_lines   on app.commission_lines   for select to app_demo_reader using (true);

-- ---------------------------------------------------------------------------
-- Belt and suspenders: make sure the public API roles hold no table
-- privileges in schema app, even if a future grant script gets sloppy.
-- Guarded so the migration also runs on plain Postgres where these roles do
-- not exist.
-- ---------------------------------------------------------------------------
do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on all tables in schema app from anon;
        revoke usage on schema app from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on all tables in schema app from authenticated;
        revoke usage on schema app from authenticated;
    end if;
end
$$;
