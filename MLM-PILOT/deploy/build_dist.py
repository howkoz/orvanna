"""Phase 5 deploy builder for orvanna.io.

Assembles a publishable static package under deploy/dist/:
  - www/*  -> dist/          (corporate site at the domain root)
  - site/* -> dist/portal/   (member portal at /portal/)
Rewrites the five cross-folder links so everything is relative and works
both at https://orvanna.io/ and at any preview URL with a path prefix.

2026-08-16 (stabilization Step 0): the build now also stamps svg assets,
asserts that every local css/js/svg reference carries a ?v= cache stamp,
fails on the owner's name outside the team page, and fails on secret-shaped
strings anywhere in the output. See the individual gate functions for why
each exists.

Run:  py deploy/build_dist.py
"""
import hashlib
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent   # MLM-PILOT
DIST = ROOT / "deploy" / "dist"
MARKER = DIST / ".build-marker"
DOMAIN = "orvanna.io"

REWRITES_ROOT = [
    # (file under dist root, old, new)
    ("login.html", "../site/index.html", "portal/index.html"),
    ("staff.html", "../site/index.html", "portal/index.html"),
]
REWRITES_PORTAL = [
    # The login link must be rewritten BEFORE the bare index.html rule, because
    # "../www/login.html" would otherwise survive the earlier substitutions and
    # trip the leftover check at the end of the build.
    ("portal/index.html", "../www/login.html", "../login.html"),
    ("portal/index.html", "../www/index.html", "../index.html"),
    ("portal/index.html", "../www/shop.html", "../shop.html"),
    ("portal/index.html", "../www/library.html", "../library.html"),
    ("portal/index.html", "../www/staff.html", "../staff.html"),
]

NOT_FOUND_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Orvanna: page not found</title>
<link rel="icon" type="image/svg+xml" href="/assets/favicon.svg">
<style>
  body { margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
         background:#0F172A; color:#E2E8F0; font-family:'Segoe UI',Arial,sans-serif; text-align:center; }
  .card { padding:48px 32px; }
  h1 { font-size:15px; letter-spacing:.35em; text-transform:uppercase; color:#818CF8; margin:0 0 14px; }
  p  { margin:0 0 26px; color:#94A3B8; font-size:15px; }
  a  { display:inline-block; padding:12px 26px; border-radius:8px; background:#4F46E5; color:#FFFFFF;
       text-decoration:none; font-size:14px; letter-spacing:.08em; }
</style>
</head>
<body>
<div class="card">
  <h1>Page not found</h1>
  <p>That address does not exist on orvanna.io.</p>
  <a href="/">Back to the home page</a>
</div>
</body>
</html>
"""

README = """# orvanna.io

Static site for Orvanna: the corporate pages at the root and the member
portal under /portal/. Published with GitHub Pages.

Orvanna is a demonstration company; see the disclaimer in the site footer.
This repository holds built output. The source of truth lives in a private
repository; edits made here directly will be overwritten by the next build.
"""


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def copy_tree(src: Path, dst: Path) -> None:
    # _partials/ holds source fragments (the canonical navigation block) that
    # the drift lint below compares pages against. They are inputs to the
    # build, not pages, so they must not ship: nav.html would otherwise land
    # in dist/_partials/ and its relative links would trip the link check.
    shutil.copytree(src, dst, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns("_partials"))


def rewrite(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        fail(f"expected link not found in {path.name}: {old}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def link_check() -> list:
    """Every relative href/src in every html file must resolve to a file in dist."""
    problems = []
    pattern = re.compile(r"""(?:href|src)=["']([^"'#?]+)[^"']*["']""")
    for page in DIST.rglob("*.html"):
        text = page.read_text(encoding="utf-8")
        for target in pattern.findall(text):
            if target.startswith(("http://", "https://", "mailto:", "data:", "//", "javascript:")):
                continue
            base = DIST if target.startswith("/") else page.parent
            resolved = (base / target.lstrip("/")).resolve()
            if not resolved.exists():
                problems.append(f"{page.relative_to(DIST)} -> {target}")
    return problems


ASSET_VERSION_RE = re.compile(r"\?v=[0-9A-Za-z._-]+")

# 2026-08-16: the stamp now covers .svg as well as .css and .js. The logo was
# redesigned on 2026-08-15 and shipped at 19:06, and returning visitors kept
# seeing the cached old one, because svg references carried no version stamp
# at all. Scalable Vector Graphics (SVG) files are cached exactly like
# stylesheets, so they need exactly the same treatment.
STAMPABLE_SUFFIXES = (".css", ".js", ".svg")

# Reference targets that leave the site or are not fetchable files. These are
# skipped by the stamping, the stamp assertion, and nothing else.
EXTERNAL_PREFIXES = (
    "http://", "https://", "mailto:", "data:", "//", "javascript:", "tel:", "#",
)

# Any href/src whose target ends in .svg with no query string. Group 1 is the
# attribute plus opening quote, group 2 the target, group 3 the closing quote.
SVG_BARE_REF_RE = re.compile(r"""((?:href|src)=["'])([^"'?#]+\.svg)(["'])""")

# Any href/src at all, full attribute value captured, for the assertion pass.
ANY_REF_RE = re.compile(r"""(?:href|src)=["']([^"']+)["']""")


def stamp_assets() -> str:
    """Rewrite every ?v= asset query to a hash of the actual asset bytes.

    WHY THIS EXISTS, and it is not a nicety. The pages hand-carried a version
    string, and it sat at 5.2 while shop.css was rewritten three times on
    2026-08-15. Because the URL never changed, every browser that had visited
    before kept serving itself the OLD stylesheet from cache. One of those
    rewrites was the fix that lifts the bank-approval chrome above the payment
    frame; with the stale sheet it is painted behind it and is invisible. So a
    fix could be correct, deployed, and provably working for a new visitor
    while reaching nobody who had been to the site before. The HTML expires in
    ten minutes and the assets did not, which is the worst of both.

    Hand-maintained version strings fail this way every time, because the
    person changing the stylesheet is never the person remembering the stamp.
    The build already hashes every file to print a digest it used for nothing,
    so the honest fix is to spend that hash: the stamp is derived from the
    content, which means it changes when, and only when, the content does.
    """
    assets = sorted(
        p for p in DIST.rglob("*")
        if p.is_file() and p.suffix.lower() in STAMPABLE_SUFFIXES and ".git" not in p.parts
    )
    digest = hashlib.sha256()
    for p in assets:
        digest.update(p.relative_to(DIST).as_posix().encode())
        digest.update(p.read_bytes())
    stamp = digest.hexdigest()[:12]

    stamped = 0
    added = 0

    def add_stamp_to_bare_svg(match: "re.Match") -> str:
        # 2026-08-16: svg references in the pages carry no ?v= at all, so the
        # replace pass above never touches them. Rather than hand-editing the
        # reference in every page, the build ADDS the stamp here. Local targets
        # only; external URLs are left alone.
        nonlocal added
        prefix, target, quote = match.groups()
        if target.startswith(EXTERNAL_PREFIXES):
            return match.group(0)
        added += 1
        return f"{prefix}{target}?v={stamp}{quote}"

    for page in DIST.rglob("*.html"):
        text = page.read_text(encoding="utf-8")
        new_text, hits = ASSET_VERSION_RE.subn(f"?v={stamp}", text)
        new_text = SVG_BARE_REF_RE.sub(add_stamp_to_bare_svg, new_text)
        if new_text != text:
            page.write_text(new_text, encoding="utf-8")
        stamped += hits
    print(f"asset cache stamp: ?v={stamp} applied to {stamped} references, "
          f"added to {added} bare svg references")
    return stamp


def assert_version_stamps() -> None:
    """Every local stylesheet, script, and svg reference must carry a ?v= stamp.

    Added 2026-08-16. The stamping pass above can only REWRITE a stamp that is
    already there (except for svg, where it adds one). A stylesheet or script
    reference written without ?v= deploys silently and then serves stale from
    every returning visitor's cache; that is exactly how the 2026-08-15 z-index
    fix reached only new visitors. So after stamping, an unstamped local
    reference is a build failure, not a warning.
    """
    problems = []
    for page in sorted(DIST.rglob("*.html")):
        if ".git" in page.parts:
            continue
        text = page.read_text(encoding="utf-8")
        for ref in ANY_REF_RE.findall(text):
            if ref.startswith(EXTERNAL_PREFIXES):
                continue
            path_part = ref.split("?", 1)[0].split("#", 1)[0]
            if not path_part.lower().endswith(STAMPABLE_SUFFIXES):
                continue
            if "?v=" not in ref:
                problems.append(f"{page.relative_to(DIST).as_posix()} -> {ref}")
    if problems:
        for p in problems:
            print(f"  unstamped reference: {p}")
        fail(f"{len(problems)} local asset reference(s) carry no ?v= cache stamp; "
             "they would deploy cache-stale for returning visitors")
    print("stamp assertion: every local css/js/svg reference carries ?v=")


# The one allowed public location for the owner's name (dist-relative posix
# paths). Decided 2026-08-16 after the third recurrence of the name leaking
# into the public build: the team page, which tells the build story, is the
# single place it belongs. DOCUMENTATION\ is not copied into dist (the build
# copies www/ and site/ only, verified 2026-08-16), so it needs no entry here.
# index.html added 2026-08-16: the homepage founder teaser is deliberate site
# content under Howard's 2026-08-14 ruling that the real team, himself included,
# tells the build story on the site. Comments and dated quotes elsewhere are
# still leaks and still fail the lint.
NAME_ALLOWLIST = {"team.html", "index.html"}
NAME_LINT_TERMS = ("koziara", "howard")


def name_lint() -> None:
    """Fail the build if the owner's name appears outside the team page.

    Added 2026-08-16, third recurrence of this finding. Orvanna is presented
    as its own company; the owner's real name in shop pages, consoles, or
    scripts breaks that and has had to be swept out three times. The Step 0
    sweep removes the current stragglers; this lint keeps them from returning.
    Case-insensitive, scans every html and js file that ships.
    """
    problems = []
    for page in sorted(DIST.rglob("*")):
        if not page.is_file() or ".git" in page.parts:
            continue
        if page.suffix.lower() not in (".html", ".js"):
            continue
        rel = page.relative_to(DIST).as_posix()
        if rel in NAME_ALLOWLIST:
            continue
        text = page.read_text(encoding="utf-8", errors="ignore")
        for lineno, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            for term in NAME_LINT_TERMS:
                if term in low:
                    problems.append(f"{rel}:{lineno}: '{term}': {line.strip()[:90]}")
                    break
    if problems:
        for p in problems:
            print(f"  name leak: {p}")
        fail(f"{len(problems)} owner-name reference(s) outside the allowed team page; "
             "sweep them (Step 0) or, if genuinely intentional, add the page to "
             "NAME_ALLOWLIST with a dated note")
    print("name lint: owner name confined to the team page")


# Secret shapes that must never ship in the public build. Added 2026-08-16.
# Deliberately NOT matched: the Supabase anon key (a JSON Web Token starting
# eyJ, public by design) and the HyperSwitch publishable key (pk_snd_, public
# by design; the lookbehind below refuses to match snd_ when preceded by a
# word character or underscore, which is what keeps pk_snd_ safe).
SECRET_PATTERNS = (
    (re.compile(r"sk_(?:test|live)_[0-9A-Za-z]{8,}"), "Stripe secret key"),
    (re.compile(r"(?<![0-9A-Za-z_])snd_[0-9A-Za-z]{8,}"), "HyperSwitch secret key"),
    (re.compile(r"SUPABASE_DB_URL"), "Supabase database connection variable"),
    (re.compile(r"service_role"), "Supabase service role marker"),
)
SECRET_SCAN_SKIP_SUFFIXES = (
    ".jpg", ".jpeg", ".png", ".gif", ".ico", ".webp",
    ".woff", ".woff2", ".ttf", ".otf", ".pdf",
)


def secret_scan() -> None:
    """Fail the build if any shipping file contains a secret-shaped string."""
    problems = []
    for page in sorted(DIST.rglob("*")):
        if not page.is_file() or ".git" in page.parts:
            continue
        if page.suffix.lower() in SECRET_SCAN_SKIP_SUFFIXES:
            continue
        rel = page.relative_to(DIST).as_posix()
        text = page.read_text(encoding="utf-8", errors="ignore")
        for pattern, label in SECRET_PATTERNS:
            m = pattern.search(text)
            if m:
                # Print the shape and location, never the matched value itself.
                problems.append(f"{rel}: {label} (matches {pattern.pattern})")
    if problems:
        for p in problems:
            print(f"  secret shape: {p}")
        fail(f"{len(problems)} secret-shaped string(s) in the public build")
    print("secret scan: no secret-shaped strings in the build")


# ---------------------------------------------------------------------------
# CHROME LINTS
# ---------------------------------------------------------------------------
# Added 2026-08-17, from docs/CORPORATE-CHROME-CONTRACT.md. Hardened the same
# day after the verifier and the quality assurance gate both found holes.
#
# WHY THESE EXIST. Nine corporate pages each carried a hand-written top
# navigation. Every one was pasted and then edited on its own, so they drifted:
# the Library, Plan and Conductors links vanished from four pages, four
# different theme controls grew, and the Support button did nothing on four
# pages. The owner noticed by walking the site, which is the expensive way to
# find it. Correcting it once fixes today; these lints are what keep it fixed,
# because the person editing a page is never the person remembering the other
# eight.
#
# The chrome now has three single sources and a lint for each:
#   www/_partials/nav.html         markup      -> nav_drift_lint
#   www/_partials/theme-boot.html  pre-paint   -> theme_boot_lint
#   www/css/site-chrome.css        presentation-> chrome_css_lint
# and a fourth lint, page_registry_lint, asserts that no page can quietly opt
# out of any of them.

# Every corporate page, mapped to the href its active navigation item must
# carry. None means the page is not one of the navigation's own destinations
# and correctly marks nothing active.
#
# This is a REGISTRY, not a convenience list. page_registry_lint below fails
# the build if a page ships that is in neither this mapping nor the exclusion
# set, which is what stops a brand new page from arriving unlinted. The
# verifier proved that hole on 2026-08-17 by adding a pricing.html with a
# mangled navigation: the build printed "9 corporate pages match" and exited 0.
# Every page marks exactly one item active. Where the page is not itself one
# of the nine destinations, it marks the section it belongs to, the way a
# printed contents page marks the chapter rather than the leaf.
CORPORATE_PAGES = {
    "index.html":         "index.html",
    "shop.html":          "shop.html",
    "product.html":       "shop.html",     # a product page is inside the shop
    "team.html":          "team.html",
    "faq.html":           "index.html",    # the footer files the questions under Learn
    "comp-plan.html":     "comp-plan.html",
    "conductor.html":     "conductor.html",
    "library.html":       "library.html",
    "library-agent.html": "library.html",  # a detail page is inside the library
}

# The cart is the ONLY permitted addition to the canonical navigation, and it
# is permitted on these two pages only. Contract section 2, rule 3.
CART_PAGES = {"shop.html", "product.html"}

# The sign-in areas, excluded by name by the owner. They keep their own chrome
# and no chrome lint applies to them.
NAV_LINT_EXCLUDED = {"login.html", "staff.html", "staff-operations.html"}

# Pages this script itself writes, which have no site chrome by design.
BUILD_GENERATED_PAGES = {"404.html"}

# DOCUMENT PAGES. Self-contained documents that happen to be served from the
# site. They deliberately carry no site chrome, because they are not sections
# of the site: they are things a reader is sent a link to, saves to a desktop,
# opens with no network, and prints.
#
# This class exists so that "no chrome" is a REGISTERED DECISION rather than a
# hole. Without it the only way to ship such a page would be to bolt a
# navigation onto a document, or to quietly widen the sign-in exclusion, which
# would hand the next person a loophole. Contract section 5A names the class.
#
# The defining property is self-containment, and document_page_lint below
# CHECKS it rather than trusting it. A document page that grew an external
# stylesheet would still print and still serve, but would break silently the
# moment somebody saved it and opened it offline, which is one of the three
# uses it exists for.
DOCUMENT_PAGES = {"plan-brochure.html"}

# What a self-contained page may never reference. Anything here means the file
# stops working the moment it leaves the server.
#
# REWRITTEN 2026-08-17, TWICE, and the second rewrite is the point.
#
# Round one was a blocklist of tags. The verifier probed it and got FIVE things
# past with exit 0: <iframe src>, <img srcset> (only src was covered), <object
# data>, an SVG <image href>, and an inline <script>. It also caught a false
# positive: an internal <use href="#id"> is a same-document reference and is
# how an inline drawing reuses a shape.
#
# Round two widened the blocklist. The verifier probed it again and got SIX
# MORE past: CSS image-set(), <feImage href>, <video poster>, <audio src>,
# <input type="image" src>, and <body background>, with sixteen further
# candidates failing by inspection. It also proved the false-positive fix did
# not work, diagnosed to the character: ["']? sat OUTSIDE the lookahead, so the
# engine matched zero quote characters and then tested (?!#) against the quote
# itself.
#
# THE REAL FINDING WAS THE SHAPE: a blocklist of tags cannot converge, because
# the set of ways to fetch something is open-ended and grows with the platform.
# So this is now an ALLOWLIST of what may appear in a URL-bearing attribute:
#   - a same-document fragment (#...)      an inline drawing reusing a shape
#   - a data: URI                          already inline, fetches nothing
#   - mailto: and tel:                     not fetches
#   - an absolute link on <a href>         a reader choosing to leave
#   - xmlns                                a namespace name, never fetched
# Everything else fails, whether or not anyone thought of it in advance.

# Attributes that can cause a fetch. The allowlist is applied to their values.
URL_ATTR_RE = re.compile(
    r"""<(?P<tag>[a-zA-Z][\w:-]*)\b(?P<attrs>[^>]*)>""", re.S)
URL_ATTR_PAIR_RE = re.compile(
    r"""\b(?P<name>src|srcset|href|xlink:href|data|poster|background|action|"""
    r"""formaction|cite|longdesc|manifest|profile|usemap|codebase|archive)"""
    r"""\s*=\s*(?P<q>["'])(?P<val>.*?)(?P=q)""", re.S | re.I)

# A value that fetches nothing from outside this file.
SELF_CONTAINED_VALUE_RE = re.compile(
    r"""^\s*(?:\#|data:|mailto:|tel:)""", re.I)

# CSS that fetches. url(#...) is a same-document filter or gradient reference.
CSS_FETCH_RE = re.compile(
    r"""(?:\burl\(\s*(?!["']?\#|["']?data:)|\bimage-set\(|@import\b|@font-face\b)""",
    re.I,
)

# A document page carries no script at all. It is a document, and a script is
# the one thing that can make the same file behave differently depending on
# where it was opened from. The verifier got an inline <script> past the first
# version of this lint, which only looked for a `src` attribute.
DOCUMENT_SCRIPT_RE = re.compile(r"<script\b", re.I)

NAV_BLOCK_RE = re.compile(r'<nav class="nav-links"[^>]*>.*?</nav>', re.S)
# The cart is an <a> on product.html and a <button> on shop.html; both are the
# page's own existing markup, which the contract says to leave untouched.
NAV_CART_RE = re.compile(r'<(a|button) class="nav-cart".*?</\1>', re.S)
NAV_CART_PRESENT_RE = re.compile(r'class="nav-cart"')
NAV_COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
NAV_ACTIVE_CLASS_RE = re.compile(r'class="nav-link is-active"')
NAV_ARIA_CURRENT_RE = re.compile(r'\s*aria-current="page"')
NAV_ACTIVE_TAG_RE = re.compile(r'<(?:a|span) class="nav-link is-active"[^>]*>')
HREF_RE = re.compile(r'href="([^"]*)"')
WHITESPACE_RE = re.compile(r"\s+")


def root_pages() -> list:
    """Every HTML page at the root of the build, in a stable order."""
    return sorted(p.name for p in DIST.glob("*.html"))


def page_registry_lint() -> None:
    """No page may ship without being registered as linted or excluded.

    Verifier finding L-2, proved by probe 2026-08-17: the chrome lints walked a
    hardcoded list, so a new corporate page was unlinted until somebody
    remembered to add it by hand. That is exactly the memory these lints exist
    to replace. The build already knows what landed in dist; from here on it
    asserts that it recognises every one of them.
    """
    known = (set(CORPORATE_PAGES) | NAV_LINT_EXCLUDED
             | BUILD_GENERATED_PAGES | DOCUMENT_PAGES)
    unknown = [n for n in root_pages() if n not in known]
    missing = [n for n in CORPORATE_PAGES if not (DIST / n).is_file()]
    missing += [f"{n} (document page)" for n in DOCUMENT_PAGES
                if not (DIST / n).is_file()]
    problems = []
    for n in unknown:
        problems.append(
            f"{n}: ships in the build but is registered nowhere. Add it to "
            "CORPORATE_PAGES with the href its active item must carry, to "
            "NAV_LINT_EXCLUDED if it is a sign-in area with its own chrome, or "
            "to DOCUMENT_PAGES if it is a self-contained document that carries "
            "no chrome on purpose.")
    for n in missing:
        problems.append(f"{n}: registered but missing from the build")
    if problems:
        for p in problems:
            print(f"  page registry: {p}")
        fail(f"{len(problems)} page(s) are not covered by the chrome lints")
    print(f"page registry: {len(root_pages())} root pages, all covered "
          f"({len(CORPORATE_PAGES)} linted, {len(NAV_LINT_EXCLUDED)} sign-in areas "
          f"excluded, {len(DOCUMENT_PAGES)} document, "
          f"{len(BUILD_GENERATED_PAGES)} build generated)")


def document_page_lint() -> None:
    """A document page must be genuinely self-contained.

    These pages are exempt from every chrome lint, so the exemption has to buy
    something checkable. Self-containment is that thing: the page is sent as a
    link, saved to a desktop, opened with no network and printed, and all three
    uses die quietly the moment it references anything outside itself. A
    stylesheet that resolves on the server and nowhere else would pass every
    other check in this build.
    """
    problems = []
    for name in sorted(DOCUMENT_PAGES):
        page = DIST / name
        if not page.is_file():
            continue
        text = page.read_text(encoding="utf-8", errors="ignore")
        for tag_m in URL_ATTR_RE.finditer(text):
            tag = tag_m.group("tag").lower()
            for a in URL_ATTR_PAIR_RE.finditer(tag_m.group("attrs")):
                val = a.group("val").strip()
                if SELF_CONTAINED_VALUE_RE.match(val):
                    continue
                # A reader choosing to leave is not the page fetching anything.
                if tag == "a" and a.group("name").lower() == "href":
                    continue
                line = text.count("\n", 0, tag_m.start()) + 1
                problems.append(
                    f"{name}:{line}: <{tag} {a.group('name')}=\"{val[:60]}\"> "
                    "fetches from outside the file. A document page must carry "
                    "everything inline so it still works saved to a desktop "
                    "with no network.")
        for m in CSS_FETCH_RE.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            problems.append(
                f"{name}:{line}: stylesheet fetches {m.group(0).strip()!r}. A "
                "document page must carry everything inline.")
        for m in DOCUMENT_SCRIPT_RE.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            problems.append(
                f"{name}:{line}: carries a <script>. A document page is a "
                "document: it must render the same opened from a server, from "
                "a desktop, and on paper, and a script is the one thing that "
                "can make those differ.")
    if problems:
        for p in problems[:20]:
            print(f"  document page: {p}")
        fail(f"{len(problems)} external reference(s) in a self-contained document page")
    print(f"document page lint: {len(DOCUMENT_PAGES)} document page(s) carry no "
          "external references")


def normalize_nav(block: str, allow_cart: bool) -> str:
    """Strip the permitted differences, then flatten whitespace.

    Comments are dropped: a note explaining why the cart sits where it sits is
    not chrome drift. Whitespace is flattened because the canonical block is
    stored at one indent and pasted into the pages at another; indentation is
    not drift either. Everything else, including attribute order and link text,
    is compared token for token.

    The cart is stripped ONLY for the two pages entitled to one. Before
    2026-08-17 it was stripped everywhere, so a cart injected into team.html
    built clean (verifier probe E).
    """
    block = NAV_COMMENT_RE.sub("", block)
    if allow_cart:
        block = NAV_CART_RE.sub("", block)
    block = NAV_ACTIVE_CLASS_RE.sub('class="nav-link"', block)
    block = NAV_ARIA_CURRENT_RE.sub("", block)
    return WHITESPACE_RE.sub(" ", block).strip()


def nav_drift_lint() -> None:
    partial = ROOT / "www" / "_partials" / "nav.html"
    if not partial.is_file():
        fail(f"the canonical navigation partial is missing: {partial}")
    canonical = NAV_BLOCK_RE.search(partial.read_text(encoding="utf-8"))
    if not canonical:
        fail(f'{partial} does not contain a <nav class="nav-links"> block')
    want = normalize_nav(canonical.group(0), allow_cart=False)

    problems = []
    for name in sorted(CORPORATE_PAGES):
        expected_active = CORPORATE_PAGES[name]
        page = DIST / name
        text = page.read_text(encoding="utf-8")
        found = NAV_BLOCK_RE.search(text)
        if not found:
            problems.append(f'{name}: no <nav class="nav-links"> block')
            continue
        block = found.group(0)

        # The cart, on the two pages entitled to one and nowhere else.
        if name not in CART_PAGES and NAV_CART_PRESENT_RE.search(block):
            problems.append(
                f"{name}: carries a nav-cart element. The cart is permitted on "
                f"{' and '.join(sorted(CART_PAGES))} only (contract section 2, rule 3).")

        # The active item: REQUIRED, exactly one, on the right destination,
        # with both halves of the marker.
        #
        # Two holes closed here on 2026-08-17. The lint used to accept
        # is-active on any item, so moving it from Team to Shop inside
        # team.html built clean (quality assurance finding L3). And it
        # permitted the active state rather than requiring it, so faq.html
        # shipped with no active item at all and passed.
        active_tags = NAV_ACTIVE_TAG_RE.findall(block)
        if len(active_tags) != 1:
            problems.append(
                f"{name}: {len(active_tags)} active navigation items, expected exactly 1 "
                f'(class="nav-link is-active" href="{expected_active}" aria-current="page")')
        else:
            tag = active_tags[0]
            href = HREF_RE.search(tag)
            if not href or href.group(1) != expected_active:
                problems.append(
                    f"{name}: the active item points at "
                    f'"{href.group(1) if href else "nothing"}", expected "{expected_active}"'
                    f"\n      {tag}")
            if 'aria-current="page"' not in tag:
                problems.append(
                    f"{name}: the active navigation item carries is-active but not "
                    f'aria-current="page"\n      {tag}')

        got = normalize_nav(block, allow_cart=(name in CART_PAGES))
        if got == want:
            continue
        cut = next((i for i, (a, b) in enumerate(zip(got, want)) if a != b),
                   min(len(got), len(want)))
        problems.append(
            f"{name}: navigation differs from _partials/nav.html at character {cut}\n"
            f"      page:      ...{got[max(0, cut - 40):cut + 60]}\n"
            f"      canonical: ...{want[max(0, cut - 40):cut + 60]}")

    if problems:
        for p in problems:
            print(f"  nav drift: {p}")
        fail(f"{len(problems)} navigation problem(s) against the canonical block in "
             "www/_partials/nav.html; only the active item and the cart on "
             f"{' and '.join(sorted(CART_PAGES))} may differ")
    print(f"nav drift lint: {len(CORPORATE_PAGES)} corporate pages match "
          f"_partials/nav.html, each marking its own page active")


# ---------------------------------------------------------------------------
# THE PRE-PAINT THEME SNIPPET
# ---------------------------------------------------------------------------
# It has to be inline and synchronous in every head, so nine copies are
# unavoidable; that is exactly why it needs a lint. Quality assurance finding
# L2, 2026-08-17: the nine copies had already grown two different wordings
# within a day of being written.

THEME_BOOT_SCRIPT_RE = re.compile(
    r"<script>\s*\(function \(\) \{\s*var theme = 'dark';.*?\}\)\(\);\s*</script>", re.S)


def theme_boot_lint() -> None:
    partial = ROOT / "www" / "_partials" / "theme-boot.html"
    if not partial.is_file():
        fail(f"the canonical theme boot partial is missing: {partial}")
    canonical = THEME_BOOT_SCRIPT_RE.search(partial.read_text(encoding="utf-8"))
    if not canonical:
        fail(f"{partial} does not contain the canonical theme boot script")
    want = WHITESPACE_RE.sub(" ", canonical.group(0)).strip()

    problems = []
    for name in sorted(CORPORATE_PAGES):
        text = (DIST / name).read_text(encoding="utf-8")
        head = text.split("</head>", 1)[0]
        found = THEME_BOOT_SCRIPT_RE.search(head)
        if not found:
            problems.append(
                f"{name}: no canonical pre-paint theme snippet in <head>. Copy it "
                "verbatim from www/_partials/theme-boot.html. It must be inline and "
                "synchronous, or the page paints the wrong palette and snaps.")
            continue
        got = WHITESPACE_RE.sub(" ", found.group(0)).strip()
        if got != want:
            problems.append(f"{name}: the pre-paint theme snippet differs from "
                            "www/_partials/theme-boot.html")

    if problems:
        for p in problems:
            print(f"  theme boot: {p}")
        fail(f"{len(problems)} page(s) carry a theme boot snippet that is missing or "
             "not the canonical one")
    print(f"theme boot lint: {len(CORPORATE_PAGES)} corporate pages carry the "
          "canonical pre-paint snippet, inline and synchronous")


# ---------------------------------------------------------------------------
# CHROME PRESENTATION
# ---------------------------------------------------------------------------
# Quality assurance finding M1, 2026-08-17, and the standing checklist row it
# earned: "shared markup is not shared chrome". The first pass unified the
# navigation markup and behaviour and left its CSS in four places. comp-plan
# rendered the bar at 12.80 pixel type, a 20 pixel gap and a 65 pixel header
# against 13.44, 26 and 69 elsewhere, and left-packed it at 390 pixels wide.
# Same items, different bar: the owner's original complaint, surviving.
#
# So www/css/site-chrome.css owns these selectors, and nothing else may declare
# them at the head of a selector. Qualified forms are still allowed, because
# they cannot reach the chrome: ".login-logo .brand-word" styles the sign-in
# card, ".foot .legal" styles the brochure footer.

CHROME_SELECTORS = (
    "nav", "nav-inner", "nav-brand", "nav-logo", "nav-links", "nav-link",
    "nav-signin", "nav-theme", "nav-support", "soon-pill", "brand-mark",
    "brand-word", "footer", "footer-cols", "footer-head", "footer-meta",
    "footer-contact", "footer-mail", "flink", "socials", "social", "legal",
    "skip-link", "bpFab",
)
# The trailing lookahead matters. \b would treat ".nav-cart" as a match for
# "nav", because a hyphen is a non-word character, and the cart is explicitly
# NOT owned by the shared sheet. The class name must end here.
CHROME_SELECTOR_RE = re.compile(
    r"(?m)^[ \t]*((?:a|span|div|button)?\.(?:" + "|".join(CHROME_SELECTORS) +
    r")(?![-\w])[^{;}]*)\{")
STYLE_BLOCK_RE = re.compile(r"<style>(.*?)</style>", re.S)

CHROME_CSS_OWNER = "site-chrome.css"


def chrome_css_lint() -> None:
    """Only site-chrome.css may declare a chrome rule."""
    problems = []

    for sheet in sorted((DIST / "css").glob("*.css")):
        if sheet.name == CHROME_CSS_OWNER:
            continue
        # The sign-in areas have their own chrome by instruction.
        if sheet.name in ("staff.css", "staff-ops.css"):
            continue
        for m in CHROME_SELECTOR_RE.finditer(sheet.read_text(encoding="utf-8")):
            problems.append(f"css/{sheet.name}: {m.group(1).strip()}")

    for name in sorted(CORPORATE_PAGES):
        text = (DIST / name).read_text(encoding="utf-8")
        for block in STYLE_BLOCK_RE.findall(text):
            for m in CHROME_SELECTOR_RE.finditer(block):
                problems.append(f"{name} (inline style): {m.group(1).strip()}")

    if problems:
        for p in problems:
            print(f"  chrome css drift: {p}")
        fail(f"{len(problems)} chrome rule(s) declared outside "
             f"www/css/{CHROME_CSS_OWNER}. That file is the single source of chrome "
             "presentation. Move the rule there, or qualify the selector with a "
             "page-scoped ancestor if it genuinely styles something else.")
    print(f"chrome css lint: chrome presentation declared only in css/{CHROME_CSS_OWNER}")


def chrome_sheet_link_lint() -> None:
    """Every corporate page must load the shared chrome sheet."""
    problems = [n for n in sorted(CORPORATE_PAGES)
                if f'href="css/{CHROME_CSS_OWNER}' not in (DIST / n).read_text(encoding="utf-8")]
    if problems:
        for p in problems:
            print(f"  chrome sheet: {p}: does not link css/{CHROME_CSS_OWNER}")
        fail(f"{len(problems)} corporate page(s) do not load css/{CHROME_CSS_OWNER}; "
             "their navigation would render unstyled")
    print(f"chrome sheet lint: {len(CORPORATE_PAGES)} corporate pages load "
          f"css/{CHROME_CSS_OWNER}")


def currency_mirror_check() -> None:
    """Fail the build if the client and server currency rate tables drift.

    Verifier finding O-M3 (2026-08-16): the conversion rates live in
    www/shop.html (what the shopper sees) and functions/_shared/tax.ts
    (what the tax quote says), with nothing keeping them equal. The
    checker applies the pricing mirror's discipline (spec check V6):
    shop.html is the declared source of truth, tax.ts is the mirror,
    and any drift in either direction fails this build, so a drifted
    table cannot ship.
    """
    import subprocess
    checker = ROOT / "functions" / "_shared" / "check_currency_mirror.py"
    result = subprocess.run(
        [sys.executable, str(checker)], capture_output=True, text=True)
    for line in (result.stdout or "").strip().splitlines():
        print(f"currency mirror: {line}")
    if result.returncode != 0:
        fail("currency rate mirror drifted (see lines above); "
             "shop.html CURRENCIES and tax.ts TAX_CURRENCY_RATES must match")


def main() -> None:
    www, site = ROOT / "www", ROOT / "site"
    for required in (www, site):
        if not required.is_dir():
            fail(f"missing source folder {required}")

    if DIST.exists():
        if not MARKER.exists():
            fail("dist exists but has no .build-marker; refusing to remove a folder this script did not build")
        # Keep .git so the deploy repo (github.com/howkoz/orvanna.io) survives rebuilds.
        for child in DIST.iterdir():
            if child.name == ".git":
                continue
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
    else:
        DIST.mkdir(parents=True)

    copy_tree(www, DIST)
    copy_tree(site, DIST / "portal")

    for name, old, new in REWRITES_ROOT + REWRITES_PORTAL:
        rewrite(DIST / name, old, new)

    (DIST / "CNAME").write_text(DOMAIN + "\n", encoding="utf-8")
    (DIST / ".gitignore").write_text("/.build-marker\n", encoding="utf-8")
    (DIST / ".nojekyll").write_text("", encoding="utf-8")
    (DIST / "404.html").write_text(NOT_FOUND_PAGE, encoding="utf-8")
    (DIST / "README.md").write_text(README, encoding="utf-8")
    MARKER.write_text("built by deploy/build_dist.py\n", encoding="utf-8")

    stamp_assets()

    leftovers = []
    for page in DIST.rglob("*.html"):
        rel = page.relative_to(DIST).as_posix()
        text = page.read_text(encoding="utf-8")
        for bad in ("../site/", "../www/"):
            if bad in text:
                leftovers.append(f"{rel}: still references {bad}")
    if leftovers:
        fail("; ".join(leftovers))

    broken = link_check()
    if broken:
        fail("broken links: " + "; ".join(broken))

    # Build gates added 2026-08-16 (stabilization Step 0): each one exits
    # nonzero on failure, so nothing cache-stale, name-leaking, or
    # secret-bearing can reach the deploy repo through this script.
    assert_version_stamps()
    name_lint()
    secret_scan()
    page_registry_lint()
    document_page_lint()
    nav_drift_lint()
    theme_boot_lint()
    chrome_sheet_link_lint()
    chrome_css_lint()
    currency_mirror_check()

    files = sorted(p for p in DIST.rglob("*") if p.is_file() and ".git" not in p.parts)
    total = sum(p.stat().st_size for p in files)
    digest = hashlib.sha256()
    for p in files:
        digest.update(p.relative_to(DIST).as_posix().encode())
        digest.update(p.read_bytes())
    print(f"OK: {len(files)} files, {total/1024:.0f} KB, bundle sha256 {digest.hexdigest()[:16]}")
    print(f"dist: {DIST}")


if __name__ == "__main__":
    main()
