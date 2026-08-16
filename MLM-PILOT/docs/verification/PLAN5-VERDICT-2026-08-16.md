# Plan Five ('orvanna_builder') Verdict, 2026-08-16

Grader: mlm-verifier, independent of the builders by charter. Scope: commit
`5a5ff33` (8 files: `db\lab\016`, `017`, `db\lab\115..118`,
`db\lab\README.md`, the builder proof document
`docs\verification\PLAN5-PROOF-RUN-2026-08-16.md`). Spec of record:
`docs\ORVANNA-BUILDER-PLAN-SPEC.md` v1.0 under the lab contract of
`docs\COMP-LAB-SPEC.md` v1.3. Live project: `oiyibdczkokegaxkwulv`, probed
2026-08-16; lab-only writes (three hostile fixture constructions and one
determinism rerun, permitted). This gate is ARITHMETIC TRUTH; the RED-TEAM
gate runs separately after it and owns the presentation-grade attacks.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Structured Query Language (SQL), Message
Digest 5 (MD5), Secure Hash Algorithm 256 (SHA-256), Quality Assurance (QA),
JavaScript Object Notation (JSON).

---

## GATE: PASS

Every fixture rederived by hand to the cent; the ENTIRE calibrated census
run independently recomputed (not five members: all 1,001, every layer,
every factor) with zero differences; Law B held under three hostile
constructions of my own design, including a repeating-decimal proration
factor and a fully exhausted pool. Zero HIGH findings. Two MEDIUM items,
both spec amendments owed to mlm-architect, none against the build. Two LOW
notes. Plan five remains NOT PRESENTABLE until QA and the RED TEAM also
pass it (spec section 13).

---

## 1. Hand rederivations: EXACT

**The ten-member fixture, all three layers (spec section 10).** Derived on
paper before reading lab output; the live run matches every cell:

- Layer 1: spine line-identical to unilevel (M1 114.00 over 9 lines, M2
  16.00 over 2, M3 130.00 over 3, M8 4.00 over 1; company 264.00).
- Layer 2: exactly ONE line: M1's generation 1 on Builder M3, basis
  1,400.00 (group {M3, M7, M8, M10}) at 0.04 = **56.00**; B = M1 is the
  root, so no other walk produces anything.
- Layer 3: M1 second-strongest leg = the M2-leg at 520.00, three active
  legs, multiplier 1.15, stored effective rate **0.0575**, amount **29.90**;
  M2 INELIGIBLE (one active leg despite two legs, the teaching case); M3
  second leg = the M8-leg at 120.00, rate 0.05, pieces 4.00 + 0.40, line
  FLOORED at **4.40** with prorated = true in its trace.
- **The M10 cap-binding row**: pool 10.000000; spine 8.00 (M8 4.00 + M3
  2.00 + M1 2.00); layer 2 piece 1.60 at f2 = 1; remaining 0.40 against the
  2.00 bonus claim gives **f3 = trunc(0.40 / 2.00, 6) = 0.200000 exactly**,
  paid 0.400000; source total **8.00 + 1.60 + 0.40 = 10.00, the cap binding
  exactly**. Live source metrics identical. The M8 row's 19.20-of-20.00
  (three layers, four payments, 0.80 unspent) also matches.
- Company **354.30 = 16.4028 percent of CV 2,160.00**, four paid
  (M1 199.90, M2 16.00, M3 134.40, M8 4.00). All live.

**The DECAY fixture (spec section 6, Law A).** My derivation: month one A =
8.00 spine + 9.60 generation 1 on B's group CV 240.00 = **17.60**; B =
16.00 spine + 4.00 bonus (legs tie at 80.00, the id tie-break makes D's leg
second) = 20.00. Month two (C lapses, B holds one active leg and is NOT a
Builder): A = **8.00**, the shrinkage **exactly the 9.60 override**; B =
8.00. Live rows identical, and the watched attribution is exactly the
spec's promise: A's month-two delta **-9.60 entirely in from_reach_lost**,
decomposable true, every other bucket zero (the 017 pairing key doing its
job: the surviving spine line and the lapsed override line on the same
source B pair separately by reason); B's -12.00 = -8.00 reach_lost plus
-4.00 aggregate, basis 80.00 to 0, lost [LAB-D].

**S1X composition (file 117).** Hand-checked: plan-five mini identity =
34.00 spine + 4.60 bonus (0.0575 x 80.00, M3-leg second on the id
tie-break) = 38.60; S1X = 50.00 spine + 8.00 bonus (M3-leg at 160.00,
multiplier back to 1.00 on two active legs) = 58.00; M1's delta +3.40 =
+4.00 from_added_members - 4.00 from_level_shift + 3.40 aggregate
(4.60 to 8.00). Matches the proof table.

## 2. Law B at its subtlest: MY OWN HOSTILE CONSTRUCTIONS, ALL HELD

Three fixtures I designed and ran myself (runs tagged VERIFIER-P5-*):

**(a) The repeating decimal (VERIFIER-P5-REPEAT).** Eleven members: a chain
of FIVE nested Builders C1..C5 (each with a side leg for its second active
leg), sources S and S2 under C5, all SV 100.00. My hand arithmetic: source
S carries spine 12.00 (C5 8.00 + C4 4.00; C3 at level 3 is depth-gated),
layer 2 claims from four generation 1 and three generation 2 assignments =
4 x 3.20 + 3 x 1.60 = 17.60, so f2 = 8.00 / 17.60 = 0.4545... repeating,
truncated to **0.454545**; pieces trunc to 1.454544 and 0.727272, l2_paid =
**7.999992**, strictly under 8.00: the truncation cushion is the proof that
floor-on-prorated keeps the cap exact. Live metrics identical on S, S2, and
C5. And S2 is even better: its extra 4.00 bonus claim meets a residue of
0.000008, f3 = **0.000002**, paid 0.000008, so S2's source total is
**exactly 20.000000 at scale 6**, binding to the microcent; the bonus line
floors to 0.00 and is correctly NOT WRITTEN while C5's l3_trace records
claimed 4.000000, paid 0.000008, prorated true. Zero sources over pool.
Rounded money can only sit at or under the scale-6 totals because every
prorated line is floored; verified.

**(b) The f2 = 0 worst case (VERIFIER-P5-F2ZERO).** Four members, pool_rate
0.10 chosen so the spine (a single reachable level at 0.10) consumes every
pool exactly; the spine-fits assertion correctly does NOT fire (spine =
pool, never above). Result, matching my hand derivation: f2 = 0.000000 on
every claimed source, f3 = 0.000000 on the bonus source, **ZERO override
and bonus lines written**, while the claims stay fully auditable: B1's
l2_traces reads builder LAB-X1, claimed 9.600000, paid 0.000000, prorated
true, and X1's l3_trace reads claimed 4.000000, paid 0.000000. Company
24.00, spine only. Spec 12A(a)'s "every claim pays 0.00" case is live and
traced.

**(c) The evaluate-then-count edge (VERIFIER-P5-WALK).** Seven members:
Builder E2 under qualified NON-Builder Q under Builder E1 under Member R0.
My derivation: the walk from E2 pays generation 1 to Q at counter 0 (a
non-Builder earning an override), passes E1 with generation 1 already
assigned (E1's own candidacy comes BEFORE its increment, and it gets
nothing), counts E1 as the boundary, and pays generation 2 to R0; E1's own
group pays generation 1 to R0. Live lines exactly: Q 9.60 on E2; R0 4.80
gen2 on E2 AND 19.20 gen1 on E1; **E1 zero layer 2 lines** despite being a
Builder standing on the walk path. Company 93.60, four paid, all matching
my paper totals. The edge the DECAY fixture could not reach is now pinned.

**Bonus, unplanned:** my first attempt to tag the fresh determinism run's
notes was REFUSED by the run freeze and rolled back whole (burned id 93),
live confirmation that plan-five runs are covered by the L2 freeze regime.

## 3. Census: the calibrated run FULLY recomputed independently

I rebuilt the entire calibrated March run from the run's raw snapshots with
my own code: own level map, own ranks (the staged live-plan logic), own
group CVs, own override walk (46 Builders-or-above, 45 generation 1 and 42
generation 2 assignments), own leg ranking and multipliers, own per-source
claims, own truncated factors, own floor-or-round line assembly. Compared
against the lab's lines, EXCEPT ALL both directions:

| Comparison | Result |
|---|---|
| Spine lines, mine versus lab calibrated run | ZERO differences |
| Calibrated run's spine versus lab 'unilevel_v13' run 15 | ZERO differences (the layer-1 equality gate, and run 15 was itself verified against my own L1 recomputation of the real engine) |
| Draft run's spine versus run 15 | ZERO differences |
| Layer 2 lines (gen 1 and gen 2), mine versus lab | ZERO differences |
| Layer 3 lines, mine versus lab | ZERO differences |
| My per-source invariant sweep (spine + l2 paid + l3 paid <= pool) | ZERO violations over 1,001 sources |
| My total | **17,417.12 = the lab's**, 207 paid |

Totals and headline figures all confirmed: draft 20,204.71 = 21.9712
percent of CV; calibrated 17,417.12 = **18.9399 percent of CV** (increment
4.3314 over the 14.6085 baseline); layer sums gen1 2,666.75 + gen2 948.88 +
bonus 367.49 + spine 13,434.00; **structure-linked share = 3,983.12 /
17,417.12 = 22.87 percent, the "22.9" as displayed**. Pool pressure: my
recomputation gives exactly the builder's figures (calibrated 120 sources
at f2 < 1 and 83 at f3 < 1, prorated-away 638.00 and 305.68; draft 333 and
139 from the stored metrics). The junior-layer growth under calibration
(bonus 287.78 draft to 367.49 calibrated) is CONFIRMED as pure waterfall
arithmetic: my own factors reproduce it, smaller senior claims leave the
junior class more room.

**members_paid 207 versus 206 (builder flag 3): STRUCTURAL, confirmed.**
Exactly one member, GW-000294, earns under plan five with no spine line: a
single generation 1 override of 7.80, the first qualified member above a
Builder whose intervening volume pays no spine. Not a defect; the plan's
design paying for development where level pay cannot reach.

**Determinism:** my fresh calibrated run 94 reproduces the committed lines
digest `43525ec8d9b799c2e310686d0d0a6c70` and every total.

## 4. Isolation, freeze, and guardrails

- App inventory unchanged at the jointly-attributed baseline
  **134 / 25 / 54 / 283 / 10**; zero lab grants to public-facing roles;
  zero lab functions writing schema app.
- **No new tables** (lab table count still 11); plan five is functions and
  constraint entries only, and its run-scoped rows land in the
  already-frozen L1 tables; the freeze proven live on a plan-five run
  (section 2's burned id 93). Deployed CHECK constraints carry
  'orvanna_builder' and all four new reason codes; migrations
  `comp_lab_p5_016` and `017` both in the ledger.
- Guardrails, all 8 files: zero em or en dashes, zero employer terminology,
  acronym keys present. The name-capture incident (loop variable shadowing
  a CTE alias, failed loudly, renamed before any run completed) is honest
  disclosure of a defect that never touched a completed run.

---

## Findings

**HIGH: none.**

**MEDIUM (both owed to mlm-architect; none against the build):**

1. **Calibration residue: 4.3314 points against the 2.0-to-4.0 budget.**
   The section 9 one-shot rule was applied exactly as written (factor
   0.4075, rates 0.015 / 0.010 / 0.020, each nearest 0.005, all verified);
   the overshoot is the same proration non-linearity binary's calibration
   met (relief shrinks as rates shrink), and Law B is untouched either way.
   Iterate, accept-and-display (the binary precedent), or shave one rate
   half-step: architect ruling owed, and the spec amended with it.
2. **Section 9's density sentence is falsified by measurement** ("the
   census tree is sparser in Builders, so the increment should land
   lower": it landed 7.3627 at draft, far above the fixture's 4.2). The
   spec was written to survive a hostile read; this sentence would not.
   Amend it to the measured truth.

**LOW:**

1. **The one-shot calibration note in plan_params** names the factor and
   date but not which run measured the 7.3627; one clause naming the draft
   run id would make the recipe self-contained. Cosmetic.
2. **The proof doc's structure-linked share prints 22.9**; the exact figure
   is 22.8690 (3,983.12 / 17,417.12). One-decimal display is fine; noting
   so the dashboard rounds consistently.

## Not probed (stated per charter)

- THE RED TEAM's territory, deliberately left to it: the section 11
  anti-gaming numbers replayed against the engine, the pool-pressure
  distribution as a presentation claim ("rare and junior" at 12 percent of
  sources prorating), regulatory posture, field-psychology failure modes,
  and every behavioral claim (the section 12 caveat: the lab proves payout
  geometry, not behavior).
- The QA gate's territory (no member-visible surface changed).
- The DRAFT census run was verified by spine equality, totals, stored
  pool-pressure metrics, and the calibration arithmetic, but not fully
  independently recomputed line by line (the calibrated run, which is the
  run of record for comparisons, was).
- The S1X plan-five watch row was hand-verified from the proof document
  and my L3-verified machinery; the 117 script's checks were not re-executed
  individually.
- Multi-month census trajectories (only March exists in the lab so far);
  August remains unused.
- The watchlist soft-cap and the 017 pairing key's no-op property for prior
  plans (asserted by the builder; the L3 determinism digests of prior-plan
  runs were not re-run after 017, though 017 only touches snapshot writing,
  which prior frozen runs cannot re-enter).

## Hashes of the graded artifacts (SHA-256, commit `5a5ff33`)

```
6fe668dbb8383fcf30e7d40b156bcd09fb6d17693a87a877fc40276fbac49ccf  db/lab/016_lab_plan_orvanna_builder.sql
d887dfbdbaa8e79cdaed71e5404e1976a53bff722516e946ed60d0b369a5ce50  db/lab/017_lab_watch_snapshots_v2.sql
8f08f0bf21aab3a7c672fe021c398f741387711a7cd9a03627bc6c9c69a17b2d  db/lab/115_proof_p5_ten_member.sql
8d11290b01bde47bd539da530d5f6b2601d1fb8c0d5e9baa38c1c97cbed7f0ca  db/lab/116_proof_p5_decay.sql
14a9753c67096293b94c70a420dd0d0637e0f265df1431ed68eddb2b2d18bd2f  db/lab/117_proof_p5_s1x_composition.sql
012a91b37c71dcdd279bfbf6637f39b1d8e3c9368f3bd4e700ebd49b00764c7c  db/lab/118_p5_census_calibration.sql
835a026985bfddd38d3cc073b0c08aa1f1292d76e134ad49ca89f84a3627b099  db/lab/README.md
186037d46b239c14280e42967df28751f0c18a60d95e79167b898c54b5eaee69  docs/verification/PLAN5-PROOF-RUN-2026-08-16.md
```

Side effects of this verification, recorded: lab runs VERIFIER-P5-F2ZERO,
VERIFIER-P5-REPEAT, VERIFIER-P5-WALK (hostile fixtures, complete), run 94
(the determinism rerun, complete), and burned id 93 (the freeze refusal,
rolled back whole). All write only to schema lab. This gate was interrupted
once by a spend-limit outage and resumed from the transcript; no completed
check was redone.

**Verdict: PASS.** Arithmetic truth holds: every fixture to the cent, the
census recomputed whole, and Law B unbroken under construction-grade
hostility. Plan five is presentable only when QA and the RED TEAM also
pass (spec section 13); the two MEDIUM amendments belong to mlm-architect.
