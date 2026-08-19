/* ============================================================
   ORVANNA PRICING MIRROR (server side)

   LOCKSTEP CONTRACT: this module MUST stay fact for fact
   identical to www/js/catalog.js, which is the single source
   of truth for the SITE. The verifier gate (Phase 6 spec,
   section 6.1, check V6) mechanically diffs all sixteen
   (sku, mode, price, pv) quadruples plus the activation fee
   and the tax rate between catalog.js and this file. Any
   drift fails the gate. If a price changes in catalog.js it
   changes here in the same commit, and vice versa.

   Contract document: MLM-PILOT/docs/PHASE-6-SPEC.md
   (section 1.3, canonical price source).

   House pricing rules mirrored here:
   - Subscription ("sub") is the default mode on every item
     that can carry one.
   - ONLY THE TWELVE AGENTS SUBSCRIBE (ruled 2026-08-19). The
     Manager bundle and the three packs are one-time purchases.
     A "sub" line naming one of them is REFUSED here rather
     than quietly repriced, because a silent reprice would
     charge a shopper a figure no page ever showed them. The
     site cannot construct such a line; this is the check for
     everything that is not the site.
   - One-time ("one") uses the 10x rule: monthly price times
     ten, Personal Volume (PV) equal to dollars in both modes.
   - Priority activation costs $25.00; standard is free.
   - Tax is 5 percent of (one-time subtotal + first-month
     subscription subtotal + activation fee), zero when the
     shopper is tax exempt.

   Money math here is INTEGER CENTS end to end, the same minor
   unit the HyperSwitch Application Programming Interface (API)
   uses, so amount checks are integer comparisons.
   ============================================================ */

export type Tier = "domain" | "support" | "bundle" | "pack";
export type Mode = "sub" | "one";

export interface ModePrice {
  price: number; // dollars, matches catalog.js exactly
  pv: number;    // Personal Volume, matches catalog.js exactly
}

export interface PriceEntry {
  tier: Tier;
  sub: ModePrice;
  once: ModePrice;
}

/* The sixteen items. Values copied verbatim from the PRODUCTS
   array in www/js/catalog.js (round 4, Phase 4C.2). */
export const CATALOG: Record<string, PriceEntry> = {
  /* ----- Domain agents: $100.00 / month, 100 PV ----- */
  payment:       { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },
  shipping:      { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },
  pricing:       { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },
  inventory:     { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },
  marketing:     { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },
  tax:           { tier: "domain",  sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 } },

  /* ----- Support agents: $50.00 / month, 50 PV ----- */
  engineer:      { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },
  qa:            { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },
  secretary:     { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },
  executive:     { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },
  accounting:    { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },
  care:          { tier: "support", sub: { price: 50,  pv: 50  }, once: { price: 500,  pv: 500  } },

  /* ----- Bundle ----- */
  manager:       { tier: "bundle",  sub: { price: 200, pv: 200 }, once: { price: 2000, pv: 2000 } },

  /* ----- Packs ----- */
  ignition:      { tier: "pack",    sub: { price: 200, pv: 200 }, once: { price: 2000, pv: 2000 } },
  momentum:      { tier: "pack",    sub: { price: 400, pv: 400 }, once: { price: 4000, pv: 4000 } },
  constellation: { tier: "pack",    sub: { price: 800, pv: 800 }, once: { price: 8000, pv: 8000 } },
};

/* Activation fee (priority only; standard activation is free)
   and tax rate. Mirrors the DELIVERY table and the 0.05 tax
   factor in www/shop.html. */
export const ACTIVATION_FEE_DOLLARS = 25; // $25.00 priority activation
export const TAX_RATE_PERCENT = 5;        // 5 percent

/* The four one-time-only SKUs. Named, not derived from tier, so this
   file and www/js/catalog.js state the rule the same way and the
   mirror check can compare them literally. */
export const ONE_TIME_ONLY: ReadonlySet<string> = new Set([
  "manager",
  "ignition",
  "momentum",
  "constellation",
]);

export function isSubscribable(sku: string): boolean {
  return sku in CATALOG && !ONE_TIME_ONLY.has(sku);
}

/* Cart caps, Phase 6 spec section 5.2 (server enforced). */
export const MAX_UNITS_PER_LINE = 99;
export const MAX_DISTINCT_LINES = 16;   // the whole catalog once
export const MAX_TOTAL_UNITS = 25;
export const MAX_TOTAL_CENTS = 2_500_000; // $25,000.00

export function toCents(dollars: number): number {
  return Math.round(dollars * 100);
}

export interface PricedLine {
  sku: string;
  mode: Mode;
  quantity: number;
  unit_price: number; // dollars, as stored in the items jsonb
  unit_pv: number;
}

export interface OrderComputation {
  items: PricedLine[];
  subtotal_one_cents: number;
  subtotal_sub_cents: number;
  activation_fee_cents: number;
  tax_cents: number;
  total_cents: number;
  pv_total: number;
}

export type PriceResult =
  | { ok: true; order: OrderComputation }
  | { ok: false; message: string };

/* Validate a raw cart from the client and recompute every money
   figure from THIS table only. Client-supplied prices, totals,
   or any extra fields are ignored by construction: only sku,
   mode, and quantity are ever read (spec section 1.5, tamper
   case). Returns ok:false with a plain-English message for any
   violation; the caller turns that into HTTP 400. */
export function priceCart(
  rawItems: unknown,
  activation: string,
  taxExempt: boolean,
): PriceResult {
  if (!Array.isArray(rawItems) || rawItems.length === 0) {
    return { ok: false, message: "The cart is empty or malformed." };
  }
  if (rawItems.length > MAX_DISTINCT_LINES) {
    return {
      ok: false,
      message: `The cart carries more than ${MAX_DISTINCT_LINES} distinct lines.`,
    };
  }
  if (activation !== "priority" && activation !== "standard") {
    return { ok: false, message: "Activation must be priority or standard." };
  }

  const seen = new Set<string>();
  const items: PricedLine[] = [];
  let subtotalOneCents = 0;
  let subtotalSubCents = 0;
  let pvTotal = 0;
  let totalUnits = 0;

  for (const raw of rawItems) {
    if (raw === null || typeof raw !== "object") {
      return { ok: false, message: "A cart line is malformed." };
    }
    const line = raw as Record<string, unknown>;
    const sku = line.sku;
    const mode = line.mode;
    const quantity = line.quantity;

    if (typeof sku !== "string" || !(sku in CATALOG)) {
      return { ok: false, message: "The cart names an item the shop does not sell." };
    }
    if (mode !== "sub" && mode !== "one") {
      return { ok: false, message: "Each line's mode must be sub or one." };
    }
    if (mode === "sub" && !isSubscribable(sku)) {
      return {
        ok: false,
        message: "That item is a one-time purchase and cannot be subscribed to.",
      };
    }
    if (
      typeof quantity !== "number" ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      quantity > MAX_UNITS_PER_LINE
    ) {
      return {
        ok: false,
        message: `Quantities must be whole numbers from 1 to ${MAX_UNITS_PER_LINE}.`,
      };
    }
    const lineKey = `${sku}|${mode}`;
    if (seen.has(lineKey)) {
      return { ok: false, message: "The cart repeats the same item and mode twice." };
    }
    seen.add(lineKey);

    const entry = CATALOG[sku];
    const modePrice = mode === "one" ? entry.once : entry.sub;
    const unitCents = toCents(modePrice.price);

    if (mode === "one") {
      subtotalOneCents += unitCents * quantity;
    } else {
      subtotalSubCents += unitCents * quantity;
    }
    pvTotal += modePrice.pv * quantity;
    totalUnits += quantity;

    items.push({
      sku,
      mode,
      quantity,
      unit_price: modePrice.price,
      unit_pv: modePrice.pv,
    });
  }

  if (totalUnits > MAX_TOTAL_UNITS) {
    return {
      ok: false,
      message: `The cart carries more than ${MAX_TOTAL_UNITS} total units.`,
    };
  }

  const activationFeeCents =
    activation === "priority" ? toCents(ACTIVATION_FEE_DOLLARS) : 0;
  const taxableCents = subtotalOneCents + subtotalSubCents + activationFeeCents;

  /* Tax in integer cents, rounded half up. Every catalog price is
     whole dollars, so (taxableCents * 5) is always divisible by
     100 and this matches the site's round2(taxable * 0.05) to the
     cent with no floating-point question. */
  const taxCents = taxExempt
    ? 0
    : Math.round((taxableCents * TAX_RATE_PERCENT) / 100);
  const totalCents = taxableCents + taxCents;

  if (totalCents > MAX_TOTAL_CENTS) {
    return {
      ok: false,
      message: "The order total is above the demo ceiling of $25,000.00.",
    };
  }

  return {
    ok: true,
    order: {
      items,
      subtotal_one_cents: subtotalOneCents,
      subtotal_sub_cents: subtotalSubCents,
      activation_fee_cents: activationFeeCents,
      tax_cents: taxCents,
      total_cents: totalCents,
      pv_total: pvTotal,
    },
  };
}
