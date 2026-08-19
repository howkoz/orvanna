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

   run_execute: LIVE AS OF MIGRATIONS 028 AND 029 (2026-08-16,
   engine commit 61ebe26). The reserved S2 change has been made:
   EXECUTE_ENABLED is true and the execute action implements 029's
   live worker contract (see the worker block below). The gates
   that replaced the old blanket refusal: dispatch must be
   explicit in the payload; the engine must answer ready (the
   three-argument tick, the verdict door, and the dispatch_mode
   seam all present; for live dispatch additionally the seeded
   sandbox credentials); and every engine refusal (clock, date
   arithmetic, limit) surfaces verbatim. This function still never
   writes app.sim_clock: initializing it is the deploy-round
   operator's explicit act per 029's acceptance procedure.

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
  HYPERSWITCH_BASE_URL,
  isAllowedOrigin,
  jsonResponse,
  mapHyperswitchStatus,
  preflight,
  type DbClient,
} from "../_shared/edge.ts";

import { CATALOG, toCents } from "../_shared/pricing.ts";

import {
  auditStaffAction,
  requireStaff,
  type StaffIdentity,
} from "../_shared/staff-auth.ts";

/* Compile-time execution switch. FLIPPED TO TRUE 2026-08-16 with
   migrations 028 (run limit) and 029 (live dispatch seam): this is
   the S2 change the earlier build reserved, made deliberately, with
   the engine contract of 029 implemented below (the live worker).
   Execution still refuses server-side unless the payload's dispatch
   mode is EXPLICIT and the engine answers ready (schema present;
   for live dispatch, the seeded sandbox credentials exist); nothing
   here ever initializes app.sim_clock. */
const EXECUTE_ENABLED = true;

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
const WRITE_ACTIONS = ["schedule_set", "sub_action", "run_execute", "clear_attention"] as const;
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
  return Number.isInteger(n) && n >= 0 ? n : fallback;
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
      "The renewal engine's clock is not initialized on this database, so no billing " +
        "run can execute here yet. RUN NOW previews; an execute is refused honestly " +
        "until the deploy round applies the engine seam (migrations 028 and 029), seeds " +
        "the test credentials, and initializes the clock per the recorded acceptance " +
        "procedure.",
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
/* THE NUMBER-TO-RUN LIMIT (Howard's ruling, 2026-08-16 evening).
   Blank means all due; a positive integer N means exactly N.
   Parsed in ONE place so preview and execute cannot disagree about
   what a limit is. Returns null for "all due", a number for N, or
   an Error-shaped string for a refusal. */
function parseRunLimit(value: unknown): number | null | "invalid" {
  if (value === undefined || value === null || value === "") return null;
  const n = Number(value);
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < 1 || n > 100000) {
    return "invalid";
  }
  return n;
}

async function actionRunPreview(
  req: Request,
  client: DbClient,
  params: Record<string, unknown>,
): Promise<Response> {
  const status = await engineStatus(client);

  const runLimit = parseRunLimit(params.run_limit);
  if (runLimit === "invalid") {
    return errorResponse(
      req,
      400,
      "bad_limit",
      "Number to run is blank for all due, or a positive whole number.",
    );
  }

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
      /* The number-to-run intent is echoed even in the inert
         answer, so the console shows the limit it will carry into
         the S2 execute payload. */
      requested_run_limit: runLimit,
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

  /* ---- THE NUMBER-TO-RUN SELECTION, aligned to migration 028. ----
     Reconciled 2026-08-16 in the ENGINE'S favor (the standing rule):
       1. The limit bounds NEW CYCLE BILLINGS ONLY (028 / spec 9B
          rule 6). Already-scheduled retries run regardless: a retry
          is a promise already made on a C1-clipped date, and
          deferring it behind a limit could vanish it as
          skipped_clipped, distorting dunning for exactly the
          members already in trouble. An earlier draft here limited
          the combined set; that reading is REJECTED.
       2. The order is 028's exactly: scheduled date ascending, then
          member code, then subscription id, then renewal index
          (total order even for a member holding two subscriptions).
     due_total below is therefore 028's due_count (new cycles only,
     measured before selection), and the WHICH list is recomputable
     from the engine's own jsonb_agg ordering, byte for byte. */
  interface DueItem {
    subscription_id: number;
    member_code: string;
    renewal_index: number;
    due_date: string;
    amount: number;
    detail: string;
  }
  const dueItems: DueItem[] = newCycles.rows.map((r) => ({
    subscription_id: Number(r.subscription_id),
    member_code: r.member_code,
    renewal_index: r.renewal_index,
    due_date: String(r.scheduled_date).slice(0, 10),
    amount: num(r.amount),
    detail: r.frequency_months + " month(s)",
  }));
  dueItems.sort((a, b) =>
    a.due_date < b.due_date
      ? -1
      : a.due_date > b.due_date
      ? 1
      : a.member_code < b.member_code
      ? -1
      : a.member_code > b.member_code
      ? 1
      : a.subscription_id !== b.subscription_id
      ? a.subscription_id - b.subscription_id
      : a.renewal_index - b.renewal_index
  );
  const selected = runLimit === null ? dueItems : dueItems.slice(0, runLimit);
  const selectedAmount = selected.reduce((a, r) => a + r.amount, 0);

  return jsonResponse(req, 200, {
    action: "run_preview",
    engine: status,
    honesty_notes: honestyNotes(status),
    inert: false,
    requested_run_limit: runLimit,
    preview: {
      tick_date: tickDate,
      /* The limit block: what a run capped at N would actually
         charge, and how much due work would remain for later runs
         (self-healing through the next gather, no bookmark). Counts
         are NEW CYCLES ONLY, matching 028's due_count arithmetic;
         retries are never limited and are reported in their own
         block. With no limit, selected covers everything due and
         remaining is zero, so the page renders one truth either
         way. */
      limit: {
        requested_n: runLimit,
        due_total: dueItems.length,
        selected_count: selected.length,
        remaining_count: dueItems.length - selected.length,
        selected_amount: Math.round(selectedAmount * 100) / 100,
        retries_note:
          "Already-scheduled retries are never limited (spec 9B rule 6); the retries block runs in full regardless of N.",
        selected: sample(selected),
      },
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

/* ============================================================
   THE LIVE WORKER (migration 029's contract, implemented to the
   letter; the contract text lives in 029's header so nobody
   improvises it, and this block is its one implementation).

   The tick, invoked with dispatch 'live', creates each payment
   attempt demo-order-shaped and leaves it in the honest
   non-terminal state 'dispatched' stamped dispatch_mode 'live'.
   This worker then, per attempt ORDERED BY ID:
     1. reprices server-side through the _shared pricing mirror
        (the same table create-payment prices from) and asserts
        the repriced integer cents EQUAL the attempt's demo-order
        total_cents; refuse on mismatch: the frozen period is the
        promise, and a drifted catalog must stop the charge, not
        reprice it;
     2. HyperSwitch create WITH confirm, amount = the frozen
        total_cents, currency USD, authentication_type no_three_ds
        (ruling 8.4: a renewal is a Merchant Initiated Transaction;
        no external authentication, no challenge flow, ever);
     3. fresh retrieve with the exact integer amount match (the
        same evidentiary bar the checkout holds);
     4. writes the verdict through app.fn_record_live_verdict, the
        engine's ONE write-back door, which funnels into the same
        classification path, state machine, and bridge the
        simulator uses.
   Then app.fn_bridge_demo_orders(true).

   CRASH RECOVERY (FM2 posture): on every invocation, BEFORE new
   work, the worker sweeps every lingering dispatched live attempt
   (any run): if its demo order carries a payment reference, the
   truth is one retrieve away; otherwise the rail is searched by
   metadata.billing_attempt_id through the payments list; a payment
   found resolves through the same verdict door with no second
   charge, and an attempt the rail has never seen is charged now,
   which is safe precisely because the rail has never seen it.

   ONE ARGUED DEVIATION from a literal reading of the contract:
   this worker never records the 'processor_unreachable' verdict on
   an AMBIGUOUS wire failure (a create or retrieve that timed out).
   That verdict marks the order abandoned and schedules an infra
   retry as a NEW attempt with a NEW charge; issuing it while the
   original create may have landed is how double charges are born
   (FM1 by way of FM2). An ambiguous failure instead leaves the
   attempt 'dispatched', visible in the attention queue, and the
   next sweep resolves it with CERTAINTY from the rail's own
   ledger. The verdict option remains for a definitive
   never-reached case a future operator tool may prove.
   ============================================================ */

/* The fixed synthetic billing block, the same ruling create-payment
   records (2026-08-14): a demonstration address, never a member's
   real one. Harmless to the no_three_ds path and satisfies any
   connector that wants an address present. */
const WORKER_BILLING_ADDRESS = {
  address: {
    line1: "1 Demonstration Way",
    city: "Springfield",
    state: "IL",
    zip: "62701",
    country: "US",
    first_name: "Orvanna",
    last_name: "Demo",
  },
};

interface LiveAttempt {
  attempt_id: number;
  run_id: number;
  demo_order_id: number;
  order_number: string;
  total_cents: number;
  payment_reference: string | null;
  items: unknown;
  token_reference: string | null;
  member_code: string;
}

interface WorkerStats {
  recovered_resolved: number;
  recovered_charged: number;
  charged: number;
  succeeded: number;
  declined: number;
  pending: number;
  mismatches: number;
  no_card: number;
  notes: string[];
}

function newWorkerStats(): WorkerStats {
  return {
    recovered_resolved: 0,
    recovered_charged: 0,
    charged: 0,
    succeeded: 0,
    declined: 0,
    pending: 0,
    mismatches: 0,
    no_card: 0,
    notes: [],
  };
}

/* The seeded sandbox marker of migration 029 section 4:
   'sandbox-card:<number>:<month>:<year>'. ONLY the confirmed
   non-3DS Braintree sandbox numbers are ever seeded (Howard's card
   rule); this parser trusts nothing and refuses any other shape.
   The real S2 path uses vaulted mandates and never stores a
   number; this marker exists for the seeded TEST subscriptions
   alone. */
function parseSandboxCard(
  token: string | null,
): { number: string; month: string; year: string } | null {
  if (!token || !token.startsWith("sandbox-card:")) return null;
  const parts = token.split(":");
  if (parts.length !== 4) return null;
  const [, number, month, year] = parts;
  if (!/^\d{12,19}$/.test(number)) return null;
  if (!/^\d{1,2}$/.test(month) || !/^\d{4}$/.test(year)) return null;
  return { number, month, year };
}

/* Reprice a renewal order from the pricing mirror: the engine's
   items carry sku (the shop slug), quantity, and covered_months;
   the month price comes from CATALOG's sub mode, never from the
   stored line, so a stale stored copy can never reprice itself.
   Renewals carry no activation fee and no tax (spec section 9
   step 5 and the dispatch shape of migration 026), so the total
   is exactly the sum of line cents. Null = the items are not a
   renewal shape this worker understands, which is a refusal. */
function repriceRenewalCents(items: unknown): number | null {
  if (!Array.isArray(items) || items.length === 0) return null;
  let total = 0;
  for (const raw of items) {
    if (raw === null || typeof raw !== "object") return null;
    const line = raw as Record<string, unknown>;
    const sku = typeof line.sku === "string" ? line.sku : "";
    const quantity = Number(line.quantity);
    const coveredMonths = Number(line.covered_months ?? 1);
    if (!(sku in CATALOG)) return null;
    if (!Number.isInteger(quantity) || quantity < 1) return null;
    if (![1, 2, 3, 6].includes(coveredMonths)) return null;
    total += toCents(CATALOG[sku].sub.price) * coveredMonths * quantity;
  }
  return total;
}

async function loadLiveAttempts(
  client: DbClient,
  where: "lingering" | { run_id: number },
): Promise<LiveAttempt[]> {
  const filter = where === "lingering" ? "" : "and ba.run_id = $1";
  const args = where === "lingering" ? [] : [where.run_id];
  const rows = await client.queryObject<{
    attempt_id: number;
    run_id: number;
    demo_order_id: number;
    order_number: string;
    total_cents: number;
    payment_reference: string | null;
    items: unknown;
    token_reference: string | null;
    member_code: string;
  }>(
    `select ba.id as attempt_id, ba.run_id, ba.demo_order_id,
            o.order_number, o.total_cents, o.payment_reference, o.items,
            c.token_reference, m.member_code
       from app.billing_attempts ba
       join app.demo_orders o on o.id = ba.demo_order_id
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
       join app.subscriptions s on s.id = rp.subscription_id
       join app.members m on m.id = s.member_id
       left join app.payment_credentials c on c.id = s.credential_id
      where ba.outcome = 'dispatched'
        and ba.dispatch_mode = 'live'
        ${filter}
      order by ba.id`,
    args,
  );
  return rows.rows.map((r) => ({
    ...r,
    attempt_id: Number(r.attempt_id),
    run_id: Number(r.run_id),
    demo_order_id: Number(r.demo_order_id),
  }));
}

async function hsRetrieve(
  apiKey: string,
  paymentId: string,
): Promise<Record<string, unknown> | "unreachable" | "error"> {
  try {
    const resp = await fetch(
      `${HYPERSWITCH_BASE_URL}/payments/${encodeURIComponent(paymentId)}`,
      {
        method: "GET",
        headers: { "api-key": apiKey },
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!resp.ok) return "error";
    return (await resp.json()) as Record<string, unknown>;
  } catch {
    return "unreachable";
  }
}

/* Search the rail by metadata.billing_attempt_id: the recovery path
   of 029's contract. The list endpoint carries no metadata filter,
   so recent payments are listed and matched here; renewal volume at
   this scale sits comfortably inside one page. */
async function hsFindByAttemptId(
  apiKey: string,
  attemptId: number,
): Promise<Record<string, unknown> | null | "unreachable"> {
  try {
    const resp = await fetch(
      `${HYPERSWITCH_BASE_URL}/payments/list?limit=100`,
      {
        method: "GET",
        headers: { "api-key": apiKey },
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!resp.ok) return null;
    const body = (await resp.json()) as { data?: unknown[] };
    for (const p of body.data ?? []) {
      const pay = p as Record<string, unknown>;
      const meta = pay.metadata as Record<string, unknown> | null | undefined;
      if (meta && String(meta.billing_attempt_id ?? "") === String(attemptId)) {
        return pay;
      }
    }
    return null;
  } catch {
    return "unreachable";
  }
}

/* RECORD WHAT THE RAIL ACTUALLY SAID (2026-08-18).

   The engine's verdict door, fn_record_live_verdict, is a gated, specified
   function and is left alone. But it writes 'rail', 'hyperswitch_braintree'
   as a LITERAL, dating from when Braintree was the only connector, and it
   only clears the 'simulated' flag on success. So before this, every live
   renewal was filed as Braintree even when Authorize.net handled it, and
   every live DECLINE was still flagged simulated.

   The worker already holds the retrieve, which names the connector and
   carries the processor's own message. Discarding it meant the only way to
   learn which processor took a renewal was to export from the vendor
   dashboard, and the only decline detail we kept was a bare code.

   This writes the presentation truth alongside the engine's verdict:
   the real connector, the processor's message, and simulated = false on
   BOTH outcomes. */
async function recordRailFacts(
  client: DbClient,
  attemptId: number,
  hs: Record<string, unknown>,
): Promise<void> {
  const str = (v: unknown, max: number) =>
    typeof v === "string" && v.trim() !== "" ? v.trim().slice(0, max) : null;
  try {
    await client.queryArray(
      `update app.demo_orders
          set processor_summary = coalesce(processor_summary, '{}'::jsonb)
              || jsonb_build_object(
                   'simulated',     false,
                   'connector',     $2::text,
                   'rail',          case when $2::text is not null
                                         then 'hyperswitch_' || $2::text
                                         else 'hyperswitch' end,
                   'error_code',    $3::text,
                   'error_message', $4::text)
        where id = (select demo_order_id from app.billing_attempts where id = $1)`,
      [attemptId, str(hs.connector, 64), str(hs.error_code, 64), str(hs.error_message, 500)],
    );
  } catch (err) {
    /* Never let bookkeeping undo a verdict: the money answer is already
       written and correct. Log and carry on. */
    console.error(
      `billing-console worker: could not record rail facts for attempt ${attemptId}: ` +
        (err instanceof Error ? err.message : String(err)),
    );
  }
}

/* Apply a retrieved payment's truth to one attempt through the
   engine's verdict door. Returns what happened, for the stats. */
async function resolveFromPayment(
  client: DbClient,
  att: LiveAttempt,
  hs: Record<string, unknown>,
): Promise<"succeeded" | "declined" | "pending" | "mismatch"> {
  const hsStatus = typeof hs.status === "string" ? hs.status : "unknown";
  const paymentId = typeof hs.payment_id === "string" ? hs.payment_id : null;
  const mapped = mapHyperswitchStatus(hsStatus);

  if (mapped.status === "succeeded") {
    /* The exact integer amount match, the checkout's evidentiary
       bar, before any succeeded verdict is written. */
    const amountOk = Number(hs.amount) === att.total_cents;
    const receivedOk = hs.amount_received === undefined ||
      hs.amount_received === null ||
      Number(hs.amount_received) === att.total_cents;
    if (!amountOk || !receivedOk) {
      console.error(
        `billing-console worker: AMOUNT MISMATCH on ${att.order_number} ` +
          `(expected ${att.total_cents}); attempt ${att.attempt_id} left dispatched for a human`,
      );
      return "mismatch";
    }
    await client.queryArray(
      `select app.fn_record_live_verdict($1, 'succeeded', null, $2)`,
      [att.attempt_id, paymentId],
    );
    await recordRailFacts(client, att.attempt_id, hs);
    return "succeeded";
  }

  if (mapped.status === "failed") {
    const declineCode = typeof hs.error_code === "string" && hs.error_code !== ""
      ? hs.error_code
      : String(mapped.reason ?? "declined");
    await client.queryArray(
      `select app.fn_record_live_verdict($1, 'declined', $2, $3)`,
      [att.attempt_id, declineCode.slice(0, 64), paymentId],
    );
    await recordRailFacts(client, att.attempt_id, hs);
    return "declined";
  }

  /* Non-terminal on the rail: not this worker's call to make. The
     attempt stays dispatched and the next sweep asks again. */
  return "pending";
}

/* Charge one live attempt: reprice, create with confirm, stamp the
   reference, retrieve, verdict. Every early return leaves the
   attempt honestly 'dispatched' for the sweep. */
async function chargeLiveAttempt(
  client: DbClient,
  apiKey: string,
  att: LiveAttempt,
  stats: WorkerStats,
): Promise<void> {
  /* Step 1: reprice from the mirror; the frozen total is the
     promise and a drifted catalog stops the charge (FM3). */
  const repriced = repriceRenewalCents(att.items);
  if (repriced === null || repriced !== att.total_cents) {
    stats.mismatches++;
    console.error(
      `billing-console worker: REPRICE MISMATCH on ${att.order_number} ` +
        `(frozen ${att.total_cents}, repriced ${repriced}); attempt ${att.attempt_id} not charged`,
    );
    return;
  }

  /* The card: the seeded sandbox marker only. An attempt without
     one is not chargeable by this worker (the vaulted-mandate path
     is future work); it stays dispatched and visible. */
  const card = parseSandboxCard(att.token_reference);
  if (card === null) {
    stats.no_card++;
    console.error(
      `billing-console worker: no chargeable credential on attempt ${att.attempt_id} (${att.order_number}); left dispatched`,
    );
    return;
  }

  /* Step 2: create WITH confirm, no_three_ds. A renewal is a
     Merchant Initiated Transaction: no external authentication is
     requested and no challenge flow can open (ruling 8.4; any
     challenge on any renewal fails acceptance A3 outright). */
  let createResp: Response;
  try {
    createResp = await fetch(`${HYPERSWITCH_BASE_URL}/payments`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "api-key": apiKey },
      body: JSON.stringify({
        amount: att.total_cents,
        currency: "USD",
        capture_method: "automatic",
        confirm: true,
        authentication_type: "no_three_ds",
        payment_method: "card",
        payment_method_data: {
          card: {
            card_number: card.number,
            card_exp_month: card.month.padStart(2, "0"),
            card_exp_year: card.year,
            card_holder_name: "Orvanna Demo",
            /* Sandbox card verification value: the seeded numbers
               are the published Braintree sandbox pair, which
               accept any three digits. Never a real card's value,
               because never a real card. */
            card_cvc: "123",
          },
        },
        billing: WORKER_BILLING_ADDRESS,
        description:
          `Orvanna renewal ${att.order_number} (test mode, no real money)`,
        metadata: {
          channel: "renewal_engine",
          billing_attempt_id: String(att.attempt_id),
          order_number: att.order_number,
        },
      }),
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    /* Ambiguous wire failure: the create may or may not have
       landed. NO verdict (see the argued deviation above); the
       attempt stays dispatched and the next sweep resolves it from
       the rail's own ledger. */
    stats.pending++;
    stats.notes.push(
      `attempt ${att.attempt_id}: create unreachable; left for the sweep`,
    );
    return;
  }

  if (!createResp.ok) {
    /* The rail answered and refused the request itself (malformed,
       misconfigured): nothing was created. Status code only, never
       the body wholesale. Left dispatched, loud, for a human; the
       sweep will confirm the rail never saw it and try again. */
    stats.pending++;
    console.error(
      `billing-console worker: HyperSwitch POST /payments returned ${createResp.status} on attempt ${att.attempt_id}`,
    );
    return;
  }

  const created = (await createResp.json()) as Record<string, unknown>;
  const paymentId = typeof created.payment_id === "string"
    ? created.payment_id
    : null;

  if (paymentId !== null) {
    /* Bookkeeping, immediately: the reference is what makes the
       next crash recoverable by direct retrieve instead of a list
       search. payment_status is untouched here; only the engine's
       verdict door moves it. */
    await client.queryArray(
      `update app.demo_orders set payment_reference = $1
        where id = $2 and payment_reference is null`,
      [paymentId, att.demo_order_id],
    );
  }

  stats.charged++;

  /* Step 3: the FRESH retrieve. The create response is not trusted
     as the verdict, exactly as the checkout never trusts its
     confirm response: one retrieve path, one evidentiary bar. */
  if (paymentId === null) {
    stats.pending++;
    console.error(
      `billing-console worker: create returned no payment_id on attempt ${att.attempt_id}; left for the sweep`,
    );
    return;
  }
  const hs = await hsRetrieve(apiKey, paymentId);
  if (hs === "unreachable" || hs === "error") {
    stats.pending++;
    stats.notes.push(
      `attempt ${att.attempt_id}: retrieve failed after create; left for the sweep`,
    );
    return;
  }

  const outcome = await resolveFromPayment(client, att, hs);
  if (outcome === "succeeded") stats.succeeded++;
  else if (outcome === "declined") stats.declined++;
  else if (outcome === "mismatch") stats.mismatches++;
  else stats.pending++;
}

/* The FM2 sweep: every lingering dispatched live attempt, resolved
   from the rail's own ledger before any new work. */
async function sweepLiveStrands(
  client: DbClient,
  apiKey: string,
  stats: WorkerStats,
): Promise<void> {
  const strands = await loadLiveAttempts(client, "lingering");
  for (const att of strands) {
    let payment: Record<string, unknown> | null = null;
    if (att.payment_reference) {
      const hs = await hsRetrieve(apiKey, att.payment_reference);
      if (hs === "unreachable" || hs === "error") {
        stats.pending++;
        continue;
      }
      payment = hs;
    } else {
      const found = await hsFindByAttemptId(apiKey, att.attempt_id);
      if (found === "unreachable") {
        stats.pending++;
        continue;
      }
      payment = found;
    }

    if (payment !== null) {
      const outcome = await resolveFromPayment(client, att, payment);
      if (outcome === "pending") stats.pending++;
      else {
        stats.recovered_resolved++;
        if (outcome === "succeeded") stats.succeeded++;
        else if (outcome === "declined") stats.declined++;
        else stats.mismatches++;
      }
    } else {
      /* The rail has never seen this attempt: charging it now is
         safe by construction (no payment exists to double). */
      stats.recovered_charged++;
      await chargeLiveAttempt(client, apiKey, att, stats);
    }
  }
}

/* ------------------------------------------------------------
   run_execute: the confirm step after the mandatory preview.

   Gates, in order, each refusal audited, none reachable from the
   page alone (a crafted request meets the same walls):
     1. dispatch must be EXPLICIT: 'live' or 'simulated', never
        defaulted by page or server (029's contract line).
     2. tick_date must be a real date; limit per ruling R9.
     3. The engine must answer READY: migrations 028 and 029
        present (the three-argument tick, the verdict door, the
        dispatch_mode seam). Before the deploy round applies them,
        this refusal is the honest state of the cloud.
     4. For live dispatch additionally: the HyperSwitch key is
        configured and the migration 029 seeded sandbox credentials
        exist (Howard's card rule made data; without them there is
        nothing chargeable and 'live' would be a lie).
     5. The engine's own refusals (clock uninitialized, wrong tick
        date, bad limit) surface VERBATIM as engine_refused.
   NOTHING here writes app.sim_clock, ever: its initialization is
   the deploy-round operator's explicit act, recorded in 029's
   acceptance procedure.

   Note on OQ8 (simulations never run in production): dispatch
   'simulated' exists in the payload because 029's contract names
   it for the proof environments; every invocation is audited with
   its dispatch mode, so a simulated run against the wrong database
   is at least never a silent one.
   ------------------------------------------------------------ */
async function actionRunExecute(
  req: Request,
  client: DbClient,
  identity: StaffIdentity,
  ipHash: string,
  params: Record<string, unknown>,
): Promise<Response> {
  const refuse = async (
    httpStatus: number,
    code: string,
    message: string,
    detail: Record<string, unknown> = {},
  ) => {
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: "billing_run_execute",
      target: "billing_runs",
      outcome: "refused",
      outcome_code: code,
      ip_hash: ipHash,
      detail,
    });
    return errorResponse(req, httpStatus, code, message);
  };

  if (!EXECUTE_ENABLED) {
    return await refuse(
      409,
      "s2_pending",
      "Executing a billing run is disabled in this build.",
    );
  }

  const runLimit = parseRunLimit(params.run_limit ?? params.limit);
  if (runLimit === "invalid") {
    return await refuse(
      400,
      "bad_limit",
      "Number to run is blank for all due, or a positive whole number.",
    );
  }

  const dispatch = params.dispatch;
  if (dispatch !== "live" && dispatch !== "simulated") {
    return await refuse(
      400,
      "dispatch_required",
      "Say explicitly how to dispatch: live (the real test rail) or simulated (the scripted processor). The console never defaults this.",
      { dispatch: String(dispatch ?? "") },
    );
  }

  const tickDateRaw = typeof params.tick_date === "string"
    ? params.tick_date.trim()
    : "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(tickDateRaw)) {
    return await refuse(
      400,
      "bad_tick_date",
      "The tick date is YYYY-MM-DD.",
      { tick_date: tickDateRaw },
    );
  }

  /* Gate 3: is the engine's execute seam actually present? */
  const ready = await client.queryObject<{
    tick_fn: boolean;
    verdict_fn: boolean;
    seam_col: boolean;
    sandbox_creds: number;
  }>(
    `select
       to_regprocedure('app.fn_billing_tick(date,integer,text)') is not null as tick_fn,
       to_regprocedure('app.fn_record_live_verdict(bigint,text,text,text)') is not null as verdict_fn,
       exists (select 1 from information_schema.columns
                where table_schema = 'app' and table_name = 'billing_attempts'
                  and column_name = 'dispatch_mode') as seam_col,
       (select count(*) from app.payment_credentials
         where token_reference like 'sandbox-card:%'
           and retired_on is null)::int as sandbox_creds`,
  );
  const r = ready.rows[0];
  if (!r?.tick_fn || !r?.verdict_fn || !r?.seam_col) {
    return await refuse(
      409,
      "engine_not_ready",
      "The engine's execute seam (migrations 028 and 029) is not applied to this database yet; the deploy round applies it after the gates. Until then the console previews only.",
      { tick_fn: r?.tick_fn, verdict_fn: r?.verdict_fn, seam_col: r?.seam_col },
    );
  }

  const apiKey = Deno.env.get("HYPERSWITCH_API_KEY");
  if (dispatch === "live") {
    if (!apiKey) {
      return await refuse(
        500,
        "not_configured",
        "The payment rail is not configured on this function.",
      );
    }
    if ((r.sandbox_creds ?? 0) < 1) {
      return await refuse(
        409,
        "live_credentials_missing",
        "No seeded sandbox credentials exist (migration 029's test-subscription seed has not run), so a live dispatch has nothing chargeable. Seed first, per the deploy-round acceptance.",
      );
    }
  }

  const stats = newWorkerStats();

  /* FM2 FIRST: sweep lingering live strands before any new work. */
  if (dispatch === "live" && apiKey) {
    await sweepLiveStrands(client, apiKey, stats);
  }

  /* THE TICK. The engine's own refusals (clock, date arithmetic,
     limit) are the rules and surface verbatim. */
  let runId: number;
  try {
    const tick = await client.queryObject<{ run_id: number }>(
      `select app.fn_billing_tick($1::date, $2, $3) as run_id`,
      [tickDateRaw, runLimit, dispatch],
    );
    runId = Number(tick.rows[0]?.run_id);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: "billing_run_execute",
      target: "billing_runs",
      outcome: "refused",
      outcome_code: "engine_refused",
      ip_hash: ipHash,
      detail: {
        tick_date: tickDateRaw,
        run_limit: runLimit,
        dispatch,
        engine_message: message.slice(0, 500),
      },
    });
    return errorResponse(req, 409, "engine_refused", message);
  }

  /* THE WORKER: this run's live attempts, ordered by id. */
  if (dispatch === "live" && apiKey) {
    const attempts = await loadLiveAttempts(client, { run_id: runId });
    for (const att of attempts) {
      await chargeLiveAttempt(client, apiKey, att, stats);
    }
    /* Contract step 4: the bridge, idempotently, so verdicts
       recorded after the tick's own bridge still book volume. */
    await client.queryArray(`select app.fn_bridge_demo_orders(true)`);
  }

  /* The run row, with 028's arithmetic, read back as the answer. */
  const runRow = await client.queryObject<Record<string, unknown>>(
    `select br.id, br.tick_date, br.status, br.subscriptions_due,
            br.attempts_made, br.succeeded, br.declined,
            to_jsonb(br) as raw
       from app.billing_runs br where br.id = $1`,
    [runId],
  );
  const row = runRow.rows[0] ?? {};
  const { raw: rowRaw, ...rowKnown } = row;

  await auditStaffAction(client, {
    actor: identity.user,
    actor_role: identity.role,
    action: "billing_run_execute",
    target: `billing_run:${runId}`,
    outcome: "allowed",
    outcome_code: null,
    ip_hash: ipHash,
    detail: {
      tick_date: tickDateRaw,
      run_limit: runLimit,
      dispatch,
      run_id: runId,
      worker: { ...stats, notes: stats.notes.slice(0, 10) },
    },
  });

  return jsonResponse(req, 200, {
    action: "run_execute",
    run_id: runId,
    tick_date: tickDateRaw,
    dispatch,
    run_limit: runLimit,
    run: {
      ...rowKnown,
      id: runId,
      limit_info: pickLimitInfo(rowRaw as Record<string, unknown>),
    },
    worker: dispatch === "live" ? stats : null,
  });
}

/* ------------------------------------------------------------
   run_history and run_detail (spec 9A.2 row 3; the brief's E13).
   member-fault and system-fault failures are separate columns on
   the run row itself (migration 024 deviation D4), so the two
   families can never hide inside each other's statistics.
   ------------------------------------------------------------ */
/* Migration 028's run-record arithmetic, ALIGNED to its real
   column names (landed in commit 61ebe26): limit_requested (null =
   unlimited), due_count, processed_count, remaining_count, plus
   migration 029's dispatch_mode. Still read from the row's JSON
   image rather than named in SQL, because the cloud database may
   not carry 028/029 until the deploy round applies them: absent
   means null, and nothing errors either side of the apply. */
function pickLimitInfo(
  raw: Record<string, unknown> | null | undefined,
): {
  limit_requested: number | null;
  due_count: number | null;
  processed_count: number | null;
  remaining_count: number | null;
  dispatch_mode: string | null;
} {
  const pickNum = (name: string): number | null => {
    if (!raw) return null;
    const v = raw[name];
    return v !== undefined && v !== null && Number.isFinite(Number(v))
      ? Number(v)
      : null;
  };
  return {
    limit_requested: pickNum("limit_requested"),
    due_count: pickNum("due_count"),
    processed_count: pickNum("processed_count"),
    remaining_count: pickNum("remaining_count"),
    dispatch_mode: raw && typeof raw.dispatch_mode === "string"
      ? raw.dispatch_mode
      : null,
  };
}

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
    raw: Record<string, unknown>;
  }>(
    `select br.id, br.tick_date, br.engine_version, br.clock_source,
            br.status, br.started_at, br.finished_at,
            br.subscriptions_due, br.attempts_made,
            br.succeeded, br.declined, br.attempts_reconciled,
            br.member_fault_failures, br.system_fault_failures,
            br.promo_hook_identity, br.mit_invariant_ok, br.notes,
            to_jsonb(br) as raw
       from app.billing_runs br
      order by br.id desc
      limit $1 offset $2`,
    [limit, offset],
  );
  const total = await client.queryObject<{ total: number }>(
    `select count(*)::int as total from app.billing_runs`,
  );
  return jsonResponse(req, 200, {
    action: "run_history",
    runs: runs.rows.map((r) => {
      const { raw, ...known } = r;
      return { ...known, id: Number(r.id), limit_info: pickLimitInfo(raw) };
    }),
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
    `select br.id, br.tick_date, br.engine_version, br.clock_source,
            br.status, br.started_at, br.finished_at,
            br.subscriptions_due, br.attempts_made,
            br.succeeded, br.declined, br.attempts_reconciled,
            br.member_fault_failures, br.system_fault_failures,
            br.promo_hook_identity, br.mit_invariant_ok, br.notes,
            to_jsonb(br) as raw
       from app.billing_runs br where br.id = $1`,
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
    /* The ORDINARY next billing date, so a row can answer "when does this
       one come round again" without the reader doing calendar arithmetic.
       Derived, never stored: it is whatever the schedule says now. */
    next_billing_date: Date | null;
    connector: string | null;
    processor_message: string | null;
  }>(
    `select ba.id as attempt_id, m.member_code,
            rp.subscription_id, rp.renewal_index,
            ba.attempt_no, ba.attempt_kind, ba.ladder_step,
            ba.scheduled_for, o.order_number,
            ba.outcome, ba.decline_code, ba.decline_class,
            ba.member_fault, ba.next_action, ba.next_retry_date,
            nb.next_billing_date,
            o.processor_summary->>'connector'     as connector,
            o.processor_summary->>'error_message' as processor_message
       from app.billing_attempts ba
       join app.renewal_periods rp on rp.id = ba.renewal_period_id
       join app.subscriptions s on s.id = rp.subscription_id
       join app.members m on m.id = s.member_id
       left join app.demo_orders o on o.id = ba.demo_order_id
       left join app.v_subscription_next_billing nb
              on nb.subscription_id = rp.subscription_id
      where ba.run_id = $1
      order by m.member_code, rp.renewal_index, ba.attempt_no`,
    [runId],
  );

  const { raw: runRaw, ...runKnown } = run.rows[0];
  return jsonResponse(req, 200, {
    action: "run_detail",
    run: {
      ...runKnown,
      id: Number(run.rows[0].id),
      limit_info: pickLimitInfo(runRaw as Record<string, unknown>),
    },
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
/* ------------------------------------------------------------
   clear_attention: record that a human LOOKED at a queue row.

   This moves no money. It changes no subscription state. It does
   not remove the row from the queue -- the row leaves when the
   underlying fault is actually resolved, not when somebody
   acknowledges it. The console says exactly that on the page, and
   this function is what keeps the sentence true.

   The operator is taken from the verified staff identity and never
   from the request body, the same rule every other write here
   follows. Idempotent per (subscription, renewal, reason) so a
   double click writes once and a second operator's note replaces
   rather than duplicates.
   ------------------------------------------------------------ */
async function actionClearAttention(
  req: Request,
  client: DbClient,
  identity: StaffIdentity,
  ipHash: string,
  params: Record<string, unknown>,
): Promise<Response> {
  const subscriptionId = toInt(params.subscription_id, 0);
  const renewalIndex = toInt(params.renewal_index, -1);
  const reason = typeof params.reason === "string" ? params.reason.trim() : "";
  const note = typeof params.note === "string" ? params.note.trim() : null;
  const target = subscriptionId > 0
    ? `subscription:${subscriptionId}/${renewalIndex}`
    : null;

  const refuse = async (code: string, message: string) => {
    await auditStaffAction(client, {
      actor: identity.user,
      actor_role: identity.role,
      action: "billing_clear_attention",
      target,
      outcome: "refused",
      outcome_code: code,
      ip_hash: ipHash,
      detail: { params: { ...params } },
    });
    return errorResponse(req, 400, code, message);
  };

  if (subscriptionId <= 0) {
    return await refuse("bad_subscription", "A subscription number is required.");
  }
  if (renewalIndex < 0) {
    return await refuse("bad_renewal_index", "A renewal index is required.");
  }
  if (!reason) {
    return await refuse("bad_reason", "A reason is required.");
  }
  if (note !== null && note.length > 500) {
    return await refuse("note_too_long", "The note is longer than 500 characters.");
  }

  /* The row must actually BE in the queue. Without this a clear could be
     written for anything at all, and the audit log would then record a
     human looking at something that was never asking to be looked at. */
  const present = await client.queryObject<{ n: number }>(
    `select count(*)::int as n
       from app.v_staff_attention_queue
      where subscription_id = $1 and renewal_index = $2 and reason = $3`,
    [subscriptionId, renewalIndex, reason],
  );
  if ((present.rows[0]?.n ?? 0) === 0) {
    return await refuse("not_in_queue", "That row is not in the attention queue.");
  }

  await client.queryObject(
    `insert into app.attention_cleared
       (subscription_id, renewal_index, reason, cleared_by, note)
     values ($1, $2, $3, $4, $5)
     on conflict (subscription_id, renewal_index, reason)
       do update set cleared_by = excluded.cleared_by,
                     note       = excluded.note,
                     cleared_at = now()`,
    [subscriptionId, renewalIndex, reason, identity.user, note],
  );

  await auditStaffAction(client, {
    actor: identity.user,
    actor_role: identity.role,
    action: "billing_clear_attention",
    target,
    outcome: "allowed",
    outcome_code: null,
    ip_hash: ipHash,
    detail: { reason, note },
  });

  /* Re-read and return server state rather than echoing what was sent. */
  const back = await client.queryObject<{
    cleared_by: string;
    cleared_at: string;
  }>(
    `select cleared_by, cleared_at
       from app.attention_cleared
      where subscription_id = $1 and renewal_index = $2 and reason = $3`,
    [subscriptionId, renewalIndex, reason],
  );

  return jsonResponse(req, 200, {
    action: "clear_attention",
    subscription_id: subscriptionId,
    renewal_index: renewalIndex,
    reason,
    cleared_by: back.rows[0]?.cleared_by ?? identity.user,
    cleared_at: back.rows[0]?.cleared_at ?? null,
    moved_money: false,
  });
}

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
    amount_at_stake: string | null;
    deadline_at: string | null;
    decline_class: string | null;
    cleared_by: string | null;
    cleared_at: string | null;
  }>(
    `select q.reason, m.member_code, q.subscription_id, q.renewal_index,
            q.billing_attempt_id, q.detail, s.state,
            q.amount_at_stake, q.deadline_at, q.decline_class,
            ac.cleared_by, ac.cleared_at
       from app.v_staff_attention_queue q
       join app.subscriptions s on s.id = q.subscription_id
       join app.members m on m.id = s.member_id
       left join app.attention_cleared ac
              on ac.subscription_id = q.subscription_id
             and ac.renewal_index   = q.renewal_index
             and ac.reason          = q.reason
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
      /* NULL IS NOT ZERO, and it travels as null all the way to the screen.
         A cycle gap has no renewal period to price and nothing was going to
         be charged; printing 0.00 for it would say the opposite of the
         truth on the one page where money decides what a human touches
         first. The console renders an em dash. */
      amount_at_stake: r.amount_at_stake === null
        ? null
        : Number(r.amount_at_stake),
      deadline_at: r.deadline_at,
      decline_class: r.decline_class,
      /* Server state, not the browser's. Two operators can be looking at
         this queue, so what is cleared is read back rather than remembered
         locally. */
      cleared_by: r.cleared_by,
      cleared_at: r.cleared_at,
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
        response = await actionRunPreview(req, client, body);
        break;
      case "run_execute":
        response = await actionRunExecute(
          req,
          client,
          auth.identity,
          ipHash,
          body,
        );
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
      case "clear_attention":
        response = await actionClearAttention(
          req,
          client,
          auth.identity,
          ipHash,
          body,
        );
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
