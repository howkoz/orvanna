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
| 1 | Schema spec + migrations + RLS on personal Supabase | mlm-architect then mlm-db-engineer | BUILT + BOTH GATES PASS 2026-08-13 (cloud apply pending) |
| 2 | Seed generator + 1,000 members + 6 months of orders | mlm-db-engineer | BUILT + BOTH GATES PASS 2026-08-13 (subscriptions model) |
| 3 | Comp engine (rollup, ranks, commission run + receipts) | mlm-comp-engineer | BUILT + DEPLOYED 2026-08-13: worked example passed on live Postgres (3x zero mismatches); full seed loaded (24,295 rows); SIX months run and FINALIZED (Feb-Jul 2026, payout 12,014.00 growing to 20,669.20, ~15 percent of CV); gates grading |
| 4 | Portal site (4 member pages + admin) on free hosting | mlm-site-builder | |
| 5 | Domain wired (orvanna.io: DNS + HTTPS), demo polish | mlm-site-builder | |
| V | TWO gates close each phase: correctness (recomputed math, security) and quality assurance (acceptance checklist, everything works end to end) | mlm-verifier + mlm-qa | continuous |

Phase 4.5 (added 2026-08-13, Howard): STAFF VIEW TOGGLE. A header button, no login,
demo-appropriate: OFF = the customer/member facing portal as built; ON = the customer
service facing view, same shell but deeper panels: customer directory (with synthetic
emails), order history with receipts (which customer bought what), subscription states
(start, cancel, churn), per-member service timeline. Ships as new v_cs_* views
(migration 010) readable by the anon key, which is safe ONLY because every byte is
synthetic; in a real deployment the button becomes a staff login. Built after Howard's
input on the Phase 4 portal.

Phase 4B (started 2026-08-13, Howard approved the portal same evening: "perfect for
an office for a member to review their volume"): THE CORPORATE SITE. The public
orvanna.io front a visitor hits to LEARN about the company, tech-forward look
(we sell AI agents), Latin filler for prose, structure per the standard corporate
archetype (hero, overview with proof numbers, pillars, origin, technology,
leadership, footer navigation). Built by orvanna-designer (graphic engineer, hired
this phase) in `www\`. Then Phase 4C: SHOP (the agent catalog as a storefront,
demo checkout). Then Phase 4D: ENROLL (fictional join flow). At Phase 5 the domain
serves www\ at the root with the member office at /portal/.

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
math is untouched by design. Full rules: `docs\COMP-PLAN-SPEC.md` v1.2.

## Comp plan v1 (superseded by docs\COMP-PLAN-SPEC.md v1.1; kept as the original draft)

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
NOW RUNNING: Phase 4, mlm-site-builder builds the portal in `site\` against the
seven public demo views. Then: visual QA + both gates, then Phase 5 (orvanna.io).
