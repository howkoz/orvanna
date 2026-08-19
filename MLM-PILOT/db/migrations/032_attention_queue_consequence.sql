-- =============================================================================
-- 032  Attention queue: expose consequence
-- =============================================================================
-- APPLIED 2026-08-19 to project oiyibdczkokegaxkwulv (mlm-pilot).
--
-- Verified against the LIVE schema before applying, not just the repo:
-- app.billing_attempts has no amount column (confirmed), the money is
-- app.renewal_periods.amount_cents (integer, confirmed), and the cycle-gap
-- source is app.v_cycle_audit with expected_date and accounted (confirmed).
-- The view's SELECT was dry-run on its own first.
--
-- Membership unchanged, which was the thing to prove: 33 rows before and 33
-- after, 26 orphaned_attempt and 7 unrecognized_code. What changed is that
-- those 33 now carry $3,300.00 of money at stake that the console could not
-- previously see. See docs/OPERATIONS-QUEUE-SERVER-SPEC.md.
--
-- WHAT THIS IS FOR
-- The operations console ranks its attention queue by consequence, and can
-- rank only by the CLASS of a row, because that is all the view returns.
-- Handoff screen 8a asks each row to also carry how much money is riding on
-- it and what the clock is. The console shows neither today, and says so on
-- the page, because a figure invented in the browser would be a fabricated
-- number on the one screen where money decides what a human touches first.
--
-- Three nullable columns. Nullable is the design, not laziness: a row with no
-- money on it is a real row, and the console must print an em dash rather than
-- a zero. "0.00" and "nothing at stake" are different statements, and the
-- second one is not the database's to invent either.
--
-- CORRECTED BEFORE IT WAS EVER RUN. The first draft of this file read
-- `ba.amount` and `app.v_cycle_accounting`. Neither exists:
-- app.billing_attempts has no amount column at all, and the cycle-gap branch
-- reads app.v_cycle_audit. Both were caught by checking migrations 024 and 026
-- rather than trusting the draft. The money is on app.renewal_periods
-- .amount_cents -- "priced at billing time, frozen" -- which is the better
-- source anyway: it is what this renewal was actually going to charge, not
-- what the plan costs today.
-- =============================================================================

create or replace view app.v_staff_attention_queue as

-- FM2 orphans: dispatched, no recorded answer. The money may already have
-- moved, which is what makes this the most urgent class in the queue.
select 'orphaned_attempt'::text        as reason,
       rp.subscription_id, rp.renewal_index, ba.id as billing_attempt_id,
       'attempt ' || ba.attempt_no || ' dispatched ' || ba.scheduled_for
       || ' with no recorded answer (FM2)' as detail,
       (rp.amount_cents / 100.0)::numeric(12,2) as amount_at_stake,
       null::timestamptz               as deadline_at,
       null::text                      as decline_class
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome = 'dispatched'

union all

-- Our defect, never the member's. The amount is what we failed to collect.
select 'system_fault', rp.subscription_id, rp.renewal_index, ba.id,
       'class ' || ba.decline_class || ' code ' || coalesce(ba.decline_code, '?')
       || ': our defect, never the member''s (FM5 and kin); member clocks untouched',
       (rp.amount_cents / 100.0)::numeric(12,2),
       null::timestamptz,
       ba.decline_class
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome in ('declined', 'preflight_failed', 'processor_unreachable')
   and coalesce(ba.member_fault, true) = false
   and ba.next_action = 'attention'

union all

-- A code we do not map. Until somebody classifies it we cannot say whose
-- fault it was, so the money is at stake in the honest sense.
select 'unrecognized_code', rp.subscription_id, rp.renewal_index, ba.id,
       'decline code ' || ba.decline_code || ' is not in '
       || 'app.decline_classifications; classified ambiguous by the catch-all, loudly',
       (rp.amount_cents / 100.0)::numeric(12,2),
       null::timestamptz,
       ba.decline_class
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome = 'declined'
   and ba.decline_code is not null
   and not exists (select 1 from app.decline_classifications c
                    where c.code = ba.decline_code)

union all

-- An integrity violation, not a payment in flight. NO amount, deliberately:
-- there is no renewal period to price, nothing was going to be charged, and
-- printing 0.00 would claim the opposite. The expected date IS the clock, so
-- it is the deadline.
select 'cycle_gap', ca.subscription_id, ca.renewal_index, null,
       'expected cycle ' || ca.renewal_index || ' (' || ca.expected_date
       || ') has NO accounting row: integrity violation (FM4)',
       null::numeric(12,2),
       ca.expected_date::timestamptz,
       null::text
  from app.v_cycle_audit ca
 where not ca.accounted;

comment on view app.v_staff_attention_queue is
    'The rows a human must see (spec 9A.2): FM2 orphans, system faults '
    'including FM5 pre-flight stops, unrecognized decline codes, FM4 cycle '
    'gaps. Added by migration 026. Migration 032 added amount_at_stake, '
    'deadline_at and decline_class so the console can rank and total by '
    'consequence. All three are nullable and null means NONE, never zero.';


-- -----------------------------------------------------------------------------
-- The audit record for clearing a row.
-- -----------------------------------------------------------------------------
-- Clearing records THAT A HUMAN LOOKED. It moves no money, changes no
-- subscription state, and deletes nothing from the queue's source tables --
-- the row leaves the queue when the underlying fault is actually resolved,
-- not when somebody acknowledges it. The console says this on the page, and
-- this table is what makes the claim true.
create table if not exists app.attention_cleared (
  id               bigint generated always as identity primary key,
  subscription_id  bigint      not null references app.subscriptions (id),
  renewal_index    int         not null,
  reason           text        not null,
  cleared_by       text        not null,      -- the operator's member number
  note             text,
  cleared_at       timestamptz not null default now(),

  -- Idempotent per row: a double click writes once, and a second operator
  -- clearing the same row updates rather than duplicating.
  constraint attention_cleared_row_uniq
    unique (subscription_id, renewal_index, reason)
);

comment on table app.attention_cleared is
    'A record that a human looked at an attention-queue row. Moves no money '
    'and changes no subscription state. Unique per (subscription, renewal, '
    'reason) so a double click writes once. Added by migration 032.';

create index if not exists attention_cleared_at_idx
    on app.attention_cleared (cleared_at desc);


-- =============================================================================
-- AFTER THIS RAN
-- =============================================================================
-- 1. functions/billing-console/index.ts now selects and returns the three new
--    columns, and gains a clear_attention action. That change is committed but
--    NOT yet deployed: deploying it needs the Supabase CLI with an access
--    token, which the build container does not have. Until it ships, the
--    console shows an em dash for every amount and says why on the page.
--
-- 2. The console reads whichever shape it is given. It does not assume the new
--    columns exist, so this migration was safe to apply ahead of the function
--    and the front end, and is safe to leave applied if either is delayed.
--
-- 3. Nothing here moves money. The view is a read, and app.attention_cleared
--    records that a human looked -- it does not resolve the underlying fault
--    and does not remove the row from the queue.
-- =============================================================================
