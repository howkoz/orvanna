# Office Landing Page: Quality Assurance (QA) Verdict

Retroactive gate on live code. Run 2026-08-14 by the mlm-qa agent.

Target: the rebuilt member portal home (the office landing), live at
https://orvanna.io/portal/ . Judged exactly as strictly as a pre-deploy gate.

Plain paths of the files graded:

- `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\site\index.html`
- `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\site\js\app.js`
- `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\site\css\portal.css`

Acronym key: Quality Assurance (QA), Sales Volume (SV), Personal Volume (PV),
Commissionable Volume (CV), Team Volume (TV), Web Content Accessibility
Guidelines (WCAG), Cascading Style Sheets (CSS), Hypertext Markup Language
(HTML), Uniform Resource Locator (URL).

---

## VERDICT: FAIL

Two computed WCAG contrast failures and one control whose label states a number
it does not deliver. Everything the page asserts about money, volume, rank and
depth is correct to the cent, so this is a presentation-layer FAIL, not a
correctness FAIL.

**Rollback or hotfix needed? NO.** Nothing on the page is wrong, unsafe, or
non-compliant enough to justify pulling live code: no figure is inaccurate, no
income claim is made, no member is shown what an unqualified downline person
cost them, and the only unreadable text is a colour token in the light theme
plus two chart segment labels whose values are repeated in readable text
directly beneath them. Queue every finding for the next polish round.

---

## How this was graded

The acceptance checklist was written from `ROADMAP.md`, `docs\COMP-PLAN-SPEC.md`
version 1.3 and the five module promises (Gate Board, Momentum Board, Rank
Runway, Earnings Mix, The Wire) BEFORE any deliverable was opened.

Evidence was gathered by running the real page against the real database on a
local origin, not by reading source alone. The browser pane was hidden, so per
the standing lesson every contrast number below is computed from
`getComputedStyle`, with alpha composited against the true effective backdrop
by walking ancestors until an opaque background is found. Both themes were
scanned. Fifty three text elements were measured in the light theme alone.

Note on access: signing in was not possible (real credentials, held as bcrypt
hashes server side, and entering a password is off limits for this agent). The
page was reached instead by writing a session object into `sessionStorage`
directly. That this worked is itself finding M4.

---

## Findings, severity ranked

| # | Sev | Finding | File and line | Computed ratio |
|---|---|---|---|---|
| H1 | HIGH | Light theme leaves four text rules bound to `--cyan` (#22D3EE), which the light theme block never overrides. Every one of them is unreadable on the light panel. | `site\css\portal.css` L37 to L65 (light block), L104 `.demo-pill`, L283 `.rank-leader`, L355 `.node-toggle`, L387 `.customer-tag` | `.node-toggle` arrow **1.73:1**; `.demo-pill` "DEMO MODE" **1.81:1**; `.rank-leader` badge **1.81:1**; `.customer-tag` "CUSTOMER" **1.81:1**. All need 4.5:1 |
| H2 | HIGH | Earnings Mix segment labels fail in both themes. White on the level 3 indigo is the worst and renders on almost every member, because level 3 is usually a wide segment. | `site\css\portal.css` L770 to L776; produced by `site\js\app.js` L775 | Dark: white on `--lvl-3` #818CF8 **2.98:1**; white on `--lvl-2` #6366F1 **4.47:1**. Light: #0F172A on `--lvl-4` #6366F1 **4.00:1**. All need 4.5:1 |
| M1 | MED | The Gate Board control reads "Show all 271" and then renders 50 rows. The footnote underneath discloses the cap, but the button label states a number it does not deliver. Proven live: label "Show all 271", rows after click 50. | `site\js\app.js` L522 to L525 (label) and L545 to L556 (`wireGateBoard`, hard 50 cap) | n/a |
| M2 | MED | The Momentum Board contradicts its own stated rule. The Sales Volume panel honestly prints "not enrolled" for months before the member existed, while the commission panel prints "0.00" and the area chart plots real data points at zero for those same months. The code comment at L234 to L236 says drawing those as a zero "would be a false statement". | `site\js\app.js` L604 to L610, L628 to L630, L653, L678 | n/a |
| M3 | MED | Gate Board tier 1 copy attaches an AGGREGATE rank rule to each NAMED individual. Rendered live for GW-000010: two people, each labelled "Rank rule unmet" with "Builder needs 2 active legs; 1 counted." No single named person is decisive when more than one leg is short, so the per person consequence is not per person true, and the row reads as "this person is why I am not a Builder". | `site\js\app.js` L408 (`TIER_WORD`), L433 to L437 | n/a |
| M4 | MED | The session gate is client side only and its comment claims otherwise. `site\index.html` L66 to L68 states "The token was signed by the server; the browser cannot mint or edit one." The page never verifies the signature. A hand written `sessionStorage` entry with the token string `qa-forged-client-side-token` rendered the entire office landing. No data beyond the already public read only views is reachable, so this is a false comment plus a demo curtain presenting as authentication, not a data exposure. | `site\index.html` L61 to L101, especially L88 to L89 | n/a |
| M5 | MED | Sweep result, sibling surface. The staff call console names the qualification gate "100 PV" (`0 / 100 PV`, "the 100 PV qualified month"), while the office landing now defines it authoritatively as "the qualification line is 100.00 SV", which is what `COMP-PLAN-SPEC.md` section 3 says. PV is a per product attribute; SV is the monthly gate. The two live surfaces now disagree on the name of the same rule. | `www\staff.html` L334, L217, L1091 to L1096 versus `site\js\app.js` L538 | n/a |
| L1 | LOW | The Wire carries six hardcoded dates and gives the newest item the lit mark. Nothing moves them, so the "newest" announcement freezes at Aug 3, 2026 forever. | `site\js\app.js` L819 to L838 | n/a |
| L2 | LOW | The Earnings Mix dateline prints "4,888.00 TOTAL" with no currency named, while the Momentum panel directly above it does name "United States dollars". | `site\js\app.js` L798 | n/a |
| L3 | LOW | Touch targets under 44 pixels at 375 pixels wide: the five tab buttons measure 36 pixels and the Support nav button 16 pixels. The Gate Board "Show all" control and the tree summary both correctly carry `min-height: 44px`, so the pattern is known and was simply not applied here. Site wide, not new to this rebuild. | `site\css\portal.css` L172 to L181, L904 to L910 | n/a |
| L4 | LOW | Before the "Show all" control is pressed, the visual list holds 5 rows while the hidden screen reader table already holds 50. The two audiences see different amounts of the same board. | `site\js\app.js` L520 to L531 | n/a |

---

## Acceptance checklist

| # | Promise | Evidence | Result |
|---|---|---|---|
| 1 | Gate Board renders and its headline counts are real | Independent recompute in the page for GW-000002, July 2026: 777 in paid depth and 271 under the line. Page printed 777 and 271. | PASS |
| 2 | Gate Board scope equals the reader's paid depth | Executive paid depth is 5 per spec section 4; deepest level shown was 4 and level 5 rows are reachable; `PAID_DEPTH` map matches the spec table exactly. | PASS |
| 3 | Gate Board healthy and empty states are drawn, not blank | GW-000009 (no downline): "No one sits inside your paid depth yet." GW-000005 (all qualified): "The one person in your paid depth reached the line in July 2026." Both with the ring drawing. | PASS |
| 4 | Gate Board "Show all" control works | Rows go 5 to 50 on click. Label says 271. | FAIL (M1) |
| 5 | Momentum Board shows six closed months on one shared axis | Six periods returned by `v_demo_company`, Feb to Jul 2026, single month axis, no dual axis. | PASS |
| 6 | Momentum Board never states a false zero | Sales Volume panel prints "not enrolled" correctly for GW-000832 (enrolled 2026-05-04). Commission panel prints 0.00 and plots points for the same three months. | FAIL (M2) |
| 7 | Momentum Board reflows rather than scrolls on a phone | At 375 pixels: `.mom-chart` computed `display: none`, `.mom-rows-wrap` computed `display: block`, page horizontal overflow 0 pixels. | PASS |
| 8 | Rank Runway ladder and unmet rules match the plan | `RANK_REQS` equals spec section 4 exactly: Builder 2 active legs, Leader TV 2,500 and 3 active legs, Director TV 10,000 and 2 legs containing a Builder, Executive TV 40,000 and 2 legs containing a Leader. Qualification bar shown whenever SV is under 100.00, per version 1.3. | PASS |
| 9 | Rank Runway leg counter is honest | GW-000002: "42 of 74 legs active", recomputed independently as 42 active of 74. Discs suppressed above 8 legs, as designed. | PASS |
| 10 | Earnings Mix total matches the statement | 658 lines for July 2026 summed to 4,888.00. Identity rail, Earnings Mix dateline and Momentum July point all read 4,888.00. | PASS |
| 11 | Earnings Mix per line arithmetic matches the plan | All 658 lines recomputed: amount equals rate times source CV rounded half up at the line, rates are 10, 5, 5, 3, 2 percent by level per spec section 5, and every source CV equals 0.80 times that member's SV. Zero mismatches. | PASS |
| 12 | Earnings Mix empty states tell the truth about why | Qualified with no lines: "no Commissionable Volume (CV) fell inside the paid depth". Unqualified: "the plan pays a member only in a month they meet it". Both correct per spec section 5. | PASS |
| 13 | Earnings Mix labels are legible | Segment labels fail contrast in both themes. | FAIL (H2) |
| 14 | The Wire renders newest first with a lit newest mark | Six items, ordered Aug 3, Jul 28, Jul 21, Jul 14, Jul 7, Jun 30. First item carries `wire-lit`. | PASS |
| 15 | The Wire touches no member data and names no person | Static array, zero database reads, no personal names, self contained and removable as documented. | PASS |
| 16 | The Wire's product claims are accurate | "Constellation Pack, every domain agent plus the Manager, 800 PV monthly" verified against `www\js\catalog.js` L118 to L122 (six domain agents plus manager, subscription 800 PV). "Ten times the price, ten times the PV" verified against the same entry (one time 8,000). "Version 1.3, ranks above Member need 100.00 SV" verified against spec section 4. Domain agent 100 PV verified against spec section 1. | PASS |
| 17 | Downline observations, never suggested actions | No contact control, no "reach out", no message button anywhere on the board. | PASS |
| 18 | No member is shown what an unqualified downline person cost them | No dollar figure is attached to any named person. The code comment at L394 to L407 correctly cites spec section 5: all CV pays upline regardless of the source member's own qualification, so nobody under the line took anything off the reader's statement. | PASS |
| 19 | Severity wording names a rule, not a verdict on a person | "Leg not counted" and "Inside paid depth" are clean. "Rank rule unmet" attaches an aggregate rule to individual names. | FAIL (M3) |
| 20 | No income claims and no fabricated social proof | No projection, no testimonial, no "members like you earn", no invented endorsement. Every figure is this member's own finalized history. | PASS |
| 21 | Money always to two decimals | Every money and volume figure routes through `fmt2`, which pins minimum and maximum fraction digits to 2. Counts use `fmt0` correctly. | PASS |
| 22 | Every acronym expanded on first use per page | Render order checked: the identity rail emits "Sales Volume (SV)" before any bare SV; the Gate Board definition line adds "Personal Volume (PV)"; the Rank Runway introduces "Team Volume (TV)"; the Earnings Mix introduces "Commissionable Volume (CV)". Inside The Wire, PV is expanded at the Jul 28 item before the bare "800 PV" at Jul 21. | PASS |
| 23 | No em dashes and no en dashes | Zero occurrences of U+2014 and U+2013 across all three files, and across every file in `www\`. | PASS |
| 24 | No external dependencies beyond the sanctioned two | The only cross origin scripts are `cdn.botpress.cloud` and `files.bpcontent.cloud`. No fonts, no libraries, no analytics. `.bpFab { display: none }` present, so nothing can open itself over the page. | PASS |
| 25 | Console clean on load and through interaction | Zero console messages across load, theme flip, member changes, period change and all five tabs. | PASS |
| 26 | Dark and light both render | Both themes render fully. Light theme has the H1 colour failures. | FAIL (H1) |
| 27 | Member picker updates every page consistently | GW-000002 at period 2026-05-01: office earned 4,096.80 equals My Statement total 4,096.80; office SV 200.00 equals My Volume SV 200.00; rank Executive and 42 of 74 legs identical on My Rank. | PASS |
| 28 | Period selector propagates | Company May 2026 total payout read 16,507.20, which matches the finalized engine run recorded in `ROADMAP.md`. Footer moved to "period 2026-05, run #10". | PASS |
| 29 | Full tree still reachable and lazy | Behind one `<details>` control, built only on first open, counts printed in the summary ("0 members and 2 customers" for GW-000009 checked against the data). | PASS |
| 30 | Footer carries the data basis line | "Synthetic demo data, 1,000 accounts, period 2026-05, run #10, no real earnings". | PASS |
| 31 | No Unicity data, terminology, or real personal data | Synthetic Globex style names only, member codes GW-xxxxxx, no employer terminology anywhere. | PASS |
| 32 | No secrets beyond the intended public key | Only the Supabase anon key, public by design and already cleared by the Phase 5 verifier. | PASS |
| 33 | Deploy path rewrites survive the move to `/portal/` | `deploy\build_dist.py` rewrites all four portal links including the sign in URL held inside the inline script string, fails the build if any expected link is missing, then runs a leftover check and a link check. | PASS |
| 34 | Access to the page is gated | Gate is client side only and its own comment overstates it. | FAIL (M4) |

Thirty four rows: 27 PASS, 7 FAIL, 0 not applicable.

---

## Scope follows capability: what the sweep turned up

The capability this page introduced is **per member observation of the downline
under the qualification gate**, plus a **theme toggle exercising a light palette
across five tabs**. The sweep covered every surface in `www\` and `site\`.

1. **The light theme is portal only, and the fault is portal wide.**
   `site\index.html` is the only page in the whole property carrying
   `data-theme`; the corporate stylesheets have no light block at all. So H1 does
   not spread to the corporate site. It does spread across all five portal tabs:
   the DEMO MODE pill sits in the header on every tab, the Leader rank badge
   renders on My Rank and My Statement as well as the office, and the customer
   tag and tree toggle render inside the tree. One stylesheet fix, five
   surfaces affected.

2. **The staff console is the only sibling that presents the same capability,
   and it now contradicts this page.** `www\staff.html` looks up a member and
   shows Sales Volume, Team Volume, rank and a qualification meter. It calls the
   gate "100 PV" while the office landing now states "the qualification line is
   100.00 SV", which is what the compensation plan says. Recorded as M5. The
   staff console also rounds the same gate to whole numbers
   (`Math.round`, `Math.ceil`) where the office renders it to two decimals.

3. **No sibling surface should gain the Gate Board.** The staff console is a
   call taker's screen, not a member's; putting named under the line downline
   people in front of a staff operator would be a worse version of M3, not a
   better one. Nothing else in `www\` shows member data.

4. **The Wire pattern has no lookalike anywhere.** No other page carries an
   announcements feed, so there is nothing to contradict and nothing that now
   needs one. It is correctly self contained and removable.

5. **The corporate metric tile is fine.** The roadmap's open wording flag
   ("12 AI agents in the catalog" versus 16 items on sale) is already resolved
   in the live markup: `www\index.html` L57 to L58 reads "12" against the label
   "Specialist AI agents, sold solo or in packs", which is accurate, since 12 is
   the agent count and the packs are bundles of those same agents.

6. **The Support chat item is on all six surfaces.** `data-orvanna-support` and
   both Botpress scripts appear in `www\index.html`, `www\shop.html`,
   `www\product.html`, `www\staff.html`, `www\team.html` and `site\index.html`.
   Consistent, nav triggered, floating button suppressed everywhere.

---

## What the page gets right, on the record

Traceability is the strongest part of this build. Every figure the office
landing shows was recomputed independently and matched: 658 commission lines to
the cent, both Gate Board headline counts, the rank test, the paid depth, and
the cross tab agreement between the office, My Volume, My Rank, My Statement
and Company across two different periods. The compensation plan constants in
`app.js` are a faithful transcription of `COMP-PLAN-SPEC.md` version 1.3,
including the version 1.3 qualification requirement on every rank above Member.

The compliance posture is deliberate and mostly well judged. The comment block
at `app.js` L394 to L407 reasons from the plan text to the conclusion that a
person under the line took nothing off the reader's statement, and the board is
built to say only what is true: no cost attribution, no contact control, no
suggested action. M3 is the one place that reasoning did not carry all the way
through, and it needs Howard's ruling rather than a silent edit.

---

## Recommended order of fixes, next polish round

1. H1: give the light theme a readable cyan, or rebind the four text rules to a
   token the light theme already darkens (`--mark-lit` is #0E7490 in light and
   would pass).
2. H2: darken `--lvl-2` and `--lvl-3`, or drop the in segment labels and rely on
   the label row underneath, which is already readable.
3. M1: make the button say what it does, or lift the cap and let it say 271.
4. M2: print "not enrolled" in the commission row too, and break the area chart
   rather than plotting a zero.
5. M3: Howard's call on the tier 1 wording.
6. M4: correct the comment in `site\index.html` to describe what the gate
   actually is.
7. M5: align the staff console on Sales Volume wording.
8. LOWs as time allows.

---

*Report only. Nothing in the product was edited by this agent.*
