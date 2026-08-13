-- Migration 001: schema app plus the nine core tables
-- Purpose: create schema app and every table of SCHEMA-SPEC.md section 1
--          (members, products, subscriptions, orders, order_lines, ranks,
--          commission_runs, run_member_results, commission_lines) with all
--          constraints and indexes. Tables live in schema app, never public.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)

create schema if not exists app;

-- ---------------------------------------------------------------------------
-- app.members
-- The sponsor_id adjacency IS the genealogy (decision 2026-08-13).
-- member_code is the ONLY identifier any public view may expose.
-- ---------------------------------------------------------------------------
create table app.members (
    id            bigint generated always as identity primary key,
    member_code   text not null,
    display_name  text not null,
    email         text not null,
    sponsor_id    bigint references app.members (id),
    enrolled_on   date not null,
    status        text not null default 'active'
                  check (status in ('active', 'closed')),
    constraint members_member_code_key unique (member_code)
);

create index members_sponsor_id_idx on app.members (sponsor_id);

-- ---------------------------------------------------------------------------
-- app.products
-- Catalog of digital AI agents sold as monthly subscriptions.
-- tier 'domain' = 100.00 / 100 volume points, tier 'support' = 50.00 / 50.
-- commissionable_value stays null in v1 (CV derived as 80 percent of SV at
-- member-month level); the column exists for forward compatibility.
-- ---------------------------------------------------------------------------
create table app.products (
    id                    bigint generated always as identity primary key,
    sku                   text not null,
    name                  text not null,
    tier                  text not null check (tier in ('domain', 'support')),
    price                 numeric(10,2) not null,
    volume_points         numeric(10,2) not null,
    commissionable_value  numeric(10,2),
    constraint products_sku_key unique (sku)
);

-- ---------------------------------------------------------------------------
-- app.subscriptions
-- One row per member-agent subscription. start_month is the first of the
-- month billing begins; cancel_month is the first of the month it STOPS
-- billing (exclusive end), null while active. Active in month m when
-- start_month <= m < cancel_month (or cancel_month is null).
-- ---------------------------------------------------------------------------
create table app.subscriptions (
    id            bigint generated always as identity primary key,
    member_id     bigint not null references app.members (id),
    product_id    bigint not null references app.products (id),
    quantity      integer not null default 1 check (quantity > 0),
    start_month   date not null,
    cancel_month  date
);

create index subscriptions_member_id_idx on app.subscriptions (member_id);

-- ---------------------------------------------------------------------------
-- app.orders
-- volume_month is ALWAYS the first day of the month the order counts toward,
-- stamped at creation (UTC) and never recomputed. v1 seeds only
-- buyer_role 'member' and status 'completed'.
-- ---------------------------------------------------------------------------
create table app.orders (
    id           bigint generated always as identity primary key,
    member_id    bigint not null references app.members (id),
    buyer_role   text not null default 'member'
                 check (buyer_role in ('member', 'preferred_customer', 'retail_customer')),
    ordered_at   timestamptz not null,
    volume_month date not null,
    status       text not null check (status in ('completed', 'refunded'))
);

create index orders_member_id_volume_month_idx on app.orders (member_id, volume_month);
create index orders_volume_month_idx on app.orders (volume_month);

-- ---------------------------------------------------------------------------
-- app.order_lines
-- unit_price and unit_volume are copied from the product at order time so
-- history stays immutable when the catalog changes. Line SV = quantity * unit_volume.
-- ---------------------------------------------------------------------------
create table app.order_lines (
    id           bigint generated always as identity primary key,
    order_id     bigint not null references app.orders (id),
    product_id   bigint not null references app.products (id),
    quantity     integer not null check (quantity > 0),
    unit_price   numeric(10,2) not null,
    unit_volume  numeric(10,2) not null
);

create index order_lines_order_id_idx on app.order_lines (order_id);

-- ---------------------------------------------------------------------------
-- app.ranks
-- Qualification RULES live in COMP-PLAN-SPEC.md and the engine, not in data;
-- this table only names the ranks and their paid depths. Seeded in 004.
-- ---------------------------------------------------------------------------
create table app.ranks (
    rank_code   text primary key,
    rank_name   text not null,
    sort_order  int not null,
    paid_depth  int not null
);

-- ---------------------------------------------------------------------------
-- app.commission_runs
-- A rerun of the same period is a NEW row; the old run flips to 'superseded'
-- with its lines untouched. Only one run per period may be 'final'.
-- ---------------------------------------------------------------------------
create table app.commission_runs (
    id            bigint generated always as identity primary key,
    period        date not null,
    spec_version  text not null,
    status        text not null check (status in ('running', 'final', 'superseded')),
    started_at    timestamptz,
    finished_at   timestamptz,
    notes         text,
    total_sv      numeric(14,2),
    total_cv      numeric(14,2),
    total_payout  numeric(14,2),
    members_paid  int
);

create unique index commission_runs_one_final_per_period_idx
    on app.commission_runs (period)
    where status = 'final';

-- ---------------------------------------------------------------------------
-- app.run_member_results
-- One row per member per run. cumulative_sv is reserved (null in v1).
-- ---------------------------------------------------------------------------
create table app.run_member_results (
    run_id         bigint not null references app.commission_runs (id),
    member_id      bigint not null references app.members (id),
    sv             numeric(12,2) not null,
    cv             numeric(12,2) not null,
    tv             numeric(14,2) not null,
    is_active      boolean not null,
    rank_earned    text not null references app.ranks (rank_code),
    paid_depth     int not null,
    total_earned   numeric(12,2) not null,
    cumulative_sv  numeric(14,2),
    primary key (run_id, member_id)
);

-- ---------------------------------------------------------------------------
-- app.commission_lines (the statement)
-- level is plain tree distance earner -> source, 1..5. amount is rounded half
-- up at the line level; totals are sums of rounded lines, never re-rounded.
-- ---------------------------------------------------------------------------
create table app.commission_lines (
    id                bigint generated always as identity primary key,
    run_id            bigint not null references app.commission_runs (id),
    earner_id         bigint not null references app.members (id),
    source_member_id  bigint not null references app.members (id),
    level             int not null check (level between 1 and 5),
    source_cv         numeric(12,2) not null,
    rate              numeric(5,4) not null,
    amount            numeric(12,2) not null,
    payout_type       text not null default 'unilevel_level_pay'
);

create index commission_lines_run_id_earner_id_idx
    on app.commission_lines (run_id, earner_id);
