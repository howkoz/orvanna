# MLM Pilot Roadmap

> As of 2026-08-13. The next small step is always listed LAST so momentum survives
> any gap. Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\ROADMAP.md`

## Council verdict (run 2026-08-13, before any build)

Seven personas vetted the idea. **Verdict: GO, with a v1 scope lock.**

- **Contractor (pragmatist):** biggest risk is scope creep toward a full back office.
  Lock v1 to a READ-focused portal plus one admin dashboard. No real payments, no
  real emails, enrollment flow is v2.
- **Principal engineer:** unilevel rollup in Postgres is a recursive tree query plus a
  materialized monthly rollup; 1,000 accounts is trivial, design the keys so 100,000
  still works. One schema decision matters early: closure table vs recursive query for
  the genealogy (architect decides in Phase 1, documented).
- **First-principles:** the genuinely interesting artifact is a DETERMINISTIC,
  AUDITABLE commission run: versioned batches, per-member statement receipts,
  recomputable by the verifier. That is the piece worth showing off.
- **Marketer:** it must LOOK like a real member portal (tree view, rank badges, volume
  bars) under the Globex Wellness brand; demo value is the point of the domain.
- **Chief financial officer:** $0/month stack confirmed; the only spend already
  happened (the domain). Use a personal Supabase org to keep IP clean.
- **Security:** row-level security from day one, synthetic identities only (fake names,
  example.com emails), public site reads through views that expose no raw tables.
- **The member (customer persona):** what a distributor actually opens the app for:
  my downline, my volume this month, my rank progress bar, my commission statement.
  That IS the v1 feature list.

## v1 scope (locked)

1. Schema: members, sponsor tree, products, orders, monthly volume rollups, ranks,
   commission runs + statement lines. Row-level security policies.
2. Seed: 1,000 synthetic members in a REALISTIC tree (a few large leaders, long tail),
   about 6 months of order history so volumes and ranks differ month to month.
3. Comp engine: monthly run computes personal volume, team volume, rank, and unilevel
   commissions (levels 1 to 5, rank-gated depth), writing an auditable statement.
4. Portal: public demo site on the domain: login-free demo mode v1 (pick a member to
   view as), four pages: My Team (tree), My Volume, My Rank, My Statement, plus one
   Company admin dashboard.
5. Verification: mlm-verifier recomputes one month's run independently and signs it.

## Phases

| Phase | What ships | Owner agents | Status |
|---|---|---|---|
| 0 | Scaffold, guardrails, team, roadmap | (main session) | DONE 2026-08-13 |
| 1 | Schema spec + migrations + RLS on personal Supabase | mlm-architect then mlm-db-engineer | BUILT + BOTH GATES PASS 2026-08-13; cloud-applied same day (migrations 001-009 live) |
| 2 | Seed generator + 1,000 members + 6 months of orders | mlm-db-engineer | BUILT + BOTH GATES PASS 2026-08-13 (subscriptions model) |
| 3 | Comp engine (rollup, ranks, commission run + receipts) | mlm-comp-engineer | CLOSED 2026-08-13, BOTH GATES PASS (verifier matched all six months to the cent); v1.3 rerun finalized same evening |
| 4 | Portal site (4 member pages + admin) on free hosting | mlm-site-builder | BUILT + Howard-approved + QA PASS 2026-08-13 ("perfect for an office") |
| 5 | Domain wired (orvanna.io: DNS + HTTPS), demo polish | (main session, deploy) | SHIPPED 2026-08-14: LIVE at https://orvanna.io. GitHub Pages from public repo github.com/howkoz/orvanna.io (built output only); builder script deploy/build_dist.py assembles www at root + site at /portal/ and rewrites the five cross-folder links; DNS at GoDaddy (4 A records + www CNAME, set by Howard by hand); HTTPS enforced; portal confirmed pulling live Supabase data from the public origin with zero console errors. GitHub access via device-code sign-in (gh CLI, account howkoz). BOTH GATES PASS same day: QA 24/24 (docs/qa/PHASE-5-QA.md) and verifier security PASS with zero HIGH (docs/verification/PHASE-5-VERDICT.md: app schema not exposed to the data Application Programming Interface, all writes denied, engine functions unreachable, no secrets beyond the intended anon key). One MEDIUM (an authoring comment naming Howard in js/catalog.js line 7) queued for cleanup in the team-page round; largely superseded by Howard's same-day ruling putting the real team, himself included, on the site. Enroll is PERMANENTLY "coming soon" per Howard 2026-08-14 ("lets keep enroll permanatly coming soon for now"). orvanna.ai is also owned; it gets a Forward Domain redirect to https://orvanna.io (Howard's browser step, pending). QA live-site gate: docs/qa/PHASE-5-QA.md |
| V | TWO gates close each phase: correctness (recomputed math, security) and quality assurance (acceptance checklist, everything works end to end) | mlm-verifier + mlm-qa | continuous |

Phase 4.5 (respecified by Howard 2026-08-14 after approving the shop round: "looks
amazing great job to the team"; NOW ACTIVE, and Phase 4D Enroll is ON HOLD per the
same ruling): THE STAFF CALL CONSOLE. The mission framing Howard gave the team: the
staff member is ON A PHONE CALL and must support the caller end to end. Spec: staff
enters a MEMBER NUMBER and sees current volume stats and member info (live stats from
the demo views; contact-style info synthetic/made up for now); then a QUICK ORDER
flow: products in a dropdown, quantity, subscription versus one-time, payment capture
suited to a phone order, confirmation number to read aloud. Entry stays Howard's
earlier ruling: a button, not permissions (in a real deployment it becomes a staff
login). Designer researches call-center order-entry and customer-relationship screens
first, then proposes what a call-taker needs on screen. Demonstration philosophy
unchanged: order placement is fake until Phase 6 wires payments.

Phase 4B (started 2026-08-13, Howard approved the portal same evening: "perfect for
an office for a member to review their volume"): THE CORPORATE SITE. The public
orvanna.io front a visitor hits to LEARN about the company, tech-forward look
(we sell AI agents), Latin filler for prose, structure per the standard corporate
archetype (hero, overview with proof numbers, pillars, origin, technology,
leadership, footer navigation). Built by orvanna-designer (graphic engineer, hired
this phase) in `www\`. Then Phase 4C: SHOP (the agent catalog as a storefront,
demo checkout). Then Phase 4D: ENROLL (fictional join flow; ruled PERMANENTLY
"coming soon" by Howard 2026-08-14, no build planned). At Phase 5 the domain
serves www\ at the root with the member office at /portal/ (done, see phase table).

Phase 6 (queued 2026-08-13, Howard; starts AFTER he reviews the Phase 4 site):
HYPERSWITCH AS THE PAYMENT ORCHESTRATOR. The pilot's subscription checkout runs
through HyperSwitch (open-source payment orchestration) in TEST MODE: test cards only,
no real money ever, order rows gain payment status from the orchestrator's responses.
Strategic beat: this fuses the two Orvanna products, the MLM Pilot becomes the first
demo merchant OF the Orvanna platform vision (PLATFORM\ is built around the
HyperSwitch core + neutral vault + pluggable 3-D Secure). Already in hand: a local
HyperSwitch sandbox at C:\hs (Docker, localhost:9000, currently parked), the fourteen
PLATFORM model documents, and connector-adapter notes. Fence note: HyperSwitch is
open source, clean for personal use; employer-side vendor evaluations stay on the
work side.
ARCHITECTURE DECIDED 2026-08-14 (Howard: "i want to do option B"): the HOSTED
route. The live site at orvanna.io takes test payments for ANY visitor, powered by
HyperSwitch's hosted sandbox (app.hyperswitch.io, test mode) rather than a Docker
copy on Howard's machine. Consequences: (a) a small server piece is required
because a static site cannot hold secret keys, plan is Supabase Edge Functions on
the existing mlm-pilot project (they hold the HyperSwitch secret key and the
service-role write path); (b) order rows from real test payments get written by
that server piece, the sealed read-only posture of the public anon key stays
untouched; (c) Howard creates the HyperSwitch sandbox account himself (credentials
never pass through Claude; connect via publishable/secret keys pasted into
Supabase secrets, not into chat); (d) the local C:\hs Docker install stays parked,
work-side. Starts after the team page ships.
SANDBOX ACCOUNT READY 2026-08-14: Howard signed up at app.hyperswitch.io himself.
Publishable key (public by design): pk_snd_bfcb22d171b54957b2cdc9046c56ae16.
The SECRET Application Programming Interface (API) key and the payment response
hash key exist but both touched the chat window, so BOTH get regenerated in the
dashboard at wiring time and the fresh values go straight into the Supabase
secrets vault, typed by Howard, never through chat or any repo. His local copy
lives at C:\Users\howar\Desktop\Desktop\HyperSwitch\APIKEY, confirmed OUTSIDE
every git repository (no push risk); he deletes it himself once the vault holds
the fresh keys. (Update: Howard later moved the key folder INSIDE ORVANNA as
ORVANNA\HyperSwitch\; it is gitignore-fenced and verified never committed.)
PHASE 6 OPENED 2026-08-14 evening (Howard: "team page is stellar!! Open Phase 6").
BUILT AND LIVE THE SAME EVENING: spec (PHASE-6-SPEC.md) -> migration 010 applied
(demo_orders + rate ledger, sealed) -> three Edge Functions deployed and
smoke-tested -> Howard loaded the vault (4 secrets) and created two dummy
connectors (pretendpay_default, stripe_test_default) -> FIRST PAYMENT EVER:
ORV-2026-08-158WRU, $105.00, succeeded via stripe_test, amount verified to the
cent, recorded in demo_orders -> LIVE_PAYMENTS flag shipped to orvanna.io
(commit b9e6936; flag confirmed in the live page). Test cards only, real money
impossible by construction.
PHASE 6 CLOSED 2026-08-14, BOTH GATES PASS, same evening it opened:
- Verifier (docs/verification/PHASE-6-VERDICT.md): zero HIGH; tamper/forge/posture
  all held live; both MEDIUMs FIXED and verified same session (migration 011
  SELECT-only views; scoped per-function rate buckets, functions v2); deferred
  finalized-months bracket closed by the coordinator: checksums byte-identical
  across 5 real succeeded payments.
- QA (docs/qa/PHASE-6-QA.md): PASS 10/10 on the live rail; hand-computed carts to
  the cent; decline/retry/idempotency proven; rails push back politely and scoped
  buckets confirmed.
- Howard's live catch, fixed and deployed same hour: declines now fail GRACEFULLY
  (processor reason shown, cart preserved, retry path); proof order
  ORV-2026-08-16STIL carries "Payment declined: Card declined" end to end.
Backlog banked from the gates (polish round, not blocking): QA M1 inert demo card
fields visible pre-mount in live mode (W4 designer); demo framing thin pre-mount
(W5 writer); LOWs: rate-limiter read-then-increment race, abandoned-terminal
asymmetry (spec-accepted), list accepts POST, list JSON raw dollars number.
First-day scoreboard on the processor: 8+ payments, 5+ succeeded, 1 failed by
design, $105.00 to $1,425.00 range, all via stripe_test (pretendpay idle).

Phase 6.2 (queued 2026-08-14, Howard: "we should apply the taxjar engine to the
site"): REAL TAX ENGINE via HyperSwitch's Tax Processor connector (TaxJar).
Architect-first, because it moves tax computation from our create-payment mirror
into the orchestrator: the spec must redefine the amount-verification contract
(today the server rejects any charge that does not equal its own math to the
cent, which would correctly reject a TaxJar-computed total). Prerequisite:
Howard starts a TaxJar 30-day trial for the sandbox token (paid tier after
trial; token goes into the HyperSwitch dashboard, never through chat). Decision
on trial timing waits for the spec.
BLOCKED AT THE DOOR 2026-08-14 night: TaxJar's free-account signup
(app.taxjar.com/api_sign_up) errors repeatedly; Howard held off. Consistent with
the post-Stripe-acquisition wind-down of their partner ecosystem. Sunday
options: (a) retry / email support@taxjar.com asking for sandbox access, (b)
keep the built-in 5 percent engine (gate-passed, live, honest for a demo) and
present the TaxJar connector screen as the "where a real engine plugs in" story,
(c) architect evaluates whether any other tax path exists in HyperSwitch's
connector list. No build time was lost; the deal-breaker surfaced at step one.

THE SUNDAY LIST (Howard, 2026-08-14 night: "putting a list together of things
for Sunday"). Runs after or alongside Phase 7's flow-out, his ordering call:
1. ORDER HISTORY on accounts: members see their orders (seeded history in
   app.orders plus live demo_orders rows, which already carry member_id).
   Architect decision first: a new sealed read path in the style of the demo
   views versus an Edge Function like list-demo-orders. Both gates.
2. AI CHATBOT on the site: DECIDED 2026-08-14 night, Howard chose BOTPRESS
   (hosted, he built the agent in their builder), so no Anthropic key, no
   Edge Function proxy, and no per-message cost on our side; Botpress hosts
   the agent and the conversation. Embed snippet (public by design, safe in
   the repository), goes immediately before the closing body tag:
     <script src="https://cdn.botpress.cloud/webchat/v5.0/inject.js"></script>
     <script src="https://files.bpcontent.cloud/2026/08/14/20/20260814201237-9JS9TWQ7.js" defer></script>
   PLACEMENT, Howard's ruling: a NAV ITEM on three surfaces, not a floating
   bubble: the corporate pages, the member portal (office), and the staff
   console. The default floating action button is suppressed with
   `.bpFab { display: none }` and the nav link calls window.botpress.open()
   (verified against the Botpress documentation; readiness event is
   window.botpress.on('webchat:ready', ...)).
   THEME, Howard 2026-08-14: the widget must render DARK to match the glow
   design system (ink #0F172A, indigo #4F46E5 and #818CF8, cyan #22D3EE as
   the single lit accent). Two levers, in order of preference: set the theme
   in the Botpress builder's webchat configuration (survives our deploys and
   is the vendor-supported path, Howard's click), and if the hosted default
   still lands light, override the widget's own custom properties in our
   stylesheet against the .bpWebchat and .bpFabWrapper classes. Verify the
   rendered colors in the browser, do not assume the setting took.
   Consequences recorded: (a) this is the SECOND sanctioned external script
   after HyperLoader.js, so the verifier is told rather than surprised, and
   the two hosts are named in the spec; (b) nav-triggered means nothing
   auto-opens over the card form, which satisfies the payment-page script
   discipline (Payment Card Industry Data Security Standard, PCI DSS 4.0,
   requirements 6.4.3 and 11.6.1) that Fable flagged; (c) a third party now
   receives visitor chat text, so the demo framing must say so plainly.
3. TAXJAR (Phase 6.2, blocked at signup): retry, email support@taxjar.com, or
   architect finds another tax route; amount-contract respec required either way.
4. 3-D SECURE (3DS): STARTED EARLY 2026-08-14 night. Howard connected
   3DSecure.io as a 3DS provider INSIDE HyperSwitch (connector label
   threedsecureio_default, merchant connector id mca_ug2mkRXAnzlFCBMDzxM5,
   status ACTIVE and ENABLED, acquirer merchant id and acquirer BIN
   registered, webhook endpoint on the HyperSwitch side). Architecture
   consequence: our code still talks ONLY to HyperSwitch, so the payment
   functions need no new vendor integration. The 3DSecure.io API key was
   pasted in chat, so it is burned and should be rotated in the 3DSecure.io
   dashboard; it lives only in HyperSwitch's connector config and in no
   repository. Sandbox challenge card already documented:
   4000 0038 0000 0446 (docs/TEST-CARDS.html).
   GAP IDENTIFIED BEFORE RESEARCH, by inspection of www\shop.html: our live
   flow sets return_url to window.location.href but has NO HANDLER for
   coming BACK from a full-page redirect. A frictionless authentication is
   invisible and works today; a challenge that redirects the shopper away
   would return them to a page that does not know which order it was. That
   return path is the real build. Research report: docs\3DS-RESEARCH.md.
   Staff console has an extra problem worth an honest answer rather than a
   pretend one: a challenge asks the CARDHOLDER to authenticate on their own
   device, which a call taker cannot do for them.

Phase 7 (queued 2026-08-14, Howard: "when hyperswitch is done, then you and i
need to do a full inventory everything that was done and flow everything out"):
FULL INVENTORY AND FLOW MAP. Howard and Fable together, not delegated: walk every
artifact the project produced (site pages, portal, staff console, database,
engine, gates, deploy pipeline, brand, library, specs) and FLOW EVERYTHING OUT
visually, Howard-style: diagrams first, an end-to-end map of how every piece
connects, what exists where, and what each phase proved. Deliverable shape to be
decided with Howard at kickoff (candidates: a master flow document in the
LIBRARY, a printable systems map, possibly a page on the site itself).

Phase 4C.2 (Howard's morning feedback round, 2026-08-14, after "Amazing job... works
with no errors"): (1) every product gets a PRODUCT PAGE (filler prose under
business-benefit headings, add to cart on page); (2) SUBSCRIPTION DEFAULT with a
one-time toggle: unchecking subscription flips a domain agent to $1,000.00 at
1,000 PV (Howard's value-anchoring play; support agents follow the same 10x rule at
$500.00 / 500 PV, coordinator's call, adjustable); (3) research how real stores flag
and word subscriptions (terminology + flag placement) before building; (4) VARIANTS:
a parent "Manager Agent" bundling 2-3 support agents as children, plus three digital
packs, even-number pricing with PV = price; (5) CHECKOUT: sign in or continue as
guest, synthetic United States billing address on sign-in, and a delivery-method
style choice for digital goods: immediate access $25.00 versus free access within
48 hours; (6) TAX: flat 5 percent displayed, removed when a Tax ID field contains
any digit; (7) PAYMENT METHODS: Apple Pay, Google Pay, PayPal, credit card, all
demonstration-only, drawn as generic marks (no copied logos). NOTE: all of 4C.2 is
shop display-layer; the database and engine learn about one-time purchases, packs,
and tax when checkout becomes real in Phase 6.

v2 parking lot: real auth (magic links), enrollment flow, binary
comp variant, order placement UI, KPI prism dashboard.

## Product concept (LOCKED 2026-08-13)

Digital AI agents sold as monthly Software as a Service (SaaS) subscriptions, fully
fictional under the Globex persona: DOMAIN agents (Payment, Shipping, Pricing, ...)
at $100.00 / 100 Personal Volume (PV); SUPPORT agents (Software Engineer, Quality
Assurance, Secretary, Chief Executive, Accounting, ...) at $50.00 / 50 PV.
Commission-qualified month = 100+ PV of subscriptions (one gate for being paid AND
for counting as an active leg). Because the product is a subscription, recurring
orders (autoship) moved from the v2 parking lot INTO v1. v1.2 (same day, per Howard):
CUSTOMER ACCOUNTS: customers buy through a referring member, their full PV rolls up
to that member's account at purchase time (books as retail_customer orders on the
member with the customer on the receipt), customers never earn or rank; the engine
math is untouched by design. v1.3 (Howard: "Gate it"): qualification required to hold
any rank above Member. Full rules: `docs\COMP-PLAN-SPEC.md` v1.3.

## Comp plan v1 (superseded by docs\COMP-PLAN-SPEC.md, now v1.3; kept as the original draft)

- Unilevel, paid 5 levels deep; depth unlocked by rank.
- Volumes: personal sales volume (SV) per month; team volume (TV) = SV of entire
  downline subtree, same month.
- Ranks (draft): Member (enrolled), Builder (SV 100+, 2 active legs), Leader (TV 2,500+,
  3 active legs), Director (TV 10,000+, 2 legs each with a Builder), Executive
  (TV 40,000+, 2 legs each with a Leader). Active = SV 50+ that month.
- Commissions (draft): level 1: 10 percent, level 2: 5, level 3: 5, level 4: 3,
  level 5: 2, on commissionable volume = 80 percent of sales volume. Paid depth:
  Member 1, Builder 2, Leader 3, Director 4, Executive 5.

## Open items needing Howard

1. ~~The domain name~~ RECEIVED 2026-08-13: **orvanna.io**. Note for Phase 5: Orvanna is
   Howard's flagship personal project, so decide then whether the pilot sits at the apex
   (orvanna.io) or on a subdomain (for example demo.orvanna.io) keeping the apex free
   for Orvanna itself. Either works on free hosting.
2. ~~Create the personal Supabase org~~ DONE 2026-08-13: organization "Orvanna"
   created under Howard's howkoz Supabase login, on the PRO plan (Howard's deliberate
   choice, $25/month base; the first project's $10/month compute is typically absorbed
   by Pro's included credit). Project **mlm-pilot** created by Howard the same day:
   ref oiyibdczkokegaxkwulv, region us-west-2, Postgres 17, ACTIVE_HEALTHY. The
   claude.ai Supabase connector is granted to the Orvanna org (note: single-org grant;
   the work org is out of connector view until switched back). Migrations deploy here
   after the Phase 1 gates pass.
3. ~~Branding decision~~ DECIDED 2026-08-13: the portal brands as **Orvanna**, matching
   the domain. Logo locked same day: Hex Team badge + engineered uppercase wordmark
   (final kit in `..\brand\`: light, dark, header, app icon, favicon). The product
   line inside the demo is the AI agent marketplace.

## Next small step

Phase 3 CLOSED 2026-08-13, both gates PASS (verifier: independent six-month
recomputation matched the cloud to the cent, 0 HIGH; QA: 38 of 42 rows, 0 HIGH).
Comp plan v1.3 same evening (Howard: "Gate it"): qualification required to hold any
rank above Member; engine migration 009 deployed, all six months rerun and
refinalized (Feb 11,906.00 / Mar 13,434.00 / Apr 14,636.00 / May 16,507.20 /
Jun 17,749.20 / Jul 20,669.20), v1.2 runs kept as frozen superseded history.
Phase 4 SHIPPED: the portal is built, Howard-approved, and QA-passed (live-data spot
checks to the cent). Phase 4B SHIPPED same evening: the glow-tech corporate site
(designer round 2: glass panels, living hero constellation, scroll reveals) plus the
fake login page, which an href census proved is the ONLY door from the corporate page
into the member area; full-journey QA PASS 35 of 36 (2026-08-13). Howard approved the
glow redesign same evening ("perfect job"). Phase 4C BUILT overnight 2026-08-13
(orvanna-designer round 3): www\shop.html, the twelve-agent catalog in two tiers with
tier filter, cart DRAWER (research-backed: drawer for browse continuation, threshold
progress bar pattern) with quantity controls, localStorage persistence, nav cart badge,
and the Personal Volume (PV) meter (fills toward the 100 PV qualified month, glows
cyan at qualification); demonstration checkout (any values continue, order number
ORV-YYYY-MM-XXXX, cart clears, forward note re the orchestration layer); index.html
nav Shop and call to action now link to the shop. Night QA PASS 40 of 41; drawer now
opens on add (coordinator's call, designer dissent + middle ground recorded in the
shop.html add handler comments). Howard's morning verdict: "Amazing job to the team...
works with no errors."

ROUND 4 SHIPPED 2026-08-14 (Howard's seven-item feedback; QA PASS 49 of 51, zero
HIGH, four orders placed, one per payment method): 16 purchasable items (12 agents +
Manager Agent bundle $200.00 with three support children + packs Ignition $200.00 /
Momentum $400.00 / Constellation $800.00), catalog.js single source of truth,
product.html template page for every item, subscription-default with the 10x one-time
anchor (domain $1,000.00 / 1,000 PV, support $500.00 / 500 PV), four-step checkout:
account (sign in with anything or guest, synthetic Iowa billing prefill), activation
selector (Standard free / Priority $25.00), 5 percent tax with live Tax ID digit
exemption, four payment methods as self-drawn generic marks. Round-3 carts migrate.

AWAITING: Howard's walk of round 4. His open wording call: the corporate metric tile
still reads "12 AI agents in the catalog" while the shop sells 16 items. LOW touch-up
queued: PV first-use ordering on product.html. Then Phase 4D (Enroll), Phase 4.5
(staff toggle), Phase 5 (orvanna.io: www at root, portal at /portal/, repoint
login.html's redirect per QA's forward flag), Phase 6 (HyperSwitch test payments).

## 3-D Secure (3DS) status, 2026-08-14 night, end of session

BUILT AND DEPLOYED, all of it:
- create-payment requests authentication_type "three_ds" and
  request_external_three_ds_authentication true, with a fixed SYNTHETIC billing
  address (1 Demonstration Way) that satisfies the external provider's
  requirement without collecting anything from anyone. Howard's ruling: fake
  everything, collect nothing real.
- Server-built return address, origin validated, page from a two-item allow
  list, our order number on it. A client-supplied address would be an open
  redirect and is refused.
- confirm-payment maps all 17 HyperSwitch statuses, returns a `reason` and a
  named `authentication` summary. The retrieve, the cent-for-cent amount check
  and the guarded update are ONE shared implementation so the browser path and
  the webhook path cannot drift.
- NEW payment-webhook, deployed without token verification (its own
  HMAC-SHA512 signature is the gate), treats the body only as a wake-up call
  and re-asks HyperSwitch itself. Machine-verified: forged signatures are
  refused with ZERO database queries.
- Checkout survives a full page redirect: resume handler, order-number
  recovery panel, two polling schedules, four distinct outcomes.
- Staff console tells the truth: it never instructs an agent to ask a caller
  for a code, and it names the vishing risk plainly.

WHY NO CHALLENGE FIRES YET, proven by test tonight: both connectors
(pretendpay_default, stripe_test_default) are HyperSwitch DUMMY connectors,
which support payments and refunds only, no 3DS. Every genuine 3DS test card
was refused with "Card not supported. Please use test cards" (DC_04), which is
the simulator saying it knows only its own short list. External authentication
never engaged either: no authentication record came back at all, so the
acquirer-resolution question the research flagged remains untested rather than
answered.

### LATER THE SAME NIGHT: the Stripe path was tried and is a dead end

The advice above (add a real Stripe test account) was FOLLOWED and DID NOT WORK.
Recording it so nobody spends the hour again.

1. Howard created a real Stripe test connector (stripe_default, ACTIVE) and, on
   my suggestion, disabled the dummy connectors. Every card then failed with
   IR_29, "authentication_connector_details is not available in business
   profile", INCLUDING plain 4242, so the live checkout was briefly broken.

2. CAUSE OF IR_29, and it was mine to find, not Howard's to fix: creating the
   3DSecure.io connector and ATTACHING it to a business profile are two separate
   steps in HyperSwitch. The connector was correct all along (acquirer_bin
   400000, acquirer_merchant_id 00002000000, both verified by reading the
   connector back). The profile simply had authentication_connector_details
   null. Fixed by POST to
   /account/{merchant}/business_profile/{profile} with
   {"authentication_connectors":["threedsecureio"],
    "three_ds_requestor_url":"https://orvanna.io/shop.html"}.
   The merchant api-key is sufficient for this; no admin key needed.

3. THE ACTUAL WALL, and it has nothing to do with 3DS. Stripe refuses raw card
   numbers sent to its application programming interface:
     "Sending credit card numbers directly to the Stripe API is generally
      unsafe... To enable testing raw card data APIs, contact support."
   Proven not to be a 3DS issue: a plain 4242 with authentication_type
   "no_three_ds" and external 3DS OFF failed with the SAME message. Unlocking it
   is a Stripe SUPPORT TICKET, not a dashboard toggle (verified against Stripe's
   own support page). So Stripe cannot carry this demo's cards today.

4. RESTORED: fauxpay re-enabled, stripe disabled, both via
   POST /account/{merchant}/connectors/{mca_id} with
   {"connector_type":"payment_processor","disabled":<bool>}. Note the
   connector_type field is REQUIRED or the call fails IR_06.

CONFIRMED CARD BEHAVIOUR on the current rail (each run end to end, not copied
from a vendor page):
  4242 4242 4242 4242   succeeded
  4111 1111 1111 1111   succeeded
  5555 5555 5555 4444   succeeded
  4000 0000 0000 0002   DECLINED, "Payment declined: Card declined"  <- the
                        decline the site can finally demonstrate
  4000 0000 0000 9995   fails, but with an ugly connector error, do not publish
  any real 3DS test card  "Card not supported. Please use test cards"
Shop and staff hints now name the first and fourth of these.

WHERE 3DS ACTUALLY STANDS: our side is DONE and the authentication provider is
now properly attached. The only missing piece is a processor that will accept a
raw test card. That is a vendor-account problem, not a build problem.

TOMORROW, in order of likely speed:
  a. Try a different real test processor that permits raw card data. Checkout.com
     sandbox, Adyen test, and Braintree sandbox are the candidates; confirm the
     raw-card-data policy BEFORE wiring each one, because that is the single
     question that decides it.
  b. In parallel, open the Stripe support request to unlock raw card data APIs
     for the test account, since it costs nothing to have running.
  c. Only after a processor accepts a 3DS card, mirror the acquirer BIN and
     merchant identifier onto THAT connector and retest the external path.

DEPLOYED SINCE: list-demo-orders is now version 3 and carries
sweepAbandonedWithFinalRetrieve. Verified functionally (boots, imports resolve,
ten calls all HTTP 200, correct data), NOT byte-compared. A Supabase personal
access token would make future deploys exact and scripted instead of hand
carried through a tool call; worth doing.

REGRESSION CHECKED after every change: ordinary payments still succeed on the
live site. ORV-2026-08-1RLZFO, 5250 cents, succeeded via pretendpay; checkout
re-verified in the browser after the restore, reaching "Pay $210.00 now, test
mode".

## 3-D SECURE IS WORKING, 2026-08-15

ROOT CAUSE, found in HyperSwitch's source rather than its documentation.
crates/common_enums/src/connector_enums.rs, is_separate_authentication_supported():
only nine connectors return true.

    Stripe, Checkout, Braintree, Adyen, Cybersource, Nuvei, NMI, Zift, Archipel

DummyConnector1 through DummyConnector7 return FALSE, by name. Every processor
on this account was a dummy, so HyperSwitch skipped authentication and charged
the card. The standalone endpoint POST /payments/{id}/3ds/authentication said so
outright: "you cannot authenticate this payment because
payment_attempt.external_three_ds_authentication_attempted is false". No setting,
key, or acquirer value on our side could ever have changed that. Two nights of
configuration work were spent against a hard-coded list.

FIX: Braintree sandbox (free, instant, self-serve) added as the payment
processor, mca_eE4v07QwkYUSyF55vrUC. All four simulators disabled so routing
cannot wander. The real Stripe connector stays disabled: it is on the qualifying
list but refuses raw card numbers without a Stripe support ticket.

VERIFIED ON THE LIVE RAIL 2026-08-15:
  4111 1111 1111 1111  ->  requires_customer_action + next_action
                           redirect_to_url  =  a real bank approval screen
  4000 1111 1111 1115  ->  failed, ProcessorDeclined
  amounts 2000.00-3000.00 also decline, Braintree's amount-triggered rule
  expiry 01/29 on all test cards
Payment pay_adXhgxSYhKH6n61KLiJS was left parked at requires_customer_action,
which is the correct state while a shopper is in front of the challenge.

DEPLOYED: create-payment v4 with REQUEST_EXTERNAL_THREE_DS = false, so the
challenge comes from Braintree's own 3-D Secure. Pricing mirror verified intact
after the hand-carried upload: a two-unit payment-agent cart priced to exactly
21000 cents, matching the hand calculation. Shop and staff card hints updated.

STILL OPEN, and NOT needed for a working challenge:
- The EXTERNAL path (3DSecure.io) still returns HE_00 "Something went wrong",
  now even with Braintree, which IS on the qualifying list, and even after
  acquirer_bin 400000 and acquirer_merchant_id 00002000000 were written into
  the Braintree connector's metadata. So the remaining fault is inside the
  3DSecure.io integration itself, not the connector-support rule. Worth noting
  the sandbox 3DSecure.io key was pasted in chat and is burned; rotating it is
  a sensible first move before debugging further.
- Correction to yesterday's note: acquirer details are read from the PAYMENT
  connector's metadata FIRST (get_payment_external_authentication_flow_during_confirm
  in crates/router/src/core/payments/helpers.rs); the values on the 3DSecure.io
  connector are only a fallback.
- Key rotation and the orvanna.ai forward remain untouched.


## THE 3DS2 CHALLENGE WINDOW, 2026-08-15 (Howard: "build the OTP window")

WHAT IS OURS TO BUILD, AND WHAT IS NOT. The one-time passcode form is served by
the cardholder's own bank (its Access Control Server). A merchant never writes
it, styles it, or sees its code. What a merchant supplies is the WINDOW: an
iframe sized to one of the five sizes the EMV 3-D Secure 2 standard permits.
    01  250x400     02  390x400     03  500x600     04  600x400     05  full screen
The bank formats its content to whichever size was requested.

WHY WE DO NOT DRAW THE INNERMOST FRAME. HyperSwitch's web SDK creates that frame
itself, because the SDK is what confirms the payment and therefore what first
sees status requires_customer_action. Taking that away from the SDK would mean
confirming server-side, which would mean the card entering our own page, which
would put this site inside Payment Card Industry (PCI) scope. Not worth it for a
demo, and not better practice for a real one.

SWITCHED TO THE IN-PAGE FLOW. Profile setting is_iframe_redirection_enabled is
now TRUE, so HyperSwitch returns next_action redirect_inside_popup (with
popup_url and redirect_response_url) instead of redirect_to_url. The shopper now
stays on orvanna.io through the approval instead of the page being navigated
away. This is the native 3DS2 browser flow; the full-page redirect is the older
fallback. Set on the PROFILE, so no Edge Function redeploy was needed. Verified:
a payment with no per-payment flag now returns redirect_inside_popup.

THE CHROME WAS ALREADY BUILT, AND HAD A DEFECT THAT WOULD HAVE HIDDEN IT.
www/shop.html and www/staff.html already carried a challenge dialog (order
number, test-mode notice, cancel that re-asks the server, focus trap, Escape
suppressed, MutationObserver on the SDK element id 'orca-fullscreen', which is
confirmed correct against hyperswitch-web src/Utilities/Utils.res). It had never
run, because no challenge had ever fired.

  DEFECT: the SDK paints its bank frame with inline z-index 422222133323.
  Browsers CLAMP z-index to a signed 32-bit integer, so it resolves to
  2147483647. Our chrome asked for 2147483000 and therefore rendered BEHIND the
  bank frame: order number, test-mode notice and cancel button all invisible at
  the exact moment they matter.

  FIX, both halves required: chrome z-index raised to 2147483647 (matching the
  ceiling, since it cannot be exceeded), AND openChallengeChrome() now moves the
  element to the end of <body> so the document-order tie-break favours us.

  VERIFIED IN THE LIVE PAGE by injecting an element with the SDK's exact id and
  inline style, then probing with document.elementFromPoint:
    shipped (max z-index AND last in DOM)   -> chrome visible
    old z-index 2147483000                  -> chrome COVERED by orca-fullscreen
    max z-index but earlier in DOM          -> chrome COVERED by orca-fullscreen
  The same fix is applied to staff.html and staff.css; only shop.html was
  probed directly, since the staff console sits behind a sign-in.

NOT YET DONE: nobody has completed a challenge end to end in a browser. The card
fields live in a cross-origin iframe that automation may not type into, so the
final click-through is Howard's to confirm.


## CHECKOUT SHAPE AFTER THE 3DS WORK, 2026-08-15

Howard, on seeing the working flow: "it is clunky, i have to enter the credit
card 2 different times", and separately that after the passcode the page "stops
for a second back at the card entry and then finishes at the complete page".
Both were real. Three changes, all verified in the live page.

1. ONE CARD ENTRY. www/shop.html carried its own card inputs, which exist only
   for the FAKE checkout. With live payments on they were a decoy: the shopper
   filled them in, pressed the button, and was handed the payment provider's
   own (empty) card form. They are now hidden whenever LIVE_PAYMENTS is true.

2. NO FLASH BACK TO THE CARD FORM. Between the bank window closing and our
   server answering, the provider's form was still mounted underneath. A
   finishing state now hides the form and the button and leaves only the status
   line. It deliberately says nothing about the outcome, because at that instant
   nobody knows it. Guarded on a payment actually being in flight, and cleared
   on every ending including the timeout path, where leaving it on would have
   hidden the button the timeout message tells the shopper to press.

3. THE CARD FORM IS NOW THE PAYMENT STEP (Howard: "do it"). The payment opens
   automatically when the payment step first becomes reachable, which is the
   account-done stage, not checkout entry: before the guest or sign-in choice
   everything below is hidden and there is nothing to pay for.

   THE HAZARD THIS CREATED. A payment fixes its AMOUNT when created. Opening it
   early means the shopper can then switch to priority activation or enter a tax
   identifier and move the total, leaving a payment that would settle at the OLD
   amount while the page showed the new one. Closed with an amount signature
   (items, activation, tax exemption, member code): every amount-affecting
   control already funnels through renderSummary, which now re-checks, and any
   change discards the opened payment and opens a fresh one. The server reprices
   from scratch each time, so an amount never originates in the browser. The
   open is debounced 900ms because a tax identifier is typed one character at a
   time and the demo allows five creates a minute per visitor.

   PROVEN: cart at $420.00 held order ORV-2026-08-1BX8GO; switching to priority
   activation produced a NEW order ORV-2026-08-1BY49Y at $446.25, with the pay
   button relabelled to match. The stale payment was discarded, not reused.

FLOW IS NOW THREE SCREENS: payment step with the card form already present ->
bank approval window -> order placed.

NOTE FOR TESTING: orvanna.io is served with Cache-Control max-age 600, so a
change can look absent for up to ten minutes in a browser that already has the
page. A cache-busting query string settles whether a fix is missing or merely
cached; this cost an unnecessary round of debugging today.


## A BLANK WINDOW IS NOT A CHALLENGE, 2026-08-15

Howard, testing 4242 4242 4242 4242: "the iframe appears for like 2 seconds
waiting for a challenge and the challenge does not come, then it disappears and
goes to the order placed page. The challenge window should not even show on that
card number." Correct, and it was our bug, not a sandbox limitation. He offered
to accept it as one; it should not have been accepted.

CAUSE: 3-D Secure 2 has two phases and the payment widget runs BOTH inside the
same full-screen frame. Phase one is silent (the issuer inspects the device and
the transaction and usually approves without asking anything). Phase two is the
visible passcode form, and only happens when the issuer wants proof. So the
frame appearing means "authentication is running", not "a challenge is up".
Treating the two as the same thing produced a blank white window on every
frictionless payment, with our chrome bar announcing an approval nobody had
asked for.

FIX: the frame is made invisible the instant it appears, and revealed only if it
is STILL PRESENT 1400ms later, which is the tell that a real challenge rendered
inside it. A frictionless authentication finishes inside that beat and the
shopper sees nothing at all, which is the entire point of frictionless. The
delay is presentation only; it never gates the payment, and the verdict still
comes from our server.

VERIFIED on the live page by driving both timelines:
  frictionless: frame present at +200ms with opacity 0 and no chrome; gone by
                +2000ms; chrome never shown
  challenge:    frame present at +200ms with opacity 0 and no chrome; at
                +2000ms still present, opacity restored, chrome shown

ALSO FIXED, same round: the card form used to reappear for a second between the
approval finishing and the receipt. The finishing state now starts the moment
the card is handed over rather than only after a challenge closes, so the form
is never back on screen while the outcome is being settled.

APPLIED TO BOTH SURFACES per the QA rule that scope follows capability, not the
brief. On the staff console the stakes are higher: that page's script tells an
agent on a live call what the cardholder is being asked to do, so announcing a
challenge that never comes would put words in the agent's mouth.


## KNOWN AND ACCEPTED, 2026-08-15 (Howard: "for now this is acceptable")

Frictionless payments still flash the authentication window briefly. The reveal
delay is 1400ms and the frictionless round trip on this sandbox sometimes runs
longer than that, so the frame is revealed just before it closes. Two ways to
finish it properly when it is worth the time:
  a. raise CHALLENGE_REVEAL_MS, which trades a slower challenge for a cleaner
     frictionless path, or
  b. stop guessing on a timer: poll the payment with the publishable key and
     reveal only when next_action is present and the status is genuinely
     requires_customer_action.
(b) is the correct fix; (a) is one number. Neither is urgent.

Howard also confirmed the payment step now feels fast, which was the point of
opening the payment behind the account step rather than in front of him.

STILL OPEN across the project, none of it blocking:
- No gate has been run over today's checkout work. The auto-open, the amount
  signature, the finishing state, the challenge reveal and the member sign-in
  all shipped verified by their BUILDER only, which is exactly what the
  two-gate rule exists to prevent. One verifier plus one QA pass over the
  checkout as a whole is owed.
- Key rotation: 3DSecure.io, HyperSwitch secret and hash keys, Stripe test key.
- orvanna.ai still needs its forward to orvanna.io.
- The external 3DS path (3DSecure.io) still returns HE_00 and is parked; the
  processor's own 3-D Secure is what runs today.
- Office landing page QA findings M2, M3 and M4 remain Howard's calls.
