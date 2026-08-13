#!/usr/bin/env python3
"""MLM Pilot seed generator (Globex persona, personal project).

Run with:  py generate_seed.py     (from db\\seed\\)

Produces, in db\\seed\\output\\:
  products.csv, members.csv, customers.csv, subscriptions.csv, orders.csv,
  order_lines.csv
  load_seed.sql                (Postgres loader for the pack above)
  worked_example_members.csv, worked_example_customers.csv,
  worked_example_subscriptions.csv,
  worked_example_orders.csv, worked_example_order_lines.csv
  worked_example_expected_member_results.csv
  worked_example_expected_commission_lines.csv
  worked_example_expected_company.csv
  load_worked_example.sql      (loader for the acceptance dataset; EMPTY db only)
  _manifest.txt                (seed value, parameters, row counts, file hashes)

Everything is DETERMINISTIC: one seeded pseudo-random generator drives all
choices, the seed is written into the manifest and the loader headers, and no
wall-clock value enters any output file, so a rerun regenerates byte-identical
data.

Dataset shape (per the Phase 1/2 brief):
  - 12 catalog products: 6 domain agents at 100.00 / 100 volume points and
    6 support agents at 50.00 / 50 volume points.
  - 1,000 members in a realistic unilevel tree: a few large leaders, a long
    tail, maximum depth 8 to 12, exactly one root, enrollment spread over
    24 months (2024-08 through 2026-07).
  - Subscriptions with lifecycles (starts spread over time, churn via
    cancel_month, upgrades as later subscription rows). Most members hold
    1 to 3 agents, a meaningful minority hold a single support agent
    (enrolled but never qualified), a few whales hold 10 or more agents.
  - Orders: for each of the 6 history months (2026-02 through 2026-07),
    every subscription active that month (start_month <= m < cancel_month,
    null cancel_month = active) produces exactly one order dated the first
    of the month, with order lines copying price and volume points.
  - Enrollment plausibility rule (generator v2, fixes verifier finding M1):
    a subscription's start_month is never earlier than the first day of the
    month FOLLOWING enrollment when the account enrolled after the 1st of a
    month; accounts enrolled exactly on the 1st may start that same month.
    Orders are stamped the 1st of the month at midnight, so this guarantees
    no order predates its buyer's enrollment date. Accounts that enroll
    after the 1st of the final enrollment month (2026-07) start billing
    2026-08, outside the history window, and therefore have no orders.
    The rule applies to member subscriptions (the member's enrolled_on) and
    to customer subscriptions (the CUSTOMER's enrolled_on) alike.
  - Customers (generator v3, spec v1.2): roughly 35 to 50 percent of active
    distributors have 1 to 4 customers (a few outliers hold more). Customer
    subscriptions follow the same lifecycle mechanics (clamped starts, some
    churn), and every customer order is BOOKED with member_id = the
    referring member's account, buyer_role = 'retail_customer', and
    customer_id = the actual buyer (the attribution rule). A seller
    archetype holds ZERO personal subscriptions and 2 or 3 customers with
    one 50-point support agent each: qualification resting entirely on
    volume sold, never bought. Customer subscriptions are internal to the
    generator (the schema's subscriptions table is member-only); only the
    generated customers and orders are exported.
  - Target realism: 40 to 65 percent of member-months qualified
    (monthly volume >= 100).

The worked example files reproduce COMP-PLAN-SPEC.md v1.2 section 7 exactly
(10 members M1-M10, one month, company sales volume (SV) 2,700.00,
commissionable volume (CV) 2,160.00, payout 264.00, members paid 4). Per
v1.2, M4's two support agents are held by M4's customers C1 and C2
(OC-000001, OC-000002); their orders book onto M4's account as
'retail_customer', and every expected result is UNCHANGED, which is the
point of the attribution rule. They are the comp engine's acceptance dataset and
must be loaded into an EMPTY database, never on top of the 1,000-member pack.
"""

import csv
import hashlib
import io
import random
from pathlib import Path

# ---------------------------------------------------------------------------
# Parameters (all deterministic behavior flows from SEED)
# ---------------------------------------------------------------------------
SEED = 20260813

N_MEMBERS = 1000
ENROLL_MONTH_COUNT = 24          # months 0..23 = 2024-08 .. 2026-07
HISTORY_FIRST_MONTH = 18         # 2026-02
HISTORY_LAST_MONTH = 23          # 2026-07
MAX_DEPTH = 12                   # depth of root = 1

# Tree shaping
SUPER_RECRUITER_COUNT = 5        # designated large-frontline leaders
SUPER_RECRUITER_POOL = 40        # supers drawn from the first N joiners
SUPER_WEIGHT_MULT = 9.0          # attachment weight multiplier for supers
PREF_CHILD_WEIGHT = 0.55         # preferential attachment per existing child
PREF_CHILD_CAP = 22              # diminishing returns above this frontline size
P_CHAIN = 0.50                   # probability of attaching to a recent joiner
RECENT_WINDOW = 90               # "recent joiner" pool size

# Holdings mix
# (retuned in generator v3: customer volume lifts the qualified share, so
# personal-subscription density comes down to keep the share mid-band)
WHALE_COUNT = 12                 # hold 10+ agents
P_STARTER = 0.35                 # single support agent, never qualified
P_STANDARD = 0.49                # 1 to 3 agents
# remainder (~0.16) are builders: 2 to 5 agents with upgrades

# Churn probabilities per subscription, by archetype
CHURN_P = {"starter": 0.35, "standard": 0.26, "builder": 0.12, "whale": 0.04}

# Customers (generator v3, spec v1.2)
SELLER_COUNT = 40                # members with zero personal spend who
                                 # qualify only through customer volume
SELLER_ENROLL_MONTH_MAX = 18     # seller pool cutoff so their customers
                                 # can still bill inside the history window
SELLER_CUSTOMER_ENROLL_CAP = 20  # latest enrollment month for a seller's
                                 # customers
SELLER_CUSTOMER_CHURN_P = 0.10
P_HAS_CUSTOMERS = 0.42           # share of active non-seller distributors
                                 # holding at least one customer
CUSTOMER_CHURN_P = 0.30

BASE_YEAR = 2024
BASE_MONTH = 8                   # month index 0 = 2024-08

OUT_DIR = Path(__file__).resolve().parent / "output"

DAYS_IN_MONTH = {1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30,
                 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31}

FIRST_NAMES = [
    "Avery", "Blake", "Casey", "Dana", "Ellis", "Frankie", "Gray", "Harper",
    "Indigo", "Jules", "Kendall", "Lane", "Marlow", "Noel", "Oakley", "Parker",
    "Quinn", "Reese", "Sage", "Tatum", "Umber", "Vale", "Wren", "Xen",
    "Yael", "Zion", "Arden", "Briar", "Cove", "Dune", "Ember", "Fern",
    "Grove", "Haven", "Isle", "Juniper", "Kai", "Linden", "Meadow", "North",
]
LAST_NAMES = [
    "Amberly", "Birchwood", "Claymore", "Dovetail", "Eastbrook", "Fairwind",
    "Goldcrest", "Hollowell", "Ironwood", "Jasperfield", "Kingsley", "Larkspur",
    "Mossbank", "Nightingale", "Oakhurst", "Pinegrove", "Quillfeather", "Rosewood",
    "Silverbrook", "Thornbury", "Underhill", "Violette", "Westerly", "Yarrow",
    "Ashford", "Bellweather", "Cinderhall", "Duskfield", "Elmsworth", "Foxglove",
    "Greenmantle", "Hazelby", "Ivorydale", "Juneberry", "Kestrel", "Lightfoot",
    "Marigold", "Nettlebed", "Orchardson", "Palewater",
]

DOMAIN_AGENTS = ["Payment Agent", "Shipping Agent", "Pricing Agent",
                 "Inventory Agent", "Marketing Agent", "Tax Agent"]
SUPPORT_AGENTS = ["Software Engineer", "Quality Assurance", "Secretary",
                  "Chief Executive", "Accounting", "Customer Care"]


# ---------------------------------------------------------------------------
# Date helpers (month index <-> calendar date)
# ---------------------------------------------------------------------------
def month_ym(idx):
    """Month index -> (year, month). Index 0 = 2024-08."""
    total = (BASE_YEAR * 12 + (BASE_MONTH - 1)) + idx
    return total // 12, total % 12 + 1


def month_first(idx):
    y, m = month_ym(idx)
    return f"{y:04d}-{m:02d}-01"


def date_in_month(idx, day):
    y, m = month_ym(idx)
    return f"{y:04d}-{m:02d}-{day:02d}"


def days_in(idx):
    y, m = month_ym(idx)
    return DAYS_IN_MONTH[m]


# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------
def build_products():
    rows = []
    pid = 0
    for i, name in enumerate(DOMAIN_AGENTS, start=1):
        pid += 1
        rows.append({"id": pid, "sku": f"AGT-D-{i:03d}", "name": name,
                     "tier": "domain", "price": "100.00",
                     "volume_points": "100.00", "commissionable_value": ""})
    for i, name in enumerate(SUPPORT_AGENTS, start=1):
        pid += 1
        rows.append({"id": pid, "sku": f"AGT-S-{i:03d}", "name": name,
                     "tier": "support", "price": "50.00",
                     "volume_points": "50.00", "commissionable_value": ""})
    return rows


def build_members(rng):
    """Members with a realistic unilevel tree. Returns (rows, depth, children)."""
    # 1. Enrollment months: root at month 0, the rest weighted toward later
    #    months (the business grows), sorted so index order = date order.
    weights = [1.0 + 0.08 * m for m in range(ENROLL_MONTH_COUNT)]
    months = sorted(rng.choices(range(ENROLL_MONTH_COUNT), weights=weights,
                                k=N_MEMBERS - 1))
    enroll_month = [0] + months

    # Enrollment days: within each month, sorted ascending so a lower member
    # index always means enrolled on or before (sponsors precede children).
    enroll_day = [0] * N_MEMBERS
    i = 0
    while i < N_MEMBERS:
        j = i
        while j < N_MEMBERS and enroll_month[j] == enroll_month[i]:
            j += 1
        days = sorted(rng.randint(1, days_in(enroll_month[i]))
                      for _ in range(j - i))
        for k in range(i, j):
            enroll_day[k] = days[k - i]
        i = j

    # 2. Super recruiters: a handful of early joiners with outsized pull.
    supers = set(rng.sample(range(1, SUPER_RECRUITER_POOL), SUPER_RECRUITER_COUNT))

    # 3. Sponsor selection: mixture of preferential attachment (large leaders)
    #    and recent-joiner chaining (depth), capped at MAX_DEPTH.
    depth = [0] * N_MEMBERS
    depth[0] = 1
    children = [0] * N_MEMBERS
    sponsor = [None] * N_MEMBERS

    for i in range(1, N_MEMBERS):
        eligible = [j for j in range(i) if depth[j] < MAX_DEPTH]
        if rng.random() < P_CHAIN:
            pool = eligible[-RECENT_WINDOW:]
            s = pool[rng.randrange(len(pool))]
        else:
            w = [(1.0 + PREF_CHILD_WEIGHT * min(children[j], PREF_CHILD_CAP))
                 * (SUPER_WEIGHT_MULT if j in supers else 1.0)
                 for j in eligible]
            s = rng.choices(eligible, weights=w, k=1)[0]
        sponsor[i] = s
        depth[i] = depth[s] + 1
        children[s] += 1

    rows = []
    for i in range(N_MEMBERS):
        first = FIRST_NAMES[rng.randrange(len(FIRST_NAMES))]
        last = LAST_NAMES[rng.randrange(len(LAST_NAMES))]
        member_id = i + 1
        rows.append({
            "id": member_id,
            "member_code": f"GW-{member_id:06d}",
            "display_name": f"{first} {last}",
            "email": f"{first.lower()}.{last.lower()}.{member_id}@example.com",
            "sponsor_id": "" if sponsor[i] is None else sponsor[i] + 1,
            "enrolled_on": date_in_month(enroll_month[i], enroll_day[i]),
            "status": "active",  # may flip to closed after churn is known
        })
    return rows, enroll_month, enroll_day, depth, children, supers


def assign_archetypes(rng, enroll_month, supers):
    """Archetype per member index: starter / standard / builder / whale /
    seller. Sellers (generator v3) hold zero personal subscriptions and
    qualify only through customer volume."""
    whale_pool = [i for i in range(1, N_MEMBERS) if enroll_month[i] <= 15]
    whales = set(rng.sample(whale_pool, WHALE_COUNT))
    seller_pool = [i for i in range(1, N_MEMBERS)
                   if i not in supers and i not in whales
                   and enroll_month[i] <= SELLER_ENROLL_MONTH_MAX]
    sellers = set(rng.sample(seller_pool, SELLER_COUNT))
    archetype = {}
    for i in range(N_MEMBERS):
        if i == 0 or i in supers:
            archetype[i] = "builder"   # root and supers behave like builders
        elif i in whales:
            archetype[i] = "whale"
        elif i in sellers:
            archetype[i] = "seller"
        else:
            r = rng.random()
            if r < P_STARTER:
                archetype[i] = "starter"
            elif r < P_STARTER + P_STANDARD:
                archetype[i] = "standard"
            else:
                archetype[i] = "builder"
    return archetype


def build_subscriptions(rng, enroll_month, enroll_day, archetype, products):
    """Subscription rows with lifecycles. Product ids: 1..6 domain, 7..12 support.

    Enrollment plausibility rule (generator v2): every start_month is clamped
    to the member's earliest plausible billing month, which is the enrollment
    month when the member enrolled on the 1st, otherwise the month after
    enrollment. Orders are stamped the 1st at midnight, so without the clamp
    a mid-month enrollee's first order would predate their enrollment date
    (verifier finding M1)."""
    domain_ids = [p["id"] for p in products if p["tier"] == "domain"]
    support_ids = [p["id"] for p in products if p["tier"] == "support"]
    rows = []
    sub_id = 0

    def add(member_idx, product_id, qty, start_idx, churn_p):
        nonlocal sub_id
        sub_id += 1
        e = enroll_month[member_idx]
        floor_idx = e if enroll_day[member_idx] == 1 else e + 1
        start_idx = max(min(start_idx, ENROLL_MONTH_COUNT - 1), floor_idx)
        cancel = ""
        if rng.random() < churn_p:
            cancel_idx = rng.randint(start_idx + 1, ENROLL_MONTH_COUNT + 3)
            cancel = month_first(cancel_idx)
        rows.append({"id": sub_id, "member_id": member_idx + 1,
                     "product_id": product_id, "quantity": qty,
                     "start_month": month_first(start_idx),
                     "cancel_month": cancel})

    for i in range(N_MEMBERS):
        kind = archetype[i]
        if kind == "seller":
            continue   # zero personal spend; their customers carry them
        e = enroll_month[i]
        churn_p = CHURN_P[kind]
        first_start = e if rng.random() < 0.85 else e + 1

        if kind == "starter":
            add(i, support_ids[rng.randrange(6)], 1, first_start, churn_p)

        elif kind == "standard":
            first_domain = rng.random() < 0.72
            add(i, (domain_ids if first_domain else support_ids)[rng.randrange(6)],
                1, first_start, churn_p)
            if rng.random() < 0.46:   # upgrade: a second agent later
                add(i, (domain_ids if rng.random() < 0.5 else support_ids)[rng.randrange(6)],
                    1, e + rng.randint(0, 6), churn_p)
            if rng.random() < 0.15:   # a third
                add(i, (domain_ids if rng.random() < 0.5 else support_ids)[rng.randrange(6)],
                    1, e + rng.randint(1, 8), churn_p)

        elif kind == "builder":
            add(i, domain_ids[rng.randrange(6)], 1, first_start, churn_p)
            add(i, (domain_ids if rng.random() < 0.5 else support_ids)[rng.randrange(6)],
                1, first_start, churn_p)
            for _ in range(rng.randint(1, 3)):   # upgrades over time
                add(i, (domain_ids if rng.random() < 0.6 else support_ids)[rng.randrange(6)],
                    1, e + rng.randint(1, 10), churn_p)

        else:  # whale: 10 or more agents
            total = 0
            qtys = []
            for pid in domain_ids:
                q = rng.randint(1, 3)
                qtys.append((pid, q))
                total += q
            n_support = rng.randint(3, 6)
            for pid in rng.sample(support_ids, n_support):
                q = rng.randint(1, 2)
                qtys.append((pid, q))
                total += q
            if total < 10:
                pid, q = qtys[0]
                qtys[0] = (pid, q + (10 - total))
            for pid, q in qtys:
                add(i, pid, q, e + rng.randint(0, 2), churn_p)

    return rows


def close_dormant_accounts(members, subscriptions):
    """Mark a member 'closed' when every subscription is cancelled early
    (cancel on or before 2026-05-01). Account status is distinct from
    monthly activity; this only flags clearly departed accounts."""
    cutoff = month_first(21)  # 2026-05-01
    by_member = {}
    for s in subscriptions:
        by_member.setdefault(s["member_id"], []).append(s)
    closed = 0
    for m in members:
        subs = by_member.get(m["id"], [])
        if subs and all(s["cancel_month"] and s["cancel_month"] <= cutoff
                        for s in subs):
            m["status"] = "closed"
            closed += 1
    return closed


def build_customers(rng, members, enroll_month, enroll_day, archetype, products):
    """Customer accounts and their subscriptions (generator v3, spec v1.2).

    Customers attach to ONE referring member and never join the genealogy.
    Roughly 35 to 50 percent of active non-seller distributors hold 1 to 4
    customers (a few outliers hold more). Sellers hold exactly 2 or 3
    customers with one 50-point support agent each: qualification resting
    entirely on volume sold. A customer never enrolls before their referring
    member, and customer subscription starts are clamped by the enrollment
    plausibility rule using the CUSTOMER's enrolled_on. Customer
    subscriptions stay internal to the generator; only customers and their
    generated orders are exported."""
    domain_ids = [p["id"] for p in products if p["tier"] == "domain"]
    support_ids = [p["id"] for p in products if p["tier"] == "support"]
    customers, cust_subs = [], []
    cid = 0

    def add_customer(member_idx, enroll_cap):
        nonlocal cid
        cid += 1
        first = FIRST_NAMES[rng.randrange(len(FIRST_NAMES))]
        last = LAST_NAMES[rng.randrange(len(LAST_NAMES))]
        em = rng.randint(enroll_month[member_idx], enroll_cap)
        lo_day = enroll_day[member_idx] if em == enroll_month[member_idx] else 1
        day = rng.randint(lo_day, days_in(em))
        customers.append({
            "id": cid,
            "customer_code": f"OC-{cid:06d}",
            "display_name": f"{first} {last}",
            "email": f"{first.lower()}.{last.lower()}.c{cid}@example.com",
            "referring_member_id": member_idx + 1,
            "enrolled_on": date_in_month(em, day),
            "status": "active",  # may flip to closed after churn is known
        })
        return cid, (em if day == 1 else em + 1)   # id, plausibility floor

    def add_cust_sub(customer_id, member_idx, product_id, start_idx, churn_p):
        start_idx = min(start_idx, ENROLL_MONTH_COUNT)
        cancel = ""
        if rng.random() < churn_p:
            cancel_idx = rng.randint(start_idx + 1, ENROLL_MONTH_COUNT + 3)
            cancel = month_first(cancel_idx)
        cust_subs.append({"customer_id": customer_id,
                          "member_id": member_idx + 1,
                          "product_id": product_id, "quantity": 1,
                          "start_month": month_first(start_idx),
                          "cancel_month": cancel})

    for i in range(N_MEMBERS):
        if archetype[i] == "seller":
            n = 2 if rng.random() < 0.75 else 3
            for _ in range(n):
                c, floor_idx = add_customer(i, SELLER_CUSTOMER_ENROLL_CAP)
                add_cust_sub(c, i, support_ids[rng.randrange(6)],
                             floor_idx, SELLER_CUSTOMER_CHURN_P)
        elif members[i]["status"] == "active" and rng.random() < P_HAS_CUSTOMERS:
            if rng.random() < 0.03:
                n = rng.randint(5, 8)                    # outliers
            else:
                n = rng.choices([1, 2, 3, 4], weights=[46, 30, 16, 8], k=1)[0]
            for _ in range(n):
                c, floor_idx = add_customer(i, ENROLL_MONTH_COUNT - 1)
                n_subs = 1 if rng.random() < 0.70 else 2
                for k in range(n_subs):
                    pool = support_ids if rng.random() < 0.60 else domain_ids
                    start = floor_idx if k == 0 else floor_idx + rng.randint(0, 2)
                    add_cust_sub(c, i, pool[rng.randrange(6)], start,
                                 CUSTOMER_CHURN_P)
    return customers, cust_subs


def close_dormant_customers(customers, cust_subs):
    """Mirror of close_dormant_accounts for customer accounts."""
    cutoff = month_first(21)  # 2026-05-01
    by_cust = {}
    for s in cust_subs:
        by_cust.setdefault(s["customer_id"], []).append(s)
    closed = 0
    for c in customers:
        subs = by_cust.get(c["id"], [])
        if subs and all(s["cancel_month"] and s["cancel_month"] <= cutoff
                        for s in subs):
            c["status"] = "closed"
            closed += 1
    return closed


def build_orders(subscriptions, cust_subs, products):
    """One order per active subscription per history month, dated the first.

    Member subscriptions book as buyer_role 'member' with customer_id null.
    Customer subscriptions book onto the REFERRING member's account as
    buyer_role 'retail_customer' with customer_id = the actual buyer: the
    attribution rule (schema spec v1.2). The commission engine aggregates
    account volume and never needs to know customers exist."""
    price = {p["id"]: p["price"] for p in products}
    volume = {p["id"]: p["volume_points"] for p in products}
    orders, lines = [], []
    oid = lid = 0

    def emit(member_id, product_id, quantity, first, buyer_role, customer_id):
        nonlocal oid, lid
        oid += 1
        orders.append({"id": oid, "member_id": member_id,
                       "buyer_role": buyer_role, "customer_id": customer_id,
                       "ordered_at": f"{first} 00:00:00+00",
                       "volume_month": first, "status": "completed"})
        lid += 1
        lines.append({"id": lid, "order_id": oid,
                      "product_id": product_id, "quantity": quantity,
                      "unit_price": price[product_id],
                      "unit_volume": volume[product_id]})

    def active(s, first):
        if s["start_month"] > first:
            return False
        if s["cancel_month"] and s["cancel_month"] <= first:
            return False
        return True

    for m in range(HISTORY_FIRST_MONTH, HISTORY_LAST_MONTH + 1):
        first = month_first(m)
        for s in subscriptions:
            if active(s, first):
                emit(s["member_id"], s["product_id"], s["quantity"], first,
                     "member", "")
        for s in cust_subs:
            if active(s, first):
                emit(s["member_id"], s["product_id"], s["quantity"], first,
                     "retail_customer", s["customer_id"])
    return orders, lines


# ---------------------------------------------------------------------------
# Worked example (COMP-PLAN-SPEC v1.1 section 7): the acceptance dataset
# ---------------------------------------------------------------------------
WE_MONTH = "2026-07-01"
WE_TREE = {  # member -> sponsor (None = root)
    "M1": None, "M2": "M1", "M3": "M1", "M4": "M1", "M5": "M2", "M6": "M2",
    "M7": "M3", "M8": "M3", "M9": "M5", "M10": "M8",
}
# member -> list of holdings. A holding is (sku, quantity) when the member
# holds it personally, or (sku, quantity, customer_code) when one of the
# member's CUSTOMERS holds it (spec v1.2): the order still books onto the
# member's account (buyer_role 'retail_customer', customer_id set), so every
# expected number below is unchanged. That is the attribution rule's point.
WE_SUBS = {
    "M1": [("AGT-D-001", 1), ("AGT-D-003", 1)],                      # Payment + Pricing
    "M2": [("AGT-D-001", 1), ("AGT-S-001", 1)],                      # Payment + Software Engineer
    "M3": [("AGT-D-002", 1)],                                        # Shipping
    "M4": [("AGT-S-002", 1, "OC-000001"),                            # QA, held by customer C1
           ("AGT-S-003", 1, "OC-000002")],                           # Secretary, held by customer C2
    "M5": [("AGT-S-005", 1)],                                        # Accounting
    "M6": [("AGT-D-005", 1), ("AGT-S-006", 1)],                      # Marketing + Customer Care
    "M7": [(f"AGT-D-{i:03d}", 2) for i in range(1, 7)]               # 12 domain
          + [(f"AGT-S-{i:03d}", 1) for i in range(1, 7)],            # + 6 support
    "M8": [("AGT-S-001", 1), ("AGT-S-005", 1)],                      # Software Engineer + Accounting
    "M9": [("AGT-D-001", 1), ("AGT-D-002", 1), ("AGT-D-003", 1)],    # 3 domain
    "M10": [("AGT-S-003", 1)],                                       # Secretary
}
# Customers of the worked example (spec v1.2 section 7.1, the M4 note):
# id, customer_code, label, referring member
WE_CUSTOMERS = [
    (1, "OC-000001", "C1", "M4"),
    (2, "OC-000002", "C2", "M4"),
]
# Expected per-member results, straight from spec section 7.1 / 7.2 / 7.4
WE_EXPECTED_RESULTS = [
    # member, sv, cv, qualified, tv, rank, paid_depth, total_earned
    ("M1", "200.00", "160.00", "true", "2500.00", "leader", 3, "114.00"),
    ("M2", "150.00", "120.00", "true", "500.00", "member", 1, "16.00"),
    ("M3", "100.00", "80.00", "true", "1650.00", "builder", 2, "130.00"),
    ("M4", "100.00", "80.00", "true", "0.00", "member", 1, "0.00"),
    ("M5", "50.00", "40.00", "false", "300.00", "member", 1, "0.00"),
    ("M6", "150.00", "120.00", "true", "0.00", "member", 1, "0.00"),
    ("M7", "1500.00", "1200.00", "true", "0.00", "member", 1, "0.00"),
    ("M8", "100.00", "80.00", "true", "50.00", "member", 1, "4.00"),
    ("M9", "300.00", "240.00", "true", "0.00", "member", 1, "0.00"),
    ("M10", "50.00", "40.00", "false", "0.00", "member", 1, "0.00"),
]
# Expected commission lines, straight from spec section 7.3
WE_EXPECTED_LINES = [
    # earner, source, level, source_cv, rate, amount
    ("M1", "M2", 1, "120.00", "0.1000", "12.00"),
    ("M1", "M3", 1, "80.00", "0.1000", "8.00"),
    ("M1", "M4", 1, "80.00", "0.1000", "8.00"),
    ("M1", "M5", 2, "40.00", "0.0500", "2.00"),
    ("M1", "M6", 2, "120.00", "0.0500", "6.00"),
    ("M1", "M7", 2, "1200.00", "0.0500", "60.00"),
    ("M1", "M8", 2, "80.00", "0.0500", "4.00"),
    ("M1", "M9", 3, "240.00", "0.0500", "12.00"),
    ("M1", "M10", 3, "40.00", "0.0500", "2.00"),
    ("M2", "M5", 1, "40.00", "0.1000", "4.00"),
    ("M2", "M6", 1, "120.00", "0.1000", "12.00"),
    ("M3", "M7", 1, "1200.00", "0.1000", "120.00"),
    ("M3", "M8", 1, "80.00", "0.1000", "8.00"),
    ("M3", "M10", 2, "40.00", "0.0500", "2.00"),
    ("M8", "M10", 1, "40.00", "0.1000", "4.00"),
]
WE_EXPECTED_COMPANY = [("2026-07-01", "2700.00", "2160.00", "264.00", 4)]


def build_worked_example(products):
    sku_to_id = {p["sku"]: p["id"] for p in products}
    price = {p["id"]: p["price"] for p in products}
    volume = {p["id"]: p["volume_points"] for p in products}
    codes = list(WE_TREE.keys())            # M1..M10 in declaration order
    code_to_id = {c: i + 1 for i, c in enumerate(codes)}

    members = []
    for c in codes:
        s = WE_TREE[c]
        members.append({"id": code_to_id[c], "member_code": c,
                        "display_name": f"Worked Example {c}",
                        "email": f"{c.lower()}@example.com",
                        "sponsor_id": "" if s is None else code_to_id[s],
                        "enrolled_on": "2026-01-01", "status": "active"})

    customers = []
    cust_code_to_id = {}
    for cid, ccode, label, ref in WE_CUSTOMERS:
        cust_code_to_id[ccode] = cid
        customers.append({"id": cid, "customer_code": ccode,
                          "display_name": f"Worked Example {label}",
                          "email": f"{label.lower()}@example.com",
                          "referring_member_id": code_to_id[ref],
                          "enrolled_on": "2026-01-01", "status": "active"})

    subs, orders, lines = [], [], []
    sid = oid = lid = 0
    for c in codes:
        for holding in WE_SUBS[c]:
            sku, qty = holding[0], holding[1]
            cust_code = holding[2] if len(holding) > 2 else None
            pid = sku_to_id[sku]
            if cust_code is None:
                # member-held: a real row in the subscriptions table
                sid += 1
                subs.append({"id": sid, "member_id": code_to_id[c],
                             "product_id": pid, "quantity": qty,
                             "start_month": WE_MONTH, "cancel_month": ""})
            oid += 1
            orders.append({"id": oid, "member_id": code_to_id[c],
                           "buyer_role": ("member" if cust_code is None
                                          else "retail_customer"),
                           "customer_id": ("" if cust_code is None
                                           else cust_code_to_id[cust_code]),
                           "ordered_at": f"{WE_MONTH} 00:00:00+00",
                           "volume_month": WE_MONTH, "status": "completed"})
            lid += 1
            lines.append({"id": lid, "order_id": oid, "product_id": pid,
                          "quantity": qty, "unit_price": price[pid],
                          "unit_volume": volume[pid]})
    return members, customers, subs, orders, lines


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------
def write_csv(path, fieldnames, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow(r)


def sql_lit(value):
    if value == "" or value is None:
        return "null"
    if isinstance(value, int):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def insert_block(out, table, columns, rows, value_fn, batch=500):
    for start in range(0, len(rows), batch):
        chunk = rows[start:start + batch]
        out.write(f"insert into {table} ({', '.join(columns)}) "
                  "overriding system value values\n")
        vals = [f"({', '.join(value_fn(r))})" for r in chunk]
        out.write(",\n".join(vals))
        out.write(";\n\n")


def write_loader(path, title, products, members, customers, subs, orders, lines):
    out = io.StringIO()
    out.write(f"-- {title}\n")
    out.write(f"-- Generated by generate_seed.py, seed = {SEED}. Do not hand-edit;\n")
    out.write("-- rerun the generator instead. Requires migrations 001..007 applied.\n")
    out.write("-- Run as the service role (or database owner); RLS blocks anon writes.\n\n")
    out.write("begin;\n\n")

    insert_block(out, "app.products",
                 ["id", "sku", "name", "tier", "price", "volume_points",
                  "commissionable_value"],
                 products,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["sku"]), sql_lit(r["name"]),
                            sql_lit(r["tier"]), r["price"], r["volume_points"],
                            "null"])

    insert_block(out, "app.members",
                 ["id", "member_code", "display_name", "email", "sponsor_id",
                  "enrolled_on", "status"],
                 members,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["member_code"]),
                            sql_lit(r["display_name"]), sql_lit(r["email"]),
                            sql_lit(r["sponsor_id"]) if r["sponsor_id"] != "" else "null",
                            f"date {sql_lit(r['enrolled_on'])}", sql_lit(r["status"])])

    insert_block(out, "app.customers",
                 ["id", "customer_code", "display_name", "email",
                  "referring_member_id", "enrolled_on", "status"],
                 customers,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["customer_code"]),
                            sql_lit(r["display_name"]), sql_lit(r["email"]),
                            sql_lit(r["referring_member_id"]),
                            f"date {sql_lit(r['enrolled_on'])}",
                            sql_lit(r["status"])])

    insert_block(out, "app.subscriptions",
                 ["id", "member_id", "product_id", "quantity", "start_month",
                  "cancel_month"],
                 subs,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["member_id"]),
                            sql_lit(r["product_id"]), sql_lit(r["quantity"]),
                            f"date {sql_lit(r['start_month'])}",
                            "null" if r["cancel_month"] == "" else f"date {sql_lit(r['cancel_month'])}"])

    insert_block(out, "app.orders",
                 ["id", "member_id", "buyer_role", "customer_id", "ordered_at",
                  "volume_month", "status"],
                 orders,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["member_id"]),
                            sql_lit(r["buyer_role"]),
                            "null" if r["customer_id"] == "" else sql_lit(r["customer_id"]),
                            f"timestamptz {sql_lit(r['ordered_at'])}",
                            f"date {sql_lit(r['volume_month'])}",
                            sql_lit(r["status"])])

    insert_block(out, "app.order_lines",
                 ["id", "order_id", "product_id", "quantity", "unit_price",
                  "unit_volume"],
                 lines,
                 lambda r: [sql_lit(r["id"]), sql_lit(r["order_id"]),
                            sql_lit(r["product_id"]), sql_lit(r["quantity"]),
                            r["unit_price"], r["unit_volume"]])

    out.write("-- Re-align identity sequences with the explicit ids above.\n")
    for t in ["products", "members", "customers", "subscriptions", "orders",
              "order_lines"]:
        out.write(f"select setval(pg_get_serial_sequence('app.{t}', 'id'), "
                  f"(select max(id) from app.{t}));\n")
    out.write("\ncommit;\n")

    with open(path, "w", newline="", encoding="utf-8") as f:
        f.write(out.getvalue())


def sha256_of(path):
    h = hashlib.sha256()
    h.update(Path(path).read_bytes())
    return h.hexdigest()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rng = random.Random(SEED)

    products = build_products()
    members, enroll_month, enroll_day, depth, children, supers = build_members(rng)
    archetype = assign_archetypes(rng, enroll_month, supers)
    subs = build_subscriptions(rng, enroll_month, enroll_day, archetype, products)
    closed = close_dormant_accounts(members, subs)
    customers, cust_subs = build_customers(rng, members, enroll_month,
                                           enroll_day, archetype, products)
    closed_customers = close_dormant_customers(customers, cust_subs)
    orders, lines = build_orders(subs, cust_subs, products)

    # Main pack
    write_csv(OUT_DIR / "products.csv",
              ["id", "sku", "name", "tier", "price", "volume_points",
               "commissionable_value"], products)
    write_csv(OUT_DIR / "members.csv",
              ["id", "member_code", "display_name", "email", "sponsor_id",
               "enrolled_on", "status"], members)
    write_csv(OUT_DIR / "customers.csv",
              ["id", "customer_code", "display_name", "email",
               "referring_member_id", "enrolled_on", "status"], customers)
    write_csv(OUT_DIR / "subscriptions.csv",
              ["id", "member_id", "product_id", "quantity", "start_month",
               "cancel_month"], subs)
    write_csv(OUT_DIR / "orders.csv",
              ["id", "member_id", "buyer_role", "customer_id", "ordered_at",
               "volume_month", "status"], orders)
    write_csv(OUT_DIR / "order_lines.csv",
              ["id", "order_id", "product_id", "quantity", "unit_price",
               "unit_volume"], lines)
    write_loader(OUT_DIR / "load_seed.sql",
                 "MLM Pilot seed loader: 12 products, 1,000 members, "
                 "customers, subscriptions, 6 months of orders",
                 products, members, customers, subs, orders, lines)

    # Worked example (acceptance dataset)
    (we_members, we_customers, we_subs, we_orders,
     we_lines) = build_worked_example(products)
    write_csv(OUT_DIR / "worked_example_members.csv",
              ["id", "member_code", "display_name", "email", "sponsor_id",
               "enrolled_on", "status"], we_members)
    write_csv(OUT_DIR / "worked_example_customers.csv",
              ["id", "customer_code", "display_name", "email",
               "referring_member_id", "enrolled_on", "status"], we_customers)
    write_csv(OUT_DIR / "worked_example_subscriptions.csv",
              ["id", "member_id", "product_id", "quantity", "start_month",
               "cancel_month"], we_subs)
    write_csv(OUT_DIR / "worked_example_orders.csv",
              ["id", "member_id", "buyer_role", "customer_id", "ordered_at",
               "volume_month", "status"], we_orders)
    write_csv(OUT_DIR / "worked_example_order_lines.csv",
              ["id", "order_id", "product_id", "quantity", "unit_price",
               "unit_volume"], we_lines)
    write_csv(OUT_DIR / "worked_example_expected_member_results.csv",
              ["member_code", "sv", "cv", "qualified", "tv", "rank_earned",
               "paid_depth", "total_earned"],
              [dict(zip(["member_code", "sv", "cv", "qualified", "tv",
                         "rank_earned", "paid_depth", "total_earned"], r))
               for r in WE_EXPECTED_RESULTS])
    write_csv(OUT_DIR / "worked_example_expected_commission_lines.csv",
              ["earner_code", "source_code", "level", "source_cv", "rate",
               "amount"],
              [dict(zip(["earner_code", "source_code", "level", "source_cv",
                         "rate", "amount"], r)) for r in WE_EXPECTED_LINES])
    write_csv(OUT_DIR / "worked_example_expected_company.csv",
              ["period", "total_sv", "total_cv", "total_payout", "members_paid"],
              [dict(zip(["period", "total_sv", "total_cv", "total_payout",
                         "members_paid"], r)) for r in WE_EXPECTED_COMPANY])
    write_loader(OUT_DIR / "load_worked_example.sql",
                 "MLM Pilot ACCEPTANCE loader: COMP-PLAN-SPEC v1.2 section 7 "
                 "worked example. Load into an EMPTY database only (ids start "
                 "at 1 and would collide with the main pack).",
                 products, we_members, we_customers, we_subs, we_orders,
                 we_lines)

    # Manifest (deterministic: no wall-clock values)
    csv_files = ["products.csv", "members.csv", "customers.csv",
                 "subscriptions.csv",
                 "orders.csv", "order_lines.csv", "load_seed.sql",
                 "worked_example_members.csv", "worked_example_customers.csv",
                 "worked_example_subscriptions.csv",
                 "worked_example_orders.csv", "worked_example_order_lines.csv",
                 "worked_example_expected_member_results.csv",
                 "worked_example_expected_commission_lines.csv",
                 "worked_example_expected_company.csv",
                 "load_worked_example.sql"]
    kinds = {k: sum(1 for i in archetype if archetype[i] == k)
             for k in ("starter", "standard", "builder", "whale", "seller")}
    with open(OUT_DIR / "_manifest.txt", "w", newline="", encoding="utf-8") as f:
        f.write("MLM Pilot seed manifest (generate_seed.py, generator v3, "
                "customer accounts + enrollment plausibility rule)\n")
        f.write(f"seed = {SEED}\n")
        f.write(f"members = {len(members)} (closed accounts: {closed})\n")
        f.write(f"customers = {len(customers)} "
                f"(closed accounts: {closed_customers})\n")
        f.write(f"archetypes = {kinds}\n")
        f.write(f"max tree depth = {max(depth)}\n")
        f.write(f"subscriptions = {len(subs)} (member-held; customer "
                f"subscriptions are internal to the generator)\n")
        f.write(f"orders = {len(orders)}\n")
        f.write(f"order_lines = {len(lines)}\n")
        f.write(f"history months = {month_first(HISTORY_FIRST_MONTH)} .. "
                f"{month_first(HISTORY_LAST_MONTH)}\n")
        f.write("Rerunning the generator with this seed regenerates every file "
                "below byte for byte.\n\n")
        f.write("sha256 per file:\n")
        for name in csv_files:
            f.write(f"  {sha256_of(OUT_DIR / name)}  {name}\n")

    print(f"seed = {SEED}")
    print(f"members = {len(members)} (closed: {closed})")
    print(f"customers = {len(customers)} (closed: {closed_customers})")
    print(f"archetypes = {kinds}")
    print(f"distributors with customers = "
          f"{len(set(c['referring_member_id'] for c in customers))}")
    print(f"max depth = {max(depth)}")
    print(f"top frontlines = {sorted(children, reverse=True)[:10]}")
    print(f"subscriptions = {len(subs)} member-held; "
          f"customer subscriptions (internal) = {len(cust_subs)}")
    print(f"orders = {len(orders)}; order_lines = {len(lines)}")
    print(f"output -> {OUT_DIR}")


if __name__ == "__main__":
    main()
