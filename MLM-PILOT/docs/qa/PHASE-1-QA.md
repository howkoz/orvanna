# Phase 1-2 Quality Assurance Gate: schema migrations + deterministic seed

Grader: mlm-qa (Verifier team, completeness gate). Date: 2026-08-13.
Graded independently of mlm-verifier; the phase closes only when BOTH gates say PASS.

Acronym key: Quality Assurance (QA), Multi-Level Marketing (MLM), Row-Level Security
(RLS), Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV), Personal
Volume (PV), Primary Key (PK), Foreign Key (FK), Common Table Expression (CTE),
Comma-Separated Values (CSV), Structured Query Language (SQL), Coordinated Universal
Time (UTC), Secure Hash Algorithm 256 (SHA-256).

## Method

The acceptance checklist below was written from the promise sources BEFORE any
deliverable was opened (checklist archived at
`C:\Users\howar\AppData\Local\Temp\claude\mlm-qa-phase1\CHECKLIST-PREBUILD.md`).
Promise sources: `ROADMAP.md` (v1 scope items 1 and 2, product concept),
`docs\SCHEMA-SPEC.md`, `docs\COMP-PLAN-SPEC.md` v1.1,
`docs\decisions\2026-08-13-genealogy-representation.md` (consequences section).

Everything runnable was run: the seed generator executed twice in an isolated
scratch copy (determinism proof), the proof builder executed (exit code checked),
and the committed DuckDB file interrogated read-only with independent queries.
No product file was modified. Migrations (Postgres SQL) received a strict static
pass, since Postgres is not runnable locally in this gate.

**Scope note, recorded up front:** cloud deploy (applying the migrations to the
Supabase project) is NOT in scope for this gate and no row fails for its absence.
Local proof was required and was present.

## Acceptance checklist

Evidence abbreviations: "static" = read and verified in the file; "run" = executed
and output captured; "query" = SQL executed against the committed
`db\seed\output\seed_proof.duckdb` (read-only).

### A. Migrations (static pass, db\migrations\001..005)

| # | Item | Evidence | Result |
|---|---|---|---|
| A1 | Files 001..005 exist, each with purpose and date header | static: all five present, headers state purpose, date 2026-08-13, project | PASS |
| A2 | Schema `app` created; all tables in `app`, never `public` | static 001: `create schema if not exists app`; all nine tables `app.*`. Views live in `public` by documented design (005 header: Supabase data API serves them without exposing schema app); spec names no schema for views | PASS |
| A3 | app.members exact columns, checks, unique(member_code), index(sponsor_id) | static 001 lines 16-28: all columns, types, checks, unique constraint, sponsor index match SCHEMA-SPEC section 1 | PASS |
| A4 | Cycle-check trigger on members, located in migration 001 per decision doc consequences | static: trigger `members_sponsor_cycle_check` EXISTS and is correct (walks up, self-sponsor check, step cap, fires before insert and update of sponsor_id) but lives in migration 002, not 001 as the decision document's consequences section states | FAIL (defect M1) |
| A5 | app.products columns per spec, commissionable_value nullable | static 001 lines 37-46: match; sku unique; tier check | PASS |
| A6 | app.subscriptions columns, quantity default 1 check > 0, index(member_id) | static 001 lines 55-64: match | PASS |
| A7 | app.orders columns, buyer_role and status checks, both promised indexes | static 001 lines 72-83: match; indexes (member_id, volume_month) and (volume_month) both present | PASS |
| A8 | app.order_lines columns and checks | static 001 lines 90-99: match; one extra benign index on (order_id) | PASS |
| A9 | app.ranks table plus the five rank rows seeded | static 001 lines 106-111 (table) and 004 (five rows member..executive, paid depths 1..5, `on conflict do nothing`) | PASS |
| A10 | app.commission_runs columns; only one 'final' run per period (unique partial index) | static 001 lines 118-134: match; `commission_runs_one_final_per_period_idx ... where status = 'final'` present | PASS |
| A11 | app.run_member_results PK (run_id, member_id), all columns, cumulative_sv reserved nullable | static 001 lines 140-152: match | PASS |
| A12 | app.commission_lines columns, level check 1..5, rate numeric(5,4), payout_type default, index (run_id, earner_id) | static 001 lines 159-172: match | PASS |
| A13 | Immutability trigger rejects UPDATE and DELETE on commission_lines AND run_member_results when run is 'final' | static 002 lines 66-97: one shared function reading status through OLD.run_id (re-pointing cannot dodge the guard), triggers on both tables | PASS |
| A14 | RLS enabled on every app table; no anon or authenticated policies | static 003: all nine `enable row level security`; policies exist ONLY for app_demo_reader; belt-and-suspenders revoke block for anon and authenticated. Documented deviation in the 003 header (definer role needs per-table RLS SELECT policies because plain GRANT is insufficient under RLS and Supabase forbids BYPASSRLS roles); intent preserved exactly | PASS |
| A15 | Five v_demo_* views, definer pattern (security_invoker = false), owned by dedicated read-only role, anon reads views only | static 005: all five views `with (security_invoker = false)`, `alter view ... owner to app_demo_reader`, guarded grants. Note: SELECT is also granted to authenticated, which the spec does not mention; surface is identical to anon so recorded as observation only | PASS |
| A16 | Every run-derived view filters to status 'final' | static 005: v_demo_members (latest final run CTE), v_demo_member_months, v_demo_statements, v_demo_company all filter final; v_demo_tree exposes edges only, no run data | PASS |
| A17 | View columns all inside SCHEMA-SPEC section 3 allowed lists; no email, no internal member ids | static 005 column-by-column against section 3: all exposed columns allowed; member_code and display_name are the only member identifiers anywhere. v_demo_company additionally exposes run_id, which is absent from the section 3 table but explicitly sanctioned by section 3's closing sentence (the site footer reads period plus run id from this view); 005 documents this inline. A run id is not a member identifier | PASS |
| A18 | Cross-file ordering correct 001 -> 005 | static: tables (001) before triggers (002), before RLS and role (003), before rank rows (004), before views and ownership transfer (005); the `grant app_demo_reader to current_user` in 003 enables 005's `alter view ... owner` | PASS |
| A19 | Idempotence claims honest | static: no migration claims re-runnability; 004 is genuinely idempotent (`on conflict do nothing`), 001 guards only the schema. The generator's determinism claim and the manifest's byte-for-byte claim were PROVEN by run (B2) | PASS |
| A20 | Headers with purpose and date on every migration | static: present on all five | PASS |

### B. Seed (v1 scope item 2)

| # | Item | Evidence | Result |
|---|---|---|---|
| B1 | Seed generator runs with `py`, exits 0 | run (scratch copy): exit 0; reports 1,000 members, 1,977 subscriptions, 8,222 orders | PASS |
| B2 | Deterministic: reruns byte-identical | run twice in isolated scratch dirs: `diff -r` of the two output trees = IDENTICAL. All 15 regenerated files also byte-identical to the committed files in `db\seed\output\` (cmp per file). All 14 SHA-256 hashes in `_manifest.txt` re-verified against the committed files: all match | PASS |
| B3 | 1,000 synthetic members, member_code format, emails @example.com | query: count = 1000; zero member_code failing `GW-nnnnnn`; zero emails outside @example.com | PASS |
| B4 | Realistic tree: few large leaders, long tail, sane depth, no cycles, sponsor precedes child | query + run: exactly one root; 0 members unreachable from root (no cycles, no orphans); top frontlines 74, 64, 38, 32, 31 then dropping to 8 and below (long tail); depth histogram spans 12 levels with 10 levels holding 10+ members; 0 children enrolled before their sponsor; enrollment spread across 24 months (2024-08 .. 2026-07) | PASS |
| B5 | About 6 months of order history, volumes differ month to month | query: exactly 6 order months (2026-02 .. 2026-07); monthly volume grows 96,350 -> 141,750; 252 members have month-over-month SV changes; churn 22.3 percent of subscriptions; 75 accounts closed. Rank movement itself is only computable in Phase 3; the varying-volume ingredient it needs is demonstrably present | PASS |
| B6 | Catalog matches COMP-PLAN-SPEC section 1 | query: 6 domain agents at exactly 100.00 / 100 PV (Payment, Shipping, Pricing, Inventory, Marketing, Tax) and 6 support agents at exactly 50.00 / 50 PV (Software Engineer, Quality Assurance, Secretary, Chief Executive, Accounting, Customer Care) | PASS |
| B7 | Orders exactly mirror active subscriptions per month, first-of-month, completed, member role | query: symmetric difference between (expected orders from subscription windows) and (actual orders plus lines) = 0 rows across all 6 months; 0 non-completed, 0 non-member buyer_role, 0 volume_month not the first of a month | PASS |
| B8 | Order lines copy unit_price and unit_volume from the product | query: 0 lines deviate from catalog price or volume points | PASS |
| B9 | Loader SQL files correct (tables, columns) | static parse of `load_seed.sql` and `load_worked_example.sql`: inserts target exactly the five app tables with column lists matching migration 001 exactly; `overriding system value` for identity columns; sequence realignment via setval for all five tables; single begin/commit transaction; row counts in the SQL match the CSVs (1000 / 12 / 1977 / 8222 / 8222) | PASS |
| B10 | Proof builder runs and produces seed_proof.duckdb | run (scratch): exit 0, "RESULT: ALL CHECKS PASSED", 21 internal checks all PASS, database file produced | PASS |
| B11 | Committed seed_proof.duckdb queryable and current | query: all 11 tables present; row counts match the committed CSVs; members content hash (member_code plus email over all 1,000 rows) identical between the DuckDB tables and the CSVs, so the committed database is not stale | PASS |

### C. Worked example (the contract for engine and verifier)

| # | Item | Evidence | Result |
|---|---|---|---|
| C1 | Expected files exist as deliverables | static: `worked_example_expected_commission_lines.csv`, `worked_example_expected_member_results.csv`, `worked_example_expected_company.csv` plus the four input CSVs and `load_worked_example.sql` all present in `db\seed\output\` | PASS |
| C2 | At least 6 commission lines match COMP-PLAN-SPEC section 7.3 exactly | by eye: ALL 15 lines compared field-by-field against the 7.3 table; identical values and identical order (spot-list: M1/M2 L1 120.00 at 0.1000 = 12.00; M1/M7 L2 1200.00 at 0.0500 = 60.00; M1/M9 L3 240.00 = 12.00; M2/M6 L1 120.00 = 12.00; M3/M7 L1 1200.00 = 120.00; M3/M10 L2 40.00 = 2.00; M8/M10 L1 40.00 = 4.00). The proof builder additionally re-verifies every amount = round(cv times rate, 2) with delta 0.00 | PASS |
| C3 | All 4 statement totals plus company row match section 7.4 | by eye: M1 114.00, M2 16.00, M3 130.00, M8 4.00 in expected_member_results; company row 2026-07-01, SV 2,700.00, CV 2,160.00, payout 264.00, members paid 4. Proof builder cross-foots per-earner sums against totals: 0 mismatches | PASS |

### D. Hygiene

| # | Item | Evidence | Result |
|---|---|---|---|
| D1 | ROADMAP status current | static: phase table still shows Phase 1 status "next" and Phase 2 blank, and "Next small step" still says mlm-architect is producing the schema spec. In reality the spec, migrations 001..005, the full seed pack, and the proof exist and await the two gates | FAIL (defect M2) |
| D2 | README accurate about what exists | static 00-README.md: agent table, guardrails, and `db\` description accurate. Three stale claims: stack table says Supabase free tier while ROADMAP records Howard's deliberate Pro plan choice; "fake wellness company" copy predates the locked AI-agent product concept; "site\ (created in Phase 3)" while ROADMAP puts the portal in Phase 4 | FAIL (defect M3) |
| D3 | No em or en dashes in any new file under db\ | Python scanner over all 30 text files (.md .sql .py .csv .txt) in MLM-PILOT, checking for U+2014 and U+2013 per line: zero occurrences anywhere, including this report | PASS |
| D4 | Acronyms expanded on first use in prose documents | static: SCHEMA-SPEC, COMP-PLAN-SPEC, decision doc, ROADMAP all carry acronym keys or inline expansions (UTC expanded inline in both specs). A few CODE comments use bare acronyms (see defect L2), but every standalone prose document complies | PASS (L2 noted) |
| D5 | Zero Unicity terminology | grep case-insensitive for Unicity and related internal terms across MLM-PILOT: the ONLY hits are the guardrail clauses in 00-README.md that prohibit Unicity terminology. Zero occurrences in any Phase 1-2 deliverable (migrations, seed code, generated data, specs) | PASS |
| D6 | No real personal data | query: 30-member random sample (deterministic sample seed 13) inspected by eye: all names drawn from the synthetic nature-style pools (Yael Underhill, Zion Palewater, Gray Lightfoot, ...), all 30 emails synthetic @example.com; plus full-population checks: 0 of 1,000 emails outside @example.com | PASS |
| D7 | No secrets or keys in any committed file | grep for token, key, password, connection-string, and Supabase-key patterns across MLM-PILOT: zero matches | PASS |

### E. Scope exclusions

| # | Item | Evidence | Result |
|---|---|---|---|
| E1 | Cloud deploy to Supabase | Explicitly out of scope for this gate per the gate brief; migrations run against Supabase later. Not graded | NOT APPLICABLE |
| E2 | Comp engine run-scoped level map | Phase 3 deliverable; the schema and decision doc support it, which is all this phase promises | NOT APPLICABLE |

Row counts: 43 rows total. PASS 38, FAIL 3 (A4, D1, D2), NOT APPLICABLE 2.

## Defects

### HIGH (broken or missing deliverable): none

No missing artifact, no broken behavior, no privacy or security exposure found.

### MEDIUM (works but off-spec or fragile)

- **M1 (row A4). Cycle-check trigger placement deviates from the decision document.**
  `docs\decisions\2026-08-13-genealogy-representation.md` consequences section says
  "Migration 001 creates members with sponsor_id, its index, and the cycle-check
  trigger." The trigger is correct but lives in
  `db\migrations\002_integrity_triggers.sql`. Adjacent wording in SCHEMA-SPEC
  ("RLS ON from the first migration") similarly lands in file 003; that phrasing is
  ambiguous ("first migration" can mean the initial migration set), so it is noted
  here rather than counted separately. No functional gap: 001 through 005 apply as
  one wave before any data loads. Fix is one line in the decision document (or
  moving the trigger); either way the deviation should be recorded, not silent.
- **M2 (row D1). ROADMAP.md status is stale.** Phase 1 still reads "next", Phase 2
  has no status, and "Next small step" describes work that is already finished
  (spec, migrations, seed, proof all exist). Update the phase table and next-step
  section to "built, awaiting mlm-verifier and mlm-qa gates" so the momentum
  protocol keeps working.
- **M3 (row D2). 00-README.md has drifted from decided reality.** Free-tier claim
  versus the recorded Pro plan choice; "fake wellness company" versus the locked
  AI-agent marketplace product concept; site listed as Phase 3 versus ROADMAP's
  Phase 4.

### LOW (cosmetic)

- **L1.** `db\migrations\003_row_level_security.sql` line 12 says "see engineer
  report" but no engineer report file exists anywhere in the repository. The
  deviation itself is fully documented inline, so only the pointer dangles.
- **L2.** Bare acronyms in a few code comments: 001 uses CV, SV, and UTC
  unexpanded; `generate_seed.py`'s docstring uses SV and CV unexpanded; the
  generated `load_seed.sql` header uses RLS unexpanded. All standalone prose
  documents carry acronym keys.

## Verdict

**PASS.**

No HIGH defect stands. Every promised artifact exists at its stated path, the seed
generator is provably deterministic (two isolated runs byte-identical, committed
outputs byte-identical to regeneration, every manifest hash re-verified), the proof
builder passes all 21 of its own checks with exit 0, the committed DuckDB database
is current against the CSVs, the loader SQL targets exactly the migrated tables and
columns, the worked-example pack reproduces COMP-PLAN-SPEC v1.1 section 7 to the
cent, the five demo views expose nothing beyond the allowed lists, and the hygiene
sweep found no dashes, no Unicity terminology, no real personal data, and no
secrets. The three MEDIUM defects are documentation-currency and placement issues
that should be fixed before Phase 3 starts but do not block this gate.

Reminder: this is one of two signatures. The phase closes only when mlm-verifier's
independent correctness gate also reports PASS.
