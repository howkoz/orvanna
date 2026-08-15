# Database migrations index

MLM (Multi-Level Marketing) Pilot, Orvanna persona, personal project.
Migrations live in `migrations\` as numbered SQL (Structured Query Language)
files and are applied in order. The commission engine source lives in `comp\`
(see the 008 and 009 pointers).

Last reconciled against the live project `oiyibdczkokegaxkwulv` on 2026-08-15.

---

## The rule this file exists to enforce

**The repository must be able to rebuild the live database.**

That is not a tidiness preference. It is the difference between a database you
own and a database you merely have. If the files here cannot reproduce
production, then production is the only copy of its own definition, and the
first thing anybody does after an accident is discover that.

Two habits follow, and both were broken on 2026-08-15 and repaired the same day:

1. **Never apply a change through the management interface without writing the
   file.** If the change is worth making, it is worth being reproducible. Write
   the file first, then apply it.
2. **Never leave a ledger entry unexplained.** If an entry exists that no file
   accounts for, either write the file or write a pointer saying where the
   source really lives. An unexplained entry is drift that compounds.

On 2026-08-15 four migrations (013, 015, 016, 017) were applied to production
with no file, and two ledger entries (008, 009) were served by one engine file.
The bodies were recovered from `supabase_migrations.schema_migrations` and
written into `migrations\`. That is why several files below carry a "recovered"
banner in their header: it says plainly that the file was reconstructed after
the fact rather than written before the change.

---

## Run order for a fresh environment

1. `migrations\001` through `migrations\007`, in order.
2. `comp\001_comp_engine.sql` (this is what ledger entries 008 and 009 both
   applied; see the two pointer files).
3. The data loaders in `seed\output\`.
4. The commission runs.
5. `migrations\010` through `migrations\017`, in order.

Migration 018 is **proposed and not applied**. It is not part of the run order
until Howard decides.

---

## Every migration, in order

| # | File | Status | What it does |
|---|---|---|---|
| 001 | `migrations\001_app_schema_core_tables.sql` | Applied, file original | Schema `app` plus the nine core tables (members, products, subscriptions, orders, order_lines, ranks, commission_runs, run_member_results, commission_lines) with constraints and indexes. |
| 002 | `migrations\002_integrity_triggers.sql` | Applied, file original | Sponsor cycle-check trigger on `app.members`; immutability trigger rejecting UPDATE and DELETE on finalized run rows. |
| 003 | `migrations\003_row_level_security.sql` | Applied, file original | Row-Level Security (RLS) ON everywhere, zero anon or authenticated policies, `app_demo_reader` definer role with per-table SELECT policies, belt-and-suspenders REVOKEs. |
| 004 | `migrations\004_ranks_seed.sql` | Applied, file original | Seeds the five ranks (member, builder, leader, director, executive). |
| 005 | `migrations\005_demo_views.sql` | Applied, file original | The five original `v_demo_*` definer views in schema `public`; SELECT granted to anon and authenticated on views only. |
| 006 | `migrations\006_immutability_hardening.sql` | Applied, file original | Finalized-run INSERT lock; treats `final` and `superseded` runs as equally frozen. |
| 007 | `migrations\007_customers.sql` | Applied, file original | `app.customers`, the order attribution rule, RLS in the house pattern, plus `v_demo_customers` and `v_demo_customer_volume` (bringing the anon view surface to seven). |
| 008 | `migrations\008_comp_engine_POINTER.md` | Applied, pointer only | Ledger entry `008_comp_engine_v12`. Applied from `comp\001_comp_engine.sql`, the canonical engine source. |
| 009 | `migrations\009_rank_qualification_gate_POINTER.md` | Applied, pointer only, **written 2026-08-15** | Ledger entry `009_rank_qualification_gate_v13`. **009 is real**, not a numbering gap: qualification (Sales Volume of at least 100) became required to HOLD any rank above Member, and the engine stamps `v1.3`. The v1.3 text is already in `comp\001_comp_engine.sql`. The earlier claim in this README that 009 was "unassigned" was wrong and is withdrawn. |
| 010 | `migrations\010_demo_orders.sql` | Applied, file original | Phase 6: `app.demo_orders` and `app.demo_rate_events`, RLS ON with ZERO policies (service role only), status transition guard, updated-at trigger. Adds no view and no grant; the anon surface stays exactly the seven `v_demo_*` views. Spec: `docs\PHASE-6-SPEC.md` section 2. |
| 011 | `migrations\011_view_privilege_hardening.sql` | Applied, file original | Revokes the platform's default ALL grant on the seven views from anon and authenticated, and grants back SELECT alone. |
| 012 | `migrations\012_demo_auth.sql` | Applied, file original | `app.demo_users` (bcrypt hashes) and `app.demo_auth_config` (generated token signing key), both RLS ON with zero policies. Passwords are supplied at apply time and never committed. |
| 013 | `migrations\013_demo_orders_created_at_index.sql` | **Ledger entry applied but was a NO-OP. The file is a deliberate rewrite and has NOT been applied.** File written 2026-08-15 | The applied body asked for a DESCENDING index using `create index if not exists demo_orders_created_at_idx`. Migration 010 had already taken that name with an ASCENDING index, and `if not exists` matches on name only, so Postgres skipped it silently and no descending index was ever built. The live index is ascending. The file now creates `demo_orders_created_at_desc_idx`, a free name, so the intent can actually be delivered. Read its header before applying: it explains the trap and is honest that the practical gain is small, because Postgres can scan a b-tree backwards. |
| 014 | `migrations\014_member_sign_in_accounts.sql` | Applied, file original | Real member sign-in: adds the `member` role and `member_code`, and creates one account per member. The username IS the member code. The member password is deliberately public. |
| 015 | `migrations\015_member_tax_addresses.sql` | Applied, **file recovered verbatim 2026-08-15** | Adds the five `demo_address_*` columns to `app.members`, defaults everyone to a house address so tax can never silently become zero, and sets three teaching accounts to real California, Florida and New York postal codes. City, state and postal code are real; the street is synthetic on every row on purpose. |
| 016 | `migrations\016_order_tax_provenance.sql` | Applied, **file recovered 2026-08-15, one guard added** | Adds `tax_source`, `tax_calculation_id`, `tax_reason`, `tax_jurisdiction`; back-fills existing rows to `flat_mirror_5pct`; adds the `tax_source` check and column comments. The only change from the applied body is an existence check around the `add constraint`, so a rebuild is re-runnable. |
| 017 | `migrations\017_tax_transaction_record.sql` | Applied, **file recovered verbatim 2026-08-15** | Adds `tax_transaction_id` and `tax_transaction_at` plus the partial index the recorder job reads, so a completed sale is booked for reporting and not only quoted. |
| 018 | `migrations\018_PROPOSED_tax_integrity_hardening.sql` | **PROPOSED. NOT APPLIED. NOT IN THE LEDGER.** Drafted 2026-08-15 | Two enforcement gaps: makes `tax_source` NOT NULL with a default so the silent fallback that 016 argues against becomes impossible, and adds a check tying `total_cents` to the sum of its four parts. Pre-flight already run read-only against live data: 115 of 115 rows satisfy the sum, 0 of 115 have a null `tax_source`, so both would validate today. Contains one open judgement call about which default to use; Howard decides. |

---

## Known differences between this repository and production

Recorded rather than hidden, because a known difference is manageable and an
unknown one is not.

| # | Difference | Why it exists |
|---|---|---|
| 1 | A rebuild produces a ledger with one entry where production has two, for the engine. | `comp\001_comp_engine.sql` carries the v1.3 text and is applied once. Production passed through v1.2 (008) and then v1.3 (009). The resulting schema and function bodies are identical; only the ledger row count differs. Keeping a second copy of a 9,000 character engine file purely to reproduce a history row would mean two files to keep in step forever, which is the worse failure mode. |
| 2 | A rebuild creates `demo_orders_created_at_desc_idx`; production does not have it. | Migration 013's file was rewritten to do what its ledger entry claims, rather than to reproduce a no-op. Production is one index short of a rebuild until 013 is applied there. That is Howard's call. |
| 3 | Migration 018 exists in the repository and not in production. | It is marked proposed on purpose. |

---

## Files in `comp\`

| File | What it does |
|---|---|
| `comp\001_comp_engine.sql` | The canonical engine: `app.run_level_map`, `app.fn_run_commission`, `app.fn_finalize_run`. Currently carries compensation plan version v1.3. |
| `comp\002_worked_example_test.sql` | The acceptance test from the compensation plan specification, section 7. |
| `comp\003_reset_app_data.sql` | Clears application data for a clean reload. |
