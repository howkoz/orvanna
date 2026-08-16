# Comp Plan Lab Specification, version 1.1

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
'stairstep_breakaway'; hand example for each appended to this spec as an amendment.
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
