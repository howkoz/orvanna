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

/* ------------------------------------------------------------
   THE GUEST STATE ALLOW LIST (added 2026-08-16).

   Howard's ask: a guest should be able to pick a state and watch
   the tax engine answer for THAT state, instead of every guest
   order silently pricing from Illinois. The rule that the
   destination comes from the server, never the browser, does not
   bend for this: the browser sends only a two-letter CODE, and
   this table is the only place a code becomes an address. Every
   address is canned, synthetic at the street (nobody lives at
   1 Demonstration Way), and real at the city, ZIP code, and
   state, which is what Stripe Tax actually prices on.

   Eight states, chosen for the demonstration they give:
     IL  the house default, stated everywhere as the default
     NY  the famous 8.875 percent New York City combined rate
     CA, TX, FL  three large, familiar, different-rate states
     OR  no state sales tax at all: the zero-with-a-reason demo
     WA, CO  two more distinct regimes (WA high, CO low state rate)

   An unknown or absent code falls back to the house address,
   silently HERE (a mistyped code must never fail a quote or a
   cart) and visibly on the page, which labels the default as the
   default. Whether a chosen state actually returns a nonzero
   figure is still Howard's Stripe dashboard registration for that
   state; an unregistered state answers zero with the reason
   not_collecting, and the page says which zero it is.
   ------------------------------------------------------------ */
export const GUEST_STATE_ADDRESSES: Record<string, TaxAddress> = {
  IL: HOUSE_TAX_ADDRESS,
  NY: { line1: "1 Demonstration Way", city: "New York", state: "NY", zip: "10007", country: "US" },
  CA: { line1: "1 Demonstration Way", city: "Sacramento", state: "CA", zip: "95814", country: "US" },
  TX: { line1: "1 Demonstration Way", city: "Austin", state: "TX", zip: "78701", country: "US" },
  FL: { line1: "1 Demonstration Way", city: "Tallahassee", state: "FL", zip: "32301", country: "US" },
  OR: { line1: "1 Demonstration Way", city: "Portland", state: "OR", zip: "97201", country: "US" },
  WA: { line1: "1 Demonstration Way", city: "Seattle", state: "WA", zip: "98101", country: "US" },
  CO: { line1: "1 Demonstration Way", city: "Denver", state: "CO", zip: "80202", country: "US" },
};

/* Map a guest's state code to its canned address. Trimming and
   uppercasing here means the two callers cannot normalize
   differently. Anything not on the list is the house default. */
export function guestAddressFor(rawStateCode: string): TaxAddress {
  const code = rawStateCode.trim().toUpperCase();
  return GUEST_STATE_ADDRESSES[code] ?? HOUSE_TAX_ADDRESS;
}

/* A tax identifier is TEXT here and a verdict nowhere else. The
   old browser-supplied tax_exempt boolean let any caller zero
   their own tax, which was the one hole in an otherwise
   server-authoritative money path. */
export function looksLikeTaxId(taxIdText: string): boolean {
  return /\d/.test(taxIdText);
}

/* Read the destination for a member code, server side.

   A miss is not an error: a mistyped code must never fail a cart,
   so it falls back to the guest path exactly as a guest does.
   Returns the member's row id too, because create-payment needs it
   for attribution and would otherwise repeat this query.

   THE GUEST STATE CODE (third argument, added 2026-08-16) applies
   ONLY when no member row is attached. The precedence, in words:

     member found, address on file   the member's stored address,
                                     the state code is IGNORED
     member found, no address        the house default, the state
                                     code is STILL ignored: an
                                     attached member's tax basis is
                                     the member record, exactly as
                                     before this parameter existed
     no member (empty code or miss)  the guest's picked state from
                                     the allow list, house default
                                     for anything unknown

   Ignoring the code whenever a member is attached is what keeps
   signed-in members byte-for-byte unchanged, and it also means a
   guest who credits a referring member gets that member's real
   destination rather than their own pick, which is the same rule
   the checkout has always applied. */
export async function resolveTaxAddress(
  client: DbClient,
  rawMemberCode: string,
  rawGuestState = "",
): Promise<{ memberId: number | null; address: TaxAddress }> {
  if (rawMemberCode === "") {
    return { memberId: null, address: guestAddressFor(rawGuestState) };
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
  if (!m) return { memberId: null, address: guestAddressFor(rawGuestState) };
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
