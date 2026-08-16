/* ============================================================
   refund-payment (Supabase Edge Function, Deno)

   LIVE. Deployed 2026-08-16 by Howard from the command line tool,
   which reads from disk, so this file is what is running.

   Deployed with verify_jwt TRUE, matching every other function
   except the webhook. That is fine and needed no workaround: the
   staff token travels in x-orvanna-session, so the platform keeps
   Authorization for the anonymous key and the two never collide.
   That header split was designed for exactly this case.

   Design: DOCUMENTATION\11-REFUNDS.md
   Schema: db\migrations\022_refunds.sql plus 023 (guard fix)
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
   FOUR RULES ABOUT THE ORDER, ALL ENFORCED HERE, NONE ON THE
   SCREEN

   An order may be refunded only if it is not already refunded,
   has no refund already in flight, actually reached 'succeeded',
   and was placed within the last 24 hours (REFUND_WINDOW_HOURS in
   _shared/refund-rules.ts, which is the one line to change).

   THE STAFF CONSOLE ENFORCES NONE OF THESE. It shows a plain
   refund button on every order, sends the request, and displays
   whatever the server says. That is Howard's call: "i can do that
   as a rule that i need to know so you do not have to program so
   much around that."

   It is also the safer half of the split. A screen that hides or
   greys a button is a courtesy to the person reading it and stops
   nobody; these checks are what mean a mistyped order number, a
   stale browser tab, or a replayed request cannot reach an old or
   ineligible order even though a person never would on purpose.

   ------------------------------------------------------------
   STAFF ONLY. THIS IS THE PRIMARY SECURITY REQUIREMENT OF THE
   WHOLE FEATURE, NOT A USER INTERFACE DETAIL.

   Howard, 2026-08-15: refunds "can only be available in the staff
   area". A Conductor, a shopper and an anonymous visitor must
   never be able to cause one.

   THREE THINGS THAT LOOK LIKE THEY SATISFY THAT AND DO NOT:

     1. Rendering the button only on staff.html. This endpoint is
        public HTTPS. Anyone who reads the shipped JavaScript knows
        its name and its request shape. Which page draws a button
        is not a gate.
     2. The origin allow list. isAllowedOrigin says the request came
        from OUR SITE. Every page on our site passes it, the shop
        included. It is a cross-site protection, not an identity
        check, and it is not described as one anywhere in this file.
     3. The browser's session object. Open finding V-H3: staff.html
        reads a session object out of session storage and trusts
        it, so a hand-written one opens the page. The browser
        cannot be the source of truth about who is asking.

   SO THE DECISION IS MADE SERVER SIDE, AGAINST THE DATABASE, ON
   EVERY CALL, in functions/_shared/staff-auth.ts: verify the token
   signature against the key in app.demo_auth_config, check the
   expiry, then RE-READ THE ROLE FROM app.demo_users and require
   'staff'. The token's role claim is discarded, so changing or
   deleting a person's row revokes them on their very next call.

   That module had to be BUILT. www/staff.html claimed "the real
   gate is the role check the server performs on every function
   call", and no such check existed anywhere in this codebase:
   demo-login minted tokens that nothing ever verified. This
   function is that module's first caller, which is what makes the
   claim true.

   Origin and rate limit still run, first. They are rails, not
   gates, and the difference is the point.

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

   ------------------------------------------------------------
   VERIFIED AGAINST THE LIVE ENDPOINT, 2026-08-16.

   Ten refusals were sent directly to this endpoint, not through the
   screen, and every one refused. The six authorisation failures all
   answer the caller with the same 'not_authorised' and record six
   DIFFERENT reasons in app.demo_staff_actions, which is the design
   working. Full table in section 16.0 of the design document.

   The two that could never be tested before deploy, because they
   need the database, both refused by name: the Orvanna_Admin member
   portal login and a GW-000001 Conductor login. There are 1,002
   accounts that can sign in and exactly one that may refund.

   ONE OPEN DEFECT, an audit label rather than a hole. A request with
   NO session header is logged as bad_signature, not missing_token,
   because bearerFrom falls back to Authorization and on this
   deployment that header always carries the anonymous key: a
   well-formed token that simply is not ours. The refusal is correct
   and nothing reaches an order. What is lost is the ability to tell
   "nobody was signed in" from "somebody presented a forged token",
   and the second is the one worth alerting on.

   THE FIX IS ONE LINE: drop the Authorization fallback in
   _shared/staff-auth.ts bearerFrom. It is right for this function
   precisely BECAUSE it is deployed with verify_jwt true, so that
   header is always the platform's and never ours. Deliberately not
   changed on the night of deploy.

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

/* Every rule about whether an ORDER may be refunded lives in one
   pure module, including the 24 hour window. Imported rather than
   restated here so the four server-enforced rules cannot be
   partially copied by a future caller, and so they can be executed
   and proven without a server. See _shared/refund-rules.ts. */
import {
  isOrderNumber,
  isReasonCode,
  isTerminal,
  mapRefundStatus,
  processorReason,
  REFUND_WINDOW_HOURS,
  refundRefusal,
  type ReasonCode,
  type RefundStatus,
} from "../_shared/refund-rules.ts";

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
  req: Request,
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

  /* jsonResponse, not a bare Response: this answer goes to a browser
     and must carry the cross-origin headers, exactly like every
     other reply in this file. */
  return jsonResponse(req, 200, {
    order_number: order.order_number,
    refund_status: mapped.status,
    amount: refund.amount_cents / 100,
    settled: isTerminal(mapped.status),
    action: "synced_existing",
  });
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
      /* 'anonymous' because this rail fires BEFORE authorisation, so
         at this point we genuinely do not know who is asking. Same
         literal the auth refusal uses, so one query finds every
         attempt that never got as far as an identity. */
      await auditStaffAction(client, {
        actor: "anonymous",
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

    /* ---- rail 3: AUTHORISATION. THE ONE THAT ACTUALLY GATES. ----

       Howard, 2026-08-15: refunds "can only be available in the
       staff area". This line is what enforces that. Not the page
       the button lives on, and not the origin check above.

       Neither of those is an identity check. The control living
       only on staff.html stops nobody, because this endpoint is
       public HTTPS and its shape is readable in the shipped
       JavaScript. And isAllowedOrigin only says the request came
       from our own site: the shop passes it too.

       requireStaff verifies the token signature against the key in
       app.demo_auth_config, checks the expiry, then RE-READS THE
       ROLE FROM app.demo_users. The token's own role claim is
       discarded, so revoking a person actually revokes them.

       STAFF ONLY, AND 'admin' IS NOT A SUPERSET. In this project
       admin is the MEMBER PORTAL demonstration account (migration
       012: "admin opens the member portal, staff opens the call
       console"). Passing ["staff"] is what keeps a Conductor out.
       Read the header of _shared/staff-auth.ts before widening it.

       THE CALLER IS TOLD ONE THING FOR ALL FAILURES. Missing,
       forged, expired, unknown user, wrong role: all of them get
       'not_authorised'. The specific code goes to the audit log,
       where it helps an operator and does not help a prober. */
    const auth = await requireStaff(client, req, ["staff"]);
    if (!auth.ok) {
      /* Finding N-M1, implemented 2026-08-16. NOT YET DEPLOYED:
         deploy owes a byte-compare against the cloud copy plus both
         gates per the standing rule; the repo is knowingly ahead of
         the cloud here, on record.

         When the refusal happened AFTER the token's signature
         verified (expired, unknown_user, wrong_role), requireStaff
         now hands back the verified username, and the audit line
         names it instead of discarding it as "anonymous". Refusals
         where no identity was ever established (missing, malformed,
         forged token) still audit as "anonymous". */
      await auditStaffAction(client, {
        actor: auth.verified_user ?? "anonymous",
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
    if (!isOrderNumber(orderNumber)) {
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

    const reasonCode: ReasonCode | null = isReasonCode(body.reason_code)
      ? body.reason_code
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
      const existing = existingResult.rows[0] ?? null;

      /* ---- THE FOUR ORDER RULES, ALL SERVER SIDE, ONE CALL ----

         not already refunded, not already in flight, actually paid,
         and inside the 24 hour window. The verdict comes from
         _shared/refund-rules.ts so the four cannot be partially
         reimplemented here, and so they can be proven by direct
         execution before anything is deployed.

         THE WINDOW IS ENFORCED HERE, NOT ON THE SCREEN. The staff
         console shows a plain refund button on every order and does
         not compute eligibility at all: Howard knows the rule. This
         check is what makes it a rule rather than a habit, and it is
         what stops a mistyped order number or a browser tab left
         open since yesterday from reaching an old order.

         WHY 'paid' MATTERS MORE THAN IT LOOKS: reaching 'succeeded'
         means retrieveAndApplyPaymentTruth already compared the
         processor amount to total_cents to the cent. So the amount
         about to be returned has been verified against the
         processor, not merely against our own arithmetic. */
      const refusal = refundRefusal({
        order: {
          payment_status: order.payment_status,
          payment_reference: order.payment_reference,
          total_cents: order.total_cents,
          created_at_ms: order.created_at.getTime(),
        },
        existingRefund: existing ? { status: existing.status } : null,
        nowMs: Date.now(),
      });

      if (refusal !== null && refusal.code === "refund_in_flight" && existing) {
        /* The one refusal that does something rather than just
           saying no: settle the refund that already exists instead
           of starting a second one. This is the second click on a
           timed-out first click. */
        await client.queryArray("commit");
        const synced = await syncExistingRefund(req, client, apiKey, order, existing);
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
        return errorResponse(req, refusal.http, refusal.code, refusal.message);
      }

      if (refusal !== null) {
        await client.queryArray("rollback");
        await auditStaffAction(client, {
          actor: actor.user,
          actor_role: actor.role,
          action: "refund_payment",
          target: orderNumber,
          outcome: "refused",
          outcome_code: refusal.code,
          ip_hash: ipHash,
          detail: {
            payment_status: order.payment_status,
            order_age_hours:
              Math.floor((Date.now() - order.created_at.getTime()) / 3_600_000),
            refund_window_hours: REFUND_WINDOW_HOURS,
          },
        });
        return errorResponse(req, refusal.http, refusal.code, refusal.message);
      }

      /* THE AMOUNT COMES FROM THE ORDER ROW, NEVER FROM THE REQUEST.
         There is no code path by which a caller can influence how
         much money leaves. Tax is inside this figure: the customer
         is made whole. */
      amountCents = order.total_cents;
      taxCents = order.tax_cents;
      refundReference = generateRefundReference();

      /* refundRefusal already guarantees a reference is present, but
         the compiler cannot know that and a non-null assertion would
         fail silently if the rule order were ever changed. Re-checked
         rather than asserted, because "silently" is the word that
         matters when the next statement leads to moving money. */
      if (!order.payment_reference) {
        await client.queryArray("rollback");
        return errorResponse(
          req,
          409,
          "no_payment_reference",
          "This order has no processor reference, so it cannot be refunded automatically.",
        );
      }
      paymentReference = order.payment_reference;

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
