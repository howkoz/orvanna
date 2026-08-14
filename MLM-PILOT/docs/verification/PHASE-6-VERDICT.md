# Phase 6 Verdict: Live TEST-MODE Payment Rail, Verifier Gate

Grader: mlm-verifier. Date: 2026-08-14. The builder never grades its own work;
this grader built none of the rail under test. Scope: the spec's section 6.1
checks plus the coordinator's Phase 6 delta list, proven live against the
deployed Edge Functions and database wherever this session could reach them.
Budget respected: exactly one demo order row was created by this audit (three
create-payment calls total, two of which were rejected by design and wrote
nothing).

Acronym key: Multi-Level Marketing (MLM), Application Programming Interface
(API), Representational State Transfer (REST), Remote Procedure Call (RPC),
Hypertext Transfer Protocol (HTTP), Row-Level Security (RLS), JavaScript Object
Notation (JSON), JSON Web Token (JWT), Structured Query Language (SQL), Secure
Hash Algorithm 256 (SHA-256), Message Digest 5 (MD5), Personal Volume (PV),
Sales Volume (SV), Internet Protocol (IP), Coordinated Universal Time (UTC),
Cross-Origin Resource Sharing (CORS), Software Development Kit (SDK),
Quality Assurance (QA), Uniform Resource Locator (URL), Data Definition
Language (DDL).

## VERDICT: PASS

Zero HIGH findings. Price tampering is ignored by construction and proven live;
a forged confirm degenerates into a harmless server-side re-check, proven live;
the anon surface is unchanged and the two new tables are invisible to it,
proven live; the pricing mirror matches the site catalog fact for fact, both
mechanically and by hand; the finalized months are byte-identical across this
audit's demo-order activity; no secret entered any repository. Two MEDIUM
findings (a pre-existing grant-hygiene gap surfaced by the first-ever grant
enumeration, and a shared rate-limit bucket across the three functions) and
three LOW notes. One half of one check is DEFERRED-TO-COORDINATOR with exact
queries: bracketing checksums around a payment that actually SUCCEEDS, because
this session cannot drive the browser card SDK.

## What was proven LIVE versus verified from source

PROVEN LIVE: anon REST probes on the new tables and the seven views; three
create-payment calls (forged prices, unknown SKU, over-cap cart); four
confirm-payment calls (forged confirm, repeat confirm, malformed number,
unknown number); database enumeration of grants, RLS, policies, triggers, and
finalized-run checksums through the Supabase management SQL channel; the
pricing mirror checker executed.

VERIFIED FROM SOURCE: the amount-mismatch code path (check 4), the rails
numbers (check 8), the secrets access pattern, and migration 010's posture,
each read line by line and cross-checked against observed live behavior.

## Check 1: anon posture unchanged, live-probed. PASS

With the shipped anon key against https://oiyibdczkokegaxkwulv.supabase.co:

    GET /rest/v1/demo_orders?select=*&limit=1
    -> HTTP 404 PGRST205 "Could not find the table 'public.demo_orders'"
    GET /rest/v1/demo_orders (Accept-Profile: app)
    -> HTTP 406 PGRST106 "Only the following schemas are exposed: public,
       graphql_public"

Identical results for demo_rate_events. All seven v_demo_* views still answer
HTTP 200. Live catalog enumeration via SQL: schema public contains EXACTLY
seven views (v_demo_members, v_demo_tree, v_demo_member_months,
v_demo_statements, v_demo_company, v_demo_customers, v_demo_customer_volume);
no eighth relation exists, and anon holds no grant on any app.* relation.
app.demo_orders and app.demo_rate_events both report rls=true with zero
policies. The enumeration also surfaced MEDIUM finding 1 below, a pre-existing
condition, not a Phase 6 change.

## Check 2: price tampering rejected, live-probed. PASS

Probe T1 sent create-payment a cart claiming one dollar for the Payment Agent:

    items: [{ sku "payment", mode "sub", quantity 1, unit_price 1.00,
              price 1, total 1 }], total 1, total_cents 100,
    activation standard, tax_exempt false, Origin http://localhost:9120

Response: HTTP 200, order ORV-2026-08-15MOGN created. The subsequent
confirm-payment receipt for that order shows the SERVER's math, not the forged
numbers: items priced at unit_price 100, subtotal_sub_cents 10000,
activation_fee_cents 0, tax_cents 500, total_cents 10500. The forged fields
vanished because the pricing module reads only sku, mode, and quantity
(functions/_shared/pricing.ts, priceCart), exactly the spec 1.5 tamper case.
The database row (read via the management SQL channel) confirms total_cents
10500.

Probe T2, unknown SKU "free-agent": HTTP 400 invalid_cart, "The cart names an
item the shop does not sell." No row written.

Probe T3, 26 total units: HTTP 400 invalid_cart, "The cart carries more than
25 total units." No row written.

Row count in app.demo_orders went from 1 (the pre-existing on-record payment)
to exactly 2 across the whole audit, proving the two 400s wrote nothing.

## Check 3: forged confirm degenerates, live-probed. PASS

- C1, confirm-payment on ORV-2026-08-15MOGN, which was never paid: HTTP 200,
  payment_status "processing", processor.status "requires_payment_method".
  Not succeeded. The function accepted only { order_number }; there is no
  status field to forge, and the answer came from the server-side HyperSwitch
  retrieve.
- C4, repeat of the same call: byte-identical receipt, same status. Idempotent.
- C2, nonsense number "HELLO-WORLD": HTTP 400 invalid_order_number.
- C3, well-formed but unknown "ORV-2026-08-ZZZZZZ": HTTP 404 order_not_found.
- The response reveals only the sanitized receipt (server money fields plus
  processor status, error_code, error_message); no processor payload, no card
  data, nothing personal.

## Check 4: amount-mismatch path, code review. PASS, no path to a false succeeded

confirm-payment (functions/confirm-payment/index.ts) can write 'succeeded'
only through one path, and that path is triple-gated:

1. mapStatus returns "succeeded" only when the HyperSwitch retrieve itself
   says status "succeeded" (line 94 to 101).
2. Before any write, lines 239 to 253 require `hs.amount === row.total_cents`
   (strict integer equality) AND `amount_received` to be undefined, null, or
   exactly equal to total_cents. Any failure sets amountMismatch, forces
   newStatus to "processing" (comment: "never succeeded on a mismatch"), and
   records error_code "amount_mismatch" in the sanitized summary.
3. The UPDATE at lines 270 to 278 is guarded with `payment_status in
   ('created', 'processing')`, so a concurrent call cannot overwrite a
   terminal state, and terminal rows short-circuit at line 172 before any
   retrieve happens.

Defense in depth below the function: migration 010 installs a database trigger
(demo_orders_guard_status_transition) that rejects any exit from 'succeeded'
or 'failed' and any return to 'created', so even a future buggy function
could not rewrite a terminal row. Verified live that the trigger exists on
app.demo_orders. Conclusion: no code path writes 'succeeded' on an amount
mismatch, and both amount fields are checked as the spec requires.

## Check 5: pricing mirror mechanical diff plus hand re-derivation. PASS

Mechanical: `py functions/_shared/check_pricing_mirror.py` exited 0 with
"Items matched exactly: 16 of 16", activation fee 25.0 = 25.0, tax rate
5.0 = 5.0 percent.

Independent hand re-derivation (both files read directly by this grader; four
representative quadruple sets, spanning all four tiers):

| SKU | catalog.js (sub price, sub PV, once price, once PV) | pricing.ts | Match |
|---|---|---|---|
| payment (domain) | 100, 100, 1000, 1000 | 100, 100, 1000, 1000 | YES |
| qa (support) | 50, 50, 500, 500 | 50, 50, 500, 500 | YES |
| manager (bundle) | 200, 200, 2000, 2000 | 200, 200, 2000, 2000 | YES |
| constellation (pack) | 800, 800, 8000, 8000 | 800, 800, 8000, 8000 | YES |

The remaining twelve entries were also read side by side and match; the
activation fee ($25.00 in shop.html's DELIVERY table and
ACTIVATION_FEE_DOLLARS = 25) and tax factor (0.05 in shop.html,
TAX_RATE_PERCENT = 5) agree.

Amount equality spot proof on the live succeeded order ORV-2026-08-158WRU
(spec check V5): its stored items are 1 x payment sub at unit_price 100.
Independent recomputation: subtotal_sub 10000 cents + activation 0 + tax
round(10000 x 5 / 100) = 500 makes total 10500 cents, equal to the stored
total_cents 10500, and the row is 'succeeded' with processor status
'succeeded' via connector stripe_test, which the reviewed confirm-payment gate
could only have written after its own integer amount check against the
HyperSwitch object.

## Check 6: finalized months byte-identical. PASS for this audit's activity; one half DEFERRED-TO-COORDINATOR

Method: ordered MD5 over every column of every finalized-run row, computed
through the Supabase management SQL channel.

BEFORE this audit created anything (14:57:38 UTC, demo_orders count 1):

| Table (finalized rows) | Rows | Checksum |
|---|---|---|
| app.commission_lines | 10,990 | fc6575d52468328e3b32c84f678f4576 |
| app.run_member_results | 6,000 | aa34b9a4151779a0a010beb1ee643606 |
| app.commission_runs | 6 | 5bb7fdf19966b667537e4499154fad4a |

AFTER the tamper order was created and confirm-forged twice (14:59:53 UTC,
demo_orders count 2): all three checksums IDENTICAL.

Structural backstop, verified live: the only non-internal triggers on the
demo tables are migration 010's two demo_orders triggers; the engine tables
carry only their four migration 006 immutability triggers; no function,
trigger, or view connects app.demo_orders to any engine table; the three Edge
Functions write only app.demo_orders and app.demo_rate_events (every SQL
statement in the three sources was read).

DEFERRED-TO-COORDINATOR, honestly: the coordinator's wording asks for the
bracket "before creating your test payment and AFTER it SUCCEEDS". This
session cannot complete a card payment (the HyperSwitch SDK card entry runs
only in a real browser), so the succeeded-payment bracket could not be closed
here; the on-record succeeded payment ORV-2026-08-158WRU predates my BEFORE
snapshot. After QA's happy-path payment succeeds (spec Q1), run the exact
queries below and compare to the three checksums above; equality closes the
gap completely:

```sql
select md5(string_agg(t.line, E'\n' order by t.line)) from (
  select concat_ws('|', run_id, earner_id, source_member_id, level,
                   source_cv, rate, amount, payout_type) as line
  from app.commission_lines
  where run_id in (select id from app.commission_runs where status = 'final')
) t;  -- expect fc6575d52468328e3b32c84f678f4576

select md5(string_agg(t.line, E'\n' order by t.line)) from (
  select concat_ws('|', run_id, member_id, sv, cv, tv, is_active, rank_earned,
                   paid_depth, total_earned, coalesce(cumulative_sv::text,'')) as line
  from app.run_member_results
  where run_id in (select id from app.commission_runs where status = 'final')
) t;  -- expect aa34b9a4151779a0a010beb1ee643606

select md5(string_agg(t.line, E'\n' order by t.line)) from (
  select concat_ws('|', id, period, spec_version, status, total_sv, total_cv,
                   total_payout, members_paid) as line
  from app.commission_runs where status = 'final'
) t;  -- expect 5bb7fdf19966b667537e4499154fad4a
```

Context note so nobody misreads the numbers: the finalized runs are now ids 7
through 12 under comp plan spec v1.3 (the rank-qualification ruling adopted
after the Phase 3 gate), so their payouts legitimately differ from the Phase 3
verdict's v1.2 table (for example February 11,906.00 now versus 12,014.00
then). That re-finalization predates Phase 6 and is not a Phase 6 event; the
byte-identity claim here is about demo-order activity, and it held exactly.

## Check 7: secrets sweep. PASS

- Public repository (github.com/howkoz/orvanna.io, new commit b9e6936,
  history now three commits, only shop.html changed, +373 lines): grep of the
  full diff and of every tracked file at b9e6936 for `snd_` and for
  64-character hexadecimal literals returns zero hits. The deployed shop.html
  contains NO publishable key at all (it arrives at runtime in the
  create-payment response); the only key-like string in the repository remains
  the already-graded Supabase anon JWT.
- Private functions folder: zero key-like literals. Secret access is
  exclusively via Deno.env.get, seven call sites total, names exactly
  HYPERSWITCH_API_KEY, HYPERSWITCH_PUBLISHABLE_KEY, ORVANNA_DEMO_IP_SALT, and
  the platform-injected SUPABASE_DB_URL. HYPERSWITCH_HASH_KEY is not read by
  any v1 function, matching the spec.
- The only external additions to the public site are the sanctioned
  HyperLoader.js from https://beta.hyperswitch.io (spec 1.4's one named
  exception) and the project's own functions base URL. Nothing else external
  entered.
- The publishable key `pk_snd_bfcb22d171b54957b2cdc9046c56ae16` observed in
  the live create-payment response is the spec section 0 public-by-design key.

## Check 8: rails sanity from source (read-only). PASS

All numbers match the spec exactly, read from the deployed sources:

| Rail | Spec 5.1/5.2 | Source | Value |
|---|---|---|---|
| create-payment per minute | 5 | create-payment line 92 | perMinute: 5 |
| create-payment per hour | 30 | create-payment line 92 | perHour: 30 |
| confirm-payment per minute | 20 | confirm-payment line 120 | perMinute: 20 |
| list-demo-orders per minute | 20 | list-demo-orders line 58 | perMinute: 20 |
| Daily ceiling | 500 | create-payment line 49 | DAILY_ORDER_CEILING = 500, answered with HTTP 503 |
| Units per line | 99 | pricing.ts | MAX_UNITS_PER_LINE = 99 |
| Distinct lines | 16 | pricing.ts | MAX_DISTINCT_LINES = 16 |
| Total units | 25 | pricing.ts | MAX_TOTAL_UNITS = 25 (proven live by T3's 400) |
| Total ceiling | $25,000.00 | pricing.ts | MAX_TOTAL_CENTS = 2,500,000 |
| Refused requests not counted | spec worked example | edge.ts checkRateLimit | bucket read first, increment only on allow |

The limits were NOT exhausted by this audit: three create calls and four
confirm or list-class calls total.

## Findings

### HIGH

None.

### MEDIUM

1. Pre-existing grant hygiene on the seven public views, surfaced by the
   first-ever grant enumeration (not a Phase 6 change): information_schema
   shows anon AND authenticated hold DELETE, INSERT, REFERENCES, SELECT,
   TRIGGER, TRUNCATE, and UPDATE on all seven v_demo_* views, not the
   SELECT-only grant migrations 005 and 007 intended. Cause: Supabase's
   default privileges in schema public grant ALL on new relations to the API
   roles at creation time; the migrations' explicit SELECT grants were
   additive, not restrictive. Exploitability today: none proven possible; no
   view is auto-updatable (every write probe in the Phase 5 verdict failed
   with Postgres error 55000) and anon has no DDL channel to exercise the
   TRIGGER privilege. It is still a latent missing control: a future
   single-table view created in public would be writable by anon by default.
   Recommendation for mlm-db-engineer: revoke all but SELECT on the seven
   views from anon and authenticated, and alter default privileges in schema
   public so future relations start at zero.

2. The rate-limit ledger bucket is shared across all three functions: the key
   is (ip_hash, window_start) with no function dimension
   (functions/_shared/edge.ts, checkRateLimit), so create-payment's 5 per
   minute and confirm-payment's 20 per minute draw down ONE shared counter.
   Spec 5.1 defines the limits per function ("confirm may be retried
   legitimately"). Consequence: a shopper who polls confirm-payment 5 or more
   times in a minute (a legitimate "processing" retry loop, allowed up to 20)
   locks themselves out of create-payment for that minute, and confirm or
   list traffic silently consumes the create hourly budget of 30. Spec drift
   with an availability effect, no security effect. Fix: add the function
   name to the ledger key (schema change or key prefix inside ip_hash).

### LOW

1. Rate limiter read-then-increment race: the bucket is read, the verdict is
   made, and only then is the count upserted, so two concurrent requests can
   both read 4 and both pass, briefly exceeding a limit by a small factor.
   A single atomic upsert returning the new count would close it. Demo-scale
   impact only.
2. Function-versus-database disagreement on 'abandoned': confirm-payment
   treats 'abandoned' as terminal (returns the row without re-checking), while
   migration 010's trigger deliberately allows abandoned to resolve to
   succeeded or failed for a late reconcile. Consequence: an order paid after
   its row aged to abandoned (over one hour) can never be corrected through
   the current function even though the database would permit it; the spec
   explicitly accepts this gap for v1 (section 4, item 3), so this is a note,
   not drift.
3. list-demo-orders accepts POST as well as GET (its own 405 text says "Use
   GET."). Harmless; cosmetic tightening only.

## SHA-256 of the graded artifacts

Private sources (MLM-PILOT):

| File | SHA-256 |
|---|---|
| functions/create-payment/index.ts | c3b2fedc84d51f8f979cdb8971a35cfe9a1cf1d5352652e54744375ad5830c86 |
| functions/confirm-payment/index.ts | c3de7039b91d46f057d18f0f37aa5eedce26e4284970a49d1038c684e53e1ae8 |
| functions/list-demo-orders/index.ts | eae694b2f275cd4c61c3ca29d8f2670b0f9bfa2c9e942dcdf8c8a34d6f55fcee |
| functions/_shared/edge.ts | 88381b56a27e270ddc074c5275da2d5d7083b8b2bc960e9615c57c8ecdd9455d |
| functions/_shared/pricing.ts | 9235559dfd0322b66dd0f5d93c8f592871ee23366b30405053ac58fba468d5ab |
| functions/_shared/check_pricing_mirror.py | acc114962af9b422f21a7be7f7280ecda45c9e5f178cc8294bc21936cd4e769f |
| db/migrations/010_demo_orders.sql | 7a5448fd629e4f13212bb78434c5d54e5343ffe34ce894a0ca88606478bc1553 |
| www/js/catalog.js | 46dc87e21c2897a77f277b64a289af197e56f7955607e6a1bb85e29987a17135 |
| www/shop.html | 50d75d700404196052e33808636bcf0ce779843a2202c21fb7dc4da7d32a808b |

Public repository: commit b9e69360986fe0a017d2275afde07a3450131528, tree
5f6b04b409435efd04d0d906db94c69725f4c02e; deployed shop.html SHA-256
477654f41c0be48297d639ec58c5c60624ea327d541e3c830f5a2c9b33c730ca (content
identical to the private www/shop.html after carriage-return normalization;
the hash difference is line endings only, verified by direct diff).

Audit residue, for the record: one demo order created by this gate,
ORV-2026-08-15MOGN, unpaid, status 'processing', which will age to
'abandoned' by the sweep. That is by design and is itself evidence for
check 3.

## Bottom line

The rail holds. Client prices are ignored by construction and in practice; a
forged confirm is just a request to re-check the truth; the anon key still
sees seven read-only views and nothing else; the mirror matches the catalog
exactly; the finalized months did not move a byte during live tampering; and
no secret is anywhere a stranger can read. PASS, with two MEDIUM cleanups
(view grant hygiene, per-function rate buckets), three LOW notes, and one
deferred re-check for the coordinator to run after QA's first in-browser
succeeded payment.

## Coordinator closure of the deferred check (2026-08-14, Fable, Chief Information Officer (CIO))

The verifier deferred one half of check 6: bracketing PAYMENTS THAT SUCCEED with
finalized-months checksums. Closed as follows, using the verifier's queries:

- BEFORE snapshot (taken before the Quality Assurance (QA) gate ran): commission_lines
  md5 32c829ac42aec575a3cddcef12b63dcf (22,076 rows), run_member_results
  md5 c94479b24b9343e25f7f7916807cc2db (12,000 rows), commission_runs final+superseded
  md5 be716caebab5f1610488d4360670ab93 (12 rows).
- Activity inside the bracket: the full QA gate (three succeeded payments, one failed,
  six rail-test creates), Howard's own live decline test, and the coordinator's decline
  path proof (ORV-2026-08-16STIL, failed with reason). app.demo_orders reached 17 rows,
  5 succeeded.
- AFTER snapshot: all three md5 values and row counts IDENTICAL, byte for byte.

Verdict on the deferred item: PASS. Real succeeded test payments cannot alter the
finalized commission months. With this, and the two MEDIUM fixes verified live
(migration 011 SELECT-only view grants; scoped per-function rate buckets, proven by
QA row 9), the verifier gate stands PASS with zero open HIGH or MEDIUM findings.
