/* ============================================================
   list-demo-orders (Supabase Edge Function, Deno)

   Phase 6, work package W2. Spec: MLM-PILOT/docs/PHASE-6-SPEC.md
   section 2.4: the anon key's database surface stays byte for
   byte what it is today (seven views), so recent live demo
   orders are served by THIS rate-limited function reading with
   the server-side connection, not by a new anon-readable view.

   Returns the most recent orders, sanitized fields ONLY:
   order_number, created_at, created_by_channel, item_count,
   total (dollars), pv_total, payment_status. No referral text,
   no processor detail, nothing personal (there is nothing
   personal in the table to begin with).

   Also runs the opportunistic abandon sweep (spec 5.4): rows
   stuck at 'created' or 'processing' for over one hour become
   'abandoned', so the list shows them honestly.

   ============================================================
   EXTENDED FOR THE STAFF ORDER HISTORY. NOT DEPLOYED as of
   2026-08-16: the live version is still the original 25-row
   listing. See the DEPLOY BLOCKER note in refund-payment/index.ts.

   NOTE FOR WHOEVER DEPLOYS THIS. The currently deployed bundle
   carries a STALE copy of _shared/edge.ts, from before
   checkRateLimit learned to borrow a caller's connection. Deploying
   this file will also refresh that copy, which is wanted, but it
   means the deploy is not a no-op for the shared code.

   Design: DOCUMENTATION\11-REFUNDS.md
   Plain path:
   C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\11-REFUNDS.md

   WHY THIS FUNCTION RATHER THAN A NEW ONE. The staff console
   needs an order history and an order detail view. Both are
   "read app.demo_orders with the server-side connection and hand
   back sanitized fields", which is precisely what this function
   already is. A second listing endpoint would have duplicated the
   rate limit, the origin check, the sweep and the sanitization,
   and duplicated code is how two screens start disagreeing about
   what an order is.

   THREE THINGS WERE ADDED, AND THE OLD BEHAVIOUR IS UNCHANGED:

   1. PAGING. The old call returned a fixed 25. It now accepts
      limit and offset, and STILL returns 25 when neither is
      given, so every existing caller sees exactly what it saw
      before. See the paging note below for the numbers chosen.

   2. STAFF DETAIL MODE. With a valid staff session token in the
      x-orvanna-session header, one order can be fetched with its
      line items, tax provenance, processor reference and refund
      history. WITHOUT that token this function behaves exactly as
      it always has, and none of those fields is reachable.

   3. REFUND STATE ON THE LIST ROWS, so history shows what was
      refunded without a second round trip.

   THE TOKEN TRAVELS IN x-orvanna-session, NOT Authorization,
   and that is deliberate. This function is deployed with platform
   JavaScript Object Signing and Encryption (JSON Web Token, JWT)
   verification ON, so Authorization must keep carrying the
   anonymous key. _shared/staff-auth.ts checks our own header
   first for exactly this reason.

   THE WINDOW IS NOT APPLIED HERE. Howard: staff "should be able
   to go into the order" for any order, so the history is
   UNFILTERED by time. The 24 hour refund window is enforced
   inside refund-payment and nowhere else. This function
   deliberately does not compute or report refund eligibility: a
   list that quietly implements a money rule is a second place
   that rule can drift.
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
  type DbClient,
} from "../_shared/edge.ts";

import { isOrderNumber } from "../_shared/refund-rules.ts";
import { requireStaff } from "../_shared/staff-auth.ts";

/* PAGING, AND THE NUMBERS CHOSEN.

   Default 25, unchanged, so existing callers are unaffected.
   Maximum 100 per page, because this is a demonstration rail
   whose whole order table is small, and an unbounded limit on a
   public endpoint is a free way to make the database work hard.
   The staff history asks for 50 and pages with offset, which at
   demonstration volumes is one or two pages in practice. If the
   table ever grows past a few thousand rows, offset paging is the
   thing to revisit first: keyset paging on (created_at, id) would
   be the replacement, and the existing created_at index already
   supports it. */
const DEFAULT_LIMIT = 25;
const MAX_LIMIT = 100;

/* Whether app.demo_order_refunds exists yet. Migration 022 is
   PROPOSED and may not be applied when this deploys, and a query
   against a missing table would take the whole listing down. The
   answer cannot change within one isolate's life, so it is asked
   once and cached. */
let refundsTablePresent: boolean | null = null;

async function hasRefundsTable(client: DbClient): Promise<boolean> {
  if (refundsTablePresent !== null) return refundsTablePresent;
  const result = await client.queryObject<{ present: boolean }>(
    `select to_regclass('app.demo_order_refunds') is not null as present`,
  );
  refundsTablePresent = result.rows[0]?.present === true;
  return refundsTablePresent;
}

interface ListedOrder {
  order_number: string;
  created_at: Date;
  created_by_channel: string;
  member_code: string | null;
  item_count: number;
  total_cents: number;
  pv_total: string | number;
  payment_status: string;
  refunded_cents: number | null;
  refunded_at: Date | null;
}

function toInt(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
}

/* ------------------------------------------------------------
   STAFF DETAIL. One order, with the fields a staff member needs
   in order to be SURE they have the right order before acting:
   the line items as the server priced them, the tax with its
   jurisdiction and provenance, the total, the status, the
   processor reference, and any refund history.

   Everything here is read-only and staff-gated. The processor
   reference in particular is not on the anonymous path and must
   not become so.
   ------------------------------------------------------------ */
async function staffOrderDetail(
  req: Request,
  client: DbClient,
  orderNumber: string,
): Promise<Response> {
  const detail = await client.queryObject<{
    order_number: string;
    created_at: Date;
    created_by_channel: string;
    member_code: string | null;
    items: unknown;
    activation: string;
    subtotal_one_cents: number;
    subtotal_sub_cents: number;
    activation_fee_cents: number;
    tax_cents: number;
    tax_exempt: boolean;
    tax_source: string | null;
    tax_reason: string | null;
    tax_jurisdiction: string | null;
    tax_transaction_id: string | null;
    total_cents: number;
    pv_total: string | number;
    payment_status: string;
    payment_reference: string | null;
    status_updated_at: Date;
  }>(
    `select o.order_number, o.created_at, o.created_by_channel,
            m.member_code,
            o.items, o.activation,
            o.subtotal_one_cents, o.subtotal_sub_cents, o.activation_fee_cents,
            o.tax_cents, o.tax_exempt, o.tax_source, o.tax_reason,
            o.tax_jurisdiction, o.tax_transaction_id,
            o.total_cents, o.pv_total,
            o.payment_status, o.payment_reference, o.status_updated_at
       from app.demo_orders o
       left join app.members m on m.id = o.member_id
      where o.order_number = $1`,
    [orderNumber],
  );

  const row = detail.rows[0];
  if (!row) {
    return errorResponse(req, 404, "order_not_found", "No such order.");
  }

  /* Refund history, when the table exists. Every refund on the
     order, newest first, so a staff member sees a failed attempt
     as well as a successful one. */
  let refunds: unknown[] = [];
  if (await hasRefundsTable(client)) {
    const r = await client.queryObject<{
      requested_at: Date;
      status: string;
      amount_cents: number;
      tax_cents_returned: number;
      reason_code: string;
      reason_note: string | null;
      requested_by: string;
      connector_refund_id: string | null;
    }>(
      `select r.requested_at, r.status, r.amount_cents, r.tax_cents_returned,
              r.reason_code, r.reason_note, r.requested_by, r.connector_refund_id
         from app.demo_order_refunds r
         join app.demo_orders o on o.id = r.demo_order_id
        where o.order_number = $1
        order by r.id desc`,
      [orderNumber],
    );
    refunds = r.rows.map((x) => ({
      requested_at: x.requested_at,
      status: x.status,
      amount: x.amount_cents / 100,
      tax_returned: x.tax_cents_returned / 100,
      reason_code: x.reason_code,
      reason_note: x.reason_note,
      requested_by: x.requested_by,
      connector_refund_id: x.connector_refund_id,
    }));
  }

  return jsonResponse(req, 200, {
    order: {
      order_number: row.order_number,
      created_at: row.created_at,
      created_by_channel: row.created_by_channel,
      member_code: row.member_code,
      /* The items as the SERVER priced them at checkout. Client
         prices were never trusted and are not stored, so this is
         the only pricing that exists. */
      items: row.items,
      activation: row.activation,
      subtotal_one: row.subtotal_one_cents / 100,
      subtotal_sub: row.subtotal_sub_cents / 100,
      activation_fee: row.activation_fee_cents / 100,
      tax: row.tax_cents / 100,
      tax_exempt: row.tax_exempt,
      /* Provenance matters on a receipt: 'stripe_tax' and
         'flat_fallback' are not the same fact, and a zero means
         different things under each (migration 016). */
      tax_source: row.tax_source,
      tax_reason: row.tax_reason,
      tax_jurisdiction: row.tax_jurisdiction,
      tax_recorded: row.tax_transaction_id !== null,
      total: row.total_cents / 100,
      total_cents: row.total_cents,
      pv_total: Number(row.pv_total),
      payment_status: row.payment_status,
      payment_reference: row.payment_reference,
      status_updated_at: row.status_updated_at,
    },
    refunds,
  });
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

  /* Parameters may arrive on the query string (GET) or in a JSON
     body (POST). Both are read; neither is required, and a caller
     that sends nothing gets exactly the old behaviour. */
  const url = new URL(req.url);
  let body: Record<string, unknown> = {};
  if (req.method === "POST") {
    try {
      body = await req.json();
    } catch {
      body = {};
    }
  }
  const param = (name: string): unknown =>
    body[name] ?? url.searchParams.get(name) ?? undefined;

  const client = await getPool().connect();
  try {
    /* ---- staff detail mode ----
       Only reachable with a verified staff session. An unsigned or
       member token gets the ordinary list, not an error, because
       this endpoint's public behaviour is not a secret and should
       not change shape based on a failed guess. */
    const requestedOrder = param("order_number");
    if (typeof requestedOrder === "string" && requestedOrder.trim() !== "") {
      const orderNumber = requestedOrder.trim().toUpperCase();
      if (!isOrderNumber(orderNumber)) {
        return errorResponse(
          req,
          400,
          "bad_order_number",
          "That does not look like an order number.",
        );
      }
      const auth = await requireStaff(client, req, ["staff"]);
      if (!auth.ok) {
        return errorResponse(
          req,
          401,
          "not_authorised",
          "Sign in to the staff console to open an order.",
        );
      }
      return await staffOrderDetail(req, client, orderNumber);
    }

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

    const limit = Math.min(toInt(param("limit"), DEFAULT_LIMIT), MAX_LIMIT);
    const offset = toInt(param("offset"), 0);

    /* THE HISTORY IS UNFILTERED BY TIME, on purpose. Staff need to
       look up any order whenever it was placed; the 24 hour refund
       window is a rule inside refund-payment, not a property of
       this list. */
    const withRefunds = await hasRefundsTable(client);

    const result = await client.queryObject<ListedOrder>(
      `select o.order_number,
              o.created_at,
              o.created_by_channel,
              m.member_code,
              jsonb_array_length(o.items)::int as item_count,
              o.total_cents,
              o.pv_total,
              o.payment_status,
              ${
        withRefunds
          ? `(select r.amount_cents from app.demo_order_refunds r
                where r.demo_order_id = o.id and r.status = 'succeeded'
                order by r.id desc limit 1) as refunded_cents,
             (select r.status_updated_at from app.demo_order_refunds r
                where r.demo_order_id = o.id and r.status = 'succeeded'
                order by r.id desc limit 1) as refunded_at`
          : `null::int as refunded_cents, null::timestamptz as refunded_at`
      }
         from app.demo_orders o
         left join app.members m on m.id = o.member_id
        order by o.created_at desc
        limit $1 offset $2`,
      [limit, offset],
    );

    const totalRow = await client.queryObject<{ total: number }>(
      `select count(*)::int as total from app.demo_orders`,
    );

    const orders = result.rows.map((row) => ({
      order_number: row.order_number,
      created_at: row.created_at,
      created_by_channel: row.created_by_channel,
      member_code: row.member_code,
      item_count: row.item_count,
      /* total in dollars, two-decimal number (display formats at
         the edge; cents are the storage unit) */
      total: row.total_cents / 100,
      pv_total: Number(row.pv_total),
      payment_status: row.payment_status,
      refunded: row.refunded_cents !== null,
      refunded_amount: row.refunded_cents === null
        ? null
        : row.refunded_cents / 100,
      refunded_at: row.refunded_at,
    }));

    return jsonResponse(req, 200, {
      orders,
      limit,
      offset,
      total: totalRow.rows[0]?.total ?? orders.length,
    });
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
