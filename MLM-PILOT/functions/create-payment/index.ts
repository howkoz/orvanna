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
      metadata per spec 1.2 step 6, 3-D Secure (3DS) requested,
      and a SERVER-BUILT return address.
  10. Returns { order_number, client_secret, publishable_key }.

   3-D Secure (3DS), added 2026-08-14 per docs/3DS-RESEARCH.md:
   the create body now carries authentication_type "three_ds" and
   request_external_three_ds_authentication true, which together
   engage the external authentication connector (3DSecure.io).
   Before this, the body said nothing about authentication at
   all, which is why nothing had ever challenged: we asked for
   nothing.

   External authentication also demands a billing address. This
   demo collects nothing personal, so it sends a hardcoded
   SYNTHETIC address (DEMO_BILLING_ADDRESS below) that satisfies
   the protocol without collecting anything from anyone.

   RETURN ADDRESS, and why it is built here and not in the
   browser: a card issuer's challenge can take the shopper's
   whole page away (HyperSwitch's redirect_to_url next action is
   an unconditional window.location.replace). The address they
   come back to is therefore attacker-interesting. We build it
   from the request's own Origin, which isAllowedOrigin has
   already checked, plus a page name from a two-item allow list,
   plus our order number. A client-supplied full address would be
   an open redirect and is never accepted.
       https://<allowed origin>/<shop.html|staff.html>?orv=<order number>

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

/* ------------------------------------------------------------
   3-D Secure (3DS) mode. Two named constants, so switching this
   later is one obvious line and not an archaeology exercise.

   AUTHENTICATION_TYPE "three_ds" asks for authentication
   deterministically instead of leaving it to HyperSwitch's 3DS
   Decision Manager and the connector's default. Sending nothing,
   which is what we used to do, is why behaviour looked arbitrary
   and why nothing ever challenged.

   REQUEST_EXTERNAL_THREE_DS true routes authentication to the
   EXTERNAL provider (3DSecure.io) instead of to the payment
   connector's own 3DS. This is the switch that makes the
   authentication connector Howard configured actually do
   something; without it, it stays idle however healthy it looks
   in the dashboard.

   REQUEST_EXTERNAL_THREE_DS IS FALSE, DELIBERATELY, 2026-08-15.
   Read this before turning it back on.

   External authentication has a prerequisite that is invisible
   from the dashboard and absent from the documentation: the
   PAYMENT processor must itself be on HyperSwitch's hard-coded
   list of connectors that support separate authentication. The
   list lives in crates/common_enums/src/connector_enums.rs, in
   is_separate_authentication_supported(), and it is exactly:

     Stripe, Checkout, Braintree, Adyen, Cybersource,
     Nuvei, NMI, Zift, Archipel

   Every HyperSwitch DUMMY connector returns false there, by
   name. That single line explains two nights of silence: with a
   simulator selected, HyperSwitch skipped authentication
   entirely and charged the card, and the standalone
   authentication endpoint refused us with "you cannot
   authenticate this payment because
   payment_attempt.external_three_ds_authentication_attempted is
   false". Nothing configurable on our side could have changed
   that outcome.

   So the account now runs Braintree in sandbox, which IS on the
   list, accepts raw test cards, and raises its own challenge.
   With authentication_type "three_ds" alone, Braintree returns
   requires_customer_action and a redirect_to_url next action:
   a real bank approval screen, verified 2026-08-15.

   TO SWITCH TO THE EXTERNAL PROVIDER (3DSecure.io) LATER, set
   this back to true, and note one correction to the older note
   below: the acquirer Bank Identification Number (BIN) and
   acquirer merchant identifier are read from the PAYMENT
   connector's metadata first (see
   get_payment_external_authentication_flow_during_confirm in
   crates/router/src/core/payments/helpers.rs). The values on the
   3DSecure.io connector are only a fallback. Put them on the
   Braintree connector before flipping this.

   Still true either way: external authentication also demands a
   billing address. See DEMO_BILLING_ADDRESS below.

   Background: docs/3DS-RESEARCH.md, "Acquirer configuration".
   ------------------------------------------------------------ */
const AUTHENTICATION_TYPE = "three_ds";
const REQUEST_EXTERNAL_THREE_DS = false;

/* ------------------------------------------------------------
   SYNTHETIC DEMONSTRATION BILLING ADDRESS. Read this before
   changing it.

   WHAT IT IS: a made-up United States address, hardcoded here,
   sent on every demo payment. It is not anyone's address. It is
   not Orvanna's address. No human lives at 1 Demonstration Way.

   WHY IT EXISTS: the external authentication request builder
   hard-requires a billing address, and errors out on each of
   city, address line one, postal code, country and state when
   absent. Without these five fields the request fails on
   billing_address.address.city long before the acquirer values
   are ever looked at. A structurally valid fake satisfies the
   protocol without collecting anything.

   WHY IT IS A CONSTANT AND NEVER SHOPPER INPUT: the privacy rail
   is that nothing personal reaches these functions. If this came
   from a form, a stranger playing with a public demo would be
   handing us, and the card networks, their real home address.
   That is a product and privacy decision, not a code detail.

   THEREFORE: never replace this with collected data without a
   privacy review, and never accept any part of it from the
   request body.

   Consequence to expect, stated honestly: a risk engine given a
   fake address has less to work with, so it challenges more
   often. For a demo whose whole point is to show the challenge
   flow, that is a feature.

   Background: docs/3DS-RESEARCH.md, "Acquirer configuration",
   section 5.4 "No billing address", option B.
   ------------------------------------------------------------ */
const DEMO_BILLING_ADDRESS = {
  address: {
    line1: "1 Demonstration Way",
    city: "Springfield",
    state: "IL",
    zip: "62701",
    country: "US",
    /* Obviously synthetic, and present because some
       authentication request builders want a cardholder name
       alongside the address. Never a shopper's name. */
    first_name: "Orvanna",
    last_name: "Demo",
  },
} as const;

/* The only two pages a payment may return to. Anything else, or
   nothing at all, means shop.html. This list is the whole
   defence against an open redirect on the return address, so it
   stays a literal allow list and never becomes a pattern. */
const RETURN_PAGES = ["shop.html", "staff.html"] as const;
const DEFAULT_RETURN_PAGE = "shop.html";

/* Build the address the issuer sends the shopper back to.
   origin is the request's Origin header, already validated by
   isAllowedOrigin; page comes from the allow list above; the
   order number is ours. HyperSwitch appends its own query
   parameters (status, payment_intent_client_secret, amount,
   manual_retry_allowed, signature, signature_algorithm) to
   whatever we give it, so ours rides alongside them. */
function buildReturnUrl(
  origin: string,
  requestedPage: unknown,
  orderNumber: string,
): string {
  const page = RETURN_PAGES.find((p) => p === requestedPage) ?? DEFAULT_RETURN_PAGE;
  return `${origin.replace(/\/+$/, "")}/${page}?orv=${encodeURIComponent(orderNumber)}`;
}

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
  const origin = req.headers.get("origin");
  if (!isAllowedOrigin(origin)) {
    return errorResponse(
      req,
      403,
      "origin_not_allowed",
      "This demo only answers its own site.",
    );
  }
  /* Narrowed by the check above: an allowed origin is a string. */
  const allowedOrigin = origin as string;

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
    /* Optional. "shop.html" or "staff.html" only; anything else
       (including absent, or a full address someone tried to
       smuggle in) falls back to shop.html in buildReturnUrl. */
    const requestedReturnPage = body.return_page;

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
          /* Ask for 3-D Secure deterministically rather than
             leaving it to the connector's own default, so the
             flow is exercised the same way every time. */
          authentication_type: AUTHENTICATION_TYPE,
          /* Route authentication to the external provider
             (3DSecure.io) rather than to the payment connector's
             own 3DS. Requires the acquirer pair on the connector
             AND the billing address below. */
          request_external_three_ds_authentication:
            REQUEST_EXTERNAL_THREE_DS,
          /* Hardcoded synthetic address. Never shopper input.
             See DEMO_BILLING_ADDRESS above. */
          billing: DEMO_BILLING_ADDRESS,
          /* Sent at create time as well as by the browser at
             confirm time, so a server-driven redirect still has
             somewhere to land if the browser value is lost. */
          return_url: buildReturnUrl(
            allowedOrigin,
            requestedReturnPage,
            orderNumber,
          ),
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
