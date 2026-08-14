/* ============================================================
   confirm-payment (Supabase Edge Function, Deno)

   Phase 6, work package W2. Spec: MLM-PILOT/docs/PHASE-6-SPEC.md
   sections 1.2 step 8, 4 (confirm by retrieve), 5.4 (status
   mapping), 5.5 (idempotency).

   Trust model: the browser can only send { order_number }.
   There is no status field to forge; the ONLY source of truth
   is our own server-side retrieve of the payment from
   HyperSwitch with the secret key. A forged confirm therefore
   degenerates into asking us to re-check the truth.

   Endpoint used: GET {sandbox}/payments/{payment_id},
   authenticated with the secret api-key header. Public API
   reference:
   https://api-reference.hyperswitch.io/api-reference/payments/payments--retrieve

   Status mapping (spec 5.4):
     succeeded                  -> succeeded (amount must match
                                   total_cents to the cent)
     failed | cancelled         -> failed (error fields kept)
     anything else non-terminal -> processing

   Idempotency (spec 5.5): there is no INSERT here. Terminal
   rows (succeeded, failed, abandoned) are immutable: a repeat
   call returns the same sanitized receipt without touching the
   row or HyperSwitch. Calling this five times produces the
   same final row.
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

const ORDER_NUMBER_RE = /^ORV-\d{4}-\d{2}-[0-9A-Z]{6}$/;
const TERMINAL_STATUSES = new Set(["succeeded", "failed", "abandoned"]);

interface DemoOrderRow {
  order_number: string;
  created_at: Date;
  created_by_channel: string;
  referral_code_entered: string | null;
  items: unknown;
  activation: string;
  subtotal_one_cents: number;
  subtotal_sub_cents: number;
  activation_fee_cents: number;
  tax_cents: number;
  tax_exempt: boolean;
  total_cents: number;
  pv_total: string | number;
  payment_reference: string | null;
  payment_status: string;
  processor_summary: Record<string, unknown> | null;
}

/* The sanitized receipt the site renders its confirmation view
   from (spec 1.2 step 8): server math only, no processor
   payloads, no card data, nothing personal. */
function receiptOf(row: DemoOrderRow) {
  const summary = row.processor_summary ?? {};
  return {
    order_number: row.order_number,
    payment_status: row.payment_status,
    created_at: row.created_at,
    channel: row.created_by_channel,
    referral_code_entered: row.referral_code_entered,
    items: row.items,
    activation: row.activation,
    subtotal_one_cents: row.subtotal_one_cents,
    subtotal_sub_cents: row.subtotal_sub_cents,
    activation_fee_cents: row.activation_fee_cents,
    tax_cents: row.tax_cents,
    tax_exempt: row.tax_exempt,
    total_cents: row.total_cents,
    pv_total: Number(row.pv_total),
    processor: {
      status: (summary as Record<string, unknown>).status ?? null,
      error_code: (summary as Record<string, unknown>).error_code ?? null,
      error_message: (summary as Record<string, unknown>).error_message ?? null,
    },
  };
}

/* Map a HyperSwitch payment status to our state machine. */
function mapStatus(hsStatus: string): "succeeded" | "failed" | "processing" {
  if (hsStatus === "succeeded") return "succeeded";
  if (hsStatus === "failed" || hsStatus === "cancelled") return "failed";
  /* requires_confirmation, requires_customer_action,
     requires_payment_method, requires_capture, processing, and
     any future non-terminal status: still in flight. */
  return "processing";
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

  const ipHash = await callerIpHash(req);
  const verdict = await checkRateLimit(ipHash, { perMinute: 20 });
  if (!verdict.allowed) {
    return errorResponse(
      req,
      429,
      "rate_limited",
      "Too many checks in one minute. Please wait a moment and try again.",
      { "Retry-After": String(verdict.retryAfterSeconds) },
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse(req, 400, "bad_json", "The request body is not valid JSON.");
  }
  const orderNumber =
    typeof body.order_number === "string" ? body.order_number.trim() : "";
  if (!ORDER_NUMBER_RE.test(orderNumber)) {
    return errorResponse(
      req,
      400,
      "invalid_order_number",
      "That does not look like an Orvanna order number.",
    );
  }

  const client = await getPool().connect();
  try {
    const result = await client.queryObject<DemoOrderRow>(
      `select order_number, created_at, created_by_channel,
              referral_code_entered, items, activation,
              subtotal_one_cents, subtotal_sub_cents,
              activation_fee_cents, tax_cents, tax_exempt,
              total_cents, pv_total, payment_reference,
              payment_status, processor_summary
         from app.demo_orders
        where order_number = $1`,
      [orderNumber],
    );
    const row = result.rows[0];
    if (!row) {
      return errorResponse(
        req,
        404,
        "order_not_found",
        "No order with that number.",
      );
    }

    /* Terminal states are immutable: answer from the row. */
    if (TERMINAL_STATUSES.has(row.payment_status)) {
      return jsonResponse(req, 200, receiptOf(row));
    }

    /* No payment_reference yet means HyperSwitch was never
       reached for this row; nothing to retrieve. The row stays
       'created' and will age into 'abandoned' (spec 5.5). */
    if (!row.payment_reference) {
      return jsonResponse(req, 200, receiptOf(row));
    }

    /* ---- the truth: server-side retrieve with the secret key ---- */
    const apiKey = Deno.env.get("HYPERSWITCH_API_KEY");
    if (!apiKey) {
      return errorResponse(
        req,
        500,
        "not_configured",
        "The payment rail is not configured yet.",
      );
    }

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
      return errorResponse(
        req,
        502,
        "processor_unreachable",
        "Could not reach the test payment service to check. Please try again in a moment.",
      );
    }
    if (!hsResponse.ok) {
      console.error(
        `confirm-payment: HyperSwitch GET /payments returned ${hsResponse.status} for ${orderNumber}`,
      );
      return errorResponse(
        req,
        502,
        "processor_error",
        "The test payment service could not report on this order. Please try again in a moment.",
      );
    }

    const hs = (await hsResponse.json()) as {
      status?: string;
      amount?: number;
      amount_received?: number | null;
      connector?: string;
      payment_method_type?: string;
      error_code?: string | null;
      error_message?: string | null;
    };
    const hsStatus = hs.status ?? "unknown";
    let newStatus = mapStatus(hsStatus);

    /* Amount equality, to the cent, before any 'succeeded' is
       written (spec 1.2 step 8). Integer comparison: both sides
       are minor units. A mismatch never marks success. */
    let amountMismatch = false;
    if (newStatus === "succeeded") {
      const amountOk = hs.amount === row.total_cents;
      const receivedOk =
        hs.amount_received === undefined ||
        hs.amount_received === null ||
        hs.amount_received === row.total_cents;
      if (!amountOk || !receivedOk) {
        amountMismatch = true;
        newStatus = "processing"; /* never succeeded on a mismatch */
        console.error(
          `confirm-payment: amount mismatch on ${orderNumber} (expected ${row.total_cents})`,
        );
      }
    }

    /* Sanitized processor summary (spec 2.2): named fields only,
       never a raw payload, never card data. */
    const summary = {
      status: hsStatus,
      connector: hs.connector ?? null,
      payment_method_type: hs.payment_method_type ?? null,
      error_code: amountMismatch ? "amount_mismatch" : hs.error_code ?? null,
      error_message: amountMismatch
        ? "The processor amount did not match the order total."
        : hs.error_message ?? null,
      last_synced_at: new Date().toISOString(),
    };

    /* Guarded update: only a non-terminal row may move, so a
       concurrent confirm cannot overwrite a terminal state. */
    await client.queryArray(
      `update app.demo_orders
          set payment_status = $1,
              processor_summary = $2::jsonb,
              status_updated_at = now()
        where order_number = $3
          and payment_status in ('created', 'processing')`,
      [newStatus, JSON.stringify(summary), orderNumber],
    );

    const fresh = await client.queryObject<DemoOrderRow>(
      `select order_number, created_at, created_by_channel,
              referral_code_entered, items, activation,
              subtotal_one_cents, subtotal_sub_cents,
              activation_fee_cents, tax_cents, tax_exempt,
              total_cents, pv_total, payment_reference,
              payment_status, processor_summary
         from app.demo_orders
        where order_number = $1`,
      [orderNumber],
    );
    return jsonResponse(req, 200, receiptOf(fresh.rows[0]));
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`confirm-payment: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Something went wrong on our side while checking this order.",
    );
  } finally {
    client.release();
  }
});
