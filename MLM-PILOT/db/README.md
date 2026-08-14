# Database migrations index

MLM (Multi-Level Marketing) Pilot, Globex persona, personal project. Migrations
live in `migrations\` as numbered SQL (Structured Query Language) files and are
applied in order. The commission engine source lives in `comp\` (see the 008
pointer). Run order for a fresh environment: 001 through 007, then
`comp\001_comp_engine.sql`, then data loaders, then runs, then 010.

| # | File | What it does |
|---|---|---|
| 001 | `migrations\001_app_schema_core_tables.sql` | Schema `app` plus the nine core tables (members, products, subscriptions, orders, order_lines, ranks, commission_runs, run_member_results, commission_lines) with constraints and indexes. |
| 002 | `migrations\002_integrity_triggers.sql` | Sponsor cycle-check trigger on `app.members`; immutability trigger rejecting UPDATE and DELETE on finalized run rows. |
| 003 | `migrations\003_row_level_security.sql` | Row-Level Security (RLS) ON everywhere, zero anon or authenticated policies, `app_demo_reader` definer role with per-table SELECT policies, belt-and-suspenders REVOKEs. |
| 004 | `migrations\004_ranks_seed.sql` | Seeds the five ranks (member, builder, leader, director, executive). |
| 005 | `migrations\005_demo_views.sql` | The five original `v_demo_*` definer views in schema `public`; SELECT granted to anon and authenticated on views only. |
| 006 | `migrations\006_immutability_hardening.sql` | Finalized-run INSERT lock; treats `final` and `superseded` runs as equally frozen. |
| 007 | `migrations\007_customers.sql` | `app.customers`, the order attribution rule, RLS in the house pattern, plus `v_demo_customers` and `v_demo_customer_volume` (bringing the anon view surface to seven). |
| 008 | `migrations\008_comp_engine_POINTER.md` | Pointer only: the live ledger entry was applied from `comp\001_comp_engine.sql`, the canonical engine source. |
| 010 | `migrations\010_demo_orders.sql` | Phase 6: `app.demo_orders` and `app.demo_rate_events`, RLS ON with ZERO policies (service role only), status transition guard, updated-at trigger. Adds no view and no grant; the anon surface stays exactly the seven `v_demo_*` views. Spec: `docs\PHASE-6-SPEC.md` section 2. |

Migration 009 is not present in this repository as of 2026-08-14. The Phase 6
spec names its migration 010 explicitly, so 010 is used here and 009 stays
unassigned until its owner claims it.
