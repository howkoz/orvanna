/* ============================================================
   Shared Edge Function plumbing for the Orvanna demo checkout.

   Covers, per MLM-PILOT/docs/PHASE-6-SPEC.md:
   - Cross-Origin Resource Sharing (CORS) locked to
     https://orvanna.io plus localhost origins for development
     (spec section 5.2 allows "a localhost origin while
     developing").
   - Structured JavaScript Object Notation (JSON) responses and
     errors: every error body is { error: { code, message } }.
   - Salted caller Internet Protocol (IP) address hashing. The
     raw IP is never stored and never logged (spec section 2.3).
   - Rate limiting backed by app.demo_rate_events (spec 5.1).
   - Database access. DESIGN NOTE: these functions talk to
     Postgres over the platform-injected direct connection
     string (SUPABASE_DB_URL), the official Supabase pattern for
     Edge Functions that need tables outside the REST layer.
     The app schema is deliberately NOT exposed to the REST
     layer (only the seven public v_demo_* views are), and the
     spec forbids widening that surface. This connection exists
     only inside the functions, exactly like the service role:
     server-side privileged access, nothing new for the anon
     key. No secret here is typed by anyone; Supabase injects
     SUPABASE_DB_URL itself.

   SECRETS: read only via Deno.env.get, never hardcoded. Names
   per spec section 3: HYPERSWITCH_API_KEY,
   HYPERSWITCH_PUBLISHABLE_KEY, ORVANNA_DEMO_IP_SALT.
   HYPERSWITCH_HASH_KEY is read by payment-webhook only, to
   verify the signature HyperSwitch puts on its outgoing
   webhooks.

   This file also holds the ONE implementation of "ask
   HyperSwitch and write the truth" (retrieveAndApplyPaymentTruth
   below). Both confirm-payment (browser-triggered) and
   payment-webhook (processor-triggered) call it, so the trust
   model cannot drift between the two callers.
   ============================================================ */

import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

/* ---------- database pool (lazy, small: demo traffic) ---------- */

let pool: Pool | null = null;

export function getPool(): Pool {
  if (pool === null) {
    const dbUrl = Deno.env.get("SUPABASE_DB_URL");
    if (!dbUrl) {
      throw new Error("SUPABASE_DB_URL is not set");
    }
    pool = new Pool(dbUrl, 2, true /* lazy */);
  }
  return pool;
}

/* ---------- CORS ---------- */

const PRODUCTION_ORIGIN = "https://orvanna.io";
const LOCALHOST_RE = /^http:\/\/localhost(:\d+)?$/;
const LOOPBACK_RE = /^http:\/\/127\.0\.0\.1(:\d+)?$/;

export function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return false;
  return (
    origin === PRODUCTION_ORIGIN ||
    LOCALHOST_RE.test(origin) ||
    LOOPBACK_RE.test(origin)
  );
}

/* Headers for an allowed origin; an empty object for anything
   else (no Access-Control-Allow-Origin header means the browser
   refuses the response to foreign pages). */
export function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin");
  if (!isAllowedOrigin(origin)) return {};
  return {
    "Access-Control-Allow-Origin": origin as string,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, apikey, x-client-info, content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

/* Answer a preflight request, or null when this is not one. */
export function preflight(req: Request): Response | null {
  if (req.method !== "OPTIONS") return null;
  return new Response(null, { status: 204, headers: corsHeaders(req) });
}

/* ---------- JSON responses ---------- */

export function jsonResponse(
  req: Request,
  status: number,
  body: unknown,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(req),
      ...extraHeaders,
    },
  });
}

export function errorResponse(
  req: Request,
  status: number,
  code: string,
  message: string,
  extraHeaders: Record<string, string> = {},
): Response {
  return jsonResponse(req, status, { error: { code, message } }, extraHeaders);
}

/* ---------- caller IP hashing (privacy rail) ---------- */

export async function callerIpHash(req: Request): Promise<string> {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  const ip =
    forwarded.split(",")[0].trim() ||
    req.headers.get("cf-connecting-ip") ||
    "unknown";
  const salt = Deno.env.get("ORVANNA_DEMO_IP_SALT") ?? "";
  const data = new TextEncoder().encode(`${salt}|${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/* ---------- rate limiting (spec section 5.1) ----------

   Semantics match the spec's worked example: the current minute
   bucket is READ first; a request at or over the limit is
   refused and NOT counted, so refused requests never extend the
   window. Only an allowed request increments the bucket. */

export interface RateLimitOptions {
  perMinute: number;
  perHour?: number;
}

export interface RateLimitVerdict {
  allowed: boolean;
  retryAfterSeconds: number;
}

export async function checkRateLimit(
  ipHash: string,
  opts: RateLimitOptions,
  scope = "shared",
  existingClient?: DbClient,
): Promise<RateLimitVerdict> {
  /* Scope keeps each function's bucket separate (Phase 6 verifier
     MEDIUM 2): confirm polling must never consume the create
     budget for the same visitor. The ledger key is scope:hash. */
  const key = `${scope}:${ipHash}`;
  /* SPEED, 2026-08-15. A caller that already holds a connection can
     lend it, which removes a whole Postgres connect (transmission
     control protocol, then Transport Layer Security, then
     authentication) from the critical path. In a fresh Edge Function
     isolate that handshake is one of the largest single costs in the
     request, and create-payment was paying it twice: once here and
     once for its own work. Callers that pass nothing keep the old
     behaviour exactly, so the other functions are unaffected. */
  const borrowed = existingClient !== undefined;
  const client = existingClient ?? await getPool().connect();
  try {
    const minuteRow = await client.queryObject<{ request_count: number }>(
      `select request_count
         from app.demo_rate_events
        where ip_hash = $1
          and window_start = date_trunc('minute', now())`,
      [key],
    );
    const minuteCount = minuteRow.rows[0]?.request_count ?? 0;
    if (minuteCount >= opts.perMinute) {
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, 60 - new Date().getUTCSeconds()),
      };
    }

    if (opts.perHour !== undefined) {
      const hourRow = await client.queryObject<{ total: number }>(
        `select coalesce(sum(request_count), 0)::int as total
           from app.demo_rate_events
          where ip_hash = $1
            and window_start > now() - interval '1 hour'`,
        [key],
      );
      const hourCount = hourRow.rows[0]?.total ?? 0;
      if (hourCount >= opts.perHour) {
        return { allowed: false, retryAfterSeconds: 900 };
      }
    }

    await client.queryArray(
      `insert into app.demo_rate_events (ip_hash, window_start, request_count)
       values ($1, date_trunc('minute', now()), 1)
       on conflict (ip_hash, window_start)
       do update set request_count = app.demo_rate_events.request_count + 1`,
      [key],
    );

    /* Opportunistic ledger hygiene (spec 2.3): occasionally drop
       buckets older than 24 hours. Cheap, and keeps the table
       tidy without a scheduler. */
    if (Math.random() < 0.02) {
      await client.queryArray(
        `delete from app.demo_rate_events
          where window_start < now() - interval '24 hours'`,
      );
    }

    return { allowed: true, retryAfterSeconds: 0 };
  } finally {
    /* a borrowed connection belongs to the caller and is theirs to
       release; releasing it here would pull it out from under them */
    if (!borrowed) client.release();
  }
}

/* ---------- HyperSwitch sandbox base ----------

   Sandbox base Uniform Resource Locator (URL) per the public
   HyperSwitch API documentation (api-reference.hyperswitch.io):
   test-mode traffic goes to https://sandbox.hyperswitch.io.
   Endpoints used in v1: POST /payments (create) and
   GET /payments/{payment_id} (retrieve). */
export const HYPERSWITCH_BASE_URL = "https://sandbox.hyperswitch.io";

/* ============================================================
   THE SINGLE SOURCE OF PAYMENT TRUTH

   Everything below implements one operation, used by exactly two
   callers:

     confirm-payment  the browser asks "what happened to my order?"
     payment-webhook  HyperSwitch says "something happened", and we
                      then ask the same question ourselves

   The operation is: retrieve the payment from HyperSwitch with
   the SECRET key, map its status, check the amount to the cent,
   and write a guarded update. Neither caller may skip a step,
   and neither caller may write a status that came from anywhere
   other than this retrieve.

   3-D Secure (3DS) note: 3DS authenticates the cardholder; it
   never reprices. The amount check below therefore stays exactly
   as strong as it was before 3DS existed, and it is the last
   word before any 'succeeded' is written.
   ============================================================ */

/* The exact type the connection pool hands out, without naming
   a symbol the driver may or may not re-export. */
export type DbClient = Awaited<ReturnType<Pool["connect"]>>;

/* The three states our column can hold while a payment is live.
   ('abandoned' is written by the sweep, never by a retrieve.) */
export type OrvannaPaymentStatus = "succeeded" | "failed" | "processing";

/* A machine-readable, plain-English-ish explanation of WHY a
   payment is in the state it is in. This is what lets the site
   tell "your bank did not confirm it was you" apart from "your
   bank confirmed it was you and then declined the money", which
   are two different sentences to a shopper and two different
   next actions. */
export type OrvannaPaymentReason =
  | null
  | "declined"
  | "declined_after_authentication"
  | "authentication_failed"
  | "authentication_error"
  | "cancelled"
  | "cancelled_post_capture"
  | "expired"
  | "awaiting_authentication"
  | "attempt_reset"
  | "not_submitted"
  | "in_flight"
  | "unexpected_capture_state"
  | "needs_human"
  | "unknown_status"
  | "amount_mismatch";

/* The named subset of external_authentication_details we are
   willing to carry to the browser. Named fields only; the raw
   authentication object is never forwarded, per spec 2.2. */
export interface AuthenticationSummary {
  /* Transaction Status (transStatus): one letter from the
     3-D Secure protocol. Y authenticated, N not authenticated,
     A attempted, R rejected by the issuer, U unavailable,
     C challenge required, I informational. */
  trans_status: string | null;
  /* The provider's own word for where authentication got to. */
  authentication_status: string | null;
  /* Electronic Commerce Indicator (ECI): the code that records
     the authentication outcome and decides who carries a fraud
     chargeback. */
  electronic_commerce_indicator: string | null;
  /* EMV 3-D Secure message version, for example 2.2.0. */
  message_version: string | null;
  /* Directory Server (DS) transaction identifier: the network's
     own reference for this authentication. Not personal. */
  ds_transaction_id: string | null;
  error_code: string | null;
  error_message: string | null;
  /* Why a challenge was cancelled, when the provider says. */
  cancel_reason: string | null;
}

/* Coerce an unknown value to a short string, or null. Keeps a
   chatty provider from writing an essay into our row. */
function shortString(value: unknown, max = 200): string | null {
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed === "" ? null : trimmed.slice(0, max);
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value).slice(0, max);
  }
  return null;
}

/* Copy the named authentication fields, or null when the payment
   carried no external authentication at all. Field names are
   read defensively because HyperSwitch spells a few of them more
   than one way across versions.

   MAY BE NULL, AND THE SITE MUST COPE. This object is populated
   on the EXTERNAL authentication path (3DSecure.io), which
   create-payment now requests (Howard's ruling 2026-08-14: the
   billing address requirement is met with a fixed synthetic
   demonstration address, never a shopper's real one). When
   HyperSwitch instead authenticates through the card connector,
   or when a payment never reaches authentication at all, this
   object is absent, `authentication` on the receipt is null, and
   the failure reason stays the plain 'declined' rather than the
   finer authentication-aware reasons. That is correct behaviour,
   not a bug: the site must never require this object in order to
   tell its story. */
export function authenticationSummaryOf(
  raw: unknown,
): AuthenticationSummary | null {
  if (raw === null || typeof raw !== "object") return null;
  const d = raw as Record<string, unknown>;
  const summary: AuthenticationSummary = {
    trans_status: shortString(d.trans_status ?? d.transaction_status, 16),
    authentication_status: shortString(d.authentication_status ?? d.status, 40),
    electronic_commerce_indicator: shortString(
      d.electronic_commerce_indicator ?? d.eci,
      8,
    ),
    message_version: shortString(d.version ?? d.message_version, 16),
    ds_transaction_id: shortString(d.ds_transaction_id, 64),
    error_code: shortString(d.error_code, 64),
    error_message: shortString(d.error_message, 200),
    cancel_reason: shortString(
      d.challenge_cancel ?? d.cancel_reason ?? d.challenge_cancel_reason,
      64,
    ),
  };
  const anyPresent = Object.values(summary).some((v) => v !== null);
  return anyPresent ? summary : null;
}

/* The full HyperSwitch IntentStatus enum, mapped to our three
   live states plus a reason. Source: the payments--retrieve API
   reference. Statuses this function does not recognise are
   treated as non-terminal and reported as 'unknown_status',
   which is the safe direction: an unknown status can never be
   mistaken for success.

   Terminal failures include 'expired' and 'cancelled_post_capture'
   as well as 'failed' and 'cancelled'. */
export function mapHyperswitchStatus(
  hsStatus: string,
): { status: OrvannaPaymentStatus; reason: OrvannaPaymentReason; loud: boolean } {
  switch (hsStatus) {
    case "succeeded":
      return { status: "succeeded", reason: null, loud: false };

    /* ---- terminal failures ---- */
    case "failed":
      /* Refined below by the authentication detail, because
         "we could not confirm it was you" and "we confirmed it
         was you and the bank still said no" are different
         stories with different next actions for the shopper. */
      return { status: "failed", reason: "declined", loud: false };
    case "cancelled":
      return { status: "failed", reason: "cancelled", loud: false };
    case "cancelled_post_capture":
      /* Money was taken and then reversed. Should not happen on
         this demo rail; shout if it does. */
      return { status: "failed", reason: "cancelled_post_capture", loud: true };
    case "expired":
      return { status: "failed", reason: "expired", loud: false };

    /* ---- in flight, and WHY ---- */
    case "requires_customer_action":
      /* The shopper is in front of a bank approval screen. This
         is a patient wait, not an error. */
      return { status: "processing", reason: "awaiting_authentication", loud: false };
    case "requires_payment_method":
      /* The attempt did not complete and HyperSwitch reset the
         intent so another attempt can be made. In a 3DS flow
         this is the usual landing spot for a failed or abandoned
         challenge: tell the shopper to try again. */
      return { status: "processing", reason: "attempt_reset", loud: false };
    case "requires_confirmation":
      return { status: "processing", reason: "not_submitted", loud: false };
    case "processing":
      return { status: "processing", reason: "in_flight", loud: false };

    /* ---- unreachable with capture_method automatic ---- */
    case "requires_capture":
    case "partially_captured":
    case "partially_captured_and_capturable":
    case "partially_authorized_and_requires_capture":
    case "partially_captured_and_processing":
      return { status: "processing", reason: "unexpected_capture_state", loud: true };

    /* ---- a human has to look ---- */
    case "requires_merchant_action":
    case "review":
    case "conflicted":
      return { status: "processing", reason: "needs_human", loud: true };

    default:
      return { status: "processing", reason: "unknown_status", loud: true };
  }
}

/* Sharpen a plain 'declined' using the authentication result.
   Only ever called when the mapped status is 'failed'. */
function refineFailureReason(
  base: OrvannaPaymentReason,
  auth: AuthenticationSummary | null,
): OrvannaPaymentReason {
  if (base !== "declined" || auth === null) return base;
  const trans = (auth.trans_status ?? "").toUpperCase();
  if (trans === "Y" || trans === "A") {
    /* Authenticated, then the money was refused. The shopper did
       nothing wrong; a different card usually works. */
    return "declined_after_authentication";
  }
  if (trans === "N" || trans === "R") {
    /* The bank did not confirm the cardholder. Retry the
       approval step. */
    return "authentication_failed";
  }
  if (trans === "U" || auth.error_code !== null) {
    /* The security check itself could not run. Not the shopper's
       fault and not their card's fault. */
    return "authentication_error";
  }
  return base;
}

/* The sanitized processor summary written to the row. Named
   fields only, never a raw payload, never card data. */
export interface ProcessorSummary {
  status: string;
  connector: string | null;
  payment_method_type: string | null;
  error_code: string | null;
  error_message: string | null;
  reason: OrvannaPaymentReason;
  /* Which of the three challenge shapes HyperSwitch chose, when
     it chose one: three_ds_invoke, redirect_to_url, or
     redirect_inside_popup. Recorded because which one fires
     decides whether the shopper stays on our page. */
  next_action_type: string | null;
  authentication: AuthenticationSummary | null;
  last_synced_at: string;
  synced_by: string;
}

export type PaymentTruthResult =
  | {
    outcome: "resolved";
    hs_status: string;
    new_status: OrvannaPaymentStatus;
    reason: OrvannaPaymentReason;
    amount_mismatch: boolean;
    summary: ProcessorSummary;
  }
  | { outcome: "not_configured" }
  | { outcome: "processor_unreachable" }
  | { outcome: "processor_error"; http_status: number };

/* The statuses a row may be moved FROM. Values are compile-time
   constants from this file, never caller input, so building the
   list into the statement text carries no injection risk. */
function guardList(allowedFrom: readonly OrvannaPaymentStatus[] | readonly string[]): string {
  return allowedFrom.map((s) => `'${s}'`).join(", ");
}

/* ------------------------------------------------------------
   Ask HyperSwitch, check the amount, write the truth.

   Steps, in this order, every time, for every caller:
     1. GET /payments/{payment_id} with the secret key.
     2. Map the status and work out the reason.
     3. Compare the amount to the cent. A mismatch is never
        allowed to be 'succeeded'.
     4. Guarded UPDATE: only a row still in an allowed source
        status may move, so a terminal row is immutable and a
        repeat call is a harmless no-op.
   ------------------------------------------------------------ */
export async function retrieveAndApplyPaymentTruth(
  client: DbClient,
  row: { order_number: string; total_cents: number; payment_reference: string },
  opts: {
    /* Which function is asking. Logged, and stamped into the
       summary so a stuck order can be traced. */
    caller: string;
    /* The webhook may resolve a row the sweep already aged into
       'abandoned', because the database explicitly permits
       abandoned to settle to succeeded or failed (migration 010).
       confirm-payment does not, so its behaviour is unchanged. */
    allowResolveFromAbandoned?: boolean;
  },
): Promise<PaymentTruthResult> {
  const apiKey = Deno.env.get("HYPERSWITCH_API_KEY");
  if (!apiKey) return { outcome: "not_configured" };

  let hsResponse: Response;
  try {
    hsResponse = await fetch(
      `${HYPERSWITCH_BASE_URL}/payments/${encodeURIComponent(row.payment_reference)}`,
      {
        method: "GET",
        headers: { "api-key": apiKey },
        signal: AbortSignal.timeout(15_000),
      },
    );
  } catch {
    return { outcome: "processor_unreachable" };
  }
  if (!hsResponse.ok) {
    /* Log only the status code; never the response body
       wholesale and never any key material. */
    console.error(
      `${opts.caller}: HyperSwitch GET /payments returned ${hsResponse.status} for ${row.order_number}`,
    );
    return { outcome: "processor_error", http_status: hsResponse.status };
  }

  const hs = (await hsResponse.json()) as {
    status?: string;
    amount?: number;
    amount_received?: number | null;
    connector?: string;
    payment_method_type?: string;
    error_code?: string | null;
    error_message?: string | null;
    next_action?: { type?: string } | null;
    external_authentication_details?: unknown;
  };

  const hsStatus = hs.status ?? "unknown";
  const mapped = mapHyperswitchStatus(hsStatus);
  const authentication = authenticationSummaryOf(hs.external_authentication_details);

  let newStatus: OrvannaPaymentStatus = mapped.status;
  let reason: OrvannaPaymentReason = mapped.status === "failed"
    ? refineFailureReason(mapped.reason, authentication)
    : mapped.reason;

  if (mapped.loud) {
    console.error(
      `${opts.caller}: unexpected HyperSwitch status '${hsStatus}' on ${row.order_number} (reason ${reason})`,
    );
  }

  /* ---- amount equality, to the cent, before any 'succeeded' ----
     Integer comparison: both sides are minor units (cents).
     3-D Secure does not change the amount, so this check is
     untouched by the 3DS work and remains the last word. */
  let amountMismatch = false;
  if (newStatus === "succeeded") {
    const amountOk = hs.amount === row.total_cents;
    const receivedOk = hs.amount_received === undefined ||
      hs.amount_received === null ||
      hs.amount_received === row.total_cents;
    if (!amountOk || !receivedOk) {
      amountMismatch = true;
      newStatus = "processing"; /* never succeeded on a mismatch */
      reason = "amount_mismatch";
      console.error(
        `${opts.caller}: amount mismatch on ${row.order_number} (expected ${row.total_cents})`,
      );
    }
  }

  const summary: ProcessorSummary = {
    status: hsStatus,
    connector: hs.connector ?? null,
    payment_method_type: hs.payment_method_type ?? null,
    error_code: amountMismatch ? "amount_mismatch" : hs.error_code ?? null,
    error_message: amountMismatch
      ? "The processor amount did not match the order total."
      : hs.error_message ?? null,
    reason,
    next_action_type: shortString(hs.next_action?.type, 40),
    authentication,
    last_synced_at: new Date().toISOString(),
    synced_by: opts.caller,
  };

  /* ---- guarded update ----
     'created' and 'processing' always. 'abandoned' additionally
     for the webhook, and then ONLY into a terminal state, since
     the database forbids abandoned going back to processing. */
  const allowedFrom: string[] = ["created", "processing"];
  if (
    opts.allowResolveFromAbandoned === true &&
    (newStatus === "succeeded" || newStatus === "failed")
  ) {
    allowedFrom.push("abandoned");
  }

  await client.queryArray(
    `update app.demo_orders
        set payment_status = $1,
            processor_summary = $2::jsonb,
            status_updated_at = now()
      where order_number = $3
        and payment_status in (${guardList(allowedFrom)})`,
    [newStatus, JSON.stringify(summary), row.order_number],
  );

  return {
    outcome: "resolved",
    hs_status: hsStatus,
    new_status: newStatus,
    reason,
    amount_mismatch: amountMismatch,
    summary,
  };
}

/* ------------------------------------------------------------
   The abandon sweep, with a final retrieve first.

   A slow 3-D Secure challenge can easily outlive the one-hour
   abandon window: the shopper is staring at a bank screen on
   their phone while our row sits at 'processing'. Ageing that
   row out unasked would record an abandonment for a payment that
   actually succeeded. So: every candidate that has a
   payment_reference is retrieved one last time, and only rows
   that are still non-terminal AFTER that retrieve are allowed to
   age out.

   Bounded on purpose. Each call rechecks at most maxRetrieves
   rows; anything not rechecked is simply left for the next call
   rather than aged out blind.
   ------------------------------------------------------------ */
export async function sweepAbandonedWithFinalRetrieve(
  client: DbClient,
  opts: { caller: string; maxRetrieves?: number } = { caller: "sweep" },
): Promise<{ candidates: number; rechecked: number; aged_out: number }> {
  const maxRetrieves = opts.maxRetrieves ?? 10;

  const candidates = await client.queryObject<{
    order_number: string;
    total_cents: number;
    payment_reference: string | null;
  }>(
    `select order_number, total_cents, payment_reference
       from app.demo_orders
      where payment_status in ('created', 'processing')
        and created_at < now() - interval '1 hour'
      order by created_at asc
      limit 50`,
  );

  const rows = candidates.rows;
  if (rows.length === 0) {
    return { candidates: 0, rechecked: 0, aged_out: 0 };
  }

  /* Rows that never reached HyperSwitch have nothing to retrieve
     and may age out immediately. */
  const ageOut: string[] = rows
    .filter((r) => !r.payment_reference)
    .map((r) => r.order_number);

  const withReference = rows.filter((r) => r.payment_reference !== null);
  let rechecked = 0;
  for (const r of withReference.slice(0, maxRetrieves)) {
    const result = await retrieveAndApplyPaymentTruth(
      client,
      {
        order_number: r.order_number,
        total_cents: r.total_cents,
        payment_reference: r.payment_reference as string,
      },
      { caller: opts.caller },
    );
    if (result.outcome !== "resolved") {
      /* Could not ask HyperSwitch. Leave the row alone: an
         unanswered question is not an abandonment. */
      continue;
    }
    rechecked++;
    if (result.new_status === "processing") {
      ageOut.push(r.order_number);
    }
  }

  if (ageOut.length === 0) {
    return { candidates: rows.length, rechecked, aged_out: 0 };
  }

  /* The guard repeats the status condition so a row that settled
     between the retrieve and this statement is not disturbed. */
  const result = await client.queryArray(
    `update app.demo_orders
        set payment_status = 'abandoned', status_updated_at = now()
      where order_number = any($1::text[])
        and payment_status in ('created', 'processing')`,
    [ageOut],
  );
  const agedOut = (result as unknown as { rowCount?: number }).rowCount ??
    ageOut.length;

  return { candidates: rows.length, rechecked, aged_out: agedOut };
}

/* ------------------------------------------------------------
   Constant-time byte comparison, for signature checking.

   A plain === on hex strings leaks, through timing, how many
   leading characters an attacker guessed right. This compares
   every byte regardless.
   ------------------------------------------------------------ */
export function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}
