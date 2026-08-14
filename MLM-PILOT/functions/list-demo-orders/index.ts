/* ============================================================
   list-demo-orders (Supabase Edge Function, Deno)

   Phase 6, work package W2. Spec: MLM-PILOT/docs/PHASE-6-SPEC.md
   section 2.4: the anon key's database surface stays byte for
   byte what it is today (seven views), so recent live demo
   orders are served by THIS rate-limited function reading with
   the server-side connection, not by a new anon-readable view.

   Returns the most recent 25 orders, sanitized fields ONLY:
   order_number, created_at, created_by_channel, item_count,
   total (dollars), pv_total, payment_status. No referral text,
   no processor detail, nothing personal (there is nothing
   personal in the table to begin with).

   Also runs the opportunistic abandon sweep (spec 5.4): rows
   stuck at 'created' or 'processing' for over one hour become
   'abandoned', so the list shows them honestly.
   ============================================================ */

import {
  callerIpHash,
  checkRateLimit,
  errorResponse,
  getPool,
  isAllowedOrigin,
  jsonResponse,
  preflight,
  sweepAbandonedWithFinalRetrieve,
} from "../_shared/edge.ts";

interface ListedOrder {
  order_number: string;
  created_at: Date;
  created_by_channel: string;
  item_count: number;
  total_cents: number;
  pv_total: string | number;
  payment_status: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  const pre = preflight(req);
  if (pre) return pre;

  if (req.method !== "GET" && req.method !== "POST") {
    return errorResponse(req, 405, "method_not_allowed", "Use GET.");
  }
  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return errorResponse(
      req,
      403,
      "origin_not_allowed",
      "This demo only answers its own site.",
    );
  }

  const ipHash = await callerIpHash(req);
  const verdict = await checkRateLimit(ipHash, { perMinute: 20 }, "list");
  if (!verdict.allowed) {
    return errorResponse(
      req,
      429,
      "rate_limited",
      "Too many refreshes in one minute. Please wait a moment and try again.",
      { "Retry-After": String(verdict.retryAfterSeconds) },
    );
  }

  const client = await getPool().connect();
  try {
    /* Opportunistic abandon sweep (spec 5.4), now with a final
       server-side retrieve first: a slow bank approval must never
       be mistaken for an abandonment, which matters far more once
       a 3-D Secure (3DS) challenge can hold a payment open for
       minutes. Gated on one call in four and capped at five
       retrieves so the list stays fast. */
    if (Math.random() < 0.25) {
      await sweepAbandonedWithFinalRetrieve(client, {
        caller: "list-demo-orders",
        maxRetrieves: 5,
      });
    }

    const result = await client.queryObject<ListedOrder>(
      `select order_number,
              created_at,
              created_by_channel,
              jsonb_array_length(items)::int as item_count,
              total_cents,
              pv_total,
              payment_status
         from app.demo_orders
        order by created_at desc
        limit 25`,
    );

    const orders = result.rows.map((row) => ({
      order_number: row.order_number,
      created_at: row.created_at,
      created_by_channel: row.created_by_channel,
      item_count: row.item_count,
      /* total in dollars, two-decimal number (display formats at
         the edge; cents are the storage unit) */
      total: row.total_cents / 100,
      pv_total: Number(row.pv_total),
      payment_status: row.payment_status,
    }));

    return jsonResponse(req, 200, { orders });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`list-demo-orders: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Could not list the recent demo orders right now.",
    );
  } finally {
    client.release();
  }
});
