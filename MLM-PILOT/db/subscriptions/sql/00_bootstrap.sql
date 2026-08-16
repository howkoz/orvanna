-- =============================================================================
-- S1 proof rig bootstrap: roles the Supabase-authored migrations expect.
-- Runs FIRST, on a fresh disposable PostgreSQL container. Creating the API
-- roles as nologin shells makes every guarded REVOKE block in the real
-- migrations take its real branch, so the rig exercises the same statements
-- production ran.
-- =============================================================================
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'anon') then
        create role anon nologin;
    end if;
    if not exists (select 1 from pg_roles where rolname = 'authenticated') then
        create role authenticated nologin;
    end if;
end
$$;

-- Quiet the bridge's per-tick notices during the 395-tick simulated year;
-- warnings and errors still surface.
alter database mlm set client_min_messages = warning;
