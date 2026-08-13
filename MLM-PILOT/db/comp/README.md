# Comp Engine (Phase 3)

As of 2026-08-13. Builder: mlm-comp-engineer. Graded by mlm-verifier (recomputes
the math) and mlm-qa (acceptance). The builder never grades its own work.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Personal Volume (PV), Common Table Expression
(CTE), Row-Level Security (RLS), Quality Assurance (QA).

Contract: `docs\COMP-PLAN-SPEC.md` version v1.1. Table shapes:
`docs\SCHEMA-SPEC.md` and `db\migrations\001..005`. Genealogy walk:
`docs\decisions\2026-08-13-genealogy-representation.md`.

## Files and run order

| Order | File | What it does |
|---|---|---|
| 1 | `001_comp_engine.sql` | Creates `app.run_level_map` and the two functions `app.fn_run_commission(period)` and `app.fn_finalize_run(run_id)`. Apply once, after migrations 001..005. |
| 2 | `db\seed\output\load_worked_example.sql` | Loads the ten-member acceptance data into an EMPTY database (not in this folder; listed for order). |
| 3 | `002_worked_example_test.sql` | Calls the engine for 2026-07 and runs THREE verification selects. All three must return ZERO rows. |
| 4 | `003_reset_app_data.sql` | Pre-production only: guarded truncate of all app data tables (ranks kept) so the full 1,000-member seed can load next. |
| 5 | `db\seed\output\load_seed.sql` | The 1,000-member pack. Then call `app.fn_run_commission(period)` per month, inspect, and `app.fn_finalize_run(run_id)` per period. |

Everything runs as the service role or database owner; RLS blocks every other
role from the app tables by design.

## How the engine works (one call = one run)

`app.fn_run_commission(period)`:

1. Inserts the `commission_runs` row: spec_version `'v1.1'`, status
   `'running'`. The status stays `'running'` when the function returns;
   finalization is a separate explicit call.
2. Materializes the run-scoped level map FIRST (the decision doc's rule): a
   recursive CTE walks `members.sponsor_id` upward from every member and
   stores one `(run_id, ancestor_id, descendant_id, level)` row per pair in
   `app.run_level_map`. Every later step reads this snapshot, never the live
   tree.
3. Builds one staging row per member (temp table, computed once so lines and
   results can never diverge): SV (sum of `quantity * unit_volume` over
   completed orders stamped with the period), CV (`round(0.80 * SV, 2)`),
   TV (subtree SV excluding self, all levels, from the snapshot),
   qualification (SV >= 100.00), rank, and paid depth from `app.ranks`.
4. Rank flags evaluate in the spec's declared order: Builder (qualified AND
   >= 2 active legs), Leader (TV >= 2,500 AND >= 3 active legs), Director
   (TV >= 10,000 AND >= 2 legs each containing a builder-flag or leader-flag
   member), Executive (TV >= 40,000 AND >= 2 legs each containing a
   leader-flag or director-flag member). An active leg is a frontline child
   who is qualified. A leg is the frontline child plus that child's whole
   subtree. Final rank is the highest flag held.
5. Inserts `commission_lines` fully set-based: earner qualified, level from
   the snapshot, level <= earner paid depth, rate by level
   (10/5/5/3/2 percent), amount = `round(rate * source CV, 2)` at the line
   level. Source qualification is irrelevant; no compression; lines only
   where source CV > 0.
6. Inserts `run_member_results` (one row per member, including zero-SV
   members) with `total_earned` = sum of that member's rounded lines, and
   writes the run totals (sums of rounded values, never re-rounded;
   `members_paid` = count of members with total_earned > 0).

`app.fn_finalize_run(run_id)`: only a `'running'` run can finalize. It first
flips any prior `'final'` run of the same period to `'superseded'` (so the
one-final-per-period unique index never sees two finals), deletes the level
maps of superseded runs of that period (the decision doc keeps a map only
until its run is superseded), then marks the run `'final'`, at which point
the schema triggers freeze its statement rows.

## Determinism and rounding

- Postgres `round(numeric, 2)` rounds half AWAY FROM ZERO. All rounded
  quantities in this system (SV, CV, rates, amounts) are non-negative, so
  this is identical to round half up, which is what the spec requires.
- Rounding happens exactly twice: CV once per member-month, amount once per
  line. All totals are sums of already-rounded values.
- Both bulk inserts carry ORDER BY (lines by earner, level, source; results
  by member id) so identity ids and row order reproduce exactly.
- All math is `numeric`; no floats anywhere.

## What proves it correct

`002_worked_example_test.sql` runs the engine against the section 7 worked
example and diffs the output against the spec's expected tables, embedded in
the script as VALUES lists (copied verbatim from
`db\seed\output\worked_example_expected_*.csv`):

1. CHECK 1: every `run_member_results` row versus expected (sv, cv,
   qualified, tv, rank, paid depth, total earned), both directions.
2. CHECK 2: every `commission_lines` row versus expected (earner, source,
   level, source_cv, rate, amount), both directions.
3. CHECK 3: company totals versus total_sv 2700.00, total_cv 2160.00,
   total_payout 264.00, members_paid 4.

All three use EXCEPT ALL symmetric diffs, so a missing row, an extra row, an
altered value, or a DUPLICATED row all surface. Success = zero rows from all
three. mlm-verifier then recomputes the run independently.

## Hand-trace of four members through the engine's own logic

Tree: M1 -> M2, M3, M4; M2 -> M5, M6; M3 -> M7, M8; M5 -> M9; M8 -> M10.
Period 2026-07. Member ids equal the M-numbers in the acceptance load.

### M1 (root)

- Step 3 SV: two domain-agent orders, 100.00 + 100.00 = 200.00.
  CV = round(0.80 * 200.00, 2) = 160.00. Qualified: 200 >= 100, yes.
- Snapshot pairs with ancestor M1: level 1 = M2, M3, M4; level 2 = M5, M6
  (via M2), M7, M8 (via M3); level 3 = M9 (M2 -> M5 -> M9), M10
  (M3 -> M8 -> M10).
- TV = 150 + 100 + 100 + 50 + 150 + 1500 + 100 + 300 + 50 = 2500.00.
- Active legs: M2 (SV 150, qualified), M3 (100, qualified), M4 (100,
  qualified) = 3.
- Flags: builder = qualified AND 3 >= 2, TRUE. leader = 2500.00 >= 2500.00
  (boundary, inclusive) AND 3 >= 3, TRUE. director = 2500 >= 10000, false.
  Rank = leader, paid depth 3.
- Lines (level <= 3, all nine descendants have CV > 0):
  level 1: M2 120 -> 12.00, M3 80 -> 8.00, M4 80 -> 8.00;
  level 2: M5 40 -> 2.00, M6 120 -> 6.00, M7 1200 -> 60.00, M8 80 -> 4.00;
  level 3: M9 240 -> 12.00, M10 40 -> 2.00. Total earned = 114.00. MATCHES.

### M2

- SV: 100.00 (Payment Agent) + 50.00 (Software Engineer) = 150.00.
  CV = 120.00. Qualified.
- TV = M5 50 + M6 150 + M9 300 = 500.00.
- Active legs: M5 has SV 50 < 100, NOT qualified; M6 qualified. Count = 1.
- Flags: builder = qualified AND 1 >= 2, FALSE (the teaching case: the M5
  leg's frontline is unqualified). leader = 500 >= 2500, false.
  Rank = member, paid depth 1.
- Lines: level 1 only: M5 CV 40 -> 4.00, M6 CV 120 -> 12.00. M9 sits at
  level 2, out of reach at depth 1 (12.00 of breakage, never written).
  Total earned = 16.00. MATCHES.

### M5

- SV: 50.00 (one Accounting support agent). CV = 40.00.
  Qualified: 50 >= 100, NO.
- TV = M9 300.00. Rank = member (fails Builder on qualification), depth 1.
- Lines: NONE; the earner-qualified filter removes M5 before any line forms.
  The 10 percent of M9's 240.00 CV (24.00) is breakage by design. M5's own
  40.00 CV still pays upline (M2 gets 4.00 at level 1, M1 gets 2.00 at
  level 2): source qualification is irrelevant. Total earned = 0.00. MATCHES.

### M8

- SV: 50.00 + 50.00 (two support agents) = 100.00, the boundary case.
  CV = 80.00. Qualified: 100.00 >= 100.00, yes.
- TV = M10 50.00.
- Active legs: only frontline is M10, SV 50, unqualified. Count = 0.
- Flags: builder = qualified AND 0 >= 2, FALSE. Rank = member, depth 1.
- Lines: level 1: M10 CV 40.00 -> round(0.10 * 40.00, 2) = 4.00 (M10's
  volume pays upline despite M10 being unqualified). Total earned = 4.00.
  MATCHES.

Company cross-foot: SV sum 200 + 150 + 100 + 100 + 50 + 150 + 1500 + 100 +
300 + 50 = 2700.00; CV sum 2160.00; payout 114 + 16 + 130 + 4 = 264.00;
members with earnings > 0 = M1, M2, M3, M8 = 4. All match section 7.4.

## Performance expectations

- Worked example (10 members): instant.
- Full seed (1,000 members, one month): the level map is a few thousand
  narrow rows; every step is a hash join or aggregate over indexed data with
  no per-member loops. Expect well under one second per month, comfortably
  inside the "low seconds" budget; six months = six calls.
- 100,000 members: the level map becomes a few million rows (one per
  ancestor-descendant pair); the recursive walk and the joins remain
  set-based and index-driven. Seconds, not minutes.

## Deviations and decisions the graders should inspect

1. **Level map depth.** The task text and decision doc say "pairs up to
   level 5", but spec section 2 defines TV as the WHOLE subtree, and the
   decision doc requires TV to be computed from the snapshot. A 5-level cap
   would corrupt TV in any tree deeper than 5 (the 1,000-member seed is
   deeper). The map therefore stores pairs to FULL depth; commission pay
   filters to level <= 5 via the rate table. The worked example is
   unaffected (max depth 3).
2. **is_active = qualified (SV >= 100.00).** The schema spec's column note
   "sv >= 50" is stale v1.0 wording; comp plan v1.1 made 100 the single
   gate, and the expected results file (M5 SV 50.00 -> qualified false)
   confirms it. The engine writes the v1.1 gate.
3. **spec_version literal is 'v1.1'.** The schema spec's "'v1.0' for this
   spec" line predates the comp plan revision; the run row records the comp
   plan version actually applied.
4. **Zero-CV sources produce no lines.** A 0.00 line on nothing is
   statement noise. No worked-example impact (every member there has CV
   above zero).

## Open questions (reported, not silently improvised)

1. **Members with status 'closed'.** The engine includes EVERY member row in
   `run_member_results` ("one row per member per run"), regardless of
   account status; a closed member with no orders simply shows zeros. Should
   closed accounts be excluded from runs, or from active-leg counting? v1
   seeds may not exercise this; flagging for the architect.
2. **"Contains a Builder (or higher)" staging.** Implemented exactly as the
   spec's declared non-circular order: Director containment tests
   builder-flag OR leader-flag; Executive containment tests leader-flag OR
   director-flag. Edge case: a member whose FINAL rank is Director but who
   holds neither builder-flag nor leader-flag (possible, since Director has
   no personal-SV or three-leg test) still counts toward an upline's
   Executive via the director-flag; and any leg containing such a Director
   necessarily contains builder-or-leader flagged members deeper down, so
   Director containment has no gap. Believed faithful; worth one verifier
   glance since the spec table's "(or higher)" wording is terser than its
   evaluation-order paragraph.
3. **Migration 006 does not exist on disk.** The Phase 2 punch list (and the
   corrected schema spec) call for hardening the finalized-run immutability
   trigger to also block INSERT before Phase 3; `db\migrations\` still ends
   at 005. The engine only inserts lines into its own 'running' run, so it
   is unaffected, but the hardening should land before any real run is
   finalized. Related observation: the current trigger guards only status
   'final', so a run flipped to 'superseded' becomes mutable again; if
   superseded statements must also stay frozen, that belongs in the same
   hardening migration (architect call).
4. **Level maps of superseded runs are deleted** by `fn_finalize_run`,
   implementing the decision doc's "keeps it until the run is superseded"
   literally. If the verifier instead wants old maps retained for byte-level
   regrades of superseded runs, remove that DELETE; the lines themselves are
   never touched either way.
5. **run_level_map security posture.** RLS enabled, NO policies, no grants:
   invisible to the public interface roles, no demo view reads it. Migration
   003's blanket grant to the demo reader role predates this table; parity
   was intentionally NOT added since no view needs it.

## Post-gate corrections (2026-08-13, after the Phase 3 verifier PASS)

1. The engine stamps spec_version 'v1.2' (comp plan v1.2; math identical to
   v1.1, customer attribution happens upstream). Citations of v1.1 elsewhere in
   this README and in 002_worked_example_test.sql refer to when the rules were
   fixed and are historical, not drift.
2. Open question 3 above is RESOLVED: migrations 006 (immutability hardening,
   extended to superseded runs) and 007 (customers) exist and are deployed to
   the live project along with 001 through 005 and the engine (008).
3. Verifier note accepted as theoretical only: a commission line could round to
   0.00 when rate times CV falls below 0.005, which no v1 catalog price can
   produce.
