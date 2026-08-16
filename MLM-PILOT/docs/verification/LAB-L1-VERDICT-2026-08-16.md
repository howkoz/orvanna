# Comp Plan Lab, Phase L1 Verdict, 2026-08-16

Grader: mlm-verifier, independent of the builders by charter ("the builder never
grades its own work"). Scope: commit `ed8f27d` (16 files: `db\lab\001..007`,
`db\lab\100..106`, `db\lab\README.md`, the builder proof document
`docs\verification\LAB-L1-PROOF-RUN-2026-08-16.md`). Spec of record:
`docs\COMP-LAB-SPEC.md` version 1.1. Live project: `oiyibdczkokegaxkwulv`,
probed 2026-08-16 with read-only queries against schema `app` and read plus
lab-only writes against schema `lab` (two determinism reruns, permitted).

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Structured Query Language (SQL), Row-Level
Security (RLS), Breadth-First Search (BFS), Message Digest 5 (MD5), Secure
Hash Algorithm 256 (SHA-256), Quality Assurance (QA), Foreign Key (FK).

---

## GATE: PASS

Every acceptance clause of the COMP-LAB-SPEC section 7 L1 gate passed under
independent recomputation. Zero HIGH findings. Three MEDIUM findings, all
owed to the ARCHITECT (spec amendments), none against the build. Three LOW
notes. Phase L1 still requires the QA gate to close (project rule: both gates).

---

## 1. Independent parity recomputation (the heart): PASS, exact three ways

Method: my own SQL, written from `docs\COMP-PLAN-SPEC.md` v1.3 alone (own
recursive level map, own volume aggregation from `app.orders`, own staged rank
flags, own line generation). Not the lab's functions, not the engine's.
Compared simultaneously against the REAL finalized March 2026 run (the unique
'final' `app.commission_runs` row for the period) and against lab parity run 3.

| Comparison | Result |
|---|---|
| Line counts (mine, real, lab) | 1,630 = 1,630 = 1,630 |
| Lines, EXCEPT ALL both directions, mine versus real, on (earner, source, level, basis, rate, amount) | ZERO differences |
| Lines, EXCEPT ALL both directions, mine versus lab run 3 | ZERO differences |
| Company totals (mine) | total_sv 114,950.00; total_cv 91,960.00; total_payout **13,434.00**; members_paid 206. Equal to the real run row and the lab run row, value for value. |
| Member results, mine versus lab run 3, on (member, sv, cv, qualified, rank, paid depth, total_earned) | ZERO differences, 1,001 rows each |
| Member results, mine versus real | Exactly ONE difference: my side carries member GW-000 (enrolled 2026-08-15, after the real run finalized 2026-08-13) with sv 0.00, cv 0.00, unqualified, rank member, total_earned 0.00. My own re-run of the PAR3-style assertion confirms NO other difference exists. The explained census drift is exactly as the builder stated. |
| Identity proof (my own ID1-style query) | Derived set of run 3 equals the `app.members` census row for row, both directions, 1,001 = 1,001, zero synthetic or mismapped rows. |

The builder's parity claim is reproduced independently and is exact.

## 2. Binary by hand: PASS

I derived both placement trees and all payouts on paper from spec sections 3.2,
3.3, and 4.2 before reading any lab output, then compared against the live
placement maps and results.

**Ten-member fixture, strategy A ('bfs_spill'), run 7.** My hand tree: M2 at
M1.left, M3 at M1.right, M4 SPILLED to M2.left, M5 at M2.right, M6 SPILLED to
M4.left, M7 at M3.left, M8 at M3.right, M9 at M5.left, M10 at M8.left. Leg CV:
M1 min(600.00, 1400.00) pays 120.00; M2 min(200.00, 280.00) pays 40.00; M3
min(1200.00, 120.00) pays 24.00; all others an empty leg or unqualified.
Company **184.00** = 8.52 percent of CV 2,160.00. The live run matches edge for
edge and cent for cent.

**Ten-member fixture, strategy B ('volume_balanced'), run 8.** My hand tree:
M4 descends to M3.left (M1's legs weighed SV 150 versus 100 at that step), M5
at M2.left, M6 at M2.right, M7 at M3.right, M8 at M4.left, M9 at M5.left, M10
at M8.left. Pay: M1 on 520.00 = 104.00; M2 on 120.00 = 24.00; M3 on 200.00 =
40.00. Company **168.00**, spread A minus B = 16.00, M2 and M3 trading places.
The live run matches edge for edge and cent for cent.

**Mini tree (spec section 6):** unilevel lines and totals (company 34.00, M1
30.00, M2 4.00) and binary A (company 24.00, M1 16.00 on pay leg 80.00, M2
8.00 on 40.00) reproduced by hand and matched against runs 4 and 5. Exact.

**Census-scale binary cross-check (beyond the assignment):** I recomputed all
166 binary lines of run 16 from its placement map with my own aggregation
(own recursive leg pairing, own CV, own cap logic): ZERO differences against
the lab's lines, total 25,784.00. Two lines DO hit the 2,500.00 cap at census
scale (see LOW note 3).

## 3. Rulings on the three flagged items

### 3a. The spec self-inconsistency (section 6.3 versus 3.3 and 6.4): THE BUILDER IS RIGHT. Finding against the SPEC.

I recomputed strategy B on the five-member mini tree by hand from section 3.3
alone. At M4's placement step, M1's legs already weigh SV 150 (left, M2)
versus 100 (right, M3). Section 3.3 says descend into the smaller leg, so M4
lands at M3.left, NOT in spillover at M2.left. Resulting legs at M1: left
{M2, M5} = 160.00 CV, right {M3, M4} = 160.00 CV, a tie, ties pay the left
leg: M1 alone earns round(0.20 x 160.00, 2) = 32.00; M2 and M3 each have an
empty right leg and earn nothing. Company under B = **32.00**, spread A minus
B = **-8.00**, not the "spread 0.00" section 6.3 asserts. Live run 6 shows
exactly my hand result (M4 at M3.left, payout 32.00, one member paid).
Section 6.3's parenthetical ("Strategy B coincides on this tree... spread
0.00") is internally inconsistent with the spec's own algorithm and its own
section 6.4 derivation. The build handled this correctly: gated on the
consistent numbers, recorded the B mini run as informational, flagged the
inconsistency. **MEDIUM finding F1, against the spec; mlm-architect owes the
section 6.3 amendment.**

### 3b. Strategy B's prose interpretation: FAITHFUL.

The builder's reading (weigh at each node by the month SV of currently placed
members per leg, ties descend left, an empty weaker leg is the open slot) is
the plain reading of section 3.3: an empty leg's sum is 0, which is always
smallest or tied-smallest, and "until an open slot is reached" makes the empty
weaker leg the destination. The implementation in `003_lab_placement.sql`
(v_l_sum <= v_r_sum descends or places left) does exactly this. Proof of
faithfulness: my independent hand derivation under this reading reproduces the
spec's OWN section 6.4 ten-member derivation placement edge for placement edge
and cent for cent (168.00), and the mini-tree result of ruling 3a. No
alternative reading of the prose reproduces 6.4. **Ruling: the interpretation
is correct; no finding.**

### 3c. The extra-root handling: ACCEPTABLE FOR L1; architect ratification owed.

Live census confirmed: exactly two rootless members, GW-000001 (id 1, the seed
root) and GW-000 (id 1001, the company retention account, migration 020). The
rule applied (lowest-id root is the placement root; later rootless members
placed as if sponsored by it) is deterministic, documented in the 003 header,
and keeps the one-connected-tree assumption the spec itself relies on. Money
effect proven nil on the live project: GW-000 carries SV 0.00 in run 16,
landed at depth 4 under GW-000106 slot 1, contributes 0.00 to every leg it
joined, and earns zero lines. Migration 020 keeps house volume out of
`app.orders`, so the exposure is currently structural zero. **Ruling:
acceptable for L1. MEDIUM finding F2, spec ambiguity: mlm-architect must
ratify or replace the rule (spec 3.2 says "root", singular) before any month
in which GW-000 could carry order volume.**

## 4. Isolation audit, re-run live: PASS on every clause

All probes run by me against the live project, not copied from the builder:

| Probe | My result | Builder claim | Match |
|---|---|---|---|
| Schema app inventory after lab (relations / non-internal triggers / functions / table grants / RLS policies) | 88 / 14 / 17 / 185 / 10 | same | YES |
| Table grants in schema lab to anon, authenticated, app_demo_reader | 0 | 0 | YES |
| Schema usage on lab for those three roles (has_schema_privilege) | 0 roles | 0 | YES |
| Lab tables with RLS off / lab policies | 0 / 0 (RLS on all ten, zero policies) | same | YES |
| Lab functions whose body writes app.* (INSERT/UPDATE/DELETE/TRUNCATE grep over pg_proc.prosrc) | 0 | 0 | YES |
| FKs lab to app / app to lab | 1 (`derived_members_app_member_id_fkey`, the spec-sanctioned one) / 0 | same | YES |
| Status 'final' possible in lab | NO, by inspection: `plan_runs_status_check` admits only ('running', 'complete', 'archived') | refused by attempt | YES |
| The 'LAB-' name wall | IN PLACE, by inspection: `derived_members_synthetic_name_wall` CHECK (app_member_id set OR member_code like 'LAB-%') | refused by attempt | YES |
| SECURITY DEFINER in lab | None; all eleven lab functions are invoker | (not claimed) | n/a |
| Run ledger | Runs 2 to 16 present, ids 1 and 10 absent (burned identities), archived probe row intact, matches builder finding 5, plus my runs 15 and 16 | consistent | YES |

## 5. Determinism, re-run by me: PASS

I created two fresh census runs myself via `lab.fn_run_plan` (writes to lab
only, permitted): run 15 (unilevel March) and run 16 (binary A March), then
computed the proof-105 digest construction over each. Every digest equals the
committed value:

| Run | Digest | Mine | Committed | Match |
|---|---|---|---|---|
| 15 unilevel | lines_md5 | `2013ad718c42d0a33b6c9e987696eeaa` | same | YES |
| 15 unilevel | results_md5 | `589801c6edab3e4d556bfbd2d20dafe5` | same | YES |
| 16 binary A | lines_md5 | `5e5bd3e98ed70f0d3ddd8e18f5230722` | same | YES |
| 16 binary A | results_md5 | `71bced9b282b5aff7e56797957234d85` | same | YES |
| 16 binary A | placement_md5 | `371f94f0305946ad7df37fd7f5c492b1` | same | YES |

Totals identical (13,434.00 / 206 paid; 25,784.00 / 166 paid). The builder's
digest-masking worry (text serialization hiding a scale-only difference) is
closed by my section 1 and 2 comparisons, which are typed-value EXCEPTs, not
text digests, and passed independently.

Order source and period snapshot for these claims, verified live: March 2026
carries 1,462 completed orders, zero bridged (`demo_order_id` null on all);
both my runs stamped `order_source = 'seeded_orders'`.

## 6. File 007 (the ANALYZE fix): PROPER FORWARD FIX

- Git: both 006 and 007 are new files in `ed8f27d`; 006 has exactly one commit
  touching it, no in-place edit exists in history.
- Live migration ledger: `comp_lab_l1_006_run_plan` applied 15:08:53,
  `comp_lab_l1_007_analyze_snapshots` applied separately 15:15:17, matching
  the house discipline (applied files stay frozen; follow-ups are new numbered
  files).
- Content diff 006 versus 007: 007 redefines `lab.fn_execute_plan` only, and
  the only behavioral additions are the four transaction-safe ANALYZE
  statements after each snapshot materialization. ANALYZE changes plans, never
  results; row order is fixed by the stable ORDER BYs. The deployed function
  carries the ANALYZE text (verified in pg_proc.prosrc), so the live project
  runs the 007 version, and my determinism digests (section 5) were produced
  against it.

## 7. Calibration figures: RECOMPUTED, CORRECT, AMENDMENT PENDING

From the run rows I verified: unilevel 13,434.00 / 91,960.00 = 14.6085 percent
of CV; binary A 25,784.00 = 28.0383 percent; binary B 24,836.00 = 27.0074
percent. Calibrated rates: 0.20 x (14.6085 / 28.0383) = 0.1042, nearest 0.005
= **0.105** (A); 0.20 x (14.6085 / 27.0074) = 0.1082, nearest 0.005 = **0.110**
(B). Census spread 948.00 = 3.68 percent of A. All three of the builder's
numbers confirmed. See MEDIUM finding F3.

## 8. Guardrail sweep: CLEAN

Across all 16 files: zero em dashes and zero en dashes (byte-level scan); zero
employer terminology or data (term sweep clean); acronyms expanded with keys
in every prose-bearing file; generic industry language throughout; the what-if
disclaimer and derived-placement caption are GENERATED columns and present on
the live rows I read.

---

## Findings

**HIGH: none.**

**MEDIUM (all owed to mlm-architect, none against the build):**

1. **F1, spec self-inconsistency, section 6.3.** The "strategy B coincides,
   spread 0.00" parenthetical is wrong by the spec's own sections 3.3 and 6.4;
   the true mini-tree B result is company 32.00, spread A minus B = -8.00
   (ruling 3a, verified by hand and live). Amend section 6.3.
2. **F2, extra-root ambiguity, section 3.2.** Two rootless census members
   exist; the build's lowest-id-root rule is deterministic and currently moves
   no money (ruling 3c). Ratify or replace it in the spec before GW-000 can
   ever carry order volume.
3. **F3, calibration amendment not yet landed.** Spec 4.2 and Howard's section
   8 ruling 3 say the spec "is amended with the number the same day". The
   builder computed the numbers (0.105 strategy A, 0.110 strategy B, both
   verified here) and was correctly under instruction not to edit the spec;
   the amendment, including WHICH strategy anchors calibration, is the
   architect's and is still open. The L1 deliverable "the calibrated rate
   amendment" is complete on the build side only.

**LOW:**

1. **Interface note, recorded:** `lab.fn_run_plan` carries a fifth defaulted
   parameter (`p_scenario_code default 'IDENTITY'`) beyond the declared
   four-parameter signature of spec 1.1. Behavior of the four-argument call is
   exactly as declared. The spec signature should be updated when 6.3 is
   amended.
2. **Trigger-function grants:** the three `enforce_*` trigger functions retain
   the Postgres default PUBLIC execute grant (`{=X/postgres}`), unlike the
   eight worker functions, which were revoked. Harmless today (no public role
   holds usage on schema lab, so nothing can reach them), but revoking would
   match the file's own hygiene convention.
3. **Cap fires at census scale:** two binary lines in the March census run are
   capped at 2,500.00. No document claims otherwise, but no document says it
   either; worth one sentence in the lab README or the L2 dashboard notes,
   since capped remainders are defined as breakage in section 4.2.

## Not probed (stated per charter)

- The QA gate's territory: no member-visible surface, page, or console was
  probed, because this commit changes none (verified: zero new grants, no
  `v_demo_*` change in the diff).
- August 2026 (bridged volume): excluded from every claim here, as in the
  builder's proofs; its run is not final.
- Strategy B at census scale was NOT independently re-derived (the 1,001-member
  volume-balanced walk); its fixture-scale algorithm is hand-verified (rulings
  3a and 3b), its census run exists (run 14, 24,836.00), and its determinism
  digest pair was the builder's, not re-run by me.
- Applied migration bodies were not byte-compared against the repository files
  (the management interface lists names only); deployed function properties
  were verified instead (007's ANALYZE present in the live function body,
  all functions invoker, write-grep clean).
- The scenario-lock, mutation-freeze, and no-delete triggers were verified by
  code inspection and ledger evidence (burned ids 1 and 10, archived probe
  row), not by fresh live refusal attempts.
- The TRUNCATE interaction on `app.members` (accepted on inspection; testing
  it would write to schema app).

## Hashes of the graded artifacts (SHA-256, commit `ed8f27d`)

```
f11f014f407060491c21df9fa506332074f9bb9271867e25b87b53dc0cbea69c  db/lab/001_lab_schema.sql
aea7c066b6584f254bea49bf708d982967a2dc2ac1b72c44ebe5033c847b6fc9  db/lab/002_lab_derivation.sql
dd79b8ba0c151345bb8645fd1193d61acc8c6e46bbe096e58fad0912583925b7  db/lab/003_lab_placement.sql
836abc042f127eabb2eca604a21a1b57fdbe903bd44d0b50229fa2ecd7aefb72  db/lab/004_lab_plan_unilevel.sql
ff8457b643aba0446446ddf7f6099bf15500c6d1068e6f2b4990ab5faf390cba  db/lab/005_lab_plan_binary.sql
49ce6f34cd03bc74423742129f0883c5c1d3879b3e9a46339ff5d172d32a3756  db/lab/006_lab_run_plan.sql
fa6f34e5b1c8b67770e0ffee03a3b4ad5c82f9bc804be4b3b466bf432caa329f  db/lab/007_lab_analyze_snapshots.sql
7cb4632ac409ef73a41d0046ca054e3bc63f72e20f69f4af79718f50a8c44fee  db/lab/100_proof_isolation.sql
ddb691b09cf343021261114df1c58ea126ff0e7d27a19457116002b548e300bb  db/lab/101_proof_identity.sql
054a5e3ce1d79b2cffe93a3ea80ef74bc0a8496d4a9b911f35ef375e1060acc4  db/lab/102_proof_parity.sql
bf1a0f8a4b5ef35eabdd35ed363b7eebedaa71003d1b176f8dc8a5fe51691a6d  db/lab/103_proof_minitree.sql
27ff43f9959fd950b740543d77add97f9e17e11e339a605bc1c12e359f3be86b  db/lab/104_proof_ten_member.sql
23415202bd3e15061d894159e945e3cbfe211fa85f3155c0814c6068971a32d2  db/lab/105_proof_determinism.sql
e9f013ae0615f3aeb3af31c906e253542fc15e40ae3f3bd3f11177fe8d7daa0e  db/lab/106_calibration_march.sql
a001b0fd24b19af8def13c37ab118e51890e10f5ef559688384ffaba5a485e5a  db/lab/README.md
95a229e658b1fd683b14187619513fcddf90579ccec2947fb317865b3fdeb1d3  docs/verification/LAB-L1-PROOF-RUN-2026-08-16.md
```

Side effects of this verification, recorded: lab runs 15 (unilevel March) and
16 (binary A March) were created on the live project as the determinism
reruns; both write only to schema lab and are ordinary registry rows.

**Verdict: PASS.** Phase L1 closes when the QA gate also passes; the three
MEDIUM amendments belong to mlm-architect and do not block the build gate.
