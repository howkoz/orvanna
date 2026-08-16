-- S1 proof run, segment 11: THE CRASH (failure mode FM2, crash-mid-batch).
-- Sixty renewals are due 2026-11-15. The crash lever (deviation D9 of
-- migration 026) kills the engine after 47 dispatches: 47 attempts written
-- 'dispatched' with their demo orders created and NOTHING submitted, the run
-- left 'running', the clock NOT advanced. This session then photographs the
-- stranded state, which is the evidence the reconciler works against.

select set_config('orvanna.sim_crash_after_dispatches', '47', false);

select app.fn_billing_tick(date '2026-11-15') as crashed_run_id;

-- Photograph the wreckage, before any recovery:
select 'crash: run status' as label, status, notes
  from app.billing_runs where tick_date = date '2026-11-15'
 order by id desc limit 1;

select 'crash: stranded attempts' as label,
       count(*) as dispatched_attempts
  from app.billing_attempts where outcome = 'dispatched';

select 'crash: clock did not advance' as label, clock_date
  from app.sim_clock;

select 'crash: attention queue orphans' as label,
       count(*) as orphaned_rows
  from app.v_staff_attention_queue where reason = 'orphaned_attempt';
