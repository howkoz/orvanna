-- Lab 014: scenario replay, the mutation machinery (phase L3, part one)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.3 sections 9.1 through 9.4 and the section 8
--       rulings (question 7: stack depth 3; question 9: month-scoped
--       removal; question 10: volume profiles in multiples of 50.00).
--       Requires db\lab\001..013.
--
-- Acronym key: Sales Volume (SV), Structured Query Language (SQL),
-- JavaScript Object Notation (JSON).
--
-- WHAT CHANGES. The derivation layer stops refusing mutations (the L1
-- placeholder) and REPLAYS them: derived tree = the run's base member set
-- plus the effective mutation list (parent chain flattened root-first, seq
-- order within each scenario) replayed in order, month-scoped mutations
-- applied only when active at the run's period. Same census snapshot plus
-- same effective list equals identical lab.derived_members rows, identical
-- level map, byte-identical run output (spec 9.4).
--
-- DESIGN DECISIONS, each named:
--   1. sv_override ON THE DERIVED ROW. One volume path for everything:
--      lab.fn_snapshot_volumes now reads coalesce(sv_override, census
--      orders). Census members carry null and read app.orders; synthetic
--      members carry their profile's value for the run month; set_volume
--      writes the override; and the PROOF fixtures load their base trees as
--      derived rows WITH sv_override, so fixture runs and census runs run
--      the identical snapshot code. Additive nullable column; frozen L1/L2
--      run rows are untouched (their volumes were inserted directly and
--      their runs are complete and trigger-frozen).
--   2. THE BASE IS THE RUN'S, NOT ALWAYS THE CENSUS. Census runs derive
--      their base from app.members (fn_derive_members); the section 6 proof
--      fixtures hand-load the five-member base (ids 1 to 5, LAB- codes,
--      sv_override set) and then call fn_replay_mutations directly, so the
--      spec's S1 and S2 hand examples exercise the REAL replay code over
--      the exact tree the spec computed them on. Fixture base ids sit LOW
--      (1..5) so the spec 9.4 synthetic id rule (10,000,000 + ordinal)
--      sorts synthetic members after every base member in fixtures exactly
--      as it does after every census member in census runs.
--   3. ORDINALS COUNT THE FULL LIST. A month-scoped add_member outside its
--      window is skipped for the month but still consumes its ordinal, so a
--      synthetic member keeps ONE id across every month of a window
--      (trajectories track the same account, spec 9.4).
--   4. VALIDATION SPLIT, honestly. Locking validates SHAPE (per-kind
--      required fields, profile grain, stack depth); EXISTENCE and cycle
--      checks happen at replay and fail LOUDLY (a mutation is never
--      silently skipped, spec 9.2). Lock-time existence checking cannot
--      work in general because fixture scenarios reference LAB- base
--      members that exist only inside a run. Flagged for the architect in
--      the L3 proof document.
--   5. remove_member deletes the target row AFTER re-pointing its frontline
--      to the target's sponsor. The spec's "orphans processed in ascending
--      member id" is honored by a single set-based UPDATE: every orphan
--      receives the same new sponsor, so per-row order cannot change the
--      result, and the outcome is identical to the ascending walk.

alter table lab.derived_members
    add column if not exists sv_override numeric(12,2);

comment on column lab.derived_members.sv_override is
    'Non-null: this member''s SV for the run month is this value (synthetic '
    'member profile, set_volume override, or a hand-loaded fixture base). '
    'Null: SV comes from app.orders through the volume snapshot. Added by '
    'lab 014.';

-- ---------------------------------------------------------------------------
-- lab.fn_effective_mutations(p_scenario_id)
-- The effective list: parent chain flattened ROOT-FIRST, each scenario's
-- mutations in seq order (spec 9.4). ord is the 1-based position in the
-- whole effective list.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_effective_mutations(p_scenario_id bigint)
returns table (ord bigint, scenario_code text, seq int, kind text,
               target_ref text, new_sponsor_ref text, volume_profile jsonb,
               month_from date, month_to date)
language sql
stable
as $$
    with recursive chain as (
        select s.id, s.scenario_code, s.parent_scenario_id, 1 as up
        from lab.scenarios s
        where s.id = p_scenario_id
        union all
        select s.id, s.scenario_code, s.parent_scenario_id, c.up + 1
        from lab.scenarios s
        join chain c on s.id = c.parent_scenario_id
    ),
    ordered_chain as (
        -- Deepest ancestor (the chain root) first.
        select id, scenario_code,
               row_number() over (order by up desc) as chain_pos
        from chain
    )
    select row_number() over (order by oc.chain_pos, m.seq) as ord,
           oc.scenario_code, m.seq, m.kind, m.target_ref, m.new_sponsor_ref,
           m.volume_profile, m.month_from, m.month_to
    from ordered_chain oc
    join lab.scenario_mutations m on m.scenario_id = oc.id
    order by oc.chain_pos, m.seq;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_profile_sv(p_profile, p_period)
-- Resolves a volume profile for one month: {"sv_per_month": X} applies to
-- every month; a per-month map {"2026-08": X, ...} applies to listed months
-- and returns NULL for unlisted ones (an add_member then contributes 0.00
-- that month; a set_volume is inert that month). Values must be
-- non-negative multiples of 50.00 (Howard's ruled default, section 8
-- question 10: preserves the plan's rounding-never-fires property).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_profile_sv(p_profile jsonb, p_period date)
returns numeric
language plpgsql
immutable
as $$
declare
    v numeric;
    k text;
begin
    if p_profile is null then
        return null;
    end if;
    if p_profile ? 'sv_per_month' then
        v := (p_profile ->> 'sv_per_month')::numeric;
    else
        k := to_char(p_period, 'YYYY-MM');
        if p_profile ? k then
            v := (p_profile ->> k)::numeric;
        else
            return null;
        end if;
    end if;
    if v < 0 or mod(v, 50.00) <> 0 then
        raise exception
            'volume profile value % is not a non-negative multiple of 50.00 '
            '(ruled default, COMP-LAB-SPEC section 8 question 10)', v;
    end if;
    return v;
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_replay_mutations(p_run_id)
-- Replays the run scenario's effective list onto the run's already-present
-- base rows in lab.derived_members. Every missing reference, root removal,
-- or cycle FAILS the run loudly (spec 9.2: a half-applied scenario is worse
-- than no run).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_replay_mutations(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_run            lab.plan_runs%rowtype;
    mut              record;
    v_ordinal        int := 0;
    v_active         boolean;
    v_target         bigint;
    v_target_sponsor bigint;
    v_sponsor        bigint;
    v_sv             numeric;
begin
    select * into v_run from lab.plan_runs where id = p_run_id;
    if not found then
        raise exception 'lab.fn_replay_mutations: run % does not exist', p_run_id;
    end if;

    for mut in select * from lab.fn_effective_mutations(v_run.scenario_id)
    loop
        -- Ordinals over the FULL list (design decision 3).
        if mut.kind = 'add_member' then
            v_ordinal := v_ordinal + 1;
        end if;

        -- Month scoping (ruled default, section 8 question 9): active for
        -- this run's month, or skipped for this run.
        v_active := (mut.month_from is null or mut.month_from <= v_run.period)
                and (mut.month_to   is null or v_run.period <= mut.month_to);
        if not v_active then
            continue;
        end if;

        if mut.kind = 'add_member' then
            select d.member_id into v_sponsor
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.new_sponsor_ref;
            if v_sponsor is null then
                raise exception
                    'replay failed loudly: mutation % (add_member, scenario %) names sponsor ''%'' which does not exist at its point in the replay',
                    mut.ord, mut.scenario_code, mut.new_sponsor_ref;
            end if;
            v_sv := coalesce(lab.fn_profile_sv(mut.volume_profile, v_run.period), 0.00);
            insert into lab.derived_members
                (run_id, member_id, member_code, sponsor_id, enrolled_on,
                 app_member_id, sv_override)
            values
                (p_run_id,
                 10000000 + v_ordinal,                             -- spec 9.4 id rule
                 'LAB-' || mut.scenario_code || '-' || mut.seq,    -- spec 9.4 code rule
                 v_sponsor,
                 v_run.period,                                     -- deterministic enrolment stamp
                 null,
                 v_sv);

        elsif mut.kind = 'remove_member' then
            select d.member_id, d.sponsor_id into v_target, v_target_sponsor
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.target_ref;
            if v_target is null then
                raise exception
                    'replay failed loudly: mutation % (remove_member, scenario %) targets ''%'' which does not exist at its point in the replay',
                    mut.ord, mut.scenario_code, mut.target_ref;
            end if;
            if v_target_sponsor is null then
                raise exception
                    'replay failed loudly: mutation % (remove_member) targets the root ''%''; removing the root is REFUSED (spec 9.2)',
                    mut.ord, mut.target_ref;
            end if;
            -- The ratified roll-up: frontline reattaches to the removed
            -- member's sponsor, each orphan keeping its own subtree.
            update lab.derived_members
            set sponsor_id = v_target_sponsor
            where run_id = p_run_id and sponsor_id = v_target;
            delete from lab.derived_members
            where run_id = p_run_id and member_id = v_target;

        elsif mut.kind = 'remove_leg' then
            select d.member_id, d.sponsor_id into v_target, v_target_sponsor
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.target_ref;
            if v_target is null then
                raise exception
                    'replay failed loudly: mutation % (remove_leg, scenario %) targets ''%'' which does not exist at its point in the replay',
                    mut.ord, mut.scenario_code, mut.target_ref;
            end if;
            if v_target_sponsor is null then
                raise exception
                    'replay failed loudly: mutation % (remove_leg) targets the root ''%''; not the root (spec 9.2)',
                    mut.ord, mut.target_ref;
            end if;
            -- The whole subtree, target included ("what if this leg never
            -- existed").
            with recursive sub as (
                select v_target as member_id
                union all
                select d.member_id
                from lab.derived_members d
                join sub on d.sponsor_id = sub.member_id
                where d.run_id = p_run_id
            )
            delete from lab.derived_members dm
            using sub
            where dm.run_id = p_run_id and dm.member_id = sub.member_id;

        elsif mut.kind = 'move_member' then
            select d.member_id into v_target
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.target_ref;
            select d.member_id into v_sponsor
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.new_sponsor_ref;
            if v_target is null or v_sponsor is null then
                raise exception
                    'replay failed loudly: mutation % (move_member, scenario %) needs both ''%'' and ''%'' to exist at its point in the replay',
                    mut.ord, mut.scenario_code, mut.target_ref, mut.new_sponsor_ref;
            end if;
            -- Cycle refusal: the new sponsor must not sit inside the moved
            -- subtree (target included).
            if exists (
                with recursive sub as (
                    select v_target as member_id
                    union all
                    select d.member_id
                    from lab.derived_members d
                    join sub on d.sponsor_id = sub.member_id
                    where d.run_id = p_run_id
                )
                select 1 from sub where sub.member_id = v_sponsor
            ) then
                raise exception
                    'replay failed loudly: mutation % (move_member) would create a cycle: ''%'' is inside the subtree of ''%''',
                    mut.ord, mut.new_sponsor_ref, mut.target_ref;
            end if;
            update lab.derived_members
            set sponsor_id = v_sponsor
            where run_id = p_run_id and member_id = v_target;

        elsif mut.kind = 'set_volume' then
            select d.member_id into v_target
            from lab.derived_members d
            where d.run_id = p_run_id and d.member_code = mut.target_ref;
            if v_target is null then
                raise exception
                    'replay failed loudly: mutation % (set_volume, scenario %) targets ''%'' which does not exist at its point in the replay',
                    mut.ord, mut.scenario_code, mut.target_ref;
            end if;
            v_sv := lab.fn_profile_sv(mut.volume_profile, v_run.period);
            if v_sv is not null then
                update lab.derived_members
                set sv_override = v_sv
                where run_id = p_run_id and member_id = v_target;
            end if;
        end if;
    end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_derive_members v2: census snapshot, then replay. The L1 refusal
-- placeholder retires; the IDENTITY scenario's empty list makes the replay
-- a no-op, so L1 and L2 behavior is unchanged for it by construction.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_derive_members(p_run_id bigint)
returns void
language plpgsql
as $$
begin
    if not exists (select 1 from lab.plan_runs r where r.id = p_run_id) then
        raise exception 'lab.fn_derive_members: run % does not exist', p_run_id;
    end if;

    insert into lab.derived_members
        (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id, sv_override)
    select p_run_id, m.id, m.member_code, m.sponsor_id, m.enrolled_on, m.id, null
    from app.members m
    order by m.id;

    perform lab.fn_replay_mutations(p_run_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_snapshot_volumes v2: one volume path (design decision 1).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_snapshot_volumes(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_period date;
begin
    select r.period into v_period
    from lab.plan_runs r
    where r.id = p_run_id;

    if not found then
        raise exception 'lab.fn_snapshot_volumes: run % does not exist', p_run_id;
    end if;

    insert into lab.member_volumes (run_id, member_id, sv)
    select p_run_id,
           dm.member_id,
           coalesce(dm.sv_override,
                    (coalesce(sum(ol.quantity * ol.unit_volume), 0)))::numeric(12,2)
    from lab.derived_members dm
    left join app.orders o
           on o.member_id = dm.app_member_id
          and o.volume_month = v_period
          and o.status = 'completed'
    left join app.order_lines ol
           on ol.order_id = o.id
    where dm.run_id = p_run_id
    group by dm.member_id, dm.sv_override
    order by dm.member_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Scenario discipline v2: shape validation and the stack-depth cap at lock.
-- Existence stays a replay-time check (design decision 4).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_validate_scenario_shape(p_scenario_id bigint)
returns void
language plpgsql
as $$
declare
    m record;
    v_val text;
    v_depth int;
begin
    -- Stack depth cap 3 (ruled default, section 8 question 7), self included.
    with recursive chain as (
        select s.id, s.parent_scenario_id, 1 as depth
        from lab.scenarios s where s.id = p_scenario_id
        union all
        select s.id, s.parent_scenario_id, c.depth + 1
        from lab.scenarios s join chain c on s.id = c.parent_scenario_id
    )
    select max(depth) into v_depth from chain;

    if v_depth > 3 then
        raise exception
            'lab.scenarios: stack depth % exceeds the ruled cap of 3; flatten into a new root scenario (COMP-LAB-SPEC section 8 question 7)',
            v_depth;
    end if;

    for m in select * from lab.scenario_mutations where scenario_id = p_scenario_id
    loop
        if m.kind = 'add_member' then
            if m.new_sponsor_ref is null then
                raise exception 'scenario mutation seq %: add_member needs new_sponsor_ref', m.seq;
            end if;
        elsif m.kind in ('remove_member', 'remove_leg') then
            if m.target_ref is null then
                raise exception 'scenario mutation seq %: % needs target_ref', m.seq, m.kind;
            end if;
        elsif m.kind = 'move_member' then
            if m.target_ref is null or m.new_sponsor_ref is null then
                raise exception 'scenario mutation seq %: move_member needs target_ref and new_sponsor_ref', m.seq;
            end if;
        elsif m.kind = 'set_volume' then
            if m.target_ref is null or m.volume_profile is null then
                raise exception 'scenario mutation seq %: set_volume needs target_ref and volume_profile', m.seq;
            end if;
        end if;

        -- Profile grain: every value a non-negative multiple of 50.00.
        if m.volume_profile is not null then
            for v_val in select value from jsonb_each_text(m.volume_profile)
            loop
                if v_val !~ '^[0-9]+(\.[0-9]+)?$'
                   or mod(v_val::numeric, 50.00) <> 0 then
                    raise exception
                        'scenario mutation seq %: profile value % is not a non-negative multiple of 50.00 (ruled default)',
                        m.seq, v_val;
                end if;
            end loop;
        end if;
    end loop;
end;
$$;

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

-- Lock-time validation runs AFTER the row change lands (mutations must be
-- inserted while draft, then the lock validates them), so it is a separate
-- AFTER trigger on the transition to locked.
create or replace function lab.enforce_scenario_lock_validation()
returns trigger
language plpgsql
as $$
begin
    if new.status = 'locked'
       and (tg_op = 'INSERT' or old.status is distinct from 'locked') then
        perform lab.fn_validate_scenario_shape(new.id);
    end if;
    return null;
end;
$$;

create trigger scenarios_lock_validation
    after insert or update on lab.scenarios
    for each row execute function lab.enforce_scenario_lock_validation();

revoke execute on function lab.fn_effective_mutations(bigint)      from public;
revoke execute on function lab.fn_profile_sv(jsonb, date)          from public;
revoke execute on function lab.fn_replay_mutations(bigint)         from public;
revoke execute on function lab.fn_validate_scenario_shape(bigint)  from public;
