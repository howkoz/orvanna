-- S1 proof run, segment 18: THE LIVE DISPATCH SEAM (migration 029), proven
-- to the exact boundary the rig can reach. The rig cannot hit the live
-- vault, so the LIVE half is the deploy-round acceptance written in
-- migration 029; what IS provable locally, and is proven here:
--   the seed function shapes ten test subscriptions with ONLY the two
--     non-3DS sandbox cards, staggered due dates;
--   a live-mode limited tick leaves its attempts honestly DISPATCHED,
--     stamped live, with real demo-order rows the bridge will inherit;
--   the next SIMULATED tick's reconciler does NOT touch them (the script
--     table is never allowed to invent processor truth for a live attempt);
--   the worker's write-back door (fn_record_live_verdict) resolves them
--     through the one shared classification path, stamps the real payment
--     reference, and the bridge books the volume.

-- Ten fresh fixture members stand in for the ten real demo members the
-- deploy-round operator will name.
insert into app.members (member_code, display_name, email, sponsor_id, enrolled_on)
select 'GW-94' || lpad(n::text, 2, '0'),
       'Live Seam Member ' || n,
       'liveseam.' || n || '@example.com',
       (select id from app.members where member_code = 'GW-9000'),
       date '2027-11-01'
from generate_series(1, 10) as n;

select app.fn_seed_s2_test_subscriptions(
           date '2027-11-06',
           array['GW-9401','GW-9402','GW-9403','GW-9404','GW-9405',
                 'GW-9406','GW-9407','GW-9408','GW-9409','GW-9410'])
       as seeded_subscriptions;

select 'seam: seeded credentials carry ONLY the two non-3DS sandbox cards' as label,
       count(*) as credentials,
       count(*) filter (where c.brand = 'visa'       and c.last4 = '4242') as visa_4242,
       count(*) filter (where c.brand = 'mastercard' and c.last4 = '4444') as mc_4444,
       case when count(*) = 10
             and count(*) filter (where c.last4 not in ('4242', '4444')) = 0
            then 'PASS' else 'FAIL' end as verdict
  from app.payment_credentials c
  join app.members m on m.id = c.member_id
 where m.member_code like 'GW-94%';

-- The live-mode limited run: two of the ten are due 2027-11-06.
select app.fn_billing_tick(date '2027-11-06', 2, 'live') as live_run_id;

select 'seam: live run record (2 of 2, dispatch_mode live)' as label,
       limit_requested, due_count, processed_count, remaining_count, dispatch_mode
  from app.billing_runs where tick_date = date '2027-11-06' and status = 'final';

select 'seam: attempts left honestly dispatched for the worker' as label,
       count(*) as live_dispatched,
       case when count(*) = 2 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts ba
 where ba.outcome = 'dispatched' and ba.dispatch_mode = 'live';

-- A simulated tick passes THROUGH the live strands without touching them
-- (and sim-bills the two members due Nov 7 normally: the modes coexist).
select app.fn_billing_tick(date '2027-11-07') as sim_run_id;

select 'seam: the sim reconciler did NOT invent truth for the live attempts' as label,
       count(*) as still_dispatched_live,
       case when count(*) = 2 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts ba
 where ba.outcome = 'dispatched' and ba.dispatch_mode = 'live';

-- The worker's write-back, exactly as the console Edge Function will call
-- it after the HyperSwitch retrieve (payment ids are stand-ins shaped like
-- the real ones).
do $$
declare
    v_att bigint;
    v_i   int := 0;
begin
    for v_att in
        select ba.id from app.billing_attempts ba
         where ba.outcome = 'dispatched' and ba.dispatch_mode = 'live'
         order by ba.id
    loop
        v_i := v_i + 1;
        perform app.fn_record_live_verdict(
            v_att, 'succeeded', null, 'pay_livetest_' || v_i);
    end loop;
end
$$;

-- The worker bridges after verdicts, as its contract says.
select count(*) as bridge_report_rows from app.fn_bridge_demo_orders(true);

select 'seam: verdicts landed with the real payment identity' as label,
       count(*) as live_orders,
       case when count(*) = 2
             and bool_and(d.payment_status = 'succeeded')
             and bool_and((d.processor_summary ->> 'simulated') = 'false')
            then 'PASS' else 'FAIL' end as verdict
  from app.demo_orders d
  join app.members m on m.id = d.member_id
 where m.member_code like 'GW-94%'
   and d.payment_reference like 'pay_livetest_%';

select 'segment 18 complete, clock now' as label, clock_date from app.sim_clock;
