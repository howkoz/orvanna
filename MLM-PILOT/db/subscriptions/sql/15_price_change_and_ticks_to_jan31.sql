-- S1 proof run, segment 15: tick to mid-December, change the catalog price
-- (failure mode FM3, stale pricing), then tick through 2027-01-31.
--
-- HANK billed 100.00 for the Shipping Agent on Dec 1. On Dec 14 (between
-- ticks, exactly how a catalog edit lands) the monthly price moves to 110.00
-- with PV 110 (PV equals dollars, the plan's invariant, so both move
-- together). His Jan 1 renewal must bill 110.00 with NO code change and NO
-- data fix, because the subscription row has no price to go stale: pricing
-- happens at billing time from the single source.

do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2026-12-02', date '2026-12-14',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

-- The catalog change. app.products is the database mirror of the pricing
-- source (catalog.js / pricing.ts); a catalog edit is an UPDATE here.
update app.products
   set price = 110.00, volume_points = 110.00
 where sku = 'AGT-D-002';

select 'price change applied 2026-12-14' as label, sku, price, volume_points
  from app.products where sku = 'AGT-D-002';

do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2026-12-15', date '2027-01-31',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

select 'segment 15 complete, clock now' as label, clock_date from app.sim_clock;
