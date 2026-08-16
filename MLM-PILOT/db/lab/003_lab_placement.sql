-- Lab 003: derived binary placement, both strategies
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.1 section 3 (the binary placement problem,
--       honestly). Requires db\lab\001 and 002.
--
-- Acronym key: Breadth-First Search (BFS), Sales Volume (SV),
-- Commissionable Volume (CV).
--
-- Orvanna has never had a placement tree: app.members stores a SPONSOR
-- genealogy where a member may have any number of frontline members. A binary
-- result on our data is therefore ALWAYS computed on a placement tree the lab
-- derived, and a different derivation gives different payouts. The lab's
-- answer is not to hide this: both strategies below run for every binary
-- month, and lab.v_placement_spread puts the two payouts side by side.
--
-- STRATEGY A, 'bfs_spill' (spec 3.2): sponsor-preference breadth-first fill.
--   Members process in ascending member id order (seed ids ascend with
--   enrollment; ties cannot occur on a primary key). For member m with
--   sponsor s: s's open left slot, else s's open right slot, else SPILLOVER,
--   the first open slot in a BFS scan of s's placement subtree (level by
--   level, within a level left subtree before right subtree, within a node
--   left slot before right slot). Implementation note: the three steps
--   collapse into ONE ordered scan, because a BFS of s's subtree visits s
--   itself first with its left slot before its right slot. Every step is a
--   total order, so the result is unique.
--
-- STRATEGY B, 'volume_balanced' (spec 3.3): weaker-leg by month volume.
--   Same processing order. For member m with sponsor s: starting at s,
--   repeatedly descend into the leg whose CURRENT placed members have the
--   smaller sum of the run month's SV (ties: left), until an open slot is
--   reached; place m there. Weights use the month's SV of already-placed
--   members only, so the walk is deterministic given the processing order.
--   This reading reproduces the spec's own section 6.4 hand-derivation of
--   the ten-member month exactly (M4 lands at M3.left because M1's right leg
--   carried less volume at that step; company pays 168.00).
--
-- TWO DOCUMENTED RULINGS THIS FILE MAKES, both flagged for the architect:
--   1. EXTRA ROOTS. Spec 3.2 step 1 says "the root of the placement tree is
--      the root of the sponsor tree", singular. The live census has TWO
--      rootless members: GW-000001 (the seed tree root, id 1) and GW-000
--      (the company retention account, id 1001, added by migration 020 with
--      no downline and no seeded volume). Rule applied here: the LOWEST-id
--      root is the placement root; every later rootless member is placed as
--      if sponsored by the placement root. This keeps one connected tree
--      (the spec's own assumption, section 9.3) and is deterministic. On the
--      seeded months it moves no money: GW-000 has zero SV in every seeded
--      month. Reported as a spec ambiguity in the L1 proof document.
--   2. PER-MEMBER LOOP. Placement is inherently sequential (each placement
--      depends on all earlier ones), so this is the one deliberate exception
--      to the engine's no-per-member-loops rule. At 1,000 members it runs in
--      seconds. The 100,000-member approach, recorded per charter: maintain
--      per-node subtree SV aggregates and open-slot frontier queues
--      incrementally instead of re-scanning, which makes each placement
--      O(depth) instead of O(subtree).

-- ---------------------------------------------------------------------------
-- lab.fn_placed_subtree_sv(p_run_id, p_root)
-- Sum of the run month's SV over p_root and every member already PLACED
-- beneath it in the placement tree being built. Strategy B's leg weight.
-- ---------------------------------------------------------------------------
create or replace function lab.fn_placed_subtree_sv(p_run_id bigint, p_root bigint)
returns numeric
language sql
stable
as $$
    with recursive st as (
        select p_root as member_id
        union all
        select pm.member_id
        from lab.placement_map pm
        join st on pm.parent_id = st.member_id
        where pm.run_id = p_run_id
    )
    select coalesce(sum(mv.sv), 0)::numeric
    from st
    join lab.member_volumes mv
      on mv.run_id = p_run_id
     and mv.member_id = st.member_id;
$$;

-- ---------------------------------------------------------------------------
-- lab.fn_derive_placement(p_run_id)
-- Materializes lab.placement_map for the run, per the run row's
-- placement_strategy. Reads lab.derived_members and lab.member_volumes
-- (volumes must already be snapshotted: strategy B weighs them).
-- ---------------------------------------------------------------------------
create or replace function lab.fn_derive_placement(p_run_id bigint)
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
    v_l_child   bigint;
    v_r_child   bigint;
    v_l_sum     numeric;
    v_r_sum     numeric;
begin
    select r.placement_strategy into v_strategy
    from lab.plan_runs r
    where r.id = p_run_id;

    if v_strategy is null then
        raise exception
            'lab.fn_derive_placement: run % carries no placement strategy', p_run_id;
    end if;

    -- The ascending-id processing order requires every sponsor to be placed
    -- before its members. True by construction for census ids (they ascend
    -- with enrollment) and for synthetic ids (10,000,001 and up, sponsors
    -- always earlier); verified here so a violation fails loudly instead of
    -- producing a silently wrong tree.
    if exists (
        select 1 from lab.derived_members d
        where d.run_id = p_run_id
          and d.sponsor_id is not null
          and d.sponsor_id >= d.member_id
    ) then
        raise exception
            'lab.fn_derive_placement: run % has a sponsor id >= member id; '
            'ascending-id placement order would be unsound', p_run_id;
    end if;

    for m in
        select d.member_id, d.sponsor_id
        from lab.derived_members d
        where d.run_id = p_run_id
        order by d.member_id
    loop
        -- Root handling, including the documented extra-root rule.
        if m.sponsor_id is null then
            if v_root is null then
                v_root := m.member_id;
                insert into lab.placement_map (run_id, member_id, parent_id, slot, depth)
                values (p_run_id, m.member_id, null, null, 0);
                continue;
            else
                v_sponsor := v_root;  -- extra root: placed as if sponsored by the placement root
            end if;
        else
            v_sponsor := m.sponsor_id;
        end if;

        if v_strategy = 'bfs_spill' then
            -- One ordered scan implements spec 3.2 steps 2 and 3: BFS of the
            -- sponsor's placement subtree, sponsor first. Order: depth, then
            -- path (left subtree before right subtree within a level), then
            -- slot (left before right within a node). First open slot wins.
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
                cross join (values (0), (1)) as cand(slot)
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
            -- Weigh-and-descend: at each node take the leg with the smaller
            -- placed SV sum (ties: left); an empty weaker leg IS the open
            -- slot. This is the reading spec section 6.4 hand-derives.
            v_cur := v_sponsor;
            loop
                select pm.member_id into v_l_child
                from lab.placement_map pm
                where pm.run_id = p_run_id and pm.parent_id = v_cur and pm.slot = 0;

                select pm.member_id into v_r_child
                from lab.placement_map pm
                where pm.run_id = p_run_id and pm.parent_id = v_cur and pm.slot = 1;

                v_l_sum := case when v_l_child is null then 0
                                else lab.fn_placed_subtree_sv(p_run_id, v_l_child) end;
                v_r_sum := case when v_r_child is null then 0
                                else lab.fn_placed_subtree_sv(p_run_id, v_r_child) end;

                if v_l_sum <= v_r_sum then          -- ties descend left, per spec
                    if v_l_child is null then
                        v_parent := v_cur; v_slot := 0; exit;
                    end if;
                    v_cur := v_l_child;
                else
                    if v_r_child is null then
                        v_parent := v_cur; v_slot := 1; exit;
                    end if;
                    v_cur := v_r_child;
                end if;
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

revoke execute on function lab.fn_placed_subtree_sv(bigint, bigint) from public;
revoke execute on function lab.fn_derive_placement(bigint)          from public;
