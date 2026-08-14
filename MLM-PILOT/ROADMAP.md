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
