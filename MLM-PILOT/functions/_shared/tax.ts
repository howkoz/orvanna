/* ============================================================
   tax.ts: the one place tax is decided.

   WHY THIS FILE EXISTS AT ALL.

   Until 2026-08-15 tax was calculated inside create-payment, as a
   side effect of opening a payment. That meant the only way to
   learn what tax was owed was to create an order row and a
   HyperSwitch payment first. Howard put the problem plainly:

     "you need to calculate the tax before payment is sent ...
      no one wants to make a payment and then find out 71 dollars
      was applied after submitting the card"

   So the calculation moved here, and two callers now share it:

     quote-tax     prices a cart and answers. Creates nothing.
     create-payment prices the same cart and charges it.

   THEY MUST AGREE, ALWAYS. A quote that says one number and a
   charge that says another is the single worst bug this checkout
   could ship, and copying this logic into two files is exactly how
   that bug gets written. One function, two callers, no second
   opinion.

   THE THREE RULES IT OBEYS, unchanged from when they were written
   inside create-payment:

   1. THE DESTINATION COMES FROM THE DATABASE, NEVER THE BROWSER.
      It is read from the signed-in member's row by
      resolveTaxAddress below. A browser that can choose its own
      destination can choose its own tax rate, which is the same
      mistake as letting it choose its own price.

   2. EXEMPTION IS STRIPE'S DECISION, NOT THE PAGE'S. The page
      sends the tax identifier TEXT, this file decides whether it
      even looks like one, and Stripe decides what it means. Honest
      limit, stated because the page states it too: Stripe checks
      the FORMAT of an identifier, not the government register
      behind it, so a well-formed fake passes. The mechanism is
      real; the verification is not, and we say so rather than
      implying a check we do not perform.

   3. A ZERO IS NEVER REPORTED WITHOUT ITS REASON. Stripe returns
      zero both when we hold no registration in a jurisdiction (a
      misconfiguration, ours to fix) and when that jurisdiction
      simply does not tax the product (the correct answer).
      taxability_reason is the only thing that separates them, so
      it is carried back and stored rather than discarded.

   FALLBACK. If Stripe cannot be reached the cart still prices, at
   the flat rate, and the outcome records source 'flat_fallback' so
   the difference is never silent. The tax code is deliberately not
   sent: the preset product category configured in the Stripe
   dashboard is the single place that decision should live.

   Secrets: STRIPE_SECRET_KEY only, via Deno.env.get.
   ============================================================ */

import type { DbClient } from "./edge.ts";

const STRIPE_TAX_URL = "https://api.stripe.com/v1/tax/calculations";

export interface TaxAddress {
  line1: string;
  city: string;
  state: string;
  zip: string;
  country: string;
}

export interface TaxOutcome {
  tax_cents: number;
  source: "stripe_tax" | "flat_fallback";
  calculation_id: string | null;
  reason: string | null;
  jurisdiction: string | null;
}

/* THE HOUSE DESTINATION. Used for a guest, and for a member code
   that matches nobody, so a calculation always has somewhere to
   land rather than silently returning zero for want of an address.

   Worth knowing when a guest sees no tax: we hold no Illinois
   registration, so Stripe correctly answers zero with the reason
   'not_collecting'. That is a real answer about a real place, not
   a failure, and the checkout says which of the two it is. */
export const HOUSE_TAX_ADDRESS: TaxAddress = {
  line1: "1 Demonstration Way",
  city: "Springfield",
  state: "IL",
  zip: "62701",
  country: "US",
};

/* A tax identifier is TEXT here and a verdict nowhere else. The
   old browser-supplied tax_exempt boolean let any caller zero
   their own tax, which was the one hole in an otherwise
   server-authoritative money path. */
export function looksLikeTaxId(taxIdText: string): boolean {
  return /\d/.test(taxIdText);
}

/* Read the destination for a member code, server side.

   A miss is not an error: a mistyped code must never fail a cart,
   so it falls back to the house address exactly as a guest does.
   Returns the member's row id too, because create-payment needs it
   for attribution and would otherwise repeat this query. */
export async function resolveTaxAddress(
  client: DbClient,
  rawMemberCode: string,
): Promise<{ memberId: number | null; address: TaxAddress }> {
  if (rawMemberCode === "") {
    return { memberId: null, address: HOUSE_TAX_ADDRESS };
  }
  const memberRow = await client.queryObject<{
    id: number;
    demo_address_line1: string | null;
    demo_address_city: string | null;
    demo_address_state: string | null;
    demo_address_zip: string | null;
    demo_address_country: string | null;
  }>(
    `select id, demo_address_line1, demo_address_city, demo_address_state,
            demo_address_zip, demo_address_country
       from app.members where member_code = $1`,
    [rawMemberCode],
  );
  const m = memberRow.rows[0];
  if (!m) return { memberId: null, address: HOUSE_TAX_ADDRESS };
  if (!m.demo_address_zip) {
    return { memberId: m.id, address: HOUSE_TAX_ADDRESS };
  }
  return {
    memberId: m.id,
    address: {
      line1: m.demo_address_line1 ?? HOUSE_TAX_ADDRESS.line1,
      city: m.demo_address_city ?? HOUSE_TAX_ADDRESS.city,
      state: m.demo_address_state ?? HOUSE_TAX_ADDRESS.state,
      zip: m.demo_address_zip,
      country: m.demo_address_country ?? "US",
    },
  };
}

export async function calculateTax(
  taxableCents: number,
  address: TaxAddress,
  taxIdText: string,
  flatFallbackCents: number,
): Promise<TaxOutcome> {
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) {
    return {
      tax_cents: flatFallbackCents,
      source: "flat_fallback",
      calculation_id: null,
      reason: "stripe_not_configured",
      jurisdiction: null,
    };
  }

  /* Nothing to tax means nothing to ask about. Stripe rejects a
     zero-amount calculation, and spending a network round trip to
     be told so would slow every empty-cart render. */
  if (taxableCents <= 0) {
    return {
      tax_cents: 0,
      source: "stripe_tax",
      calculation_id: null,
      reason: "nothing_taxable",
      jurisdiction: null,
    };
  }

  /* One line item for the whole taxable amount. Every product here is
     the same category (software as a service), so splitting per item
     would produce identical treatment and only add rounding seams. */
  const form = new URLSearchParams();
  form.set("currency", "usd");
  form.set("line_items[0][amount]", String(taxableCents));
  form.set("line_items[0][reference]", "orvanna-order");
  form.set("line_items[0][tax_behavior]", "exclusive");
  form.set("customer_details[address][line1]", address.line1);
  form.set("customer_details[address][city]", address.city);
  form.set("customer_details[address][state]", address.state);
  form.set("customer_details[address][postal_code]", address.zip);
  form.set("customer_details[address][country]", address.country);
  form.set("customer_details[address_source]", "billing");
  /* A tax identifier that looks like one asks Stripe to treat the
     buyer as exempt. Stripe, not this function, decides the effect. */
  if (looksLikeTaxId(taxIdText)) {
    form.set("customer_details[taxability_override]", "customer_exempt");
  }

  try {
    const resp = await fetch(STRIPE_TAX_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form.toString(),
      signal: AbortSignal.timeout(8_000),
    });
    if (!resp.ok) {
      console.error(`tax: Stripe Tax returned ${resp.status}`);
      return {
        tax_cents: flatFallbackCents,
        source: "flat_fallback",
        calculation_id: null,
        reason: `stripe_http_${resp.status}`,
        jurisdiction: null,
      };
    }
    const calc = (await resp.json()) as {
      id?: string;
      tax_amount_exclusive?: number;
      tax_breakdown?: Array<{
        taxability_reason?: string;
        tax_rate_details?: { state?: string; country?: string; tax_type?: string };
      }>;
    };
    const first = calc.tax_breakdown?.[0];
    const j = first?.tax_rate_details;
    return {
      tax_cents: calc.tax_amount_exclusive ?? 0,
      source: "stripe_tax",
      calculation_id: calc.id ?? null,
      reason: first?.taxability_reason ?? "no_breakdown",
      jurisdiction: j ? [j.state, j.country].filter(Boolean).join(", ") : null,
    };
  } catch {
    console.error("tax: Stripe Tax unreachable");
    return {
      tax_cents: flatFallbackCents,
      source: "flat_fallback",
      calculation_id: null,
      reason: "stripe_unreachable",
      jurisdiction: null,
    };
  }
}
