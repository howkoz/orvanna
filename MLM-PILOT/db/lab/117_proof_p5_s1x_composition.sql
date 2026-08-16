-- Lab 117: plan five composes with the L3 scenario machinery (S1X, watched)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: ORVANNA-BUILDER-PLAN-SPEC.md section 8 (the plan runs under lab spec
--       v1.3 sections 1 and 9 through 11 unchanged). Requires db\lab\016,
--       017, and the L3 scenarios (S1X from proof 113).
--
-- Hand derivation (this build's, for the verifier), draft rates. Mini
-- identity under plan five: M1 is a BUILDER (three active legs) and the
-- ROOT, so layer 2 pays nobody; spine = the unilevel mini 34.00; layer 3:
-- M1's legs are M2-leg 160.00, M3-leg 80.00, M4-leg 80.00 (tie broken by
-- frontline id: M3-leg is second), three active legs so multiplier 1.15:
-- bonus 0.0575 x 80.00 = 4.60; company 38.60 (M1 34.60, M2 4.00). S1X
-- (add LAB-S1-1 under M2, move M4 under M3): spine = the S1X unilevel
-- 50.00; M1 Builder with TWO active legs (M2, M3), multiplier 1.00; legs
-- M2-leg 240.00, M3-leg 160.00: bonus 0.05 x 160.00 = 8.00; company 58.00
-- (M1 38.00, M2 12.00, M3 8.00). Watched M1 delta +3.40, decomposed:
-- +4.00 from_added_members (the recruit's level 2 spine line), -4.00
-- from_level_shift (M4's line, level 1 to 2), +3.40 aggregate (bonus 4.60
-- to 8.00), decomposable false, basis 80.00 to 160.00, gained [LAB-M4].
-- Watched M2 delta +8.00 (added), decomposable true. The plan's per-source
-- and aggregate parts flow through the L3 decomposition without special
-- cases: that is the composition proof.
-- Acronym key: Commissionable Volume (CV).

do $$
declare
    v_base bigint;
    v_id   bigint;
begin
    v_base := lab.fn_run_mini_fixture('PROOF-MINI', 'orvanna_builder',
        '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
        null, date '2026-07-01', null, 'P5-BASE-MINI-ORVANNA');

    v_id := lab.fn_run_mini_fixture('S1X', 'orvanna_builder',
        '{"spine_rates": [0.10, 0.05, 0.05, 0.03, 0.02], "gen1_rate": 0.04, "gen2_rate": 0.02, "second_leg_rate": 0.05, "leg_multipliers": {"2": 1.00, "3": 1.15, "4": 1.25}, "pool_rate": 0.25, "waterfall_order": ["spine", "overrides", "second_leg"]}'::jsonb,
        null, date '2026-07-01', v_base, 'P5-PROOF-S1X-ORVANNA');
end
$$;

-- ---------------------------------------------------------------------------
-- P5-T5 (every count must be 0): base and S1X per-member tables, and the
-- S1X watched rows against the hand derivation above.
-- ---------------------------------------------------------------------------
with base_run as (select max(id) as id from lab.plan_runs where notes = 'P5-BASE-MINI-ORVANNA'),
s1x_run as (select max(id) as id from lab.plan_runs where notes = 'P5-PROOF-S1X-ORVANNA'),
exp_member (tag, member_code, total_earned) as (
    values ('BASE', 'LAB-M1', 34.60::numeric), ('BASE', 'LAB-M2', 4.00::numeric),
           ('BASE', 'LAB-M3',  0.00::numeric), ('BASE', 'LAB-M4', 0.00::numeric),
           ('BASE', 'LAB-M5',  0.00::numeric),
           ('S1X', 'LAB-M1', 38.00::numeric), ('S1X', 'LAB-M2', 12.00::numeric),
           ('S1X', 'LAB-M3',  8.00::numeric), ('S1X', 'LAB-M4',  0.00::numeric),
           ('S1X', 'LAB-M5',  0.00::numeric), ('S1X', 'LAB-S1-1', 0.00::numeric)
),
act_member as (
    select case when pr.run_id = (select id from base_run) then 'BASE' else 'S1X' end,
           m.member_code, pr.total_earned
    from lab.plan_run_results pr
    join lab.derived_members m on m.run_id = pr.run_id and m.member_id = pr.member_id
    where pr.run_id in ((select id from base_run), (select id from s1x_run))
),
exp_watch (member_ref, delta_earned, from_added, level_shift, aggregate_delta,
           decomposable, basis_before, basis_after, gained) as (
    values ('LAB-M1', 3.40::numeric, 4.00::numeric, -4.00::numeric, 3.40::numeric,
            false, 80.00::numeric, 160.00::numeric, '["LAB-M4"]'::jsonb),
           ('LAB-M2', 8.00::numeric, 8.00::numeric, 0.00::numeric, null,
            true, null, null, null)
),
act_watch as (
    select ws.member_ref, ws.delta_earned,
           (ws.delta_components ->> 'from_added_members')::numeric,
           (ws.delta_components ->> 'from_level_shift')::numeric,
           (ws.delta_components ->> 'aggregate_delta')::numeric,
           (ws.delta_components ->> 'decomposable')::boolean,
           (ws.delta_components ->> 'basis_before')::numeric,
           (ws.delta_components ->> 'basis_after')::numeric,
           ws.delta_components -> 'basis_members_gained'
    from lab.watch_snapshots ws
    where ws.run_id = (select id from s1x_run)
)
select 'p5_member_diff' as check_kind, count(*) as n from (
    select * from act_member except all select * from exp_member
    union all select * from exp_member except all select * from act_member) x
union all
select 'p5_s1x_watch_diff', count(*) from (
    select * from act_watch except all select * from exp_watch
    union all select * from exp_watch except all select * from act_watch) x;
