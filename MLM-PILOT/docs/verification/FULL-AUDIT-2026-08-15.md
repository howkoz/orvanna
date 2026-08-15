# Full Correctness and Security Audit, 2026-08-15

Auditor: mlm-verifier (independent; built none of this).
Scope: the whole MLM Pilot, weighted toward the work of 2026-08-15, all of which
shipped to production with no verifier and no Quality Assurance (QA) gate.
Method: read every file in the money path and the sign-in path, recompute the
money independently, recompute one full commission period independently from the
specification (not from the engine's code), and query the live database directly
for the applied security posture.

**GATE VERDICT: FAIL.** Four HIGH findings. The money path itself is sound; the
failures are in the new auto-open checkout, in order attribution, in a security
claim the code makes about itself that is not true, and in credential hygiene.

Acronym key: Application Programming Interface (API), Cross-Origin Resource
Sharing (CORS), Commissionable Volume (CV), Hash-based Message Authentication
Code (HMAC), Internet Protocol (IP), JavaScript Object Notation (JSON), Personal
Volume (PV), Row-Level Security (RLS), Sales Volume (SV), Team Volume (TV),
Three-Domain Secure (3DS), Coordinated Universal Time (UTC).

---

## 1. Findings, severity ranked

| # | Sev | Finding | File and line |
|---|---|---|---|
| H1 | HIGH | A total that moves while `create-payment` is in flight is dropped on the floor. `liveEnsureCheckout` returns early on `busy`, `resuming`, `checkOnly` or `challengeOpen` and schedules no re-check, so `liveOpenedFor` keeps the stale signature. The card form then mounts with a button reading the CURRENT total while the open payment carries the OLD one. | `www/shop.html:1598`, `1614`, `1995` |
| H2 | HIGH | A hand-typed member code is silently discarded on the live path. `#memberCode` has no input listener, so nothing calls `liveEnsureCheckout` when it changes; the auto-opened payment was already created with an empty `member_code`. A guest who types a sponsor's code gets an order credited to nobody. Regression created by the auto-open. | `www/shop.html:181`, `1573`, `1917` |
| H3 | HIGH | The session token is never verified, and the shipped comment claims it is. `sessionIsValid` checks only that `token` is truthy plus role and expiry. Writing `{"token":"x","role":"staff","expires_at":9999999999}` into `sessionStorage` opens the staff console; the same trick with `"admin"` opens the member portal. The comment "The token was signed by the server; the browser cannot mint or edit one" is false as implemented, and it is public source. | `www/staff.html:298-312`, `site/index.html:66-88` |
| H4 | HIGH | The administrator and staff passwords are in version control in plaintext and were never rotated. Commit `9c802a5` carries `crypt('Orvanna2026', ...)` and `crypt('2026Orvanna', ...)`. Migration 012 acknowledges the draft survives in history but records no rotation. Private repository, so exposure is bounded, but these are the only credentials gating the console and they are guessable besides. | `db/migrations/012_demo_auth.sql:64-76`, git `9c802a5` |
| M1 | MEDIUM | Cart edits made while the checkout view is open never reach the checkout. The drawer handler calls `renderAll()`, which is `renderBadge` plus `renderDrawer` only. The summary and the opened payment both stay stale; the drawer shows one total and the order carries another. | `www/shop.html:822-840`, `2565-2568` |
| M2 | MEDIUM | The auto-open manufactures orphan orders and burns the rails. Measured in production: 2026-08-14 (before auto-open) 49 orders created, 5 stuck at `created` (10 percent); 2026-08-15 (auto-open) 32 created, 21 stuck at `created` WITH a live HyperSwitch payment attached (66 percent). The 500-per-UTC-day circuit breaker counts every row, so mere browsing consumes it, and the abandon sweep only runs when somebody happens to load the shop. | `www/shop.html:1577-1628`, `functions/create-payment/index.ts:281-293` |
| M3 | MEDIUM | `confirm-payment` performs no authorization, and `list-demo-orders` publishes the last 25 order numbers to anyone on the site. Chained, a visitor reads any recent order's full cart, totals, `referral_code_entered`, and processor error text, and forces a HyperSwitch retrieve per call at 20 per minute. Nothing personal is stored, which is what keeps this MEDIUM rather than HIGH. | `functions/confirm-payment/index.ts:176-195`, `functions/list-demo-orders/index.ts:85-96` |
| M4 | MEDIUM | Specification drift, three places, none amended. Section 1.2 step 1 still says the payment is created at the Place order action; it is now created on arrival at checkout. Ground rule 5 and section 1.4 still say EXACTLY ONE external script; the site loads three URLs from two hosts. Section 5.3's test-card copy still names `4242 4242 4242 4242`; the site now names the Braintree table. | `docs/PHASE-6-SPEC.md:31-33`, `:88-90`, `:174-183`, `:~245` |
| M5 | MEDIUM | A third-party chat script runs on the payment page. Botpress loads on `shop.html` beside the card form. The card number is inside HyperSwitch's cross-origin frame so the number itself is safe, but the script has full access to the page's Document Object Model and to the `client_secret`. Acceptable on a test rail; it must never carry to a live one. | `www/shop.html:2587-2588` |
| M6 | MEDIUM | Migration 013 is applied to production and absent from the repository. The cloud records `013_demo_orders_created_at_index` at version `20260815175105`; `db/migrations/` jumps from 012 to 014. Its body is a single `create index if not exists demo_orders_created_at_idx on app.demo_orders (created_at desc)`, harmless in itself, but the migration folder no longer describes the database. | `db/migrations/` (missing file) |
| M7 | MEDIUM | Howard's real first name appears 16 times in the public build, in comments carrying verbatim internal quotes and dated rulings, together with the processor's identity ("the account now runs Braintree in sandbox"). Against the generic-persona guardrail, and readable with View Source at orvanna.io. | `deploy/dist/shop.html` (8), `index.html` (2), `team.html` (4), `staff.html` (1), `portal/js/app.js` (1) |
| M8 | MEDIUM | The rate limiter reads then increments in two separate statements with no lock or atomic upsert-and-test, so concurrent requests can each read the same count and all pass. The stated ceiling is a soft one under concurrency. | `functions/_shared/edge.ts:176-211` |
| M9 | MEDIUM | `demo-login`'s role allow-list omits `member`, so a page asking `role: "member"` silently gets "any role is acceptable". Only `shop.html`'s own client-side check currently stops an administrator credential becoming a shopper. | `functions/demo-login/index.ts:111` |
| L1 | LOW | The daily circuit breaker uses `date_trunc('day', now())`, which follows the session time zone rather than UTC as the specification states. Correct today because the project runs UTC; fragile as a written guarantee. | `functions/create-payment/index.ts:283` |
| L2 | LOW | The client never enforces or explains the 25-total-unit cap. With the auto-open, a 26-unit cart now fails as a status line on the payment step instead of at the cart, with no route back except the drawer. | `www/js/catalog.js:396-416`, `functions/_shared/pricing.ts:194-199` |
| L3 | LOW | `catalog.js` ships with a UTF-8 byte order mark (`ef bb bf`). Harmless as JavaScript, untidy. | `www/js/catalog.js:1` |
| L4 | LOW | Supabase advisors report 7 SECURITY DEFINER views at ERROR and 7 mutable-`search_path` functions at WARN. Both are safe here and I verified why: `anon` and `authenticated` have no USAGE on the `app` schema at all, and every `app` function is SECURITY INVOKER (`prosecdef = false`). The finding is that nothing in the repository records this analysis, so the ERRORs look unexamined. | Supabase advisors, project `oiyibdczkokegaxkwulv` |
| L5 | LOW | `build_dist.py` copies `www/` and `site/` verbatim with no secret scan before publishing to a public repository. Nothing has leaked; the guard is simply absent. | `deploy/build_dist.py:127-140` |
| L6 | LOW | If the `payment_reference` update fails after HyperSwitch created the payment, the row is orphaned with no reference and the webhook cannot find it by payment id. Bounded by the metadata fallback in the webhook, which looks the order up by `order_number`. | `functions/create-payment/index.ts:481-486` |

---

## 2. The money path: recomputed independently

### 2.1 Does the server price the cart correctly?

Yes. I recomputed the specification's worked example (section 1.5) by hand from
`pricing.ts` alone:

```
Payment Agent, subscription   $100.00 ->  10,000 cents
Ignition Pack, one-time     $2,000.00 -> 200,000 cents
Priority activation            $25.00 ->   2,500 cents
taxable base                            212,500 cents
tax, 5 percent                           10,625 cents
ORDER TOTAL                             223,125 cents = $2,231.25
```

Matches the specification to the cent. The mirror check passes 16 of 16 items,
32 of 32 (sku, mode, price, PV) quadruples, plus the activation fee and the tax
rate:

```
PASS: pricing mirror matches catalog.js fact for fact.
```

The rounding comment in `pricing.ts:205-211` is correct and I verified the
reasoning: every catalog price and the activation fee are whole dollars, so
`taxableCents` is always a multiple of 100 and `taxableCents * 5 / 100` is always
an exact integer. There is no floating-point question on the server, and the
site's `round2(taxable * 0.05)` lands on the same cent.

### 2.2 Can a client ever influence an amount?

No. `priceCart` reads exactly three fields off each line, `sku`, `mode` and
`quantity`, and nothing else in the request body is ever consulted for money
(`functions/_shared/pricing.ts:141-192`). A posted `price`, `total`, or
`unit_price` is structurally unreachable. Caps are enforced server side: 1 to 99
per line, at most 16 distinct lines, at most 25 total units, at most
$25,000.00, duplicate `sku|mode` rejected.

### 2.3 Is the amount checked to the cent before any success?

Yes, in one implementation used by both callers
(`functions/_shared/edge.ts:585-603`). Integer comparison of `hs.amount` and, when
present, `hs.amount_received` against the stored `total_cents`. A mismatch is
forced to `processing` with reason `amount_mismatch` and can never be written as
`succeeded`. This is the single strongest control in the project and it is
correctly placed as the last word.

### 2.4 Can a payment status be written from anywhere but a server-side retrieve?

No. I traced every write to `app.demo_orders.payment_status`:

- `create-payment` writes the literal `'created'` on insert only.
- `confirm-payment` and `payment-webhook` both write only through
  `retrieveAndApplyPaymentTruth`, which sources the status from its own
  authenticated `GET /payments/{id}`.
- The webhook verifies HMAC-SHA512 over the raw body with a constant-time
  comparison BEFORE opening any database connection, and then still ignores the
  body's status field entirely, reading only an identifier out of it
  (`functions/payment-webhook/index.ts:201-235`).
- The abandon sweep writes only `'abandoned'`, and only after a final retrieve
  that failed to resolve the row.

The guarded `UPDATE ... where payment_status in (...)` makes a terminal row
immutable, and I confirmed the database enforces the same rule independently. The
live trigger body reads:

```
if old.payment_status in ('succeeded', 'failed') then raise exception ...
if old.payment_status = 'abandoned' and new.payment_status not in ('succeeded','failed') then raise exception ...
if new.payment_status = 'created' then raise exception ...
```

That is exactly what the code comments claim. PASS.

---

## 3. The auto-open in `www/shop.html`

The design is thoughtful. The amount signature covers precisely the four inputs
that can move the total or the attribution (items, activation, tax exemption,
member code), `renderSummary` is a genuine funnel for the amount-affecting
controls, the replace path discards the old payment rather than reusing it, and
the server reprices from scratch every time. The intent is right.

Three holes remain, and two of them are the exact hazard the design set out to
close.

**H1, the in-flight window.** `liveEnsureCheckout` opens with

```js
if (liveState.busy || liveState.resuming || liveState.checkOnly || challengeOpen) return;
```

and returns without scheduling anything. `liveState.busy` is true for the whole
`create-payment` round trip, measured at 2.2 seconds. Reachable sequence: enter
checkout, the auto-open starts; choose "Continue as guest" quickly, which reveals
the activation radios; toggle priority activation before the create resolves.
`renderSummary` fires, `liveEnsureCheckout` returns on `busy`, and no re-check is
queued. The create then resolves, `liveMountCheckout` runs, and line 1995 sets

```js
placeOrderBtn.textContent = 'Pay ' + fmtMoney(orderMath().total) + ' now, test mode';
```

from the CURRENT math while `liveState.clientSecret` belongs to the OLD amount.
The shopper is shown one figure and charged another.

Impact is bounded, and the bound is worth stating precisely: the amount actually
taken always equals the amount the server priced and stored, the cent check still
holds, and the confirmation view renders from the server receipt, so the final
receipt is truthful. What is wrong is the figure on the button at the moment of
consent. On a test rail that is a bug; on a live rail it is a consent defect.

The fix is one line in shape: on any early return, remember that a re-check is
owed and run it when the blocking condition clears.

**H2, the member code.** The signature includes `member_code`, which shows the
author knew it mattered. Nothing ever fires on it: `#memberCode` has no `input`
listener, and the only two calls that follow a member-code change come from the
sign-in path (line 1018) and from `clearSignedInMember`. In the guest path the
field is free text, and the auto-opened payment was created before a single
character was typed. The order lands with `referral_code_entered` null. Before
the auto-open this worked, because `liveStart` read the field at submit time.

For a project whose entire subject is sponsor attribution, this is the most
consequential finding in the audit even though no money moves incorrectly.

**M1, the cart.** The nav cart button (`www/shop.html:28`) is outside the view
system and is only disabled while a payment is in flight, so the drawer is
reachable from the checkout view. Drawer edits call `renderAll()`, which never
touches `renderSummary`. The drawer, the checkout summary, and the open payment
can all disagree.

**What I could NOT break.** A stale `client_secret` cannot survive a cart change
by any path I could construct: `liveResetPayment` clears `liveOpenedFor`, the
client secret, the mount, and the resume state together, and `checkoutButton`
calls it unconditionally on every fresh entry to checkout. `resumeBoot` sets
`checkOnly`, which blocks any second create behind an unresolved resume. The
return address is built server side from a validated Origin plus a two-item page
allow list, so no open redirect is available. `cleanAddressBar` strips the query
so a refresh cannot re-enter carrying a stale secret. The client secret is written
to `sessionStorage` only; the `localStorage` copy is explicitly nulled
(`www/shop.html:1384`). All of that is correct.

---

## 4. The member sign-in

### 4.1 Is `app.demo_users` still sealed?

Yes, verified against the live database, not against the migration text:

```
demo_users        rls_on=true  policies=0  acl=postgres=arwdDxtm/postgres
demo_auth_config  rls_on=true  policies=0  acl=postgres=arwdDxtm/postgres
demo_orders       rls_on=true  policies=0  acl=postgres=arwdDxtm/postgres
demo_rate_events  rls_on=true  policies=0  acl=postgres=arwdDxtm/postgres
```

and, more decisively, `anon`, `authenticated` and `service_role` all have
`has_schema_privilege(..., 'app', 'USAGE') = false`. There is no path from a
public role into the `app` schema at all. PASS.

The seven public views expose only `member_code`, `display_name`, `enrolled_on`,
`rank_name`, period figures, tree edges and statement lines. No email column, no
key material, no raw table. PASS.

### 4.2 Is the posture sound and honestly described?

The credential check is real. The comparison happens inside Postgres against a
bcrypt hash the public key cannot reach, the failure message is identical for
every failure shape so it cannot confirm a username, and the endpoint has its own
rate-limit bucket at 8 per minute and 40 per hour.

Applied state matches the migration:

```
role     n     distinct_salts  with_member_code  non_bcrypt
admin       1  1               0                 0
member   1000  1               1000              0
staff       1  1               0                 0
```

One thousand member accounts, all sharing one bcrypt hash, exactly as migration
014 says and for the reason it gives. For a password printed on the page, that is
a defensible choice, and it is described honestly.

The honesty breaks in one place, and it is H3. Migration 012 and `demo-login`
both carry a careful "honest scope" note saying the gate is not absolute because
the site is static and the views are anon-readable. That note is accurate, but it
lives in files a visitor never sees. What the visitor CAN see, in the shipped
page source, is a comment asserting that the token cannot be minted or edited by
a browser. That assertion is untrue: neither gate verifies the HMAC, so a
hand-written session object passes. The impact today is close to nil, because
everything behind the gate is already anon-readable and a forged staff session
buys only the ability to place a `staff_console` order that the shop would place
anyway. The defect is that shipped code makes a security claim it does not honour.

### 4.3 Can a member account reach anything it should not?

No. Verified on both sides:

- Server: `demo-login` returns `wrong_role` when `role` is `admin` or `staff` and
  the account is a member (`functions/demo-login/index.ts:146-155`).
- Client: `site/index.html` requires `role === 'admin'`, `www/staff.html` requires
  `role === 'staff'`. A member role satisfies neither.

The residual gap is M9, the missing `member` entry in the allow-list, which means
the shop's own check is currently client-side only. Worth closing, but it does
not let a member into anything.

---

## 5. Secrets

Clean. Scanned every committed file, the whole `deploy/dist` tree, and the public
repository's full history.

- No secret key, hash key, service-role key, or salt appears in any file.
- The only key in the shipped pages is the `anon` JSON Web Token. I decoded it:
  `{"iss":"supabase","ref":"oiyibdczkokegaxkwulv","role":"anon", ...}`. Public by
  design and, as shown in section 4.1, it grants nothing on the `app` schema.
- The HyperSwitch secret and hash keys and the IP salt are read only through
  `Deno.env.get` and never logged. Error paths log status codes and order numbers
  only, never bodies.
- The public repository `github.com/howkoz/orvanna.io` history contains exactly
  one credential, `OrvannaDemo2026`, which is the deliberately public member
  password printed on the checkout page. Correct.
- `deploy/dist` is a faithful build of `www/` and `site/`. The only differences
  are the two documented link rewrites.

The one credential problem is H4, and it is in the PRIVATE repository, not the
public one.

---

## 6. Migrations, applied versus recorded

| Cloud | Repository | Verdict |
|---|---|---|
| 001 to 007 | present | match |
| 008 `_comp_engine_v12`, 009 `_rank_qualification_gate_v13` | `008_comp_engine_POINTER.md` -> `db/comp/` | match, pointer is adequate |
| 010, 011, 012 | present | match |
| **013 `_demo_orders_created_at_index`** | **absent** | **DRIFT (M6)** |
| 014 `_member_sign_in_accounts` | present | match |

Migration 014's applied body and the committed file agree on every statement that
matters: the role check constraint now reads
`role = ANY (ARRAY['admin','staff','member'])`, the `member_code` column exists
and is populated on all 1,000 member rows, and the `revoke all ... from anon,
authenticated` held. Only the header prose differs slightly between the two.

---

## 7. Compensation engine, recomputed independently

Charter requirement: recompute a full period from the specification, not from the
engine's code. I wrote my own recursive SQL from `COMP-PLAN-SPEC.md` v1.3, giving
SV, CV, TV, qualification, the four rank tests, paid depths, and every commission
line, and compared it to stored run 12 (2026-07-01, v1.3, final):

```
my_lines   2187   engine_lines   2187
my_payout  20669.20   engine_payout  20669.20
my_paid     284   engine_paid     284
my_sv  172550.00   my_cv  138040.00   (both match commission_runs)
lines in mine not in engine   0
lines in engine not in mine   0
rank disagreements            0
volume disagreements (sv, cv, tv)  0
```

Exact agreement on 2,187 lines to the cent. PASS.

Immutability holds at the database level: `commission_lines` and
`run_member_results` each carry a BEFORE DELETE OR UPDATE trigger rejecting writes
when the run is final, plus a BEFORE INSERT trigger rejecting writes INTO a final
run. The v1.2 runs are retained as `superseded` rather than deleted, which is the
right shape for an auditable statement history.

---

## 8. Project guardrails

| Guardrail | Result |
|---|---|
| Zero Unicity data, names, or terminology | PASS, nothing in the shipped output |
| Generic industry language | PASS |
| No em dashes or en dashes | PASS, zero in `www/` and `deploy/dist` |
| Acronyms expanded on first use | PASS in the functions, the specifications, and the page copy |
| Synthetic-data basis stated on every page | PASS, present on all seven published pages |
| Generic persona, no personal identity in the product | **FAIL (M7)**, 16 occurrences of Howard's name in public comments |

---

## 9. What must be fixed before this is shown to anyone

In order.

1. **H2, the member code.** Add an `input` listener on `#memberCode` that calls
   `liveEnsureCheckout` (the debounce already exists for exactly this shape of
   typing). Until then, no guest order is attributed and the demonstration's
   central mechanic is silently broken.
2. **H1, the in-flight window.** Make the early returns in `liveEnsureCheckout`
   remember that a re-check is owed, and run it when `busy`, `resuming`,
   `checkOnly` and `challengeOpen` all clear. Belt and braces: recompute the
   button label from the amount the payment was OPENED at, not from live
   `orderMath()`, so the two can never disagree even if the re-check is missed.
3. **H3, the session claim.** Either verify the HMAC (which needs a small
   server-side verify endpoint) or delete the false comment and replace it with
   what is actually true: the gate is a courtesy, and the data behind it is
   public by design. The second is a five-minute change and is honest.
4. **H4, rotate the two passwords.** One `update` statement each. History cannot
   be unwritten; the credentials can be.
5. **M1, the cart.** Call `renderSummary()` from the drawer's mutation handler,
   which pulls `liveEnsureCheckout` in behind it for free.
6. **M6, commit migration 013.**

Everything at M2 and below can wait, with one caveat: M2 will exhaust the
500-per-day ceiling on a busy demonstration day, and the day it does, the shop
answers "the demo is resting" to everyone.

---

## 10. Artifacts graded (SHA-256)

```
c662eb2849aef22f3a413d3df3034908bf50b86c123295a57de5c2d7078c096e  functions/_shared/edge.ts
9235559dfd0322b66dd0f5d93c8f592871ee23366b30405053ac58fba468d5ab  functions/_shared/pricing.ts
81266e9c4fc4cbef9ed00d3926a76aef7487dd41ad3346dbbd3e4228fa235624  functions/create-payment/index.ts
e6bcdbe95dc24c4c80285fa5749a6c64200829728a20f14ffdbf6fd0b7e37f8f  functions/confirm-payment/index.ts
fa0d11af0fb1c550b69df679ace0bfd99df4e3ff7c1bc8ff64618501f86507fc  functions/payment-webhook/index.ts
7d7407501d71a348878212d81fd7cce63cd1622a87b61cefd096355f652efa83  functions/demo-login/index.ts
f098befef92626d8c321fa4109208cdc2f5a1830f322b871f4e923e3a9b34129  functions/list-demo-orders/index.ts
49e6e02bbb39b1e870d492e5d46bd75205aa796c282d4b8255496f7cbdef539b  www/shop.html
8b1576c11b5a3300c0d105fa5844226215f62fd38eee805420c0b614a530d970  www/staff.html
8cc7d728c8d29037cafd5d622f900be5ae61313d3546a9662d3f40fafabbad6e  www/login.html
46dc87e21c2897a77f277b64a289af197e56f7955607e6a1bb85e29987a17135  www/js/catalog.js
24e88528009f20e5067ab2fa4b80a15468e2c00436b12c4f1a842d641aa70168  site/index.html
63d380699b7a13437e84532a2abba4ef77fde12a9d8c37312a35079bbca49ad1  db/migrations/012_demo_auth.sql
cb1eeba4bdfcf2594fd8c63f535f624e5b31f5fbe026e24ed727ee20800f92b6  db/migrations/014_member_sign_in_accounts.sql
```

Live database queried: Supabase project `oiyibdczkokegaxkwulv`, read-only, on
2026-08-15.

Report only. Nothing in the product was changed.
