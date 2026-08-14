-- Migration 010: Phase 6 demo order tables (app.demo_orders, app.demo_rate_events)
-- Purpose: create the two tables of docs\PHASE-6-SPEC.md sections 2.2 and 2.3:
--          app.demo_orders, the live TEST-MODE checkout orders written only by
--          the Edge Functions using the service role, and app.demo_rate_events,
--          the rate limit ledger keyed by a salted Internet Protocol (IP)
--          address hash. Row-Level Security (RLS) is enabled on both tables
--          with ZERO policies: no anon policy, no authenticated policy, and,
--          unlike migrations 003 and 007, no app_demo_reader policy either,
--          because no view reads these tables (PHASE-6-SPEC section 2.4 rules
--          out a live-orders view in v1). Only the service role, which
--          bypasses RLS by design, reads or writes them.
--
--          ANON SURFACE UNCHANGED: the public anon grant surface remains
--          EXACTLY the seven existing v_demo_* views (v_demo_members,
--          v_demo_tree, v_demo_member_months, v_demo_statements,
--          v_demo_company, v_demo_customers, v_demo_customer_volume). This
--          migration adds no view, no grant to anon or authenticated, and no
--          schema exposure change. The only role statements below are REVOKEs,
--          in the belt-and-suspenders style of migrations 003 and 007.
--
--          ENGINE UNTOUCHED: no foreign key into app.orders, no change to any
--          existing table, view, function, or trigger. Nothing that computes
--          app.commission_runs, app.run_member_results, or app.commission_lines
--          gains a new input, so the finalized-months invariant holds by
--          construction (PHASE-6-SPEC section 2.1). The one foreign key here,
--          demo_orders.member_id referencing app.members(id), is read-only
--          attribution required by the spec and feeds nothing.
-- Date: 2026-08-14
-- Project: MLM Pilot (Orvanna, personal project)

-- ---------------------------------------------------------------------------
-- app.demo_orders (PHASE-6-SPEC section 2.2)
-- One row per live demo checkout. order_number is THE idempotency key: the
-- database itself forbids two rows for one order. Money lives in integer
-- cents on purpose: it is the same minor unit the HyperSwitch Application
-- Programming Interface (API) uses, so the amount equality check in
-- confirm-payment is an integer comparison with no rounding question.
-- Display formatting back to two-decimal dollars happens at the edge.
-- items is a JavaScript Object Notation (JSON) array of
-- { sku, mode, quantity, unit_price, unit_pv } as the SERVER priced them;
-- client prices are never trusted or stored. processor_summary is the
-- sanitized summary from the server-side retrieve only: never raw card data,
-- never a full processor payload.
-- ---------------------------------------------------------------------------
create table app.demo_orders (
    id                    bigint generated always as identity primary key,
    order_number          text not null,
    created_at            timestamptz not null default now(),
    created_by_channel    text not null
                          check (created_by_channel in ('shop', 'staff_console')),
    member_id             bigint references app.members (id),
    referral_code_entered text,
    items                 jsonb not null,
    activation            text not null
                          check (activation in ('priority', 'standard')),
    subtotal_one_cents    integer not null,
    subtotal_sub_cents    integer not null,
    activation_fee_cents  integer not null,
    tax_cents             integer not null,
    tax_exempt            boolean not null,
    total_cents           integer not null,
    pv_total              numeric(10,2) not null,
    payment_reference     text,
    payment_status        text not null default 'created'
                          check (payment_status in
                                 ('created', 'processing', 'succeeded',
                                  'failed', 'abandoned')),
    processor_summary     jsonb,
    status_updated_at     timestamptz not null default now(),
    constraint demo_orders_order_number_key unique (order_number)
);

-- payment_reference is the HyperSwitch payment_id: null until HyperSwitch
-- responds, unique when not null (partial unique index per the spec).
create unique index demo_orders_payment_reference_key
    on app.demo_orders (payment_reference)
    where payment_reference is not null;

create index demo_orders_created_at_idx     on app.demo_orders (created_at);
create index demo_orders_payment_status_idx on app.demo_orders (payment_status);

-- ---------------------------------------------------------------------------
-- Status transition guard (PHASE-6-SPEC sections 1.5, 5.4, 5.5).
-- The state machine, derived from the spec's state tables:
--   created    -> processing | succeeded | failed | abandoned
--   processing -> succeeded | failed | abandoned
--   succeeded  -> (terminal, no exit)
--   failed     -> (terminal, no exit; a retry is a NEW order number)
--   abandoned  -> succeeded | failed only (a late reconcile or the v1.1
--                 webhook may discover the processor-confirmed truth; it can
--                 never move back to a pre-payment state)
--   'created' is the initial state only; no row ever returns to it.
-- Setting the same status again is allowed: confirm-payment retries are
-- idempotent no-ops by construction. Confirmation is UPDATE-only on an
-- existing order_number at the function layer; at the database layer the
-- unique constraint above already forbids a second row for the same order.
-- ---------------------------------------------------------------------------
create or replace function app.demo_orders_guard_status_transition()
returns trigger
language plpgsql
as $$
begin
    if new.payment_status = old.payment_status then
        return new;  -- idempotent repeat of the same status: allowed
    end if;

    if old.payment_status in ('succeeded', 'failed') then
        raise exception 'demo order % payment_status is % (terminal); it cannot change to %',
            old.order_number, old.payment_status, new.payment_status;
    end if;

    if old.payment_status = 'abandoned'
       and new.payment_status not in ('succeeded', 'failed') then
        raise exception 'demo order % is abandoned; it may only resolve to succeeded or failed, not %',
            old.order_number, new.payment_status;
    end if;

    if new.payment_status = 'created' then
        raise exception 'demo order % cannot return to created; created is the initial state only',
            old.order_number;
    end if;

    return new;
end;
$$;

create trigger demo_orders_status_transition_guard
    before update of payment_status on app.demo_orders
    for each row
    execute function app.demo_orders_guard_status_transition();

-- ---------------------------------------------------------------------------
-- Updated-at maintenance: status_updated_at follows payment_status changes
-- automatically, so the Edge Functions cannot forget to stamp it.
-- ---------------------------------------------------------------------------
create or replace function app.demo_orders_touch_status_updated_at()
returns trigger
language plpgsql
as $$
begin
    if new.payment_status is distinct from old.payment_status then
        new.status_updated_at := now();
    end if;
    return new;
end;
$$;

create trigger demo_orders_touch_status_updated_at
    before update on app.demo_orders
    for each row
    execute function app.demo_orders_touch_status_updated_at();

-- ---------------------------------------------------------------------------
-- app.demo_rate_events (PHASE-6-SPEC section 2.3): the rate limit ledger.
-- ip_hash is a salted hash of the caller's IP address (salt
-- ORVANNA_DEMO_IP_SALT from the secrets vault); the raw IP is never stored.
-- window_start is the minute bucket, truncated. Rows older than 24 hours are
-- dropped by a scheduled cleanup or opportunistically inside the functions;
-- no database job ships in this migration.
-- ---------------------------------------------------------------------------
create table app.demo_rate_events (
    ip_hash       text not null,
    window_start  timestamptz not null,
    request_count integer not null,
    primary key (ip_hash, window_start)
);

-- ---------------------------------------------------------------------------
-- Row-Level Security: ON for both tables, ZERO policies. With RLS enabled and
-- no policy, every role subject to RLS (anon and authenticated included) can
-- neither read nor write a single row; the service role bypasses RLS and is
-- the only actor that touches these tables, always inside an Edge Function.
-- ---------------------------------------------------------------------------
alter table app.demo_orders      enable row level security;
alter table app.demo_rate_events enable row level security;

-- Belt and suspenders, same pattern as migrations 003 and 007: strip any
-- table privilege the public API roles could ever hold on these tables.
-- Guarded so the migration also runs on plain Postgres without Supabase
-- roles. These REVOKEs are the only role statements in this migration.
do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.demo_orders      from anon;
        revoke all on app.demo_rate_events from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.demo_orders      from authenticated;
        revoke all on app.demo_rate_events from authenticated;
    end if;
end
$$;
