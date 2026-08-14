# Phase 5 Verdict: Public Launch Security and Exposure Audit

Grader: mlm-verifier. Date: 2026-08-14. The builder never grades its own work;
this grader built none of the shipped site and probed the live public surface
independently and adversarially. This half covers SECURITY AND EXPOSURE only.
mlm-qa already ran the completeness pass (24 of 24 PASS, docs\qa\PHASE-5-QA.md);
its availability and link checks are not repeated here.

Acronym key: Multi-Level Marketing (MLM), Row-Level Security (RLS), JavaScript
Object Notation (JSON), JSON Web Token (JWT), Application Programming Interface
(API), Representational State Transfer (REST), Remote Procedure Call (RPC),
Hypertext Transfer Protocol (HTTP), Structured Query Language (SQL), Secure Hash
Algorithm 256 (SHA-256), Sales Volume (SV), Personal Volume (PV),
Transport Layer Security (TLS).

## VERDICT: PASS

Zero HIGH findings. The public repository leaks no secret, no personal data
beyond the site owner's own GitHub commit identity, and no employer term. The
published anonymous key was proven live to be read-only and confined to the
seven demonstration views: the entire `app` schema of base tables is not exposed
to the data API at all, every base-table probe fails, and every write and every
RPC is denied. One MEDIUM finding (an internal authoring note naming the owner
leaked into a public code comment) and two LOW items are recorded below.

## What was proven LIVE versus verified from source

PROVEN LIVE (curl against https://oiyibdczkokegaxkwulv.supabase.co with the
shipped anonymous key, responses quoted verbatim under Findings and Evidence):
- Every base table returns HTTP 404 "Could not find the table" (the `app` schema
  is not exposed; only `public` and `graphql_public` are).
- An explicit schema-switch to `app` is refused (HTTP 406 PGRST106).
- All seven `v_demo_*` views return data (HTTP 200), by design.
- INSERT, UPDATE, DELETE on the base tables and on a demo view are all denied.
- Both commission RPCs (`fn_run_commission`, `fn_finalize_run`) return HTTP 404
  (not exposed to the API).
- The `email` column cannot be selected from any demo view (HTTP 400, column
  does not exist).
- The auth signup endpoint is OPEN (`disable_signup: false`, email provider on).
- The GraphQL endpoint has `pg_graphql` disabled, so no GraphQL surface exists.

VERIFIED FROM SOURCE (migrations 003, 005, 007 read line by line; the Supabase
management advisors could not be reached from this non-interactive session, so
RLS and grant posture were confirmed from the migration SQL, then cross-checked
against the live behavior above, which is consistent with the source):
- RLS is enabled on all ten `app.*` tables; no anon or authenticated policy
  exists on any of them; the only SELECT policies are for the `app_demo_reader`
  definer role.
- An authenticated user would gain NOTHING wider than anon: migrations 003 and
  007 revoke all table privileges and schema usage from `authenticated`, and
  migrations 005 and 007 grant `authenticated` SELECT on exactly the same seven
  views granted to anon. Open signup therefore has no blast radius here.

## Findings

### HIGH

None.

### MEDIUM

1. Internal authoring note naming the site owner leaked into a public,
   tracked file. `js/catalog.js` line 7 reads, inside a shipped code comment:
   "Billing modes, per Howard's rule:". The property is meant to stand fully
   generic and personal (the persona in the private migrations is "Globex");
   an author's real first name embedded in the public build output breaks that
   fence. It is only a first name, no surname, no employer, and no secret, so
   the severity is MEDIUM, not HIGH: it does not expose credentials or the
   employer, but it is real personal data on an open-internet property and it
   is a one-line fix (reword the comment to "Billing modes:" or "per the
   catalog rule"). This is the only occurrence of the name in all 22 files
   (grep for "howard" is case-insensitive and returned this line alone).

### LOW

1. The Git commit author identity is the owner's personal address:
   `HowKoz <hkoziara@gmail.com>` on the single commit ea4589f. This is normal
   and unavoidable for a commit pushed under a personal GitHub account, and it
   is the owner's own choice of account, so it is not a defect to fix. It is
   recorded only so the owner is aware that the personal email is publicly
   readable in the repository history, consistent with the site being an
   openly personal project rather than an anonymous one.

2. The shipped anonymous key is a long-lived legacy JWT: its payload decodes to
   `role: anon`, issued at 1786633501, expiring 2102209501 (year 2036). This is
   the intended public key and its power was proven minimal above, so this is
   not a vulnerability. It is noted only because the far-future expiry means key
   rotation, if ever wanted, is a manual act; there is no automatic cutoff.

## 1. Public repository leak audit

Cloned https://github.com/howkoz/orvanna.io to a scratch directory and read all
22 tracked files plus the full history.

- History is a single commit (ea4589f, "Orvanna site: corporate root + member
  portal, Phase 5 initial deploy"), one branch (`main`), no other refs.
  `git log --all --stat` shows 22 files added, 8362 insertions, and no file ever
  deleted, so there is no deleted-then-removed sensitive file hiding in history.
- Credential sweep: the ONLY `eyJ`-prefixed strings are the intended anonymous
  key, appearing exactly twice, in `portal/js/app.js` line 11 and `staff.html`
  line 225. No service-role key, no `sk_`/`pk_` secret, no password value, no
  bearer token other than the anon key passed to its own API. The word "secret"
  appears only in product marketing prose ("Secret" as a common noun) and
  "password" only as input field types on the two demonstration login forms,
  which store and transmit nothing.
- Employer and personal term sweep across all 22 files for Unicity, UnityDBStage,
  Hydra, Teller, ClickUp, PaymentWF, and the real processor names (WorldPay,
  Nuvei, 2C2P, Braintree, Gr4vy, HyperSwitch): zero hits. The one personal-name
  hit is the MEDIUM finding above.
- No internal filesystem paths, no private-material TODO or FIXME, no `@import`
  or external `url(...)` in either CSS file. The only outbound references in
  markup are `mailto:support@orvanna.io` (an in-fiction address) and the single
  same-origin Supabase host. No third-party script, font, analytics, or tracker.

## 2. Anonymous key blast radius (proven live)

All requests sent with headers `apikey:` and `Authorization: Bearer` set to the
shipped anon key, over TLS to the project host.

2a. Direct SELECT on base tables, every name from SCHEMA-SPEC.md plus
`run_level_map`:

    GET /rest/v1/members?select=*&limit=1
    -> HTTP 404 {"code":"PGRST205", ... "Could not find the table
       'public.members' in the schema cache"}

Identical 404 PGRST205 for orders, customers, commission_runs,
commission_lines, ranks, products, subscriptions, order_lines,
run_member_results, run_level_map. The base tables live in schema `app`, which
is not exposed. An explicit attempt to reach it:

    GET /rest/v1/members  (header: Accept-Profile: app)
    -> HTTP 406 {"code":"PGRST106", ... "Only the following schemas are
       exposed: public, graphql_public" ... "Invalid schema: app"}

Zero rows of table data were returned by any probe.

2b. The seven demonstration views all return data (HTTP 200), as designed:
v_demo_members, v_demo_tree, v_demo_member_months, v_demo_statements,
v_demo_company, v_demo_customers, v_demo_customer_volume. Spot check that no
forbidden column leaks: selecting `email` from v_demo_members returns
HTTP 400 42703 "column v_demo_members.email does not exist".

2c. Write attempts, all denied:

    POST   /rest/v1/members (public)      -> HTTP 404 PGRST205 (no such table)
    POST   /rest/v1/members (Content-Profile: app) -> HTTP 406 PGRST106 (schema not exposed)
    POST   /rest/v1/v_demo_members        -> HTTP 500 55000 "cannot insert into view"
    PATCH  /rest/v1/v_demo_members?...     -> HTTP 500 55000 "cannot update view"
    DELETE /rest/v1/v_demo_members?...     -> HTTP 500 55000 "cannot delete from view"

The views carry a Common Table Expression, so Postgres refuses auto-updates and
no INSTEAD OF trigger exists; there is no writable path to any data.

2d. RPC attempts, all denied:

    POST /rest/v1/rpc/fn_run_commission   -> HTTP 404 PGRST202 (function not found in exposed schema)
    POST /rest/v1/rpc/fn_finalize_run     -> HTTP 404 PGRST202 (function not found in exposed schema)

The engine functions live in schema `app` and are not exposed, so the public key
cannot start or finalize a commission run.

Auth signup state: `GET /auth/v1/settings` reports `disable_signup: false` with
the email provider enabled, so a stranger could register an account. This is
harmless here because an authenticated role gains no wider grants than anon
(section 4). Recommendation, not a blocker: disable email signup in the Supabase
dashboard since the demo has no real accounts, to remove a needless surface.

## 3. Fiction fence

Grepped all 22 shipped files for Unicity, UnityDBStage, Hydra, Teller, and other
employer terminology: zero hits. The site is wholly in-fiction: a demonstration
company "Orvanna" with synthetic leaders (Auren Vale, Liora Sen, Dorian Vesk,
Maren Ostrey), a synthetic catalog of AI agents, and a repeated
"demonstration company, all data synthetic, no real earnings" disclaimer on
every page footer and login form. The single crack in the fence is the owner
first-name comment in catalog.js (MEDIUM finding 1). No em dashes (U+2014) or
en dashes (U+2013) appear anywhere in the 22 files.

## 4. Supabase posture (verified from source, consistent with live behavior)

The management advisors were not reachable from this session, so posture was read
from the migrations and cross-checked against the proven live behavior.

- Migration 003 enables RLS on all nine original `app.*` tables and creates the
  `app_demo_reader` NOLOGIN definer role with a single `SELECT ... USING (true)`
  policy per table. There is NO anon or authenticated policy on any table, and
  the migration additionally REVOKEs all table privileges and schema usage from
  both anon and authenticated as belt and suspenders. A documented deviation is
  present and sound: because Supabase forbids a BYPASSRLS role, the definer role
  reads through an RLS policy rather than raw table ownership; this preserves the
  spec intent (tables invisible to the public API) and is exactly what the live
  404s confirm.
- Migration 007 applies the identical posture to the tenth table,
  `app.customers`.
- Migrations 005 and 007 create the seven `v_demo_*` views as definer views
  (`security_invoker = false`) owned by `app_demo_reader`, in schema `public` so
  the data API can serve them without exposing schema `app`. No view selects
  `email` or any internal id; member_code and customer_code are the only
  identifiers. anon and authenticated are each granted SELECT on exactly these
  seven views and nothing else.
- Net authenticated-versus-anon: identical. Open signup therefore widens no
  access. The demo views are the only readable surface, which matches every live
  probe above.

## 5. History and settings

- Single commit, single branch, no deleted files in history (section 1).
- GitHub Pages is served from `main` branch root: the repo carries `CNAME`
  (`orvanna.io`), `.nojekyll` (bypasses Jekyll so the static files publish as
  written), and a `404.html` at root. mlm-qa confirmed HTTPS is enforced and the
  apex domain resolves; not re-tested here.
- The commit author is the owner's personal identity (LOW finding 1).

## SHA-256 of the graded artifacts

Graded object: public repository https://github.com/howkoz/orvanna.io at commit
`ea4589fa0d219ef4d0bd7da75420e278a62a835f`, Git tree
`08ed3902fc4c3d506aae7aba79ee60d00b01186e`.

Per-file SHA-256 of the 22 tracked files:

| File | SHA-256 |
|---|---|
| .gitignore | c577e06bbe9cb18fa06630e597348a355029e06b98c96111b275ba2ffd1d1baa |
| .nojekyll | e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 |
| 404.html | 87af9c26bddc9aa012ac0c70dbec1e39b28d6f246c883e37e6dedb7944efb8ac |
| CNAME | 0e53e7e4446c387ed372a990237c062a09fb805a7d54651f8e0857a128f0d3ba |
| README.md | b5ac39bc4633f8a8a130f3b1ee06efc0adad8f3f6c1e5d3d8e9594efb14e2c8f |
| assets/favicon.svg | 6ea7c7dc4e6be32ba40e27e1945d86b524c8cb0b2dc0f7fc0e1b9fe85c8103b2 |
| assets/logo-header-dark.svg | b98de728f69fb8508f73badf89f137d9e3155fcba58d82fca7e50c8a46a52f80 |
| css/corporate.css | 8ec2bef4523da6b2324054f64207ead275f25979930b0f7e1ecd8345cf5edcfb |
| css/shop.css | 4a8de3ac2c5a16c6d8c3308d539d8a2b372f5d1a32b7f95d6cda2fcacc5bb83c |
| css/staff.css | 1bff05be1553125c510ba1374dd3e0d46c66f629f1ff1e26163bd21e10e558c5 |
| index.html | 0f6c9c6fdb41a3bd276081b8cf4b7e5f60ffb75eccc7944279c374676217d560 |
| js/catalog.js | 3d0bbe6f49f55047b868b3559d979a18dfbecc9369b0270cb3b1ea38b82ab827 |
| login.html | 2ef94536ec1d10221111c9cfa09880845eb7fa72a458f9bbc07ff7074ad4b38e |
| portal/assets/favicon.svg | 6ea7c7dc4e6be32ba40e27e1945d86b524c8cb0b2dc0f7fc0e1b9fe85c8103b2 |
| portal/assets/logo-final-primary.svg | 84ff457a22507eb360953c9e591fa6ea38c1fe95324cae2488bad68254c3f1ed |
| portal/assets/logo-header-dark.svg | b98de728f69fb8508f73badf89f137d9e3155fcba58d82fca7e50c8a46a52f80 |
| portal/css/portal.css | e68c01100aabadcdbfa1cd245aec83ace4a5d7ccb2109e250e0876ab776d6b8e |
| portal/index.html | 085cc2f522153ea2708c4c9fd73c640586946c814f8cdad552314a7ff6ac7035 |
| portal/js/app.js | cdf53dad8b336bfbe908040e4e2e0e308791bcf30a47a67dbdda8440d0499688 |
| product.html | 56ea61b6782c79ac8ceed711dbd6eaa169ca846c8d05e78b2a4552c4450ac19c |
| shop.html | 56109afcfe396b6780621ae6a9e88be74c59ed2ff974f02526ded8dc731ae0c5 |
| staff.html | b24be49233d0ee3fc743070d348232093fe78e239d8cb6c90df63ce1eba4455a |

## Bottom line

The property is safe on the open internet. Base tables and engine functions are
invisible to the public key, every write is denied, no secret or employer term
ships, and an authenticated stranger gains nothing anon does not already have.
PASS, with one MEDIUM cleanup (strip the "per Howard's rule" comment from
js/catalog.js line 7) and two LOW awareness notes (personal commit email; a
long-lived anon key). Optional hardening: turn off email signup, since the demo
has no real accounts.
