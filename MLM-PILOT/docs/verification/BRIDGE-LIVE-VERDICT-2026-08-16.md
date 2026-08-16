# Verification Verdict: the shop-to-comp bridge, LIVE, independently recomputed

Verifier: mlm-verifier, run 2026-08-16, after commit c37a5c1 (migrations
shop_to_comp_bridge_019, house_account_020, calendar_month_containment_021
applied to production on Howard's explicit straight-to-production ruling).
Per charter: I grade, I fix nothing. Instruments: my own Structured Query
Language (SQL) run read-only against the production project through the
management SQL channel, plus repository reads. Every figure below was
recomputed from `app.demo_orders` by my own queries, written from the policy
rulings, never from the bridge's own code.

Acronym key: Personal Volume (PV), Sales Volume (SV), Coordinated Universal
Time (UTC), Message Digest 5 (MD5), Secure Hash Algorithm 256-bit (SHA-256).

## GATE: PASS

Zero findings at any severity. Every number the engineer reported reproduced
exactly under independent recomputation, every policy gate held under direct
adversarial query, the finalized months are byte-identical to the Phase 6
record under the established checksum queries, and the public surface is
unchanged. This is the cleanest gate this project has produced.

## 1. Independent recomputation of the bridge: EXACT MATCH

My own SQL derived, from `app.demo_orders` alone (payment_status
`succeeded`, `member_id` set, items expanded from the order's own JSON,
volume month from `created_at` in UTC, one-time lines split into ten slices,
subscription lines one slice):

| Figure | My recomputation | Live `app.orders` + `app.order_lines` (demo_order_id set) | Engineer's report |
| --- | --- | --- | --- |
| Bridged orders | 11 | 11 (11 order rows, one (order, month) pair each) | 11 |
| Cart lines | 12 | 12 | 12 |
| Total bridged SV | 2,000.00 | 2,000.00 (sum of unit_volume times quantity) | 2,000.00 |
| August SV, GW-000003 | 900.00 | 900.00 | 900.00 |
| August SV, GW-000014 | 600.00 | 600.00 | 600.00 |
| August SV, GW-000001 | 300.00 | 300.00 | 300.00 |
| August SV, GW-000002 | 200.00 | 200.00 | 200.00 |
| Volume months other than 2026-08-01 | none expected (all attributed lines are subscription) | none present | all 2026-08 |

Reconciliation completeness: every one of the 31 succeeded demo orders is
accounted for, either bridged (11) or retained to the house (20); the query
for succeeded orders that are neither returned zero rows. No succeeded order
arrived after the run and sits unbridged.

## 2. The house ledger: EXACT MATCH, separation structural

| Figure | My recomputation from demo_orders | Live `app.house_retained_volume` | Engineer's report |
| --- | --- | --- | --- |
| Unattributed succeeded orders | 20 | 20 distinct demo_order_id | 20 |
| Retention slices | 30 (20 subscription + 10 one-time) | 30 | 30 |
| Total retained PV | 3,950.00 | 3,950.00 | 3,950.00 |
| August retained PV | 3,050.00 | 3,050.00 | 3,050.00 |
| One-time spread | ten slices of 100.00, 2026-08-01 through 2027-05-01 | ten slices of 100.00, stamped 1/10 through 10/10, same months | same |

House separation: zero rows in `app.orders` belong to GW-000; the GW-000
member row exists with a null sponsor; `app.members` holds 1,001 rows while
the public views hold 1,000 (below). All three guard triggers exist and are
enabled (`tgenabled` O): `commission_lines_no_house_account`,
`members_no_sponsoring_by_house_account`, `orders_no_house_account`.

## 3. Policy conformance, queried directly: ZERO VIOLATIONS

- Succeeded-only (decision 4.4): zero `app.orders` rows whose demo order is
  in any state other than `succeeded`.
- Refunds excluded (decision 4.3): the 2 refunded demo orders appear in
  neither `app.orders` nor `app.house_retained_volume`; zero rows.
- Calendar containment (decisions 4.1, 4.5): every bridged and retained
  slice's volume_month is the first of its own calendar month (zero
  exceptions), and zero slices fall in any finalized period (runs 7 through
  12, 2026-02 through 2026-07).
- Packs never exploded (decisions 4.2, 4.6): bridged line count equals cart
  line count exactly (12 = 12), and the two multi-agent items among the
  bridged lines each appear as ONE line at the parent's full volume
  (Manager Agent bundle, quantity 1, volume 200.00; Constellation Pack,
  quantity 1, volume 800.00). No child rows exist.
- Idempotency, structurally: the partial unique index
  `orders_demo_order_volume_month_idx` on (demo_order_id, volume_month)
  where demo_order_id is not null exists on `app.orders`, which is what
  makes the reported zero-row re-run a property rather than a promise.
  Totals stand at 10,343 orders and 10,344 lines, exactly the engineer's
  post-idempotency figures.

## 4. Finalized-run checksums: IDENTICAL to the Phase 6 record

Recomputed by me with the exact queries recorded in PHASE-6-VERDICT.md
(ordered MD5 over every column of every finalized-run row):

| Table | My recomputation, after the live bridge | Phase 6 recorded value | Match |
| --- | --- | --- | --- |
| app.commission_lines | fc6575d52468328e3b32c84f678f4576 | fc6575d52468328e3b32c84f678f4576 | YES |
| app.run_member_results | aa34b9a4151779a0a010beb1ee643606 | aa34b9a4151779a0a010beb1ee643606 | YES |
| app.commission_runs | 5bb7fdf19966b667537e4499154fad4a | 5bb7fdf19966b667537e4499154fad4a | YES |

Three migrations applied, eleven orders and thirty retention slices written,
and the six finalized months did not move by a byte.

## 5. Public surface: UNCHANGED

`public.v_demo_members` returns exactly 1,000 members; `public.v_demo_tree`
has exactly one root; GW-000 appears in neither view (zero rows across
both). The house account is real in `app.members` (1,001 rows) and invisible
to the site, which is precisely the design.

## 6. Documentation truth: CLAIMS MATCH MEASUREMENTS

- The decision record's Outcome section: every figure it claims (11/12,
  2,000.00, the four member subtotals, 30 slices, 3,950.00, the 100.00
  ten-slice schedule, 10,343/10,344, the three checksums) matches my
  independent measurements above.
- The recorded surprise is accurate: demo order 142, ORV-2026-08-0XWV5X, is
  `succeeded` with member GW-000014 attached and IS bridged, exactly as the
  decision file says (and this corrects the assumption, current earlier in
  the day, that the order was unattributed).
- The 09 banners: each of the seven decision sections now carries an
  "ANSWERED BY HOWARD, 2026-08-16" banner whose content matches the ruling
  in the decision record (spot-read 4.2, 4.3, 4.4 verbatim; the rulings and
  the recorded defaults, including rerun-as-superseding-version and
  policy-recording-only for clawbacks, agree between the two files).
- ROADMAP's new next-step block: every factual claim in it (bridge live,
  seven decisions ruled, three migrations applied straight to production,
  11 orders, 2,000.00 SV August, 3,950.00 PV retained on GW-000, checksums
  byte-identical, idempotent) is one I verified independently this run. The
  two listed next steps match migration 019 section 7 and the decision
  record's "What happens next".

## SHA-256 of the graded artifacts (at commit c37a5c1)

| Artifact | SHA-256 |
| --- | --- |
| `MLM-PILOT\docs\decisions\2026-08-16-bridge-seven-decisions.md` | `57aa3f329a561ac6c9d66779b362e0c6f2cab4a9f9fbaa0a0ff877a8ffe4f5b8` |
| `MLM-PILOT\db\migrations\019_shop_to_comp_bridge.sql` | `5c5efa8efc7f2a4667c4611e5fe2acbe8bb0086dd86483be95218b692efcee56` |
| `MLM-PILOT\db\migrations\020_house_account.sql` | `497a967e7f556181adcb1140b7a7ef09c49c8bc6321c0dae39283f542d545acd` |
| `MLM-PILOT\db\migrations\021_calendar_month_containment.sql` | `5950252789a55bf5132e158276ab2b8054a66d9fc8f9ea32610676e9882e553e` |
| `MLM-PILOT\db\comp\003_reset_app_data.sql` | `490d48e5cf72cbf28b03660cc6fd89d6faa84f767900e2b4d1dc87ae28a30f86` |
| `DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md` | `163ff744af334b91385bfccd75ddecf9f334238fb1e577927687c3b376245060` |
| `MLM-PILOT\ROADMAP.md` | `c4145b441941c1fece6da8976102cca6564a807ea0d431b7b0cd4f714dc4bf24` |

## What I did NOT probe

- The idempotent re-run itself: re-running the two functions is a write and
  this gate is read-only. I verified the structural guarantee (the partial
  unique index) and that the live totals equal the reported
  post-idempotency figures; the zero-row re-run claim rests on those plus
  the engineer's execution log.
- The finalized-period refusal trigger firing: the engineer's functional
  proof (an attempted insert into July refused with the run-12 message) is
  a write test I did not repeat; I verified the trigger exists and that
  zero slices sit in any finalized month.
- The migrations' byte-for-byte equivalence between the repository files
  and the applied ledger bodies (the ledger stores the applied text; a
  byte-compare is a sensible future check, and the per-migration
  verification queries already passed against the live objects).
- The end-of-August commission run: it has not happened; its gate is a
  future obligation and the first one whose inputs now include real bridged
  volume.
