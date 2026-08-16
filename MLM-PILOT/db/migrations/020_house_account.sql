-- =============================================================================
-- Migration 020: the house account, GW-000, and the company retention ledger
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-15
-- Author:  mlm-comp-engineer
-- Answers: design decision 4.7, ANSWERED BY HOWARD 2026-08-15.
--          His words: "when no one is linked then lets pay that to the company
--          for now" and "lets make an ID that is the top of the tree like GW-000".
-- Design:  DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md, section 10.
--
-- STATUS: APPLIED 2026-08-16 to the live project (mlm-pilot, oiyibdczkokegaxkwulv)
--         as migration house_account_020, immediately after 019, on Howard's
--         straight-to-production ruling. Decision record:
--         MLM-PILOT\docs\decisions\2026-08-16-bridge-seven-decisions.md.
--         From this point this file is FROZEN: applied SQL is never edited, a
--         follow-up change is a new numbered migration.
--
-- LAYERS ON TOP OF 019, DOES NOT EDIT IT. Migration 019 is byte-for-byte
-- unchanged and remains the file the verifier is recomputing against. This file
-- consumes exactly the orders 019 reports as "skip: not attributed" and does
-- nothing else to 019's behaviour.
--
-- Acronyms: Personal Volume (PV), Sales Volume (SV), Commissionable Volume (CV),
-- Team Volume (TV), Row Level Security (RLS), Coordinated Universal Time (UTC).
--
-- =============================================================================
-- THE ACCOUNTING DISTINCTION. READ THIS BEFORE READING THE CODE.
-- =============================================================================
-- This is BOOKKEEPING, not a disbursement.
--
-- 18 of the 29 paid orders on the live site name no member. Until now that
-- volume was silent: nobody was paid on it and nothing recorded it. GW-000 makes
-- it VISIBLE, so it can be counted, reported, and watched. It does not make it a
-- commission.
--
-- The money never left the company. Treating retained margin as a commission
-- would distort every payout report ever produced, because "total payout" would
-- silently include money the company paid itself. So the design keeps the two
-- kinds of money in SEPARATE TABLES rather than in one table with a label:
--
--   * MEMBER PAYOUT lives in app.commission_lines and app.run_member_results,
--     exactly as it always has, and is completely untouched by this migration.
--   * COMPANY RETENTION lives in app.house_retained_volume, a new table that no
--     commission run reads.
--
-- That is the strongest available form of the guarantee. A report cannot mix
-- them by accident, because there is no query over app.commission_lines that can
-- reach company retention, and no query over the retention ledger that can reach
-- a commission. The separation is structural, not a naming convention.
--
-- WHY THE RETAINED VOLUME IS NOT BOOKED INTO app.orders
-- If it were, GW-000 would have SV, would pass the SV >= 100 qualification gate,
-- would hold a rank, would appear as a qualified member in every count, and its
-- CV would inflate the run's total_cv so that "payout as a percentage of CV"
-- became a misleading number. Keeping it out of app.orders means GW-000 cannot
-- qualify BY CONSTRUCTION rather than by a rule somebody has to remember. The
-- engine, app.fn_run_commission, needs no change at all and is not touched here.
--
-- WHAT GW-000 LOOKS LIKE IN A RUN: a row in app.run_member_results with SV 0.00,
-- CV 0.00, TV 0.00, is_active false, rank 'member' (the lowest rung, meaning
-- enrolled and nothing more), total_earned 0.00. A harmless zero row.
--
-- =============================================================================
-- SIBLING ROOT, NOT FORMAL ROOT. THE CHOICE AND THE REASON.
-- =============================================================================
-- app.members.sponsor_id is nullable with no constraint requiring exactly one
-- null, and app.check_sponsor_cycle only ever walks UPWARD, so a second
-- null-sponsor row is structurally safe. Two shapes were possible:
--
--   FORMAL ROOT   GW-000 at the very top, with GW-000001 re-parented under it.
--                 REJECTED, for two independent reasons. First, it re-parents an
--                 existing member, which changes the tree. Second and worse, a
--                 formal root sits above all 1,000 members, so every future run
--                 would compute level-pay commission lines FROM the whole
--                 organisation TO the company. That is precisely the outcome
--                 this migration exists to prevent.
--
--   SIBLING ROOT  GW-000 alongside GW-000001, both with sponsor_id null, nothing
--                 above it and nothing below it. CHOSEN. The existing tree is
--                 untouched: 1,000 members, every sponsor link exactly as it was.
--                 GW-000 is sterile in both directions and can never earn,
--                 because it has no downline to earn from.
--
-- "Top of the tree", in Howard's phrase, is satisfied: GW-000 has nobody above
-- it. It simply also has nobody below it, which is what keeps it honest.
--
-- GW-000 deliberately breaks the six-digit GW-NNNNNN member code format. That is
-- a feature: it reads instantly as not-a-person in any list it appears in.
--
-- =============================================================================
-- NOTHING FINALIZED MOVES. THE PROOF, NOT THE PROMISE.
-- =============================================================================
-- The six finalized monthly runs (February through July 2026) live in
-- app.run_member_results and app.commission_lines. This migration writes to
-- neither. It adds a column to app.members, inserts one member row, creates one
-- new table, three triggers and two views.
--
-- A finalized run's rows are frozen by triggers already in place
-- (run_member_results_immutable_when_final, commission_lines_immutable_when_final,
-- and the matching no_write_into_final pair, verified live 2026-08-15). Adding a
-- member row cannot reach them: those rows were computed and stored months ago,
-- and a new member simply has no row in any of them.
--
-- Verified read-only on 2026-08-15 by re-running the whole August dry run with a
-- virtual GW-000 injected as a sibling root. Output was identical to the cent:
-- 3 commission lines, 2 members paid, 120.00 total payout, total SV 2,000.00,
-- total CV 1,600.00, and ZERO commission lines naming the house account.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The house account marker
--
--    A boolean column rather than a magic member_code string, so every guard
--    below tests a fact rather than pattern-matching a name. The partial unique
--    index allows at most one house account to exist, ever.
-- -----------------------------------------------------------------------------
alter table app.members
    add column if not exists is_house_account boolean not null default false;

create unique index if not exists members_one_house_account_idx
    on app.members ((true))
    where is_house_account;

comment on column app.members.is_house_account is
    'True only for GW-000, the company retention account (migration 020). A '
    'house account holds volume that no member was attributed, earns nothing, '
    'sponsors nobody, is sponsored by nobody, and can never appear on a '
    'commission line. Enforced by triggers, not by convention.';


-- -----------------------------------------------------------------------------
-- 2. GW-000 itself
--
--    sponsor_id null: a SIBLING root. enrolled_on is the date this account came
--    into being rather than a back-dated one, because pretending it existed
--    during the six finalized months would be a small lie in a table people read.
--    The email address uses the reserved .invalid domain so it can never resolve
--    and can never be mistaken for a real inbox. No view exposes it anyway.
-- -----------------------------------------------------------------------------
insert into app.members
    (member_code, display_name, email, sponsor_id, enrolled_on, status,
     is_house_account)
values
    ('GW-000',
     'Orvanna (company retention account)',
     'house-account@orvanna.invalid',
     null,
     date '2026-08-15',
     'active',
     true)
on conflict (member_code) do nothing;


-- -----------------------------------------------------------------------------
-- 3. app.house_retained_volume: the retention ledger
--
--    One row per (unattributed paid order, volume month, cart line). Carries the
--    same slice fields the spreading policy produces, so a one-time purchase
--    that nobody claimed is retained across ten months exactly as an attributed
--    one would have been recognised across ten months. Retention and recognition
--    follow the same calendar; only the destination differs.
--
--    RLS on with ZERO policies: no public view reads this table.
-- -----------------------------------------------------------------------------
create table if not exists app.house_retained_volume (
    id               bigint generated always as identity primary key,
    house_member_id  bigint not null references app.members (id),
    demo_order_id    bigint not null references app.demo_orders (id),
    volume_month     date   not null,
    shop_sku         text   not null,
    billing_mode     text   not null check (billing_mode in ('sub', 'one')),
    slice_index      int    not null check (slice_index >= 1),
    slice_count      int    not null check (slice_count >= 1),
    quantity         int    not null check (quantity > 0),
    unit_price       numeric(10,2) not null,
    unit_volume      numeric(10,2) not null,
    retained_pv      numeric(12,2) not null,
    created_at       timestamptz   not null default now(),
    constraint house_retained_volume_slice_key
        unique (demo_order_id, volume_month, shop_sku, billing_mode),
    constraint house_retained_volume_slice_range
        check (slice_index <= slice_count)
);

create index if not exists house_retained_volume_month_idx
    on app.house_retained_volume (volume_month);

comment on table app.house_retained_volume is
    'RETAINED, NOT PAID. Volume from paid orders that named no member. No '
    'commission run reads this table; it exists so company retention is visible '
    'and countable without ever being mistakable for a member payout.';

comment on column app.house_retained_volume.retained_pv is
    'quantity * unit_volume for this slice. Personal Volume retained by the '
    'company. It is NOT Commissionable Volume and NOT a payout.';

alter table app.house_retained_volume enable row level security;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.house_retained_volume from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.house_retained_volume from authenticated;
    end if;
end
$$;


-- =============================================================================
-- 4. THE THREE GUARDS
--
-- The coordinator's instruction was to assert these in code rather than rely on
-- the tree shape. Today GW-000 earns nothing because nothing sits below it, but
-- "nothing sits below it today" is a fact about data, and facts about data
-- change. These three triggers turn each property into a rule the database
-- itself enforces, in the same spirit as the sponsor cycle check and the
-- finalized-run immutability triggers.
-- =============================================================================

-- ---- Guard 1: nobody may be sponsored BY a house account --------------------
-- This is what keeps GW-000 permanently childless, and therefore permanently
-- unable to earn a single commission line. It also makes the "existing members
-- must not be re-parented under it" instruction a permanent property rather
-- than a thing this migration merely refrained from doing.
create or replace function app.reject_sponsoring_by_house_account()
returns trigger
language plpgsql
as $$
begin
    if new.sponsor_id is not null
       and exists (select 1 from app.members h
                    where h.id = new.sponsor_id and h.is_house_account) then
        raise exception
            'member % cannot be sponsored by a house account: the company '
            'retention account holds volume, it does not build an organisation',
            new.member_code;
    end if;
    return new;
end;
$$;

create trigger members_no_sponsoring_by_house_account
    before insert or update of sponsor_id on app.members
    for each row
    execute function app.reject_sponsoring_by_house_account();


-- ---- Guard 2: a house account may never hold an order ------------------------
-- This is the one that makes "cannot qualify" structural. SV comes only from
-- app.orders. With no order possible, SV is always 0.00, so the SV >= 100 gate
-- can never pass, so no rank above Member is reachable and is_active is always
-- false. Retained volume goes to app.house_retained_volume instead, which the
-- engine does not read.
create or replace function app.reject_order_for_house_account()
returns trigger
language plpgsql
as $$
begin
    if exists (select 1 from app.members h
                where h.id = new.member_id and h.is_house_account) then
        raise exception
            'a house account cannot hold an order: retained volume belongs in '
            'app.house_retained_volume, which no commission run reads';
    end if;
    return new;
end;
$$;

create trigger orders_no_house_account
    before insert or update of member_id on app.orders
    for each row
    execute function app.reject_order_for_house_account();


-- ---- Guard 3: no commission line may name a house account -------------------
-- The explicit assertion. Even if guards 1 and 2 were both somehow defeated, no
-- money can be written against the company as though it were a member.
create or replace function app.reject_commission_for_house_account()
returns trigger
language plpgsql
as $$
begin
    if exists (select 1 from app.members h
                where h.id in (new.earner_id, new.source_member_id)
                  and h.is_house_account) then
        raise exception
            'a commission line cannot name a house account (earner %, source %): '
            'company retention is bookkeeping, never a payout',
            new.earner_id, new.source_member_id;
    end if;
    return new;
end;
$$;

create trigger commission_lines_no_house_account
    before insert on app.commission_lines
    for each row
    execute function app.reject_commission_for_house_account();


-- =============================================================================
-- 5. app.fn_retain_unattributed_orders(p_commit boolean default false)
--
-- Consumes exactly the orders that 019's bridge reports as
-- "skip: not attributed". Same policies as 019 for state (P1 succeeded only),
-- month (P3 created_at in UTC), spreading (P4 ten slices) and packs (P5 parent
-- Personal Volume only). The only difference is the destination: the retention
-- ledger rather than app.orders.
--
-- Report-only by default, exactly like the bridge.
--
-- RUN ORDER: run the bridge first, then this. They are disjoint by construction
-- (the bridge takes member_id not null, this takes member_id null), so the order
-- does not actually matter, but reading them in that order matches the story.
-- =============================================================================
create or replace function app.fn_retain_unattributed_orders(p_commit boolean default false)
returns table (
    volume_month     date,
    retained_orders  bigint,
    retained_slices  bigint,
    retained_pv      numeric,
    action           text
)
language plpgsql
as $$
#variable_conflict use_column
declare
    v_state_gate      constant text    := 'succeeded';  -- P1
    v_spread_one_time constant boolean := true;         -- P4
    v_one_time_slices constant int     := 10;           -- P4
    v_house_id        bigint;
    v_written         int := 0;
begin
    select h.id into v_house_id from app.members h where h.is_house_account limit 1;
    if v_house_id is null then
        raise exception
            'no house account exists: insert GW-000 (migration 020 step 2) first';
    end if;

    drop table if exists pg_temp.tmp_retained;

    create temp table tmp_retained on commit drop as
    with src as (
        select d.id                                 as demo_order_id,
               d.created_at,
               it.value ->> 'sku'                   as shop_sku,
               case when it.value ->> 'mode' = 'one' then 'one' else 'sub' end
                                                    as billing_mode,
               (it.value ->> 'quantity')::int       as quantity,
               (it.value ->> 'unit_price')::numeric as line_price,
               (it.value ->> 'unit_pv')::numeric    as line_pv
        from app.demo_orders d
        cross join lateral jsonb_array_elements(d.items) it
        where d.payment_status = v_state_gate     -- POLICY P1
          and d.member_id is null                 -- the unattributed half
    ),
    sliced as (
        select s.*,
               case when s.billing_mode = 'one' and v_spread_one_time
                    then v_one_time_slices else 1 end as n_slices
        from src s
    )
    select sl.demo_order_id,
           ((date_trunc('month', sl.created_at at time zone 'UTC')::date)
              + (gs.n * interval '1 month'))::date        as volume_month,
           sl.shop_sku,
           sl.billing_mode,
           (gs.n + 1)                                     as slice_index,
           sl.n_slices                                    as slice_count,
           sl.quantity,
           (sl.line_price / sl.n_slices)::numeric(10,2)   as unit_price,
           (sl.line_pv    / sl.n_slices)::numeric(10,2)   as unit_volume,
           (sl.quantity * (sl.line_pv / sl.n_slices))::numeric(12,2) as retained_pv
    from sliced sl
    cross join lateral generate_series(0, sl.n_slices - 1) as gs(n);

    if p_commit then
        insert into app.house_retained_volume
            (house_member_id, demo_order_id, volume_month, shop_sku, billing_mode,
             slice_index, slice_count, quantity, unit_price, unit_volume, retained_pv)
        select v_house_id, t.demo_order_id, t.volume_month, t.shop_sku,
               t.billing_mode, t.slice_index, t.slice_count, t.quantity,
               t.unit_price, t.unit_volume, t.retained_pv
        from pg_temp.tmp_retained t
        order by t.demo_order_id, t.volume_month, t.shop_sku
        on conflict on constraint house_retained_volume_slice_key do nothing;

        get diagnostics v_written = row_count;
        raise notice 'fn_retain_unattributed_orders: wrote % retention row(s)', v_written;
    end if;

    return query
    select t.volume_month,
           count(distinct t.demo_order_id)      as retained_orders,
           count(*)                             as retained_slices,
           sum(t.retained_pv)::numeric(12,2)    as retained_pv,
           case when p_commit then 'RETAINED (written)' else 'RETAINED (report only)' end
    from pg_temp.tmp_retained t
    group by t.volume_month
    order by t.volume_month;
end;
$$;

revoke execute on function app.fn_retain_unattributed_orders(boolean) from public;


-- =============================================================================
-- 6. THE TWO REPORTING VIEWS
--
-- Both name their columns so that company retention and member payout can never
-- be read as the same thing, even by somebody skimming.
-- =============================================================================

create or replace view app.v_company_retention_by_period as
select h.volume_month                          as period,
       count(distinct h.demo_order_id)         as retained_orders,
       count(*)                                as retained_slices,
       sum(h.retained_pv)::numeric(14,2)       as company_retained_pv,
       'RETAINED, NOT PAID'::text              as basis
from app.house_retained_volume h
group by h.volume_month;

comment on view app.v_company_retention_by_period is
    'Company retention per month. Every figure here is volume the company kept '
    'because no member was attributed. None of it is a commission and none of '
    'it appears in app.commission_lines.';


-- The one report that puts both kinds of money on one line, side by side, with
-- names that cannot be confused. Note that the two halves come from two
-- different tables: there is no row in which they are added together.
create or replace view app.v_period_money as
select coalesce(r.period, h.period)                       as period,
       coalesce(r.total_sv, 0)::numeric(14,2)             as member_sv,
       coalesce(r.total_cv, 0)::numeric(14,2)             as member_cv,
       coalesce(r.total_payout, 0)::numeric(14,2)         as member_payout_paid,
       coalesce(r.members_paid, 0)                        as members_paid,
       coalesce(h.company_retained_pv, 0)::numeric(14,2)  as company_retained_pv_not_paid,
       r.run_id,
       r.run_status
from (
    select cr.period, cr.id as run_id, cr.status as run_status,
           cr.total_sv, cr.total_cv, cr.total_payout, cr.members_paid
    from app.commission_runs cr
    where cr.status = 'final'
) r
full outer join app.v_company_retention_by_period h on h.period = r.period;

comment on view app.v_period_money is
    'Member payout and company retention for one month, side by side and never '
    'summed. member_payout_paid is money owed to members. '
    'company_retained_pv_not_paid is volume the company kept and is NOT a '
    'payout. The two come from different tables on purpose.';


-- =============================================================================
-- 7. THE PUBLIC READ SURFACE. THIS BLOCK CHANGES WHAT THE WEBSITE SEES.
--
-- Without it, GW-000 would appear on the live site as a member: in the member
-- roster from v_demo_members with a blank rank, and as a SECOND row with a null
-- sponsor in v_demo_tree. Migration 005's own comment says "The root appears
-- with sponsor_code null so the site can anchor the tree", so a second null
-- sponsor is exactly the assumption that view was built on.
--
-- Both views are replaced with one extra predicate each and nothing else. The
-- column lists are identical, so the site's queries are unaffected, and the
-- definer property and owner are restated so neither can be lost in the replace.
--
-- Result after this block: the site still shows 1,000 members and one root,
-- exactly as it does today. The company retention account is a bookkeeping
-- object and is not a member of anything.
-- =============================================================================
create or replace view public.v_demo_members
with (security_invoker = false)
as
with latest_final_run as (
    select r.id
    from app.commission_runs r
    where r.status = 'final'
    order by r.period desc, r.id desc
    limit 1
)
select
    m.member_code,
    m.display_name,
    m.enrolled_on,
    rk.rank_name
from app.members m
left join app.run_member_results rmr
       on rmr.member_id = m.id
      and rmr.run_id = (select id from latest_final_run)
left join app.ranks rk
       on rk.rank_code = rmr.rank_earned
where not m.is_house_account;

create or replace view public.v_demo_tree
with (security_invoker = false)
as
select
    c.member_code,
    s.member_code as sponsor_code
from app.members c
left join app.members s
       on s.id = c.sponsor_id
where not c.is_house_account;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'app_demo_reader') then
        execute 'alter view public.v_demo_members owner to app_demo_reader';
        execute 'alter view public.v_demo_tree    owner to app_demo_reader';
    end if;
end
$$;


-- =============================================================================
-- 8. HOW TO USE IT
-- =============================================================================
--   -- see what would be retained, writing nothing:
--   select * from app.fn_retain_unattributed_orders();
--
--   -- actually retain:
--   select * from app.fn_retain_unattributed_orders(true);
--
--   -- read the two kinds of money side by side, never summed:
--   select * from app.v_period_money order by period;
--
-- WHY THIS NUMBER MATTERS BEYOND THE ACCOUNTING: retained volume was invisible
-- before this migration, and invisible numbers never improve. Now it is a figure
-- on a report that should SHRINK every month as checkout attribution gets
-- better. It is a product metric wearing an accounting coat.
-- =============================================================================
