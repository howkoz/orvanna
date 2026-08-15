-- Migration 018: PROPOSED, NOT APPLIED. Howard decides.
-- Purpose: close two gaps on app.demo_orders that the database currently does
--          not enforce, both found during the data model documentation pass of
--          2026-08-15:
--            1. tax_source is nullable, so the silent fallback that migration
--               016 argues against is still reachable.
--            2. nothing ties total_cents to the sum of its parts.
-- Date drafted: 2026-08-15
-- Project: MLM Pilot (Orvanna, personal project)
--
-- ===========================================================================
-- STATUS: PROPOSED. NOT APPLIED TO PRODUCTION. NOT IN THE LIVE LEDGER.
-- ===========================================================================
-- This file exists so the fix can be read and judged before it is real. It was
-- written during a documentation and recovery task whose scope explicitly
-- excluded touching production. Do not apply it by reflex; read the two
-- decisions below first, because one of them is a genuine judgement call.
--
-- PRE-FLIGHT, ALREADY CHECKED AGAINST LIVE DATA (read-only) 2026-08-15:
--   115 demo orders exist.
--   115 of 115 satisfy total_cents = the sum of the four parts. The check
--       constraint will therefore validate without a single failing row.
--     0 of 115 have a null tax_source. The 'set not null' will therefore
--       succeed without needing a backfill.
-- Re-run those two counts before applying, since rows arrive continuously.
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- 1. tax_source becomes NOT NULL, with a default.
--
-- WHY. Migration 016 states the rule in its own header: "A FALLBACK MUST NEVER
-- BE SILENT ... tax_source records it on every row, with no default that could
-- hide it." The column as shipped does not enforce that rule. It is nullable,
-- and its check constraint explicitly begins 'tax_source is null or ...', so a
-- null passes. Today no row is null, because the Edge Function always supplies
-- a value. That is a habit of the code, not a guarantee of the database, and
-- the whole argument of 016 is that this particular fact must be guaranteed.
--
-- THE JUDGEMENT CALL, stated openly because it is the one thing here worth
-- disagreeing about. A 'set not null' needs a default, otherwise any future
-- insert that omits the column fails outright. Two defensible defaults exist:
--
--   (a) default 'flat_fallback'  <- chosen here
--       A row whose provenance nobody recorded is treated as the LEAST
--       trustworthy kind. A forgotten value can then never overstate where a
--       figure came from. The cost: 'flat_fallback' asserts a specific story
--       (the tax engine was unreachable) that may not be what happened, so a
--       defaulted row makes a slightly wrong claim rather than no claim.
--
--   (b) add a fourth value, 'unspecified', to the check constraint and default
--       to that.
--       Strictly more truthful: it claims nothing, and unlike null it is loud
--       and easy to query for. The cost: it is a new state that every reader
--       of tax_source has to learn and handle, and it quietly re-admits the
--       "we do not know" case that 016 set out to abolish.
--
-- (a) is written below because it keeps the value set closed and forces the
-- weakest claim. If Howard prefers (b), swap the default and extend the check;
-- the rest of this file is unaffected.
-- ---------------------------------------------------------------------------

-- Belt and braces: fill anything null before the constraint tightens. A no-op
-- today (0 rows), and the reason this file is safe to run more than once.
update app.demo_orders
   set tax_source = 'flat_fallback'
 where tax_source is null;

alter table app.demo_orders
    alter column tax_source set default 'flat_fallback';

alter table app.demo_orders
    alter column tax_source set not null;

-- With the column NOT NULL, the 'is null or' branch of the original check is
-- dead text. Replaced with the plain membership test so the constraint says
-- what it now means. Dropped by name with 'if exists' so this is re-runnable.
alter table app.demo_orders
    drop constraint if exists demo_orders_tax_source_check;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conrelid = 'app.demo_orders'::regclass
          and conname  = 'demo_orders_tax_source_check'
    ) then
        alter table app.demo_orders
          add constraint demo_orders_tax_source_check
          check (tax_source in ('stripe_tax', 'flat_mirror_5pct', 'flat_fallback'));
    end if;
end
$$;

comment on column app.demo_orders.tax_source is
  'NOT NULL. stripe_tax = calculated by Stripe Tax; flat_fallback = Stripe unreachable or provenance not recorded, flat rate assumed; flat_mirror_5pct = priced before Stripe Tax existed. Defaults to flat_fallback so a forgotten value can never overstate provenance.';


-- ---------------------------------------------------------------------------
-- 2. total_cents must equal the sum of its parts.
--
-- WHY. The order total is stored as its own column alongside the four numbers
-- that make it up. Nothing currently stops the five from disagreeing. The
-- pricing code is careful (it RECOMPUTES the total from the parts after tax is
-- calculated, rather than adjusting the existing total, which is the right
-- instinct) but a single arithmetic slip in a future edit would be written to
-- the database without complaint, and total_cents is the number the payment is
-- actually opened for. A row where the total does not equal its parts is a
-- receipt that does not add up.
--
-- This is the cheapest possible guarantee: one check constraint, evaluated on
-- write, on integers. There is no rounding question to argue about because
-- every one of these columns is integer cents.
--
-- SCOPE NOTE: this deliberately does NOT constrain pv_total, which is volume
-- points rather than money, is numeric rather than integer, and is derived from
-- the items array by a different rule.
-- ---------------------------------------------------------------------------

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conrelid = 'app.demo_orders'::regclass
          and conname  = 'demo_orders_total_is_sum_of_parts_check'
    ) then
        alter table app.demo_orders
          add constraint demo_orders_total_is_sum_of_parts_check
          check (total_cents = subtotal_one_cents
                             + subtotal_sub_cents
                             + activation_fee_cents
                             + tax_cents);
    end if;
end
$$;


-- ---------------------------------------------------------------------------
-- ROLLBACK, if either change turns out to be wrong.
-- Kept as comments on purpose: an applied rollback belongs in its own numbered
-- migration, not hidden at the bottom of the migration it undoes.
--
--   alter table app.demo_orders drop constraint if exists demo_orders_total_is_sum_of_parts_check;
--   alter table app.demo_orders drop constraint if exists demo_orders_tax_source_check;
--   alter table app.demo_orders alter column tax_source drop not null;
--   alter table app.demo_orders alter column tax_source drop default;
--   alter table app.demo_orders add constraint demo_orders_tax_source_check
--     check (tax_source is null or tax_source in ('stripe_tax', 'flat_mirror_5pct', 'flat_fallback'));
-- ---------------------------------------------------------------------------
