# Decision record: the seven bridge policy decisions, and straight to production

Date: 2026-08-16
Ruled by: Howard (all seven, and the deployment path)
Recorded by: mlm-db-engineer, before applying migrations 019, 020, 021
Design source: `DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md` section 4
Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md`

Acronym key: Personal Volume (PV), Sales Volume (SV), Commissionable Volume (CV),
Team Volume (TV), Stock Keeping Unit (SKU), Coordinated Universal Time (UTC).

This file is the single record of the rulings that let the shop-to-comp bridge go
live. Migrations 019 (bridge), 020 (house account), and 021 (calendar-month
containment) were written to these exact defaults; the rulings below confirm
them, so the migrations apply unchanged.

---

## The seven decisions

### 4.1 One-time purchases: spread over ten months (ruled 2026-08-15)

Chosen: option B, spread over ten months, one tenth of the price and one tenth
of the PV per month, calendar-month contained, starting with the month of
purchase. Howard's words: "spread it for now but going forward lets keep
everything within a calendar month and we run the entire commissions end of
month."
Reasoning: every threshold in the plan is a per-month number, and the house
pricing rule already says a one-time price is ten months paid up front;
spreading makes the volume say what the price says, and removes the
buy-a-rank-in-one-transaction spike.
Built in: migration 021 (and policy P4 of migration 019).

### 4.2 Packs and bundles carry the parent's Personal Volume (ruled 2026-08-16)

Chosen: confirm the 019 default. A pack is ONE product row carrying the
parent's PV; children never gain volume.
Reasoning: PV equals dollars is the plan's one invariant, and only this reading
keeps it true for all four multi-agent items; child volume would double-count
and break the 20 percent payout ceiling.
Built in: migration 019, policy P5.

### 4.3 Refunds and the published-month question (ruled 2026-08-16)

Chosen, in two halves:

- BEFORE a month is published: remove the bridged rows and rerun the month.
  This is 019's design (policy P8's operational fix) and is safe because
  nothing is published.
- AFTER publication: RERUN THE ORIGINAL MONTH, implemented as a SUPERSEDING
  VERSIONED RUN, never an edit. The new run gets a new run id; the old run
  stays frozen as history with a visible superseded-by marker. This follows
  the existing precedent: the v1.2 runs (ids 1 to 6) were superseded by the
  v1.3 runs (ids 7 to 12) exactly this way, old rows intact, status
  'superseded', new rows final.

Two follow-up sentences recorded as policy, with defaults:

1. Monthly volume MAY go negative arithmetic-wise inside a rerun. A rerun is a
   recomputation over corrected inputs, not a stored negative number.
2. Member notification IS the superseded-by marker on the statement. No
   separate notice channel is invented.

Reasoning: the rerun-as-superseding-version shape keeps the immutability
promise literal (no published row is ever edited) while letting a corrected
truth exist beside the old one, visibly.

THIS IS POLICY RECORDING ONLY. No clawback code is built today. The refunds
machinery that exists (migration 022, applied 2026-08-16) records refunds and
snapshots their compensation impact; it does not reverse volume.

### 4.4 Volume counts only at processor-confirmed succeeded (ruled 2026-08-16)

Chosen: confirm the 019 default (policy P1). Only payment_status 'succeeded',
which the system writes only after a fresh retrieve from the processor and an
exact integer amount match against total_cents, produces volume.
Reasoning: a commission is a share of money that was received; 'succeeded' is
the only state backed by independent confirmation, and it is terminal, so
volume derived from it can never be invalidated by a later status change.
Built in: migration 019, policy P1.

### 4.5 Month attribution: creation month forever, refuse a published month (ruled 2026-08-16)

Chosen: confirm the 019 default (policy P3) plus 021's backstop. An order
belongs to the month of its created_at in UTC, forever. If that month already
has a final run, the bridge REFUSES the whole order and reports the rows; it
never shifts volume to an open month and never reopens a statement. Migration
021 turns the refusal into a database trigger
(orders_no_write_into_finalized_period), not just a function branch.
Reasoning: of the four options, this is the only one that can change neither a
published statement nor an order's month without a human deciding to.
Built in: migration 019 policy P3; migration 021 step 1.

### 4.6 A pack never explodes into components (ruled 2026-08-16)

Chosen: confirm the 019 default. Same ruling as 4.2 seen from the other side:
one order line per pack, parent PV, children stay a marketing fact in
catalog.js and never become a compensation fact.
Reasoning: exploding is not even neutral; it would under-credit the Manager
Agent by 50 (150 of child volume against a $200.00 sale) and make the rule
unstateable in one sentence.
Built in: migration 019, policy P5.

### 4.7 Unattributed volume books to house account GW-000 (ruled 2026-08-15)

Chosen: option B with the critical qualification: bookkeeping, never a
disbursement. Howard's words: "when no one is linked then lets pay that to the
company for now" and "lets make an ID that is the top of the tree like
GW-000." GW-000 is a sibling root (nothing above it, nothing below it), volume
lands in app.house_retained_volume which no commission run reads, and three
database triggers make "never paid" structural.
Reasoning: visibility over silence; an invisible number never improves. The
retained figure should shrink month over month as checkout attribution gets
better.
Built in: migration 020.

---

## The deployment ruling: straight to production

Howard ruled on 2026-08-16 to apply migrations 019, 020, and 021 straight to
the production Supabase project (mlm-pilot, ref oiyibdczkokegaxkwulv),
skipping the branch. His explicit ruling, on record.

Rationale: this is a demo pilot with sandbox money only; the migrations were
verifier-audited (the 2026-08-15 bridge verdict forced corrections M1, M2, M4,
L1, L2 which are already in the files); the finalized months are protected by
checksums recomputed before and after; and the bridge itself defaults to
report-only, so the write step is a separate, deliberate call.

Safety rails used in place of a branch: pre-apply checksum snapshot of the six
finalized runs, per-migration verification queries, a dry run before the
commit call, an idempotency re-run, and post-commit checksum comparison. All
results are appended below when the work completes.

---

## Outcome, 2026-08-16: the bridge is LIVE

Executed by mlm-db-engineer against the live project, in the order: record,
apply, verify, dry run, commit, verify again.

### Ledger versions applied

| Migration file | Applied as | Result |
|---|---|---|
| `db\migrations\019_shop_to_comp_bridge.sql` | `shop_to_comp_bridge_019` | success |
| `db\migrations\020_house_account.sql` | `house_account_020` | success |
| `db\migrations\021_calendar_month_containment.sql` | `calendar_month_containment_021` | success |

The live migration ledger before these three ended at `refund_guard_fix_023`
(with 018 tax integrity hardening, 022 refunds, and the 023 refund guard fix
already applied). 022's runtime detection of 019 now takes its applied branch.

### Per-migration verification, all PASS

- 019: tier CHECK widened to (domain, support, bundle, pack); 16 products (4
  new bundle and pack rows); 16 shop_sku_map rows, all joined to products;
  billing_mode and demo_order_id columns present; idempotency index present;
  fn_bridge_demo_orders present; RLS on shop_sku_map; zero data rows touched
  (orders and order_lines both still 10,332).
- 020: 1,001 member rows; exactly one house account, GW-000, sponsor null;
  house_retained_volume table present, empty; all three guard triggers
  present; public v_demo_members still returns 1,000 members and v_demo_tree
  still one root (GW-000 invisible to the site); view owner app_demo_reader
  preserved.
- 021: orders_no_write_into_finalized_period trigger present;
  v_volume_schedule view present; FUNCTIONAL PROOF: an attempted insert into
  finalized July 2026 was refused with "order refused: volume month 2026-07
  was finalized by run 12", and the attempt wrote nothing.

### Dry run (p_commit false), recomputed from live data

The live data had grown past the documented section 8 dry run (150 demo
orders now: 31 succeeded, 45 created, 56 abandoned, 11 failed, 5 processing,
2 refunded), so expectations were recomputed live rather than force-matched:

- bridge: 11 orders, 11 (order, month) pairs, 12 cart lines, 2,000.00 SV,
  all volume month 2026-08-01, all subscription lines.
- skip: not attributed: 20 orders, 29 pairs, 3,950.00 PV (one unattributed
  one-time line on demo order 6 spreads across ten months, 2026-08 through
  2027-05).
- No unmapped SKUs, no finalized-period refusals, no orphan errors.
- The 2 refunded orders (200 PV) produce nothing: the succeeded-only gate
  excludes them, which is decision 4.4 and 4.3 working together.
- No writes: orders 10,332, order_lines 10,332, ledger 0 after both dry runs.

### Commit and verification

- fn_bridge_demo_orders(true): 11 orders and 12 lines written. app.orders
  10,332 to 10,343; app.order_lines 10,332 to 10,344; bridged SV 2,000.00,
  exactly the dry-run verdict. August per member: GW-000003 900.00,
  GW-000014 600.00, GW-000001 300.00, GW-000002 200.00.
- fn_retain_unattributed_orders(true): 30 retention slices, 3,950.00 PV
  (3,050.00 in 2026-08, then 100.00 per month through 2027-05).
- IDEMPOTENCY: both functions run again with p_commit true wrote ZERO new
  rows (10,343 / 10,344 / 30 unchanged); the 11 bridged pairs all report
  "skip: already bridged".
- HOUSE SEPARATION: zero rows in app.orders belong to the house account;
  all GW-000 volume sits in app.house_retained_volume only.
- SPREAD SCHEDULE: the one one-time purchase produced exactly ten monthly
  slices, slice 1 of 10 through 10 of 10, each stamped to the first of its
  own calendar month, 100.00 PV each, summing exactly to the original 1,000.
- FINALIZED MONTHS UNTOUCHED, checksum proof (md5 over ordered row images of
  the six final runs, the established Phase 6 query), identical before the
  apply and after the commit:
  - app.commission_lines:    fc6575d52468328e3b32c84f678f4576
  - app.run_member_results:  aa34b9a4151779a0a010beb1ee643606
  - app.commission_runs:     5bb7fdf19966b667537e4499154fad4a

### Surprises, recorded

1. ORV-2026-08-0XWV5X (demo order 142) was described as succeeded and
   unattributed, but the live row carries member GW-000014, so it BRIDGED
   rather than retaining to the house. The live data wins; presumably the
   referral code was attached at checkout.
2. The live migration ledger contained refund_guard_fix_023 with no matching
   file in `db\migrations\` (a pointer file
   `023_refund_guard_fix_POINTER.md` stands in for it); noted, not changed.
3. `db\comp\003_reset_app_data.sql` needed TWO tables added to its truncate
   list, not one: app.shop_sku_map (references products) AND
   app.house_retained_volume (references members). Both added, with the
   post-reset reseed step documented in that file's header.

### What happens next

The first real commission run happens at the end of August, by hand:
bridge first (`select * from app.fn_bridge_demo_orders(true);` then
`select * from app.fn_retain_unattributed_orders(true);`), then
`select app.fn_run_commission(date '2026-08-01');`, then finalize. Policy P3
plus the 021 trigger make late writes into the finalized month refuse loudly.
