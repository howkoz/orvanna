"""Phase 5 deploy builder for orvanna.io.

Assembles a publishable static package under deploy/dist/:
  - www/*  -> dist/          (corporate site at the domain root)
  - site/* -> dist/portal/   (member portal at /portal/)
Rewrites the five cross-folder links so everything is relative and works
both at https://orvanna.io/ and at any preview URL with a path prefix.

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
    ("portal/index.html", "../www/index.html", "../index.html"),
    ("portal/index.html", "../www/shop.html", "../shop.html"),
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

    files = sorted(p for p in DIST.rglob("*") if p.is_file())
    total = sum(p.stat().st_size for p in files)
    digest = hashlib.sha256()
    for p in files:
        digest.update(p.relative_to(DIST).as_posix().encode())
        digest.update(p.read_bytes())
    print(f"OK: {len(files)} files, {total/1024:.0f} KB, bundle sha256 {digest.hexdigest()[:16]}")
    print(f"dist: {DIST}")


if __name__ == "__main__":
    main()
