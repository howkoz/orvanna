# Comp Plan Lab, Phase L2 Verdict, 2026-08-16

Grader: mlm-verifier, independent of the builders by charter. Scope: commit
`a26ca0d` (12 files: `db\lab\008..013`, `db\lab\107..110`, `db\lab\README.md`,
the builder proof document `docs\verification\LAB-L2-PROOF-RUN-2026-08-16.md`).
Spec of record: `docs\COMP-LAB-SPEC.md` version 1.2 at build time; version
1.3 (commit `df53e81`) landed mid-gates and section 5 of this verdict grades
the interpreted prose against v1.3's now-normative wording, per the
coordinator. Live project:
`oiyibdczkokegaxkwulv`, probed 2026-08-16 with read-only queries against
schema `app` and lab-only writes (freeze probes and five determinism reruns,
permitted).

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Group Volume (GV), Structured Query Language (SQL), Message
Digest 5 (MD5), Secure Hash Algorithm 256 (SHA-256), Quality Assurance (QA),
Breadth-First Search (BFS).

---

## GATE: PASS

Every L2 acceptance clause passed under independent recomputation, and both
census-scale plans were re-derived from raw volumes with my own code, not
only spot-checked. Zero HIGH findings. Zero open MEDIUM findings: the three
architect items this gate confirmed numbers for (calibration residue ruling,
the two wording amendments, the hand-example appendix) all landed in spec
v1.3 mid-gates, matching what this verdict independently verified. Three
LOW notes, one of which is the adjudicated one-digit correction (24.4408,
section 5c) owed by the builder proof doc and spec v1.3 section 6.6. Phase
L2 still requires the QA gate to close.

---

## 1. PROOF-STAIR, hand-rederived: EXACT

I derived the seven-member chain on paper from spec section 4.4 alone before
reading any lab output. My numbers, all confirmed against the live run:

- **Bottom-up GV with exclusion**, leaves first: S6 GV 15,000.00 BREAKAWAY
  (inclusive threshold), bracket 20. S5 GV 5,000.00 (S6's group left),
  bracket 15. S4 GV 10,000 + 5,000 = 15,000.00 BREAKAWAY, bracket 20:
  **S4 breaks away only BECAUSE S5's group stayed** (had S6 not broken away,
  S5 would carry GV 20,000 and break away itself, leaving S4 at GV 10,000,
  bracket 15: the fixture's order-dependence is real and my derivation
  reproduces it). S3 GV 500.00 (S4's group left), bracket 5. S7 GV 50.00,
  unqualified. S2 GV 650.00. S1 GV 850.00. Breakaways exactly S4 and S6.
- **Differentials**: S6 = 0.20 x 12,000 = 2,400.00; S5 = 0.15 x 4,000 =
  600.00; S4 = 0.20 x 12,000 minus 0.15 x 4,000 = 1,800.00; S3 = 0.05 x 400
  = 20.00; S2 = 0.05 x 520 minus (20.00 + 2.00) = 4.00; S1 = 0.05 x 680
  minus 26.00 = 8.00; S7 unqualified, its 2.00 is breakage and is the
  minimum differential (the run note's 2.0000).
- **Overrides**: S6's group CV 12,000.00: generation 1 to S5 (first
  qualified, zero boundaries) 480.00; walk passes breakaway S4 (boundary
  counted after S4's own candidacy), generation 2 to S3 240.00. S4's group
  CV 12,000.00: generation 1 to S3 480.00; no boundary above S4, so NO
  generation 2. **S3 earns both a generation 1 (on S4's group) and a
  generation 2 (on S6's group), 740.00 total with its differential.**
- **Company 6,032.00** on CV 24,680.00, six paid, under the 26 percent
  stacked-breakaway ceiling. The percent of CV is ADJUDICATED in section 5c
  below: 24.4408, not the 24.4409 the proof doc prints.

Live run rows match every cell: all nine lines (six differentials, two
generation 1, one generation 2), every GV, group CV, bracket label, and
breakaway flag, totals 30,850.00 / 24,680.00 / 6,032.00 / 6.

## 2. Matrix ten-member, hand-rederived: EXACT, and the level-7 boundary is real

By hand at width 3 both strategies place the ten members exactly on the
sponsor tree (no member has more than three frontline members; strategy B's
weigh-in always finds an empty leg at the sponsor). Lines at 5/5/4: M1 level
1 = 14.00, level 2 = 72.00, level 3 = 9.60 + 1.60 = 11.20, total 97.20; M2 =
20.00; M3 = 66.00; M8 = 2.00; M5 unqualified (12.00 claim on M9 is
breakage). **Company 185.20** = 8.5741 percent of CV 2,160.00, four paid.
Live fixture runs match, both strategies, and the mini matrix (18.00) and
mini stairstep (22.00) match my derivations too.

The fixture is too shallow for the depth boundary, so I probed it at census
scale: I recomputed ALL of census matrix run 31's lines independently (my
own recursive placement-distance walk over its placement map, own CV, own
rates): **2,963 lines, zero differences both directions, total 15,039.20.**
The placement tree reaches distance 15; 238 qualified (earner, source) pairs
exist at level 8 with non-zero CV and are paid NOTHING; 338 lines exist at
level 7; zero lines beyond level 7. The paid-depth boundary sits exactly at
7.

Binary width-2 equivalence through the new placement code confirmed live:
24.00 / 184.00 / 168.00 on the equivalence reruns, the L1 numbers unchanged.

## 3. The calibration residue: ARITHMETIC CONFIRMED TO THE CENT

All figures below recomputed from live line data, not copied:

| Claim | My live recomputation | Verdict |
|---|---|---|
| Run 28 (0.105 A) uncapped total = 15,129.40 + 1,347.20 = 16,476.60 | uncapped sum 16,476.60; capped lines 1; capped remainder 1,347.20 | CONFIRMED |
| Uncapped run 28 = 0.525 x uncapped run 12/13/16 (31,384.00), exactly | ratio computes to 0.525000 exactly (and 0.525 = 0.105 / 0.20) | CONFIRMED: the linearity is to the cent |
| Same on strategy B (bonus) | run 29 uncapped 17,107.20 = 0.550000 exactly x run 14's 31,104.00 | CONFIRMED |
| The whale leg | max pay-leg CV 36,640.00; 0.105 x 36,640.00 = 3,847.20, capped to 2,500.00, remainder 1,347.20 | CONFIRMED |
| The 0.090 estimate's method | total pay-leg CV (A) = 156,920.00; minus the whale = 120,280.00; in the one-whale-cap regime payout(r) = 120,280 x r + 2,500 (valid: the whale caps for every r >= 0.0683 and run 28 shows exactly one capped line at 0.105); solving for the 13,434.00 target gives r = 10,934 / 120,280 = 0.0909, nearest 0.005 = **0.090** | METHOD SOUND |
| What 0.090 actually lands (my addition) | exact line-rounded payout at 0.090 over run 16's bases = **13,325.20**, residue -108.80 against the 13,434.00 target = 0.118 points of CV, versus +1.84 points at the ruled 0.105 | Quantified for the architect |

So the finding stands as stated: the ruled rates (0.105 / 0.110) leave
16.4522 / 17.4898 percent of CV against the baseline's 14.6085 because the
rule divided CAPPED percentages and then scaled linearly while the cap is
not linear. The numbers the architect's iterate-versus-accept ruling rests
on are correct. The ruling itself is the architect's and is requested in
parallel; nothing in it blocks this build gate.

## 4. The freeze: MY OWN TAMPER BATTERY, ALL CORRECT

I built my own probe runs (35 completed, 36 left running with a hand line)
and attacked:

| Probe | Result |
|---|---|
| T1 update a completed run's totals | REFUSED |
| T2 update a completed run's result row | REFUSED |
| T3 insert a line into a completed run | REFUSED |
| T4 delete a completed run's line | REFUSED |
| T5 cross-side: re-point a RUNNING run's line INTO the completed run | REFUSED (destination side guarded) |
| T6 cross-side: re-point the completed run's line OUT to the running run | REFUSED (source side guarded) |
| T7 update a completed run's derived-member row | REFUSED |
| T8 archive the completed run, status only | ALLOWED, the one permitted transition |
| T9 update the archived run's notes | REFUSED |
| Insert a line into a RUNNING run | ALLOWED (correct: the engine writes while running) |

T8 succeeding proves the 013 fix live (under 008's generated-column defect
the legal archive was refused). The deployed `enforce_run_freeze` body
carries the 013 exclusions (verified in pg_proc), and the deployed
dispatcher is the 012 four-plan version. **008 versus 013: over-strict,
never leaky, CONFIRMED** by construction: the 008 equality test could only
fail MORE often than intended (NEW's generated columns serialize as null in
a BEFORE UPDATE trigger, breaking equality), so it refused the legal
transition while still refusing every illegal one; 013 only removes from
the comparison two columns an updater cannot write at all. Git and the
migration ledger confirm 008 was never edited: 013 is a separate later
migration (`comp_lab_l2_013_run_freeze_fix`, 15:51:18) and the run ledger's
missing ids are exactly 1, 10, 17, matching the three disclosed burns.

## 5. The interpreted-prose rulings, graded against spec v1.3

Spec v1.3 (commit `df53e81`) landed between the L2 build and this verdict,
turning both interpreted areas into exact normative text (section 4.4
"Model one" and "Model two") and ruling the calibration residue
(accept-and-display, rates standing). Rulings 5a and 5b below were derived
against the v1.2 prose and then checked against v1.3's wording: **the v1.3
text matches the build's implemented behavior exactly in both areas, so the
amendments are words-only as this gate requires, and they have already
landed. No behavior change is needed anywhere.** V1.3's stated assumption
("the build's interpretations are assumed to hold unless the verifier's
verdict says otherwise") is hereby CONFIRMED, not contradicted. The v1.3
Model-two requirement that every differential be rebuildable from
plan_metrics alone is satisfied by demonstration: section 5a's full census
rebuild used exactly those fields.

### 5a. The override walk: FAITHFUL; the amendment needed WORDS ONLY, and v1.3 supplies them.

The build's model (walk upward with boundary counter k; first qualified at
k = 0 takes generation 1; first qualified at k = 1 takes generation 2; a
breakaway ancestor is a candidate BEFORE it increments k; stop after
generation 2) is the only reading that keeps both spec sentences true at
once: counting the boundary before candidacy would strand the 4 percent when
the first qualified upline member is itself a breakaway (contradicting
"paid to the first QUALIFIED member found walking the sponsor chain
upward"), and the model makes a generation 2 payment exist exactly when "a
breakaway is found under a breakaway", the spec's own parenthetical. V1.3's
boundary-counter wording states this model verbatim, boundary counted as
the walk PASSES a breakaway (after its own candidacy), unqualified members
passed over without incrementing. Proof by independence: I implemented MY OWN code for this reading and recomputed
the ENTIRE stairstep census run 34 from raw volumes (own depth walk, own
bottom-up GV, own override walk): **451 lines, zero differences both
directions, total 21,025.60, breakaway flags and every GV / group CV /
bracket metric identical across all 1,001 members.** The census even
exercises the subtle case the fixture cannot: one census generation 1
override is earned by a member who is itself a breakaway, and my
independent walk paid the same line. The architect's amendment should state
the walk model in the spec; **no behavior change is needed.**

### 5b. The differential columns: THE RIGHT CHOICE; WORDS ONLY.

For `stairstep_differential`, `amount = round(rate x basis, 2)` is
arithmetically unsatisfiable whenever a child's bracket differs from the
earner's (S4: rate 0.20, basis 12,000.00, amount 1,800.00, not 2,400.00).
The build keeps section 1.2's own basis definition ("the amount the rate
was applied to... group CV differential basis"): rate = the earner's bracket
rate, basis = own CV plus non-breakaway group CV, amount = the differential
rounded once, full decomposition in plan_metrics. Every dollar remains
recomputable from raw data, which section 1 exists to guarantee, and I did
recompute every one. The spec's "basis = the signed net basis" phrase was the
defective wording; v1.3 supersedes it exactly as this gate requires: the
section 1.2 invariant now carries the scoped exception and section 4.4
Model two defines the three columns in the build's exact semantics.
**No behavior change is needed.**

### 5c. ADJUDICATION: the PROOF-STAIR percent of CV is 24.4408, not 24.4409. QA is right; the builder proof doc and spec v1.3 correct.

Requested by the coordinator: the builder's proof doc (line 100) and the
architect's v1.3 section 6.6 (line 665) print 24.4409; the L2 QA gate
computed 24.4408 (its LOW-1). The division, stated explicitly: numerator =
total_payout 6,032.00 (the sum of the nine already-rounded lines);
denominator = total_cv 24,680.00 (the sum of per-member CV = round half up
(0.80 x SV, 2), the CV base the spec's section 5 metric names); percent =
100 x 6,032.00 / 24,680.00 = **24.44084278...** exactly (continuing
24.4408427876823...). At four decimals the fifth decimal digit is 4, so
EVERY standard rounding rule (half up, half even, truncation) yields
**24.4408**; printing 24.4409 would require the true value to reach at
least 24.44085, and it does not. **RULING: QA's 24.4408 is correct. The
24.4409 in the builder proof doc and in spec v1.3 section 6.6 is a
one-digit error, and the loser corrects: both documents.** Note for the
correction: the spec's own section 5 metric definition prescribes two
decimals, under which both documents would simply print 24.44; wherever
four decimals are kept, the digit is 8. The money itself, 6,032.00 on
24,680.00, is agreed by all parties and confirmed by my hand derivation in
section 1.

## 6. Determinism, fresh runs, and isolation

I created five fresh census runs myself (37 binary A at 0.105, 38 binary B
at 0.110, 39 matrix A, 40 matrix B, 41 stairstep) and compared full ordered
digests against the builder's runs 28, 29, 31, 32, 34: **lines, results,
placement digests, and totals all identical on all five pairs** (verifier
digests recorded in the session; e.g. binary A lines
`b7d37a99b261e6c9947f02b392438f54`, stairstep lines
`319c6129cb77b0a55333d19d992e9f46`). Payouts reconfirmed: 15,129.40 / 166;
16,083.60 / 145; 15,039.20 / 237; 13,904.00 / 240; 21,025.60 / 448.

Isolation, re-run after everything above: schema app inventory
**88 / 14 / 17 / 185 / 10**, exactly the recorded baseline; zero lab grants
and zero schema usage for anon, authenticated, app_demo_reader; zero lab
functions writing to schema app. Reason-code coverage on the census
confirmed in my recomputations: 448 differentials, 2 generation 1, 1
generation 2, and 5,750 matrix lines across runs 31 and 32 (2,963 of them
on run 31, matched line for line).

## 7. Guardrail sweep: CLEAN

Across all 12 files: zero em or en dashes (byte-level scan), zero employer
terminology or data, acronym keys present in every prose-bearing file,
generic industry language throughout.

---

## Findings

**HIGH: none.**

**MEDIUM: none open.** The three architect items this gate confirmed the
numbers for all LANDED in spec v1.3 (commit `df53e81`) while the gate was
running, and v1.3's content matches what this verdict independently
verified:

1. **The calibration residue: RULED accept-and-display, rates standing.**
   The arithmetic the ruling rests on is confirmed to the cent in section 3
   (linearity ratios exactly 0.525 and 0.550; the 0.090 cap-aware estimate's
   method sound, landing 13,325.20, within 0.118 points of CV on March).
   V1.3's reasoning for rejecting iteration (rate-dependent cap set,
   single-month anchor) is consistent with those numbers. NOTE FOR L4: the
   ruling creates a binding dashboard display obligation (actual percent
   beside baseline, no "size held equal", caption "size approximately held;
   residue shown"); the L4 gate must check it.
2. **The two wording amendments (section 5): landed in v1.3 as Models one
   and two, matching the build's behavior exactly.** Words only, as ruled;
   nothing to rebuild.
3. **The matrix and stairstep hand examples: landed as v1.3 sections 6.5
   and 6.6**, matching my independent derivations, except the one digit
   adjudicated in 5c (LOW 1 below).

**LOW:**

1. **The 24.4409 digit (adjudicated in 5c): correction owed** in BOTH the
   builder proof doc (`LAB-L2-PROOF-RUN-2026-08-16.md` line 100) and spec
   v1.3 section 6.6 (line 665). The correct four-decimal figure is 24.4408
   (or 24.44 at the spec's own two-decimal metric definition). One digit,
   money agreed; LOW, but it sits in normative spec text, so it should be
   fixed with the next spec touch.
2. **Proof script 110 C6 counts capped lines by `amount = 2500.00`**, which
   would also count an uncapped line that happens to land exactly on the cap.
   My recount used the plan_metrics capped flag and agreed on this data;
   cosmetic, worth tightening if 110 is rerun at other rates.
3. **The L1 LOW on default PUBLIC execute for trigger functions** presumably
   extends to the two new `enforce_run_*` trigger functions; harmless for the
   same schema-usage reason (not re-inspected this round; carried forward).

## Not probed (stated per charter)

- The QA gate's territory (no member-visible surface changed; zero new
  grants confirmed).
- August 2026 bridged volume (excluded by the builder too; not final).
- Census-scale PLACEMENT derivation was not independently re-walked for
  either strategy (the sequential width-N walk); fixture-scale placements
  are hand-verified, census placement digests are stable across independent
  reruns, and all downstream money was independently recomputed from the
  stored placement maps.
- The historical 008 refusal of F4 (the incident itself) is accepted from
  the builder's disclosure plus structural argument and the burned run id
  17; I did not re-create a pre-013 database to reproduce it.
- Applied migration bodies were not byte-compared against repository files
  (names-only ledger); deployed function bodies were checked for the 013
  exclusions and the 012 dispatch instead.
- The ACLs of the two new trigger functions (LOW note 2).

## Hashes of the graded artifacts (SHA-256, commit `a26ca0d`)

```
ec393d1dc08d47ee6d562b4fcc838c97cbc53fe57f6af5e79c13cd0a1ee00db4  db/lab/008_lab_run_freeze.sql
07bc072cf948668b31d958a895dc09e757e8854d11d6e26c3afb138bf01b8f04  db/lab/009_lab_placement_width.sql
4b226f3be80fb6486a55afc05dbf9ed96dc7dacc659c9e37f414db938edf8002  db/lab/010_lab_plan_matrix.sql
735d175de70092a12cccf85c0381fbe2eab4046db7f89dfaf6cb9402a5915bb6  db/lab/011_lab_plan_stairstep.sql
bc10835c8c4d8afd2b9fafeaf2e6c7333315dfa14043f7b8713c9c9d8d7170bc  db/lab/012_lab_execute_plan_l2.sql
7e47b00b18e241848deeb8f0405c6e3554d0abf5d8c427d70023670cff1b8e1f  db/lab/013_lab_run_freeze_fix.sql
f03b6ae19049f1b4a7f6093e872e71e37c1b02c497e788b245766a8313025951  db/lab/107_proof_freeze.sql
01f75fe2f9ca5aa113b8882455722a1885948ad12533c53925618939fdcc6c79  db/lab/108_proof_matrix_fixtures.sql
3ad8a8c6fc52161b7acb58fd10ada8732413c35c9c3aa37aae73108d5702a3a4  db/lab/109_proof_stairstep_fixtures.sql
de6e14f531b5891a9208c774fb972a5ff2e6ee1e30371c51500e541242a92f23  db/lab/110_census_l2_runs.sql
145c3cbd9707ebb1240ec9e151321d8f1559441bf14bb69d8918aa4438b1025b  db/lab/README.md
9c1cc2f89c4356ad35407de12abc1239c93156729c7414c322411d9e8363afff  docs/verification/LAB-L2-PROOF-RUN-2026-08-16.md
```

Side effects of this verification, recorded: lab runs 35 and 36 (freeze
probes, both archived) and 37 through 41 (determinism reruns, complete)
were created on the live project; all write only to schema lab.

**Verdict: PASS.** Phase L2 closes when the QA gate also passes; the three
MEDIUM items belong to mlm-architect and do not block the build gate.
