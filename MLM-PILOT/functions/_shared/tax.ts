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

   1. A MEMBER DESTINATION COMES FROM THE DATABASE, NEVER THE
      BROWSER. It is read from the signed-in member's row by
      resolveTaxAddress below. A checkout destination may come from
      the billing State/ZIP fields because this is a sandbox pilot
      and the visible address fields are the shopper control. Member
      attribution and tax destination are separate facts.

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

/* Display-currency tax staging.

   Orvanna still stores order money as USD cents and create-payment is
   deliberately guarded to USD. For quote-tax, though, we can ask
   Stripe Tax in the selected display currency and convert the answer
   back into the USD-base cents contract the browser already expects.
   That keeps the page honest while the database currency migration is
   not done yet.

   LOCKSTEP CONTRACT (verifier finding O-M3, 2026-08-16): this table
   is the MIRROR of the single source of truth, the CURRENCIES table
   in www/shop.html, exactly as pricing.ts mirrors catalog.js. It must
   stay rate for rate and code for code identical: the page's table
   converts what the shopper SEES, this one converts what the quote
   SAYS, and any difference makes the displayed conversion and the
   quoted tax disagree by design. Parity is mechanically enforced by
   functions/_shared/check_currency_mirror.py, which the deploy build
   (deploy/build_dist.py) runs and fails on any drift, the same
   discipline as the pricing mirror's check V6. If a rate changes in
   shop.html it changes here in the same commit. */
const TAX_CURRENCY_RATES: Record<string, number> = {
  USD: 1,
  GBP: 0.79,
  EUR: 0.92,
  CHF: 0.88,
};

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
  calculation_currency: string;
  calculation_tax_cents: number;
}

function normalizeTaxCurrency(rawCurrency: string): string {
  const currency = rawCurrency.trim().toUpperCase().slice(0, 3);
  return TAX_CURRENCY_RATES[currency] ? currency : "USD";
}

function displayMinorFromUsdCents(usdCents: number, currency: string): number {
  return Math.round(usdCents * TAX_CURRENCY_RATES[currency]);
}

function usdCentsFromDisplayMinor(displayCents: number, currency: string): number {
  return Math.round(displayCents / TAX_CURRENCY_RATES[currency]);
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
   THE GUEST STATE FALLBACK TABLE (added 2026-08-16).

   The checkout walk made the right shopper expectation clear:
   the visible State/ZIP fields should drive guest tax. This table
   gives every U.S. state a synthetic fallback city and ZIP, while
   guestAddressFor below replaces those defaults with the typed ZIP,
   city, and street when the checkout sends them.

   An unknown or absent code falls back to the house address,
   silently HERE (a mistyped code must never fail a quote or a
   cart) and visibly on the page, which labels the default as the
   default. Whether a chosen state actually returns a nonzero
   figure is still the Stripe dashboard registration for that
   state; an unregistered state answers zero with the reason
   not_collecting, and the page says which zero it is.
   ------------------------------------------------------------ */
export const GUEST_STATE_ADDRESSES: Record<string, TaxAddress> = {
  IL: HOUSE_TAX_ADDRESS,
  GB: { line1: "10 Downing Street", city: "London", state: "", zip: "SW1A 2AA", country: "GB" },
  IE: { line1: "1 College Green", city: "Dublin", state: "", zip: "D02 X285", country: "IE" },
  CH: { line1: "Bahnhofstrasse 1", city: "Zurich", state: "", zip: "8001", country: "CH" },
  AL: { line1: "1 Demonstration Way", city: "Montgomery", state: "AL", zip: "36104", country: "US" },
  AK: { line1: "1 Demonstration Way", city: "Juneau", state: "AK", zip: "99801", country: "US" },
  AZ: { line1: "1 Demonstration Way", city: "Phoenix", state: "AZ", zip: "85004", country: "US" },
  AR: { line1: "1 Demonstration Way", city: "Little Rock", state: "AR", zip: "72201", country: "US" },
  NY: { line1: "1 Demonstration Way", city: "New York", state: "NY", zip: "10007", country: "US" },
  CA: { line1: "1 Demonstration Way", city: "Sacramento", state: "CA", zip: "95814", country: "US" },
  CT: { line1: "1 Demonstration Way", city: "Hartford", state: "CT", zip: "06103", country: "US" },
  DE: { line1: "1 Demonstration Way", city: "Dover", state: "DE", zip: "19901", country: "US" },
  DC: { line1: "1 Demonstration Way", city: "Washington", state: "DC", zip: "20001", country: "US" },
  GA: { line1: "1 Demonstration Way", city: "Atlanta", state: "GA", zip: "30303", country: "US" },
  HI: { line1: "1 Demonstration Way", city: "Honolulu", state: "HI", zip: "96813", country: "US" },
  ID: { line1: "1 Demonstration Way", city: "Boise", state: "ID", zip: "83702", country: "US" },
  IN: { line1: "1 Demonstration Way", city: "Indianapolis", state: "IN", zip: "46204", country: "US" },
  IA: { line1: "1 Demonstration Way", city: "Des Moines", state: "IA", zip: "50309", country: "US" },
  KS: { line1: "1 Demonstration Way", city: "Topeka", state: "KS", zip: "66603", country: "US" },
  KY: { line1: "1 Demonstration Way", city: "Frankfort", state: "KY", zip: "40601", country: "US" },
  LA: { line1: "1 Demonstration Way", city: "Baton Rouge", state: "LA", zip: "70802", country: "US" },
  ME: { line1: "1 Demonstration Way", city: "Augusta", state: "ME", zip: "04330", country: "US" },
  MD: { line1: "1 Demonstration Way", city: "Annapolis", state: "MD", zip: "21401", country: "US" },
  MA: { line1: "1 Demonstration Way", city: "Boston", state: "MA", zip: "02108", country: "US" },
  MI: { line1: "1 Demonstration Way", city: "Lansing", state: "MI", zip: "48933", country: "US" },
  MN: { line1: "1 Demonstration Way", city: "Saint Paul", state: "MN", zip: "55101", country: "US" },
  MS: { line1: "1 Demonstration Way", city: "Jackson", state: "MS", zip: "39201", country: "US" },
  MO: { line1: "1 Demonstration Way", city: "Jefferson City", state: "MO", zip: "65101", country: "US" },
  MT: { line1: "1 Demonstration Way", city: "Helena", state: "MT", zip: "59601", country: "US" },
  NE: { line1: "1 Demonstration Way", city: "Lincoln", state: "NE", zip: "68508", country: "US" },
  NV: { line1: "1 Demonstration Way", city: "Carson City", state: "NV", zip: "89701", country: "US" },
  NH: { line1: "1 Demonstration Way", city: "Concord", state: "NH", zip: "03301", country: "US" },
  NJ: { line1: "1 Demonstration Way", city: "Trenton", state: "NJ", zip: "08608", country: "US" },
  NM: { line1: "1 Demonstration Way", city: "Santa Fe", state: "NM", zip: "87501", country: "US" },
  NC: { line1: "1 Demonstration Way", city: "Raleigh", state: "NC", zip: "27601", country: "US" },
  ND: { line1: "1 Demonstration Way", city: "Bismarck", state: "ND", zip: "58501", country: "US" },
  OH: { line1: "1 Demonstration Way", city: "Columbus", state: "OH", zip: "43215", country: "US" },
  OK: { line1: "1 Demonstration Way", city: "Oklahoma City", state: "OK", zip: "73102", country: "US" },
  PA: { line1: "1 Demonstration Way", city: "Harrisburg", state: "PA", zip: "17101", country: "US" },
  RI: { line1: "1 Demonstration Way", city: "Providence", state: "RI", zip: "02903", country: "US" },
  SC: { line1: "1 Demonstration Way", city: "Columbia", state: "SC", zip: "29201", country: "US" },
  SD: { line1: "1 Demonstration Way", city: "Pierre", state: "SD", zip: "57501", country: "US" },
  TN: { line1: "1 Demonstration Way", city: "Nashville", state: "TN", zip: "37219", country: "US" },
  TX: { line1: "1 Demonstration Way", city: "Austin", state: "TX", zip: "78701", country: "US" },
  UT: { line1: "1 Demonstration Way", city: "Salt Lake City", state: "UT", zip: "84111", country: "US" },
  VT: { line1: "1 Demonstration Way", city: "Montpelier", state: "VT", zip: "05602", country: "US" },
  VA: { line1: "1 Demonstration Way", city: "Richmond", state: "VA", zip: "23219", country: "US" },
  FL: { line1: "1 Demonstration Way", city: "Tallahassee", state: "FL", zip: "32301", country: "US" },
  OR: { line1: "1 Demonstration Way", city: "Portland", state: "OR", zip: "97201", country: "US" },
  WA: { line1: "1 Demonstration Way", city: "Seattle", state: "WA", zip: "98101", country: "US" },
  WV: { line1: "1 Demonstration Way", city: "Charleston", state: "WV", zip: "25301", country: "US" },
  WI: { line1: "1 Demonstration Way", city: "Madison", state: "WI", zip: "53703", country: "US" },
  WY: { line1: "1 Demonstration Way", city: "Cheyenne", state: "WY", zip: "82001", country: "US" },
  CO: { line1: "1 Demonstration Way", city: "Denver", state: "CO", zip: "80202", country: "US" },
};

function cleanAddressText(raw: string): string {
  return raw.trim().replace(/\s+/g, " ").slice(0, 80);
}

function cleanPostal(raw: string, country: string): string {
  const compact = raw.trim().replace(/\s+/g, " ");
  if (country === "US") {
    const match = compact.match(/\d{5}(?:-\d{4})?/);
    return match ? match[0] : "";
  }
  return compact.replace(/[^A-Za-z0-9 -]/g, "").slice(0, 12);
}

function checkoutAddressSupplied(rawStateCode: string, rawZip: string): boolean {
  const code = rawStateCode.trim().toUpperCase();
  const base = GUEST_STATE_ADDRESSES[code];
  return base !== undefined && cleanPostal(rawZip, base.country) !== "";
}

/* Map a guest's entered billing address to the tax address. Trimming
   and uppercasing here means the two callers cannot normalize
   differently. Anything without a known state is the house default. */
export function guestAddressFor(
  rawStateCode: string,
  rawZip = "",
  rawCity = "",
  rawLine1 = "",
): TaxAddress {
  const code = rawStateCode.trim().toUpperCase();
  const base = GUEST_STATE_ADDRESSES[code];
  if (!base) return HOUSE_TAX_ADDRESS;
  return {
    line1: cleanAddressText(rawLine1) || base.line1,
    city: cleanAddressText(rawCity) || base.city,
    state: base.state,
    zip: cleanPostal(rawZip, base.country) || base.zip,
    country: base.country,
  };
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

   THE CHECKOUT ADDRESS FIELDS apply whenever State and ZIP are
   supplied. The precedence, in words:

     member found, checkout address  member id is kept for credit,
                                     checkout address is used for tax
     member found, no checkout addr  member's stored address, then
                                     the house default if missing
     no member (empty code or miss)  checkout address, house default
                                     for unknown State

   This lets member attribution and billing address be separate
   facts. The browser still cannot choose price or tax amount, only
   the destination that Stripe Tax prices server side. */
export async function resolveTaxAddress(
  client: DbClient,
  rawMemberCode: string,
  rawGuestState = "",
  rawGuestZip = "",
  rawGuestCity = "",
  rawGuestLine1 = "",
): Promise<{ memberId: number | null; address: TaxAddress }> {
  if (rawMemberCode === "") {
    return {
      memberId: null,
      address: guestAddressFor(rawGuestState, rawGuestZip, rawGuestCity, rawGuestLine1),
    };
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
  if (!m) {
    return {
      memberId: null,
      address: guestAddressFor(rawGuestState, rawGuestZip, rawGuestCity, rawGuestLine1),
    };
  }
  if (checkoutAddressSupplied(rawGuestState, rawGuestZip)) {
    return {
      memberId: m.id,
      address: guestAddressFor(rawGuestState, rawGuestZip, rawGuestCity, rawGuestLine1),
    };
  }
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
  requestedCurrency = "USD",
): Promise<TaxOutcome> {
  const calculationCurrency = normalizeTaxCurrency(requestedCurrency);
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) {
    return {
      tax_cents: flatFallbackCents,
      source: "flat_fallback",
      calculation_id: null,
      reason: "stripe_not_configured",
      jurisdiction: null,
      calculation_currency: calculationCurrency,
      calculation_tax_cents: displayMinorFromUsdCents(flatFallbackCents, calculationCurrency),
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
      calculation_currency: calculationCurrency,
      calculation_tax_cents: 0,
    };
  }

  /* One line item for the whole taxable amount. Every product here is
     the same category (software as a service), so splitting per item
     would produce identical treatment and only add rounding seams. */
  const form = new URLSearchParams();
  form.set("currency", calculationCurrency.toLowerCase());
  form.set("line_items[0][amount]", String(displayMinorFromUsdCents(taxableCents, calculationCurrency)));
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
        calculation_currency: calculationCurrency,
        calculation_tax_cents: displayMinorFromUsdCents(flatFallbackCents, calculationCurrency),
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
    const calculationTaxCents = calc.tax_amount_exclusive ?? 0;
    return {
      tax_cents: usdCentsFromDisplayMinor(calculationTaxCents, calculationCurrency),
      source: "stripe_tax",
      calculation_id: calc.id ?? null,
      reason: first?.taxability_reason ?? "no_breakdown",
      jurisdiction: j ? [j.state, j.country].filter(Boolean).join(", ") : null,
      calculation_currency: calculationCurrency,
      calculation_tax_cents: calculationTaxCents,
    };
  } catch {
    console.error("tax: Stripe Tax unreachable");
    return {
      tax_cents: flatFallbackCents,
      source: "flat_fallback",
      calculation_id: null,
      reason: "stripe_unreachable",
      jurisdiction: null,
      calculation_currency: calculationCurrency,
      calculation_tax_cents: displayMinorFromUsdCents(flatFallbackCents, calculationCurrency),
    };
  }
}
