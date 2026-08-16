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
-- POST-RESET STEP, REQUIRED SINCE MIGRATIONS 019 AND 020 (added 2026-08-16):
-- after any reset plus reseed, RE-RUN migration 019 sections 2 and 3 (the four
-- bundle and pack product rows, and the sixteen app.shop_sku_map rows) and
-- migration 020 steps 2 and 3 (the GW-000 house member row; step 3's table
-- survives the reset but its rows do not). All of those inserts are written
-- with ON CONFLICT DO NOTHING, so re-running them is safe and repeatable.
-- If this step is skipped, the shop-to-comp bridge answers
-- "skip: unmapped shop sku" for EVERY order: loud, but quietly non-functional
-- until somebody notices. The seed loaders restore only the twelve seeded
-- products and know nothing about the bridge's mapping rows.
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
    app.house_retained_volume,
    app.shop_sku_map,
    app.customers,
    app.subscriptions,
    app.members,
    app.products
restart identity;
-- (app.customers added 2026-08-13 at deploy: this script predated migration
-- 007; customers reference members, so the truncate needs them in the list.)
-- (app.shop_sku_map and app.house_retained_volume added 2026-08-16 when
-- migrations 019 and 020 were applied: shop_sku_map references products, and
-- house_retained_volume references members, so Postgres refuses to truncate
-- either parent while a referencing table is absent from the same list. See
-- the POST-RESET STEP in the header: the reseed does NOT restore these rows.)

reset app.allow_reset;

-- After this script: load db\seed\output\load_seed.sql (the 1,000-member
-- pack), then call app.fn_run_commission(period) for each month to compute.
