-- S1 proof run, segment 20: the compensation engine reads what the bridge
-- wrote. Four months are computed (September through December 2026) with the
-- UNMODIFIED engine (spec v1.3): the worked examples' commission lines come
-- out of the real engine, not a reimplementation. Runs are left un-finalized
-- on purpose: the rig proves arithmetic, and finalization is an operational
-- act with its own protections already proven in production.

select app.fn_run_commission(date '2026-09-01') as run_sep;
select app.fn_run_commission(date '2026-10-01') as run_oct;
select app.fn_run_commission(date '2026-11-01') as run_nov;
select app.fn_run_commission(date '2026-12-01') as run_dec;

select 'commission runs' as label, id, period, spec_version, status
  from app.commission_runs order by id;
