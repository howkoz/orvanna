-- S1 proof run, segment 13: tick 2026-11-16 through 2026-11-30.
do $$
declare
    d date;
begin
    for d in
        select generate_series(date '2026-11-16', date '2026-11-30',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);
    end loop;
end
$$;

select 'segment 13 complete, clock now' as label, clock_date from app.sim_clock;
