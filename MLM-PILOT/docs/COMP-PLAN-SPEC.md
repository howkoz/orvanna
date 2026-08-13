# MLM Pilot Compensation Plan Specification, version v1.0

As of 2026-08-13. Author: architect role (written inline by the main session; content
follows the architect brief). The numbers below are the roadmap draft Howard approved,
made precise. Where a rule had to be DECIDED to make the plan deterministic, the
decision is marked DECIDED and listed again in section 7 for Howard's confirmation.
mlm-comp-engineer must reproduce section 6 exactly; mlm-verifier recomputes it
independently.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable Volume (CV),
Team Volume (TV).

## 1. Volumes

- **SV (personal, monthly):** sum of (quantity times unit_volume) across the member's
  completed orders stamped with that volume month. Two decimals.
- **CV (personal, monthly):** 0.80 times SV, rounded half up to 2 decimals. CV is the
  base every commission percentage applies to.
- **TV (monthly):** the sum of SV of every member STRICTLY BELOW the member in the
  genealogy (the whole subtree), same month. DECIDED: TV excludes the member's own SV,
  matching the roadmap draft wording. Alternative (include own SV) is open question 1.

## 2. Activity

- **Active** = SV greater than or equal to 50.00 in the month. DECIDED: exactly 50.00
  counts as active. All plan thresholds are "greater than or equal to".
- Activity is monthly; it resets every period. No grace months in v1.

## 3. Ranks (recomputed from scratch every month)

A **leg** is one frontline (directly sponsored) member together with that member's
whole subtree. DECIDED: a leg is ACTIVE when its frontline member is personally active
that month (subtree activity does not rescue an inactive frontline). A leg
"contains a Builder" when ANY member in the leg (frontline included) earned that rank
this month.

| Rank | Requirements (all must hold, same month) | Paid depth |
|---|---|---|
| Member | enrolled | 1 |
| Builder | SV >= 100 AND >= 2 active legs | 2 |
| Leader | TV >= 2,500 AND >= 3 active legs | 3 |
| Director | TV >= 10,000 AND >= 2 legs each containing a Builder (or higher) | 4 |
| Executive | TV >= 40,000 AND >= 2 legs each containing a Leader (or higher) | 5 |

A member holds the HIGHEST rank whose requirements they meet. Evaluation is
deterministic and non-circular: Builder depends only on activity; Leader on TV plus
active legs; Director references downline Builder qualification; Executive references
downline Leader qualification. Compute in that order for the whole tree.

## 4. Commissions (unilevel level pay, the only payout type in v1)

- Rates by level (tree distance from earner to source member):
  level 1: 10 percent, level 2: 5, level 3: 5, level 4: 3, level 5: 2, of the source
  member's monthly CV.
- The earner is paid on levels 1 through their paid depth (rank table above).
- DECIDED: the earner must be ACTIVE that month to be paid anything. An inactive
  member's would-be earnings are unpaid (recorded nowhere but reportable; see breakage
  note in section 6).
- DECIDED: NO COMPRESSION in v1. Levels are plain tree distance. Volume that no one is
  paid on (inactive earner, or depth out of reach) is breakage. Compression is the
  flagship v2 feature.
- Rounding: each commission line amount = rate times source CV, rounded half up to
  2 decimals AT THE LINE LEVEL. Member totals and company totals are sums of rounded
  lines, never re-rounded.

## 5. Edge cases, decided

1. **Roots** (no sponsor): earn normally on their downline; nobody earns on them.
2. **Multiple orders per member per month:** SV aggregates before CV is derived; CV is
   computed once per member-month, not per order.
3. **Month boundary:** an order belongs to the volume month stamped at creation from
   its timestamp in Coordinated Universal Time (UTC). Late edits never move volume.
4. **Refunds:** out of scope for v1 seeds ('completed' only); the status column exists
   so v2 can claw back.
5. **Ties and boundaries:** every threshold is inclusive (>=). SV exactly 50 is active;
   TV exactly 2,500 with 3 active legs is Leader; SV exactly 100 with 2 active legs is
   Builder.
6. **Determinism:** same orders plus same tree plus spec v1.0 equals identical output
   to the cent, always. A rerun creates a new run id; finalized statements never change.

## 6. Worked example (the contract for engine and verifier)

Ten members, one month. Tree (sponsor -> children):
M1 -> M2, M3, M4; M2 -> M5, M6; M3 -> M7, M8; M5 -> M9; M8 -> M10.
Depth reaches 4 (M1-M2-M5-M9 and M1-M3-M8-M10).

### 6.1 Volumes and activity

| Member | SV | CV (0.80 x SV) | Active (SV >= 50)? | TV (subtree, excl. self) |
|---|---|---|---|---|
| M1 | 200.00 | 160.00 | yes | 2,500.00 |
| M2 | 150.00 | 120.00 | yes | 560.00 |
| M3 | 100.00 | 80.00 | yes | 1,630.00 |
| M4 | 60.00 | 48.00 | yes | 0.00 |
| M5 | 40.00 | 32.00 | NO | 400.00 |
| M6 | 120.00 | 96.00 | yes | 0.00 |
| M7 | 1,500.00 | 1,200.00 | yes | 0.00 |
| M8 | 80.00 | 64.00 | yes | 50.00 |
| M9 | 400.00 | 320.00 | yes | 0.00 |
| M10 | 50.00 | 40.00 | yes (boundary) | 0.00 |

TV checks: TV(M2) = 40 + 120 + 400 = 560. TV(M3) = 1,500 + 80 + 50 = 1,630.
TV(M1) = 150 + 100 + 60 + 40 + 120 + 1,500 + 80 + 400 + 50 = 2,500 (boundary).

### 6.2 Ranks

| Member | Test | Rank | Paid depth |
|---|---|---|---|
| M1 | TV 2,500 >= 2,500 AND active legs M2, M3, M4 = 3 | **Leader** (boundary case) | 3 |
| M2 | SV 150 >= 100 BUT active legs: M5 inactive, M6 active = only 1 | Member | 1 |
| M3 | SV 100 >= 100 (boundary) AND active legs M7, M8 = 2 | **Builder** | 2 |
| M5 | inactive | Member | 1 (but earns nothing, inactive) |
| all others | fail Builder | Member | 1 |

Note the teaching case: M2 has strong personal volume but loses Builder because the
M5 leg's frontline is inactive.

### 6.3 Commission lines (every line in the run)

| Earner | Source | Level | Source CV | Rate | Amount |
|---|---|---|---|---|---|
| M1 | M2 | 1 | 120.00 | 10% | 12.00 |
| M1 | M3 | 1 | 80.00 | 10% | 8.00 |
| M1 | M4 | 1 | 48.00 | 10% | 4.80 |
| M1 | M5 | 2 | 32.00 | 5% | 1.60 |
| M1 | M6 | 2 | 96.00 | 5% | 4.80 |
| M1 | M7 | 2 | 1,200.00 | 5% | 60.00 |
| M1 | M8 | 2 | 64.00 | 5% | 3.20 |
| M1 | M9 | 3 | 320.00 | 5% | 16.00 |
| M1 | M10 | 3 | 40.00 | 5% | 2.00 |
| M2 | M5 | 1 | 32.00 | 10% | 3.20 |
| M2 | M6 | 1 | 96.00 | 10% | 9.60 |
| M3 | M7 | 1 | 1,200.00 | 10% | 120.00 |
| M3 | M8 | 1 | 64.00 | 10% | 6.40 |
| M3 | M10 | 2 | 40.00 | 5% | 2.00 |
| M8 | M10 | 1 | 40.00 | 10% | 4.00 |

### 6.4 Statement totals and company totals

| Earner | Total |
|---|---|
| M1 | 112.40 |
| M2 | 12.80 |
| M3 | 128.40 |
| M8 | 4.00 |
| everyone else | 0.00 |

Company: total SV 2,700.00; total CV 2,160.00; total payout **257.60**; members paid
**4**; payout rate 11.93 percent of CV (9.54 percent of SV).

Breakage recorded for understanding (not paid, not stored): M5 would have earned 10
percent of M9's 320.00 = 32.00 but is inactive; M2's level 2 claim on M9 (16.00) is out
of reach at paid depth 1. No compression rescues either; both are breakage by design.

## 7. Open questions for Howard (defaults stand unless he overrides)

1. TV currently EXCLUDES the member's own SV (literal roadmap wording). Include it
   instead ("group volume" style)? Default: exclude.
2. Earner must be active to be paid. Confirm? Default: yes, active required.
3. All thresholds inclusive (>=). Confirm? Default: inclusive.
4. Ranks recompute monthly with no retention ("you are what you did this month").
   Retention or highest-achieved titles are v2 candidates. Confirm monthly-pure for v1?
