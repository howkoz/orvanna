-- Lab 001: the comp plan lab schema, walled off from schema app
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: docs\COMP-LAB-SPEC.md version 1.1 (THE LAW for this build), sections
--       1 (plan engine interface), 2 (sandbox isolation), 9 (scenarios, of
--       which phase L1 carries only the IDENTITY scenario), 11.1 (run registry).
-- Phase: L1. Scenario mutation kinds, watched accounts, and the living report
--        arrive in later phases; their table SHELLS land here because the spec
--        names them as L1 deliverables and the input path must not be rebuilt.
--
-- Acronym key: Structured Query Language (SQL), Row-Level Security (RLS),
-- Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV),
-- JavaScript Object Notation (JSON), Breadth-First Search (BFS).
--
-- ISOLATION IS THE FIRST THING BUILT, per the spec's section 2 argument:
--   1. Everything lab lives in schema lab. Nothing here writes to schema app.
--   2. Schema lab receives ZERO grants for app_demo_reader, anon, or
--      authenticated. The demo views' definer role cannot see lab rows even
--      by accident, because it has no usage on the schema at all.
--   3. The status constraint on lab.plan_runs carries NO 'final' value, by
--      CHECK. No query that means "the real money" can ever match a lab row.
--   4. Every synthetic (scenario-created) member's member_code must carry the
--      'LAB-' prefix, by CHECK. Real accounts are 'GW-' codes; no export or
--      screenshot can ever show a synthetic account that reads like a real one.
--   5. Every lab run row carries the what-if disclaimer as a GENERATED column,
--      so it cannot be blanked or edited away.
--
-- The one spec-sanctioned reference from lab to app: lab.derived_members
-- carries a nullable foreign key to app.members(id) (COMP-LAB-SPEC section 2.1
-- amended hard rule). Set for census members, null for synthetic ones. This
-- adds only internal referential-integrity triggers on app.members; it creates
-- no readable surface and no write path. Known interaction, recorded honestly:
-- while lab rows exist, a TRUNCATE of app.members (used only by the fresh-
-- rebuild script db\comp\003_reset_app_data.sql) would refuse loudly until lab
-- run data is cleared first. Refusing loudly is the correct failure mode.

create schema if not exists lab;

-- ---------------------------------------------------------------------------
-- lab.scenarios (COMP-LAB-SPEC section 9.2)
-- A scenario is a NAMED, VERSIONED, ORDERED list of tree and volume mutations
-- layered on the base census. The census with an EMPTY mutation list is the
-- IDENTITY scenario, seeded below, so "no scenario" is never a special case.
-- ---------------------------------------------------------------------------
create table lab.scenarios (
    id                  bigint generated always as identity primary key,
    scenario_code       text not null,
    name                text not null,
    parent_scenario_id  bigint references lab.scenarios (id),
    status              text not null default 'draft'
                        check (status in ('draft', 'locked', 'archived')),
    created_at          timestamptz not null default clock_timestamp(),
    notes               text,
    constraint scenarios_scenario_code_key unique (scenario_code)
);

-- ---------------------------------------------------------------------------
-- lab.scenario_mutations (COMP-LAB-SPEC section 9.2), SHELL in phase L1.
-- The five kinds are constrained now so no undocumented kind can ever be
-- stored; the REPLAY of mutations arrives in phase L3. In L1 any scenario
-- carrying a mutation is refused loudly by lab.fn_derive_members.
-- ---------------------------------------------------------------------------
create table lab.scenario_mutations (
    id               bigint generated always as identity primary key,
    scenario_id      bigint not null references lab.scenarios (id),
    seq              int not null,
    kind             text not null
                     check (kind in ('add_member', 'remove_member', 'remove_leg',
                                     'move_member', 'set_volume')),
    target_ref       text,
    new_sponsor_ref  text,
    volume_profile   jsonb,
    month_from       date,
    month_to         date,
    constraint scenario_mutations_seq_key unique (scenario_id, seq)
);

-- ---------------------------------------------------------------------------
-- lab.plan_runs: the run registry (COMP-LAB-SPEC sections 1.2, 2.2, 11.1).
-- Every run appends a row; rows are never deleted (trigger below); 'archived'
-- only hides a run from the default report.
--
-- The status CHECK deliberately has NO 'final' value (isolation argument 3).
--
-- order_source and snapshotted_at exist because of the engineer charter
-- amendment of 2026-08-16: every determinism claim states which order source
-- it was proven against (seeded, bridged, or both) and which period snapshot.
-- The run row itself carries that statement so no claim depends on memory.
-- ---------------------------------------------------------------------------
create table lab.plan_runs (
    id                  bigint generated always as identity primary key,
    scenario_id         bigint not null references lab.scenarios (id),
    plan_code           text not null
                        check (plan_code in ('unilevel_v13', 'binary',
                                             'matrix_3x7', 'stairstep_breakaway')),
    plan_params         jsonb not null,
    placement_strategy  text
                        check (placement_strategy in ('bfs_spill', 'volume_balanced')),
    period              date not null,
    baseline_run_id     bigint references lab.plan_runs (id),
    status              text not null default 'running'
                        check (status in ('running', 'complete', 'archived')),
    order_source        text not null,
    snapshotted_at      timestamptz not null default clock_timestamp(),
    started_at          timestamptz,
    finished_at         timestamptz,
    notes               text,
    total_sv            numeric(14,2),
    total_cv            numeric(14,2),
    total_payout        numeric(14,2),
    members_paid        int,
    -- The what-if label (spec section 2.2): generated, so it can never be
    -- edited away or blanked on any row.
    disclaimer          text not null
                        generated always as
                        ('WHAT-IF RUN: not a statement, pays nobody') stored,
    -- The derived-placement caption (spec section 3.4): every run computed on
    -- a derived placement carries the fixed caption in its own row.
    placement_caption   text
                        generated always as
                        (case when placement_strategy is not null then
                         'computed on a DERIVED placement; a different derivation gives different payouts'
                         end) stored,
    -- Placement-tree plans must record their strategy; sponsor-tree plans
    -- must not carry one. One CHECK makes the rule structural.
    constraint plan_runs_strategy_matches_plan
        check ((plan_code in ('binary', 'matrix_3x7')) = (placement_strategy is not null))
);

create index plan_runs_period_plan_idx on lab.plan_runs (period, plan_code);

-- ---------------------------------------------------------------------------
-- lab.derived_members: the derived tree, materialized ONCE per run
-- (COMP-LAB-SPEC section 1.1). For the IDENTITY scenario this is exactly the
-- census snapshot: census members keep their app ids; synthetic members get
-- id = 10,000,000 + ordinal (spec section 9.4), which sorts after every
-- census id so placement processes them last, deterministically.
--
-- app_member_id: the spec-sanctioned nullable reference to app.members(id).
-- Set for census rows, null for synthetic rows. The 'LAB-' CHECK below is
-- the name wall of spec section 2.3.
-- ---------------------------------------------------------------------------
create table lab.derived_members (
    run_id         bigint not null references lab.plan_runs (id),
    member_id      bigint not null,
    member_code    text not null,
    sponsor_id     bigint,
    enrolled_on    date not null,
    app_member_id  bigint references app.members (id),
    primary key (run_id, member_id),
    -- Sponsor must be a derived member of the SAME run (or null for a root).
    constraint derived_members_sponsor_fk
        foreign key (run_id, sponsor_id) references lab.derived_members (run_id, member_id),
    -- The name wall: a row with no census reference is synthetic and MUST
    -- read as one. Real accounts are 'GW-'; synthetic accounts are 'LAB-'.
    constraint derived_members_synthetic_name_wall
        check (app_member_id is not null or member_code like 'LAB-%')
);

create index derived_members_run_sponsor_idx on lab.derived_members (run_id, sponsor_id);

-- ---------------------------------------------------------------------------
-- lab.member_volumes: the month's SV per derived member, materialized once
-- per run (the explicit snapshot step of COMP-LAB-SPEC section 1.1). Census
-- runs fill this from app.orders read-only; proof fixtures fill it by hand.
-- Every later computation reads THIS table, never app.orders, so a run's
-- input is frozen the moment it is snapshotted.
-- ---------------------------------------------------------------------------
create table lab.member_volumes (
    run_id     bigint not null,
    member_id  bigint not null,
    sv         numeric(12,2) not null,
    primary key (run_id, member_id),
    constraint member_volumes_member_fk
        foreign key (run_id, member_id) references lab.derived_members (run_id, member_id)
);

-- ---------------------------------------------------------------------------
-- lab.run_level_map: run-scoped (ancestor, descendant, level) pairs over the
-- DERIVED tree, exactly the discipline of app.run_level_map in
-- db\comp\001_comp_engine.sql: materialized once per run, read by every later
-- step, full depth (a depth cap would corrupt TV).
-- ---------------------------------------------------------------------------
create table lab.run_level_map (
    run_id         bigint not null,
    ancestor_id    bigint not null,
    descendant_id  bigint not null,
    level          int not null check (level >= 1),
    primary key (run_id, ancestor_id, descendant_id),
    constraint run_level_map_ancestor_fk
        foreign key (run_id, ancestor_id) references lab.derived_members (run_id, member_id),
    constraint run_level_map_descendant_fk
        foreign key (run_id, descendant_id) references lab.derived_members (run_id, member_id)
);

create index run_level_map_run_descendant_idx on lab.run_level_map (run_id, descendant_id);

-- ---------------------------------------------------------------------------
-- lab.placement_map: the DERIVED two-leg placement tree, materialized per run
-- (COMP-LAB-SPEC sections 1.1 and 3), never read from a previous run.
-- slot 0 = left, 1 = right (a CHECK admits 2 now so the width-3 matrix of
-- phase L2 extends this table instead of replacing it).
-- ---------------------------------------------------------------------------
create table lab.placement_map (
    run_id     bigint not null,
    member_id  bigint not null,
    parent_id  bigint,
    slot       int check (slot between 0 and 2),
    depth      int not null check (depth >= 0),
    primary key (run_id, member_id),
    constraint placement_map_member_fk
        foreign key (run_id, member_id) references lab.derived_members (run_id, member_id),
    constraint placement_map_parent_fk
        foreign key (run_id, parent_id) references lab.derived_members (run_id, member_id),
    -- The root (and only the root) has no parent and no slot.
    constraint placement_map_root_shape check ((parent_id is null) = (slot is null)),
    -- One member per (parent, slot): a slot can be filled once.
    constraint placement_map_slot_key unique (run_id, parent_id, slot)
);

-- ---------------------------------------------------------------------------
-- lab.plan_run_results: one row per derived member per run, zero-volume and
-- zero-earning members included (COMP-LAB-SPEC section 1.2).
-- sv, cv, qualified are PLAN-INDEPENDENT; rank_label and plan_metrics are the
-- plan's own vocabulary; total_earned is the sum of the member's rounded
-- lines, never re-rounded.
-- ---------------------------------------------------------------------------
create table lab.plan_run_results (
    run_id        bigint not null references lab.plan_runs (id),
    member_id     bigint not null,
    sv            numeric(12,2) not null,
    cv            numeric(12,2) not null,
    qualified     boolean not null,
    rank_label    text not null,
    plan_metrics  jsonb not null,
    total_earned  numeric(12,2) not null,
    primary key (run_id, member_id),
    constraint plan_run_results_member_fk
        foreign key (run_id, member_id) references lab.derived_members (run_id, member_id)
);

-- ---------------------------------------------------------------------------
-- lab.plan_run_lines: one row per payment, each carrying its machine-readable
-- reason (COMP-LAB-SPEC section 1.2). source_member_id and level are null for
-- aggregate-basis pay (binary pay leg); set for per-source pay (unilevel).
-- amount = round half up (rate x basis, 2), rounded AT THE LINE, exactly the
-- real engine's rule.
-- ---------------------------------------------------------------------------
create table lab.plan_run_lines (
    id                bigint generated always as identity primary key,
    run_id            bigint not null references lab.plan_runs (id),
    earner_id         bigint not null,
    source_member_id  bigint,
    level             int check (level >= 1),
    basis             numeric(12,2) not null,
    rate              numeric(6,4) not null,
    amount            numeric(12,2) not null,
    reason            text not null
                      check (reason in ('unilevel_level_pay', 'binary_pay_leg',
                                        'matrix_level_pay', 'stairstep_differential',
                                        'stairstep_override_gen1', 'stairstep_override_gen2')),
    constraint plan_run_lines_earner_fk
        foreign key (run_id, earner_id) references lab.derived_members (run_id, member_id),
    constraint plan_run_lines_source_fk
        foreign key (run_id, source_member_id) references lab.derived_members (run_id, member_id)
);

create index plan_run_lines_run_earner_idx on lab.plan_run_lines (run_id, earner_id);

-- ---------------------------------------------------------------------------
-- lab.watchlist: SHELL in phase L1 (watched accounts arrive in L3; the shell
-- lands with the schema so the L3 build is additive, per the spec's re-cut
-- phasing argument). No code reads or writes it yet.
-- ---------------------------------------------------------------------------
create table lab.watchlist (
    id          bigint generated always as identity primary key,
    member_ref  text not null,
    active      boolean not null default true,
    note        text,
    added_at    timestamptz not null default clock_timestamp()
);

-- ---------------------------------------------------------------------------
-- Scenario discipline triggers (COMP-LAB-SPEC section 9.2):
--   a. A scenario may be locked only if its parent is locked.
--   b. A locked scenario is frozen; the only permitted change is
--      locked -> archived with every other column untouched.
--   c. A locked (or archived) scenario's mutations are frozen entirely.
--   d. Scenario rows are never deleted (the project's no-delete rule).
--   e. A run may reference only a LOCKED scenario.
-- ---------------------------------------------------------------------------
create or replace function lab.enforce_scenario_discipline()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'DELETE' then
        raise exception 'lab.scenarios: rows are never deleted (archive instead)';
    end if;

    -- Lock rule: parent must already be locked.
    if new.status = 'locked'
       and (tg_op = 'INSERT' or old.status <> 'locked')
       and new.parent_scenario_id is not null then
        if not exists (select 1 from lab.scenarios p
                       where p.id = new.parent_scenario_id and p.status = 'locked') then
            raise exception
                'lab.scenarios: scenario % may be locked only if its parent is locked',
                new.scenario_code;
        end if;
    end if;

    -- Freeze rule: a locked row admits exactly one change, becoming archived.
    if tg_op = 'UPDATE' and old.status = 'locked' then
        if not (new.status = 'archived'
                and new.id = old.id
                and new.scenario_code = old.scenario_code
                and new.name = old.name
                and new.parent_scenario_id is not distinct from old.parent_scenario_id
                and new.created_at = old.created_at
                and new.notes is not distinct from old.notes) then
            raise exception
                'lab.scenarios: scenario % is locked and frozen; create a child scenario instead of editing',
                old.scenario_code;
        end if;
    end if;

    return new;
end;
$$;

create trigger scenarios_discipline
    before insert or update or delete on lab.scenarios
    for each row execute function lab.enforce_scenario_discipline();

create or replace function lab.enforce_mutation_freeze()
returns trigger
language plpgsql
as $$
declare
    v_scenario_id bigint;
    v_status text;
begin
    v_scenario_id := coalesce(new.scenario_id, old.scenario_id);
    select s.status into v_status from lab.scenarios s where s.id = v_scenario_id;
    if v_status is distinct from 'draft' then
        raise exception
            'lab.scenario_mutations: scenario % is %; mutations may change only while draft',
            v_scenario_id, coalesce(v_status, 'missing');
    end if;
    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;

create trigger scenario_mutations_freeze
    before insert or update or delete on lab.scenario_mutations
    for each row execute function lab.enforce_mutation_freeze();

create or replace function lab.enforce_run_registry_discipline()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'DELETE' then
        raise exception 'lab.plan_runs: registry rows are never deleted (archive instead)';
    end if;
    if tg_op = 'INSERT' then
        if not exists (select 1 from lab.scenarios s
                       where s.id = new.scenario_id and s.status = 'locked') then
            raise exception
                'lab.plan_runs: a run may reference only a LOCKED scenario (scenario id %)',
                new.scenario_id;
        end if;
    end if;
    return new;
end;
$$;

create trigger plan_runs_registry_discipline
    before insert or delete on lab.plan_runs
    for each row execute function lab.enforce_run_registry_discipline();

-- ---------------------------------------------------------------------------
-- The IDENTITY scenario: the base census with an empty mutation list, a real
-- scenario row so "no scenario" is not a special case anywhere (spec 9.1).
-- Locked at birth: it is definitionally complete and must never gain a
-- mutation.
-- ---------------------------------------------------------------------------
insert into lab.scenarios (scenario_code, name, status, notes)
values ('IDENTITY',
        'Identity scenario: the base census, empty mutation list',
        'locked',
        'Seeded by db\lab\001_lab_schema.sql. The derived member set under this '
        'scenario must equal the app.members census snapshot row for row; that '
        'equality is the L1 identity proof.')
on conflict (scenario_code) do nothing;

-- ---------------------------------------------------------------------------
-- The A-versus-B placement spread, present in the run output structure
-- (COMP-LAB-SPEC section 3.4): pairs every completed 'bfs_spill' run with its
-- 'volume_balanced' twin (same scenario, plan, period, parameters) and shows
-- both payouts, the spread, and the caption.
-- ---------------------------------------------------------------------------
create view lab.v_placement_spread as
select a.scenario_id,
       a.plan_code,
       a.period,
       a.plan_params,
       a.id            as run_id_bfs_spill,
       b.id            as run_id_volume_balanced,
       a.total_payout  as payout_bfs_spill,
       b.total_payout  as payout_volume_balanced,
       (a.total_payout - b.total_payout) as spread_a_minus_b,
       a.placement_caption,
       a.disclaimer
from lab.plan_runs a
join lab.plan_runs b
  on b.scenario_id = a.scenario_id
 and b.plan_code   = a.plan_code
 and b.period      = a.period
 and b.plan_params = a.plan_params
 and b.placement_strategy = 'volume_balanced'
where a.placement_strategy = 'bfs_spill'
  and a.status = 'complete'
  and b.status = 'complete';

-- ---------------------------------------------------------------------------
-- RLS in the house pattern: enabled on every lab table with ZERO policies.
-- Only the service role (which bypasses RLS) and the table owner can touch
-- lab rows. No definer view exists over any lab table.
-- ---------------------------------------------------------------------------
alter table lab.scenarios          enable row level security;
alter table lab.scenario_mutations enable row level security;
alter table lab.plan_runs          enable row level security;
alter table lab.derived_members    enable row level security;
alter table lab.member_volumes     enable row level security;
alter table lab.run_level_map      enable row level security;
alter table lab.placement_map      enable row level security;
alter table lab.plan_run_results   enable row level security;
alter table lab.plan_run_lines     enable row level security;
alter table lab.watchlist          enable row level security;

-- ---------------------------------------------------------------------------
-- The zero-grant wall. A newly created schema grants nothing by default; the
-- revokes below are belt and suspenders against any future sloppy grant
-- script, guarded so the file also runs on plain Postgres.
-- NOTE what is deliberately ABSENT here: there is no
-- "grant select on all tables in schema lab to app_demo_reader" and no
-- "grant usage on schema lab" to any public-facing role. That absence IS the
-- isolation mechanism (COMP-LAB-SPEC section 2.1 argument 1).
-- ---------------------------------------------------------------------------
do $$
declare
    r text;
begin
    foreach r in array array['anon', 'authenticated', 'app_demo_reader'] loop
        if exists (select 1 from pg_roles where rolname = r) then
            execute format('revoke all on all tables in schema lab from %I', r);
            execute format('revoke all on all functions in schema lab from %I', r);
            execute format('revoke usage on schema lab from %I', r);
        end if;
    end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- VERIFICATION (run after applying; every query must return ZERO rows)
-- ---------------------------------------------------------------------------
-- V1. No table grants in schema lab to any public-facing role:
--   select grantee, table_name, privilege_type
--   from information_schema.role_table_grants
--   where table_schema = 'lab'
--     and grantee in ('anon', 'authenticated', 'app_demo_reader');
--
-- V2. No usage on schema lab for any public-facing role:
--   select r.rolname
--   from pg_roles r
--   where r.rolname in ('anon', 'authenticated', 'app_demo_reader')
--     and has_schema_privilege(r.rolname, 'lab', 'usage');
--
-- V3. The value 'final' is impossible in lab (expect check_violation):
--   insert into lab.plan_runs (scenario_id, plan_code, plan_params, period,
--                              status, order_source)
--   select id, 'unilevel_v13', '{}'::jsonb, date '2026-01-01', 'final', 'x'
--   from lab.scenarios where scenario_code = 'IDENTITY';
--
-- V4. The 'LAB-' name wall holds (expect check_violation on a synthetic row
--     whose code does not start with LAB-). Exercised by proof script
--     db\lab\100_proof_isolation.sql.
