"""Mechanical currency-rate mirror parity check (verifier finding O-M3).

The conversion rate table exists in two codebases by architectural
necessity: the static page cannot import Deno TypeScript and the Edge
Functions bundle only the functions folder, so a single file cannot be
consumed by both at runtime. The pricing mirror (catalog.js versus
pricing.ts, spec check V6) answers the same problem with a declared
source of truth plus a mechanical diff that fails on drift; this is
that discipline applied to the currency rates.

Source of truth: the CURRENCIES table in www/shop.html (what the
shopper SEES). Mirror: TAX_CURRENCY_RATES in functions/_shared/tax.ts
(what the quote SAYS). This script diffs every (code, rate) pair in
both directions, so a currency added, removed, or repriced on one side
only is a failure, not a silent drift.

Run:  py functions/_shared/check_currency_mirror.py
Exit: 0 clean, 1 on any drift (each difference printed).
Wired into deploy/build_dist.py, so a drifted table cannot ship.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # MLM-PILOT
SHOP_HTML = ROOT / "www" / "shop.html"
TAX_TS = ROOT / "functions" / "_shared" / "tax.ts"


def parse_shop_rates(text):
    """Return {code: rate} from the CURRENCIES table in shop.html."""
    block_m = re.search(r"var CURRENCIES = \{(.*?)\n  \};", text, re.DOTALL)
    if not block_m:
        return {}
    out = {}
    for m in re.finditer(r"([A-Z]{3}):\s*\{\s*rate:\s*([\d.]+)", block_m.group(1)):
        out[m.group(1)] = float(m.group(2))
    return out


def parse_tax_rates(text):
    """Return {code: rate} from TAX_CURRENCY_RATES in tax.ts."""
    block_m = re.search(
        r"const TAX_CURRENCY_RATES: Record<string, number> = \{(.*?)\};",
        text, re.DOTALL)
    if not block_m:
        return {}
    out = {}
    for m in re.finditer(r"([A-Z]{3}):\s*([\d.]+)", block_m.group(1)):
        out[m.group(1)] = float(m.group(2))
    return out


def main():
    shop = parse_shop_rates(SHOP_HTML.read_text(encoding="utf-8"))
    tax = parse_tax_rates(TAX_TS.read_text(encoding="utf-8"))

    problems = []
    if not shop:
        problems.append("shop.html: could not parse the CURRENCIES rate table")
    if not tax:
        problems.append("tax.ts: could not parse TAX_CURRENCY_RATES")

    for code in sorted(set(shop) | set(tax)):
        if code not in tax:
            problems.append(f"{code}: in shop.html but missing from tax.ts")
        elif code not in shop:
            problems.append(f"{code}: in tax.ts but missing from shop.html")
        elif shop[code] != tax[code]:
            problems.append(
                f"{code}: shop.html rate={shop[code]} tax.ts rate={tax[code]}")

    matched = sum(1 for c in shop if c in tax and shop[c] == tax[c])
    print(f"Currency rates matched exactly: {matched} of {len(shop)} "
          f"(shop.html={sorted(shop.items())} tax.ts={sorted(tax.items())})")

    if problems:
        print("\nFAIL: the currency rate mirror has drifted:")
        for p in problems:
            print("  - " + p)
        return 1
    print("\nPASS: currency rate mirror matches shop.html rate for rate.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
