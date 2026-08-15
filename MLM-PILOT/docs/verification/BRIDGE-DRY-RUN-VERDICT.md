# Verification Verdict: the shop-to-compensation bridge and its dry run

**Verifier:** mlm-verifier (independent; did not build any of this)
**Date:** 2026-08-15
**Requested by:** the compensation engineer, whose own standing rule is "I never verify my own math"
**Posture:** adversarial. Every number below was recomputed from a different direction than the
engineer's query took. Agreement is only reported where I derived the figure myself.

**Acronym key.** Personal Volume (PV). Sales Volume (SV). Commissionable Volume (CV). Team Volume
(TV). Stock Keeping Unit (SKU), a short code naming one sellable thing. Coordinated Universal Time
(UTC). Structured Query Language (SQL). Row Level Security (RLS). Foreign Key (FK).

---

## GATE: FAIL

**The money is right. The story told about the money is not.**

Every payout figure survived independent recomputation to the cent: 120.00 across three lines to two
of one thousand members, largest earner GW-000002 at 112.00, and the 400.00 reconciliation splits
exactly as claimed. I attacked those numbers from a different derivation and could not move them.

The gate fails on two published statements of fact that are wrong, both repeated in more than one
artifact, and one of which is the check the engineer himself called "the check that matters most".
Neither changes a cent of payout. Both would become somebody's expectation if shipped.

This is a documentation-correction FAIL, not a rebuild. Fix H1 and H2, re-read M1 and M2, and this
passes.

---

## Artifacts graded, SHA-256

| File | SHA-256 |
|---|---|
| `DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md` | `4d043a8b05132495b8a55f0b4320dcf4d5a75aad82e6e74c90d944dc3d0260d0` |
| `MLM-PILOT\db\migrations\019_shop_to_comp_bridge.sql` | `ce919b36874d708cb1fce795ef5268493f31cbeb7c698cd01aaba1c1786fb004` |
| `MLM-PILOT\db\comp\004_bridge_dry_run.sql` | `328467746dfe75fc722314a13a5bb7ffbae8e3db4fc584f2a213ef2aeba584d2` |

Plain paths:

`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md`
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\db\migrations\019_shop_to_comp_bridge.sql`
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\db\comp\004_bridge_dry_run.sql`

**Production posture confirmed clean.** Migration 019 is NOT applied. I verified this directly rather
than trusting the header: `app.shop_sku_map` does not exist, `app.orders.demo_order_id` does not
exist, `app.order_lines.billing_mode` does not exist, and `products_tier_check` still reads
`CHECK ((tier = ANY (ARRAY['domain'::text, 'support'::text])))`. I ran no function, applied no
migration, and issued no write of any kind. Every query below is a SELECT.

---

## Claim-by-claim

| # | Claim | Verdict |
|---|---|---|
| 1 | 115 orders, 29 paid, 11 naming a member | **FAIL on the order count.** 117, not 115. Paid and attributed counts PASS. |
| 2 | SV 2,000.00, CV 1,600.00 from $2,114.63, gap = tax plus the $25.00 activation fee | **FAIL on the gap.** All three totals PASS. The gap explanation is wrong on both halves. |
| 3 | Payout 120.00, 3 lines, 2 of 1,000, GW-000002 at 112.00 | **PASS**, recomputed independently. |
| 4 | 400.00 = 224.00 + 56.00 + 120.00 | **PASS**, recomputed independently. |
| 5 | 1,000 of 2,000 is bundles and packs | **PASS**, exactly half. |
| 6 | 3,650 PV of paid orders names no member | **PASS**, 18 of 29 paid orders. |
| 7 | `app.shop_sku_map` complete and correct | **PASS.** All 16 mapped, all 12 engine SKU strings resolve, no strays. |
| 8 | `fn_bridge_demo_orders` genuinely idempotent | **PASS with caveat.** No double-pay sequentially or concurrently. See M1 and L1. |
| 9 | Bridge counts only `payment_status = 'succeeded'` | **PASS.** No money bug. |
| 10 | Widened tier plus four products break nothing | **PASS.** Six finalized runs untouched and immutable. |
| 11 | The nine policy assumptions match the SQL | **PARTIAL.** All nine policies match. Two code comments overclaim. See M1, M2. |

---

## HIGH findings

### H1. The order count is 117, not 115. The engineer's own recorded output contradicts his total.

The design document states 115 orders in four places: the section 3 table, the lead Mermaid diagram
(`app.demo_orders / 115 rows, 29 succeeded`), the section 8 narrative, and the comment block under
Query 0 in the dry-run SQL file.

The engineer's own inline result under Query 0 records the per-status rows as 26 abandoned, 50
created, 8 failed, 4 processing, 29 succeeded. **Those five numbers add to 117.** The `TOTAL` line
beneath them says 115. The error was already visible inside the artifact.

I ruled out the innocent explanation, which was that two orders arrived after the engineer ran his
query. They did not. My per-status counts today are byte-identical to his recorded per-status counts,
row for row, including the "with a member" column and every PV subtotal:

| Payment status | Orders | With a member | PV |
|---|---|---|---|
| `abandoned` | 26 | 1 | 2,550.00 |
| `created` | 50 | 13 | 11,050.00 |
| `failed` | 8 | 1 | 550.00 |
| `processing` | 4 | 2 | 550.00 |
| `succeeded` | 29 | 11 | 5,650.00 |
| **Total** | **117** | **28** | **20,350.00** |

The 28 and the 20,350.00 in the document are both correct. Only the order count is wrong. This is a
plain addition error, not a data drift.

**Everything downstream of it is unaffected.** 29 paid PASS. 11 attributed PASS. 18 unattributed
PASS. The "62 percent of paid orders carry no referral code" figure uses 18 of 29 and is right.

Correct all four occurrences to 117.

### H2. The 2,114.63 gap is 100 percent tax. There is no activation fee in it, and the tax is not 5 percent.

The document, section 8.4, states: "The gap is 5 percent tax and the $25.00 priority activation fee
on some orders, neither of which is commissionable (policy P9)." The dry-run file repeats it verbatim
in the comment under Query 3.

Both halves are false. I decomposed the money from the actual columns rather than from the pricing
constants:

| Activation | Tax source | Jurisdiction | Orders | Subtotal | Activation fee | Tax |
|---|---|---|---|---|---|---|
| standard | `flat_mirror_5pct` | (none) | 5 | 500.00 | **0.00** | 25.00 |
| standard | `stripe_tax` | CA, US | 3 | 500.00 | **0.00** | 9.75 |
| standard | `stripe_tax` | IL, US | 1 | 100.00 | **0.00** | 0.00 |
| standard | `stripe_tax` | NY, US | 2 | 900.00 | **0.00** | 79.88 |
| | | **Total** | **11** | **2,000.00** | **0.00** | **114.63** |

**Half one is wrong: there is no activation fee anywhere in the gap.** All eleven attributed paid
orders carry `activation = 'standard'`, and standard activation is free. The sum of
`activation_fee_cents` across all eleven is exactly zero. Not "on some orders". On no orders.

**Half two is wrong: the tax is not a flat 5 percent.** The effective rates are 0.000, 5.000, 8.875,
8.880 and 9.750 percent, drawn from two different tax sources. Six of the eleven orders were priced
by `stripe_tax` against a real jurisdiction; only five still use the `flat_mirror_5pct` path.

**The correct sentence is simply: the 114.63 gap is entirely sales tax, at jurisdiction rates ranging
from 0 to 9.75 percent, and no order in this set paid an activation fee.**

**Root cause, and why it matters more than the sentence.** The document lists
`functions\_shared\pricing.ts` as a source, and that file declares `TAX_RATE_PERCENT = 5` and
`ACTIVATION_FEE_DOLLARS = 25`. The claim was written from those two constants instead of from
`tax_cents` and `activation_fee_cents`. The live shop has since moved to a real tax service, evidenced
by the `tax_source`, `tax_jurisdiction`, and `tax_calculation_id` columns that the document never
mentions. Reading the constant instead of measuring the data is the exact failure the reconciliation
section existed to prevent.

**What is NOT wrong.** SV 2,000.00 PASS. CV 1,600.00 PASS. $2,114.63 charged PASS. The per-member
table in section 8.4 PASS, all four rows. And 2,000.00 + 114.63 + 0.00 = 2,114.63 closes exactly, so
the bridge still invents no volume and loses none. Only the explanation is wrong.

---

## What I recomputed, and how I derived it differently

I deliberately did not re-run the engineer's recursive common table expression over 1,000 members and
call agreement proof.

**SV, derived two ways.** I computed each member's SV from the order-level `pv_total` stamped on the
receipt, and separately from expanding the `items` array line by line. If the bridge's line expansion
invented or lost volume the two would disagree. Delta is 0.00 for every member:

| Member | Paid orders | Cart lines | SV from receipt | SV from lines | Delta |
|---|---|---|---|---|---|
| GW-000003 | 2 | 2 | 900.00 | 900.00 | 0.00 |
| GW-000001 | 3 | 4 | 500.00 | 500.00 | 0.00 |
| GW-000014 | 5 | 5 | 500.00 | 500.00 | 0.00 |
| GW-000002 | 1 | 1 | 100.00 | 100.00 | 0.00 |

Zero one-time units appear among the attributed paid orders, which independently confirms the
document's section 8.7 statement that decision 4.1 changes no number in this dry run.

**The tree, derived from `sponsor_id` directly, not from a recursive walk.** GW-000001 is the root
(`sponsor_id` null, 5 frontline). GW-000002 is its child (74 frontline). GW-000003 and GW-000014 are
both children of GW-000002. Confirmed.

**Ranks, derived by hand.** GW-000002 is qualified (SV 100.00, exactly on the line) and has two
qualified frontline children, so builder_flag holds and paid depth is 2. Its TV of 1,400.00 is below
the 2,500.00 Leader threshold, so it stops at Builder. GW-000001 is qualified but has only one
qualified frontline child, so it fails the two-leg Builder test and holds rank Member at paid depth 1.

**Commission lines, by explicit enumeration of five ancestor pairs rather than a full level map:**

| Earner | Source | Level | Source CV | Rate | Amount | Gate |
|---|---|---|---|---|---|---|
| GW-000001 | GW-000002 | 1 | 80.00 | 10% | 8.00 | PAID |
| GW-000001 | GW-000003 | 2 | 720.00 | 5% | 36.00 | BLOCKED, depth 1 |
| GW-000001 | GW-000014 | 2 | 400.00 | 5% | 20.00 | BLOCKED, depth 1 |
| GW-000002 | GW-000003 | 1 | 720.00 | 10% | 72.00 | PAID |
| GW-000002 | GW-000014 | 1 | 400.00 | 10% | 40.00 | PAID |

**Claim 3 PASS.** Payout 8.00 + 72.00 + 40.00 = **120.00**. Three lines. GW-000002 earns 72.00 + 40.00
= **112.00**. GW-000001 earns 8.00.

**"2 of 1,000" independently confirmed.** I enumerated the complete ancestor set of all four buyers.
It contains exactly two members, GW-000001 and GW-000002. No third member of the thousand can appear
on any line, regardless of gates.

**Claim 4 PASS**, recomputed from the reachable side rather than the engineer's subtractive side:

- Ceiling: 25 percent of 1,600.00 CV = **400.00**
- Reachable, summing only levels that physically exist above each buyer: 8.00 + 36.00 + 20.00 + 72.00
  + 40.00 = **176.00**
- Therefore never existed: 400.00 minus 176.00 = **224.00**
- Depth-gate breakage: 36.00 + 20.00 = **56.00**
- Paid: **120.00**
- **400.00 = 224.00 + 56.00 + 120.00.** Closes exactly.

One wording quibble, not a finding. The 224.00 is labelled "no upline exists", but 12.00 of it belongs
to GW-000002, who does have an upline; what it lacks is levels 2 through 5. The table beneath the
label is precise even though the label is loose.

**Claim 5 PASS, exactly half.** Constellation Pack 800 PV plus Manager Agent 200 PV = 1,000 of 2,000.
The visible remainder is 7 Payment Agents at 700 PV plus one each of Inventory, Pricing and Shipping
at 300 PV.

**Claim 6 PASS.** 3,650.00 PV across 18 of the 29 paid orders names no member.

---

## Item 7: is the SKU map complete and correct? PASS

This was the item most likely to hide silent volume loss, so I attacked it twice.

**Completeness.** I extracted every distinct shop SKU ever written into `app.demo_orders.items` and
full-outer-joined it against the sixteen the migration maps. **No live SKU is unmapped, and no mapped
SKU is a stray.** Thirteen of the sixteen have been sold; `accounting`, `ignition` and `tax` have not
yet appeared in an order. That is forward coverage, not a defect.

**Correctness, which is the subtler risk.** The migration populates the map with an inner join:
`join app.products p on p.sku = v.product_sku`. A single mistyped engine SKU would not error. That map
row would silently fail to insert, the table would quietly hold fewer than sixteen rows, and every
order naming that item would later be refused with `skip: unmapped shop sku`. I resolved all twelve
strings against `app.products`. **All twelve exist. None would vanish.** The engine names also match
`catalog.js` item for item, including the one pairing worth double-checking, shop `executive` to
`AGT-S-004` "Chief Executive".

The four new rows are self-consistent: `AGT-B-001` Manager Agent at 200.00 / 200 PV, `AGT-P-001`
Ignition 200.00 / 200, `AGT-P-002` Momentum 400.00 / 400, `AGT-P-003` Constellation 800.00 / 800, all
matching `catalog.js` and `pricing.ts`.

---

## Item 9: does the bridge count anything other than `succeeded`? PASS, no money bug

There is exactly one read of `app.demo_orders` in the entire function, in the `src` common table
expression, and it carries `where d.payment_status = v_state_gate` with `v_state_gate` a constant
`'succeeded'`. `tmp_bridge_lines` is built from that and nothing else; `tmp_bridge_orders` is built
only from `tmp_bridge_lines`; both INSERTs read only those two temp tables. There is no second path,
no union, and no later re-read that could readmit a `created`, `processing`, `abandoned` or `failed`
row. **No money bug here.**

Worth stating plainly because of its size: policy P1 correctly discards 14,700.00 PV, and policy P2
correctly discards a further 3,650.00 PV. Only 2,000.00 of the 20,350.00 PV on the table reaches the
engine. That is the design working, but it is a 90 percent haircut and nobody should meet it by
surprise.

---

## Item 10: does the widening break anything? PASS

**The six finalized runs are untouched and remain immutable.** February through July 2026 are `final`.
Their statement rows live in `app.commission_lines` and `app.run_member_results`, and I confirmed both
tables still carry their immutability triggers (`commission_lines_immutable_when_final`,
`commission_lines_no_write_into_final`, and the matching pair on `run_member_results`). Migration 019
never mentions either table. Nothing it does can reach a finalized statement.

**Widening the tier constraint is safe.** Dropping and recreating `products_tier_check` with a wider
predicate revalidates existing rows against a superset, which cannot fail. `tier` is read by no
foreign key, no trigger, and no view; the engine computes SV from `order_lines.unit_volume` and never
mentions the column. Adding four product rows changes no existing row.

**Adding `billing_mode` is safe.** A `not null default 'sub'` add is a metadata-only operation on
modern Postgres, and all 10,332 existing lines are genuinely subscription orders, so the default is
correct history.

Baseline figures verified against the document: 10,332 orders, 10,332 order lines, 22,076 commission
lines, 1,000 members, six distinct volume months ending 2026-07-01, and **zero orders in August 2026**.
August is genuinely clean, so the engineer's choice of period is sound.

---

## MEDIUM findings

### M1. Policy P8's stated recovery procedure can silently destroy volume

P8 tells the operator that if a refund arrives before finalization, "the operational fix is to delete
the bridged rows and run the month again". The `skip: already bridged` verdict tests `app.orders`
only:

```
when exists (select 1 from app.orders eo
              where eo.demo_order_id = p.demo_order_id
                and eo.volume_month  = p.volume_month)
     then 'skip: already bridged'
```

If an operator deletes the `app.order_lines` rows but leaves the `app.orders` row, the next bridge run
reports `skip: already bridged` and never restores the lines. The order survives with zero lines,
contributes 0.00 SV, and nothing anywhere reports a problem. The FK from `order_lines.order_id` forces
the safe ordering only in the other direction.

Reword P8 to name both tables, lines first then orders, and consider adding an orphan check to the
report.

### M2. `ordered_at` on slices two through ten is timezone-dependent, and the comment says it is not

The comment above the insert claims: "later slices are stamped to the first instant of their own
month, so ordered_at always sits inside its volume_month." The code is
`o.volume_month::timestamptz`, which resolves a date against the **session** TimeZone, not UTC. The
function never pins a timezone.

I checked: this project's TimeZone is UTC, so the claim happens to hold today. From any session east
of UTC it does not. At UTC+9, `date '2026-09-01'::timestamptz` is 2026-08-31 15:00 UTC, placing a
September slice's `ordered_at` in August.

Not a money bug, because the engine keys on `volume_month` and never reads `ordered_at`. It is an
audit-trail inconsistency and the word "always" is not earned. Use
`(o.volume_month::timestamp at time zone 'UTC')`.

### M3. Section 6 says only the audit tag differs. A public view disagrees.

Section 6 concludes that booking a guest purchase as `buyer_role = 'member'` is harmless because "the
money is the same either way" and "what differs is only the audit tag".

The money claim is correct: the engine never reads `buyer_role`. The "only" is not. The view
`public.v_demo_customer_volume` is defined as

```
... where o.buyer_role = 'retail_customer' and o.status = 'completed'
```

and it is granted SELECT to `anon` and `authenticated`, so it is readable through the public
application programming interface. Every genuine customer purchase booked as `member` will be
permanently invisible in that view. Add one sentence to section 6 naming this view, and note that
customer-attributed volume reporting stays empty until the checkout question exists.

### M4. The reset-script landmine is real but understated

The engineer deserves credit for finding it unprompted: `db\comp\003_reset_app_data.sql` truncates
`app.products` at line 54, and the new FK from `app.shop_sku_map` will make that fail.

The stated fix, "one line, adding `app.shop_sku_map` to the truncate list", makes the truncate succeed
but leaves a worse state. The reseed restores only the twelve seeded products. The four bundle and
pack rows are gone, and every one of the sixteen map rows is gone with them. The bridge would then
answer `skip: unmapped shop sku` for every order, which is at least loud rather than silent, but the
system is quietly non-functional until somebody re-runs sections 2 and 3 of migration 019.

The fix is one line **plus a documented post-reset step**. Say so in both files.

### M5. Nothing in the database protects a finalized month on `app.orders`

The migration header is admirably honest that the finalized-months invariant moves from "protected by
an absence" to "protected by a rule", and policy P3 implements that rule correctly.

What it does not say is that the rule has no database backstop. I checked: **there are no triggers at
all on `app.orders`, `app.order_lines`, or `app.products`.** The immutability triggers exist only on
`commission_lines` and `run_member_results`. Any direct INSERT into `app.orders`, by a script, by a
future function, or by hand, can put volume into a finalized month, and only a re-run would ever
reveal it.

The published statement itself stays immutable, so this is not a breach of the core promise. But the
invariant now depends entirely on one CASE branch in one function. That is worth one sentence in the
header, and eventually a trigger.

---

## LOW findings

### L1. Concurrency: no double-pay, but the second run dies loudly rather than skipping

The task asked specifically what happens on a concurrent second run. Answer: the `exists()` check is a
non-locking read, so two simultaneous `fn_bridge_demo_orders(true)` calls both compute verdict
`bridge` for the same pair and both attempt the insert. The partial unique index
`orders_demo_order_volume_month_idx` is the real guarantee: the second insert blocks on the index,
then raises `unique_violation`, and since a PL/pgSQL function body runs inside the caller's
transaction, that whole transaction rolls back. **No order is double-written and no commission is
double-paid.** The idempotency claim holds.

But the header implies the second run is *harmless*, and it is actually an unhandled exception with a
misleading `get diagnostics` count behind it. `on conflict (demo_order_id, volume_month) do nothing`
on the orders insert, or a transaction-level advisory lock at the top of the function, would make the
concurrent case as graceful as the sequential one.

### L2. The no-rounding guarantee depends on the catalog staying round

`(sl.line_price / sl.n_slices)::numeric(10,2)` relies on the header's claim that "every catalogue
value divides by ten with no remainder". I verified all sixteen: one-time prices of 500, 1000, 2000,
4000 and 8000 all divide by ten exactly, PV likewise. True today.

It stops being true the first time a discount, proration, partial refund, or promotional price writes
a non-round `unit_price` into `items`. Ten slices would then no longer add back to the one-time total,
and the loss would be silent. Add a report-side assertion that the slices sum to the original.

### L3. Only `final` blocks a period; a `running` run does not

P3 refuses a period with a `final` run. A period whose run is `running` is still writable. Bridging
between `fn_run_commission` and `fn_finalize_run` would leave the run's stored totals disagreeing with
the month's orders, with no error. Section 7's usage note says to bridge first, which is right, but
nothing enforces the order.

---

## Item 11: do the nine policies match the SQL? PARTIAL

I read each policy against the code rather than against the prose. **All nine are faithfully
implemented.**

| Policy | Implemented as | Match |
|---|---|---|
| P1 succeeded only | `where d.payment_status = v_state_gate` in `src` | yes |
| P2 `member_id`, role `member`, unattributed reported | `v_buyer_role`, verdict `skip: not attributed` | yes |
| P3 UTC creation month, refuse whole order if any slice hits a final run | `date_trunc` in UTC, `bool_or(fr.run_id is not null)` per order | yes |
| P4 one-time spread over ten months | `n_slices = 10`, `generate_series(0, n_slices - 1)` | yes |
| P5 pack is its own product, never exploded | one map row per shop SKU, no child expansion | yes |
| P6 no separate one-time products | sixteen map rows, sixteen products, mode on the line | yes |
| P7 idempotency on `(demo_order_id, volume_month)` | partial unique index plus `exists` check | yes |
| P8 insert only, never update or delete | only INSERT statements in the function | yes |
| P9 activation fee and tax never booked | reads only `items[].unit_pv` and `items[].unit_price` | yes |

The partial mark is for two **code comments** that overstate what their code does, not for the
policies themselves: the `ordered_at` comment in M2, and P8's incomplete recovery instruction in M1.
That is a much better result than this project's history would predict, and it is worth saying so.

Note that P9 is correctly implemented, which is precisely why finding H2 is a documentation error and
not a code error. The bridge has never booked an activation fee. The document simply described a fee
that was not there.

---

## Project guardrails

Checked across all three artifacts.

- **Em dashes and en dashes:** zero occurrences in all three files. PASS.
- **Unicity data or terminology:** zero occurrences in all three files. PASS.
- **Acronyms expanded on first use:** both the design document and the migration header carry explicit
  acronym keys. PASS.
- **Lead with the picture:** `DOCUMENTATION\diagrams\shop-to-comp-bridge.svg` exists (8,576 bytes) and
  section 1 leads with it before any prose. PASS.

---

## What must happen before this becomes anyone's expectation

1. **Correct 115 to 117** in all four places: the section 3 table, the Mermaid diagram in section 1,
   the section 8 narrative, and the Query 0 comment in `004_bridge_dry_run.sql`.
2. **Rewrite the gap sentence** in section 8.4 and in the Query 3 comment: the 114.63 is entirely
   sales tax at jurisdiction rates from 0 to 9.75 percent, and no order in this set paid an activation
   fee. Mention `tax_source` and the `stripe_tax` migration while doing it.
3. **Reword P8** to delete order lines and orders, in that order.
4. **Fix the `ordered_at` cast** to pin UTC, or drop the word "always" from its comment.
5. **Add one sentence to section 6** naming `public.v_demo_customer_volume`.
6. Then proceed with the engineer's own step 3: apply 019 to a branch, never to production, and
   re-run the dry run against the branch so the numbers come from the real bridge rather than a
   simulation of it.

The payout arithmetic is sound and I could not break it. Correct the narrative and this is ready for
a branch.
