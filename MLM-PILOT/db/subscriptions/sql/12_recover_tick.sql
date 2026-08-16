-- S1 proof run, segment 12: THE RECOVERY RERUN (FM2 resolution).
-- The same tick date runs again in a fresh session (the crashed process is
-- gone; no lever set). The reconciler opens the run by retrieving the truth
-- for all 47 stranded attempts: 46 were received and approved by the
-- processor; batch member 47's dispatch was never received (the scripted
-- orphan), so its strand is consumed and the SAME attempt re-dispatched
-- idempotently under the per-cycle key. The gather step then finds cycles
-- 48 through 60 unaccounted and bills them once each.

select app.fn_billing_tick(date '2026-11-15') as recovery_run_id;

select 'recover: batch periods accounted' as label,
       count(*)                                   as periods,
       count(distinct rp.subscription_id)         as distinct_subscriptions,
       count(*) filter (where rp.outcome = 'paid') as paid
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id
 where m.member_code like 'GW-92%';

select 'recover: attempts per batch cycle (must all be 1)' as label,
       max(cnt) as max_attempts_per_cycle,
       min(cnt) as min_attempts_per_cycle
  from (select rp.id, count(ba.id) as cnt
          from app.renewal_periods rp
          join app.subscriptions s on s.id = rp.subscription_id
          join app.members m on m.id = s.member_id
          join app.billing_attempts ba on ba.renewal_period_id = rp.id
         where m.member_code like 'GW-92%'
         group by rp.id) x;

select 'recover: batch demo orders (must be 60, all succeeded)' as label,
       count(*) as demo_orders,
       count(*) filter (where d.payment_status = 'succeeded') as succeeded
  from app.demo_orders d
  join app.members m on m.id = d.member_id
 where m.member_code like 'GW-92%';

select 'recover: stranded attempts remaining (must be 0)' as label,
       count(*) as still_dispatched
  from app.billing_attempts where outcome = 'dispatched';

select 'recover: run rows for 2026-11-15 (crashed superseded, rerun final)' as label,
       id, status, attempts_reconciled, notes
  from app.billing_runs where tick_date = date '2026-11-15' order by id;
