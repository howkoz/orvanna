# Orvanna Builder Plan Specification (lab plan five: 'orvanna_builder'), version 1.0

As of 2026-08-16. Written by mlm-architect on Howard's green light, his objective
verbatim: "i just want to make sure we have a strong comp plan that incentivizes the
member to stay working on their downlines and keep growing but does not break the
company bank."

This is a LAB PLAN: it runs inside the Comp Plan Lab under the engine contract of
`docs\COMP-LAB-SPEC.md` version 1.3 (sections 1, 2, and 9 through 11 apply unchanged:
one contract, sandbox isolation, scenarios, watched accounts, the living report). It is
registered as plan five in that spec's plan list by dated note. It is NOT the live
plan; the live plan remains unilevel v1.3 (`docs\COMP-PLAN-SPEC.md`). Every number this
plan produces is a what-if.

Builders: mlm-comp-engineer. Grader: mlm-verifier. Deterministic: two independent
implementations of this document must agree to the cent. No production code here; SQL
names are contracts.

**Addendum, same day, Howard's law verbatim: "it needs to be solid and strong in case i
show someone the plan and they do not say this is not going to work."** This document is
therefore written to survive a hostile read by a veteran compensation plan consultant:
section 1A names each mechanism's industry lineage and the known failure mode removed
from it, section 12A answers the objections such a reader will raise, each with worked
numbers inside this document, and section 13 adds a RED-TEAM review as a named release
gate equal in standing to the verifier and QA gates.

Acronym key: Multi-Level Marketing (MLM), Personal Volume (PV), Sales Volume (SV),
Commissionable Volume (CV), Team Volume (TV), Structured Query Language (SQL),
JavaScript Object Notation (JSON), Quality Assurance (QA).

---

## 1. The design in one view

Three layers, two laws.

| Piece | What it is | Why it exists |
|---|---|---|
| Layer 1, THE SPINE | Unilevel v1.3 exactly as live: rates 10/5/5/3/2 percent of source CV, five levels, rank-gated paid depth, the SV >= 100.00 qualification gate. Unchanged. | The plan inherits the live baseline's explainability, its verified engine semantics, and its worked examples. A member who understands today's plan already understands most of this one. |
| Layer 2, BUILDER OVERRIDES | An override on the group CV of each downline member holding Builder rank or above this month, two generations deep, generations defined by Builder-rank boundaries (the boundary-counter walk of lab spec v1.3 section 4.4, with NO breakaway: no volume ever leaves anyone's group). | The team-building engine: developing a Builder pays you on that Builder's whole organization, and developing Builders who develop Builders pays a second generation. |
| Layer 3, SECOND-LEG BONUS | A bonus on the member's SECOND-STRONGEST leg's monthly CV, with a multiplier stepping up on the count of active legs. Legs are personally sponsored subtrees in the ordinary genealogy; no placement tree exists anywhere in this plan. | Binary's soul without binary's tree: one giant leg pays nothing extra by construction, so the rational move is a second real leg, then a third. |
| Law A, DECAY | Every layer recomputes fresh monthly from that month's qualified structure. Nothing is permanent. | Sustained engagement: a lapsed Builder stops paying their sponsor THAT MONTH, which makes the upline the downline's retention agent, structurally. Section 6. |
| Law B, THE WATERFALL | Per-source-member contribution capped into a pool; spine draws first, overrides second, second-leg bonus last; junior layers prorate down when the pool exhausts. | The bank cannot break, per order, provably, whatever the parameters do. Section 7. This is the plan's central invariant. |

---

## 1A. Precedent and lineage: proven mechanisms, each with its known failure mode removed

Nothing in this plan is invented math. Every mechanism has decades of industry service;
what is new is the assembly, and specifically that each mechanism arrives with its
best-known failure mode surgically removed. A veteran reader should recognize every
part.

| Mechanism here | Industry lineage | The known failure mode | Removed how |
|---|---|---|---|
| Layer 1, the unilevel spine | The industry's most common chassis: more modern plans are built on a unilevel base than on any other structure, precisely because it is the easiest plan to explain and the hardest to game. | Unilevel's PASSIVITY toward development: it pays on whatever depth happens to exist, and pays nothing extra for turning a recruit into a leader, so pure unilevels under-reward the exact behavior that grows a company. | Layers 2 and 3 exist to pay for development explicitly; the spine itself stays untouched, keeping the explainability. |
| Layer 2, generation overrides on developed leaders | The core mechanism of generational and breakaway plans, the OLDEST plan family in the industry, running for decades: leaders earn on the groups of the leaders they develop, generations deep. | Breakaway's VOLUME THEFT: in classic stairstep-breakaway, promoting a leader removes their whole group from your volume, so the plan punishes the promotion it claims to want, and the field learns to suppress its best people. | NO breakaway, stated as a rule in section 3: no volume ever leaves anyone's group. Developing a Builder here is pure addition (a new override) with zero subtraction; there is no rank a downline can reach that costs their upline a cent of volume. |
| Layer 3, lesser-leg pay | Binary's proven engine: paying on the weaker leg is the industry's most effective known driver of teamwork and balance, which is why binaries dominate the fast-growth segment. | Two: binary's PLACEMENT GAMING (spillover lotteries, strategic placement, purchased positions in the tree) and binary's CONCENTRATION and runaway-liability profile (pay-leg value compounding with depth, top-heavy checks, carryover banking). | No placement tree EXISTS in this plan: legs are the real sponsor genealogy, so there is nothing to game with placement, no spillover to lottery, and no carryover to bank (Law A). The liability side is bounded twice: the bonus sits JUNIOR in the waterfall and under the per-source cap (Law B). |
| The leg-count multiplier | Standard leadership bonus structure: stepping a bonus on the count of developed legs is how the industry's leadership pools, car programs, and rank bonuses have worked for decades. | Cliff effects: big steps at magic numbers produce buy-ins at month end to cross a threshold. | The steps are deliberately shallow (1.00 / 1.15 / 1.25), each requires an ACTIVE leg (another qualified human, not a purchase), and section 11 shows the step never reverses the dilution math, so there is no cliff worth buying. |
| Law B, the hard payout ceiling | The solvency discipline this company already lives by: the live plan's published promise that no order ever pays more than 20 percent of its price. Caps and pay-ratio governors are standard practice in every professionally administered plan. | Uncapped plans' COST DRIFT: payout ratio creeping upward as the field matures, discovered in the accounts months later, fixed by emergency plan changes that burn field trust. | The ceiling is enforced PER ORDER, structurally, inside the calculation itself (section 7), not monitored after the fact; drift is bounded by construction and watched monthly by the lab's metrics (section 12). |

Framed plainly, for the hostile reader: this plan is a unilevel chassis carrying
breakaway's development engine without the breakaway, binary's balance engine without
the binary tree, a standard leadership multiplier without the cliffs, all inside the
solvency cap the company already promises. Every piece is proven; every piece's
best-known abuse is structurally absent, not policy-forbidden.

## 2. Layer 1, the spine: unilevel v1.3, unchanged

Exactly `docs\COMP-PLAN-SPEC.md` v1.3 as reimplemented and parity-proven in the lab at
L1: SV summed per member-month, CV = round half up (0.80 x SV, 2), qualification SV >=
100.00, ranks Member through Executive with paid depths 1 through 5, active legs, TV
excluding self, rates 10/5/5/3/2 percent of source CV by tree level, earner qualified,
source qualification irrelevant, no compression, line-level rounding. Reason code:
'builder_spine_level_pay'. On any month, layer 1's lines are identical to plan
'unilevel_v13' run on the same data; that equality is a gate fixture (section 15).

## 3. Layer 2, Builder overrides: the exact model

**Group CV of a member B** = CV of B plus the CV of every member in B's whole sponsor
subtree, full depth, nothing excluded. There is NO breakaway in this plan: a nested
Builder's group stays inside every enclosing group. (Consequence, stated honestly:
groups NEST, so one source member's CV can back override claims for several enclosing
Builders. Layer 2's structural ceiling is therefore not bounded by its rates alone; the
waterfall of section 7 is the ceiling. This is a design choice, not an oversight: it
keeps "your group" meaning the same thing for everybody, and lets the cap do the
capping.)

**The override walk (per Builder, boundary-counter, adopted from lab spec v1.3 section
4.4 with Builder-rank boundaries instead of breakaways).** For EACH member B holding
Builder rank or above this month, independently: walk the sponsor chain upward from B
toward the root, carrying a boundary counter starting at 0. At each member encountered,
in order: first evaluate, then count.

1. Evaluate: if the member is QUALIFIED and the counter is 0 and generation 1 for B is
   unassigned, that member earns the generation 1 override, gen1_rate x (B's group CV).
   Else if the member is qualified and the counter is 1 and generation 2 for B is
   unassigned, that member earns the generation 2 override, gen2_rate x (B's group CV).
2. Count: if the member evaluated holds Builder rank or above, increment the counter.
3. Stop when the counter reaches 2, or at the root.

Normative consequences, mirroring the lab's stairstep ratification: generation 1 for B
goes to the first qualified member above B with no Builder between (usually the
sponsor, which is the coordinator sketch's "personally sponsored" case, but the walk
also handles an unqualified sponsor by passing over them without counting); a
generation 2 payment for B exists exactly when a Builder-or-above sits between B and
the generation 2 recipient; an unqualified member is passed over and never increments
the counter (under v1.3 an unqualified Builder is impossible, so every boundary is
qualified); one member may collect generation 1 for one Builder and generation 2 for a
deeper one in the same month.

Reason codes: 'builder_override_gen1', 'builder_override_gen2'. Line shape: source =
the Builder B, basis = B's group CV, rate = the generation rate; amount per section 7's
waterfall (equal to round(rate x basis, 2) whenever no proration touched the line).

## 4. Layer 3, the second-leg bonus: the exact model

**Legs.** A leg of member E is one frontline (personally sponsored) member plus that
member's whole subtree, in the sponsor genealogy. Leg CV = the sum of CV of every
member in the leg, the frontline member included, qualification irrelevant (volume is
volume, exactly as TV counts it). A leg is ACTIVE when its frontline member is
qualified this month (the live plan's definition, unchanged).

**Ranking.** Rank E's legs by leg CV descending; ties broken by frontline member id
ascending. The SECOND-STRONGEST leg is the leg ranked second. Deterministic always.

**The bonus.** E earns the bonus if and only if E is qualified AND has at least 2
active legs this month. Amount basis = the second-strongest leg's CV. Effective rate =
second_leg_rate x multiplier, where the multiplier steps on the count of ACTIVE legs:
2 active legs 1.00; 3 active legs 1.15; 4 or more 1.25. The line's rate column stores
the effective rate exactly (for example 0.05 x 1.15 = 0.0575), so amount = round(rate
x basis, 2) holds whenever no proration touched the line. One line per earner, reason
'builder_second_leg_bonus', source_member_id null, level null (aggregate basis, like
binary's pay leg).

**One giant leg pays nothing extra, by construction:** with one leg there is no second
leg and no bonus; and eligibility needs two ACTIVE legs besides. The ranking runs over
ALL legs by CV while eligibility and the multiplier count ACTIVE legs; so a member
with two active legs and a third, fat, inactive leg is paid on the second-strongest by
volume, whichever that is (open question 4 confirms the default).

## 5. Parameter table (draft values, all recorded per run in plan_params)

| Parameter | Draft | Meaning |
|---|---|---|
| spine_rates | [0.10, 0.05, 0.05, 0.03, 0.02] | Layer 1, fixed: the live plan's rates. Not a tuning dial. |
| gen1_rate | 0.04 | Layer 2 generation 1, on the Builder's group CV. |
| gen2_rate | 0.02 | Layer 2 generation 2. |
| second_leg_rate | 0.05 | Layer 3 base rate on second-strongest leg CV. |
| leg_multipliers | {2: 1.00, 3: 1.15, 4: 1.25} | Multiplier by active-leg count; 4 means 4 or more; below 2, ineligible. |
| pool_rate | 0.25 | Law B: the per-source pool is 0.25 x that source's CV, which equals 20 percent of revenue (0.25 x 0.80). See section 7 and open question 1. |
| waterfall_order | ["spine", "overrides", "second_leg"] | Seniority, fixed. Overrides generation 1 and 2 share one class (open question 2). |
| earner gate | qualified (SV >= 100.00), every layer | The live plan's single gate, unchanged. |
| placement | none | Sponsor tree only; p_placement_strategy is null, like stairstep. |

## 6. Law A: sustained engagement by decay

**Principle, as spec law.** Every layer computes fresh each month from that month's
qualified structure: ranks are monthly-pure (live plan rule), so the Builder set is
monthly-pure, so the override walk's boundaries and recipients are monthly-pure; legs
are re-ranked monthly, so the second-strongest leg and the multiplier are monthly-pure.
Nothing is permanent, grandfathered, or banked. A downline Builder who lapses stops
paying their sponsor THAT MONTH. The upline therefore has a monthly, personal,
exactly-priced reason to keep their people qualified and building: the plan makes the
upline the downline's retention agent, structurally rather than rhetorically.

**Two-month worked example (fixture DECAY, four members).** A sponsors B; B sponsors C
and D. Subscriptions: every member holds one domain agent ($100.00, 100 PV), so SV 100
and CV 80.00 each; all qualified in month one.

Month one. B is qualified with active legs C and D: B holds BUILDER. B's group CV = 80
+ 80 + 80 = 240.00. A is qualified, 1 active leg (B): rank Member, paid depth 1.
Layer 1: A earns 10 percent x 80.00 on B = 8.00; B earns 8.00 on C and 8.00 on D =
16.00 (C and D at level 2 are beyond A's depth 1: breakage, live-plan behavior).
Layer 2: walk up from Builder B: A is qualified at counter 0, takes generation 1 =
0.04 x 240.00 = 9.60; A is not Builder-or-above, no boundary; root, stop. Layer 3: A
has one leg, ineligible; B has 2 active legs, multiplier 1.00, legs tie at 80.00 and
80.00, tie-break by frontline id makes C's leg first and D's leg second: bonus = 0.05
x 80.00 = 4.00. Waterfall: every source pool clears (largest use is source D: pool
20.00 against 8.00 spine + 3.20 override + 4.00 bonus = 15.20). Checks: **A = 17.60**
(8.00 + 9.60), **B = 20.00** (16.00 + 4.00).

Month two. C cancels (SV 0). B is still qualified but has ONE active leg: B is NOT a
Builder this month. Layer 1 for A is unchanged (B's own CV is unchanged): 8.00.
Layer 2: there is no Builder below A: the 9.60 is GONE. Layer 3 for B: one active leg,
ineligible: the 4.00 is gone; B's spine drops to 8.00 (no C line). Checks: **A = 8.00,
shrinks by exactly 9.60, the generation 1 override to the cent.** B = 8.00.

The fixture is built so the decay isolates cleanly: A's paid depth 1 never reached C,
so A's ENTIRE month-over-month loss is the override on B's Builder status. That number
is the retention agency made visible: A's check tells A precisely what keeping C
active was worth. The lab's watched-account delta components (lab spec section 10.2)
attribute it: from_reach_lost on the override line, everything else zero.

## 7. Law B: the bank cannot break, by waterfall

**The pool.** Every source member-month s contributes a pool of pool_rate x CV(s) =
0.25 x CV(s), which is 20 percent of the revenue behind that CV (CV = 0.80 x SV and PV
equals dollars, so 0.25 x 0.80 = 0.20 of money in the door). This is the SAME ceiling
the live plan already states publicly ("the most an order can ever pay is 20 percent
of the price"): plan five does not raise the ceiling, it spends the head-room under it.
The spine's maximum claim on any source is exactly 10 + 5 + 5 + 3 + 2 = 25 percent of
CV (one ancestor per level at most), so THE SPINE ALWAYS FITS and is never prorated,
which is what keeps layer 1 literally unchanged. Layers 2 and 3 are funded exclusively
by what the spine did not claim: unreachable levels, unqualified earners, depth gates.
**The team-building money is reclaimed spine breakage, and nothing else.**

**Per-source claim decomposition (what makes the invariant recomputable).** Every
layer's pay is restated as claims against individual sources:

- Spine lines are already per-source: ancestor E claims rate(level) x CV(s).
- A layer 2 override on Builder B's group CV at rate r is IDENTICALLY the set of
  claims r x CV(m) for every member m in B's group (B included), because group CV is
  the sum of member CVs. The earner and rate come from the walk; the claims attach to
  each m as source.
- A layer 3 bonus on E's second-strongest leg at effective rate r is identically the
  claims r x CV(m) for every member m of that leg.

**The waterfall, per source s, simultaneous within each seniority class:**

1. pool(s) = 0.25 x CV(s).
2. Spine claims on s are paid in full. spine_paid(s) <= pool(s) always (proof above).
3. R2(s) = pool(s) minus spine_paid(s). Let L2(s) = the sum of ALL layer 2 claims on s
   (generation 1 and generation 2, one class). If L2(s) <= R2(s), every claim pays in
   full and f2(s) = 1. Otherwise every layer 2 claim on s pays claim x f2(s), where
   f2(s) = R2(s) / L2(s).
4. R3(s) = R2(s) minus layer 2 paid on s. Same rule for the layer 3 claims on s with
   factor f3(s) = min(1, R3(s) / L3(s)).

**Determinism and order-independence.** The waterfall is defined per source as closed
formulas over the complete claim sets, never as sequential draining of a ledger: no
enumeration order of members, claims, or layers can change any factor. Same inputs,
same factors, same cents, always.

**Rounding.** Claims, factors, and prorated pieces are computed in numeric at scale 6;
factors and prorated pieces are TRUNCATED (rounded toward zero) at scale 6, so paid
never exceeds pool at full precision. A member-visible line's amount is the sum of its
per-source pieces, rounded half up to 2 decimals if NO piece of it was prorated, and
FLOORED (rounded down) to 2 decimals if ANY piece was prorated. Consequence: the
per-source invariant holds in rounded money too, because proration only ever rounds
down; unprorated lines keep the live plan's half-up posture (and with the catalog's
multiples of 50.00, unprorated amounts land exactly on cents anyway, the live plan's
documented property).

**THE INVARIANT, which the verifier recomputes per source:** for every source
member-month s, spine_paid(s) + layer2_paid(s) + layer3_paid(s) <= 0.25 x CV(s),
exactly at scale 6 and in rounded money. No order can ever pay more than its cap. The
worked example in section 10 includes a source where the cap BINDS (M10: pool 10.00,
paid 10.00 exactly, bonus prorated from 2.00 to 0.40), so the gate fixture proves the
law at its boundary, not only in its slack.

## 8. Engine contract mapping (lab spec v1.3 sections 1 and 9 through 11)

| Contract item | Plan five |
|---|---|
| plan_code | 'orvanna_builder' |
| p_placement_strategy | null (sponsor tree; the strategy CHECK treats it like 'stairstep_breakaway') |
| p_params | The section 5 table as JSON, recorded per run. |
| Inputs | The derived tree and month volumes per lab spec 1.1, scenarios included; SV, CV, qualification identical across plans (contract invariant 4). |
| Reason codes | 'builder_spine_level_pay' (per-source, level 1 to 5), 'builder_override_gen1' and 'builder_override_gen2' (source = the Builder, level null), 'builder_second_leg_bonus' (source null, level null). The builder extends the lines CHECK with these four. |
| Rounding identity | amount = round(rate x basis, 2) holds for every line NOT touched by proration; a prorated line is floored per section 7 and flagged prorated = true in its plan_metrics trace. This is a scoped exception in the style of lab spec v1.3's 'stairstep_differential'. |
| plan_metrics, earner side | {rank_label, paid_depth, builder_flag, group_cv, legs: [{frontline_code, leg_cv, active}], second_leg_cv, active_leg_count, multiplier} |
| plan_metrics, source side | {pool, spine_claimed, l2_claimed, l2_paid, f2, l3_claimed, l3_paid, f3}, at scale 6. The verifier rebuilds every prorated amount and checks the section 7 invariant from this alone. |
| rank_label | The live ladder's labels (member, builder, leader, director, executive): layer 1 computes them anyway, and reusing them keeps rank-band metrics comparable across plans. |
| Company totals | Sums of rounded lines, never re-rounded. |

## 9. Calibration approach

Per the lab's residue-display discipline (lab spec v1.3, section 4.2 ruling): the
phrase "size held equal" is BANNED for this plan too; every dashboard surface shows
this plan's actual percent of CV beside the baseline's.

Plan five cannot and should not match the baseline's size: layer 1 IS the baseline and
layers 2 and 3 are additive, so its percent of CV is strictly above the baseline's by
construction. The calibration target is therefore a BUDGET, not parity: on seeded
March 2026, layers 2 plus 3 together should land between 2.0 and 4.0 points of CV
above the baseline's 14.6085. The draft rates were sized for that window by hand: the
ten-member fixture pays 16.40 percent of CV against unilevel's 12.22 (section 10), an
increment of 4.2 points on a tree deliberately dense with structure; the census tree
is sparser in Builders, so the increment should land lower. If the measured March
increment falls outside the window, scale gen1_rate, gen2_rate, and second_leg_rate by
the single common factor (window midpoint 3.0 / measured increment), each rounded to
the nearest 0.005, recorded in plan_params and amended into section 5 the same day,
per-strategy questions not arising (no placement). The waterfall makes calibration a
sizing question only: even wildly wrong rates cannot breach 25 percent of CV per
source, because Law B holds regardless of parameters.

## 10. Worked example, hand-computed: the ten-member fixture, all three layers

The lab's canonical ten-member month (lab spec section 6.4 tree and volumes; CVs M1
160, M2 120, M3 80, M4 80, M5 40, M6 120, M7 1,200, M8 80, M9 240, M10 40; qualified:
all but M5 and M10; ranks per the live plan: M1 Leader depth 3, M3 Builder depth 2,
everyone else Member depth 1). This section is the builder's L-gate fixture: every
line to the cent.

**Layer 1, the spine:** identical to the unilevel v1.3 run, all fifteen lines
(COMP-PLAN-SPEC section 7.3): totals M1 114.00, M2 16.00, M3 130.00, M8 4.00, company
264.00.

**Layer 2, overrides.** Builder-or-above this month: M1 (Leader), M3 (Builder). For
B = M3, group = {M3, M7, M8, M10}, group CV = 80 + 1,200 + 80 + 40 = 1,400.00: walk up
from M3: M1 is qualified at counter 0, takes generation 1 = 0.04 x 1,400.00 = 56.00;
M1 is Builder-or-above, counter to 1; M1 is the root, stop; no generation 2 exists.
For B = M1: root, nobody above, no lines. Layer 2 lines: exactly one, M1 earns 56.00
on source M3 (per-source claims: 3.20 on M3, 48.00 on M7, 3.20 on M8, 1.60 on M10).

**Layer 3, second-leg bonus.** M1: legs by CV: M3-leg 1,400.00, M2-leg (M2, M5, M6,
M9) 520.00, M4-leg 80.00; second-strongest = M2-leg, 520.00; active legs 3 (M2, M3,
M4 all qualified): multiplier 1.15, effective rate 0.0575; claim 0.0575 x 520.00 =
29.90 (per-source: M2 6.90, M5 2.30, M6 6.90, M9 13.80). M2: legs M5-leg 280.00,
M6-leg 120.00, but only ONE active leg (M5 is unqualified): INELIGIBLE, the teaching
case: balance without qualified frontlines pays nothing. M3: legs M7-leg 1,200.00,
M8-leg 120.00; 2 active legs, multiplier 1.00; claim 0.05 x 120.00 = 6.00 (per-source:
M8 4.00, M10 2.00). M8: one leg, ineligible. No other member has legs.

**The waterfall, per source (pool = 0.25 x CV):**

| Source | CV | Pool | Spine paid | Layer 2 claims | f2 | Layer 3 claims | f3 | Total paid | Cap holds |
|---|---|---|---|---|---|---|---|---|---|
| M1 | 160.00 | 40.00 | 0.00 (root, no upline) | 0 | 1 | 0 | 1 | 0.00 | yes |
| M2 | 120.00 | 30.00 | 12.00 | 0 | 1 | 6.90 | 1 | 18.90 | yes |
| M3 | 80.00 | 20.00 | 8.00 | 3.20 | 1 | 0 | 1 | 11.20 | yes |
| M4 | 80.00 | 20.00 | 8.00 | 0 | 1 | 0 | 1 | 8.00 | yes |
| M5 | 40.00 | 10.00 | 6.00 | 0 | 1 | 2.30 | 1 | 8.30 | yes |
| M6 | 120.00 | 30.00 | 18.00 | 0 | 1 | 6.90 | 1 | 24.90 | yes |
| M7 | 1,200.00 | 300.00 | 180.00 | 48.00 | 1 | 0 | 1 | 228.00 | yes |
| M8 | 80.00 | 20.00 | 12.00 | 3.20 | 1 | 4.00 | 1 | 19.20 | yes |
| M9 | 240.00 | 60.00 | 12.00 | 0 | 1 | 13.80 | 1 | 25.80 | yes |
| M10 | 40.00 | 10.00 | 8.00 | 1.60 | 1 | 2.00 | **0.200000** | **10.00** | **BINDS exactly** |

The M10 row is the law at work: spine 8.00 (M8, M3, M1 at levels 1 to 3), override
piece 1.60, remaining pool 0.40 against a 2.00 bonus claim: f3 = 0.40 / 2.00 =
0.200000, paid 0.40, source total exactly 10.00 = the cap. (Spine detail per source:
M2 pays M1 level 1; M5 pays M2 4.00 + M1 2.00; M6 pays M2 12.00 + M1 6.00; M7 pays M3
120.00 + M1 60.00; M8 pays M3 8.00 + M1 4.00; M9 pays M1 level 3 12.00 only, M5
unqualified and M2 depth-gated, live-plan breakage; M10 pays M8 4.00 + M3 2.00 + M1
2.00; M3 pays M1 8.00; M4 pays M1 8.00.)

**Final lines and totals.** M1: spine 114.00; override generation 1 on M3, basis
1,400.00, rate 0.04, amount 56.00 (no proration); second-leg bonus, basis 520.00, rate
0.0575, amount 29.90 (no proration): **199.90**. M2: spine **16.00**. M3: spine
130.00; second-leg bonus, basis 120.00, rate 0.05, pieces 4.00 + 0.40 (the M10 piece
prorated), line FLOORED at **4.40**: **134.40**. M8: spine **4.00**. Everyone else
0.00.

**Company: spine 264.00 + layer 2 56.00 + layer 3 34.30 = 354.30 = 16.4028 percent of
CV 2,160.00** (baseline 12.22; displayed side by side per section 9, never "equal").
Cross-check: the waterfall table's Total paid column sums to 354.30. Members paid 4.

## 11. Anti-gaming analysis

**Ranks stay unpurchasable.** Builder requires two ACTIVE LEGS: two OTHER accounts,
each with SV >= 100.00 this month. Money spent on yourself cannot create that, and the
ten-month spreading rule (bridge decision 4.1) prevents one giant one-time
self-purchase from spiking a month's SV or TV to snatch Leader or Director for an
override month: a $2,000.00 one-time purchase arrives as 200 PV a month for ten
months, not 2,000 once.

**Funding fake Builders loses money, arithmetically.** The obvious attack on layer 2:
create and fund a downline account into Builder so its group pays you generation 1.
Cost: the puppet Builder needs SV 100 plus two active legs at SV 100 each = $300.00 a
month of real money. Yield: generation 1 on group CV 240.00 = 9.60, plus spine level 1
on the puppet 8.00 and level 2 on its legs 8.00 = 25.60 a month best case. Spend
300.00 to collect 25.60: the attack loses 274.40 a month, every month, forever,
because decay (Law A) makes it a subscription, not a purchase. The 20-percent-of-
revenue ceiling makes this structural: no plan funded under the cap can ever return
more than 20 cents of commission on a self-funded dollar, so every self-funding attack
on every layer loses at least 80 percent.

**Leg-stacking cannot game layer 3.** Stacking everyone in one leg: no second leg, no
bonus, by construction. Splitting a fixed downline volume V across k equal legs pays
second_leg_rate x multiplier(k) x V / k: at k = 2, 0.05 x 1.00 x V/2 = 0.0250 x V; at
k = 3, 0.05 x 1.15 x V/3 = 0.0192 x V; at k = 4, 0.05 x 1.25 x V/4 = 0.0156 x V. Two
balanced legs is the optimum, the multiplier softens but never reverses the dilution,
so width-spam (many shell legs) strictly loses. And shell legs cannot even count: the
multiplier counts ACTIVE legs, which need real qualified frontline members.

**Waterfall arbitrage: none.** Claims attach to sources by structure (tree position),
not by earner choice; a member cannot route a claim toward a source with a richer
pool. Proration factors are per-source facts, not negotiable order.

**What remains after the attacks fail** is the intended behavior: qualify yourself,
keep two or more real legs active, develop Builders, and keep them qualified, because
Law A re-prices all of it monthly. The plan's best exploit is doing the work.

## 12. Measurement plan: what proves "stronger team-building pull"

All computed from exported run results per the lab's dashboard discipline (open
grids, residue displayed, no live credentials):

1. **Structure-linked share:** (layer 2 + layer 3 payout) / total payout, per run. The
   headline number: the fraction of the check that exists only because of structure.
2. **Builder-developer delta:** bucket members by SV band; within each band, compare
   mean total earnings of members with at least one personally sponsored
   Builder-or-above against members with none. Same volume, different structure: the
   delta is the plan's team-building premium, recomputable from results plus
   plan_metrics.
3. **Watched-account trajectories:** the lab spec section 11 views, unilevel v1.3
   beside orvanna_builder for the same scenario and months; the DECAY fixture members
   as standing watchlist entries.
4. **Decay events:** count of members whose layer 2 income fell month over month
   because a downline member left the Builder-or-above set (set difference between
   consecutive runs' plan_metrics builder_flag), with the summed override delta.
5. **Pool pressure:** share of sources with f2 < 1 or f3 < 1, the distribution of
   factors, and total prorated-away amounts by layer. This is Law B's gauge: how hard
   the cap is working.

**The honest behavioral caveat, stated once and inherited by every readout:** the lab
replays RECORDED volumes under different rules. It proves how this plan REDISTRIBUTES
pay toward structure and decay; it cannot prove that members would have BEHAVED
differently under it. Every "incentivizes" claim from lab output is a claim about
payout geometry, not a measured behavioral response. The measurement plan shows the
incentive is priced; only live months with real members can show it works.

## 12A. The hostile reader's questions, answered with numbers

The objections a veteran compensation consultant will raise, each answered inside this
document. The reader is assumed unfriendly and numerate.

**(a) "Overrides on group volume stack across generations and nested Builders; the
budget blows up."** The claims stack without limit; the PAYMENT cannot. Worked worst
case: a source with CV 80.00 (pool 20.00) sitting under TEN nested Builders, so layer
2 claims against it total 10 x 6 percent x 80.00 = 48.00, two point four times its
entire pool. Case one, full spine above it (five qualified ancestors in depth): spine
pays 25 percent x 80.00 = 20.00, the pool is exhausted, f2 = 0, and every one of the
48.00 in override claims pays 0.00. Case two, partial spine (qualified ancestors at
levels 1 and 3 only): spine pays 8.00 + 4.00 = 12.00, R2 = 8.00, f2 = 8.00 / 48.00 =
0.166666, and the ten Builders' overrides collectively receive exactly 8.00. In both
cases the source pays out at most 20.00 = its cap, to the cent. Section 7's invariant
is not a monitoring policy; it is the arithmetic the amounts are computed BY.

**(b) "Lesser-leg pay makes members sandbag the strong leg or split volume across legs
artificially."** Sandbagging is structurally absent: there is no carryover to bank
(Law A) and no placement tree to park volume in; volume books to the account that
bought it, monthly, and pay is on the second-STRONGEST leg as the month actually
landed. The splitting attack is worked in section 11 and loses: fixed downline volume
V across k equal legs pays 0.0250 x V at k = 2, 0.0192 x V at k = 3, 0.0156 x V at
k = 4; the optimum is two real balanced legs, which is not a leak, it is the design
goal wearing its own name. Funding an artificial second leg costs $100.00 a month of
real subscription to return at most 0.0575 x 80.00 = 4.60: a 95 percent monthly loss,
forever, because decay re-prices it every month. Directing genuine new recruits into
the weaker leg IS profitable, and that is the intended behavior, paid at the designed
rate under the cap.

**(c) "Monthly decay churns leaders who have one bad month."** Stated honestly: v1 has
no grace months, inherited from the live plan, and the tradeoff is real. Three things
bound the damage. First, the qualification bar is low and wide: 100.00 SV is one
domain agent, and CUSTOMER volume counts (live plan v1.2), so a working leader's
qualification rarely hinges on a single order of their own. Second, the decay lands
FIRST on the upline's override, and the upline is precisely the person positioned and
now paid to intervene, which is Law A working as designed: the plan does not punish
the bad month, it prices, for the sponsor, what preventing it is worth (section 6:
9.60 to the cent in the fixture). Third, the lab MEASURES it: metric 4 counts decay
events and their summed override deltas per month, so the churn cost is an observed
number before this plan is ever presented, not a hope. If observed decay is too sharp,
a one-month Builder grace is a single parameter away (open question 8), and adding it
would be a spec amendment, not a redesign.

**(d) "This double-pays the same volume."** Every override plan in the industry pays
multiple people on one order; the honest question is whether the SUM is bounded.
Follow one order's dollar: M8's month is one $100.00 domain agent subscription (plus a
$50.00 support agent, CV 80.00 total, pool 20.00). Layer 1: M3 earns 8.00 at level 1,
M1 earns 4.00 at level 2: 12.00. Layer 2: M8 sits in Builder M3's group, so M1's
generation 1 override claims 4 percent x 80.00 = 3.20. Layer 3: M8 heads M3's
second-strongest leg, so M3's bonus claims 5 percent x 80.00 = 4.00. Total: 12.00 +
3.20 + 4.00 = 19.20 of a 20.00 cap, three layers, four payments, 0.80 unspent, to the
cent (section 10's waterfall table, row M8). And row M10 shows the boundary case: the
same accounting drives a source's payout INTO the cap and stops it there exactly
(10.00 of 10.00, the junior claim prorated from 2.00 to 0.40). The plan never pays
more than the 20 percent of revenue the company already promises today; it pays the
SAME ceiling to more purposes.

**(e) "The ceiling will prorate the field's checks and they will riot."** On the
ten-member fixture, proration touched one source in ten and moved 1.60 out of 354.30
paid: 0.45 percent of the run, all of it on the most junior layer. Structurally,
proration requires a source whose spine coverage is nearly full AND which sits under
stacked structure: the baseline's realized spine draw is 14.6085 percent of CV against
a 25-point pool, so the AVERAGE source carries about 10.4 points of headroom against
layers targeted to draw 2 to 4 points. The honest completion of this answer is a
measured one, and the spec makes it mandatory: metric 5 (pool pressure: share of
sources with f2 or f3 below 1, factor distributions, prorated-away totals by layer)
must be computed on the census runs and CARRIED IN ANY PRESENTATION of this plan, so
the claim "proration is rare and junior" is shown from realized data or the plan is
retuned before anyone sees it. No assurance substitutes for that number.

**(f) The skeptic's strongest objection, raised against ourselves: "payout ratio
CREEPS as the field professionalizes. More Builders and more balanced legs mean more
layer 2 and layer 3 claims every month; you have built cost drift INTO the design,
and it compresses margin exactly when the company scales."** True as far as it goes,
and answered structurally: the drift is real, intended (the plan pays MORE as the
field develops, that is the incentive), and BOUNDED ABOVE at 25 percent of CV = 20
percent of revenue per order, by the same per-source arithmetic as (a), not by policy.
The company already prices its product against a 20-percent-of-revenue commission
promise (the live plan's published ceiling); every point of drift comes out of the
BREAKAGE WINDFALL between the realized 14.6 percent of CV and the 25-point ceiling,
money the price already carries, and no month, however mature, can cross the line.
What maturity shrinks is the company's unpaid remainder, never the priced margin
floor. The lab watches it happen rather than discovering it: the living report's
trajectory of realized percent of CV per month is the drift, plotted. The classic
version of this failure (a plan discovered at 45 percent payout in year three,
emergency-amended, field trust burned) is arithmetically unreachable here.

## 13. Phasing and gates

Plan five is an L2-class deliverable in the lab's terms (a plan implementation under
the existing contract): its gate is the section 10 fixture reproduced to the cent,
line for line, factors included, by independent recomputation, plus the section 6
DECAY fixture both months, plus the layer 1 equality check against 'unilevel_v13' on
one seeded month. Both gates (verifier and QA) per project convention.

**The RED-TEAM gate (added by Howard's addendum, a named release gate).** After the
engine builds and the census runs land, and BEFORE Howard ever presents this plan to
anyone, a dedicated red-team review runs: a skeptic, charged to attack the plan with
everything the industry knows (the section 12A list is the floor, not the ceiling:
gaming, solvency, regulatory posture, field-psychology failure modes, edge-case
arithmetic), working from the spec, the engine output, and the census measurements,
and PUBLISHING what was attacked, what broke, and what survived, as
`docs\verification\ORVANNA-BUILDER-RED-TEAM-<date>.md`. The red-team verdict is equal
in standing to the verifier and QA gates: the plan is not presentable until all three
have passed, and a red-team finding that breaks a mechanism reopens this spec, not the
slide deck.

## 14. Open questions for Howard (defaults stand unless he overrides)

1. **Pool rate.** The coordinator sketch said the cap is "20 percent of Commissionable
   Volume"; this spec sets pool_rate = 0.25 of CV, which is 20 percent of REVENUE,
   the ceiling the live plan already promises publicly. A literal 20-percent-of-CV
   pool would force the SPINE itself to prorate (its five levels claim up to 25
   percent of CV), contradicting "layer 1 unchanged". Default: 0.25 of CV. If Howard
   wants a stricter bank, the waterfall handles any pool_rate; only the "spine never
   prorates" property would be lost and section 7 would be amended.
2. **Override seniority within layer 2.** Generation 1 and generation 2 share one
   proration class. Alternative: generation 1 senior to generation 2. Default: one
   class, pro-rata; simpler, and the pool rarely binds on overrides alone.
3. **Should layer 2 earners need Builder rank themselves?** Default: no, qualified
   only; the walk already demands a developed Builder below, and adding a rank gate
   on the earner would double-gate the same behavior. Alternative recorded: require
   Builder-or-above to earn generation 2 (a "match your depth" flavor).
4. **Second-leg ranking universe.** Legs are ranked by CV over ALL legs while
   eligibility and the multiplier count ACTIVE legs. Alternative: rank over active
   legs only. Default: as specified; volume is volume, and the active-leg gates
   already carry the qualification pressure.
5. **Multiplier values.** 1.00 / 1.15 / 1.25 are drafts tuned for the k = 2 optimum
   shown in section 11; any change re-checks that the dilution argument still holds
   (multiplier(k) / k must strictly decrease in k).
6. **Calibration window.** Layers 2 plus 3 target 2.0 to 4.0 points of CV above
   baseline on seeded March (section 9). Confirm or name a different budget.
7. **A name for the field.** 'orvanna_builder' is the plan_code; if this plan ever
   leaves the lab, it needs a member-facing name and a booklet. Default: lab-only
   until Howard says otherwise.
8. **A one-month Builder grace (raised by hostile question (c)).** Should a member who
   held Builder-or-above last month keep override-boundary status through one lapsed
   month? Default: NO for v1, monthly-pure like everything else, because grace blunts
   the retention-agent dynamic that is Law A's point; revisit only if the measured
   decay events (metric 4) on census months show churn worth buying back.

---

Amendment discipline (charter rule): when the build diverges from this spec, the spec
is amended the same day, never abandoned. Every amendment is dated and names what
changed and why.
