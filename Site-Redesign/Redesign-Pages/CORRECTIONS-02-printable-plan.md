# Wiring the printable plan into orvanna.io

Two files, one anchor. Nothing here needs a build step.

## 1. The file

`Compensation Plan PDF.dc.html` is the printable full plan. Save it into the repo root as:

```
comp-plan-print.html
```

That name is what the links in the redesigned plan page already point at. If you'd rather call it something else, change it in both places.

It is a self-contained static page: no site chrome, no `css/` dependency, its own print geometry. It belongs in `DOCUMENT_PAGES` in `deploy/build_dist.py`, alongside `plan-brochure.html` — same category, same reason (self-contained, no chrome, prints).

## 2. The anchor on `comp-plan.html`

The existing page already has the right pattern for this — the `.note` block above the contents that points at `plan-brochure.html`. Put the printable plan in the same place, immediately after it:

```html
<div class="note lit">
  <p><strong>Need the whole plan on paper?</strong> The complete plan &mdash; both parts,
  all twenty-four sections, every worked example &mdash; is set as a printable
  document. <a href="comp-plan-print.html">Open the printable compensation plan</a>.</p>
  <p class="small">Same rules, same numbers, laid out for print rather than for
  scrolling. Your browser's Print command saves it as a PDF with no further setup.</p>
</div>
```

Placing it there rather than at the foot of the page is deliberate: a reader deciding whether to commit to a long document should be offered the alternatives *before* they start, which is the reason the `plan-brochure.html` link already sits there.

## 3. Optional: the cover button

`comp-plan.html`'s cover carries a `Print this brochure` button (`#printBtn`) and a `Contents` link, both `.chrome-btn`. A third fits the row without any new CSS:

```html
<a class="chrome-btn" href="comp-plan-print.html" style="text-decoration:none;">Printable full plan</a>
```

## 4. One thing to correct while you are in there

The rank thresholds in section eleven are the source of truth and the printable plan matches them: Leader is Team Volume 2,500.00 with 3 or more active legs; Executive is Team Volume 40,000.00 with 2 or more legs each containing a Leader or higher. If any other surface in the site states different figures, section eleven wins.
