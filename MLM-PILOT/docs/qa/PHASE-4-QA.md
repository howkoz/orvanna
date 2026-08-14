# Phase 4 QA: Full Web Property (Corporate Site + Fake Login + Member Portal)

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-13
Scope: `www\index.html` (corporate, round 2 glow redesign), `www\login.html` (fake login),
`site\` (member portal, five tabs, live Supabase data), house rules, hygiene.
Server under test: http://localhost:9120 serving the MLM-PILOT root (corporate at /www/,
login at /www/login.html, portal at /site/).

## Method note (read this first)

The Browser pane was HIDDEN for this entire session, so screenshots were not used at all.
Every visual and behavioral claim below was verified through the live document object
model (DOM), the console log, and the network request log of the running page at
localhost:9120. Where the checklist asked for a click, the click was dispatched on the
real element in the page (the actual anchor or the actual form submit), so the genuine
handlers and hrefs were exercised; coordinate-based synthetic clicks do not land while
the pane is hidden, and one such attempt on the Sign In link was a no-op before the
DOM-dispatched click navigated correctly. The hidden pane turned into an asset for one
row: with document.hidden true, the hero animation reported isRunning false, which is a
live proof of the pause-when-hidden promise, not just a code read.

Acronym key: DOM (Document Object Model), SV (Sales Volume), TV (Team Volume),
CV (Commissionable Volume), AI (Artificial Intelligence), CSS (Cascading Style Sheets),
JS (JavaScript), QA (Quality Assurance), REST (Representational State Transfer).

## Checklist

### A. The journey

| # | Item | Evidence | Grade |
|---|---|---|---|
| A1 | /www/ loads | GET /www/index.html 200, title "Orvanna", all sections in DOM | PASS |
| A2 | Nav Sign In goes to login.html | Sign In anchor href="login.html"; dispatched click landed on /www/login.html, title "Orvanna Sign In" | PASS |
| A3 | Continue with EMPTY fields reaches the portal | Both fields blank, form submitted; landed on http://localhost:9120/site/index.html, portal booted with live data | PASS |
| A4 | Continue with JUNK credentials reaches the portal | username "xyz!!junk", password "not-a-password-123"; same landing, portal title confirmed | PASS |
| A5 | Back link returns to the corporate page | .login-back href="index.html"; click landed on /www/index.html | PASS |
| A6 | login.html is the ONLY route from /www/index.html into /site/ | Full href census of the live page: #top, #overview x2, login.html, mailto x2. Zero hrefs contain "site/". Exactly one login link | PASS |

### B. Corporate page (round 2 glow redesign)

| # | Item | Evidence | Grade |
|---|---|---|---|
| B1 | All sections present | DOM section census: nav, hero, overview, pillars, origin, technology, leadership, cta, footer | PASS |
| B2 | Metrics 12 / 1,000 / 6 | Live tiles: "12 AI agents in the catalog", "1,000 Members in the network", "6 Months of locked statements" | PASS |
| B3 | Three pillars | Domain Agents, Support Agents, The Network | PASS |
| B4 | Origin section | #origin band present with story copy, pull quote, and orbital art | PASS |
| B5 | Technology section | #technology band with Orchestration, Vault, Secure Payments features | PASS |
| B6 | Four leaders | Auren Vale, Liora Sen, Dorian Vesk, Maren Ostrey | PASS |
| B7 | Contact band + footer | #cta band with Contact us button; footer with four link columns, contact block, legal line | PASS |
| B8 | support@orvanna.io as the mailto | Two anchors, both href="mailto:support@orvanna.io" (contact band button + footer) | PASS |
| B9 | Shop and Enroll are styled dead links | Both are SPAN elements (not anchors), class is-soon, aria-disabled="true", "soon" pill text | PASS |
| B10 | Legal synthetic-data line | Footer: "Orvanna is a demonstration company. All data is synthetic. No real earnings, products, or offers exist." Same line on login.html | PASS |
| B11 | Favicon and logo load | Network log: assets/favicon.svg 200, assets/logo-header-dark.svg 200; in-page fetch of both returned 200 | PASS |
| B12 | Zero console errors | Console log empty across index, login, and repeat loads | PASS |
| B13 | Zero horizontal scroll at 1280 | Viewport 1280x800: scrollWidth 1265 = clientWidth 1265, no element extends past the right edge | PASS |
| B14 | Zero horizontal scroll at 375 | Viewport 375x812: scrollWidth 375 = clientWidth 375, zero overflowing elements | PASS |
| B15 | Hero canvas pauses when hidden | LIVE: with document.hidden true (pane hidden), window.OrvannaHero.isRunning() returned false. Code: visibilitychange handler stops/starts, start() refuses while hidden | PASS |
| B16 | Hero reduced-motion static path | Code: reduce.matches renders one static frame (drawStatic) and never starts the loop; change listener flips modes live; a static frame is also painted when loaded in a hidden tab. Verified in code only; the pane cannot emulate the reduced-motion media query | PASS |
| B17 | Reveals never leave content invisible without JS | corporate.css gates opacity:0 behind the html.js class ("Hidden state is gated behind html.js"); the js class is added by an inline script, so no-JS renders everything visible. Reduced-motion block also forces reveals visible. Live: html.js present, 11 reveal blocks wired | PASS |

### C. Portal (spot re-verification against live data at /site/ on the 9120 server)

| # | Item | Evidence | Grade |
|---|---|---|---|
| C1 | Default member GW-000002, period 2026-07 | Picker shows "GW-000002 · Kai Eastbrook"; period select value 2026-07-01; six periods Feb through Jul | PASS |
| C2 | July company totals 20,669.20 / 284 paid / run #12 | Company tab: "Total payout 20,669.20", "14.97% of CV", "Members paid 284 of 1,000 accounts", "run #12". Independent REST call to v_demo_company returned the identical rows (status 200) | PASS |
| C3 | Unqualified member GW-000014 shows the unpaid note | Statement for GW-000014 (Casey Pinegrove): Total earned 0.00, NOT QUALIFIED pill, note "Unpaid this month: this member was not qualified (Sales Volume (SV) under 100.00) in July 2026..." | PASS |
| C4 | Period switch to February changes footer run to #7 | After switching the select to 2026-02-01: footer reads "period 2026-02 · run #7"; Company tab shows run #7, payout 11,906.00, matching the roadmap figure | PASS |
| C5 | All five tabs render | My Team (tree with 971 downline), My Volume (chart + four stat cards), My Rank (requirements list), My Statement (658 lines totaling 4,888.00 for GW-000002), Company (totals, rank distribution, trend). No spinner left behind on any tab | PASS |
| C6 | Zero console errors | Console log empty after full tab walk, member switch, and period switch | PASS |
| C7 | Footer data-basis line format | "Synthetic demo data · 1,000 accounts · period 2026-07 · run #12 · no real earnings", exactly the app.js template | PASS |
| C8 | Six-month payout trend matches roadmap | Chart labels 11,906.00 / 13,434.00 / 14,636.00 / 16,507.20 / 17,749.20 / 20,669.20 equal the ROADMAP v1.3 refinalized run list, and the live REST rows match to the cent | PASS |

### D. House rules (all three HTML files, both CSS files, app.js)

| # | Item | Evidence | Grade |
|---|---|---|---|
| D1 | Zero em or en dashes | Python character scan of all six files: 0 em (U+2014), 0 en (U+2013) in every file | PASS |
| D2 | Acronyms expanded on first use | Hero: "artificial intelligence (AI) agents" before the AI metric label; hero script comments expand the application programming interface and central processing unit references; portal copy expands Sales Volume (SV), Team Volume (TV), Commissionable Volume (CV) in each section before short forms appear | PASS |
| D3 | Money: 2 decimals + thousands separators | fmt2() uses toLocaleString en-US with min/max 2 fraction digits; rendered proof: 20,669.20, 167,800.00, 4,888.00, 11,906.00 | PASS |
| D4 | Relative paths only | Grep for file:// and C:\ across www and site: zero real references (one code comment mentions file:// storage blocking, not a path). All hrefs/srcs relative | PASS |
| D5 | No external CDN dependencies | Grep for http(s) src/href: only SVG xmlns namespace attributes (not network requests) and the Supabase REST base in app.js, which is the sanctioned data call. Network log shows only localhost + Supabase | PASS |

### E. Hygiene

| # | Item | Evidence | Grade |
|---|---|---|---|
| E1 | ROADMAP currency | Phase 4 status cell in the phases table is BLANK and "Next small step" still says "NOW RUNNING: Phase 4, mlm-site-builder builds the portal", while reality is: portal built and approved by Howard, corporate site round 2 built, fake login built and ruled on. The roadmap is behind the work | FAIL |
| E2 | www\assets self-contained | Folder holds favicon.svg + logo-header-dark.svg only; both referenced by the pages, both served 200, no external asset references inside them | PASS |
| E3 | launch.json entry mlm-pilot-www points at the MLM-PILOT root | `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\.claude\launch.json`: mlm-pilot-www runs python http.server 9120 with --directory C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT (the root, correct) | PASS |
| E4 | No staff toggle present (Phase 4.5 is future scope, not yet promised) | site\index.html header: brand, member picker, period select, theme button only. Correctly absent | PASS |

## Defects

### HIGH (broken journey, wrong data, console error)

None found.

### MEDIUM (off-spec, fragile)

1. **ROADMAP is behind reality (E1).** The Phase 4 status cell is blank and the
   "Next small step" section still describes the portal build as now running. Reality:
   the portal is built and Howard approved it, the corporate site round 2 glow redesign
   is built, the fake login page is built per Howard's ruling. One roadmap edit fixes it:
   fill the Phase 4 status cell and rewrite the next-step paragraph.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\ROADMAP.md`

### LOW (cosmetic, forward-looking)

1. **Login redirect is wired for today's layout, not Phase 5's.** login.html sends the
   member to `../site/index.html`. That is correct on the 9120 root server, but the
   roadmap says Phase 5 serves `www\` at the domain root with the member office at
   `/portal/`, at which point `../site/` resolves to nothing. Expected rewiring work at
   Phase 5; flagged so it is on the Phase 5 checklist, not discovered in production.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\login.html` line 55
2. **Nav "Learn" link is hard-coded active.** The is-active class on the Learn link never
   moves as the visitor scrolls other sections. Cosmetic on a single-page site.
   File: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\www\index.html` line 21

## Verdict

**PASS.** 36 rows executed: 35 PASS, 1 FAIL (E1, MEDIUM severity), 0 NOT APPLICABLE,
0 HIGH defects standing. The journey Howard ruled on this evening works end to end
exactly as specified: Sign In opens the fake login, anything or nothing plus Continue
reaches the member portal, Back returns, and the login page is the single doorway from
the corporate site into the member area. The portal's live numbers match the finalized
v1.3 runs to the cent, verified against Supabase independently of the page.

Condition on the pass: fix the ROADMAP staleness (MEDIUM 1) before Phase 4 is declared
closed on paper; it is a five-minute edit and the only row that failed.
