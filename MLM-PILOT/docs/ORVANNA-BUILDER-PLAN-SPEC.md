# Orvanna Builder Plan Specification (lab plan five: 'orvanna_builder'), version 1.2

**Amendment 2026-08-16, v1.2 (the red-team gate's price, paid).** The red-team review
(`docs\verification\ORVANNA-BUILDER-RED-TEAM-2026-08-16.md`, commit 5170cc8) ruled NOT
PRESENTABLE YET with an exact path to PASS. Its strongest finding, attack 2b, BROKE a
claim this spec made: the section 6 retention-agent story was stated universally and
is measured TRUE only for the one to two nearest Builder generations and SIGN-INVERTED
above a pool-binding stack. This amendment: names and owns the LAPSE-BENEFIT INVERSION
in section 6 and corrects 12A(c) (item 1, with the new standing metric 6 in section
12); re-anchors the anti-gaming and double-pay arithmetic of sections 11, 12A(b), and
12A(d) to the calibrated rates of record (item 2; every conclusion STRENGTHENS at the
rates of record); adds the member-level proration exposure and the normative
shaved-line statement rule to 12A(e) (item 3); and binds the three presentation rules
into section 13 (item 4). The waterfall, the walk, the gates, the calibration honesty,
and the regulatory posture survived every executed attack; what is amended here is
what the spec SAID, brought level with what the engine DOES.

**Amendment 2026-08-16, v1.1 (the build landed, commit 5a5ff33, proof
`docs\verification\PLAN5-PROOF-RUN-2026-08-16.md`; the calibration residue ruled).**
The one-shot calibration of section 9 was applied exactly as written and landed at an
increment of 4.3314 points of CV, 0.33 above the window's 4.0 ceiling, because
proration relief is non-linear (the same cause as the binary calibration residue).
RULED: ACCEPT AND DISPLAY, the binary precedent extended; the calibrated rates (gen1
0.015, gen2 0.010, second_leg 0.020) are the parameters of record in section 5; the
full ruling with the rejected options is in section 9; section 9's falsified
Builder-density expectation is corrected there; and section 12A(e) now carries the
REAL census proration number (12 percent of sources) in place of the fixture-derived
"rare" expectation. The section 10 gate fixture stays at the draft rates, correctly:
every run records its rates, and the fixture's arithmetic is the contract, not the
calibration.

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
| gen1_rate | **0.015** (calibrated of record, v1.1, 2026-08-16; draft was 0.04) | Layer 2 generation 1, on the Builder's group CV. |
| gen2_rate | **0.010** (calibrated of record, v1.1; draft was 0.02) | Layer 2 generation 2. |
| second_leg_rate | **0.020** (calibrated of record, v1.1; draft was 0.05; effective rates with multipliers 0.020 / 0.023 / 0.025) | Layer 3 base rate on second-strongest leg CV. |
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
paying their sponsor THAT MONTH. (Scoped v1.2, 2026-08-16, corrected by red-team
attack 2b, engine-measured:) the retention-agent dynamic is TRUE, monthly, personal,
and exactly priced, FOR THE ONE TO TWO BUILDER GENERATIONS NEAREST THE LAPSE, the
people whose override the lapse erases. It is NOT universal, and above a pool-binding
stack it inverts; section 6A names that honestly.

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

### 6A. The lapse-benefit inversion, named and owned (v1.2, 2026-08-16, red-team attack 2b)

**The finding, engine-measured, not argued.** Above any POOL-BINDING stack, a downline
Builder's lapse RAISES senior checks, because a lapse removes claims from bound pools
and Law B's proration relief flows to everyone else claiming those sources. The red
team built it: fixture REDTEAM-P5-RELIEF, 19 members, eight nested Builders over a
source whose pool binds at f2 = 0.526315. One mid-stack Builder (B7) lapses to SV
0.00, the field loses 100.00 SV of real monthly revenue, and SIX checks RISE: the top
earner E goes +7.44 (its second-leg bonus rose 10.60 to 15.00 while the bonus BASIS
fell), B1 through B4 each rise, while the two nearest Builder generations lose hard
(B6 -17.00, B5 -11.29) and the lapsed member loses everything (-25.89). Company
payout FELL 36.37; f2 on the bound source went 0.526315 to 1; the cap held on both
sides to the cent. Less volume, more bonus, measured. The system-level version was
already on this spec's record (the junior layer GREW under calibration because
proration relief flows downhill, section 9); this is the same arithmetic seen from
one member's chair, and it was stated nowhere until the red team measured it.

**The honest scoping, which is also the bound.** The senior upline above a binding
stack is not the lapse's retention agent; the senior upline is the lapse BENEFICIARY.
Three facts keep this an incentive blind spot rather than a hole. One: it CANNOT be
actively farmed; a member cannot make a downline lapse, only decline to help one
recover, and red-team attacks 1 and 4 confirmed no active construction extracts it.
Two: the gain is CAPPED BY LAW B; it is exactly the freed share of already-bound
pools (+7.44 on a 212.91 check, 3.5 percent, in the hostile fixture), never new
money, and company cost goes DOWN on every lapse. Three: the near generations, the
people actually positioned to act, still lose the most, so the retention incentive
points the right way where intervention is possible. At the calibrated rates of
record this is not a corner: 120 of 1,001 census sources bind, so the inversion is
live in any presentation month and must be named before a hostile consultant names
it.

**The standing watch (required per-run metric, added to section 12 as metric 6):**
per consecutive run pair, the count of members whose total pay ROSE attributable to a
downline lapse (a member leaving the qualified or Builder set), with the summed gain,
computed from the watch machinery's delta components and the proration traces. The
inversion is watched, never rediscovered.

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

**The calibration executed and the residue ruled (v1.1, 2026-08-16).** Measured on
seeded March: the DRAFT rates paid 21.9712 percent of CV, an increment of 7.3627
points, far outside the window, and this paragraph's own expectation is hereby
CORRECTED as falsified by measurement: the census is much DENSER in nested Builders
than the ten-member fixture, not sparser (pool pressure at draft: 333 of 1,001 sources
at f2 below 1). The one-shot rule was applied exactly as written: factor 3.0 / 7.3627
= 0.4075, rates gen1 0.015, gen2 0.010, second_leg 0.020, each nearest 0.005.
CALIBRATED RESULT: 18.9399 percent of CV, increment **4.3314 points, 0.33 ABOVE the
window's 4.0 ceiling**, because proration relief is non-linear: as rates shrink, fewer
sources prorate (f2 below 1 fell from 333 to 120 sources, f3 from 139 to 83), so
payout shrinks slower than the rates, the exact non-linearity the binary calibration
met with its cap.

RULED: **ACCEPT THE RESIDUE AND DISPLAY IT. The calibrated rates above are the
parameters of record (section 5).** The window was a BUDGET, not a law; the miss is
0.33 of a point, bounded by Law B either way, and it must be displayed per the
standing rule: every surface shows this plan's actual 18.9399 beside the baseline's
14.6085, "size held equal" banned. Reasoning, the binary precedent extended: iterating
to convergence would solve a fixed point AGAINST the waterfall's proration, which is a
shape feature of Law B, the same laundering this lab already refused once; and the
measured interplay is itself information the dashboard should show, not tune away:
under calibration the JUNIOR layer's paid total ROSE (second-leg bonus 287.78 at
draft, 367.49 calibrated) because smaller senior claims leave the junior class more
pool room, a redistribution the red team is directed to examine. Rejected options,
recorded: iterate the factor to convergence on capped-and-prorated totals; or shave
one rate a half-step (gen1 0.010 lands low in the window but cuts the plan's headline
team-building rate by a third to chase a third of a point). Either remains available
later as a new run with its rates in plan_params, never a respec.

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

**Funding fake Builders loses money, arithmetically.** (Re-anchored v1.2 to the
calibrated rates of record; the red team EXECUTED this attack at those rates, runs 98
and 99, and it loses HARDER than the draft arithmetic said.) The obvious attack on
layer 2: create and fund a downline account into Builder so its group pays you
generation 1. Cost: the puppet Builder needs SV 100 plus two active legs at SV 100
each = $300.00 a month of real money. Yield, engine-measured: generation 1 on group
CV 240.00 at 0.015 = 3.60, plus spine 24.00 and second-leg bonus 1.60, a marginal
attack yield of 21.20 a month against 300.00 of spend: **7.07 cents returned per
attack dollar, a 92.9 percent monthly loss, forever**, because decay (Law A) makes
the puppet a subscription, not a purchase. The 20-percent-of-revenue ceiling makes
this structural: no plan funded under the cap can ever return more than 20 cents of
commission on a self-funded dollar, so every self-funding attack on every layer loses
at least 80 percent; this one loses 93.

**Leg-stacking cannot game layer 3.** (Re-anchored v1.2; red-team attack 1 executed
all three arrangements at the rates of record and the dilution held to the cent.)
Stacking everyone in one leg: no second leg, no bonus, by construction. Splitting a
fixed downline volume V across k equal legs pays second_leg_rate x multiplier(k) x
V / k: at k = 2, 0.020 x 1.00 x V/2 = 0.0100 x V; at k = 3, 0.020 x 1.15 x V/3 =
0.0077 x V; at k = 4, 0.020 x 1.25 x V/4 = 0.0063 x V. Two balanced legs is the
optimum, the multiplier softens but never reverses the dilution, so width-spam (many
shell legs) strictly loses; the red team's executed table (same six recruits, three
arrangements) also showed splitting FORFEITS overrides. And shell legs cannot even
count: the multiplier counts ACTIVE legs, which need real qualified frontline
members.

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
6. **Lapse-benefit exposure (added v1.2, required by red-team attack 2b):** per
   consecutive run pair, the count of members whose total pay ROSE attributable to a
   downline lapse, with the summed gain (section 6A). Watched every run, so the
   inversion's real size is a number on the record, never a hope.

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
case (draft-rate teaching arithmetic, like the section 10 fixture; the conclusion is
rate-independent, and the red team's cold census sweep at the rates of record found
the worst real source at 0.56 of its pool with ZERO of 1,001 over): a source with CV
80.00 (pool 20.00) sitting under TEN nested Builders, so layer 2 claims against it
total 10 x 6 percent x 80.00 = 48.00, two point four times its entire pool. Case one, full spine above it (five qualified ancestors in depth): spine
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
V across k equal legs pays 0.0100 x V at k = 2, 0.0077 x V at k = 3, 0.0063 x V at
k = 4; the optimum is two real balanced legs, which is not a leak, it is the design
goal wearing its own name. (Re-anchored v1.2 to the rates of record:) funding an
artificial second leg costs $100.00 a month of real subscription to return at most
0.025 x 80.00 = 2.00: a 98 percent monthly loss, forever, because decay re-prices it
every month. Directing genuine new recruits into the weaker leg IS profitable, and
that is the intended behavior, paid at the designed rate under the cap. One qualifier
the red team added and this answer now carries: the RANKING channel cannot be gamed
downward or upward, but the WATERFALL channel has the passive inversion of section
6A, which is named, bounded, and watched there.

**(c) "Monthly decay churns leaders who have one bad month."** Stated honestly: v1 has
no grace months, inherited from the live plan, and the tradeoff is real. Three things
bound the damage. First, the qualification bar is low and wide: 100.00 SV is one
domain agent, and CUSTOMER volume counts (live plan v1.2), so a working leader's
qualification rarely hinges on a single order of their own. Second (scoped v1.2 per attack 2b), the decay lands
FIRST on the one to two NEAREST Builder generations' overrides, and those uplines are
precisely the people positioned and now paid to intervene, which is Law A working as
designed: the plan does not punish the bad month, it prices, for the sponsor, what
preventing it is worth (section 6: 9.60 to the cent in the fixture). Above a
pool-binding stack the sign inverts and seniors gain from a lapse; that is section
6A, named there with the engine numbers, bounded by Law B, and watched by metric 6. Third, the lab MEASURES it: metric 4 counts decay
events and their summed override deltas per month, so the churn cost is an observed
number before this plan is ever presented, not a hope. If observed decay is too sharp,
a one-month Builder grace is a single parameter away (open question 8), and adding it
would be a spec amendment, not a redesign.

**(d) "This double-pays the same volume."** Every override plan in the industry pays
multiple people on one order; the honest question is whether the SUM is bounded.
Follow one order's dollar (re-anchored v1.2 to the rates of record, red-team
confirmed): M8's month is one $100.00 domain agent subscription (plus a $50.00
support agent, CV 80.00 total, pool 20.00). Layer 1: M3 earns 8.00 at level 1, M1
earns 4.00 at level 2: 12.00. Layer 2: M8 sits in Builder M3's group, so M1's
generation 1 override claims 0.015 x 80.00 = 1.20. Layer 3: M8 heads M3's
second-strongest leg, so M3's bonus claims 0.020 x 80.00 = 1.60. Total: 12.00 + 1.20
+ 1.60 = 14.80 of a 20.00 cap, three layers, four payments, 5.20 unspent, to the
cent. And section 10's row M10 shows the boundary case at the fixture's draft rates:
the same accounting drives a source's payout INTO the cap and stops it there exactly
(10.00 of 10.00, the junior claim prorated from 2.00 to 0.40). The plan never pays
more than the 20 percent of revenue the company already promises today; it pays the
SAME ceiling to more purposes.

**(e) "The ceiling will prorate the field's checks and they will riot."** (Rewritten
v1.1, 2026-08-16, with the measured census numbers this section always demanded; the
v1.0 text predicted from the ten-member fixture that proration would be "rare and
junior", and the measurement KEPT the junior half and RETIRED the word "rare".) The
realized presentation numbers, seeded March at the calibrated rates of record: **120
of 1,001 sources prorate, 12.0 percent**, down from 333 at the draft rates; the
prorated-away amounts are 638.00 on layer 2 and 305.68 on layer 3 (scale 6), together
943.68 against 17,417.12 paid, about 5.4 percent of the run. The honest phrase is now:
**proration is ROUTINE AND JUNIOR: a working feature, not an edge case.** Every
prorated cent comes off layers 2 and 3; the spine is structurally untouchable (section
7), so no member's live-plan-equivalent pay is ever reduced, and the field-facing
sentence is exact: "your base plan pay is never prorated; the two bonus layers share
what the cap leaves, and in a given month about one source in eight hits the cap."
The counter-intuitive detail the red team is directed to verify (section 9): shrinking
the senior rates GREW the junior layer's paid total, because proration relief flows
downhill. These realized numbers, refreshed per run, must be CARRIED IN ANY
PRESENTATION of this plan per metric 5; the v1.0 commitment stands, and this
paragraph is its first discharge. No assurance substitutes for the number, including
the retired one.

(Extended v1.2, red-team attack 4: the MEMBER-level exposure rides beside the
source-level number on every surface, because members are what riot, not sources.)
Seeded March at the rates of record: **35 of the 207 paid members, 17 percent, carry
at least one shaved line**; the worst-shaved member loses 324.14, and the worst RATIO
is 21 percent of that member's gross claims. The exhibit that states the problem in
one row, GW-000044's bonus line: rate 0.020, basis 120.00, member-visible paid 0.17
(the floor-on-prorated rule of section 7) against a rate-times-basis of 2.40, a 93 percent haircut that depends on OTHER people's claims
on shared sources, per source, at scale 6, and is not recomputable from anything the
member can see. Therefore, AS NORMATIVE SPEC TEXT: **any member-facing statement of
this plan MUST print, on every prorated line, the CLAIMED amount, the PAID amount,
and a one-line reason** ("this order reached its 20 percent cap; the bonus layers
shared what remained"), sourced from the engine's per-line traces, which already hold
the data (l2_traces, l3_trace). A shaved line a member cannot recompute is survivable
only when the statement itself shows the claim, the paid, and the why; this rule is
part of the PLAN now, not a lab internals feature, and any build of a member-facing
surface without it fails its gate.

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

**The three presentation rules (v1.2, 2026-08-16, binding on any deck, page, or
conversation about this plan; from red-team attacks 5, 6, and 7):**

1. **The cost-drift chart is a standing exhibit.** Every presentation shows the
   measured trajectory of percent of CV across the seven computed months (February
   18.5594 rising to July 19.6812, about 0.22 points a month at this field maturity),
   presented as what it is: real, intended, and bounded above at 25 percent of CV per
   source by Law B. The drift is shown climbing toward a ceiling it cannot cross;
   hiding it would hand a hostile reader the chart to draw themselves.
2. **Law A is presented with the GW-000294 exhibit, not only the tidy fixture.** A
   real census member whose entire check is one 7.80 override sees it go to **0.00 in
   one month** because a Builder two hops down missed qualification once: a 100
   percent wipe on someone else's bad month, attributed entirely to from_reach_lost.
   That is the no-grace reality, shown honestly beside the section 6 fixture's 9.60,
   with the countermeasure stated (hold more than one Builder and more than one leg).
   Open question 8 (the grace month) is re-decided by Howard WITH this exhibit and
   section 6A in hand.
3. **The development premium is THE pull number; "wide reach" is never claimed.**
   The pitch leads with spec metric 2 as the red team computed it: within the same SV
   band, members who developed at least one Builder out-earn equal-volume members who
   did not by **7.9x to 92x** (52.47 versus 6.66 at SV 100 to 149; 725.57 versus 7.90
   at 150 to 299; 955.31 versus 11.77 at 300 plus), said in the same breath as the
   participation counts (24 members hold that position; 44 earn any structure money;
   the top five capture 90.2 percent of the structure budget). The 22.9 percent
   structure-linked share is never shown without those companions. And the reach
   claim is BANNED: 207 of 1,001 paid versus the baseline's 206 and stairstep's 448
   is on the record; the honest sentence is "same paid population, radically deeper
   development premium", never "wide reach".

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
8. **A one-month Builder grace (raised by hostile question (c); re-framed v1.2 by the
   red team).** Should a member who held Builder-or-above last month keep
   override-boundary status through one lapsed month? Default: NO for v1, monthly-pure
   like everything else, and the red team CONCURS with no-grace, with two sharpenings
   now on the record for Howard's re-decision: grace would blunt the near-upline's
   retention incentive (the original reason) while doing NOTHING about the section 6A
   inversion, which lives in the waterfall, not the rank decay; and the decision
   should be made with the GW-000294 exhibit (a 100 percent single-month check wipe)
   and section 6A in hand, not on the tidy fixture alone. Also on the record: the
   seeded census is growth-biased with almost no churn, so no volatility claim rides
   on seeded months without the section 12 behavioral caveat attached.

---

Amendment discipline (charter rule): when the build diverges from this spec, the spec
is amended the same day, never abandoned. Every amendment is dated and names what
changed and why.
