/* ============================================================
   quote-tax (Supabase Edge Function, Deno)

   Prices a cart and answers what tax is owed. CREATES NOTHING:
   no order row, no HyperSwitch payment, no Stripe transaction.

   WHY IT EXISTS. Howard, 2026-08-15:

     "you need to calculate the tax before payment is sent ... so
      you will need to do an additional call to get the taxes ...
      no one wants to make a payment and then find out 71 dollars
      was applied after submitting the card"

   Before this, tax was a side effect of opening a payment. Three
   things were wrong with that, and this function fixes all three:

   1. NOTHING COULD BE PRICED WITHOUT BEING STARTED. Merely looking
      at a total wrote an order row and opened a payment at the
      processor. The abandoned-order sweep existed largely to clean
      up after curiosity.

   2. THE INTERIM WAS A GUESS WEARING THE ANSWER'S CLOTHES. For the
      seconds before the payment came back, the summary showed a
      flat five percent, in the same position and the same type as
      the real figure. Nobody could tell which one they were
      looking at.

   3. CHANGING THE CART THREW A PAYMENT AWAY. Adding an item
      discarded a perfectly good payment purely to re-ask what tax
      was owed on the new amount.

   WHAT IT IS NOT. It is not authority. The charge is still priced
   by create-payment, from the same cart, through the same shared
   calculateTax, at the moment the payment opens. This answers the
   question "what will this cost"; create-payment answers "what is
   being charged". They share one implementation (_shared/tax.ts)
   precisely so they cannot drift apart, and the page always defers
   to the payment's figure once it has one.

   A quote is not held. Stripe's calculation identifier is
   deliberately NOT returned or stored: a calculation only becomes
   a tax record when a sale completes, that recording is
   record-tax's job, and a quote that nobody buys should leave
   nothing behind.

   Rate limit: its own bucket, deliberately looser than create's,
   because quoting is what a shopper does repeatedly while making
   up their mind and it must never eat the budget for actually
   paying (the same reasoning that gave confirm its own scope).

   Nothing personal is accepted, stored, or logged: no names, no
   addresses, no Tax ID values, no card data, no raw IPs. The
   destination is read from the database, never from the request.
   ============================================================ */

import {
  callerIpHash,
  checkRateLimit,
  errorResponse,
  getPool,
  isAllowedOrigin,
  jsonResponse,
  preflight,
} from "../_shared/edge.ts";
import { priceCart } from "../_shared/pricing.ts";
import { calculateTax, looksLikeTaxId, resolveTaxAddress } from "../_shared/tax.ts";

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
  const client = await getPool().connect();
  try {
    /* Looser than create's 5 and 30, and in its own 'quote' scope so
       a shopper who fiddles with their cart can still pay at the end
       of it. Still bounded: every quote is a Stripe call. */
    const verdict = await checkRateLimit(
      ipHash,
      { perMinute: 20, perHour: 200 },
      "quote",
      client,
    );
    if (!verdict.allowed) {
      return errorResponse(
        req,
        429,
        "rate_limited",
        "Pricing this cart a little too often. Please wait a moment.",
        { "Retry-After": String(verdict.retryAfterSeconds) },
      );
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return errorResponse(req, 400, "bad_json", "The request body is not valid JSON.");
    }

    const activation = typeof body.activation === "string" ? body.activation : "";
    const taxIdText = typeof body.tax_id === "string" ? body.tax_id.trim().slice(0, 40) : "";
    const rawMemberCode =
      typeof body.member_code === "string" ? body.member_code.trim().slice(0, 40) : "";

    /* Identical call to the one create-payment makes, on purpose:
       the same mirror, the same caps, the same ceiling. A quote that
       accepted a cart the charge would reject would be a lie told
       early. */
    const priced = priceCart(body.items, activation, looksLikeTaxId(taxIdText));
    if (!priced.ok) {
      return errorResponse(req, 400, "invalid_cart", priced.message);
    }
    const order = priced.order;

    const { address } = await resolveTaxAddress(client, rawMemberCode);

    const taxableCents =
      order.subtotal_one_cents + order.subtotal_sub_cents + order.activation_fee_cents;
    const taxOutcome = await calculateTax(
      taxableCents,
      address,
      taxIdText,
      order.tax_cents, /* the mirror's flat figure, used only if Stripe cannot answer */
    );

    /* Recomputed from parts rather than adjusted, so a quoted total
       can never drift from the lines above it. */
    return jsonResponse(req, 200, {
      totals: {
        subtotal_one_cents: order.subtotal_one_cents,
        subtotal_sub_cents: order.subtotal_sub_cents,
        activation_fee_cents: order.activation_fee_cents,
        tax_cents: taxOutcome.tax_cents,
        total_cents: taxableCents + taxOutcome.tax_cents,
        tax_source: taxOutcome.source,
        tax_reason: taxOutcome.reason,
        tax_jurisdiction: taxOutcome.jurisdiction,
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`quote-tax: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Could not price this cart just now.",
    );
  } finally {
    client.release();
  }
});
