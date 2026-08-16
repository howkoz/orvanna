/* ============================================================
   billing-console (Supabase Edge Function, Deno)

   THE STAFF BILLING CONSOLE'S SERVER SIDE.
   Spec: MLM-PILOT/docs/SUBSCRIPTION-ENGINE-SPEC.md section 9A.2
   (the console), 9A.1 (the scheduler), section 9 (the pipeline the
   preview mirrors), section 12 (the member-action edge rules), and
   Howard's rulings, OQ8 (production inertness) above all.
   Authored 2026-08-16 by mlm-site-builder; NOT DEPLOYED by the
   builder (gates first, then the deploy engineer ships with
   byte-compare).

   THE TWO HARD RULES, both precedents from the refund screen
   (spec 9A.2, verbatim obligations):
     1. Every write is audited to the SAME app.demo_staff_actions
        ledger the refund system uses, with the staff username.
     2. Every rule is enforced HERE, never by the page, because
        hiding a button is not a gate. A crafted request without a
        staff session gets the same refusal the console would show.

   ROLES: staff ONLY. This function moves money-adjacent state
   (schedules, pauses, cancellations), so it takes the refund
   endpoint's default, not the commission dashboard's widened
   read-only list. See _shared/staff-auth.ts's "admin is not a
   super-user" block before ever widening this.

   ------------------------------------------------------------
   THE STATE OF THE WORLD THIS FILE IS WRITTEN INTO, 2026-08-16

   Migrations 024 to 027 are APPLIED to the cloud project and the
   engine is DELIBERATELY INERT there:
     - app.sim_clock is EMPTY (zero rows). Ruling OQ8: simulations
       never run in production, and nothing in this file may
       initialize that clock. NOTHING HERE WRITES app.sim_clock,
       and app.fn_sim_clock_init is never called.
     - app.fn_billing_tick refuses while the clock is empty, and
       this file refuses BEFORE that anyway (see run_execute).
     - pg_cron is NOT installed on this instance, so the daily
       schedule cannot fire server-side yet. The schedule CONTROL
       below is faithful and live (app.billing_schedule is real and
       seeded disabled); the console surfaces an honest banner that
       automatic runs await the scheduler installation, an
       infrastructure step recorded for the coordinator.
     - The engine's sanctioned member/staff action functions
       (fn_sub_pause and kin, migration 026) all read the clock for
       their business date. With the clock empty they would write
       null dates, so every one of them is gated here behind the
       ENGINE-INERT CHECK: a clean, honest refusal instead of a
       corrupted event stream. When S2 arrives and the engine gains
       its real-rail clock, the same calls drive it unchanged.

   WHY run_execute IS STRUCTURALLY DISABLED (not just gated):
   Howard's OQ8 ruling is that the production console drives the
   REAL pipeline only when S2 arrives. Today RUN NOW performs the
   dry-run preview path ONLY: gather and price, create nothing.
   The execute step is refused server-side with an honest
   s2_pending answer even if someone hand-initialized the clock,
   because EXECUTE_ENABLED below is a compile-time false. Flipping
   it is the S2 change, made deliberately, with its own review;
   no runtime data can flip it.

   ------------------------------------------------------------
   THE PREVIEW, AND WHY THE INERT ANSWER REFUSES TO PRICE

   The preview mirrors pipeline step 3 (gather due work) using the
   ENGINE'S OWN derivation functions (app.fn_sub_scheduled_date via
   app.v_subscription_next_billing, the engine's retry pointers,
   the engine's epoch floor), so preview and execution read the
   same arithmetic and can never disagree (spec 9A.2's quote-then-
   record obligation). It creates nothing: no run row, no periods,
   no attempts, plain SELECTs only.

   With the clock EMPTY there is no engine_epoch, and the epoch is
   not a nicety: the 1,820 seeded subscriptions are anchored years
   in the past, their history owned by SEEDED orders, and without
   the epoch floor a due-work gather would "find" roughly two
   years of phantom catch-up billing (migration 026 deviation D7
   exists precisely to prevent that). A preview that priced that
   backlog would be a lie about what the engine would do, and a
   preview that silently invented its own epoch would be a second
   engine. So the inert-state preview reports, honestly: the
   engine is inert, the epoch is unset (an S2 clock-initialization
   decision), here is the raw backlog headcount awaiting that
   decision, and no dollar figure is claimed. The page renders
   exactly that.
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

import {
  auditStaffAction,
  requireStaff,
  type StaffIdentity,
} from "../_shared/staff-auth.ts";

/* Compile-time execution switch. See the header: flipping this is
   the S2 change. While false, run_execute always refuses with
   s2_pending, whatever the database says. */
const EXECUTE_ENABLED = false;

/* Actions, a closed union: unknown actions are refused, so a
   future action is denied by default rather than silently
   admitted. Reads, the heavy preview, and writes carry separate
   rate-limit scopes (see the limiter call below). */
const READ_ACTIONS = [
  "overview",
  "run_history",
  "run_detail",
  "retry_queue",
  "attention",
  "forecast",
  "member_subscriptions",
] as const;
const WRITE_ACTIONS = ["schedule_set", "sub_action", "run_execute"] as const;
const PREVIEW_ACTIONS = ["run_preview"] as const;
type Action =
  | (typeof READ_ACTIONS)[number]
  | (typeof WRITE_ACTIONS)[number]
  | (typeof PREVIEW_ACTIONS)[number];

const ALL_ACTIONS: readonly string[] = [
  ...READ_ACTIONS,
  ...WRITE_ACTIONS,
  ...PREVIEW_ACTIONS,
];

/* The subscription operations of spec 9A.2's management row, each
   mapped to its SANCTIONED engine function (migration 026 part 5).
   Raw UPDATEs on app.subscriptions are refused by the migration
   024 schedule-column guard, and this file never attempts one. */
const SUB_OPS = [
  "pause",
  "resume",
  "cancel",
  "change_day",
  "change_frequency",
  "flag_card_update",
  "reactivate",
] as const;
type SubOp = (typeof SUB_OPS)[number];

function toInt(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
}

function num(value: unknown): number {
  return value === null || value === undefined ? 0 : Number(value);
}

function isMemberCode(value: string): boolean {
  return /^GW-\d{6}$/.test(value);
}

/* ------------------------------------------------------------
   Engine status: the one honest snapshot every screen leans on.
   Read fresh per call (never cached across requests: the whole
   point is that S2 flips it and the console notices by itself).
   ------------------------------------------------------------ */
interface EngineStatus {
  clock_initialized: boolean;
  clock_date: string | null;
  engine_epoch: string | null;
  pg_cron_installed: boolean;
}

async function engineStatus(client: DbClient): Promise<EngineStatus> {
  const r = await client.queryObject<{
    clock_date: Date | null;
    engine_epoch: Date | null;
    pg_cron: boolean;
  }>(
    `select (select clock_date from app.sim_clock)   as clock_date,
            (select engine_epoch from app.sim_clock) as engine_epoch,
            exists (select 1 from pg_extension where extname = 'pg_cron')
              as pg_cron`,
  );
  const row = r.rows[0];
  const iso = (d: Date | null | undefined) =>
    d ? new Date(d).toISOString().slice(0, 10) : null;
  return {
    clock_initialized: !!row?.clock_date,
    clock_date: iso(row?.clock_date),
    engine_epoch: iso(row?.engine_epoch),
    pg_cron_installed: row?.pg_cron === true,
  };
}

/* The honest banner strings, produced server-side so every client
   of this function tells the same truth. */
function honestyNotes(status: EngineStatus): string[] {
  const notes: string[] = [];
  if (!status.pg_cron_installed) {
    notes.push(
      "The scheduler extension (pg_cron) is not installed on this database instance, " +
        "so the daily schedule cannot fire server-side yet. The schedule you set here is " +
        "stored and will be honored once the scheduler is installed, an infrastructure " +
        "step recorded for the coordinator.",
    );
  }
  if (!status.clock_initialized) {
    notes.push(
      "The renewal engine is deliberately inert in production (Phase S1, ruling OQ8): " +
        "its clock is not initialized and no billing run can execute here. RUN NOW " +
        "offers the dry-run preview only; execution arrives with Phase S2.",
    );
  }
  return notes;
}

/* ------------------------------------------------------------
   overview: schedule row, engine status, headline counts.
   ------------------------------------------------------------ */
async function actionOverview(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const status = await engineStatus(client);

  const schedule = await client.queryObject<{
    enabled: boolean;
    run_at_time: string | null;
    timezone: string;
    updated_by: string | null;
    updated_at: Date;
  }>(
    `select enabled, run_at_time::text as run_at_time, timezone,
            updated_by, updated_at
       from app.billing_schedule`,
  );

  const counts = await client.queryObject<{
    runs: number;
    last_tick: Date | null;
    retry_pointers: number;
    attention: number;
    active_subs: number;
    paused_subs: number;
    troubled_subs: number;
  }>(
    `select (select count(*) from app.billing_runs)::int as runs,
            (select max(tick_date) from app.billing_runs
              where status = 'final') as last_tick,
            (select count(*) from app.billing_attempts ba
              where ba.next_action in ('retry', 'infra_immediate'))::int
              as retry_pointers,
            (select count(*) from app.v_staff_attention_queue)::int
              as attention,
            (select count(*) from app.subscriptions
              where state = 'active')::int as active_subs,
            (select count(*) from app.subscriptions
              where state = 'paused')::int as paused_subs,
            (select count(*) from app.subscriptions
              where state in ('past_due', 'dunning', 'card_update_required',
                              'suspended'))::int as troubled_subs`,
  );
  const c = counts.rows[0];

  return jsonResponse(req, 200, {
    action: "overview",
    engine: status,
    honesty_notes: honestyNotes(status),
    schedule: schedule.rows[0] ?? null,
    counts: {
      billing_runs: c?.runs ?? 0,
      last_final_tick: c?.last_tick ?? null,
      retry_pointers: c?.retry_pointers ?? 0,
      attention_rows: c?.attention ?? 0,
      active_subscriptions: c?.active_subs ?? 0,
      paused_subscriptions: c?.paused_subs ?? 0,
      troubled_subscriptions: c?.troubled_subs ?? 0,
    },
  });
}

/* ------------------------------------------------------------
   schedule_set: the ONE sanctioned write path to
   app.billing_schedule (spec 9A.2 row 1; the table's own comment
   says "edited only through the staff console's Edge Function",
   and this is that function).

   Rules enforced HERE, server-side:
     - enabled must be a boolean.
     - enabling requires a time. The schema tolerates an enabled
       row with no time (the poll treats it as manual-only), but a
       schedule that LOOKS armed and never fires is a lie waiting
       to be believed, so this console refuses the combination.
     - the time is HH:MM, 24 hour.
     - the timezone must exist in pg_timezone_names; "Chicago"
       does not fire at any hour.
   The write stamps updated_by with the AUTHENTICATED staff
   username (never anything from the request body) and is audited.
   ------------------------------------------------------------ */
async function actionScheduleSet(
  req: Request,
  client: DbClient,
  identity: StaffIdentity,
  ipHash: string,
  params: Record<string, unknown>,
): Promise<Response> {
  const refuse = async (code: string, message: string) => {
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: "billing_schedule_set",
      target: "billing_schedule",
      outcome: "refused",
      outcome_code: code,
      ip_hash: ipHash,
      detail: { params: { ...params } },
    });
    return errorResponse(req, 400, code, message);
  };

  if (typeof params.enabled !== "boolean") {
    return await refuse(
      "bad_enabled",
      "Say whether the daily run is enabled: true or false.",
    );
  }
  const enabled = params.enabled;

  let runAtTime: string | null = null;
  if (params.run_at_time !== null && params.run_at_time !== undefined &&
    params.run_at_time !== "") {
    const t = String(params.run_at_time).trim();
    if (!/^([01]\d|2[0-3]):([0-5]\d)$/.test(t)) {
      return await refuse(
        "bad_time",
        "The run time is HH:MM on a 24 hour clock, for example 03:30.",
      );
    }
    runAtTime = t;
  }
  if (enabled && runAtTime === null) {
    return await refuse(
      "time_required",
      "Enabling the daily run needs a time of day; an enabled schedule with no time would look armed and never fire.",
    );
  }

  const timezone = typeof params.timezone === "string" &&
      params.timezone.trim() !== ""
    ? params.timezone.trim()
    : "UTC";
  if (timezone.length > 64) {
    return await refuse("bad_timezone", "That timezone name is not real.");
  }
  const tzCheck = await client.queryObject<{ ok: boolean }>(
    `select exists (select 1 from pg_timezone_names where name = $1) as ok`,
    [timezone],
  );
  if (tzCheck.rows[0]?.ok !== true) {
    return await refuse(
      "bad_timezone",
      "That timezone is not in the database's timezone table. Use a name like UTC, America/Chicago, or Europe/Berlin.",
    );
  }

  await client.queryArray(
    `update app.billing_schedule
        set enabled     = $1,
            run_at_time = $2::time,
            timezone    = $3,
            updated_by  = $4,
            updated_at  = now()
      where singleton`,
    [enabled, runAtTime, timezone, identity.user],
  );

  await auditStaffAction(client, {
    actor: identity.user,
    actor_role: identity.role,
    action: "billing_schedule_set",
    target: "billing_schedule",
    outcome: "allowed",
    outcome_code: null,
    ip_hash: ipHash,
    detail: { enabled, run_at_time: runAtTime, timezone },
  });

  const status = await engineStatus(client);
  const fresh = await client.queryObject<{
    enabled: boolean;
    run_at_time: string | null;
    timezone: string;
    updated_by: string | null;
    updated_at: Date;
  }>(
    `select enabled, run_at_time::text as run_at_time, timezone,
            updated_by, updated_at
       from app.billing_schedule`,
  );

  return jsonResponse(req, 200, {
    action: "schedule_set",
    schedule: fresh.rows[0] ?? null,
    engine: status,
    honesty_notes: honestyNotes(status),
  });
}

/* ------------------------------------------------------------
   run_preview: the mandatory dry run (spec 9A.2 row 2).

   Clock present (a simulation environment, or S2 later): the SAME
   gather the tick performs, read-only. Tick date is clock + 1,
   exactly what fn_billing_tick would accept next.
     - New cycles: the engine's own derivation. For every active
       subscription whose derived next date is due, expand cycle
       indexes with app.fn_sub_scheduled_date (bounded at 60
       periods, five monthly years; the derivation view's
       next_index is by construction the first unaccounted cycle),
       floored strictly above the engine epoch (deviation D7),
       due on or before the tick.
     - Retries: the live pointers (latest attempt of each open
       period, next_action retry or infra_immediate, date due),
       with the C1 clip stated per row: a retry whose calendar
       window passed will be clipped, not run, and the preview
       says which.
     - Housekeeping due: pause auto-resumes.
   Priced from app.products, the single pricing source (FM3), the
   same statement shape the tick uses. Creates NOTHING.

   Clock absent (production today): the honest inert answer; see
   the file header for why no dollar figure is claimed.
   ------------------------------------------------------------ */
async function actionRunPreview(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const status = await engineStatus(client);

  if (!status.clock_initialized) {
    const backlog = await client.queryObject<{
      backlog_subs: number;
      earliest: Date | null;
      latest: Date | null;
      future_subs: number;
    }>(
      `select count(*) filter (where next_billing_date <= current_date)::int
                as backlog_subs,
              min(next_billing_date) filter
                (where next_billing_date <= current_date) as earliest,
              max(next_billing_date) filter
                (where next_billing_date <= current_date) as latest,
              count(*) filter (where next_billing_date > current_date)::int
                as future_subs
         from app.v_subscription_next_billing
        where state = 'active'`,
    );
    const b = backlog.rows[0];
    return jsonResponse(req, 200, {
      action: "run_preview",
      engine: status,
      honesty_notes: honestyNotes(status),
      inert: true,
      preview: null,
      backlog: {
        active_subscriptions_with_past_derived_dates: b?.backlog_subs ?? 0,
        earliest_derived_date: b?.earliest ?? null,
        latest_derived_date: b?.latest ?? null,
        active_subscriptions_due_in_future: b?.future_subs ?? 0,
        explanation:
          "These derived dates predate the engine because the seeded subscriptions' history " +
          "is owned by seeded orders. What the first real tick will actually gather depends " +
          "on the engine epoch chosen at S2 clock initialization; pricing this backlog now " +
          "would claim a number no run would ever bill.",
      },
    });
  }

  /* ---- the live gather (simulation environment, or S2) ---- */
  const tick = await client.queryObject<{ tick_date: Date }>(
    `select (clock_date + 1)::date as tick_date from app.sim_clock`,
  );
  const tickDate = tick.rows[0]?.tick_date;

  const newCycles = await client.queryObject<{
    subscription_id: number;
    member_code: string;
    renewal_index: number;
    scheduled_date: Date;
    frequency_months: number;
    amount: string;
    pv: string;
  }>(
    `with base as (
        select nb.subscription_id, nb.next_renewal_index
          from app.v_subscription_next_billing nb
         where nb.state = 'active'
           and nb.next_billing_date <= (select clock_date + 1 from app.sim_clock)
     )
     select b.subscription_id,
            m.member_code,
            gs.n as renewal_index,
            app.fn_sub_scheduled_date(b.subscription_id, gs.n) as scheduled_date,
            s.frequency_months,
            round(s.quantity * p.price * s.frequency_months, 2) as amount,
            round(s.quantity * p.volume_points * s.frequency_months, 2) as pv
       from base b
       cross join lateral generate_series(
         b.next_renewal_index, b.next_renewal_index + 59) as gs(n)
       join app.subscriptions s on s.id = b.subscription_id
       join app.members m on m.id = s.member_id
       join app.products p on p.id = s.product_id
      where app.fn_sub_scheduled_date(b.subscription_id, gs.n) is not null
        and app.fn_sub_scheduled_date(b.subscription_id, gs.n)
              > (select engine_epoch from app.sim_clock)
        and app.fn_sub_scheduled_date(b.subscription_id, gs.n)
              <= (select clock_date + 1 from app.sim_clock)
      order by m.member_code, gs.n`,
  );

  const retries = await client.queryObject<{
    subscription_id: number;
    member_code: string;
    renewal_index: number;
    decline_class: string | null;
    next_retry_date: Date;
    next_retry_step: number | null;
    amount_cents: number;
    will_clip: boolean;
  }>(
    `select rp.subscription_id, m.member_code, rp.renewal_index,
            ba.decline_class, ba.next_retry_date, ba.next_retry_step,
            rp.amount_cents,
            /* Rule C1 restated as data: a retry runs only inside its
               billing month and only through day 26; otherwise the
               tick records skipped_clipped instead. */
            not (
              date_trunc('month', (select clock_date + 1 from app.sim_clock)::timestamp)
                = date_trunc('month', rp.scheduled_date::timestamp)
              and extract(day from (select clock_date + 1 from app.sim_clock))::int <= 26
            ) as will_clip
       from app.billing_attempts ba
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
       join app.subscriptions s on s.id = rp.subscription_id
       join app.members m on m.id = s.member_id
      where rp.outcome = 'open'
        and ba.next_action in ('retry', 'infra_immediate')
        and ba.next_retry_date is not null
        and ba.next_retry_date <= (select clock_date + 1 from app.sim_clock)
        and ba.attempt_no = (select max(b2.attempt_no)
                               from app.billing_attempts b2
                              where b2.renewal_period_id = rp.id)
        and s.state in ('active', 'past_due', 'dunning')
      order by m.member_code, rp.renewal_index`,
  );

  const housekeeping = await client.queryObject<{
    auto_resumes: number;
  }>(
    `select count(*)::int as auto_resumes
       from app.subscriptions s
      where s.state = 'paused'
        and exists (select 1 from app.subscription_events e
                     where e.subscription_id = s.id and e.event_type = 'pause'
                       and e.pause_until <= (select clock_date + 1 from app.sim_clock)
                       and e.id = (select max(e2.id) from app.subscription_events e2
                                    where e2.subscription_id = s.id
                                      and e2.event_type in ('pause', 'resume')))`,
  );

  const newAmount = newCycles.rows.reduce((a, r) => a + num(r.amount), 0);
  const retryRows = retries.rows.filter((r) => !r.will_clip);
  const clipRows = retries.rows.filter((r) => r.will_clip);
  const retryAmount = retryRows.reduce((a, r) => a + r.amount_cents / 100, 0);

  const byFrequency = new Map<number, { count: number; amount: number }>();
  for (const r of newCycles.rows) {
    const f = Number(r.frequency_months);
    const cur = byFrequency.get(f) ?? { count: 0, amount: 0 };
    cur.count += 1;
    cur.amount += num(r.amount);
    byFrequency.set(f, cur);
  }

  const sample = (rows: unknown[], limit = 50) => rows.slice(0, limit);

  return jsonResponse(req, 200, {
    action: "run_preview",
    engine: status,
    honesty_notes: honestyNotes(status),
    inert: false,
    preview: {
      tick_date: tickDate,
      new_cycles: {
        count: newCycles.rows.length,
        amount: Math.round(newAmount * 100) / 100,
        by_frequency: Array.from(byFrequency.entries())
          .sort((a, b) => a[0] - b[0])
          .map(([frequency_months, v]) => ({
            frequency_months,
            count: v.count,
            amount: Math.round(v.amount * 100) / 100,
          })),
        rows: sample(newCycles.rows.map((r) => ({
          subscription_id: Number(r.subscription_id),
          member_code: r.member_code,
          renewal_index: r.renewal_index,
          scheduled_date: r.scheduled_date,
          frequency_months: r.frequency_months,
          amount: num(r.amount),
          pv: num(r.pv),
        }))),
      },
      retries: {
        count: retryRows.length,
        amount: Math.round(retryAmount * 100) / 100,
        will_clip_count: clipRows.length,
        rows: sample(retries.rows.map((r) => ({
          subscription_id: Number(r.subscription_id),
          member_code: r.member_code,
          renewal_index: r.renewal_index,
          decline_class: r.decline_class,
          next_retry_date: r.next_retry_date,
          ladder_step: r.next_retry_step,
          amount: r.amount_cents / 100,
          will_clip: r.will_clip,
        }))),
      },
      housekeeping: {
        pause_auto_resumes_due: housekeeping.rows[0]?.auto_resumes ?? 0,
      },
      total_would_bill: Math.round((newAmount + retryAmount) * 100) / 100,
    },
  });
}

/* ------------------------------------------------------------
   run_execute: the confirm step after the preview. Refused today.

   Order of refusals, each audited, none reachable from the page
   alone (a crafted request meets the same wall):
     1. EXECUTE_ENABLED is false: s2_pending, always, in this
        build. This is the OQ8 production-inertness ruling made
        structural.
     2. (When S2 flips the constant) clock uninitialized:
        engine_inert.
     3. (When S2 flips the constant) confirm !== true, or the
        caller's expected counts disagree with a fresh gather:
        the mandatory-preview discipline, so execution can never
        run on stale eyes.
   The eventual execute path is app.fn_billing_tick(clock + 1) on
   this same connection; it is written nowhere else so there is
   exactly one thing to review when S2 arrives.
   ------------------------------------------------------------ */
async function actionRunExecute(
  req: Request,
  client: DbClient,
  identity: StaffIdentity,
  ipHash: string,
): Promise<Response> {
  /* Deliberately before any other check: this build cannot
     execute, full stop. */
  if (!EXECUTE_ENABLED) {
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: "billing_run_execute",
      target: "billing_runs",
      outcome: "refused",
      outcome_code: "s2_pending",
      ip_hash: ipHash,
      detail: {},
    });
    return errorResponse(
      req,
      409,
      "s2_pending",
      "Executing a billing run arrives with Phase S2. Today the console previews only: the engine is deliberately inert in production, and no run can be executed from here.",
    );
  }

  /* Unreachable in this build. Kept minimal on purpose: the S2
     builder extends THIS block (clock gate, confirm gate, fresh
     re-gather comparison, then select app.fn_billing_tick(...)),
     with its own spec amendment and both gates. */
  return errorResponse(req, 500, "internal_error", "Unreachable.");
}

/* ------------------------------------------------------------
   run_history and run_detail (spec 9A.2 row 3; the brief's E13).
   member-fault and system-fault failures are separate columns on
   the run row itself (migration 024 deviation D4), so the two
   families can never hide inside each other's statistics.
   ------------------------------------------------------------ */
async function actionRunHistory(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const limit = Math.min(toInt(params.limit, 50), 100);
  const offset = toInt(params.offset, 0);
  const runs = await client.queryObject<{
    id: number;
    tick_date: Date;
    engine_version: string;
    clock_source: string;
    status: string;
    started_at: Date | null;
    finished_at: Date | null;
    subscriptions_due: number | null;
    attempts_made: number | null;
    succeeded: number | null;
    declined: number | null;
    attempts_reconciled: number | null;
    member_fault_failures: number | null;
    system_fault_failures: number | null;
    promo_hook_identity: boolean | null;
    mit_invariant_ok: boolean | null;
    notes: string | null;
  }>(
    `select id, tick_date, engine_version, clock_source, status,
            started_at, finished_at, subscriptions_due, attempts_made,
            succeeded, declined, attempts_reconciled,
            member_fault_failures, system_fault_failures,
            promo_hook_identity, mit_invariant_ok, notes
       from app.billing_runs
      order by id desc
      limit $1 offset $2`,
    [limit, offset],
  );
  const total = await client.queryObject<{ total: number }>(
    `select count(*)::int as total from app.billing_runs`,
  );
  return jsonResponse(req, 200, {
    action: "run_history",
    runs: runs.rows.map((r) => ({ ...r, id: Number(r.id) })),
    total: total.rows[0]?.total ?? 0,
    limit,
    offset,
  });
}

async function actionRunDetail(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const runId = toInt(params.run_id, 0);
  if (runId <= 0) {
    return errorResponse(req, 400, "bad_run_id", "That is not a run number.");
  }
  const run = await client.queryObject<Record<string, unknown>>(
    `select id, tick_date, engine_version, clock_source, status,
            started_at, finished_at, subscriptions_due, attempts_made,
            succeeded, declined, attempts_reconciled,
            member_fault_failures, system_fault_failures,
            promo_hook_identity, mit_invariant_ok, notes
       from app.billing_runs where id = $1`,
    [runId],
  );
  if (!run.rows[0]) {
    return errorResponse(req, 404, "run_not_found", "No such billing run.");
  }

  const attempts = await client.queryObject<{
    attempt_id: number;
    member_code: string;
    subscription_id: number;
    renewal_index: number;
    attempt_no: number;
    attempt_kind: string;
    ladder_step: number | null;
    scheduled_for: Date;
    order_number: string | null;
    outcome: string;
    decline_code: string | null;
    decline_class: string | null;
    member_fault: boolean | null;
    next_action: string | null;
    next_retry_date: Date | null;
  }>(
    `select ba.id as attempt_id, m.member_code,
            rp.subscription_id, rp.renewal_index,
            ba.attempt_no, ba.attempt_kind, ba.ladder_step,
            ba.scheduled_for, o.order_number,
            ba.outcome, ba.decline_code, ba.decline_class,
            ba.member_fault, ba.next_action, ba.next_retry_date
       from app.billing_attempts ba
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
       join app.subscriptions s on s.id = rp.subscription_id
       join app.members m on m.id = s.member_id
       left join app.demo_orders o on o.id = ba.demo_order_id
      where ba.run_id = $1
      order by m.member_code, rp.renewal_index, ba.attempt_no`,
    [runId],
  );

  return jsonResponse(req, 200, {
    action: "run_detail",
    run: { ...run.rows[0], id: Number(run.rows[0].id) },
    attempts: attempts.rows.map((a) => ({
      ...a,
      attempt_id: Number(a.attempt_id),
      subscription_id: Number(a.subscription_id),
    })),
  });
}

/* ------------------------------------------------------------
   retry_queue (spec 9A.2 row 4): everything scheduled to retry,
   when, and under which decline class. Only the LATEST attempt of
   an open period can hold a live pointer (migration 024's
   supersession hygiene), and the query says so explicitly rather
   than trusting it.
   ------------------------------------------------------------ */
async function actionRetryQueue(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const rows = await client.queryObject<{
    member_code: string;
    subscription_id: number;
    renewal_index: number;
    state: string;
    decline_code: string | null;
    decline_class: string | null;
    next_action: string;
    next_retry_date: Date | null;
    next_retry_step: number | null;
    amount_cents: number;
    scheduled_date: Date;
  }>(
    `select m.member_code, rp.subscription_id, rp.renewal_index, s.state,
            ba.decline_code, ba.decline_class, ba.next_action,
            ba.next_retry_date, ba.next_retry_step,
            rp.amount_cents, rp.scheduled_date
       from app.billing_attempts ba
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
       join app.subscriptions s on s.id = rp.subscription_id
       join app.members m on m.id = s.member_id
      where rp.outcome = 'open'
        and ba.next_action in ('retry', 'infra_immediate')
        and ba.attempt_no = (select max(b2.attempt_no)
                               from app.billing_attempts b2
                              where b2.renewal_period_id = rp.id)
      order by ba.next_retry_date asc nulls last, m.member_code asc`,
  );
  return jsonResponse(req, 200, {
    action: "retry_queue",
    retries: rows.rows.map((r) => ({
      member_code: r.member_code,
      subscription_id: Number(r.subscription_id),
      renewal_index: r.renewal_index,
      state: r.state,
      decline_code: r.decline_code,
      decline_class: r.decline_class,
      next_action: r.next_action,
      next_retry_date: r.next_retry_date,
      ladder_step: r.next_retry_step,
      amount: r.amount_cents / 100,
      billed_on: r.scheduled_date,
    })),
  });
}

/* ------------------------------------------------------------
   attention (spec 9A.2 row 5): the rows a human must see, read
   from the engine's own lens app.v_staff_attention_queue (FM2
   orphans, system faults, unrecognized codes, FM4 cycle gaps),
   joined to member codes so a human can act.
   ------------------------------------------------------------ */
async function actionAttention(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const rows = await client.queryObject<{
    reason: string;
    member_code: string;
    subscription_id: number;
    renewal_index: number;
    billing_attempt_id: number | null;
    detail: string;
    state: string;
  }>(
    `select q.reason, m.member_code, q.subscription_id, q.renewal_index,
            q.billing_attempt_id, q.detail, s.state
       from app.v_staff_attention_queue q
       join app.subscriptions s on s.id = q.subscription_id
       join app.members m on m.id = s.member_id
      order by q.reason, m.member_code`,
  );
  return jsonResponse(req, 200, {
    action: "attention",
    rows: rows.rows.map((r) => ({
      reason: r.reason,
      member_code: r.member_code,
      subscription_id: Number(r.subscription_id),
      renewal_index: r.renewal_index,
      billing_attempt_id: r.billing_attempt_id === null
        ? null
        : Number(r.billing_attempt_id),
      detail: r.detail,
      state: r.state,
    })),
  });
}

/* ------------------------------------------------------------
   forecast (spec 9A.2 row 7): the next seven days of scheduled
   billing, by day, derived from the same scheduled_date(n)
   arithmetic the engine runs (through the engine's own lens
   app.v_subscription_next_billing), so what the forecast shows is
   what the engine will do. Retries due in the window ride along.

   Basis date: the clock's next day when the clock exists, else
   the real calendar (honest in production: derived dates for the
   seeded rows sit in the past, so the window is sparse until S2
   starts the engine, and the response says how many subscriptions
   sit in that past-due backlog rather than hiding them).
   ------------------------------------------------------------ */
async function actionForecast(
  req: Request,
  client: DbClient,
): Promise<Response> {
  const status = await engineStatus(client);
  const basisExpr = status.clock_initialized
    ? `(select clock_date + 1 from app.sim_clock)`
    : `current_date`;

  const days = await client.queryObject<{
    day: Date;
    subscriptions: number;
    amount: string;
    pv: string;
  }>(
    `select nb.next_billing_date as day,
            count(*)::int as subscriptions,
            sum(round(s.quantity * p.price * s.frequency_months, 2)) as amount,
            sum(round(s.quantity * p.volume_points * s.frequency_months, 2)) as pv
       from app.v_subscription_next_billing nb
       join app.subscriptions s on s.id = nb.subscription_id
       join app.products p on p.id = s.product_id
      where nb.state = 'active'
        and nb.next_billing_date >= ${basisExpr}
        and nb.next_billing_date <  ${basisExpr} + 7
      group by nb.next_billing_date
      order by nb.next_billing_date`,
  );

  const retryDays = await client.queryObject<{
    day: Date;
    retries: number;
    amount_cents: string;
  }>(
    `select ba.next_retry_date as day,
            count(*)::int as retries,
            sum(rp.amount_cents) as amount_cents
       from app.billing_attempts ba
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
      where rp.outcome = 'open'
        and ba.next_action in ('retry', 'infra_immediate')
        and ba.next_retry_date >= ${basisExpr}
        and ba.next_retry_date <  ${basisExpr} + 7
        and ba.attempt_no = (select max(b2.attempt_no)
                               from app.billing_attempts b2
                              where b2.renewal_period_id = rp.id)
      group by ba.next_retry_date
      order by ba.next_retry_date`,
  );

  const backlog = await client.queryObject<{ backlog: number }>(
    `select count(*)::int as backlog
       from app.v_subscription_next_billing
      where state = 'active' and next_billing_date < ${basisExpr}`,
  );

  return jsonResponse(req, 200, {
    action: "forecast",
    engine: status,
    honesty_notes: honestyNotes(status),
    days: days.rows.map((d) => ({
      day: d.day,
      subscriptions: d.subscriptions,
      amount: num(d.amount),
      pv: num(d.pv),
    })),
    retry_days: retryDays.rows.map((d) => ({
      day: d.day,
      retries: d.retries,
      amount: num(d.amount_cents) / 100,
    })),
    past_due_backlog_subscriptions: backlog.rows[0]?.backlog ?? 0,
  });
}

/* ------------------------------------------------------------
   member_subscriptions: one member's subscriptions with state,
   schedule facts, the derived next billing date (the lens, never
   a stored copy), the credential summary, and the recent event
   stream, whose cause texts carry the engine's own disclosures
   (the 12.1 double-billing disclosure among them).

   Exposure: member code and display name; brand, last four digits
   and expiry of the stored credential (what a human needs for a
   card conversation); NEVER token_reference, NEVER network_anchor,
   NEVER email or address. Subscription ids are exposed because
   they are the handle the sanctioned management functions take; a
   subscription id names a contract, not a person.
   ------------------------------------------------------------ */
async function actionMemberSubscriptions(
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
  const member = await client.queryObject<{
    id: number;
    member_code: string;
    display_name: string;
  }>(
    `select id, member_code, display_name from app.members
      where member_code = $1`,
    [rawCode],
  );
  const m = member.rows[0];
  if (!m) {
    return errorResponse(req, 404, "member_not_found", "No such member.");
  }

  const subs = await client.queryObject<{
    id: number;
    product_name: string;
    sku: string;
    quantity: number;
    frequency_months: number;
    billing_day: number | null;
    billing_anchor_date: Date;
    state: string;
    state_changed_at: Date;
    start_month: Date;
    cancel_month: Date | null;
    next_billing_date: Date | null;
    monthly_price: string;
    monthly_pv: string;
    cred_brand: string | null;
    cred_last4: string | null;
    cred_expiry_month: number | null;
    cred_expiry_year: number | null;
    cred_retired_on: Date | null;
  }>(
    `select s.id, p.name as product_name, p.sku, s.quantity,
            s.frequency_months, s.billing_day, s.billing_anchor_date,
            s.state, s.state_changed_at, s.start_month, s.cancel_month,
            nb.next_billing_date,
            p.price as monthly_price, p.volume_points as monthly_pv,
            c.brand as cred_brand, c.last4 as cred_last4,
            c.expiry_month as cred_expiry_month,
            c.expiry_year as cred_expiry_year,
            c.retired_on as cred_retired_on
       from app.subscriptions s
       join app.products p on p.id = s.product_id
       left join app.v_subscription_next_billing nb
              on nb.subscription_id = s.id
       left join app.payment_credentials c on c.id = s.credential_id
      where s.member_id = $1
      order by s.state = 'cancelled', s.id`,
    [m.id],
  );

  const events = await client.queryObject<{
    subscription_id: number;
    event_type: string;
    occurred_on: Date;
    from_state: string | null;
    to_state: string | null;
    cause: string | null;
    actor: string | null;
  }>(
    `select e.subscription_id, e.event_type, e.occurred_on,
            e.from_state, e.to_state, e.cause, e.actor
       from app.subscription_events e
       join app.subscriptions s on s.id = e.subscription_id
      where s.member_id = $1
      order by e.id desc
      limit 20`,
    [m.id],
  );

  return jsonResponse(req, 200, {
    action: "member_subscriptions",
    member_code: m.member_code,
    display_name: m.display_name,
    subscriptions: subs.rows.map((s) => ({
      subscription_id: Number(s.id),
      product_name: s.product_name,
      sku: s.sku,
      quantity: s.quantity,
      frequency_months: s.frequency_months,
      billing_day: s.billing_day,
      billing_anchor_date: s.billing_anchor_date,
      state: s.state,
      state_changed_at: s.state_changed_at,
      start_month: s.start_month,
      cancel_month: s.cancel_month,
      next_billing_date: s.next_billing_date,
      monthly_price: num(s.monthly_price),
      monthly_pv: num(s.monthly_pv),
      credential: s.cred_brand === null ? null : {
        brand: s.cred_brand,
        last4: s.cred_last4,
        expiry_month: s.cred_expiry_month,
        expiry_year: s.cred_expiry_year,
        retired_on: s.cred_retired_on,
      },
    })),
    recent_events: events.rows.map((e) => ({
      subscription_id: Number(e.subscription_id),
      event_type: e.event_type,
      occurred_on: e.occurred_on,
      from_state: e.from_state,
      to_state: e.to_state,
      cause: e.cause,
      actor: e.actor,
    })),
  });
}

/* ------------------------------------------------------------
   sub_action: the management writes (spec 9A.2 row 6), every one
   through its SANCTIONED engine function with the authenticated
   staff username as the actor, every one audited, every one
   refused while the engine is inert (the functions read the
   engine clock for their business date; calling them clockless
   would corrupt the event stream, so the refusal is the correct
   and honest behavior until S2).

   Engine refusals (a state the transition table forbids, a pause
   longer than two months, a billing day outside 1 to 28) surface
   VERBATIM: the engine's raise messages are written in plain
   English precisely so a console can show them, and a second
   paraphrase here would be a second place the rules live.
   ------------------------------------------------------------ */
async function actionSubAction(
  req: Request,
  client: DbClient,
  identity: StaffIdentity,
  ipHash: string,
  params: Record<string, unknown>,
): Promise<Response> {
  const op = typeof params.op === "string" ? params.op : "";
  const subscriptionId = toInt(params.subscription_id, 0);
  const auditAction = `billing_sub_${op || "unknown"}`;
  const target = subscriptionId > 0 ? `subscription:${subscriptionId}` : null;

  const refuse = async (
    httpStatus: number,
    code: string,
    message: string,
  ) => {
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: auditAction,
      target,
      outcome: "refused",
      outcome_code: code,
      ip_hash: ipHash,
      detail: { op, params: { ...params } },
    });
    return errorResponse(req, httpStatus, code, message);
  };

  if (!(SUB_OPS as readonly string[]).includes(op)) {
    return await refuse(
      400,
      "bad_op",
      "The operations are: pause, resume, cancel, change_day, change_frequency, flag_card_update, reactivate.",
    );
  }
  if (subscriptionId <= 0) {
    return await refuse(
      400,
      "bad_subscription",
      "That is not a subscription number.",
    );
  }

  const sub = await client.queryObject<{
    id: number;
    member_code: string;
    state: string;
  }>(
    `select s.id, m.member_code, s.state
       from app.subscriptions s
       join app.members m on m.id = s.member_id
      where s.id = $1`,
    [subscriptionId],
  );
  if (!sub.rows[0]) {
    return await refuse(404, "subscription_not_found", "No such subscription.");
  }

  /* THE ENGINE-INERT GATE. Every sanctioned function stamps its
     events with the engine clock's date; with the clock empty
     those functions would write nulls into an append-only stream.
     Refusing here is the only honest move, and it is the same
     answer for a crafted request as for the console. */
  const status = await engineStatus(client);
  if (!status.clock_initialized) {
    return await refuse(
      409,
      "engine_inert",
      "The renewal engine is deliberately inert in production (Phase S1): its clock is not initialized, so subscription changes cannot be recorded on the engine's ledger yet. This control goes live with Phase S2.",
    );
  }

  /* Per-operation validation, then the sanctioned call. The actor
     passed to the engine is ALWAYS the authenticated username,
     never anything from the request body. */
  try {
    switch (op as SubOp) {
      case "pause": {
        const months = toInt(params.months, 0);
        if (months !== 1 && months !== 2) {
          return await refuse(
            400,
            "bad_months",
            "A pause is 1 or 2 months (ruling R3).",
          );
        }
        await client.queryArray(
          `select app.fn_sub_pause($1, $2, $3)`,
          [subscriptionId, months, identity.user],
        );
        break;
      }
      case "resume": {
        await client.queryArray(
          `select app.fn_sub_resume($1, $2)`,
          [subscriptionId, identity.user],
        );
        break;
      }
      case "cancel": {
        await client.queryArray(
          `select app.fn_sub_cancel($1, $2)`,
          [subscriptionId, identity.user],
        );
        break;
      }
      case "change_day": {
        const day = toInt(params.new_day, 0);
        if (day < 1 || day > 28) {
          return await refuse(
            400,
            "bad_day",
            "Billing day picks run 1 to 28 (the OQ3 ruling); days 29 to 31 do not exist in every month.",
          );
        }
        await client.queryArray(
          `select app.fn_sub_change_billing_day($1, $2, $3)`,
          [subscriptionId, day, identity.user],
        );
        break;
      }
      case "change_frequency": {
        const f = toInt(params.new_frequency, 0);
        if (![1, 2, 3, 6].includes(f)) {
          return await refuse(
            400,
            "bad_frequency",
            "Frequencies are 1, 2, 3 or 6 months (ruling R1).",
          );
        }
        await client.queryArray(
          `select app.fn_sub_change_frequency($1, $2, $3)`,
          [subscriptionId, f, identity.user],
        );
        break;
      }
      case "flag_card_update": {
        /* No dedicated engine function exists for the staff flag;
           the sanctioned state path is fn_record_state, and the
           migration 024 transition guard enforces the state table
           (T3 from active, T9 from past_due, T13 from dunning;
           anything else raises and surfaces verbatim below). */
        await client.queryArray(
          `select app.fn_record_state(
              $1, 'card_update_required',
              'staff flag: card update requested from the billing console',
              (select clock_date from app.sim_clock), $2)`,
          [subscriptionId, identity.user],
        );
        break;
      }
      case "reactivate": {
        const brand = typeof params.brand === "string"
          ? params.brand.trim().slice(0, 20)
          : "";
        const last4 = typeof params.last4 === "string"
          ? params.last4.trim()
          : "";
        if (brand === "" || !/^\d{4}$/.test(last4)) {
          return await refuse(
            400,
            "bad_card_summary",
            "Reactivation records the fresh card's brand and its last four digits (a fresh cardholder-present payment mints the credential).",
          );
        }
        await client.queryArray(
          `select app.fn_sub_reactivate_sim($1, $2, $3, $4)`,
          [subscriptionId, brand, last4, identity.user],
        );
        break;
      }
    }
  } catch (err) {
    /* The engine said no. Its message is the rule, verbatim. */
    const message = err instanceof Error ? err.message : String(err);
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: auditAction,
      target,
      outcome: "refused",
      outcome_code: "engine_refused",
      ip_hash: ipHash,
      detail: { op, engine_message: message.slice(0, 500) },
    });
    return errorResponse(req, 409, "engine_refused", message);
  }

  /* The engine's own record of what just happened, returned so
     the console shows the ENGINE'S disclosure text (the 12.1
     double-billing disclosure on a day change, the pause-lane
     clock semantics, the reactivation coverage note), never a
     page-side paraphrase. */
  const event = await client.queryObject<{
    event_type: string;
    occurred_on: Date;
    from_state: string | null;
    to_state: string | null;
    cause: string | null;
  }>(
    `select event_type, occurred_on, from_state, to_state, cause
       from app.subscription_events
      where subscription_id = $1
      order by id desc limit 1`,
    [subscriptionId],
  );
  const fresh = await client.queryObject<{ state: string }>(
    `select state from app.subscriptions where id = $1`,
    [subscriptionId],
  );

  await auditStaffAction(client, {
    actor: identity.user,
    actor_role: identity.role,
    action: auditAction,
    target,
    outcome: "allowed",
    outcome_code: null,
    ip_hash: ipHash,
    detail: {
      op,
      member_code: sub.rows[0].member_code,
      new_state: fresh.rows[0]?.state ?? null,
      params: {
        months: params.months ?? null,
        new_day: params.new_day ?? null,
        new_frequency: params.new_frequency ?? null,
      },
    },
  });

  return jsonResponse(req, 200, {
    action: "sub_action",
    op,
    subscription_id: subscriptionId,
    member_code: sub.rows[0].member_code,
    new_state: fresh.rows[0]?.state ?? null,
    engine_record: event.rows[0] ?? null,
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
  const action = typeof body.action === "string" ? body.action : "";
  if (!ALL_ACTIONS.includes(action)) {
    return errorResponse(
      req,
      400,
      "bad_action",
      "Unknown billing console action.",
    );
  }

  const started = Date.now();
  const ipHash = await callerIpHash(req);
  const client = await getPool().connect();
  try {
    /* Three rate-limit scopes: ordinary reads 30 per minute
       (browsing with drills), the gather-everything preview 6 per
       minute (the one heavy read, same budget shape as the
       commission projection), writes 12 per minute (a human pace;
       nobody legitimately edits schedules or subscriptions faster,
       and a script doing so is exactly what the limiter is for).
       Separate scopes so no family can starve another. */
    const isPreview = (PREVIEW_ACTIONS as readonly string[]).includes(action);
    const isWrite = (WRITE_ACTIONS as readonly string[]).includes(action);
    const verdict = await checkRateLimit(
      ipHash,
      { perMinute: isPreview ? 6 : isWrite ? 12 : 30 },
      isPreview
        ? "billing-console-preview"
        : isWrite
        ? "billing-console-write"
        : "billing-console",
      client,
    );
    if (!verdict.allowed) {
      return errorResponse(
        req,
        429,
        "rate_limited",
        "Too many billing console requests in one minute. Please wait a moment.",
        { "Retry-After": String(verdict.retryAfterSeconds) },
      );
    }

    /* THE GATE: staff only, role re-read from the database on
       every call. Refusals after a verified signature carry the
       verified username into the audit line (finding N-M1). */
    const auth = await requireStaff(client, req, ["staff"]);
    if (!auth.ok) {
      if (isWrite && (auth.code === "wrong_role" || auth.code === "expired" ||
        auth.code === "unknown_user")) {
        await auditStaffAction(client, {
          actor: auth.verified_user ?? "anonymous",
          actor_role: null,
          action: `billing_${action}`,
          target: null,
          outcome: "refused",
          outcome_code: auth.code,
          ip_hash: ipHash,
        });
      }
      return errorResponse(
        req,
        401,
        "not_authorised",
        "Sign in to the staff console to use the billing console.",
      );
    }

    let response: Response;
    switch (action as Action) {
      case "overview":
        response = await actionOverview(req, client);
        break;
      case "schedule_set":
        response = await actionScheduleSet(
          req,
          client,
          auth.identity,
          ipHash,
          body,
        );
        break;
      case "run_preview":
        response = await actionRunPreview(req, client);
        break;
      case "run_execute":
        response = await actionRunExecute(req, client, auth.identity, ipHash);
        break;
      case "run_history":
        response = await actionRunHistory(req, client, body);
        break;
      case "run_detail":
        response = await actionRunDetail(req, client, body);
        break;
      case "retry_queue":
        response = await actionRetryQueue(req, client);
        break;
      case "attention":
        response = await actionAttention(req, client);
        break;
      case "forecast":
        response = await actionForecast(req, client);
        break;
      case "member_subscriptions":
        response = await actionMemberSubscriptions(req, client, body);
        break;
      case "sub_action":
        response = await actionSubAction(
          req,
          client,
          auth.identity,
          ipHash,
          body,
        );
        break;
    }

    /* One structured usage line per call: action, username,
       duration. Never a token, never row data. */
    console.log(JSON.stringify({
      fn: "billing-console",
      action,
      staff: auth.identity.user,
      ms: Date.now() - started,
    }));

    return response;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`billing-console: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "The billing console could not answer right now.",
    );
  } finally {
    client.release();
  }
});
