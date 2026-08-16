-- S1 proof run, segment 16: A MISSED DAY, then tick to the end of the year.
--
-- The clock SKIPS 2027-02-01 with no run (a scheduler outage on the busiest
-- day of the month, ruling R7's worst case). The 2027-02-02 tick must gather
-- everything that was due Feb 1 under the catch-up rule (pipeline step 3,
-- due ON OR BEFORE, derived from cycle accounting): nothing lost, nothing
-- double-billed. Then the year runs out to 2027-09-30, which carries FRED's
-- twelfth cycle (the FM4 day-31 anchor crossing February on the way).

select app.fn_sim_clock_skip(date '2027-02-01');

do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2027-02-02', date '2027-09-30',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

select 'catch-up: cycles scheduled for the missed day (billed on Feb 2)' as label,
       count(*)                                   as periods_due_feb1,
       count(*) filter (where rp.outcome = 'paid') as paid,
       min(ba.scheduled_for)                      as attempted_on_min,
       max(ba.scheduled_for)                      as attempted_on_max
  from app.renewal_periods rp
  join app.billing_attempts ba on ba.renewal_period_id = rp.id and ba.attempt_no = 1
 where rp.scheduled_date = date '2027-02-01';

select 'segment 16 complete, clock now' as label, clock_date from app.sim_clock;
