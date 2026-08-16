-- =============================================================================
-- Migration 024: subscription engine Phase S1, the schema
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
-- Design:  MLM-PILOT\docs\SUBSCRIPTION-ENGINE-SPEC.md (the law for this build),
--          sections 5 (state machine), 6 (schema), 13A (failure-mode register),
--          plus the addendum recording Howard's rulings on all nine open
--          questions (2026-08-16 evening). Bridge rulings ride underneath:
--          MLM-PILOT\docs\decisions\2026-08-16-bridge-seven-decisions.md.
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY. Per open question ruling OQ8 and
--         the standing rule, NOTHING in Phase S1 applies to the cloud project
--         until both gates pass on these exact artifacts. The local proof rig
--         is MLM-PILOT\db\subscriptions\run_proofs.py (a disposable PostgreSQL
--         container that applies migrations 001 through 027 verbatim).
--         Once applied anywhere, this file is FROZEN: applied SQL is never
--         edited, a follow-up change is a new numbered migration.
--
-- Acronym key, spelled out once: Personal Volume (PV), Sales Volume (SV),
-- Commissionable Volume (CV), Stock Keeping Unit (SKU), Coordinated Universal
-- Time (UTC), Row Level Security (RLS), Customer Initiated Transaction (CIT,
-- the cardholder is present and acting), Merchant Initiated Transaction (MIT,
-- the merchant charges a stored credential with no cardholder present),
-- Foreign Key (FK), Primary Key (PK), failure mode (FM), Quality Assurance (QA).
--
-- -----------------------------------------------------------------------------
-- WHAT THIS MIGRATION IS
-- -----------------------------------------------------------------------------
-- The complete data shape for the renewal engine: one evolved table
-- (app.subscriptions), one widened check (app.demo_orders.created_by_channel),
-- and the spec's ten new tables. The engine FUNCTIONS live in migration 026;
-- the classification and retry-policy DATA in 025; the one bridge amendment in
-- 027. Splitting shape from data from behavior keeps each reviewable alone and
-- lets a cadence change later be a data migration, never a code deploy.
--
-- DELIBERATE DEVIATIONS FROM THE SPEC'S SKETCHES, each argued where it lands
-- (the spec says its SQL blocks are sketches for shape only; the real calls
-- are this file's to make and to defend):
--   D1. app.sim_clock's date column is named clock_date, not current_date,
--       because current_date is a reserved word in PostgreSQL.
--   D2. app.subscription_events gains effective_from_renewal_index and
--       pause_until: pause and billing-day-change consequences are RESOLVED
--       INTO DATA at event time (the migration 021 materialise-at-decision
--       principle), so the schedule derivation replays deterministically
--       without re-deciding which renewals a pause deferred.
--   D3. app.billing_attempts gains ladder_step, decline_class and a
--       member_fault flag: the spec's section 6.2 table 5 principle (member
--       fault versus system fault, reported separately, only member fault may
--       consume the member's clocks) needs the classification snapshotted on
--       the attempt, because classifications are effective-dated and the
--       attempt must carry the answer it was judged by.
--   D4. app.billing_runs gains the close-out assertion columns of pipeline
--       step 12 (promo hook identity, the MIT invariant, member-fault and
--       system-fault totals, attempts reconciled) so a run row IS its own
--       run report.
--   D5. billing_day is checked 1 through 28, not 1 through 31 as the spec's
--       6.1 sketch had it, because Howard's addendum ruling on OQ3 (2026-08-16
--       evening) allows member picks through the 28th ONLY, with 29 through 31
--       normalizing to 28 at signup. The pick rule is therefore structural.
--       billing_anchor_date carries NO day restriction: seeded and legacy
--       anchors may land on 29 through 31 and the derivation clamp
--       (spec 12.5, failure mode FM4) handles them; that defensive path is
--       exactly what proof D exercises with a day-31 anchor.
--
-- RUN ORDER: after 001 through 023 (023 exists as a pointer; its refund guard
-- is not a dependency). Before 025, 026, 027.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. EVOLVE app.subscriptions (spec 6.1: evolve, do not replace)
--
--    The existing shape (member_id, product_id, quantity, start_month
--    inclusive, cancel_month exclusive) stays. 1,820 seeded rows and six
--    finalized months interpret it, the comp engine never reads this table
--    (it reads orders), and the month model is exactly the coverage arithmetic
--    the engine needs.
--
--    Backfill reproduces current seeded behavior exactly: monthly, anchor at
--    start_month (day 1, so no clamp ever fires on a seeded row), state
--    active where cancel_month is null, cancelled otherwise.
-- -----------------------------------------------------------------------------
alter table app.subscriptions
    add column if not exists frequency_months int not null default 1;

alter table app.subscriptions drop constraint if exists subscriptions_frequency_months_check;
alter table app.subscriptions
    add constraint subscriptions_frequency_months_check
    check (frequency_months in (1, 2, 3, 6));

alter table app.subscriptions
    add column if not exists billing_day int;

alter table app.subscriptions drop constraint if exists subscriptions_billing_day_check;
alter table app.subscriptions
    add constraint subscriptions_billing_day_check
    check (billing_day is null or (billing_day between 1 and 28));

alter table app.subscriptions
    add column if not exists billing_anchor_date date;

alter table app.subscriptions
    add column if not exists state text not null default 'active';

alter table app.subscriptions drop constraint if exists subscriptions_state_check;
alter table app.subscriptions
    add constraint subscriptions_state_check
    check (state in ('active', 'past_due', 'dunning', 'card_update_required',
                     'paused', 'suspended', 'cancelled'));

alter table app.subscriptions
    add column if not exists state_changed_at timestamptz not null default now();

-- credential_id FK is added in section 3 below, after app.payment_credentials
-- exists.

-- Backfill: every pre-existing row is a seeded monthly subscription anchored
-- on the first of its start month. A cancelled seeded row (cancel_month set)
-- becomes state 'cancelled' so the engine never gathers it; its history is
-- interpreted by start_month/cancel_month exactly as before.
update app.subscriptions
   set billing_anchor_date = start_month
 where billing_anchor_date is null;

update app.subscriptions
   set state = 'cancelled'
 where cancel_month is not null
   and state = 'active';

alter table app.subscriptions
    alter column billing_anchor_date set not null;

comment on column app.subscriptions.frequency_months is
    'Ruling R1 frequencies as data: 1 monthly, 2 bi-monthly, 3 quarterly, '
    '6 semi-annual. The charge is frequency_months times the current catalog '
    'monthly price, priced at billing time (never stored, FM3).';
comment on column app.subscriptions.billing_day is
    'Member-picked day of month, 1 to 28 (OQ3 ruling: picks above 28 are not '
    'representable; 29 to 31 normalize to 28 at signup). Null means the anchor '
    'rule: the billing day is billing_anchor_date''s day of month.';
comment on column app.subscriptions.billing_anchor_date is
    'The schedule anchor. Checkout-born rows: purchase date plus 30 days, '
    'normalized to day 28 when the sum lands on 29 to 31 (OQ3). Seeded rows: '
    'backfilled to start_month (day 1). Every cycle date derives from THIS '
    'plus cycle-number arithmetic, never from a stored next date (FM4).';
comment on column app.subscriptions.state is
    'The seven-state machine of spec section 5. Transitions are guarded by '
    'trigger subscriptions_state_transition_guard; nothing returns to active '
    'except a processor-confirmed succeeded payment.';

-- No next_billing_date column, DELIBERATELY (spec 6.1, the E16 footgun rule):
-- the next billing date is a lens (app.v_subscription_next_billing, migration
-- 026), never a store an operator could forget to update.


-- -----------------------------------------------------------------------------
-- 2. STATE TRANSITION GUARD on app.subscriptions
--
--    Spec 5.2: transitions not listed are forbidden and the trigger refuses
--    them. The allowed set is written out pair by pair so the trigger IS the
--    transition table. Setting the same state again is allowed (T1's recorded
--    no-op for active, and idempotent repeats generally); the trigger also
--    stamps state_changed_at so callers cannot forget.
--
--    The trigger validates; it does not log. The ENGINE writes the
--    app.subscription_events row, because only the engine knows the cause
--    (the T-number and the decline detail). The verifier's replay of the
--    event stream is what catches a write that skipped the engine.
-- -----------------------------------------------------------------------------
create or replace function app.subscriptions_guard_state_transition()
returns trigger
language plpgsql
as $$
begin
    if new.state = old.state then
        return new;  -- idempotent repeat, including T1's active self-transition
    end if;

    if not (
        (old.state = 'active'      and new.state in ('past_due', 'card_update_required', 'cancelled', 'paused'))            -- T2 T3 T4 T5
     or (old.state = 'past_due'    and new.state in ('active', 'dunning', 'card_update_required', 'paused', 'cancelled'))   -- T6 T8 T9 T10 T11
     or (old.state = 'dunning'     and new.state in ('active', 'card_update_required', 'suspended', 'cancelled'))           -- T12 T13 T14 T15
     or (old.state = 'card_update_required' and new.state in ('active', 'suspended', 'cancelled'))                          -- T16 T17 T18
     or (old.state = 'paused'      and new.state in ('active', 'cancelled'))                                                -- T19 T20
     or (old.state = 'suspended'   and new.state in ('active', 'cancelled'))                                                -- T21 T22
    ) then
        raise exception
            'subscription % state transition % -> % is not in the spec section 5.2 table and is refused',
            old.id, old.state, new.state;
    end if;

    new.state_changed_at := now();
    return new;
end;
$$;

drop trigger if exists subscriptions_state_transition_guard on app.subscriptions;
create trigger subscriptions_state_transition_guard
    before update of state on app.subscriptions
    for each row
    execute function app.subscriptions_guard_state_transition();

comment on function app.subscriptions_guard_state_transition() is
    'Refuses any subscription state change not in spec section 5.2''s allowed '
    'set (T1 to T22), and stamps state_changed_at. cancelled is terminal by '
    'absence: no pair leads out of it. Added by migration 024.';


-- -----------------------------------------------------------------------------
-- 3. app.payment_credentials (spec 6.2 table 10, the FM5 defense)
--
--    Payment identity as ONE immutable record: card identity and its network
--    anchor live together, versioned, never as loose copies that can drift
--    apart. A card change NEVER edits a credential: it mints a NEW row through
--    a fresh cardholder-present transaction, repoints
--    subscriptions.credential_id, and retires the old row with a date.
--
--    Simulation note (Path B): synthetic credential rows use network_anchor
--    format 'sim:<brand>:<serial>' so the pre-flight coherence check
--    (migration 026) can parse the anchor's brand and catch a deliberately
--    corrupted row, which is exactly proof E of the S1 proof run.
-- -----------------------------------------------------------------------------
create table if not exists app.payment_credentials (
    id                       bigint generated always as identity primary key,
    member_id                bigint not null references app.members (id),
    brand                    text not null,
    last4                    text not null,
    expiry_month             int not null check (expiry_month between 1 and 12),
    expiry_year              int not null,
    token_reference          text not null,
    network_anchor           text,
    minted_by_demo_order_id  bigint references app.demo_orders (id),
    created_on               date not null,
    retired_on               date
);

create index if not exists payment_credentials_member_id_idx
    on app.payment_credentials (member_id);

comment on table app.payment_credentials is
    'One immutable payment credential per minted card (FM5 defense): identity '
    'and network anchor together, versioned. A card change mints a new row and '
    'retires the old one; nothing is ever edited in place. Added by 024.';

-- Immutability: the ONLY permitted update is setting retired_on, once, from
-- null to a date. Everything else about a credential is a fact of the CIT
-- that minted it and may never drift.
create or replace function app.payment_credentials_guard_immutable()
returns trigger
language plpgsql
as $$
begin
    if new.member_id      is distinct from old.member_id
    or new.brand          is distinct from old.brand
    or new.last4          is distinct from old.last4
    or new.expiry_month   is distinct from old.expiry_month
    or new.expiry_year    is distinct from old.expiry_year
    or new.token_reference is distinct from old.token_reference
    or new.network_anchor is distinct from old.network_anchor
    or new.minted_by_demo_order_id is distinct from old.minted_by_demo_order_id
    or new.created_on     is distinct from old.created_on then
        raise exception
            'payment credential % is immutable; a card change mints a NEW credential and retires this one',
            old.id;
    end if;
    if old.retired_on is not null
       and new.retired_on is distinct from old.retired_on then
        raise exception
            'payment credential % is already retired on %; retirement is written once',
            old.id, old.retired_on;
    end if;
    return new;
end;
$$;

drop trigger if exists payment_credentials_immutable_guard on app.payment_credentials;
create trigger payment_credentials_immutable_guard
    before update on app.payment_credentials
    for each row
    execute function app.payment_credentials_guard_immutable();

create or replace function app.payment_credentials_refuse_delete()
returns trigger
language plpgsql
as $$
begin
    raise exception
        'payment credentials are never deleted; retire them (retired_on) instead';
end;
$$;

drop trigger if exists payment_credentials_no_delete on app.payment_credentials;
create trigger payment_credentials_no_delete
    before delete on app.payment_credentials
    for each row
    execute function app.payment_credentials_refuse_delete();

-- Now the FK from subscriptions, deferred to here so the table existed first.
alter table app.subscriptions
    add column if not exists credential_id bigint references app.payment_credentials (id);

comment on column app.subscriptions.credential_id is
    'The stored credential renewals charge (spec 6.2 table 10). Null for '
    'seeded rows and Path B simulated rows until a credential exists.';


-- -----------------------------------------------------------------------------
-- 4. app.subscription_events, the append-only fact stream (spec 6.2 table 1)
--
--    Every member and engine action lands here; the verifier replays this
--    stream plus the outcome record to reproduce everything. Append-only by
--    trigger, the same discipline as finalized commission rows.
--
--    Deviation D2: effective_from_renewal_index and pause_until materialise
--    the consequence of a pause or billing-day change AT EVENT TIME, so the
--    schedule derivation is a pure replay of stored facts:
--      shift_months(n) = sum of pause_months over pause events whose
--                        effective_from_renewal_index is at most n
--      effective day(n) = newest billing_day_change with
--                         effective_from_renewal_index at most n, else the
--                         subscription's stored pick, else the anchor's day
-- -----------------------------------------------------------------------------
create table if not exists app.subscription_events (
    id                            bigint generated always as identity primary key,
    subscription_id               bigint not null references app.subscriptions (id),
    event_type                    text not null check (event_type in
                                    ('created', 'state_change', 'billing_day_change',
                                     'pause', 'resume', 'cancel_request', 'reactivation')),
    occurred_on                   date not null,   -- simulated or real clock date, UTC
    from_state                    text,
    to_state                      text,
    cause                         text,            -- transition id T1..T22 plus detail
    old_billing_day               int,
    new_billing_day               int,
    pause_months                  int check (pause_months in (1, 2)),
    pause_until                   date,            -- materialised: occurred_on + pause_months months
    effective_from_renewal_index  int,             -- materialised: first renewal index this event moves
    actor                         text,            -- 'engine', 'member', or a staff username
    billing_attempt_id            bigint           -- FK added in section 6, after billing_attempts
);

create index if not exists subscription_events_subscription_id_idx
    on app.subscription_events (subscription_id, occurred_on);

comment on table app.subscription_events is
    'Append-only fact stream of every member and engine action on a '
    'subscription (spec 6.2 table 1). The verifier replays this stream plus '
    'the outcome record to reproduce the engine''s entire behavior. Added by 024.';

create or replace function app.subscription_events_refuse_change()
returns trigger
language plpgsql
as $$
begin
    raise exception
        'app.subscription_events is append-only; history is never edited or deleted';
end;
$$;

drop trigger if exists subscription_events_append_only on app.subscription_events;
create trigger subscription_events_append_only
    before update or delete on app.subscription_events
    for each row
    execute function app.subscription_events_refuse_change();


-- -----------------------------------------------------------------------------
-- 5. app.billing_runs, the versioned batch (spec 6.2 table 2)
--
--    One row per tick, the commission-run discipline exactly: statuses
--    running, final, superseded; a rerun is a new row; the partial unique
--    index allows one final run per tick date.
--
--    Deviation D4: the close-out assertion columns of pipeline step 12 live
--    on the row, so a run row is its own run report: promo hook identity, the
--    MIT and 3-D Secure invariant, member-fault versus system-fault failure
--    totals reported separately (the section 6.2 table 5 principle), and the
--    count of attempts the FM2 reconciler resolved at open.
-- -----------------------------------------------------------------------------
create table if not exists app.billing_runs (
    id                     bigint generated always as identity primary key,
    tick_date              date not null,
    engine_version         text not null,
    clock_source           text not null check (clock_source in ('simulated', 'real')),
    status                 text not null check (status in ('running', 'final', 'superseded')),
    started_at             timestamptz,          -- honest wall time, bookkeeping only
    finished_at            timestamptz,          -- never a business date (spec section 10)
    subscriptions_due      int,
    attempts_made          int,
    succeeded              int,
    declined               int,
    attempts_reconciled    int,                  -- FM2: resolved at open by the reconciler
    member_fault_failures  int,                  -- reported separately by principle
    system_fault_failures  int,                  --   (spec 6.2 table 5)
    promo_hook_identity    boolean,              -- pipeline step 4 assertion: S1 must be true
    mit_invariant_ok       boolean,              -- section 8.4: no interactive authentication anywhere
    notes                  text
);

create unique index if not exists billing_runs_one_final_per_tick
    on app.billing_runs (tick_date)
    where status = 'final';

create index if not exists billing_runs_tick_date_idx on app.billing_runs (tick_date);

comment on table app.billing_runs is
    'One row per billing tick, versioned like commission runs: running, final, '
    'superseded; a rerun is a new row; one final per tick date. The assertion '
    'columns make the row its own run report (pipeline step 12). Added by 024.';


-- -----------------------------------------------------------------------------
-- 6. app.renewal_periods, the obligation ledger (spec 6.2 table 3)
--
--    Materialised at first attempt (rule resolved into data at billing time,
--    the migration 021 principle): the derived schedule DECIDES what is due,
--    and the moment the engine acts on cycle n it freezes what it decided
--    (date, coverage, amount, PV) into this row.
--
--    THE UNIQUE KEY (subscription_id, renewal_index) IS THE PER-CYCLE
--    IDEMPOTENCY LOCK (failure mode FM1, the double release). A second
--    billing of the same cycle is refused by the DATABASE, not by
--    discipline, the same pattern as the bridge's (demo_order_id,
--    volume_month) index. Proof A of the S1 proof run hammers this exact key.
-- -----------------------------------------------------------------------------
create table if not exists app.renewal_periods (
    id                   bigint generated always as identity primary key,
    subscription_id      bigint not null references app.subscriptions (id),
    renewal_index        int not null check (renewal_index >= 1),
    scheduled_date       date not null,        -- as derived at billing time, frozen
    covered_month_first  date not null,        -- first of the first covered month
    covered_months       int not null,         -- = frequency_months at billing time
    amount_cents         int not null,         -- priced at billing time, frozen
    pv_total             numeric(10,2) not null,
    outcome              text not null default 'open' check (outcome in
                           ('open', 'paid', 'unpaid', 'skipped_paused', 'void_cancelled')),
    unique (subscription_id, renewal_index)
);

create index if not exists renewal_periods_subscription_idx
    on app.renewal_periods (subscription_id, renewal_index);

comment on table app.renewal_periods is
    'The obligation ledger: one row per subscription per renewal cycle, '
    'materialised at first attempt with frozen date, coverage, amount and PV. '
    'unique (subscription_id, renewal_index) is the FM1 per-cycle idempotency '
    'lock. Added by 024.';

-- Outcome discipline: open may resolve once; resolved outcomes are frozen.
-- The unpaid periods stay unpaid forever (spec 12.6); paid is terminal by
-- decision 4.4's logic (succeeded is terminal on the payment side).
create or replace function app.renewal_periods_guard_outcome()
returns trigger
language plpgsql
as $$
begin
    if new.subscription_id is distinct from old.subscription_id
    or new.renewal_index   is distinct from old.renewal_index
    or new.scheduled_date  is distinct from old.scheduled_date
    or new.covered_month_first is distinct from old.covered_month_first
    or new.covered_months  is distinct from old.covered_months
    or new.amount_cents    is distinct from old.amount_cents
    or new.pv_total        is distinct from old.pv_total then
        raise exception
            'renewal period % is materialised data and frozen; only its outcome may resolve',
            old.id;
    end if;
    if new.outcome is distinct from old.outcome and old.outcome <> 'open' then
        raise exception
            'renewal period % outcome is % (resolved, frozen); it cannot become %',
            old.id, old.outcome, new.outcome;
    end if;
    return new;
end;
$$;

drop trigger if exists renewal_periods_outcome_guard on app.renewal_periods;
create trigger renewal_periods_outcome_guard
    before update on app.renewal_periods
    for each row
    execute function app.renewal_periods_guard_outcome();


-- -----------------------------------------------------------------------------
-- 7. app.billing_attempts, the attempt and retry ledger (spec 6.2 table 4)
--
--    One row per attempt; a retry is a new row (and, downstream, a NEW demo
--    order with a new order number, so every attempt survives as its own
--    receipt, spec section 7 point 3).
--
--    'dispatched' is the ONLY non-terminal outcome: sent, no answer recorded
--    yet. The FM2 reconciler exists precisely to hunt rows stuck there.
--
--    Deviation D3: ladder_step, decline_class and member_fault snapshot the
--    classification the attempt was judged by (classifications are
--    effective-dated data; the attempt carries its own answer forever).
-- -----------------------------------------------------------------------------
create table if not exists app.billing_attempts (
    id                 bigint generated always as identity primary key,
    run_id             bigint not null references app.billing_runs (id),
    renewal_period_id  bigint not null references app.renewal_periods (id),
    attempt_no         int not null check (attempt_no >= 1),
    attempt_kind       text not null check (attempt_kind in
                         ('initial', 'retry_soft', 'retry_ambiguous', 'retry_infra_immediate')),
    ladder_step        int,                  -- 0 initial, 1.. = position in the class ladder
    scheduled_for      date not null,
    demo_order_id      bigint references app.demo_orders (id),
    outcome            text not null default 'dispatched' check (outcome in
                         ('dispatched',
                          'succeeded', 'declined', 'processor_unreachable',
                          'preflight_failed', 'skipped_clipped')),
    decline_code       text,
    decline_class      text,
    member_fault       boolean,
    next_action        text,                 -- 'retry' | 'infra_immediate' | 'dunning' | 'card_update' | 'attention' | 'none'
    next_retry_date    date,                 -- when next_action is a retry: the surviving C1-clipped date
    next_retry_step    int,                  -- and the ladder step that date belongs to
    unique (renewal_period_id, attempt_no)
);

create index if not exists billing_attempts_run_id_idx on app.billing_attempts (run_id);
create index if not exists billing_attempts_outcome_idx on app.billing_attempts (outcome)
    where outcome = 'dispatched';

comment on table app.billing_attempts is
    'The attempt and retry ledger: one row per billing attempt, unique per '
    '(renewal_period_id, attempt_no). dispatched is the only non-terminal '
    'outcome and is what the FM2 reconciler sweeps for. Added by 024.';

-- Outcome discipline: dispatched resolves once to a terminal outcome; a
-- terminal outcome is frozen except next_action, which the engine may refine
-- (for example writing the retry date after classification).
create or replace function app.billing_attempts_guard_outcome()
returns trigger
language plpgsql
as $$
begin
    if new.run_id            is distinct from old.run_id
    or new.renewal_period_id is distinct from old.renewal_period_id
    or new.attempt_no        is distinct from old.attempt_no
    or new.attempt_kind      is distinct from old.attempt_kind
    or new.scheduled_for     is distinct from old.scheduled_for
    or new.demo_order_id     is distinct from old.demo_order_id then
        raise exception
            'billing attempt % identity fields are frozen; a correction is a new attempt row',
            old.id;
    end if;
    if old.outcome <> 'dispatched' and new.outcome is distinct from old.outcome then
        raise exception
            'billing attempt % outcome is % (terminal); it cannot become %',
            old.id, old.outcome, new.outcome;
    end if;
    return new;
end;
$$;

drop trigger if exists billing_attempts_outcome_guard on app.billing_attempts;
create trigger billing_attempts_outcome_guard
    before update on app.billing_attempts
    for each row
    execute function app.billing_attempts_guard_outcome();

-- The deferred FK from the event stream, now that attempts exist.
do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'subscription_events_billing_attempt_id_fkey'
    ) then
        alter table app.subscription_events
            add constraint subscription_events_billing_attempt_id_fkey
            foreign key (billing_attempt_id) references app.billing_attempts (id);
    end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 8. app.decline_classifications, the classification table as DATA (table 5)
--
--    Rows carry an effective-from date; changing a classification is an
--    INSERT of a new effective row, never an edit, so a past run's
--    classification is always reconstructible. Seeded in migration 025.
--
--    member_fault is the table's governing principle made a column: hard,
--    soft, ambiguous, ambiguous_contact, cancellation and auth are
--    member-side facts about a card or cardholder; infra, config, duplicate
--    and internal_config are OUR faults. Only member-fault classes may ever
--    consume the member's retry ladder, dunning clock, or auto-cancel
--    counter (enforced in migration 026's pipeline; reported separately on
--    every run row).
-- -----------------------------------------------------------------------------
create table if not exists app.decline_classifications (
    id                     bigint generated always as identity primary key,
    code                   text not null,   -- connector code, orchestrator status, or internal reason
    source                 text not null check (source in ('braintree', 'internal')),
    class                  text not null check (class in
                             ('hard', 'soft', 'ambiguous', 'ambiguous_contact',
                              'cancellation', 'cancellation_all', 'infra', 'config',
                              'duplicate', 'auth', 'internal_config')),
    max_scheduled_retries  int not null,
    member_fault           boolean not null,
    needs_human            boolean not null default false,
    effective_from         date not null,
    note                   text
);

create index if not exists decline_classifications_code_idx
    on app.decline_classifications (code, effective_from);

comment on table app.decline_classifications is
    'Decline classification as effective-dated DATA, never code (spec 6.2 '
    'table 5). A change is an insert of a new effective row; past runs stay '
    'reconstructible. member_fault gates every member clock. Added by 024.';

create or replace function app.decline_classifications_refuse_change()
returns trigger
language plpgsql
as $$
begin
    raise exception
        'app.decline_classifications is effective-dated; changing a classification is an INSERT of a new row, never an edit or delete';
end;
$$;

drop trigger if exists decline_classifications_append_only on app.decline_classifications;
create trigger decline_classifications_append_only
    before update or delete on app.decline_classifications
    for each row
    execute function app.decline_classifications_refuse_change();


-- -----------------------------------------------------------------------------
-- 9. app.retry_policies, the ladder as data (spec 6.2 table 6)
--
--    One row per class per step. Changing a cadence is a data change with an
--    effective date, not a code deploy. is_escalation_step marks the step
--    whose FAILURE enters dunning (spec 8.2): soft step 3 (the plus-8 retry),
--    ambiguous step 2, ambiguous_contact step 1. Seeded in migration 025.
-- -----------------------------------------------------------------------------
create table if not exists app.retry_policies (
    id                  bigint generated always as identity primary key,
    class               text not null,
    step                int not null check (step >= 0),   -- 0 = the immediate infra retry
    offset_days         int not null check (offset_days >= 0),
    is_escalation_step  boolean not null default false,
    effective_from      date not null,
    note                text
);

create index if not exists retry_policies_class_idx
    on app.retry_policies (class, effective_from, step);

comment on table app.retry_policies is
    'The retry ladder as effective-dated data (spec 6.2 table 6): offsets are '
    'days from the BILLING ATTEMPT date (ruling R5), clipped by rule C1 at '
    'dispatch time. Cadence changes are inserts, not deploys. Added by 024.';

create or replace function app.retry_policies_refuse_change()
returns trigger
language plpgsql
as $$
begin
    raise exception
        'app.retry_policies is effective-dated; changing a cadence is an INSERT of new rows, never an edit or delete';
end;
$$;

drop trigger if exists retry_policies_append_only on app.retry_policies;
create trigger retry_policies_append_only
    before update or delete on app.retry_policies
    for each row
    execute function app.retry_policies_refuse_change();


-- -----------------------------------------------------------------------------
-- 10. app.sim_clock and its advance log (spec 6.2 table 7, section 10)
--
--     The engine NEVER calls now() or reads the wall clock for business
--     dates; every date in the pipeline reads the clock the run was opened
--     with. Wall-clock timestamps (started_at, finished_at) remain honest
--     wall time, labelled bookkeeping, never business dates.
--
--     Deviation D1: the column is clock_date because current_date is a
--     reserved word in PostgreSQL.
-- -----------------------------------------------------------------------------
create table if not exists app.sim_clock (
    singleton     boolean primary key default true check (singleton),
    clock_date    date not null,
    engine_epoch  date not null
);

comment on table app.sim_clock is
    'The simulated clock, a single row (spec section 10). Business dates in '
    'the engine come from HERE, never from now(). Advanced only by '
    'app.fn_billing_tick. engine_epoch (deviation D7 of migration 026) is '
    'the floor below which no cycle is ever gathered: seeded subscriptions '
    'are anchored years back and their history is owned by SEEDED orders, '
    'so without the epoch the first tick after evolving 1,820 seeded rows '
    'would catch-up-bill two years of history. Added by 024.';

create table if not exists app.sim_clock_advances (
    id               bigint generated always as identity primary key,
    from_date        date,
    to_date          date not null,
    advanced_by_run  bigint references app.billing_runs (id),
    advanced_at      timestamptz not null default now()   -- bookkeeping wall time
);

comment on table app.sim_clock_advances is
    'Append-only log of every clock advance: from, to, and the run that did '
    'it. Added by 024.';

create or replace function app.sim_clock_advances_refuse_change()
returns trigger
language plpgsql
as $$
begin
    raise exception 'app.sim_clock_advances is append-only';
end;
$$;

drop trigger if exists sim_clock_advances_append_only on app.sim_clock_advances;
create trigger sim_clock_advances_append_only
    before update or delete on app.sim_clock_advances
    for each row
    execute function app.sim_clock_advances_refuse_change();


-- -----------------------------------------------------------------------------
-- 11. app.sim_outcome_scripts, the Path B simulated processor (table 8)
--
--     One row per (subscription, renewal index, attempt number) with the
--     scripted outcome. ANY ATTEMPT WITHOUT A SCRIPT ROW SUCCEEDS: that
--     default keeps scripts small and the happy path implicit (spec
--     section 10). Outcomes:
--       succeeded              the processor confirms payment
--       declined               with decline_code, classified by the data table
--       processor_unreachable  infra: one immediate uncounted retry (R5)
--       not_received           the processor NEVER SAW the dispatch: this is
--                              the deliberate FM2 orphan. The reconciler
--                              consumes the row (consumed = true) and
--                              re-dispatches; the re-dispatch consults the
--                              remaining scripts, so a single not_received
--                              row strands exactly once, deterministically.
-- -----------------------------------------------------------------------------
create table if not exists app.sim_outcome_scripts (
    id               bigint generated always as identity primary key,
    subscription_id  bigint not null references app.subscriptions (id),
    renewal_index    int not null,
    attempt_no       int not null,
    outcome          text not null check (outcome in
                       ('succeeded', 'declined', 'processor_unreachable', 'not_received')),
    decline_code     text,
    consumed         boolean not null default false,
    note             text,
    unique (subscription_id, renewal_index, attempt_no)
);

comment on table app.sim_outcome_scripts is
    'The Path B simulated processor (spec section 10): deterministic scripted '
    'outcomes per attempt; no row means succeeded. not_received is the FM2 '
    'orphan lever, one-shot via the consumed flag. Added by 024.';


-- -----------------------------------------------------------------------------
-- 12. app.billing_schedule, the staff-set daily schedule (table 9, R7)
--
--     A single row, edited only through the staff console's Edge Function,
--     honored server-side (section 9A: the pg_cron poll reads this; the cron
--     tick is a convenience alarm, never the owner of the work). When enabled
--     is false or no time is set, the engine runs manually only, which is
--     also this row's shipped default.
-- -----------------------------------------------------------------------------
create table if not exists app.billing_schedule (
    singleton    boolean primary key default true check (singleton),
    enabled      boolean not null default false,
    run_at_time  time,
    timezone     text not null default 'UTC',
    updated_by   text,
    updated_at   timestamptz not null default now()
);

insert into app.billing_schedule (singleton, enabled)
values (true, false)
on conflict (singleton) do nothing;

comment on table app.billing_schedule is
    'The staff-configured daily run schedule (ruling R7, spec 9A). Single '
    'row; disabled by default; honored server-side by the scheduler poll. '
    'Added by 024.';


-- -----------------------------------------------------------------------------
-- 13. WIDEN app.demo_orders.created_by_channel (spec 6.3)
--
--     Engine-created rows are channel 'renewal_engine' and set created_at
--     from the run's TICK date, never now(), so month attribution (bridge
--     policy P3) reads the clock the engine ran on. Items written by the
--     engine carry mode 'sub' plus per-line covered_months (1, 2, 3 or 6)
--     inside the existing items jsonb; migration 027's bridge amendment
--     reads it. No column change is needed for items: jsonb already carries
--     what the server priced.
-- -----------------------------------------------------------------------------
alter table app.demo_orders drop constraint if exists demo_orders_created_by_channel_check;
alter table app.demo_orders
    add constraint demo_orders_created_by_channel_check
    check (created_by_channel in ('shop', 'staff_console', 'renewal_engine'));

comment on column app.demo_orders.created_by_channel is
    'shop, staff_console, or renewal_engine (widened by migration 024). '
    'renewal_engine rows carry created_at = the billing run''s tick date, so '
    'bridge policy P3 month attribution reads the engine''s clock.';


-- -----------------------------------------------------------------------------
-- 14. ROW LEVEL SECURITY: ON for every new table, ZERO policies
--
--     Same posture as app.demo_orders (migration 010): no view reads these
--     tables, so nothing but the service role and the owner touches them.
--     Belt-and-suspenders revokes are guarded so this file also runs on
--     plain PostgreSQL (the local proof rig) without Supabase roles.
-- -----------------------------------------------------------------------------
alter table app.payment_credentials     enable row level security;
alter table app.subscription_events     enable row level security;
alter table app.billing_runs            enable row level security;
alter table app.renewal_periods         enable row level security;
alter table app.billing_attempts        enable row level security;
alter table app.decline_classifications enable row level security;
alter table app.retry_policies          enable row level security;
alter table app.sim_clock               enable row level security;
alter table app.sim_clock_advances      enable row level security;
alter table app.sim_outcome_scripts     enable row level security;
alter table app.billing_schedule        enable row level security;

do $$
declare
    t text;
begin
    foreach t in array array[
        'payment_credentials', 'subscription_events', 'billing_runs',
        'renewal_periods', 'billing_attempts', 'decline_classifications',
        'retry_policies', 'sim_clock', 'sim_clock_advances',
        'sim_outcome_scripts', 'billing_schedule']
    loop
        if exists (select 1 from pg_roles where rolname = 'anon') then
            execute format('revoke all on app.%I from anon', t);
        end if;
        if exists (select 1 from pg_roles where rolname = 'authenticated') then
            execute format('revoke all on app.%I from authenticated', t);
        end if;
    end loop;
end
$$;


-- =============================================================================
-- VERIFICATION QUERIES (the 019/020/021 convention: run these after applying)
-- =============================================================================
-- 1. Eleven new relations exist (ten spec tables plus the advance log):
--      select count(*) from pg_tables where schemaname = 'app'
--       and tablename in ('payment_credentials','subscription_events',
--         'billing_runs','renewal_periods','billing_attempts',
--         'decline_classifications','retry_policies','sim_clock',
--         'sim_clock_advances','sim_outcome_scripts','billing_schedule');
--    Expect 11.
-- 2. app.subscriptions gained exactly six columns; every pre-existing row is
--    backfilled monthly/day-1/anchored at start_month, and no row has a null
--    anchor:
--      select count(*) from app.subscriptions where billing_anchor_date is null;
--    Expect 0.
-- 3. The FM1 lock exists:
--      select indexname from pg_indexes where schemaname='app'
--       and tablename='renewal_periods';
--    Expect the unique (subscription_id, renewal_index) constraint index.
-- 4. The state guard refuses a forbidden pair (run inside a rolled-back
--    transaction): update app.subscriptions set state='suspended' where
--    state='active' limit 1  ->  must raise (active -> suspended is not in
--    the table; suspension only ever comes from dunning or
--    card_update_required).
-- 5. demo_orders channel check admits 'renewal_engine' and still refuses
--    anything else.
-- 6. Zero rows of data were touched in any pre-existing table other than the
--    app.subscriptions backfill columns.
-- =============================================================================
