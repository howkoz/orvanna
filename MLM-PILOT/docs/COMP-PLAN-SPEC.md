# MLM Pilot Compensation Plan Specification, version v1.1

As of 2026-08-13 (v1.1, same day as v1.0: product concept locked to digital agent
subscriptions and the qualification gate moved from 50 to 100 volume points, both per
Howard; the v1.0 worked example was rebuilt accordingly). mlm-comp-engineer must
reproduce section 7 exactly; mlm-verifier recomputes it independently.

Acronym key: Multi-Level Marketing (MLM), Personal Volume (PV), Sales Volume (SV),
Commissionable Volume (CV), Team Volume (TV), Software as a Service (SaaS),
Quality Assurance (QA).

## 1. The product: digital AI agents, sold as monthly subscriptions

Globex sells AI agents as SaaS subscriptions. Two tiers:

| Tier | What they are | Price / month | PV / month |
|---|---|---|---|
| Domain agents | run one business function end to end: Payment Agent, Shipping Agent, Pricing Agent, Inventory Agent, Marketing Agent, Tax Agent | $100.00 | 100 |
| Support agents | staff roles that assist: Software Engineer, Quality Assurance, Secretary, Chief Executive, Accounting, Customer Care | $50.00 | 50 |

PV equals dollars one to one. A subscription bills and grants its PV EVERY month it is
active; cancel and the PV stops. There is no physical product, no shipping, no
inventory.

**Subscription mechanics:** each member holds zero or more subscriptions. On the first
day of each month, every active subscription generates one order for that volume
month. Churn = the subscription is cancelled and generates nothing from its cancel
month onward. (The schema's subscriptions table and the seed generator implement
this; the comp engine only ever sees the generated orders.)

## 2. Volumes

- **SV (personal, monthly):** sum of PV across the member's completed orders in that
  volume month. Two decimals.
- **CV (personal, monthly):** 0.80 times SV, rounded half up to 2 decimals. CV is the
  base every commission percentage applies to.
- **TV (monthly):** the sum of SV of every member STRICTLY BELOW the member in the
  genealogy (whole subtree, same month). TV excludes the member's own SV
  (open question 1).

## 3. Qualification (the single gate)

- **Qualified** = SV greater than or equal to 100.00 in the month. One threshold does
  both jobs: a qualified member may be PAID commissions that month, and a leg counts
  as ACTIVE only if its frontline member is qualified.
- Equivalents: one domain agent, or two support agents, or any mix reaching 100.
  A member holding a single support agent (50 PV) is enrolled but not qualified.
- Boundary: exactly 100.00 qualifies. Every threshold in this plan is
  "greater than or equal to".
- Qualification is monthly; it resets every period. No grace months in v1.

**Design note for the real world (teaching point, not a v1 rule):** in this v1 the
gate is met through the member's own subscriptions. Real-world regulators criticize
plans where qualification comes only from self-purchase (pay to play). Version 2
therefore adds customer sales (buyer_role already exists on orders) so qualification
can rest on volume sold to customers, not only volume bought.

## 4. Ranks (recomputed from scratch every month)

A **leg** is one frontline (directly sponsored) member together with that member's
whole subtree. A leg is ACTIVE when its frontline member is qualified that month. A
leg "contains a Builder" when ANY member in the leg earned that rank this month.

| Rank | Requirements (all must hold, same month) | Paid depth |
|---|---|---|
| Member | enrolled | 1 |
| Builder | SV >= 100 AND >= 2 active legs | 2 |
| Leader | TV >= 2,500 AND >= 3 active legs | 3 |
| Director | TV >= 10,000 AND >= 2 legs each containing a Builder (or higher) | 4 |
| Executive | TV >= 40,000 AND >= 2 legs each containing a Leader (or higher) | 5 |

A member holds the HIGHEST rank whose requirements they meet. Evaluation is
deterministic and non-circular: Builder depends only on qualification; Leader on TV
plus active legs; Director references downline Builder qualification; Executive
references downline Leader qualification. Compute in that order for the whole tree.
(Note Builder's SV >= 100 is now identical to the qualification gate, so Builder
reduces to: qualified AND 2 active legs.)

## 5. Commissions (unilevel level pay, the only payout type in v1)

- Rates by level (tree distance from earner to source member):
  level 1: 10 percent, level 2: 5, level 3: 5, level 4: 3, level 5: 2, of the source
  member's monthly CV.
- The earner is paid on levels 1 through their paid depth (rank table above).
- The earner must be QUALIFIED that month to be paid anything.
- The SOURCE member's own qualification does NOT matter: all CV pays upline, whoever
  generated it. (An unqualified member's 50 PV still pays their upline; it just does
  not qualify or pay the member themselves.)
- NO COMPRESSION in v1. Levels are plain tree distance. Volume nobody is paid on
  (unqualified earner, or depth out of reach) is breakage. Compression is the flagship
  v2 feature.
- Rounding: each commission line amount = rate times source CV, rounded half up to
  2 decimals AT THE LINE LEVEL. Member totals and company totals are sums of rounded
  lines, never re-rounded.
- Money math per one domain agent ($100, CV 80.00): the five levels can earn at most
  8.00 + 4.00 + 4.00 + 2.40 + 1.60 = 20.00, i.e. 20 percent of revenue before
  breakage.

## 6. Edge cases, decided

1. **Roots** (no sponsor): earn normally on their downline; nobody earns on them.
2. **Multiple subscriptions and orders per month:** SV aggregates first; CV is
   computed once per member-month, not per order.
3. **Month boundary:** an order belongs to the volume month stamped at creation
   (subscription generation stamps the first of the month, Coordinated Universal Time
   (UTC)). Late edits never move volume.
4. **Refunds and mid-month cancels:** out of scope for v1 seeds ('completed' orders
   only); a cancel simply stops FUTURE months.
5. **Determinism:** same subscriptions plus same tree plus spec v1.1 equals identical
   output to the cent, always. A rerun creates a new run id; finalized statements
   never change.

## 7. Worked example (the contract for engine and verifier)

Ten members, one month. Tree (sponsor -> children):
M1 -> M2, M3, M4; M2 -> M5, M6; M3 -> M7, M8; M5 -> M9; M8 -> M10.

### 7.1 Subscriptions, volumes, qualification

| Member | Subscriptions held | SV | CV (0.80 x SV) | Qualified (SV >= 100)? | TV (subtree, excl. self) |
|---|---|---|---|---|---|
| M1 | Payment + Pricing (2 domain) | 200.00 | 160.00 | yes | 2,500.00 |
| M2 | Payment + Software Engineer | 150.00 | 120.00 | yes | 500.00 |
| M3 | Shipping (1 domain) | 100.00 | 80.00 | yes (boundary) | 1,650.00 |
| M4 | QA + Secretary (2 support) | 100.00 | 80.00 | yes (boundary) | 0.00 |
| M5 | Accounting (1 support) | 50.00 | 40.00 | NO | 300.00 |
| M6 | Marketing + Customer Care | 150.00 | 120.00 | yes | 0.00 |
| M7 | agency stack: 12 domain + 6 support | 1,500.00 | 1,200.00 | yes | 0.00 |
| M8 | Software Engineer + Accounting (2 support) | 100.00 | 80.00 | yes (boundary) | 50.00 |
| M9 | Payment + Shipping + Pricing (3 domain) | 300.00 | 240.00 | yes | 0.00 |
| M10 | Secretary (1 support) | 50.00 | 40.00 | NO | 0.00 |

TV checks: TV(M5) = 300. TV(M8) = 50.
TV(M2) = 50 + 150 + 300 = 500. TV(M3) = 1,500 + 100 + 50 = 1,650.
TV(M1) = 150 + 100 + 100 + 50 + 150 + 1,500 + 100 + 300 + 50 = 2,500 (boundary).

### 7.2 Ranks

| Member | Test | Rank | Paid depth |
|---|---|---|---|
| M1 | TV 2,500 >= 2,500 AND active legs M2, M3, M4 = 3 | **Leader** (boundary) | 3 |
| M2 | qualified BUT active legs: M5 unqualified, M6 qualified = only 1 | Member | 1 |
| M3 | SV 100 (boundary) AND active legs M7, M8 = 2 | **Builder** | 2 |
| M4 | qualified, no legs | Member | 1 |
| M5 | unqualified | Member | 1, but earns nothing |
| M8 | qualified, only leg M10 is unqualified = 0 active legs | Member | 1 |
| all others | fail Builder | Member | 1 |

Teaching cases: M2 loses Builder because the M5 leg's frontline is unqualified; M10's
50 PV does not qualify M10 but still pays upline.

### 7.3 Commission lines (every line in the run)

| Earner | Source | Level | Source CV | Rate | Amount |
|---|---|---|---|---|---|
| M1 | M2 | 1 | 120.00 | 10% | 12.00 |
| M1 | M3 | 1 | 80.00 | 10% | 8.00 |
| M1 | M4 | 1 | 80.00 | 10% | 8.00 |
| M1 | M5 | 2 | 40.00 | 5% | 2.00 |
| M1 | M6 | 2 | 120.00 | 5% | 6.00 |
| M1 | M7 | 2 | 1,200.00 | 5% | 60.00 |
| M1 | M8 | 2 | 80.00 | 5% | 4.00 |
| M1 | M9 | 3 | 240.00 | 5% | 12.00 |
| M1 | M10 | 3 | 40.00 | 5% | 2.00 |
| M2 | M5 | 1 | 40.00 | 10% | 4.00 |
| M2 | M6 | 1 | 120.00 | 10% | 12.00 |
| M3 | M7 | 1 | 1,200.00 | 10% | 120.00 |
| M3 | M8 | 1 | 80.00 | 10% | 8.00 |
| M3 | M10 | 2 | 40.00 | 5% | 2.00 |
| M8 | M10 | 1 | 40.00 | 10% | 4.00 |

### 7.4 Statement totals and company totals

| Earner | Total |
|---|---|
| M1 | 114.00 |
| M2 | 16.00 |
| M3 | 130.00 |
| M8 | 4.00 |
| everyone else | 0.00 |

Company: total SV 2,700.00; total CV 2,160.00; total payout **264.00**; members paid
**4**; payout rate 12.22 percent of CV (9.78 percent of SV).

Breakage recorded for understanding (not paid, not stored): M5 is unqualified, so the
10 percent of M9's 240.00 CV (24.00) that would have been M5's level 1 is unpaid; M2's
level 2 claim on M9 (12.00) is out of reach at paid depth 1. No compression rescues
either; both are breakage by design.

## 8. Open questions for Howard (defaults stand unless he overrides)

1. TV currently EXCLUDES the member's own SV (literal roadmap wording). Include it
   instead ("group volume" style)? Default: exclude.
2. Every threshold is inclusive (>=): exactly 100 qualifies, exactly 2,500 is Leader.
   Confirm? Default: inclusive.
3. Ranks recompute monthly with no retention ("you are what you did this month").
   Retention or highest-achieved titles are v2 candidates. Confirm monthly-pure for v1?
4. Source volume pays upline regardless of the source member's own qualification
   (decided in section 5). Confirm? Default: yes, it pays.
