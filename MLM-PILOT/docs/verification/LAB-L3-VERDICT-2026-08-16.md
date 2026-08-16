# Comp Plan Lab, Phase L3 Verdict, 2026-08-16

Grader: mlm-verifier, independent of the builders by charter. Scope: commit
`d25a2ef` (8 files: `db\lab\014`, `015`, `db\lab\111..114`,
`db\lab\README.md`, the builder proof document
`docs\verification\LAB-L3-PROOF-RUN-2026-08-16.md`). Spec of record:
`docs\COMP-LAB-SPEC.md` v1.3 sections 9 (scenarios) and 10 (watched
accounts) with the section 8 rulings. Live project: `oiyibdczkokegaxkwulv`,
probed 2026-08-16 with read-only queries against schema `app` and lab-only
writes (two construction probes and three determinism reruns, permitted).

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Group Volume (GV), Structured Query Language
(SQL), Message Digest 5 (MD5), Secure Hash Algorithm 256 (SHA-256), Quality
Assurance (QA), JavaScript Object Notation (JSON), Row-Level Security (RLS),
Foreign Key (FK).

---

## GATE: PASS

Every L3 acceptance clause passed under independent replay, and both of the
builder's argued-not-proven points (the ordinal rule under month scoping;
the set-based roll-up on a non-leaf removal) were PROVEN by construction
probes I built myself. Zero HIGH findings. One MEDIUM and three LOW, all
spec-wording items owed to mlm-architect; none against the build. Phase L3
still requires the QA gate to close.

---

## 1. Independent replays: EXACT, all three scenarios

Each derived on paper from spec sections 9 and 10 before reading lab output,
then matched against the live rows (runs, lines, placements, watch
snapshots).

**S1 (add a 100-volume recruit under M2), spec 9.5.** My replay: synthetic
member LAB-S1-1, id 10,000,001, sponsor LAB-M2, SV 100.00, CV 80.00,
qualified. Unilevel: TV(M1) 500.00, TV(M2) 150.00, ranks unchanged (M1
Builder depth 2; M2 one active leg, Member), new lines only M2 on LAB-S1-1
at level 1 = 8.00 and M1 at level 2 = 4.00; company **46.00** on SV 700.00 /
CV 560.00; watched deltas M1 +4.00 and M2 +8.00, both entirely
from_added_members, decomposable true. Binary A (draft 0.20 per the fixture
ruling): LAB-S1-1 spills to M4.left (BFS of M2's full subtree), legs M1
320/80 and M2 160/40, pay legs UNCHANGED at 80.00 and 40.00, company
**24.00**, both deltas 0.00 with bases unchanged; flushed unmatched CV over
members WITH a pay line = 240.00 + 120.00 = **360.00** (72.00 at the rate).
Live rows: identical in every cell.

**S2 (move M4 under M3), spec 10.3.** My replay: unilevel M1 26.00, M2 4.00,
M3 8.00, company **38.00**; binary A legs of M1 TIE at 160.00 each, ties pay
the LEFT leg, M1 alone earns **32.00**. The four watched rows, mine versus
live, all exact:
- M1 unilevel -4.00, entirely from_level_shift (M4's line, level 1 8.00 to
  level 2 4.00), every other bucket zero;
- **M1 binary +16.00, decomposable false, basis 80.00 to 160.00,
  basis_members_gained [LAB-M2, LAB-M5], basis_members_lost [LAB-M3]** (the
  pay leg switched sides on the tie: baseline pay leg was the right {M3},
  the tie hands it to the left {M2, M5}), which is exactly what the live
  snapshot carries;
- M2 unilevel 0.00, all buckets zero;
- M2 binary -8.00, basis 40.00 to 0.00, lost [LAB-M5] (the move took M4's
  spillover leg away, so M2's weaker leg is now the empty right).

**S1X (S2's move stacked on S1's add, parent chain depth 2).** My replay of
the effective list (add, then move): tree M1 -> M2, M3; M2 -> M5, LAB-S1-1;
M3 -> M4. Unilevel: M1 30.00 (M2 12.00 + M3 8.00 + level 2: M5 2.00, S1-1
4.00, M4 4.00), M2 12.00, M3 8.00, company **50.00** on SV 700.00. **The
showcase row, confirmed exactly: M1's delta against the identity baseline is
0.00, composed of +4.00 from_added_members (LAB-S1-1's level 2 line) and
-4.00 from_level_shift (M4 pushed from level 1 to level 2), the two stacked
mutations telling themselves apart inside one decomposition that sums to the
delta to the cent.** M2 +8.00 from_added_members. Binary A: placement M4 to
M3.left, M5 to M2.left, S1-1 to M2.right; M1 pays on 160.00 = 32.00 (no tie
this time: 240 versus 160), M2 on 40.00 = 8.00, company **40.00**; M1's
basis movement gained [LAB-M4] and lost nothing (the pay leg stayed right
and M4 joined it), which the live snapshot carries.

**The five-recipe sweep table** (identity / S1 / S2 / S1X under unilevel,
binary A at ruled 0.105, binary B at ruled 0.110, matrix A, stairstep): I
re-derived all twenty cells by hand, including the ruled-rate binary cells
(12.60 / 12.60 / 16.80 / 21.00 for A; 17.60 / 22.00 / 17.60 / 22.00 for B),
matrix (18.00 / 26.00 / 22.00 / 30.00), and stairstep (22.00 / 26.00 /
22.00 / 26.00, uniform bottom bracket collapsing every differential to 5
percent of own CV). Every cell matches the live ledger. The shape stories
the builder tells (the recruit worth nothing to ruled binary A; the move
that doubles binary A leaving stairstep untouched) are arithmetically real.

**Month scoping (S-REM):** July run 5 members / 600.00 / 34.00, August run
4 members / 500.00 / 26.00, M4 present then gone. Matches the question 9
ruling and the live rows.

## 2. The ordinal rule under month scoping: PROVEN by my own construction

I built scenario V-ORD myself: seq 1 add_member under LAB-M1 scoped
month_from 2026-09-01 (OUT of a July run), seq 2 add_member under LAB-M3
unscoped. The July run's derived set carries EXACTLY ONE synthetic member:
**code LAB-V-ORD-2, id 10,000,002**, sponsor LAB-M3, SV 100.00. The
scoped-out first add consumed ordinal 1 without materializing, exactly the
014 design decision 3 contract (one id per synthetic member across a
window). The run's money also matched my hand prediction (company 46.00,
three paid: M1 34.00, M2 4.00, M3 8.00).

## 3. remove_member on a NON-empty frontline: PROVEN, set-based = walk

The builder's S-REM probe removed a leaf; I built the real case: scenario
V-REM2, child of S1, removing LAB-M2 whose frontline in the derived tree is
TWO members of different id conventions, LAB-M5 (base id 5) and LAB-S1-1
(synthetic id 10,000,001). Live result: both orphans reattached to LAB-M1,
each keeping its own (empty) subtree, M2 gone, tree M1 -> M3, M4, M5,
S1-1. Money exactly my hand prediction: SV 550.00 / CV 440.00, M1 the sole
earner at level 1 on all four (8.00 + 8.00 + 4.00 + 8.00 = **28.00**), one
member paid. On the equivalence argument itself (014 decision 5): the
set-based UPDATE assigns every orphan the SAME new sponsor, so no per-row
order can change the outcome; the ascending-walk wording and the set-based
implementation are extensionally identical for every input, and the live
case confirms it where both conventions meet. PROVED, not just argued. The
ascending-id placement guard also survives (both orphan ids exceed the new
sponsor's id 1).

## 4. Determinism, the invariant, and isolation

**Determinism, fresh runs:** I created three runs myself through the same
entry points (S1 unilevel, S2 binary A at ruled 0.105, S1X stairstep) with
the builder's named baselines, and compared code-keyed MD5 digests against
the builder's sweep runs 72, 73, and 74: derived members, lines, results,
watch snapshots (full component JSON included), and totals: **all five
digest families identical on all three pairs** (payouts 46.00, 16.80,
26.00). The builder's SW1a code-keyed convention is the right one for
cross-convention comparison; the disclosed id-keyed incident is a loading
convention difference, not an output difference, and my code-keyed digests
close it.

**The component invariant (spec 10.2):** my own whole-table query over all
**73** watch snapshots: bucket sum plus aggregate_delta equals delta_earned
in every row with a resolvable baseline, **zero violations**; the 26
baseline-less rows carry null delta and {"no_baseline": true} as designed.
The bucket edge semantics match 10.2 exactly (a common source with lines at
different levels lands in from_level_shift as now minus before, verified in
S2 and S1X).

**Isolation co-sign, with attribution.** Fresh inventory at gate time:
schema app **134 relations / 25 non-internal triggers / 54 functions / 283
grants / 10 policies**, versus the L2 baseline 88 / 14 / 17 / 185 / 10 and
the L3 proof doc's own interim reading (131 / 25 / 28 / 262, taken before
migrations 026 and 027 finished landing). The migration ledger ends at
`bridge_covered_months_027`; nothing landed after it. Attribution, checked
by name over every table, view, and function in schema app: every object
beyond the L2 baseline is subscription-engine vocabulary (subscriptions,
subscription_events, billing_attempts, billing_runs, billing_schedule,
renewal_periods, retry_policies, decline_classifications, sim_clock and its
audit tables, fn_sub_*, fn_billing_tick, fn_dispatch_attempt, fn_classify,
fn_scheduler_poll, fn_sim_*, the guard triggers on those tables, and views
v_subscription_next_billing, v_volume_schedule, v_cycle_audit,
v_staff_attention_queue), matching migrations `subscription_engine_schema_
024`, `subscription_classification_data_025`, `subscription_engine_core_
026`, and `bridge_covered_months_027`. **Lab-flavored objects in schema
app: ZERO** (name scan). The lab's baseline-independent proofs re-run by
me: zero lab functions writing app.* (pg_proc grep), exactly one lab-to-app
FK (the sanctioned one), zero app-to-lab, zero lab grants or schema usage
for anon / authenticated / app_demo_reader (the new `watch_snapshots` table
included), RLS on every lab table, app policies unchanged at 10. **CO-SIGNED:
the app delta belongs entirely to migrations 024 through 027 and none of it
to the lab.** I second the builder's recommendation: re-baseline the app
inventory jointly with the subscriptions builder before L4.

**Refusal evidence, cross-checked in the ledger:** S-D4 does not exist
(depth-4 lock refused), no L3-PROBE-BAD-ROOT run exists, and the missing
run ids are exactly 1, 10, 17, 52, the four disclosed burns (52 = the
rolled-back root-removal replay). Scenario statuses all locked, none
deleted.

## 5. The two architect-owed spec items, ruled at my judged severity

1. **Lock-time validation is shape-only (MEDIUM, architect, v1.4).** Spec
   9.2's mutation table says "Validation at lock, re-checked at run"; the
   build validates SHAPE (per-kind fields, 50.00 profile grain, depth cap)
   at lock and existence/cycle at replay, failing loudly. The behavior is
   the right one, and the builder's reason is structural, not
   convenience: fixture scenarios reference base members that exist only
   inside a run, so lock-time existence checking is impossible in general.
   That makes this the same class as the L2 wording items: correct behavior
   the spec text does not yet say. V1.4 owes the scoping sentence; no
   rebuild.
2. **The sixth defaulted parameter on fn_run_plan (LOW, architect, v1.4).**
   `p_baseline_run_id default null` makes question 11's named baseline
   callable; a five-argument call (and a four-argument call) behaves
   exactly as the spec text declares, and the old signature was dropped so
   no ambiguity exists. Identical in kind to the fifth parameter at L1,
   which was LOW then and ratified in v1.2; consistency says LOW, and the
   same one-line ratification is owed.

Two further builder flags, ruled while here: the **flushed-CV aggregation
wording** (flushed totals sum over members WITH a pay line; a one-legged
member's strong leg is no-pay, not flush) is arithmetically forced by spec
9.5's own 360.00 and belongs in section 5's breakage row (LOW, folded into
finding 3); the **stairstep mixed-case snapshot** (per-source override
buckets plus an aggregate differential movement in one component object,
decomposable false, the invariant spanning both) is CONFIRMED as the honest
reading of 10.2's plan classification, since stairstep is the one plan that
emits both line kinds; v1.4 should say so in a sentence (LOW, finding 4).

## 6. Guardrail sweep: CLEAN

Across all 8 files: zero em or en dashes (byte-level scan), zero employer
terminology or data, acronym keys present, generic industry language
throughout. The disclosed mid-build outage note in the proof document is
honest disclosure, properly recorded.

---

## Findings

**HIGH: none.**

**MEDIUM (architect-owed, none against the build):**

1. **V1.4 owes the lock-time validation scoping sentence** (section 5 item
   1): state that lock validates shape, grain, and depth, and that
   existence and cycle checks run at replay and fail the run loudly.

**LOW (all v1.4 wording, behavior verified correct):**

1. **Sixth-parameter signature ratification** for `lab.fn_run_plan`
   (section 5 item 2), the fifth-parameter precedent applied.
2. **Flushed-CV aggregation sentence** in section 5's breakage row: flushed
   totals are computed from lines (members with a pay line), never from
   per-member flags alone.
3. **Stairstep mixed-case snapshot classification**: one sentence in 10.2
   recording that stairstep snapshots carry both per-source buckets and an
   aggregate differential movement, decomposable false, invariant spanning
   both (my confirmation of the builder's flag 4).

## Not probed (stated per charter)

- The QA gate's territory (no member-visible surface changed; lab grants
  and app policies re-verified unchanged).
- CENSUS-SCALE scenario runs: every L3 proof and probe runs on the
  five-member mini base (the spec's own hand examples). The identity
  scenario's census path is unchanged by construction (empty replay) and
  was verified at L1/L2, but no mutation scenario has yet replayed over the
  1,001-member census; the L4 gate should include one census scenario run
  when the report renders one.
- The builder's full 66-run SW1a pairwise assertion was not re-executed;
  my targeted three-pair code-keyed digest comparison (which includes watch
  snapshots, which SW1a's totals do not) passed instead.
- The watchlist soft-cap warning trigger (notice-only) was not exercised.
- The ACLs of the three new trigger or notice functions (carry-over of the
  L1 LOW; harmless without schema usage).
- The disclosed spend-limit outage: accepted from disclosure; the ledger
  shows no unexplained gaps (every missing id accounted for).
- August 2026 bridged volume (still not final; unused by L3).

## Hashes of the graded artifacts (SHA-256, commit `d25a2ef`)

```
bb1446cd67e41594a6e72b89037f0b5cf208d0da4d6a63f2cebeea7238433ce3  db/lab/014_lab_scenario_replay.sql
bea0f0b58f40fa5a420dc528367eab9dbb5cef91f995a96c1f55554467f11d44  db/lab/015_lab_watch_snapshots.sql
1df3fd079fefeeb375676e212df9e6c1bd932205d5f8763009f686a6fd5e86b4  db/lab/111_proof_scenario_s1.sql
a01b92aced6ac1c1265f4c709ecce602692bfc11dc5c340d2d352ae90bc3d628  db/lab/112_proof_scenario_s2.sql
b14b820c52188612879eb993355b3c0ea679d2720aeecdb338387b5ac3a077b8  db/lab/113_proof_stack_and_months.sql
c03761d2b1adbef61af67a668e14b483f8476d2ca58e141084198285563f2bda  db/lab/114_proof_l3_sweep.sql
030245ff27426e66fe617a133be445abf124cce47fb04cfc5ce476a34b6719d5  db/lab/README.md
650f4b3ef35041925cc47d2cbbe8da0569f53a0be3902e0c92a597739aca88dc  docs/verification/LAB-L3-PROOF-RUN-2026-08-16.md
```

Side effects of this verification, recorded: scenarios V-ORD and V-REM2
(both locked, verifier construction probes) and five lab runs
(VERIFIER-L3-ORD-JULY, VERIFIER-L3-REM2, and the three
VERIFIER-L3-DET reruns, ids 75 through 79, all complete); all write only to
schema lab.

**Verdict: PASS.** Phase L3 closes when the QA gate also passes; the one
MEDIUM and three LOW wording items belong to mlm-architect's v1.4 and do
not block the build gate.
