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
    shutil.copytree(src, dst, dirs_exist_ok=True)


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
NAME_ALLOWLIST = {"team.html"}
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
