# Phase 6 Specification: Real TEST-MODE Payments on the Live Site

As of 2026-08-14. Author: mlm-architect. Builders: mlm-db-engineer (migration) and
mlm-site-builder (Edge Functions plus checkout wiring) implement EXACTLY this;
ambiguities go back to the architect, never improvised. Graded by mlm-verifier and
mlm-qa, both gates required.

Status: SPEC. Nothing in this document is code; worked examples are hand-computed.

Acronym key: Application Programming Interface (API), Software Development Kit (SDK),
Personal Volume (PV), Commissionable Volume (CV), Row-Level Security (RLS),
JavaScript Object Notation (JSON), Internet Protocol (IP), Hypertext Transfer
Protocol (HTTP), Coordinated Universal Time (UTC), Cross-Origin Resource Sharing
(CORS), JSON Web Token (JWT), Uniform Resource Locator (URL), Multi-Level
Marketing (MLM), Quality Assurance (QA).

## 0. Fixed ground rules (decided by Howard, not revisited here)

1. Hosted HyperSwitch sandbox at app.hyperswitch.io, TEST MODE ONLY. Test cards
   only. No real money, ever. The publishable key is public by design:
   `pk_snd_bfcb22d171b54957b2cdc9046c56ae16`.
2. The SECRET HyperSwitch API key and the payment response hash key live ONLY in
   the Supabase secrets vault. Howard types them into the dashboard himself. They
   never appear in any repository, spec, chat window, or log line. Both are being
   REGENERATED before wiring because the first pair touched a chat window.
3. Server piece: Supabase Edge Functions on the existing project
   (`oiyibdczkokegaxkwulv`). Edge Functions hold the secret key and write to the
   database with the service role.
4. THE PUBLIC ANON KEY POSTURE IS UNTOUCHABLE. The anon role keeps exactly its
   current seven read-only `v_demo_*` views. Zero new grants to anon. Zero write
   paths for anon. Every database write in this phase happens inside an Edge
   Function using the service role.
5. The live site stays static GitHub Pages at orvanna.io. It may load exactly ONE
   external script, named in section 1.4, and may call our Edge Function endpoints.
6. Demo philosophy: safe for strangers. Rate limited, no personal data required,
   and the payment screen says out loud that this is a test.

---

## 1. Payment flow, end to end

### 1.1 The picture first

```
 SHOPPER (browser, static site at orvanna.io)
    |
    | (1) Pay clicked on the existing step-4 checkout
    v
 EDGE FUNCTION create-payment  (holds nothing from the client but SKUs and choices)
    |  validates cart against the server-side pricing table (section 1.3)
    |  recomputes money and PV itself; client prices are IGNORED
    |  writes app.demo_orders row, payment_status = 'created'   [service role]
    |
    | (2) POST /payments to HyperSwitch (secret key, amount in cents, metadata)
    v
 HYPERSWITCH SANDBOX  --> returns payment_id + client_secret
    |
    | (3) function returns { order_number, client_secret, publishable_key }
    v
 SHOPPER'S BROWSER mounts the official HyperSwitch checkout SDK
    |  shopper enters a TEST card (for example 4242 4242 4242 4242)
    |  SDK talks to HyperSwitch directly; card data never touches our code
    |
    | (4) SDK completion callback fires (client-side, UNTRUSTED)
    v
 EDGE FUNCTION confirm-payment (order_number only; no status accepted from client)
    |
    | (5) GET /payments/{payment_id} from HyperSwitch (secret key)  <- THE TRUTH
    |     status and amount checked server-side
    |
    | (6) only a HyperSwitch-confirmed 'succeeded' with the matching amount
    |     updates app.demo_orders to 'succeeded'                   [service role]
    v
 SHOPPER sees the confirmation screen with the server's order number
```

### 1.2 Step by step

1. The shopper walks the existing four-step checkout in `www\shop.html` (account,
   billing address, activation, payment) exactly as today. New behavior begins at
   the Place order action: instead of the always-succeeds demonstration handler,
   the site calls `create-payment`.
2. The site sends `create-payment` ONLY these fields:
   - `items`: array of `{ sku, mode, quantity }` where mode is `sub` or `one`
     (the cart snapshot; never any price)
   - `activation`: `priority` or `standard`
   - `tax_exempt`: true or false (the client's Tax ID digit check result; the
     server re-derives nothing from the Tax ID itself and the Tax ID value is
     NOT transmitted)
   - `member_code`: optional referring member code, may be blank
   - `channel`: `shop` (the Phase 4.5 staff console will send `staff_console`)
   Deliberately NOT sent: names, street addresses, card data, prices, totals,
   the Tax ID value. The billing address panel stays client-side stage dressing;
   no personal data leaves the browser. Card data goes only into the HyperSwitch
   SDK's own fields, never through our functions.
3. `create-payment` validates SERVER-SIDE:
   - every `sku` exists in the server pricing table and every `mode` is valid
     for it; unknown SKU or mode rejects the whole request (HTTP 400)
   - quantities are integers 1 to 99 per line, at most 25 total units, at most
     16 distinct lines
   - it recomputes subtotal (one-time), subtotal (monthly), activation fee, tax,
     total, and PV using ONLY the server pricing table (worked example in 1.5)
   - it caps the total at $25,000.00; anything above rejects (HTTP 400)
   - `member_code` is looked up in `app.members`; a match stores the member id,
     a miss stores null and keeps the raw text for the receipt (a demo order
     never fails because a stranger mistyped a code)
4. `create-payment` generates the ORDER NUMBER server-side, same format the shop
   already uses, `ORV-YYYY-MM-XXXXXX`: year, two-digit month, then a six-character
   base36 token, now built from the server clock plus two random base36 characters
   so two simultaneous strangers cannot collide. The client no longer generates
   order numbers; it displays what the server returns.
5. `create-payment` writes one row to `app.demo_orders` (section 2) with
   `payment_status = 'created'` and the full server-computed money snapshot, then
   calls HyperSwitch and updates the row with the returned `payment_reference`.
6. `create-payment` calls HyperSwitch `POST /payments` with:
   - `amount`: the server-computed total in MINOR UNITS (cents): $2,231.25 is
     sent as 223125
   - `currency`: `USD`
   - `capture_method`: `automatic`
   - `confirm`: false (the browser SDK collects the payment method and confirms)
   - `description`: `Orvanna demo order <order_number> (test mode, no real money)`
   - `metadata`: `{ "order_number": "...", "member_code": "..." or "", "demo":
     "true", "channel": "shop" }`
   The response's `payment_id` is stored as `payment_reference` and the
   `client_secret` is returned to the browser together with the publishable key
   and the order number. The secret API key is used only inside the function.
7. The site mounts the official HyperSwitch checkout SDK (section 1.4) with
   `client_secret` plus publishable key, inside the existing step-4 panel. The
   express buttons (Apple Pay, Google Pay, PayPal marks) remain demonstration
   drawings in v1; the SDK's card flow is the one REAL test rail. Copy on screen
   states: test mode, test cards only, nothing is ever charged (writer package,
   section 7).
8. On the SDK's completion callback the site calls `confirm-payment` with ONLY
   `{ order_number }`. The client cannot pass a status; there is nothing to
   forge. `confirm-payment` looks up the row, calls HyperSwitch
   `GET /payments/{payment_reference}` with the secret key, and checks:
   - `status` is `succeeded`
   - `amount` (and `amount_received` when present) equals the stored
     `total_cents` exactly
   Only then does it update the row to `payment_status = 'succeeded'` and store
   the processor summary (section 2). Any other status maps per section 5.4.
   The function returns the sanitized order receipt; the site renders the
   confirmation view from that response, not from its own math.

### 1.3 Canonical price source: mirrored pricing table inside the Edge Function (DECIDED)

The choice was between (a) a pricing table lookup in `app.products` and (b) a
mirrored catalog constant deployed with the Edge Functions. DECISION: (b), a
mirrored pricing module, shared by both functions.

Why not `app.products`: the database products table models the ENGINE's world,
twelve subscription agents with price and volume points. The shop sells sixteen
items across four tiers with two billing modes each, plus an activation fee and a
tax rule, none of which exist in `app.products` (bundles, packs, one-time 10x
prices, activation, tax are Phase 4C.2 display-layer constructs by explicit
ruling). Teaching `app.products` about modes and packs is a schema change to a
gate-passed, engine-facing table for the benefit of a demo checkout, exactly the
kind of scope bleed Phase 6 must not cause. The engine and its finalized months
stay untouched when the pricing mirror changes.

The mirror: a small server-side pricing table (one entry per SKU: tier, sub price,
sub PV, once price, once PV) plus the two constants (activation fee $25.00, tax
rate 5 percent), deployed inside the Edge Function bundle. `www\js\catalog.js`
remains the single source of truth for the SITE; the mirror must match it fact
for fact. Guard: the verifier gate includes a mechanical diff of the sixteen
(sku, mode, price, pv) quadruples between `catalog.js` and the deployed mirror
(section 6.1, check V6). Drift fails the gate. The mirror file carries a header
comment naming `catalog.js` as its master and this spec as the contract.

### 1.4 The one sanctioned external script

The static site's standing rule is no external scripts. Phase 6 grants EXACTLY ONE
exception, by name: the official HyperSwitch browser checkout SDK loader,
`HyperLoader.js`, loaded from HyperSwitch's own domain (the documented sandbox
loader URL, currently `https://beta.hyperswitch.io/v1/HyperLoader.js`; the builder
pins the exact URL from the HyperSwitch dashboard documentation at wiring time and
records it in the QA sheet). Nothing else external: no analytics, no fonts, no
other payment scripts. The SDK is what keeps card data inside HyperSwitch's
certified surface and out of our pages and functions.

### 1.5 Worked example (money and state, hand-computed)

Cart: 1 x Payment Agent, subscription mode, plus 1 x Ignition Pack, one-time mode.
Activation: Priority. No Tax ID digit, so tax applies. Channel: shop. Member code
entered: `GW-000123` (assume it exists).

Server recomputation from the pricing mirror:

| Line | Mode | Unit price | Qty | Amount | PV |
|---|---|---|---|---|---|
| Payment Agent | subscription | $100.00 | 1 | $100.00 | 100 |
| Ignition Pack | one-time | $2,000.00 | 1 | $2,000.00 | 2,000 |
| Priority activation | fee | $25.00 | 1 | $25.00 | 0 |

- Subtotal, monthly: $100.00
- Subtotal, one-time: $2,000.00
- Activation fee: $25.00
- Taxable base: $100.00 + $2,000.00 + $25.00 = $2,125.00
- Tax at 5 percent: $106.25
- Order total: $2,231.25
- Amount sent to HyperSwitch: 223125 (cents)
- Total PV: 2,100 (a qualified month is 100 PV or more, so the receipt says
  qualified)

Tamper case: a hostile client edits its JavaScript to claim a $1.00 total. It
cannot: the request carries no prices, only `{ sku, mode, quantity }`. The server
computes $2,231.25 from its own mirror and that is the only number HyperSwitch
ever sees. A hostile client inventing `{ sku: "payment", mode: "one", quantity: 1,
price: 1 }` gets the extra field ignored and pays the mirror's $1,000.00 one-time
price. A hostile client inventing SKU `free-agent` gets HTTP 400.

State walk for the same order:

| Moment | app.demo_orders.payment_status | Written by |
|---|---|---|
| create-payment validated the cart | `created` | create-payment (service role) |
| HyperSwitch returned payment_id | `created` (payment_reference now filled) | create-payment |
| Shopper completed the test card | unchanged (client callbacks write nothing) | nobody |
| confirm-payment retrieved `succeeded`, amount 223125 matches | `succeeded` | confirm-payment (service role) |

---

## 2. Schema delta

### 2.1 Decision: a parallel table, `app.demo_orders`, NOT rows in `app.orders`

`app.orders` is the commission engine's input. It requires a not-null `member_id`
(a stranger checking out as a guest has none), it feeds `volume_month`
aggregation, and it sits upstream of the six finalized commission months whose
statements are frozen by the immutability triggers (migration 006) and by the
finalized-months invariant. Writing live stranger traffic into the engine's input
table buys nothing in v1 (the engine is not being rerun for live orders) and
creates exactly one new risk: that a future rerun, view, or seed assumption
silently ingests stranger data into commission math. DECISION: live demo orders
get their own table, `app.demo_orders`, which the engine does not read and no
existing view touches. The finalized months cannot change because nothing that
computes them gains a new input. Promotion of demo orders into engine months is
explicitly OUT OF SCOPE for v1 and would be its own architect decision.

### 2.2 app.demo_orders (new, migration 010)

Schema `app`, RLS ON, no anon or authenticated policies, same posture as every
other table: only the service role (inside Edge Functions) reads or writes it.

| Column | Type | Rules |
|---|---|---|
| id | bigint generated always as identity | Primary key |
| order_number | text | unique, not null; `ORV-YYYY-MM-XXXXXX`, server-generated; THE idempotency key |
| created_at | timestamptz | not null, default now() |
| created_by_channel | text | check in ('shop','staff_console'); not null |
| member_id | bigint | null; foreign key app.members(id); resolved from member_code when it matches |
| referral_code_entered | text | null; the raw member code the shopper typed, kept for the receipt even when unresolved |
| items | jsonb | not null; the validated cart snapshot: array of { sku, mode, quantity, unit_price, unit_pv } as the SERVER priced them |
| activation | text | check in ('priority','standard'); not null |
| subtotal_one_cents | integer | not null; one-time subtotal in cents |
| subtotal_sub_cents | integer | not null; first-month subscription subtotal in cents |
| activation_fee_cents | integer | not null |
| tax_cents | integer | not null; 0 when tax_exempt |
| tax_exempt | boolean | not null |
| total_cents | integer | not null; the exact amount sent to HyperSwitch |
| pv_total | numeric(10,2) | not null |
| payment_reference | text | null until HyperSwitch responds; the HyperSwitch payment_id; unique when not null |
| payment_status | text | check in ('created','processing','succeeded','failed','abandoned'); not null, default 'created' |
| processor_summary | jsonb | null; sanitized summary from the server-side retrieve: { status, connector, payment_method_type, error_code, error_message, last_synced_at }. NEVER raw card data, never a full processor payload |
| status_updated_at | timestamptz | not null, default now() |

Indexes: unique (order_number); unique (payment_reference) where not null;
(created_at); (payment_status).

Money lives in integer cents in this table on purpose: it is the same unit the
HyperSwitch API uses, so the amount equality check in confirm-payment is an
integer comparison with no rounding question. Display formatting back to two
decimal dollars happens at the edge.

### 2.3 Rate limit ledger (new, same migration)

| Column | Type | Rules |
|---|---|---|
| ip_hash | text | part of primary key; salted hash of the caller's IP address, salt from the vault; the raw IP is never stored |
| window_start | timestamptz | part of primary key; the minute bucket, truncated |
| request_count | integer | not null |

Table `app.demo_rate_events`, primary key (ip_hash, window_start). RLS ON, no
policies, service role only. A scheduled cleanup (or opportunistic delete inside
the function) drops rows older than 24 hours.

### 2.4 How live orders appear to visitors (anon posture preserved)

The constraint is zero new anon grants, so there is NO new `v_demo_live_orders`
view for anon in v1. Instead, a third Edge Function, `list-demo-orders`, returns
the most recent 25 sanitized live orders (order_number, created_at,
created_by_channel, item count, total in dollars, pv_total, payment_status;
nothing else: no referral text, no processor detail). It reads with the service
role, is rate limited like the others, and the portal or shop page renders a
"Live demo orders" section from it. The anon key's database surface stays byte
for byte what it is today: seven views. (If Howard later prefers a real view plus
one anon grant, that is a posture change only he can rule on; open question 3.)

### 2.5 Worked example: the row after the section 1.5 order succeeds

```
order_number         ORV-2026-08-0K7Q2A
created_by_channel   shop
member_id            123            (GW-000123 resolved)
referral_code_entered GW-000123
items                [ { sku payment, mode sub, quantity 1, unit_price 100.00, unit_pv 100 },
                       { sku ignition, mode one, quantity 1, unit_price 2000.00, unit_pv 2000 } ]
activation           priority
subtotal_one_cents   200000
subtotal_sub_cents   10000
activation_fee_cents 2500
tax_cents            10625
tax_exempt           false
total_cents          223125
pv_total             2100.00
payment_reference    pay_abc123XYZ   (HyperSwitch payment_id)
payment_status       succeeded
processor_summary    { status succeeded, connector <sandbox connector>,
                       payment_method_type card, error_code null,
                       error_message null, last_synced_at 2026-08-14T18:30:12Z }
```

Invariant restated: no row in `app.demo_orders`, whatever a stranger does, is an
input to `app.commission_runs`, `app.run_member_results`, or
`app.commission_lines`. The six finalized months (February through July 2026)
must be byte-identical before and after any demo order, and section 6.1 makes
that a proven gate check, not an assumption.

---

## 3. Secrets layout

All secrets live in the Supabase secrets vault of project `oiyibdczkokegaxkwulv`,
typed by Howard in the dashboard. Rotating or setting any of them is a
DASHBOARD-ONLY operation: never via chat, never via a checked-in file, never via
a command an agent runs. Edge Functions read them as environment variables at
runtime.

| Secret name | What it is | Used by |
|---|---|---|
| HYPERSWITCH_API_KEY | The regenerated SECRET HyperSwitch sandbox API key. Authorizes POST /payments and GET /payments/{id}. | create-payment, confirm-payment |
| HYPERSWITCH_HASH_KEY | The regenerated payment response hash key. Verifies webhook signatures in v1.1 (section 4). Stored now so rotation happens once. | webhook handler (v1.1) |
| HYPERSWITCH_PUBLISHABLE_KEY | `pk_snd_bfcb22d171b54957b2cdc9046c56ae16`. Public by design; vaulted anyway so the functions have one source and a future key swap is one dashboard edit. | create-payment (returned to the browser) |
| ORVANNA_DEMO_IP_SALT | Random salt for hashing caller IP addresses in the rate limit ledger, so raw IPs are never stored. Howard generates it (any long random string) and types it in. | all three functions |

Provided by the platform automatically (not typed by anyone): `SUPABASE_URL` and
the service role key are injected into Edge Functions by Supabase itself. The
service role key is likewise never written down anywhere in this project.

Rule restated because it is the whole point: the two HyperSwitch secrets being
wired are the REGENERATED pair. The old pair, which touched a chat window, is
dead the moment the new pair exists, and Howard deletes his local
`C:\Users\howar\Desktop\Desktop\HyperSwitch\APIKEY` copy himself afterward.

---

## 4. Webhooks versus polling

RECOMMENDATION (v1): server-side retrieve on confirm. No webhook endpoint ships
in v1.

Reasoning, spelled out:

1. The trust problem. Anything the BROWSER says about payment status is
   forgeable: a visitor can call `confirm-payment` claiming success at will. The
   only two trustworthy channels are (a) our server asking HyperSwitch directly
   with the secret key, and (b) HyperSwitch calling us with a message we verify
   cryptographically. v1 uses (a): `confirm-payment` calls
   `GET /payments/{payment_id}` and believes only that response. A forged
   confirm therefore degenerates into asking us to re-check the truth, which is
   harmless.
2. Why polling wins for v1. The retrieve path is one authenticated outbound call
   with no new public surface. A webhook endpoint is a PUBLIC URL that accepts
   unsolicited POSTs; it is only safe when every payload's signature is verified
   against HYPERSWITCH_HASH_KEY, with replay and ordering handled. That is real
   work and real attack surface, and v1 does not need it: the shopper is present
   at confirmation time, card sandbox flows resolve in seconds, and nothing
   downstream (no fulfillment, no commissions) waits on late status changes.
3. The gap polling leaves, honestly stated. If a shopper closes the tab between
   paying and the confirm call, the row can sit at `created` even though
   HyperSwitch shows `succeeded`. v1 accepts this: `list-demo-orders` shows such
   rows as `created` or `abandoned` (section 5.4), and a reconcile sweep can
   re-retrieve stale `created` rows opportunistically when either function runs.
   No money is real, so nothing is lost but tidiness.
4. v1.1, planned: a `hyperswitch-webhook` Edge Function. Every incoming payload
   is verified against HYPERSWITCH_HASH_KEY (signature match required, reject
   otherwise), matched to `app.demo_orders` by `payment_reference`, and even
   then the handler treats the webhook as a HINT: it re-retrieves the payment
   server-side before writing, so a forged or replayed webhook can never write a
   status the API does not confirm. Webhooks close the abandoned-tab gap and are
   the professional pattern the platform demo should eventually show.

---

## 5. Abuse and safety rails

### 5.1 Rate limits (inside the Edge Functions, backed by app.demo_rate_events)

- Key: salted hash of the caller IP (salt ORVANNA_DEMO_IP_SALT). Raw IP never
  stored.
- `create-payment`: at most 5 requests per minute AND at most 30 per hour per
  IP hash. Over limit: HTTP 429 with a friendly plain-English body and a
  Retry-After header.
- `confirm-payment` and `list-demo-orders`: at most 20 per minute per IP hash
  (confirm may be retried legitimately; listing is cheap and read-only).
- Global circuit breaker: if `create-payment` writes more than 500 rows in one
  UTC day, it returns HTTP 503 ("the demo is resting") until the next day.
  Protects the free tier and caps any scripted abuse at a known ceiling.

Worked example: a script hits create-payment 7 times in one minute from one IP.
Requests 1 to 5 pass (bucket count 1,2,3,4,5). Requests 6 and 7 read count 5,
exceed the limit, return 429, and are NOT written as orders. The next minute
bucket starts empty, but the hourly count (now 5) keeps accruing toward 30.

### 5.2 Cart caps (server-enforced in create-payment)

- 1 to 99 units per line (matches the shop's own cap), at most 16 distinct
  lines (the whole catalog once), at most 25 total units, total at most
  $25,000.00 (2,500,000 cents). Violations: HTTP 400, no row written.
- CORS: the functions answer only to origin `https://orvanna.io` (plus a
  localhost origin while developing). The functions are invoked with the public
  anon key as the bearer token, which is standard Supabase function invocation
  and grants NOTHING on the database; all database access inside uses the
  service role.

### 5.3 Test-card-only enforcement

Inherent to the platform, and worth saying plainly: the HyperSwitch SANDBOX
environment processes only test payment instruments against test connectors. A
real card number entered into the sandbox does not move real money anywhere; there
is no charge path to the real world from app.hyperswitch.io test mode. Our rails
therefore do not need to (and could not) validate card numbers; the framing job
is COPY: the payment panel states "Test mode. Use a test card such as
4242 4242 4242 4242. Nothing is ever charged." (writer package, section 7).

### 5.4 Decline, abandon, and status mapping

| HyperSwitch retrieve says | app.demo_orders.payment_status | Shopper sees |
|---|---|---|
| succeeded | succeeded | Confirmation view, order number, PV note |
| failed / cancelled | failed (processor_summary keeps error_code and error_message) | Friendly decline: "The test bank declined this one. Try the standard test card." Cart is PRESERVED so retry is one click |
| requires_confirmation, requires_customer_action, processing | processing | "Still processing, one moment"; the site may re-call confirm-payment (rail: 20 per minute) |
| row stuck at created or processing for over 1 hour | abandoned (swept opportunistically) | Nothing; it shows as abandoned in list-demo-orders |

The cart clears ONLY on `succeeded`. Today's demo clears it on submit; Phase 6
moves the clear to the confirmed-success branch.

### 5.5 Idempotency (same order number retried must not double-write)

- `order_number` is unique in `app.demo_orders`; the database itself forbids two
  rows for one order.
- `create-payment` creates a NEW order number per call, so double-clicking Pay
  creates at most one HyperSwitch payment per returned client_secret; the site
  disables the Pay button once a client_secret is in hand and reuses it.
- `confirm-payment` is idempotent by construction: it retrieves, compares, and
  UPDATES the one row. Calling it five times for the same order produces the
  same final row; a repeat call on an already-succeeded row is a no-op that
  returns the same receipt. There is no INSERT anywhere in confirm-payment.
- If create-payment dies between the HyperSwitch call and its response reaching
  the browser, the row exists with a payment_reference and status `created`;
  the shopper simply pays nothing and the row ages into `abandoned`. No
  duplicate is possible because the browser never got a second order number.

---

## 6. Acceptance criteria, the two gates

### 6.1 mlm-verifier must be able to RECOMPUTE or PROVE, independently

- V1 Anon posture unchanged, LIVE-PROBED: with the public anon key against the
  live project, (a) every one of the seven `v_demo_*` views still answers
  SELECT; (b) `app.demo_orders`, `app.demo_rate_events`, and every other
  `app.*` table refuse SELECT, INSERT, UPDATE, and DELETE; (c) no eighth
  relation is readable by anon (enumerate grants, compare to the Phase 5
  baseline).
- V2 Forged confirm rejected: call `confirm-payment` for an order whose
  HyperSwitch status is NOT succeeded (or with a made-up order number). Prove
  the row's payment_status did not become `succeeded` and the response reveals
  nothing beyond the sanitized status.
- V3 Price tampering rejected: replay a `create-payment` request carrying bogus
  price fields and a hostile SKU. Prove (a) extra fields changed nothing (the
  HyperSwitch payment amount equals the mirror's math to the cent), and (b) the
  unknown SKU got HTTP 400 with no row written.
- V4 Finalized months byte-identical: checksum `app.commission_lines` and
  `app.run_member_results` for all finalized runs (an ordered dump hashed with
  a cryptographic hash) BEFORE a live test order and again AFTER it succeeds.
  The two checksums must be equal. Also recompute one prior month end to end
  (the standing Phase 3 skill) and match to the cent.
- V5 Amount equality: for a succeeded order, independently recompute the total
  from the items jsonb (unit prices, activation, tax at 5 percent, rounding
  half up to 2 decimals) and prove it equals `total_cents` AND the amount on
  the HyperSwitch payment object.
- V6 Mirror parity: mechanical diff of all sixteen (sku, mode, price, pv)
  quadruples plus activation fee and tax rate between `www\js\catalog.js` and
  the deployed pricing mirror. Zero differences.
- V7 Secrets hygiene: grep the entire repository and the deployed function
  sources for the secret key patterns (and the old exposed pair). Zero hits;
  the only key present anywhere client-visible is the publishable key.

### 6.2 mlm-qa must TRACE, on the live site

- Q1 Happy path: from orvanna.io, real browser, build the section 1.5 cart, pay
  with a HyperSwitch test card, land on confirmation, and match every displayed
  number ($2,231.25 total, 2,100 PV, order number format) to the
  `app.demo_orders` row.
- Q2 Decline path: pay with the documented sandbox decline card; see the
  friendly decline copy, cart preserved, row `failed` with error fields
  populated; then retry and succeed on the same cart.
- Q3 Idempotent retry: double-click Pay, call confirm twice (or refresh
  mid-flow); prove exactly one order row and one confirmation.
- Q4 Rails: drive one IP past 5 create-payment calls in a minute and see 429
  with readable copy; submit a 26-unit cart and see 400; verify the CORS
  refusal from a foreign origin.
- Q5 Framing: the payment screen states test mode, test cards, nothing charged,
  before and during SDK mount; no real brand logos; acronyms expanded on first
  use; money always two decimals.
- Q6 Abandon: pay-then-close-tab; confirm the row ages to `abandoned` and the
  live-orders section shows it honestly.
- Q7 No personal data: inspect the create-payment request in the network panel;
  confirm no name, address, Tax ID value, or card field ever leaves the browser
  toward OUR functions.

Both gates PASS before Phase 6 closes; either gate failing returns the work to
its owning builder with the failing check named.

---

## 7. Build sequence

Prerequisites, Howard, dashboard only, BEFORE any wiring:

- H1 Regenerate both HyperSwitch keys (secret API key and payment response hash
  key) in the app.hyperswitch.io dashboard, then type the fresh values plus
  ORVANNA_DEMO_IP_SALT and the publishable key into the Supabase secrets vault.
  Afterward delete the local APIKEY file.
- H2 In the HyperSwitch dashboard, enable a TEST connector on the sandbox
  profile (the built-in dummy/test connector, or a Stripe test-mode connector)
  so test-card payments have a rail to run on. Note which connector, for the QA
  sheet.

Work packages, in order:

| # | Package | Owner | Depends on |
|---|---|---|---|
| W1 | Migration 010: app.demo_orders + app.demo_rate_events, RLS on, no policies, indexes and checks per section 2 | mlm-db-engineer | nothing (can start now) |
| W2 | Edge Functions: create-payment, confirm-payment, list-demo-orders, with the pricing mirror module, rails, CORS, and status mapping per sections 1, 4, 5 | mlm-site-builder | H1, H2, W1 |
| W3 | Checkout wiring in www\shop.html: call create-payment on Pay, mount HyperLoader (the one sanctioned external script), call confirm-payment on completion, success/decline/processing branches, cart clears only on success, live-orders section from list-demo-orders | mlm-site-builder | W2 |
| W4 | Payment-screen framing polish: test-mode banner, SDK panel styling consistent with the glass checkout, decline state design | orvanna-designer | W3 in draft |
| W5 | The obviously-test copy: banner, decline message, confirmation receipt wording, test-card hint | orvanna-writer | W4 |
| W6 | Verifier gate V1 to V7 (section 6.1) | mlm-verifier | W1 to W5 done |
| W7 | QA gate Q1 to Q7 on the live site (section 6.2) | mlm-qa | W1 to W5 done |

Both gates run last, independently, and Phase 6 closes only on BOTH passing,
per the standing roadmap rule.

---

## Open questions for Howard

1. Live-orders visibility (section 2.4): v1 shows recent live demo orders
   through the rate-limited `list-demo-orders` Edge Function so the anon grant
   list stays untouched. Alternative: a real `v_demo_live_orders` view plus ONE
   new anon grant. Recommendation: keep the Edge Function route; the untouchable
   anon posture stays literally untouched.
2. Where the live-orders section renders: shop page footer section versus a
   portal page. Recommendation: shop page, near the confirmation exit, framed as
   "recent test orders from visitors like you"; the portal stays the members'
   room.
3. Daily circuit breaker ceiling (section 5.1): 500 orders per UTC day is
   proposed. Raise or lower on taste; anything in the hundreds keeps the free
   tier and the table tidy. Recommendation: keep 500.
4. Subscription reality (section 1.2): v1 charges the first month as a one-shot
   test payment and does NOT create a HyperSwitch recurring mandate. True
   recurring billing on the orchestrator is its own phase. Recommendation:
   confirm this stays out of Phase 6.
