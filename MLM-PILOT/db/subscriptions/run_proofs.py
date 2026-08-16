"""S1 subscription engine proof harness.

One command re-runs every proof:

    py MLM-PILOT\\db\\subscriptions\\run_proofs.py

What it does, start to finish:
  1. Starts a DISPOSABLE PostgreSQL container (docker, image postgres:latest,
     container name mlm-s1-proof, database mlm). Any previous container of
     that name is removed first: every run starts from nothing.
  2. Applies the REAL migration files verbatim, in production order, plus the
     canonical comp engine source (the 008/009 pointer convention):
     001..007, comp/001, 010, 013, fixture part 1, 015..018, 019, 020, 021,
     022, 024, 025, 026, 027, fixture part 2.
     Deliberately NOT applied: 011 (view grant hygiene for the public data
     API), 012 and 014 (demo sign-in accounts; they need the Supabase
     'extensions' schema and psql secrets, and nothing in the engine touches
     authentication). 023 exists only as a pointer (refund guard fix) and is
     not an engine dependency.
  3. Drives the simulated year 2026-09-01 through 2027-09-30 in segments,
     interposing the scripted adversity between ticks exactly where a real
     operator would stand: the crash lever before the 2026-11-15 tick, the
     catalog price change on 2026-12-14, the skipped day 2027-02-01.
  4. Runs the September..December commission runs with the UNMODIFIED comp
     engine and then the proof battery, which prints PASS or FAIL per proof.
  5. Writes the complete transcript to proof_output/transcript-<stamp>.txt
     and exits nonzero if any proof failed or any statement errored.

Flags:
    --keep      leave the container running afterward for inspection
    --port N    host port for PostgreSQL (default 55439)

Why a container and not DuckDB: the engine is trigger-heavy plpgsql and the
proof must exercise the EXACT files the cloud will run, not a dialect
translation. The container is the local-proof discipline made literal.
"""

import argparse
import datetime
import pathlib
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent            # MLM-PILOT
MIGRATIONS = REPO / "db" / "migrations"
COMP = REPO / "db" / "comp"
SQL = HERE / "sql"
OUT = HERE / "proof_output"

CONTAINER = "mlm-s1-proof"
DB = "mlm"
PGUSER = "postgres"
PGPASSWORD = "s1proof"

# The replay set, in order. (path, description)
APPLY_ORDER = [
    (SQL / "00_bootstrap.sql",                          "rig bootstrap (roles, quiet notices)"),
    (MIGRATIONS / "001_app_schema_core_tables.sql",     "001 core tables"),
    (MIGRATIONS / "002_integrity_triggers.sql",         "002 integrity triggers"),
    (MIGRATIONS / "003_row_level_security.sql",         "003 row level security"),
    (MIGRATIONS / "004_ranks_seed.sql",                 "004 ranks seed"),
    (MIGRATIONS / "005_demo_views.sql",                 "005 demo views"),
    (MIGRATIONS / "006_immutability_hardening.sql",     "006 immutability hardening"),
    (MIGRATIONS / "007_customers.sql",                  "007 customers"),
    (COMP / "001_comp_engine.sql",                      "comp engine v1.3 (the 008/009 pointer target)"),
    (MIGRATIONS / "010_demo_orders.sql",                "010 demo orders"),
    (MIGRATIONS / "013_demo_orders_created_at_index.sql", "013 demo orders index"),
    (SQL / "01_fixture_base.sql",                       "fixture part 1: products, members, legacy subscriptions"),
    (MIGRATIONS / "015_member_tax_addresses.sql",       "015 member tax addresses"),
    (MIGRATIONS / "016_order_tax_provenance.sql",       "016 order tax provenance"),
    (MIGRATIONS / "017_tax_transaction_record.sql",     "017 tax transaction record"),
    (MIGRATIONS / "018_tax_integrity_hardening.sql",    "018 tax integrity hardening"),
    (MIGRATIONS / "019_shop_to_comp_bridge.sql",        "019 shop-to-comp bridge"),
    (MIGRATIONS / "020_house_account.sql",              "020 house account"),
    (MIGRATIONS / "021_calendar_month_containment.sql", "021 calendar-month containment"),
    (MIGRATIONS / "022_refunds.sql",                    "022 refunds"),
    (MIGRATIONS / "024_subscription_engine_schema.sql", "024 subscription engine schema (S1)"),
    (MIGRATIONS / "025_subscription_policy_data.sql",   "025 classification and ladder data (S1)"),
    (MIGRATIONS / "026_renewal_engine.sql",             "026 renewal engine (S1)"),
    (MIGRATIONS / "027_bridge_covered_months_spread.sql", "027 bridge covered_months amendment (S1)"),
    (SQL / "02_fixture_s1.sql",                         "fixture part 2: clock, cast, credentials, scripts"),
]

SIM_ORDER = [
    (SQL / "10_ticks_sep_to_nov14.sql",                 "ticks 2026-09-01 .. 2026-11-14 (worked examples A/B, auto-cancel)"),
    (SQL / "11_crash_tick.sql",                         "FM2: the crash after 47 of 60 dispatches"),
    (SQL / "12_recover_tick.sql",                       "FM2: the recovery rerun (reconciler + gather)"),
    (SQL / "13_ticks_nov16_nov30.sql",                  "ticks 2026-11-16 .. 2026-11-30"),
    (SQL / "14_dec1_double_tick.sql",                   "FM1: the double tick of 2026-12-01"),
    (SQL / "15_price_change_and_ticks_to_jan31.sql",    "FM3: price change 2026-12-14, ticks to 2027-01-31"),
    (SQL / "16_skip_and_finish.sql",                    "catch-up: skip 2027-02-01, ticks to 2027-09-30"),
    (SQL / "20_commission_runs.sql",                    "commission runs Sep..Dec 2026 (unmodified engine)"),
    (SQL / "30_proof_battery.sql",                      "THE PROOF BATTERY"),
]


def sh(args, check=True, **kw):
    return subprocess.run(args, check=check, capture_output=True, text=True, **kw)


def psql_file(path: pathlib.Path) -> subprocess.CompletedProcess:
    """Run one SQL file inside the container over a single connection."""
    with open(path, "r", encoding="utf-8") as fh:
        sql_text = fh.read()
    return subprocess.run(
        ["docker", "exec", "-i", "-e", f"PGPASSWORD={PGPASSWORD}", CONTAINER,
         "psql", "-v", "ON_ERROR_STOP=1", "-U", PGUSER, "-d", DB, "-f", "-"],
        input=sql_text, capture_output=True, text=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--port", type=int, default=55439)
    args = ap.parse_args()

    OUT.mkdir(exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    transcript_path = OUT / f"transcript-{stamp}.txt"
    transcript = open(transcript_path, "w", encoding="utf-8")

    def log(text):
        print(text)
        transcript.write(text + "\n")
        transcript.flush()

    failures = []

    log(f"S1 proof run, {datetime.datetime.now().isoformat()}")
    log(f"repo: {REPO}")

    # 1. Fresh container.
    sh(["docker", "rm", "-f", CONTAINER], check=False)
    sh(["docker", "run", "-d", "--name", CONTAINER,
        "-e", f"POSTGRES_PASSWORD={PGPASSWORD}", "-e", f"POSTGRES_DB={DB}",
        "-p", f"{args.port}:5432", "postgres:latest"])
    log(f"container {CONTAINER} started (postgres:latest, host port {args.port})")

    for attempt in range(60):
        r = sh(["docker", "exec", "-e", f"PGPASSWORD={PGPASSWORD}", CONTAINER,
                "pg_isready", "-U", PGUSER, "-d", DB], check=False)
        if r.returncode == 0:
            # pg_isready can pass a moment before the init script's restart;
            # confirm with a real query.
            r2 = sh(["docker", "exec", "-e", f"PGPASSWORD={PGPASSWORD}", CONTAINER,
                     "psql", "-U", PGUSER, "-d", DB, "-c", "select 1"], check=False)
            if r2.returncode == 0:
                break
        time.sleep(1)
    else:
        log("FATAL: PostgreSQL never became ready")
        return 2
    log("postgres ready")

    # 2. Apply the replay set.
    for path, desc in APPLY_ORDER:
        t0 = time.time()
        r = psql_file(path)
        dt = time.time() - t0
        log(f"\n===== APPLY [{desc}] {path.name} ({dt:.1f}s) =====")
        if r.stdout.strip():
            log(r.stdout.rstrip())
        if r.stderr.strip():
            log(r.stderr.rstrip())
        if r.returncode != 0:
            failures.append(f"APPLY FAILED: {path.name}")
            log(f"*** APPLY FAILED: {path.name} ***")
            break

    # 3 and 4. The simulated year and the battery.
    if not failures:
        for path, desc in SIM_ORDER:
            t0 = time.time()
            r = psql_file(path)
            dt = time.time() - t0
            log(f"\n===== RUN [{desc}] {path.name} ({dt:.1f}s) =====")
            if r.stdout.strip():
                log(r.stdout.rstrip())
            if r.stderr.strip():
                log(r.stderr.rstrip())
            if r.returncode != 0:
                failures.append(f"SEGMENT FAILED: {path.name}")
                log(f"*** SEGMENT FAILED: {path.name} ***")
                break
            if "FAIL" in r.stdout:
                for line in r.stdout.splitlines():
                    if "FAIL" in line:
                        failures.append(f"{path.name}: {line.strip()}")

    # 5. Verdict.
    log("\n===== HARNESS VERDICT =====")
    if failures:
        log(f"FAILED ({len(failures)}):")
        for f in failures:
            log(f"  - {f}")
    else:
        log("ALL PROOFS PASS")
    log(f"transcript: {transcript_path}")

    if not args.keep:
        sh(["docker", "rm", "-f", CONTAINER], check=False)
        log(f"container {CONTAINER} removed (use --keep to inspect)")
    else:
        log(f"container kept: docker exec -it {CONTAINER} psql -U {PGUSER} -d {DB}")

    transcript.close()
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
