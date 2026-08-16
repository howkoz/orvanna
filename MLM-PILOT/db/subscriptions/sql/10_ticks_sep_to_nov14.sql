-- S1 proof run, segment 10: tick every day 2026-09-01 through 2026-11-14.
-- September carries worked examples A and B; November 1 carries example B's
-- auto-cancel (two consecutive unpaid months while suspended, ruling R4).
do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2026-09-01', date '2026-11-14',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

select 'segment 10 complete, clock now' as label, clock_date from app.sim_clock;
