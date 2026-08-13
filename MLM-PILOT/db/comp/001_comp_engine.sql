-- Comp engine 001: commission run engine, in-database functions
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date: 2026-08-13
-- Spec: docs\COMP-PLAN-SPEC.md version v1.2, math identical to v1.1; v1.2 adds
-- upstream customer attribution only (customer orders book onto the referring
-- member's account before this engine ever runs). (Contract; section 7 is the
--       acceptance test), docs\SCHEMA-SPEC.md (table shapes),
--       docs\decisions\2026-08-13-genealogy-representation.md (per-run level map).
-- Requires: migrations 001..005 applied. Run as the service role or database
--       owner; RLS blocks every other role from the app tables by design.
--
-- FUNCTIONS
--   app.fn_run_commission(p_period date) returns bigint
--       Creates a commission_runs row (status 'running'), materializes the
--       run-scoped level map, computes SV / CV / TV / qualification / rank /
--       commission lines / member results / run totals. Leaves the run in
--       status 'running'; finalization is a separate explicit step.
--   app.fn_finalize_run(p_run_id bigint) returns void
--       Flips the run to 'final' (schema triggers then freeze its rows) and
--       supersedes any prior final run of the same period.
--
-- DETERMINISM NOTES
--   1. Rounding. Every rounded value uses Postgres round(numeric, 2), which
--      rounds half AWAY FROM ZERO. For the non-negative amounts in this
--      system (SV, CV, rates, commission amounts are all >= 0) round half
--      away from zero is IDENTICAL to round half up, which is what
--      COMP-PLAN-SPEC v1.1 requires. Rounding happens exactly twice:
--      once per member-month for CV = round(0.80 * SV, 2), and once per
--      commission line for amount = round(rate * source_cv, 2). Member and
--      company totals are sums of already-rounded values, never re-rounded.
--   2. Stable ordering. Both bulk INSERTs carry ORDER BY (lines by earner,
--      level, source; results by member id) so identity ids are assigned in
--      a reproducible order and two runs over the same data produce
--      byte-identical statements, row order included.
--   3. Snapshot isolation. The level map is materialized ONCE per run from
--      members.sponsor_id and every downstream step (TV, legs, ranks, lines)
--      reads the snapshot, never the live tree. Editing the tree after a run
--      starts cannot change that run's output.
--   4. All math is numeric, never float. Same inputs plus spec v1.1 equals
--      identical output to the cent, always.
--
-- SCALABILITY (the 100,000-member argument)
--   Everything is set-based: one recursive CTE materializes the ancestor
--   pairs (an indexed adjacency walk, well under a second at 100,000 rows in
--   Postgres), and every later step is a hash join or aggregate over the
--   indexed run_level_map and a single staging table. There are NO
--   per-member loops anywhere. The level map holds one row per
--   (ancestor, descendant) pair; at 100,000 members with realistic depth
--   that is a few million narrow rows, which Postgres joins in seconds.
--   Run-scoped rows mean reruns never contend with old runs.
--
-- DESIGN DECISIONS CALLED OUT (also in db\comp\README.md)
--   a. The level map stores pairs to FULL depth, not capped at 5. TV is
--      defined as the WHOLE subtree (spec section 2), so a 5-level cap would
--      corrupt TV in any tree deeper than 5. Commission pay filters to
--      level <= 5 (and <= earner paid depth) at line-insert time.
--   b. is_active is written as (SV >= 100.00): spec v1.1 made qualification
--      the single gate for both being paid and counting as an active leg.
--      The schema spec's older "sv >= 50" column note is v1.0 wording.
--   c. Commission lines are only written when source CV > 0; a line paying
--      0.00 on nothing is noise on a statement. The worked example has no
--      zero-CV member, so its expected lines are unaffected.
--   d. Rank flags evaluate in spec order: Builder, then Leader, then
--      Director (legs containing a builder_flag or leader_flag member), then
--      Executive (legs containing a leader_flag or director_flag member).
--      Final rank is the highest flag held. This is the spec's declared
--      non-circular order; see README for the containment edge-case note.

-- ---------------------------------------------------------------------------
-- Run-scoped level map: one row per (ancestor, descendant) pair per run,
-- with level = plain tree distance (1 = frontline). Kept until the run is
-- superseded (decision doc); fn_finalize_run deletes superseded runs' maps.
-- RLS is enabled with NO policies: the table is invisible to the public API;
-- the engine writes through the service role or table owner, which bypass RLS.
-- ---------------------------------------------------------------------------
create table if not exists app.run_level_map (
    run_id        bigint not null references app.commission_runs (id),
    ancestor_id   bigint not null references app.members (id),
    descendant_id bigint not null references app.members (id),
    level         int    not null check (level >= 1),
    primary key (run_id, ancestor_id, descendant_id)
);

create index if not exists run_level_map_run_id_descendant_id_idx
    on app.run_level_map (run_id, descendant_id);

alter table app.run_level_map enable row level security;

-- ---------------------------------------------------------------------------
-- fn_run_commission(p_period date) returns bigint
-- p_period is normalized to the first day of its month.
-- ---------------------------------------------------------------------------
create or replace function app.fn_run_commission(p_period date)
returns bigint
language plpgsql
as $$
declare
    v_period date;
    v_run_id bigint;
begin
    v_period := (date_trunc('month', p_period))::date;

    -- Step 0: the run row. Status stays 'running' for the whole computation;
    -- fn_finalize_run is the only path to 'final'.
    insert into app.commission_runs (period, spec_version, status, started_at, notes)
    values (v_period, 'v1.2', 'running', clock_timestamp(),
            'engine run for period ' || to_char(v_period, 'YYYY-MM'))
    returning id into v_run_id;

    -- Step 1: materialize the run-scoped level map (decision doc: FIRST step).
    -- Recursive walk UP the sponsor chain from every member: each member
    -- pairs with every ancestor at its exact distance. Full depth (see
    -- design decision a). The cycle-check trigger on app.members guarantees
    -- the recursion terminates.
    insert into app.run_level_map (run_id, ancestor_id, descendant_id, level)
    with recursive walk as (
        select m.sponsor_id as ancestor_id,
               m.id         as descendant_id,
               1            as level
        from app.members m
        where m.sponsor_id is not null

        union all

        select p.sponsor_id,
               w.descendant_id,
               w.level + 1
        from walk w
        join app.members p on p.id = w.ancestor_id
        where p.sponsor_id is not null
    )
    select v_run_id, w.ancestor_id, w.descendant_id, w.level
    from walk w
    order by w.ancestor_id, w.descendant_id;

    -- Step 2: one staging row per member with SV, CV, TV, qualification,
    -- rank, and paid depth. Computed once, read by both bulk inserts below,
    -- so lines and results can never diverge. Temp table is dropped on
    -- commit; the explicit drop guards repeated calls in one transaction.
    drop table if exists pg_temp.tmp_member_calc;

    create temp table tmp_member_calc on commit drop as
    with member_sv as (
        -- SV: sum of quantity * unit_volume over the member's completed
        -- orders stamped with this volume month. Members with no orders get 0.
        select m.id as member_id,
               (coalesce(sum(ol.quantity * ol.unit_volume), 0))::numeric(12,2) as sv
        from app.members m
        left join app.orders o
               on o.member_id = m.id
              and o.volume_month = v_period
              and o.status = 'completed'
        left join app.order_lines ol
               on ol.order_id = o.id
        group by m.id
    ),
    vols as (
        -- CV: round half up (0.80 * SV, 2 decimals), once per member-month.
        select ms.member_id,
               ms.sv,
               (round(0.80 * ms.sv, 2))::numeric(12,2) as cv
        from member_sv ms
    ),
    tv_agg as (
        -- TV: subtree SV excluding self, from the snapshot, ALL levels.
        select lm.ancestor_id as member_id,
               sum(v.sv)      as tv
        from app.run_level_map lm
        join vols v on v.member_id = lm.descendant_id
        where lm.run_id = v_run_id
        group by lm.ancestor_id
    ),
    base as (
        select v.member_id,
               v.sv,
               v.cv,
               (coalesce(t.tv, 0))::numeric(14,2) as tv,
               (v.sv >= 100.00)                   as qualified
        from vols v
        left join tv_agg t on t.member_id = v.member_id
    ),
    legs as (
        -- Frontline edges from the snapshot (level 1 pairs). A leg is the
        -- frontline child plus that child's whole subtree.
        select lm.ancestor_id  as member_id,
               lm.descendant_id as child_id
        from app.run_level_map lm
        where lm.run_id = v_run_id
          and lm.level = 1
    ),
    active_leg_counts as (
        -- A leg is ACTIVE when its frontline member is qualified this month.
        select l.member_id,
               count(*) as n_active_legs
        from legs l
        join base c on c.member_id = l.child_id
        where c.qualified
        group by l.member_id
    ),
    flags_bl as (
        -- Stage 1 (Builder) and stage 2 (Leader), per spec section 4 order.
        -- Builder: qualified AND >= 2 active legs (SV >= 100 is the same
        -- test as qualification in v1.1). Leader: TV >= 2,500 AND >= 3
        -- active legs (the spec table sets no personal SV test for Leader).
        select b.member_id,
               b.sv,
               b.cv,
               b.tv,
               b.qualified,
               coalesce(al.n_active_legs, 0)                          as n_active_legs,
               (b.qualified and coalesce(al.n_active_legs, 0) >= 2)   as builder_flag,
               (b.tv >= 2500.00 and coalesce(al.n_active_legs, 0) >= 3) as leader_flag
        from base b
        left join active_leg_counts al on al.member_id = b.member_id
    ),
    leg_members as (
        -- Membership of each leg: the frontline child itself, plus every
        -- member of the child's subtree (from the snapshot).
        select l.member_id, l.child_id, l.child_id as leg_member_id
        from legs l
        union all
        select l.member_id, l.child_id, lm.descendant_id
        from legs l
        join app.run_level_map lm
          on lm.run_id = v_run_id
         and lm.ancestor_id = l.child_id
    ),
    director_leg_counts as (
        -- Stage 3 (Director) containment: a leg "contains a Builder (or
        -- higher)" when ANY member of the leg holds builder_flag or
        -- leader_flag (the flags already computed in prior stages).
        select lmem.member_id,
               count(distinct lmem.child_id) as n_legs_with_builder_plus
        from leg_members lmem
        join flags_bl f on f.member_id = lmem.leg_member_id
        where f.builder_flag or f.leader_flag
        group by lmem.member_id
    ),
    flags_d as (
        select f.*,
               (f.tv >= 10000.00
                and coalesce(dl.n_legs_with_builder_plus, 0) >= 2) as director_flag
        from flags_bl f
        left join director_leg_counts dl on dl.member_id = f.member_id
    ),
    executive_leg_counts as (
        -- Stage 4 (Executive) containment: a leg "contains a Leader (or
        -- higher)" when ANY member of the leg holds leader_flag or
        -- director_flag (a Director counts as Leader-or-higher).
        select lmem.member_id,
               count(distinct lmem.child_id) as n_legs_with_leader_plus
        from leg_members lmem
        join flags_d f on f.member_id = lmem.leg_member_id
        where f.leader_flag or f.director_flag
        group by lmem.member_id
    ),
    flags_e as (
        select f.*,
               (f.tv >= 40000.00
                and coalesce(el.n_legs_with_leader_plus, 0) >= 2) as executive_flag
        from flags_d f
        left join executive_leg_counts el on el.member_id = f.member_id
    ),
    ranked as (
        -- Final rank: the HIGHEST rank whose requirements are met.
        select f.member_id,
               f.sv,
               f.cv,
               f.tv,
               f.qualified,
               case
                   when f.executive_flag then 'executive'
                   when f.director_flag  then 'director'
                   when f.leader_flag    then 'leader'
                   when f.builder_flag   then 'builder'
                   else 'member'
               end as rank_code
        from flags_e f
    )
    select r.member_id,
           r.sv,
           r.cv,
           r.tv,
           r.qualified,
           r.rank_code,
           rk.paid_depth
    from ranked r
    join app.ranks rk on rk.rank_code = r.rank_code;

    -- Step 3: commission lines, fully set-based. One line per
    -- (qualified earner, descendant source) pair within the earner's paid
    -- depth. The rate table doubles as the level <= 5 filter. The source
    -- member's own qualification is IRRELEVANT (spec section 5): all CV
    -- pays upline. No compression: level is plain snapshot distance.
    insert into app.commission_lines
        (run_id, earner_id, source_member_id, level, source_cv, rate, amount, payout_type)
    select v_run_id,
           lm.ancestor_id,
           lm.descendant_id,
           lm.level,
           src.cv,
           rt.rate,
           round(rt.rate * src.cv, 2),
           'unilevel_level_pay'
    from app.run_level_map lm
    join pg_temp.tmp_member_calc earner on earner.member_id = lm.ancestor_id
    join pg_temp.tmp_member_calc src    on src.member_id    = lm.descendant_id
    join (values (1, 0.1000::numeric(5,4)),
                 (2, 0.0500::numeric(5,4)),
                 (3, 0.0500::numeric(5,4)),
                 (4, 0.0300::numeric(5,4)),
                 (5, 0.0200::numeric(5,4))) as rt(level, rate)
      on rt.level = lm.level
    where lm.run_id = v_run_id
      and earner.qualified                 -- earner must be qualified to be paid
      and lm.level <= earner.paid_depth    -- rank-gated depth
      and src.cv > 0                       -- no 0.00 lines on nothing (decision c)
    order by lm.ancestor_id, lm.level, lm.descendant_id;

    -- Step 4: one result row per member (including zero-SV members), with
    -- total_earned = sum of that member's rounded lines (never re-rounded).
    insert into app.run_member_results
        (run_id, member_id, sv, cv, tv, is_active, rank_earned, paid_depth,
         total_earned, cumulative_sv)
    select v_run_id,
           c.member_id,
           c.sv,
           c.cv,
           c.tv,
           c.qualified,                    -- v1.1 single gate (decision b)
           c.rank_code,
           c.paid_depth,
           coalesce(e.total_earned, 0.00),
           null                            -- reserved in v1
    from pg_temp.tmp_member_calc c
    left join (
        select cl.earner_id, sum(cl.amount) as total_earned
        from app.commission_lines cl
        where cl.run_id = v_run_id
        group by cl.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    -- Step 5: run totals. Sums of already-rounded values; members_paid
    -- counts members with total_earned > 0. Status stays 'running'.
    update app.commission_runs r
    set total_sv     = t.total_sv,
        total_cv     = t.total_cv,
        total_payout = t.total_payout,
        members_paid = t.members_paid,
        finished_at  = clock_timestamp()
    from (
        select (coalesce(sum(rmr.sv), 0))::numeric(14,2)            as total_sv,
               (coalesce(sum(rmr.cv), 0))::numeric(14,2)            as total_cv,
               (coalesce(sum(rmr.total_earned), 0))::numeric(14,2)  as total_payout,
               count(*) filter (where rmr.total_earned > 0)         as members_paid
        from app.run_member_results rmr
        where rmr.run_id = v_run_id
    ) t
    where r.id = v_run_id;

    drop table if exists pg_temp.tmp_member_calc;

    return v_run_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- fn_finalize_run(p_run_id bigint)
-- Marks the run 'final' (the schema immutability triggers then freeze its
-- statement rows) and supersedes any prior final run of the same period.
-- The supersede happens FIRST so the partial unique index (one final run
-- per period) never sees two finals at once.
-- ---------------------------------------------------------------------------
create or replace function app.fn_finalize_run(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_period date;
    v_status text;
begin
    select r.period, r.status
    into v_period, v_status
    from app.commission_runs r
    where r.id = p_run_id
    for update;

    if not found then
        raise exception 'fn_finalize_run: run % does not exist', p_run_id;
    end if;

    if v_status <> 'running' then
        raise exception
            'fn_finalize_run: run % has status ''%''; only a ''running'' run can be finalized',
            p_run_id, v_status;
    end if;

    -- Supersede prior final run(s) of the same period.
    update app.commission_runs
    set status = 'superseded'
    where period = v_period
      and status = 'final'
      and id <> p_run_id;

    -- Decision doc: the level map is kept until the run is superseded.
    -- Drop the maps of every superseded run of this period.
    delete from app.run_level_map lm
    using app.commission_runs r
    where lm.run_id = r.id
      and r.period = v_period
      and r.status = 'superseded';

    update app.commission_runs
    set status      = 'final',
        finished_at = coalesce(finished_at, clock_timestamp())
    where id = p_run_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privilege hygiene: functions default to EXECUTE for PUBLIC in Postgres.
-- Only the service role / owner should ever run the engine (RLS would block
-- other roles' writes anyway; this makes the intent explicit).
-- ---------------------------------------------------------------------------
revoke execute on function app.fn_run_commission(date)  from public;
revoke execute on function app.fn_finalize_run(bigint)  from public;
