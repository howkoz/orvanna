# Console gate verdict: the complete staff-console artifact, 2026-08-16

Verifier: mlm-verifier (correctness gate). Scope: commits 49cdb9e, 58160e4,
61ebe26, 614bc1d: migrations 028 (run limit) and 029 (live dispatch seam),
`functions\billing-console\index.ts` (including the live worker),
`functions\commission-report\index.ts`, `www\staff-operations.html`, plus
the harness segments 17 and 18 and the extended battery. Specs of record:
SUBSCRIPTION-ENGINE-SPEC v1.2 section 9B (ruling R9) and
STAFF-COMMISSION-DASHBOARD-SPEC. Method: full code reading of every file
plus independent execution on the disposable Docker rig. The verifier fixes
nothing.

Plain path:
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\verification\CONSOLE-VERDICT-2026-08-16.md`

Acronym key: Merchant Initiated Transaction (MIT), 3-D Secure (3DS),
Customer Initiated Transaction (CIT), failure mode (FM), open question (OQ),
ruling (R), card verification code (CVC), Row Level Security (RLS).

## Verdict

**PASS. DEPLOY ROUND: YES**, under the checklist and conditions in
section 8. Zero HIGH, zero MEDIUM findings; five LOW notes, none gating.
The battery re-ran independently: ALL PROOFS PASS (65 core plus LM1 to LM6
and LV1 to LV4), transcript identical to the committed
`transcript-20260816-175504.txt` except the container-kept housekeeping
line. Every requested probe was run; every ruling requested is given below.

## 1. Ruling on the worker's argued deviation: ENDORSED

The deviation: on an AMBIGUOUS wire failure (create or retrieve timed out,
or the create was refused with a non-ok status), the worker never records
the `processor_unreachable` verdict; the attempt stays honestly
'dispatched' and the next sweep resolves it from the rail's own ledger
(direct retrieve when a payment reference exists, else a list search by
`metadata.billing_attempt_id`; an attempt the rail has never seen is
charged then, safe by construction).

Endorsed, and the argument is the engine's own: `processor_unreachable`
marks the demo order abandoned and schedules an immediate infra retry as a
NEW attempt with a NEW charge (migration 026's infra lane). Issuing that
verdict while the original create may have landed is precisely how a
double charge is born, FM1 by way of FM2. The chosen posture is the FM2
reconciler pattern the spec itself prescribes ("retrieve the truth from
the processor"), applied to the real rail, and the sweep-before-new-work
ordering plus the reference-stamped-at-create bookkeeping make the crash
window recoverable at every point I traced (create-ok-then-crash: direct
retrieve; create-unclear-then-crash: list search; rail-never-saw-it:
charge, which cannot double because no payment exists). Two consequences,
recorded as facts, not faults: the infra retry lane is unreachable under
live dispatch in this build (conservative, correct for S2 minimal; a
definitive never-reached signal may reopen it), and a wire failure leaves
the attempt in the attention queue rather than silently retried, which is
the design's stated intent.

## 2. Migration 028 re-proven in the rig, plus selection equivalence

- LM1 to LM6 re-ran under my own harness execution: the 5-of-23 run row
  (limit 5, due 23, processed 5, remaining 18), the deterministic first
  five, the next-tick self-heal starting at number six with zero
  strandings and the FM1 key held across limited runs, the retry that
  processed on a limited day regardless (9B rule 6), the day-4 remainder
  self-heal, and the arithmetic present on unlimited runs too. All PASS.
- **Selection equivalence, probed independently (V1):** I recomputed the
  full 23-candidate due set for 2027-11-01 and ordered it by the engine's
  four keys (scheduled date, member code, subscription id, renewal index),
  took the first five, and compared against the members the limited run
  actually processed, in order: byte-identical
  (GW-9000, GW-9001, GW-9004, GW-9006, GW-9007). The console preview's
  sort (read in `actionRunPreview`) applies the same four keys to the same
  gather; its date key sorts the YYYY-MM-DD string, which is
  chronologically identical, and member codes are plain ASCII so the
  JavaScript and PostgreSQL orderings agree. The preview's limit block
  counts new cycles only and states in its own payload that retries are
  never limited, matching 028's arithmetic.
- Misuse probes: limit zero refused with the R9 error; gibberish dispatch
  refused; exactly one `fn_billing_tick` exists with the three-argument
  signature (no ambiguous overload) (V4a, V4b, V6).

## 3. The worker's create body, verified by reading

- `authentication_type: "no_three_ds"` on the one and only create call;
  no other create path exists in the file; no external authentication or
  challenge flow is requestable (ruling 8.4; acceptance A3 makes any
  challenge an outright FAIL).
- Amount is the FROZEN `demo_orders.total_cents` in integer minor units,
  asserted twice: repriced server-side from the shared pricing mirror
  (`CATALOG[sku].sub.price` times covered_months times quantity, the
  shop-slug sku written through `shop_sku_map`, multi-month items
  included) and refused on any mismatch BEFORE the charge; then on the
  success side the fresh retrieve's amount and amount_received must equal
  the same frozen cents before a succeeded verdict is written. FM3 and the
  checkout's evidentiary bar, both present.
- The metadata contract is exact: `channel: "renewal_engine"`,
  `billing_attempt_id` (stringified), `order_number`, and the recovery
  path searches by exactly that key.
- The fixed CVC "123": acceptable and correctly flagged. The two seeded
  numbers are the published Braintree sandbox pair, which accept any
  three digits; the parser refuses any token not shaped
  `sandbox-card:<number>:<month>:<year>`, and probe V7 confirms no other
  number exists behind any sandbox marker in the rig. Deploy-round
  checklist item V-A14 carries the assumption forward.

## 4. commission-report and the role fence

- Projection hygiene, read line by line: one transaction on the direct
  connection; the REAL `app.fn_run_commission` for the server-derived open
  period only (a finalized month is refused before the transaction
  opens); rollback in `finally` so a mid-read throw cannot leave rows;
  the before-and-after row-count tripwire on runs, results, lines and the
  level map, logged loudly on mismatch; the ephemeral run id used only to
  filter the in-transaction reads and returned NOWHERE (the projection
  response carries `projection: true`, the banner, the timestamp, and no
  run id at any nesting). `fn_finalize_run` is never referenced.
- Role fencing: `commission-report` requires `["staff", "admin"]`;
  `billing-console` requires `["staff"]` only, re-read from the database
  per call. **Ruling on the OQ5 widening: WANTED, exactly as scoped.**
  The dashboard spec's OQ5 accepted default is "admin and staff both,
  member refused" for the READ-ONLY dashboard, and that is what the code
  widens; the billing console is a write surface (schedules, pauses,
  cancellations, execute) and correctly keeps the refund screen's
  staff-only default per the "admin is not a super-user" block. The
  fence sits on the right line; do not widen billing-console.

## 5. Execute gating and production inertness

- Gate order verified in `actionRunExecute`: compile-time switch, limit
  parse, `dispatch_required` (explicit live or simulated, never
  defaulted; the page's select ships on a blank "choose..." option and
  the server refuses regardless), tick-date shape, `engine_not_ready`
  via `to_regprocedure` on the three-argument tick AND the verdict door
  AND the seam column (honest pre-deploy refusal), then for live only:
  `not_configured` (missing key) and `live_credentials_missing` (no
  seeded sandbox credentials). Engine refusals surface verbatim as
  `engine_refused`. Every refusal on the write path is audited to
  `app.demo_staff_actions`.
- Neither function contains any statement that writes `app.sim_clock` or
  calls `app.fn_sim_clock_init` (swept; the only textual mention is the
  comment stating it is never called). Clock initialization remains the
  deploy-round operator's explicit act.
- The live verdict door refuses simulated attempts (probed, V3); the
  in-tick reconciler resolves simulated strands only (segment 18: the
  sim tick passed through two live strands without touching them); the
  seed function refuses unknown members (V5).

## 6. Guardrail sweep

All five gate files: zero em or en dashes, zero Unicity terminology,
acronyms expanded with keys, persona headers correct. The
staff-operations page contains a clearly-marked local mock for
file-preview whose refusal strings mirror the server's; the page is not a
gate and the server enforces every rule independently (verified in
section 5).

## 7. Findings

No HIGH. No MEDIUM. LOW notes, none gating:

- **L1.** The worker's list-search recovery (`/payments/list?limit=100`)
  matches by metadata over the most recent page only; acknowledged in
  code, comfortable at pilot scale, revisit when renewal volume nears a
  page.
- **L2.** On a live success, `fn_apply_attempt_result` first stamps the
  simulator's placeholder reference (SIM- prefix, simulated true) and
  `fn_record_live_verdict` immediately overwrites it when a payment id is
  passed. If the retrieve ever returned a succeeded payment without a
  string `payment_id`, the placeholder would survive with a stale
  simulated label. The worker always passes the id; noted for the reader.
- **L3.** `billing_runs.clock_source` remains hardcoded 'simulated' even
  on live-dispatch runs. The honest reading is "the clock TABLE drives
  business dates" (true in S2 minimal), but a future reader may misread
  run history; a follow-up migration may relabel or document.
- **L4.** `run_preview` is unaudited (reads are not audited by design);
  the preview is the one read that prices money. Acceptable under the
  read/write audit rule; noted because the mandatory-preview discipline
  is enforced by the page only, while the server enforces everything
  else. A server-side previewed-recently check is a possible S3 nicety,
  not a requirement.
- **L5.** `EXECUTE_ENABLED` is a compile-time constant. Fine for this
  build; the deploy round should know the off switch is a redeploy, not
  a data flag.

## 8. DEPLOY ROUND: YES, with this checklist

Migration 029's A1 to A7 are adopted as written, with these verifier
additions. The finale A2/A3 run is HOWARD's to press, by name; nothing in
the deploy round presses it for him.

- **A1 to A7** (029's footer): seed check, the limit-2 live run, the rail
  photograph (zero challenges, connector Braintree, no_three_ds), the
  write-back with real payment ids and integer-cent matches, the bridge
  and commission dry run, the staggered remainder with FM1 held, the
  strand drill.
- **V-A8, byte-compare (charter duty):** the deployed source of
  billing-console AND commission-report byte-compared against the repo
  copies at the gated hashes (section 9) before A2 runs.
- **V-A9, the clock act:** `app.sim_clock` initialization (date and
  engine_epoch) is a recorded, deliberate operator step; BEFORE the first
  tick, run the console preview and confirm the epoch floor holds (no
  phantom multi-year backlog is priced; the inert banner is replaced by
  a real gather of plausible size).
- **V-A10, apply hygiene:** after applying 028 and 029, re-run the RLS
  advisors and the finalized-months checksum (the S1 apply's before-and-
  after read) since `fn_billing_tick` was replaced; confirm the pg_cron
  poll still refuses (schedule disabled) and that scheduled runs, when
  ever enabled, are unlimited by construction (9B rule 5).
- **V-A11, role fence live probe:** an admin token against
  billing-console answers 401; the same token against commission-report
  answers a read; a member token answers 401 on both.
- **V-A12, projection hygiene live probe:** row counts of the four
  commission tables identical before and after one projection call; the
  response JSON contains no run id at any nesting.
- **V-A13, the card rule:** confirm during A3 that the sandbox pair plus
  fixed CVC 123 behaves as assumed on the real Braintree sandbox; any
  CVC enforcement surprise stops the round (the worker's assumption is
  compile-time).
- **Standing conditions carried forward:** the QA (completeness) gate
  must pass on these same hashes before the deploy round ships; 028 and
  029 freeze at cloud apply; the simulation fixtures never ship.

## 9. Artifacts graded (SHA-256)

```
28493480b6faa1bcebd9357d160a9b45c0cacde6fa1f78ef151c2215efc0f366  db/migrations/028_run_limit.sql
1524202cbfe95ef7429b7a1474f872d6e94c936cb631d7b83672fa42cde55e5f  db/migrations/029_live_dispatch_seam.sql
f24d25771f3d8ddc33bcafe184280bf7e86b5282c80357a5de550b2e44b4f40b  functions/billing-console/index.ts
980a4bc792f6996a26307ce8751c6da1e904ebd3c93c0c6c8187bded7f42c436  functions/commission-report/index.ts
249d6b95b2949bb7b16948b497e740624444dcda3e6e40c48af2d31768357cda  www/staff-operations.html
e35ad8a1360c28d0b3f6262b784b7b5b9a86d03b80edd946784ba749de71b409  db/subscriptions/sql/17_limit_run.sql
ba5e34e065bc1d1fda7712d6adfceba98648c9b58574cb43b3f6461bb874142d  db/subscriptions/sql/18_live_seam.sql
8367b33f99cfc18df1832ddbd68865e4c6f085eed0e262317050f4a40d5a24e0  db/subscriptions/sql/30_proof_battery.sql
a11a44ecefec378d021aaa94b3cf96822b1579af65db8ec89e58e329c52afda9  docs/STAFF-COMMISSION-DASHBOARD-SPEC.md
59533a2c172940a178c3204d70e5950578e3ea0a02c794cd455de12c16465569  docs/SUBSCRIPTION-ENGINE-SPEC.md (v1.2)
```

## 10. What was not probed

The live HyperSwitch rail itself (the deploy round's A2 to A7 own it, by
design); the Edge Functions running under Deno (code-read only; the rig
proves the SQL they call); pg_cron (absent in the rig and the cloud);
concurrent worker invocations (the sweep-then-charge design and the
verdict door's terminal-outcome guard bound the damage: a doubled verdict
write is refused by the attempt outcome guard, and a doubled charge
requires the rail to have no record, which a prior charge contradicts;
still, run the strand drill A7 twice in the deploy round for comfort);
the member-portal redesign commit (4cb15c5), which is outside this gate's
scope.
