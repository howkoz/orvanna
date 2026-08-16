/* ============================================================
   staff-auth.ts  NOT DEPLOYED (see refund-payment/index.ts, the
   DEPLOY BLOCKER note, 2026-08-16)

   THE SINGLE PLACE "IS THIS A STAFF AGENT?" IS DECIDED.

   The same rule _shared/tax.ts follows for tax: one
   implementation, so two callers cannot drift into two different
   answers. Any future function that moves money or changes a money
   record calls requireStaff and nothing else. Do not write a
   second check anywhere.

   ------------------------------------------------------------
   WHY THIS FILE HAD TO BE WRITTEN BEFORE ANY REFUND COULD SHIP

   Howard, 2026-08-15: refunds "can only be available in the staff
   area". That is a security requirement, not a layout preference,
   and THREE of the obvious ways to satisfy it are not gates at
   all. Each is written out because each is a mistake that looks
   like a solution.

   1. HIDING THE BUTTON IS NOT A GATE. Putting the control only on
      staff.html stops nobody. This function is a public HTTPS
      endpoint, and anyone who reads the shipped JavaScript learns
      its name and its request shape. If which page renders a
      button were the only thing between a stranger and a refund,
      we would have shipped a way to move money out of the business
      from a browser console.

   2. THE ORIGIN ALLOW LIST IS NOT AUTHORISATION. isAllowedOrigin
      in edge.ts answers "did this come from our own site". EVERY
      page on our site passes it, the shop included. It is a
      cross-site protection and an identity check is a different
      thing. It must never be described as one.

   3. THE BROWSER'S SESSION OBJECT IS NOT EVIDENCE. This is open
      finding V-H3. staff.html and site/index.html read a session
      object out of session storage and trust it; a hand-written
      one opens the page. So the browser cannot be the source of
      truth about who is asking, and no comment in this codebase
      may assume it is.

   Therefore the decision is made HERE, server side, against the
   DATABASE, on every single call.

   ------------------------------------------------------------
   WHAT A TOKEN IS, AND WHAT IT IS NOT TRUSTED FOR

   demo-login (functions/demo-login/index.ts) produces:

       base64url(JSON.stringify(payload)) + "." + base64url(HMAC)

   where payload is { user, role, iat, exp } and HMAC is SHA-256
   over the FIRST part, keyed with a 32-byte random value that
   lives only in app.demo_auth_config (migration 012). A browser
   cannot mint or edit that without the key.

   SO THE TOKEN PROVES TWO THINGS: that the server issued it, and
   to which username. IT IS NOT TRUSTED FOR THE ROLE.

   The role is re-read from app.demo_users on every call, and the
   token's own role claim is discarded. That is deliberate and it
   buys three things a signed claim cannot:

     - REVOCATION THAT ACTUALLY WORKS. Delete the row, or change
       its role, and the next call fails. With a trusted claim, a
       token issued before the change keeps working for its full
       eight hours no matter what the database says.
     - ONE SOURCE OF TRUTH. app.demo_users.role is the answer,
       everywhere, always. A token is a cached copy, and cached
       copies of authorisation decisions go stale.
     - A SMALLER BLAST RADIUS IF THE SIGNING KEY EVER LEAKED. A
       forged token still has to name a username that exists AND
       carries the staff role in the database.

   ------------------------------------------------------------
   'admin' IS NOT A SUPER-USER HERE. READ THIS BEFORE CHANGING IT.

   The obvious assumption is that admin outranks staff. IN THIS
   PROJECT IT DOES NOT. Migration 012 says so in as many words:
   "Roles: admin opens the member portal, staff opens the call
   console." Orvanna_Admin is labelled "Member portal
   demonstration account". It is the MEMBER-facing login.

   demo-login already treats the two as DISTINCT rather than
   hierarchical: it refuses a sign-in whose role does not match the
   role the page asked for, and tells an admin outright that "the
   staff console needs the staff credentials".

   So the default here is ['staff'] and ONLY 'staff'. Letting
   'admin' through would hand the refund endpoint to the member
   portal demonstration account, which is precisely the Conductor
   that Howard's constraint excludes. If a genuine super-user role
   is ever wanted, add a NEW role; do not widen this default.

   ------------------------------------------------------------
   WHAT THIS FILE DELIBERATELY DOES NOT DO

   - It does not make the static site private. The pages are on
     static hosting and stay publicly fetchable, and the seven
     public demonstration views stay readable with the publishable
     key by design. This closes the gap on ACTIONS, not on markup.
   - It does not implement token revocation lists. A token stays
     valid for its eight hours. Revoking a PERSON works (change or
     delete their app.demo_users row); revoking a single leaked
     TOKEN while keeping the account does not. Written down rather
     than discovered later.
   - It does not replace the origin check or the rate limit. It is
     a third rail alongside them, not instead of them.

   Secrets: the signing key is read from the database with the
   platform-injected connection, never from an environment variable
   and never logged. No token, no password hash and no key value is
   ever logged, returned, or placed in a URL.
   ============================================================ */

import { timingSafeEqual, type DbClient } from "./edge.ts";

/* THE THREE ROLES app.demo_users PERMITS, verified against the live
   database on 2026-08-15:

     admin   1 account     Orvanna_Admin, the MEMBER PORTAL login
     staff   1 account     Orvanna_Staff, the call console login
     member  1000 accounts GW-000001 and up, the Conductor logins

   Migration 012 created the table with only admin and staff;
   migration 014 widened it and added the thousand member sign-in
   accounts. So the live constraint is
   CHECK (role = ANY (ARRAY['admin','staff','member'])).

   READ THOSE NUMBERS AGAIN. There are 1,002 accounts that can sign
   in, and exactly ONE of them may refund. 'member' is not merely a
   different role, it is a thousand Conductors, which is precisely
   the population Howard's constraint excludes. A gate written as
   "not a member" or "any signed-in user" would hand the refund
   endpoint to all of them.

   Anything not in this union is refused as wrong_role, so a role
   added in some future migration is denied by DEFAULT rather than
   silently admitted. That is the safe direction and it is why this
   is a closed union and not a string. */
export type DemoRole = "staff" | "admin" | "member";

export interface StaffIdentity {
  /* The username as the DATABASE spells it, not as the token spelled
     it. Sign-in is case-insensitive, so this is the canonical form
     and is what gets written to the audit log. */
  user: string;
  /* The role as read from app.demo_users on THIS call. Never the
     token's claim. */
  role: DemoRole;
  /* Unix seconds from the token, carried so a caller can record how
     much life a token had left when it was used. */
  expires_at: number;
}

export type StaffAuthResult =
  | { ok: true; identity: StaffIdentity }
  /* Every failure is one of these codes. They are deliberately not
     shown to the caller: the browser is told one thing for all of
     them, and the specific code goes to the audit log where it
     helps an operator and not a prober. */
  | {
    ok: false;
    code:
      | "missing_token"
      | "malformed_token"
      | "bad_signature"
      | "expired"
      | "unknown_user"
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

/* Pull the staff token out of the request.

   x-orvanna-session IS CHECKED FIRST, AND THAT ORDER MATTERS.
   Supabase Edge Functions use Authorization for the PLATFORM key.
   A function deployed with platform JavaScript Object Signing and
   Encryption (JSON Web Token, JWT) verification left ON must
   receive the anonymous key in Authorization, which leaves no room
   for ours. list-demo-orders is exactly that case: it keeps the
   anonymous key in Authorization and carries the staff token in
   x-orvanna-session.

   If Authorization were checked first, that function would pick up
   the anonymous key, try to verify it as one of our tokens, and
   fail with bad_signature without ever looking at the header the
   staff token actually arrived in. A caller would be told it was
   not authorised while holding a perfectly good session. Checking
   our own header first removes that trap entirely.

   Authorization is still accepted, for functions deployed with
   platform verification OFF (refund-payment, like payment-webhook),
   where the header is free for us to use. */
export function bearerFrom(req: Request): string | null {
  const header = req.headers.get("x-orvanna-session") ??
    req.headers.get("authorization");
  if (!header) return null;
  const trimmed = header.trim();
  const token = trimmed.toLowerCase().startsWith("bearer ")
    ? trimmed.slice(7).trim()
    : trimmed;
  /* A token is small. Anything large is not one, and is refused
     before any hashing or database work is done. */
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
   Verify a caller and require one of the given DATABASE roles.

   The order of the five checks is deliberate, and each one is
   cheaper than the next:

     1. Is there a token at all?           no input, no work
     2. Does it verify against our key?    nothing in the payload is
                                           believed before this
     3. Has it expired?                    a perfect signature on an
                                           old token is still a no
     4. Does that user still exist?        database, live
     5. Is their CURRENT role allowed?     database, live

   Steps 4 and 5 are why this is an authorisation check rather than
   a signature check wearing its clothes.
   ------------------------------------------------------------ */
export async function requireStaff(
  client: DbClient,
  req: Request,
  /* Defaults to staff ONLY. See the 'admin is not a super-user'
     block in the header before widening this. */
  allowedRoles: readonly DemoRole[] = ["staff"],
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
     ever copies it out. */
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
    /* Log the fact, never the token and never the key. */
    return { ok: false, code: "bad_signature" };
  }

  /* Signed by us. Now, and only now, is the payload worth reading,
     and even now only for the username and the expiry. */
  const payloadBytes = base64urlToBytes(bodyPart);
  if (payloadBytes === null) return { ok: false, code: "malformed_token" };

  let payload: { user?: unknown; exp?: unknown };
  try {
    payload = JSON.parse(new TextDecoder().decode(payloadBytes));
  } catch {
    return { ok: false, code: "malformed_token" };
  }

  const claimedUser = typeof payload.user === "string"
    ? payload.user.trim()
    : "";
  const exp = Number(payload.exp);
  if (claimedUser === "" || claimedUser.length > 100 || !Number.isFinite(exp)) {
    return { ok: false, code: "malformed_token" };
  }

  /* Expiry in seconds, matching how demo-login writes it. A token
     that has expired is refused even though its signature is
     perfect: that is the entire point of an expiry. */
  if (exp * 1000 <= Date.now()) return { ok: false, code: "expired" };

  /* ---- THE AUTHORISATION ITSELF ----
     The role comes from HERE, live, and the token's own role claim
     is never read. Case-insensitive to match the
     demo_users_username_lower_key index and demo-login's own
     lookup. */
  const userRow = await client.queryObject<{ username: string; role: string }>(
    `select username, role from app.demo_users where lower(username) = lower($1)`,
    [claimedUser],
  );
  const row = userRow.rows[0];
  if (!row) {
    /* Correctly signed, but names an account that no longer exists.
       Deleting the row is how a person is revoked, and this is that
       working. */
    return { ok: false, code: "unknown_user" };
  }

  /* An unrecognised role is refused rather than trusted. A role
     added by a future migration is therefore denied by default,
     which is the safe direction: the alternative is a new role
     silently inheriting whatever this gate protects. */
  const role: DemoRole | null =
    row.role === "staff" || row.role === "admin" || row.role === "member"
      ? row.role
      : null;
  if (role === null || !allowedRoles.includes(role)) {
    return { ok: false, code: "wrong_role" };
  }

  return {
    ok: true,
    /* The DATABASE spelling of the username, so the audit trail is
       canonical rather than however the caller happened to type it
       at sign-in. */
    identity: { user: row.username, role, expires_at: exp },
  };
}

/* ------------------------------------------------------------
   Write one line to the audit log (migration 022 section 4).

   NEVER THROWS. An audit write that fails must not turn a
   successful refund into a 500, and must not stop a refusal from
   being returned. A failure here is logged and swallowed, which is
   the correct trade: the alternative is that a full log table
   blocks refunds entirely.

   THE ACTOR MUST COME FROM requireStaff, NEVER FROM THE REQUEST
   BODY. There is no code path in refund-payment that puts a
   browser-supplied name in this field, and there must not be one.
   An audit trail that records what the caller claimed about itself
   is not an audit trail.

   Nothing personal reaches this function: the actor is a
   demonstration username, ip_hash is already salted and hashed by
   callerIpHash, and detail is a small object built by our own code.
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
