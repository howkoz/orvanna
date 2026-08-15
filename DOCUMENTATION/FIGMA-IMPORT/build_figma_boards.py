# -*- coding: utf-8 -*-
"""
Builds the Orvanna FIGMA-IMPORT board set.

Every board is a 1920 x 1080 SVG sized as a Figma frame, with a white
background rectangle, pale hardcoded fills and dark hardcoded text, so a
screen grab pastes cleanly into Snagit and the file imports into Figma as
named, editable layers rather than one flat picture.

No CSS classes, no <style> block, no CSS variables: Figma reads presentation
attributes reliably and reads stylesheets poorly. Every <g> carries an id,
because Figma names the imported layer from the id.
"""

import os
import html

# Boards are written beside this script, so the generator can be moved or the
# repository cloned without editing a hardcoded path.
OUT = os.path.dirname(os.path.abspath(__file__))
W, H = 1920, 1080

# ---------------------------------------------------------------- palette
INK       = "#0F172A"   # headings
BODY      = "#334155"   # body text
MUTED     = "#64748B"   # captions
LINE      = "#CBD5E1"   # hairlines
ARROW     = "#475569"   # connectors
PAPER     = "#FFFFFF"
WASH      = "#F8FAFC"   # lane wash

PALE = {
    "indigo": ("#EEF2FF", "#4F46E5"),
    "cyan":   ("#ECFEFF", "#0E7490"),
    "violet": ("#F5F3FF", "#7C3AED"),
    "amber":  ("#FFFBEB", "#B45309"),
    "green":  ("#ECFDF5", "#065F46"),
    "red":    ("#FEF2F2", "#B91C1C"),
    "slate":  ("#F1F5F9", "#475569"),
}

FONT = "Inter, 'Segoe UI', sans-serif"
MONO = "'Roboto Mono', Consolas, monospace"

_ids = {}


def uid(stem):
    _ids[stem] = _ids.get(stem, 0) + 1
    n = _ids[stem]
    return stem if n == 1 else "%s-%d" % (stem, n)


def esc(s):
    return html.escape(str(s), quote=True)


def text(x, y, s, size=15, fill=BODY, weight="400", anchor="start",
         font=FONT, spacing=None):
    ls = ' letter-spacing="%s"' % spacing if spacing else ""
    return ('<text x="%s" y="%s" font-family="%s" font-size="%s" '
            'font-weight="%s" fill="%s" text-anchor="%s"%s>%s</text>'
            % (x, y, font, size, weight, fill, anchor, ls, esc(s)))


def rect(x, y, w, h, fill, stroke=None, rx=10, sw=1.5, dash=None):
    st = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    da = ' stroke-dasharray="%s"' % dash if dash else ""
    return ('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s%s/>'
            % (x, y, w, h, rx, fill, st, da))


def node(x, y, w, h, title, lines=(), tone="indigo", ident=None, tsize=17,
         lsize=13.5, dash=None):
    """A named box: bold title, optional detail lines under it."""
    fill, stroke = PALE[tone]
    gid = uid(ident or ("node-" + title.lower().replace(" ", "-")[:26]))
    parts = ['<g id="%s">' % esc(gid), rect(x, y, w, h, fill, stroke, dash=dash)]
    parts.append(text(x + 16, y + 28, title, tsize, INK, "700"))
    ty = y + 52
    for ln in lines:
        parts.append(text(x + 16, ty, ln, lsize, BODY))
        ty += 19
    parts.append("</g>")
    return "".join(parts)


def arrow(x1, y1, x2, y2, label=None, color=ARROW, dash=None, ident=None,
          label_dy=-9, curve=None):
    gid = uid(ident or "flow")
    da = ' stroke-dasharray="%s"' % dash if dash else ""
    if curve:
        d = "M %s %s Q %s %s %s %s" % (x1, y1, curve[0], curve[1], x2, y2)
        path = ('<path d="%s" fill="none" stroke="%s" stroke-width="2"%s '
                'marker-end="url(#arrowhead)"/>' % (d, color, da))
    else:
        path = ('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" '
                'stroke-width="2"%s marker-end="url(#arrowhead)"/>'
                % (x1, y1, x2, y2, color, da))
    parts = ['<g id="%s">' % esc(gid), path]
    if label:
        mx, my = (x1 + x2) / 2.0, (y1 + y2) / 2.0
        parts.append('<rect x="%s" y="%s" width="%s" height="16" rx="4" '
                     'fill="#FFFFFF"/>'
                     % (mx - (len(label) * 3.3), my + label_dy - 12,
                        len(label) * 6.6))
        parts.append(text(mx, my + label_dy, label, 11.5, MUTED, "600", "middle"))
    parts.append("</g>")
    return "".join(parts)


def lane(x, y, w, h, title, tone="slate", ident=None, note=None):
    """A swimlane. `note` is the right aligned connector line: it says how this
    lane is reached from another, which keeps the connection visible without
    drawing an arrow across three lanes of boxes."""
    fill, stroke = PALE[tone]
    gid = uid(ident or "lane")
    parts = [
        '<g id="%s">' % esc(gid),
        rect(x, y, w, h, WASH, LINE, rx=14, sw=1.2),
        rect(x, y, 6, h, stroke, rx=3),
        text(x + 20, y + 26, title, 13, stroke, "700", spacing="0.14em")]
    if note:
        parts.append(text(x + w - 20, y + 26, note, 12.5, MUTED, "600",
                          anchor="end"))
    parts.append("</g>")
    return "".join(parts)


def board(name, title, subtitle, body, footer=None):
    """Wraps board content in the frame skeleton and writes the file."""
    foot = footer or ("Orvanna design system  |  generated 2026-08-15  |  "
                      "hardcoded colours, no theme variables")
    svg = "".join([
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
        'viewBox="0 0 %d %d">' % (W, H, W, H),
        "<defs>",
        '<marker id="arrowhead" markerWidth="9" markerHeight="9" refX="8" '
        'refY="3" orient="auto"><path d="M0,0 L8,3 L0,6 z" fill="%s"/></marker>'
        % ARROW,
        "</defs>",
        '<g id="Board background">',
        rect(0, 0, W, H, PAPER, rx=0),
        "</g>",
        '<g id="Board title">',
        rect(72, 48, 8, 46, PALE["indigo"][1], rx=4),
        text(96, 74, title, 30, INK, "700"),
        text(96, 100, subtitle, 15, MUTED),
        "</g>",
        body,
        '<g id="Board footer">',
        '<line x1="72" y1="1006" x2="1848" y2="1006" stroke="%s" '
        'stroke-width="1"/>' % LINE,
        text(72, 1032, foot, 12, MUTED),
        "</g>",
        "</svg>"])
    path = os.path.join(OUT, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print("wrote", path, len(svg), "bytes")


# ================================================================ board 01
def board_system():
    b = []
    b.append(lane(72, 140, 1776, 210, "LANE 1  VISITOR, THE PUBLIC PATH",
                  "indigo", "Lane 1 visitor"))
    xs = [110, 356, 602, 848, 1094, 1340, 1586]
    labels = [
        ("Corporate site", ["index.html", "Hero, pillars, team"], "indigo"),
        ("Shop catalog", ["shop.html", "Three tier bands"], "indigo"),
        ("Product page", ["product.html", "Subscribe toggle"], "indigo"),
        ("Cart drawer", ["Glass sheet, right", "Personal Volume meter"], "cyan"),
        ("Checkout", ["Four numbered steps", "Account, ship, pay"], "cyan"),
        ("Bank approval", ["3-D Secure overlay", "Chrome bar on top"], "amber"),
        ("Confirmation", ["Order number", "Read and forward"], "green"),
    ]
    for i, (t, ls, tone) in enumerate(labels):
        b.append(node(xs[i], 190, 222, 128, t, ls, tone))
        if i:
            b.append(arrow(xs[i - 1] + 222, 254, xs[i] - 4, 254))

    b.append(lane(72, 386, 1776, 210, "LANE 2  MEMBER, THE SIGNED IN PATH",
                  "cyan", "Lane 2 member",
                  note="Entered from lane 1: a shopper becomes a member at "
                       "the first purchase, then signs in."))
    m = [
        ("Sign in", ["login.html", "One quiet door"], "indigo"),
        ("The Office", ["Landing view", "Identity rail"], "cyan"),
        ("My Business", ["Gate Board", "The team tree"], "cyan"),
        ("My Volume", ["Momentum Board", "Own vs customer"], "cyan"),
        ("My Rank", ["Rank Runway", "Requirement list"], "cyan"),
        ("My Statement", ["Commission table", "Level chips"], "cyan"),
        ("Company", ["The Wire", "Rank spread"], "violet"),
    ]
    for i, (t, ls, tone) in enumerate(m):
        b.append(node(xs[i], 436, 222, 128, t, ls, tone))
        if i:
            b.append(arrow(xs[i - 1] + 222, 500, xs[i] - 4, 500))

    b.append(lane(72, 632, 1776, 210, "LANE 3  STAFF, THE CALL PATH",
                  "violet", "Lane 3 staff",
                  note="Reads and writes the SAME member record and the SAME "
                       "catalog as lanes 1 and 2."))
    s = [
        ("Caller lookup", ["Type ahead list", "Keyboard driven"], "violet"),
        ("Caller snapshot", ["Rank and qualified", "Verification block"], "violet"),
        ("Call notes", ["Per member", "This browser only"], "slate"),
        ("Quick order", ["Product, mode, qty", "Line table"], "violet"),
        ("Payment by phone", ["Link is preferred", "Agent rule card"], "amber"),
        ("Waiting on bank", ["Only the cardholder", "can finish it"], "amber"),
        ("Read aloud", ["Big order number", "Phonetic spelling"], "green"),
    ]
    for i, (t, ls, tone) in enumerate(s):
        b.append(node(xs[i], 682, 222, 128, t, ls, tone))
        if i:
            b.append(arrow(xs[i - 1] + 222, 746, xs[i] - 4, 746))

    # shared foundation
    b.append('<g id="Shared foundation">')
    b.append(rect(72, 872, 1776, 118, PALE["slate"][0], LINE, rx=14))
    b.append(text(96, 902, "ONE FOUNDATION UNDER ALL THREE LANES", 13,
                  PALE["slate"][1], "700", spacing="0.14em"))
    found = [
        ("corporate.css", "tokens, glass panel, buttons, nav, fields"),
        ("shop.css", "catalog, cart drawer, checkout, 3DS chrome"),
        ("staff.css", "console density, work fields, read aloud"),
        ("portal.css", "the only file with a light theme"),
        ("assets/", "logo-header-dark.svg, favicon.svg"),
    ]
    fx = 96
    for nme, why in found:
        b.append(text(fx, 934, nme, 14.5, INK, "700", font=MONO))
        b.append(text(fx, 956, why, 12.5, MUTED))
        fx += 352
    b.append("</g>")

    board("01-system-flow.svg", "Orvanna, the whole system",
          "Three lanes of user, one shared foundation. Every box is a real "
          "file or a real view in the pilot.", "".join(b))


# ================================================================ board 02
def board_shop():
    b = []
    b.append(text(96, 152, "HAPPY PATH", 13, PALE["cyan"][1], "700",
                  spacing="0.14em"))
    row = [
        ("Catalog", ["Tier filter pills", "Product cards, 3 up"], "indigo"),
        ("Add to cart", ["Button fills cyan", "then flashes a tick"], "indigo"),
        ("Cart drawer", ["Lines, quantity steppers", "Personal Volume meter"], "cyan"),
        ("Step 1 Account", ["Sign in or continue", "as a guest"], "cyan"),
        ("Step 2 Delivery", ["Radio option cards", "Free option lit cyan"], "cyan"),
        ("Step 3 Payment", ["Four method buttons", "Card form skeleton"], "cyan"),
        ("Step 4 Place", ["Pay button disables", "for about 2 seconds"], "amber"),
    ]
    xs = [96, 350, 604, 858, 1112, 1366, 1620]
    for i, (t, ls, tone) in enumerate(row):
        b.append(node(xs[i], 176, 228, 126, t, ls, tone))
        if i:
            b.append(arrow(xs[i - 1] + 228, 239, xs[i] - 4, 239))

    b.append(text(96, 372, "THE BANK BRANCH, ADDED PHASE 6", 13,
                  PALE["amber"][1], "700", spacing="0.14em"))
    b.append(node(96, 396, 300, 150, "Order number is held",
                  ["Issued BEFORE the bank step,",
                   "so a lost page is still",
                   "traceable by number."], "amber"))
    b.append(node(452, 396, 300, 150, "Challenge chrome",
                  ["Fixed bar at z-index",
                   "2147483647, moved to the end",
                   "of body so it wins the tie."], "amber"))
    b.append(node(808, 396, 300, 150, "Bank overlay",
                  ["The bank's own frame.",
                   "We never style inside it.",
                   "Cancel stays reachable."], "slate"))
    b.append(node(1164, 396, 300, 150, "Approved",
                  ["Confirmation view.",
                   "Order number, summary,",
                   "renewal note."], "green"))
    b.append(node(1520, 396, 328, 150, "Page was taken away",
                  ["Resume view polls the",
                   "payment service, or looks",
                   "the order up by number."], "violet"))
    for a, bx in ((396, 452), (752, 808), (1108, 1164)):
        b.append(arrow(a, 471, bx - 4, 471))
    # label pushed below the curve so it never sits on top of the Approved card
    b.append(arrow(1108, 500, 1520, 500, "the shopper came back to a different page",
                   dash="6 5", curve=(1314, 600), label_dy=112))

    b.append(text(96, 628, "WHAT THE SHOPPER SEES CHANGE", 13,
                  PALE["indigo"][1], "700", spacing="0.14em"))
    states = [
        ("Cart count badge", "Scales to 1.35 for one beat on every add."),
        ("Personal Volume meter", "Indigo to cyan fill; turns solid cyan and the "
                                  "note lights when 100 PV is reached."),
        ("Add button", "Label swaps to a tick, background goes solid cyan."),
        ("Pay button, disabled", "States BOTH colours, ink #0F172A on slate "
                                 "#64748B, instead of an opacity fade. Measures "
                                 "3.75 to 1: much better, still short of 4.5. "
                                 "See board 07."),
        ("Card form skeleton", "Holds the exact height of the real form so "
                               "nothing jumps when it arrives."),
        ("Page behind payment", "body.payment-in-flight really disables the "
                                "quantity, remove and pay controls."),
    ]
    y = 656
    for nme, why in states:
        b.append('<g id="%s">' % esc(uid("state-" + nme.lower().replace(" ", "-"))))
        b.append(rect(96, y, 1752, 52, PAPER, LINE, rx=8, sw=1))
        b.append(rect(96, y, 5, 52, PALE["cyan"][1], rx=2.5))
        b.append(text(120, y + 32, nme, 15, INK, "700"))
        b.append(text(452, y + 32, why, 14, BODY))
        b.append("</g>")
        y += 60

    board("02-shop-purchase-flow.svg", "Function, the shop and the checkout",
          "shop.html and product.html. Seven steps, one branch for the bank, "
          "and the six states the shopper actually watches change.", "".join(b))


# ================================================================ board 03
def board_portal():
    b = []
    b.append(node(96, 176, 260, 132, "Sign in",
                  ["login.html", "Glass card on the navy field",
                   "Error box collapses when empty"], "indigo"))
    b.append(arrow(356, 242, 424, 242))
    b.append(node(428, 176, 300, 132, "The Office, landing",
                  ["Identity rail, then five boards",
                   "stacked down the page",
                   "Tree demoted behind one control"], "cyan"))

    b.append(text(96, 372, "THE FIVE BOARDS OF THE OFFICE", 13,
                  PALE["cyan"][1], "700", spacing="0.14em"))
    boards = [
        ("Gate Board", ["Who is short, and by how much.",
                        "Open part of the scale is hatched,",
                        "never filled."], "cyan"),
        ("Momentum Board", ["Six months of volume.",
                            "Own is solid, customer is hatched.",
                            "Under 560 px it becomes six rows."], "indigo"),
        ("Rank Runway", ["Stops across the ranks, the current",
                         "one bold. Micro meters for each",
                         "unmet requirement."], "violet"),
        ("Earnings Mix", ["Five level fills. The label carries",
                          "its own dark chip so contrast",
                          "stops depending on the fill."], "violet"),
        ("The Wire", ["Company notices on a hanging rail.",
                      "One mark is lit. Self contained,",
                      "no outside feed."], "amber"),
    ]
    x = 96
    for t, ls, tone in boards:
        b.append(node(x, 396, 332, 150, t, ls, tone))
        x += 352

    b.append(text(96, 610, "THE FIVE TABS", 13, PALE["indigo"][1], "700",
                  spacing="0.14em"))
    tabs = [
        ("My Business", ["Team tree, hairline connectors",
                         "Customers drawn dashed, not solid"]),
        ("My Volume", ["Stacked bars, own plus customer",
                       "Hatch means an open gap"]),
        ("My Rank", ["Requirement list with met marks",
                     "Progress bar per requirement"]),
        ("My Statement", ["Sticky header table",
                          "Tabular numerals, level chips"]),
        ("Company", ["Rank spread bars",
                     "Distribution across the field"]),
    ]
    x = 96
    for t, ls in tabs:
        b.append(node(x, 634, 332, 118, t, ls, "slate"))
        x += 352

    b.append('<g id="Theme note">')
    b.append(rect(96, 800, 1752, 178, PALE["green"][0], PALE["green"][1], rx=14))
    b.append(text(120, 834, "THIS IS THE ONE PLACE WITH TWO THEMES", 13,
                  PALE["green"][1], "700", spacing="0.14em"))
    b.append(text(120, 866,
                  "portal.css defines the whole palette on bare :root as dark, "
                  "then html[data-theme=\"light\"] restates only the tokens that "
                  "must change.", 15, BODY))
    b.append(text(120, 892,
                  "The corrections of 2026-08-15: cyan text became #0E7490, "
                  "qualified green became #065F46, not qualified red became "
                  "#B91C1C, amber became #B45309.", 15, BODY))
    b.append(text(120, 918,
                  "Rule that came out of it: a colour may never be defined ONLY "
                  "inside a theme block. It is defined on bare :root first, then "
                  "restated.", 15, INK, "600"))
    b.append(text(120, 950,
                  "Second lesson, same day: cyan was swept alone, so green, red "
                  "and amber were missed. Sweep the whole palette, never one "
                  "token.", 15, INK, "600"))
    b.append("</g>")

    board("03-member-portal-flow.svg", "Function, the member portal",
          "site/index.html. One landing view, five boards, five tabs, and the "
          "only light theme in the system.", "".join(b))


# ================================================================ board 04
def board_staff():
    b = []
    b.append(text(96, 152, "THE CALL, LEFT TO RIGHT", 13, PALE["violet"][1],
                  "700", spacing="0.14em"))
    steps = [
        ("1  Lookup", ["Type ahead, arrow keys,",
                       "visible grabbable scrollbar"], "violet"),
        ("2  Snapshot", ["Name, code, rank chip,",
                         "qualified chip, four stats"], "violet"),
        ("3  Notes", ["Free text, saved per member",
                      "in this browser only"], "slate"),
        ("4  Quick order", ["Product, billing mode, quantity",
                            "then a line table and totals"], "violet"),
        ("5  Payment", ["Payment link is the",
                        "recommended path"], "amber"),
        ("6  Confirmation", ["Built to be read down",
                             "a phone line"], "green"),
    ]
    xs = [96, 396, 696, 996, 1296, 1596]
    for i, (t, ls, tone) in enumerate(steps):
        b.append(node(xs[i], 176, 274, 118, t, ls, tone))
        if i:
            b.append(arrow(xs[i - 1] + 274, 235, xs[i] - 4, 235))

    b.append(text(96, 360, "WHAT THE CONSOLE REFUSES TO DO", 13,
                  PALE["red"][1], "700", spacing="0.14em"))
    b.append(node(96, 384, 560, 172, "Agent rule card, always on screen",
                  ["A red bordered card sits above the payment",
                   "controls so the standing rules never need a",
                   "manual: the link path first, never read a card",
                   "number back, never finish a bank approval on",
                   "behalf of the caller."], "red"))
    b.append(node(688, 384, 560, 172, "Waiting on the bank, said honestly",
                  ["An amber card that states plainly that only the",
                   "cardholder can finish the approval, shows the",
                   "order number in monospace, and offers an",
                   "abandon control so nothing is left sitting",
                   "in limbo."], "amber"))
    b.append(node(1280, 384, 568, 172, "Read aloud confirmation",
                  ["Order number set huge in monospace, a phonetic",
                   "spelling under it, and say blocks: short scripted",
                   "lines with a cyan left rule, written to be spoken",
                   "word for word rather than summarised."], "green"))

    b.append(text(96, 620, "HOW THE CONSOLE DIFFERS FROM THE SHOP, ON PURPOSE",
                  13, PALE["indigo"][1], "700", spacing="0.14em"))
    diffs = [
        ("Width", "1240 px work surface, against 1100 px for marketing."),
        ("Glow", "One calm wash at roughly a third of the marketing dose."),
        ("Motion", "No reveal animations at all. Work tools do not perform."),
        ("Density", "16 to 18 px panel padding, against 30 to 36 px."),
        ("Primary button", "Indigo #4F46E5 with white text, not the cyan of the shop."),
        ("Focus", "A 2 px cyan outline with 1 px offset on every field."),
        ("Contrast", "Every interactive colour is annotated in the file with its "
                     "measured ratio."),
    ]
    y = 648
    for k, v in diffs:
        b.append('<g id="%s">' % esc(uid("diff-" + k.lower().replace(" ", "-"))))
        b.append(rect(96, y, 1752, 44, PAPER, LINE, rx=8, sw=1))
        b.append(rect(96, y, 5, 44, PALE["violet"][1], rx=2.5))
        b.append(text(120, y + 28, k, 15, INK, "700"))
        b.append(text(392, y + 28, v, 14, BODY))
        b.append("</g>")
        y += 52

    board("04-staff-console-flow.svg", "Function, the staff call console",
          "staff.html. Six steps of a phone call, three cards that keep the "
          "agent inside the rules, and the deliberate differences from the shop.",
          "".join(b))


# ================================================================ board 05
SWATCH_CORE = [
    ("--navy",     "#060B18", "Page field, every www page", "dark"),
    ("--navy-2",   "#0A1226", "Raised field, lists and chrome bars", "dark"),
    ("--ink",      "#0F172A", "Ink on light, and on disabled buttons", "dark"),
    ("--indigo",   "#4F46E5", "Structure on light, primary button in console", "dark"),
    ("--indigo-d", "#818CF8", "Indigo on dark: hairlines, marks, scrollbar", "dark"),
    ("--indigo-l", "#A5B4FC", "Small text on dark, 7.4 to 1 on navy", "dark"),
    ("--violet",   "#A78BFA", "Third accent, bundles and company", "dark"),
    ("--cyan",     "#22D3EE", "THE single lit accent", "dark"),
    ("--paper",    "#FFFFFF", "Paper, and text on indigo buttons", "light"),
    ("--text-d",   "#C7D0DE", "Body text on dark", "dark"),
    ("--muted-d",  "#94A3B8", "Muted text on dark, 7.4 to 1 on navy", "dark"),
]

SWATCH_LIT = [
    ("#F1F5F9", "Headings on dark", "dark"),
    ("#E2E8F0", "Field and table text on dark", "dark"),
    ("#05121C", "Ink on a cyan button, 10.7 to 1", "dark"),
    ("#67E3F4", "Cyan hover, solid buttons", "dark"),
    ("#67E8F9", "Cyan TEXT in the console, 9.6 to 1", "dark"),
    ("#7C8AA0", "Legal and not yet, 5.61 to 1 on navy", "dark"),
    ("#64748B", "Disabled button field", "dark"),
    ("#8B99AF", "Placeholder text, 4.9 to 1 in a field", "dark"),
    ("#34D399", "Good, qualified", "dark"),
    ("#F87171", "Bad, declined, remove", "dark"),
    ("#FACC15", "Waiting, bank approval in flight", "dark"),
    ("#050914", "Footer field, one step under navy", "dark"),
]

SWATCH_PORTAL = [
    ("--bg",        "#0F172A", "#F1F5F9"),
    ("--bg-soft",   "#1E293B", "#FFFFFF"),
    ("--bg-inset",  "#16223A", "#F8FAFC"),
    ("--line",      "#334155", "#CBD5E1"),
    ("--text",      "#E2E8F0", "#0F172A"),
    ("--muted",     "#94A3B8", "#475569"),
    ("--indigo-soft", "#818CF8", "#4F46E5"),
    ("--cyan",      "#22D3EE", "#0E7490"),
    ("--good",      "#34D399", "#065F46"),
    ("--bad",       "#F87171", "#B91C1C"),
    ("--amber",     "#FBBF24", "#B45309"),
    ("--violet",    "#C084FC", "#7C3AED"),
]


def board_tokens():
    b = []
    b.append(text(96, 152, "CORE TOKENS, corporate.css :root", 13,
                  PALE["indigo"][1], "700", spacing="0.14em"))
    y = 172
    for i, (nme, hexv, role, _) in enumerate(SWATCH_CORE):
        col = i % 2
        row = i // 2
        x = 96 + col * 880
        yy = y + row * 62
        b.append('<g id="%s">' % esc(uid("token-" + nme.strip("-"))))
        b.append(rect(x, yy, 852, 54, PAPER, LINE, rx=8, sw=1))
        b.append(rect(x + 8, yy + 8, 38, 38, hexv, LINE, rx=6, sw=1))
        b.append(text(x + 60, yy + 24, nme, 14, INK, "700", font=MONO))
        b.append(text(x + 60, yy + 43, hexv, 13, MUTED, font=MONO))
        b.append(text(x + 210, yy + 34, role, 14, BODY))
        b.append("</g>")

    b.append(text(96, 566, "LITERAL COLOURS THAT ARE NOT TOKENS BUT ARE LOAD BEARING",
                  13, PALE["cyan"][1], "700", spacing="0.14em"))
    y = 586
    for i, (hexv, role, _) in enumerate(SWATCH_LIT):
        col = i % 3
        row = i // 3
        x = 96 + col * 586
        yy = y + row * 58
        b.append('<g id="%s">' % esc(uid("literal-" + hexv.strip("#"))))
        b.append(rect(x, yy, 558, 50, PAPER, LINE, rx=8, sw=1))
        b.append(rect(x + 8, yy + 8, 34, 34, hexv, LINE, rx=6, sw=1))
        b.append(text(x + 52, yy + 22, hexv, 13.5, INK, "700", font=MONO))
        b.append(text(x + 52, yy + 40, role, 12.5, MUTED))
        b.append("</g>")

    b.append(text(96, 846, "TYPE SCALE, SPACING, RADIUS, ELEVATION", 13,
                  PALE["violet"][1], "700", spacing="0.14em"))
    b.append('<g id="Type scale">')
    b.append(rect(96, 866, 852, 118, WASH, LINE, rx=10, sw=1))
    b.append(text(116, 894, "Hero  clamp(1.9rem, 4.6vw, 3.1rem)  700  0.09em  UPPERCASE",
                  14, INK, "600"))
    b.append(text(116, 916, "Section  clamp(1.45rem, 3vw, 2.05rem)  700  0.10em  UPPERCASE",
                  14, BODY))
    b.append(text(116, 938, "Kicker  0.78rem  600  0.34em   |   Card title  1.02rem  700  0.12em",
                  14, BODY))
    b.append(text(116, 960, "Body  16 px / 1.7  400   |   Console body 15 px / 1.45   |   "
                            "Numbers always tabular", 14, BODY))
    b.append("</g>")
    b.append('<g id="Spacing radius elevation">')
    b.append(rect(996, 866, 852, 118, WASH, LINE, rx=10, sw=1))
    b.append(text(1016, 894, "Spacing  6 8 10 12 14 16 18 22 26 28 32 36 44 56 64 84 104 px",
                  14, BODY))
    b.append(text(1016, 916, "Radius  4 small chip, 8 control, 9 to 10 field, 12 to 14 panel, "
                             "999 pill", 14, BODY))
    b.append(text(1016, 938, "Elevation on dark is GLOW, not shadow: 0 0 26px indigo at 0.14",
                  14, BODY))
    b.append(text(1016, 960, "Elevation on light is a real shadow: 0 4px 14px ink at 0.10",
                  14, BODY))
    b.append("</g>")

    board("05-design-tokens.svg", "The palette, the type scale, the rhythm",
          "Every value read straight out of corporate.css and portal.css on "
          "2026-08-15. Swatches are the real hex values.", "".join(b))


# ================================================================ board 06
def board_components():
    b = []
    comps = [
        ("Button, solid", "cyan", [
            "Cyan field, ink #05121C label, 8 px radius.",
            "Hover lifts 2 px and widens the glow.",
            "Where: every primary action in shop and site."]),
        ("Button, ghost", "indigo", [
            "Dark gradient field, indigo border, #E2E8F0 label.",
            "Hover swaps the border and label to cyan.",
            "Where: secondary actions, back, cancel."]),
        ("Button, disabled", "slate", [
            "STATES BOTH COLOURS: #0F172A on #64748B. Measures 3.75 to 1.",
            "Never an opacity fade, which measured 1.70 to 1.",
            "Where: the pay button, for about 2 seconds, every payment."]),
        ("Glass panel", "indigo", [
            "Translucent gradient, 1 px luminous border, 14 px radius,",
            "outer glow plus a 1 px inset highlight along the top.",
            "Where: every card, every panel, the login card."]),
        ("Product card", "cyan", [
            "Icon, tier badge, name, description, price row, add button.",
            "Hover lifts 5 px and the border turns cyan.",
            "Where: the three tier bands of the shop."]),
        ("Summary row", "slate", [
            "Name left, amount right, tabular numerals, hairline under.",
            "Children indent 16 px and read Included at $0.00.",
            "Where: cart drawer, checkout summary, confirmation."]),
        ("Badge and pill", "violet", [
            "999 px radius, 0.6 to 0.7 rem, 700, wide tracking.",
            "Tier, billing mode, rank, qualified, demo, included.",
            "Where: everywhere a row needs a one word fact."]),
        ("Meter", "cyan", [
            "8 px track, indigo to cyan fill, turns solid cyan and lights",
            "its note when the 100 Personal Volume gate is met.",
            "Where: cart drawer, checkout summary, staff totals."]),
        ("Form field", "indigo", [
            "Field 12 px by 14 px, 8 px radius, dark inset background.",
            "Focus: cyan border plus a 3 px cyan ring. Console uses a",
            "2 px cyan outline instead. Placeholder #8B99AF, 4.9 to 1."]),
        ("Table", "slate", [
            "Sticky uppercase header, 1 px row rules, tabular numerals,",
            "monospace for codes, wide content scrolls in its own box.",
            "Where: statement table, console order lines."]),
        ("Challenge chrome", "amber", [
            "Fixed bar at the clamped maximum z-index 2147483647, moved",
            "to the end of body so it wins the tie on document order.",
            "Carries the order number, the notice and cancel."]),
        ("Skeleton", "slate", [
            "42 px bars that hold the exact height of the real card form",
            "and pulse at 1.4 s. The pulse stops under reduced motion.",
            "Where: the roughly 2 seconds before the card form arrives."]),
    ]
    x0, y0 = 96, 152
    for i, (t, tone, ls) in enumerate(comps):
        col = i % 3
        row = i // 3
        x = x0 + col * 586
        y = y0 + row * 214
        b.append(node(x, y, 558, 190, t, ls, tone, tsize=18, lsize=13.5))

    board("06-component-inventory.svg", "The component inventory",
          "Twelve components that make up every screen in the pilot. What each "
          "looks like, and where it appears.", "".join(b))


# ================================================================ board 07
def board_theming():
    b = []
    b.append(text(96, 152, "THE RULE", 13, PALE["green"][1], "700",
                  spacing="0.14em"))
    b.append('<g id="The rule">')
    b.append(rect(96, 172, 1752, 128, PALE["green"][0], PALE["green"][1], rx=14))
    b.append(text(120, 208,
                  "A colour is NEVER defined only inside a media query or a "
                  "data-theme block.", 21, INK, "700"))
    b.append(text(120, 240,
                  "Define the complete palette on bare :root. A theme block may "
                  "only RESTATE a token that already exists there.", 15, BODY))
    b.append(text(120, 266,
                  "If a token exists only inside a theme block, every viewer "
                  "outside that theme gets an empty value and the browser falls "
                  "back to something nobody chose.", 15, BODY))
    b.append("</g>")

    b.append(text(96, 348, "THE TWO CORRECTIONS OF 2026-08-15", 13,
                  PALE["red"][1], "700", spacing="0.14em"))

    b.append('<g id="Correction one disabled button">')
    b.append(rect(96, 368, 858, 320, PAPER, LINE, rx=14, sw=1.5))
    b.append(rect(96, 368, 858, 42, PALE["red"][0], rx=14))
    b.append(text(120, 396, "ONE  The disabled button", 16, PALE["red"][1], "700"))
    b.append(text(120, 442, "BEFORE", 12, MUTED, "700", spacing="0.12em"))
    b.append(rect(120, 456, 240, 44, "#8FE9F6", "#CBD5E1", rx=8, sw=1))
    b.append(text(240, 484, "Pay now", 15, "#7FA0AA", "700", anchor="middle"))
    b.append(text(120, 522, "opacity: 0.45 on ink over cyan", 13.5, BODY, font=MONO))
    b.append(text(120, 544, "1.70 to 1.  Fails the 4.5 to 1 floor.", 14,
                  PALE["red"][1], "700"))
    b.append(text(500, 442, "AFTER", 12, MUTED, "700", spacing="0.12em"))
    b.append(rect(500, 456, 240, 44, "#64748B", "#CBD5E1", rx=8, sw=1))
    b.append(text(620, 484, "Pay now", 15, "#0F172A", "700", anchor="middle"))
    b.append(text(500, 522, "#0F172A on #64748B, opacity 1", 13.5, BODY, font=MONO))
    b.append(text(500, 544, "3.75 to 1.  Still short of 4.5.", 14,
                  PALE["amber"][1], "700"))
    b.append(text(120, 578,
                  "Why it mattered: payment now opens automatically, so the pay",
                  13.5, BODY))
    b.append(text(120, 596,
                  "button sits disabled for about two seconds on EVERY payment.",
                  13.5, BODY))
    b.append(text(120, 614,
                  "The least readable state became one of the most seen.",
                  13.5, BODY))
    b.append(text(120, 640, "OPEN: the comment claims 4.63 to 1. It does not "
                            "reproduce.", 13, INK, "700"))
    b.append(text(120, 658, "Measured 3.75 to 1. Lightening the field to "
                            "#7C8AA0, already a", 12.5, PALE["red"][1], "700"))
    b.append(text(120, 674, "token here, keeps the ink and gives 5.10 to 1.",
                  12.5, PALE["red"][1], "700"))
    b.append("</g>")

    b.append('<g id="Correction two light theme">')
    b.append(rect(990, 368, 858, 320, PAPER, LINE, rx=14, sw=1.5))
    b.append(rect(990, 368, 858, 42, PALE["amber"][0], rx=14))
    b.append(text(1014, 396, "TWO  The light theme of the portal", 16,
                  PALE["amber"][1], "700"))
    rows = [
        ("--cyan",  "#22D3EE", "1.73", "#0E7490", "5.36"),
        ("--good",  "#34D399", "3.28", "#065F46", "6.72"),
        ("--bad",   "#F87171", "4.12", "#B91C1C", "5.53"),
        ("--amber", "#FBBF24", "1.67", "#B45309", "5.02"),
    ]
    b.append(text(1014, 438, "TOKEN", 11.5, MUTED, "700", spacing="0.1em"))
    b.append(text(1160, 438, "WAS", 11.5, MUTED, "700", spacing="0.1em"))
    b.append(text(1420, 438, "NOW", 11.5, MUTED, "700", spacing="0.1em"))
    yy = 458
    for tok, was, wr, now, nr in rows:
        b.append(rect(1014, yy, 812, 34, WASH, None, rx=6))
        b.append(text(1024, yy + 23, tok, 13, INK, "700", font=MONO))
        b.append(rect(1160, yy + 8, 18, 18, was, "#CBD5E1", rx=4, sw=1))
        b.append(text(1186, yy + 23, was, 12.5, BODY, font=MONO))
        b.append(text(1290, yy + 23, wr + " to 1", 12.5, PALE["red"][1], "700"))
        b.append(rect(1420, yy + 8, 18, 18, now, "#CBD5E1", rx=4, sw=1))
        b.append(text(1446, yy + 23, now, 12.5, BODY, font=MONO))
        b.append(text(1550, yy + 23, nr + " to 1", 12.5, PALE["green"][1], "700"))
        yy += 40
    b.append(text(1014, 638 - 18,
                  "Cyan was fixed in the morning. Green, red and amber were "
                  "missed because only cyan was swept.", 13.5, INK, "600"))
    b.append("</g>")

    b.append(text(96, 718, "HOW THE TWO THEMES ARE ACTUALLY WIRED", 13,
                  PALE["indigo"][1], "700", spacing="0.14em"))
    b.append(node(96, 740, 400, 150, "1  Bare :root",
                  ["The COMPLETE palette lives here.",
                   "In the portal that palette is the",
                   "dark one, because dark is the",
                   "default the member sees."], "indigo"))
    b.append(arrow(496, 815, 556, 815))
    b.append(node(560, 740, 400, 150, "2  html[data-theme=\"light\"]",
                  ["Restates ONLY the tokens that",
                   "must change. Twenty two of them.",
                   "It never introduces a token that",
                   "bare :root has not already set."], "cyan"))
    b.append(arrow(960, 815, 1020, 815))
    b.append(node(1024, 740, 400, 150, "3  A button flips it",
                  ["The theme button writes the",
                   "attribute on <html>. Nothing else",
                   "in the page knows or cares which",
                   "theme is running."], "violet"))
    b.append(arrow(1424, 815, 1484, 815))
    b.append(node(1488, 740, 360, 150, "4  Drawings follow",
                  ["Chart fills resolve through",
                   "drawing tokens, so a chart",
                   "restates itself with the theme",
                   "instead of being redrawn."], "green"))

    b.append('<g id="Where light exists">')
    b.append(rect(96, 892, 1752, 96, PALE["slate"][0], LINE, rx=14))
    b.append(text(120, 922, "AND WHERE LIGHT DOES NOT EXIST", 13,
                  PALE["slate"][1], "700", spacing="0.14em"))
    b.append(text(120, 952,
                  "Only the member portal has two themes. The corporate site, "
                  "the shop, the product page, the login page and the staff "
                  "console are dark only, on purpose:", 14.5, BODY))
    b.append(text(120, 974,
                  "the glow language IS the brand, and a light version of it "
                  "would be a second design system to maintain rather than a "
                  "second theme.", 14.5, BODY))
    b.append("</g>")

    board("07-theming-and-contrast.svg", "Theming, and the accessibility floor",
          "One rule, two corrections made on 2026-08-15, and the four steps "
          "that make the light theme work.", "".join(b))


if __name__ == "__main__":
    if not os.path.isdir(OUT):
        os.makedirs(OUT)
    board_system()
    board_shop()
    board_portal()
    board_staff()
    board_tokens()
    board_components()
    board_theming()
    print("done")
