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
       case when count(*) = 720 and count(*) filter (where rp.outcome = 'paid') = 720
            then 'PASS'
            else 'FAIL: ' || count(*) || ' periods, '
                 || count(*) filter (where rp.outcome = 'paid') || ' paid' end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id
 where m.member_code like 'GW-92%';
-- 720 = 60 members x 12 monthly cycles (2026-11-15 through 2027-10-15; the
-- clock ends 2027-11-07, before the thirteenth cycle).

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
-- FRED note: the sim now runs past his twelfth cycle (a thirteenth, 2027-10-31,
-- bills in the segment 17 October ticks). The FM4 February-crossing proof is
-- the TWELVE-cycle window, so D1/D2 scope to renewal_index 1 to 12; the
-- thirteenth cycle is covered by the global audits (D3, GX1).
select 'D1: FRED, the twelve-cycle FM4 window, all accounted, all paid' as proof,
       case when count(*) = 12 and count(*) filter (where rp.outcome = 'paid') = 12
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9005'
 where rp.renewal_index <= 12;

-- The twelve dates PRINTED VERBATIM (QA L1: the proof document quotes the
-- transcript rather than presenting an asserted-equal string as recorded):
select 'D2-print: FRED cycle ' || rp.renewal_index as label,
       rp.scheduled_date, rp.outcome
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9005'
 where rp.renewal_index <= 12
 order by rp.renewal_index;

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
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9005'
 where rp.renewal_index <= 12;

select 'D3: the cycle audit shows ZERO gaps across every billing-state subscription' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) || ' gaps' end as verdict
  from app.v_cycle_audit where not accounted;

-- ---------------------------------------------------------------------------
-- PROOF E (FM5, the corrupted credential): DANA.
-- ---------------------------------------------------------------------------
select 'E1: every DANA attempt stopped at pre-flight, classified internal_config' as proof,
       case when count(*) = 15   -- exactly: 15 monthly cycles, Sep 2026 through Nov 2027 (QA L3: equality, not a floor)
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

-- DANA's count note: 15 cycles because the simulated run now extends to
-- 2027-11-07 (the limit and live-seam segments); the last cycle (Nov 1,
-- gathered in the limited first five) is her fifteenth pre-flight stop.
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
       case when count(*) = 15 then 'PASS' else 'FAIL: ' || count(*) end as verdict,
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

-- ===========================================================================
-- FIX-ROUND PROOFS (2026-08-16, spec v1.1, both gate verdicts).
-- FQ = frequencies, MA = member actions, MG = guards, GX = new globals.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- FQ: bi-monthly and semi-annual actually BILL, COVER and SPREAD (QA M2,
-- verifier M5).
-- ---------------------------------------------------------------------------
select 'FQ1: OSCAR bi-monthly billed 8 cycles of 20000 cents covering 2 months each, all paid' as proof,
       case when count(*) = 8   -- Sep/Nov 2026, Jan/Mar/May/Jul/Sep 2027, and Nov 2027 (the limited-run segment)
             and bool_and(rp.amount_cents = 20000 and rp.covered_months = 2
                          and rp.outcome = 'paid')
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9007';

select 'FQ2: OSCAR volume spreads to exactly 100.00 in each of the 12 months Sep 2026 to Aug 2027' as proof,
       case when count(*) = 12 and bool_and(x.sv = 100.00)
            then 'PASS' else 'FAIL: ' || count(*) || ' months' end as verdict
  from (select o.volume_month, sum(ol.quantity * ol.unit_volume)::numeric(12,2) as sv
          from app.orders o
          join app.order_lines ol on ol.order_id = o.id
          join app.members m on m.id = o.member_id and m.member_code = 'GW-9007'
         where o.volume_month between date '2026-09-01' and date '2027-08-01'
         group by o.volume_month) x;

select 'FQ3: SARA semi-annual billed 3 cycles of 60000 cents covering 6 months each, all paid' as proof,
       case when count(*) = 3   -- Oct 2026, Apr 2027, Oct 2027 (the sim now reaches October)
             and bool_and(rp.amount_cents = 60000 and rp.covered_months = 6
                          and rp.outcome = 'paid')
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9008';

select 'FQ4: SARA volume spreads to exactly 100.00 in each of the 12 months Oct 2026 to Sep 2027' as proof,
       case when count(*) = 12 and bool_and(x.sv = 100.00)
            then 'PASS' else 'FAIL: ' || count(*) || ' months' end as verdict
  from (select o.volume_month, sum(ol.quantity * ol.unit_volume)::numeric(12,2) as sv
          from app.orders o
          join app.order_lines ol on ol.order_id = o.id
          join app.members m on m.id = o.member_id and m.member_code = 'GW-9008'
         where o.volume_month between date '2026-10-01' and date '2027-09-01'
         group by o.volume_month) x;

-- ---------------------------------------------------------------------------
-- MA: the member-action year (verifier H1 scenarios, QA M3).
-- ---------------------------------------------------------------------------
select 'MA1: PETE paused mid-ladder WITHOUT error (the H1 case): T10 event, retry clipped on the record, period unpaid' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'pause'
                            and e.from_state = 'past_due'
                            and e.occurred_on = date '2026-09-04')
             and exists (select 1 from app.billing_attempts ba
                          join app.renewal_periods rp on rp.id = ba.renewal_period_id
                         where rp.subscription_id = s.id and rp.renewal_index = 1
                           and ba.outcome = 'skipped_clipped')
             and (select rp.outcome from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.renewal_index = 1) = 'unpaid'
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9011';

select 'MA2: PETE paused months materialised skipped_paused (Oct+Nov), auto-resumed Nov 4, next cycle Dec 1 paid' as proof,
       case when exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id and rp.outcome = 'skipped_paused'
                            and rp.covered_month_first = date '2026-10-01'
                            and rp.covered_months = 2)
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'resume'
                            and e.occurred_on = date '2026-11-04')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2026-12-01'
                            and rp.outcome = 'paid')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9011';

select 'MA3: QUINN paused FROM DUNNING (T10a lane exists), October skipped_paused, resumed Oct 12' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'pause'
                            and e.from_state = 'dunning'
                            and e.occurred_on = date '2026-09-12')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id and rp.outcome = 'skipped_paused'
                            and rp.covered_month_first = date '2026-10-01'
                            and rp.covered_months = 1)
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'resume'
                            and e.occurred_on = date '2026-10-12')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9012';

select 'MA4: QUINN, the frozen clock (spec v1.1 12.3 micro-example): November fails, suspended Nov 26, auto-cancel DEC 1 counting September plus November through the paused October' as proof,
       case when (select rp.outcome from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.scheduled_date = date '2026-11-01') = 'unpaid'
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'suspended'
                            and e.occurred_on = date '2026-11-26')
             and s.state = 'cancelled'
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'cancelled'
                            and e.occurred_on = date '2026-12-01'
                            and e.cause like 'T22%')
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9012';

select 'MA5: RITA early resume inside the first paused month REFUSED (exactly one resume event, the Nov 20 auto-resume), then Dec 1 paid' as proof,
       case when (select count(*) from app.subscription_events e
                   where e.subscription_id = s.id and e.event_type = 'resume') = 1
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'resume'
                            and e.occurred_on = date '2026-11-20')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2026-12-01'
                            and rp.outcome = 'paid')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9013';

select 'MA6: SAM early resume ALLOWED after one whole month (resume event Nov 10, active, next cycle Jan 1 paid, Nov+Dec skipped_paused)' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'resume'
                            and e.occurred_on = date '2026-11-10'
                            and e.cause like 'early resume%')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id and rp.outcome = 'skipped_paused'
                            and rp.covered_month_first = date '2026-11-01'
                            and rp.covered_months = 2)
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2027-01-01'
                            and rp.outcome = 'paid')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9014';

select 'MA7: TINA cancelled during dunning (T15) on Sep 12: no attempt after Sep 9, period frozen unpaid' as proof,
       case when s.state = 'cancelled'
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'cancelled'
                            and e.occurred_on = date '2026-09-12'
                            and e.cause like 'T15%')
             and (select max(ba.scheduled_for) from app.billing_attempts ba
                   join app.renewal_periods rp on rp.id = ba.renewal_period_id
                  where rp.subscription_id = s.id
                    and ba.outcome in ('succeeded','declined')) = date '2026-09-09'
             and (select rp.outcome from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.renewal_index = 1) = 'unpaid'
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9015';

select 'MA8: UMA decline 2017 cancels THIS subscription same day (T4), period unpaid' as proof,
       case when s.state = 'cancelled'
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'cancelled'
                            and e.occurred_on = date '2026-09-01'
                            and e.cause like 'T4%2017%')
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9016';

select 'MA9: VIC decline 2018 cancels EVERY subscription he holds; the second never billed at all' as proof,
       case when count(*) = 2
             and bool_and(s.state = 'cancelled')
             and sum(case when p.sku = 'AGT-S-001'
                          then (select count(*) from app.renewal_periods rp
                                 where rp.subscription_id = s.id)
                          else 0 end) = 0
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9017'
  join app.products p on p.id = s.product_id;

select 'MA10: WALT day-28 zero-survivor ladder (spec 8.3 named case): one attempt only, dunning same day, suspended at MONTH END Sep 30' as proof,
       case when (select count(*) from app.billing_attempts ba
                   join app.renewal_periods rp on rp.id = ba.renewal_period_id
                  where rp.subscription_id = s.id and rp.renewal_index = 1) = 1
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'dunning'
                            and e.occurred_on = date '2026-09-28')
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'suspended'
                            and e.occurred_on = date '2026-09-30')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9018';

select 'MA11: WALT reactivated from suspended (T21) on Oct 10: CIT coverage booked for October, next cycle Nov 28 paid, coherent credential minted' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.event_type = 'reactivation'
                            and e.occurred_on = date '2026-10-10')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id and rp.outcome = 'paid'
                            and rp.covered_month_first = date '2026-10-01'
                            and rp.scheduled_date = date '2026-10-10')
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2026-11-28'
                            and rp.outcome = 'paid')
             and exists (select 1 from app.payment_credentials c
                          where c.member_id = s.member_id and c.retired_on is null
                            and c.brand = 'mastercard')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9018';

select 'MA12: XENA hard decline then reactivation from card_update_required (T16): the same-month CIT covers the open period (index 1 paid), next cycle Oct 15 paid' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'card_update_required'
                            and e.occurred_on = date '2026-09-01')
             and (select rp.outcome from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.renewal_index = 1) = 'paid'
             and exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2026-10-15'
                            and rp.outcome = 'paid')
             and s.state = 'active'
            then 'PASS' else 'FAIL: state ' || s.state end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9019';

select 'MA13: YVES, no card update: suspended at the checkpoint (T17, Sep 26) then auto-cancelled Nov 1 (T22)' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'suspended'
                            and e.occurred_on = date '2026-09-26'
                            and e.cause like 'T17%')
             and exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id and e.to_state = 'cancelled'
                            and e.occurred_on = date '2026-11-01'
                            and e.cause like 'T22%')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9020';

-- ---------------------------------------------------------------------------
-- MG: the OQ4 letter and the frequency guard (verifier M1 and M2).
-- ---------------------------------------------------------------------------
select 'MG1: PAULA transition charge ran 2027-03-25 covering APRIL (the E3 letter); March holds exactly two billings' as proof,
       case when exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2027-03-25'
                            and rp.covered_month_first = date '2027-04-01'
                            and rp.outcome = 'paid')
             and (select count(*) from app.renewal_periods rp
                   where rp.subscription_id = s.id
                     and rp.scheduled_date between date '2027-03-01' and date '2027-03-31') = 2
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9010';

select 'MG2: PAULA thereafter: 2027-04-25 covers MAY, and April volume is exactly 100.00 booked once' as proof,
       case when exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id
                            and rp.scheduled_date = date '2027-04-25'
                            and rp.covered_month_first = date '2027-05-01'
                            and rp.outcome = 'paid')
             and (select sum(ol.quantity * ol.unit_volume) from app.orders o
                   join app.order_lines ol on ol.order_id = o.id
                  where o.member_id = s.member_id
                    and o.volume_month = date '2027-04-01') = 100.00
             and (select sum(ol.quantity * ol.unit_volume) from app.orders o
                   join app.order_lines ol on ol.order_id = o.id
                  where o.member_id = s.member_id
                    and o.volume_month = date '2027-05-01') = 100.00
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9010';

select 'MG3: PAULA''s disclosure event describes what the engine actually does (transition date and next-uncovered-month coverage named)' as proof,
       case when exists (select 1 from app.subscription_events e
                          where e.subscription_id = s.id
                            and e.event_type = 'billing_day_change'
                            and e.cause like '%2027-03-25%'
                            and e.cause like '%next uncovered month%'
                            and e.cause like '%two billings%')
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9010';

select 'MG4: NORA quarterly-to-monthly through the sanctioned function: coverage respected, first monthly charge Jan 1, nine monthly cycles of 10000' as proof,
       case when exists (select 1 from app.renewal_periods rp
                          where rp.subscription_id = s.id and rp.renewal_index = 1
                            and rp.amount_cents = 30000 and rp.covered_months = 3
                            and rp.outcome = 'paid')
             and (select count(*) from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.renewal_index > 1) = 11
             and (select min(rp.scheduled_date) from app.renewal_periods rp
                   where rp.subscription_id = s.id and rp.renewal_index > 1) = date '2027-01-01'
             and not exists (select 1 from app.renewal_periods rp
                              where rp.subscription_id = s.id and rp.renewal_index > 1
                                and (rp.amount_cents <> 10000 or rp.covered_months <> 1))
            then 'PASS' else 'FAIL' end as verdict
  from app.subscriptions s
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9009';

create temp table probe_results (proof text, verdict text);
do $probe$
declare
    v_oscar bigint;
begin
    select s.id into v_oscar
      from app.subscriptions s
      join app.members m on m.id = s.member_id
     where m.member_code = 'GW-9007';
    begin
        update app.subscriptions set frequency_months = 6 where id = v_oscar;
        insert into probe_results values
            ('MG5: a RAW frequency_months update is REFUSED by the schedule-column guard',
             'FAIL: the raw update went through');
    exception when others then
        insert into probe_results values
            ('MG5: a RAW frequency_months update is REFUSED by the schedule-column guard',
             'PASS');
    end;
    begin
        update app.subscriptions set billing_anchor_date = date '2020-01-01' where id = v_oscar;
        insert into probe_results values
            ('MG6: a RAW billing_anchor_date update is REFUSED by the schedule-column guard',
             'FAIL: the raw update went through');
    exception when others then
        insert into probe_results values
            ('MG6: a RAW billing_anchor_date update is REFUSED by the schedule-column guard',
             'PASS');
    end;
end
$probe$;
select proof, verdict from probe_results order by proof;

-- ---------------------------------------------------------------------------
-- GX: new global invariants.
-- ---------------------------------------------------------------------------
select 'GX1: no calendar month is covered twice by any subscription (coverage never doubles, v1.1 12.1)' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from (select rp.subscription_id,
               (rp.covered_month_first + make_interval(months => gs.n))::date as covered_m
          from app.renewal_periods rp
          cross join lateral generate_series(0, rp.covered_months - 1) as gs(n)
         group by 1, 2
        having count(*) > 1) dup;

select 'GX2: supersession hygiene holds: no live retry pointer exists on any non-latest attempt' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_attempts ba
 where ba.next_action in ('retry', 'infra_immediate')
   and exists (select 1 from app.billing_attempts b2
                where b2.renewal_period_id = ba.renewal_period_id
                  and b2.attempt_no > ba.attempt_no);

select 'GX3: the outcome vocabulary is fully alive: skipped_paused and void_cancelled both occur in the ledger' as proof,
       case when count(*) filter (where outcome = 'skipped_paused') = 4
             and count(*) filter (where outcome = 'void_cancelled') = 2
            then 'PASS (skipped_paused 4: one marker each for PETE, QUINN, '
                 || 'RITA, SAM, pauses of 2, 1, 2, 2 months; void_cancelled '
                 || '2: ZOE September and October)'
            else 'FAIL: skipped_paused '
                 || count(*) filter (where outcome = 'skipped_paused')
                 || ', void_cancelled '
                 || count(*) filter (where outcome = 'void_cancelled') end as verdict
  from app.renewal_periods;

select 'GX4: ZOE, cancellation unrelated to payment failure: her preflight-stopped periods read void_cancelled, never unpaid' as proof,
       case when count(*) = 2 and bool_and(rp.outcome = 'void_cancelled')
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.renewal_periods rp
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id and m.member_code = 'GW-9021';

-- ===========================================================================
-- LM: THE RUN LIMIT (migration 028, ruling R9, spec v1.2 section 9B)
-- ===========================================================================
select 'LM1: the limited run record reads ran 5 of 23 due, 18 remaining' as proof,
       case when limit_requested = 5 and due_count = 23
             and processed_count = 5 and remaining_count = 18
            then 'PASS'
            else 'FAIL: ' || coalesce(limit_requested::text,'null') || '/'
                 || due_count || '/' || processed_count || '/' || remaining_count
       end as verdict
  from app.billing_runs
 where tick_date = date '2027-11-01' and status = 'final';

select 'LM2: the deterministic first five (oldest due, then member code)' as proof,
       case when string_agg(m.member_code, ',' order by m.member_code)
            = 'GW-9000,GW-9001,GW-9004,GW-9006,GW-9007'
            then 'PASS'
            else 'FAIL: ' || string_agg(m.member_code, ',' order by m.member_code)
       end as verdict
  from app.renewal_periods rp
  join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.attempt_no = 1
  join app.billing_runs br on br.id = ba.run_id
       and br.tick_date = date '2027-11-01' and br.status = 'final'
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id;

select 'LM3: the remainder self-healed next tick, number six onward, zero strandings, FM1 held across limited runs' as proof,
       case when (select due_count || '/' || processed_count || '/' || remaining_count
                    from app.billing_runs
                   where tick_date = date '2027-11-02' and status = 'final') = '18/18/0'
             and (select count(*) from app.renewal_periods
                   where scheduled_date = date '2027-11-01') = 23
             and (select count(distinct subscription_id) from app.renewal_periods
                   where scheduled_date = date '2027-11-01') = 23
             and (select min(m.member_code)
                    from app.renewal_periods rp
                    join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.attempt_no = 1
                    join app.billing_runs br on br.id = ba.run_id
                         and br.tick_date = date '2027-11-02' and br.status = 'final'
                    join app.subscriptions s on s.id = rp.subscription_id
                    join app.members m on m.id = s.member_id
                   where rp.scheduled_date = date '2027-11-01') = 'GW-9009'
            then 'PASS' else 'FAIL' end as verdict;

select 'LM4: a scheduled retry processes on a limited day REGARDLESS of the limit (9B rule 6)' as proof,
       case when (select limit_requested || '/' || due_count || '/'
                         || processed_count || '/' || remaining_count || '/' || attempts_made
                    from app.billing_runs
                   where tick_date = date '2027-11-04' and status = 'final') = '1/3/1/2/2'
             and exists (select 1
                           from app.billing_attempts ba
                           join app.renewal_periods rp on rp.id = ba.renewal_period_id
                           join app.subscriptions s on s.id = rp.subscription_id
                           join app.members m on m.id = s.member_id
                                and m.member_code = 'GW-9301'
                          where ba.attempt_no = 2 and ba.attempt_kind = 'retry_soft'
                            and ba.scheduled_for = date '2027-11-04'
                            and ba.outcome = 'succeeded')
            then 'PASS' else 'FAIL' end as verdict;

select 'LM5: the limited day-4 remainder self-healed on Nov 5 (2 of 2), all three day-4 cycles paid once' as proof,
       case when (select due_count || '/' || processed_count from app.billing_runs
                   where tick_date = date '2027-11-05' and status = 'final') = '2/2'
             and (select count(*) from app.renewal_periods rp
                    join app.subscriptions s on s.id = rp.subscription_id
                    join app.members m on m.id = s.member_id
                   where m.member_code in ('GW-9313','GW-9314','GW-9315')
                     and rp.outcome = 'paid') = 3
            then 'PASS' else 'FAIL' end as verdict;

select 'LM6: unlimited runs carry the arithmetic too: every final 028-era run has remaining_count = due minus processed' as proof,
       case when count(*) = 0 then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.billing_runs
 where status = 'final' and due_count is not null
   and remaining_count <> due_count - processed_count;

-- ===========================================================================
-- LV: THE LIVE DISPATCH SEAM (migration 029), to the rig''s honest boundary
-- ===========================================================================
select 'LV1: the S2 seed carries ONLY the two non-3DS sandbox cards, expiry 01/2029' as proof,
       case when count(*) = 10
             and count(*) filter (where c.brand = 'visa' and c.last4 = '4242') = 5
             and count(*) filter (where c.brand = 'mastercard' and c.last4 = '4444') = 5
             and bool_and(c.expiry_month = 1 and c.expiry_year = 2029)
             and bool_and(c.token_reference like 'sandbox-card:%')
            then 'PASS' else 'FAIL' end as verdict
  from app.payment_credentials c
  join app.members m on m.id = c.member_id
 where m.member_code like 'GW-94%';

select 'LV2: the live limited run: 2 of 2, dispatch_mode live on the run row' as proof,
       case when limit_requested = 2 and due_count = 2 and processed_count = 2
             and remaining_count = 0 and dispatch_mode = 'live'
            then 'PASS' else 'FAIL' end as verdict
  from app.billing_runs
 where tick_date = date '2027-11-06' and status = 'final';

select 'LV3: live verdicts resolved through the one shared path, real payment ids stamped, volume bridged to the covered month' as proof,
       case when count(*) = 2
             and bool_and(d.payment_status = 'succeeded')
             and bool_and(d.payment_reference like 'pay_livetest_%')
             and bool_and((d.processor_summary ->> 'simulated') = 'false')
             and (select count(*) from app.orders o
                    join app.members m2 on m2.id = o.member_id
                   where m2.member_code in ('GW-9401', 'GW-9406')
                     and o.volume_month = date '2027-11-01') = 2
            then 'PASS' else 'FAIL' end as verdict
  from app.demo_orders d
  join app.members m on m.id = d.member_id
 where m.member_code like 'GW-94%'
   and d.payment_reference like 'pay_livetest_%';

select 'LV4: simulated and live coexist: the Nov 7 seeds sim-billed normally beside the live strands' as proof,
       case when count(*) = 2
             and bool_and(d.payment_status = 'succeeded')
             and bool_and(d.payment_reference like 'SIM-%')
            then 'PASS' else 'FAIL: ' || count(*) end as verdict
  from app.demo_orders d
  join app.members m on m.id = d.member_id
 where m.member_code in ('GW-9402', 'GW-9407');
