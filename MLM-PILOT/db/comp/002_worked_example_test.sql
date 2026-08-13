-- Comp engine 002: worked example acceptance test (COMP-PLAN-SPEC v1.1 section 7)
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date: 2026-08-13
--
-- PRECONDITIONS
--   1. Migrations 001..005 applied.
--   2. db\comp\001_comp_engine.sql applied.
--   3. The worked example data loaded into the app tables via
--      db\seed\output\load_worked_example.sql (EMPTY database: members
--      M1..M10 with ids 1..10, subscriptions, and the generated 2026-07
--      orders and order lines).
--   4. Run as the service role or database owner.
--
-- WHAT SUCCESS LOOKS LIKE
--   The engine call returns a run id, then CHECK 1, CHECK 2, and CHECK 3
--   each return ZERO rows. Any returned row is a spec violation and names
--   which side disagrees ('in_actual_not_expected' = the engine produced a
--   row the spec does not expect; 'in_expected_not_actual' = the spec
--   expects a row the engine did not produce). EXCEPT ALL is used so
--   duplicated rows are caught too, not just missing or altered ones.
--
-- Expected values are embedded below verbatim from
--   db\seed\output\worked_example_expected_member_results.csv
--   db\seed\output\worked_example_expected_commission_lines.csv
--   db\seed\output\worked_example_expected_company.csv
-- so this script is fully self-contained.

-- ---------------------------------------------------------------------------
-- Run the engine for the worked example period.
-- ---------------------------------------------------------------------------
select app.fn_run_commission(date '2026-07-01') as run_id;

-- Every check below targets the newest run for the period, which on a fresh
-- worked-example database is the run just created.

-- ---------------------------------------------------------------------------
-- CHECK 1 (must return ZERO rows): run_member_results versus expected.
-- Compares sv, cv, qualified (stored as is_active), tv, rank_earned,
-- paid_depth, total_earned for every member, both directions.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id
    from app.commission_runs
    where period = date '2026-07-01'
),
expected (member_code, sv, cv, qualified, tv, rank_earned, paid_depth, total_earned) as (
    values
        ('M1',   200.00::numeric,  160.00::numeric, true,  2500.00::numeric, 'leader',  3, 114.00::numeric),
        ('M2',   150.00::numeric,  120.00::numeric, true,   500.00::numeric, 'member',  1,  16.00::numeric),
        ('M3',   100.00::numeric,   80.00::numeric, true,  1650.00::numeric, 'builder', 2, 130.00::numeric),
        ('M4',   100.00::numeric,   80.00::numeric, true,     0.00::numeric, 'member',  1,   0.00::numeric),
        ('M5',    50.00::numeric,   40.00::numeric, false,  300.00::numeric, 'member',  1,   0.00::numeric),
        ('M6',   150.00::numeric,  120.00::numeric, true,     0.00::numeric, 'member',  1,   0.00::numeric),
        ('M7',  1500.00::numeric, 1200.00::numeric, true,     0.00::numeric, 'member',  1,   0.00::numeric),
        ('M8',   100.00::numeric,   80.00::numeric, true,    50.00::numeric, 'member',  1,   4.00::numeric),
        ('M9',   300.00::numeric,  240.00::numeric, true,     0.00::numeric, 'member',  1,   0.00::numeric),
        ('M10',   50.00::numeric,   40.00::numeric, false,    0.00::numeric, 'member',  1,   0.00::numeric)
),
actual as (
    select m.member_code,
           rmr.sv,
           rmr.cv,
           rmr.is_active as qualified,
           rmr.tv,
           rmr.rank_earned,
           rmr.paid_depth,
           rmr.total_earned
    from app.run_member_results rmr
    join app.members m on m.id = rmr.member_id
    where rmr.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (
    select * from actual
    except all
    select * from expected
) d
union all
select 'in_expected_not_actual' as difference, d.*
from (
    select * from expected
    except all
    select * from actual
) d;

-- ---------------------------------------------------------------------------
-- CHECK 2 (must return ZERO rows): commission_lines versus expected.
-- Compares earner, source, level, source_cv, rate, amount, both directions.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id
    from app.commission_runs
    where period = date '2026-07-01'
),
expected (earner_code, source_code, level, source_cv, rate, amount) as (
    values
        ('M1', 'M2',  1,  120.00::numeric, 0.1000::numeric,  12.00::numeric),
        ('M1', 'M3',  1,   80.00::numeric, 0.1000::numeric,   8.00::numeric),
        ('M1', 'M4',  1,   80.00::numeric, 0.1000::numeric,   8.00::numeric),
        ('M1', 'M5',  2,   40.00::numeric, 0.0500::numeric,   2.00::numeric),
        ('M1', 'M6',  2,  120.00::numeric, 0.0500::numeric,   6.00::numeric),
        ('M1', 'M7',  2, 1200.00::numeric, 0.0500::numeric,  60.00::numeric),
        ('M1', 'M8',  2,   80.00::numeric, 0.0500::numeric,   4.00::numeric),
        ('M1', 'M9',  3,  240.00::numeric, 0.0500::numeric,  12.00::numeric),
        ('M1', 'M10', 3,   40.00::numeric, 0.0500::numeric,   2.00::numeric),
        ('M2', 'M5',  1,   40.00::numeric, 0.1000::numeric,   4.00::numeric),
        ('M2', 'M6',  1,  120.00::numeric, 0.1000::numeric,  12.00::numeric),
        ('M3', 'M7',  1, 1200.00::numeric, 0.1000::numeric, 120.00::numeric),
        ('M3', 'M8',  1,   80.00::numeric, 0.1000::numeric,   8.00::numeric),
        ('M3', 'M10', 2,   40.00::numeric, 0.0500::numeric,   2.00::numeric),
        ('M8', 'M10', 1,   40.00::numeric, 0.1000::numeric,   4.00::numeric)
),
actual as (
    select e.member_code as earner_code,
           s.member_code as source_code,
           cl.level,
           cl.source_cv,
           cl.rate,
           cl.amount
    from app.commission_lines cl
    join app.members e on e.id = cl.earner_id
    join app.members s on s.id = cl.source_member_id
    where cl.run_id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (
    select * from actual
    except all
    select * from expected
) d
union all
select 'in_expected_not_actual' as difference, d.*
from (
    select * from expected
    except all
    select * from actual
) d;

-- ---------------------------------------------------------------------------
-- CHECK 3 (must return ZERO rows): company totals versus expected.
-- total_sv 2700.00, total_cv 2160.00, total_payout 264.00, members_paid 4.
-- Also fails (one 'in_expected_not_actual' row) if the run row is missing.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id
    from app.commission_runs
    where period = date '2026-07-01'
),
expected (total_sv, total_cv, total_payout, members_paid) as (
    values (2700.00::numeric, 2160.00::numeric, 264.00::numeric, 4)
),
actual as (
    select r.total_sv,
           r.total_cv,
           r.total_payout,
           r.members_paid
    from app.commission_runs r
    where r.id = (select run_id from run_under_test)
)
select 'in_actual_not_expected' as difference, d.*
from (
    select * from actual
    except all
    select * from expected
) d
union all
select 'in_expected_not_actual' as difference, d.*
from (
    select * from expected
    except all
    select * from actual
) d;

-- ---------------------------------------------------------------------------
-- Optional next step (NOT part of the acceptance checks): finalize the run
-- so the v_demo_* views serve it. Uncomment after the three checks pass.
--
-- select app.fn_finalize_run((select max(id)
--                             from app.commission_runs
--                             where period = date '2026-07-01'));
-- ---------------------------------------------------------------------------
