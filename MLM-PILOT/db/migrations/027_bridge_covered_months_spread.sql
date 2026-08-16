-- =============================================================================
-- Migration 027: the ONE bridge amendment, covered_months spread (OQ1, OQ5)
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
--
-- APPLIED TO THE CLOUD PROJECT 2026-08-16 (gated: verifier re-gate 13f273e
-- CLOUD APPLY YES, quality assurance delta 8bf59df, on commit 8f31a76). The
-- in-place-edit window on this file is CLOSED FOREVER as of that apply: any
-- future change, however small, is a NEW numbered migration file.
--
-- Design:  MLM-PILOT\docs\SUBSCRIPTION-ENGINE-SPEC.md section 7 and 4.4;
--          confirmed by Howard's addendum rulings OQ1 (multi-month
--          frequencies SPREAD their volume, one product-month of Personal
--          Volume per covered calendar month) and OQ5 (the amendment is the
--          existing materialised-slice mechanism with a parameterised count).
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY (see migration 024's status
--         block). FROZEN once applied anywhere.
--
-- LAYERS ON TOP OF 019, EDITS NOTHING. Migration 019 is byte-for-byte
-- unchanged (the standing lesson: applied SQL is never edited in place; this
-- is the follow-up-is-a-new-migration rule working as intended). This file
-- REPLACES the function app.fn_bridge_demo_orders with a version that is
-- 019's function plus exactly one new datum, and re-records every 019 policy
-- constant untouched.
--
-- Acronym key: Personal Volume (PV), Sales Volume (SV), Stock Keeping Unit
-- (SKU), Coordinated Universal Time (UTC).
--
-- -----------------------------------------------------------------------------
-- THE AMENDMENT, STATED EXACTLY (spec section 7)
-- -----------------------------------------------------------------------------
-- Today the bridge spreads mode 'one' lines over ten months and books mode
-- 'sub' lines to the creation month. It gains a single datum: a 'sub' line
-- carrying covered_months greater than 1 spreads over exactly that many
-- months, first slice in the creation month, later slices stamped to the
-- first of each following calendar month. This is the IDENTICAL
-- materialised-slice mechanism migration 021 already built and proved (ten
-- slices, summing exactly, calendar contained), extended with a
-- parameterised count. It is not a duplicate and not a bypass: policies P1
-- through P9 are untouched and the seven bridge rulings keep applying to
-- every engine-written row automatically.
--
-- WHY THE NUMBERS DIVIDE EXACTLY: a quarterly billing charges 3 times the
-- monthly price and carries 3 times the monthly PV, so each of 3 slices is
-- exactly the monthly figure (300.00 / 3 = 100.00); likewise bi-monthly and
-- semi-annual. No rounding is created, the same property 019 argued for the
-- ten-slice split. This makes the quarterly member identical, month by
-- month, to a monthly member, which is the property the plan's per-month
-- thresholds require (worked example C, spec section 11).
--
-- WHAT CHANGES IN THE FUNCTION BODY, precisely three things (the third was
-- added in the 2026-08-16 fix round for spec v1.1 erratum E3; the file was
-- still unapplied everywhere, so the coordinator ruled the fix lands here):
--   1. The slicing rule in step 1 reads the per-line covered_months field
--      (written by the renewal engine, migration 026): n_slices =
--        mode 'one'  -> 10 (policy P4, unchanged)
--        mode 'sub'  -> coalesce(covered_months, 1)
--      A shop-written 'sub' line has no covered_months field and behaves
--      exactly as before (coalesce to 1). Nothing else in the temp-table
--      pipeline, verdict logic, write step, or report changes.
--   2. The line insert divides price and PV by n_slices for 'sub' lines the
--      same way it always did for 'one' lines (the arithmetic was already
--      per-slice; only the slice count was mode-hardcoded).
--   3. Every slice's volume month shifts by the per-line
--      covered_month_offset (default 0): the OQ4 transition charge bills in
--      the change month but covers the NEXT UNCOVERED month (v1.1 12.1
--      sentence 1), so its volume must land in the covered months to keep
--      PV equals dollars true per calendar month. Zero for every shop line
--      and every unbroken-schedule engine line, so nothing else moves.
--
-- RUN ORDER: after 026 (the engine that writes covered_months), before the
-- first tick that bills a multi-month frequency.
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
    -- ---- policy constants, ALL of 019's, byte-identical in meaning. ----
    v_state_gate        constant text    := 'succeeded';  -- P1
    v_buyer_role        constant text    := 'member';     -- P2
    v_spread_one_time   constant boolean := true;         -- P4
    v_one_time_slices   constant int     := 10;           -- P4
    v_written           int := 0;
begin
    -- -------------------------------------------------------------------
    -- Step 1: expand every qualifying demo order into per-month slices.
    -- A subscription line makes coalesce(covered_months, 1) slices (the 027
    -- amendment; shop lines carry no covered_months and make one). A
    -- one-time line makes ten (policy P4). Every slice carries one
    -- n_slices-th of the price and the PV, stamped to consecutive months.
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
               (it.value ->> 'unit_pv')::numeric        as line_pv,
               coalesce((it.value ->> 'covered_months')::int, 1)
                                                        as covered_months,
               -- Fix round (spec v1.1 erratum E3): a day-change TRANSITION
               -- charge bills in the change month and covers the NEXT
               -- UNCOVERED month, so its volume must book to the covered
               -- months, not the billing month. The engine stamps the
               -- per-line covered_month_offset (months from the creation
               -- month to the first covered month; zero on an unbroken
               -- schedule, so every shop line and every pre-fix engine line
               -- behaves exactly as before) and every slice shifts by it.
               coalesce((it.value ->> 'covered_month_offset')::int, 0)
                                                        as covered_month_offset
        from app.demo_orders d
        cross join lateral jsonb_array_elements(d.items) it
        where d.payment_status = v_state_gate            -- POLICY P1
    ),
    sliced as (
        select s.*,
               case
                   when s.billing_mode = 'one' and v_spread_one_time
                        then v_one_time_slices           -- P4, unchanged
                   when s.billing_mode = 'sub'
                        then s.covered_months            -- THE 027 AMENDMENT
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
           -- For the engine's rows created_at IS the billing run's tick date
           -- (migration 024, section 13), so slice one lands in the billing
           -- month and later slices in the following covered months, exactly
           -- worked example C.
           ((date_trunc('month', sl.created_at at time zone 'UTC')::date)
              + ((sl.covered_month_offset + gs.n) * interval '1 month'))::date as volume_month,
           sl.shop_sku,
           sl.billing_mode,
           sl.quantity,
           (sl.line_price / sl.n_slices)::numeric(10,2)     as unit_price,
           (sl.line_pv    / sl.n_slices)::numeric(10,2)     as unit_volume
    from sliced sl
    cross join lateral generate_series(0, sl.n_slices - 1) as gs(n);

    -- -------------------------------------------------------------------
    -- Step 2: one row per (demo order, volume month), with its verdict.
    -- Unchanged from 019, verdict order and all (the orphan check stays
    -- FIRST, verifier finding M1).
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
    -- Step 3: write, but only when explicitly asked to. Unchanged from 019
    -- including the concurrency clauses (verifier L1) and the pinned
    -- timezone (verifier M2).
    -- -------------------------------------------------------------------
    if p_commit then

        insert into app.orders
            (member_id, buyer_role, customer_id, ordered_at, volume_month,
             status, demo_order_id)
        select o.member_id,
               v_buyer_role,          -- POLICY P2
               null,
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
        on conflict (demo_order_id, volume_month)
            where demo_order_id is not null
            do nothing;

        get diagnostics v_written = row_count;

        insert into app.order_lines
            (order_id, product_id, quantity, unit_price, unit_volume, billing_mode)
        select ao.id,
               map.product_id,
               b.quantity,
               b.unit_price,
               b.unit_volume,
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
        where not exists (select 1 from app.order_lines el where el.order_id = ao.id)
        order by ao.id, map.product_id;

        raise notice 'fn_bridge_demo_orders: wrote % order(s)', v_written;
    end if;

    -- -------------------------------------------------------------------
    -- Step 4: the report. Unchanged from 019.
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

revoke execute on function app.fn_bridge_demo_orders(boolean) from public;

comment on function app.fn_bridge_demo_orders(boolean) is
    'Translates succeeded live checkout AND renewal-engine orders into engine '
    'orders. Report-only by default; pass true to write. 019''s nine policies '
    'unchanged; migration 027 added exactly one datum: a sub line carrying '
    'covered_months > 1 spreads over that many months by the materialised- '
    'slice mechanism of migration 021 (rulings OQ1 and OQ5).';


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- 1. A shop-written 'sub' line (no covered_months field) still produces ONE
--    slice: bridge a plain shop order and expect a single (demo_order_id,
--    volume_month) pair, exactly as under 019.
-- 2. A renewal-engine quarterly order (covered_months 3, 300.00, 300 PV)
--    produces THREE order rows, volume months m, m+1, m+2, each with one
--    line of unit_volume 100.00; the three slices sum exactly to 300.
-- 3. A 'one' line still produces ten slices (policy P4 untouched).
-- 4. Idempotency: running the committing call twice writes zero new rows the
--    second time; every pair reports 'skip: already bridged'.
-- 5. The full proof run (worked example C to the cent, Beth earning 8.00 in
--    each covered month) is recorded in
--    MLM-PILOT\docs\verification\S1-PROOF-RUN-2026-08-16.md.
-- =============================================================================
