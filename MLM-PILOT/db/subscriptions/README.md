# Subscription engine S1 proof harness

One command re-runs every proof from nothing:

```
py MLM-PILOT\db\subscriptions\run_proofs.py
```

Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\db\subscriptions\run_proofs.py`

Requirements: Docker Desktop running (image `postgres:latest`, pulled
automatically if absent) and the `py` Python launcher. Nothing touches the
cloud project; the standing rule (open question ruling OQ8) is that NOTHING
in Phase S1 applies to Supabase until both gates pass on these exact
artifacts.

## What one run does

1. Starts a disposable PostgreSQL container (`mlm-s1-proof`, database `mlm`)
   and deletes any previous one, so every run starts from an empty database.
2. Applies the REAL migration files verbatim in production order: 001..007,
   the canonical comp engine (`db\comp\001_comp_engine.sql`, the 008/009
   pointer target), 010, 013, 015..022, then the four S1 migrations
   024..027. Migrations 011, 012 and 014 are deliberately skipped (public
   data-API grant hygiene and demo sign-in accounts; they need Supabase's
   `extensions` schema and secrets, and the engine never touches
   authentication).
3. Seeds a deterministic proof cast (`sql\01_fixture_base.sql`,
   `sql\02_fixture_s1.sql`): products, members, legacy-shaped subscriptions
   inserted BEFORE migration 024 so the backfill is proven on real rows, and
   the outcome scripts that are the whole year's scripted adversity.
4. Drives the simulated year 2026-09-01 through 2027-09-30 (394 daily ticks,
   one day deliberately skipped), interposing the crash lever, the catalog
   price change, the skipped day, AND (since the 2026-08-16 fix round) the
   full member-action year at its scripted dates: pause mid-ladder, pause
   from dunning, pause from active, an early-resume refusal and an allowed
   early resume, cancel during dunning, a cancel that voids system-fault
   periods, the 2017 and 2018 cancellation lanes, the day-28 zero-ladder
   case, reactivations from suspended and from card_update_required, the
   OQ4 billing-day transition, and a sanctioned frequency change.
5. Runs September..December 2026 through the UNMODIFIED compensation engine,
   then the proof battery (`sql\30_proof_battery.sql`), where every proof
   prints PASS or FAIL with its key numbers: 65 battery rows as of the fix
   round.
6. Writes the full transcript to `proof_output\transcript-<stamp>.txt` and
   exits nonzero on any FAIL or SQL error. A full run takes roughly 40
   seconds wall time (about 20 seconds of SQL plus container start-up).

Flags: `--keep` leaves the container up for inspection
(`docker exec -it mlm-s1-proof psql -U postgres -d mlm`); `--port N` changes
the host port (default 55439).

## Why a PostgreSQL container and not DuckDB

The engine is trigger-heavy plpgsql (state-transition guards, append-only
triggers, the demo-order status machine). DuckDB cannot execute it, and a
Python re-implementation would prove a PARALLEL rule set, not the shipped
SQL. The container runs the exact files the cloud will run, which is the
charter's local-proof discipline made literal.

## The proofs, mapped to the spec's register

| Battery rows | Failure mode / requirement |
|---|---|
| A1..A3 + segment 14 | FM1 double release: same tick run twice, zero new rows, per-cycle key held |
| B1..B4 + segments 11/12 | FM2 orphaned order: crash after 47 of 60 dispatches, orphan surfaced in the attention queue, reconciler resolves and re-dispatches idempotently, batch completes with zero duplicates |
| C1..C2 | FM3 stale pricing: mid-year catalog change bills the new price next cycle; the schema carries no stored-price path at all |
| D1..D3 | FM4 skipped month: day-31 anchor crosses February, twelve cycles, zero gaps in the cycle audit |
| E1..E5 | FM5 corrupted credential: stopped at pre-flight, internal_config, zero retries, member clocks untouched, attention queue row |
| W-A*, W-B*, W-C* | The spec section 11 worked examples, to the cent, through the real bridge and the real comp engine |
| S1..S2 | The 6.1 evolution backfill and the engine-epoch guard |
| G1..G8 | The section 14 invariants (R2 structural, ladder discipline, rule C1, promo hook identity, MIT invariant, fault-family separation, clock continuity) |
| FQ1..FQ4 | Bi-monthly and semi-annual billing, coverage and spread (QA M2, verifier M5) |
| MA1..MA13 | The member-action year: every pause lane including T10a's frozen clock (spec v1.1 12.3 micro-example), resume paths, cancels, the 2017/2018 lanes, day-28 truncation, both reactivations (verifier H1 scenarios, QA M3) |
| MG1..MG6 | The OQ4 transition rule to the letter (spec v1.1 erratum E3) and the schedule-column guard refusing raw frequency and anchor updates (verifier M1, M2) |
| GX1..GX4 | Coverage never doubles; supersession hygiene; the outcome vocabulary fully alive (skipped_paused and void_cancelled both written, verifier L1) |

The recorded proof run lives at
`MLM-PILOT\docs\verification\S1-PROOF-RUN-2026-08-16.md`.
