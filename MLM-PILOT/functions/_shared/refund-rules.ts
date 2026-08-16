/* ============================================================
   refund-rules.ts  NOT DEPLOYED (see refund-payment/index.ts, the
   DEPLOY BLOCKER note, 2026-08-16)

   EVERY RULE ABOUT WHETHER AN ORDER MAY BE REFUNDED, IN ONE
   PURE MODULE.

   Two reasons this is its own file rather than a block of ifs
   inside the Edge Function.

   1. THE FOUR RULES STAY TOGETHER. Not already refunded, not
      already in flight, paid, and inside the time window. They
      are one decision with one answer, and keeping them in one
      function is what stops a future caller picking up three of
      them and missing the fourth.

   2. IT IS TESTABLE WITHOUT A SERVER. This file imports nothing,
      touches no database, reads no environment, and performs no
      input or output. It is a function from facts to a verdict.
      That means every refusal can be executed and checked
      directly, which is exactly what the verification in
      DOCUMENTATION\11-REFUNDS.md does, and it is the only reason
      those refusals could be proven before anything is deployed.

   NOTHING HERE IS A SECURITY BOUNDARY BY ITSELF. This module
   decides "is this order refundable". It does NOT decide "is this
   caller allowed to refund", which is _shared/staff-auth.ts. And
   it does not enforce anything on its own: it is a rule only for
   as long as the SERVER is the thing calling it. The staff
   console deliberately does not call it at all.
   ============================================================ */

/* ------------------------------------------------------------
   THE TIME WINDOW. THE ONE NUMBER TO CHANGE.

   Howard set this to 24 hours on 2026-08-15. It is one named
   constant so the number is visible and changing it is one
   obvious line rather than an archaeology exercise.

   IT IS ENFORCED ON THE SERVER AND NOWHERE ELSE. Howard's own
   words on the screen side: "i can do that as a rule that i need
   to know so you do not have to program so much around that." So
   the staff console does NOT compute eligibility, does not grey
   anything out, and does not explain the rule. It shows a refund
   button, and if the server refuses it shows the refusal.

   That split is deliberate and it is the safer half that was
   kept. A screen that hides a button is a courtesy; it stops
   nobody. This check is what actually means a mistyped order
   number or a browser tab left open since yesterday cannot reach
   an old order, even though a person never would on purpose.

   WHAT THIS IS: a deliberate blast-radius limit for a
   demonstration rail. It is the answer to "if something goes
   wrong with this control, how much money can it reach", and the
   answer is "only what was taken in the last day". On a
   demonstration that is worth far more than flexibility.

   WHAT THIS IS NOT: a business refund policy. A real business
   sets this from its terms of sale, its card scheme obligations
   and its consumer-law position, and the number is usually
   measured in weeks or months, not hours. Those rules would also
   distinguish a customer's right to a refund from a staff
   member's authority to issue one, which this single number
   deliberately does not. The pilot is tighter ON PURPOSE, and a
   real deployment would replace this constant with a policy
   input, very probably a per-market one.

   The window is measured from app.demo_orders.created_at, the
   moment the order was placed, to the moment the refund is
   REQUESTED. It is deliberately not measured to the moment the
   refund settles: a refund requested at hour 23 that the
   processor settles at hour 25 must be allowed to finish, and
   basing the rule on request time is what makes that true.
   ------------------------------------------------------------ */
export const REFUND_WINDOW_HOURS = 24;

/* HyperSwitch documents a minimum refund amount of 100 in the
   lowest denomination, i.e. one dollar. Nothing in the catalogue
   is priced under a dollar, so this is a guard against a future
   surprise rather than a live case.
   Source: api-reference.hyperswitch.io/v1/refunds/refunds--create */
export const MIN_REFUND_CENTS = 100;

/* The four reason values HyperSwitch documents. Stripe-routed
   payments REQUIRE one of the first three, so 'other' is mapped
   to requested_by_customer before the call and kept verbatim in
   our own row. Keeping this set even though we run Braintree is
   what makes a later connector change a configuration change. */
export const REASON_CODES = [
  "duplicate",
  "fraudulent",
  "requested_by_customer",
  "other",
] as const;
export type ReasonCode = typeof REASON_CODES[number];

export function isReasonCode(value: unknown): value is ReasonCode {
  return typeof value === "string" &&
    (REASON_CODES as readonly string[]).includes(value);
}

export function processorReason(code: ReasonCode): string {
  return code === "other" ? "requested_by_customer" : code;
}

/* Order numbers are ORV-YYYY-MM-XXXXXX (create-payment,
   generateOrderNumber). Shape-checked before a value reaches a
   query. Every query is parameterised regardless; this is belt
   and suspenders and an early, clear refusal. */
export const ORDER_NUMBER_RE = /^ORV-\d{4}-\d{2}-[0-9A-Z]{6}$/;

export function isOrderNumber(value: unknown): boolean {
  return typeof value === "string" && ORDER_NUMBER_RE.test(value.trim().toUpperCase());
}

/* ------------------------------------------------------------
   HyperSwitch RefundStatus, verbatim from the API reference:
   succeeded, failed, pending, review. Anything else is treated as
   non-terminal and reported as 'pending', which is the safe
   direction: an unrecognised status can never be mistaken for a
   completed refund, and the next sync asks again.
   ------------------------------------------------------------ */
export type RefundStatus = "succeeded" | "failed" | "pending" | "review";

export function mapRefundStatus(
  raw: unknown,
): { status: RefundStatus; known: boolean } {
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
   "ask again later", and while a refund is in either the ORDER
   stays 'succeeded', because nothing has actually been returned. */
export function isTerminal(status: RefundStatus): boolean {
  return status === "succeeded" || status === "failed";
}

/* The live refund statuses that occupy an order's one-refund
   slot. Mirrors the partial unique index in migration 022. */
export const LIVE_REFUND_STATUSES = [
  "requested",
  "pending",
  "review",
  "succeeded",
] as const;

/* ------------------------------------------------------------
   The facts the verdict is computed from. Deliberately a plain
   shape rather than the database row type, so this module never
   acquires a dependency on the driver or the schema.
   ------------------------------------------------------------ */
export interface RefundOrderFacts {
  payment_status: string;
  payment_reference: string | null;
  total_cents: number;
  /* When the order was PLACED. Milliseconds since the epoch, so
     the caller does the Date handling once and this module stays
     free of timezone questions. */
  created_at_ms: number;
}

export interface ExistingRefundFacts {
  status: string;
}

export type RefusalCode =
  | "order_not_found"
  | "already_refunded"
  | "refund_in_flight"
  | "not_refundable"
  | "outside_refund_window"
  | "no_payment_reference"
  | "amount_too_small";

export interface Refusal {
  code: RefusalCode;
  /* The status the endpoint answers with. */
  http: number;
  /* Shown to the staff agent. Plain English, says what is true
     rather than what went wrong internally. */
  message: string;
}

export function hoursSince(createdAtMs: number, nowMs: number): number {
  return (nowMs - createdAtMs) / 3_600_000;
}

/* Say an age the way a person would, because this string ends up
   in front of a staff member who has just been told no.

   ONE DECIMAL JUST OVER THE BOUNDARY, ON PURPOSE. Flooring an age
   of 24.1 hours against a 24 hour limit produces "this one is 24
   hours old", which reads as a contradiction and makes a correct
   refusal look like a bug. Days are used past two days, where a
   decimal hour count stops being meaningful. */
export function describeAge(ageHours: number): string {
  if (ageHours < 48) {
    const rounded = Math.round(ageHours * 10) / 10;
    return `${rounded} hours`;
  }
  const days = Math.floor(ageHours / 24);
  return `${days} days`;
}

export function withinRefundWindow(
  createdAtMs: number,
  nowMs: number,
  windowHours: number = REFUND_WINDOW_HOURS,
): boolean {
  const age = hoursSince(createdAtMs, nowMs);
  /* An order with a created_at in the future is a clock problem,
     not a refundable order. Treated as outside the window rather
     than silently allowed, because a negative age would otherwise
     pass every comparison below. */
  if (age < 0) return false;
  return age <= windowHours;
}

/* ------------------------------------------------------------
   THE VERDICT. Returns null when the refund may proceed, or the
   single most useful reason it may not.

   THE ORDER OF THE CHECKS IS THE DESIGN, not an accident. Each
   one is placed where it produces the reason a human most needs:

     1. no order                 nothing else can be evaluated
     2. already refunded         BEFORE the status check, because a
                                 refunded order's payment_status is
                                 'refunded', so a status-first order
                                 would report the vague "not
                                 refundable" instead of the precise
                                 "already refunded"
     3. refund in flight         the caller syncs rather than starting
                                 a second one
     4. not succeeded            you cannot refund what was not paid
     5. outside the window       the blast-radius limit
     6. no processor reference   nothing to call the processor about
     7. below the minimum        the processor would refuse anyway

   Checks 4, 5 and 2/3 are the three Howard asked to be server
   enforced, and they live here TOGETHER so that no future caller
   can pick up two of them and miss the third.
   ------------------------------------------------------------ */
export function refundRefusal(input: {
  order: RefundOrderFacts | null;
  existingRefund: ExistingRefundFacts | null;
  nowMs: number;
  windowHours?: number;
}): Refusal | null {
  const windowHours = input.windowHours ?? REFUND_WINDOW_HOURS;
  const order = input.order;

  if (order === null) {
    return {
      code: "order_not_found",
      http: 404,
      message: "No such order.",
    };
  }

  const existing = input.existingRefund;
  if (existing !== null) {
    if (existing.status === "succeeded") {
      return {
        code: "already_refunded",
        http: 409,
        message: "This order has already been refunded in full.",
      };
    }
    if ((LIVE_REFUND_STATUSES as readonly string[]).includes(existing.status)) {
      return {
        code: "refund_in_flight",
        http: 409,
        message:
          "A refund on this order is already under way. Check again shortly.",
      };
    }
    /* A 'failed' refund does not block a genuine retry, and falls
       through deliberately. */
  }

  if (order.payment_status !== "succeeded") {
    return {
      code: "not_refundable",
      http: 409,
      message:
        `Only a paid order can be refunded. This one is ${order.payment_status}.`,
    };
  }

  if (!withinRefundWindow(order.created_at_ms, input.nowMs, windowHours)) {
    const age = hoursSince(order.created_at_ms, input.nowMs);
    return {
      code: "outside_refund_window",
      http: 409,
      message: age < 0
        ? "This order's placement time is in the future, so it cannot be refunded here."
        : `Refunds are limited to orders placed in the last ${windowHours} hours. This one is ${
          describeAge(age)
        } old, so it has to be handled another way.`,
    };
  }

  if (!order.payment_reference) {
    return {
      code: "no_payment_reference",
      http: 409,
      message:
        "This order has no processor reference, so it cannot be refunded automatically.",
    };
  }

  if (order.total_cents < MIN_REFUND_CENTS) {
    return {
      code: "amount_too_small",
      http: 422,
      message: "The processor will not refund an amount below one dollar.",
    };
  }

  return null;
}
