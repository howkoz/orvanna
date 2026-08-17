/* ============================================================
   commission-report (Supabase Edge Function, Deno)

   THE STAFF COMMISSION DASHBOARD'S ONE DATA PATH.
   Spec: MLM-PILOT/docs/STAFF-COMMISSION-DASHBOARD-SPEC.md v1.0,
   which this file implements in full. Authored 2026-08-16 by
   mlm-site-builder; NOT DEPLOYED by the builder (gates first,
   then the deploy engineer ships with byte-compare).

   WHAT THIS IS. One staff-gated, READ-ONLY function, parameterized
   by panel (spec section 4, the decided data path). It is a window
   over the real compensation tables, never a second engine: every
   figure it returns is read from what app.fn_run_commission already
   wrote, or (for the projection, section 5) computed by that very
   function inside a transaction that is always rolled back.

   WHY ONE FUNCTION AND NOT VIEWS (spec 4, restated so nobody
   "simplifies" this later):
     1. The public view surface must not widen. The seven v_demo_*
        views are anon-readable by design; this dashboard carries
        things that surface deliberately does not (the house ledger,
        cross-run member history, movers, projections).
     2. The staff gate must be server-side. A view cannot check a
        session; this function checks it on EVERY call.
     3. One function keeps the final-run filtering, the projection
        labeling rule's data side, and the member-code-only exposure
        rule in ONE reviewed place.
     4. Read-only is structural: the only statements here are
        SELECTs, plus the single fenced transaction of the
        projection, and app.fn_finalize_run is never reachable.

   THE EXPOSURE BLACKLIST (spec section 7), binding on every panel:
     - member_code and display_name only; NEVER email, NEVER any
       street address, NEVER an internal bigint member id.
     - No payment or card data of any kind; this function reads the
       compensation tables, app.orders/app.order_lines (bridged
       volume), and app.house_retained_volume; it never touches
       app.demo_orders or any processor field.
     - No lab data; there is no code path to the retry lab here.
     - Projections are never cached, stored, or exported (labeling
       rule 4): this function computes them on demand and holds
       them only in this response.

   THE LABELING RULE'S DATA SIDE (spec 3.2): every finalized figure
   carries its run id; a projection response carries NO run id
   anywhere, plus projection: true, the literal banner text, and
   the computed-at timestamp. The presence or absence of a run id
   is the machine-checkable tell, and the verifier asserts it.

   RATE LIMITS (spec section 6), in app.demo_rate_events via the
   shared checkRateLimit, refuse-and-do-not-count preserved:
     scope "commission-report"             30 per minute (reads)
     scope "commission-report-projection"   6 per minute (dry run)
   Two scopes so projection hammering cannot starve the read
   panels, and the reverse.

   ROLES: staff AND admin (spec OQ5's accepted default: "Admin and
   staff both, member refused"). This deliberately differs from the
   refund endpoint's staff-only default, and the difference is
   defensible because this endpoint is READ-ONLY: admitting the
   member-portal demonstration account to a window is not admitting
   it to a control. If a write control is ever added here, it must
   NOT inherit this widened list; it audits and gates like
   refund-payment (staff only).

   AUDIT: reads are not audited row-by-row (they change nothing);
   one structured log line per call (panel, staff username,
   duration) makes usage visible without inventing a ledger
   (spec 6). No write control exists in version 1.

   Deployment note for the deploy engineer: deploy exactly like
   list-demo-orders (platform JSON Web Token verification ON is
   fine); the staff token rides x-orvanna-session, which
   _shared/staff-auth.ts checks first for exactly that reason.
   ============================================================ */

import {
  callerIpHash,
  checkRateLimit,
  errorResponse,
  getPool,
  isAllowedOrigin,
  jsonResponse,
  preflight,
  type DbClient,
} from "../_shared/edge.ts";

import { requireStaff } from "../_shared/staff-auth.ts";

/* The six panels of spec section 4.3. A closed union: anything
   else is refused, so a future panel is denied by default rather
   than silently admitted. */
const PANELS = [
  "runs_board",
  "current_month",
  "member_drill",
  "house_ledger",
  "superseded_trail",
  "projection",
] as const;
type Panel = (typeof PANELS)[number];

/* The literal banner text of labeling rule 2 (spec 3.2). The page
   substitutes the timestamp into <timestamp>; the SERVER also
   returns computed_at so the page cannot invent its own time. The
   text is a constant here so the verifier can assert it byte for
   byte. */
const PROJECTION_BANNER =
  "WHAT-IF PROJECTION, not a statement. Computed <timestamp>. " +
  "Numbers change as the month accumulates and are not payable.";

/* Paging bounds for the run drill. Same reasoning as
   list-demo-orders: a demonstration-scale table, and an unbounded
   limit on a public endpoint is a free way to make the database
   work hard. */
const DRILL_DEFAULT_LIMIT = 50;
const DRILL_MAX_LIMIT = 100;

/* GW-000 is the house account. Per spec 3.4 it appears ONLY on the
   house ledger panel, so member listings elsewhere filter it out
   defensively even though it should never hold orders or results. */
const HOUSE_CODE = "GW-000";

function toInt(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isInteger(n) && n >= 0 ? n : fallback;
}

/* deno-postgres returns numeric columns as strings (correctly: a
   numeric does not fit a float in general). Every money and volume
   figure in this system is at most two decimals and well inside
   the double range, so Number() is exact here. One helper so the
   conversion is uniform and greppable. */
function num(value: unknown): number {
  return value === null || value === undefined ? 0 : Number(value);
}

/* Member codes are GW- plus six digits. Validated before any query
   so a malformed code never reaches SQL (parameters are bound
   anyway; this is about answering 400 rather than 404). */
function isMemberCode(value: string): boolean {
  return /^GW-\d{6}$/.test(value);
}

/* ------------------------------------------------------------
   Panel: runs_board (spec 3.1)

   Without run_id: every FINAL run as a row, plus the TOP MOVERS
   list per run versus the prior finalized period, computed to the
   spec's deterministic definition: delta = this run's total_earned
   minus the prior final run's, per member, members present in
   either run, ordered by absolute delta descending, ties by member
   code ascending, limit 10. A member absent from a run counts from
   0.00. The earliest final period has no prior and therefore no
   movers list.

   With run_id: the drill. The run's commission_lines (earner code,
   source code, level, source CV, rate, amount) and its
   run_member_results, both page-sized, exactly the figures the
   member statements already show. Drilling a superseded run is
   allowed (the trail links here) and the response carries the
   run's status so the page renders the frozen marker.
   ------------------------------------------------------------ */
async function panelRunsBoard(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const runIdRaw = params.run_id;
  if (runIdRaw !== undefined && runIdRaw !== null && runIdRaw !== "") {
    return await runDrill(req, client, params);
  }

  const runs = await client.queryObject<{
    id: number;
    period: Date;
    spec_version: string;
    status: string;
    total_sv: string;
    total_cv: string;
    total_payout: string;
    members_paid: number;
    finished_at: Date | null;
  }>(
    `select id, period, spec_version, status,
            total_sv, total_cv, total_payout, members_paid, finished_at
       from app.commission_runs
      where status = 'final'
      order by period asc`,
  );

  /* Movers for every adjacent pair of final periods, one statement.
     The full outer join runs over run-filtered subselects (NOT over
     the raw table with a where clause, which would quietly turn the
     outer join back into an inner one and lose the absent-member
     rows the spec's counting rule exists for). */
  const movers = await client.queryObject<{
    run_id: number;
    member_code: string;
    display_name: string;
    earned_now: string;
    earned_prior: string;
    delta: string;
  }>(
    `with finals as (
        select id, period,
               row_number() over (order by period asc) as rn
          from app.commission_runs
         where status = 'final'
     ),
     pairs as (
        select f.id as run_id, p.id as prior_id
          from finals f
          join finals p on p.rn = f.rn - 1
     ),
     deltas as (
        select pr.run_id,
               d.member_id,
               d.earned_now,
               d.earned_prior,
               d.earned_now - d.earned_prior as delta
          from pairs pr
          cross join lateral (
             select coalesce(a.member_id, b.member_id) as member_id,
                    coalesce(a.total_earned, 0)        as earned_now,
                    coalesce(b.total_earned, 0)        as earned_prior
               from (select member_id, total_earned
                       from app.run_member_results
                      where run_id = pr.run_id) a
               full outer join
                    (select member_id, total_earned
                       from app.run_member_results
                      where run_id = pr.prior_id) b
                 on b.member_id = a.member_id
          ) d
     ),
     ranked as (
        select dl.run_id, m.member_code, m.display_name,
               dl.earned_now, dl.earned_prior, dl.delta,
               row_number() over (
                 partition by dl.run_id
                 order by abs(dl.delta) desc, m.member_code asc
               ) as pos
          from deltas dl
          join app.members m on m.id = dl.member_id
     )
     select run_id, member_code, display_name,
            earned_now, earned_prior, delta
       from ranked
      where pos <= 10
      order by run_id, abs(delta) desc, member_code asc`,
  );

  const moversByRun = new Map<number, unknown[]>();
  for (const row of movers.rows) {
    const list = moversByRun.get(Number(row.run_id)) ?? [];
    list.push({
      member_code: row.member_code,
      display_name: row.display_name,
      earned_now: num(row.earned_now),
      earned_prior: num(row.earned_prior),
      delta: num(row.delta),
    });
    moversByRun.set(Number(row.run_id), list);
  }

  return jsonResponse(req, 200, {
    panel: "runs_board",
    runs: runs.rows.map((r) => ({
      /* Finalized figures display their run id: labeling rule 1. */
      run_id: Number(r.id),
      period: r.period,
      spec_version: r.spec_version,
      status: r.status,
      total_sv: num(r.total_sv),
      total_cv: num(r.total_cv),
      total_payout: num(r.total_payout),
      members_paid: r.members_paid,
      finished_at: r.finished_at,
      top_movers: moversByRun.get(Number(r.id)) ?? [],
    })),
  });
}

async function runDrill(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const runId = toInt(params.run_id, 0);
  if (runId <= 0) {
    return errorResponse(req, 400, "bad_run_id", "That is not a run number.");
  }

  const run = await client.queryObject<{
    id: number;
    period: Date;
    spec_version: string;
    status: string;
    total_sv: string;
    total_cv: string;
    total_payout: string;
    members_paid: number;
    finished_at: Date | null;
  }>(
    `select id, period, spec_version, status, total_sv, total_cv,
            total_payout, members_paid, finished_at
       from app.commission_runs where id = $1`,
    [runId],
  );
  const runRow = run.rows[0];
  if (!runRow) {
    return errorResponse(req, 404, "run_not_found", "No such commission run.");
  }
  /* A run still in status running is mid-computation and its rows
     are not a statement of anything; refuse rather than render
     half-written figures. */
  if (runRow.status === "running") {
    return errorResponse(
      req,
      409,
      "run_not_finished",
      "That run is still computing and has nothing final to show.",
    );
  }

  const linesLimit = Math.min(
    toInt(params.lines_limit, DRILL_DEFAULT_LIMIT),
    DRILL_MAX_LIMIT,
  );
  const linesOffset = toInt(params.lines_offset, 0);
  const resultsLimit = Math.min(
    toInt(params.results_limit, DRILL_DEFAULT_LIMIT),
    DRILL_MAX_LIMIT,
  );
  const resultsOffset = toInt(params.results_offset, 0);

  const lines = await client.queryObject<{
    earner_code: string;
    source_code: string;
    level: number;
    source_cv: string;
    rate: string;
    amount: string;
  }>(
    `select e.member_code as earner_code,
            s.member_code as source_code,
            l.level, l.source_cv, l.rate, l.amount
       from app.commission_lines l
       join app.members e on e.id = l.earner_id
       join app.members s on s.id = l.source_member_id
      where l.run_id = $1
      order by e.member_code, l.level, s.member_code
      limit $2 offset $3`,
    [runId, linesLimit, linesOffset],
  );

  const linesTotal = await client.queryObject<{ total: number }>(
    `select count(*)::int as total from app.commission_lines where run_id = $1`,
    [runId],
  );

  const results = await client.queryObject<{
    member_code: string;
    display_name: string;
    sv: string;
    cv: string;
    tv: string;
    is_active: boolean;
    rank_earned: string;
    paid_depth: number;
    total_earned: string;
  }>(
    `select m.member_code, m.display_name,
            r.sv, r.cv, r.tv, r.is_active, r.rank_earned,
            r.paid_depth, r.total_earned
       from app.run_member_results r
       join app.members m on m.id = r.member_id
      where r.run_id = $1
      order by r.total_earned desc, m.member_code asc
      limit $2 offset $3`,
    [runId, resultsLimit, resultsOffset],
  );

  const resultsTotal = await client.queryObject<{ total: number }>(
    `select count(*)::int as total from app.run_member_results where run_id = $1`,
    [runId],
  );

  return jsonResponse(req, 200, {
    panel: "runs_board",
    drill: {
      run_id: Number(runRow.id),
      period: runRow.period,
      spec_version: runRow.spec_version,
      /* superseded runs render frozen with the visible marker
         (spec 3.5); the page reads this field to do it. */
      status: runRow.status,
      total_sv: num(runRow.total_sv),
      total_cv: num(runRow.total_cv),
      total_payout: num(runRow.total_payout),
      members_paid: runRow.members_paid,
      finished_at: runRow.finished_at,
      lines: lines.rows.map((l) => ({
        earner_code: l.earner_code,
        source_code: l.source_code,
        level: l.level,
        source_cv: num(l.source_cv),
        rate: num(l.rate),
        amount: num(l.amount),
      })),
      lines_total: linesTotal.rows[0]?.total ?? 0,
      lines_limit: linesLimit,
      lines_offset: linesOffset,
      results: results.rows.map((r) => ({
        member_code: r.member_code,
        display_name: r.display_name,
        sv: num(r.sv),
        cv: num(r.cv),
        tv: num(r.tv),
        is_active: r.is_active,
        rank_earned: r.rank_earned,
        paid_depth: r.paid_depth,
        total_earned: num(r.total_earned),
      })),
      results_total: resultsTotal.rows[0]?.total ?? 0,
      results_limit: resultsLimit,
      results_offset: resultsOffset,
    },
  });
}

/* ------------------------------------------------------------
   Panel: current_month (spec 3.2)

   The open month as it accumulates: bridged volume so far
   (completed app.orders rows in the open volume month), the
   house-retained slice BESIDE it (so attributed and unattributed
   money are always seen together), and the order count. The
   if-run-today projection is a SEPARATE call (panel=projection)
   under its own rate-limit scope, so a projection burst cannot
   starve this read and the reverse; the page composes the two.
   ------------------------------------------------------------ */
async function panelCurrentMonth(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const summary = await client.queryObject<{
    open_period: Date;
    bridged_orders: number;
    bridged_sv: string;
    house_retained_pv: string;
    house_slices: number;
    has_final_run: boolean;
  }>(
    `with om as (select date_trunc('month', now())::date as m)
     select om.m as open_period,
            (select count(*)::int
               from app.orders o
              where o.volume_month = om.m and o.status = 'completed')
              as bridged_orders,
            (select coalesce(sum(ol.quantity * ol.unit_volume), 0)
               from app.orders o
               join app.order_lines ol on ol.order_id = o.id
              where o.volume_month = om.m and o.status = 'completed')
              as bridged_sv,
            (select coalesce(sum(h.retained_pv), 0)
               from app.house_retained_volume h
              where h.volume_month = om.m) as house_retained_pv,
            (select count(*)::int
               from app.house_retained_volume h
              where h.volume_month = om.m) as house_slices,
            exists (select 1 from app.commission_runs r
                     where r.period = om.m and r.status = 'final')
              as has_final_run
       from om`,
  );
  const s = summary.rows[0];

  /* Per-member bridged volume so far, largest first. GW-000 is
     excluded defensively: the house account belongs to the house
     ledger panel and nowhere else (spec 3.4). */
  const perMember = await client.queryObject<{
    member_code: string;
    display_name: string;
    sv: string;
    orders: number;
  }>(
    `select m.member_code, m.display_name,
            sum(ol.quantity * ol.unit_volume) as sv,
            count(distinct o.id)::int as orders
       from app.orders o
       join app.order_lines ol on ol.order_id = o.id
       join app.members m on m.id = o.member_id
      where o.volume_month = date_trunc('month', now())::date
        and o.status = 'completed'
        and m.member_code <> $1
      group by m.member_code, m.display_name
      order by sv desc, m.member_code asc
      limit 25`,
    [HOUSE_CODE],
  );

  return jsonResponse(req, 200, {
    panel: "current_month",
    open_period: s?.open_period ?? null,
    /* has_final_run should be false for a genuinely open month; if
       it ever reads true the month has finalized and the page says
       so instead of calling this month "open". */
    has_final_run: s?.has_final_run ?? false,
    bridged_orders: s?.bridged_orders ?? 0,
    bridged_sv: num(s?.bridged_sv),
    house_retained_pv: num(s?.house_retained_pv),
    house_slices: s?.house_slices ?? 0,
    members: perMember.rows.map((r) => ({
      member_code: r.member_code,
      display_name: r.display_name,
      sv: num(r.sv),
      orders: r.orders,
    })),
  });
}

/* ------------------------------------------------------------
   Panel: member_drill (spec 3.3)

   By member code, the only member identifier this page ever shows.
   Current rank (latest final run), open-month volume against the
   100.00 gate, commission history across ALL final runs, and the
   downline contribution for one selected final run: lines grouped
   by level plus the active-leg count.

   ACTIVE LEGS, stated so the verifier can recompute it: a leg is a
   frontline child in the run's own level map (level 1 pair from
   the earner), and the leg is active when the child, or any member
   of the child's subtree in that same run's map, has is_active in
   the run's results. Run-scoped data only (the level map is kept
   for final runs; fn_finalize_run deletes superseded runs' maps,
   so for a superseded run this figure is null, never guessed).
   ------------------------------------------------------------ */
async function panelMemberDrill(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const rawCode = typeof params.member_code === "string"
    ? params.member_code.trim().toUpperCase()
    : "";
  if (!isMemberCode(rawCode)) {
    return errorResponse(
      req,
      400,
      "bad_member_code",
      "Member codes look like GW-000123.",
    );
  }
  if (rawCode === HOUSE_CODE) {
    /* Spec 3.4: GW-000 appears nowhere but the house ledger. */
    return errorResponse(
      req,
      404,
      "member_not_found",
      "The house account has no member drill; see the house ledger panel.",
    );
  }

  const member = await client.queryObject<{
    id: number;
    member_code: string;
    display_name: string;
    enrolled_on: Date;
  }>(
    `select id, member_code, display_name, enrolled_on
       from app.members where member_code = $1`,
    [rawCode],
  );
  const m = member.rows[0];
  if (!m) {
    return errorResponse(req, 404, "member_not_found", "No such member.");
  }
  /* m.id is used to join below and is NEVER returned: the exposure
     blacklist forbids internal bigint member identifiers. */

  const history = await client.queryObject<{
    run_id: number;
    period: Date;
    rank_earned: string;
    sv: string;
    cv: string;
    tv: string;
    is_active: boolean;
    total_earned: string;
  }>(
    `select r.run_id, cr.period, r.rank_earned, r.sv, r.cv, r.tv,
            r.is_active, r.total_earned
       from app.run_member_results r
       join app.commission_runs cr on cr.id = r.run_id
      where r.member_id = $1 and cr.status = 'final'
      order by cr.period asc`,
    [m.id],
  );

  const openMonth = await client.queryObject<{
    open_period: Date;
    sv: string;
    orders: number;
  }>(
    `with om as (select date_trunc('month', now())::date as m)
     select om.m as open_period,
            coalesce(sum(ol.quantity * ol.unit_volume), 0) as sv,
            count(distinct o.id)::int as orders
       from om
       left join app.orders o
         on o.volume_month = om.m and o.status = 'completed' and o.member_id = $1
       left join app.order_lines ol on ol.order_id = o.id
      group by om.m`,
    [m.id],
  );
  const om = openMonth.rows[0];
  const openSv = num(om?.sv);

  /* The selected run for the downline contribution: the caller's
     run_id when given and FINAL for this dashboard's history rule
     (superseded runs appear only in the trail, spec 3.3 last
     sentence), else the latest final run. */
  let selectedRunId = toInt(params.run_id, 0);
  if (selectedRunId > 0) {
    const check = await client.queryObject<{ status: string }>(
      `select status from app.commission_runs where id = $1`,
      [selectedRunId],
    );
    if (check.rows[0]?.status !== "final") {
      return errorResponse(
        req,
        400,
        "not_a_final_run",
        "The member drill reads final runs only; superseded runs live in the superseded-run trail.",
      );
    }
  } else {
    const latest = await client.queryObject<{ id: number }>(
      `select id from app.commission_runs
        where status = 'final' order by period desc limit 1`,
    );
    selectedRunId = Number(latest.rows[0]?.id ?? 0);
  }

  let contribution: unknown = null;
  if (selectedRunId > 0) {
    const byLevel = await client.queryObject<{
      level: number;
      line_count: number;
      amount: string;
    }>(
      `select l.level, count(*)::int as line_count, sum(l.amount) as amount
         from app.commission_lines l
        where l.run_id = $1 and l.earner_id = $2
        group by l.level order by l.level`,
      [selectedRunId, m.id],
    );
    const legs = await client.queryObject<{ active_legs: number }>(
      `select count(*)::int as active_legs
         from app.run_level_map fl
        where fl.run_id = $1 and fl.ancestor_id = $2 and fl.level = 1
          and (
            exists (select 1 from app.run_member_results r
                     where r.run_id = $1 and r.member_id = fl.descendant_id
                       and r.is_active)
            or exists (select 1
                         from app.run_level_map d
                         join app.run_member_results r
                           on r.run_id = $1 and r.member_id = d.descendant_id
                          and r.is_active
                        where d.run_id = $1 and d.ancestor_id = fl.descendant_id)
          )`,
      [selectedRunId, m.id],
    );
    const period = await client.queryObject<{ period: Date }>(
      `select period from app.commission_runs where id = $1`,
      [selectedRunId],
    );
    contribution = {
      run_id: selectedRunId,
      period: period.rows[0]?.period ?? null,
      by_level: byLevel.rows.map((l) => ({
        level: l.level,
        line_count: l.line_count,
        amount: num(l.amount),
      })),
      active_legs: legs.rows[0]?.active_legs ?? 0,
    };
  }

  const latestFinal = history.rows[history.rows.length - 1];

  return jsonResponse(req, 200, {
    panel: "member_drill",
    member_code: m.member_code,
    display_name: m.display_name,
    enrolled_on: m.enrolled_on,
    current_rank: latestFinal?.rank_earned ?? null,
    current_rank_run_id: latestFinal ? Number(latestFinal.run_id) : null,
    open_month: {
      open_period: om?.open_period ?? null,
      sv: openSv,
      orders: om?.orders ?? 0,
      /* The 100.00 qualification gate, stated as data so the page
         renders the same test the engine applies. */
      qualification_gate: 100.0,
      qualified_so_far: openSv >= 100.0,
    },
    history: history.rows.map((h) => ({
      run_id: Number(h.run_id),
      period: h.period,
      rank_earned: h.rank_earned,
      sv: num(h.sv),
      cv: num(h.cv),
      tv: num(h.tv),
      is_active: h.is_active,
      total_earned: num(h.total_earned),
    })),
    contribution,
  });
}

/* ------------------------------------------------------------
   Panel: house_ledger (spec 3.4)

   GW-000 retained volume month by month, running cumulative, and
   the month-over-month direction (decision 4.7's health metric:
   this figure should shrink as checkout attribution improves).
   The panel text states, and this response repeats as data, that
   retained volume is BOOKKEEPING, never a disbursement, and no
   commission run reads it.
   ------------------------------------------------------------ */
async function panelHouseLedger(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const months = await client.queryObject<{
    period: Date;
    slice_count: number;
    retained_pv: string;
    cumulative_pv: string;
    prior_pv: string | null;
  }>(
    `select h.volume_month as period,
            count(*)::int as slice_count,
            sum(h.retained_pv) as retained_pv,
            sum(sum(h.retained_pv)) over (order by h.volume_month)
              as cumulative_pv,
            lag(sum(h.retained_pv)) over (order by h.volume_month)
              as prior_pv
       from app.house_retained_volume h
      group by h.volume_month
      order by h.volume_month`,
  );

  return jsonResponse(req, 200, {
    panel: "house_ledger",
    house_code: HOUSE_CODE,
    note:
      "Retained volume is bookkeeping, never a disbursement; no commission run reads it.",
    months: months.rows.map((r) => {
      const pv = num(r.retained_pv);
      const prior = r.prior_pv === null ? null : num(r.prior_pv);
      return {
        period: r.period,
        slice_count: r.slice_count,
        retained_pv: pv,
        cumulative_pv: num(r.cumulative_pv),
        direction: prior === null
          ? "first"
          : pv > prior
          ? "up"
          : pv < prior
          ? "down"
          : "flat",
      };
    }),
  });
}

/* ------------------------------------------------------------
   Panel: superseded_trail (spec 3.5)

   For any period holding more than one run: the version chain,
   ordered by run id, old runs frozen with the superseded marker,
   the current final run last. Real data on day one: runs 1..6
   (spec v1.2) superseded by runs 7..12 (v1.3).
   ------------------------------------------------------------ */
async function panelSupersededTrail(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const rows = await client.queryObject<{
    period: Date;
    id: number;
    spec_version: string;
    status: string;
    total_sv: string;
    total_cv: string;
    total_payout: string;
    members_paid: number;
    finished_at: Date | null;
  }>(
    `select r.period, r.id, r.spec_version, r.status,
            r.total_sv, r.total_cv, r.total_payout, r.members_paid,
            r.finished_at
       from app.commission_runs r
      where r.period in (
        select period from app.commission_runs
         group by period having count(*) > 1
      )
      order by r.period asc, r.id asc`,
  );

  /* Group by period into chains, preserving run-id order. */
  const chains = new Map<string, unknown[]>();
  for (const r of rows.rows) {
    const key = r.period instanceof Date
      ? r.period.toISOString().slice(0, 10)
      : String(r.period);
    const list = chains.get(key) ?? [];
    list.push({
      run_id: Number(r.id),
      spec_version: r.spec_version,
      status: r.status,
      total_sv: num(r.total_sv),
      total_cv: num(r.total_cv),
      total_payout: num(r.total_payout),
      members_paid: r.members_paid,
      finished_at: r.finished_at,
    });
    chains.set(key, list);
  }

  return jsonResponse(req, 200, {
    panel: "superseded_trail",
    periods: Array.from(chains.entries()).map(([period, runs]) => ({
      period,
      runs,
    })),
  });
}

/* ------------------------------------------------------------
   Panel: projection (spec section 5): the transactional dry run.

   The decided mechanism, implemented to the letter. Mirror-math
   was REJECTED (a third implementation of the plan drifts, and a
   dashboard that can disagree with the engine is worse than no
   projection). Instead this opens ONE transaction on its direct
   Postgres connection and, inside it: calls the REAL
   app.fn_run_commission for the open period, SELECTs the
   aggregates it needs into memory, then ROLLS BACK. The rollback
   discards every inserted row; nothing survives; no run id is
   consumed as a visible artifact (sequence gaps are harmless and
   invisible); app.fn_finalize_run is NEVER called, so nothing
   finalized was ever touchable; and the numbers are the engine's
   own, zero drift by construction.

   Fencing rules, normative and enforced here:
     - runs ONLY against a period with no final run (the open
       month). The period is derived SERVER-SIDE from the calendar,
       never taken from the caller, so the fence cannot be steered.
     - the transaction contains nothing but the engine call and
       the SELECTs of the captured aggregates.
     - the response carries the labeling fields and NO run id.
     - concurrency is bounded by the 6-per-minute projection scope.

   Self-check: row counts of runs, results, lines and the level map
   are captured before the transaction and re-checked after the
   rollback. They MUST be identical; a difference is logged loudly
   and reported as left_nothing_behind: false so the page can shout
   instead of shrugging. This is a tripwire for the verifier's
   probe 4, not a substitute for it.
   ------------------------------------------------------------ */
interface TableCounts {
  runs: number;
  results: number;
  lines: number;
  level_map: number;
}

async function tableCounts(client: DbClient): Promise<TableCounts> {
  const r = await client.queryObject<{
    runs: number;
    results: number;
    lines: number;
    level_map: number;
  }>(
    `select (select count(*) from app.commission_runs)::int     as runs,
            (select count(*) from app.run_member_results)::int  as results,
            (select count(*) from app.commission_lines)::int    as lines,
            (select count(*) from app.run_level_map)::int       as level_map`,
  );
  const row = r.rows[0];
  return {
    runs: row?.runs ?? 0,
    results: row?.results ?? 0,
    lines: row?.lines ?? 0,
    level_map: row?.level_map ?? 0,
  };
}

async function panelProjection(
  req: Request,
  client: DbClient,
): Promise<Response> {
  /* The open period, derived here and only here. */
  const periodRow = await client.queryObject<{
    open_period: Date;
    has_final: boolean;
  }>(
    `select date_trunc('month', now())::date as open_period,
            exists (select 1 from app.commission_runs
                     where period = date_trunc('month', now())::date
                       and status = 'final') as has_final`,
  );
  const openPeriod = periodRow.rows[0]?.open_period;
  if (periodRow.rows[0]?.has_final) {
    /* The fence: a finalized period is a statement, and the spec
       forbids projecting over one. */
    return errorResponse(
      req,
      409,
      "period_finalized",
      "This month already has a final commission run; a projection is only computed for an open month.",
    );
  }

  const before = await tableCounts(client);

  let totals: {
    total_sv: number;
    total_cv: number;
    total_payout: number;
    members_paid: number;
  } | null = null;
  let qualified = 0;
  let ranks: { rank: string; members: number }[] = [];
  let topEarners: {
    member_code: string;
    display_name: string;
    rank_earned: string;
    total_earned: number;
  }[] = [];

  /* THE FENCED TRANSACTION. Everything between begin and rollback
     is discarded; the finally guarantees the rollback runs even if
     a read throws mid-way, so a failure can never leave the
     engine's rows behind. */
  await client.queryArray("begin");
  try {
    const runRes = await client.queryObject<{ run_id: number }>(
      `select app.fn_run_commission($1::date) as run_id`,
      [openPeriod],
    );
    /* Held only to filter the reads below. NEVER returned: a
       projection has no run id (labeling rule 1), and this one
       stops existing at the rollback anyway. */
    const ephemeralRunId = Number(runRes.rows[0]?.run_id);

    const t = await client.queryObject<{
      total_sv: string;
      total_cv: string;
      total_payout: string;
      members_paid: number;
    }>(
      `select total_sv, total_cv, total_payout, members_paid
         from app.commission_runs where id = $1`,
      [ephemeralRunId],
    );
    const tr = t.rows[0];
    totals = {
      total_sv: num(tr?.total_sv),
      total_cv: num(tr?.total_cv),
      total_payout: num(tr?.total_payout),
      members_paid: tr?.members_paid ?? 0,
    };

    const q = await client.queryObject<{ qualified: number }>(
      `select count(*) filter (where is_active)::int as qualified
         from app.run_member_results where run_id = $1`,
      [ephemeralRunId],
    );
    qualified = q.rows[0]?.qualified ?? 0;

    const rk = await client.queryObject<{ rank_earned: string; n: number }>(
      `select rank_earned, count(*)::int as n
         from app.run_member_results
        where run_id = $1
        group by rank_earned
        order by count(*) desc, rank_earned asc`,
      [ephemeralRunId],
    );
    ranks = rk.rows.map((r) => ({ rank: r.rank_earned, members: r.n }));

    const top = await client.queryObject<{
      member_code: string;
      display_name: string;
      rank_earned: string;
      total_earned: string;
    }>(
      `select m.member_code, m.display_name, r.rank_earned, r.total_earned
         from app.run_member_results r
         join app.members m on m.id = r.member_id
        where r.run_id = $1 and r.total_earned > 0
        order by r.total_earned desc, m.member_code asc
        limit 10`,
      [ephemeralRunId],
    );
    topEarners = top.rows.map((r) => ({
      member_code: r.member_code,
      display_name: r.display_name,
      rank_earned: r.rank_earned,
      total_earned: num(r.total_earned),
    }));
  } finally {
    await client.queryArray("rollback");
  }

  const after = await tableCounts(client);
  const clean = before.runs === after.runs &&
    before.results === after.results &&
    before.lines === after.lines &&
    before.level_map === after.level_map;
  if (!clean) {
    /* This should be impossible: a rollback discards everything.
       If it ever fires, the verifier's checksum probe is the next
       stop and this log line is the alarm. */
    console.error(
      `commission-report: PROJECTION LEFT ROWS BEHIND ` +
        `(before ${JSON.stringify(before)} after ${JSON.stringify(after)})`,
    );
  }

  const computedAt = new Date().toISOString();

  return jsonResponse(req, 200, {
    panel: "projection",
    /* Labeling rule fields (spec 3.2). NO run id in this object,
       and none nested anywhere below: that absence is the
       machine-checkable tell. */
    projection: true,
    banner: PROJECTION_BANNER.replace("<timestamp>", computedAt),
    computed_at: computedAt,
    period: openPeriod,
    totals,
    qualified_members: qualified,
    rank_distribution: ranks,
    top_projected_earners: topEarners,
    left_nothing_behind: clean,
  });
}

/* ------------------------------------------------------------ */

Deno.serve(async (req: Request): Promise<Response> => {
  const pre = preflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return errorResponse(req, 405, "method_not_allowed", "Use POST.");
  }
  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return errorResponse(
      req,
      403,
      "origin_not_allowed",
      "This demo only answers its own site.",
    );
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  const panel = typeof body.panel === "string" ? body.panel : "";
  if (!(PANELS as readonly string[]).includes(panel)) {
    return errorResponse(
      req,
      400,
      "bad_panel",
      "Ask for one of: runs_board, current_month, member_drill, house_ledger, superseded_trail, projection.",
    );
  }

  const started = Date.now();
  const ipHash = await callerIpHash(req);
  const client = await getPool().connect();
  try {
    /* Rate limit BEFORE authentication: the limiter is the cheap
       outer wall, and an unauthenticated flood should burn its own
       bucket, not the database's password checks. Two scopes per
       spec section 6. */
    const isProjection = panel === "projection";
    const verdict = await checkRateLimit(
      ipHash,
      { perMinute: isProjection ? 6 : 30 },
      isProjection ? "commission-report-projection" : "commission-report",
      client,
    );
    if (!verdict.allowed) {
      return errorResponse(
        req,
        429,
        "rate_limited",
        isProjection
          ? "Projections are limited to six per minute. Please wait a moment."
          : "Too many dashboard requests in one minute. Please wait a moment.",
        { "Retry-After": String(verdict.retryAfterSeconds) },
      );
    }

    /* THE GATE. Staff and admin both (spec OQ5 accepted default),
       member refused; the role is re-read from the database on
       every call by requireStaff, never trusted from the token. */
    const auth = await requireStaff(client, req, ["staff", "admin"]);
    if (!auth.ok) {
      return errorResponse(
        req,
        401,
        "not_authorised",
        "Sign in to the staff console to open the commission dashboard.",
      );
    }

    let response: Response;
    switch (panel as Panel) {
      case "runs_board":
        response = await panelRunsBoard(req, client, body);
        break;
      case "current_month":
        response = await panelCurrentMonth(req, client);
        break;
      case "member_drill":
        response = await panelMemberDrill(req, client, body);
        break;
      case "house_ledger":
        response = await panelHouseLedger(req, client);
        break;
      case "superseded_trail":
        response = await panelSupersededTrail(req, client);
        break;
      case "projection":
        response = await panelProjection(req, client);
        break;
    }

    /* The one structured usage line per call (spec 6). Username,
       panel, duration; never a token, never row data. */
    console.log(JSON.stringify({
      fn: "commission-report",
      panel,
      staff: auth.identity.user,
      role: auth.identity.role,
      ms: Date.now() - started,
    }));

    return response;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`commission-report: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Could not read the commission dashboard right now.",
    );
  } finally {
    client.release();
  }
});
