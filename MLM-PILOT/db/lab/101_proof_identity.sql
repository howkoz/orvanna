-- Lab 101: L1 identity proof (and the parity run's creation)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 7 L1 gate: "the identity scenario's
--       derived member set equals the app.members snapshot row for row."
--
-- The run created here is ALSO the parity run of proof 102: lab plan
-- 'unilevel_v13' on the identity scenario for March 2026, the first full
-- seeded month (the month the spec's own calibration rule names).
--
-- Acronym key: Sales Volume (SV).

-- ---------------------------------------------------------------------------
-- Create the run. Records the run id; every check below reads the LATEST
-- complete unilevel March run so the script is re-runnable.
-- ---------------------------------------------------------------------------
select lab.fn_run_plan(date '2026-03-01',
                       'unilevel_v13',
                       '{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}'::jsonb,
                       null) as lab_run_id;

-- ---------------------------------------------------------------------------
-- ID1 (must return ZERO rows): the derived member set equals the census,
-- row for row, both directions, on every column the spec names for the
-- census (id, member_code, sponsor_id, enrolled_on). EXCEPT ALL catches
-- duplicates as well as missing or altered rows.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id
    from lab.plan_runs
    where period = date '2026-03-01'
      and plan_code = 'unilevel_v13'
      and status = 'complete'
),
derived as (
    select d.member_id, d.member_code, d.sponsor_id, d.enrolled_on
    from lab.derived_members d
    where d.run_id = (select run_id from run_under_test)
),
census as (
    select m.id as member_id, m.member_code, m.sponsor_id, m.enrolled_on
    from app.members m
)
select 'in_derived_not_census' as difference, d.*
from (select * from derived except all select * from census) d
union all
select 'in_census_not_derived' as difference, d.*
from (select * from census except all select * from derived) d;

-- ---------------------------------------------------------------------------
-- ID2 (must return exactly one row with equal counts and zero synthetics):
-- under the identity scenario every derived row references its census row
-- and no synthetic member exists.
-- ---------------------------------------------------------------------------
with run_under_test as (
    select max(id) as run_id
    from lab.plan_runs
    where period = date '2026-03-01'
      and plan_code = 'unilevel_v13'
      and status = 'complete'
)
select (select count(*) from lab.derived_members d
         where d.run_id = (select run_id from run_under_test))          as derived_rows,
       (select count(*) from app.members)                               as census_rows,
       (select count(*) from lab.derived_members d
         where d.run_id = (select run_id from run_under_test)
           and (d.app_member_id is null or d.app_member_id <> d.member_id)) as synthetic_or_mismapped;
