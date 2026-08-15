-- Migration 016: record WHERE each order's tax figure came from.
-- Date: 2026-08-15
-- Project: MLM Pilot (Orvanna, personal project)
--
-- RECOVERED FILE, BODY COPIED VERBATIM EXCEPT FOR ONE ADDED GUARD. This
-- migration was applied to the cloud project through the management interface
-- on 2026-08-15 (ledger version 20260815190816) and no file was written at the
-- time. The statements below are copied verbatim from
-- supabase_migrations.schema_migrations, with ONE change, marked inline: the
-- 'alter table ... add constraint' is wrapped in an existence check so a
-- rebuild can be re-run. The constraint definition itself is unchanged, so the
-- resulting schema is identical to production. Recovered 2026-08-15 during
-- migration recovery. Nothing was applied to production by the recovery.
--
-- Tax stops being a flat five percent computed by our own pricing mirror and
-- becomes a real figure returned by Stripe Tax for a real destination. Two
-- consequences make provenance worth storing rather than inferring.
--
-- 1. A ZERO IS AMBIGUOUS AND THE DIFFERENCE MATTERS. Stripe returns zero when
--    the seller has no registration in that jurisdiction, and ALSO when the
--    jurisdiction genuinely does not tax the product. The first is a
--    misconfiguration and the second is the correct answer. Only Stripe's
--    taxability_reason tells them apart, so it is stored instead of thrown
--    away, and the checkout can say WHY a figure is what it is.
--
-- 2. A FALLBACK MUST NEVER BE SILENT. If Stripe cannot be reached the order
--    still has to price, so it falls back to the flat rate. An order priced
--    that way is not the same fact as one priced by a tax engine, and a
--    receipt that cannot tell you which is a receipt that quietly lies.
--    tax_source records it on every row, with no default that could hide it.

alter table app.demo_orders add column if not exists tax_source text;
alter table app.demo_orders add column if not exists tax_calculation_id text;
alter table app.demo_orders add column if not exists tax_reason text;
alter table app.demo_orders add column if not exists tax_jurisdiction text;

-- Existing rows were all priced by the flat mirror. Saying so is more honest
-- than leaving them null and letting a reader assume.
update app.demo_orders set tax_source = 'flat_mirror_5pct' where tax_source is null;

-- ADDED BY RECOVERY (the only change from the applied body): the original ran
-- a bare 'add constraint', which errors on a second run. The constraint text is
-- byte-for-byte the applied one; only the existence check around it is new.
do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conrelid = 'app.demo_orders'::regclass
          and conname  = 'demo_orders_tax_source_check'
    ) then
        alter table app.demo_orders
          add constraint demo_orders_tax_source_check
          check (tax_source is null or tax_source in ('stripe_tax', 'flat_mirror_5pct', 'flat_fallback'));
    end if;
end
$$;

-- NOTE FOR THE READER, not part of the applied body: this check PERMITS NULL,
-- which leaves reachable the exact silent case the comment above argues against.
-- No live row is null today because the Edge Function always supplies a value,
-- but the database is not enforcing the rule this migration states. The fix is
-- proposed, and NOT applied, in 018_PROPOSED_tax_integrity_hardening.sql.

comment on column app.demo_orders.tax_source is
  'stripe_tax = calculated by Stripe Tax; flat_fallback = Stripe unreachable, flat rate used; flat_mirror_5pct = priced before Stripe Tax existed.';
comment on column app.demo_orders.tax_reason is
  'Stripe taxability_reason. not_collecting means no registration; not_subject_to_tax means the jurisdiction does not tax it. A zero means different things under each.';
