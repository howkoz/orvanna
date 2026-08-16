-- Lab 002: the derivation layer (census snapshot, level map, volume snapshot)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 sections 1.1 (what every plan RECEIVES) and
--       9.4 (determinism rule). Requires db\lab\001_lab_schema.sql.
--
-- Acronym key: Sales Volume (SV), Structured Query Language (SQL).
--
-- WHY THE DERIVATION LAYER ARRIVES IN PHASE L1 (spec section 7): scenarios
-- changed the interface INPUT. Every plan reads a DERIVED tree, never
-- app.members directly. In L1 the only scenario is IDENTITY (empty mutation
-- list), so derivation is exactly a census snapshot; the mutation REPLAY
-- arrives in L3 on this same input path, with no rebuild.
--
-- READS FROM SCHEMA APP (all read-only, the spec's explicit snapshot steps):
--   app.members      (census: id, member_code, sponsor_id, enrolled_on)
--   app.orders and app.order_lines (the month's volume, status 'completed')
-- WRITES ONLY TO SCHEMA LAB. No function in this file (or any lab file)
-- contains an INSERT, UPDATE, or DELETE against schema app; proof script
-- db\lab\100_proof_isolation.sql greps every lab function body to prove it.

-- ---------------------------------------------------------------------------
-- lab.fn_derive_members(p_run_id)
-- Materializes the run's derived member set into lab.derived_members.
-- IDENTITY scenario: exactly the census, row for row, census ids kept
-- (spec 9.4: census members keep their ids; synthetic ids start at
-- 10,000,001 and therefore sort after every census id).
-- Any mutation found in the scenario's EFFECTIVE list (parent chain flattened
-- root-first, seq order) is refused LOUDLY: replay arrives in phase L3, and a
-- half-applied scenario is worse than no run (spec 9.2).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_derive_members(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_scenario_id    bigint;
    v_mutation_count int;
begin
    select r.scenario_id into v_scenario_id
    from lab.plan_runs r
    where r.id = p_run_id;

    if not found then
        raise exception 'lab.fn_derive_members: run % does not exist', p_run_id;
    end if;

    -- Effective mutation list size across the whole parent chain.
    with recursive chain as (
        select s.id, s.parent_scenario_id
        from lab.scenarios s
        where s.id = v_scenario_id
        union all
        select s.id, s.parent_scenario_id
        from lab.scenarios s
        join chain c on s.id = c.parent_scenario_id
    )
    select count(*) into v_mutation_count
    from lab.scenario_mutations m
    join chain c on c.id = m.scenario_id;

    if v_mutation_count > 0 then
        raise exception
            'lab.fn_derive_members: scenario chain of run % carries % mutation(s); '
            'mutation replay arrives in phase L3. A mutation is never silently '
            'skipped (COMP-LAB-SPEC section 9.2).',
            p_run_id, v_mutation_count;
    end if;

    -- The census snapshot, materialized once. Stable ORDER BY so two
    -- derivations from the same census insert identical rows in identical
    -- order (determinism contract, spec 9.4).
    insert into lab.derived_members
        (run_id, member_id, member_code, sponsor_id, enrolled_on, app_member_id)
    select p_run_id, m.id, m.member_code, m.sponsor_id, m.enrolled_on, m.id
    from app.members m
    order by m.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_build_level_map(p_run_id)
-- The run-scoped level map over the DERIVED tree, exactly the discipline of
-- app.run_level_map in db\comp\001_comp_engine.sql: a recursive walk UP the
-- sponsor chain, full depth (a cap would corrupt Team Volume), materialized
-- once, read by every later step.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_build_level_map(p_run_id bigint)
returns void
language plpgsql
as $$
begin
    -- A sponsor missing from the derived set means a broken derivation;
    -- fail loudly rather than compute on a disconnected tree.
    if exists (
        select 1
        from lab.derived_members d
        where d.run_id = p_run_id
          and d.sponsor_id is not null
          and not exists (select 1 from lab.derived_members s
                          where s.run_id = p_run_id and s.member_id = d.sponsor_id)
    ) then
        raise exception
            'lab.fn_build_level_map: run % has a member whose sponsor is not in the derived set',
            p_run_id;
    end if;

    -- Census cycle-freedom is guaranteed by the sponsor cycle-check trigger
    -- on app.members (migration 002); the identity derivation copies that
    -- tree unchanged, so this recursion terminates.
    insert into lab.run_level_map (run_id, ancestor_id, descendant_id, level)
    with recursive walk as (
        select d.sponsor_id as ancestor_id,
               d.member_id  as descendant_id,
               1            as level
        from lab.derived_members d
        where d.run_id = p_run_id
          and d.sponsor_id is not null

        union all

        select p.sponsor_id,
               w.descendant_id,
               w.level + 1
        from walk w
        join lab.derived_members p
          on p.run_id = p_run_id
         and p.member_id = w.ancestor_id
        where p.sponsor_id is not null
    )
    select p_run_id, w.ancestor_id, w.descendant_id, w.level
    from walk w
    order by w.ancestor_id, w.descendant_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_snapshot_volumes(p_run_id)
-- The month's SV per derived member, computed once per run with the same
-- query shape as the real engine's member_sv step (sum of quantity times
-- unit_volume over completed orders stamped with the run's volume month),
-- over the DERIVED member set. Zero-volume members get an explicit 0.00 row.
--
-- Synthetic members (app_member_id null) have no census orders, so the left
-- join yields 0.00; their volume PROFILES arrive with scenario replay in
-- phase L3. In L1 no synthetic member exists in any census run.
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
           (coalesce(sum(ol.quantity * ol.unit_volume), 0))::numeric(12,2)
    from lab.derived_members dm
    left join app.orders o
           on o.member_id = dm.app_member_id
          and o.volume_month = v_period
          and o.status = 'completed'
    left join app.order_lines ol
           on ol.order_id = o.id
    where dm.run_id = p_run_id
    group by dm.member_id
    order by dm.member_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privilege hygiene, engine convention: only the service role or owner runs
-- lab functions.
-- ---------------------------------------------------------------------------
revoke execute on function lab.fn_derive_members(bigint)   from public;
revoke execute on function lab.fn_build_level_map(bigint)  from public;
revoke execute on function lab.fn_snapshot_volumes(bigint) from public;
