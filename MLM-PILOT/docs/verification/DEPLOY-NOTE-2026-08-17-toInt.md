# Deploy note: billing-console and commission-report, toInt strictness

Date: 2026-08-17
Deployed by: mlm-db-engineer (deploy-engineer role)
Supabase project id: `oiyibdczkokegaxkwulv`
Repository commit deployed: `5928ff4`
Previous deployed commit: `63bc130`

Acronym key: JSON Web Token (JWT); line feed (LF); carriage return line feed (CRLF);
command line interface (CLI); Secure Hash Algorithm 256-bit (SHA-256).

## Why this deploy existed

Commit `a334250` changed the `toInt` helper in both function entrypoints:

    - return Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
    + return Number.isInteger(n) && n >= 0 ? n : fallback;

It was never deployed, so the cloud kept flooring while the repository did not.
This deploy closes that divergence. It was the only difference between `63bc130`
and `5928ff4` across all five files involved, confirmed by diffing the live cloud
bundles against the repository blobs before deploying.

## File set uploaded

Confirmed by reading the import statements, not by assumption.

| Function | Files uploaded |
|---|---|
| `billing-console` | `functions/billing-console/index.ts`, `functions/_shared/edge.ts`, `functions/_shared/pricing.ts`, `functions/_shared/staff-auth.ts` |
| `commission-report` | `functions/commission-report/index.ts`, `functions/_shared/edge.ts`, `functions/_shared/staff-auth.ts` |

`staff-auth.ts` imports `./edge.ts`, which is already in both sets. `pricing.ts` has
no relative imports. No import map was passed; neither function had one.

## Authentication posture preserved

`verify_jwt` was `true` on both functions before the deploy and was passed as `true`
on the deploy call. Both report `true` afterwards. No auth posture changed.

## Byte comparison against `5928ff4`

Compared under LF normalisation. This matters: the repository has `core.autocrlf=true`,
and `_shared/staff-auth.ts` is checked out with CRLF (18,445 bytes on disk versus
18,022 in the blob, 423 CRLF pairs). The other four files happen to be checked out
with LF. Supabase stores and returns all function files with LF. To remove that as a
variable, the upload source was a set of LF-normalised copies extracted directly from
the git blobs at `5928ff4`, and every comparison below converts CRLF to LF on both
sides before hashing.

Every uploaded file was re-fetched from the cloud after deploying and compared.

### billing-console, version 2

| File | Result | SHA-256 (first 16) |
|---|---|---|
| `functions/billing-console/index.ts` | IDENTICAL | `b095b914b859b822` |
| `functions/_shared/edge.ts` | IDENTICAL | `832db86450095598` |
| `functions/_shared/pricing.ts` | IDENTICAL | `9235559dfd0322b6` |
| `functions/_shared/staff-auth.ts` | IDENTICAL | `2b7a45736ea52309` |

Bundle SHA-256: `b2a42fdcf5d847fd936627a184217eb68c2ddd27153b77df19dfc7931a056677`

### commission-report, version 3

| File | Result | SHA-256 (first 16) |
|---|---|---|
| `functions/commission-report/index.ts` | IDENTICAL | `a341b8e0d96d675d` |
| `functions/_shared/edge.ts` | IDENTICAL | `832db86450095598` |
| `functions/_shared/staff-auth.ts` | IDENTICAL | `2b7a45736ea52309` |

Bundle SHA-256: `bd3dfcb8fff56b54dd761ffce1e21e511744d55e860192c83381669dc616b4a7`

## The changed line, quoted from the deployed bundle

Read back out of the deployed `billing-console` version 2, not out of the repository:

    function toInt(value: unknown, fallback: number): number {
      const n = Number(value);
      return Number.isInteger(n) && n >= 0 ? n : fallback;
    }

`Math.floor` appears zero times anywhere in the deployed `billing-console/index.ts`.

`parseRunLimit` is unchanged in the deployed copy, which is what keeps the
number-to-run limit out of scope for this change:

    function parseRunLimit(value: unknown): number | null | "invalid" {
      if (value === undefined || value === null || value === "") return null;
      const n = Number(value);
      if (!Number.isFinite(n) || !Number.isInteger(n) || n < 1 || n > 100000) {
        return "invalid";
      }
      return n;
    }

## Post-deploy checks

No billing run was executed. The engine clock was not initialised, advanced or reset.
Only read-only paths were touched, and none of them reached a staff-authenticated
handler.

| Check | Result |
|---|---|
| POST with no `Authorization` header, both functions | 401, `UNAUTHORIZED_NO_AUTH_HEADER` |
| POST with anon JWT, wrong origin, both functions | 403, `origin_not_allowed` (proves `_shared/edge.ts` loaded and ran) |
| POST with anon JWT, origin `https://orvanna.io`, no staff session | 401, `not_authorised`, with each function's own distinct message (proves each entrypoint and `_shared/staff-auth.ts` loaded and ran) |
| CORS preflight from `https://orvanna.io` | 204, both functions |
| `https://orvanna.io/staff-operations.html` | 200, 87,267 bytes, pointing at the correct functions base |

Not covered: a signed-in staff click-through of the console. The deploy engineer does
not enter passwords to authenticate, so that step needs Howard. Everything short of the
staff session is confirmed working, including that both deployed bundles boot and
resolve their shared imports.

## Deploy count, recorded plainly

`commission-report` was deployed twice. A background deploy produced version 2 and a
second deploy produced version 3 before the first was known to have landed. Both
uploads carried the same content, and version 3, the live one, is byte-identical to
`5928ff4`. `billing-console` was deployed once, version 1 to version 2. No other
function in the project was touched.
