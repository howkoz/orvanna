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

   Status mapping: the full HyperSwitch IntentStatus enum is
   named in mapHyperswitchStatus() in _shared/edge.ts, including
   'expired' and 'cancelled_post_capture' as terminal failures.
   Every answer now carries a `reason`, a short machine-readable
   explanation the site turns into a sentence a shopper can act
   on, and an `authentication` object with named 3-D Secure (3DS)
   fields only.

   The retrieve, the amount check and the guarded update all live
   in _shared/edge.ts (retrieveAndApplyPaymentTruth) so that this
   function and payment-webhook cannot drift apart. The amount
   check is unchanged and is still the last word before any
   'succeeded' is written: 3DS authenticates a cardholder, it
   never changes an amount.

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
  isAllowedOrigin,
  jsonResponse,
  preflight,
  retrieveAndApplyPaymentTruth,
} from "../_shared/edge.ts";
/* IMPORTED, not restated. This file used to carry its own copy of the order
   number pattern, which is how the format came to be defined in six separate
   places. One definition per side is the rule now: the server's lives in
   refund-rules.ts, the browser's in payments.js. */
import { ORDER_NUMBER_RE } from "../_shared/refund-rules.ts";
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
  tax_source: string | null;
  tax_reason: string | null;
  tax_jurisdiction: string | null;
  total_cents: number;
  pv_total: string | number;
  payment_reference: string | null;
  payment_status: string;
  processor_summary: Record<string, unknown> | null;
}

/* When a row has never been synced with HyperSwitch there is no
   stored reason, but the row still says something honest. */
function fallbackReason(row: DemoOrderRow): string | null {
  if (row.payment_status === "abandoned") return "abandoned";
  if (row.payment_status === "created" && !row.payment_reference) {
    return "not_submitted";
  }
  return null;
}

/* The sanitized receipt the site renders its confirmation view
   from (spec 1.2 step 8): server math only, no processor
   payloads, no card data, nothing personal.

   Two 3-D Secure (3DS) additions, both read back out of the
   stored processor_summary so a terminal row answers with them
   too:
     reason         a short machine-readable explanation
     authentication named 3DS fields only, or null */
function receiptOf(row: DemoOrderRow) {
  const summary = (row.processor_summary ?? {}) as Record<string, unknown>;
  const storedReason = typeof summary.reason === "string" ? summary.reason : null;
  const authentication =
    summary.authentication !== undefined && summary.authentication !== null
      ? summary.authentication
      : null;
  return {
    reason: storedReason ?? fallbackReason(row),
    authentication,
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
    tax_source: row.tax_source,
    tax_reason: row.tax_reason,
    tax_jurisdiction: row.tax_jurisdiction,
    total_cents: row.total_cents,
    pv_total: Number(row.pv_total),
    processor: {
      status: summary.status ?? null,
      error_code: summary.error_code ?? null,
      error_message: summary.error_message ?? null,
      /* Which challenge shape HyperSwitch chose, when it chose
         one: three_ds_invoke, redirect_to_url, or
         redirect_inside_popup. Useful to the site and to us. */
      next_action_type: summary.next_action_type ?? null,
    },
  };
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
  const verdict = await checkRateLimit(ipHash, { perMinute: 20 }, "confirm");
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
              tax_source, tax_reason, tax_jurisdiction,
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

    /* ---- the truth: server-side retrieve with the secret key,
       the amount check, and the guarded update. One shared
       implementation, also used by payment-webhook, so the two
       callers cannot disagree about what is true. ---- */
    const truth = await retrieveAndApplyPaymentTruth(
      client,
      {
        order_number: row.order_number,
        total_cents: row.total_cents,
        payment_reference: row.payment_reference,
      },
      { caller: "confirm-payment" },
    );

    if (truth.outcome === "not_configured") {
      return errorResponse(
        req,
        500,
        "not_configured",
        "The payment rail is not configured yet.",
      );
    }
    if (truth.outcome === "processor_unreachable") {
      return errorResponse(
        req,
        502,
        "processor_unreachable",
        "Could not reach the test payment service to check. Please try again in a moment.",
      );
    }
    if (truth.outcome === "processor_error") {
      return errorResponse(
        req,
        502,
        "processor_error",
        "The test payment service could not report on this order. Please try again in a moment.",
      );
    }

    const fresh = await client.queryObject<DemoOrderRow>(
      `select order_number, created_at, created_by_channel,
              referral_code_entered, items, activation,
              subtotal_one_cents, subtotal_sub_cents,
              activation_fee_cents, tax_cents, tax_exempt,
              tax_source, tax_reason, tax_jurisdiction,
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
