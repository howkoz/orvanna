/* ============================================================
   payment-webhook (Supabase Edge Function, Deno)

   Phase 6.1. Spec: MLM-PILOT/docs/PHASE-6-SPEC.md section 4
   (webhooks versus polling) and MLM-PILOT/docs/3DS-RESEARCH.md
   section A5 (a challenged payment can reach 'succeeded' while
   the shopper never comes back to us).

   THE PROBLEM THIS SOLVES, in one paragraph. A shopper is sent
   to their bank for a 3-D Secure (3DS) challenge, approves it on
   their phone, and then closes the tab, loses signal, or the
   return redirect fails. HyperSwitch completes the payment and
   marks it succeeded. Our row is still 'created' or 'processing'
   and eventually ages into 'abandoned'. On a test rail that is
   untidy; on a live rail that is money taken with no order
   recorded. This function is the second, browser-independent
   way for us to find out.

   THE TRUST MODEL IS UNCHANGED. The incoming body is treated as
   a WAKE-UP CALL and nothing more:

     1. Verify the signature first. A body that does not verify
        is answered 401 and the database is never touched.
     2. Even a perfectly signed body's status field is IGNORED.
        We read only an identifier out of it, and then run the
        same server-side GET /payments/{id}, the same
        cent-for-cent amount check, and the same guarded update
        that confirm-payment runs. That one implementation lives
        in _shared/edge.ts (retrieveAndApplyPaymentTruth).

   So the worst a forger with a valid signature could achieve is
   to make us re-ask HyperSwitch a question we already know how
   to answer. No status ever enters our database from a request
   body, from either the browser or the processor.

   SIGNATURE. HyperSwitch signs the raw body with a Hash-based
   Message Authentication Code (HMAC) using SHA-512 and the
   merchant's payment response hash key, and sends the digest in
   the x-webhook-signature-512 header. Our copy of that key is
   the vault secret HYPERSWITCH_HASH_KEY. Comparison is
   constant time.

   NO CROSS-ORIGIN RESOURCE SHARING (CORS), NO ORIGIN CHECK, NO
   RATE LIMIT, and why. This is machine traffic: HyperSwitch is
   not a browser, sends no Origin header, and gets no benefit
   from CORS headers, so none are emitted. An Internet Protocol
   (IP) address rate limit would be actively harmful here,
   because every legitimate call arrives from the same small set
   of processor addresses and would share one bucket: a burst of
   genuine events would be throttled, HyperSwitch would retry,
   and we would throttle the retries too. The signature check is
   the gate, and it is a better one than an address bucket. What
   we do bound is work: the body is size-capped before it is
   hashed, and every path answers quickly.

   DEPLOYMENT. This function must be deployed WITHOUT JavaScript
   Object Signing and Encryption (JSON Web Token, JWT)
   verification, because HyperSwitch cannot present our anonymous
   key. Its own signature check is what secures it. The exact
   flag is in the builder's report; setting it is the
   coordinator's call, not this file's.

   Secrets: only via Deno.env.get. Names per spec section 3.
   Nothing personal is read, stored, or logged.
   ============================================================ */

import {
  getPool,
  retrieveAndApplyPaymentTruth,
  timingSafeEqual,
} from "../_shared/edge.ts";

/* A HyperSwitch webhook body is small. Anything larger is not
   one, and we refuse to spend time hashing it. */
const MAX_BODY_BYTES = 64 * 1024;

const SIGNATURE_HEADER = "x-webhook-signature-512";

/* Plain JSON answer. No CORS headers on purpose (see the header
   comment): no browser is ever meant to call this. */
function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function hexToBytes(hex: string): Uint8Array | null {
  const clean = hex.trim().toLowerCase();
  if (clean.length === 0 || clean.length % 2 !== 0) return null;
  if (!/^[0-9a-f]+$/.test(clean)) return null;
  const out = new Uint8Array(clean.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(clean.substring(i * 2, i * 2 + 2), 16);
  }
  return out;
}

function base64ToBytes(value: string): Uint8Array | null {
  try {
    const binary = atob(value.trim());
    const out = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
    return out;
  } catch {
    return null;
  }
}

/* Compute HMAC-SHA512 over the exact bytes we received. The raw
   text matters: re-serializing the parsed object would change
   whitespace and key order and break every signature. */
async function hmacSha512(key: string, message: string): Promise<Uint8Array> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(key),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    new TextEncoder().encode(message),
  );
  return new Uint8Array(signature);
}

/* The header is documented as a digest of the body. HyperSwitch
   sends it hexadecimal; base64 is accepted as a fallback so a
   formatting difference between versions cannot silently reject
   every genuine event. Both comparisons are constant time, and
   an unparseable header simply fails. */
function signatureMatches(expected: Uint8Array, provided: string): boolean {
  const asHex = hexToBytes(provided);
  if (asHex !== null && timingSafeEqual(expected, asHex)) return true;
  const asBase64 = base64ToBytes(provided);
  if (asBase64 !== null && timingSafeEqual(expected, asBase64)) return true;
  return false;
}

/* Pull a payment identifier out of the body without trusting
   anything else in it. HyperSwitch nests the payment object
   differently across event shapes, so several known locations
   are checked. If none of them yields an identifier we also
   accept our own order number out of the metadata we set at
   create time, which is a value we minted ourselves. */
function identifiersFrom(
  body: unknown,
): { payment_id: string | null; order_number: string | null } {
  const empty = { payment_id: null, order_number: null };
  if (body === null || typeof body !== "object") return empty;

  const root = body as Record<string, unknown>;
  const content = root.content as Record<string, unknown> | undefined;
  const candidates: unknown[] = [
    root.object,
    root.data,
    content?.object,
    content?.data,
    content,
    root,
  ];

  let paymentId: string | null = null;
  let orderNumber: string | null = null;

  for (const candidate of candidates) {
    if (candidate === null || typeof candidate !== "object") continue;
    const obj = candidate as Record<string, unknown>;
    if (paymentId === null && typeof obj.payment_id === "string") {
      paymentId = obj.payment_id.slice(0, 128);
    }
    const metadata = obj.metadata as Record<string, unknown> | undefined;
    if (
      orderNumber === null && metadata !== undefined && metadata !== null &&
      typeof metadata.order_number === "string"
    ) {
      orderNumber = metadata.order_number.slice(0, 40);
    }
  }

  return { payment_id: paymentId, order_number: orderNumber };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return reply(405, { error: { code: "method_not_allowed" } });
  }

  const declaredLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return reply(413, { error: { code: "payload_too_large" } });
  }

  const rawBody = await req.text();
  if (rawBody.length > MAX_BODY_BYTES) {
    return reply(413, { error: { code: "payload_too_large" } });
  }

  /* ---- 1. signature, before anything else touches anything ---- */
  const hashKey = Deno.env.get("HYPERSWITCH_HASH_KEY");
  if (!hashKey) {
    console.error("payment-webhook: HYPERSWITCH_HASH_KEY is not set");
    return reply(500, { error: { code: "not_configured" } });
  }

  const provided = req.headers.get(SIGNATURE_HEADER) ?? "";
  if (provided === "") {
    return reply(401, { error: { code: "signature_missing" } });
  }

  const expected = await hmacSha512(hashKey, rawBody);
  if (!signatureMatches(expected, provided)) {
    /* No database connection was opened and none will be. Log
       the fact, never the header value or the body. */
    console.error("payment-webhook: signature did not verify; ignoring");
    return reply(401, { error: { code: "signature_invalid" } });
  }

  /* ---- 2. the body is now known to be from HyperSwitch, and
     is still not believed. Read identifiers only. ---- */
  let parsed: unknown;
  try {
    parsed = JSON.parse(rawBody);
  } catch {
    return reply(400, { error: { code: "bad_json" } });
  }
  const ids = identifiersFrom(parsed);
  if (ids.payment_id === null && ids.order_number === null) {
    /* Signed, but not about a payment we can locate. Answer 2xx
       so HyperSwitch stops retrying something we cannot use. */
    console.error("payment-webhook: verified event carried no payment identifier");
    return reply(200, { ok: true, action: "ignored_no_identifier" });
  }

  const client = await getPool().connect();
  try {
    const lookup = ids.payment_id !== null
      ? await client.queryObject<{
        order_number: string;
        total_cents: number;
        payment_reference: string | null;
        payment_status: string;
      }>(
        `select order_number, total_cents, payment_reference, payment_status
           from app.demo_orders
          where payment_reference = $1`,
        [ids.payment_id],
      )
      : await client.queryObject<{
        order_number: string;
        total_cents: number;
        payment_reference: string | null;
        payment_status: string;
      }>(
        `select order_number, total_cents, payment_reference, payment_status
           from app.demo_orders
          where order_number = $1`,
        [ids.order_number],
      );

    const row = lookup.rows[0];
    if (!row) {
      /* Not our payment, or a row that never got a reference.
         Nothing to do, and nothing worth retrying. */
      return reply(200, { ok: true, action: "ignored_unknown_payment" });
    }

    if (row.payment_status === "succeeded" || row.payment_status === "failed") {
      /* Terminal rows are immutable, at the database level as
         well as here. Answering 2xx stops the retries. */
      return reply(200, { ok: true, action: "already_terminal" });
    }

    if (!row.payment_reference) {
      /* We were told about a payment we have no reference for.
         We will not invent one from the body. */
      return reply(200, { ok: true, action: "ignored_no_reference" });
    }

    /* ---- 3. ask HyperSwitch ourselves and write the truth ----
       Same retrieve, same cent-for-cent amount check, same
       guarded update as confirm-payment. A row the sweep already
       aged into 'abandoned' is allowed to settle to a terminal
       state here, which is exactly the late-arriving-truth case
       the database's transition guard was written to permit. */
    const truth = await retrieveAndApplyPaymentTruth(
      client,
      {
        order_number: row.order_number,
        total_cents: row.total_cents,
        payment_reference: row.payment_reference,
      },
      { caller: "payment-webhook", allowResolveFromAbandoned: true },
    );

    if (truth.outcome !== "resolved") {
      /* We could not reach HyperSwitch. Ask to be told again:
         a 5xx is HyperSwitch's cue to retry this event. */
      return reply(503, { error: { code: truth.outcome } });
    }

    return reply(200, {
      ok: true,
      action: "resolved",
      order_number: row.order_number,
      payment_status: truth.new_status,
      reason: truth.reason,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`payment-webhook: unexpected error: ${message}`);
    return reply(500, { error: { code: "internal_error" } });
  } finally {
    client.release();
  }
});
