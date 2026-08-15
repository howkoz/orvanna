-- =============================================================================
-- Comp 004: DRY RUN of the shop-to-compensation bridge
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-15
-- Author:  mlm-comp-engineer
-- Pairs with: db\migrations\019_shop_to_comp_bridge.sql (proposed, not applied)
-- Design:  DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md, section 8
--
-- READ-ONLY FROM THE FIRST LINE TO THE LAST.
-- There is no insert, no update, no delete, no create, no function call, and no
-- transaction in this file. Every statement is a SELECT. It can be run against
-- production safely, and it was: the results recorded in section 8 of the design
-- document were produced by these exact queries against the live project
-- oiyibdczkokegaxkwulv on 2026-08-15.
--
-- WHAT IT DOES
-- It answers one question: if the bridge were live, what commissions would
-- today's real, paid orders actually generate?
--
-- It does this WITHOUT the bridge existing. It builds the orders the bridge
-- WOULD write, in memory, then re-implements app.fn_run_commission's algorithm
-- step for step over them: the recursive level map, Sales Volume (SV),
-- Commissionable Volume (CV), Team Volume (TV), the qualification gate, all five
-- rank stages, and the depth-gated commission lines. The common table
-- expressions below are named after the engine's own (lvl, vols, tv_agg, base,
-- legs, active_leg_counts, flags_bl, leg_members, director_leg_counts, flags_d,
-- executive_leg_counts, flags_e, ranked) so the two can be diffed by eye.
--
-- PERIOD TESTED: 2026-08-01.
-- The six finalized months are February through July 2026. August has no
-- commission run and no seeded orders whatsoever, so every figure it produces
-- comes from money real people really paid on the live site.
--
-- POLICIES APPLIED, all from migration 019's header, all recommendations:
--   P1  only payment_status = 'succeeded' counts
--   P2  volume books to demo_orders.member_id; unattributed orders pay nobody
--   P3  volume month = month of created_at in Coordinated Universal Time
--   P4  a one-time purchase is spread over ten months, one tenth each
--   P5  a pack carries its own Personal Volume; children are never exploded
--
-- ACRONYMS: Personal Volume (PV), Sales Volume (SV), Commissionable Volume (CV),
-- Team Volume (TV), Coordinated Universal Time (UTC), Stock Keeping Unit (SKU).
-- =============================================================================


-- =============================================================================
-- QUERY 0: what is actually sitting in the live checkout table
-- Establishes the denominator before any policy is applied.
-- =============================================================================
select d.payment_status,
       count(*)                                   as orders,
       count(d.member_id)                         as orders_naming_a_member,
       sum(d.pv_total)                            as personal_volume,
       sum(d.total_cents) / 100.0                 as dollars
from app.demo_orders d
group by d.payment_status
order by d.payment_status;

-- Result, 2026-08-15:
--   abandoned   26 orders,  1 with a member,  2,550 PV
--   created     50 orders, 13 with a member, 11,050 PV
--   failed       8 orders,  1 with a member,    550 PV
--   processing   4 orders,  2 with a member,    550 PV
--   succeeded   29 orders, 11 with a member,  5,650 PV
--   TOTAL      117 orders, 28 with a member, 20,350 PV
--
-- Policy P1 discards 88 of the 117 rows and 14,700 of the 20,350 PV. Policy P2
-- then discards a further 18 paid orders carrying 3,650 PV that name no member.
-- What survives into the run below is 11 orders and 2,000 PV.


-- =============================================================================
-- QUERY 1: the volume that would arrive, per member, for 2026-08-01
-- =============================================================================
with recursive lvl as (
    -- Engine step 1: the level map. Recursive walk UP sponsor_id, full depth,
    -- exactly as app.fn_run_commission materializes it into app.run_level_map.
    select m.sponsor_id as ancestor_id, m.id as descendant_id, 1 as level
    from app.members m
    where m.sponsor_id is not null
    union all
    select p.sponsor_id, w.descendant_id, w.level + 1
    from lvl w
    join app.members p on p.id = w.ancestor_id
    where p.sponsor_id is not null
),
src as (
    -- The bridge's step 1, in memory: one row per cart line of every paid,
    -- attributed order. POLICY P1 and POLICY P2 are both in this WHERE clause.
    select d.member_id,
           d.created_at,
           case when it.value ->> 'mode' = 'one' then 'one' else 'sub' end as billing_mode,
           (it.value ->> 'quantity')::int   as quantity,
           (it.value ->> 'unit_pv')::numeric as line_pv
    from app.demo_orders d
    cross join lateral jsonb_array_elements(d.items) it
    where d.payment_status = 'succeeded'
      and d.member_id is not null
),
sliced as (
    -- POLICY P4: a one-time line becomes ten monthly slices; a subscription
    -- line stays one. Every catalogue value divides by ten exactly, so this
    -- creates no rounding.
    select s.*, case when s.billing_mode = 'one' then 10 else 1 end as n_slices
    from src s
),
bridged as (
    -- POLICY P3: the month comes from created_at in UTC.
    select sl.member_id,
           ((date_trunc('month', sl.created_at at time zone 'UTC')::date)
              + (gs.n * interval '1 month'))::date as volume_month,
           sl.quantity * (sl.line_pv / sl.n_slices) as pv
    from sliced sl
    cross join lateral generate_series(0, sl.n_slices - 1) as gs(n)
),
member_sv as (
    -- Engine step 2, member_sv: every member gets a row, most of them zero.
    select m.id as member_id,
           (coalesce(sum(b.pv), 0))::numeric(12,2) as sv
    from app.members m
    left join bridged b
           on b.member_id = m.id
          and b.volume_month = date '2026-08-01'
    group by m.id
),
vols as (
    select member_id, sv, (round(0.80 * sv, 2))::numeric(12,2) as cv
    from member_sv
),
tv_agg as (
    select l.ancestor_id as member_id, sum(v.sv) as tv
    from lvl l join vols v on v.member_id = l.descendant_id
    group by 1
),
base as (
    select v.member_id, v.sv, v.cv,
           (coalesce(t.tv, 0))::numeric(14,2) as tv,
           (v.sv >= 100.00)                   as qualified
    from vols v left join tv_agg t on t.member_id = v.member_id
),
legs as (
    select l.ancestor_id as member_id, l.descendant_id as child_id
    from lvl l where l.level = 1
),
active_leg_counts as (
    select lg.member_id, count(*) as n_active_legs
    from legs lg join base c on c.member_id = lg.child_id
    where c.qualified
    group by 1
),
flags_bl as (
    select b.member_id, b.sv, b.cv, b.tv, b.qualified,
           coalesce(al.n_active_legs, 0) as n_active_legs,
           (b.qualified and coalesce(al.n_active_legs, 0) >= 2) as builder_flag,
           (b.qualified and b.tv >= 2500.00
              and coalesce(al.n_active_legs, 0) >= 3)           as leader_flag
    from base b left join active_leg_counts al on al.member_id = b.member_id
),
leg_members as (
    select lg.member_id, lg.child_id, lg.child_id as leg_member_id from legs lg
    union all
    select lg.member_id, lg.child_id, l.descendant_id
    from legs lg join lvl l on l.ancestor_id = lg.child_id
),
director_leg_counts as (
    select lm.member_id, count(distinct lm.child_id) as n
    from leg_members lm join flags_bl f on f.member_id = lm.leg_member_id
    where f.builder_flag or f.leader_flag
    group by 1
),
flags_d as (
    select f.*, (f.qualified and f.tv >= 10000.00 and coalesce(dl.n, 0) >= 2) as director_flag
    from flags_bl f left join director_leg_counts dl on dl.member_id = f.member_id
),
executive_leg_counts as (
    select lm.member_id, count(distinct lm.child_id) as n
    from leg_members lm join flags_d f on f.member_id = lm.leg_member_id
    where f.leader_flag or f.director_flag
    group by 1
),
flags_e as (
    select f.*, (f.qualified and f.tv >= 40000.00 and coalesce(el.n, 0) >= 2) as executive_flag
    from flags_d f left join executive_leg_counts el on el.member_id = f.member_id
),
ranked as (
    select f.member_id, f.sv, f.cv, f.tv, f.qualified, f.n_active_legs,
           case when f.executive_flag then 'executive'
                when f.director_flag  then 'director'
                when f.leader_flag    then 'leader'
                when f.builder_flag   then 'builder'
                else 'member' end as rank_code
    from flags_e f
),
calc as (
    select r.*, rk.paid_depth from ranked r join app.ranks rk on rk.rank_code = r.rank_code
)
select m.member_code, c.sv, c.cv, c.tv, c.qualified, c.n_active_legs,
       c.rank_code, c.paid_depth
from calc c join app.members m on m.id = c.member_id
where c.sv > 0 or c.tv > 0
order by c.sv desc, m.member_code;

-- Result, 2026-08-15 (996 of the 1,000 members have zero of everything):
--   GW-000003  SV 900.00  CV 720.00  TV     0.00  qualified  0 active legs  member   depth 1
--   GW-000001  SV 500.00  CV 400.00  TV 1,500.00  qualified  1 active leg   member   depth 1
--   GW-000014  SV 500.00  CV 400.00  TV     0.00  qualified  0 active legs  member   depth 1
--   GW-000002  SV 100.00  CV  80.00  TV 1,400.00  qualified  2 active legs  BUILDER  depth 2
--
-- Total SV 2,000.00. Total CV 1,600.00.
-- Half of that SV (1,000) is bundles and packs the engine cannot see today:
-- GW-000003's Constellation Pack (800) and GW-000001's Manager Agent (200).


-- =============================================================================
-- QUERY 2: every commission line the run would produce
-- Identical prefix to Query 1; only the tail differs.
-- =============================================================================
with recursive lvl as (
    select m.sponsor_id as ancestor_id, m.id as descendant_id, 1 as level
    from app.members m where m.sponsor_id is not null
    union all
    select p.sponsor_id, w.descendant_id, w.level + 1
    from lvl w join app.members p on p.id = w.ancestor_id
    where p.sponsor_id is not null
),
src as (
    select d.member_id, d.created_at,
           case when it.value ->> 'mode' = 'one' then 'one' else 'sub' end as billing_mode,
           (it.value ->> 'quantity')::int    as quantity,
           (it.value ->> 'unit_pv')::numeric as line_pv
    from app.demo_orders d
    cross join lateral jsonb_array_elements(d.items) it
    where d.payment_status = 'succeeded' and d.member_id is not null
),
sliced as (select s.*, case when s.billing_mode = 'one' then 10 else 1 end as n_slices from src s),
bridged as (
    select sl.member_id,
           ((date_trunc('month', sl.created_at at time zone 'UTC')::date)
              + (gs.n * interval '1 month'))::date as volume_month,
           sl.quantity * (sl.line_pv / sl.n_slices) as pv
    from sliced sl cross join lateral generate_series(0, sl.n_slices - 1) as gs(n)
),
member_sv as (
    select m.id as member_id, (coalesce(sum(b.pv), 0))::numeric(12,2) as sv
    from app.members m
    left join bridged b on b.member_id = m.id and b.volume_month = date '2026-08-01'
    group by m.id
),
vols as (select member_id, sv, (round(0.80 * sv, 2))::numeric(12,2) as cv from member_sv),
tv_agg as (select l.ancestor_id as member_id, sum(v.sv) as tv
           from lvl l join vols v on v.member_id = l.descendant_id group by 1),
base as (select v.member_id, v.sv, v.cv, (coalesce(t.tv,0))::numeric(14,2) as tv,
                (v.sv >= 100.00) as qualified
         from vols v left join tv_agg t on t.member_id = v.member_id),
legs as (select l.ancestor_id as member_id, l.descendant_id as child_id from lvl l where l.level = 1),
active_leg_counts as (select lg.member_id, count(*) as n_active_legs
                      from legs lg join base c on c.member_id = lg.child_id
                      where c.qualified group by 1),
flags_bl as (select b.member_id, b.sv, b.cv, b.tv, b.qualified,
                    coalesce(al.n_active_legs, 0) as n_active_legs,
                    (b.qualified and coalesce(al.n_active_legs,0) >= 2) as builder_flag,
                    (b.qualified and b.tv >= 2500.00 and coalesce(al.n_active_legs,0) >= 3) as leader_flag
             from base b left join active_leg_counts al on al.member_id = b.member_id),
leg_members as (select lg.member_id, lg.child_id, lg.child_id as leg_member_id from legs lg
                union all
                select lg.member_id, lg.child_id, l.descendant_id
                from legs lg join lvl l on l.ancestor_id = lg.child_id),
director_leg_counts as (select lm.member_id, count(distinct lm.child_id) as n
                        from leg_members lm join flags_bl f on f.member_id = lm.leg_member_id
                        where f.builder_flag or f.leader_flag group by 1),
flags_d as (select f.*, (f.qualified and f.tv >= 10000.00 and coalesce(dl.n,0) >= 2) as director_flag
            from flags_bl f left join director_leg_counts dl on dl.member_id = f.member_id),
executive_leg_counts as (select lm.member_id, count(distinct lm.child_id) as n
                         from leg_members lm join flags_d f on f.member_id = lm.leg_member_id
                         where f.leader_flag or f.director_flag group by 1),
flags_e as (select f.*, (f.qualified and f.tv >= 40000.00 and coalesce(el.n,0) >= 2) as executive_flag
            from flags_d f left join executive_leg_counts el on el.member_id = f.member_id),
ranked as (select f.member_id, f.sv, f.cv, f.tv, f.qualified,
                  case when f.executive_flag then 'executive'
                       when f.director_flag  then 'director'
                       when f.leader_flag    then 'leader'
                       when f.builder_flag   then 'builder'
                       else 'member' end as rank_code
           from flags_e f),
calc as (select r.*, rk.paid_depth from ranked r join app.ranks rk on rk.rank_code = r.rank_code),
lines as (
    -- Engine step 3, verbatim in structure: the earner must be qualified, the
    -- level must be inside the earner's paid depth, the SOURCE member's own
    -- qualification is deliberately not tested, and no line is written on zero
    -- Commissionable Volume. No compression: level is plain tree distance.
    select l.ancestor_id as earner_id, l.descendant_id as source_id, l.level,
           s.cv as source_cv, rt.rate, round(rt.rate * s.cv, 2) as amount
    from lvl l
    join calc earner on earner.member_id = l.ancestor_id
    join calc s      on s.member_id      = l.descendant_id
    join (values (1, 0.1000::numeric(5,4)), (2, 0.0500::numeric(5,4)),
                 (3, 0.0500::numeric(5,4)), (4, 0.0300::numeric(5,4)),
                 (5, 0.0200::numeric(5,4))) as rt(level, rate) on rt.level = l.level
    where earner.qualified
      and l.level <= earner.paid_depth
      and s.cv > 0
)
select em.member_code as earner, sm.member_code as source, ln.level,
       ln.source_cv, ln.rate, ln.amount
from lines ln
join app.members em on em.id = ln.earner_id
join app.members sm on sm.id = ln.source_id
order by em.member_code, ln.level, sm.member_code;

-- Result, 2026-08-15. Three lines. That is the entire run.
--   GW-000001 <- GW-000002   level 1   CV  80.00   10%    8.00
--   GW-000002 <- GW-000003   level 1   CV 720.00   10%   72.00
--   GW-000002 <- GW-000014   level 1   CV 400.00   10%   40.00
--
-- Totals:      payout 120.00, members paid 2 of 1,000,
--              largest single earner GW-000002 at 112.00,
--              7.50 percent of CV, 6.00 percent of money received.
--
-- RECONCILIATION, every dollar (worked through in full in section 8.5 of
-- DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md):
--   structural ceiling  25% of 1,600.00 CV                      = 400.00
--   minus levels that do not exist above these four buyers      = 224.00
--   minus breakage at the depth gate (GW-000001 is depth 1)     =  56.00
--   equals payout                                               = 120.00
--
-- No earner in this run fails the qualification gate. The only breakage is the
-- depth gate, and it falls entirely on the root: GW-000001 holds rank Member,
-- so their level 2 claims on GW-000003 (36.00) and GW-000014 (20.00) are out of
-- reach and are paid to nobody.


-- =============================================================================
-- QUERY 3: the sanity check that the volume above is the volume that was paid
-- Ties the run back to app.demo_orders so no PV appears from nowhere.
-- =============================================================================
select m.member_code,
       count(distinct d.id)          as paid_orders,
       sum(d.pv_total)               as personal_volume,
       sum(d.total_cents) / 100.0    as dollars_charged
from app.demo_orders d
join app.members m on m.id = d.member_id
where d.payment_status = 'succeeded'
group by m.member_code
order by 3 desc;

-- Result, 2026-08-15:
--   GW-000003   2 orders   900 PV   $979.88
--   GW-000001   3 orders   500 PV   $509.75
--   GW-000014   5 orders   500 PV   $520.00
--   GW-000002   1 order    100 PV   $105.00
--   TOTAL      11 orders 2,000 PV  $2,114.63
--
-- The PV column matches the SV column of Query 1 exactly, member for member,
-- which is the check that matters: the bridge invents no volume and loses none.
--
-- CORRECTED 2026-08-15 after the verifier's finding H2. The earlier version of
-- this comment said the gap was "5 percent tax and the $25.00 activation fee on
-- some orders". Both halves were false, and both were written from the constants
-- in functions\_shared\pricing.ts instead of from the columns on the rows. See
-- Query 3b below, which measures it.


-- =============================================================================
-- QUERY 3b: WHAT THE 114.63 GAP ACTUALLY IS
-- Decomposed from tax_cents and activation_fee_cents, never from a constant.
-- =============================================================================
select d.activation,
       d.tax_source,
       coalesce(d.tax_jurisdiction, '(none)') as jurisdiction,
       count(*)                                             as orders,
       sum(d.subtotal_one_cents + d.subtotal_sub_cents)/100.0 as subtotal,
       sum(d.activation_fee_cents)/100.0                    as activation_fee,
       sum(d.tax_cents)/100.0                               as tax,
       round(100.0 * sum(d.tax_cents)
             / nullif(sum(d.subtotal_one_cents + d.subtotal_sub_cents
                          + d.activation_fee_cents), 0), 3) as effective_rate_pct
from app.demo_orders d
where d.payment_status = 'succeeded'
  and d.member_id is not null
group by 1, 2, 3
order by 2, 3;

-- Result, 2026-08-15:
--   standard  flat_mirror_5pct  (none)   5 orders  sub  500.00  fee 0.00  tax 25.00
--   standard  stripe_tax        CA, US   3 orders  sub  500.00  fee 0.00  tax  9.75
--   standard  stripe_tax        IL, US   1 order   sub  100.00  fee 0.00  tax  0.00
--   standard  stripe_tax        NY, US   2 orders  sub  900.00  fee 0.00  tax 79.88
--   TOTAL                               11 orders  sub 2,000.00 fee 0.00  tax 114.63
--
-- THE GAP IS 100 PERCENT SALES TAX AND 0 PERCENT ACTIVATION FEE.
-- All eleven orders are activation='standard', which is free. The sum of
-- activation_fee_cents across all eleven is exactly zero.
--
-- The tax is NOT a flat 5 percent. Six distinct effective per-order rates
-- appear, from two different sources:
--   0.000%  stripe_tax        IL, US   Illinois did not tax this sale
--   0.000%  stripe_tax        CA, US   a California sale taxed at zero, the
--                                      ambiguous case: no registration, or a
--                                      genuinely untaxed product. Only
--                                      tax_reason distinguishes them.
--   5.000%  flat_mirror_5pct  (none)   the fallback path, pre tax engine
--   8.875%  stripe_tax        NY, US
--   8.880%  stripe_tax        NY, US   same state, different rounding base
--   9.750%  stripe_tax        CA, US
--
-- Five of eleven orders still price through the flat fallback; six were priced
-- by a real tax engine against a real destination.
--
-- Reconciliation closes exactly: 2,000.00 volume + 114.63 tax + 0.00 fee
-- = 2,114.63 charged. Neither tax nor an activation fee is ever commissionable
-- (policy P9), which is why 2,114.63 of money produced 2,000.00 of volume.


-- =============================================================================
-- QUERY 3c: THE SLICE ASSERTION (verifier L2)
--
-- Policy P4 divides a one-time line by ten. The no-rounding guarantee rests on
-- the claim that every catalogue value divides by ten with no remainder, which
-- is true of today's catalogue and stops being true the first time a discount,
-- proration, partial refund, or promotional price writes a non-round unit_price
-- into items. Ten slices would then no longer add back to the one-time total and
-- the loss would be silent.
--
-- This is the assertion that makes it loud: for every cart line of every paid
-- order, the slices must sum EXACTLY back to the original price and the original
-- Personal Volume. Any non-zero mismatch count is a defect.
-- =============================================================================
with src as (
    select d.id as demo_order_id, d.created_at, it.ordinality as line_no,
           case when it.value ->> 'mode' = 'one' then 'one' else 'sub' end as billing_mode,
           (it.value ->> 'unit_price')::numeric as line_price,
           (it.value ->> 'unit_pv')::numeric    as line_pv
    from app.demo_orders d
    cross join lateral jsonb_array_elements(d.items) with ordinality it
    where d.payment_status = 'succeeded'
),
sliced as (
    select s.*, case when s.billing_mode = 'one' then 10 else 1 end as n_slices from src s
),
expanded as (
    select sl.demo_order_id, sl.line_no, sl.line_price, sl.line_pv,
           sum((sl.line_price / sl.n_slices)::numeric(10,2)) over w as slices_price_sum,
           sum((sl.line_pv    / sl.n_slices)::numeric(10,2)) over w as slices_pv_sum
    from sliced sl
    cross join lateral generate_series(0, sl.n_slices - 1) as gs(n)
    window w as (partition by sl.demo_order_id, sl.line_no)
)
select count(distinct (demo_order_id, line_no))                as cart_lines_checked,
       count(*) filter (where slices_pv_sum    <> line_pv)     as pv_mismatches,
       count(*) filter (where slices_price_sum <> line_price)  as price_mismatches,
       min(slices_pv_sum    - line_pv)                         as worst_pv_delta,
       max(slices_price_sum - line_price)                      as worst_price_delta
from expanded;

-- Result, 2026-08-15: 31 cart lines checked, 0 Personal Volume mismatches,
-- 0 price mismatches, worst delta 0.00 in both directions. The slices add back
-- exactly. Re-run this after ANY change to pricing, and treat a non-zero
-- mismatch as a release blocker rather than a rounding curiosity.


-- =============================================================================
-- QUERY 4: what policy P2 leaves on the table
-- The paid volume that names no member, which under the recommendation pays
-- nobody. This is the largest single number in the whole exercise, so it is
-- measured rather than described.
-- =============================================================================
select case when d.member_id is null then 'no member named' else 'attributed' end as attribution,
       count(*)          as paid_orders,
       sum(d.pv_total)   as personal_volume,
       round(sum(d.pv_total) * 0.80, 2) as commissionable_volume_if_counted
from app.demo_orders d
where d.payment_status = 'succeeded'
group by 1
order by 1;

-- Result, 2026-08-15:
--   attributed        11 orders   2,000 PV   CV 1,600.00
--   no member named   18 orders   3,650 PV   CV 2,920.00
--
-- 62 percent of paid orders carry no referral code. Under the recommendation
-- that volume is breakage and pays nobody, which makes this a product finding
-- rather than a compensation finding: the checkout is not asking clearly enough.
-- A page change is worth more here than any plan rule.
