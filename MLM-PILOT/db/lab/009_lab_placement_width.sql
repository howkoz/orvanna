-- Lab 009: placement generalized to width N (matrix needs width 3)
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 section 4.3: "strategies A and B of section 3,
--       generalized to width 3: same algorithms with 3 slots per node; slot
--       order left-to-right; both strategies run." Requires db\lab\001..008.
--
-- Acronym key: Breadth-First Search (BFS), Sales Volume (SV).
--
-- File 003 is applied history and stays frozen. This file generalizes its
-- algorithm to N slots per node and redefines the two-slot entry point as a
-- delegation, so binary keeps byte-identical behavior:
--   width 2, bfs_spill      : candidate slots (0, 1) in that order, BFS scan
--                             ordered by depth, path, slot: IDENTICAL to 003.
--   width 2, volume_balanced: the leg with the smaller placed SV sum, ties
--                             to the LOWEST slot, descend or place: with two
--                             slots, "lowest slot on ties" IS "ties: left",
--                             IDENTICAL to 003.
-- The equivalence is re-proven live in proof 108 (the mini and ten-member
-- binary fixtures re-run through this code path must reproduce the L1
-- numbers).
--
-- The v1.2-ratified extra-root rule and the ascending-id guard carry over
-- verbatim. The per-member loop remains the documented deliberate exception
-- to the no-loops rule (placement is sequential by nature); the
-- 100,000-member approach stays as recorded in file 003.

create or replace function lab.fn_derive_placement_width(p_run_id bigint, p_width int)
returns void
language plpgsql
as $$
declare
    v_strategy  text;
    v_root      bigint;
    m           record;
    v_sponsor   bigint;
    v_parent    bigint;
    v_slot      int;
    v_cur       bigint;
    v_child     bigint;
    v_sum       numeric;
    v_best_slot int;
    v_best_sum  numeric;
    v_best_child bigint;
    s           int;
begin
    if p_width is null or p_width < 2 then
        raise exception 'lab.fn_derive_placement_width: width % is not a placement width', p_width;
    end if;

    select r.placement_strategy into v_strategy
    from lab.plan_runs r
    where r.id = p_run_id;

    if v_strategy is null then
        raise exception
            'lab.fn_derive_placement_width: run % carries no placement strategy', p_run_id;
    end if;

    if exists (
        select 1 from lab.derived_members d
        where d.run_id = p_run_id
          and d.sponsor_id is not null
          and d.sponsor_id >= d.member_id
    ) then
        raise exception
            'lab.fn_derive_placement_width: run % has a sponsor id >= member id; '
            'ascending-id placement order would be unsound', p_run_id;
    end if;

    for m in
        select d.member_id, d.sponsor_id
        from lab.derived_members d
        where d.run_id = p_run_id
        order by d.member_id
    loop
        if m.sponsor_id is null then
            if v_root is null then
                v_root := m.member_id;
                insert into lab.placement_map (run_id, member_id, parent_id, slot, depth)
                values (p_run_id, m.member_id, null, null, 0);
                continue;
            else
                -- Extra-root rule, RATIFIED in spec v1.2 section 3.2: the
                -- lowest-id rootless member anchors; later rootless members
                -- are placed as if sponsored by it.
                v_sponsor := v_root;
            end if;
        else
            v_sponsor := m.sponsor_id;
        end if;

        if v_strategy = 'bfs_spill' then
            -- One ordered scan: BFS of the sponsor's placement subtree,
            -- sponsor first; within a level, left subtree before right
            -- (path order); within a node, slots ascending. First open
            -- slot wins. Total order, unique result.
            with recursive sub as (
                select v_sponsor as member_id, array[]::int[] as path, 0 as d
                union all
                select pm.member_id, sub.path || pm.slot, sub.d + 1
                from lab.placement_map pm
                join sub on pm.parent_id = sub.member_id
                where pm.run_id = p_run_id
            ),
            candidate_slots as (
                select sub.member_id, sub.path, sub.d, cand.slot
                from sub
                cross join generate_series(0, p_width - 1) as cand(slot)
                where not exists (
                    select 1 from lab.placement_map c
                    where c.run_id = p_run_id
                      and c.parent_id = sub.member_id
                      and c.slot = cand.slot
                )
            )
            select cs.member_id, cs.slot
            into v_parent, v_slot
            from candidate_slots cs
            order by cs.d, cs.path, cs.slot
            limit 1;

        else  -- volume_balanced
            -- Weigh-and-descend over N legs: at each node take the leg with
            -- the smallest placed SV sum, ties to the LOWEST slot; an empty
            -- weaker leg IS the open slot (the spec 6.3-corrected reading).
            v_cur := v_sponsor;
            loop
                v_best_slot  := null;
                v_best_sum   := null;
                v_best_child := null;

                for s in 0 .. p_width - 1 loop
                    select pm.member_id into v_child
                    from lab.placement_map pm
                    where pm.run_id = p_run_id and pm.parent_id = v_cur and pm.slot = s;

                    v_sum := case when v_child is null then 0
                                  else lab.fn_placed_subtree_sv(p_run_id, v_child) end;

                    -- strict < : on equal sums the earlier (lower) slot wins
                    if v_best_sum is null or v_sum < v_best_sum then
                        v_best_slot  := s;
                        v_best_sum   := v_sum;
                        v_best_child := v_child;
                    end if;
                end loop;

                if v_best_child is null then
                    v_parent := v_cur; v_slot := v_best_slot; exit;
                end if;
                v_cur := v_best_child;
            end loop;
        end if;

        insert into lab.placement_map (run_id, member_id, parent_id, slot, depth)
        select p_run_id, m.member_id, v_parent, v_slot, p.depth + 1
        from lab.placement_map p
        where p.run_id = p_run_id and p.member_id = v_parent;

        v_parent := null;
        v_slot   := null;
    end loop;
end;
$$;

-- The two-slot entry point of file 003 becomes a delegation; every existing
-- caller keeps its exact behavior.
create or replace function lab.fn_derive_placement(p_run_id bigint)
returns void
language plpgsql
as $$
begin
    perform lab.fn_derive_placement_width(p_run_id, 2);
end;
$$;

revoke execute on function lab.fn_derive_placement_width(bigint, int) from public;
revoke execute on function lab.fn_derive_placement(bigint)            from public;
