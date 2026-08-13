-- Comp engine 003: guarded app-data reset
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date: 2026-08-13
--
-- *** PRE-PRODUCTION USE ONLY. ***
-- This script TRUNCATES every data table in schema app (members, products,
-- subscriptions, orders, order lines, commission runs, results, lines, and
-- the run level maps) so the environment can move from the worked-example
-- data to the full 1,000-member seed (db\seed\output\load_seed.sql), which
-- requires an empty database because it inserts explicit ids starting at 1.
--
-- Notes:
--   * TRUNCATE does not fire row-level triggers, so even FINALIZED
--     (immutable) runs are cleared. That is exactly why this script is
--     pre-production only: in any real environment finalized statements are
--     receipts and must never be destroyed.
--   * app.ranks is intentionally KEPT: it is reference data seeded by
--     migration 004, and the data loaders do not reseed it.
--   * RESTART IDENTITY resets every identity sequence so the loaders'
--     explicit ids (starting at 1) apply cleanly.
--   * Run as the service role or database owner (RLS blocks everyone else).
--
-- GUARD: the DO block below refuses to run unless the session setting
-- app.allow_reset holds the exact acknowledgement phrase. The SET is
-- included here so running the WHOLE script works in one paste; the guard
-- protects against running the TRUNCATE fragment alone or via a stray
-- copy-paste into the wrong session.

set app.allow_reset = 'wipe app data, pre-production only';

do $$
begin
    if coalesce(current_setting('app.allow_reset', true), '')
       <> 'wipe app data, pre-production only' then
        raise exception
            'reset refused: set app.allow_reset to the acknowledgement phrase first (see script header)';
    end if;
end
$$;

-- One statement, all referencing tables listed together, so foreign keys
-- never block the truncate. Dependency order shown children first for
-- readability; TRUNCATE itself treats the list atomically.
truncate table
    app.commission_lines,
    app.run_member_results,
    app.run_level_map,
    app.commission_runs,
    app.order_lines,
    app.orders,
    app.customers,
    app.subscriptions,
    app.members,
    app.products
restart identity;
-- (app.customers added 2026-08-13 at deploy: this script predated migration
-- 007; customers reference members, so the truncate needs them in the list.)

reset app.allow_reset;

-- After this script: load db\seed\output\load_seed.sql (the 1,000-member
-- pack), then call app.fn_run_commission(period) for each month to compute.
