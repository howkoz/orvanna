/* ============================================================
   demo-login (Supabase Edge Function, Deno)

   Phase 6 follow-up, Howard 2026-08-14: "get the sign to be
   validated from the database and not be hidden on the page."

   Before: login.html accepted anything and the staff console had
   no gate. Now: the browser sends an attempt, the SERVER checks
   it against bcrypt hashes in app.demo_users (migration 012),
   and the page never holds, compares, or receives a password.

   On success the function returns a session token: the payload
   plus a keyed hash (Hash-based Message Authentication Code,
   HMAC) computed with a signing key that lives only in
   app.demo_auth_config. A browser cannot mint or edit a token
   without that key, so a token is evidence the server said yes.

   Rate limited hard, because a sign-in endpoint is the one door
   worth guessing at: 8 attempts per minute and 40 per hour per
   salted Internet Protocol (IP) address hash, in the login
   bucket only, so a guessing storm cannot lock a shopper out of
   checkout.

   Honest scope, stated plainly and repeated in migration 012:
   this makes the CREDENTIAL CHECK real and server side. The
   site is static hosting, so page markup stays publicly
   fetchable and the seven public demonstration views stay
   readable with the public key by design. Making the gate
   absolute means routing portal and console data through an
   authenticated function, which is the tracked follow-up.
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

/* Eight hours: long enough to demonstrate without an interruption,
   short enough that a copied token stops working the same day. */
const SESSION_SECONDS = 8 * 60 * 60;

function base64url(bytes: Uint8Array): string {
  let binary = "";
  bytes.forEach((b) => (binary += String.fromCharCode(b)));
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function signToken(
  payload: Record<string, unknown>,
  signingKey: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const body = base64url(encoder.encode(JSON.stringify(payload)));
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(signingKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
  return `${body}.${base64url(new Uint8Array(signature))}`;
}

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
      "This demonstration only answers its own site.",
    );
  }

  /* Brute-force rail, in its own bucket. */
  const ipHash = await callerIpHash(req);
  const verdict = await checkRateLimit(ipHash, { perMinute: 8, perHour: 40 }, "login");
  if (!verdict.allowed) {
    return errorResponse(
      req,
      429,
      "rate_limited",
      "Too many sign-in attempts. Please wait a moment and try again.",
      { "Retry-After": String(verdict.retryAfterSeconds) },
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse(req, 400, "bad_json", "The request body is not valid JSON.");
  }

  const username = typeof body.username === "string" ? body.username.trim().slice(0, 80) : "";
  const password = typeof body.password === "string" ? body.password.slice(0, 200) : "";
  /* Optional: the page may say which role it needs, so a staff
     credential cannot quietly open the portal gate and the other
     way round. Absent means any role is acceptable. */
  const wantRole = body.role === "admin" || body.role === "staff" ? body.role : null;

  if (username === "" || password === "") {
    return errorResponse(
      req,
      400,
      "missing_credentials",
      "Enter both a username and a password.",
    );
  }

  const client = await getPool().connect();
  try {
    /* The comparison happens inside Postgres: the attempt is hashed
       with the stored salt and matched against the stored hash. The
       password is never logged and never leaves this call. */
    const found = await client.queryObject<{ username: string; role: string; label: string | null }>(
      `select username, role, label
         from app.demo_users
        where lower(username) = lower($1)
          and password_hash = extensions.crypt($2, password_hash)`,
      [username, password],
    );
    const row = found.rows[0];

    /* One message for every failure shape, so the response never
       reveals whether a username exists. */
    if (!row) {
      return errorResponse(
        req,
        401,
        "invalid_credentials",
        "That username and password do not match a demonstration account.",
      );
    }
    if (wantRole && row.role !== wantRole) {
      return errorResponse(
        req,
        403,
        "wrong_role",
        wantRole === "staff"
          ? "That account is not a staff account. The staff console needs the staff credentials."
          : "That account is not a member portal account.",
      );
    }

    const keyRow = await client.queryObject<{ value: string }>(
      `select value from app.demo_auth_config where key = 'token_signing_key'`,
    );
    const signingKey = keyRow.rows[0]?.value;
    if (!signingKey) {
      return errorResponse(
        req,
        500,
        "not_configured",
        "The sign-in service is not configured yet.",
      );
    }

    const issuedAt = Math.floor(Date.now() / 1000);
    const expiresAt = issuedAt + SESSION_SECONDS;
    const token = await signToken(
      { user: row.username, role: row.role, iat: issuedAt, exp: expiresAt },
      signingKey,
    );

    return jsonResponse(req, 200, {
      token,
      role: row.role,
      username: row.username,
      label: row.label,
      expires_at: expiresAt,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`demo-login: unexpected error: ${message}`);
    return errorResponse(
      req,
      500,
      "internal_error",
      "Something went wrong while checking that sign-in.",
    );
  } finally {
    client.release();
  }
});
