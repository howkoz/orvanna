# Comp Plan Lab, Phase L3 Proof Run, 2026-08-16

Builder: mlm-comp-engineer. BUILDER EVIDENCE; mlm-verifier and the Quality
Assurance (QA) gate grade it after (builder self-report closes nothing).
Spec: `docs\COMP-LAB-SPEC.md` version 1.3, sections 9 (scenarios) and 10
(watched accounts), with the section 8 rulings (question 7 stack depth 3,
question 8 watchlist soft cap 10, question 9 month-scoped removal,
question 10 volume profiles in multiples of 50.00, question 11 the named
baseline).

Session note, recorded honestly: this build was interrupted once by an
account spend-limit outage after migrations 014 and 015 were applied; on
restore, state was re-established from the cloud ledger and the working
files, and no applied step was redone.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Group Volume (GV), Structured Query Language
(SQL), Message Digest 5 (MD5), Quality Assurance (QA), JavaScript Object
Notation (JSON).

## What was built and applied

Files `db\lab\014` and `015`, applied verbatim to the live project as
migrations `comp_lab_l3_014_scenario_replay` (ledger 20260816162729) and
`comp_lab_l3_015_watch_snapshots` (ledger 20260816162840); proof scripts
`111` through `114`. All prior applied files stayed frozen.

- 014, the mutation machinery: `lab.fn_effective_mutations` (parent chain
  flattened root-first, seq order), `lab.fn_replay_mutations` (all five
  kinds: add_member with the spec 9.4 identity rule, remove_member with the
  ratified roll-up, remove_leg, move_member with cycle refusal, set_volume),
  `lab.fn_profile_sv` (profiles in multiples of 50.00, per-month maps),
  month scoping on every mutation, `fn_derive_members` v2 (census snapshot
  then replay; the IDENTITY scenario's empty list is a no-op by
  construction), `fn_snapshot_volumes` v2 (one volume path:
  coalesce(sv_override, census orders)), and lock-time validation (shape,
  profile grain, stack depth cap 3).
- 015, watched accounts: `lab.watch_snapshots` (run-scoped, freeze-covered,
  RLS on, zero grants), the soft-cap warning trigger,
  `lab.fn_write_watch_snapshots` (per-run snapshots with the six-bucket
  decomposition and aggregate basis movements, invariant enforced in code),
  `fn_execute_plan` v4 (snapshots written while running), `fn_run_plan` v2
  (sixth defaulted parameter p_baseline_run_id, question 11's named
  baseline; the five-parameter signature of record still works; old
  signature dropped so calls are never ambiguous), and the fixture support
  functions (`fn_load_mini_base`, `fn_run_mini_fixture`) that run the
  section 6 mini tree through the SAME replay-snapshot-execute path as
  census runs.

DESIGN DECISIONS the gates should know (full rationale in the file
headers): the replay operates on the RUN'S base member set (census for
census runs, the hand-loaded mini base for the spec's hand examples), so S1
and S2 exercise the real machinery over the exact tree the spec computed
them on; fixture base ids are 1..5 so the normative synthetic id rule
(10,000,000 + ordinal over the FULL effective list, month-scoped or not)
can never collide; add_member ordinals are consumed even by month-scoped
mutations so a synthetic member keeps one id across a window; delta
decomposition joins runs by member CODE (stable across id conventions);
lock-time validation is SHAPE-only with existence and cycle checks at
replay, because fixture scenarios reference base members that exist only
inside a run (flag 1 below).

## Hand example S1 (spec 9.5, add a 100-volume recruit under M2): PASS

Scenario S1 = one add_member mutation, replayed by the real machinery.

- The synthetic member is EXACTLY the spec 9.4 identity: code LAB-S1-1, id
  10,000,001, sponsor LAB-M2, SV 100.00 from the profile. Zero differences.
- Unilevel after: all SEVEN lines exact (the two new lines are M2 on
  LAB-S1-1 at level 1 = 8.00 and M1 on LAB-S1-1 at level 2 = 4.00), company
  **46.00** on SV 700.00 / CV 560.00, two paid. Watched deltas: M1 **+4.00**
  and M2 **+8.00**, both entirely in from_added_members, decomposable true.
- Binary A (draft 0.20, per the v1.2 fixture ruling) after: LAB-S1-1
  SPILLED to M4.left exactly as 9.5 derives; company **24.00** unchanged;
  watched deltas both **0.00** with decomposable false and bases unchanged
  (M1 80.00 to 80.00, M2 40.00 to 40.00); flushed unmatched CV rose
  **200.00 to 360.00** (value at the rate 40.00 to 72.00). One check-side
  correction found and recorded: the spec's flushed total counts members
  WITH a pay line (M4's one-legged 80.00 is no-pay, not flush); the proof
  first summed the per-member metric over everyone (440.00), and the check
  was fixed to the line-scoped sum, the same lines-not-flags lesson as QA
  LOW-2. The engine code needed no change.

## Hand example S2 (spec 10.3, move M4 under M3): PASS

- Unilevel: M1 26.00, M2 4.00, M3 8.00, company **38.00**, three paid.
- Binary A: M1's legs TIE at 160.00 each, ties pay the LEFT leg, M1 alone
  earns **32.00**.
- THE WATCHED SNAPSHOT TABLE, all four rows exact against spec 10.3:

| Watched | Plan | Delta | Components (actual, matched to the cent) |
|---|---|---|---|
| M1 | unilevel | -4.00 | decomposable true; from_level_shift -4.00 (M4's line moved level 1 to 2, 8.00 to 4.00); every other bucket 0.00 |
| M1 | binary A | +16.00 | decomposable false; basis 80.00 to 160.00; basis_members_gained [LAB-M2, LAB-M5]; basis_members_lost [LAB-M3] |
| M2 | unilevel | 0.00 | all components 0.00 |
| M2 | binary A | -8.00 | decomposable false; basis 40.00 to 0.00; basis_members_lost [LAB-M5] (the move took the spillover away) |

## The stacked scenario S1X (S2's move on S1's add, parent chain depth 2): PASS

Hand derivation in `db\lab\113`'s header; the lab matched it exactly:

- Unilevel company **50.00** (M1 30.00, M2 12.00, M3 8.00) on SV 700.00.
  The stacked watch row is the product's teaching moment in one line:
  **M1's delta is 0.00, composed of +4.00 from_added_members and -4.00
  from_level_shift**, the two stacked mutations telling themselves apart
  inside one exact decomposition. M2 +8.00 (added).
- Binary A company **40.00** (M1 32.00 on tied legs, M2 8.00).

## Month-scoped removal (S-REM, remove LAB-M4 month_from August): PASS

Same scenario, two runs: July has all five members and the identity numbers
(SV 600.00, payout 34.00); August has four members, M4 gone with its
frontline roll-up trivially empty, SV 500.00, payout **26.00** (M1 22.00,
M2 4.00). One mechanism, both behaviors, exactly the question 9 ruling.

## Refusal probes: PASS

- Depth: a depth-3 stack locks; a depth-4 lock is REFUSED (cap 3).
- Replay: a scenario removing the root fails the run LOUDLY and the whole
  run rolls back (its id is burned, no half-applied rows exist).
- Lock-time: shape validation and the 50.00 profile grain enforce at lock;
  scenario mutations are insertable only while draft (L1 trigger).

## The five-recipe sweep (S1, S2, S1X across all five current recipes)

Binary at the RULED rates (0.105 A / 0.110 B) for comparison runs, per the
v1.2 ruling; matrix A; stairstep; unilevel. Recorded payouts (mini base,
period 2026-07; baselines are plan-matched mini identity runs, named per
question 11):

| Recipe | Identity base | S1 (add recruit) | S2 (move M4) | S1X (stack) |
|---|---|---|---|---|
| unilevel_v13 | 34.00 | 46.00 | 38.00 | 50.00 |
| binary bfs_spill 0.105 | 12.60 | 12.60 | 16.80 | 21.00 |
| binary volume_balanced 0.110 | 17.60 | 22.00 | 17.60 | 22.00 |
| matrix_3x7 A | 18.00 | 26.00 | 22.00 | 30.00 |
| stairstep_breakaway | 22.00 | 26.00 | 22.00 | 26.00 |

Shape stories already visible at five members: the recruit that pays
unilevel +12.00 pays ruled-rate binary A exactly nothing; S2's move that
doubles binary A leaves stairstep at 22.00 to the cent (uniform bottom
bracket collapses every differential to 5 percent of own CV, tree shape
irrelevant); the stack is additive for matrix (+12.00) and a wash for
stairstep. Every run row carries its disclaimer, placement runs their
caption, stairstep runs their monotonicity note.

## Determinism: PASS, two assertions

- SW1a, SEMANTIC (code-keyed): over EVERY pair of completed runs sharing
  (scenario, plan, parameters, strategy, period), digests keyed on member
  codes and effective volumes for members, lines, and results, plus all
  four totals: **ZERO disagreements**, across 66 completed runs. This
  includes the cross-convention pairs: the L3 REPLAY of identity-on-mini
  reproduces the frozen L1/L2 HAND-INSERTED fixture runs code for code and
  cent for cent (found because the first id-keyed draft of this assertion
  flagged exactly those pairs on internal ids while every value agreed;
  the id conventions differ by construction and the file records the
  incident).
- SW1b, BYTE-ORDER (id-keyed, insertion order, watch snapshots included
  with their full component JSON): over the three deliberate same-flow
  duplicate pairs (S1 unilevel, S2 binary A ruled, S1X stairstep): **ZERO
  disagreements**.
- Order source and period snapshot (charter discipline): every L3 proof run
  is a hand fixture (order_source 'hand_fixture', volumes from the loaded
  base and replayed profiles, period 2026-07 or 2026-08 as tagged); no
  census month participated in L3 proofs, and the census path itself is
  unchanged for the IDENTITY scenario by construction (empty replay).

## The component invariant (spec 10.2): PASS

Enforced in code (a run ABORTS if any watched account's buckets plus
aggregate delta miss the delta) and re-verified over the whole table: 64
watch snapshots, **ZERO violations** of bucket-sum-equals-delta among rows
with a resolvable baseline; rows without one carry {"no_baseline": true}
and null deltas.

## Isolation, re-verified, with an attribution note

The app-schema inventory is NO LONGER the L1 baseline (now 131 relations,
25 triggers, 28 functions, 262 grants versus 88/14/17/185), and the delta
is NOT the lab's: the migration ledger shows the subscriptions build landed
`subscription_engine_schema_024`, `subscription_classification_data_025`,
`subscription_engine_core_026`, and `bridge_covered_months_027` around and
after the lab's 014/015 during the same day (another agent's sanctioned
work, per the coordinator). The lab's own contribution to schema app is
proven zero three ways, independent of any baseline:

1. The applied lab migration bodies (repository files 001..015, applied
   verbatim) contain no `app.*` DDL or DML;
2. the pg_proc grep over every function in schema lab for INSERT, UPDATE,
   DELETE, or TRUNCATE against `app.*`: **ZERO rows**;
3. cross-schema constraints: still exactly ONE lab-to-app foreign key (the
   spec-sanctioned `derived_members_app_member_id_fkey`) and ZERO
   app-to-lab; lab grants to anon, authenticated, app_demo_reader: ZERO;
   app RLS policies unchanged at 10.

Recommendation to the gates: re-baseline the app inventory jointly with the
subscriptions builder before L4, so the next zero-new-objects claim has one
number both builds sign.

## Interpretation flags for the architect

1. **Lock-time validation is shape-only** (kind fields, profile grain,
   depth cap); existence and cycle checks run at replay and fail loudly.
   Spec 9.2's "validation at lock" implicitly assumed census-based
   scenarios; fixture scenarios reference LAB- base members that exist only
   inside a run, so lock-time existence checking is impossible in general.
   Suggest a v1.4 sentence scoping the lock-time check.
2. **fn_run_plan gained a sixth defaulted parameter** (p_baseline_run_id),
   the question 11 named baseline made callable; needs the same signature
   ratification the fifth received.
3. **Flushed-CV aggregation semantics** (from the S1 proof): the spec's
   flushed totals count members with a pay line; a one-legged member's
   strong leg is no-pay, not flush. Worth one clarifying sentence in
   section 5's breakage row (it already gestures at this by reporting flush
   separately); the dashboard rule from QA LOW-2 (compute from lines, never
   flags) covers it operationally.
4. **Stairstep snapshots are the mixed case**: per-source override buckets
   AND an aggregate differential movement in one delta_components object,
   decomposable false, invariant spanning both. This is the honest reading
   of 10.2's plan classification; the verifier should confirm.

## What the gates should probe hardest

- Independent hand replay of S1, S2, and the stack per the L3 gate,
  especially the S1X watch row (delta 0.00 = +4.00 added - 4.00 shifted)
  and the S2 binary basis movements.
- The bucket definitions' edge semantics: a source present in both trees
  with lines in both runs at DIFFERENT levels lands in from_level_shift as
  (now minus before); confirm against 10.2's table.
- The ordinal rule under month scoping (a scoped-out add_member still
  consumes its ordinal): construct a two-add scenario with the first add
  scoped out and verify the second still gets 10,000,002.
- The remove_member roll-up on a target whose frontline is non-empty (the
  S-REM probe removed a leaf; the machinery's set-based re-pointing is
  argued equivalent to the ascending walk in 014's header, decision 5).
- The isolation attribution above: verify the app delta belongs entirely to
  migrations 024 through 027.

Every L3 proof above: PASS (with the flushed-CV check correction and the
digest-convention incident disclosed). Phase L3 remains OPEN until
mlm-verifier and QA say so.
