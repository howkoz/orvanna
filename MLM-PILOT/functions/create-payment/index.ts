/* ============================================================
   create-payment (Supabase Edge Function, Deno)

   Phase 6, work package W2. Spec: MLM-PILOT/docs/PHASE-6-SPEC.md
   sections 1 (flow), 2 (schema), 3 (secrets), 5 (rails).

   What it does, in order:
   1. Preflight and origin checks (CORS locked per spec 5.2).
   2. Rate limits the caller: 5 per minute AND 30 per hour per
      salted Internet Protocol (IP) address hash (spec 5.1).
   3. Daily circuit breaker: over 500 orders created this
      Coordinated Universal Time (UTC) day answers 503 (spec 5.1).
   4. Validates the cart SERVER-SIDE against the pricing mirror
      (_shared/pricing.ts). Client prices are ignored by
      construction; only { sku, mode, quantity } are read.
   5. Recomputes all money in integer cents, enforces cart caps
      and the $25,000.00 ceiling (spec 5.2).
   6. Resolves the optional member code against app.members
      (a miss stores null and keeps the raw text; a mistyped
      code never fails the order).
   7. Generates the server-side order number ORV-YYYY-MM-XXXXXX
      (six base36 characters: four from the server clock plus
      two random, spec 1.2 step 4).
   8. Inserts the pending app.demo_orders row (payment_status
      'created') using the server-side database connection.
   9. Creates the HyperSwitch payment: POST /payments on the
      sandbox host (see _shared/edge.ts for the base URL and
      endpoint citation), amount in cents, confirm false,
      metadata per spec 1.2 step 6.
  10. Returns { order_number, client_secret, publishable_key }.

   Secrets: only via Deno.env.get, names per spec section 3.
   Nothing personal is accepted, stored, or logged: no names,
   no addresses, no Tax ID values, no card data, no raw IPs.
   ============================================================ */

import {
  callerIpHash,
  checkRateLimit,
  errorResponse,
  getPool,
  HYPERSWITCH_BASE_URL,
  isAllowedOrigin,
  jsonResponse,
  preflight,
} from "../_shared/edge.ts";
import { priceCart } from "../_shared/pricing.ts";

const DAILY_ORDER_CEILING = 500; // spec 5.1 circuit breaker

const BASE36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/* ORV-YYYY-MM-XXXXXX: four base36 characters from the server
   clock (seconds since UTC midnight, zero padded) plus two
   random base36 characters, so two simultaneous strangers
   cannot collide (spec 1.2 step 4). The order_number column is
   unique; the insert retries on the astronomically rare clash. */
function generateOrderNumber(): string {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  const secondsSinceMidnight =
    now.getUTCHours() * 3600 + now.getUTCMinutes() * 60 + now.getUTCSeconds();
  const clockPart = secondsSinceMidnight
    .toString(36)
    .toUpperCase()
    .padStart(4, "0");
  const rand = new Uint8Array(2);
  crypto.getRandomValues(rand);
  const randomPart = BASE36[rand[0] % 36] + BASE36[rand[1] % 36];
  return `ORV-${year}-${month}-${clockPart}${randomPart}`;
}

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

  /* ---- rails: rate limit, then circuit breaker ---- */
  const ipHash = await callerIpHash(req);
  const verdict = await checkRateLimit(ipHash, { perMinute: 5, perHour: 30 }, "create");
  if (!verdict.allowed) {
    return errorResponse(
      req,
      429,
      "rate_limited",
      "Easy does it. This demo takes a few orders per minute per visitor. Please wait a moment and try again.",
      { "Retry-After": String(verdict.retryAfterSeconds) },
    );
  }

  const client = await getPool().connect();
  try {
    const todayCount = await client.queryObject<{ total: number }>(
      `select count(*)::int as total
         from app.demo_orders
        where created_at >= date_trunc('day', now())`,
    );
    if ((todayCount.rows[0]?.total ?? 0) >= DAILY_ORDER_CEILING) {
      return errorResponse(
        req,
        503,
        "demo_resting",
        "The demo is resting for today. It wakes up again at midnight Coordinated Universal Time (UTC).",
      );
    }

    /* ---- parse and validate the request ---- */
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return errorResponse(req, 400, "bad_json", "The request body is not valid JSON.");
    }

    const activation = typeof body.activation === "string" ? body.activation : "";
    const taxExempt = body.tax_exempt === true;
    const channel =
      body.channel === "staff_console" ? "staff_console" : "shop";
    const rawMemberCode =
      typeof body.member_code === "string" ? body.member_code.trim().slice(0, 40) : "";

    const priced = priceCart(body.items, activation, taxExempt);
    if (!priced.ok) {
      return errorResponse(req, 400, "invalid_cart", priced.message);
    }
    const order = priced.order;

    /* ---- member code: match stores the id, miss stores null,
       the raw text is kept for the receipt either way ---- */
    let memberId: number | null = null;
    if (rawMemberCode !== "") {
      const memberRow = await client.queryObject<{ id: number }>(
        `select id from app.members where member_code = $1`,
        [rawMemberCode],
      );
      memberId = memberRow.rows[0]?.id ?? null;
    }

    /* ---- insert the pending row (idempotency anchor) ---- */
    let orderNumber = "";
    let inserted = false;
    for (let attempt = 0; attempt < 5 && !inserted; attempt++) {
      orderNumber = generateOrderNumber();
      try {
        await client.queryArray(
          `insert into app.demo_orders
             (order_number, created_by_channel, member_id,
              referral_code_entered, items, activation,
              subtotal_one_cents, subtotal_sub_cents,
              activation_fee_cents, tax_cents, tax_exempt,
              total_cents, pv_total, payment_status)
           values ($1, $2, $3, $4, $5::jsonb, $6,
                   $7, $8, $9, $10, $11, $12, $13, 'created')`,
          [
            orderNumber,
            channel,
            memberId,
            rawMemberCode === "" ? null : rawMemberCode,
            JSON.stringify(order.items),
            activation,
            order.subtotal_one_cents,
            order.subtotal_sub_cents,
            order.activation_fee_cents,
            order.tax_cents,
            taxExempt,
            order.total_cents,
            order.pv_total,
          ],
        );
        inserted = true;
      } catch (err) {
        /* 23505 = unique_violation on order_number: regenerate. */
        const message = err instanceof Error ? err.message : String(err);
        if (!message.includes("23505") && !message.includes("duplicate key")) {
          throw err;
        }
      }
    }
    if (!inserted) {
      return errorResponse(
        req,
        500,
        "order_number_collision",
        "Could not assign an order number. Please try again.",
      );
    }

    /* ---- create the HyperSwitch payment ----
       Endpoint: POST {sandbox}/payments, authenticated with the
       secret api-key header. Public API reference:
       https://api-reference.hyperswitch.io/api-reference/payments/payments--create */
    const apiKey = Deno.env.get("HYPERSWITCH_API_KEY");
    const publishableKey = Deno.env.get("HYPERSWITCH_PUBLISHABLE_KEY");
    if (!apiKey || !publishableKey) {
      return errorResponse(
        req,
        500,
        "not_configured",
        "The payment rail is not configured yet.",
      );
    }

    let hsResponse: Response;
    try {
      hsResponse = await fetch(`${HYPERSWITCH_BASE_URL}/payments`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "api-key": apiKey,
        },
        body: JSON.stringify({
          amount: order.total_cents, // minor units (cents), spec 1.2 step 6
          currency: "USD",
          capture_method: "automatic",
          confirm: false,
          description:
            `Orvanna demo order ${orderNumber} (test mode, no real money)`,
          metadata: {
            order_number: orderNumber,
            member_code: rawMemberCode,
            demo: "true",
            channel,
          },
        }),
        signal: AbortSignal.timeout(15_000),
      });
    } catch {
      /* The row stays 'created' with no payment_reference and
         ages into 'abandoned' per spec 5.5; nothing to undo. */
      return errorResponse(
        req,
        502,
        "processor_unreachable",
        "Could not reach the test payment service. Nothing was charged. Please try again.",
      );
    }

    if (!hsResponse.ok) {
      /* Log only the status code; never the response body wholesale
         and never any key material. */
      console.error(
        `create-payment: HyperSwitch POST /payments returned ${hsResponse.status} for ${orderNumber}`,
      );
      return errorResponse(
        req,
        502,
        "processor_error",
        "The test payment service refused the request. Nothing was charged. Please try again.",
      );
    }

    const hsBody = (await hsResponse.json()) as {
      payment_id?: string;
      client_secret?: string;
    };
    if (!hsBody.payment_id || !hsBody.client_secret) {
      console.error(
        `create-payment: HyperSwitch response missing payment_id or client_secret for ${orderNumber}`,
      );
      return errorResponse(
        req,
        502,
        "processor_error",
        "The test payment service answered strangely. Nothing was charged. Please try again.",
      );
    }

    await client.queryArray(
      `update app.demo_orders
          set payment_reference = $1, status_updated_at = now()
        where order_number = $2`,
      [hsBody.payment_id, orderNumber],
    );

    return jsonResponse(req, 200, {
      order_number: orderNumber,
      client_secret: hsBody.client_secret,
      publishable_key: publishableKey,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`create-payment: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Something went wrong on our side. Nothing was charged.",
    );
  } finally {
    client.release();
  }
});
