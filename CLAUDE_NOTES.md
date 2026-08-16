# ORVANNA Project Notes

## 2026-08-16 Folder Audit

Reviewed the full ORVANNA workspace from `C:\Users\howar\Desktop\Desktop\ORVANNA`.

What was verified:
- Local build passed with `py MLM-PILOT\deploy\build_dist.py`.
  - Cache stamps applied.
  - Local CSS, JS and SVG stamp assertion passed.
  - Owner-name lint passed.
  - Secret-shaped string scan passed.
  - Build output: `MLM-PILOT\deploy\dist`, 34 files, bundle hash `1467ad0cf2f1e70f`.
- Subscription proof harness passed from a disposable Postgres container with `py MLM-PILOT\db\subscriptions\run_proofs.py`.
  - All 65 proofs passed.
  - Transcript written to `MLM-PILOT\db\subscriptions\proof_output\transcript-20260816-130630.txt`.
- Supabase connector showed eight active Edge Functions, matching the corrected architecture count.
- `payment-webhook` is the only Edge Function with platform JWT verification off, consistent with webhook design.
- The deployed `refund-payment` bundle contains the N-M1 staff-auth audit fix, so the older "repo ahead of cloud" note is no longer true for that function.

Concerns found:
- `MLM-PILOT\functions\refund-payment\index.ts` and `MLM-PILOT\functions\_shared\staff-auth.ts` contained stale comments saying the N-M1 audit fix was "NOT YET DEPLOYED", even though the deployed bundle contained the fix. Fixed in the follow-up cleanup.
- `MLM-PILOT\functions\refund-payment\index.ts` had contradictory deployment commentary: the header said `verify_jwt TRUE`, but a later block still said it must be deployed without platform JWT verification. Fixed in the follow-up cleanup.
- `MLM-PILOT\www\staff.html` had stale internal comments saying refund order history/detail were proposed or not deployed. Fixed in the follow-up cleanup.
- `MLM-PILOT\docs\verification\PICKER-VERDICT-2026-08-16.md` recorded open P-M1: a guest who picks a tax state and also types a referral code is priced from the referrer's stored address, not the picked state, until the quote answer repaints the truth. The follow-up cleanup softened the live copy so the picker does not overpromise while a referral code is present.
- `DOCUMENTATION\06-QA-AND-VERIFICATION.md` still records the office landing H2 contrast issue as open, plus M2, M3 and M4 as Howard-call items.
- `MLM-PILOT\docs\qa\S1-QA-2026-08-16.md` keeps Phase S1 open by design because the staff billing console is not built yet, even though the engine proofs pass.
- `MLM-PILOT\www\comp-plan.html` said the prototype runs on synthetic data. Since the bridge now includes real sandbox test purchases, that wording was only mostly true. Fixed in the follow-up cleanup.
- The working tree is ahead of `origin/main` by six commits and has uncommitted migration header notes plus untracked lab/proof artifacts.

Current working tree notes:
- Modified migration files:
  - `MLM-PILOT\db\migrations\024_subscription_engine_schema.sql`
  - `MLM-PILOT\db\migrations\025_subscription_policy_data.sql`
  - `MLM-PILOT\db\migrations\026_renewal_engine.sql`
  - `MLM-PILOT\db\migrations\027_bridge_covered_months_spread.sql`
- Those changes are header-only notes stating the migrations were applied to cloud and must not be edited in place again.
- New untracked proof transcript from this audit:
  - `MLM-PILOT\db\subscriptions\proof_output\transcript-20260816-130630.txt`

Follow-up cleanup applied:
- Stale comments in `refund-payment`, `staff-auth`, and `staff.html` were corrected.
- P-M1 referral-code precedence got a copy softener: when a referral code is present, the picker no longer overpromises that state alone controls tax.
- The comp-plan synthetic-data wording now mentions sandbox test purchases.
- Rebuild after cleanup passed with bundle hash `021a9f2b7c45efee`.

Remaining suggested cleanup:
1. Decide whether to commit or archive the current untracked proof and lab artifacts.

## 2026-08-16 Checkout Tax Address Fix

Howard reported that guest checkout defaulted tax to Illinois instead of using the State/ZIP fields in the billing form.

What changed:
- `MLM-PILOT\www\shop.html` no longer has a separate guest "Tax state" selector in the order summary.
- Guest checkout now normalizes the visible billing State field and sends it as `guest_state`.
  - Examples: `NY`, `New York`, and `new york` all normalize to `NY`.
- Guest checkout also sends `guest_zip`, `guest_city`, and `guest_line1` for the ZIP-aware server path.
- The address fields are now part of the payment amount signature, so editing State/ZIP forces a fresh quote and a fresh payment opening.
- `MLM-PILOT\functions\quote-tax\index.ts` and `MLM-PILOT\functions\create-payment\index.ts` now parse the guest address fields identically.
- `MLM-PILOT\functions\_shared\tax.ts` now has fallback synthetic addresses for every U.S. state and uses the typed ZIP when present.
- `MLM-PILOT\functions\confirm-payment\index.ts` returns stored tax provenance on receipts.
- `MLM-PILOT\www\js\payments.js` uses the receipt's own `tax_jurisdiction` before falling back to in-memory quote totals.

Verification:
- Inline JavaScript syntax check passed for `MLM-PILOT\www\shop.html`.
- `node --check MLM-PILOT\www\js\payments.js` passed.
- `py MLM-PILOT\deploy\build_dist.py` passed with bundle hash `326662642176d221`.
- Public static bundle was pushed to `howkoz/orvanna.io` at commit `d9193b8`.

Deploy note:
- Supabase CLI deploy for `quote-tax`, `create-payment`, and `confirm-payment` is still blocked locally by missing `SUPABASE_ACCESS_TOKEN`.
- The static deploy still fixes the visible Illinois-default issue for states the current live functions already support, because the browser now sends `guest_state` from the billing State field.
- Full ZIP-specific pricing needs the updated Edge Functions deployed.
