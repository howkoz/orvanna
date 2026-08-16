-- =============================================================================
-- Migration 022: refunds. APPLIED 2026-08-16.
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-15, applied 2026-08-16
-- Author:  mlm-architect
-- Design:  DOCUMENTATION\11-REFUNDS.md
--          Plain path:
--          C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\11-REFUNDS.md
--
-- STATUS: APPLIED on Howard's authorisation. Pre-flight was RE-MEASURED against
--         live data immediately before applying rather than trusted from earlier
--         in the session, and every number below is from that measurement:
--
--           117 demo orders: 29 succeeded, 50 created, 26 abandoned, 8 failed,
--                            4 processing
--           6 orders carry a tax_transaction_id (the only ones that can ever
--             contribute Stripe tax drift, per section 7)
--           payment_status CHECK held exactly the five original values
--           demo_orders_status_transition_guard present, 2 triggers on the table
--           app.demo_order_refunds and app.demo_staff_actions both ABSENT
--           app.orders.demo_order_id ABSENT, so migration 019 is NOT applied and
--             fn_refund_comp_snapshot takes its 'not_applied' branch
--
--         TWO DRIFTS FOUND BY THAT RE-MEASUREMENT, both recorded rather than
--         assumed away:
--
--         1. MIGRATION 018 IS NOW APPLIED (version 20260816000812, tax integrity
--            hardening). This header previously said it was not. It adds no
--            trigger to app.demo_orders, so it does not interact with the refund
--            update path; verified by listing the table's triggers.
--         2. app.demo_users CARRIES THREE ROLES, NOT TWO. Migration 014 widened
--            the constraint to (admin, staff, member) and added 1,000 member
--            sign-in accounts (GW-000001 up). So 1,002 accounts can sign in and
--            exactly ONE of them, Orvanna_Staff, may refund. The comment in
--            functions/_shared/staff-auth.ts was corrected to match before
--            deploying.
--
-- RUN ORDER: after 001..018 and 021. This file does NOT require 019.
--            Section 5 detects at run time whether 019 has been applied and
--            behaves correctly either way. Run as the service role or the
--            database owner; Row Level Security blocks every other role.
--
-- Acronym key, spelled out once and then used short: Application Programming
-- Interface (API), Row Level Security (RLS), JavaScript Object Notation (JSON),
-- Coordinated Universal Time (UTC), Sales Volume (SV), Personal Volume (PV),
-- Hash-based Message Authentication Code (HMAC), Internet Protocol (IP).
--
-- -----------------------------------------------------------------------------
-- WHAT THIS FIXES
-- -----------------------------------------------------------------------------
-- Today a refund cannot be represented at all, let alone performed. Two things
-- block it, and both are deliberate features rather than oversights:
--
--   1. app.demo_orders.payment_status has no refunded value. Its CHECK
--      constraint permits exactly five: created, processing, succeeded, failed,
--      abandoned.
--   2. Migration 010's trigger demo_orders_status_transition_guard makes
--      'succeeded' TERMINAL. Even if the constraint allowed a refunded value,
--      the trigger would raise an exception on the way there.
--
-- Migration 019 policy P8 states the consequence in as many words: "REFUNDS: NO
-- REVERSAL PATH EXISTS, AND NONE IS INVENTED HERE." This migration is where one
-- is invented, openly.
--
-- -----------------------------------------------------------------------------
-- SCOPE: FULL REFUNDS ONLY. PARTIAL REFUNDS ARE DELIBERATELY OUT OF SCOPE, AND
-- THE SCHEMA BELOW IS SHAPED TO ACCEPT THEM WITHOUT A REWRITE. READ THIS.
-- -----------------------------------------------------------------------------
-- Howard's instruction, 2026-08-15: "if doing 100% refund is the easiest then
-- lets do that." So the only refund this system can currently perform returns
-- the ENTIRE amount the customer paid, tax included, in one action.
--
-- The next person reading this will find several columns that look like
-- over-engineering for an all-or-nothing operation. They are not an oversight
-- and they are not speculative generality. They are the four specific places
-- where getting it wrong today would force a data migration later:
--
--   a. REFUNDS ARE THEIR OWN TABLE, NOT COLUMNS ON THE ORDER. One order can
--      carry MANY refund rows. A partial refund world needs exactly that, and a
--      boolean or a pair of columns on app.demo_orders would have to be torn out
--      and back-filled to get there. Today every order simply has zero rows or
--      one row.
--   b. amount_cents IS A REAL COLUMN, NEVER IMPLIED FROM THE ORDER TOTAL. A full
--      refund stores the full amount explicitly. When partial arrives, nothing
--      about this column changes: it already means "the amount of THIS refund".
--      Code that reads it never learns the difference.
--   c. THE ORDER STATE HAS BOTH 'refunded' AND 'partially_refunded' FROM DAY
--      ONE, and the transition guard already permits the partial paths. Only
--      'refunded' is reachable by today's code. Adding partial later is a change
--      to a function, never to a constraint or a trigger, which means it needs no
--      migration against a table that by then holds live money records.
--   d. refund_kind RECORDS WHICH KIND EACH ROW WAS, so a future reader can tell
--      a full refund from a partial one without comparing amounts against an
--      order total that may itself have been partially refunded already.
--
-- The one thing NOT designed here is what a SECOND partial refund may add up to.
-- That rule (the sum of succeeded refunds may never exceed total_cents) is
-- stated as a constraint in section 3 and is already enforced, because it is
-- correct for full refunds too and it is the rule most likely to be forgotten
-- later.
--
-- -----------------------------------------------------------------------------
-- WHAT THIS MIGRATION DOES NOT DO, STATED SO NOBODY ASSUMES OTHERWISE
-- -----------------------------------------------------------------------------
-- NO TAX REVERSAL. Howard's instruction, 2026-08-15. The CUSTOMER gets back
-- everything they paid INCLUDING the tax: amount_cents is the full total_cents,
-- which already contains tax_cents. What is skipped is the BOOKKEEPING reversal
-- in Stripe's own records. Consequence, stated plainly rather than buried:
-- Stripe's tax reports will overstate tax owed by exactly the tax on every
-- refunded order that had already been recorded as a tax transaction. Section 7
-- ships a view that measures that drift to the cent, and section 11 of
-- DOCUMENTATION\11-REFUNDS.md names the exact endpoint that would close it.
--
-- NO CLAWBACK. Out of scope by instruction. This migration does not reverse one
-- cent of volume, does not touch app.orders, app.order_lines,
-- app.commission_runs, app.run_member_results or app.commission_lines, and adds
-- no negative balance concept. What it DOES do is record enough on the refund
-- row that a future clawback can find the order, the amount, the date and the
-- affected commission runs WITHOUT GUESSWORK. That is section 5, and it is the
-- single most important part of this file for future work. A refund recorded
-- thinly today is a clawback that cannot be built tomorrow.
--
-- =============================================================================


-- =============================================================================
-- 1. WIDEN THE STATE, AND SAY WHAT THE NEW STATES MEAN
--
--    'refunded'            every cent the customer paid has been returned.
--                          Terminal. This is the only new state today's code
--                          can reach.
--    'partially_refunded'  some but not all of it has been returned. NOT
--                          reachable by today's code. Present now so that
--                          adding partial refunds later never has to alter a
--                          constraint on a table holding live money records.
-- =============================================================================
alter table app.demo_orders drop constraint if exists demo_orders_payment_status_check;

alter table app.demo_orders
    add constraint demo_orders_payment_status_check
    check (payment_status in
           ('created', 'processing', 'succeeded', 'failed', 'abandoned',
            'refunded', 'partially_refunded'));

comment on column app.demo_orders.payment_status is
    'created, processing, succeeded, failed, abandoned, refunded, '
    'partially_refunded. The last two were added by migration 022. '
    'partially_refunded is defined and permitted but is not reachable by the '
    'current code: full refunds only, by instruction.';


-- =============================================================================
-- 2. AMEND THE TRANSITION GUARD
--
--    Migration 010 made 'succeeded' terminal with no exit. That was right when
--    nothing could follow a successful payment. A refund is the one thing that
--    can, so 'succeeded' gains exactly two exits and no others.
--
--    THE FULL STATE MACHINE AFTER THIS MIGRATION:
--      created            -> processing | succeeded | failed | abandoned
--      processing         -> succeeded | failed | abandoned
--      succeeded          -> refunded | partially_refunded          (NEW)
--      partially_refunded -> partially_refunded | refunded          (NEW)
--      refunded           -> (terminal, no exit)
--      failed             -> (terminal, no exit)
--      abandoned          -> succeeded | failed only
--      'created' is the initial state only; no row ever returns to it.
--
--    WHAT IS DELIBERATELY STILL FORBIDDEN, because each one would be a bug
--    wearing a plausible face:
--      - refunded -> succeeded. Money that went out does not come back by
--        changing a row. A re-purchase is a NEW order number, exactly as a
--        retry after a failure already is.
--      - processing -> refunded. You cannot refund what was never captured.
--        The guard forces a payment to be observed 'succeeded' first, which
--        means the amount check in _shared/edge.ts has already run against it.
--      - abandoned -> refunded. Same reason.
--      - failed -> refunded. There is nothing to return.
--
--    The 'same status again is allowed' rule from migration 010 is preserved
--    unchanged, which is what keeps a repeated refund sync a harmless no-op.
-- =============================================================================
create or replace function app.demo_orders_guard_status_transition()
returns trigger
language plpgsql
as $$
begin
    if new.payment_status = old.payment_status then
        return new;  -- idempotent repeat of the same status: allowed
    end if;

    -- Nothing ever returns to the initial state. Checked first because it is
    -- true regardless of where the row is coming from.
    if new.payment_status = 'created' then
        raise exception 'demo order % cannot return to created; created is the initial state only',
            old.order_number;
    end if;

    -- ADDED BY MIGRATION 023, AND THE REASON IS WORTH READING.
    --
    -- A refund state may be entered ONLY from a paid state. Without this rule
    -- the guard below FALLS THROUGH for 'created' and 'processing', because
    -- those branches only ever tested where a row was coming FROM and relied on
    -- migration 010's CHECK constraint to reject any value it had never heard
    -- of. Widening that constraint in section 1 to admit 'refunded' silently
    -- removed the thing that was doing the work, and 'processing' -> 'refunded'
    -- became legal.
    --
    -- Caught by the section 9 guard tests on 2026-08-16, AFTER 022 was applied
    -- and BEFORE any refund existed. No data was affected: the Edge Function
    -- never attempts this transition, because refund-rules.ts requires
    -- 'succeeded' first. So this was a missing BACKSTOP rather than a live hole,
    -- which is precisely the difference the tests were there to find.
    --
    -- The lesson, recorded because it generalises: when you widen a CHECK
    -- constraint, re-read every trigger that was relying on it to be narrow.
    if new.payment_status in ('refunded', 'partially_refunded')
       and old.payment_status not in ('succeeded', 'partially_refunded') then
        raise exception 'demo order % cannot go from % to %; only a paid order can be refunded',
            old.order_number, old.payment_status, new.payment_status;
    end if;

    -- NEW (migration 022): the refund exits from a successful payment.
    if old.payment_status = 'succeeded' then
        if new.payment_status in ('refunded', 'partially_refunded') then
            return new;
        end if;
        raise exception 'demo order % payment_status is succeeded; it may only change to refunded or partially_refunded, not %',
            old.order_number, new.payment_status;
    end if;

    -- NEW (migration 022): a partly refunded order may be refunded further, and
    -- eventually in full. It can never go anywhere else.
    if old.payment_status = 'partially_refunded' then
        if new.payment_status in ('refunded', 'partially_refunded') then
            return new;
        end if;
        raise exception 'demo order % is partially_refunded; it may only change to partially_refunded or refunded, not %',
            old.order_number, new.payment_status;
    end if;

    -- Unchanged from migration 010, with 'refunded' joining the terminal set.
    if old.payment_status in ('failed', 'refunded') then
        raise exception 'demo order % payment_status is % (terminal); it cannot change to %',
            old.order_number, old.payment_status, new.payment_status;
    end if;

    if old.payment_status = 'abandoned'
       and new.payment_status not in ('succeeded', 'failed') then
        raise exception 'demo order % is abandoned; it may only resolve to succeeded or failed, not %',
            old.order_number, new.payment_status;
    end if;

    return new;
end;
$$;

-- The trigger itself is unchanged and is NOT re-created: 'create or replace
-- function' swaps the body underneath the existing trigger. Stated explicitly
-- because a reader looking for a 'create trigger' below will not find one, and
-- should not add one.


-- =============================================================================
-- 3. app.demo_order_refunds: ONE ROW PER REFUND, NOT PER ORDER
--
--    This is the shape decision that makes partial refunds a later change to a
--    function rather than a later change to a table. See the scope block at the
--    top, point (a).
--
--    THE ROW IS CREATED BEFORE HYPERSWITCH IS CALLED, not after. That ordering
--    is the whole anti-double-refund design and it is worth understanding:
--
--      If we called HyperSwitch first and wrote the row afterwards, then a
--      timeout between the two would leave money returned and no record of it.
--      The next staff click would find no refund row, decide the order had
--      never been refunded, and return the money a SECOND time. Writing the row
--      first inverts the failure: the worst case becomes a 'pending' row for a
--      refund that may or may not have happened, which is a question the
--      processor can be asked (GET /refunds/{refund_id}) and which blocks any
--      second attempt in the meantime. An unanswered question is recoverable.
--      A double refund is not.
--
--    refund_reference is OUR identifier, minted before the call and sent to
--    HyperSwitch as its refund_id. HyperSwitch documents that field as the
--    idempotency mechanism: "This is to ensure idempotency for multiple partial
--    refunds initiated against the same payment." So the unique index below and
--    the processor's own idempotency are the SAME key, which is why a retry
--    with the same reference cannot produce two refunds at either end.
-- =============================================================================
create table if not exists app.demo_order_refunds (
    id                    bigint generated always as identity primary key,

    -- ---- what was refunded ----
    demo_order_id         bigint not null references app.demo_orders (id),
    -- Denormalised on purpose. A clawback, an audit, or a support question
    -- starts from an order NUMBER, never from a surrogate key, and this column
    -- means none of those needs a join to app.demo_orders to get started. It is
    -- written once and never updated; app.demo_orders.order_number is unique and
    -- immutable, so the two cannot drift.
    order_number          text   not null,

    -- ---- how much, in the same minor unit as everything else ----
    -- Integer cents, matching app.demo_orders.total_cents and the HyperSwitch
    -- API, so every comparison is an integer comparison with no rounding
    -- question anywhere in the path.
    amount_cents          integer not null check (amount_cents > 0),
    currency              text    not null default 'USD',

    -- THE TAX INSIDE THAT AMOUNT. Not a separate refund: the customer is
    -- returned amount_cents, and this column simply records how much of it was
    -- tax. It exists for one reason, and it is the reason section 7 can measure
    -- the Stripe drift to the cent instead of estimating it.
    tax_cents_returned    integer not null default 0 check (tax_cents_returned >= 0),

    -- 'full' or 'partial'. Today the function only ever writes 'full'.
    refund_kind           text    not null default 'full'
                          check (refund_kind in ('full', 'partial')),

    -- ---- why, and who ----
    -- The four values HyperSwitch documents for the reason field. Stripe-routed
    -- payments REQUIRE one of duplicate, fraudulent or requested_by_customer, so
    -- constraining to that set keeps us portable off Braintree without a
    -- migration. 'other' is ours and is mapped before the call.
    reason_code           text    not null
                          check (reason_code in
                                 ('duplicate', 'fraudulent',
                                  'requested_by_customer', 'other')),
    -- Free text from the staff agent. Capped so a chatty note cannot become a
    -- storage problem. Never sent to the processor.
    reason_note           text    check (reason_note is null or length(reason_note) <= 500),

    -- The verified staff username from the signed session token, never a value
    -- the browser simply asserted. See functions/_shared/staff-auth.ts.
    requested_by          text    not null,
    -- Salted hash of the caller's IP address, same privacy rail as
    -- app.demo_rate_events. The raw address is never stored.
    requested_ip_hash     text,

    -- ---- processor side ----
    -- Our minted identifier, sent as HyperSwitch's refund_id. Unique here and
    -- idempotent there: the same key at both ends.
    refund_reference      text    not null,
    -- The acquirer's own identifier, returned by HyperSwitch as
    -- connector_refund_id. Null until the call succeeds. This is the value a
    -- human quotes to Braintree support.
    connector_refund_id   text,
    connector             text,

    -- HyperSwitch RefundStatus, verbatim: succeeded, failed, pending, review.
    -- 'requested' is OURS and means the row exists but the call has not yet
    -- returned, which is the pre-call state described above. It is the only
    -- value here that HyperSwitch never sends.
    status                text    not null default 'requested'
                          check (status in
                                 ('requested', 'pending', 'succeeded',
                                  'failed', 'review')),
    -- Sanitized named fields only, exactly like demo_orders.processor_summary.
    -- Never a raw payload, never card data, never a key.
    processor_summary     jsonb,

    -- ---- when ----
    requested_at          timestamptz not null default now(),
    status_updated_at     timestamptz not null default now(),

    -- ---- the clawback hooks. See section 5. ----
    volume_month_first    date,
    comp_impact           jsonb,

    constraint demo_order_refunds_reference_key unique (refund_reference)
);

comment on table app.demo_order_refunds is
    'One row per refund of a live checkout order. Many rows per order are '
    'permitted by design so that partial refunds can be added later without a '
    'schema change; today the function writes at most one full refund per '
    'order. The row is created BEFORE the processor is called, which is what '
    'makes a double refund impossible across a timeout.';

comment on column app.demo_order_refunds.refund_reference is
    'Our identifier, sent to HyperSwitch as refund_id. HyperSwitch documents '
    'that field as the idempotency key for refunds against one payment, so this '
    'column and the processor idempotency are the same key.';

comment on column app.demo_order_refunds.tax_cents_returned is
    'How much of amount_cents was tax. The customer receives the whole of '
    'amount_cents including this. Recorded so the Stripe Tax reporting drift '
    'described in migration 022 section 7 is measurable rather than estimated.';

comment on column app.demo_order_refunds.status is
    'requested (ours: row written, processor not yet answered), then the '
    'HyperSwitch RefundStatus values pending, succeeded, failed, review. '
    'succeeded and failed are terminal; pending and review are not.';

-- ---- indexes: each answers one question that will actually be asked ----

-- "has this order been refunded, and by how much" (the guard the function runs
-- before every refund, and the join a clawback starts from)
create index if not exists demo_order_refunds_order_idx
    on app.demo_order_refunds (demo_order_id);

-- "which refunds are still unsettled" (the reconcile path: rows the processor
-- has not given a terminal answer for yet)
create index if not exists demo_order_refunds_unsettled_idx
    on app.demo_order_refunds (status)
    where status in ('requested', 'pending', 'review');

-- "what did this staff member do, and when" (the audit question)
create index if not exists demo_order_refunds_actor_idx
    on app.demo_order_refunds (requested_by, requested_at desc);


-- -----------------------------------------------------------------------------
-- 3b. AT MOST ONE LIVE REFUND PER ORDER, AND NEVER MORE THAN WAS PAID
--
--     Two rules, and they are separate because they fail differently.
--
--     RULE ONE, enforced by a partial unique index: an order may have at most
--     one refund that is not yet finished. Without it, two staff agents
--     clicking at the same moment could each write a 'requested' row and each
--     call HyperSwitch. The Edge Function also takes a row lock, which is the
--     first line of defence; this index is the one that holds even if a future
--     caller forgets the lock. A FAILED refund does not occupy the slot, so a
--     genuine retry after a decline is still possible.
-- -----------------------------------------------------------------------------
create unique index if not exists demo_order_refunds_one_live_per_order_idx
    on app.demo_order_refunds (demo_order_id)
    where status in ('requested', 'pending', 'review', 'succeeded');

-- -----------------------------------------------------------------------------
--     RULE TWO, enforced by a trigger because it needs to see other rows: the
--     succeeded refunds against one order may never total more than the order
--     was paid. Today, with full refunds only and rule one in force, this can
--     never fire. It is written now anyway, because it is the rule a partial
--     refund implementation is most likely to forget, and because a constraint
--     that already exists cannot be forgotten.
-- -----------------------------------------------------------------------------
create or replace function app.demo_order_refunds_guard_total()
returns trigger
language plpgsql
as $$
declare
    v_order_total integer;
    v_refunded    integer;
begin
    if new.status <> 'succeeded' then
        return new;  -- only settled money counts against the ceiling
    end if;

    select total_cents into v_order_total
      from app.demo_orders
     where id = new.demo_order_id;

    select coalesce(sum(amount_cents), 0) into v_refunded
      from app.demo_order_refunds
     where demo_order_id = new.demo_order_id
       and status = 'succeeded'
       and id <> new.id;

    if v_refunded + new.amount_cents > v_order_total then
        raise exception
            'refund of % cents on demo order % would bring total refunds to % cents against a paid total of % cents',
            new.amount_cents, new.order_number,
            v_refunded + new.amount_cents, v_order_total;
    end if;

    -- The tax returned can never exceed the amount returned.
    if new.tax_cents_returned > new.amount_cents then
        raise exception
            'refund on demo order % returns % cents of tax inside an amount of only % cents',
            new.order_number, new.tax_cents_returned, new.amount_cents;
    end if;

    return new;
end;
$$;

create trigger demo_order_refunds_total_guard
    before insert or update of status, amount_cents on app.demo_order_refunds
    for each row
    execute function app.demo_order_refunds_guard_total();

-- -----------------------------------------------------------------------------
-- 3c. status_updated_at maintains itself, same pattern as migration 010, so no
--     caller can forget to stamp it.
-- -----------------------------------------------------------------------------
create or replace function app.demo_order_refunds_touch_status_updated_at()
returns trigger
language plpgsql
as $$
begin
    if new.status is distinct from old.status then
        new.status_updated_at := now();
    end if;
    return new;
end;
$$;

create trigger demo_order_refunds_touch_status_updated_at
    before update on app.demo_order_refunds
    for each row
    execute function app.demo_order_refunds_touch_status_updated_at();


-- =============================================================================
-- 4. app.demo_staff_actions: THE AUDIT LOG
--
--    WHY A SEPARATE TABLE WHEN THE REFUND ROW ALREADY RECORDS WHO AND WHEN.
--    Because the refund row only exists for refunds that were ALLOWED. The
--    attempts you most want a record of are the ones that were refused: the
--    expired token, the wrong role, the order that was already refunded, the
--    order that never succeeded. None of those produce a refund row, and all of
--    them are the shape of either a mistake worth noticing or somebody probing.
--
--    A refund moves money OUT of the business to a party outside it, and it
--    cannot be undone from our side. That is the whole reason this table exists:
--    for an irreversible outward transfer, "who asked, what did they ask for,
--    and what did the system decide" has to survive the event itself.
--
--    NOTHING PERSONAL IS STORED. The actor is a demonstration username, the
--    address is a salted hash, and detail is a small named-fields object written
--    by our own code. No card data and no key material ever reaches it.
-- =============================================================================
create table if not exists app.demo_staff_actions (
    id            bigint generated always as identity primary key,
    occurred_at   timestamptz not null default now(),
    -- The verified username from the signed token, or the literal 'anonymous'
    -- when the token did not verify at all. Never a browser-asserted value.
    actor         text not null,
    actor_role    text,
    action        text not null,          -- e.g. 'refund_payment'
    target        text,                   -- e.g. the order number
    -- 'allowed' or 'refused'. Deliberately two words rather than a boolean, so
    -- a future third outcome does not need a migration.
    outcome       text not null check (outcome in ('allowed', 'refused')),
    -- Machine-readable reason, matching the error codes the function returns.
    outcome_code  text,
    ip_hash       text,
    detail        jsonb
);

comment on table app.demo_staff_actions is
    'Audit log for staff console actions that move money or change money '
    'records. Records REFUSED attempts as well as allowed ones, which is the '
    'main reason it is separate from app.demo_order_refunds.';

-- APPEND ONLY. An audit log that can be edited is not an audit log, and this
-- one is the record of an irreversible outward money movement. In the style of
-- migration 006's immutability hardening: the row may be written once and never
-- changed or removed. Note the honest limit, stated rather than implied: the
-- table owner can drop this trigger, so it defends against a mistaken or
-- compromised FUNCTION, not against someone holding the database owner role.
-- That is the same boundary every other trigger in this project sits behind.
create or replace function app.demo_staff_actions_append_only()
returns trigger
language plpgsql
as $$
begin
    raise exception 'app.demo_staff_actions is append only; rows cannot be % once written',
        lower(tg_op);
end;
$$;

create trigger demo_staff_actions_no_update
    before update or delete on app.demo_staff_actions
    for each row
    execute function app.demo_staff_actions_append_only();

create index if not exists demo_staff_actions_occurred_idx
    on app.demo_staff_actions (occurred_at desc);
create index if not exists demo_staff_actions_actor_idx
    on app.demo_staff_actions (actor, occurred_at desc);
create index if not exists demo_staff_actions_target_idx
    on app.demo_staff_actions (target);


-- =============================================================================
-- 5. WHAT A REFUND LEAVES BEHIND FOR A CLAWBACK
--
--    CLAWBACKS ARE OUT OF SCOPE. Not one cent of volume is reversed by this
--    migration. What follows exists so that whoever builds clawbacks does not
--    have to reconstruct history from timestamps and hope.
--
--    THE PROBLEM A LATER CLAWBACK WILL HAVE. By the time somebody builds it,
--    the answer to "which commission runs paid on this order" may have changed.
--    Migration 019 policy P4 spreads a one-time purchase across TEN volume
--    months, so a single refunded order can have contributed volume to ten
--    separate runs, some finalized and some not, and the set of finalized ones
--    grows every month. Asking that question in six months' time gives a
--    DIFFERENT and less useful answer than asking it at the moment of refund,
--    because by then everything is finalized and nothing records what was
--    already published WHEN THE MONEY WENT BACK.
--
--    So the answer is captured AT REFUND TIME, as a snapshot, and stored on the
--    refund row. That is what comp_impact is. It is evidence, not a working
--    table: nothing reads it today, and a clawback engine may recompute whatever
--    it likes. But it can never be re-derived, so it is taken now.
--
--    THE FOUR THINGS THE COORDINATOR ASKED FOR, and where each one lives:
--      the order   demo_order_id, and order_number for a human
--      the amount  amount_cents, with tax_cents_returned broken out
--      the date    requested_at, and volume_month_first for the compensation
--                  calendar rather than the wall clock
--      the run(s)  comp_impact -> bridged[] -> run_id and run_status
--
--    GRACEFUL WHEN MIGRATION 019 IS NOT APPLIED. app.orders.demo_order_id is
--    added by 019, which is itself still proposed. This function detects the
--    column at run time and returns an honest 'not_bridgeable' snapshot rather
--    than failing, so 022 can be applied before, after, or without 019.
-- =============================================================================
create or replace function app.fn_refund_comp_snapshot(p_demo_order_id bigint)
returns jsonb
language plpgsql
stable
as $$
declare
    v_has_bridge boolean;
    v_result     jsonb;
begin
    select exists (
        select 1 from information_schema.columns
         where table_schema = 'app'
           and table_name   = 'orders'
           and column_name  = 'demo_order_id'
    ) into v_has_bridge;

    if not v_has_bridge then
        -- Migration 019 is not applied, so no live order has ever produced
        -- volume and there is nothing for a clawback to reverse. Say so
        -- explicitly rather than returning an empty list, which would be
        -- indistinguishable from "bridged, but contributed nothing".
        return jsonb_build_object(
            'captured_at',  now(),
            'bridge',       'not_applied',
            'note',         'app.orders.demo_order_id does not exist, so this order never produced volume.',
            'bridged',      jsonb_build_array()
        );
    end if;

    -- One entry per (order, volume month) this refunded sale contributed to,
    -- with the Sales Volume it carried and the state of that month's run AT THIS
    -- MOMENT. Dynamic SQL because the column is not guaranteed to exist at parse
    -- time; the only interpolated value is a bigint bound as a parameter.
    execute $q$
        select jsonb_build_object(
                   'captured_at', now(),
                   'bridge',      'applied',
                   'bridged',     coalesce(jsonb_agg(x order by x->>'volume_month'), jsonb_build_array())
               )
          from (
              select jsonb_build_object(
                         'order_id',      o.id,
                         'volume_month',  o.volume_month,
                         'order_sv',      coalesce(sum(l.quantity * l.unit_volume), 0),
                         'n_lines',       count(l.id),
                         'run_id',        r.id,
                         'run_status',    r.status
                     ) as x
                from app.orders o
                left join app.order_lines l on l.order_id = o.id
                left join app.commission_runs r
                       on r.period = o.volume_month
                      and r.status = 'final'
               where o.demo_order_id = $1
               group by o.id, o.volume_month, r.id, r.status
          ) s
    $q$
    into v_result
    using p_demo_order_id;

    return coalesce(v_result, jsonb_build_object(
        'captured_at', now(),
        'bridge',      'applied',
        'bridged',     jsonb_build_array()
    ));
end;
$$;

comment on function app.fn_refund_comp_snapshot(bigint) is
    'Evidence for a future clawback: which bridged orders, which volume months, '
    'how much Sales Volume, and which of those months had already been finalized '
    'AT THE MOMENT OF THE REFUND. Captured at refund time because it cannot be '
    're-derived later. Reverses nothing. Returns a not_applied marker when '
    'migration 019 has not been run.';

revoke execute on function app.fn_refund_comp_snapshot(bigint) from public;


-- -----------------------------------------------------------------------------
-- 5b. THE ONE KNOCK-ON THAT NEEDS NO CODE, AND IS WORTH UNDERSTANDING
--
--     Migration 019's bridge gates on payment_status = 'succeeded' (policy P1).
--     Migration 017's tax recorder gates on the same value. Moving a refunded
--     order to 'refunded' therefore removes it from BOTH queues automatically,
--     and that gives a genuinely useful split for free:
--
--       REFUND BEFORE THE BRIDGE RUNS  the order never becomes volume at all.
--                                      Nothing to claw back, ever. Self-healing.
--       REFUND AFTER THE BRIDGE RUNS   the volume already exists and stays.
--                                      comp_impact above records exactly what.
--                                      This is the clawback case.
--
--       REFUND BEFORE record-tax RUNS  no Stripe tax transaction is ever
--                                      created, so there is NO drift for this
--                                      order. This is why section 7 counts only
--                                      orders that already have a
--                                      tax_transaction_id.
--       REFUND AFTER record-tax RUNS   the transaction stands unreversed. Drift.
--
--     None of that required a line of code. It is a consequence of the gates
--     already being written against 'succeeded' rather than against "not
--     failed". Recorded here because it looks like luck and is worth keeping.
-- -----------------------------------------------------------------------------


-- =============================================================================
-- 6. app.v_demo_refunds: the operator's view of what has been refunded
--
--    Internal only. NOT added to the anon surface. The public anon grant surface
--    remains EXACTLY the seven v_demo_* views listed in migration 010; this view
--    is granted to nobody and is readable only by the service role and the owner,
--    the same posture as the tables it reads.
-- =============================================================================
create or replace view app.v_demo_refunds as
select r.id                       as refund_id,
       r.order_number,
       r.requested_at,
       r.status,
       r.refund_kind,
       r.amount_cents,
       r.amount_cents / 100.0     as amount,
       r.tax_cents_returned,
       r.tax_cents_returned / 100.0 as tax_returned,
       r.reason_code,
       r.requested_by,
       r.refund_reference,
       r.connector_refund_id,
       r.connector,
       o.total_cents,
       o.total_cents / 100.0      as order_total,
       o.payment_status           as order_payment_status,
       o.payment_reference,
       o.tax_transaction_id,
       r.volume_month_first,
       r.comp_impact
  from app.demo_order_refunds r
  join app.demo_orders o on o.id = r.demo_order_id;

comment on view app.v_demo_refunds is
    'Operator view of refunds joined to their orders. Internal only: granted to '
    'no API role. The anon surface is unchanged by migration 022.';


-- =============================================================================
-- 7. THE TAX DRIFT, MEASURED RATHER THAN ESTIMATED
--
--    READ THIS EVEN IF YOU SKIP EVERYTHING ELSE IN THIS FILE.
--
--    By instruction, this system does NOT reverse the Stripe Tax transaction
--    when it refunds an order. The customer is made whole: they receive the
--    entire amount they paid, and that amount includes the tax. What is skipped
--    is telling Stripe that the sale was undone.
--
--    THE CONSEQUENCE, STATED PLAINLY. Stripe's tax reports will OVERSTATE the
--    tax owed by exactly the tax on every refunded order that had already been
--    recorded as a tax transaction. It is an overstatement, never an
--    understatement, which is the safer direction to be wrong in: the reports
--    claim more is owed than actually is. It is still wrong, and it grows with
--    every refund.
--
--    THE FIX THAT IS NOT BEING BUILT, named here so a future implementer does
--    not have to research it again:
--        POST https://api.stripe.com/v1/tax/transactions/create_reversal
--        mode=full
--        original_transaction=<app.demo_orders.tax_transaction_id>
--        reference=<order_number>-refund-1
--    Stripe requires 'reference' to be unique across ALL transactions and
--    reversals, and our order numbers are already unique by construction, so
--    suffixing one is sufficient and no new identifier need be invented. The
--    full parameter list is in DOCUMENTATION\11-REFUNDS.md section 11.
--
--    THE MEASUREMENT. Two objects. The view is the running total a human reads;
--    the per-order view underneath it is what you hand to whoever eventually
--    files the reversals, because it already names every transaction id that
--    needs one.
-- =============================================================================
create or replace view app.v_demo_tax_reversal_backlog as
select o.order_number,
       o.tax_transaction_id,
       o.tax_transaction_at,
       o.tax_source,
       o.tax_jurisdiction,
       o.tax_cents,
       o.tax_cents / 100.0 as tax_overstated,
       r.requested_at      as refunded_at,
       r.amount_cents / 100.0 as amount_refunded,
       r.requested_by,
       -- The exact reference to send, precomputed so nobody has to invent one.
       o.order_number || '-refund-1' as proposed_reversal_reference
  from app.demo_orders o
  join app.demo_order_refunds r
    on r.demo_order_id = o.id
   and r.status = 'succeeded'
 where o.payment_status in ('refunded', 'partially_refunded')
   -- ONLY orders that actually reached Stripe as a transaction can drift. An
   -- order refunded before record-tax ran has no transaction to reverse and is
   -- correctly absent from this list (see section 5b).
   and o.tax_transaction_id is not null;

comment on view app.v_demo_tax_reversal_backlog is
    'Every refunded order whose Stripe Tax transaction was never reversed, with '
    'the amount by which Stripe now overstates tax owed and the reference to '
    'use when reversing it. By instruction, no reversal is performed; this view '
    'is how the resulting gap stays known and measurable rather than unknown.';

create or replace view app.v_demo_tax_drift as
select count(*)                                   as refunded_orders_with_tax_transaction,
       coalesce(sum(tax_cents), 0)                as tax_overstated_cents,
       coalesce(sum(tax_cents), 0) / 100.0        as tax_overstated,
       min(refunded_at)                           as first_refund_at,
       max(refunded_at)                           as latest_refund_at
  from app.v_demo_tax_reversal_backlog;

comment on view app.v_demo_tax_drift is
    'One row. How far Stripe tax reporting has drifted from reality because '
    'refunds do not reverse tax transactions. Expected to be zero rows worth of '
    'drift until the first refund of a tax-recorded order.';

-- The same measurement as a plain query, for anyone who has this file open and
-- does not want to go looking for a view name:
--
--   select count(*)                 as refunded_orders,
--          sum(o.tax_cents) / 100.0 as stripe_overstates_tax_by
--     from app.demo_orders o
--     join app.demo_order_refunds r
--       on r.demo_order_id = o.id and r.status = 'succeeded'
--    where o.payment_status in ('refunded', 'partially_refunded')
--      and o.tax_transaction_id is not null;


-- =============================================================================
-- 8. ROW LEVEL SECURITY AND PRIVILEGE HYGIENE
--
--    Same posture as app.demo_orders in migration 010: RLS ON with ZERO
--    policies, so every role subject to RLS (anon and authenticated included)
--    can neither read nor write a single row. The service role bypasses RLS by
--    design and is the only actor that ever touches these tables, always inside
--    an Edge Function.
--
--    The REVOKEs are belt and suspenders in the style of migrations 003, 007 and
--    010, and are the only role statements in this file. They are guarded so
--    this migration also runs on plain Postgres without Supabase roles.
-- =============================================================================
alter table app.demo_order_refunds enable row level security;
alter table app.demo_staff_actions enable row level security;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.demo_order_refunds          from anon;
        revoke all on app.demo_staff_actions          from anon;
        revoke all on app.v_demo_refunds              from anon;
        revoke all on app.v_demo_tax_reversal_backlog from anon;
        revoke all on app.v_demo_tax_drift            from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.demo_order_refunds          from authenticated;
        revoke all on app.demo_staff_actions          from authenticated;
        revoke all on app.v_demo_refunds              from authenticated;
        revoke all on app.v_demo_tax_reversal_backlog from authenticated;
        revoke all on app.v_demo_tax_drift            from authenticated;
    end if;
end
$$;


-- =============================================================================
-- 9. VERIFICATION. Run these after applying. Every one should hold.
-- =============================================================================
--
-- -- 9.1 the new states are permitted
-- select conname, pg_get_constraintdef(oid)
--   from pg_constraint
--  where conrelid = 'app.demo_orders'::regclass
--    and conname  = 'demo_orders_payment_status_check';
--   -- expect: ... 'refunded'::text, 'partially_refunded'::text ...
--
-- -- 9.2 succeeded may now become refunded, and refunded is terminal.
-- --     Run inside a transaction and ROLL BACK. Nothing here is meant to stick.
-- begin;
--   -- pick any succeeded order
--   select id, order_number, payment_status from app.demo_orders
--    where payment_status = 'succeeded' limit 1;
--   -- this should SUCCEED:
--   update app.demo_orders set payment_status = 'refunded' where id = <that id>;
--   -- this should RAISE (terminal):
--   update app.demo_orders set payment_status = 'succeeded' where id = <that id>;
-- rollback;
--
-- -- 9.3 a processing order may NOT be refunded (nothing was captured)
-- begin;
--   update app.demo_orders set payment_status = 'refunded'
--    where payment_status = 'processing';   -- expect: exception
-- rollback;
--
-- -- 9.4 one live refund per order
-- --     Insert two 'requested' rows for one order; the second must violate
-- --     demo_order_refunds_one_live_per_order_idx.
--
-- -- 9.5 the over-refund guard, which today cannot fire but must still work
-- --     Insert a succeeded refund for total_cents + 1; expect the exception
-- --     raised by app.demo_order_refunds_guard_total.
--
-- -- 9.6 the drift measurement answers, and answers zero before any refund
-- select * from app.v_demo_tax_drift;
--
-- -- 9.7 the clawback snapshot runs whether or not migration 019 is applied
-- select app.fn_refund_comp_snapshot(id) from app.demo_orders limit 1;
--
-- -- 9.8 the anon surface is UNCHANGED: this should return the same seven
-- --     v_demo_* views it returned before migration 022, and nothing new.
-- select table_name
--   from information_schema.role_table_grants
--  where grantee = 'anon' and table_schema = 'app'
--  order by table_name;
--
-- -- 9.9 the audit log is append only. Both statements must RAISE.
-- begin;
--   insert into app.demo_staff_actions (actor, action, outcome)
--   values ('verification', 'probe', 'refused');
--   update app.demo_staff_actions set actor = 'someone else'
--    where actor = 'verification';                 -- expect: exception
--   delete from app.demo_staff_actions where actor = 'verification';
--                                                  -- expect: exception
-- rollback;
--
-- -- 9.10 the staff role gate is a DATABASE fact, not a token claim.
-- --      Confirm the two demonstration accounts still carry the roles the
-- --      refund function depends on. 'admin' must NOT be a staff account:
-- --      it is the member portal login, and refund-payment refuses it.
-- select username, role from app.demo_users order by role;
--   -- expect: Orvanna_Admin = admin, Orvanna_Staff = staff
-- =============================================================================
