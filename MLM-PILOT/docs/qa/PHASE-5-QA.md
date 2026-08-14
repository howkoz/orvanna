# Phase 5 QA: orvanna.io Live on the Public Internet

Graded by: mlm-qa (the builder never grades its own work)
Date: 2026-08-14
Scope: the LIVE deployment at https://orvanna.io (GitHub Pages, repo
github.com/howkoz/orvanna.io, custom domain, HTTPS enforced), assembled by
`deploy\build_dist.py` (www to the domain root, site to /portal/, five
cross-folder links rewritten, new CNAME / .nojekyll / 404.html / README.md /
.gitignore). This is the network-level acceptance pass: every claim below comes
from raw HTTP requests (curl) against the public internet, plus a fresh shallow
clone of the public repository. No browser-pane tools were used; the manager's
visual and console checks are attached separately.

## Verdict (read this first)

**PASS.** 24 rows executed: 24 PASS, 0 FAIL, 0 HIGH or MEDIUM defects, 2 LOW
notes. One row (the bare-apex plain-HTTP redirect) started the pass PENDING
behind an edge cache and resolved to PASS during the session, watched live. The site is live, every page and asset serves 200 over
HTTPS, all five rewritten links land where the builder promised, zero stale
../site/ or ../www/ references survive, the branded 404 works, the live origin
reads the Supabase demo views, Enroll is a non-clickable pill everywhere it
appears, and the public repository contains exactly the built site and nothing
else, byte-identical to deploy\dist.

Acronym key: QA (Quality Assurance), HTTP (Hypertext Transfer Protocol),
HTTPS (Hypertext Transfer Protocol Secure), DNS (Domain Name System),
CNAME (Canonical Name, the domain file GitHub Pages uses), REST
(Representational State Transfer), JS (JavaScript), CSS (Cascading Style
Sheets), SVG (Scalable Vector Graphics), URL (Uniform Resource Locator),
GMT (Greenwich Mean Time), CRLF (Carriage Return Line Feed), PV (Personal
Volume), CDN (Content Delivery Network).

## Method note

Promises first: the checklist below was written from the Phase 5 brief and
`deploy\build_dist.py` BEFORE any live request was made. Every row was then
executed with curl against https://orvanna.io. Link integrity was verified by
downloading all seven live HTML pages, extracting every href and src with a
Python scan, resolving each relative target against its page URL, and fetching
every unique target from the live origin. The Supabase probe used the anon key
extracted from the LIVE portal/js/app.js (not the local copy) with an Origin
header of https://orvanna.io. Repo hygiene came from a fresh shallow clone into
the session scratchpad; content equality with deploy\dist was proven by git
blob hashes after ruling out CRLF checkout noise. House-rule scans (dash
characters) ran on the live-fetched 404.html and README.md bytes.

## Checklist

### A. Availability over HTTPS (Phase 5 brief item 1)

| # | Item | Evidence | Grade |
|---|---|---|---|
| A1 | All nine page URLs return 200 | /, /index.html, /shop.html, /product.html?sku=payment, /product.html?sku=constellation (both skus taken from the LIVE js/catalog.js, which carries all 16), /login.html, /staff.html, /portal/, /portal/index.html: every one 200 over HTTPS, Server: GitHub.com | PASS |
| A2 | Root assets serve | /css/corporate.css, /css/shop.css, /css/staff.css, /js/catalog.js, /assets/favicon.svg, /assets/logo-header-dark.svg: all 200 | PASS |
| A3 | Portal assets serve | /portal/css/portal.css, /portal/js/app.js, /portal/assets/favicon.svg, /portal/assets/logo-final-primary.svg, /portal/assets/logo-header-dark.svg: all 200 | PASS |
| A4 | 404.html itself fetchable | direct GET /404.html: 200, 994 bytes, identical content to the builder's template | PASS |

### B. Redirects and domain (brief item 2)

| # | Item | Evidence | Grade |
|---|---|---|---|
| B1 | http to https on the apex | Enforcement ACTIVE and now complete: http://orvanna.io/index.html, /shop.html, and /portal/ answered 301 to their https URLs from the first probe. The bare path http://orvanna.io/ initially answered a cached 200 (x-origin-cache: HIT, Cache-Control max-age=600, expires 13:31:41 GMT), the CDN edge holding the pre-enforcement response; re-probed at 13:32:45 GMT, one minute after expiry, it now answers 301 Location: https://orvanna.io/ and the followed chain ends 200 at the https apex. Watched flip live during this pass | PASS |
| B2 | www over https lands on the site | https://www.orvanna.io/ answers 301 to https://orvanna.io/; followed chain ends 200 at the apex in one hop. GitHub redirects www to the apex when the CNAME file holds the apex, exactly as expected | PASS |
| B3 | www over http lands on the site | http://www.orvanna.io/ answers 301 to https://orvanna.io/ (scheme upgraded AND host collapsed in one hop), chain ends 200 | PASS |
| B4 | DNS shape | orvanna.io resolves to the four GitHub Pages anycast addresses (185.199.108-111.153); www.orvanna.io resolves as an alias of the apex | PASS |

### C. Link integrity on the live HTML (brief item 3)

| # | Item | Evidence | Grade |
|---|---|---|---|
| C1 | Every relative href/src on every page resolves 200 | All seven live pages downloaded (index, shop, product, login, staff, 404, portal/index); 19 unique relative targets extracted and fetched from the live origin: 19 of 19 answer 200, including the version-stamped ones (corporate.css?v=4.1 and ?v=4.5, catalog.js?v=4.1 and ?v=4.5, staff.css?v=4.5.1, portal.css?v=1.0.2, app.js?v=1.0.1) | PASS |
| C2 | Zero stale cross-folder references | Byte scan of all seven live pages: zero occurrences of "../site/" and zero of "../www/" anywhere | PASS |
| C3 | Rewrite 1 and 2: login.html and staff.html point into portal/ | login.html line 55: `window.location.href = 'portal/index.html'`; staff.html line 30: `<a class="console-link" href="portal/index.html">Member portal</a>`; neither file contains "site/" in any form | PASS |
| C4 | Rewrites 3 to 5: portal/index.html points up with ../ | Live portal/index.html carries exactly `href="../index.html"`, `href="../shop.html"`, `href="../staff.html"`; all three fetch 200 from /portal/ context | PASS |

### D. Behavior (brief items 4 and 5)

| # | Item | Evidence | Grade |
|---|---|---|---|
| D1 | login.html Continue goes to the portal | The page's only script block preventDefaults the form submit and sets `window.location.href = 'portal/index.html'`, with the comment stating Continue always opens the member portal | PASS |
| D2 | staff.html Member portal link goes to the portal | Same href confirmed in C3; target /portal/index.html serves 200 | PASS |
| D3 | Branded 404 on a nonsense path | GET /definitely-not-a-page-qa5: status 404, body is the branded page (title "Orvanna: page not found", contains "Back to the home page", link href="/" which serves 200, favicon /assets/favicon.svg which serves 200) | PASS |
| D4 | Branded 404 on a deep path too | GET /portal/nope/deep-qa5: status 404, same branded page | PASS |

### E. House rules on the NEW artifacts (brief item 6)

| # | Item | Evidence | Grade |
|---|---|---|---|
| E1 | 404.html: zero em or en dashes | Character scan of the live-fetched bytes: 0 U+2014, 0 U+2013 | PASS |
| E2 | README.md: zero em or en dashes | Character scan of the live-fetched bytes: 0 U+2014, 0 U+2013 | PASS |
| E3 | Acronyms expanded on first use | Neither artifact contains an unexpanded acronym: the 404 page's visible text carries none; README's "GitHub Pages" is a product name, not an acronym. Money format not applicable, neither file shows a figure | PASS |

### F. Supabase reachability (brief item 7)

| # | Item | Evidence | Grade |
|---|---|---|---|
| F1 | Live portal JS still points at the project | Live /portal/js/app.js contains exactly one Supabase URL: https://oiyibdczkokegaxkwulv.supabase.co, plus the anon key and the v_demo_* view names (members, tree, company, customers, member_months, customer_volume, statements) | PASS |
| F2 | REST probe with the live key returns data | GET rest/v1/v_demo_company?limit=1 with the anon key from the live bundle and Origin: https://orvanna.io: 200 with the February 2026 company row (run_id 7, 179 members paid). GET rest/v1/v_demo_members?limit=2: 200 with GW-000001 Kendall Marigold and GW-000002 Kai Eastbrook. The live origin can read the demo views | PASS |

### G. Enroll state (brief item 8, PERMANENT by Howard's decision)

| # | Item | Evidence | Grade |
|---|---|---|---|
| G1 | Enroll is a pill, never a link, on every nav that shows it | index.html, shop.html, product.html each render `<span class="nav-link is-soon" aria-disabled="true">Enroll<span class="soon-pill">soon</span></span>`: a span, not an anchor, so non-clickable by construction. Full-text census of all seven live pages: zero anchors containing "Enroll" anywhere; login, staff, portal, and 404 pages carry no Enroll control at all (their only other matches are lowercase enrolled_on data fields in staff.html's JS) | PASS |

### H. Repo hygiene (brief item 9)

| # | Item | Evidence | Grade |
|---|---|---|---|
| H1 | Public repo contains ONLY the built site | Fresh shallow clone of github.com/howkoz/orvanna.io: exactly 22 tracked files: 8 root pages/files (404.html, CNAME, README.md, index.html, login.html, product.html, shop.html, staff.html), .nojekyll, .gitignore, 2 root assets, 3 root css, js/catalog.js, and 6 portal files. Pattern sweep for db, duckdb, sqlite, csv, sql, py, spec, agent, seed, marker: the only hit is README.md itself. No database dumps, no specs, no agent files, no seed data, no .build-marker | PASS |
| H2 | Deploy metadata correct | CNAME contains exactly "orvanna.io"; .gitignore contains exactly "/.build-marker"; .nojekyll present and empty; .build-marker absent from the clone | PASS |
| H3 | Repo content is byte-identical to deploy\dist | Recursive diff with carriage-return stripping: identical (the raw diff hits were CRLF checkout artifacts from git autocrlf, not content). Git blob-hash cross-check on index.html, js/catalog.js, portal/js/app.js: repo hash equals hash-object of the dist file on all three | PASS |

## Findings

### HIGH (broken or missing deliverable)

None found.

### MEDIUM (works but off-spec or fragile)

None found.

### PENDING, RESOLVED DURING THE PASS

1. **Bare-apex plain-HTTP redirect lagged the edge cache, then landed (B1).**
   HTTPS enforcement was provably ON from the first probe: http requests to
   /index.html, /shop.html, and /portal/ all 301ed to https. Only
   http://orvanna.io/ (the bare path, with or without a query string) still
   returned 200, and its headers showed why: x-origin-cache: HIT with
   Cache-Control max-age=600, an edge-cached copy of the pre-enforcement
   response stamped to expire at 13:31:41 GMT. Re-probed at 13:32:45 GMT: 301
   Location: https://orvanna.io/, chain ends 200 at the https apex. Zero action
   needed; recorded so the mechanism (per-path CDN cache rollover after the
   enforcement toggle) is on file for any future domain change.

### LOW (cosmetic, bookkeeping)

1. **File-count phrasing in the brief versus reality.** The brief said "22
   tracked files plus .gitignore" (which would total 23). The actual repo holds
   22 tracked files WITH .gitignore among them (21 site files plus .gitignore).
   The substance of the promise, only the built site and nothing else, holds
   exactly; recorded so the next gate counts against the real census.
2. **Version-stamp spread is now public.** The live bundle serves
   corporate.css and catalog.js under two different cache stamps (?v=4.1 from
   shop and product, ?v=4.5 from staff). Both resolve to the same underlying
   file and both 200, so nothing is broken; noted because a future hotfix that
   edits either file must bump BOTH stamps (or unify them) to avoid a stale
   cached copy on half the pages. Same class as the login.html stamp note from
   the Phase 4C.2 hotfix delta.

## Out of scope, verified elsewhere

Rendering, console cleanliness, contrast, and interactive behavior of the live
pages were graded by the manager's browser pass (attached separately); this
gate deliberately stayed at the network layer per its brief. The Phase 4C.2
report and its two deltas remain the deepest functional record of the shop and
portal behavior, all of which shipped unchanged into this bundle (proven
byte-identical in H3).

## Verdict

**PASS.** 24 rows: 24 PASS, 0 FAIL. The one item that started PENDING (the
bare-apex http redirect) resolved to a clean 301 during the session, watched
live at cache expiry. Phase 5's promise is delivered: orvanna.io is live over
HTTPS with every page, asset, and rewritten link serving correctly from GitHub
Pages, the branded 404 in place, the portal reading Supabase from the public
origin, Enroll permanently a non-clickable pill, and a public repository that
exposes exactly the 22 built files and nothing from the private side. Phase 5
closes on this gate when mlm-verifier also stamps PASS, per the standing rule.
