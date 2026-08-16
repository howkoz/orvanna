-- =============================================================================
-- S1 proof battery: every acceptance proof as a query that answers PASS or
-- FAIL with its key numbers on the row. Run after the full simulated year
-- and the commission runs. The harness greps for 'FAIL'.
-- Acronym key: Personal Volume (PV), Sales Volume (SV), Commissionable
-- Volume (CV), failure mode (FM).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- PROOF A (FM1, double tick): asserted live in segment 14; re-asserted here
-- from the durable record: exactly one FINAL run per tick date, and every
-- cycle accounted exactly once.
-- ---------------------------------------------------------------------------
select 'A1: one final run per tick date' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) || ' dates' end as verdict
  from (select tick_date from app.billing_runs where status = 'final'
         group by tick_date having count(*) > 1) x;

select 'A2: superseded rerun evidence exists for 2026-12-01' as proof,
       case when count(*) filter (where status = 'superseded') >= 1
             and count(*) filter (where status = 'final') = 1
            then 'PASS' else 'FAIL' end as verdict,
       count(*) as run_rows
  from app.billing_runs where tick_date = date '2026-12-01';

select 'A3: every cycle accounted exactly once (the FM1 key held)' as proof,
       case when count(*) = count(distinct (subscription_id, renewal_index))
            then 'PASS' else 'FAIL' end as verdict,
       count(*) as periods
  from app.renewal_periods;

-- ---------------------------------------------------------------------------
-- PROOF B (FM2, orphan and crash-mid-batch): re-asserted from the record.
-- ---------------------------------------------------------------------------
select 'B1: no attempt is left non-terminal at year end' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts where outcome = 'dispatched';

select 'B2: the crash batch billed exactly once each (60 of 60 paid)' as proof,
       case when count(*) = 660 and count(*) filter (where rp.outcome = 'paid') = 660
            then 'PASS'
            else 'FAIL: ' || count(*) || ' periods, '
                 || count(*) filter (where rp.outcome = 'paid') || ' paid' end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id
 where m.member_code like 'GW-92%';
-- 660 = 60 members x 11 monthly cycles (2026-11-15 through 2027-09-15).

select 'B3: the scripted orphan (GW-9247 cycle 1) resolved on its ORIGINAL attempt row' as proof,
       case when count(*) = 1
             and bool_and(ba.attempt_no = 1 and ba.outcome = 'succeeded')
            then 'PASS' else 'FAIL' end as verdict,
       count(*) as attempts_for_cycle_1
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id and rp.renewal_index = 1
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9247';

select 'B4: the crashed run row survives as superseded history' as proof,
       case when count(*) = 1 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_runs
 where tick_date = date '2026-11-15' and status = 'superseded'
   and notes like 'SIMULATED CRASH after 47 dispatches%';

-- ---------------------------------------------------------------------------
-- PROOF C (FM3, stale pricing impossible)
-- ---------------------------------------------------------------------------
select 'C1: HANK Dec billed the old price, Jan the new, to the cent' as proof,
       case when min(rp.amount_cents) filter (where rp.scheduled_date = date '2026-12-01') = 10000
             and min(rp.amount_cents) filter (where rp.scheduled_date = date '2027-01-01') = 11000
             and min(rp.pv_total)     filter (where rp.scheduled_date = date '2027-01-01') = 110.00
            then 'PASS' else 'FAIL' end as verdict,
       min(rp.amount_cents) filter (where rp.scheduled_date = date '2026-12-01') as dec_cents,
       min(rp.amount_cents) filter (where rp.scheduled_date = date '2027-01-01') as jan_cents
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9006';

select 'C2: the schema has NO stored-price path on subscriptions at all' as proof,
       case when count(*) = 0 then 'PASS'
            else 'FAIL: ' || string_agg(column_name, ', ') end as verdict
  from information_schema.columns
 where table_schema = 'app' and table_name = 'subscriptions'
   and (column_name ilike '%price%' or column_name ilike '%amount%'
        or column_name ilike '%cents%');

-- ---------------------------------------------------------------------------
-- PROOF D (FM4, the skipped month): FRED, anchored 2026-10-31, twelve
-- accounted cycles, zero gaps, Feb clamped to the 28th, back on the 31st.
-- ---------------------------------------------------------------------------
select 'D1: FRED has exactly twelve accounted cycles, all paid' as proof,
       case when count(*) = 12 and count(*) filter (where rp.outcome = 'paid') = 12
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9005';

select 'D2: FRED cycle dates clamp and return, never drift' as proof,
       case when string_agg(rp.scheduled_date::text, ',' order by rp.renewal_index)
            = '2026-10-31,2026-11-30,2026-12-31,2027-01-31,2027-02-28,'
              || '2027-03-31,2027-04-30,2027-05-31,2027-06-30,2027-07-31,'
              || '2027-08-31,2027-09-30'
            then 'PASS'
            else 'FAIL: ' || string_agg(rp.scheduled_date::text, ',' order by rp.renewal_index)
       end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9005';

select 'D3: the cycle audit shows ZERO gaps across every billing-state subscription' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) || ' gaps' end as verdict
  from app.v_cycle_audit where not accounted;

-- ---------------------------------------------------------------------------
-- PROOF E (FM5, the corrupted credential): DANA.
-- ---------------------------------------------------------------------------
select 'E1: every DANA attempt stopped at pre-flight, classified internal_config' as proof,
       case when count(*) >= 12
             and bool_and(ba.outcome = 'preflight_failed'
                          and ba.decline_class = 'internal_config'
                          and ba.member_fault = false
                          and ba.demo_order_id is null)
            then 'PASS' else 'FAIL' end as verdict,
       count(*) as preflight_stops
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9004';

select 'E2: zero retries ever ran for DANA (one attempt per cycle, no ladder)' as proof,
       case when max(ba.attempt_no) = 1 then 'PASS'
            else 'FAIL: max attempt_no ' || max(ba.attempt_no) end as verdict
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9004';

select 'E3: DANA''s dunning and auto-cancel clocks are untouched (state active, zero member-fault events)' as proof,
       case when s.state = 'active'
             and not exists (select 1 from app.subscription_events e
                              where e.subscription_id = s.id
                                and e.to_state in ('past_due', 'dunning',
                                                   'suspended', 'cancelled',
                                                   'card_update_required'))
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9004';

select 'E4: DANA is surfaced in the staff attention queue as a system fault' as proof,
       case when count(*) >= 12 then 'PASS' else 'FAIL: ' || count(*) end as verdict,
       count(*) as attention_rows
  from app.v_staff_attention_queue q
  join app.subscriptions s on s.id = q.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9004'
 where q.reason = 'system_fault';

select 'E5: never reached the processor: DANA has zero demo orders' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.demo_orders d
  join app.members m on m.id = d.member_id and m.member_code = 'GW-9004';

-- ---------------------------------------------------------------------------
-- WORKED EXAMPLE A (spec section 11): soft decline recovered by the plus-8
-- retry; qualified; Beth earns 8.00.
-- ---------------------------------------------------------------------------
select 'W-A1: ANN A attempt trail is decline,decline,decline,success on Sep 1,3,5,9' as proof,
       case when string_agg(ba.scheduled_for::text || ':' || ba.outcome,
                            ',' order by ba.attempt_no)
            = '2026-09-01:declined,2026-09-03:declined,2026-09-05:declined,2026-09-09:succeeded'
            then 'PASS'
            else 'FAIL: ' || string_agg(ba.scheduled_for::text || ':' || ba.outcome,
                                        ',' order by ba.attempt_no) end as verdict
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id and rp.renewal_index = 1
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9001';

select 'W-A2: ANN A September SV is exactly 100.00' as proof,
       case when coalesce(sum(ol.quantity * ol.unit_volume), 0) = 100.00
            then 'PASS' else 'FAIL: ' || coalesce(sum(ol.quantity * ol.unit_volume), 0) end as verdict
  from app.orders o
  join app.order_lines ol on ol.order_id = o.id
  join app.members m on m.id = o.member_id and m.member_code = 'GW-9001'
 where o.volume_month = date '2026-09-01';

select 'W-A3: Beth earns exactly 8.00 from ANN A in the September run' as proof,
       case when count(*) = 1 and min(cl.amount) = 8.00 and min(cl.source_cv) = 80.00
            then 'PASS' else 'FAIL: ' || count(*) || ' lines' end as verdict
  from app.commission_lines cl
  join app.commission_runs r on r.id = cl.run_id and r.period = date '2026-09-01'
  join app.members e on e.id = cl.earner_id        and e.member_code = 'GW-9000'
  join app.members src on src.id = cl.source_member_id and src.member_code = 'GW-9001'
 where cl.level = 1;

-- ---------------------------------------------------------------------------
-- WORKED EXAMPLE B: retries exhaust; not qualified; suspension then
-- auto-cancel; Beth's line does not exist.
-- ---------------------------------------------------------------------------
select 'W-B1: ANN B ran six attempts on Sep 1,3,5,9,16,23, all declined' as proof,
       case when string_agg(ba.scheduled_for::text, ',' order by ba.attempt_no)
                 = '2026-09-01,2026-09-03,2026-09-05,2026-09-09,2026-09-16,2026-09-23'
             and bool_and(ba.outcome = 'declined')
            then 'PASS'
            else 'FAIL: ' || string_agg(ba.scheduled_for::text || ':' || ba.outcome,
                                        ',' order by ba.attempt_no) end as verdict
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id and rp.renewal_index = 1
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9002';

select 'W-B2: ANN B entered dunning when the plus-8 retry failed (Sep 9), suspended at the Sep 26 checkpoint' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'dunning'
                            and e.occurred_on = date '2026-09-09')
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'suspended'
                            and e.occurred_on = date '2026-09-26')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9002';

select 'W-B3: ANN B September SV is 0.00 and the period is frozen unpaid' as proof,
       case when not exists (select 1 from app.orders o
                              where o.member_id = m.id
                                and o.volume_month = date '2026-09-01')
             and (select rp.outcome from app.renewal_periods rp
                   join app.subscriptions s on s.id = rp.subscription_id
                  where s.member_id = m.id and rp.renewal_index = 1) = 'unpaid'
            then 'PASS' else 'FAIL' end as verdict
  from app.members m where m.member_code = 'GW-9002';

select 'W-B4: Beth has NO commission line from ANN B in September' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.commission_lines cl
  join app.commission_runs r on r.id = cl.run_id and r.period = date '2026-09-01'
  join app.members src on src.id = cl.source_member_id and src.member_code = 'GW-9002';

select 'W-B5: ANN B auto-cancelled on Nov 1 after two consecutive unpaid months (T22, R4)' as proof,
       case when s.state = 'cancelled'
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'cancelled'
                            and e.occurred_on = date '2026-11-01'
                            and e.cause like 'T22%')
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9002';

-- ---------------------------------------------------------------------------
-- WORKED EXAMPLE C: quarterly spread (rulings R6/OQ1, bridge amendment 027).
-- ---------------------------------------------------------------------------
select 'W-C1: CARL''s Oct 1 quarterly billing charged 30000 cents' as proof,
       case when rp.amount_cents = 30000 and rp.pv_total = 300.00
             and rp.covered_months = 3 and rp.outcome = 'paid'
            then 'PASS' else 'FAIL: ' || rp.amount_cents end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9003'
 where rp.renewal_index = 1;

select 'W-C2: the bridge spread it into exactly 100 PV in Oct, Nov, Dec' as proof,
       case when string_agg(x.volume_month::text || ':' || x.sv, ',' order by x.volume_month)
            = '2026-10-01:100.00,2026-11-01:100.00,2026-12-01:100.00'
            then 'PASS'
            else 'FAIL: ' || string_agg(x.volume_month::text || ':' || x.sv,
                                        ',' order by x.volume_month) end as verdict
  from (select o.volume_month, sum(ol.quantity * ol.unit_volume)::numeric(12,2) as sv
          from app.orders o
          join app.order_lines ol on ol.order_id = o.id
          join app.members m on m.id = o.member_id and m.member_code = 'GW-9003'
         where o.volume_month between date '2026-10-01' and date '2026-12-01'
         group by o.volume_month) x;

select 'W-C3: Beth earns exactly 8.00 from CARL in EACH of Oct, Nov, Dec' as proof,
       case when count(*) = 3 and bool_and(cl.amount = 8.00)
            then 'PASS' else 'FAIL: ' || count(*) || ' lines' end as verdict
  from app.commission_lines cl
  join app.commission_runs r on r.id = cl.run_id
       and r.period in (date '2026-10-01', date '2026-11-01', date '2026-12-01')
  join app.members e   on e.id   = cl.earner_id        and e.member_code   = 'GW-9000'
  join app.members src on src.id = cl.source_member_id and src.member_code = 'GW-9003'
 where cl.level = 1;

-- ---------------------------------------------------------------------------
-- THE EVOLUTION AND THE EPOCH (spec 6.1 backfill; deviation D7)
-- ---------------------------------------------------------------------------
select 'S1: legacy rows backfilled exactly (monthly, anchored at start_month, states preserved)' as proof,
       case when count(*) = 3
             and bool_and(s.frequency_months = 1
                          and s.billing_anchor_date = s.start_month)
             and count(*) filter (where s.state = 'cancelled'
                                    and s.cancel_month is not null) = 1
             and count(*) filter (where s.state = 'active') = 2
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id
 where m.member_code like 'GW-91%';

select 'S2: the engine epoch stopped any catch-up billing of seeded history' as proof,
       case when min(rp.scheduled_date) = date '2026-09-01'
             and min(rp.renewal_index) = 21
            then 'PASS'
            else 'FAIL: first ' || min(rp.scheduled_date) || ' index ' || min(rp.renewal_index)
       end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id
 where m.member_code like 'GW-91%';

-- ---------------------------------------------------------------------------
-- GLOBAL INVARIANTS (spec section 14, verifier row 4)
-- ---------------------------------------------------------------------------
select 'G1: no volume without a succeeded demo order (R2 structural)' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.orders o
  join app.demo_orders d on d.id = o.demo_order_id
 where d.payment_status <> 'succeeded';

select 'G2: no retry ever followed a hard, cancellation, config, duplicate, auth, or internal_config classification' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts ba
  join app.billing_attempts nxt
    on nxt.renewal_period_id = ba.renewal_period_id
   and nxt.attempt_no = ba.attempt_no + 1
 where ba.decline_class in ('hard', 'cancellation', 'cancellation_all',
                            'config', 'duplicate', 'auth', 'internal_config');

select 'G3: no executed attempt outside its billing month or above day 26 (rule C1)' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.attempt_no > 1
   and ba.outcome in ('succeeded', 'declined', 'processor_unreachable')
   and (date_trunc('month', ba.scheduled_for) <> date_trunc('month', rp.scheduled_date)
        or extract(day from ba.scheduled_for)::int > 26);

select 'G4: every run asserts the promo hook was identity and the MIT invariant held' as proof,
       case when bool_and(promo_hook_identity) and bool_and(mit_invariant_ok)
            then 'PASS' else 'FAIL' end as verdict,
       count(*) as final_runs
  from app.billing_runs where status = 'final';

select 'G5: member-fault and system-fault failures are reported separately and never mix' as proof,
       case when not exists (select 1 from app.billing_attempts
                              where decline_class in ('infra', 'config', 'duplicate', 'internal_config')
                                and member_fault = true)
            then 'PASS' else 'FAIL' end as verdict;

select 'G6: the attention queue is empty of orphans and cycle gaps at year end' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.v_staff_attention_queue
 where reason in ('orphaned_attempt', 'cycle_gap');

select 'G7: the clock advance log is day-continuous (the deliberate skip wrote its own logged advance)' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) || ' anomalies' end as verdict
  from (select to_date - lag(to_date) over (order by id) as gap
          from app.sim_clock_advances) x
 where x.gap is not null and x.gap <> 1;
-- The 2027-02-01 skip has no RUN of its own but does write its own advance
-- row (Jan 31 to Feb 1), so the log stays one-day continuous end to end; the
-- skipped day is visible as the advance row whose advanced_by_run is null.

select 'G8: pricing totals reconcile: every paid period equals its demo order total' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.outcome = 'succeeded'
  join app.demo_orders d on d.id = ba.demo_order_id
 where rp.outcome = 'paid' and d.total_cents <> rp.amount_cents;
