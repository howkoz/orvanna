-- Migration 011: view privilege hardening (Phase 6 verifier MEDIUM 1)
-- Purpose: the platform's default grants gave anon and authenticated ALL
--          privileges on the seven demo views, not SELECT only. No view is
--          auto-updatable, so this was latent, not exploitable, but the
--          belt-and-suspenders posture is SELECT and nothing else.
--          This migration revokes everything and grants back SELECT alone.
--          The anon surface remains exactly the seven views, read only.
-- Applied to cloud 2026-08-14 via the management connector; verified live:
-- information_schema.role_table_grants shows SELECT as the only privilege
-- for anon and authenticated on all seven views.
-- Date: 2026-08-14
-- Project: MLM Pilot (Orvanna, personal project)

do $$
declare
    v text;
begin
    foreach v in array array[
        'v_demo_members', 'v_demo_tree', 'v_demo_member_months',
        'v_demo_statements', 'v_demo_company', 'v_demo_customers',
        'v_demo_customer_volume'
    ] loop
        if exists (select 1 from pg_roles where rolname = 'anon') then
            execute format('revoke all on public.%I from anon', v);
            execute format('grant select on public.%I to anon', v);
        end if;
        if exists (select 1 from pg_roles where rolname = 'authenticated') then
            execute format('revoke all on public.%I from authenticated', v);
            execute format('grant select on public.%I to authenticated', v);
        end if;
    end loop;
end
$$;
