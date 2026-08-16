# Plan Five Proof Run: 'orvanna_builder', 2026-08-16

Builder: mlm-comp-engineer. BUILDER EVIDENCE; the verifier, QA, and the
RED-TEAM gate (the spec's named third gate) grade it after. Spec:
`docs\ORVANNA-BUILDER-PLAN-SPEC.md` v1.0, running under the lab contract of
`docs\COMP-LAB-SPEC.md` v1.3.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Structured Query Language (SQL), Message Digest 5 (MD5),
Quality Assurance (QA), JavaScript Object Notation (JSON).

## What was built and applied

Files `db\lab\016` and `017`, applied to the live project as
`comp_lab_p5_016_plan_orvanna_builder` and
`comp_lab_p5_017_watch_snapshots_v2`; proof scripts `115` through `118`.
The plan_code and reason CHECK constraints gained plan five's entries; the
dispatcher gained its branch; `fn_basis_member_codes` learned the
second-leg basis; the snapshot writer learned plan five's shapes AND
widened its decomposition pairing key to (source_code, reason), which plan
five requires (one earner can hold a spine line and an override line on the
same source member) and which is a no-op for every prior plan.

Disclosed incident: the first apply of 016 carried a plpgsql name-capture
defect (the builder-walk loop variable `b` shadowed a CTE alias `b`), which
failed the first fixture run loudly; the variable was renamed `rb` in the
repository file and the corrected function re-applied before any run
completed. No table exists whose freeze regime needed extending: plan five
adds functions and constraint entries only, and every run-scoped row it
writes lands in the already-frozen L1 tables.

## Gate fixture 1, the ten-member worked example (spec section 10): PASS

Every check zero-difference, to the cent:

- LAYER 1 THE SPINE: per-earner totals and line counts exactly the unilevel
  numbers (M1 114.00 over 9 lines, M2 16.00 over 2, M3 130.00 over 3, M8
  4.00 over 1; company 264.00).
- LAYER 2: exactly one line, M1's generation 1 on Builder M3, basis
  1,400.00 at 0.04 = **56.00**, unprorated.
- LAYER 3: M1 basis 520.00 at effective rate **0.0575** (multiplier 1.15 on
  three active legs) = **29.90**; M3 basis 120.00 at 0.05, pieces 4.00 +
  0.40, line FLOORED at **4.40** with prorated = true in its trace.
- Company **354.30 = 16.4028 percent of CV 2,160.00**, four members paid
  (M1 199.90, M2 16.00, M3 134.40, M8 4.00).
- THE M10 CAP-BINDING ROW, the law at its boundary: pool 10.000000, spine
  8.00, layer 2 claim 1.600000 at f2 = 1, layer 3 claim 2.000000 at
  **f3 = 0.200000** paying 0.400000, source total **exactly 10.000000**:
  8.00 + 1.60 + 0.40 = 10.00. Invariant sweep over all ten sources: ZERO
  violations.

## Gate fixture 2, DECAY (spec section 6, Law A): PASS

Scenario 'DECAY' (one set_volume, per-month map {"2026-08": 0.00} on
LAB-C), the same locked scenario serving both months through the L3 replay:

- Month one: A **17.60** (spine 8.00 + generation 1 override 9.60 on B's
  group CV 240.00), B **20.00** (spine 16.00 + bonus 4.00, D's leg second
  on the id tie-break).
- Month two (C lapses, B loses Builder): A **8.00**, the shrinkage
  **exactly the 9.60 override**; B 8.00.
- The attribution the spec promises, delivered by the watched-account
  machinery: A's month-two watch row (baseline = the month-one run) reads
  delta **-9.60 entirely in from_reach_lost**, decomposable true, every
  other bucket zero; B's reads -12.00 = -8.00 reach_lost (C's spine line)
  plus -4.00 aggregate (the bonus). The 017 pairing key is what makes A's
  attribution exact: the spine line and the lapsed override line on the
  same source (B) pair separately by reason.

## Composition with the L3 machinery (S1X, watched): PASS

Plan five over the stacked scenario S1X (add a recruit under M2, move M4
under M3), baseline = the mini identity run under plan five (hand-derived
in file 117's header: base company 38.60, S1X company 58.00):

| Watched | Delta | Decomposition (matched to the cent) |
|---|---|---|
| **LAB-M1** | **+3.40** | +4.00 from_added_members (the recruit's spine line), -4.00 from_level_shift (M4's line moved level 1 to 2), +3.40 aggregate (bonus 4.60 at multiplier 1.15 on the 80.00 second leg becomes 8.00 at multiplier 1.00 on the 160.00 second leg); decomposable false; basis 80.00 to 160.00; basis_members_gained [LAB-M4] |
| LAB-M2 | +8.00 | all in from_added_members, decomposable true |

Scenarios, watched accounts, and the six-bucket-plus-aggregate invariant
all ran unmodified over the new plan: the composition holds.

## Census on seeded March 2026

Order source and snapshot (charter discipline): seeded `app.orders` only
(zero bridged rows in March), the 1,001-member census, frozen by migration
021 and the per-run snapshots.

- LAYER 1 EQUALITY GATE: the census run's spine lines versus the lab
  'unilevel_v13' March run (run 15), both directions on (earner, source,
  level, basis, rate, amount): **ZERO differences** (13,434.00 over the
  same 1,630 lines).
- DRAFT RATES (0.04 / 0.02 / 0.05): company 20,204.71 = **21.9712 percent
  of CV**, an increment of **7.3627 points** over the 14.6085 baseline, far
  outside the section 9 budget of 2.0 to 4.0: the census is much DENSER in
  nested Builders than section 9 guessed (its "sparser in Builders"
  expectation is falsified by measurement). Pool pressure at draft: 333 of
  1,001 sources at f2 < 1, 139 at f3 < 1: Law B working hard, zero
  violations.
- CALIBRATION, the section 9 one-shot rule applied exactly: common factor
  3.0 / 7.3627 = 0.4075; **gen1 0.015, gen2 0.010, second_leg 0.020** (each
  nearest 0.005; all effective bonus rates still fit the 4-decimal rate
  column: 0.020 / 0.023 / 0.025).
- CALIBRATED RESULT: company 17,417.12 = **18.9399 percent of CV**,
  increment **4.3314 points: just ABOVE the window's 4.0 ceiling.** Cause,
  the same non-linearity binary's calibration met: proration is relief
  that shrinks as rates shrink (f2 < 1 sources fall 333 to 120, f3 < 1
  fall 139 to 83; prorated-away amounts 638.00 layer 2 and 305.68 layer 3
  at scale 6), so payout shrinks slower than the rates. A striking
  redistribution the red team should see: the JUNIOR layer's paid total
  ROSE under calibration (bonus 287.78 at draft, 367.49 calibrated)
  because smaller senior claims leave the junior class more room. The
  one-shot rule was applied as written; the residue is RECORDED AND
  DISPLAYED per the standing rule (the phrase "size held equal" appears
  nowhere), and iterate-versus-accept is an architect ruling (flag 1).
- DETERMINISM: the two calibrated census runs share the ordered lines
  digest `43525ec8d9b799c2e310686d0d0a6c70` and every total. Same for the
  fixture reruns by construction (stable ORDER BY discipline throughout).
- CAP RE-CHECK: the per-source cap (Law B) binds through proration factors
  rather than a flat line cap; at draft rates a third of all sources
  prorated; at calibrated rates 120 sources still do. Zero invariant
  violations in every run, asserted in code AND re-swept by query.

## The comparison record: six recipes on seeded March (latest run each)

| Recipe | Payout | Percent of CV | Members paid | Gini | Top-10-percent share |
|---|---|---|---|---|---|
| unilevel_v13 (baseline) | 13,434.00 | **14.6085** | 206 | 0.9625 | 94.25 |
| matrix_3x7 bfs_spill | 15,039.20 | 16.3541 | 237 | 0.9418 | 91.41 |
| binary bfs_spill 0.105 | 15,129.40 | 16.4522 | 166 | 0.9658 | 97.45 |
| binary volume_balanced 0.110 | 16,083.60 | 17.4898 | 145 | 0.9705 | 98.30 |
| **orvanna_builder calibrated** | **17,417.12** | **18.9399** | **207** | **0.9687** | **95.33** |
| stairstep_breakaway | 21,025.60 | 22.8639 | 448 | 0.9330 | 89.12 |

Structure-linked share (spec metric 1) for calibrated plan five: (2,666.75
+ 948.88 + 367.49) / 17,417.12 = **22.9 percent of the check exists only
because of structure.**

## Isolation, the fresh jointly-attributed baseline

Per both gates' request, the NEW app-schema baseline of record, attributed
jointly with the subscriptions build (its vocabulary landed as migrations
024 through 027): **134 relations, 25 non-internal triggers, 54 functions,
283 grants, 10 policies**, measured before and after the plan five apply
and runs, UNCHANGED by them. Lab hygiene re-proven: lab functions writing
to app 0; lab grants to anon, authenticated, app_demo_reader 0; the single
sanctioned lab-to-app foreign key only.

## Housekeeping delivered (QA L3 MEDIUM-1)

The lab README's stale L1-placeholder gotcha ("scenario mutations are phase
L3... fails loudly") and its half-stale fixture neighbor ("derived sets
inserted, not replayed") are rewritten to the L3-and-after truth: mutations
replay, fixtures hand-load only the BASE and exercise the real replay.

## Flags for the architect

1. **Calibration residue 0.33 above the window.** The one-shot section 9
   rule lands at 4.3314 against a 2.0-to-4.0 budget because proration
   relief is non-linear. Options: accept and display (the binary
   precedent), or amend section 9 to iterate to convergence, or shave one
   rate half-step (gen1 0.010 would land low in the window; a mixed shave
   needs a rule). Architect's call; nothing in Law B is affected either
   way.
2. **Section 9's density expectation is falsified**: the seeded census is
   denser in nested Builders than the ten-member fixture, not sparser
   (increment 7.36 versus the fixture's 4.2 at draft rates). The spec
   sentence should be corrected by amendment so the hostile reader does
   not catch it.
3. **members_paid 207 versus the baseline's 206**: exactly one census
   member earns under plan five who earns nothing under unilevel (an
   override or bonus with no spine line). Named here so the verifier
   confirms it is structural, not a defect.

## What the gates and the RED TEAM should attack hardest

- THE WATERFALL'S TRUNCATION ARITHMETIC: hand-recompute the M10 row at
  scale 6, then construct a hostile source where f2 lands on a repeating
  decimal (claims not multiples of 50) and verify paid never exceeds pool
  in exact arithmetic AND rounded money; the floor-on-prorated rule is the
  subtle half of Law B.
- SPEC 12A(a)'s worst case, live: build a fixture with a full spine (five
  qualified ancestors) over a deeply nested Builder stack and verify f2 =
  0 writes ZERO override lines (the zero-line skip) while the traces still
  show the claims.
- THE OVERRIDE WALK with an UNQUALIFIED intermediate (impossible for
  Builders under v1.3, but a qualified NON-Builder between two Builders is
  the evaluate-then-count edge; the DECAY fixture exercises only the
  simple case).
- THE JUNIOR-LAYER GROWTH UNDER CALIBRATION (287.78 to 367.49): verify it
  is pure waterfall arithmetic and quantify how it moves the layer mix the
  dashboard will present.
- THE RED TEAM specifically: the section 11 anti-gaming numbers replayed
  against the engine (fund-a-Builder loses 274.40 a month; leg-splitting
  dilution monotone), the pool-pressure distribution as the 12A(e)
  presentation number (12 percent of sources prorate at calibrated rates:
  is "rare and junior" still the honest phrase?), and the behavioral
  caveat of section 12 carried on every readout.

Every proof above: PASS (with the name-capture incident and the
calibration residue disclosed). Plan five is NOT presentable until the
verifier, QA, and the red team all pass it (spec section 13).
