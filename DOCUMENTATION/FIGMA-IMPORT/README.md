# FIGMA-IMPORT

Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\FIGMA-IMPORT\`

Everything in this folder is a drag-and-drop pack for Figma. Nothing here needs a
build step, a plugin licence, or an internet connection.

---

## Read this first: which route was taken

Howard asked for a Figma flow of the whole system and of each function. The Figma
connection **was** authorised in this session, so the real file was built. You now
have BOTH of the following, and they are different things:

| What | Where | What it is |
|---|---|---|
| **A real Figma board** | https://www.figma.com/board/m4qgXgmSqjOjLTuhflVj5L | A live FigJam file in the `howardk` team, built object by object. Five boards, real connectors, real text, plus 28 real Figma colour variables with Dark and Light modes. |
| **This folder** | the files listed below | A self contained backup and print pack. Seven boards as clean layered `.svg`, plus the tokens as JSON. Works with no Figma account at all. |

The Figma board is the living copy. This folder is the copy that survives without
Figma, drops into Snagit cleanly, and can be re-imported if the board is ever lost.

Board titled **Orvanna System Flows and Design System**. It contains:

| Section in the Figma file | Covers |
|---|---|
| `01  The whole system` | Three lanes of user, seven steps each, one shared foundation strip |
| `02  Function, the shop and the checkout` | The seven step happy path, the bank approval branch, six states the shopper watches change |
| `03  Function, the member portal` | Sign in, the Office landing, the five boards, the five tabs, the theming note |
| `04  Function, the staff call console` | Six call steps, three cards that keep the agent inside the rules, the differences from the shop |
| `05  The palette and the rhythm` | Core token swatches, load bearing literals, the four light theme corrections, the type and spacing scale |

There is an older, separate FigJam board called **The Whole Machine**, built
2026-08-13, which explains the product and the factory side by side. It is listed in
`MLM-PILOT\docs\FIGMA-VISUAL-PACK.md` and is untouched. The new file sits beside it
rather than replacing it: that one explains the business, this one explains the
build.

---

## What is in this folder

| File | What it is |
|---|---|
| `01-system-flow.svg` | The whole system, three lanes |
| `02-shop-purchase-flow.svg` | The shop and the checkout, including the bank approval branch |
| `03-member-portal-flow.svg` | The member portal |
| `04-staff-console-flow.svg` | The staff call console |
| `05-design-tokens.svg` | The palette, the type scale, the rhythm |
| `06-component-inventory.svg` | Twelve components, what each looks like and where it appears |
| `07-theming-and-contrast.svg` | Theming, and the two accessibility corrections of 2026-08-15 |
| `design-tokens.json` | Every colour, type, spacing and radius token, in a format Figma variable importers read |

Boards 06 and 07 exist **only** in this folder. They were not rebuilt in the Figma
file, because the component inventory and the theming rules read better as a
reference sheet than as a flow. If you want them in Figma, use the import steps
below, which is exactly what they are sized for.

---

## Step by step: importing the SVG boards into Figma

Each board is **1920 by 1080**, which is the standard Figma desktop frame size. They
arrive as frames, not as flat pictures.

### Into a Figma design file

1. Open Figma and create or open a design file.
2. Open Windows File Explorer at the plain path at the top of this document.
3. Select the `.svg` files you want. You can select all seven at once.
4. Drag them onto the Figma canvas and drop.
5. Figma places each file as its own frame, 1920 by 1080.

### Into FigJam

Same drag and drop. FigJam accepts SVG and keeps the layer structure. FigJam will
not give you Figma variables, so if you want the tokens as variables, use a design
file.

### The alternative, if dragging misbehaves

In Figma: `File` then `Import`, then pick the `.svg` files. Same result. Some
corporate machines block drag and drop between Explorer and a browser tab; the
desktop app does not have that problem.

---

## What you will actually get

This matters, because SVG can arrive in Figma as one unusable blob if it is authored
carelessly. These were authored specifically to avoid that.

**You will get:**

- One **frame** per board, 1920 by 1080, named after the file.
- **Named groups** inside it. Every group carries an `id`, and Figma turns the `id`
  into the layer name. So you will see layers called `Lane 1 visitor`,
  `node-corporate-site`, `Shared foundation`, `Correction one disabled button`, and
  so on, rather than `Group 47`.
- **Real editable text.** Every label is a live text layer. Click it and retype it.
  It is not outlined and it is not a picture of text.
- **Real editable shapes.** Every box, rule and arrow is a vector you can recolour,
  move or delete.
- **Flat hardcoded colours.** Every fill is a literal hex value. There are no CSS
  variables, no `currentColor`, and no dark mode, so what you see in Figma is exactly
  what you see in Explorer, in a browser, and in a Snagit grab.

**You will not get:**

- **Auto layout.** SVG has no concept of it. Boxes are absolutely positioned. If you
  want a board to reflow, wrap the groups in auto layout yourself after import.
- **Components.** These are drawings of the design system, not a component library.
  The real component library is the CSS in `MLM-PILOT\www\css\`.
- **The exact fonts.** Text will land in whatever Figma resolves from the
  `Inter, 'Segoe UI', sans-serif` stack, which is normally Inter. The live product
  uses the Segoe UI stack. Select all and change the family if the difference
  matters. It does not change any measurement in the document.

---

## Step by step: importing the tokens as Figma variables

`design-tokens.json` is written in the Design Tokens Community Group draft format,
which uses `$type` and `$value`. That is the format the common importers read.

### Using Tokens Studio for Figma, the usual choice

1. In Figma, open `Plugins`, then run **Tokens Studio for Figma**.
2. Choose `Settings`, then `File`, then `Import`.
3. Pick `design-tokens.json` from this folder.
4. Choose `Styles and Variables`, then `Create variables`.
5. Tokens Studio writes a variable collection into the file.

### Using any variable importer plugin

Most of them ask for a JSON file and a collection name. Point them at
`design-tokens.json` and name the collection `Orvanna colour`. If a plugin rejects
the `$` prefixed keys, it is an older plugin expecting `value` and `type` without the
dollar signs; update the plugin rather than editing the file, because the dollar
prefixed form is the current standard.

### Or skip the plugin entirely

The Figma board listed at the top of this document **already has 28 real colour
variables**, in a collection called `Orvanna colour`, with two modes named `Dark` and
`Light`. Switching the mode switches every bound colour, exactly as the real portal
does. If that is all you needed, you do not need a plugin at all: open the board and
use the variables that are already there.

### One thing the JSON cannot carry

Figma variables cannot hold a gradient or a multi part shadow. The glass panel
recipe, the glow values and the accent bar gradient are therefore listed under
`effect` in the JSON as text, for a human to rebuild as Figma effect styles. Each one
records the exact CSS it came from.

---

## How these files were made, if they need regenerating

The seven SVG boards are generated, not hand drawn, so they can be rebuilt from the
stylesheets if the design changes. The generator sits in this folder:

`C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\FIGMA-IMPORT\build_figma_boards.py`

Run it from anywhere:

```
py "C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\FIGMA-IMPORT\build_figma_boards.py"
```

It writes the seven boards beside itself and overwrites the previous set. Use `py`,
not `python`, on this machine. Editing a board by hand is fine for a one off, but the
next run will overwrite it, so put lasting changes in the generator.

---

## House rules these files follow

- No em dashes and no en dashes anywhere.
- Every acronym is written out on first use: Personal Volume (PV), 3-D Secure (3DS),
  scalable vector graphics (SVG).
- White background, pale fills, dark text, no dark mode, so a Snagit grab is clean.
- Nothing is claimed that does not exist. The Figma board named above is real and was
  built in this session; the two boards that exist only as SVG are named as such.
