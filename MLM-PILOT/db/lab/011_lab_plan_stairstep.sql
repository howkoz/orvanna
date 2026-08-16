-- Lab 011: plan 'stairstep_breakaway', draft parameters
-- Project: MLM (Multi-Level Marketing) Pilot (Orvanna persona, personal project)
-- Date: 2026-08-16
-- Author: mlm-comp-engineer
-- Spec: COMP-LAB-SPEC.md v1.2 section 4.4. Runs on the real SPONSOR tree
--       (no derived placement). Requires db\lab\001..008.
--
-- Acronym key: Sales Volume (SV), Commissionable Volume (CV),
-- Group Volume (GV), JavaScript Object Notation (JSON).
--
-- THE PLAN, restated operationally:
--   GV(m)        = own SV + SV of m's whole sponsor subtree EXCLUDING
--                  breakaway groups. Computed bottom-up (leaves first),
--                  because a member's breakaway status depends on their own
--                  GV, which depends on their non-breakaway children's GV.
--   breakaway(m) = GV(m) >= 15,000.00 (monthly-pure, like ranks).
--   bracket(gv)  = the rate of the highest bracket floor at or under gv
--                  (5 percent from 0, 10 from 1,000, 15 from 5,000, 20 from
--                  15,000; every threshold inclusive, house rule).
--   DIFFERENTIAL, one line per qualified earner, reason
--   'stairstep_differential':
--     amount = round( rate(own GV) x (own CV + non-breakaway group CV)
--                     minus SUM over each NON-BREAKAWAY direct child c of
--                     rate(GV(c)) x (CV(c) + group CV(c)), 2)
--     computed exactly in numeric and rounded ONCE at the line. Breakaway
--     children are excluded from BOTH terms: their group left the earner's
--     GV, and what the earner gets from them is the override, not the
--     differential. An unqualified member earns no line but their bracket
--     still subtracts from their upline normally (spec rule).
--   MONOTONICITY, the spec's proof made executable: parent GV >= each
--   non-breakaway child's GV, brackets are monotone, so no differential can
--   be negative. This function ASSERTS it: any negative differential raises
--   and aborts the run, and the minimum differential observed is recorded
--   in the run notes as part of the run output.
--   OVERRIDES, per breakaway b with group CV G = CV(b) + group CV(b),
--   walking the sponsor chain upward from b with a boundary counter k
--   (k = breakaway ancestors passed so far):
--     the first QUALIFIED member reached while k = 0 earns
--       round(0.04 x G, 2), reason 'stairstep_override_gen1';
--     the first QUALIFIED member reached while k = 1 earns
--       round(0.02 x G, 2), reason 'stairstep_override_gen2';
--     the walk stops at k = 2 (only generations 1 and 2 exist) or at the
--     top. "Generation counting restarts at each breakaway boundary": k
--     increments AFTER a breakaway ancestor is considered as a candidate,
--     so a qualified breakaway ancestor can itself earn the generation 1
--     override before becoming the boundary. A generation 2 payment
--     therefore exists exactly when a breakaway is found under a breakaway,
--     which is the spec's own parenthetical definition.
--   INTERPRETATION FLAGS FOR THE ARCHITECT, stated in the proof document:
--     (a) the walk model above is this build's reading of the override
--         clause; the mini fixtures pin its arithmetic for the verifier;
--     (b) for a differential line, a single (rate x basis) product cannot
--         reproduce the amount when child brackets differ from the
--         earner's. This build stores rate = the earner's bracket rate,
--         basis = own CV + non-breakaway group CV (the amount that rate
--         was applied to, per the section 1.2 parenthetical), amount = the
--         rounded differential, and the full decomposition in
--         plan_metrics, so every dollar remains explainable by its row.
--
-- plan_metrics keys: gv, bracket (the rate), breakaway (boolean), group_cv
-- (the spec's watch shape {"gv": ..., "bracket": ...} plus the two fields
-- the differential needs to be audited).

create or replace function lab.fn_plan_stairstep(p_run_id bigint)
returns void
language plpgsql
as $$
declare
    v_params    jsonb;
    v_threshold numeric;
    v_gen1      numeric;
    v_gen2      numeric;
    v_max_depth int;
    d           int;
    v_min_diff  numeric;
    b           record;
    v_cur       bigint;
    v_k         int;
    v_gen1_paid boolean;
    v_gen2_paid boolean;
    v_cand      record;
begin
    select r.plan_params into v_params
    from lab.plan_runs r
    where r.id = p_run_id;

    if v_params is null or jsonb_typeof(v_params -> 'brackets') <> 'array' then
        raise exception
            'lab.fn_plan_stairstep: run % plan_params must carry a "brackets" array', p_run_id;
    end if;

    v_threshold := (v_params ->> 'breakaway_threshold')::numeric;
    v_gen1      := (v_params ->> 'override_gen1_rate')::numeric;
    v_gen2      := (v_params ->> 'override_gen2_rate')::numeric;

    if v_threshold is null or v_gen1 is null or v_gen2 is null then
        raise exception
            'lab.fn_plan_stairstep: run % plan_params must carry breakaway_threshold, '
            'override_gen1_rate, override_gen2_rate', p_run_id;
    end if;

    -- Bracket table: floors ascending; rate(gv) = the rate of the highest
    -- floor at or under gv.
    drop table if exists pg_temp.tmp_lab_ss_brackets;
    create temp table tmp_lab_ss_brackets on commit drop as
    select (t.elem ->> 'min')::numeric  as min_gv,
           (t.elem ->> 'rate')::numeric as rate
    from jsonb_array_elements(v_params -> 'brackets') as t(elem);

    -- Volumes, qualification, sponsor edge, and tree depth (number of
    -- ancestors; roots are depth 0; a forest is fine, each root anchors its
    -- own subtree, and GW-000 alone at GV 0 earns and pays nothing).
    drop table if exists pg_temp.tmp_lab_ss_calc;
    create temp table tmp_lab_ss_calc on commit drop as
    select mv.member_id,
           mv.sv,
           (round(0.80 * mv.sv, 2))::numeric(12,2) as cv,
           (mv.sv >= 100.00)                       as qualified,
           dm.sponsor_id,
           (select count(*) from lab.run_level_map lm
             where lm.run_id = p_run_id
               and lm.descendant_id = mv.member_id) as depth,
           null::numeric(14,2) as gv,
           null::boolean       as breakaway,
           null::numeric(14,2) as group_cv,
           null::numeric       as bracket_rate
    from lab.member_volumes mv
    join lab.derived_members dm
      on dm.run_id = p_run_id and dm.member_id = mv.member_id
    where mv.run_id = p_run_id;

    create index tmp_lab_ss_calc_sponsor_idx on tmp_lab_ss_calc (sponsor_id);
    create index tmp_lab_ss_calc_depth_idx   on tmp_lab_ss_calc (depth);

    select max(depth) into v_max_depth from pg_temp.tmp_lab_ss_calc;

    -- Bottom-up GV, breakaway, and group CV: process the deepest members
    -- first; every child of a depth-d member sits at depth d + 1 and is
    -- already resolved. Each pass is set-based; the loop runs once per
    -- tree level, not once per member.
    for d in reverse v_max_depth .. 0 loop
        update pg_temp.tmp_lab_ss_calc m
        set gv = t.gv,
            breakaway = (t.gv >= v_threshold),
            group_cv = t.group_cv,
            bracket_rate = (select br.rate from pg_temp.tmp_lab_ss_brackets br
                            where br.min_gv <= t.gv
                            order by br.min_gv desc limit 1)
        from (
            select c.member_id,
                   (c.sv + coalesce(k.child_gv, 0))::numeric(14,2)  as gv,
                   (coalesce(k.child_group_cv, 0))::numeric(14,2)   as group_cv
            from pg_temp.tmp_lab_ss_calc c
            left join (
                select ch.sponsor_id,
                       sum(ch.gv)            filter (where not ch.breakaway) as child_gv,
                       sum(ch.cv + ch.group_cv) filter (where not ch.breakaway) as child_group_cv
                from pg_temp.tmp_lab_ss_calc ch
                where ch.depth = d + 1
                group by ch.sponsor_id
            ) k on k.sponsor_id = c.member_id
            where c.depth = d
        ) t
        where m.member_id = t.member_id;
    end loop;

    -- The monotonicity assertion, over EVERY member (qualified or not,
    -- because an unqualified member's differential is breakage and must
    -- still be a well-formed non-negative quantity).
    select min(  c.bracket_rate * (c.cv + c.group_cv)
               - coalesce((select sum(ch.bracket_rate * (ch.cv + ch.group_cv))
                           from pg_temp.tmp_lab_ss_calc ch
                           where ch.sponsor_id = c.member_id
                             and not ch.breakaway), 0))
    into v_min_diff
    from pg_temp.tmp_lab_ss_calc c;

    if v_min_diff < 0 then
        raise exception
            'lab.fn_plan_stairstep: run % produced a NEGATIVE differential (%); '
            'the spec proves this impossible, so the inputs or the build are wrong '
            'and the run refuses to complete',
            p_run_id, v_min_diff;
    end if;

    update lab.plan_runs
    set notes = notes || ' | monotonicity asserted: minimum differential '
                || v_min_diff::text || ' >= 0'
    where id = p_run_id;

    -- Differential lines: qualified earners, non-zero amounts only
    -- (decision c: no zero lines), rounded once at the line.
    insert into lab.plan_run_lines
        (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
    select p_run_id,
           c.member_id,
           null,                        -- aggregate basis: no single source
           null,
           (c.cv + c.group_cv),         -- the amount the earner's rate applies to
           c.bracket_rate,
           round(  c.bracket_rate * (c.cv + c.group_cv)
                 - coalesce((select sum(ch.bracket_rate * (ch.cv + ch.group_cv))
                             from pg_temp.tmp_lab_ss_calc ch
                             where ch.sponsor_id = c.member_id
                               and not ch.breakaway), 0), 2),
           'stairstep_differential'
    from pg_temp.tmp_lab_ss_calc c
    where c.qualified
      and round(  c.bracket_rate * (c.cv + c.group_cv)
                - coalesce((select sum(ch.bracket_rate * (ch.cv + ch.group_cv))
                            from pg_temp.tmp_lab_ss_calc ch
                            where ch.sponsor_id = c.member_id
                              and not ch.breakaway), 0), 2) > 0
    order by c.member_id;

    -- Override lines: per breakaway, ascending member id (stable order),
    -- generation 1 before generation 2, the walk model of the header.
    for b in
        select c.member_id, c.sponsor_id,
               (c.cv + c.group_cv)::numeric(14,2) as group_total_cv
        from pg_temp.tmp_lab_ss_calc c
        where c.breakaway
        order by c.member_id
    loop
        v_cur := b.sponsor_id;
        v_k := 0;
        v_gen1_paid := false;
        v_gen2_paid := false;

        while v_cur is not null and v_k <= 1 loop
            select c.member_id, c.sponsor_id, c.qualified, c.breakaway
            into v_cand
            from pg_temp.tmp_lab_ss_calc c
            where c.member_id = v_cur;

            if v_cand.qualified and v_k = 0 and not v_gen1_paid then
                insert into lab.plan_run_lines
                    (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
                values (p_run_id, v_cand.member_id, b.member_id, null,
                        b.group_total_cv, v_gen1,
                        round(v_gen1 * b.group_total_cv, 2),
                        'stairstep_override_gen1');
                v_gen1_paid := true;
            elsif v_cand.qualified and v_k = 1 and not v_gen2_paid then
                insert into lab.plan_run_lines
                    (run_id, earner_id, source_member_id, level, basis, rate, amount, reason)
                values (p_run_id, v_cand.member_id, b.member_id, null,
                        b.group_total_cv, v_gen2,
                        round(v_gen2 * b.group_total_cv, 2),
                        'stairstep_override_gen2');
                v_gen2_paid := true;
                exit;                    -- both generations settled
            end if;

            if v_cand.breakaway then
                v_k := v_k + 1;          -- the boundary, counted after candidacy
            end if;

            v_cur := v_cand.sponsor_id;
        end loop;
    end loop;

    -- Results: every member; rank_label is the plan's own vocabulary
    -- ('bracket_5pct' .. 'bracket_20pct').
    insert into lab.plan_run_results
        (run_id, member_id, sv, cv, qualified, rank_label, plan_metrics, total_earned)
    select p_run_id,
           c.member_id,
           c.sv,
           c.cv,
           c.qualified,
           'bracket_' || (c.bracket_rate * 100)::int || 'pct',
           jsonb_build_object(
               'gv',        c.gv,
               'bracket',   c.bracket_rate,
               'breakaway', c.breakaway,
               'group_cv',  c.group_cv),
           coalesce(e.total_earned, 0.00)
    from pg_temp.tmp_lab_ss_calc c
    left join (
        select l.earner_id, sum(l.amount) as total_earned
        from lab.plan_run_lines l
        where l.run_id = p_run_id
        group by l.earner_id
    ) e on e.earner_id = c.member_id
    order by c.member_id;

    drop table if exists pg_temp.tmp_lab_ss_calc;
    drop table if exists pg_temp.tmp_lab_ss_brackets;
end;
$$;

revoke execute on function lab.fn_plan_stairstep(bigint) from public;
