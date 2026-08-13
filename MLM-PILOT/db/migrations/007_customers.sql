-- Migration 007: customer accounts (schema spec v1.2)
-- Purpose: add app.customers and wire the customer attribution rule into
--          app.orders. Customers buy through one referring member and never
--          join the genealogy, never qualify, never hold rank, never earn.
--          THE ATTRIBUTION RULE (schema spec v1.2, app.orders): a customer's
--          order is booked with member_id = the REFERRING MEMBER's account,
--          so volume rolls up at purchase time, and customer_id = the actual
--          buyer, so the receipt stays auditable. The commission engine needs
--          no knowledge of customers; it aggregates account volume exactly as
--          before. Also ships the two v1.2 demo views (v_demo_customers,
--          v_demo_customer_volume) in the same definer pattern as migration
--          005, and Row-Level Security (RLS) on app.customers in the same
--          pattern as migration 003: no anon or authenticated policies, one
--          SELECT policy for the app_demo_reader definer role.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)

-- ---------------------------------------------------------------------------
-- app.customers
-- ---------------------------------------------------------------------------
create table app.customers (
    id                  bigint generated always as identity primary key,
    customer_code       text   not null unique,
    display_name        text   not null,
    email               text   not null,
    referring_member_id bigint not null references app.members(id),
    enrolled_on         date   not null,
    status              text   not null check (status in ('active', 'closed'))
);

create index customers_referring_member_id_idx
    on app.customers (referring_member_id);

-- ---------------------------------------------------------------------------
-- app.orders: the buyer column and the attribution check.
-- (buyer_role = 'retail_customer') = (customer_id is not null) makes the tag
-- and the receipt inseparable: a customer order always names its customer,
-- and no member order can carry one.
-- ---------------------------------------------------------------------------
alter table app.orders
    add column customer_id bigint null references app.customers(id);

alter table app.orders
    add constraint orders_customer_attribution_check
    check ((buyer_role = 'retail_customer') = (customer_id is not null));

-- ---------------------------------------------------------------------------
-- Row-Level Security: same posture as every other app table (migration 003).
-- No anon or authenticated policy exists; the published anon key reads
-- nothing from tables. app_demo_reader gets SELECT (grant plus policy) so
-- the definer views below can read.
-- ---------------------------------------------------------------------------
alter table app.customers enable row level security;

grant select on app.customers to app_demo_reader;

create policy demo_reader_select_customers on app.customers
    for select to app_demo_reader using (true);

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.customers from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.customers from authenticated;
    end if;
end
$$;

-- ---------------------------------------------------------------------------
-- v_demo_customers: customer_code, display_name, referring member_code,
-- enrolled_on. No email, no internal ids: customer_code and the referring
-- member's member_code are the only identifiers exposed.
-- ---------------------------------------------------------------------------
create view public.v_demo_customers
with (security_invoker = false)
as
select
    c.customer_code,
    c.display_name,
    m.member_code as referring_member_code,
    c.enrolled_on
from app.customers c
join app.members m
  on m.id = c.referring_member_id;

-- ---------------------------------------------------------------------------
-- v_demo_customer_volume: member_code, volume_month, customer_sv: the slice
-- of that member's Sales Volume (SV) that came from customer purchases,
-- computed from completed orders where buyer_role = 'retail_customer'
-- (completed only, matching the SV definition in the comp plan spec). Like
-- v_demo_tree this view carries no run data, so it has no final-run filter.
-- ---------------------------------------------------------------------------
create view public.v_demo_customer_volume
with (security_invoker = false)
as
select
    m.member_code,
    o.volume_month,
    sum(l.quantity * l.unit_volume) as customer_sv
from app.orders o
join app.order_lines l
  on l.order_id = o.id
join app.members m
  on m.id = o.member_id
where o.buyer_role = 'retail_customer'
  and o.status = 'completed'
group by m.member_code, o.volume_month;

-- ---------------------------------------------------------------------------
-- Ownership and grants: same pattern as migration 005.
-- ---------------------------------------------------------------------------
alter view public.v_demo_customers       owner to app_demo_reader;
alter view public.v_demo_customer_volume owner to app_demo_reader;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        grant select on public.v_demo_customers,
                        public.v_demo_customer_volume
        to anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        grant select on public.v_demo_customers,
                        public.v_demo_customer_volume
        to authenticated;
    end if;
end
$$;
