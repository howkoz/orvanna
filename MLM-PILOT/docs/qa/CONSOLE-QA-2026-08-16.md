# Console gate, Quality Assurance (QA) verdict: the complete staff-console artifact, 2026-08-16

Gate agent: mlm-qa (acceptance and truth). Scope: commits `49cdb9e`, `58160e4`,
`61ebe26`, `614bc1d`: `www\staff-operations.html`, `www\css\staff-ops.css`,
`functions\billing-console\index.ts`, `functions\commission-report\index.ts`,
migrations 028 and 029, plus the `login.html` and `staff.html` wiring. Specs of
record: SUBSCRIPTION-ENGINE-SPEC version 1.2 (sections 9A.2 and 9B) and
STAFF-COMMISSION-DASHBOARD-SPEC version 1.0. Companion gate:
`docs\verification\CONSOLE-VERDICT-2026-08-16.md` (verifier PASS, DEPLOY YES,
five LOW notes, all read and adopted below).

Method: checklist built from the specs before any deliverable was opened; the
page was then DRIVEN IN A BROWSER served locally from `www\`. The two new
functions are not deployed, so the drive graded live what is live (sign-in,
navigation, the graceful-failure states of the real page against the real
platform) and used the page's fenced development mock, which mirrors the
pre-deploy production truth, for everything behind the undeployed functions.
The local server was stopped after the pass.

Acronym key: Quality Assurance (QA), Personal Volume (PV), Sales Volume (SV),
Commissionable Volume (CV), Team Volume (TV), open question (OQ), failure mode
(FM), Graphical User Interface (GUI), Merchant Initiated Transaction (MIT).

## Verdict, stated first

**PASS. DEPLOY: YES**, joining the verifier's DEPLOY YES on the same
artifacts, under the deploy-round checklist already adopted (migration 029's
A1 to A7 plus the verifier's V-A8 to V-A13) and two QA additions below. One
MEDIUM finding (the unreachable-service message breaks the discoverability
rule), non-gating because deploying the functions removes the guaranteed
occurrence; it takes a one-line fix that should ride the deploy round. Three
LOW notes.

## Section A: spec conformance inventory, every promised panel

| Row | Promise | Evidence | Grade |
|---|---|---|---|
| A01 | Schedule control (enable, disable, time, timezone), server-stored (9A.2) | Panel present with labeled controls; mock save answers with the stored row and honest pg_cron note; server function `schedule_set` refuses enabled-without-time with a reasoned message | PASS |
| A02 | Run now with MANDATORY dry-run preview: count due, dollars, frequency and new-versus-retry breakdown (9A.2) | Preview button drives the same gather-and-price read; execute button ships disabled and unlocks only after a preview this session (courtesy half; the server enforces its own gates regardless, verified by the verifier section 5) | PASS |
| A03 | The limit field beside RUN NOW: blank = all, N = exactly N (9B rule 5) | `runLimitInput` labeled "Number to run", placeholder "blank = all due"; one reader function feeds BOTH preview and execute so the ask can never diverge | PASS |
| A04 | Preview with N set lists WHICH subscriptions the first N are, in selection order (9B rule 5) | Rendering code present (Order, Member, Sub, Cycle, Due date, Billing, Amount table in the server's four-key order); server selection proven byte-identical to the engine's by the verifier (probe V1) and the LM battery rows. The list itself cannot render against the inert pre-deploy database; browser proof lands in the deploy round (QA-A15 below). In the inert state the preview still acknowledges the ask: "Number to run: 5. The limit rides the execute payload..." | PASS, browser proof deferred to deploy round on the record |
| A05 | Arm-then-fire confirm, separate from preview | Driven: first click arms and renames the button "Click again to execute (simulated)"; changing dispatch DISARMS; live arming states the money consequence ("live dispatch will really charge the seeded test cards on the sandbox rail") | PASS |
| A06 | Run history: run id, tick date, gathered, succeeded, declined with member-fault and system-fault separate, retries, drill to attempts, and the LIMIT COLUMN ("ran N of M due, R remaining", 9B rule 4) | Table carries all columns including Member fault, System fault, and Limit; `limitLabel` renders migration 028's real fields and renders pre-028 and unlimited runs as "all due", the honest reading; drill renders per-attempt kind, code, class, fault family, next action | PASS |
| A07 | Retry queue by decline class | Panel present; empty state reads "Nothing is scheduled to retry." | PASS |
| A08 | Attention queue (orphans, cycle gaps, internal_config, needs_human) | Panel present; empty state reads "Nothing needs a human right now." | PASS |
| A09 | Member management: pause, resume, cancel, change billing day, change frequency, flag card update, reactivate, with the 12.1 disclosure shown to staff | All seven actions render per subscription card; each opens a confirm strip with the honest consequence text and a "Never mind" exit; the engine's own disclosure text renders verbatim on success (`ops-disclosure`, never a paraphrase); day picks validated 1 to 28 per the OQ3 ruling | PASS |
| A10 | Seven-day forecast from the same schedule arithmetic | Panel present; in the pre-deploy state it renders the 1,419-subscription backlog honestly with the epoch explanation instead of inventing dates | PASS |
| A11 | The five commission panels (dashboard spec section 3) | Runs board (every figure with its run number), current month live (bridged and house-retained shown together; figures match the spec section 8 worked example: 2,000.00 bridged SV, 11 orders, 3,050.00 retained), member drill (member code only), house ledger (bookkeeping language present, GW-000 nowhere else), superseded trail (runs frozen and marked, final last) | PASS |
| A12 | The projection labeling rule (dashboard 3.2) | Driven: banner text EXACT ("WHAT-IF PROJECTION, not a statement. Computed <timestamp>. Numbers change as the month accumulates and are not payable."), rendered in the warning treatment (`ops-warn`), timestamp present, and ZERO run-id text anywhere in the projection block; the server's literal string at `commission-report\index.ts` line 109; finalized figures all carry "run N", so the machine-checkable tell holds in both directions | PASS |
| A13 | The page is not a gate; servers enforce every rule | The page's own header says so and behaves so; the verifier verified the server half line by line (roles re-read per call, staff-only on billing-console, staff-and-admin on commission-report per OQ5) | PASS |
| A14 | Every write audited to `app.demo_staff_actions` | Code-read (verifier section 5: every refusal and write on the write path audited); live probe is deploy-round V-A11/V-A12 | PASS, code-read |

## Section B: the Howard rows

| Row | Rule | Evidence | Grade |
|---|---|---|---|
| B01 | Blank limit = run everything due | Placeholder says "blank = all due"; blank preview claims no limit note; run history renders unlimited runs as "all due" | PASS |
| B02 | Limit 5 = exactly 5, preview lists WHICH five before confirm | Field carries the ask to both preview and execute; server selection deterministic and proven (verifier V1: the five members recomputed independently, byte-identical); WHICH-list rendering present in the page; inert-state preview acknowledges the ask honestly. Browser demonstration of the visible list is the deploy round's A2 (limit 2), adopted as QA-A15 | PASS |
| B03 | A projection can never read as a finalized statement | Exact banner, warning treatment, no run id at any nesting (driven and code-read); finalized rows always carry run ids; the projection-over-finalized-month case is refused server-side ("period_finalized") | PASS |
| B04 | Every refusal hands the operator a next step (the permanent discoverability row) | Driven refusals that PASS: dispatch missing ("Choose the dispatch mode first: live or simulated..."), engine not ready ("...the deploy round applies it after the gates. Until then the console previews only."), engine inert on member actions ("This control goes live with Phase S2."), malformed member code ("Member codes look like GW-000123."), schedule enabled without time, sign-in failure, empty states ("expected state before Phase S2"). ONE FAILURE: the unreachable-service catch message, defect M1 | FAIL on one state, defect M1 |

## Section C: documentation truth, ten claims traced

| # | Claim (in-file reports, README, commit titles) | Evidence | Grade |
|---|---|---|---|
| C1 | Mock mode activates ONLY on localhost plus `dev=mock` | Code fence reads exactly that; DRIVEN both ways: the no-flag visit hit the real platform endpoints (fetch reached Supabase and failed on the undeployed functions, no mock data appeared, no banner); the flagged visit showed the loud banner | PASS |
| C2 | "This banner cannot appear on the public site" | True by construction: condition 1 (localhost hostname) cannot hold on the public origin | PASS |
| C3 | Mock fixtures are recorded live shapes, not inventions | The commission figures in the mock equal the dashboard spec's section 8 recorded reality (2,000.00 SV, 11 orders, 3,050.00 retained; the 1 through 6 superseded by 7 through 12 trail) | PASS |
| C4 | "Console: run exactly N, previewed first" (58160e4) | Limit field, preview limit block, WHICH-list rendering, execute payload carriage all present | PASS |
| C5 | "Migration 028: run exactly N, strand exactly zero" (61ebe26) | 028 adds limit_requested, due_count, processed_count, remaining_count and the deterministic four-key selection; LM1 to LM6 battery rows in the committed transcript `transcript-20260816-175504.txt` (79 PASS rows, zero FAIL), re-proven independently by the verifier | PASS |
| C6 | "Console worker: the run button becomes real" (614bc1d) | `run_execute` action with the full gate ladder (dispatch_required, engine_not_ready, not_configured, live_credentials_missing) present in the function; LV1 to LV4 rows in the transcript | PASS |
| C7 | Execute sends the PREVIEW'S tick date so what executes is what was previewed | Code: the execute body reads `lastPreview.preview.tick_date` | PASS |
| C8 | Dispatch is explicit, never defaulted | Select ships on a blank "choose..." option; the page refuses without a choice (driven); the server refuses regardless (verifier section 5) | PASS |
| C9 | Migration 029's footer carries the A1 to A7 deploy acceptance procedure | Present at 029 lines 659 onward, exactly as the verifier adopted | PASS |
| C10 | Harness README: 65 battery rows as of the fix round plus the console segments | README updated; committed transcript carries the LM and LV rows beyond the 65 with zero FAIL | PASS |

## Section D: sign-in truth

| Row | Check | Evidence | Grade |
|---|---|---|---|
| D1 | The staff account is `Orvanna_Staff` / the recorded staff password; "staff" does not exist | Migration 012 seeds `Orvanna_Staff` (role staff) and no "staff" account; DRIVEN: username "staff" refused with the truthful, non-leaking message "That username and password do not match a demonstration account."; `Orvanna_Staff` signed in and landed on the operations page with a staff session | PASS |
| D2 | The page and helper text say the truth | No text anywhere on the page, the login page, or the mock claims a "staff" username; the mock's `updated_by` fixture uses `Orvanna_Staff`; the login note truthfully says the server checks the demonstration database and the page never holds a password | PASS |
| D3 | The unauthenticated page redirects to the staff sign-in with the right return | Driven: session cleared, reload redirected to `login.html?role=staff&next=staff-operations.html`; after sign-in the page returned to the operations area; `login.html` accepts the new destination through its known-next allowlist only | PASS |

## Section E: hygiene and accessibility

| Row | Check | Evidence | Grade |
|---|---|---|---|
| E1 | Em and en dashes | Zero across every changed file in the four commits | PASS |
| E2 | No Unicity terminology, no owner name in product surfaces | Zero Unicity hits; the owner's name appears only in spec-citation comments per house precedent | PASS |
| E3 | Acronyms expanded | Page notice expands PV, SV, CV, TV; migrations 028 and 029 carry acronym keys; billing-console expands Merchant Initiated Transaction where it rules. One slip: LOW L-QA3 | PASS with L-QA3 |
| E4 | Form labels and keyboard | ZERO unlabeled controls (every input and select has a `for`-bound or wrapping label); tabs are real buttons with `role=tab` and `aria-selected`; clickable table rows carry `tabindex=0` with Enter and Space handlers | PASS |
| E5 | Computed contrast (charter standing lesson: computed styles with alpha compositing, worst five reported) | Worst five on the page: `ops-btn-danger` 4.83, `ops-table th` 5.16, `ops-stat-label` 5.62, `btn-addline` 6.29, `ops-final-chip` 6.38. Every measured element, including all state pills, chips, banners, both tab states, and every table role, is at or above 4.5 to 1 | PASS |

## Defects and notes

### MEDIUM

- **M1. The unreachable-service refusal hands no next step, and it is the
  guaranteed state of the live page today.** Every panel's network-failure
  catch renders exactly "Could not reach the billing console service." (or
  the commission twin). Driven live with the functions undeployed: the
  platform refuses the preflight, the fetch throws, and the operator gets
  six such lines with no pointer to WHY (the services are not deployed yet)
  or WHAT NEXT (the deploy round; or, post-deploy, "try again; if it
  persists, tell the engineer"). This breaks Howard's permanent
  discoverability row on the exact surface it was written for. One-sentence
  fix in the shared catch messages; non-gating because the deploy round
  itself removes the guaranteed occurrence, but the wording should ride
  along so the genuine-outage case also complies.

### LOW

- **L-QA1.** The mandatory-preview discipline is page-side only (the
  execute button unlocks on any successful preview, including an inert
  one); the server does not require a recent preview. Same substance as the
  verifier's L4, restated from the acceptance side: acceptable under the
  read/write audit rule, noted for S3.
- **L-QA2.** The tablist has no arrow-key roving focus; both tabs are
  ordinary buttons reachable by Tab and activatable by Enter, which meets
  the basics; full tablist keyboard semantics are a nicety.
- **L-QA3.** `commission-report\index.ts` uses "CV" in a comment (line 158)
  with no expansion anywhere in the file. First-use expansion is the
  standing rule even in comments. One-word fix, any convenient commit.

### Adopted from the verifier, unchanged

L1 (list-search recovery page bound), L2 (placeholder-then-overwrite on the
live reference), L3 (`clock_source` label on live runs), L4 (preview
unaudited), L5 (`EXECUTE_ENABLED` is compile-time). None gating; all stand.

## Deploy round: YES, checklist additions

Migration 029's A1 to A7 and the verifier's V-A8 to V-A13 are adopted as
written, including the rule that the finale A2/A3 run is Howard's to press,
by name. QA adds:

- **QA-A14.** Before or with the deploy, add the next-step sentence to the
  unreachable-service catch messages (defect M1). Non-gating; one line each.
- **QA-A15.** After the functions deploy and 028/029 apply, re-drive the
  LIVE page browser pass on the deployed origin: every panel answers with
  real data; during the A2 limit-2 run, the preview VISIBLY lists WHICH two
  subscriptions will bill before the confirm (the Howard row's browser
  proof, deferred here on the record); the run-history row afterward reads
  "limit 2: ran 2 of N due" in the Limit column; and the mock banner is
  confirmed absent on the public origin.

Both gates have now passed on the same artifact hashes (verifier section 9
list). Per the standing rule, the deploy round may proceed on exactly those
bytes; anything rebuilt re-opens both gates.
