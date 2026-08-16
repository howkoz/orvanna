-- S1 proof run, segment 14: THE DOUBLE TICK (failure mode FM1, double release).
-- 2026-12-01 is a busy billing day (every day-1 monthly subscription, plus
-- HANK's first cycle). The tick runs once, normally. Then the SAME date is
-- ticked AGAIN: the rerun must supersede the first run, find every cycle
-- already accounted under the (subscription_id, renewal_index) key, and
-- produce EXACTLY ZERO new periods, attempts, demo orders, or bridged
-- order rows. The database key is the lock, not discipline.

select app.fn_billing_tick(date '2026-12-01') as first_run_id;

create temp table pre_double as
select (select count(*) from app.renewal_periods)  as periods,
       (select count(*) from app.billing_attempts) as attempts,
       (select count(*) from app.demo_orders)      as demo_orders,
       (select count(*) from app.orders)           as orders;

select app.fn_billing_tick(date '2026-12-01') as double_tick_run_id;

select 'double-tick: new rows created by the second tick (all must be 0)' as label,
       (select count(*) from app.renewal_periods)  - p.periods     as new_periods,
       (select count(*) from app.billing_attempts) - p.attempts    as new_attempts,
       (select count(*) from app.demo_orders)      - p.demo_orders as new_demo_orders,
       (select count(*) from app.orders)           - p.orders      as new_orders
  from pre_double p;

select 'double-tick: run rows for 2026-12-01 (first superseded, rerun final)' as label,
       id, status from app.billing_runs
 where tick_date = date '2026-12-01' order by id;

select 'double-tick: one billing for 2026-12-01 per subscription' as label,
       count(*) as periods_scheduled_today,
       count(distinct subscription_id) as distinct_subscriptions
  from app.renewal_periods where scheduled_date = date '2026-12-01';
