# Comp Plan Lab Specification, version 1.3

As of 2026-08-16. Written by mlm-architect on Howard's green light of the same day, his
words: "start running different comp plan runs... binary, unilevel and so on and then we
show a dashboard on the different comp plan runs to understand how they are either better
or worse than each other."

**Amendment 2026-08-16, v1.1 (same day, after the v1.0 commit).** Howard's words: "with
the comp plan we will need to be able to build multiple runs so you can track a couple of
accounts and see how they will either make more money or less money over how the downline
does... basically we need to figure out how to have a living report that is able to show
how things work over different runs because we need to add more accounts, remove accounts
and so on through the trees." This adds three capabilities: SCENARIOS (section 9),
WATCHED ACCOUNTS (section 10), and the LIVING REPORT (section 11). It also amends the
plan input (section 1.1: plans now read a DERIVED tree), adds new isolation walls
(section 2.3), re-cuts the phasing (section 7), and appends open questions (section 8).
Sections 3 through 6 are unchanged: every v1.0 number still stands.

**Amendment 2026-08-16, v1.2 (L1 gate results).** The L1 build passed the verifier gate
(`docs\verification\LAB-L1-VERDICT-2026-08-16.md`, PASS, zero findings against the
build) and failed the QA gate on exactly one HIGH owed to this spec
(`docs\qa\LAB-L1-QA-2026-08-16.md`). This amendment settles what both gates put on the
architect: the CALIBRATED binary rates are RULED per strategy in section 4.2,
superseding the draft 0.20; section 6.3's "strategies coincide, spread 0.00" claim is
CORRECTED in place (it was wrong by this spec's own algorithm, caught independently by
the builder, the verifier, and the live run); the extra-root placement rule is RATIFIED
in section 3.2; the interface's fifth defaulted parameter is ratified in section 1.1;
and the census-scale cap behavior is documented in section 4.2. Sections 6.1, 6.2, the
strategy A half of 6.3, and 6.4 are numerically unchanged.

**Amendment 2026-08-16, v1.3 (Phase L2 landed, commit a26ca0d).** Two architect items
out of the L2 build (`docs\verification\LAB-L2-PROOF-RUN-2026-08-16.md`; the verifier's
L2 verdict was not yet committed when this amendment was written, and per the
coordinator the build's interpretations are assumed to hold unless that verdict says
otherwise). One: the CALIBRATION RESIDUE is ruled in section 4.2: the v1.2 rates stand
and the residue is DISPLAYED, never hidden; the rejected iterate-to-cap-aware-parity
option is recorded with the builder's math. Two: the two stairstep areas the builder
implemented from interpreted prose are now stated in exact words in section 4.4 (the
override walk model with its boundary counter, and the differential line columns with
the scoped exception to the section 1.2 rounding invariant), and the builder's staged
hand examples are appended as sections 6.5 and 6.6, discharging the L2 deliverable
"hand example for each appended to this spec".

The lab is a WHAT-IF machine. It takes the same members, the same tree, and the same
month of volume that the real engine reads, runs them through alternative compensation
plans, and puts the results side by side. Nothing the lab produces is ever money, ever a
statement, or ever visible to a member. The real plan is unilevel v1.3
(`docs\COMP-PLAN-SPEC.md`); inside the lab it is simply plan number one of four.

Builders: mlm-db-engineer and mlm-comp-engineer. Grader: mlm-verifier. This spec is
deterministic: two agents implementing it independently must reach identical numbers to
the cent. No production code appears in this document; the SQL object names below are
contracts, not implementations.

Acronym key: Multi-Level Marketing (MLM), Personal Volume (PV), Sales Volume (SV),
Commissionable Volume (CV), Team Volume (TV), Group Volume (GV), Breadth-First Search
(BFS), JavaScript Object Notation (JSON), HyperText Markup Language (HTML), Structured
Query Language (SQL), Quality Assurance (QA), Comma-Separated Values (CSV).

---

## 1. The plan engine interface: four plans, one contract

Every plan in the lab, including the reimplemented unilevel baseline, is one
implementation of a single contract. The contract is what makes the dashboard possible:
if every plan produces the same output shape, every comparison metric is computed once,
by one piece of code, over any plan's output.

### 1.1 What every plan implementation RECEIVES

One call per (plan, month, parameter set). Declared entry point:

```
lab.fn_run_plan(p_period date, p_plan_code text, p_params jsonb,
                p_placement_strategy text,
                p_scenario_code text default 'IDENTITY') returns bigint  -- run id
```

(Amended v1.2, 2026-08-16, ratifying the build's fifth parameter, verifier LOW note 1:
`p_scenario_code` defaults to 'IDENTITY', so every four-argument call behaves exactly
as v1.1 declared, and scenario runs name their scenario explicitly. This is the
signature of record.)

The implementation may read, and only read:

| Input | Source | Snapshot rule |
|---|---|---|
| The member tree | (Amended v1.1, 2026-08-16.) The DERIVED TREE of the run's scenario, section 9: the base census (`app.members`: id, member_code, sponsor_id, enrolled_on) with the scenario's mutation list replayed on top. The base census alone is the IDENTITY scenario (empty mutation list). | Materialized ONCE per lab run: first the derived member set into `lab.derived_members`, then the run-scoped level map over it, exactly the discipline of `app.run_level_map` in `db\comp\001_comp_engine.sql`. Every later step reads the snapshot, never the live tree. |
| The month's volume | `app.orders` and `app.order_lines`, status 'completed', stamped with the volume month, then adjusted by the scenario's volume mutations (v1.1): removed members contribute nothing, added members contribute their volume profile, set_volume overrides apply | SV per member computed once per run with the same query shape as the real engine's `member_sv` step, over the derived member set. |
| Plan parameters | `p_params`, a JSON object | Stored verbatim on the lab run row. A rerun with the same period, plan, parameters, and placement strategy must be byte-identical in results. |
| Derived placement (binary and matrix only) | Computed by the lab from the sponsor tree, section 3 | Materialized per run into `lab.placement_map`; never read from a previous run. |

The lab never reads `app.commission_runs`, `app.commission_lines`, or
`app.run_member_results` as INPUT to a plan. (It may read them for the L1 parity proof,
section 7, which is a comparison, not an input.)

### 1.2 What every plan implementation MUST PRODUCE

Three outputs per run, written only to the `lab` schema (section 2):

**Per-member results**, one row per member, zero-volume members included:

| Column | Meaning |
|---|---|
| run_id, member_id | Keys. |
| sv, cv | Same definitions as the real plan: SV summed per member-month, CV = round half up (0.80 x SV, 2). These two are PLAN-INDEPENDENT and must be identical across all four plans for the same month; the verifier checks this equality first. |
| qualified | SV >= 100.00, plan-independent in v1 of the lab. |
| rank_label | Free text per plan ('leader', 'bracket_15pct', 'binary_earner'); the plan's own vocabulary. |
| plan_metrics | JSON: whatever the plan's shape needs (TV for unilevel, left-leg and right-leg CV for binary, GV and bracket for stairstep). Named keys are listed per plan in section 4. |
| total_earned | Sum of the member's rounded lines, never re-rounded. |

**Commission lines**, one row per payment, each carrying its reason:

| Column | Meaning |
|---|---|
| run_id, earner_id | Keys. |
| source_member_id | Nullable: null for aggregate-basis pay (binary pay-leg, stairstep differential), set for per-source pay (unilevel, matrix, overrides). |
| level | Nullable: tree distance for level pay, null for aggregate pay. |
| basis | The amount the rate was applied to (source CV, pay-leg CV, group CV differential basis). |
| rate, amount | amount = round half up (rate x basis, 2), rounded AT THE LINE, exactly the real engine's rule. (Scoped in v1.3: this identity holds for every reason code EXCEPT 'stairstep_differential', which is arithmetically incapable of it; its exact column semantics and the recomputation path are defined in section 4.4.) |
| reason | Not null, machine-readable: 'unilevel_level_pay', 'binary_pay_leg', 'matrix_level_pay', 'stairstep_differential', 'stairstep_override_gen1', 'stairstep_override_gen2'. Every dollar must be explainable by its own row. |

**Company totals** on the lab run row: total_sv, total_cv, total_payout, members_paid
(count with total_earned > 0), all sums of already-rounded values, never re-rounded.

### 1.3 Contract invariants (the verifier's checklist)

1. Deterministic: same period + plan + params + placement strategy = identical output to
   the cent, row order included (stable ORDER BY on every bulk insert, per the engine).
2. Rounding happens exactly twice: once at CV, once per line. Totals are sums.
3. All math in `numeric`, never float.
4. SV, CV, and the qualified flag are identical across plans for the same month.
5. Every line has a reason; every member has a result row.

---

## 2. Sandbox isolation: the non-negotiable

A lab run may NEVER touch, supersede, or sit beside a real finalized run in any
member-visible surface. Two mechanisms were considered; the first is chosen.

### 2.1 Chosen: a separate schema, `lab`

All lab tables live in a new Postgres schema `lab`: `lab.plan_runs`,
`lab.plan_run_results`, `lab.plan_run_lines`, `lab.placement_map`. Nothing lab-related
is ever written into schema `app`.

The argument, grounded in how the member-visible surface is actually sealed today:

1. **The demo views' grant is schema-wide.** Migration
   `db\migrations\003_row_level_security.sql` line 57 runs
   `grant select on all tables in schema app to app_demo_reader`, and the five public
   `v_demo_*` views are DEFINER views owned by that role
   (`db\migrations\005_demo_views.sql`). Any lab table placed inside schema `app` would
   be born readable by the exact role that powers the public site. One future view, one
   forgotten filter, and what-if numbers are on orvanna.io. A separate schema receives
   ZERO grants: no `usage` on schema `lab` for `app_demo_reader`, `anon`, or
   `authenticated`, so the definer role cannot see lab rows even by accident.
2. **The rejected alternative, a run-kind column on `app.commission_runs`, fails on
   count of filters.** It would require kind-awareness in: the partial unique index
   `commission_runs_one_final_per_period_idx` (one FINAL run per period must mean one
   REAL final run), `app.fn_finalize_run`'s supersede logic (a lab run must never
   supersede a real run), the immutability triggers of migration 006, all four
   run-reading demo views, migration 021's finalized-period refusal trigger, and every
   future query anyone writes. Each is one WHERE clause somebody must remember forever.
   A schema boundary is one wall nobody has to remember.
3. **Statuses cannot collide.** `lab.plan_runs.status` permits only
   ('running', 'complete', 'archived'). The value 'final' does not exist in the lab, by
   CHECK constraint, so no query that means "the real money" can ever match a lab row
   even if someone joins across schemas.
4. **The real engine is untouched.** `app.fn_run_commission`, `app.fn_finalize_run`, the
   checksummed finalized runs (decision record 2026-08-16), and the bridge all remain
   byte-identical. The lab is additive: one new schema, new functions under it.

Hard rules, enforceable and to be enforced structurally:

- No foreign key from any `app` table to any `lab` table (nothing real may depend on the
  lab). (Amended v1.1: lab result tables reference `lab.derived_members`, not
  `app.members` directly, because scenarios introduce synthetic members that must never
  require a row in `app.members`; `lab.derived_members` itself carries a nullable
  reference to `app.members(id)` that is set for census members and null for synthetic
  ones.)
- No lab function writes to schema `app`. The lab functions are created by a migration
  the verifier reads; "no INSERT/UPDATE/DELETE targeting app.*" is a grader check.
- The member portal (`site\js\app.js`) and the public site read only `v_demo_*` views;
  those views are not modified by this project. Zero surface change.
- Dashboard consumption is by EXPORTED files only (section 5), never a live connection.

### 2.2 What "what-if" means on a label

Every lab artifact carries the tag. `lab.plan_runs` has a generated, non-nullable column
`disclaimer` defaulting to 'WHAT-IF RUN: not a statement, pays nobody', the exported
JSON carries the same string at the top level, and the dashboard page prints it in the
header. Binary and matrix results additionally carry the DERIVED-placement label of
section 3.4.

### 2.3 New walls for scenarios (added v1.1, 2026-08-16)

Scenarios create members that do not exist. Three walls keep them from ever looking
like they do:

1. **Synthetic members live only in `lab.derived_members`.** No code path inserts a
   scenario-created member into `app.members`, ever. The grader check of section 2.1
   ("no writes to app") already covers this; it is restated because this is the wall a
   hurried implementer would breach first.
2. **The name wall.** Every synthetic member's member_code carries the mandatory prefix
   'LAB-', enforced by CHECK constraint on `lab.derived_members` for rows with no
   `app.members` reference. Real accounts are 'GW-' codes; no export, screenshot, or
   grid can ever show a synthetic account that reads like a real one.
3. **Scenario runs of REAL months stay what-if.** A scenario replayed over August's real
   bridged volume is a counterfactual ("what August would have paid if..."), and it
   inherits every existing wall: lab schema, no 'final' status, disclaimer column, export
   only. The dashboard labels such runs 'counterfactual on real volume' so nobody reads
   a mutated August as the August that happened.

---

## 3. The binary placement problem, honestly

### 3.1 The problem

Binary pays on a two-leg PLACEMENT tree. Orvanna has never had one: `app.members` stores
a SPONSOR genealogy where a member may have any number of frontline members (M1 in the
worked example has three). A binary result on our data is therefore always computed on a
placement tree the lab DERIVED, and a different derivation gives different payouts. The
lab's answer is not to hide this: it runs at least two derivations and shows the spread.

### 3.2 Placement strategy A: 'bfs_spill' (sponsor-preference breadth-first fill)

Deterministic algorithm, processing members in ascending member id order (seed ids
ascend with enrollment; ties cannot occur on a primary key), root first, sponsor always
processed before its members by construction:

1. The root of the placement tree is the root of the sponsor tree. (Amended v1.2,
   2026-08-16, ratifying the build's rule after verifier ruling 3c: the census carries
   TWO rootless members, GW-000001 the seed root and GW-000 the house account of
   migration 020, and v1.1's "the root", singular, was ambiguous. RULE: the LOWEST-ID
   rootless member anchors the placement tree, and every other rootless member is
   placed as if sponsored by it, through the ordinary steps below. This is
   deterministic and preserves the one-connected-tree assumption every plan relies on.
   Its money-effect is zero BY CONSTRUCTION, not by coincidence: migration 020's
   guard triggers keep all house volume in `app.house_retained_volume` and out of
   `app.orders`, and the lab's volume snapshot reads only `app.orders`, so GW-000
   carries SV 0.00 into every leg it joins and can never earn or pay a cent. The
   ratification is therefore permanent: the structure that makes the rule harmless is
   the same structure decision 4.7 already made "never paid" mean. If that wall ever
   moved, migration 020's own triggers would have to be dismantled first, which is a
   Howard decision, not a drift. The rule applies identically to derived trees under
   scenarios, section 9.)
2. For each subsequent member m with sponsor s: if s has an open left slot, place m at
   s.left; else if s has an open right slot, place m at s.right.
3. Otherwise SPILLOVER: scan s's placement subtree in BFS order (level by level, within
   a level left subtree before right subtree, within a node left slot before right
   slot) and place m in the first open slot found.

Every step is a total order, so the result is unique. Spillover is real binary behavior:
volume from your sponsor's later enrollees lands under you.

### 3.3 Placement strategy B: 'volume_balanced' (weaker-leg by month volume)

Same processing order. For member m with sponsor s: starting at s, repeatedly descend
into the leg whose CURRENT placed members have the smaller sum of the run month's SV
(ties: left), until an open slot is reached; place m there. Weights use the month's SV
of already-placed members only, so the walk is deterministic given the processing order.
This models an operator placing enrollees to balance legs, the behavior real binary
fields exhibit.

### 3.4 The sensitivity, named and quantified

Strategies A and B produce DIFFERENT trees and DIFFERENT payouts from the same data. On
the canonical ten-member month (spec section 7) at the draft parameters of section 4.2,
strategy A pays 184.00 company-wide and strategy B pays 168.00, an 8.7 percent relative
spread, with M2 and M3 swapping fortunes (A: M2 40.00, M3 24.00; B: M2 24.00, M3 40.00;
derivations in section 6.4). Therefore:

- Every binary (and matrix) run row and export records its placement strategy.
- The dashboard never shows a binary number without its strategy label and the fixed
  caption: "computed on a DERIVED placement; a different derivation gives different
  payouts", plus the A-versus-B spread for that month.
- The lab launch requirement is BOTH strategies run for every binary month.

---

## 4. The four launch plans, with exact draft parameters

Common gates for all four (held fixed so comparisons are about SHAPE): qualification is
SV >= 100.00, sources pay regardless of their own qualification, no compression, line
rounding per section 1.3. Parameter values below are drafts; they live in `p_params`
and are recorded per run, so changing them is a new run, never an edit.

### 4.1 Plan 'unilevel_v13' (the baseline, as-is)

Exactly `docs\COMP-PLAN-SPEC.md` v1.3, reimplemented through the lab interface: rates
10/5/5/3/2 percent of source CV at levels 1 to 5, ranks Member/Builder/Leader/Director/
Executive with paid depths 1 to 5, TV excludes self, active legs, containment ranks.
Parameters JSON: `{"rates": [0.10, 0.05, 0.05, 0.03, 0.02]}` plus the rank table. Its
parity proof against the real engine is the L1 gate (section 7).

### 4.2 Plan 'binary' (draft)

| Parameter | Draft value | Meaning |
|---|---|---|
| pay_leg_rate | RULED v1.2, 2026-08-16, superseding the draft 0.20: **0.105 under 'bfs_spill' and 0.110 under 'volume_balanced'**, per strategy (see "The calibration ruled" below). The FIXTURE examples of section 6 and the L1 fixture proof runs remain computed at the draft 0.20, correctly: every run records its rate in plan_params, and a hand example at 20 percent is easier arithmetic teaching the same shape. Census-scale comparison runs use the ruled rates. | Rate applied to the pay leg CV. |
| pay_leg | weaker leg | Pay leg = the leg with the SMALLER total CV this month (ties: left leg is the pay leg). |
| carryover | flush | Unmatched CV in the stronger leg is DISCARDED at month end. No carry ledger in lab v1; 'carry' with a per-leg ledger and a 3-month expiry is defined as an L2-plus option but not launched, because carryover makes months non-independent and the lab runs months independently. |
| cap_per_member | 2,500.00 per month | A member's binary earnings line is capped after rounding; the capped remainder is recorded as breakage. |
| earner gate | qualified (SV >= 100.00) | Same gate as the baseline. |
| empty leg | pays zero | min(left CV, right CV) with an empty leg is 0; no line is written (mirrors the engine's no-zero-lines decision c). |

One line per earner per month, reason 'binary_pay_leg', basis = pay-leg CV,
amount = round(0.20 x basis, 2), then capped.

**Targeting hand math, and its honest limit.** The baseline's structural ceiling is
10 + 5 + 5 + 3 + 2 = 25 percent of CV. Binary has NO per-source ceiling: one member's CV
sits in the pay leg of possibly several ancestors, so binary payout GROWS with tree
depth, which is exactly why real binaries carry caps and flush. On the shallow
ten-member tree, 20 percent pays 184.00 = 8.52 percent of CV against the baseline's
264.00 = 12.22 percent of CV (hand math in section 6.4), so 20 percent UNDERSHOOTS on a
shallow tree and will land higher on the seeded 1,000-member tree, whose depth is
realistic. The deterministic calibration rule, applied once at the L1 gate: run March
2026 (the first full seeded month) under both plans, then set
pay_leg_rate* = 0.20 x (unilevel percent of CV / binary percent of CV), rounded to the
nearest 0.005, recorded in the run parameters and in this spec by amendment the same
day. Size is calibrated so the dashboard can talk about shape.

**The calibration ruled (v1.2, 2026-08-16, closing QA HIGH-1).** The L1 build ran the
rule on seeded March 2026 and the verifier independently recomputed every figure:
unilevel 13,434.00 / 91,960.00 = 14.6085 percent of CV; binary at the draft 0.20 paid
28.0383 percent of CV under 'bfs_spill' and 27.0074 percent under 'volume_balanced'.
The rule as written produces a different rate per strategy (0.20 x 14.6085 / 28.0383 =
0.1042, nearest 0.005 = 0.105; 0.20 x 14.6085 / 27.0074 = 0.1082, nearest 0.005 =
0.110), and v1.1 never said which strategy anchors. RULED: **PER-STRATEGY RATES.
pay_leg_rate = 0.105 under 'bfs_spill' and 0.110 under 'volume_balanced'.** Reasoning:
the calibration exists so that size is held equal and every visible difference is
shape (this section's own closing sentence), and the placement strategy is part of the
run's recipe, not part of the plan's identity; anchoring one rate on strategy A would
leave every strategy B total about one point of CV oversized, a residue of the
derivation, and the dashboard would then show a size difference that is calibration
noise, not placement information. The placement sensitivity that section 3.4 exists to
show is not erased by equalizing totals: it lives in WHO gets paid (M2 and M3 trading
places, per-member deltas, leg compositions), and those comparisons are cleaner, not
weaker, when both strategies pay the same total. The rejected alternative (one rate
anchored on A, B reported at the same rate carrying its own percent) is recorded here
so the choice is auditable.

**The cap binds on real data (v1.2, documenting verifier LOW note 3).** In the March
2026 census run at the draft 0.20 rate, two binary lines hit the 2,500.00 per-member
cap, and the capped remainders are breakage per this section. The cap is therefore a
live parameter at census scale, not decoration; dashboard breakage figures for binary
must include capped remainders, and any rate change re-tests where the cap starts
binding.

**The calibration residue ruled (v1.3, 2026-08-16).** The L2 build ran the ruled rates
on seeded March and proved they do NOT land size parity: binary pays 16.4522 percent of
CV under 'bfs_spill' at 0.105 and 17.4898 percent under 'volume_balanced' at 0.110,
against the baseline's 14.6085, a residue of 1.8 to 2.9 points. The cause is proven to
the cent in the L2 proof run: the calibration rule is LINEAR (the rate scales every
line proportionally) but the percents it divided were CAPPED totals and the cap is
non-linear; at 0.20 the cap withheld 5,600.00, at 0.105 only 1,347.20, so payout
shrinks slower than the rate (verification: run 28's uncapped total 16,476.60 equals
0.525 times the uncapped 0.20 total 31,384.00, exactly).

RULED: **ACCEPT THE RESIDUE AND DISPLAY IT. The v1.2 rates 0.105 and 0.110 stand
unchanged.** Display rule, binding on the dashboard: every binary card, cell, and
cross-plan comparison shows that run's ACTUAL percent of CV beside the baseline's
percent, always, so the size difference is visible information rather than a hidden
assumption; the phrase "size held equal" must not appear on any lab surface, and the
caption reads "size approximately held; residue shown". Reasoning: the cap's binding
SET depends on the rate (which legs cap changes as the rate moves), so cap-aware
parity is a fixed-point chase, and worse, it was anchored on March alone: a rate
solved to the cent for March (the builder's estimate, one whale line capped,
payout(r) = 120,280 x r + 2,500.00, r of about 0.0909, nearest 0.005 = 0.090) buys
parity for exactly one month and would still leave residue in February, April through
July, and August. Size-parity to the cent across months with one rate never existed to
be had; and tuning the rate against capped totals would launder the cap, which is a
SHAPE feature of binary (it truncates top earners and shows up in the concentration
metrics), into a size dial. Coarse calibration plus honest display keeps the shape
story clean. The rejected option (iterate to cap-aware per-strategy rates, near 0.090
for 'bfs_spill') is recorded here so the choice is auditable; it remains available
later if Howard ever wants single-month parity for a specific exhibit, as a new run
with its rate in plan_params, never a respec.

### 4.3 Plan 'matrix_3x7' (draft)

| Parameter | Draft value | Meaning |
|---|---|---|
| width | 3 | At most 3 placement-tree children per member. |
| depth | 7 | Pay levels 1 to 7 of the PLACEMENT tree. |
| rates | 5, 5, 4, 4, 3, 2, 2 percent | Of source CV by placement level. |
| placement | strategies A and B of section 3, generalized to width 3 | Same algorithms with 3 slots per node; slot order left-to-right; both strategies run. |
| earner gate | qualified; paid depth flat 7 | No rank ladder in the lab matrix: the width constraint IS the plan's shape, and holding gates minimal isolates it. Recorded as open question 5. |

**Targeting hand math.** 5 + 5 + 4 + 4 + 3 + 2 + 2 = 25 percent of CV, the identical
structural ceiling to the baseline's 25 percent of CV. Same size by construction; the
difference the dashboard will show is WHERE the money lands (matrix pushes pay deeper
and spreads it flatter; spillover past width 3 feeds depth).

### 4.4 Plan 'stairstep_breakaway' (draft)

Runs on the real SPONSOR tree (no derived placement). GV = own SV plus the SV of the
member's whole sponsor subtree EXCLUDING breakaway groups.

| Parameter | Draft value |
|---|---|
| Brackets (on GV, inclusive lower bounds) | 0 to 999.99: 5 percent; 1,000.00 to 4,999.99: 10 percent; 5,000.00 to 14,999.99: 15 percent; 15,000.00 and up: 20 percent |
| Breakaway threshold | A member whose own GV >= 15,000.00 is a BREAKAWAY; their whole group leaves every upline member's GV that month. Monthly-pure, like ranks. |
| Generation override | 4 percent of a breakaway group's total CV at generation 1, 2 percent at generation 2, assigned by the BOUNDARY-COUNTER WALK stated exactly below (v1.3). |
| Differential pay | One line per earner, reason 'stairstep_differential', with the exact column semantics stated below (v1.3), superseding v1.1's undefined "basis = the signed net basis". |
| Earner gate | qualified (SV >= 100.00); an unqualified member's differential is breakage (their downline's brackets still subtract normally). |

Negative differentials cannot occur: a parent's GV includes every non-breakaway child
group, so parent GV >= child GV, brackets are monotone in GV, and breakaway removes
exactly the groups that would out-bracket the parent.

**The two models in exact words (v1.3, 2026-08-16).** The L2 build implemented both of
the following from interpreted prose, fixture-pinned them, and flagged them; they are
now spec text, so they stop being interpretation.

**Model one, the override walk (boundary counter).** For EACH breakaway member B,
independently: walk the sponsor chain upward from B toward the root, carrying a
boundary counter that starts at 0 and increments each time the walk passes another
breakaway member. The first QUALIFIED member encountered while the counter is 0
receives the generation 1 override, 0.04 x (B's group CV); the first qualified member
encountered while the counter is 1 receives the generation 2 override, 0.02 x (B's
group CV); the walk stops when the counter reaches 2, or at the root. Consequences
that are now normative: a generation 2 payment for B exists exactly when another
breakaway sits between B and its generation 2 recipient, which is the precise meaning
of v1.1's parenthetical "a breakaway found under a breakaway"; an unqualified member
is passed over without incrementing the counter (only breakaways are boundaries); and
one member may collect different generations from different breakaways in the same
month (in the section 6.6 chain, S3 takes generation 1 on S4's group AND generation 2
on S6's group). Override lines are per-source (source = the breakaway member), so
amount = round(rate x basis, 2) holds for both override reason codes.

**Model two, the differential line columns.** A differential is a difference of
bracket products, so no single rate-times-basis product can reproduce it whenever any
child group's bracket differs from the earner's. The columns of a
'stairstep_differential' line are therefore defined as: rate = the EARNER's bracket
rate; basis = the earner's own CV plus their non-breakaway group CV; amount = the
once-rounded differential, round(rate x basis minus the sum over each direct child
group of (that child group's bracket rate x that group's CV, own CV included), 2).
The identity amount = round(rate x basis, 2) does NOT hold for this one reason code
(section 1.2 carries the scoped exception), and the recomputation path is normative:
plan_metrics carries gv, bracket, breakaway flag, and group_cv for every member, and
the verifier must be able to rebuild every differential amount from plan_metrics
alone. This supersedes v1.1's "basis = the signed net basis", which named a column it
never defined.

**Targeting hand math.** Worst-case ceiling = top bracket 20 percent of CV plus a full
two-generation override chain 4 + 2 = 26 percent of CV, only when stacked breakaways
exist; with no breakaway in the month the ceiling is 20 percent of CV. Bracketed
against the baseline's 25 percent of CV: same size class, different shape (stairstep
concentrates pay in the highest brackets, which the concentration metrics in section 5
are built to expose).

---

## 5. The dashboard

One page, self-contained HTML like every dashboard in this project: inline styles and
script, no external requests, fed by an exported JSON file embedded at build time by
`lab\build_dashboard.py` reading the `lab` schema with the service role. The page never
holds database credentials; a rebuild is a rerun of the build script. Proposed paths:
`MLM-PILOT\lab\build_dashboard.py` and `MLM-PILOT\lab\comp-lab-dashboard.html`.

Every metric below is defined precisely enough for mlm-verifier to recompute from the
exported run rows. n = ALL members in the run (zero earners included), x_i = member i's
total_earned.

| Metric | Definition |
|---|---|
| Total payout percent of CV | total_payout / total_cv x 100, 2 decimals. Also shown per revenue: total_payout / total_sv x 100. |
| Payout by depth | Sum of line amounts grouped by line level (null level shown as its reason group, e.g. 'pay leg', 'differential'), as amount and as percent of total_payout. |
| Payout by rank band | Sum of member totals grouped by rank_label, per plan's own labels. |
| Earner concentration | Sort earners by total_earned descending, ties by member id ascending. Top 1 percent share = sum of the top ceil(0.01 x n) members' earnings / total_payout. Top 10 percent share = same with ceil(0.10 x n). |
| Gini-style index | Sort ALL n members ascending by total_earned, ties by member id. G = (2 x sum over i of (i x x_i)) / (n x sum of x_i) minus (n + 1) / n, with i = 1..n. If total payout is 0, G = 0 by definition. Range 0 (perfect equality) to near 1 (one earner takes all). |
| Members earning anything | Count with total_earned > 0, and as percent of n. |
| Breakage | Per plan, all recomputable from lines and results: UNILEVEL and MATRIX: reachable ceiling minus paid, where reachable = sum over sources of rate x source CV over only the ancestor levels that EXIST above that source (the spec section 7.4 decomposition: structural ceiling = no-upline-exists + breakage + paid); BINARY: (rate x pay-leg CV summed over members with two non-empty legs) minus paid, plus capped remainders, with flushed strong-leg value (rate x (strong minus pay leg)) reported separately and labeled 'unmatched, not breakage'; STAIRSTEP: (0.20 x total CV) minus paid, labeled 'differential retained by company'. |
| Per-member deltas | One row per member per plan pair: earnings under each plan, delta, delta percent, rank under each. Rendered as an OPEN grid: every row, every column, sortable by clicking any header, no baked-in filters. Howard filters in the grid (his standing preference: build queries open). Default sort: delta descending, so who wins leads and who loses closes. |

Per-plan cards across the top (payout percent, earners, Gini, top-10 share), the
comparison table in the middle, the open per-member grid at the bottom. Binary and
matrix cards carry the derived-placement caption and the A-versus-B spread from section
3.4. The what-if disclaimer of section 2.2 sits in the page header.

---

## 6. Worked example, hand-computed: the five-member mini tree

The comp plan booklet carries no five-member tree, so the lab's contract example is
defined HERE as the named truncation of the canonical ten-member tree of
COMP-PLAN-SPEC.md section 7: keep M1, M2, M3, M4, M5 with their exact section 7
subscriptions and volumes; drop M6 through M10. Sponsor tree: M1 -> M2, M3, M4 and
M2 -> M5. This is the acceptance example for L1: the lab's unilevel and binary
implementations must reproduce every number below to the cent, and mlm-verifier
recomputes it independently.

### 6.1 Volumes and qualification (identical under every plan)

| Member | SV | CV = round(0.80 x SV, 2) | Qualified (SV >= 100.00)? |
|---|---|---|---|
| M1 | 200.00 | 160.00 | yes |
| M2 | 150.00 | 120.00 | yes |
| M3 | 100.00 | 80.00 | yes (boundary) |
| M4 | 100.00 | 80.00 | yes (boundary) |
| M5 | 50.00 | 40.00 | NO |

Totals: SV 600.00... check: 200 + 150 + 100 + 100 + 50 = 600.00. CV: 160 + 120 + 80 +
80 + 40 = 480.00, and 0.80 x 600.00 = 480.00 agrees.

### 6.2 Baseline unilevel v1.3 on the mini tree

TV: M1 = 150 + 100 + 100 + 50 = 400.00; M2 = 50.00; M3, M4, M5 = 0.00.

Ranks: M1 is qualified with active legs M2, M3, M4 (all three qualified) = 3 active
legs; Leader needs TV >= 2,500.00 and M1 has 400.00, so M1 is a BUILDER (qualified, >= 2
active legs), paid depth 2. M2 is qualified but its only leg's frontline M5 is
unqualified: 0 active legs, Member, depth 1. M3, M4: no legs, Member. M5: unqualified,
Member, earns nothing.

Every line in the run:

| Earner | Source | Level | Source CV | Rate | Arithmetic | Amount |
|---|---|---|---|---|---|---|
| M1 | M2 | 1 | 120.00 | 10% | 0.10 x 120.00 | 12.00 |
| M1 | M3 | 1 | 80.00 | 10% | 0.10 x 80.00 | 8.00 |
| M1 | M4 | 1 | 80.00 | 10% | 0.10 x 80.00 | 8.00 |
| M1 | M5 | 2 | 40.00 | 5% | 0.05 x 40.00 | 2.00 |
| M2 | M5 | 1 | 40.00 | 10% | 0.10 x 40.00 | 4.00 |

Totals: M1 = 12.00 + 8.00 + 8.00 + 2.00 = 30.00. M2 = 4.00. Company = 34.00, which is
34.00 / 480.00 = 7.08 percent of CV.

### 6.3 Binary (draft parameters, strategy A) on the mini tree

Placement derivation, ascending id order M2, M3, M4, M5:

1. M2: sponsor M1, left slot open, place at M1.left.
2. M3: sponsor M1, left taken, right open, place at M1.right.
3. M4: sponsor M1, BOTH slots full. SPILLOVER: BFS scan of M1's subtree finds M2.left
   open first, place M4 at M2.left. M4 now sits under M2, whom M4's sponsor did not
   choose: this is the spillover event the contrast below turns on.
4. M5: sponsor M2, left taken (M4), right open, place at M2.right.

Placement tree: M1(left: M2(left: M4, right: M5), right: M3).

**CORRECTION, v1.2, 2026-08-16 (verifier finding F1, MEDIUM, against this spec).** The
v1.0 and v1.1 text of this paragraph claimed strategy B ('volume_balanced') coincides
with strategy A on this tree, spread 0.00. That claim was WRONG by this spec's own
section 3.3 algorithm, and it was caught three ways independently: the builder flagged
it, the verifier hand-derived the true result, and live lab run 6 computed it. The
original claim is preserved here as the error it was; the correct derivation follows.

Strategy B on the mini tree, by the section 3.3 algorithm, ascending id order: M2 lands
at M1.left (both legs empty, tie goes left). M3: M1's left leg already weighs SV 150.00
(M2) against the right leg's 0, so descend right: M3 at M1.right. M4: sponsor M1, legs
weigh 150.00 (left) against 100.00 (right), descend into the WEAKER right leg to M3,
whose legs are both empty, tie left: M4 at M3.left, NOT spilled under M2 as in strategy
A. M5: sponsor M2, both legs empty: M5 at M2.left.

Placement tree B: M1(left: M2(left: M5), right: M3(left: M4)). Legs of M1: left
{M2, M5} = 120.00 + 40.00 = 160.00, right {M3, M4} = 80.00 + 80.00 = 160.00, a TIE,
and ties make the LEFT leg the pay leg (section 4.2): M1 alone earns
round(0.20 x 160.00, 2) = 32.00. M2 and M3 each have an empty right leg: no lines.
Company under B = 32.00, one member paid, spread A minus B = 24.00 minus 32.00 =
**-8.00**, not 0.00. The mini tree is thus ALSO a sensitivity example, and a sharper
one than 6.4: under A the payout is split two ways and totals 24.00; under B one
balanced pair of legs pays one member 32.00 and everyone else nothing.

Leg CVs and pay, rate 20 percent of the weaker leg, earner must be qualified:

| Earner | Left leg members | Left CV | Right leg members | Right CV | Pay leg CV | Amount = round(0.20 x pay leg, 2) |
|---|---|---|---|---|---|---|
| M1 | M2, M4, M5 | 120 + 80 + 40 = 240.00 | M3 | 80.00 | 80.00 | 16.00 |
| M2 | M4 | 80.00 | M5 | 40.00 | 40.00 | 8.00 |
| M3 | none | 0.00 | none | 0.00 | 0.00 | no line |
| M4 | none | 0.00 | none | 0.00 | 0.00 | no line |
| M5 | unqualified, and both legs empty | | | | | no line |

Company binary payout = 16.00 + 8.00 = 24.00 = 5.00 percent of CV. No cap fires (both
amounts are far under 2,500.00). Flushed unmatched CV: M1's stronger leg exceeds its pay
leg by 240.00 minus 80.00 = 160.00, M2's by 40.00; flushed value at the rate =
0.20 x 200.00 = 40.00, reported as 'unmatched, not breakage'.

**The contrast that is the entire product:**

| Member | Unilevel v1.3 | Binary (draft, strategy A) | Delta | Why |
|---|---|---|---|---|
| M2 | 4.00 | 8.00 | +4.00, DOUBLES | Spillover handed M2 a leg it never sponsored: M4's 80.00 of CV became M2's pay leg. Binary rewards receiving depth. |
| M1 | 30.00 | 16.00 | -14.00, loses nearly half | M1's three-wide frontline is unilevel's best shape and binary's worst: two of the three legs collapse into one placement leg, and the strong leg's surplus is flushed. Binary punishes width. |

Same members, same month, same money in the door: 34.00 paid one way, 24.00 the other,
and the winners change places. That is what the dashboard exists to show.

### 6.4 Targeting and sensitivity check on the full ten-member month (reference)

On the unmodified section 7 tree (M1 through M10), strategy A places M4 at M2.left, M6
at M4.left (both spillover), M5 at M2.right, M7 at M3.left, M8 at M3.right, M9 at
M5.left, M10 at M8.left. Leg CVs: M1 min(600.00, 1400.00) = 600.00 -> 120.00; M2
min(200.00, 280.00) = 200.00 -> 40.00; M3 min(1200.00, 120.00) = 120.00 -> 24.00; all
others have an empty leg or are unqualified. Company = 184.00 = 8.52 percent of CV,
against the baseline's 264.00 = 12.22 percent of CV: the 20 percent draft undershoots on
a shallow tree, which is why the calibration rule of section 4.2 runs on the seeded
1,000-member March. Strategy B on the same month places M4 at M3.left instead (M1's
right leg carried less volume at that step) and pays M1 104.00, M2 24.00, M3 40.00,
company 168.00: an A-to-B spread of 16.00 with M2 and M3 trading places, which is the
sensitivity of section 3.4 made concrete.

### 6.5 Matrix worked examples (added v1.3, 2026-08-16, from the L2 build's staged derivation in `db\lab\108_proof_matrix_fixtures.sql`, recomputed by hand by the architect before adoption)

Parameters per section 4.3: width 3, depth 7, rates 5/5/4/4/3/2/2 percent of source CV
by placement level, qualified-earner gate, flat depth.

**Mini tree.** Placement under BOTH strategies is identical to the sponsor tree: M1's
three frontline members fill M1's three slots and M5 lands in M2's first slot, so no
placement step ever needs spillover or a non-trivial weigh-in; spread 0.00, and here
it is PROVABLE, unlike the corrected binary claim of 6.3. Lines: M1 on M2 at level 1 =
0.05 x 120.00 = 6.00, on M3 = 4.00, on M4 = 4.00, on M5 at level 2 = 0.05 x 40.00 =
2.00; M2 on M5 at level 1 = 2.00. Company = 18.00 (M1 16.00, M2 2.00) = 3.75 percent
of CV 480.00. Against unilevel's 34.00 on the same tree, the whole story is the front
line: matrix's flat 5 percent versus unilevel's 10 percent.

**Ten-member tree.** Placement again equals the sponsor tree under both strategies (no
member has more than three frontline members); spread 0.00. Lines: M1 level 1 on M2
6.00, M3 4.00, M4 4.00; level 2 on M5 2.00, M6 6.00, M7 60.00, M8 4.00; level 3 at 4
percent on M9 9.60, M10 1.60; M1 total 97.20. M2 on M5 2.00, M6 6.00, M9 (level 2)
12.00 = 20.00. M3 on M7 60.00, M8 4.00, M10 (level 2) 2.00 = 66.00. M8 on M10 2.00.
M5 is unqualified: its level 1 claim on M9 (12.00) is breakage. Company = 185.20 =
8.5741 percent of CV 2,160.00 (unilevel 264.00, binary A at the draft rate 184.00).
Flat depth 7 changes nothing here because the tree is only three levels deep; the
losses versus unilevel are pure rate shape.

### 6.6 Stairstep worked examples (added v1.3, 2026-08-16, from `db\lab\109_proof_stairstep_fixtures.sql`, recomputed by hand by the architect before adoption)

Parameters per section 4.4: brackets 5/10/15/20 percent at GV 0 / 1,000 / 5,000 /
15,000, breakaway at 15,000, overrides 4 and 2 percent.

**Mini tree.** GVs: M1 600.00, M2 200.00, M3 100.00, M4 100.00, M5 50.00. Everybody
sits in the 5 percent bracket, so every differential collapses: M1 = 0.05 x 480.00
minus (0.05 x 160.00 + 0.05 x 80.00 + 0.05 x 80.00) = 24.00 minus 16.00 = 8.00; M2 =
0.05 x 160.00 minus 0.05 x 40.00 = 6.00; M3 = 4.00; M4 = 4.00; M5 is unqualified, its
2.00 is breakage. Company = 22.00 = 4.5833 percent of CV 480.00, no breakaways, no
overrides. On a shallow low-volume tree stairstep is the stingiest of the four plans
(unilevel 34.00, binary A 24.00, stairstep 22.00, matrix 18.00): everyone is stuck in
the bottom bracket and differentials cancel to 5 percent of own CV.

**The breakaway chain (fixture PROOF-STAIR, built to exercise every stairstep reason
code including generation 2).** Sponsor chain S1 -> S2 -> S3 -> S4 -> S5 -> S6, plus
S7 under S2. SV: S1 200, S2 100, S3 500, S4 10,000, S5 5,000, S6 15,000, S7 50.
Bottom-up: S6 GV 15,000.00, BREAKAWAY, bracket 20. S5 GV 5,000.00 (S6's group left),
bracket 15. S4 GV 10,000 + 5,000 = 15,000.00, BREAKAWAY, bracket 20. S3 GV 500.00
(S4's group left), bracket 5. S7 GV 50.00, unqualified. S2 GV 650.00, S1 GV 850.00,
both bracket 5. Differentials: S6 = 0.20 x 12,000.00 = 2,400.00; S5 = 0.15 x 4,000.00
= 600.00; S4 = 0.20 x 12,000.00 minus 0.15 x 4,000.00 = 1,800.00; S3 = 0.05 x 400.00
= 20.00; S2 = 0.05 x 520.00 minus (0.05 x 400.00 + 0.05 x 40.00) = 4.00; S1 = 0.05 x
680.00 minus 0.05 x 520.00 = 8.00; S7's 2.00 is breakage; no negative differential
anywhere, the monotonicity assertion holding on a fixture built to stress it.
Overrides by the section 4.4 walk: S6's group CV 12,000.00 pays generation 1 to S5
(first qualified, zero boundaries) = 480.00, then the walk passes breakaway S4
(counter to 1) and S3 takes generation 2 = 240.00; S4's group CV 12,000.00 pays
generation 1 to S3 = 480.00, and no breakaway sits above S4, so its generation 2 does
not exist, which is the walk model's defining clause in action. S3 thus collects a
generation 1 AND a generation 2 in one month, from different breakaways. Totals: S1
8.00, S2 4.00, S3 740.00, S4 1,800.00, S5 1,080.00, S6 2,400.00, S7 0.00. Company =
6,032.00 = 24.4409 percent of CV 24,680.00, six members paid, under the 26 percent
stacked-breakaway ceiling of section 4.4.

---

## 7. Phasing, each level closed by two gates (re-cut in v1.1, 2026-08-16)

Project convention: a level is CLOSED only when BOTH the mlm-verifier verdict and the QA
gate are PASS. Builder self-report closes nothing.

**Why the re-cut instead of a bolted-on L4 for everything.** Scenarios change the
INTERFACE INPUT: section 1.1 now says every plan reads a derived tree, not `app.members`
directly. If L1 were built reading the census raw and scenarios arrived later, the input
path of every plan would be rebuilt, which is exactly the rework a spec exists to
prevent. So the derivation LAYER arrives in L1, carrying only the IDENTITY scenario
(empty mutation list), which costs one extra equality proof and nothing else. The
mutation kinds, the watchlist, and the report are then pure additions on a stable input
path. The report goes last because it renders whatever exists and nothing depends on
it; scenarios go before it because trajectories without scenario runs are a single
flat line.

**L1: the interface, the derivation layer, the baseline, and binary.**
Deliverables: the `lab` schema migration (tables, statuses, zero public grants,
`lab.derived_members`, `lab.scenarios`, `lab.scenario_mutations` shells);
`lab.fn_run_plan` dispatch reading the derived tree; the IDENTITY scenario; plan
'unilevel_v13' through the interface; both placement strategies; plan 'binary'; the
calibration run and the calibrated rate amendment.
Gates: (1) verifier reproduces section 6.1 to 6.3 independently by hand AND proves lab
unilevel parity: for one seeded finalized month under the identity scenario, lab
unilevel lines and totals equal the real run's lines and totals exactly (the real run
copied for comparison only); verifier also proves the identity scenario's derived
member set equals the `app.members` snapshot row for row, and confirms schema isolation
(no grants, no writes to app, 'final' impossible in lab, 'LAB-' check in place).
(2) QA PASS.

**L2: matrix plus stairstep-breakaway.**
Deliverables: plans 'matrix_3x7' (both placement strategies at width 3) and
'stairstep_breakaway'; hand example for each appended to this spec as an amendment;
plus (added v1.2, from QA finding MEDIUM-1) extend the registry discipline trigger so
a run row freezes once its status is 'complete', mirroring the scenario freeze, closing
the service-role UPDATE gap QA identified.
Gates: verifier hand-recomputation of both plans on the mini tree plus one seeded month
spot-check of every reason code; QA PASS.

**L3: scenarios and watched accounts.**
Deliverables: the four mutation kinds plus 'remove_leg' (section 9.2), scenario locking
and stacking, deterministic replay, the watchlist, per-run watch snapshots with delta
components (section 10).
Gates: verifier independently replays scenarios S1 and S2 by hand and matches sections
9.5 and 10.3 to the cent, under both plans, including the delta components; a stacking
case (a scenario extending a scenario) is replayed and matched; QA PASS.

**L4: the living report.**
Deliverables: the append-only export (per-run files plus regenerable index, section
11.3), `lab\build_dashboard.py`, and the self-contained HTML page with every metric of
section 5, the trajectory views and comparison matrix of section 11, the open grids,
posted PRIVATE behind the staff sign-in (Howard's ruling, section 8 question 2).
Gates: verifier recomputes every displayed metric, trajectory point, and matrix cell
from the exported files alone (no database access) and matches the page; QA PASS on the
page, including the private posting.

---

## 8. Open questions for Howard

**Questions 1 through 6: RULED by Howard 2026-08-16 (via the coordinator), same day as
v1.1.** All recommended defaults ACCEPTED as written, with question 2 ruled explicitly:

1. **Which months does the lab run?** RULED: all seven, the six seeded finalized months
   (February through July 2026) plus August 2026 with the real bridged volume once its
   run is final.
2. **Is the lab page public on orvanna.io?** RULED: PRIVATE behind the staff sign-in
   for now. Publishing later is a deliberate product decision, not a default: Howard
   sees the lab as potentially a flagship product, his words, "this could be gold."
   The future-public path, recorded so it is designed for and not retrofitted: the page
   is already self-contained and credential-free, so going public is (a) a product
   decision by Howard, (b) a fresh isolation review of the export content (member codes
   in a public what-if grid are the one exposure to re-examine; the 'LAB-' wall already
   separates synthetic accounts), and (c) a publish location decision. Nothing in the
   architecture has to change.
3. **Calibrated binary rate.** RULED: accept the section 4.2 calibration rule's output
   on seeded March; this spec is amended with the number the same day.
4. **Number of placement strategies.** RULED: two ('bfs_spill', 'volume_balanced') at
   launch.
5. **Matrix gating.** RULED: flat depth 7 for qualified members (section 4.3).
6. **Does the lab ever appear in the member portal?** RULED: NEVER, structurally
   (section 2).

**New open questions raised by v1.1 (defaults stand unless Howard overrides):**

7. **Maximum scenario stack depth.** Default: 3 (a scenario, its extension, and one
   more). Deep chains are replayable but unreadable; past 3, flatten by creating a new
   root scenario with the combined mutation list.
8. **Watchlist size.** Default: 10 active watched accounts. Soft cap, enforced only by
   a warning: the trajectory view and the comparison matrix stop being readable past
   roughly ten rows, and Howard's own phrase was "a couple of accounts".
9. **Removed member's history: vanish or truncate?** Default: month-scoped. Every
   removal carries month_from (default: the first month of the run window), so within
   the run the member vanishes from month_from onward and is present before it.
   "Vanish entirely" is month_from = first run month; "truncate from June" is
   month_from = June. One mechanism, both behaviors, no special case.
10. **Synthetic volume profiles.** Default: restricted to multiples of 50.00 per month
    (the catalog's grain). This preserves the plan's rounding-never-fires property
    (COMP-PLAN-SPEC arithmetic; every CV and every line lands exactly on a cent), so
    scenario runs stay exactly reconcilable. Arbitrary amounts are allowed only if
    Howard wants to study rounding behavior itself.
11. **The named baseline run.** Default: for each month, the baseline is (identity
    scenario, plan 'unilevel_v13', that month). Every watch snapshot's delta is against
    this unless the run names a different baseline_run_id, which the registry permits
    (for example, binary-versus-binary across two scenarios).
12. **Scenario runs over real August volume.** Default: allowed, labeled
    'counterfactual on real volume' (section 2.3 wall 3). Counterfactuals on real
    months are much of the point; the walls hold either way.

---

## 9. Scenarios (added v1.1, 2026-08-16)

### 9.1 What a scenario is

A scenario is a NAMED, VERSIONED, ORDERED list of tree and volume mutations layered on
the base census. The census is never touched: the mutated tree is DERIVED by replaying
the list, exactly the anchor-derivation principle of section 3 (binary's placement tree
is derived from the sponsor tree; a scenario's tree is derived from the census). What is
stored is the DELTA, auditable and replayable; what is computed is the tree. The base
census with an empty mutation list is the IDENTITY scenario, and it is a real scenario
row, so "no scenario" is not a special case anywhere.

Scenarios STACK: scenario B may name scenario A as its parent, and B's effective
mutation list is A's effective list followed by B's own. Every lab run records
(scenario, plan, parameters, placement strategy, months), so any number on any surface
traces to exactly one recipe.

### 9.2 The mutation tables

**`lab.scenarios`**: id (identity primary key), scenario_code (text, unique, not null),
name, parent_scenario_id (nullable self-reference), status with CHECK in
('draft', 'locked', 'archived'), created_at, notes. Rules: a scenario may be locked only
if its parent is locked; a run may reference only a LOCKED scenario; a locked
scenario's rows and its mutations are frozen by trigger, the same immutability
discipline as finalized runs. Editing a locked scenario means creating a child or a new
scenario, never an update.

**`lab.scenario_mutations`**: id, scenario_id (not null), seq (int, unique per
scenario), kind with CHECK in ('add_member', 'remove_member', 'remove_leg',
'move_member', 'set_volume'), target_ref (text member code, 'GW-' census or 'LAB-'
synthetic; null for add_member), new_sponsor_ref (for add_member and move_member),
volume_profile (JSON, for add_member and set_volume: either
{"sv_per_month": 100.00} applied to every run month, or a per-month map like
{"2026-08": 150.00, "2026-09": 100.00}), month_from and month_to (nullable dates
scoping the mutation within the run window; null means the whole window).

| Kind | What it does | Validation at lock, re-checked at run |
|---|---|---|
| add_member | Creates a synthetic member under new_sponsor_ref with volume_profile. | Sponsor ref must exist at its point in the replay. |
| remove_member | Removes target and reattaches the target's frontline to the target's sponsor (section 9.3), orphans processed in ascending member id, each keeping its own subtree. Target's volume vanishes from month_from onward. | Target must exist; removing the root is REFUSED. |
| remove_leg | Removes target and its ENTIRE subtree ("what if this leg never existed"). | Target must exist; not the root. |
| move_member | Reattaches target (with its whole subtree) under new_sponsor_ref. | Both must exist; the new sponsor must not be inside the moved subtree (cycle refusal). |
| set_volume | Overrides the target's monthly SV with volume_profile for the scoped months. | Target must exist. |

A reference that is missing when a run replays the list FAILS the run loudly. A
mutation is never silently skipped; a half-applied scenario is worse than no run.

### 9.3 The orphaned-downline rule, argued

**Rule: remove_member reattaches the removed member's frontline members to the removed
member's sponsor.** Why this and not the alternatives:

1. **It is what real MLM administration does.** Terminating a distributor rolls their
   frontline up to the terminator's upline. A counterfactual should mirror an action an
   operator could actually take, or it answers a question nobody can act on.
2. **Minimum edit.** Only edges touching the removed member change, so a watched
   account's delta attributes to the REMOVAL, not to collateral restructuring the rule
   invented.
3. **Total and deterministic.** Every non-root member has a sponsor, so the reattachment
   target always exists; ascending-id processing of orphans makes the result unique.

Alternatives, named and dispositioned: cascade removal of the whole subtree is a REAL
and different question, so it is its own kind, remove_leg, not a variant flag;
promoting orphans to roots is REJECTED (every plan and TV assume one connected tree);
reattach-to-a-named-beneficiary needs no kind of its own, because it is expressible as
move_member of each child followed by remove_member, and keeping the kinds primitive
keeps replays auditable.

### 9.4 Determinism rule

Effective mutation list = the parent chain flattened root-first, each scenario's
mutations in seq order. Derived tree = the run's census snapshot plus a replay of the
effective list in that order. Synthetic members get deterministic identities: id =
10,000,000 plus the 1-based ordinal of their add_member mutation within the effective
list; member_code = 'LAB-' plus scenario_code plus '-' plus seq. Because synthetic ids
sort after every census id, placement derivation (section 3, ascending id order) places
added members after census members, deterministically. The contract: same census
snapshot plus same effective mutation list equals identical `lab.derived_members` rows,
identical level map, and byte-identical run output, row order included. Census months
February through July are frozen and August is append-only under the migration 021
trigger, so reruns are stable in practice as well as by construction.

### 9.5 Worked scenario example S1, hand-computed: add one recruit under M2

Scenario S1, one mutation: add_member, new_sponsor_ref M2, volume profile 100.00 SV per
month. Synthetic member: code 'LAB-S1-1', id 10,000,001, SV 100.00, CV = round(0.80 x
100.00, 2) = 80.00, qualified (boundary). Base = the five-member mini tree of section 6.

**Unilevel v1.3, before and after.** After: TV(M1) = 400 + 100 = 500.00, TV(M2) = 50 +
100 = 150.00. Ranks unchanged: M1 stays Builder depth 2 (TV 500 is far under Leader's
2,500); M2 has active legs LAB-S1-1 (qualified) but not M5, so 1 active leg, still
Member depth 1. New lines only: M2 on LAB-S1-1 at level 1 = 0.10 x 80.00 = 8.00; M1 on
LAB-S1-1 at level 2 = 0.05 x 80.00 = 4.00.

| Member | Before | After | Delta |
|---|---|---|---|
| M1 | 30.00 | 34.00 | +4.00 |
| M2 | 4.00 | 12.00 | +8.00 |
| Company | 34.00 | 46.00 | +12.00 |

**Binary, draft parameters, strategy A, before and after.** Placement replay: base
placements as section 6.3 (M2 at M1.left, M3 at M1.right, M4 spilled to M2.left, M5 at
M2.right); then LAB-S1-1, sponsor M2, both M2 slots full, BFS spillover under M2 finds
M4.left open: LAB-S1-1 lands at M4.left. Legs after: M1 left {M2, M4, M5, LAB-S1-1} =
120 + 80 + 40 + 80 = 320.00, right {M3} = 80.00, pay leg 80.00, amount 16.00. M2 left
{M4, LAB-S1-1} = 160.00, right {M5} = 40.00, pay leg 40.00, amount 8.00. M4 has one
empty leg: no line.

| Member | Before | After | Delta |
|---|---|---|---|
| M1 | 16.00 | 16.00 | 0.00 |
| M2 | 8.00 | 8.00 | 0.00 |
| Company | 24.00 | 24.00 | 0.00 |

**The teaching read, which the report must surface.** The same recruit that is worth
8.00 a month to M2 under unilevel is worth exactly NOTHING to anybody under this binary:
spillover dropped the recruit into strong legs, and flushed unmatched value rose from
0.20 x 200.00 = 40.00 to 0.20 x 360.00 = 72.00. "Add an account and watch who gains" is
Howard's core question, and the answer is plan-shaped: that is the product.

---

## 10. Watched accounts (added v1.1, 2026-08-16)

### 10.1 The watchlist and the snapshot

**`lab.watchlist`**: id, member_ref (census 'GW-' code or synthetic 'LAB-' code),
active flag, note, added_at. Howard's "track a couple of accounts".

**`lab.watch_snapshots`**, written by every run for every active watched account
present in that run's derived tree:

| Field | Content |
|---|---|
| run_id, member_ref | Keys. |
| earnings | The account's total_earned in this run. |
| rank_label, paid_depth | The plan's own vocabulary; paid_depth null for plans without one. |
| sv | The account's SV that month. |
| shape_volume | JSON, plan-shaped: {"tv": ...} for unilevel, {"left_cv": ..., "right_cv": ...} for binary and matrix, {"gv": ..., "bracket": ...} for stairstep. |
| contributing_downline_count | Per-source plans: distinct source members on the account's lines. Aggregate plans: member count of the basis (binary: pay-leg members; stairstep: non-breakaway group size). |
| baseline_run_id | The named baseline (default per section 8 question 11: same month, identity scenario, unilevel_v13; any run may name another). |
| delta_earned, delta_components | Section 10.2. |

### 10.2 The delta, explained in components, honestly

For PER-SOURCE plans (unilevel, matrix, and stairstep's override lines), the delta
decomposes EXACTLY, because both runs carry per-source lines and the sources partition:

| Component | Definition |
|---|---|
| from_added_members | Sum of amounts on sources that are scenario-added members. |
| from_removed_members | Minus the baseline amounts on sources removed by the scenario. |
| from_reach_gained | Amounts on sources present in both trees that had NO line in the baseline (came into reach: rank, depth, or qualification change). |
| from_reach_lost | Minus baseline amounts on common sources with no line now. |
| from_level_shift | For sources with lines in both runs at DIFFERENT levels: amount now minus amount before (structure moved them). |
| from_same_level_change | Lines in both runs at the same level with different amounts (volume or rate mechanics). |

The six components sum to delta_earned to the cent, always, because every line of both
runs falls in exactly one bucket. The verifier's check is that equality.

For AGGREGATE-BASIS plans (binary pay-leg, stairstep differential), a per-source
decomposition DOES NOT EXIST: the pay is a function of a leg or group total, and no
principled rule assigns cents of min(left, right) to individual members. The snapshot
says so instead of pretending: delta_components carries
{"decomposable": false, "basis_before": ..., "basis_after": ...,
"basis_members_gained": [...], "basis_members_lost": [...]} and the report shows the
raw delta plus these basis movements, labeled "basis movement, not attribution".

### 10.3 Worked watched-account example S2: one account, two plans, opposite directions

Scenario S2, one mutation: move_member, target M4, new sponsor M3. Base = the section 6
mini tree. Watched accounts: M1 and M2. Derived sponsor tree: M1 -> M2, M3;
M2 -> M5; M3 -> M4.

**Unilevel v1.3.** TV(M1) = 400.00 unchanged (same members below); TV(M3) = 100.00.
Ranks: M1 has active legs M2, M3 = 2, still Builder depth 2. M3 is qualified with one
active leg (M4): still Member depth 1, but M4 is now M3's level 1. Lines: M1 on M2
12.00, on M3 8.00, on M5 at level 2 2.00, on M4 NOW AT LEVEL 2 0.05 x 80.00 = 4.00
(was level 1, 8.00). M2 on M5 4.00. M3 on M4 0.10 x 80.00 = 8.00. Totals: M1 26.00,
M2 4.00, M3 8.00, company 38.00.

**Binary, strategy A.** Placement replay on the derived tree, ascending id: M2 to
M1.left; M3 to M1.right; M4, sponsor M3, M3.left open: M4 at M3.left (no spillover this
time); M5, sponsor M2, M2.left open: M5 at M2.left. Legs: M1 left {M2, M5} = 160.00,
right {M3, M4} = 160.00, a TIE, and the tie rule (section 4.2) makes the LEFT leg the
pay leg: basis 160.00, amount 0.20 x 160.00 = 32.00. M2 left {M5} = 40.00, right empty:
no line. M3 left {M4} = 80.00, right empty: no line.

**The watched snapshot, deltas against the S2-free baseline (section 6 numbers):**

| Watched | Plan | Baseline | S2 | Delta | Components |
|---|---|---|---|---|---|
| M1 | unilevel v1.3 | 30.00 | 26.00 | -4.00 | from_level_shift -4.00 (M4's line moved from level 1, 8.00, to level 2, 4.00); every other component 0.00. Sums exactly. |
| M1 | binary draft A | 16.00 | 32.00 | +16.00 | decomposable false; basis 80.00 to 160.00; basis_members_gained M2, M5 (pay leg switched sides on the tie); basis_members_lost M3. |
| M2 | unilevel v1.3 | 4.00 | 4.00 | 0.00 | all components 0.00. |
| M2 | binary draft A | 8.00 | 0.00 | -8.00 | decomposable false; basis 40.00 to 0.00; M2's second leg existed only because M4 had SPILLED into it, and the move took the spillover away. |

**M1 is the contrast the product exists for: the SAME move, same month, same money,
loses M1 4.00 under unilevel (a frontline member pushed one level deeper) and DOUBLES
M1's binary pay from 16.00 to 32.00 (the legs balanced at 160.00 each).** A plan is a
lens, and the living report puts two lenses on one account side by side.

---

## 11. The living report (added v1.1, 2026-08-16)

### 11.1 The run registry

The dashboard of section 5 stops being single-shot. `lab.plan_runs` IS the registry:
every run appends a row recording (scenario_id, plan_code, plan_params,
placement_strategy, period, baseline_run_id, created_at, status), rows are never
deleted, and 'archived' only hides a run from the default report. Section 5's metric
definitions are unchanged; this section adds how runs accumulate and how the report
renders them over time.

### 11.2 The report surfaces

All fed from exports, all in the open-grid style: every row, every column, sortable,
no baked-in filters; Howard filters. Exact deltas are always printed as numbers, with
delta coloring on top (hardcoded colors, positive and negative distinguishable in a
screenshot).

1. **Trajectories.** For each watched account: months on the horizontal axis, earnings
   on the vertical, one line per (plan, scenario) combination, small multiples per
   account so accounts sit side by side. This is "see how they make more or less money
   over how the downline does", literally drawn.
2. **The comparison matrix.** Rows: watched accounts. Columns: scenario-plan
   combinations (identity + unilevel is the anchor column). Cells: earnings for the
   selected month (or the month range's sum, toggled), colored by delta against each
   row's baseline, exact number in every cell.
3. **The open grids.** The per-member delta grid of section 5 gains scenario and plan
   columns; the watch-snapshot table renders raw, components included.
4. **Labels everywhere**, inherited: what-if disclaimer, derived-placement caption with
   the A-to-B spread, 'counterfactual on real volume' on mutated real months.

Posting: PRIVATE behind the staff sign-in (Howard's ruling, section 8 question 2), with
the future-public path recorded there.

### 11.3 How the export accumulates, argued

**Chosen: one immutable JSON file per run plus a regenerable index.**
`lab\exports\runs\run-<id>.json` (written once when the run completes, never edited,
the file-level mirror of run immutability) and `lab\exports\index.json` (run id, plan,
scenario, period, totals per run; REGENERATED by scanning the runs folder, so it is
derived state that can never be the single point of truth or of corruption).
`lab\build_dashboard.py` embeds the index plus the selected runs into the HTML page at
build time, so the page remains fully self-contained: no fetches, no credentials, works
from a file share behind the staff sign-in.

**Rejected: a single append-only runs.json.** It grows without bound, every write
rewrites the whole archive (one interrupted write corrupts the entire history), two
concurrent exports clash on one file, and "append-only" would be a promise a text file
cannot enforce. Per-run files get immutability from never being reopened, which is the
same trick the commission tables use, and the folder itself is the audit trail.

Archived runs stay on disk and out of the default embed. Nothing exported is ever
deleted (the project's no-delete rule applies to the lab's history too).

---

Amendment discipline (charter rule, Phase 6 precedent): when the build diverges from
this spec, the spec is amended the same day, never abandoned. Every amendment is dated
and names what changed and why.
