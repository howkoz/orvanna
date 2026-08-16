/* ============================================================
   refund-payment (Supabase Edge Function, Deno)

   PROPOSED, NOT DEPLOYED. Nothing in this file has been deployed
   and no refund has been issued against the sandbox by its author.

   Design: DOCUMENTATION\11-REFUNDS.md
   Schema: db\migrations\022_PROPOSED_refunds_NOT_APPLIED.sql
   Plain path to the design:
   C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\11-REFUNDS.md

   ------------------------------------------------------------
   WHAT THIS DOES, IN ONE PARAGRAPH

   A staff agent, signed in with a token this function actually
   verifies, names an order. If that order was really paid, was
   never refunded before, and has no refund already in flight, this
   function returns EVERY CENT the customer paid, tax included, and
   records what it did. That is the whole feature.

   ------------------------------------------------------------
   FULL REFUNDS ONLY, AND THAT IS A DECISION, NOT A LIMITATION

   Howard, 2026-08-15: "if doing 100% refund is the easiest then
   lets do that." So there is no amount input on this endpoint. A
   caller cannot ask for a partial refund, and the function cannot
   be talked into one: the amount is read from the order row on the
   server, never from the request body.

   The SCHEMA underneath is nonetheless shaped to accept partial
   refunds later without a rewrite (many refund rows per order, a
   real amount_cents column, a refund_kind label, and the
   partially_refunded state already permitted by the trigger). See
   the scope block at the top of migration 022. When partial
   arrives, the change is to this file and to the staff console.
   The database does not move.

   ------------------------------------------------------------
   THE CUSTOMER GETS THE TAX BACK. STRIPE IS NOT TOLD.

   amount_cents is demo_orders.total_cents, which already contains
   tax_cents. The customer is made whole. What is deliberately NOT
   done is the bookkeeping reversal in Stripe's own tax records, by
   instruction. The consequence is that Stripe's reports overstate
   tax owed by exactly the tax on every refunded order that had
   already been recorded, and app.v_demo_tax_drift measures that to
   the cent. Section 11 of the design document names the endpoint
   that would close it. This is a KNOWN and MEASURED gap, which is
   acceptable; an unknown one would not be.

   ------------------------------------------------------------
   THE THREE RAILS, AND WHY A THIRD ONE EXISTS HERE

   Every other function in this project is gated on ORIGIN and RATE
   LIMIT. That is correct for all of them, because none does
   anything a visitor could not already do from the shop. This one
   is different: it moves money out of the business to a party
   outside it, and it cannot be undone from our side.

   So it adds AUTHORISATION, and that had to be built, because it
   did not exist. www/staff.html says "the real gate is the role
   check the server performs on every function call". No such check
   existed anywhere in this codebase: demo-login minted tokens that
   nothing ever verified. functions/_shared/staff-auth.ts is that
   missing half, and this function is its first caller.

   ------------------------------------------------------------
   WHY THE DATABASE ROW IS WRITTEN BEFORE THE PROCESSOR IS CALLED

   This is the single most important ordering decision in the file.

   Call first, record after, and a timeout between the two leaves
   money returned with no record of it. The next staff click finds
   no refund row, concludes the order was never refunded, and
   returns the money a SECOND time. Nothing in the system would
   ever notice.

   Record first, call after, and the same timeout leaves a
   'requested' row for a refund that may or may not have happened.
   That is a QUESTION, and questions are answerable: this function
   asks GET /refunds/{refund_id} on the next click and settles it.
   Meanwhile the row occupies the one-live-refund-per-order slot in
   the database, so no second call can start.

   An unanswered question is recoverable. A double refund is not.

   ------------------------------------------------------------
   SECRETS: HYPERSWITCH_API_KEY only, read via Deno.env.get. The
   key is never logged, never returned, and never placed in a URL.
   No card data is read, stored, logged, or returned by any path in
   this file. Processor error text is stored in a named field and
   never echoed wholesale.

   DEPLOYMENT: like payment-webhook, this must be deployed WITHOUT
   platform JavaScript Object Signing and Encryption (JSON Web
   Token, JWT) verification, because the Authorization header
   carries OUR staff token rather than the platform key. Its own
   signature check is what secures it. Setting that flag is the
   coordinator's call, not this file's.
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
  type DbClient,
} from "../_shared/edge.ts";

import { auditStaffAction, requireStaff } from "../_shared/staff-auth.ts";

/* HyperSwitch documents a minimum refund amount of 100 in the
   lowest denomination, i.e. one dollar. An order below that cannot
   be refunded through the API at all, so it is refused with a clear
   message rather than a processor error. Nothing in the catalogue
   is priced under a dollar, so this is a guard against a future
   surprise rather than a live case. */
const MIN_REFUND_CENTS = 100;

/* The four reason values HyperSwitch documents. Stripe-routed
   payments REQUIRE one of the first three, so 'other' is mapped to
   requested_by_customer before the call and kept verbatim in our
   own row. Keeping the constraint even though we run Braintree is
   what makes a later connector change a configuration change. */
const REASON_CODES = [
  "duplicate",
  "fraudulent",
  "requested_by_customer",
  "other",
] as const;
type ReasonCode = typeof REASON_CODES[number];

function processorReason(code: ReasonCode): string {
  return code === "other" ? "requested_by_customer" : code;
}

/* Order numbers are ORV-YYYY-MM-XXXXXX (create-payment,
   generateOrderNumber). Validated by shape before it reaches a
   query so a malformed value is refused early. Every query below
   is parameterised regardless; this is belt and suspenders. */
const ORDER_NUMBER_RE = /^ORV-\d{4}-\d{2}-[0-9A-Z]{6}$/;

/* Our refund identifier, sent to HyperSwitch as refund_id.
   HyperSwitch documents that field as the idempotency mechanism for
   refunds against one payment, and documents its length as 30, so
   this mints exactly 30 characters: 6 of prefix plus 24 hex.
   Randomness comes from the platform generator, never from the
   clock alone, because two agents can click in the same second. */
function generateRefundReference(): string {
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  const hex = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `orvrf_${hex}`; /* 6 + 24 = 30 */
}

/* HyperSwitch RefundStatus, verbatim from the API reference:
   succeeded, failed, pending, review. Anything else is treated as
   non-terminal and reported as 'pending', which is the safe
   direction: an unrecognised status can never be mistaken for a
   completed refund, and the next sync will ask again. */
type RefundStatus = "succeeded" | "failed" | "pending" | "review";

function mapRefundStatus(raw: unknown): { status: RefundStatus; known: boolean } {
  switch (raw) {
    case "succeeded":
      return { status: "succeeded", known: true };
    case "failed":
      return { status: "failed", known: true };
    case "pending":
      return { status: "pending", known: true };
    case "review":
      return { status: "review", known: true };
    default:
      return { status: "pending", known: false };
  }
}

/* Only succeeded and failed are terminal. pending and review mean
   "ask again later", and while a refund is in either the order
   stays 'succeeded', because nothing has actually been returned
   yet. */
function isTerminal(status: RefundStatus): boolean {
  return status === "succeeded" || status === "failed";
}

interface OrderRow {
  id: number;
  order_number: string;
  total_cents: number;
  tax_cents: number;
  payment_status: string;
  payment_reference: string | null;
  created_at: Date;
  tax_transaction_id: string | null;
}

interface RefundRow {
  id: number;
  refund_reference: string;
  status: string;
  amount_cents: number;
}

/* The sanitized summary written to the refund row. Named fields
   only, exactly like demo_orders.processor_summary. Never a raw
   payload and never anything that could carry card data. */
function summarize(
  hs: Record<string, unknown>,
  caller: string,
  extra: Record<string, unknown> = {},
): Record<string, unknown> {
  const s = (v: unknown, max = 200): string | null =>
    typeof v === "string" && v.trim() !== "" ? v.trim().slice(0, max) : null;
  return {
    status: s(hs.status, 40),
    connector: s(hs.connector, 60),
    connector_refund_id: s(hs.connector_refund_id, 128),
    error_code: s(hs.error_code, 64),
    error_message: s(hs.error_message, 200),
    unified_code: s(hs.unified_code, 64),
    unified_message: s(hs.unified_message, 200),
    amount: typeof hs.amount === "number" ? hs.amount : null,
    currency: s(hs.currency, 8),
    last_synced_at: new Date().toISOString(),
    synced_by: caller,
    ...extra,
  };
}

/* ------------------------------------------------------------
   Apply a processor answer to our rows.

   Writes the refund row always. Moves the ORDER to 'refunded' only
   when the refund actually succeeded, because until then nothing
   has been returned and the order is still an ordinary paid order.

   Both updates are guarded so a repeat is a harmless no-op, in the
   same style as retrieveAndApplyPaymentTruth in _shared/edge.ts.
   ------------------------------------------------------------ */
async function applyRefundTruth(
  client: DbClient,
  refund: { id: number; order_number: string },
  status: RefundStatus,
  hs: Record<string, unknown>,
  caller: string,
): Promise<void> {
  const connectorRefundId = typeof hs.connector_refund_id === "string"
    ? hs.connector_refund_id.slice(0, 128)
    : null;
  const connector = typeof hs.connector === "string"
    ? hs.connector.slice(0, 60)
    : null;

  await client.queryArray(
    `update app.demo_order_refunds
        set status              = $1,
            connector_refund_id = coalesce($2, connector_refund_id),
            connector           = coalesce($3, connector),
            processor_summary   = $4::jsonb
      where id = $5
        and status in ('requested', 'pending', 'review')`,
    [
      status,
      connectorRefundId,
      connector,
      JSON.stringify(summarize(hs, caller)),
      refund.id,
    ],
  );

  if (status === "succeeded") {
    /* The order moves to 'refunded' ONLY here. The guard added by
       migration 022 permits succeeded -> refunded and nothing else,
       so this statement cannot corrupt a row that is in any other
       state: it simply matches nothing. */
    await client.queryArray(
      `update app.demo_orders
          set payment_status = 'refunded'
        where order_number = $1
          and payment_status = 'succeeded'`,
      [refund.order_number],
    );
  }
}

/* ------------------------------------------------------------
   Ask HyperSwitch about a refund we already created.

   This is the recovery path for the "row written, call outcome
   unknown" case described in the header, and it is also what makes
   a second click on an in-flight refund safe: it settles the
   existing one instead of starting another.
   ------------------------------------------------------------ */
async function syncExistingRefund(
  client: DbClient,
  apiKey: string,
  order: OrderRow,
  refund: RefundRow,
): Promise<Response | null> {
  let resp: Response;
  try {
    resp = await fetch(
      `${HYPERSWITCH_BASE_URL}/refunds/${encodeURIComponent(refund.refund_reference)}`,
      {
        method: "GET",
        headers: { "api-key": apiKey },
        signal: AbortSignal.timeout(15_000),
      },
    );
  } catch {
    return null; /* still unknown; caller reports in_flight */
  }

  if (resp.status === 404) {
    /* HyperSwitch has never heard of this reference, which means our
       create call never actually reached it. The refund did NOT
       happen. Release the slot by marking the row failed so a
       genuine retry is possible.

       This is safe precisely because refund_reference is OUR
       idempotency key: if the call HAD reached HyperSwitch under
       this reference, HyperSwitch would know the reference. A 404
       is therefore evidence of absence, not merely absence of
       evidence. */
    await client.queryArray(
      `update app.demo_order_refunds
          set status = 'failed',
              processor_summary = $1::jsonb
        where id = $2
          and status in ('requested', 'pending', 'review')`,
      [
        JSON.stringify({
          status: "not_found",
          error_code: "unknown_to_processor",
          error_message:
            "HyperSwitch does not know this refund reference, so the refund was never created.",
          last_synced_at: new Date().toISOString(),
          synced_by: "refund-payment.sync",
        }),
        refund.id,
      ],
    );
    return null;
  }

  if (!resp.ok) {
    console.error(
      `refund-payment: HyperSwitch GET /refunds returned ${resp.status} for ${order.order_number}`,
    );
    return null;
  }

  const hs = (await resp.json()) as Record<string, unknown>;
  const mapped = mapRefundStatus(hs.status);
  if (!mapped.known) {
    console.error(
      `refund-payment: unrecognised refund status on ${order.order_number}`,
    );
  }
  await applyRefundTruth(
    client,
    { id: refund.id, order_number: order.order_number },
    mapped.status,
    hs,
    "refund-payment.sync",
  );

  return new Response(
    JSON.stringify({
      order_number: order.order_number,
      refund_status: mapped.status,
      amount: refund.amount_cents / 100,
      settled: isTerminal(mapped.status),
      action: "synced_existing",
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

Deno.serve(async (req: Request): Promise<Response> => {
  const pre = preflight(req);
  if (pre) return pre;

  /* ---- rail 1: method and origin ---- */
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
  const client = await getPool().connect();

  try {
    /* ---- rail 2: rate limit, IN ITS OWN SCOPE ----
       'refund' is a separate bucket, so a staff agent working
       through a queue of refunds can never consume the budget that
       a shopper needs for checkout, and vice versa. Tighter than
       every other function on purpose: a legitimate operator does
       not refund three orders in a minute, and an attacker who
       somehow held a valid token should be throttled hard. */
    const verdict = await checkRateLimit(
      ipHash,
      { perMinute: 3, perHour: 20 },
      "refund",
      client,
    );
    if (!verdict.allowed) {
      await auditStaffAction(client, {
        actor: "unknown",
        actor_role: null,
        action: "refund_payment",
        target: null,
        outcome: "refused",
        outcome_code: "rate_limited",
        ip_hash: ipHash,
      });
      return errorResponse(
        req,
        429,
        "rate_limited",
        "Too many refund attempts in a short time. Please wait a moment.",
        { "Retry-After": String(verdict.retryAfterSeconds) },
      );
    }

    /* ---- rail 3: AUTHORISATION ----
       The token is verified against the signing key in
       app.demo_auth_config. A hand-written session object does not
       get past this line.

       THE CALLER IS TOLD ONE THING FOR ALL FAILURES. Whether the
       token was missing, forged, expired or belonged to a member
       rather than a staff agent, the browser is told
       'not_authorised'. The SPECIFIC reason goes to the audit log,
       where it helps an operator and does not help a prober. */
    const auth = await requireStaff(client, req, ["staff", "admin"]);
    if (!auth.ok) {
      await auditStaffAction(client, {
        actor: "anonymous",
        actor_role: null,
        action: "refund_payment",
        target: null,
        outcome: "refused",
        outcome_code: auth.code,
        ip_hash: ipHash,
      });
      return errorResponse(
        req,
        401,
        "not_authorised",
        "Sign in to the staff console to refund an order.",
      );
    }
    const actor = auth.identity;

    /* ---- input ---- */
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return errorResponse(req, 400, "bad_json", "The request body is not valid JSON.");
    }

    const orderNumber = typeof body.order_number === "string"
      ? body.order_number.trim().toUpperCase()
      : "";
    if (!ORDER_NUMBER_RE.test(orderNumber)) {
      await auditStaffAction(client, {
        actor: actor.user,
        actor_role: actor.role,
        action: "refund_payment",
        target: null,
        outcome: "refused",
        outcome_code: "bad_order_number",
        ip_hash: ipHash,
      });
      return errorResponse(
        req,
        400,
        "bad_order_number",
        "That does not look like an order number.",
      );
    }

    const reasonCode = REASON_CODES.includes(body.reason_code as ReasonCode)
      ? (body.reason_code as ReasonCode)
      : null;
    if (reasonCode === null) {
      return errorResponse(
        req,
        400,
        "bad_reason",
        "Choose a refund reason: duplicate, fraudulent, requested_by_customer, or other.",
      );
    }
    const reasonNote = typeof body.reason_note === "string"
      ? body.reason_note.trim().slice(0, 500)
      : null;

    /* EXPLICIT CONFIRMATION, SERVER SIDE.
       The staff console also asks the agent to type the order
       number before the button enables, but a browser control is a
       convenience and not a guarantee. Requiring an explicit flag
       here means a mistyped or replayed request that happens to
       carry a valid token still cannot move money by accident. */
    if (body.confirm !== true) {
      await auditStaffAction(client, {
        actor: actor.user,
        actor_role: actor.role,
        action: "refund_payment",
        target: orderNumber,
        outcome: "refused",
        outcome_code: "not_confirmed",
        ip_hash: ipHash,
      });
      return errorResponse(
        req,
        400,
        "not_confirmed",
        "A refund must be confirmed explicitly.",
      );
    }

    const apiKey = Deno.env.get("HYPERSWITCH_API_KEY");
    if (!apiKey) {
      console.error("refund-payment: HYPERSWITCH_API_KEY is not set");
      return errorResponse(
        req,
        500,
        "not_configured",
        "Refunds are not configured on this environment.",
      );
    }

    /* ============================================================
       PHASE ONE: decide, and write the intent. One transaction.

       The row lock is what makes two agents clicking at the same
       instant safe. The partial unique index in migration 022 is
       the backstop if a future caller forgets the lock; this is the
       lock that means the backstop is never reached in practice.

       The five values below are filled inside the transaction and
       read after it commits, so they are initialised rather than
       merely declared. Every one of them is set on the only path
       that reaches phase two; the guards above return before that
       path on every other outcome.
       ============================================================ */
    let refundId = 0;
    let refundReference = "";
    let amountCents = 0;
    let taxCents = 0;
    let paymentReference = "";

    await client.queryArray("begin");
    try {
      const orderResult = await client.queryObject<OrderRow>(
        `select id, order_number, total_cents, tax_cents, payment_status,
                payment_reference, created_at, tax_transaction_id
           from app.demo_orders
          where order_number = $1
          for update`,
        [orderNumber],
      );
      const order = orderResult.rows[0];

      if (!order) {
        await client.queryArray("rollback");
        await auditStaffAction(client, {
          actor: actor.user,
          actor_role: actor.role,
          action: "refund_payment",
          target: orderNumber,
          outcome: "refused",
          outcome_code: "order_not_found",
          ip_hash: ipHash,
        });
        return errorResponse(req, 404, "order_not_found", "No such order.");
      }

      /* Is there already a refund on this order? Answered inside
         the same transaction and under the same lock, so the answer
         cannot change between the question and the write. */
      const existingResult = await client.queryObject<RefundRow>(
        `select id, refund_reference, status, amount_cents
           from app.demo_order_refunds
          where demo_order_id = $1
            and status in ('requested', 'pending', 'review', 'succeeded')
          order by id desc
          limit 1`,
        [order.id],
      );
      const existing = existingResult.rows[0];

      if (existing && existing.status === "succeeded") {
        await client.queryArray("rollback");
        await auditStaffAction(client, {
          actor: actor.user,
          actor_role: actor.role,
          action: "refund_payment",
          target: orderNumber,
          outcome: "refused",
          outcome_code: "already_refunded",
          ip_hash: ipHash,
        });
        return errorResponse(
          req,
          409,
          "already_refunded",
          "This order has already been refunded in full.",
        );
      }

      if (existing) {
        /* A refund is in flight. Do NOT start another. Settle the
           one that exists and report what it is doing. This is the
           second click on a timed-out first click. */
        await client.queryArray("commit");
        const synced = await syncExistingRefund(client, apiKey, order, existing);
        await auditStaffAction(client, {
          actor: actor.user,
          actor_role: actor.role,
          action: "refund_payment",
          target: orderNumber,
          outcome: "refused",
          outcome_code: "refund_in_flight",
          ip_hash: ipHash,
          detail: { refund_reference: existing.refund_reference },
        });
        if (synced) return synced;
        return errorResponse(
          req,
          409,
          "refund_in_flight",
          "A refund on this order is already under way. Check again shortly.",
        );
      }

      /* Only a payment we OBSERVED succeed may be refunded. That
         matters more than it looks: reaching 'succeeded' means
         retrieveAndApplyPaymentTruth already compared the processor
         amount to total_cents to the cent. So the amount this
         function is about to return has been verified against the
         processor, not merely against our own arithmetic. */
      if (order.payment_status !== "succeeded") {
        await client.queryArray("rollback");
        await auditStaffAction(client, {
          actor: actor.user,
          actor_role: actor.role,
          action: "refund_payment",
          target: orderNumber,
          outcome: "refused",
          outcome_code: "not_refundable_status",
          ip_hash: ipHash,
          detail: { payment_status: order.payment_status },
        });
        return errorResponse(
          req,
          409,
          "not_refundable",
          `Only a paid order can be refunded. This one is ${order.payment_status}.`,
        );
      }

      if (!order.payment_reference) {
        await client.queryArray("rollback");
        return errorResponse(
          req,
          409,
          "no_payment_reference",
          "This order has no processor reference, so it cannot be refunded automatically.",
        );
      }

      if (order.total_cents < MIN_REFUND_CENTS) {
        await client.queryArray("rollback");
        return errorResponse(
          req,
          422,
          "amount_too_small",
          "The processor will not refund an amount below one dollar.",
        );
      }

      /* THE AMOUNT COMES FROM THE ORDER ROW, NEVER FROM THE REQUEST.
         There is no code path by which a caller can influence how
         much money leaves. Tax is inside this figure: the customer
         is made whole. */
      amountCents = order.total_cents;
      taxCents = order.tax_cents;
      paymentReference = order.payment_reference;
      refundReference = generateRefundReference();

      /* The clawback evidence, captured NOW because it cannot be
         re-derived later: which months already had a final run at
         the moment the money went back. See migration 022 section 5. */
      const snapshotResult = await client.queryObject<{ snapshot: unknown }>(
        `select app.fn_refund_comp_snapshot($1) as snapshot`,
        [order.id],
      );
      const compImpact = snapshotResult.rows[0]?.snapshot ?? {};

      const inserted = await client.queryObject<{ id: number }>(
        `insert into app.demo_order_refunds
           (demo_order_id, order_number, amount_cents, tax_cents_returned,
            refund_kind, reason_code, reason_note, requested_by,
            requested_ip_hash, refund_reference, status, volume_month_first,
            comp_impact)
         values ($1, $2, $3, $4, 'full', $5, $6, $7, $8, $9, 'requested',
                 date_trunc('month', $10::timestamptz at time zone 'UTC')::date,
                 $11::jsonb)
         returning id`,
        [
          order.id,
          order.order_number,
          amountCents,
          taxCents,
          reasonCode,
          reasonNote,
          actor.user,
          ipHash,
          refundReference,
          order.created_at.toISOString(),
          JSON.stringify(compImpact),
        ],
      );
      refundId = inserted.rows[0].id;

      /* COMMIT BEFORE THE PROCESSOR IS CALLED. This is the whole
         anti-double-refund design; see the file header. */
      await client.queryArray("commit");
    } catch (err) {
      await client.queryArray("rollback").catch(() => {});
      throw err;
    }

    await auditStaffAction(client, {
      actor: actor.user,
      actor_role: actor.role,
      action: "refund_payment",
      target: orderNumber,
      outcome: "allowed",
      outcome_code: "requested",
      ip_hash: ipHash,
      detail: {
        refund_reference: refundReference,
        amount_cents: amountCents,
        tax_cents_returned: taxCents,
        reason_code: reasonCode,
      },
    });

    /* ============================================================
       PHASE TWO: call HyperSwitch.

       POST /refunds with payment_id, our refund_id, the amount in
       minor units, and a reason. refund_id is the documented
       idempotency mechanism, so even a retry of this exact call
       cannot produce two refunds at the processor.
       ============================================================ */
    let hsResponse: Response;
    try {
      hsResponse = await fetch(`${HYPERSWITCH_BASE_URL}/refunds`, {
        method: "POST",
        headers: {
          "api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          /* Read from the locked row in phase one, never re-fetched
             here: the value that was checked is the value that is
             sent. */
          payment_id: paymentReference,
          refund_id: refundReference,
          amount: amountCents,
          reason: processorReason(reasonCode),
          refund_type: "instant",
          metadata: { order_number: orderNumber },
        }),
        signal: AbortSignal.timeout(20_000),
      });
    } catch {
      /* Unknown outcome. The row stays 'requested' and holds the
         slot, so nothing can double-refund. The next click syncs. */
      console.error(`refund-payment: HyperSwitch unreachable for ${orderNumber}`);
      return jsonResponse(req, 202, {
        order_number: orderNumber,
        refund_status: "requested",
        settled: false,
        action: "processor_unreachable",
        message:
          "The refund was recorded but the processor did not answer. Check this order again shortly; it will not be refunded twice.",
      });
    }

    if (!hsResponse.ok) {
      /* Status code only, never the body wholesale, never the key. */
      console.error(
        `refund-payment: HyperSwitch POST /refunds returned ${hsResponse.status} for ${orderNumber}`,
      );
      /* A 4xx is a refusal we can believe: the refund did not
         happen, so release the slot and let the agent retry or
         escalate. A 5xx is genuinely unknown, so the row stays
         'requested' and the sync path settles it later. */
      if (hsResponse.status >= 400 && hsResponse.status < 500) {
        await client.queryArray(
          `update app.demo_order_refunds
              set status = 'failed', processor_summary = $1::jsonb
            where id = $2 and status = 'requested'`,
          [
            JSON.stringify({
              status: "rejected",
              error_code: `http_${hsResponse.status}`,
              error_message: "The processor refused the refund request.",
              last_synced_at: new Date().toISOString(),
              synced_by: "refund-payment",
            }),
            refundId,
          ],
        );
        return errorResponse(
          req,
          502,
          "processor_refused",
          "The processor refused this refund. Nothing was returned to the customer.",
        );
      }
      return jsonResponse(req, 202, {
        order_number: orderNumber,
        refund_status: "requested",
        settled: false,
        action: "processor_error",
        message:
          "The refund was recorded but the processor errored. Check this order again shortly; it will not be refunded twice.",
      });
    }

    const hs = (await hsResponse.json()) as Record<string, unknown>;
    const mapped = mapRefundStatus(hs.status);
    if (!mapped.known) {
      console.error(
        `refund-payment: unrecognised refund status on ${orderNumber}`,
      );
    }

    /* SANITY CHECK ON THE WAY BACK. HyperSwitch echoes the amount
       it refunded. If that is not the amount we asked for, we do
       NOT mark the order refunded on this pass: the row is left
       for a human and for the sync path. Cheap, and it is the same
       instinct as the cent-for-cent check on the payment side. */
    if (typeof hs.amount === "number" && hs.amount !== amountCents) {
      console.error(
        `refund-payment: processor refunded a different amount on ${orderNumber}`,
      );
      await client.queryArray(
        `update app.demo_order_refunds
            set status = 'review', processor_summary = $1::jsonb
          where id = $2 and status = 'requested'`,
        [
          JSON.stringify(
            summarize(hs, "refund-payment", {
              error_code: "amount_mismatch",
              error_message: "The processor refunded a different amount than requested.",
            }),
          ),
          refundId,
        ],
      );
      return jsonResponse(req, 202, {
        order_number: orderNumber,
        refund_status: "review",
        settled: false,
        action: "amount_mismatch",
        message: "The processor reported a different amount. This refund needs a human.",
      });
    }

    await applyRefundTruth(
      client,
      { id: refundId, order_number: orderNumber },
      mapped.status,
      hs,
      "refund-payment",
    );

    return jsonResponse(req, 200, {
      order_number: orderNumber,
      refund_status: mapped.status,
      amount: amountCents / 100,
      tax_returned: taxCents / 100,
      settled: isTerminal(mapped.status),
      action: mapped.status === "succeeded" ? "refunded" : "recorded",
      /* Said out loud to the operator, every time, because the
         staff console should never have to remember it. */
      note: mapped.status === "succeeded"
        ? "The customer has been returned everything they paid, including tax."
        : "The processor has not settled this refund yet.",
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`refund-payment: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Could not process that refund right now.",
    );
  } finally {
    client.release();
  }
});
