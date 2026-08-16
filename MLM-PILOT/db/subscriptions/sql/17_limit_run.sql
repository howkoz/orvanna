-- S1 proof run, segment 17: THE RUN LIMIT (migration 028, ruling R9, spec
-- v1.2 section 9B). October 2027 ticks bring the clock forward; twelve new
-- members join with day-1 subscriptions so 2027-11-01 carries EXACTLY 23
-- due new cycles (11 existing actives due that day plus these 12). Then:
--   Nov 1  tick with LIMIT 5: the deterministic first five by member code
--          (all share the due date) process; run row must read 5/23/18.
--   Nov 2  tick unlimited: the remaining 18 self-heal, number 6 onward.
--   Nov 4  tick with LIMIT 1: three new day-4 members are due, ONE
--          processes; GW-9301's retry (scheduled Nov 4 from its Nov 2
--          decline) processes REGARDLESS of the limit (9B rule 6).
--   Nov 5  tick unlimited: the two remaining day-4 cycles self-heal.

do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2027-10-01', date '2027-10-31',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

-- The limit cast: twelve day-1 members due 2027-11-01, three day-4 members
-- due 2027-11-04. GW-9301 is scripted to decline soft on its first attempt
-- (which runs Nov 2, in the self-heal batch), putting its plus-2 retry on
-- Nov 4, the second limited day.
insert into app.members (member_code, display_name, email, sponsor_id, enrolled_on)
select 'GW-93' || lpad(n::text, 2, '0'),
       'Limit Member ' || n,
       'limit.' || n || '@example.com',
       (select id from app.members where member_code = 'GW-9000'),
       date '2027-10-01'
from generate_series(1, 15) as n;

insert into app.subscriptions
    (member_id, product_id, quantity, start_month, billing_anchor_date,
     frequency_months, billing_day, state)
select m.id,
       (select id from app.products where sku = 'AGT-D-001'),
       1,
       date '2027-11-01',
       case when m.member_code <= 'GW-9312' then date '2027-11-01' else date '2027-11-04' end,
       1, null, 'active'
from app.members m
where m.member_code like 'GW-93%'
order by m.member_code;

insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2001',
       '9B rule 6 proof: this decline makes a retry land on the limited day Nov 4'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9301';

-- The limited run.
select app.fn_billing_tick(date '2027-11-01', 5) as limited_run_id;

select 'limit: run record for 2027-11-01 (must be 5 of 23, 18 remaining)' as label,
       limit_requested, due_count, processed_count, remaining_count
  from app.billing_runs where tick_date = date '2027-11-01' and status = 'final';

select 'limit: the deterministic first five (oldest due, then member code)' as label,
       string_agg(m.member_code, ',' order by m.member_code) as processed_members
  from app.renewal_periods rp
  join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.attempt_no = 1
  join app.billing_runs br on br.id = ba.run_id
       and br.tick_date = date '2027-11-01' and br.status = 'final'
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id;

-- The self-heal.
select app.fn_billing_tick(date '2027-11-02') as selfheal_run_id;

select 'limit: self-heal run record for 2027-11-02 (must be 18 of 18, 0 remaining)' as label,
       limit_requested, due_count, processed_count, remaining_count
  from app.billing_runs where tick_date = date '2027-11-02' and status = 'final';

select 'limit: number six onward picked up first (lowest code in the self-heal batch)' as label,
       min(m.member_code) as first_selfheal_member
  from app.renewal_periods rp
  join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.attempt_no = 1
  join app.billing_runs br on br.id = ba.run_id
       and br.tick_date = date '2027-11-02' and br.status = 'final'
  join app.subscriptions s on s.id = rp.subscription_id
  join app.members m on m.id = s.member_id
 where rp.scheduled_date = date '2027-11-01';

select app.fn_billing_tick(date '2027-11-03') as quiet_run_id;

-- The limited day that carries a scheduled retry.
select app.fn_billing_tick(date '2027-11-04', 1) as limited_retry_day_run_id;

select 'limit: run record for 2027-11-04 (1 of 3 new, 2 remaining, retry processed regardless)' as label,
       limit_requested, due_count, processed_count, remaining_count, attempts_made
  from app.billing_runs where tick_date = date '2027-11-04' and status = 'final';

select app.fn_billing_tick(date '2027-11-05') as selfheal2_run_id;

select 'segment 17 complete, clock now' as label, clock_date from app.sim_clock;
