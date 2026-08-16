/* ============================================================
   refund-rules.test.ts

   Executes the REAL rule module, the same file refund-payment
   imports, and prints the verdict for every refusal case.

   WHY THIS EXISTS AND WHAT IT DOES NOT PROVE. Nothing in this
   feature is deployed, so the refusals cannot yet be exercised
   against a live endpoint. What CAN be exercised, today, without
   a server or a database, is the decision itself, because
   _shared/refund-rules.ts imports nothing and touches nothing.
   That is the reason the rules were put in a pure module.

   So this proves the RULES refuse. It does not prove the
   DEPLOYED FUNCTION refuses: that is verification step 3 in
   DOCUMENTATION\11-REFUNDS.md, which still has to be run against
   the real endpoint after deploy, and which additionally covers
   the authorisation refusals that live in staff-auth.ts.

   Run it with Node 22 or newer, which strips the types itself:

     node --experimental-strip-types functions/_shared/refund-rules.test.ts

   Exit code 0 means every case matched its expectation.
   ============================================================ */

import {
  REFUND_WINDOW_HOURS,
  refundRefusal,
  type RefusalCode,
} from "./refund-rules.ts";

const HOUR = 3_600_000;
/* A fixed "now" so the results are identical on every run and in
   every timezone. A test whose output moves with the clock is a
   test nobody trusts. */
const NOW = Date.parse("2026-08-15T20:00:00Z");

const paid = (ageHours: number, over: Record<string, unknown> = {}) => ({
  payment_status: "succeeded",
  payment_reference: "pay_mbabizu24mvu3mela5njyhpit4",
  total_cents: 15_000,
  created_at_ms: NOW - ageHours * HOUR,
  ...over,
});

interface Case {
  name: string;
  order: ReturnType<typeof paid> | null;
  existing: { status: string } | null;
  expect: RefusalCode | null;
}

const cases: Case[] = [
  /* ---- the one that must be allowed ---- */
  {
    name: "ALLOWED: paid, 2 hours old, inside the window",
    order: paid(2),
    existing: null,
    expect: null,
  },

  /* ---- the four rules Howard asked to be server enforced ---- */
  {
    name: "REFUSED: placed 30 hours ago, outside the 24 hour window",
    order: paid(30),
    existing: null,
    expect: "outside_refund_window",
  },
  {
    name: "REFUSED: placed 8 days ago, well outside the window",
    order: paid(24 * 8),
    existing: null,
    expect: "outside_refund_window",
  },
  {
    name: "REFUSED: payment never succeeded (processing)",
    order: paid(2, { payment_status: "processing" }),
    existing: null,
    expect: "not_refundable",
  },
  {
    name: "REFUSED: payment failed",
    order: paid(2, { payment_status: "failed" }),
    existing: null,
    expect: "not_refundable",
  },
  {
    name: "REFUSED: order was abandoned",
    order: paid(2, { payment_status: "abandoned" }),
    existing: null,
    expect: "not_refundable",
  },
  {
    name: "REFUSED: already refunded (refund row succeeded)",
    order: paid(2),
    existing: { status: "succeeded" },
    expect: "already_refunded",
  },
  {
    name: "REFUSED: already refunded (order status refunded, no row passed)",
    order: paid(2, { payment_status: "refunded" }),
    existing: null,
    expect: "not_refundable",
  },
  {
    name: "REFUSED: a refund is already in flight (pending)",
    order: paid(2),
    existing: { status: "pending" },
    expect: "refund_in_flight",
  },
  {
    name: "REFUSED: a refund is already in flight (requested)",
    order: paid(2),
    existing: { status: "requested" },
    expect: "refund_in_flight",
  },
  {
    name: "REFUSED: a refund is under review",
    order: paid(2),
    existing: { status: "review" },
    expect: "refund_in_flight",
  },

  /* ---- precedence: the reason reported must be the useful one ---- */
  {
    name: "PRECEDENCE: already refunded AND stale reports already_refunded",
    order: paid(200, { payment_status: "refunded" }),
    existing: { status: "succeeded" },
    expect: "already_refunded",
  },

  /* ---- a failed refund must NOT block a genuine retry ---- */
  {
    name: "ALLOWED: an earlier refund FAILED, so a retry is permitted",
    order: paid(2),
    existing: { status: "failed" },
    expect: null,
  },

  /* ---- the window boundary, exactly ---- */
  {
    name: `ALLOWED: exactly ${REFUND_WINDOW_HOURS} hours old (boundary, inclusive)`,
    order: paid(REFUND_WINDOW_HOURS),
    existing: null,
    expect: null,
  },
  {
    name: `REFUSED: ${REFUND_WINDOW_HOURS} hours and 6 minutes old`,
    order: paid(REFUND_WINDOW_HOURS + 0.1),
    existing: null,
    expect: "outside_refund_window",
  },
  {
    name: "REFUSED: created_at in the future (clock problem, not refundable)",
    order: paid(-3),
    existing: null,
    expect: "outside_refund_window",
  },

  /* ---- the rest ---- */
  {
    name: "REFUSED: no such order",
    order: null,
    existing: null,
    expect: "order_not_found",
  },
  {
    name: "REFUSED: no processor reference to refund against",
    order: paid(2, { payment_reference: null }),
    existing: null,
    expect: "no_payment_reference",
  },
  {
    name: "REFUSED: below the processor minimum of one dollar",
    order: paid(2, { total_cents: 99 }),
    existing: null,
    expect: "amount_too_small",
  },
];

console.log(`REFUND_WINDOW_HOURS = ${REFUND_WINDOW_HOURS}`);
console.log(`fixed now = ${new Date(NOW).toISOString()}\n`);

let failures = 0;
for (const c of cases) {
  const refusal = refundRefusal({
    order: c.order,
    existingRefund: c.existing,
    nowMs: NOW,
  });
  const got: RefusalCode | null = refusal === null ? null : refusal.code;
  const ok = got === c.expect;
  if (!ok) failures++;
  const verdict = refusal === null
    ? "ALLOWED"
    : `${refusal.http} ${refusal.code}`;
  console.log(`${ok ? "pass" : "FAIL"}  ${c.name}`);
  console.log(`        -> ${verdict}`);
  if (refusal !== null) console.log(`        -> "${refusal.message}"`);
  if (!ok) console.log(`        !! expected ${c.expect ?? "ALLOWED"}`);
}

console.log(
  `\n${cases.length - failures}/${cases.length} cases matched expectation.`,
);
if (failures > 0) {
  console.log("RESULT: FAILURES PRESENT");
  process.exitCode = 1;
} else {
  console.log("RESULT: all rule refusals behave as specified");
}
