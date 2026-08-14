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
   (HYPERSWITCH_HASH_KEY is vaulted for the v1.1 webhook
   handler and is not read by any v1 function.)
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
): Promise<RateLimitVerdict> {
  const client = await getPool().connect();
  try {
    const minuteRow = await client.queryObject<{ request_count: number }>(
      `select request_count
         from app.demo_rate_events
        where ip_hash = $1
          and window_start = date_trunc('minute', now())`,
      [ipHash],
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
        [ipHash],
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
      [ipHash],
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
    client.release();
  }
}

/* ---------- HyperSwitch sandbox base ----------

   Sandbox base Uniform Resource Locator (URL) per the public
   HyperSwitch API documentation (api-reference.hyperswitch.io):
   test-mode traffic goes to https://sandbox.hyperswitch.io.
   Endpoints used in v1: POST /payments (create) and
   GET /payments/{payment_id} (retrieve). */
export const HYPERSWITCH_BASE_URL = "https://sandbox.hyperswitch.io";
