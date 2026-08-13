# Phase 3 Quality Assurance Gate: commission engine build + cloud deployment

Grader: mlm-qa (Verifier team, completeness gate). Date: 2026-08-13.
Graded independently of mlm-verifier; the phase closes only when BOTH gates say PASS.
The builder never grades its own work.

Acronym key: Quality Assurance (QA), Multi-Level Marketing (MLM), Row-Level Security
(RLS), Sales Volume (SV), Commissionable Volume (CV), Team Volume (TV), Personal
Volume (PV), Common Table Expression (CTE), Comma-Separated Values (CSV), Structured
Query Language (SQL), Coordinated Universal Time (UTC).

## Method

The acceptance checklist below was written from the promise sources BEFORE any
deliverable was opened (checklist archived at
`C:\Users\howar\AppData\Local\Temp\claude\mlm-qa-phase3\CHECKLIST-PREBUILD.md`).
Promise sources: `ROADMAP.md` (phase 3 row and v1 scope item 3),
`docs\COMP-PLAN-SPEC.md` v1.2 sections 5 and 6 (section 7 as the contract),
`docs\SCHEMA-SPEC.md` (commission_runs / run_member_results / commission_lines,
immutability including superseded), `db\comp\README.md` (the engine's own promises),
the engineer brief promises, and the deployment facts supplied by the main session.

Everything runnable locally was run: the seed proof executed clean via `py`, the
three `db\comp\*.sql` files received a strict static pass (Postgres 17 syntax and
spec-literal logic), the embedded expected values were compared character for
character against the three `worked_example_expected_*.csv` files, at least four
hand-trace numbers were re-derived against spec section 7, and the hygiene sweep ran
over `db\comp\` and the phase documents.

**Scope note, recorded up front:** this gate cannot reach the cloud project. The
deployment rows in section E are graded PASS against the deployment facts given by
the main session (attested evidence), and every one of them that could be
corroborated locally was corroborated (row counts, payout plausibility, migration
files on disk carrying the deploy fixes).

## Acceptance checklist

Evidence abbreviations: "static" = read and verified in the file; "run" = executed
locally and output captured; "attested" = the main session's deployment facts;
"derived" = recomputed by hand for this gate.

### A. v1 scope item 3 (ROADMAP: what phase 3 exists to deliver)

| # | Item | Evidence | Result |
|---|---|---|---|
| A1 | Monthly run computes personal volume | static 001_comp_engine.sql step 2: SV = sum of quantity x unit_volume over completed orders stamped with the period, zero for orderless members; attested live worked example CHECK 1 zero mismatches | PASS |
| A2 | Team volume | static: TV = subtree SV excluding self, from the run-scoped snapshot, ALL levels (full-depth map, documented design decision a); derived: M1 TV 2,500.00 and M2 TV 500.00 reproduce spec 7.1 | PASS |
| A3 | Rank | static: flags evaluate in the spec's declared non-circular order (Builder, Leader, Director, Executive), highest flag wins, paid_depth joined from app.ranks; derived: M1 leader (boundary TV 2,500), M2 member (the unqualified-leg teaching case), M3 builder, M8 member with 0 active legs, all per spec 7.2 | PASS |
| A4 | Unilevel commissions, levels 1 to 5, rank-gated depth | static step 3: rate VALUES table doubles as the level <= 5 filter, `lm.level <= earner.paid_depth` gates depth, earner must be qualified | PASS |
| A5 | Auditable statement written | static: commission_runs row (period, spec_version, status, notes, totals, members_paid), one run_member_results row per member including zeros, per-line commission_lines with source CV, rate, amount, payout_type; statuses running / final / superseded with immutability triggers | PASS |

### B. COMP-PLAN-SPEC v1.2 sections 5 and 6 (commissions, determinism, edge cases)

| # | Item | Evidence | Result |
|---|---|---|---|
| B1 | Rates 10 / 5 / 5 / 3 / 2 percent of source CV by level | static: VALUES (1, 0.1000), (2, 0.0500), (3, 0.0500), (4, 0.0300), (5, 0.0200), numeric(5,4) | PASS |
| B2 | Earner must be qualified to be paid | static: `earner.qualified` filter in the line insert; derived: M5 (SV 50) earns zero rows, its would-be 24.00 on M9 is breakage per spec | PASS |
| B3 | Source qualification irrelevant, all CV pays upline | static: no filter on source qualification; derived: M10 (unqualified, CV 40.00) still pays M8 4.00, M3 2.00, M1 2.00, exactly spec 7.3 | PASS |
| B4 | No compression, plain tree distance | static: level = snapshot distance from the recursive walk, nothing skips unqualified members | PASS |
| B5 | Line rounding half up at line level; totals are sums of rounded lines, never re-rounded | static: amount = round(rate x source_cv, 2) per line; total_earned = sum(amount); run totals = sums over run_member_results; Postgres round-half-away-from-zero = round half up for non-negative values, documented in the file header | PASS |
| B6 | CV = 0.80 x SV rounded half up, once per member-month | static: `round(0.80 * ms.sv, 2)` computed once in the staging table both inserts read, so lines and results cannot diverge | PASS |
| B7 | Roots earn normally, nobody earns on them | static: the walk only creates pairs where a sponsor exists, so the root has no ancestor rows; derived: M1 earns 114.00, no line has M1 as source | PASS |
| B8 | SV aggregates before CV (multiple orders and subscriptions) | static: member_sv aggregates all the month's completed orders first; CV computed on the aggregate | PASS |
| B9 | Month boundary via stamped volume_month | static: orders filtered on `volume_month = period` (normalized to the first of the month); the stamp is set at creation per schema, never recomputed | PASS |
| B10 | Completed orders only | static: `o.status = 'completed'` in member_sv | PASS |
| B11 | Determinism: rerun = new run id, finalized statements never change | static: every fn_run_commission call inserts a NEW run row; both bulk inserts carry ORDER BY for reproducible identity assignment; all math numeric; finalize flips prior finals to superseded, and triggers (migrations 002 + 006) freeze final AND superseded rows | PASS |

### C. SCHEMA-SPEC contracts (runs / results / lines, immutability)

| # | Item | Evidence | Result |
|---|---|---|---|
| C1 | commission_runs contract: period, spec_version, status enum, totals and members_paid at finish, one final per period, rerun = new row + supersede | static: engine writes all fields, leaves status 'running'; fn_finalize_run supersedes prior finals FIRST so the partial unique index never sees two finals, only a 'running' run can finalize, FOR UPDATE taken. Note: the engine writes spec_version 'v1.2' (correct, matches the deployed contract); the schema spec's "'v1.0' for this spec" cell is stale (defect QA-L3) | PASS |
| C2 | run_member_results: one row per member including zeros; is_active = the single 100.00 gate | static step 4: every staging row inserted, total_earned coalesced to 0.00, cumulative_sv null (reserved); is_active = (SV >= 100.00), the corrected v1.1 gate, matching the expected CSV (M5 SV 50 -> false) | PASS |
| C3 | commission_lines shape: level 1..5, source_cv, rate numeric(5,4), amount, payout_type 'unilevel_level_pay' | static: insert column list and values match the schema exactly | PASS |
| C4 | Immutability includes superseded, INSERT included | static migration 006 on disk: reject_write_into_final_run guards INSERT and UPDATE of run_id via NEW.run_id; reject_write_when_run_final (redefined) guards UPDATE and DELETE via OLD.run_id; BOTH treat 'final' and 'superseded' identically, delivering the corrected schema-spec paragraph; attested: applied to live as 006_immutability_hardening | PASS |
| C5 | run_level_map security posture | static: RLS enabled, zero policies, zero grants; created after migration 003's blanket grant so the demo reader role never gained SELECT on it, and no demo view reads it; the public surface cannot see the map | PASS |

### D. Engineer brief promises

| # | Item | Evidence | Result |
|---|---|---|---|
| D1 | fn_run_commission + fn_finalize_run as in-database functions | static: both plpgsql functions in 001_comp_engine.sql, EXECUTE revoked from public | PASS |
| D2 | Spec-literal implementation, deviations documented not silent | static: four deviations called out in file header and README (full-depth map, the 100 gate vs the stale schema note, spec_version literal, zero-CV lines suppressed), each justified; the Director / Executive containment edge case is argued closed in the README and the argument holds (a director-flagged member's own qualifying legs sit inside the same upline leg) | PASS |
| D3 | Run-scoped level map materialized FIRST | static: step 1 is the map insert; every later step (TV, legs, leg membership, lines) joins the snapshot, never the live tree | PASS |
| D4 | Set-based lines, no per-member loops | static: single INSERT ... SELECT joining the map, the staging table twice, and the rate VALUES table; no LOOP anywhere in the file | PASS |
| D5 | Self-contained worked-example test, three zero-row checks | static + derived: 002_worked_example_test.sql embeds all 10 expected member rows, all 15 expected lines, and the company row as VALUES lists, compared character for character against the three worked_example_expected_*.csv files: identical; all three checks are EXCEPT ALL symmetric diffs (duplicates caught), labeled by direction | PASS |
| D6 | Guarded reset script including app.customers | static 003_reset_app_data.sql: DO-block guard on the acknowledgement phrase in app.allow_reset, single TRUNCATE ... RESTART IDENTITY over all ten data tables including app.customers, ranks kept, pre-production warning explains TRUNCATE bypasses the row triggers | PASS |
| D7 | README hand-traces of M1, M2, M5, M8, numbers correct | static + derived, six numbers re-derived against spec section 7: M1 TV 2,500.00 and total 114.00 (nine lines re-summed); M2 total 16.00 and TV 500.00; M5 total 0.00 with 24.00 breakage while its own CV pays M2 4.00 and M1 2.00; M8 total 4.00 from M10's CV 40.00; company cross-foot 2,700.00 / 2,160.00 / 264.00 / 4. All match | PASS |

### E. Deployment (attested by the main session; locally corroborated where possible)

| # | Item | Evidence | Result |
|---|---|---|---|
| E1 | Migrations applied to the live project in order: 001_app_schema_core_tables, 002_integrity_triggers, 003_row_level_security (scoped-grant deploy fix), 004_ranks_seed, 005_demo_views (same fix), 006_immutability_hardening (extended to superseded), 007_customers, 008_comp_engine_v12 | attested; corroborated: all files 001..007 on disk, 003 carries the per-table reader policies and 005 the definer views inline, 006 covers superseded, and db\comp\001_comp_engine.sql is the 008 content writing spec_version 'v1.2' | PASS |
| E2 | Worked-example acceptance on live Postgres: zero mismatches on all three checks | attested; corroborated: the local test script is self-contained and its expected values are verbatim the spec section 7 numbers | PASS |
| E3 | Full seed loaded: 1,000 members, 799 customers, 1,820 subscriptions, 10,332 orders, 1 root | attested; corroborated by run: CSV data rows count exactly 1,000 / 799 / 1,820 / 10,332 (+ 10,332 order lines + 12 products = 24,295 rows, matching the ROADMAP claim); seed proof confirms exactly one root | PASS |
| E4 | Six runs Feb-Jul 2026 executed and finalized: payouts 12,014.00 / 13,549.20 / 14,763.20 / 16,507.20 / 17,749.20 / 20,669.20; members_paid 179 / 206 / 227 / 248 / 261 / 284 | attested; corroborated by derivation: against the seed proof's monthly volumes (104,450 to 172,550) these payouts are 14.4 to 15.0 percent of CV, under the 20.00 percent structural maximum, rising monotonically as the tree matures, matching the ROADMAP's "about 15 percent of CV"; members_paid 179 to 284 against 596 to 841 buying members is plausible for a qualified-and-has-downline gate | PASS |
| E5 | Performance inside the stated budget (well under one second per month at 1,000 members) | static: fully set-based, indexed map, no loops, consistent with the budget; attested: all six runs plus finalization completed inside the same working session. No wall-clock timings were captured (observation O1) | PASS |

### F. Hygiene and docs currency

| # | Item | Evidence | Result |
|---|---|---|---|
| F1 | Seed proof runs clean via py | run: `py db\seed\build_seed_proof.py` exits with RESULT: ALL CHECKS PASSED, including the v1.2 customer attribution checks and the worked-example section | PASS |
| F2 | No em or en dashes in db\comp\ | run: Unicode scan of all four files for U+2013, U+2014, and smart quotes: clean | PASS |
| F3 | Acronyms expanded in prose | static: README carries the full acronym key. But 001_comp_engine.sql uses RLS (three times) and CTE (once), and 003_reset_app_data.sql uses RLS, with no expansion and no key in those files; each file is a deliverable under the house rule | FAIL (defect QA-L2) |
| F4 | Zero Unicity terms | run: case-insensitive sweep of the whole MLM-PILOT tree for Unicity and related internal terms: the only hits are the guardrail clauses in 00-README.md and the prior gate reports describing this same sweep; zero in any phase 3 deliverable | PASS |
| F5 | ROADMAP phase 3 row updated | static: row reads BUILT + DEPLOYED 2026-08-13 with the live results and "gates grading", which is exactly the current state | PASS |
| F6 | ROADMAP overall currency | static: the phase 1 row still says "(cloud apply pending)" and the "Next small step" section still instructs applying migrations plus seed to the cloud and THEN having mlm-comp-engineer build the engine, all of which is done; the file's own banner makes Next small step the momentum anchor, so it currently points a fresh session at completed work | FAIL (defect QA-M2) |
| F7 | Booklet stamped v1.2 | static ORVANNA-COMP-PLAN-BOOKLET.html: "Orvanna Compensation Plan, version 1.2 ... Source of truth for the engine: COMP-PLAN-SPEC.md v1.2, same numbers, same worked example" | PASS |
| F8 | Comp README consistent with what deployed | static: four contradictions with the deployed reality: (1) "Contract: docs\COMP-PLAN-SPEC.md version v1.1" while the engine implements v1.2; (2) step 1 says spec_version 'v1.1' and (3) deviation 3 says "spec_version literal is 'v1.1'" while the engine file on disk and every live run row write 'v1.2'; (4) open question 3 says "Migration 006 does not exist on disk" and the run-order table says "after migrations 001..005" while 006 and 007 exist on disk and the live ledger runs through 008 | FAIL (defect QA-M1) |
| F9 | Version citations inside db\comp\ SQL files current | static: 001's header correctly cites v1.2, but its determinism notes still say "COMP-PLAN-SPEC v1.1 requires" and "spec v1.1 equals identical output"; 002's header cites "COMP-PLAN-SPEC v1.1 section 7". Section 7 is unchanged between v1.1 and v1.2, so zero math impact | FAIL (defect QA-L1) |

Checklist total: 42 rows. 38 PASS, 4 FAIL, 0 NOT APPLICABLE.

## Defects, ranked

### HIGH

None.

### MEDIUM

- **QA-M1 (from F8): db\comp\README.md contradicts the deployed engine.** It cites
  comp plan v1.1 as the contract, states the run rows carry spec_version 'v1.1',
  and asserts migration 006 does not exist, while the engine on disk and every live
  run row carry 'v1.2' and the live migration ledger runs 001 through 008. An
  auditor reconciling live run rows against this README would conclude the wrong
  engine was deployed. Fix: refresh the README's contract line, step 1, deviation 3,
  the run-order table, and open question 3 to the deployed reality (small, pure-docs
  edit).
- **QA-M2 (from F6): ROADMAP.md momentum anchor is stale.** The phase 1 row still
  carries "(cloud apply pending)" and the "Next small step" section still instructs
  applying migrations and seed to the cloud and then starting the phase 3 build,
  all of which shipped. The file's own banner promises the next small step is
  always current so momentum survives any gap; right now it would send a fresh
  session at completed work. Fix: update both after this gate lands.

### LOW

- **QA-L1 (from F9):** stale v1.1 citations inside 001 (determinism notes) and 002
  (header) in db\comp\. Section 7 is identical across v1.1 and v1.2, so no math
  impact.
- **QA-L2 (from F3):** RLS and CTE appear unexpanded in 001_comp_engine.sql and
  003_reset_app_data.sql (no acronym key in those files; the README key does not
  travel with a single SQL file).
- **QA-L3:** SCHEMA-SPEC.md commission_runs.spec_version cell still reads "'v1.0'
  for this spec" while live rows carry 'v1.2'; third document to say a third thing
  about the same literal (see QA-M1).
- **QA-L4:** traceability gap: the live ledger's 008_comp_engine_v12 has no
  counterpart or pointer under db\migrations\ (the content lives in
  db\comp\001_comp_engine.sql). A rebuild from the repo depends on the README run
  order, which QA-M1 shows is currently stale. A one-line pointer file or README
  ledger table would close it.

### Observations (no grade)

- **O1:** no wall-clock timings were captured for the six live runs; the "well under
  one second per month" claim rests on design and the attested same-session
  completion. Worth capturing once when convenient.
- **O2:** migration 003's blanket SELECT grant predates run_level_map, and no RLS
  policy exists for the reader role on it, so the map is invisible to the entire
  public surface exactly as the README's open question 5 states. Confirmed, no
  action.

## Verdict

**PASS.** 38 of 42 checklist rows pass; the 4 failures are all documentation
currency, none touches engine behavior, and nothing HIGH stands. The engine
implements COMP-PLAN-SPEC v1.2 sections 5 and 6 literally, the self-contained
acceptance test embeds the section 7 contract verbatim and returned zero mismatches
on live Postgres, the seed proof passes locally with the exact deployed row counts,
and the six finalized live runs sit at 14.4 to 15.0 percent of CV, inside the
plan's 20 percent structural ceiling. Phase 3 closes on this gate when mlm-verifier
also passes; the two MEDIUM documentation defects (QA-M1, QA-M2) should be fixed in
the same session so the next phase starts from documents that tell the truth.
