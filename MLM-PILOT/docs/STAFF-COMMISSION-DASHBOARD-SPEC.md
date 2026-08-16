# Staff Commission Dashboard Specification, version 1.0

As of 2026-08-16. Author: mlm-architect. Ruled by Howard the same day: "we
should build a dashboard in the staff area for commission." This is a STAFF
surface reading the REAL compensation engine. It is fully separate from the
retry lab and from the subscription engine specification; it shares only the
staff sign-in and the Edge Function pattern that the future billing console
will also use.

Plain path:
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\STAFF-COMMISSION-DASHBOARD-SPEC.md`

## 1. Acronym key

| Short form | Spelled out |
|---|---|
| PV | Personal Volume |
| SV | Sales Volume |
| CV | Commissionable Volume |
| TV | Team Volume |
| QA | Quality Assurance |
| GUI | Graphical User Interface |
| JSON | JavaScript Object Notation |
| RLS | Row Level Security |
| IP | Internet Protocol address |

## 2. What it is

One staff page behind the existing staff sign-in (the demo-login session, the
same gate the refund screen and the future billing console use), rendering
five read-only panels over the real compensation tables. The dashboard
computes nothing the engine does not already compute; it is a window, never a
second engine, and it writes nothing, ever, with one carefully fenced
apparent exception (the projection, section 5, which also writes nothing that
survives).

## 3. The five panels

### 3.1 Runs board

Every FINALIZED month (February through July 2026 today; August joins after
its run). Per run row: period, run id, spec version, total SV, total CV,
total payout, members paid, finished timestamp, all read from
`app.commission_runs` where status is final. TOP MOVERS versus the prior
finalized period, defined deterministically so two implementations agree:
delta = this run's `total_earned` minus the prior final run's, per member,
members present in either run, ordered by absolute delta descending, ties by
member code ascending, limit 10. Drill into any run: its
`app.commission_lines` rows (earner code, source code, level, source CV,
rate, amount) and its `app.run_member_results` rows, page-sized, exactly the
figures the member statements already show.

### 3.2 Current month live

The open month (August 2026 at writing) as it accumulates: bridged volume so
far (completed `app.orders` rows in the open volume month, summed per member
and in total), HOUSE-RETAINED volume beside it (section 3.4's month slice, so
attributed and unattributed money are always seen together), count of bridged
orders, and the IF-RUN-TODAY PROJECTION of section 5.

**The normative labeling rule, binding on every rendering of a projection:**

1. A projection NEVER displays a run identifier, because it has none; every
   finalized figure on this dashboard displays its run id in a data-basis
   line. The presence or absence of a run id IS the machine-checkable tell.
2. Every projection block carries the literal banner text "WHAT-IF
   PROJECTION, not a statement. Computed <timestamp>. Numbers change as the
   month accumulates and are not payable." rendered in the warning visual
   treatment, never the neutral one.
3. A projection figure is never rendered on the same panel row as a
   finalized figure without both labels present.
4. Nothing from a projection is ever written, cached server-side, exported,
   or reachable by any member-facing surface.

### 3.3 Member drill

By member number (member code, the only member identifier this page ever
shows). Panels: current rank (latest final run), volumes and qualification
status for the open month (bridged SV so far against the 100.00 gate),
commission history across ALL final runs (period, rank, SV, CV, TV,
total earned), and a downline contribution summary: for the selected final
run, this member's `commission_lines` grouped by level (level, line count,
sum of amounts) plus active-leg count from the run's results. Superseded runs
appear in the drill only inside the section 3.5 trail, marked, never mixed
into history totals.

### 3.4 House ledger

GW-000 retained volume month by month from `app.house_retained_volume`:
period, slice count, retained PV total, running cumulative total, and the
month-over-month direction (the decision 4.7 health metric: this figure
should shrink as checkout attribution improves). States plainly on the
panel: retained volume is BOOKKEEPING, never a disbursement; no commission
run reads it; GW-000 appears nowhere else on the dashboard.

### 3.5 Superseded-run trail

For any period holding more than one run: the version chain, ordered by run
id, each with status, spec version, totals, and finished timestamp; old runs
render frozen with the visible superseded marker, the current final run
last. This is decision 4.3's rerun rule made visible, and it has REAL data
on day one: the six v1.2 runs (ids 1 through 6) superseded by the six v1.3
runs (ids 7 through 12), so the panel is testable now, not only after a
future refund rerun ever fires.

## 4. The data path, decided and argued

**Decision: one staff-gated, read-only Edge Function,
`commission-report`, in the `list-demo-orders` style, parameterized by
panel. No new public views.**

Argument:

1. **The public view surface must not widen.** The seven `v_demo_*` views
   are readable with the publishable key by design; that is what makes the
   portal a demonstration. This dashboard carries things the public surface
   deliberately does not: the house ledger, per-member commission history
   assembled across runs, movers deltas, and projections. Sealed-view
   variants would still live in schema `public` under the same key unless a
   second role plus per-view grants were invented, which is a new security
   surface for zero gain over the pattern that already exists.
2. **The staff gate must be server-side.** An Edge Function checks the staff
   session on EVERY call before touching data, exactly as `list-demo-orders`
   does; hiding a button is not a gate. Views cannot check a session.
3. **One function, one truth.** A single `commission-report` function with a
   `panel` parameter (`runs_board`, `current_month`, `member_drill`,
   `house_ledger`, `superseded_trail`, `projection`) keeps the final-run
   filtering, the labeling rule's data side (run id present or absent), and
   the member-code-only exposure rule in one reviewed place, rather than
   scattered across seven view definitions.
4. **Read-only is structural.** The function's Postgres role work is SELECT
   plus the section 5 fenced transaction; it calls no writer function, and
   `fn_finalize_run` is never reachable from it.

Requests and responses are JSON; the page is a static staff page in the
existing `www` staff area calling the function with the staff session token.

## 5. The projection, computed without writing anything

The engine's run machinery is insert-based (`fn_run_commission` writes the
level map, member results, and lines). A projection must produce today's
would-be numbers WITHOUT creating a run and without disturbing decision 4.3's
immutability discipline. Two candidate mechanisms, decided:

**Rejected: mirror-math read-only queries.** Re-implementing SV, CV, TV,
rank, and line math as dashboard SQL creates a THIRD implementation of the
plan (engine, verifier, dashboard), and the drift between independent
implementations is exactly what this project's worked-example discipline
exists to catch. A dashboard that can disagree with the engine is worse than
no projection.

**Decided: the transactional dry run.** The `commission-report` function,
for `panel = projection` only, opens one transaction on its direct Postgres
connection and, inside it: calls the REAL `app.fn_run_commission` for the
open period, SELECTs the aggregates it needs (company totals, members paid,
rank distribution, top would-be earners) into memory, then ROLLS BACK. The
rollback discards every inserted row; nothing survives, no run id is
consumed as a visible artifact (sequence gaps are harmless and invisible),
no finalized row was ever touchable (the engine cannot finalize, and
`fn_finalize_run` is never called), and the numbers are the engine's own,
zero drift by construction. Fencing rules, normative: the projection runs
ONLY against a period with no final run (the open month); the transaction
never contains any other statement; the function returns the captured
aggregates with the section 3.2 labeling fields and no run id; concurrency
is bounded by the projection rate limit below, and at this scale the
transaction is sub-second.

## 6. Rate limits and audit

Per the `_shared\edge.ts` pattern exactly: scope-prefixed salted IP hash
buckets in `app.demo_rate_events` (raw address never stored), the
refuse-and-do-not-count rule preserved. Scopes and budgets:

| Scope | Budget | Why |
|---|---|---|
| `commission-report` (all read panels) | 30 per minute | Ordinary browsing, drill clicks included |
| `commission-report-projection` | 6 per minute | The dry run is the one heavy call; a separate scope keeps projection hammering from starving the read panels, and the reverse |

Reads are not audited row-by-row (they change nothing); the function logs
one structured line per call (panel, staff username, duration) so usage is
visible without inventing a new ledger. If a write control is ever added to
this page, it audits to `app.demo_staff_actions` like every other staff
write, but version 1 has no write control.

## 7. What the page never shows

- No member personal data beyond what the portal already exposes: member
  code, display name, enrolled date, rank, volumes, statement lines. NEVER
  email addresses, NEVER street addresses (not even the synthetic ones),
  NEVER internal bigint identifiers.
- No payment or card data of any kind; this dashboard reads the
  compensation tables and `app.house_retained_volume` only, never
  `app.demo_orders`, never any credential or processor field.
- No lab data, ever. The retry lab and its simulated year live in a separate
  environment; this dashboard's function has no path to it, and no lab
  figure may ever render on a page that also renders real-engine figures.
- No projection anywhere member-facing, per labeling rule 4.

## 8. Worked example, hand-computed

Current-month panel, using the real recorded August figures from the bridge
commit of 2026-08-16: bridged SV so far 2,000.00 across 11 orders
(GW-000003 900.00, GW-000014 600.00, GW-000001 300.00, GW-000002 200.00);
house-retained August slice 3,050.00. The panel therefore shows bridged
2,000.00 and retained 3,050.00 side by side, and the member drill for
GW-000003 shows August SV 900.00, qualified (900.00 at or above 100.00).
Movers arithmetic, stated inputs: if member X earned 130.00 in the prior
final run and 114.00 in the selected run, delta is minus 16.00 and X ranks
by 16.00 absolute; a member absent from the prior run counts from 0.00.
These figures are the acceptance numbers for QA's first browser pass;
remeasure live before asserting, per the data model's measure-never-copy
rule.

## 9. Verification, both gates

**mlm-verifier (correctness gate):**

1. Recompute every runs-board row directly from `app.commission_runs` and
   drill lines from `app.commission_lines`; match to the cent.
2. Recompute the movers list for at least two adjacent final periods from
   `app.run_member_results` under the section 3.1 definition, including the
   tie and absent-member rules; match order and deltas exactly.
3. Recompute the current-month bridged SV and house slice from `app.orders`
   and `app.house_retained_volume`; match the panel.
4. Projection equivalence, the decisive test: in a controlled environment
   with inputs frozen, capture a projection, then run the real engine for
   the same period; every projected aggregate must equal the real run's to
   the cent. Then verify the projection left NOTHING behind: row counts of
   runs, results, lines, and level map identical before and after the
   projection call, and the six finalized runs' checksums unchanged (the
   established md5-over-ordered-row-images query).
5. Assert the labeling rule's data side: no projection response contains a
   run id; every finalized response does.
6. Probe the function for exposure: no email, no street address, no bigint
   member id in any response JSON for any panel and any parameter, and
   member-role or anonymous sessions refused on every panel.

**mlm-qa (acceptance gate, driven in the browser):**

1. Staff signs in and reaches the dashboard; a member-role account is
   refused server-side (the hiding-a-button-is-not-a-gate test).
2. All five panels render with live data; runs board shows the six final
   runs; drill into July matches the member portal's statement figures.
3. The superseded trail renders the runs 1 through 6 chain, frozen and
   marked, with runs 7 through 12 as the final word.
4. The projection renders with the exact banner text, warning treatment,
   timestamp, and no run id; refreshing after a new bridged order changes
   the projection, proving it is live.
5. House ledger months sum to the recorded retained totals and GW-000
   appears on no other panel.
6. The projection rate limit refuses the seventh call in a minute without
   counting it, and read panels remain responsive during the refusal.

## 10. Open questions for Howard, each with a recommended default

| # | Question | Recommended default, so nothing blocks |
|---|---|---|
| OQ1 | Movers list size and window: top 10 by absolute delta versus prior period only? | **Yes, 10, adjacent final periods only.** Longer windows are a member-drill job, not a board job. |
| OQ2 | Cache projections server-side for the rate window? | **No cache.** Compute on demand under the 6-per-minute scope; a cached projection is a stored projection, which rule 4 of the labeling rule forbids, and staleness questions are worse than sub-second recomputes at this scale. |
| OQ3 | Build now or after the August run? | **Now.** The superseded trail and runs board have real data today, and the current-month panel is most valuable BEFORE a month's first run, which is exactly now. |
| OQ4 | Export (spreadsheet download of a run's lines)? | **Not in version 1.** It is one more data egress path to review; add it as its own small change if Howard asks after using the drill. |
| OQ5 | Which roles may open it: admin and staff, or staff only? | **Admin and staff both**, member refused; matches every other staff surface. |

## 11. What this specification deliberately did not do

No production code and no SQL beyond naming the tables read; the builder
owns the function and page. No write controls of any kind in version 1. No
new tables, no new views, no schema change at all: the dashboard is a
reader of what exists, and the day it needs a table of its own is the day
this spec gets a versioned amendment, same-day, per this role's charter.
