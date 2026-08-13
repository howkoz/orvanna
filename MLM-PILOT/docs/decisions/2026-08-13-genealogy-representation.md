# Decision: genealogy representation, adjacency list plus per-run level snapshot

As of 2026-08-13. Status: DECIDED (architect role). Applies from the first migration.

Acronym key: Common Table Expression (CTE), Sales Volume (SV).

## The question

How the sponsor tree is stored and walked: adjacency list (each member points at its
sponsor) with recursive queries, versus a closure table (one row for every
ancestor-descendant pair, maintained on every change).

## Decision

**Adjacency list as the single source of truth** (`members.sponsor_id`), walked with
recursive CTEs, **plus a per-run materialized level map**: when a commission run
starts, the engine expands (earner, descendant, level 1..5) pairs once into a working
table scoped to that run, computes everything from that snapshot, and keeps it until
the run is superseded.

## Why

1. **Integrity is trivial.** One parent pointer per member; a cycle-check trigger is
   the whole invariant. A closure table must be perfectly maintained on every insert
   and re-sponsor event, and silent drift there corrupts pay.
2. **Scale is a non-issue at both targets.** A recursive CTE over an indexed
   sponsor_id resolves a 1,000-member tree in milliseconds and a 100,000-member tree
   in well under a second in Postgres. The pilot walks the whole tree once per monthly
   run, not per page view.
3. **The per-run snapshot buys determinism.** Statements must stay reproducible even
   if the tree is edited later (re-sponsoring in v2). Freezing the level map inside
   the run means the verifier can regrade an old run byte for byte, which is the whole
   audit story.
4. **Both walk types fit.** Level walks (plain distance, v1) and generation walks
   (stop at first member holding a rank, v2) are both natural recursive CTEs over the
   same adjacency; a closure table only helps the first.
5. **Site reads never touch the tree walk.** Pages read run-scoped results and views;
   the only recursive work happens inside the engine at run time.

## Rejected alternative

Closure table: faster for ad hoc "all descendants" queries at very large scale, but
costs write-path complexity and an integrity surface we do not need at 100,000 members,
and it duplicates what the per-run snapshot already provides where it matters (inside
a run).

## Consequences

- Migration 001 creates members with sponsor_id, its index, and the cycle-check
  trigger.
- The comp engine (Phase 3) creates the run-scoped level map as its first step; SV
  rollups and TV aggregation read from that snapshot, never live.
