#!/usr/bin/env python3
"""Fail if www/js/catalog.js and functions/_shared/pricing.ts disagree.

The lockstep contract at the top of pricing.ts says the two files stay
fact for fact identical. Until now only the currency rates had a checker;
the sixteen price quadruples and, as of 2026-08-19, the set of items that
may carry a subscription were kept in step by hand.

That set is the one worth a machine: a SKU that is one-time only on the
site but subscribable on the server can be subscribed by anything that is
not the site, at a tenth of its price. Drift in either direction fails.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "www" / "js" / "catalog.js"
PRICING = ROOT / "functions" / "_shared" / "pricing.ts"


def from_catalog() -> tuple[dict, set]:
    """Read the browser file by running it, so this checks the shipped
    behaviour rather than a regex's reading of it."""
    script = (
        "global.window={};require(%s);"
        "const O=window.ORVANNA;"
        "const out={};O.PRODUCTS.forEach(p=>{out[p.sku]=[p.sub.price,p.sub.pv,p.once.price,p.once.pv];});"
        "console.log(JSON.stringify({prices:out,"
        "subs:O.PRODUCTS.filter(p=>O.subscribable(p)).map(p=>p.sku)}));"
    ) % json.dumps(str(CATALOG))
    r = subprocess.run(["node", "-e", script], capture_output=True, text=True)
    if r.returncode != 0:
        print("could not evaluate catalog.js:", r.stderr.strip()[:400])
        sys.exit(1)
    data = json.loads(r.stdout)
    return data["prices"], set(data["subs"])


def from_pricing() -> tuple[dict, set]:
    src = PRICING.read_text(encoding="utf-8")
    prices = {}
    row = re.compile(
        r"^\s*(\w+):\s*\{\s*tier:\s*\"(\w+)\",\s*"
        r"sub:\s*\{\s*price:\s*([\d_]+),\s*pv:\s*([\d_]+)\s*\},\s*"
        r"once:\s*\{\s*price:\s*([\d_]+),\s*pv:\s*([\d_]+)\s*\}",
        re.M,
    )
    for m in row.finditer(src):
        n = lambda g: int(m.group(g).replace("_", ""))
        prices[m.group(1)] = [n(3), n(4), n(5), n(6)]
    block = re.search(r"ONE_TIME_ONLY[^=]*=\s*new Set\(\[([^\]]*)\]", src)
    if not block:
        print("pricing.ts has no ONE_TIME_ONLY set")
        sys.exit(1)
    one_time = set(re.findall(r'"([^"]+)"', block.group(1)))
    return prices, set(prices) - one_time


def main() -> None:
    cat_prices, cat_subs = from_catalog()
    srv_prices, srv_subs = from_pricing()
    problems = []

    if set(cat_prices) != set(srv_prices):
        problems.append(
            "the two files do not carry the same SKUs: "
            f"only in catalog.js {sorted(set(cat_prices) - set(srv_prices))}, "
            f"only in pricing.ts {sorted(set(srv_prices) - set(cat_prices))}"
        )
    for sku in sorted(set(cat_prices) & set(srv_prices)):
        if cat_prices[sku] != srv_prices[sku]:
            problems.append(
                f"{sku}: catalog.js {cat_prices[sku]} vs pricing.ts {srv_prices[sku]} "
                "(sub price, sub pv, one price, one pv)"
            )
    if cat_subs != srv_subs:
        problems.append(
            "subscribable sets differ: "
            f"subscribable only on the site {sorted(cat_subs - srv_subs)}, "
            f"only on the server {sorted(srv_subs - cat_subs)}"
        )

    if problems:
        for p in problems:
            print("DRIFT:", p)
        sys.exit(1)

    print(f"price mirror: {len(cat_prices)} SKUs match on all four figures")
    print(f"subscribable mirror: {len(cat_subs)} subscribable, "
          f"{len(cat_prices) - len(cat_subs)} one-time only, both files agree")


if __name__ == "__main__":
    main()
