# Copy Audit, every word the site shows a human

Date: 2026-08-15
Auditor: orvanna-writer (content writer)
Instruction: Howard, "audit everything... nothing sloppy."
Scope: `www\index.html`, `www\shop.html`, `www\product.html`, `www\team.html`,
`www\login.html`, `www\staff.html`, `www\js\catalog.js`, `site\index.html`,
`site\js\app.js`. Hypertext Markup Language (HTML) comments included.
Nothing was edited. This is a report.

Acronym key used below: Personal Volume (PV), Sales Volume (SV), Commissionable
Volume (CV), Team Volume (TV), 3-D Secure (3DS), Strong Customer Authentication
(SCA), Quality Assurance (QA), Chief Information Officer (CIO).

Plain path to this file:
`C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\docs\qa\COPY-AUDIT-2026-08-15.md`

---

## 1. The one-paragraph verdict

The writing is good. The error and status copy on the live payment rail is the
best writing on the property, and the catalog prose is the second best. What is
wrong is almost entirely one thing: a layer of checkout copy written when
payments were pretend is still shipping on top of a real processor. Five
sentences on the shop and one on the staff console now say things that are not
true, and two of them sit on the highest-stakes screens the site has. A second
problem is invisible to a reader but not to a reader who presses View Source:
the production HTML carries a discarded fake leadership team and nine comments
that quote Howard by name and narrate the build.

Total findings: 7 HIGH, 11 MEDIUM, 11 LOW. Zero direct-selling compliance
findings.

---

## 2. Severity-ranked findings

### HIGH

| # | File and line | The copy | Why it is wrong |
|---|---|---|---|
| H1 | `www\shop.html:390` | "Payments route through the Orvanna orchestration layer in a later phase." | Flatly false, and it is static markup with no id, never touched by any script, so it prints on **every** successful confirmation, directly under a receipt for a payment that just went through that layer. |
| H2 | `www\shop.html:306` | "Demonstration checkout: any values continue, including empty fields." | False in live mode and it invites a shopper to skip fields on a real rail. The provider's secure form rejects empty and invalid card data, and this same page has a branch (`liveAfterSdk`, 2039-2049) whose only job is to report those rejections. Static, always visible on the payment step. |
| H3 | `www\shop.html:214` | "Express options place the order in one step. Credit card opens the card form." | Both halves false. Apple Pay, Google Pay and PayPal are disabled in live mode (2328-2334) and place nothing. The card form no longer waits for a button; it opens automatically when the account step completes (1577-1628). |
| H4 | `www\staff.html:149` | "No bank approval is possible on this path." | False and operationally dangerous. The keyed telephone path does raise 3DS on this rail. The same page ships bank-approval chrome (270-276), an `awaitAuth` panel (182-186), and a status line at 1512-1515 that tells the agent card 4000 0000 0000 2503 "raises the approval screen". It also contradicts its own sibling bullet at line 138, which correctly says the bank "usually will not ask". |
| H5 | `www\shop.html:461` | "Test mode: this is a simulated approval and no money moves." | The approval is not simulated. It is a real 3-D Secure 2 challenge served by a sandbox issuer through Braintree. This is the exact sentence the brief predicted: written for the simulated era, still shipping on the single screen where a shopper is most anxious. |
| H6 | `www\index.html:354-426` | 73-line HTML comment: "WRITER REFERENCE ONLY... Ruled by Howard 2026-08-14", containing four invented executives (Auren Vale, Liora Sen, Dorian Vesk, Maren Ostrey) with full bios. | Ships to production. Confirmed present in `deploy\dist\index.html:354`. Anyone who views source on a page whose entire premise is "this team is real" finds an abandoned fake executive roster underneath it. |
| H7 | `www\shop.html:936, 1120, 1510, 1540, 1608, 1778, 1968, 2133`; `www\staff.html:881` | Nine comments quoting Howard verbatim and dating the build, e.g. `Howard, 2026-08-15: "i want to move to next phase and it not be theater."`, "Howard hit that on 2026-08-15", "Howard caught the console still faking payments while the rail was live". | Ships to production (confirmed in `deploy\dist\shop.html`; `build_dist.py` copies files verbatim, it strips nothing). Names a private individual and narrates defect history in public source. The engineering reasoning in those comments is genuinely valuable and should be kept, in the repository, not in the deployed page. |

### MEDIUM

| # | File and line | Finding |
|---|---|---|
| M1 | `www\staff.html:263`, `:1814` | Footer says "no real members, orders, or charges". The top notice on the same page (line 41) says payments run on the live test rail and real order rows are written. One page, two answers. |
| M2 | `www\shop.html:389` | Default confirmation note "Demonstration checkout: no payment occurred and nothing will be charged." Overwritten on the live success path by `liveSuccessNote` (2303), so rarely seen, but it is the shipped default of the confirmation panel and false if it ever renders. |
| M3 | `www\shop.html:355, 486, 795` vs `www\staff.html` chips and `:869` vs `site\js\app.js` | Qualification unit mismatch across surfaces. The shop says "A qualified month needs 100 PV"; the portal and the staff meter say "100.00 SV". The staff console's own comment (847-850) records that this exact confusion was fixed on the meter, yet three sibling strings on that same panel still say PV: the qualified chip ("Qualified · 150 PV"), the not-qualified chip ("needs 50 PV more"), and `meterNote` at line 869 ("PV short of a qualified month"). |
| M4 | `site\js\app.js` throughout (897, 1159, 1269, 1194, 804) | Portal money carries no currency mark. Every figure goes through `fmt2`, which gives "114.00" and "20,669.20". Labels are inconsistent about supplying it: "Earned, dollars" (897), "Commission earned by month, United States dollars" (628), and nothing at all on the statement and company cards. The shop and the staff console both print "$". Two decimals is satisfied everywhere; currency is not. |
| M5 | `www\product.html:279`, `:284` | "Own it outright: one payment, yours for good." is a perpetual-ownership promise for hosted software, with no term, no license copy, and nothing in the system that expresses ownership. And "Full value $1,000.00. Subscribe and start for $100.00 this month." presents a reference price that exists nowhere except as a 10x anchor. |
| M6 | `www\product.html:73`, `:278` | "Renews monthly. Cancel anytime." Nothing in the demo cancels a subscription and no page tells a buyer how. |
| M7 | `www\js\catalog.js:67`, `:89` | "Prepares every filing on time, ready for your sign-off." and "Balances books to the cent, month after month." Absolute guarantees, against the charter rule that an agent may not guarantee. The long prose for both items is correctly hedged (211-221, 286-296); only the one-line blurbs overreach. |
| M8 | `www\team.html:300`, `www\index.html:153` | "built in gated phases over two days, August 13 to 14, 2026". Substantial work shipped 2026-08-15: real member sign-in, the 3DS challenge window, the whole checkout reshape. The team page's phase rail (349-374) also stops at "The property" and never mentions the live payment rail, which is now the most impressive thing on the property. |
| M9 | `www\shop.html:130, 147`; `www\staff.html:58, 61`; `site\js\app.js:13` | Member codes read `GW-`, a leftover of the Globex persona the pilot was named under before Orvanna (ROADMAP line 248; `COMP-PLAN-SPEC.md:17` still opens "Globex sells AI agents"). Every other visible identifier on the property is `ORV-`. A sharp reader asks what GW stands for and there is no answer. |
| M10 | `site\index.html:6, 44-48, 88` | Titled "Member Portal" with tabs "My Business / My Volume / My Rank / My Statement", but it requires the `admin` role and its "Viewing as" control opens any of the 1,000 accounts. The first-person framing describes a different tool than the one that is there. |
| M11 | `www\shop.html:1987` | "4000 0000 0000 2503 asks your bank for the passcode 1234 and then approves." Backwards: the bank asks the shopper. Also line 1986 "any three digit security code" wants a hyphen, "three-digit". |

### LOW

| # | File and line | Finding |
|---|---|---|
| L1 | `www\shop.html:462`, `www\staff.html:273` | `&mdash;` is an em dash (U+2014). House-rule breach. Both are placeholders that JavaScript replaces before the dialog is shown, so they are almost never seen, but the character ships. The only two dash breaches on the property. |
| L2 | `www\shop.html:2154`, `www\staff.html:1627` | The fallback outcome opens with a bare "Declined." One-word verdict in a copy set that is otherwise full-sentence and careful. The only place the voice drops. |
| L3 | `site\js\app.js:66, 1010, 1270` vs everywhere else | Percent style split: the shop, the console and the corporate pages write "5 percent"; the portal writes "80%", "10%", "12.22% of CV". |
| L4 | `www\staff.html:41`, `:190` | "play money". The only slang about money anywhere on the property; every other surface says "test mode" or "nothing is charged". |
| L5 | `www\team.html:402-408` | Footer "Learn" column drops "About us", which `index.html` and `shop.html` both carry. Same footer, two versions. |
| L6 | all pages, footer | Most footer links are inert `<span>` elements (Help center, Contact, Pricing, Open roles, Internships, Activation status, and so on). Acceptable for a demonstration, but nothing labels them, so a visitor who clicks one learns the site is a shell by accident rather than by design. |
| L7 | `www\product.html:80` vs `:84` | "100 PV" renders above the "Personal Volume (PV)" expansion in document order. First use on the page is unexpanded. |
| L8 | `site\js\app.js:837-839` | The Wire item dated 2026-07-07 announces the support chat, which actually shipped 2026-08-14. Backdated five weeks inside a record that carries dates. |
| L9 | `www\js\catalog.js:346`, `:137` | "revenue that compounds" and "You see recovered revenue" are the two strongest business-outcome claims in the catalog. Not income claims about the member program, but the closest the copy comes to promising a result. |
| L10 | `www\staff.html:153` vs `:167` | "Card on file" is disabled at runtime in live mode (942) with no reason shown, while the payment-link option immediately above it explains exactly why it is off. Two disabled options in one group, handled two ways. |
| L11 | `www\staff.html:238` | "Your agents come online within 48 hours" is hardcoded. True today, because the console always sends `activation: 'standard'` (1487), but the sentence is not derived from the order it describes. |

---

## 3. House rules

| Rule | Result |
|---|---|
| No em dashes or en dashes | **2 breaches**, both `&mdash;` entities: `shop.html:462`, `staff.html:273`. No literal U+2014 or U+2013 anywhere in any audited file, including the stylesheets. |
| Every acronym expanded on first use, per page | **1 breach**: `product.html` renders "100 PV" at line 80, above the expansion at line 84. Everything else is clean and several pages are exemplary: `staff.html:41` front-loads PV, SV and TV in the top notice; `team.html:39` opens with "artificial intelligence (AI) agents"; `staff.html:138` expands Strong Customer Authentication (SCA); `shop.html:297` expands 3-D Secure (3DS); `index.html:149` expands Chief Information Officer (CIO). Minor watch item: `site\js\app.js:781` prints "L1", "L2" as segment labels, though the screen-reader table underneath spells "Level 1". |
| Money always to two decimals | **Clean.** `fmtMoney` (catalog.js:380) and `fmt2` (app.js:58) both force two decimals with no exceptions. Every hardcoded amount in markup is written "$0.00". |
| Plain English, no jargon | **Clean, and unusually so.** No unexplained processor vocabulary reaches a reader. Where a technical idea is unavoidable it gets a plain gloss: "3-D Secure (3DS), the card networks' identity check" (shop:297); "Strong Customer Authentication (SCA), the European rule that requires these approvals" (staff:138); "Commission earned by month, United States dollars" (app.js:628). |
| Currency legible | **Fails in the portal only**, see M4. |

---

## 4. Voice

One voice overall, and a good one: short sentences, second person, concrete
nouns, precise verbs, no hype words. But five authoring rounds are detectable,
and one of them is the problem.

- **Round A, corporate** (`index.html`, `team.html`). Confident and essayistic,
  comfortable with a longer lead sentence. "Agents do not sell themselves."
- **Round B, catalog prose** (`catalog.js:132-373`). The strongest writing on the
  property. All 18 entries hold the same three-beat structure: the cost of the
  problem, what the agent actually does on a Tuesday, where the human keeps
  authority. "It proposes journal entries; it does not invent them."
- **Round C, simulated checkout** (`shop.html:214, 250, 306, 389, 390`).
  Breezy, present tense, "Demonstration checkout", "Nothing is charged". **This
  is the seam.** Every high-severity truthfulness finding on the shop is a Round C
  sentence that survived the rail going live. It is the only round that reads as
  a different, earlier product.
- **Round D, live payments** (2026-08-14 and 15, throughout `shop.html` and
  `staff.html`). Careful and specific. Always names the order number, always
  states whether anything was charged, never claims an outcome it does not have.
- **Round E, portal boards** (`app.js:350-865`). A distinct editorial register:
  dateline capitals, "CLOSED AND FINAL", newspaper cadence. Deliberate and it
  works, but it is visibly a different pen from the shop.

Recommendation: rewrite Round C in Round D's voice and the property reads as one
piece. Rounds A, B, D and E can stay as they are.

---

## 5. Believability

- **No Latin filler anywhere.** The Phase 4 brief called for it; none survived.
- **No TODO, FIXME, WIP or placeholder prose.** The only "XXXXXX" strings are
  intentional order-number input placeholders.
- **No fabricated business figures.** The three metrics on `index.html` all check
  out against the system: 12 specialist agents (6 domain + 6 support in
  catalog.js), 1,000 members, 6 months of locked statements. The call to action
  at line 434 correctly says "twelve specialist agents, plus the Manager Agent
  and three ready-made packs".
- **Synthetic contact data is honestly built.** `staff.html:383-408` uses the
  555-01XX fictional telephone block and tags the panel "demonstration data".
- **Two believability leaks, both in markup, both HIGH**: H6 (the discarded fake
  leadership roster) and H7 (nine comments naming Howard and narrating the
  build).
- **One naming leak, MEDIUM**: M9, the `GW-` member codes from the retired
  Globex persona.
- **The 404 page is clean** and carries no leaks.

---

## 6. Direct-selling compliance

**No findings.** This part of the property is genuinely well done.

- No income claims of any kind. Not on the corporate pages, not in the shop, not
  in the portal, not in The Wire. The qualification meter states a rule ("A
  qualified month needs 100 PV") and never predicts an outcome.
- No fabricated social proof. No testimonials, star ratings, named customers,
  logos, press quotes or member counts presented as endorsement. The one number
  that could be mistaken for proof, "1,000 members", is labelled synthetic in the
  footer of every page.
- No pressure language. No countdowns, no scarcity, no "act now", no "limited
  time", no "only X left".
- Commission figures appear only behind a sign-in, only as historical synthetic
  data, and the portal footer states "no real earnings" on every render
  (`app.js:1318-1323`).
- **Worth specific credit**: `app.js:392-408`. The Gate Board deliberately
  refuses to print "Blocks your rank" beside a person's name, refuses to imply
  anyone cost the reader money, and cites the compensation plan for why ("all CV
  pays upline", section 5). That is a copy decision most real compensation
  portals get wrong.

The one adjacent item to watch is M5, the "Full value $1,000.00" reference
price. That is a pricing-presentation question rather than a direct-selling one,
but it is the kind of reference-price claim a regulator asks about.

---

## 7. Error and status messages

The least-reviewed copy in most products is the best copy in this one. I walked
every failing path.

**Every terminal failure states that nothing was charged. No exceptions found.**

Shop: 1841, 1862, 1928, 1945, 2047, 2117, 2120, 2123-2124, 2148-2152,
2154-2155, 2196-2197, 2247-2249, 2411, 2432, 2440, 2488, 2548.
Staff: 1250, 1445, 1457, 1498, 1523, 1567, 1616, 1620, 1624, 1627, 1654, 1736,
1855, 1871, 1891, 1905.

Specific strengths:

- **Waiting states never claim an outcome.** `shop.html:1722`, "Finishing your
  order, one moment. Nothing is charged until this settles." The comment above it
  (1713-1719) explains that the shopper may have approved, failed, or closed the
  window, and only the server knows which. That is the right instinct written
  down.
- **The four distinct endings** (`liveOutcomeMessage`, 2112-2156) tell apart a
  broken security check, a refused identity check, an approved identity check
  followed by a card decline, and a plain decline. Each gets its own sentence and
  its own next step. Most checkouts show one generic decline for all four.
- **Order lookup** is exactly right: "No order with that number, which means
  nothing was charged for it." It answers the question behind the question.
- **The abandonment path** re-asks the server rather than assuming
  (`shop.html:1837`, `staff.html:1451`), because the shopper may have approved a
  second before giving up.
- **Rate limiting** is calm and lets the server own the wording. `login.html`
  reads the `Retry-After` header and turns it into "Try again in about 45
  seconds" or "about 2 minutes" (140-145), and never leaks whether a username
  exists (130-138). The checkout's five-creates-a-minute limit surfaces through
  `friendlyError` with a "Nothing was charged" fallback.
- **The resume view** never tells anyone to press Back, and says why in the
  markup comment (407-417): the widget navigates with a history replace, so the
  entry Back would return to no longer exists.

Two nits only, both LOW: the bare "Declined." (L2), and `shop.html:2117`
"nothing about your card is wrong", which is a slightly contorted way of saying
the check failed rather than the card.

---

## 8. The worst sentences, with replacements

1. **`www\shop.html:390`**
   Now: "Payments route through the Orvanna orchestration layer in a later phase."
   Use: "This payment ran through the Orvanna orchestration layer in test mode. No real money moved."

2. **`www\shop.html:306`**
   Now: "Demonstration checkout: any values continue, including empty fields."
   Use: "Test mode checkout. The card form belongs to the payment provider and it checks what you type. Nothing real is ever charged."

3. **`www\staff.html:149`**
   Now: "Key the card here, telephone order. key it while they read; repeat back the last four only. No bank approval is possible on this path."
   Use: "Key the card here, telephone order. Key it while they read; repeat back the last four only. Their bank can still ask them to approve on their own device, and only they can do that."

4. **`www\shop.html:461`**
   Now: "Test mode: this is a simulated approval and no money moves."
   Use: "Test mode: this is a real approval step running on a test card. No money moves."

5. **`www\shop.html:214`**
   Now: "Express options place the order in one step. Credit card opens the card form."
   Use: "Card is the live test rail in this phase. The express marks are drawings and are switched off."

6. **`www\product.html:279`**
   Now: "Own it outright: one payment, yours for good."
   Use: "Buy it once: a single payment instead of a monthly subscription."

7. **`www\staff.html:263`**
   Now: "Orvanna staff console · demonstration data · no real members, orders, or charges"
   Use: "Orvanna staff console · demonstration data · real test orders, test cards only, no real charge"

8. **`www\shop.html:1987`**
   Now: "4000 0000 0000 2503 asks your bank for the passcode 1234 and then approves."
   Use: "4000 0000 0000 2503 makes your bank ask for a passcode, which is 1234, and then approves."

---

## 9. Suggested order of work

1. The six Round C sentences (H1, H2, H3, H5, plus M2 and M11). One editing pass,
   one file, biggest truth gain per minute.
2. H4, the staff console's "No bank approval is possible". Highest real-world
   stakes of anything in this report: it is the one line that could put a call
   taker in the wrong place during a live approval.
3. H6 and H7, the markup leaks. A deletion job, not a writing job, but decide
   first where the engineering reasoning in those comments should live instead.
4. M1, M3, M4, the three consistency splits (charged-or-not, PV-or-SV,
   dollars-or-not).
5. Everything else at leisure.

Two items are Howard's calls rather than a writer's: **M9** (whether the `GW-`
member codes get reissued as `ORV-`, which is a data question, not a copy one)
and **M10** (whether the portal is renamed to match what it is, or gated to match
what it says).
