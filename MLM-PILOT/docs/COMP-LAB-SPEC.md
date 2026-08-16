# Comp Plan Lab Specification, version 1.0

As of 2026-08-16. Written by mlm-architect on Howard's green light of the same day, his
words: "start running different comp plan runs... binary, unilevel and so on and then we
show a dashboard on the different comp plan runs to understand how they are either better
or worse than each other."

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
                p_placement_strategy text) returns bigint  -- the lab run id
```

The implementation may read, and only read:

| Input | Source | Snapshot rule |
|---|---|---|
| The member tree | `app.members` (id, member_code, sponsor_id, enrolled_on) | Materialized ONCE per lab run into a run-scoped level map, exactly the discipline of `app.run_level_map` in `db\comp\001_comp_engine.sql`. Every later step reads the snapshot, never the live tree. |
| The month's volume | `app.orders` and `app.order_lines`, status 'completed', stamped with the volume month | SV per member computed once per run with the same query shape as the real engine's `member_sv` step. |
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
| rate, amount | amount = round half up (rate x basis, 2), rounded AT THE LINE, exactly the real engine's rule. |
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
  lab). Foreign keys from `lab` to `app.members(id)` are allowed and wanted.
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

1. The root of the placement tree is the root of the sponsor tree.
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
| pay_leg_rate | 0.20 (20 percent) | Rate applied to the pay leg CV. |
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
| Generation override | 4 percent of a generation 1 breakaway group's total CV; 2 percent for generation 2 (a breakaway found under a breakaway). Paid to the first QUALIFIED member found walking the sponsor chain upward from the breakaway; generation counting restarts at each breakaway boundary. |
| Differential pay | Earner receives rate(own GV) x (own CV + non-breakaway group CV) minus the sum over each direct child group of rate(child GV) x (that child group's CV including the child's own). Reason 'stairstep_differential', one line per earner, basis = the signed net basis. |
| Earner gate | qualified (SV >= 100.00); an unqualified member's differential is breakage (their downline's brackets still subtract normally). |

Negative differentials cannot occur: a parent's GV includes every non-breakaway child
group, so parent GV >= child GV, brackets are monotone in GV, and breakaway removes
exactly the groups that would out-bracket the parent.

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

Placement tree: M1(left: M2(left: M4, right: M5), right: M3). Strategy B
('volume_balanced') coincides on this tree (every placement lands in an empty or forced
slot before any weigh-in can differ), which the lab must report as spread 0.00 for this
month; the ten-member month in 6.4 is where the strategies diverge.

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

---

## 7. Phasing, each level closed by two gates

Project convention: a level is CLOSED only when BOTH the mlm-verifier verdict and the QA
gate are PASS. Builder self-report closes nothing.

**L1: the interface, the baseline, and binary on the derived tree.**
Deliverables: the `lab` schema migration (tables, statuses, zero public grants);
`lab.fn_run_plan` dispatch; plan 'unilevel_v13' through the interface; both placement
strategies; plan 'binary'; the calibration run and the calibrated rate amendment.
Gates: (1) verifier reproduces section 6.1 to 6.3 independently by hand AND proves lab
unilevel parity: for one seeded finalized month, lab unilevel lines and totals equal the
real run's lines and totals exactly (the real run copied for comparison only); verifier
also confirms schema isolation (no grants, no writes to app, 'final' impossible in lab).
(2) QA PASS.

**L2: matrix plus stairstep-breakaway.**
Deliverables: plans 'matrix_3x7' (both placement strategies at width 3) and
'stairstep_breakaway'; hand example for each appended to this spec as an amendment.
Gates: verifier hand-recomputation of both plans on the mini tree plus one seeded month
spot-check of every reason code; QA PASS.

**L3: the dashboard.**
Deliverables: `lab\build_dashboard.py` export plus the self-contained HTML page with
every metric of section 5 and the open per-member grid.
Gates: verifier recomputes every displayed metric from the exported JSON alone (no
database access) and matches the page; QA PASS on the page.

---

## 8. Open questions for Howard (defaults stand unless he overrides)

1. **Which months does the lab run?** Default: all seven, the six seeded finalized
   months (February through July 2026) plus August 2026 with the real bridged volume
   once its run is final. The seeded months carry the statistical weight; August is the
   first month where the lab compares plans on real shop money.
2. **Is the lab page public on orvanna.io?** Default: PRIVATE. The page is a local file
   plus, at most, an unlinked path; it does not enter the site navigation. A what-if
   payout page sitting next to a live plan is a field-confusion risk (the same reason
   Instant Payout carries a not-built warning). Publish later by explicit decision only.
3. **Calibrated binary rate.** Default: accept the section 4.2 calibration rule's output
   on seeded March and amend this spec the same day. Alternative: Howard names a rate.
4. **Number of placement strategies.** Default: two ('bfs_spill', 'volume_balanced'),
   the minimum that shows the spread. More strategies are one function each, later.
5. **Matrix gating.** Default: flat depth 7 for qualified members (section 4.3), keeping
   the matrix's shape isolated. Alternative: reuse the five-rank ladder mapped onto
   matrix depths, which makes matrix results less pure but more comparable rank-by-rank.
6. **Does the lab ever appear in the member portal?** Default: NEVER, structurally
   (section 2). Recorded so the default is a decision on the record, not an omission.

---

Amendment discipline (charter rule, Phase 6 precedent): when the build diverges from
this spec, the spec is amended the same day, never abandoned. Every amendment is dated
and names what changed and why.
