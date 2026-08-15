# Architecture and Documentation Audit

As of 2026-08-15. Author: mlm-architect. Status: REPORT ONLY. No file was edited
to produce this document, and nothing in it is a change; every item is a finding
or a recommendation for Howard to rule on.

Commissioned by Howard: "audit everything, make sure all is in order, I want
everything to be world class coding and clean and nothing sloppy."

Plain path:
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\decisions\ARCHITECTURE-AUDIT-2026-08-15.md`

Acronym key, expanded once here so the body reads cleanly. Application
Programming Interface (API). Software Development Kit (SDK). Personal Volume
(PV). Sales Volume (SV). Team Volume (TV). Commissionable Volume (CV).
Row-Level Security (RLS). JavaScript Object Notation (JSON). Hypertext Transfer
Protocol (HTTP). Cross-Origin Resource Sharing (CORS). Hash-based Message
Authentication Code (HMAC). Uniform Resource Locator (URL). 3-D Secure (3DS).
Access Control Server (ACS). Electronic Commerce Indicator (ECI). Quality
Assurance (QA). Mail Order or Telephone Order (MOTO). Strong Customer
Authentication (SCA). Structured Query Language (SQL). Line Feed (LF). Carriage
Return plus Line Feed (CRLF). Byte Order Mark (BOM).

---

## 0. The picture first

Where every decision is made today, and which of them are made twice.

```
                    THE BROWSER                     |            THE SERVER
                    (public, editable, untrusted)   |   (Edge Functions, Supabase, HyperSwitch)
 ===================================================|=========================================
                                                    |
  www/shop.html  ......... 2,626 lines              |  create-payment ....... 505 lines
  www/staff.html ......... 1,973 lines              |  confirm-payment ...... 272 lines
  www/js/catalog.js ...... 469 lines                |  payment-webhook ...... 318 lines
  site/index.html + app.js  1,481 lines             |  list-demo-orders ..... 123 lines
                                                    |  demo-login ........... 196 lines
                                                    |  _shared/edge.ts ...... 752 lines
                                                    |  _shared/pricing.ts ... 233 lines
                                                    |
  ---------------------------------------------------------------------------------------
  DECISION            | decided in the browser      | decided on the server   | VERDICT
  ---------------------------------------------------------------------------------------
  Item price and PV   | catalog.js PRODUCTS         | pricing.ts CATALOG      | TWICE, checked
  Activation fee $25  | shop.html DELIVERY          | ACTIVATION_FEE_DOLLARS  | TWICE, checked
  Tax rate 5 percent  | shop.html 0.05 literal      | TAX_RATE_PERCENT        | TWICE, checked
                      | staff.html 0.05 literal     |         "               | TWICE, UNCHECKED
  Tax EXEMPTION       | /\d/.test(taxId) -> boolean | ACCEPTS THE BOOLEAN     | ONCE, IN THE
                      |                             |                         | WRONG PLACE
  Order total charged | display only                | priceCart(), authority  | ONCE, correct
  Order number        | orderNumber() (dead code)   | generateOrderNumber()   | TWICE, one dead
  Payment outcome     | SDK verdict DISCARDED       | retrieveAndApply...     | ONCE, correct
  Who the member is   | role check at shop.html:990 | demo-login (bcrypt)     | TWICE
  Which order is his  | sends member_code string    | unauthenticated lookup  | ONCE, unproven
  Portal / console    | sessionStorage shape check  | token signed, NEVER     | ONCE, in the
  access              |                             | verified anywhere       | wrong place
  ---------------------------------------------------------------------------------------

  THE ONE PLACE THE DESIGN IS EXCELLENT:

     browser  --(order_number only)-->  confirm-payment  \
                                                          >-- retrieveAndApplyPaymentTruth()
     HyperSwitch --(signed webhook)-->  payment-webhook  /      ONE implementation
                                                                GET /payments/{id} with the
                                                                secret key, amount checked to
                                                                the cent, guarded UPDATE.
                                                                Neither caller can skip a step.
                                                                Neither caller can drift.
```

**One-line verdict.** The server half of this system is genuinely good: the
payment truth path is single-sourced, the price mirror is mechanically checked,
the anon posture is sealed and was live-probed. The browser half has accreted.
Two full copies of the payment engine now exist and have already drifted, one
money decision is made in the browser and obeyed by the server, identity is
decided in two places that do not bind to each other, and every document that
describes the system is between one and two days behind the code it describes.
None of it is unsafe today because no real money can move. All of it is the kind
of thing that becomes unsafe the moment that stops being true.

---

## 1. Spec versus reality: `docs/PHASE-6-SPEC.md`

The spec is dated 2026-08-14 and was written before any of the payment work
existed. It is still an excellent document, and most of it held. What follows is
every place it now describes something that is not true, with a recommendation
for each. The recommendation is almost always **amend the spec**, because the
code moved for good reasons that were ruled on by Howard. Three items are the
other way round.

### 1.1 Divergences where the SPEC should be amended

| # | Spec says | Reality on 2026-08-15 | Recommendation |
|---|---|---|---|
| S1 | Section 0.1 and 7.H2: "the built-in dummy/test connector, or a Stripe test-mode connector" | **Braintree sandbox** (`mca_eE4v07QwkYUSyF55vrUC`) is the only enabled processor. All four simulators are disabled; the Stripe connector is disabled because Stripe refuses raw card numbers without a support ticket. | Amend. Add the reason: HyperSwitch's `is_separate_authentication_supported()` hard-codes nine connectors and no dummy is on it. This is the most expensive fact the project learned and it belongs in the spec, not only in the roadmap. |
| S2 | Section 1.2 step 6: the create body carries `amount`, `currency`, `capture_method`, `confirm`, `description`, `metadata` | It also carries `authentication_type: "three_ds"`, `request_external_three_ds_authentication: false`, a hardcoded synthetic `billing` address, and a server-built `return_url`. | Amend section 1.2 step 6 with the full body. The synthetic billing address in particular is a product and privacy decision (Howard's ruling: fake everything, collect nothing) and currently exists only as a code comment. |
| S3 | Section 1.1 and 1.2 step 1: "New behavior begins at the Place order action" | The payment opens **automatically**, at three different moments, none of which is a Place order press: on entering the checkout view (`shop.html:1232`), when the account step completes (`shop.html:896`), and after a member signs in (`shop.html:1018`). | Amend. This is the single largest behavioural change since the spec and it is not described anywhere in it. Section 1 needs a new subsection on the payment lifecycle, including the amount signature. |
| S4 | Section 1.4: the one sanctioned external script is HyperLoader.js | There are now **two**: HyperLoader.js and the Botpress webchat pair (`cdn.botpress.cloud` plus `files.bpcontent.cloud`, which is two hosts, so arguably three scripts from two vendors). | Amend section 1.4 to name both, with the PCI DSS 4.0 requirement 6.4.3 and 11.6.1 reasoning that justified nav-triggered rather than floating. Right now the roadmap knows this and the spec does not. |
| S5 | Section 4: "no webhook endpoint ships in v1"; webhooks are v1.1 | `payment-webhook` is built, deployed, and signature-verified. | Amend. Move section 4's v1.1 plan into the present tense and record that it is deployed without JSON Web Token verification because HyperSwitch cannot present the anon key. |
| S6 | Section 5.4: a three-row status table mapping to `succeeded` / `failed` / `processing` | `mapHyperswitchStatus()` in `_shared/edge.ts` names all seventeen statuses and carries a fifteen-value `reason` vocabulary plus an `authentication` summary. | Amend. The 3DS research already wrote the replacement table (its section A3); it was implemented but never folded back into the spec. |
| S7 | Section 5.5: rows age into `abandoned` after an hour | `sweepAbandonedWithFinalRetrieve()` now does one last server-side retrieve before ageing any row out. | Amend. This is strictly better than the spec and the spec should say so. |
| S8 | Section 3: four vault secrets, and `HYPERSWITCH_HASH_KEY` is "used by the webhook handler (v1.1)" | Four secrets is still right, but the hash key is in use now, and `SUPABASE_DB_URL` (platform-injected) is the actual database path rather than the service role key the spec describes. | Amend section 3. `_shared/edge.ts` documents the direct-connection choice well; the spec still says "service role". |
| S9 | Section 6.2 Q1: the worked example cart totals $2,231.25 with priority activation | Braintree declines every amount between $2,000.00 and $3,000.00 by its own sandbox rule. The spec's own canonical QA cart **cannot pass** on the live rail. | Amend the worked example to a cart outside that band, and record the amount-triggered decline rule. This is a live trap for the next QA run. |
| S10 | Section 6.2 Q2: "the documented sandbox decline card" | The documented card no longer exists on this rail. The live decline is driven by amount, or by `4000 1111 1111 1115`. | Amend, and see finding D3 on `TEST-CARDS.html`. |
| S11 | Section 1.2 step 2: the checkout is "the existing four-step checkout ... account, billing address, activation, payment" and "the site sends only these fields" | The step machine is not four steps; it is a single binary gate (`setAccountStage`, `shop.html:886`) where account completion reveals steps two through four at once. The field list is right, plus `return_page`. | Amend the description to match. Minor, but the spec's step count is quoted in the QA sheets. |
| S12 | Section 2.4: `list-demo-orders` returns 25 sanitized orders | True, and it also runs the abandon sweep on one call in four. Not described. | Amend. |
| S13 | Open question 4: "confirm this stays out of Phase 6" (no recurring mandate) | Still true and still unanswered on the record. | Close the open question explicitly. |

### 1.2 Divergences where the CODE should come back to the spec

Three, and the first is the most important finding in this section.

**C1. Tax exemption is decided in the browser, and the server obeys.**
Spec section 1.2 step 2 says the site sends `tax_exempt: true or false` and that
"the server re-derives nothing from the Tax ID itself and the Tax ID value is NOT
transmitted." The code does exactly that (`shop.html:1142` computes
`/\d/.test(taxIdInput.value)`, `create-payment` accepts `body.tax_exempt === true`
at line 304 and hands it straight to `priceCart`). So the code matches the spec
precisely, and **the spec is wrong**.

The spec's own headline invariant, stated three times, is that the server
recomputes all money from its own table and client values are ignored by
construction (section 1.1, 1.3, 1.5 tamper case). The tamper case is written as
airtight: "a hostile client edits its JavaScript to claim a $1.00 total. It
cannot: the request carries no prices." That is true of prices. It is not true of
the total, because a caller can send `{"tax_exempt": true}` and legitimately
reduce a $2,000.00 order by $100.00. The server has no evidence to check it
against, by design.

On a test rail this costs nothing. As the pattern a platform demo is meant to
show, it is the one line in the design that a payment person would circle. The
honest fix is not to transmit the Tax ID (that would import personal data the
demo has correctly refused to collect); it is to stop treating a tax exemption as
something a shopper can assert. Recommendation: either **make the demo tax
unconditional** and delete the exemption control, or **have the server derive the
exemption from something it can verify** (for example, the exemption applies only
when a signed-in member's account carries an exempt flag). Howard's call; the
architect's recommendation is the first, because a tax engine is Phase 6.2's job
and a fake exemption toggle is not worth the hole.

**C2. The daily circuit breaker now counts rows the shopper never intended.**
Spec section 5.1 sets a 500-row-per-day ceiling to "cap any scripted abuse at a
known ceiling". That ceiling was designed when a row was created only by a Place
order press. Since the auto-open change, a row plus a HyperSwitch payment intent
is created when the shopper merely walks into the checkout, and a **new** row is
created every time the amount signature changes: switching to priority
activation, typing a Tax ID (debounced at 900 milliseconds, so a slow typist can
produce more than one), or signing in. The stale payment is discarded in the
browser only. There is **no cancel call to HyperSwitch and no update to the
orphaned row**; it sits at `created` until the sweep ages it to `abandoned`.

Proof is already in the roadmap: cart at $420.00 held `ORV-2026-08-1BX8GO`;
switching activation produced `ORV-2026-08-1BY49Y` at $446.25. Two rows, one
shopper, one cart, zero completed orders.

Recommendation: bring the code back toward the spec's intent by (a) counting only
non-abandoned rows against the daily ceiling, or (b) having `liveResetPayment`
call a small `cancel-payment` function that marks the orphan `cancelled` and asks
HyperSwitch to void the intent. (b) is the correct answer and is the same shape as
the existing functions. Either way the spec's section 5.1 needs to say which.

**C3. The staff console diverged from the shared design without a spec change.**
Spec section 1.2 anticipates the console sending `channel: 'staff_console'`, which
it does. But the console hardcodes `activation: 'standard'` and has no priority
control, so the activation fee can never appear on a phone order. That is a
sensible product decision and it is written in a code comment
(`staff.html:1126`). It is not in the spec, not in the roadmap, and not in any QA
sheet. Recommendation: put it in the spec, because it is a money rule.

### 1.3 What the spec got right and should be preserved verbatim

Worth recording, because an audit that only lists faults teaches the wrong
lesson.

- Section 2.1, the decision to give live demo orders their own table rather than
  writing stranger traffic into `app.orders`, is the single best architectural
  call in the project. It is why the six finalized commission months are provably
  untouched by everything Phase 6 did.
- Section 1.3, the mirrored pricing module with a mechanical parity gate, works.
  The checker (`functions/_shared/check_pricing_mirror.py`) was run during this
  audit and passes: 32 of 32 quadruples, activation fee and tax rate matched.
- Section 4's trust argument, and its eventual implementation as one shared
  `retrieveAndApplyPaymentTruth`, is the reason a forged confirm and a forged
  webhook are both harmless. This is the piece of the build that is genuinely
  world class.

---

## 2. Documentation accuracy

The question asked was specifically: which statements are now **wrong** rather
than merely superseded, because those are the ones that mislead. That distinction
is applied strictly below. A statement that was true when written and is clearly
dated is superseded. A statement presented as current fact that is false today is
wrong.

### 2.1 `ROADMAP.md`: statements that are WRONG

The file is 656 lines with fourteen top-level sections, six of which were appended
on 2026-08-15 and correct earlier sections rather than replacing them.

| # | Line | Statement | Why it is wrong |
|---|---|---|---|
| W1 | 3 | "As of 2026-08-13." | The document's last section is dated 2026-08-15. Every reader anchors on the header date. |
| W2 | 3 | "The next small step is always listed LAST so momentum survives any gap." | The `## Next small step` section is at line 291 of 656. Six sections follow it. The document's own navigation promise is false, and this is the promise Howard relies on to resume after a gap. |
| W3 | 291-330 | The entire `## Next small step` section: "AWAITING: Howard's walk of round 4 ... Then Phase 4D (Enroll), Phase 4.5 (staff toggle), Phase 5 (orvanna.io ...), Phase 6 (HyperSwitch test payments)." | Every one of those is done, shipped, or permanently deferred. Read alone, as its title invites, it describes a project two days and four phases behind. |
| W4 | 52 | Phase 5 row: "One MEDIUM (an authoring comment naming Howard in js/catalog.js line 7) queued for cleanup in the team-page round." | The comment is gone; `catalog.js` line 7 now reads "Billing modes, per the house pricing rule". The item is closed and still listed as owed. (See finding W17 for the larger version of this problem.) |
| W5 | 50 | Phase 6 row and lines 121-138: "PHASE 6 CLOSED 2026-08-14, BOTH GATES PASS." | True on 2026-08-14 and false as a description of what is live. Since those gates ran, the processor changed, the 3DS mode changed, the challenge presentation changed, the payment lifecycle changed, and checkout identity changed. The row is the first thing a reader sees and it certifies a rail that no longer exists. |
| W6 | 334-336 | "create-payment requests authentication_type 'three_ds' and request_external_three_ds_authentication **true**." | `create-payment/index.ts:140` sets `REQUEST_EXTERNAL_THREE_DS = false`. Stated as present-tense fact under a heading that says "BUILT AND DEPLOYED, all of it". |
| W7 | 203-204 | "Sandbox challenge card already documented: 4000 0038 0000 0446 (docs/TEST-CARDS.html)." | That is a HyperSwitch dummy-connector card. No dummy connector is enabled. It cannot produce a challenge on Braintree. |
| W8 | 341-343 | "Checkout survives a full page redirect: resume handler, order-number recovery panel, two polling schedules, four distinct outcomes." | Two of these are now true of `shop.html` only. `staff.html` has a reduced `staffResumeBoot` with no resume view, no `resumeApply`, no `cleanAddressBar`, and four outcome branches rather than six. The sentence is written about "checkout" as one thing. |
| W9 | 624-627 | "APPLIED TO BOTH SURFACES per the QA rule that scope follows capability." | Half true, and the half that is false is the dangerous half. The **challenge reveal** fix is genuinely in both (`CHALLENGE_REVEAL_MS = 1400` at `shop.html:1793` and `staff.html:1404`, identical; z-index 2147483647 in both stylesheets). The **finishing state** fix, described in the same paragraph, is in `shop.html` only: `liveSetFinishing` appears five times in `shop.html` and zero times in `staff.html`. `staff.html`'s `closeChallengeChrome` omits the finishing branch entirely. So the console still shows the exact "stops for a second back at the card entry" symptom the paragraph claims was fixed on both. |
| W10 | 561-563 | "The payment opens automatically when the payment step first becomes reachable, which is the **account-done stage, not checkout entry**." | It opens at both. `shop.html:1232` calls `liveEnsureCheckout()` from the drawer Checkout handler, immediately after `showView('checkout')`, while the account step is still on screen. `shop.html:896` calls it again at account-done. The roadmap describes the second and denies the first, and the git history contains a commit explicitly titled "Open the payment at checkout entry so the wait falls behind the account step". |
| W11 | 429 | "A Supabase personal access token would make future deploys exact and scripted instead of hand carried through a tool call; worth doing." | Still true and still not done, but it is filed under a section headed "DEPLOYED SINCE" and reads as a completed note. Minor. |
| W12 | 328 | "the corporate metric tile still reads '12 AI agents in the catalog' while the shop sells 16 items." | Still true (`www/index.html:57` renders `data-count="12"`), so this one is correct. Listed only to confirm it remains open. |
| W13 | 646-657 | "STILL OPEN across the project, none of it blocking" | The list is accurate as far as it goes but omits every item in section 5 of this audit that is not 3DS-related. Presented as the project's open-items list, it is materially incomplete. |
| W14 | 483 | "Key rotation and the orvanna.ai forward remain untouched." | Correct. Confirmed: no rotation is recorded anywhere and `ORVANNA/HyperSwitch/` is gitignore-fenced with no commits. |
| W15 | 55-66 | Phase 4.5 "NOW ACTIVE" | The staff console shipped and was gated (`docs/qa/PHASE-45-QA.md`). "NOW ACTIVE" reads as not-yet-done. |
| W16 | 79-89 | Phase 6 "queued 2026-08-13 ... starts AFTER he reviews the Phase 4 site" and "Already in hand: a local HyperSwitch sandbox at C:\hs" | Superseded four paragraphs later within the same block. Not wrong, but the block requires reading 60 lines before the reader learns the first 10 are obsolete. |
| W17 | throughout | The append-only structure itself | Six sections dated 2026-08-15 each correct the section above them. A reader who stops early gets a confidently stated falsehood. This is the mechanism that produced W5, W6, W7 and W10; they are symptoms, not separate defects. |

**Recommendation for the roadmap.** It has outgrown its form. It is now three
documents wearing one hat: a phase ledger, a decision log, and a working
engineering diary. The single highest-value documentation action in this audit is
to split it: a short phase table with live status at the top, decisions moved
into `docs/decisions/` where the architect charter already says they belong, and
the diary archived by date. The `Next small step` section moves to the bottom and
stays there.

### 2.2 `docs/3DS-RESEARCH.md`

1,349 lines. As research it holds up unusually well: it correctly predicted the
return-path gap, the webhook need, the billing-address blocker, and the
`4242 4242 4242 4242` trap, and it was honest about what it could not verify. Its
"What I could not verify" sections are exactly the right practice.

Statements that are now wrong as descriptions of the rail:

| # | Location | Statement | Status |
|---|---|---|---|
| R1 | One-paragraph summary and section A4 | "because `create-payment` sends neither `authentication_type` nor `request_external_three_ds_authentication`, the 3DSecure.io connector ... is not being asked to do anything yet" | Was true; is now the opposite of the situation. `authentication_type` is sent, external authentication is deliberately off, and 3DSecure.io is parked because it returns HE_00 even with a qualifying connector. |
| R2 | Section A0, A1, A2 (the whole return-path argument) | The `redirect_to_url` full page redirect "is the gap" and is the path to build for | The profile now sets `is_iframe_redirection_enabled = true`, so HyperSwitch returns `redirect_inside_popup` and the shopper stays on the page. A2 remains the correct design for the fallback, and the code implements it, but the document's framing that this is the live path is wrong. |
| R3 | Section A1's table | "Popup challenge (`redirect_inside_popup`) ... Partly. If the popup is blocked the shopper is stuck with no message." | This is now the primary path. The document's one-line dismissal of it is the least-developed part of the report and the most operationally important. Nothing in the code handles a blocked popup. |
| R4 | Section B, the entire test matrix | Three worlds: dummy connector, Stripe, 3DSecure.io | None of the three is the live world. The live world is Braintree. Zero Braintree cards appear anywhere in the document. |
| R5 | Section B5 and the appended "Acquirer configuration" chapter (400 lines) | Everything about acquirer BIN and acquirer merchant identifier | All of it is about the external 3DSecure.io path, which is off. The chapter's own conclusion ("Recommended plan for tonight: set authentication_type three_ds, leave request_external_three_ds_authentication off") is what shipped, which means the 400 lines above it are now background rather than instruction. |
| R6 | The change list, items 1 through 35 | "Nothing below was implemented. This is the build list." | Items 1, 3 through 22, 24 and 30 through 35 were implemented or superseded. Item 2 was implemented and then deliberately reverted. Items 25 through 29 (staff console) were implemented in part; item 28 (pay by link) was not, and that is now a shipped shell with a disabled button. The list is presented as a to-do and is largely a done-list. |

Recommendation: **amend, do not rewrite.** Add a dated preamble at the top saying
plainly which of its three worlds is live, add a Braintree section to Part B, and
mark the change list items done or dropped. The analysis is worth keeping; it is
the framing that has expired.

### 2.3 `docs/TEST-CARDS.html`

This is the most dangerous document in the project, because it is the one a tester
opens in order to act, and `www/shop.html:1983` points at it as authoritative
("Full matrix: docs/TEST-CARDS.html").

- It carries **no date at all**. Its file timestamp is 2026-08-14 18:46, before
  the Braintree switch.
- Its framing block names the 3DSecure.io external path as "the path this site
  uses" and calls processor-native 3DS "the fallback path". Both statements are
  now inverted.
- **Of roughly forty card rows, four are true on the live rail**
  (`4111 1111 1111 1111`, `5555 5555 5555 4444`, `3782 8224 6310 005`,
  `6011 1111 1111 1117`, as plain successes). Everything else is a Stripe PAN, a
  3DSecure.io sandbox PAN, or a HyperSwitch dummy-connector PAN, and none of
  those rails is connected.
- Two rows are **actively inverted**: `5105 1051 0510 5100` is documented as a
  decline and is a published Braintree success; and the large red-box instruction
  to use `4242 4242 4242 4242` "to prove the frictionless path still sails
  through" names a card that is not valid on Braintree at all and that Howard
  personally hit a blank-challenge bug with on 2026-08-15.
- The four cards the live checkout itself recommends
  (`shop.html:1975-1990`, verified end to end) appear **nowhere** in the file:
  `4000 0000 0000 2503` (challenge, passcode 1234, approves),
  `4000 0000 0000 2370` (challenge, authentication fails),
  `4000 0000 0000 2701` (frictionless, approves),
  `4000 1111 1111 1115` (authenticates, then the card declines).
- Expiry guidance conflicts: the document says "any future expiry, for example
  12/30"; the live hint pins `01/29`.
- The Braintree amount-triggered decline band ($2,000.00 to $3,000.00) is
  documented nowhere in the file, and it is the rule most likely to make a tester
  believe the site is broken.

Recommendation: **the code should not be brought back to this document; the
document should be rebuilt from the code.** Until it is, it should carry a banner
at the top. It is the only artifact in the project where following the
documentation produces a wrong conclusion within thirty seconds.

### 2.4 The remaining documents, briefly

| Document | Stated date | Wrong statements |
|---|---|---|
| `docs/SCHEMA-SPEC.md` | As of 2026-08-13 | Pins the engine spec version at "currently 'v1.2'"; it is v1.3. Documents ten tables; the database has fifteen. Delegates `demo_orders` and `demo_rate_events` to the Phase 6 spec with an explicit pointer, which is correct practice. Says nothing at all about `app.demo_users` or `app.demo_auth_config` and gives no pointer, so the entire authentication schema is documented nowhere but its own migration headers. Also omits `app.run_level_map`, a real table the comp engine creates. |
| `00-README.md` | As of 2026-08-13 | Says hosting is "GitHub Pages or Cloudflare Pages" (decided: GitHub Pages) and that the apex-versus-subdomain question is "decided at Phase 5" (Phase 5 shipped). Its heading claims "$0/month" while the table beneath it says $25/month. Its "What v1 proves" paragraph does not mention the shop, checkout, payments, 3DS, sign-in, or the staff console, which is now roughly half the built system. Points at `site\` as "the website" when the corporate site and the shop are in `www\`. |
| `db/README.md` | 2026-08-14 | Its rebuild recipe reads "001 through 007, then comp\001_comp_engine.sql, then data loaders, then runs, then 010." **A fresh environment built from that recipe has no view privilege hardening (011), no sign-in tables (012), and no member accounts (014).** It also states migration 009 "stays unassigned until its owner claims it", while `COMP-PLAN-SPEC.md:223` and `ROADMAP.md:296` both record 009 as the deployed engine v1.3 migration. |
| `docs/COMP-PLAN-SPEC.md` | As of 2026-08-13, version v1.3 | Accurate for its scope. It says nothing about payments or demo orders, which is correct by design, since the Phase 6 spec rules demo orders out of the engine entirely. No findings. |

---

## 3. Coherence: one design, or a set of patches?

**Answer: one good server design, and a browser layer that has become two
divergent copies of a patched design.**

### 3.1 The boundary between browser and server

The boundary is drawn correctly and then crossed in four places.

Drawn correctly: the browser sends `{ sku, mode, quantity }` and never a price;
the browser sends `{ order_number }` and never a status; card data never touches
Orvanna code; the return address is built on the server from a validated Origin
plus a two-item page allow list, so a client-supplied address cannot become an
open redirect. All four are exemplary and all four were live-probed by the Phase
6 verifier.

Crossed:

1. **`tax_exempt`** is a money decision the browser makes and the server obeys.
   Finding C1 above.
2. **Every number the shopper reads before the receipt is computed in the
   browser**, including the label on the pay button (`shop.html:1995`, from
   `orderMath()`). Only the confirmation view renders from the server receipt.
   The two agree today because the mirror check passes; nothing in the running
   system would notice if they stopped agreeing mid-session.
3. **The sign-in role check** at `shop.html:990` is an authorization decision made
   in the browser. Its own comment calls it "a courtesy", which is honest, but it
   is still a rule enforced in the one place it cannot be enforced.
4. **The portal and staff console gates** are shape checks on a `sessionStorage`
   object. Neither page ever transmits the token it holds. `demo-login` mints an
   HMAC-signed token and **no code anywhere verifies a signature**. The comments
   on both pages state the opposite: `site/index.html:66-68` and
   `staff.html:293-294` both say "The token was signed by the server; the browser
   cannot mint or edit one." The QA agent raised this as finding M4 on 2026-08-14,
   demonstrated it by hand-writing a token string, and the comment is still there
   unchanged. Nothing privileged sits behind either gate, so the exposure is nil;
   the false comment is the defect.

### 3.2 Where the truth about a payment lives

**This is the best part of the system and it should be the template for
everything else.** One function, `retrieveAndApplyPaymentTruth` in
`_shared/edge.ts`, performs the retrieve, the cent-for-cent amount check, and the
guarded update. Both `confirm-payment` and `payment-webhook` call it and neither
can skip a step. The database independently enforces the state machine with a
transition-guard trigger, so terminal rows are immutable at two layers. A forged
confirm degenerates into asking the server to re-check the truth. A forged webhook
is refused before a database connection is opened.

One gap: `livePollReceipt` (`shop.html:2188`), `resumeConfirm` (2428) and
`runLookup` (2486) have **no `.catch`**. A single network rejection ends the poll
loop silently with the page frozen in the finishing state, which is the one state
that deliberately says nothing about the outcome. The user-visible result is a
checkout that stops talking. The same omission exists in `staff.html`'s
`staffPollReceipt`.

### 3.3 Where money is computed

Three sources of the same numbers, two of them checked.

- `www/js/catalog.js` (browser, both pages) and `functions/_shared/pricing.ts`
  (server) hold parallel price and PV tables. **Mechanically checked** by
  `check_pricing_mirror.py`, which was run during this audit and passes 32 of 32.
- The activation fee lives as `DELIVERY.priority.price = 25` in `shop.html:1041`
  and `ACTIVATION_FEE_DOLLARS = 25` in `pricing.ts:75`. **Checked.**
- The tax rate lives as a bare `0.05` literal in `shop.html:1178`,
  **again as a bare `0.05` literal in `staff.html:819`**, and as
  `TAX_RATE_PERCENT = 5` in `pricing.ts:76`. The checker reads `shop.html` only.
  **`staff.html`'s copy is unchecked and can drift silently.** It is also
  unnamed: a magic number in two files.

Separately, `staff.html` folds no activation fee into its taxable base at all, by
deliberate design, so the two surfaces compute tax on different bases. Correct,
undocumented outside a code comment, and not covered by any gate.

### 3.4 Where identity is decided

Four places, and none of them binds to the next.

```
  login.html ----POST demo-login----> bcrypt check in Postgres      [REAL, server-side]
       |                                       |
       |                              returns HMAC-signed token
       v                                       v
  sessionStorage.orvanna_session  <----  written verbatim by the browser
       |
       +--> site/index.html gate:  shape check only, token never sent  [DECORATIVE]
       +--> www/staff.html gate:   shape check only, token never sent  [DECORATIVE]

  shop.html checkout sign-in ----POST demo-login----> bcrypt check     [REAL, server-side]
       |                                                    |
       |                                       returns role + username
       v                                                    v
  browser sets #memberCode.readOnly = true          token DISCARDED, never stored
       |
       +--> create-payment receives member_code as a PLAIN STRING
              and resolves it against app.members with NO proof       [UNAUTHENTICATED]
```

Consequence, stated plainly: migration 014 made the checkout credential check
real, which was the right call and answered Howard's "i want it not to be
theater". But **it did not make member attribution real**, because
`create-payment` still takes `member_code` on trust and every member code is
publicly readable through `v_demo_members`. A guest who never signs in can
attribute an order to any member in the roster by typing their code. The sign-in
therefore changes what the shopper experiences and changes nothing the server
enforces.

This is fine for a demo whose password is printed on the page. It is worth
knowing that it is fine *by accident of scope*, not by design, because the design
already mints exactly the artifact needed to fix it: a signed token that nothing
currently reads.

### 3.5 The same decision made in two places, consolidated

| Decision | Place one | Place two | Guarded? |
|---|---|---|---|
| Item price and PV | `catalog.js` PRODUCTS | `pricing.ts` CATALOG | Yes, mechanical |
| Activation fee | `shop.html:1041` | `pricing.ts:75` | Yes, mechanical |
| Tax rate | `shop.html:1178`, `staff.html:819` | `pricing.ts:76` | Shop only |
| Tax exemption | browser (`/\d/` test) | server accepts the verdict | No |
| Order total | `orderMath()` x2 | `priceCart()` | By convention only |
| Order number format | `ORDER_NUMBER_RE` x2, `orderNumber()` x2 (both dead) | `generateOrderNumber()` | No |
| Quantity cap 99 | `shop.html` x3, `staff.html` | `MAX_UNITS_PER_LINE` | No |
| Qualification threshold | `QUAL_PV = 100` (staff), bare `100` x6 (shop), `100.00 SV` (portal) | comp engine `sv >= 100.00` | No |
| Member role authorization | `shop.html:990` | `demo-login` role gate | No |
| Session validity | `site/index.html`, `staff.html` shape checks | `demo-login` HMAC, never verified | No |
| The whole payment engine | `shop.html:1069-2560` | `staff.html:885-1925` | No |

**The last row is the one that matters.** Roughly 600 to 650 lines, about 60
percent of `staff.html`'s payment engine and a third of the whole file, is a copy
of `shop.html`. About 210 of those lines are character-for-character identical
including comments: the resume block, the entire challenge chrome, the six
authentication predicates, `nextPollDelay`, both wait constants,
`canonicalReturnUrl`, the order-number regular expression. The rest is a
line-by-line copy with `live*` renamed to `staff*`.

It has already drifted, in four measurable ways:

1. `liveSetFinishing` exists in `shop.html` and not in `staff.html`, so the
   console still shows the card form flashing back between the approval closing
   and the verdict arriving.
2. `liveOutcomeMessage` has six branches in `shop.html` and four in `staff.html`.
   The two missing branches are exactly the "the passcode must never look
   ignored" fix, so a caller who completes an approval and is then declined gets
   the wrong sentence read to them by a live agent.
3. `shop.html` memoizes the HyperLoader promise and warms it; `staff.html` does
   neither and can append two script tags on overlapping calls.
4. `staff.html`'s comment at line 1345 says the z-index note "lives in shop.css".
   It was copied into `staff.css` as well. The pointer is wrong about its own
   copy.

The comment justifying the duplication (`staff.html:295-298`) applies to the
twenty-five-line session gate and says "Twenty-five lines duplicated beats a
fragile path". That reasoning is sound for twenty-five lines. It was never argued
for six hundred, and no comment attempts to.

### 3.6 Coherence verdict

Not one design, and not a random pile either. It is a **coherent server with a
forked client**. The fork happened when the staff console was built by copying
the shop, and every payment fix since has had to be applied twice by hand. Three
such fixes landed on 2026-08-15 and only one of the three made it to both
surfaces.

The correct repair is the one the 3DS research already recommended for the server
and which the server actually did: factor the shared thing into one place. For the
browser that means a `www/js/payments.js` holding the resume store, the challenge
chrome, the authentication predicates, the poll schedules, the return-URL builder
and the order-number regular expression, loaded by both pages exactly as
`catalog.js` already is. `catalog.js` is the proof that the pattern works on this
site: it is the one thing both pages share and it is the one money surface that
has never drifted.

---

## 4. The two-gate rule

### 4.1 The measurement

Every gate document in the project:

```
  verification/PHASE-1-VERDICT.md   2026-08-13
  verification/PHASE-3-VERDICT.md   2026-08-13
  verification/PHASE-5-VERDICT.md   2026-08-14
  verification/PHASE-6-VERDICT.md   2026-08-14
  qa/PHASE-1-QA.md ............... 2026-08-13
  qa/PHASE-3-QA.md ............... 2026-08-13
  qa/PHASE-4-QA.md ............... 2026-08-13
  qa/PHASE-45-QA.md .............. 2026-08-14
  qa/PHASE-4C-QA.md .............. 2026-08-14
  qa/PHASE-4C2-QA.md ............. 2026-08-14
  qa/PHASE-5-QA.md ............... 2026-08-14
  qa/PHASE-5T-QA.md .............. 2026-08-14
  qa/PHASE-6-QA.md ............... 2026-08-14
  qa/office-landing-QA-verdict.md  2026-08-14

  Gate documents dated 2026-08-15: ZERO.
```

Work shipped to production on 2026-08-15, measured from the last commit of
2026-08-14:

```
  15 commits
  945 insertions, 78 deletions across 8 files
  Of which, excluding ROADMAP.md prose:  723 insertions of code and SQL

  www/shop.html ....................... +529 / -  ~   (the entire checkout lifecycle)
  db/migrations/014_*.sql ............. + 54        (new table column, new role,
                                                     ~1,000 new credential rows)
  functions/create-payment/index.ts ... + 93        (3DS mode, billing address,
                                                     return URL, borrowed connection)
  www/staff.html ...................... + 54
  functions/_shared/edge.ts ........... + 16        (rate limiter connection lending)
  www/css/shop.css .................... + 48
  www/css/staff.css ................... +  7
```

### 4.2 What that surface actually contains

Every one of these shipped live, verified by its builder only:

1. **A processor change.** Braintree sandbox replaced four simulators. The
   connector that authorizes money changed, and nothing independent confirmed the
   amount path still holds end to end on the new one. The verifier's check V5
   (amount equality on a succeeded order) was explicitly deferred on 2026-08-14
   because that session could not drive the card SDK, and it has not been run
   since on any rail.
2. **A 3DS mode change.** `authentication_type: "three_ds"` on every payment,
   external authentication off, in-page popup redirection on at the profile
   level. The profile setting `is_iframe_redirection_enabled` was changed in a
   vendor dashboard, which means it is a production configuration change with no
   record in this repository at all.
3. **A new payment lifecycle.** Auto-open at three trigger points, an amount
   signature, orphan discard with no server-side cancel, a debounce, a finishing
   state, a challenge reveal timer. This is new state machinery on the money path
   and it is the largest single change of the day.
4. **New authentication surface.** Migration 014 altered a `CHECK` constraint on a
   live table, added a column, and inserted roughly one thousand credential rows
   sharing one bcrypt hash. No verifier looked at it. No QA signed the sign-in.
5. **A new client-side authorization rule** (`shop.html:990`).
6. **A shared-code change** in `_shared/edge.ts` (connection lending in
   `checkRateLimit`) that touches every function including the webhook.

### 4.3 The honest risk

Ranked by what could actually go wrong, not by how alarming it sounds.

**Nothing here can lose real money.** Braintree sandbox has no path to the real
world, the anon key remains sealed (live-probed 2026-08-14, and nothing on
2026-08-15 touched grants or views), the finalized commission months gained no new
input, and `app.demo_orders` remains outside the engine. The severity ceiling on
everything below is embarrassment and wasted time, not loss.

Inside that ceiling, the real exposures are:

- **HIGH, and it is a documentation risk rather than a code risk.** The project
  now claims, in its most-read document, that Phase 6 closed with both gates
  passing. A reader, including a future session of this team, will act on that.
  The gates passed on a rail that has since been replaced. Untrue certification is
  worse than no certification, because it stops the check from being made.
- **MEDIUM.** The staff console's payment path has drifted from the shop's and
  the divergences are exactly the fixes made for defects Howard hit in person. A
  live agent on a call will read a wrong sentence to a caller who authenticated
  and was then declined. That is the failure mode the whole MOTO honesty section
  of the console was written to prevent, undone by a copy that did not get the
  patch.
- **MEDIUM.** Orphaned payment intents accumulate with no cancel, and every one
  counts toward a 500-per-day ceiling that was sized for deliberate orders. A
  small number of curious visitors toggling activation can now put the demo into
  its "the demo is resting" 503 state on a day nobody abused anything.
- **MEDIUM.** The poll loops have no `.catch`. One dropped request leaves the
  checkout permanently silent in a state designed to say nothing.
- **LOW.** Migration 014 is not re-runnable (`drop constraint` without
  `if exists`) and its final `revoke` is not wrapped in the role-existence guard
  every other migration uses, so it fails on a plain Postgres instance. Combined
  with `db/README.md` omitting 011, 012 and 014 from the rebuild recipe, the
  database cannot currently be rebuilt from this repository without hand
  correction.

**The structural point.** The two-gate rule did not fail because anyone decided
to skip it. It failed because 2026-08-15 was a debugging day, and debugging days
produce a long chain of small fixes each of which feels too small to gate. Fifteen
commits, none of which individually warranted stopping, add up to a rebuilt
payment rail. The rule has no trigger that fires on accumulation. Recommendation:
add one. A standing rule that any change to `create-payment`, `confirm-payment`,
`_shared/edge.ts`, or the payment block of either page opens a gate obligation
that stays open until both gates run, regardless of how small the individual
change was.

---

## 5. What is owed: the definitive open-items list

Deduplicated across `ROADMAP.md`, the Phase 6 verdict and QA backlogs, the
office-landing QA verdict, the 3DS research change list, and this audit. Each
carries why it matters and what it would take. Ordered by the order the architect
recommends doing them; Howard's ordering call overrides.

### Tier 1: owed before anything else ships

| # | Item | Why it matters | What it would take |
|---|---|---|---|
| 1 | **Run one verifier pass and one QA pass over the checkout as a whole.** | The two-gate rule's entire purpose. Fifteen commits of money-path work are certified by their builder only, and the roadmap currently claims otherwise. | One verifier session against the live Braintree rail covering the deferred check V5 (amount equality on a genuinely succeeded payment, which now finally can be driven), plus the auto-open, the amount signature, the orphan behaviour, and migration 014's posture. One QA session on the live site, both surfaces. Half a day each. |
| 2 | **Correct the roadmap's false statements.** | W5, W6, W7, W9 and W10 in section 2.1 are wrong today and will be acted on. W5 in particular certifies a rail that does not exist. | Two hours. Best combined with the structural split recommended at the end of 2.1. |
| 3 | **Rebuild `docs/TEST-CARDS.html` from the live rail.** | It is the one document that produces a wrong action within thirty seconds, and the shop page points at it as authoritative. | Copy the four Braintree cards already proven in `shop.html:1975-1990`, add the $2,000.00 to $3,000.00 amount-decline band and the 01/29 expiry, and archive the three dead worlds behind a clearly labelled historical section. Two hours. |
| 4 | **Rotate the burned keys.** | Four secrets have touched a chat window or a repository: the 3DSecure.io sandbox key, the HyperSwitch secret API key, the HyperSwitch payment response hash key, and the Stripe test key. Migration 012's own header records that an earlier draft of that file carried two plaintext passwords into git history. | Howard, dashboard only, twenty minutes. New values typed straight into the Supabase vault. Nothing in this repository changes. |

### Tier 2: correctness and coherence

| # | Item | Why it matters | What it would take |
|---|---|---|---|
| 5 | **Decide the `tax_exempt` question (finding C1).** | The one place where a money figure is decided in the browser and obeyed by the server, inside a design whose stated invariant is that this never happens. | Architect recommendation: delete the exemption control and tax unconditionally until Phase 6.2 brings a real engine. One hour if that is the ruling; a schema question if Howard prefers to derive it from a signed-in member. |
| 6 | **Extract the shared browser payment module.** | Two copies of a 650-line engine that has already drifted three ways in one day, on the money path, on a page a live agent reads aloud from. | A new `www/js/payments.js` holding the resume store, challenge chrome, authentication predicates, poll schedules, return-URL builder and order-number regular expression, loaded by both pages exactly as `catalog.js` is. One focused day. The deploy builder needs no change; `catalog.js` already proves the path survives the move. |
| 7 | **Carry the three missing fixes to `staff.html`.** | The finishing state, the two extra outcome branches, and the loader memo. Until item 6 lands, these are the drift that is live. | Half a day, or free if item 6 is done first. |
| 8 | **Cancel orphaned payments (finding C2).** | Auto-open plus signature invalidation creates rows and HyperSwitch intents that nothing ever closes, and they count against the daily ceiling. | A small `cancel-payment` Edge Function in the shape of the existing ones, called from `liveResetPayment`; or, minimally, exclude `abandoned` rows from the daily count. Half a day for the function. |
| 9 | **Add `.catch` to the four poll loops.** | One dropped request leaves the checkout permanently silent in the state designed to say nothing about the outcome. | One hour. `shop.html:2188`, `shop.html:2428`, `shop.html:2486`, `staff.html:1645`. |
| 10 | **Name the tax rate and check `staff.html`'s copy.** | A bare `0.05` in two HTML files is the only money constant with no name and no gate on one of its copies. | Extend `check_pricing_mirror.py` to read `staff.html` as well; move the literal to a named constant in `catalog.js`. Two hours. |
| 11 | **Fix the two false gate comments.** | `site/index.html:66-68` and `staff.html:293-294` both claim the browser cannot mint a token. QA proved otherwise on 2026-08-14 and the comment is unchanged. A false comment is worse than no comment. | Twenty minutes to correct the wording honestly. Making the gate real is item 20. |
| 12 | **Resolve the PV-versus-SV naming split.** | Office-landing QA finding M5. The console and the portal were corrected to "100.00 SV"; `www/shop.html` still says "100 PV" and "A qualified month needs 100 PV" in five places. Two live surfaces now name the same rule differently, which is the state M5 was raised to end. | One hour. |

### Tier 3: repository and rebuild integrity

| # | Item | Why it matters | What it would take |
|---|---|---|---|
| 13 | **Fix the migration ledger.** | 009 is recorded as deployed by two documents and as "unassigned" by `db/README.md`. 013 is skipped with no explanation anywhere in the repository. There is no `009_*_POINTER.md` beside the `008` one. | Add the 009 pointer, record what 013 was, one hour. |
| 14 | **Repair `db/README.md`'s rebuild recipe.** | It omits 011, 012 and 014. A fresh environment built from it has no view privilege hardening and no sign-in tables. This is the only document that says how to reconstitute the database. | One hour. |
| 15 | **Make migration 014 re-runnable and portable.** | `drop constraint` without `if exists` fails on a second run; the final `revoke` is not wrapped in the `pg_roles` existence guard that 003, 007, 010 and 012 all use, so it fails on plain Postgres. | Twenty minutes. |
| 16 | **Record the engine v1.2 source, or accept that six frozen runs are not re-derivable.** | `db/comp/001_comp_engine.sql` was edited in place for v1.3. The database still holds six commission runs stamped `spec_version = 'v1.2'` as deliberate superseded history. The source that produced them exists only in git history. For a project whose stated crown jewel is a recomputable, auditable commission run, that is the one auditability gap in the engine. | Either copy the v1.2 source to `db/comp/000_comp_engine_v1.2_ARCHIVE.sql`, or write one line in `COMP-PLAN-SPEC.md` saying superseded runs are not re-derivable from the working tree. One hour. |
| 17 | **Update `SCHEMA-SPEC.md` and `00-README.md`.** | The authentication schema (`demo_users`, `demo_auth_config`) is documented nowhere but its own migration headers. `00-README.md` describes a project without a shop, a checkout, payments, or a staff console. | Half a day for both. |
| 18 | **Move decisions into `docs/decisions/`.** | The architect charter says one dated file per decision. There is exactly one file, from 2026-08-13. Since then the project has decided: the parallel demo-orders table, the mirrored pricing module, the Braintree switch, the in-page challenge, the auto-open lifecycle, the member sign-in design, and Botpress. All of them live in roadmap prose. | Half a day, and it is most of the fix for the roadmap's structural problem. |
| 19 | **Fix the build's line-ending translation.** | `deploy/build_dist.py`'s `rewrite()` uses `Path.write_text` without `newline=""`, so on Windows every LF becomes CRLF. `www/staff.html` is LF in source and CRLF in the published output: 1,973 lines and 1,972 bytes different for a one-string substitution. The public deploy repository shows a whole-file diff for that page on every build, and no byte-identical verification between source and deployed artifact is possible for it. | One argument. Ten minutes. |

### Tier 4: known and accepted, or deferred by ruling

| # | Item | Status |
|---|---|---|
| 20 | Make the portal and console gates real (route data through an authenticated function) | Tracked follow-up, disclosed honestly in migration 012's header and in office-landing QA M4. Nothing privileged sits behind either gate today. |
| 21 | Bind member attribution to the sign-in (send the token to `create-payment`) | Not currently tracked anywhere. Section 3.4. Would take an afternoon and would make the sign-in mean something on the server. |
| 22 | Frictionless payments still flash the authentication window | Howard: "for now this is acceptable". The correct fix (poll for `next_action` rather than guess on a 1,400 millisecond timer) is recorded in the roadmap. |
| 23 | The external 3DS path (3DSecure.io) returns HE_00 | Parked. The processor's own 3DS works. Rotate the burned key before debugging further. |
| 24 | TaxJar / Phase 6.2 | Blocked at signup. Three options recorded in the roadmap; the architect's view is that option (b), keeping the honest built-in 5 percent engine and presenting the connector screen as the "where a real engine plugs in" story, is the right demo answer and costs nothing. |
| 25 | Pay by link on the staff console | A complete shell with a deliberately empty handler (`staff.html:966-968`) and an honest on-screen note. **But four separate on-screen strings instruct the agent to "send them a payment link", which the console cannot do.** Either build it (a fifth Edge Function; the 3DS research called it the largest single item on its list) or soften the four strings. |
| 26 | `orvanna.ai` forward to `orvanna.io` | Howard's browser step. Untouched. |
| 27 | Office-landing QA findings M2, M3 | Howard's calls, still open. (M4 is item 11 and 20; M5 is item 12; H1 was fixed.) |
| 28 | Corporate metric tile reads "12 AI agents" while the shop sells 16 | `www/index.html:57`. Howard's wording call, still open. |
| 29 | Supabase personal access token for exact, scripted function deploys | Roadmap notes deploys are currently hand-carried and functionally verified rather than byte-compared. Confirmed: `functions/` and `supabase/functions/` are byte-identical today, so nothing has drifted yet. |
| 30 | Phase 6 QA and verifier backlog: inert demo card fields visible pre-mount (M1), thin demo framing pre-mount, rate-limiter read-then-increment race, abandoned-terminal asymmetry (spec-accepted), list accepts POST, list JSON raw dollars | All still open. M1 is partly overtaken: the fake card fields are now hidden whenever `LIVE_PAYMENTS` is true, but they are still present in the markup and are only hidden once the script reaches `setPayMethod`, so a script error before that point exposes them. |
| 31 | Dead code sweep | Not tracked anywhere. `shop.html`: `demoPlaceOrder` (44 lines) and `orderNumber` are unreachable, `accountMode` is written five times and never read, `livePollReceipt`'s `attempt` parameter is never used. `staff.html`: `orderNumber` and the demo tail of `placeOrder` are unreachable, eight lines clear card inputs the user can never see, `createLinkBtn`'s handler is empty, `renderProductOptions` is called three times where one would do. |
| 32 | Stale user-facing copy | Not tracked. `shop.html:250` "Nothing is charged", `:306` "any values continue, including empty fields", `:390` "Payments route through the Orvanna orchestration layer in a later phase", `:121` "your saved billing address" (it is a hardcoded synthetic one). All permanently visible on a live payment page. |
| 33 | Development-diary comments shipped to a public site | Not tracked. `www/shop.html`, `www/staff.html` and `site/js/app.js` carry roughly a dozen comments naming Howard, several quoting him verbatim ("i want to move to next phase and it not be theater") and dating his bug reports. This is the Phase 5 verifier's MEDIUM finding (an authoring comment naming Howard in `catalog.js`) recurring at ten times the volume, on files any visitor can fetch. |
| 34 | `www/js/catalog.js` carries a UTF-8 BOM | Cosmetic. The only file in the project that does. |

---

## 6. What was checked, and what was not

Stated plainly so the next reader knows the boundary of this audit.

**Read in full:** `ROADMAP.md`, `docs/PHASE-6-SPEC.md`, `docs/3DS-RESEARCH.md`,
`docs/TEST-CARDS.html`, `docs/SCHEMA-SPEC.md`, `00-README.md`, `db/README.md`,
`db/migrations/010`, `011`, `012`, `014`, all five Edge Functions,
`_shared/edge.ts`, `_shared/pricing.ts`, `www/shop.html`, `www/staff.html`,
`www/login.html`, `site/index.html`, `deploy/build_dist.py`,
`docs/qa/office-landing-QA-verdict.md`, `docs/verification/PHASE-6-VERDICT.md`.

**Executed:** `functions/_shared/check_pricing_mirror.py` (PASS, 32 of 32
quadruples, activation fee and tax rate matched). Byte comparison of `functions/`
against `supabase/functions/` (identical). Byte comparison of `www/` against
`deploy/dist/` (identical except the two files the builder rewrites; see item 19).
Repository-wide sweep for em dashes and en dashes (zero, the standing rule holds).
Git history and diff statistics for 2026-08-15.

**NOT checked, and each is a real limit on this audit:**

- Nothing was probed against the live site or the live database. Every claim about
  runtime behaviour is read from source or taken from the dated gate documents.
- The HyperSwitch dashboard was not opened. The profile setting
  `is_iframe_redirection_enabled`, the Braintree connector state, and the disabled
  simulators are taken from the roadmap's account of them.
- No card was driven end to end. The verifier's deferred check V5 remains
  deferred.
- The Supabase vault contents were not inspected, correctly.
- The comp engine's arithmetic was not recomputed. Phase 3's gates did that and
  nothing since has touched the engine's inputs, which is itself an architectural
  guarantee from spec section 2.1 rather than an assumption.

---

## 7. Closing note

The instruction was "world class coding and clean and nothing sloppy". Measured
against that bar, this project is two different projects.

The server is close to the bar. One implementation of payment truth serving two
callers, an amount check that is the last word before any success, a database
state machine enforced by trigger as well as by code, a webhook that refuses a
forged signature before opening a connection, a price mirror with a mechanical
gate, and an anon posture that was live-probed rather than asserted. Very little
of that needs changing.

The browser is not at the bar, and the reason is specific and fixable: the staff
console was created by copying the shop, and nothing has forced the two back
together since. Every finding in section 3 that is not about identity traces to
that one decision. Item 6 on the owed list is the highest-leverage hour in this
report.

The documentation is furthest from the bar, and it is the part that will cost the
most, because it is what the next session will trust. A roadmap that certifies a
replaced rail, and a test-card sheet that names cards that cannot work, are not
untidy; they are instructions to do the wrong thing.

None of this is a crisis. No real money can move, the engine's finalized months
are provably untouched, and the sealed data posture held through every change.
What is owed is a day of consolidation and a day of documentation, and then the
two-gate rule needs a trigger that fires on accumulated small changes rather than
on phase boundaries, because that is the exact gap fifteen commits walked through
on 2026-08-15.
