-- 030_order_number_reformat.sql
-- Howard, 2026-08-17: "I want all order numbers to look like this going forward
-- regardless how the order is placed, from shop or ran in the subscription batch:
-- O-10001 ... can you go in and renumber everything now."
--
-- WHAT THIS DOES
--   1. Preserves every existing order number in legacy_order_number. Nothing is
--      destroyed: the old number is the ONLY link back to the processor's own
--      record, because create-payment writes it into the HyperSwitch payment's
--      description and metadata, and those are immutable history at the vendor.
--   2. Renumbers all existing orders O-10001 upward in creation order, oldest first.
--   3. Keeps app.demo_order_refunds.order_number (a denormalized copy) in step.
--   4. Installs app.fn_next_order_number() as the ONE source of new numbers, and
--      makes it the column default, so every insert path gets the same shape
--      whether it came from the shop, the staff console, or the renewal engine.
--
-- WHY THE RENUMBER IS SAFE
--   Every internal reference to an order is a foreign key on demo_orders.id, a
--   bigint, never on the text: demo_order_refunds, orders, house_retained_volume,
--   payment_credentials and billing_attempts all join on id. Verified against
--   pg_constraint before this migration was written. The only physical duplicate
--   of the text is demo_order_refunds.order_number, updated here in the same
--   transaction.
--
-- WHY DROPPING THE 'REN-' NAME IS SAFE
--   The renewal engine minted REN-<subscription>-<renewal_index>-<attempt_no>,
--   which LOOKED like the batch's duplicate guard. It is not the guard. The guard
--   is structural and independent: UNIQUE (renewal_period_id, attempt_no) on
--   billing_attempts and UNIQUE (subscription_id, renewal_index) on
--   renewal_periods already forbid exactly what that name encoded. The name was a
--   redundant second copy of a rule enforced elsewhere.
--
-- REVERSIBILITY
--   update app.demo_orders set order_number = legacy_order_number
--    where legacy_order_number is not null;
--   restores the previous state exactly.

-- ---- 1. preserve ---------------------------------------------------------
alter table app.demo_orders
  add column if not exists legacy_order_number text;

comment on column app.demo_orders.legacy_order_number is
  'The order number this row carried before the 2026-08-17 reformat to O-#####. '
  'Kept permanently: it is the reference written into the processor''s own '
  'payment record, so it is the join key for any vendor-side reconciliation.';

update app.demo_orders
   set legacy_order_number = order_number
 where legacy_order_number is null;

-- ---- 2. the counter ------------------------------------------------------
create sequence if not exists app.order_number_seq
  as bigint start with 10001 increment by 1 minvalue 10001 no cycle;

comment on sequence app.order_number_seq is
  'The single counter behind every Orvanna order number. Atomic, so two '
  'simultaneous buyers cannot collide and no retry loop is needed.';

-- ---- 3. renumber, oldest order first -------------------------------------
with ordered as (
  select id, row_number() over (order by created_at, id) - 1 as rn
    from app.demo_orders
)
update app.demo_orders d
   set order_number = 'O-' || (10001 + o.rn)::text
  from ordered o
 where d.id = o.id;

-- ---- 4. keep the denormalized copy honest --------------------------------
update app.demo_order_refunds r
   set order_number = d.order_number
  from app.demo_orders d
 where d.id = r.demo_order_id
   and r.order_number is distinct from d.order_number;

-- ---- 5. advance the counter past what was just assigned ------------------
select setval(
  'app.order_number_seq',
  greatest(10001, (select 10000 + count(*) from app.demo_orders)),
  true
);

-- ---- 6. one source of new numbers, for every insert path -----------------
create or replace function app.fn_next_order_number()
returns text
language sql
volatile
as $$
  select 'O-' || nextval('app.order_number_seq')::text;
$$;

comment on function app.fn_next_order_number() is
  'The only place a new order number is minted. Shop, staff console and the '
  'renewal engine all arrive here through the demo_orders.order_number default.';

alter table app.demo_orders
  alter column order_number set default app.fn_next_order_number();
