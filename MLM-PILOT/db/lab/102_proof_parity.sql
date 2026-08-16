-- Lab 102: L1 parity proof, lab unilevel v1.3 versus the REAL finalized March run
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 7 L1 gate: "for one seeded finalized
--       month under the identity scenario, lab unilevel lines and totals
--       equal the real run's lines and totals exactly (the real run copied
--       for comparison only)."
--
-- Target month: March 2026, the first full seeded month, the month the
-- spec's calibration rule (section 4.2) names for the L1 gate. The real run
-- is the unique 'final' run for the period (the one-final-per-period partial
-- unique index guarantees uniqueness). The lab run is the one created by
-- proof 101. The real run is READ, never written: this is a comparison, not
-- an input (spec 1.1 note).
--
-- KNOWN, EXPLAINED census drift: the real March run was finalized 2026-08-13
-- over the then-1000-member census. Member GW-000 (the company retention
-- account, migration 020) was enrolled 2026-08-15, AFTER finalization, so
-- today's identity snapshot carries 1001 members. GW-000 has zero volume in
-- every seeded month, so: commission lines match exactly, company totals
-- match exactly, and the member-results comparison shows exactly ONE
-- lab-side row (GW-000, all zeros). PAR3 proves that surplus row is exactly
-- that and nothing else.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV).

-- ---------------------------------------------------------------------------
-- PAR1 (must return ZERO rows): every commission line, both directions,
-- compared on (earner, source, level, basis, rate, amount). EXCEPT ALL
-- catches duplicated lines too.
-- ---------------------------------------------------------------------------
with real_run as (
    select r.id from app.commission_runs r
    where r.period = date '2026-03-01' and r.status = 'final'
),
lab_run as (
    select max(id) as id from lab.plan_runs
    where period = date '2026-03-01' and plan_code = 'unilevel_v13' and status = 'complete'
),
real_lines as (
    select cl.earner_id, cl.source_member_id, cl.level, cl.source_cv as basis, cl.rate, cl.amount
    from app.commission_lines cl
    where cl.run_id = (select id from real_run)
),
lab_lines as (
    select l.earner_id, l.source_member_id, l.level, l.basis, l.rate, l.amount
    from lab.plan_run_lines l
    where l.run_id = (select id from lab_run)
)
select 'in_lab_not_real' as difference, d.*
from (select * from lab_lines except all select * from real_lines) d
union all
select 'in_real_not_lab' as difference, d.*
from (select * from real_lines except all select * from lab_lines) d;

-- ---------------------------------------------------------------------------
-- PAR2 (must return ZERO rows): both company totals, compared value by value.
-- ---------------------------------------------------------------------------
with real_run as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from app.commission_runs r
    where r.period = date '2026-03-01' and r.status = 'final'
),
lab_run as (
    select r.total_sv, r.total_cv, r.total_payout, r.members_paid
    from lab.plan_runs r
    where r.id = (select max(id) from lab.plan_runs
                  where period = date '2026-03-01'
                    and plan_code = 'unilevel_v13' and status = 'complete')
)
select 'in_lab_not_real' as difference, d.*
from (select * from lab_run except all select * from real_run) d
union all
select 'in_real_not_lab' as difference, d.*
from (select * from real_run except all select * from lab_run) d;

-- ---------------------------------------------------------------------------
-- PAR3: member results, both directions, on (member, sv, cv, qualified,
-- rank, paid depth, total_earned). Expected output: EXACTLY ONE row,
-- difference 'in_lab_not_real', member GW-000 with sv 0, cv 0, unqualified,
-- rank member, total_earned 0 (the explained census drift). The final
-- SELECT must return zero rows: it asserts no OTHER difference exists.
-- ---------------------------------------------------------------------------
with real_run as (
    select r.id from app.commission_runs r
    where r.period = date '2026-03-01' and r.status = 'final'
),
lab_run as (
    select max(id) as id from lab.plan_runs
    where period = date '2026-03-01' and plan_code = 'unilevel_v13' and status = 'complete'
),
real_results as (
    select rmr.member_id, rmr.sv, rmr.cv, rmr.is_active as qualified,
           rmr.rank_earned as rank_label, rmr.paid_depth, rmr.total_earned
    from app.run_member_results rmr
    where rmr.run_id = (select id from real_run)
),
lab_results as (
    select pr.member_id, pr.sv, pr.cv, pr.qualified,
           pr.rank_label, (pr.plan_metrics ->> 'paid_depth')::int as paid_depth, pr.total_earned
    from lab.plan_run_results pr
    where pr.run_id = (select id from lab_run)
),
diffs as (
    select 'in_lab_not_real' as difference, d.*
    from (select * from lab_results except all select * from real_results) d
    union all
    select 'in_real_not_lab' as difference, d.*
    from (select * from real_results except all select * from lab_results) d
)
select * from diffs;

-- The assertion: zero rows means the ONLY member-results difference is the
-- explained GW-000 zero row on the lab side.
with real_run as (
    select r.id from app.commission_runs r
    where r.period = date '2026-03-01' and r.status = 'final'
),
lab_run as (
    select max(id) as id from lab.plan_runs
    where period = date '2026-03-01' and plan_code = 'unilevel_v13' and status = 'complete'
),
real_results as (
    select rmr.member_id, rmr.sv, rmr.cv, rmr.is_active as qualified,
           rmr.rank_earned as rank_label, rmr.paid_depth, rmr.total_earned
    from app.run_member_results rmr
    where rmr.run_id = (select id from real_run)
),
lab_results as (
    select pr.member_id, pr.sv, pr.cv, pr.qualified,
           pr.rank_label, (pr.plan_metrics ->> 'paid_depth')::int as paid_depth, pr.total_earned
    from lab.plan_run_results pr
    where pr.run_id = (select id from lab_run)
),
diffs as (
    select 'in_lab_not_real' as difference, d.*
    from (select * from lab_results except all select * from real_results) d
    union all
    select 'in_real_not_lab' as difference, d.*
    from (select * from real_results except all select * from lab_results) d
)
select d.*
from diffs d
left join app.members m on m.id = d.member_id
where not (d.difference = 'in_lab_not_real'
           and m.member_code = 'GW-000'
           and d.sv = 0 and d.cv = 0 and d.total_earned = 0
           and not d.qualified);
