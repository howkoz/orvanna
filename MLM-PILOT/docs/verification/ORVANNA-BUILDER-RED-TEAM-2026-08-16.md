# Plan Five ('orvanna_builder') RED-TEAM Review, 2026-08-16

Reviewer: the red team, the third and final release gate named by
`docs\ORVANNA-BUILDER-PLAN-SPEC.md` section 13, equal in standing to the
verifier and Quality Assurance (QA) gates. Charter: a veteran direct-selling
compensation consultant hired to make this plan fail BEFORE it is shown to
anyone. Inputs: the spec v1.1 (sections 1A, 12A, and the residue ruling
included), the builder proof run (`PLAN5-PROOF-RUN-2026-08-16.md`), both gate
verdicts (`PLAN5-VERDICT-2026-08-16.md` PASS, `PLAN5-QA-2026-08-16.md` PASS),
and the live lab (project oiyibdczkokegaxkwulv, schema lab only). Every attack
below was EXECUTED in the lab engine at the calibrated parameters of record
(gen1 0.015, gen2 0.010, second_leg 0.020), not argued on paper, except where
the attack is against a sentence, in which case the sentence is quoted.

Method note: every fixture below was hand-derived by me before the engine ran
it; where my paper number and the engine disagree nowhere, I say so once here
and do not repeat it. All new lab artifacts are tagged REDTEAM-P5-* (runs 95
to 111, scenarios RT-FIX, RT-SB-STARVE, RT-SB-RELIEF, RT-294-LAPSE). Writes
were lab-schema only. Three watchlist entries were added for the watched-account
attacks (LAB-RT-E, LAB-RT-B1, GW-000294) and deactivated after use, disclosed
here so the next reader is not puzzled.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), Quality Assurance (QA), Structured Query
Language (SQL).

---

## THE RULING, UP FRONT: NOT PRESENTABLE YET

The arithmetic is sound everywhere I struck it. The bank cannot break; I
tried. But I broke one CLAIM with engine numbers (attack 2b: the plan's own
incentive PAYS six members more when a mid-tree Builder lapses, which inverts
the retention-agent story the spec tells in section 6), and I caught the
spec's anti-gaming numbers still printed at rates that v1.1 itself
superseded. Per section 13, a finding that breaks a mechanism reopens the
spec, not the slide deck: nothing here demands a redesign, but the spec owes
same-day amendments and the presentation owes three number-pairings before
Howard shows this to anyone. The exact list is at the end. Once those land,
this gate is a PASS; the mechanisms themselves survived everything I threw.

Attack verdicts in one view:

| # | Attack | Verdict |
|---|---|---|
| 1 | Leg-splitting to farm the multiplier (executed) | HELD |
| 2a | Sandbagging by leg ranking (executed) | HELD |
| 2b | Less volume, more bonus, via proration relief (executed) | BROKE IT (the section 6 retention-agent claim, not the waterfall) |
| 3 | Builder-farming (executed) | HELD, with a documentation finding: spec sections 11, 12A(b), 12A(d) still print superseded draft rates |
| 4 | The 12A questions re-asked cold from the census | HELD WITH A CAVEAT (12A(e) statement-explainability) |
| 5 | The pitch versus the numbers | HELD WITH A CAVEAT (the corner claim must never be made as "wide reach"; 22.9 needs two companions) |
| 6 | Decay churn and check volatility (executed, seven months) | HELD WITH A CAVEAT (the one-line-earner shock; seeded data understates churn) |
| 7 | Regulatory smell test (executed and verified) | HELD |
| 8 | The one-page test | PASSED; artifact at the end |

---

## Attack 1: leg-splitting to farm the multiplier

**The attack.** One member rearranges the SAME six recruits (SV 100.00 each,
plus the attacker's own SV 100.00; identical field volume 700.00 SV in every
arrangement) across more legs to chase the active-leg multiplier
(1.00 / 1.15 / 1.25). Runs 95 to 97, calibrated rates, hand-derived first,
engine-matched to the cent.

| Arrangement | Attacker spine | Overrides | Second-leg bonus | Attacker total | Company total |
|---|---|---|---|---|---|
| K2: two legs, nested (two puppet Builders emerge) | 32.00 | 7.20 | 4.80 (multiplier 1.00 on leg CV 240.00) | 44.00 | 79.20 |
| K3: three legs, one recruit under each | 36.00 | 0.00 | 3.68 (multiplier 1.15 on leg CV 160.00) | 39.68 | 63.68 |
| K6: all six flat at the attacker's frontline | 48.00 | 0.00 | 2.00 (multiplier 1.25 on leg CV 80.00) | 50.00 | 50.00 |

The bonus falls 4.80 to 3.68 to 2.00 as the multiplier rises: the dilution
(V/k) beats the step (1.00/1.15/1.25) at every k, exactly as section 11
claims. Splitting also DESTROYS overrides (K2's two nested Builders pay 7.20;
K3 and K6 pay none). Earnings per dollar of volume never rises from
multiplier-chasing restructures.

Two honest observations the presentation should carry: (1) the attacker's own
optimum is maximal flat WIDTH (50.00), because the 10 percent front line
dominates every development rate; the plan pays the ATTACKER most for the
least team-building shape, and pays the FIELD most (79.20, 24 percent of CV
versus K6's 15 percent) for the most developed shape. Layers 2 and 3 reward
the downline's development, not the placement of one's own recruits, which is
the right side of the placement-gaming line but should be said plainly: this
plan does not invert unilevel's width preference for self-placed recruits,
and it should never be pitched as if it does. (2) Puppet-Builder creation via
restructuring (K2) is the profitable-looking variant, and it still loses to
doing nothing structural (44.00 versus 50.00).

**VERDICT 1: HELD.** The multiplier cannot be farmed; splitting strictly
loses bonus (4.80 > 3.68 > 2.00) and forfeits overrides; the engine numbers
match the spec's dilution argument at the calibrated rates.

## Attack 2a: sandbagging by leg ranking

**The attack.** Starve the strongest leg to inflate the second-strongest.
Runs 101 (base: legs CV 240.00 / 120.00) and 102 (scenario RT-SB-STARVE:
strongest frontline drops SV 300.00 to 100.00, legs become 80.00 / 120.00).

Result: bonus basis falls 120.00 to 80.00 (the second-RANKED value is an
order statistic; removing volume from any leg can never raise the second
largest), bonus falls 2.40 to 1.60, spine falls 36.00 to 20.00, total falls
38.40 to 21.60. And there is nothing to bank: no carryover exists (Law A), so
volume withheld this month is simply pay lost forever.

**VERDICT 2a: HELD.** Sandbagging by the ranking channel strictly loses,
structurally (second-order statistic monotonicity) and as measured.

## Attack 2b: less total volume, more bonus, via proration relief. THE FINDING.

**The attack.** The charter question: is there ANY sequence where less total
volume yields more bonus? The ranking channel says no. The WATERFALL channel
says yes, and I built it: fixture REDTEAM-P5-RELIEF (runs 103 base, 104
lapse; scenario RT-SB-RELIEF), 19 members, eight nested Builders B1 to B8
each holding a side leg, a source S at the bottom whose pool binds (my
hand-derived f2 = 0.526315 on S, engine-confirmed), an earner E at the top
with a fat second account making the Builder stack E's SECOND-strongest leg.
Then ONE mid-stack member, B7, lapses to SV 0.00: the field loses 100.00 SV
(80.00 CV, one hundred real dollars of monthly revenue).

What the engine paid, baseline versus lapse month:

| Member | Base total | Lapse total | Delta |
|---|---|---|---|
| E (four Builder generations above B7) | 212.91 | 220.35 | **+7.44** |
| B1 | 47.91 | 50.95 | +3.04 |
| B2 | 43.91 | 46.95 | +3.04 |
| B3 | 39.71 | 42.75 | +3.04 |
| B4 | 34.92 | 35.77 | +0.85 |
| B5 (two above B7) | 31.29 | 20.00 | -11.29 |
| B6 (directly above B7) | 28.60 | 11.60 | -17.00 |
| B7 (the lapsed member) | 25.89 | 0.00 | -25.89 |
| B8 (below B7) | 16.00 | 16.40 | +0.40 |
| Company | 481.14 | 444.77 | -36.37 |

SIX members' checks ROSE when the field lost a member. E's second-leg bonus
rose 10.60 to 15.00 while its basis FELL 1360.00 to 1280.00: less volume,
more bonus, to the cent, which is the charter question answered YES. The
mechanism is Law B doing exactly what it says: on source S, B7's lapse cut
spine claims 12.00 to 8.00 and override claims 15.20 to 11.20, so f2 went
0.526315 to 1 and f3 went 0.000003 to 0.25; S paid out 19.999996 before and
20.000000 after. The cap held both times. The MONEY moved from the dead
member and his two nearest uplines to everyone senior. The watched-account
machinery attributed E's +7.44 exactly (+3.04 same-level override relief,
+4.40 aggregate bonus relief).

Why this matters more than a curiosity: the spec's section 6 sells Law A with
"the plan makes the upline the downline's retention agent, structurally
rather than rhetorically", and 12A(c) says the decay "lands FIRST on the
upline's override, and the upline is precisely the person positioned and now
paid to intervene". MEASURED: that is true for the two Builder generations
nearest the lapse (B6 -17.00, B5 -11.29) and INVERTED for everyone above them
whenever pools bind below. The senior upline is not the retention agent; the
senior upline is the lapse BENEFICIARY. At the calibrated rates, 120 of the
1,001 census sources already bind (12 percent), so this is not a corner of
parameter space; it is live in the presentation month. The spec itself
directed the red team at the system-level version of this (the junior layer
GREW under calibration, 287.78 to 367.49, because "proration relief flows
downhill"); the member-level incentive inversion is the same arithmetic and
is stated nowhere.

Honest scoping, because a red team that overclaims is useless: no member can
directly EXPLOIT this. You cannot make a downline lapse, you can only decline
to help one recover, and the gain is bounded by the freed pool room (here
7.44 on a 212.91 check, 3.5 percent). Law B is untouched; company cost went
DOWN. This is an incentive-alignment blind spot, not a solvency or gaming
hole. But a hostile consultant WILL find it (it falls out of one reading of
the waterfall), and the current spec text hands him a falsified sentence.

**VERDICT 2b: BROKE IT.** The broken thing is the section 6 and 12A(c)
universality claim, not the waterfall: "the upline is the downline's
retention agent" is measured TRUE only for the nearest one to two Builder
generations and measured FALSE (sign-inverted, +7.44 on a real engine run)
for senior uplines above a pool-binding stack. Spec amendment owed: scope the
retention-agent claim to the generations that actually lose, name the
lapse-benefit inversion with this fixture's numbers, and add a lab metric
(members whose pay rose on a downline lapse, per run) so the size of the
inversion is watched, not hoped small. This finding also sharpens open
question 8: a one-month Builder grace would blunt the near-upline's retention
incentive (the spec's stated reason to refuse it) while doing NOTHING about
this inversion, which lives in the waterfall, not the rank decay.

## Attack 3: Builder-farming

**The attack.** Mint a shallow, barely-qualified Builder purely to trigger
overrides. Runs 98 (base: attacker plus one real frontline, attacker earns
8.00) and 99 (attack: attacker self-funds puppet P plus two leg members, all
SV 100.00, three hundred real dollars a month).

Attacker after: spine 24.00, gen1 override 3.60 (0.015 x group CV 240.00),
second-leg bonus 1.60, total 29.20. Attack yield: 21.20 a month against
300.00 a month of spend: **7.07 cents returned per attack dollar, a 92.9
percent monthly loss, forever**, because Law A makes the puppet a
subscription, not a purchase. The structural floor the spec claims (no
self-funded dollar can return more than 20 cents under the revenue cap) holds
with room to spare. The restructuring variant (mint Builders from EXISTING
recruits, zero new money) is attack 1's K2 arrangement and also loses (44.00
versus 50.00 flat).

**Documentation finding, real and owed:** the spec's anti-gaming arithmetic
is still printed at the DRAFT rates that v1.1 itself retired. Section 11:
"generation 1 on group CV 240.00 = 9.60" and "25.60 a month best case" (at
the rates of record: 3.60 and 21.20); section 11's splitting table "0.05 x
1.00 x V/2 = 0.0250 x V" (now 0.020, giving 0.0100 x V); 12A(b): "0.0575 x
80.00 = 4.60: a 95 percent monthly loss" (now 0.025 x 80.00 = 2.00, a 98
percent loss); 12A(d)'s worked order: "4 percent x 80.00 = 3.20" and "5
percent x 80.00 = 4.00" with the 19.20-of-20.00 total (at rates of record the
same order pays 12.00 + 1.20 + 1.60 = 14.80 of 20.00). v1.1 re-anchored
12A(e) to the measured census and explicitly left the section 10 gate fixture
at draft rates (correctly, the fixture is a contract); it did NOT re-anchor
sections 11, 12A(b), 12A(d), and they are presentation sections. Every
conclusion SURVIVES re-anchoring (the attacks lose harder at the calibrated
rates), which is exactly why the stale numbers are embarrassing rather than
dangerous: a hostile reader catches the spec quoting rates its own section 5
supersedes, the same class of catch as the verifier's MEDIUM-2 density
sentence.

**VERDICT 3: HELD.** The qualification gate plus the revenue cap price
Builder-farming out at 7 cents on the dollar, engine-measured. One spec
amendment owed: re-anchor sections 11, 12A(b), 12A(d) to the rates of record
(or annotate each as draft-rate teaching arithmetic the way section 10
already is).

## Attack 4: the 12A questions re-asked cold

I re-derived every 12A answer from the live calibrated census run (run 86)
with my own queries, ignoring the spec's numbers until after.

**(a) Override stacking blows the budget.** My census sweep: worst source has
layer 2 claims at 0.56 of its pool (the spec's worked worst case of 2.4x is a
deliberate fixture, fine); ZERO of 1,001 sources pay over pool; my own
19-member stack (attack 2b) pushed claims to 15.20 against a 20.00 pool with
spine at 12.00 and the source paid 19.999996. The verifier's three hostile
constructions (repeating-decimal factor, exhausted pool, walk edge) all held
independently of mine. Concur: the invariant is the arithmetic, not a policy.

**(b) Sandbagging and splitting.** Re-answered by attacks 1 and 2 above:
ranking channel HELD, splitting HELD, but the answer's printed numbers are
stale (finding in attack 3) and the waterfall channel (2b) is a real
qualifier the 12A(b) answer does not mention.

**(c) Decay churns leaders.** Re-answered by attack 6 below, with the
one-line-earner shock as the caveat.

**(d) Double-paying volume.** Confirmed bounded per source in every run I
made; the M8-style decomposition at rates of record is 14.80 of a 20.00 pool.
Stale printed numbers, owed with attack 3's amendment.

**(e) Proration and the field's acceptance. The judged question.** My cold
numbers match the spec's exactly: 120 of 1,001 sources prorate (12.0
percent), 943.68 shaved (638.00 layer 2, 305.68 layer 3), 5.4 percent of the
run. New numbers the spec does NOT carry, and should: **35 of the 207 paid
members (17 percent) have at least one shaved line**; the worst-shaved member
loses 324.14, and the worst RATIO is 21 percent of that member's gross
claims. Exhibit GW-000044: gen1 claim 33.00 paid 22.47, gen2 claim 20.40 paid
13.91, bonus claim 2.40 paid 0.18. That last line is the statement problem in
one row: the member's statement says rate 0.020, basis 120.00, amount 0.17.
Rate times basis is 2.40. The 93 percent haircut on that line is not
recomputable from anything the member can see; it depends on the spine and
override claims of OTHER people on shared sources, per source, at scale 6.
The field-facing sentence the spec commits to ("your base plan pay is never
prorated; the two bonus layers share what the cap leaves; about one source in
eight hits the cap") is TRUE and is carried, and the engine keeps
claimed-versus-paid per line in its traces. Judgment as a field veteran: a
shrunken line a member cannot recompute is survivable ONLY if the statement
itself shows the claim, the paid, and one sentence of why, per line. The data
exists (l2_traces, l3_trace); the commitment to print it on the member
statement does not.

**VERDICT 4: HELD WITH A CAVEAT.** Every 12A number re-derives cleanly, and
12A(e)'s honesty discipline is real. The caveat is binding for presentation:
the statement-level rule (every prorated line shows claimed, paid, and the
one-sentence reason) must be a spec commitment, not a lab internals feature,
and the 35-of-207 member-exposure number rides beside the 12-percent source
number on every surface, because members are what riot, not sources.

## Attack 5: the pitch versus the numbers

The committed documents, read hostile, sentence by sentence, against the
comparison record (all latest seeded-March runs): baseline 14.6085 percent of
CV with 206 paid, plan five calibrated 18.9399 with 207 paid, stairstep
22.8639 with 448 paid, Gini 0.9687 versus baseline 0.9625, top-10-percent
share 95.33 versus 94.25.

First, what the documents do NOT say: I searched every committed document for
an "empty corner" style claim (wide reach AND strong building) and it appears
nowhere. The spec's actual claims are payout-geometry claims with the
behavioral caveat stated (section 12), and after v1.1 the realized numbers
are displayed. The committed text does not overclaim. The DANGER is the oral
pitch: if this plan is ever presented as "wide reach and strong building",
the census contradicts the reach half on the spot: 207 of 1,001 members paid
(20.7 percent), ONE more than the baseline's 206, less than half of
stairstep's 448, and concentration HIGHER than the baseline (Gini 0.9687
versus 0.9625; top-10 share 95.33 versus 94.25). This plan does not widen
reach. It deepens the payoff for development inside roughly the same paid
population. Said that way, it is honest and defensible; said as "reach", it
dies in the room.

Second, the structure-linked 22.9 percent attacked as a metric. Re-derived:
3,983.12 of 17,417.12, 22.87 percent, confirmed. What it measures: the
fraction of the check that the two new layers carry. What it does NOT
measure: pull. My decomposition: only 44 of 1,001 members earn ANY structure
money, and the top FIVE of them take 3,590.97 of the 3,983.12: **90.2 percent
of the entire structure budget lands on five accounts** (94.2 percent on the
top ten). A number that is 22.9 percent of the company check and 90 percent
owned by five people measures that two layers exist and that the tree's apex
captures them; it does not measure a field-wide team-building incentive. The
metric that DOES measure pull is the spec's own metric 2, which neither gate
computed, so I did: within the same SV band, qualified members with at least
one personally sponsored Builder out-earn those with none by **7.9x (52.47
versus 6.66, SV 100 to 149), 92x (725.57 versus 7.90, SV 150 to 299), and
81x (955.31 versus 11.77, SV 300 plus)**; 24 members hold that position
today. That is a real, enormous, honest premium on development, and it is the
number the pitch should lead with, with the participation count (24) said in
the same breath.

**VERDICT 5: HELD WITH A CAVEAT.** No committed sentence overclaims; v1.1's
display discipline is genuinely unusual and creditable. Binding for
presentation: (1) never say "reach" (207 versus 448 is on the record and any
consultant will pull it), say "development premium inside the same paid
population"; (2) never show 22.9 without its two companions: the metric-2
premium (7.9x to 92x by band) and the participation counts (44 earn structure
money; top 5 take 90.2 percent). The naked 22.9 invites exactly the takedown
I just wrote.

## Attack 6: decay churn and check volatility

**Executed, not argued.** I ran the calibrated plan over ALL seven months:
February through July seeded, August real-bridged partial (runs 106, 86, 107,
108, 109, 110, 111), plus a targeted one-month lapse scenario on a real census
member.

The trajectory (percent of CV): Feb 18.5594, Mar 18.9399, Apr 19.1224, May
19.4412, Jun 19.5434, Jul 19.6812. Members paid: 180, 207, 228, 249, 262,
285. (August: 10.375 on 1,600.00 CV, 2 paid, eleven bridged orders; a partial
month, evidence of nothing.) Two readings: (1) 12A(f)'s admitted cost drift
is REAL and now MEASURED: +1.12 points of CV in five month-steps, about 0.22
a month at this field maturity, bounded above by 25 of CV per source
structurally, and (as the spec argues) funded from breakage the price already
carries. The drift TRAJECTORY must be a standing exhibit, per the spec's own
metric discipline; it now exists. (2) Volatility on the seeded months is
mild: 43 members ever earn overrides; across 215 member-month pairs, 22
declines, 4 to 7 members per month with falling override income, ONE total
wipeout, TWO drops over half. HONESTY ITEM: the seeded census is a
growth-biased generator with almost no churn, so these six months CANNOT
certify field-grade volatility; they certify only that decay events are
attributable and countable. The spec's behavioral caveat (section 12) covers
this, and it must ride on any volatility claim.

The mean case, executed on real census structure: GW-000294's entire check is
ONE gen1 override, 7.80, on Builder GW-000369 (group CV 520.00). Scenario
RT-294-LAPSE (run 105): GW-000369 misses qualification ONE month (a holiday,
a card failure). GW-000294's check: 7.80 to **0.00, a 100 percent
month-over-month wipe**, attributed by the watch machinery entirely to
from_reach_lost, exactly as Law A intends and exactly as a field member
experiences it: my check vanished because someone two hops down had a bad
month I may not even have known about. Five members' pay moved in total
(GW-000369 lost 33.20 of their own; three uplines lost 4.00 to 12.40 of
spine). Today, single-override earners like GW-000294 are the fragile class:
in July, several members' checks are 87 to 100 percent override lines
(GW-000294 100 percent, GW-000472 90 percent, GW-000303 87 percent).

Does the plan need a smoothing answer before presentation? My ruling as the
hired skeptic: NO grace month in v1 is defensible (the spec's reasoning that
grace blunts the near-upline's retention incentive is coherent, and my attack
2b shows grace would not fix the deeper inversion anyway), PROVIDED the
presentation carries the shock number honestly: a member whose bonus rests on
one Builder can lose 100 percent of that line in one month, and the sponsor's
countermeasure (the intended one) is holding more than one Builder and more
than one leg. What is NOT defensible is presenting Law A's decay with only
the fixture's tidy 9.60 example; RT-294 is the real face of it and must be
shown. Open question 8 should be re-decided by Howard WITH this exhibit and
attack 2b in hand, not on the fixture alone.

**VERDICT 6: HELD WITH A CAVEAT.** Volatility on seeded data is small and
attributable, the drift is real, measured, and bounded, and no-grace is a
coherent v1 ruling. The caveats bind: the RT-294 wipe (100 percent of a
member's check on someone else's bad month) goes into any presentation of Law
A, the drift trajectory (18.56 to 19.68 and climbing) is a standing exhibit,
and no volatility claim rides on seeded months without the section 12
behavioral caveat attached.

## Attack 7: regulatory smell test

Every dollar must trace to product volume, never to recruitment. Verified in
the engine output, not the prose, on run 86 (1,001 members):

- Exactly four reason codes exist; every line's basis is CV (a member's, a
  group's, or a leg's), which is 0.80 x SV, which is product dollars. There
  is NO reason code, line, or parameter that pays on count of recruits,
  enrollments, or sign-ups. Zero lines with null or non-positive basis.
- ZERO self-source lines (no member is ever paid on their own volume as
  source; overrides pay the UPLINE on a Builder's group; the bonus basis is a
  leg, which excludes self by construction).
- Pay-to-play, executed: fixture REDTEAM-P5-SOLO (run 100), one member, SV
  10,000.00, no downline: total earned **0.00**, rank member. Own purchases
  buy qualification (the standard low gate: SV 100.00, and customer volume
  counts toward it per the live plan v1.2), never income, never rank: Builder
  requires two ACTIVE legs, which are two OTHER humans each with SV 100.00
  this month; Leader and up require TV, which excludes self.
- Inventory-loading spike attack: blunted by the ten-month spreading rule
  (confirmed in `docs\COMP-PLAN-SPEC.md` sections 5A.4 and 6.3: a one-time
  purchase's volume recognizes across ten months), so a 2,000.00 one-time buy
  cannot spike one month's SV or TV for a rank grab.
- The 20-percent-of-revenue ceiling is enforced inside the calculation per
  order (zero violations in every run I made or re-swept, including my own
  hostile stack), which is the posture regulators and processors like to see:
  the payout ratio CANNOT drift above the published promise.

Residual notes for the record, not findings: qualification via own purchase
(SV 100.00 a month) is industry-standard and low, and the customer-volume
path mitigates it; income disclosure discipline (median earner numbers: 207
of 1,001 paid, median check small) will matter the day this leaves the lab,
and the lab already computes everything such a disclosure needs.

**VERDICT 7: HELD.** Volume-traced pay throughout, engine-verified; no
recruitment payment exists; rank and income are not purchasable with own
spend (0.00 on 10,000.00 SV, executed); the cap is structural.

## Attack 8: the one-page test

I wrote the member-facing explanation below from the spec alone, in one pass,
and it fits one page. The plan is explainable; the base plan carries over
verbatim, the two additions each take two sentences, and the two laws take
four. The one hard-to-say piece is proration (see attack 4's caveat), which I
could state honestly in two lines only because the spine is never touched;
that structural choice is what makes the page possible.

**VERDICT 8: PASSED.** Artifact follows at the end of this document.

---

## What must change (the exact list), then this gate is a PASS

Spec amendments, same-day class, none a redesign:

1. **Section 6 and 12A(c), the retention-agent claim (from attack 2b, BROKE
   IT):** scope it to the generations that actually lose (the one to two
   nearest Builder generations), and name the inversion: above a pool-binding
   stack, senior uplines' pay RISES on a downline lapse (fixture
   REDTEAM-P5-RELIEF: six members up, E +7.44, on a 100.00 SV lapse; 120 of
   1,001 census sources bind at the rates of record). Add the lab metric:
   per run pair, count of members whose total rose attributable to a
   downline lapse, with summed gain, so the inversion is watched.
2. **Sections 11, 12A(b), 12A(d) (from attack 3):** re-anchor the worked
   anti-gaming and double-pay numbers to the calibrated rates of record, or
   mark each explicitly as draft-rate teaching arithmetic the way section 10
   already is. Every conclusion strengthens at the rates of record; only the
   printed numbers are stale.
3. **12A(e) (from attack 4):** add the member-level exposure beside the
   source-level number (35 of 207 paid members carry a shaved line; worst
   member ratio 21 percent of gross claims), and commit, as spec text, that
   any member-facing statement prints claimed, paid, and a one-line reason on
   every prorated line (the engine traces already hold the data).

Presentation rules, binding on any deck or conversation:

4. Never claim reach. 207 versus the baseline's 206 and stairstep's 448 are
   on the record. The honest sentence: same paid population, radically deeper
   development premium.
5. Never show the 22.9 percent structure share without its companions: the
   builder-developer premium (7.9x to 92x by SV band, spec metric 2, computed
   in this review) and the capture numbers (44 members earn structure money;
   the top five take 90.2 percent of it).
6. Present Law A with the RT-294 exhibit (a real member's check going 7.80 to
   0.00 because a Builder two hops down missed one month), not only the
   fixture's 9.60; and show the drift trajectory (18.56 to 19.68 percent of
   CV, February to July) as a standing chart. Re-decide open question 8 (the
   grace month) with exhibits 2b and RT-294 in hand; I concur with no-grace
   for v1 either way.

When items 1 through 3 are amended into the spec (items 4 through 6 are
conduct, checkable at deck time), the red-team gate is a PASS: I could not
break the waterfall, the walk, the gates, the calibration honesty, or the
regulatory posture, and I tried with twenty years of scars.

---

## Lab side effects of this review (recorded per charter)

Runs 95 to 104 (hand fixtures: SPLIT-K2/K3/K6, FARM-BASE/PUP, SOLO,
SBMONO-BASE/STARVE, RELIEF-BASE/LAPSE), 105 (RT-294-LAPSE on seeded March,
counterfactual), 106 to 111 (calibrated identity runs, February and April
through August; March was existing run 86). Scenarios RT-FIX (15),
RT-SB-STARVE (16), RT-SB-RELIEF (17), RT-294-LAPSE (18), all locked before
use. Watchlist entries LAB-RT-E, LAB-RT-B1, GW-000294 added for the
watched-account attacks and set inactive afterward. All writes lab schema
only; schema app untouched.

---

## ARTIFACT: the one-page member explanation (from attack 8)

### The Orvanna Builder Plan on one page

Words used: Sales Volume (SV) is the dollar volume of product bought by you
and your customers this month. Commissionable Volume (CV) is 80 percent of
SV. You are ACTIVE in any month your SV is at least 100 (one subscription, or
your customers' orders). A LEG is one person you personally sponsored, plus
everyone under them.

**1. Base pay (today's plan, unchanged).** You earn a percent of the CV of
each person in your organization by their level below you: 10, 5, 5, 3, 2
percent through five levels. Your rank sets how deep you are paid: two or
more active legs makes you a Builder (paid two levels); larger teams unlock
Leader, Director, and Executive (three, four, five levels).

**2. Builder override (new).** Any month someone in your organization holds
Builder rank, the person who developed them earns 1.5 percent of that
Builder's WHOLE group volume, and the developer one generation further up
earns 1.0 percent. Nobody ever loses volume when someone below them ranks up;
developing a Builder is pure addition to your check.

**3. Second-team bonus (new).** Rank your legs by volume. If at least two of
your legs are active, you earn 2.0 percent of your SECOND-biggest leg's
volume (2.3 percent with three active legs, 2.5 percent with four or more).
One giant leg pays nothing extra, on purpose: the plan pays you to build a
second real team, then a third.

**Fresh every month.** Everything above recomputes each month from that
month's actual orders. Nothing is banked, nothing is grandfathered. If your
Builder lapses, your override on them stops that month; helping your people
stay active is literally worth money to you, every month, and the plan tells
you exactly how much.

**The 20 percent promise.** No order ever pays out more than 20 percent of
its price, enforced order by order inside the math itself. Your BASE pay is
never reduced by this. When an order's cap is reached, the two bonus layers
on that order share what remains, so a bonus line can pay less than its
listed rate; in a typical month about one source in eight is at its cap, and
your statement marks any reduced line with what it would have paid and why.

**What never pays:** recruiting (no dollar is ever paid for signing someone
up; only product volume pays), your own purchases (they keep you active; they
never earn you commission), one giant leg, and shell accounts (bonuses count
only ACTIVE legs: real people with real 100 SV months).
