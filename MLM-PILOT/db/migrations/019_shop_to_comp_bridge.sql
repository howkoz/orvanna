-- =============================================================================
-- Migration 019: the bridge from the live shop to the compensation engine
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-15
-- Author:  mlm-comp-engineer
-- Design:  DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md
--          Plain path:
--          C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md
--
-- STATUS: APPLIED 2026-08-16 to the live project (mlm-pilot, oiyibdczkokegaxkwulv)
--         as migration shop_to_comp_bridge_019, on Howard's straight-to-production
--         ruling. All seven policy decisions in section 4 of the design doc were
--         answered by Howard by 2026-08-16 and every constant below matches his
--         rulings; see MLM-PILOT\docs\decisions\2026-08-16-bridge-seven-decisions.md.
--         From this point this file is FROZEN: applied SQL is never edited, a
--         follow-up change is a new numbered migration.
--         WORLD MOVED BETWEEN WRITING AND APPLYING, recorded rather than hidden:
--         migrations 018 (tax integrity hardening), 022 (refunds) and 023 (refund
--         guard fix) were applied BEFORE this file. Migration 022 added 'refunded'
--         and 'partially_refunded' payment states, so policy P8's opening sentence
--         ("no refunded state at all") describes the world of 2026-08-15, not
--         today. The bridge is unaffected: the state gate is 'succeeded' only, so
--         a refunded order simply produces no volume.
--
-- Acronym key, spelled out once: Personal Volume (PV), Sales Volume (SV),
-- Commissionable Volume (CV), Team Volume (TV), Stock Keeping Unit (SKU, a short
-- code naming one sellable thing), Coordinated Universal Time (UTC), Row Level
-- Security (RLS), JavaScript Object Notation (JSON).
--
-- -----------------------------------------------------------------------------
-- WHAT THIS FIXES
-- -----------------------------------------------------------------------------
-- The live shop writes to app.demo_orders. Migration 010's own header says that
-- table "feeds nothing". Every commission this project has ever computed came
-- from seeded data; no real purchase has ever produced a cent. Separately,
-- app.products permits only the tiers 'domain' and 'support', so the four
-- bundles and packs the shop sells cannot even be stored as products the engine
-- can see, and the two catalogues share no join key at all (the shop says
-- 'payment', the engine says 'AGT-D-001').
--
-- This migration adds the missing link, the missing tiers, and the missing join,
-- and nothing else. It does NOT change one line of app.fn_run_commission. The
-- bridge TRANSLATES a paid checkout into ordinary rows in app.orders and
-- app.order_lines, the exact shape the engine has always read, and then gets out
-- of the way. That is deliberate: the engine keeps one input shape, so the
-- ten-member worked example in db\comp\002_worked_example_test.sql still governs
-- everything the engine does.
--
-- -----------------------------------------------------------------------------
-- THIS DELIBERATELY REVERSES A PROPERTY OF MIGRATION 010. READ THIS.
-- -----------------------------------------------------------------------------
-- Migration 010 states: "ENGINE UNTOUCHED: no foreign key into app.orders ...
-- Nothing that computes app.commission_runs, app.run_member_results, or
-- app.commission_lines gains a new input, so the finalized-months invariant
-- holds by construction." Section 13 item 11 of DOCUMENTATION\02-DATA-MODEL.md
-- names the risk exactly: "that a future change could quietly make live
-- demonstration orders an input to commission math".
--
-- This migration IS that change, and it is made openly rather than quietly. The
-- finalized-months invariant is now protected by a rule instead of by an absence:
-- POLICY P3 below refuses to write into any period that already has a final run.
--
-- AND THAT RULE HAS NO DATABASE BACKSTOP IN THIS FILE. SAID PLAINLY (verifier
-- M5). There are NO triggers of any kind on app.orders, app.order_lines or
-- app.products. The immutability triggers exist only on app.commission_lines and
-- app.run_member_results, and they protect the OUTPUT of a run, never its input.
-- So after this migration alone, the invariant depends entirely on one CASE
-- branch inside one function. Any direct INSERT into app.orders, by a script, by
-- a future function, or by hand, can put volume into a finalized month, and only
-- a re-run would ever reveal it. The published statement itself stays immutable,
-- so this is not a breach of the core promise, but it is much weaker than the
-- rest of this project's guarantees.
--
-- MIGRATION 021 CLOSES THIS. It adds orders_no_write_into_finalized_period, a
-- trigger that rejects any insert or volume_month change into a period with a
-- final run. If 019 is applied without 021, the sentence above is the accurate
-- description of what protects a closed month.
--
-- RELATED, AND STILL OPEN (verifier L3): policy P3 blocks a period whose run is
-- 'final'. A period whose run is 'running' is still writable, so bridging in the
-- window between fn_run_commission and fn_finalize_run would leave the run's
-- stored totals disagreeing with the month's orders, with no error raised.
-- Section 7's usage note says to bridge first, which is right, but nothing
-- enforces the order. Left as a documented caution rather than a hard block on
-- purpose: a run abandoned in 'running' status would otherwise wedge that month
-- shut permanently, which is a worse failure than the one being prevented.
--
-- =============================================================================
-- POLICY SWITCHES. EVERY ASSUMPTION IS HERE, NAMED, IN ONE PLACE.
-- =============================================================================
-- None of the nine policies below is answered by docs\COMP-PLAN-SPEC.md. Each is
-- a decision for Howard, written up with options and consequences in section 4 of
-- 09-LINKING-SHOP-TO-COMP.md. What is implemented here is the RECOMMENDED option
-- in each case. To change one, change the named constant in
-- app.fn_bridge_demo_orders and re-read the matching section of the design doc.
--
--   P1  STATE GATE = 'succeeded' only.
--       Only a payment the processor confirmed, with an exact integer amount
--       match against total_cents, produces volume. 'created', 'processing',
--       'abandoned' and 'failed' produce nothing. Design doc decision 4.4.
--
--   P2  ATTRIBUTION = demo_orders.member_id, buyer_role 'member'.
--       Volume books to the member whose code was typed. A paid order naming no
--       member pays nobody and is reported, never re-homed to a house account.
--       The buyer earns NOTHING from their own purchase; their upline does.
--       Design doc sections 6 and decision 4.7.
--       KNOWN APPROXIMATION: the checkout cannot tell a member buying for
--       themselves from a guest using a member's code, because it deliberately
--       collects no buyer identity. Both are tagged buyer_role 'member'. The
--       money is identical either way; only the audit tag is approximate. The
--       proper fix is a checkout question, not a database change.
--
--   P3  VOLUME MONTH = month of demo_orders.created_at, in UTC.
--       Matches the engine's existing stamp-at-creation rule (spec section 6.3).
--       If any period an order would land in already has a FINAL commission run,
--       the WHOLE order is refused and reported. It is never silently shifted to
--       an open month, and a published statement is never re-opened to absorb it.
--       Design doc decision 4.5.
--
--   P4  ONE-TIME PURCHASES ARE SPREAD OVER 10 MONTHS.
--       The house rule is that a one-time price is ten times the monthly price
--       with ten times the PV, i.e. ten months paid up front. Every threshold in
--       the plan (qualification 100, Leader TV 2,500, Executive TV 40,000) is a
--       PER-MONTH number, so ten months of volume is spread across ten months.
--       Implemented as ten order rows at one tenth of the price and one tenth of
--       the volume each; ten slices add back exactly to the one-time figures, and
--       every catalogue value divides by ten with no remainder, so no rounding is
--       created. Set v_spread_one_time to false for the all-at-once alternative.
--       Design doc decision 4.1.
--       CONSEQUENCE TO EXPECT: months two through ten carry volume with no money
--       arriving in them. The money already arrived in month one. Any single
--       month's reconciliation must say so.
--
--   P5  A PACK IS ITS OWN PRODUCT. Children are never exploded.
--       PV equals dollars is the plan's one invariant, and only this option keeps
--       it true for all four items. Exploding would double-count, and for the
--       Manager Agent specifically would credit 150 of child volume against a
--       $200.00 sale. Design doc decisions 4.2 and 4.6.
--
--   P6  ONE-TIME MODE NEEDS NO NEW PRODUCTS.
--       app.order_lines already copies unit_price and unit_volume at order time,
--       so a one-time sale is the same product with different copied values. The
--       mode is recorded on the line in the new billing_mode column. Sixteen
--       products, not thirty-two.
--
--   P7  IDEMPOTENCY = unique (demo_order_id, volume_month) on app.orders.
--       Running the bridge twice cannot produce two orders for one sale, exactly
--       as demo_orders.order_number already stops a double-submitted checkout
--       becoming two payments.
--
--   P8  REFUNDS: NO REVERSAL PATH EXISTS, AND NONE IS INVENTED HERE.
--       app.demo_orders.payment_status has no refunded state at all, so a refund
--       cannot currently be represented. The bridge only ever INSERTS; it never
--       updates or deletes an order it wrote. After finalization there is no rule
--       yet, and the member booklet already promises one will be published
--       before refunds exist. Design doc decision 4.3.
--
--       IF A REFUND ARRIVES BEFORE THAT MONTH'S RUN IS FINALIZED, the
--       operational fix is to delete the bridged rows and run the month again,
--       which is safe because nothing is published. DELETE BOTH TABLES, IN THIS
--       ORDER:
--
--         delete from app.order_lines
--          where order_id in (select id from app.orders
--                              where demo_order_id = <id>);
--         delete from app.orders where demo_order_id = <id>;
--
--       CORRECTED 2026-08-15 after the verifier's finding M1. The earlier
--       wording said only "delete the bridged rows", which is a trap: the
--       'skip: already bridged' test below looks at app.orders alone. Deleting
--       the LINES but leaving the ORDER leaves a row with no lines that
--       contributes 0.00 Sales Volume, and every later bridge run reports
--       'skip: already bridged' and never restores it. Volume would be lost
--       permanently with nothing anywhere reporting a problem. The foreign key
--       from order_lines.order_id forces the safe ordering only in the other
--       direction, so it cannot save you here.
--
--       The verdict list below now also detects that exact orphan state and
--       reports it as an ERROR rather than silently skipping it.
--
--   P9  THE $25.00 PRIORITY ACTIVATION FEE IS NOT COMMISSIONABLE.
--       It is not a product, carries no PV, and the compensation specification
--       never mentions it. The bridge never books it. This makes today's
--       accidental answer an explicit one. Tax is likewise never volume.
--
-- =============================================================================
-- RUN ORDER: after migrations 001..017. Independent of the proposed 018.
-- Run as the service role or database owner; RLS blocks every other role.
-- =============================================================================
--
-- -----------------------------------------------------------------------------
-- KNOWN FOLLOW-UP, FOUND WHILE WRITING THIS AND RECORDED RATHER THAN FIXED
-- -----------------------------------------------------------------------------
-- db\comp\003_reset_app_data.sql TRUNCATEs app.products. Once app.shop_sku_map
-- exists it references app.products, and Postgres refuses to truncate a table
-- while a referencing table is absent from the same TRUNCATE list. That reset
-- script will therefore fail the first time it is run after this migration is
-- applied, with a clear error naming app.shop_sku_map.
--
-- The fix is one line PLUS A POST-RESET STEP, and the second half matters more
-- (verifier M4). Adding app.shop_sku_map to the truncate list makes the truncate
-- succeed, but it leaves a worse state than it found: the reseed restores only
-- the twelve seeded products, so the four bundle and pack rows are gone and all
-- sixteen map rows are gone with them. The bridge would then answer
-- 'skip: unmapped shop sku' for EVERY order. That is at least loud rather than
-- silent, but the system is quietly non-functional until somebody notices.
--
-- THE COMPLETE PROCEDURE AFTER ANY RESET:
--   1. add app.shop_sku_map to the truncate list in 003_reset_app_data.sql
--   2. run the reset and the seed loaders as usual
--   3. RE-RUN SECTIONS 2 AND 3 OF THIS MIGRATION (the four product rows and the
--      sixteen map rows). Both are written with ON CONFLICT DO NOTHING, so
--      re-running them is safe and repeatable.
--   4. if migration 020 is applied, re-run its steps 2 and 3 as well (the GW-000
--      row and the retention ledger), for the same reason.
--
-- The one-line edit is deliberately NOT made here, because the reset script must
-- keep working BEFORE this migration is applied, and a table that does not exist
-- yet cannot be truncated. Apply 019 and edit 003 in the same change, or neither.
--
-- app.orders gaining a foreign key to app.demo_orders creates no such problem:
-- app.orders is the child, so truncating it needs nothing added.
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- 1. Widen the product tier constraint (the blocker, stated exactly)
--
--    Live definition before this migration:
--      CHECK ((tier = ANY (ARRAY['domain'::text, 'support'::text])))
--
--    tier is a LABEL. No arithmetic anywhere reads it: app.fn_run_commission
--    never mentions the column, and SV comes from order_lines.unit_volume.
--    Widening it therefore changes no money, it only stops the storefront from
--    being able to sell something the engine cannot represent.
-- -----------------------------------------------------------------------------
alter table app.products drop constraint if exists products_tier_check;

alter table app.products
    add constraint products_tier_check
    check (tier in ('domain', 'support', 'bundle', 'pack'));

comment on column app.products.tier is
    'Product family label: domain, support, bundle, pack. Read by nothing that '
    'computes money; the engine reads order_lines.unit_volume. Widened from '
    '(domain, support) by migration 019 so bundles and packs can exist at all.';


-- -----------------------------------------------------------------------------
-- 2. The four missing products, at their MONTHLY price and MONTHLY PV
--
--    Per policy P6, the one-time versions are NOT separate products: a one-time
--    sale is the same product with ten times the price and PV copied onto the
--    order line. Values are taken verbatim from www\js\catalog.js, which
--    functions\_shared\pricing.ts already mirrors under a lockstep check.
--
--    commissionable_value stays null exactly as it is on the other twelve rows:
--    version 1 derives CV as 80 percent of SV at the member-month level.
-- -----------------------------------------------------------------------------
insert into app.products (sku, name, tier, price, volume_points, commissionable_value)
values
    ('AGT-B-001', 'Manager Agent',       'bundle', 200.00, 200.00, null),
    ('AGT-P-001', 'Ignition Pack',       'pack',   200.00, 200.00, null),
    ('AGT-P-002', 'Momentum Pack',       'pack',   400.00, 400.00, null),
    ('AGT-P-003', 'Constellation Pack',  'pack',   800.00, 800.00, null)
on conflict (sku) do nothing;


-- -----------------------------------------------------------------------------
-- 3. app.shop_sku_map: the join that has never existed
--
--    The shop calls a product 'constellation'. The engine calls it 'AGT-P-003'.
--    There is no column in either table connecting them, so even with the tiers
--    widened a bridge would have nothing to join on.
--
--    This is a TABLE rather than a column on app.products for one reason: an
--    unmapped shop SKU must be a loud failure. The bridge refuses a whole order
--    that names a SKU it cannot map, rather than silently crediting part of it.
--
--    RLS on with ZERO policies, the same posture as app.run_level_map and
--    app.demo_orders: no view reads this table, so nothing but the service role
--    and the table owner should ever see it.
-- -----------------------------------------------------------------------------
create table if not exists app.shop_sku_map (
    shop_sku    text primary key,
    product_id  bigint not null references app.products (id),
    note        text
);

comment on table app.shop_sku_map is
    'Joins the storefront catalogue (www/js/catalog.js SKUs) to app.products. '
    'Added by migration 019. An unmapped SKU makes the bridge refuse the whole '
    'order rather than credit part of it.';

insert into app.shop_sku_map (shop_sku, product_id, note)
select v.shop_sku, p.id, v.note
from (values
    ('payment',       'AGT-D-001', 'domain agent, 100.00 / 100 PV'),
    ('shipping',      'AGT-D-002', 'domain agent, 100.00 / 100 PV'),
    ('pricing',       'AGT-D-003', 'domain agent, 100.00 / 100 PV'),
    ('inventory',     'AGT-D-004', 'domain agent, 100.00 / 100 PV'),
    ('marketing',     'AGT-D-005', 'domain agent, 100.00 / 100 PV'),
    ('tax',           'AGT-D-006', 'domain agent, 100.00 / 100 PV'),
    ('engineer',      'AGT-S-001', 'support agent, 50.00 / 50 PV'),
    ('qa',            'AGT-S-002', 'support agent, 50.00 / 50 PV'),
    ('secretary',     'AGT-S-003', 'support agent, 50.00 / 50 PV'),
    ('executive',     'AGT-S-004', 'support agent, 50.00 / 50 PV'),
    ('accounting',    'AGT-S-005', 'support agent, 50.00 / 50 PV'),
    ('care',          'AGT-S-006', 'support agent, 50.00 / 50 PV'),
    ('manager',       'AGT-B-001', 'bundle, parent PV only (policy P5)'),
    ('ignition',      'AGT-P-001', 'pack, parent PV only (policy P5)'),
    ('momentum',      'AGT-P-002', 'pack, parent PV only (policy P5)'),
    ('constellation', 'AGT-P-003', 'pack, parent PV only (policy P5)')
) as v(shop_sku, product_sku, note)
join app.products p on p.sku = v.product_sku
on conflict (shop_sku) do nothing;

alter table app.shop_sku_map enable row level security;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.shop_sku_map from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.shop_sku_map from authenticated;
    end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 4. app.order_lines.billing_mode: which mode the sale actually was
--
--    NOT NULL with default 'sub'. All 10,332 existing rows are subscription
--    orders generated from app.subscriptions, so the default is correct history
--    and no back-fill is needed.
--
--    This column carries no arithmetic. SV is still quantity * unit_volume. It
--    exists so a statement can explain WHY a line carries 100 of volume against
--    a 1,000.00 payment: it is one of ten monthly slices (policy P4).
-- -----------------------------------------------------------------------------
alter table app.order_lines
    add column if not exists billing_mode text not null default 'sub';

alter table app.order_lines drop constraint if exists order_lines_billing_mode_check;

alter table app.order_lines
    add constraint order_lines_billing_mode_check
    check (billing_mode in ('sub', 'one'));

comment on column app.order_lines.billing_mode is
    'sub = monthly subscription, one = one-time purchase. Recording only: SV is '
    'quantity * unit_volume regardless. A one-time purchase appears as ten '
    'monthly slices under policy P4 of migration 019.';


-- -----------------------------------------------------------------------------
-- 5. app.orders.demo_order_id: the link, and the idempotency key
--
--    This single column does three jobs:
--      a. IDEMPOTENCY. The partial unique index on (demo_order_id, volume_month)
--         means running the bridge twice cannot produce two orders for one sale.
--         The pair, not the id alone, because policy P4 emits ten rows for one
--         one-time sale, one per month.
--      b. AUDIT TRAIL. From any commission line you can now walk
--         earner -> source member -> order -> demo order -> payment_reference.
--         Without it a bridged order is indistinguishable from a seeded one.
--      c. PROVENANCE. demo_order_id is null on all 10,332 seeded rows and not
--         null on every live one, so "how much of this month came from real
--         sales" is a one-line query forever.
-- -----------------------------------------------------------------------------
alter table app.orders
    add column if not exists demo_order_id bigint references app.demo_orders (id);

create unique index if not exists orders_demo_order_volume_month_idx
    on app.orders (demo_order_id, volume_month)
    where demo_order_id is not null;

comment on column app.orders.demo_order_id is
    'The live checkout receipt this order was bridged from (migration 019), or '
    'null for seeded orders. Unique per (demo_order_id, volume_month), which is '
    'what makes re-running the bridge harmless.';


-- =============================================================================
-- 6. THE BRIDGE ITSELF
--
--    app.fn_bridge_demo_orders(p_commit boolean default false)
--
--    Defaults to REPORT ONLY. Called with no argument it writes nothing and
--    returns one row per (demo order, volume month) with a verdict explaining
--    exactly what would happen and why. Call it with true to actually write.
--
--    Set-based throughout, no per-order loop, in the same style as the engine.
--
--    VERDICTS
--      bridge                      would be written (or was, when p_commit)
--      skip: not attributed        paid, but names no member (policy P2)
--      skip: unmapped shop sku     names a SKU absent from app.shop_sku_map
--      skip: period finalized      lands in a month with a final run (policy P3)
--      skip: already bridged       an order already exists for this pair (P7)
--      ERROR: bridged order has no lines
--                                  an order row exists for this pair but carries
--                                  zero order_lines, so it contributes 0.00
--                                  Sales Volume and no re-run will ever repair
--                                  it. This is the half-deleted state described
--                                  in policy P8. It is reported LOUDLY rather
--                                  than skipped, because it is silent volume
--                                  loss. Fix by deleting the orphan order row,
--                                  then running the bridge again.
--
--    A demo order is judged as a WHOLE. It is never half-bridged: if any of its
--    slices lands in a finalized period, or any of its lines names an unmapped
--    SKU, none of it is written.
-- =============================================================================
create or replace function app.fn_bridge_demo_orders(p_commit boolean default false)
returns table (
    demo_order_id bigint,
    order_number  text,
    member_code   text,
    volume_month  date,
    verdict       text,
    order_sv      numeric,
    n_lines       int
)
language plpgsql
as $$
#variable_conflict use_column
declare
    -- ---- policy constants. See the POLICY SWITCHES block at the top. ----
    v_state_gate        constant text    := 'succeeded';  -- P1
    v_buyer_role        constant text    := 'member';     -- P2
    v_spread_one_time   constant boolean := true;         -- P4
    v_one_time_slices   constant int     := 10;           -- P4
    v_written           int := 0;
begin
    -- -------------------------------------------------------------------
    -- Step 1: expand every qualifying demo order into per-month slices.
    -- A subscription line makes one slice. A one-time line makes ten
    -- (policy P4), each carrying one tenth of the price and one tenth of
    -- the PV, stamped to ten consecutive volume months.
    -- -------------------------------------------------------------------
    drop table if exists pg_temp.tmp_bridge_lines;

    create temp table tmp_bridge_lines on commit drop as
    with src as (
        select d.id                                     as demo_order_id,
               d.order_number,
               d.member_id,
               d.created_at,
               it.value ->> 'sku'                       as shop_sku,
               case when it.value ->> 'mode' = 'one' then 'one' else 'sub' end
                                                        as billing_mode,
               (it.value ->> 'quantity')::int           as quantity,
               (it.value ->> 'unit_price')::numeric     as line_price,
               (it.value ->> 'unit_pv')::numeric        as line_pv
        from app.demo_orders d
        cross join lateral jsonb_array_elements(d.items) it
        where d.payment_status = v_state_gate            -- POLICY P1
    ),
    sliced as (
        select s.*,
               case when s.billing_mode = 'one' and v_spread_one_time
                    then v_one_time_slices
                    else 1
               end as n_slices
        from src s
    )
    select sl.demo_order_id,
           sl.order_number,
           sl.member_id,
           sl.created_at,
           -- POLICY P3: the month is taken from created_at in UTC and never
           -- recomputed later, matching the engine's stamp-at-creation rule.
           ((date_trunc('month', sl.created_at at time zone 'UTC')::date)
              + (gs.n * interval '1 month'))::date          as volume_month,
           sl.shop_sku,
           sl.billing_mode,
           sl.quantity,
           (sl.line_price / sl.n_slices)::numeric(10,2)     as unit_price,
           (sl.line_pv    / sl.n_slices)::numeric(10,2)     as unit_volume
    from sliced sl
    cross join lateral generate_series(0, sl.n_slices - 1) as gs(n);

    -- -------------------------------------------------------------------
    -- Step 2: one row per (demo order, volume month), with its verdict.
    -- The verdict order matters: the cheapest and most fundamental
    -- disqualifier is tested first so the reported reason is the real one.
    -- -------------------------------------------------------------------
    drop table if exists pg_temp.tmp_bridge_orders;

    create temp table tmp_bridge_orders on commit drop as
    with per_pair as (
        select b.demo_order_id,
               b.order_number,
               b.member_id,
               b.created_at,
               b.volume_month,
               count(*)::int                                as n_lines,
               sum(b.quantity * b.unit_volume)::numeric(12,2) as order_sv,
               bool_or(map.product_id is null)              as has_unmapped_sku
        from pg_temp.tmp_bridge_lines b
        left join app.shop_sku_map map on map.shop_sku = b.shop_sku
        group by 1, 2, 3, 4, 5
    ),
    -- A demo order is judged whole: if ANY of its slices is blocked, none of
    -- it is written.
    per_order as (
        select p.demo_order_id,
               bool_or(p.has_unmapped_sku)                          as any_unmapped,
               bool_or(fr.run_id is not null)                       as any_period_final
        from per_pair p
        left join lateral (
            select r.id as run_id
            from app.commission_runs r
            where r.period = p.volume_month
              and r.status = 'final'
            limit 1
        ) fr on true
        group by 1
    )
    select p.demo_order_id,
           p.order_number,
           p.member_id,
           p.created_at,
           p.volume_month,
           p.n_lines,
           p.order_sv,
           case
               when p.member_id is null              then 'skip: not attributed'
               when o.any_unmapped                   then 'skip: unmapped shop sku'
               when o.any_period_final               then 'skip: period finalized'
               -- Orphan check FIRST, because it is a subset of "already
               -- bridged" and must never be swallowed by it (verifier M1).
               when exists (select 1
                              from app.orders eo
                             where eo.demo_order_id = p.demo_order_id
                               and eo.volume_month  = p.volume_month
                               and not exists (select 1
                                                 from app.order_lines el
                                                where el.order_id = eo.id))
                                                     then 'ERROR: bridged order has no lines'
               when exists (select 1
                              from app.orders eo
                             where eo.demo_order_id = p.demo_order_id
                               and eo.volume_month  = p.volume_month)
                                                     then 'skip: already bridged'
               else 'bridge'
           end as verdict
    from per_pair p
    join per_order o on o.demo_order_id = p.demo_order_id;

    -- -------------------------------------------------------------------
    -- Step 3: write, but only when explicitly asked to.
    -- -------------------------------------------------------------------
    if p_commit then

        insert into app.orders
            (member_id, buyer_role, customer_id, ordered_at, volume_month,
             status, demo_order_id)
        select o.member_id,
               v_buyer_role,          -- POLICY P2
               null,                  -- no customer identity is ever collected
               -- The first slice keeps the real purchase timestamp; later
               -- slices are stamped to the first instant of their own month in
               -- Coordinated Universal Time, so ordered_at sits inside its
               -- volume_month.
               --
               -- THE TIMEZONE IS PINNED EXPLICITLY (verifier M2). The earlier
               -- version cast with volume_month::timestamptz, which resolves a
               -- date against the SESSION TimeZone rather than UTC. This
               -- project's TimeZone is UTC so it happened to be right, but from
               -- a session at UTC+9, date '2026-09-01'::timestamptz is
               -- 2026-08-31 15:00 UTC, which would put a September slice's
               -- ordered_at in August. Not a money bug, because the engine keys
               -- on volume_month and never reads ordered_at, but the audit
               -- trail should not depend on who is connected.
               case when o.volume_month
                         = date_trunc('month', o.created_at at time zone 'UTC')::date
                    then o.created_at
                    else (o.volume_month::timestamp at time zone 'UTC')
               end,
               o.volume_month,
               'completed',
               o.demo_order_id
        from pg_temp.tmp_bridge_orders o
        where o.verdict = 'bridge'
        order by o.demo_order_id, o.volume_month
        -- GRACEFUL UNDER CONCURRENCY (verifier L1). The verdict test above is a
        -- non-locking read, so two simultaneous committing calls can both decide
        -- to bridge the same pair. The partial unique index is the real
        -- guarantee and already made double-paying impossible, but without this
        -- clause the second caller died with an unhandled unique_violation that
        -- rolled back its whole transaction. Now it simply writes nothing, which
        -- makes the concurrent case as quiet as the sequential one, and leaves
        -- v_written reporting what was actually inserted rather than attempted.
        on conflict (demo_order_id, volume_month)
            where demo_order_id is not null
            do nothing;

        get diagnostics v_written = row_count;

        insert into app.order_lines
            (order_id, product_id, quantity, unit_price, unit_volume, billing_mode)
        select ao.id,
               map.product_id,
               b.quantity,
               b.unit_price,      -- copied at order time, never looked up later
               b.unit_volume,     -- the only figure SV is ever computed from
               b.billing_mode
        from pg_temp.tmp_bridge_lines b
        join pg_temp.tmp_bridge_orders o
          on o.demo_order_id = b.demo_order_id
         and o.volume_month  = b.volume_month
         and o.verdict       = 'bridge'
        join app.shop_sku_map map on map.shop_sku = b.shop_sku
        join app.orders ao
          on ao.demo_order_id = b.demo_order_id
         and ao.volume_month  = b.volume_month
        -- Companion to the on-conflict clause above (verifier L1): if a
        -- concurrent caller already created this order AND its lines, the join
        -- would otherwise re-insert a duplicate set of lines and double the
        -- Sales Volume. Skipping any order that already carries lines makes the
        -- whole function idempotent, not just its orders insert.
        where not exists (select 1 from app.order_lines el where el.order_id = ao.id)
        order by ao.id, map.product_id;

        raise notice 'fn_bridge_demo_orders: wrote % order(s)', v_written;
    end if;

    -- -------------------------------------------------------------------
    -- Step 4: the report. Always returned, whether or not anything was
    -- written, so a dry run and a real run produce the same explanation.
    -- -------------------------------------------------------------------
    return query
    select o.demo_order_id,
           o.order_number,
           m.member_code,
           o.volume_month,
           o.verdict,
           o.order_sv,
           o.n_lines
    from pg_temp.tmp_bridge_orders o
    left join app.members m on m.id = o.member_id
    order by o.verdict, o.demo_order_id, o.volume_month;
end;
$$;

-- Privilege hygiene, same reasoning as the engine functions: Postgres grants
-- EXECUTE to PUBLIC by default, and only the service role or owner should ever
-- be able to move volume into the compensation tables.
revoke execute on function app.fn_bridge_demo_orders(boolean) from public;

comment on function app.fn_bridge_demo_orders(boolean) is
    'Translates succeeded live checkout orders into engine orders. Report-only '
    'by default; pass true to write. Every policy assumption is documented in '
    'the header of migration 019 and in DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md.';


-- =============================================================================
-- 7. HOW TO USE IT, and the order of operations for a real month
-- =============================================================================
--   -- see what would happen, writing nothing:
--   select * from app.fn_bridge_demo_orders();
--
--   -- actually bridge:
--   select * from app.fn_bridge_demo_orders(true);
--
--   -- then run and finalize the month exactly as always:
--   select app.fn_run_commission(date '2026-08-01');
--   select app.fn_finalize_run(<the run id it returned>);
--
-- Bridge BEFORE running the month, never after. Once a run is finalized, policy
-- P3 refuses to add anything to that month, which is the guardrail working, not
-- a failure.
-- =============================================================================
