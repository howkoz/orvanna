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
- Follow-up: the billing State field is now a dropdown with all 50 states plus District of Columbia, so guest state selection is explicit instead of free text.
- Follow-up: the account step no longer shows an Illinois tax estimate before login or guest State/ZIP entry. Tax is pending with a blank tax amount until either a member login supplies the stored address or a guest supplies State and ZIP.
- Follow-up: the billing address now stays blank after member sign-in too. The shopper must enter State and ZIP before tax quotes or payment opens. Source Edge Function logic now separates attribution from tax destination: a member code can credit the order while the entered checkout address drives tax after function deploy.
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

## 2026-08-16 Sticky Checkout Summary

Howard reported that the order total scrolls out of view by the time the shopper reaches the payment area.

What changed:
- The checkout order summary is sticky on desktop, with a 96px top offset and its own vertical scroll if the summary content is taller than the viewport.
- The checkout section overflow is visible so sticky positioning can work correctly.
- Mobile keeps the summary in normal document flow and still shows it before the form, so it does not take over the small screen.
- The stale tax-helper HTML comment was updated to match the current blank-address flow.

Verification:
- `node --check MLM-PILOT\www\js\payments.js` passed.
- Inline JavaScript syntax check for `MLM-PILOT\www\shop.html` passed.
- `py MLM-PILOT\deploy\build_dist.py` passed with bundle hash `0927252101bb6d0e`.

Follow-up:
- The 3DS passcode frame now gets explicit top-center placement when it is revealed, with a layer above the sticky checkout summary and below the page's bank-approval instruction bar. This keeps the OTP screen from opening underneath the sticky price area.
- The payment panel, live payment status, and card-form skeleton now rise above the sticky checkout summary while `payment-in-flight` is active. This covers the short finishing transition after OTP and before the thank-you page.

## 2026-08-16 HyperSwitch Multi-Processor Routing Check

Howard re-enabled the Stripe, Braintree, and Authorize.net sandbox connectors and asked whether Orvanna can route traffic around instead of disabling extra processors.

What was verified:
- The Orvanna HyperSwitch profile is `pro_BA39ULYq4Vj0salGS0YA`.
- Payment processor connector state from the HyperSwitch sandbox API:
  - `braintree_default`, `mca_eE4v07QwkYUSyF55vrUC`, active and enabled.
  - `authorizedotnet_default`, `mca_3FSgAbQMH1lTeJYxKUqI`, active and enabled.
  - `stripe_default`, `mca_l0vwOt0SoWLPXRYjDwTF`, active and enabled.
- Active routing config is `routing_loBp0KbnCzD0IADxwWbY`, named `Volume Based Routing-2026-08-16`.
- Active routing is a 50/50 volume split between Braintree and Authorize.net. Stripe is enabled but not in the active split.

Probe results:
- Targeted Braintree sandbox authorization with `connector=["braintree"]` succeeded.
- Targeted Authorize.net sandbox authorization with `connector=["authorizedotnet"]` succeeded.
- Targeted Stripe sandbox authorization with `connector=["stripe"]` failed with Stripe's raw-card-data restriction. This is the same issue discovered earlier: Orvanna's HyperSwitch SDK flow uses raw card data through HyperSwitch, and this Stripe test account still needs Stripe raw-card API access or a tokenized Stripe-specific path before it should receive storefront traffic.
- Eight untargeted sandbox authorizations, with no connector specified, all succeeded through active routing:
  - 5 routed to Braintree.
  - 3 routed to Authorize.net.

Operational decision:
- Leave customer-facing active routing on Braintree plus Authorize.net.
- Do not add Stripe to active routing until its raw-card path is fixed, because it is enabled but still fails the actual Orvanna-style card flow.
- Orvanna's `create-payment` code already leaves connector selection to HyperSwitch, so no frontend deploy is required for the current Braintree/Authorize.net routing split.

## 2026-08-16 Plaid and Multi-Currency Staging

Howard asked to integrate Plaid to the site, then noted that GBP/EUR multi-currency is the natural next step.

What changed:
- The shop now has a currency selector for USD, GBP, and EUR in the sticky order summary.
- Catalog, cart, checkout summary, and confirmation display amounts through the selected display currency.
- The checkout now shows a selectable Bank account payment method for the Plaid/Open Banking sandbox path.
- Apple Pay, Google Pay, and PayPal remain disabled demonstration marks in live mode.
- Bank account checkout is intentionally staged: selecting it shows an honest message instead of creating a HyperSwitch payment.
- Non-USD card settlement is also guarded, because `app.demo_orders` stores cents but not currency yet.
- `create-payment` now rejects non-card or non-USD attempts before pricing and before inserting an order row, so crafted requests cannot create misleading orders.

Why:
- HyperSwitch's Plaid Open Banking PIS support is currently GBP/EUR, while Orvanna's order records and live card flow are USD.
- The next real maturity step is a schema migration for order currency, receipt/refund currency propagation, tax currency handling, and then a true Plaid/Open Banking payment create path.
- Howard installed Avalara AvaTax inside Stripe sandbox. Good direction for EU/GB maturity, but the current custom checkout calls Stripe Tax directly from the Edge Function. The next tax decision is whether Stripe's third-party tax app path can power that calculation transparently after setup, or whether Orvanna should call AvaTax directly with Avalara credentials.

Verification:
- `node --check MLM-PILOT/www/js/payments.js` passed.
- Inline JavaScript syntax check for `MLM-PILOT/www/shop.html` passed.
- `py MLM-PILOT/deploy/build_dist.py` passed with bundle hash `ca321ad1f09ffde6`.
- Browser check against `http://127.0.0.1:4177/shop.html` confirmed GBP display, Bank account selectable, and staged Plaid messaging with no payment create.

Follow-up correction:
- USD now disables the Plaid/Bank account button instead of allowing a click that only explains failure afterward.
- The payment method row now uses wordmark-style payment marks for Apple Pay, GPay, PayPal, Card, and Plaid instead of generic line icons.
- Browser check confirmed USD disables Plaid with the ACH/bank-debit explanation, while GBP keeps Plaid selectable and still shows the staged settlement message without creating a payment.

Follow-up wallet enablement:
- HyperSwitch sandbox API confirmed the Braintree connector now exposes wallet methods for `google_pay` and `paypal`.
- The checkout enables Google Pay and PayPal as USD sandbox options and opens the secure HyperSwitch widget for them.
- The HyperSwitch payment widget now includes `walletReturnUrl`, which wallet redirects need in order to return to Orvanna cleanly.
- Apple Pay remains disabled in the Orvanna UI until the Braintree Apple Pay domain setup is complete.
- Plaid/Open Banking remains staged behind GBP/EUR readiness and is still disabled for USD.

Follow-up Stripe Tax currency staging:
- Howard confirmed the intended European currency code is `EUR`, not `EU`.
- CHF was added to the shopper currency selector beside USD, GBP, and EUR.
- `quote-tax` now reads the selected currency and asks Stripe Tax in USD, GBP, EUR, or CHF.
- The tax answer is converted back into Orvanna's existing USD-base cents contract before the browser paints totals, because the order table still does not store settlement currency.
- `create-payment` remains explicitly USD for now, so payment settlement cannot silently mix a non-USD tax quote with USD order records.
- Non-USD currency choices seed demo tax addresses: GBP uses GB/London, EUR uses IE/Dublin, and CHF uses CH/Zurich.
- Until the Supabase `quote-tax` function can be deployed, the browser blocks live server tax quotes for non-USD currencies so the old deployed function cannot fall back to IL and overwrite the IE/GB/CH estimate.
- The Plaid tile is still staged, but selecting it now updates the visible wallet note and status line immediately instead of appearing inert.

Follow-up Plaid panel:
- The Plaid tile now opens a page-owned sandbox panel modeled after the OTP overlay pattern, so selecting Plaid no longer looks like it only changed button text.
- The panel shows the visible checkout total, the current two-letter country code, a few sandbox bank choices, and a final "nothing charged" authorization preview.
- This is intentionally not Plaid Link yet. The real backend still needs order currency storage and a HyperSwitch Open Banking create-payment path before Plaid can create an actual payment.
- Browser smoke check confirmed GBP checkout opens the panel above the sticky order summary, shows country `GB`, matches the sticky total, and updates the authorization preview message.

Follow-up Plaid shopper simulation:
- Howard correctly called out that the first Plaid panel still did not feel like a user experience.
- The panel now simulates the shopper flow: choose sandbox bank, enter sandbox credentials, consent, choose an account, see a processing handoff, then land on the normal order confirmation page.
- The final Plaid authorization button includes the visible checkout amount, for example `Authorize EUR 289.80`.
- The IE/GB billing row was cleaned up at the same time: `ZIP / postal code` became `Postal code`, and the three-column row now reserves enough width for non-US address labels.

Follow-up wallet demo guard:
- Google Pay and PayPal are intentionally routed to storefront demo completion for now.
- Selecting either wallet no longer opens HyperSwitch, Google Pay, or PayPal, so it cannot validate the shopper's real wallet cards.
- On USD checkout, the button reads `Place demo order with Google Pay` or `Place demo order with PayPal` and lands on the normal order confirmation page with the matching sandbox payment method.
