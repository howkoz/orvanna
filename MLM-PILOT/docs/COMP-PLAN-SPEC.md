# MLM Pilot Compensation Plan Specification, version v1.3

As of 2026-08-13 (v1.3, Howard's ruling on the Phase 3 verifier's finding: a member
must be QUALIFIED, SV >= 100, to HOLD any rank above Member; deployed and all six
months rerun same day. v1.2 added customer accounts: customers buy through a referring
member and their volume rolls up at purchase time; customers never earn. v1.1 locked
the agent product and the 100 PV gate). The worked example is unchanged by v1.3 (its
only high-rank holders were already qualified). mlm-comp-engineer must reproduce
section 7 exactly; mlm-verifier recomputes it independently.

**Amendment 2026-08-15: section 5A, Instant Payout.** Terms APPROVED by Howard at **20
percent of the order price**, with a rule he supplied that it **does not roll up to the
upline**. **It is not built and it pays nothing.** Chargeback recovery is the one open
question and it is the gate on building it. Nothing in sections 1 through 5 or 6 through 8
is changed by this amendment, because Instant Payout consumes no volume and writes no level
pay. The engine, the worked example in section 7 and all six finalized runs are untouched.

Acronym key: Multi-Level Marketing (MLM), Personal Volume (PV), Sales Volume (SV),
Commissionable Volume (CV), Team Volume (TV), Software as a Service (SaaS),
Quality Assurance (QA).

## 1. The product: digital AI agents, sold as monthly subscriptions

Orvanna sells AI agents as SaaS subscriptions. Two tiers:

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

**Customers (v1.2):** anyone may buy agents as a CUSTOMER attached to one referring
member, without joining the genealogy. The customer's order is booked onto the
referring member's account (tagged buyer_role 'retail_customer' with the customer's
identity on the order for the receipt), so its full PV counts in that member's SV:
qualification, CV, TV, and upline pay all include it automatically. Customers never
qualify, never hold rank, and never earn commissions. Rationale on the record: this
also means a member's qualification can rest on volume SOLD, not only volume bought,
the plain-dealing property regulators look for.

## 2. Volumes

- **SV (personal, monthly):** sum of PV across ALL completed orders booked to the
  member's account in that volume month, whether bought by the member themselves
  (buyer_role 'member') or by one of their customers (buyer_role 'retail_customer').
  Two decimals.
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
| Builder | QUALIFIED (SV >= 100) AND >= 2 active legs | 2 |
| Leader | QUALIFIED AND TV >= 2,500 AND >= 3 active legs | 3 |
| Director | QUALIFIED AND TV >= 10,000 AND >= 2 legs each containing a Builder (or higher) | 4 |
| Executive | QUALIFIED AND TV >= 40,000 AND >= 2 legs each containing a Leader (or higher) | 5 |

(v1.3: the QUALIFIED requirement on Leader, Director, and Executive is Howard's ruling
of 2026-08-13; before that, team volume and legs alone could hold a high rank.)

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

## 5A. Instant Payout (TERMS APPROVED 2026-08-15 by Howard; NOT BUILT)

**Amendment note 1, 2026-08-15.** Added on Howard's instruction, "log that in your notes as a
rule of one of the commission rules". Adopted as a rule with no design and five open
questions. No surrounding rule was changed.

**Amendment note 2, 2026-08-15, later the same day.** Howard's words: **"20 on instant payout
and it does not roll up to the upline"**. This amendment records the **approved rate of 20
percent of the order price**, closes open questions 1, 2, 3 and 5, and adds a **new rule he
supplied, the no-roll-up rule**, as 5A.3 below. **Open question 4, chargeback recovery,
remains open and is now the sole gate on building this.** No surrounding rule is changed by
this amendment: sections 1 through 5 and 6 through 8 are untouched, because Instant Payout
consumes no volume and writes no level pay.

### 5A.1 The rule

- **Name.** The mechanism is called **Instant Payout**, and the name is normative: it is to be
  used in the plan, in the field, and in any table, column, or function built for it.
- **What it is.** An immediate payout on a first order, paid at the moment the payment
  succeeds rather than in the end-of-month run.
- **Status.** **Terms approved. Not built.** There is no migration, no engine change, no
  column and no function. It pays nothing and it must not be described to anyone as available.
  An approved-but-unbuilt mechanism is the one people begin describing as though it works.
- **Rationale on the record.** Immediate payout on a first order is the strongest known lever
  for a new distributor to begin selling, because the gap between effort and reward is what
  kills early momentum.

### 5A.2 The approved terms

| # | Term | The rule |
|---|---|---|
| 1 | Who is paid | The **sponsor**, meaning the member who personally enrolled the buyer. Never the buyer. This mechanism pays for selling, not for buying. |
| 2 | Trigger | The **first order ever** placed by a member the sponsor personally enrolled, placed **within 30 days of that member's enrolment date**. One Instant Payout per sponsored member, ever. |
| 3 | Basis | The **order price**, excluding tax and any activation fee. **Not Commissionable Volume**, which closes open question 2 and dissolves the spreading collision in 5A.4. |
| 4 | **Rate** | **20 percent of that price.** Approved by Howard, 2026-08-15. |
| 5 | Cap per event | The basis is capped at **250.00**, so no single Instant Payout exceeds **50.00**. |
| 6 | Cap per sponsor | At most **3** Instant Payouts to one sponsor in one calendar month. |
| 7 | Eligibility of the payee | The sponsor must already have at least one **completed purchase** of their own. **No monthly qualification gate applies**, because a qualified month cannot be known at the instant a payment succeeds. This closes open question 5. |
| 8 | When it is paid | At the moment `payment_status` reaches `succeeded`, which is the only status backed by a fresh retrieve from the processor and an exact amount match. |
| 9 | Placement | A real-time payment, reconciled by the monthly batch rather than computed by it. One ledger. This closes open question 3. |
| 10 | Against level pay | **In addition** to level 1 pay, never instead of it. No ordinary commission line is suppressed and **nothing in section 5 changes**. |
| 11 | Against volume | It consumes **no volume**. Sales Volume, Commissionable Volume, Team Volume, every rank, and the ten-month spreading rule are untouched by it. |
| 12 | Recovery | Recovered from the member's next monthly commission run. **See 5A.5: this does not exist and is the gate on the whole mechanism.** |
| 13 | Ledger | Written to `app.commission_lines` with `payout_type = 'instant_payout'`, and a recovery with `payout_type = 'instant_payout_clawback'`, so the two kinds of money never merge silently in any existing report. |

### 5A.3 The no-roll-up rule (added by Howard, 2026-08-15)

**RULE: an Instant Payout is TERMINAL AT THE SPONSOR. It pays the sponsor and nobody above
them.**

Howard's words: "it does not roll up to the upline". This is stated as a rule rather than left
as a consequence of term 3, because a future implementer who changed the basis, or who wrote
an Instant Payout as an order row so that it would show on a report, would break it without
intending to.

Four prohibitions, each of which is a way this could go wrong in code:

1. **No commission lines above the sponsor.** One qualifying event produces exactly **one**
   line, to **one** earner. It never produces a level 2, 3, 4 or 5 line for the sponsor's own
   upline.
2. **No volume anywhere.** The amount is never written into `app.orders` or
   `app.order_lines`, and never enters Sales Volume, Commissionable Volume or Team Volume for
   anybody, including the sponsor who received it.
3. **No effect on rank or qualification.** Receiving an Instant Payout does not help the
   sponsor reach the 100.00 qualification threshold, does not count toward any Team Volume
   threshold, and does not make any leg active.
4. **Paid depth does not apply.** Every other payment in this plan is gated by the earner's
   paid depth. An Instant Payout has no level, so there is nothing for paid depth to gate. An
   Executive and a plain Member receive an identical Instant Payout on an identical first
   order.

**Why the rule earns its place beyond being Howard's instruction.** Instant Payout pays out of
money still inside the chargeback window. A payment that rolled up would spread that exposure
across five people, and a recovery would then have to reach five balances. Terminal at the
sponsor means one payee, one amount, one source order, and one balance line to reverse, which
is what makes the recovery path in 5A.5 tractable at all.

### 5A.4 The collision with section 6.3 and with the spreading rule, now resolved

Every other payout in this plan resolves once, at month end, inside a self-contained calendar
month. An immediate payout does not, which is resolved by term 9: a real-time payment
reconciled by the batch, not computed by it.

Separately, a one-time purchase's volume is recognised across ten months (Howard, 2026-08-15),
so paying Instant Payout on the full one-time price out of **volume** would pay at once on
volume the plan deliberately declined to recognise at once. **Term 3 dissolves this.** The
basis is the order price, a quantity the receipt already carries and the processor already
confirmed, so no deferred volume is consumed and the ten-month schedule is untouched.

### 5A.5 The one open question, which is the gate

**Open question 4, chargeback recovery, is still open, and the mechanism may not be built
until it is answered and the answer is implemented.**

Today: `app.demo_orders.payment_status` permits only `created`, `processing`, `succeeded`,
`failed`, `abandoned`, with **no refunded and no charged-back state**; a trigger refuses to
move a row out of a terminal state and `succeeded` is terminal; `app.orders.status = 'refunded'`
has never been written by any code path; there is no member balance and no concept of a
negative one. **No clawback path exists anywhere in this system.** The chargeback window runs
for months, so Instant Payout pays out of money that can still be taken back.

Four pieces have to exist first, in this order:

1. A `charged_back` and `refunded` payment status, plus a trigger amendment permitting exactly
   the transitions `succeeded -> charged_back` and `succeeded -> refunded` and no others.
2. A member balance that may go negative, one line per event, each carrying the source order
   so a payout and its reversal can always be matched.
3. Settlement inside `app.fn_run_commission`: payable equals commission total minus any
   outstanding negative balance, floored at zero, with the remainder carried forward. The
   commission lines themselves must not change, because they are frozen by trigger once a run
   is final. **A statement says what was earned; a balance says what was paid. They must stay
   separate.**
4. A block on further Instant Payouts to a member carrying an unsettled negative balance.

**Full costing and the option sets behind every term above:**
`DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`. Plain path:
`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\10-INSTANT-PAYOUT-TERMS.md`
Measured on the six finalized runs, March to July 2026: 234 qualifying events, 5,050.00 of
Instant Payout, 0.72 percent of revenue, taking the whole plan from 11.86 to **12.59 percent
of revenue against the 20 percent ceiling**. The no-roll-up rule moved no figure, because the
cost model was already terminal at the sponsor.

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
| M4 | QA + Secretary (2 support), both held by M4's CUSTOMERS C1 and C2 (v1.2 note: identical math, the volume books to M4's account) | 100.00 | 80.00 | yes (boundary) | 0.00 |
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
5. (v1.2) Should the referring member ALSO earn a direct retail commission on customer
   purchases (a level-0 percentage on customer CV, on top of the volume roll-up)?
   Default for v1: no, roll-up only; a retail commission is a one-line engine change
   later if wanted.
6. ~~(raised by the Phase 3 verifier)~~ DECIDED by Howard 2026-08-13: "Gate it."
   Qualification (SV >= 100) is required to HOLD any rank above Member. Delivered as
   v1.3 (engine migration 009), all six months rerun and refinalized; the v1.2 runs
   remain as frozen superseded history.
7. **(section 5A, Instant Payout) PARTLY DECIDED by Howard 2026-08-15: "20 on instant
   payout and it does not roll up to the upline."** The rate, the definition of "first",
   the basis, the caps, the eligibility test and the placement are all now settled in
   section 5A.2, and the no-roll-up rule is 5A.3. **Still open, and the sole gate on
   building it: how an Instant Payout is recovered after a chargeback.** No clawback path
   exists anywhere in this system. See 5A.5 for the four pieces that have to be built
   first. Until then Instant Payout is an approved rule that pays nobody.
