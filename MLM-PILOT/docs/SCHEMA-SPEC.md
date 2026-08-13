# MLM Pilot Schema Specification

As of 2026-08-13. Author: architect role (written inline by the main session after
repeated server outages killed the agent runs; content follows the architect brief).
Builder: mlm-db-engineer implements EXACTLY this; ambiguities go back to the architect,
never improvised. Graded by mlm-verifier and mlm-qa.

Acronym key: Multi-Level Marketing (MLM), Sales Volume (SV), Commissionable Volume (CV),
Team Volume (TV), Row-Level Security (RLS), Common Table Expression (CTE),
Primary Key (PK), Foreign Key (FK).

Design target: 1,000 members seeded, every choice must still work at 100,000.

## 1. Tables

All tables live in schema `app` (not `public`), RLS ON from the first migration.
The public demo NEVER touches tables; it reads only the views in section 3.

### app.members
| Column | Type | Rules |
|---|---|---|
| id | bigint generated always as identity | PK |
| member_code | text | unique, not null; public-safe handle like "GW-000123"; the ONLY identifier views expose |
| display_name | text | not null; synthetic name |
| email | text | not null; synthetic, always @example.com; NEVER exposed by any view |
| sponsor_id | bigint | FK to app.members(id); null ONLY for the root member(s) |
| enrolled_on | date | not null |
| status | text | check in ('active','closed'); account status, distinct from monthly activity |

Indexes: unique (member_code); index (sponsor_id). The sponsor_id adjacency IS the
genealogy (see decision document 2026-08-13-genealogy-representation.md).
Constraint: a trigger rejects cycles (walking up from sponsor must reach a root).

### app.products
The catalog is DIGITAL AI AGENTS sold as monthly subscriptions (comp plan spec
section 1): domain agents at $100.00 / 100 volume points (Payment Agent, Shipping
Agent, Pricing Agent, ...), support agents at $50.00 / 50 volume points (Software
Engineer, Quality Assurance, Secretary, ...). PV equals dollars one to one in v1.

| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| sku | text | unique, not null |
| name | text | not null |
| tier | text | check in ('domain','support') |
| price | numeric(10,2) | not null; what the buyer pays |
| volume_points | numeric(10,2) | not null; drives SV and rank |
| commissionable_value | numeric(10,2) | null in v1 (forward compatibility: the price / volume points / commissionable value triple stays independent; v1 computes CV as 80 percent of SV at member-month level instead) |

### app.customers (added v1.2, 2026-08-13: customer accounts per Howard)
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| customer_code | text | unique, not null; public-safe handle like "OC-000123" |
| display_name | text | not null; synthetic |
| email | text | not null; synthetic @example.com; NEVER exposed by any view |
| referring_member_id | bigint | FK app.members(id), not null; the distributor this customer buys through |
| enrolled_on | date | not null |
| status | text | check in ('active','closed') |

Customers are NOT members: they never appear in the genealogy, never qualify, never
hold rank, never earn. Their purchases exist to roll volume up to their referring
member (see orders below). Index: (referring_member_id). Ships as migration 007.

### app.subscriptions (added in spec update, same day: the product is SaaS)
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| member_id | bigint | FK members, not null |
| product_id | bigint | FK products, not null |
| quantity | integer | not null, check > 0, default 1 |
| start_month | date | not null; first of month the subscription begins billing |
| cancel_month | date | null while active; first of month it STOPS billing (exclusive end) |

One row per member-agent subscription. On the first day of each month, every
subscription where start_month <= month < cancel_month (or cancel_month is null)
generates exactly one order (below) for that volume month. In v1 the SEED performs
this generation when it fabricates history; the engine and site only ever read the
generated orders. Index: (member_id).

### app.orders
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| member_id | bigint | FK members, not null |
| buyer_role | text | check in ('member','preferred_customer','retail_customer'); default 'member'. ACTIVE from v1.2: 'retail_customer' marks a customer purchase |
| customer_id | bigint | null; FK app.customers(id) (added v1.2, migration 007). THE ATTRIBUTION RULE: a customer's order is booked with member_id = the REFERRING MEMBER's account (volume rolls up at purchase time) and customer_id = the actual buyer (the receipt stays auditable). CHECK: (buyer_role = 'retail_customer') = (customer_id IS NOT NULL). The commission engine needs NO knowledge of customers: it aggregates account volume exactly as before |
| ordered_at | timestamptz | not null |
| volume_month | date | not null; always the FIRST day of the month the order counts toward; stamped at creation from ordered_at in Coordinated Universal Time (UTC); never recomputed later |
| status | text | check in ('completed','refunded'); v1 seeds only 'completed' |

Indexes: (member_id, volume_month); (volume_month).

### app.order_lines
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| order_id | bigint | FK orders, not null |
| product_id | bigint | FK products, not null |
| quantity | integer | not null, check > 0 |
| unit_price | numeric(10,2) | not null; copied from product at order time |
| unit_volume | numeric(10,2) | not null; copied from product at order time |

Line SV = quantity times unit_volume. Copies make history immutable when catalog prices
change later.

### app.ranks
| Column | Type | Rules |
|---|---|---|
| rank_code | text | PK: 'member','builder','leader','director','executive' |
| rank_name | text | display name |
| sort_order | int | member=1 ... executive=5 |
| paid_depth | int | 1,2,3,4,5 respectively |

Qualification RULES live in the comp plan specification and the engine, not in data,
so the spec version pins them.

### app.commission_runs
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| period | date | first day of the paid month |
| spec_version | text | not null, 'v1.0' for this spec |
| status | text | check in ('running','final','superseded') |
| started_at / finished_at | timestamptz | |
| notes | text | free text: why the run exists |
| total_sv / total_cv / total_payout | numeric(14,2) | written at finish |
| members_paid | int | written at finish |

A rerun of the same period is a NEW row; the old run flips to 'superseded', its lines
untouched. Unique partial index: only one run per period may be 'final'.

### app.run_member_results (one row per member per run)
| Column | Type | Rules |
|---|---|---|
| run_id | bigint | FK commission_runs; PK (run_id, member_id) |
| member_id | bigint | FK members |
| sv | numeric(12,2) | that month's personal sales volume |
| cv | numeric(12,2) | round half up (0.80 times sv, 2 decimals) |
| tv | numeric(14,2) | subtree SV, exclusive of self (comp plan spec section 2) |
| is_active | boolean | sv >= 50 |
| rank_earned | text | FK ranks |
| paid_depth | int | copied from rank at run time |
| total_earned | numeric(12,2) | sum of the member's lines in this run |
| cumulative_sv | numeric(14,2) | reserved, null in v1 (forward compatibility for cross-month state) |

### app.commission_lines (the statement)
| Column | Type | Rules |
|---|---|---|
| id | bigint identity | PK |
| run_id | bigint | FK commission_runs, not null |
| earner_id | bigint | FK members, not null |
| source_member_id | bigint | FK members, not null |
| level | int | tree distance earner to source, 1..5 |
| source_cv | numeric(12,2) | the source member's CV that month |
| rate | numeric(5,4) | 0.1000 / 0.0500 / 0.0500 / 0.0300 / 0.0200 |
| amount | numeric(12,2) | round half up (rate times source_cv, 2 decimals) |
| payout_type | text | 'unilevel_level_pay' in v1 (forward compatibility: multiple payout types per run in v2) |

Index: (run_id, earner_id). IMMUTABILITY: triggers reject INSERT, UPDATE, and DELETE
on commission_lines and run_member_results whenever the referenced run's status is
'final' (the INSERT check validates NEW.run_id), so a finalized statement can neither
change, shrink, NOR silently grow. (Spec corrected 2026-08-13 after the verifier gate
caught that the original wording allowed INSERT; migration update due before Phase 3.)

## 2. Row-Level Security intent

- Every app.* table: RLS enabled, NO policy for anon or authenticated roles. Result:
  the published anon key can read NOTHING from tables.
- Writes happen only through the service role (seed loader, comp engine) which bypasses
  RLS by design and never ships to the browser.
- The demo site reads ONLY the views below. Views are created with
  security_invoker = false owned by a dedicated read-only definer role that has SELECT
  on the underlying tables, and anon gets SELECT on the views only. No view exposes
  email, internal id, or any column not listed.

## 3. Public demo views (the site's entire surface)

| View | Exposes |
|---|---|
| v_demo_members | member_code, display_name, enrolled_on, current rank_name (from the latest final run) |
| v_demo_tree | child member_code, sponsor member_code (edges only, public-safe codes) |
| v_demo_member_months | member_code, period, sv, cv, tv, is_active, rank_earned (from final runs) |
| v_demo_statements | period, earner member_code, level, source member_code, source_cv, rate, amount |
| v_demo_company | per final run: period, total_sv, total_cv, total_payout, members_paid, rank distribution counts |
| v_demo_customers (v1.2) | customer_code, display_name, referring member_code, enrolled_on |
| v_demo_customer_volume (v1.2) | member_code, volume_month, customer_sv (the slice of that member's SV that came from customer purchases; computed from orders where buyer_role = 'retail_customer') |

Every view filters to runs with status 'final'. The site footer's data-basis line reads
from v_demo_company (period + run id).

## 4. Forward compatibility (informed by published industry plans, generic here)

1. Orders carry buyer_role so customer-versus-member volume streams can split in v2.
2. Products carry the independent triple (price, volume_points, commissionable_value);
   v1 leaves the third null and derives CV at 80 percent, so a per-product CV never
   requires a schema change.
3. run_member_results reserves cumulative_sv for cross-month state (bonus tiers keyed
   to lifetime volume).
4. The genealogy walk (decision document) supports both level walks (stop counting at
   plain distance) and generation walks (stop at first member holding a given rank),
   so richer payout types drop in without new structures.
5. commission_lines.payout_type enumerates; v2 adds types without altering the table.

## 5. Scale notes (100,000 members)

- Recursive CTE over an indexed sponsor_id adjacency handles a 100,000-row tree in
  well under a second in Postgres; the comp engine materializes each run's level map
  once per run (see decision document), so page loads never walk the tree.
- All money and volume columns numeric, never float.
- Rollups are run-scoped rows, not global mutable state: reruns never contend.
