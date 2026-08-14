"""Mechanical pricing-mirror parity check (Phase 6 spec, check V6).

Diffs every (sku, mode, price, pv) quadruple between the site's
single source of truth, www/js/catalog.js, and the Edge Function
pricing mirror, functions/_shared/pricing.ts. Also checks the
activation fee (mirror vs the DELIVERY table in www/shop.html)
and the tax rate (mirror vs the 0.05 factor in www/shop.html).

Run:  py functions/_shared/check_pricing_mirror.py
Exit: 0 clean, 1 on any drift (each difference printed).
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # MLM-PILOT
CATALOG_JS = ROOT / "www" / "js" / "catalog.js"
SHOP_HTML = ROOT / "www" / "shop.html"
PRICING_TS = ROOT / "functions" / "_shared" / "pricing.ts"

MODE_RE = re.compile(
    r"sub:\s*\{\s*price:\s*([\d.]+),\s*pv:\s*([\d.]+)\s*\},\s*"
    r"once:\s*\{\s*price:\s*([\d.]+),\s*pv:\s*([\d.]+)\s*\}"
)


def parse_catalog_js(text):
    """Return {sku: (sub_price, sub_pv, once_price, once_pv)}."""
    out = {}
    chunks = text.split("{ sku:")[1:]
    for chunk in chunks:
        sku_m = re.match(r"\s*'(\w+)'", chunk)
        mode_m = MODE_RE.search(chunk)
        if not sku_m or not mode_m:
            continue
        out[sku_m.group(1)] = tuple(float(x) for x in mode_m.groups())
    return out


def parse_pricing_ts(text):
    """Return ({sku: quadruple}, activation_fee_dollars, tax_percent)."""
    out = {}
    entry_re = re.compile(r'^\s*(\w+):\s*\{\s*tier:\s*"\w+",\s*' + MODE_RE.pattern,
                          re.MULTILINE)
    for m in entry_re.finditer(text):
        out[m.group(1)] = tuple(float(x) for x in m.groups()[1:])
    fee = re.search(r"ACTIVATION_FEE_DOLLARS\s*=\s*([\d.]+)", text)
    tax = re.search(r"TAX_RATE_PERCENT\s*=\s*([\d.]+)", text)
    return out, float(fee.group(1)) if fee else None, float(tax.group(1)) if tax else None


def main():
    catalog = parse_catalog_js(CATALOG_JS.read_text(encoding="utf-8"))
    mirror, mirror_fee, mirror_tax = parse_pricing_ts(
        PRICING_TS.read_text(encoding="utf-8"))
    shop = SHOP_HTML.read_text(encoding="utf-8")

    problems = []

    if len(catalog) != 16:
        problems.append(f"catalog.js parsed {len(catalog)} items, expected 16")
    if len(mirror) != 16:
        problems.append(f"pricing.ts parsed {len(mirror)} items, expected 16")

    for sku in sorted(set(catalog) | set(mirror)):
        if sku not in mirror:
            problems.append(f"{sku}: in catalog.js but missing from pricing.ts")
            continue
        if sku not in catalog:
            problems.append(f"{sku}: in pricing.ts but missing from catalog.js")
            continue
        c, m = catalog[sku], mirror[sku]
        labels = ["sub price", "sub pv", "once price", "once pv"]
        for label, cv, mv in zip(labels, c, m):
            if cv != mv:
                problems.append(
                    f"{sku} {label}: catalog.js={cv} pricing.ts={mv}")

    # Activation fee: DELIVERY table in shop.html vs the mirror constant.
    fee_m = re.search(
        r"priority:\s*\{\s*label:\s*'Priority activation',\s*price:\s*([\d.]+)", shop)
    shop_fee = float(fee_m.group(1)) if fee_m else None
    if shop_fee is None:
        problems.append("shop.html: could not find the priority activation fee")
    elif shop_fee != mirror_fee:
        problems.append(
            f"activation fee: shop.html={shop_fee} pricing.ts={mirror_fee}")

    # Tax rate: the 0.05 factor in shop.html vs the mirror constant.
    tax_m = re.search(r"taxable\s*\*\s*0*\.(\d+)", shop)
    shop_tax_pct = float("0." + tax_m.group(1)) * 100 if tax_m else None
    if shop_tax_pct is None:
        problems.append("shop.html: could not find the tax factor")
    elif shop_tax_pct != mirror_tax:
        problems.append(
            f"tax rate percent: shop.html={shop_tax_pct} pricing.ts={mirror_tax}")

    quads = sum(1 for s in catalog if s in mirror and catalog[s] == mirror[s])
    print(f"Items matched exactly: {quads} of 16 "
          f"(that is {quads * 2} of 32 (sku, mode, price, pv) quadruples)")
    print(f"Activation fee: shop.html={shop_fee} pricing.ts={mirror_fee}")
    print(f"Tax rate percent: shop.html={shop_tax_pct} pricing.ts={mirror_tax}")

    if problems:
        print("\nFAIL: the pricing mirror has drifted:")
        for p in problems:
            print("  - " + p)
        return 1
    print("\nPASS: pricing mirror matches catalog.js fact for fact.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
