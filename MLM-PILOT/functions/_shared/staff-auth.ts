/* ============================================================
   staff-auth.ts  PROPOSED, NOT DEPLOYED

   Server-side verification of the staff session token.

   WHY THIS FILE HAD TO BE WRITTEN BEFORE ANY REFUND COULD SHIP.

   www/staff.html carries this comment above its session gate:

     "KNOWN GAP, do not read this gate as security. The session
      token is NOT verified here or anywhere else. This code only
      reads what is already in session storage and trusts it, so a
      hand-written session object opens this page. The real gate is
      the role check the server performs on every function call."

   The first half of that is exactly right. The second half is not
   true yet. There is no server-side role check anywhere in this
   project: demo-login MINTS a token (functions/demo-login/index.ts,
   signToken) and no function has ever VERIFIED one. Every Edge
   Function to date is gated on origin and rate limit alone, which
   is correct for the functions that exist, because none of them
   does anything a visitor could not do from the shop anyway.

   A refund is the first action where that stops being true. It
   moves money out of the business, to a party outside it, and it
   cannot be undone from our side. Shipping it behind a gate that
   consists of a browser trusting its own session storage would mean
   anyone who can read the page source can return any order's money.
   So the missing half is built here, and refund-payment is its
   first caller.

   WHAT A TOKEN IS. demo-login produces:

       base64url(JSON.stringify(payload)) + "." + base64url(HMAC)

   where payload is { user, role, iat, exp } and HMAC is
   SHA-256 over the FIRST part, keyed with a 32-byte random value
   that lives only in app.demo_auth_config (migration 012). A
   browser cannot mint or edit a token without that key, so a token
   that verifies is evidence the server said yes.

   WHAT THIS FILE DELIBERATELY DOES NOT DO:

   - It does not make the static site private. The pages are on
     static hosting and stay publicly fetchable, and the seven
     public demonstration views stay readable with the publishable
     key by design. This closes the gap on ACTIONS, not on markup.
   - It does not implement revocation. A token is valid until it
     expires, eight hours after issue. There is no deny list. For a
     demonstration that is an accepted limit; it is written down
     here rather than discovered later.
   - It does not replace the origin check or the rate limit. It is a
     third rail alongside them, not instead of them.

   Secrets: the signing key is read from the database with the
   platform-injected connection, never from an environment variable
   the operator has to set, and never logged.
   ============================================================ */

import { timingSafeEqual, type DbClient } from "./edge.ts";

/* Roles that exist in app.demo_users (migration 012). 'admin' is
   treated as a superset of 'staff' for authorisation purposes: an
   admin can do anything a staff agent can. */
export type StaffRole = "staff" | "admin";

export interface StaffIdentity {
  user: string;
  role: StaffRole;
  /* Unix seconds, from the token. Carried through so a caller can
     log how much life a token had left when it was used. */
  expires_at: number;
}

export type StaffAuthResult =
  | { ok: true; identity: StaffIdentity }
  /* Every failure is one of these codes. They are deliberately
     coarse in what they reveal to the caller: the browser is told
     'not_authorised' for all of them (see refund-payment), while
     the specific code goes to the audit log, where it is useful. */
  | {
    ok: false;
    code:
      | "missing_token"
      | "malformed_token"
      | "bad_signature"
      | "expired"
      | "wrong_role"
      | "not_configured";
  };

function base64urlToBytes(value: string): Uint8Array | null {
  try {
    const padded = value.replace(/-/g, "+").replace(/_/g, "/");
    const binary = atob(padded + "=".repeat((4 - (padded.length % 4)) % 4));
    const out = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
    return out;
  } catch {
    return null;
  }
}

/* Pull the bearer token out of the Authorization header.

   NOTE ON THE HEADER, because it looks like a collision and is not.
   Supabase Edge Functions also use Authorization for the platform
   key. This function is intended to be deployed with JavaScript
   Object Signing and Encryption (JSON Web Token, JWT) verification
   DISABLED, exactly like payment-webhook, so the platform does not
   claim that header and the staff token can travel in it. If a
   future deployment turns platform verification back on, move the
   token to a dedicated header (x-orvanna-session) and change only
   this function. */
export function bearerFrom(req: Request): string | null {
  const header = req.headers.get("authorization") ??
    req.headers.get("x-orvanna-session");
  if (!header) return null;
  const trimmed = header.trim();
  const token = trimmed.toLowerCase().startsWith("bearer ")
    ? trimmed.slice(7).trim()
    : trimmed;
  /* A token is small. Anything large is not one, and is refused
     before any hashing work is done. */
  if (token === "" || token.length > 4096) return null;
  return token;
}

async function hmacSha256(key: string, message: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    encoder.encode(message),
  );
  return new Uint8Array(signature);
}

/* ------------------------------------------------------------
   Verify a token and require one of the given roles.

   Order of checks is deliberate and matches payment-webhook's:
   the SIGNATURE is checked before anything in the payload is
   believed, because an unsigned payload is just a string somebody
   typed. Only after it verifies do the expiry and the role mean
   anything at all.
   ------------------------------------------------------------ */
export async function requireStaff(
  client: DbClient,
  req: Request,
  allowedRoles: readonly StaffRole[] = ["staff", "admin"],
): Promise<StaffAuthResult> {
  const token = bearerFrom(req);
  if (token === null) return { ok: false, code: "missing_token" };

  const dot = token.indexOf(".");
  if (dot <= 0 || dot === token.length - 1) {
    return { ok: false, code: "malformed_token" };
  }
  const bodyPart = token.slice(0, dot);
  const signaturePart = token.slice(dot + 1);

  /* The signing key lives in the database, not in an environment
     variable, because migration 012 generates it there and nothing
     copies it out. */
  const keyRow = await client.queryObject<{ value: string }>(
    `select value from app.demo_auth_config where key = 'token_signing_key'`,
  );
  const signingKey = keyRow.rows[0]?.value;
  if (!signingKey) {
    console.error("staff-auth: token_signing_key is missing from app.demo_auth_config");
    return { ok: false, code: "not_configured" };
  }

  const expected = await hmacSha256(signingKey, bodyPart);
  const provided = base64urlToBytes(signaturePart);
  if (provided === null || !timingSafeEqual(expected, provided)) {
    /* Log the fact, never the token. */
    return { ok: false, code: "bad_signature" };
  }

  /* Signed by us. Now, and only now, read the payload. */
  const payloadBytes = base64urlToBytes(bodyPart);
  if (payloadBytes === null) return { ok: false, code: "malformed_token" };

  let payload: { user?: unknown; role?: unknown; exp?: unknown };
  try {
    payload = JSON.parse(new TextDecoder().decode(payloadBytes));
  } catch {
    return { ok: false, code: "malformed_token" };
  }

  const user = typeof payload.user === "string" ? payload.user : null;
  const role = payload.role === "staff" || payload.role === "admin"
    ? payload.role
    : null;
  const exp = Number(payload.exp);
  if (user === null || role === null || !Number.isFinite(exp)) {
    return { ok: false, code: "malformed_token" };
  }

  /* Expiry in seconds, matching how demo-login writes it. A token
     that has expired is refused even though its signature is
     perfect: that is the entire point of an expiry. */
  if (exp * 1000 <= Date.now()) return { ok: false, code: "expired" };

  if (!allowedRoles.includes(role)) return { ok: false, code: "wrong_role" };

  return { ok: true, identity: { user, role, expires_at: exp } };
}

/* ------------------------------------------------------------
   Write one line to the audit log (migration 022 section 4).

   NEVER THROWS. An audit write that fails must not turn a
   successful refund into a 500, and must not stop a refusal from
   being returned. A failure here is logged and swallowed, which is
   the correct trade for a demonstration: the alternative is that a
   full log table blocks refunds entirely.

   Nothing personal reaches this function: actor is a demonstration
   username, ipHash is already salted and hashed by callerIpHash,
   and detail is a small object built by our own code.
   ------------------------------------------------------------ */
export async function auditStaffAction(
  client: DbClient,
  entry: {
    actor: string;
    actor_role: string | null;
    action: string;
    target: string | null;
    outcome: "allowed" | "refused";
    outcome_code: string | null;
    ip_hash: string | null;
    detail?: Record<string, unknown>;
  },
): Promise<void> {
  try {
    await client.queryArray(
      `insert into app.demo_staff_actions
         (actor, actor_role, action, target, outcome, outcome_code, ip_hash, detail)
       values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)`,
      [
        entry.actor.slice(0, 100),
        entry.actor_role,
        entry.action,
        entry.target === null ? null : entry.target.slice(0, 100),
        entry.outcome,
        entry.outcome_code,
        entry.ip_hash,
        JSON.stringify(entry.detail ?? {}),
      ],
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`staff-auth: audit write failed: ${message}`);
  }
}
