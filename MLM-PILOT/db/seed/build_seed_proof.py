#!/usr/bin/env python3
"""MLM Pilot seed proof (Globex persona, personal project).

Run with:  py build_seed_proof.py     (from db\\seed\\, after generate_seed.py)

Loads the CSV pack from db\\seed\\output\\ into a DuckDB database at
db\\seed\\output\\seed_proof.duckdb (tables are created or replaced in place;
no file is ever deleted) and prints the sanity report:

  - total members
  - tree depth reached and members per depth level
  - orphan count (members beyond the single root with a missing sponsor)
  - per-month volume totals for the 6 history months
  - percent of member-months qualified (monthly volume >= 100)
  - subscription counts by tier
  - churn rate
  - realism bars: qualified share 40 to 65 percent, depth histogram not
    degenerate, at least 3 members with large frontlines

It also validates the worked example CSVs against COMP-PLAN-SPEC v1.1
section 7: per-member sales volume (SV) and commissionable volume (CV), team
volume (TV) recomputed from the tree, and the expected company totals
(SV 2,700.00, CV 2,160.00, payout 264.00, members paid 4).

Exit code 0 = every check passed; 1 = at least one check failed.
"""

import sys
from pathlib import Path

import duckdb

OUT_DIR = Path(__file__).resolve().parent / "output"
DB_PATH = OUT_DIR / "seed_proof.duckdb"

HISTORY_MONTHS = ["2026-02-01", "2026-03-01", "2026-04-01",
                  "2026-05-01", "2026-06-01", "2026-07-01"]

FAILURES = []


def check(label, ok, detail=""):
    mark = "PASS" if ok else "FAIL"
    print(f"  [{mark}] {label}" + (f" ({detail})" if detail else ""))
    if not ok:
        FAILURES.append(label)


def main():
    con = duckdb.connect(str(DB_PATH))

    def load(table, filename, columns):
        con.execute(f"create or replace table {table} as "
                    f"select * from read_csv('{(OUT_DIR / filename).as_posix()}', "
                    f"header = true, columns = {columns})")

    load("members", "members.csv",
         "{'id':'BIGINT','member_code':'VARCHAR','display_name':'VARCHAR',"
         "'email':'VARCHAR','sponsor_id':'BIGINT','enrolled_on':'DATE',"
         "'status':'VARCHAR'}")
    load("products", "products.csv",
         "{'id':'BIGINT','sku':'VARCHAR','name':'VARCHAR','tier':'VARCHAR',"
         "'price':'DECIMAL(10,2)','volume_points':'DECIMAL(10,2)',"
         "'commissionable_value':'DECIMAL(10,2)'}")
    load("subscriptions", "subscriptions.csv",
         "{'id':'BIGINT','member_id':'BIGINT','product_id':'BIGINT',"
         "'quantity':'INTEGER','start_month':'DATE','cancel_month':'DATE'}")
    load("orders", "orders.csv",
         "{'id':'BIGINT','member_id':'BIGINT','buyer_role':'VARCHAR',"
         "'ordered_at':'VARCHAR','volume_month':'DATE','status':'VARCHAR'}")
    load("order_lines", "order_lines.csv",
         "{'id':'BIGINT','order_id':'BIGINT','product_id':'BIGINT',"
         "'quantity':'INTEGER','unit_price':'DECIMAL(10,2)',"
         "'unit_volume':'DECIMAL(10,2)'}")

    load("we_members", "worked_example_members.csv",
         "{'id':'BIGINT','member_code':'VARCHAR','display_name':'VARCHAR',"
         "'email':'VARCHAR','sponsor_id':'BIGINT','enrolled_on':'DATE',"
         "'status':'VARCHAR'}")
    load("we_orders", "worked_example_orders.csv",
         "{'id':'BIGINT','member_id':'BIGINT','buyer_role':'VARCHAR',"
         "'ordered_at':'VARCHAR','volume_month':'DATE','status':'VARCHAR'}")
    load("we_order_lines", "worked_example_order_lines.csv",
         "{'id':'BIGINT','order_id':'BIGINT','product_id':'BIGINT',"
         "'quantity':'INTEGER','unit_price':'DECIMAL(10,2)',"
         "'unit_volume':'DECIMAL(10,2)'}")
    load("we_expected_results", "worked_example_expected_member_results.csv",
         "{'member_code':'VARCHAR','sv':'DECIMAL(12,2)','cv':'DECIMAL(12,2)',"
         "'qualified':'BOOLEAN','tv':'DECIMAL(14,2)','rank_earned':'VARCHAR',"
         "'paid_depth':'INTEGER','total_earned':'DECIMAL(12,2)'}")
    load("we_expected_lines", "worked_example_expected_commission_lines.csv",
         "{'earner_code':'VARCHAR','source_code':'VARCHAR','level':'INTEGER',"
         "'source_cv':'DECIMAL(12,2)','rate':'DECIMAL(5,4)',"
         "'amount':'DECIMAL(12,2)'}")
    load("we_expected_company", "worked_example_expected_company.csv",
         "{'period':'DATE','total_sv':'DECIMAL(14,2)','total_cv':'DECIMAL(14,2)',"
         "'total_payout':'DECIMAL(14,2)','members_paid':'INTEGER'}")

    q1 = lambda sql: con.execute(sql).fetchone()[0]

    print("=" * 68)
    print("MLM Pilot seed proof")
    print(f"database: {DB_PATH}")
    print("=" * 68)

    # ---------------- members and tree ----------------
    total_members = q1("select count(*) from members")
    roots = q1("select count(*) from members where sponsor_id is null")
    bad_sponsor = q1("select count(*) from members m left join members s "
                     "on s.id = m.sponsor_id "
                     "where m.sponsor_id is not null and s.id is null")
    orphans = (roots - 1) + bad_sponsor

    print("\n-- Members and tree --")
    print(f"total members: {total_members}")
    check("total members = 1000", total_members == 1000)
    check("exactly one root", roots == 1, f"roots = {roots}")
    check("orphan count beyond the root = 0", orphans == 0,
          f"orphans = {orphans}")

    depth_rows = con.execute("""
        with recursive tree as (
            select id, 1 as depth from members where sponsor_id is null
            union all
            select m.id, t.depth + 1
            from members m join tree t on m.sponsor_id = t.id
        )
        select depth, count(*) as members
        from tree group by depth order by depth
    """).fetchall()
    reached = sum(n for _, n in depth_rows)
    max_depth = max(d for d, _ in depth_rows)
    print("members per depth level:")
    for d, n in depth_rows:
        print(f"  depth {d:>2}: {n:>4}  {'#' * max(1, n // 12)}")
    print(f"tree depth reached: {max_depth}")
    check("every member reachable from the root", reached == total_members,
          f"reached = {reached}")
    check("max depth between 8 and 12", 8 <= max_depth <= 12,
          f"max depth = {max_depth}")
    populated = sum(1 for _, n in depth_rows if n >= 10)
    check("depth histogram not degenerate (>= 6 levels with 10+ members)",
          populated >= 6, f"levels with 10+ members = {populated}")

    top_front = con.execute("""
        select s.member_code, count(*) as frontline
        from members m join members s on s.id = m.sponsor_id
        group by s.member_code order by frontline desc limit 10
    """).fetchall()
    print("top 10 frontlines (direct enrollees):")
    for code, n in top_front:
        print(f"  {code}: {n}")
    big = sum(1 for _, n in top_front if n >= 15)
    check("at least 3 members with large frontlines (15+ direct)", big >= 3,
          f"count = {big}")

    # ---------------- volumes per month ----------------
    print("\n-- Volume per history month --")
    vol_rows = con.execute("""
        select o.volume_month, sum(l.quantity * l.unit_volume) as sv,
               count(distinct o.member_id) as buyers
        from orders o join order_lines l on l.order_id = o.id
        where o.status = 'completed'
        group by o.volume_month order by o.volume_month
    """).fetchall()
    for month, sv, buyers in vol_rows:
        print(f"  {month}: total volume {float(sv):>10.2f}  "
              f"(buying members: {buyers})")
    check("exactly 6 history months of orders", len(vol_rows) == 6,
          f"months = {len(vol_rows)}")

    # ---------------- qualified member-months ----------------
    months_list = ", ".join(f"date '{m}'" for m in HISTORY_MONTHS)
    qual = con.execute(f"""
        with months as (select unnest([{months_list}]) as period),
        member_months as (
            select m.id, mo.period
            from members m cross join months mo
            where date_trunc('month', m.enrolled_on) <= mo.period
        ),
        sv as (
            select o.member_id, o.volume_month as period,
                   sum(l.quantity * l.unit_volume) as sv
            from orders o join order_lines l on l.order_id = o.id
            where o.status = 'completed'
            group by o.member_id, o.volume_month
        )
        select count(*) as member_months,
               sum(case when coalesce(sv.sv, 0) >= 100 then 1 else 0 end) as qualified
        from member_months mm left join sv
             on sv.member_id = mm.id and sv.period = mm.period
    """).fetchone()
    member_months, qualified = qual
    share = 100.0 * qualified / member_months
    print("\n-- Qualification --")
    print(f"member-months (enrolled): {member_months}")
    print(f"qualified member-months (volume >= 100): {qualified}")
    print(f"qualified share: {share:.1f} percent")
    check("qualified share between 40 and 65 percent", 40.0 <= share <= 65.0,
          f"{share:.1f} percent")

    # ---------------- subscriptions ----------------
    print("\n-- Subscriptions --")
    for tier, n in con.execute("""
        select p.tier, count(*) from subscriptions s
        join products p on p.id = s.product_id
        group by p.tier order by p.tier
    """).fetchall():
        print(f"  {tier}: {n}")
    total_subs = q1("select count(*) from subscriptions")
    cancelled = q1("select count(*) from subscriptions where cancel_month is not null")
    cancelled_in_window = q1("select count(*) from subscriptions "
                             "where cancel_month is not null "
                             "and cancel_month <= date '2026-07-01'")
    print(f"total subscriptions: {total_subs}")
    print(f"churn rate (cancel_month set): {100.0 * cancelled / total_subs:.1f} percent")
    print(f"churned by end of history window: "
          f"{100.0 * cancelled_in_window / total_subs:.1f} percent")
    agents_10plus = q1("""
        select count(*) from (
            select member_id from subscriptions
            group by member_id having sum(quantity) >= 10)
    """)
    single_support = q1("""
        select count(*) from (
            select s.member_id
            from subscriptions s join products p on p.id = s.product_id
            group by s.member_id
            having count(*) = 1 and sum(s.quantity) = 1
               and max(p.tier) = 'support' and min(p.tier) = 'support')
    """)
    print(f"members holding 10+ agents (whales): {agents_10plus}")
    print(f"members holding exactly one support agent: {single_support}")
    check("a few whales hold 10 or more agents", agents_10plus >= 5,
          f"count = {agents_10plus}")
    check("meaningful minority hold a single support agent",
          single_support >= 100, f"count = {single_support}")

    # ---------------- worked example validation ----------------
    print("\n-- Worked example (COMP-PLAN-SPEC v1.1 section 7) --")
    mismatches = con.execute("""
        with sv as (
            select o.member_id, sum(l.quantity * l.unit_volume) as sv
            from we_orders o join we_order_lines l on l.order_id = o.id
            group by o.member_id
        ),
        actual as (
            select m.member_code, m.id, coalesce(sv.sv, 0) as sv,
                   round(coalesce(sv.sv, 0) * 0.80, 2) as cv
            from we_members m left join sv on sv.member_id = m.id
        ),
        tv as (
            select a.member_code,
                   (with recursive down as (
                        select id from we_members where sponsor_id = a.id
                        union all
                        select m.id from we_members m
                        join down d on m.sponsor_id = d.id)
                    select coalesce(sum(x.sv), 0)
                    from down join actual x on x.id = down.id) as tv
            from actual a
        )
        select count(*)
        from we_expected_results e
        join actual a on a.member_code = e.member_code
        join tv on tv.member_code = e.member_code
        where a.sv <> e.sv or a.cv <> e.cv or tv.tv <> e.tv
           or (a.sv >= 100) <> e.qualified
    """).fetchone()[0]
    check("per-member SV, CV, TV and qualification match spec section 7.1",
          mismatches == 0, f"mismatching members = {mismatches}")

    tot = con.execute("""
        select sum(l.quantity * l.unit_volume),
               (select sum(round(sv * 0.80, 2)) from (
                    select sum(l2.quantity * l2.unit_volume) as sv
                    from we_orders o2 join we_order_lines l2 on l2.order_id = o2.id
                    group by o2.member_id))
        from we_orders o join we_order_lines l on l.order_id = o.id
    """).fetchone()
    check("company SV = 2700.00", float(tot[0]) == 2700.00, f"sv = {tot[0]}")
    check("company CV = 2160.00", float(tot[1]) == 2160.00, f"cv = {tot[1]}")

    exp = con.execute("""
        select sum(amount), count(distinct earner_code),
               sum(round(source_cv * rate, 2)) - sum(amount)
        from we_expected_lines
    """).fetchone()
    check("expected commission lines sum to 264.00", float(exp[0]) == 264.00,
          f"sum = {exp[0]}")
    check("expected members paid = 4", exp[1] == 4, f"earners = {exp[1]}")
    check("every expected line amount = round(cv * rate, 2)",
          float(exp[2]) == 0.0, f"delta = {exp[2]}")

    per_earner_ok = q1("""
        select count(*) from (
            select l.earner_code, sum(l.amount) as amt
            from we_expected_lines l group by l.earner_code) s
        join we_expected_results r on r.member_code = s.earner_code
        where s.amt <> r.total_earned
    """)
    check("expected per-earner totals match section 7.4", per_earner_ok == 0,
          f"mismatches = {per_earner_ok}")
    company_ok = q1("""
        select count(*) from we_expected_company
        where total_sv <> 2700.00 or total_cv <> 2160.00
           or total_payout <> 264.00 or members_paid <> 4
    """)
    check("expected company row matches section 7.4", company_ok == 0)

    con.close()

    print("\n" + "=" * 68)
    if FAILURES:
        print(f"RESULT: {len(FAILURES)} CHECK(S) FAILED")
        for f in FAILURES:
            print(f"  - {f}")
        sys.exit(1)
    print("RESULT: ALL CHECKS PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
