-- Migration 017: record the tax transaction for a completed sale.
-- Date: 2026-08-15
-- Project: MLM Pilot (Orvanna, personal project)
--
-- RECOVERED FILE, BODY COPIED VERBATIM. This migration was applied to the cloud
-- project through the management interface on 2026-08-15 (ledger version
-- 20260815191928) and no file was written at the time. The statements below are
-- copied verbatim from supabase_migrations.schema_migrations, so this file and
-- production agree exactly. Recovered 2026-08-15 during migration recovery.
-- Nothing was applied to production by the recovery.
--
-- RE-RUN SAFETY: already safe as written. Both column adds and the index carry
-- 'if not exists', and the definitions are unchanged, so the guard is doing the
-- job it is meant for. (Contrast migration 013, where 'if not exists' was used
-- against a name whose definition HAD changed, and silently swallowed the
-- statement.) No guard needed to be added.
--
-- A Stripe Tax CALCULATION is a quote. It is what tells the shopper the
-- figure. A TRANSACTION is the record of a sale actually having happened, and
-- it is what a tax report is later built from. Calculating without ever
-- recording means the checkout shows the right number and the books never
-- learn the sale occurred.
--
-- WHY THIS IS A SEPARATE JOB AND NOT PART OF THE PAYMENT PATH. Tax liability
-- is assumed when the sale completes, so recording must happen AFTER a payment
-- succeeds, never at the quote. But it must also never delay a shopper's
-- receipt: if Stripe is slow, that is a bookkeeping problem, not a reason to
-- leave someone staring at a spinner after their money moved. So the record is
-- written by a separate, idempotent job, and these two columns are how it knows
-- what is still outstanding.
--
-- Stripe requires the transaction reference to be unique across all
-- transactions including reversals. Our order number already is, by
-- construction, so it is used directly and no second identifier is invented.

alter table app.demo_orders add column if not exists tax_transaction_id text;
alter table app.demo_orders add column if not exists tax_transaction_at timestamptz;

comment on column app.demo_orders.tax_transaction_id is
  'Stripe Tax transaction id. Null means the sale has not been recorded for reporting yet: either it has not succeeded, it had no calculation, or the recorder has not run.';

-- The recorder asks exactly one question: which succeeded orders hold a
-- calculation but no transaction yet. This index answers it directly rather
-- than scanning every order ever placed.
create index if not exists demo_orders_tax_unrecorded_idx
  on app.demo_orders (payment_status)
  where tax_calculation_id is not null and tax_transaction_id is null;
