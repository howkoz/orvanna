/* ============================================================
   ORVANNA CONTRAST SWEEP
   docs/verification/contrast-sweep.js

   The script that produced CONTRAST-SWEEP-2026-08-17.md. It
   ships beside the numbers so that anybody can re-check them
   without redoing the work, which is the whole reason it exists:
   the round before this one reported its figures in a commit
   message and two of them could not be reproduced.

   HOW TO RUN
     1. Serve MLM-PILOT/www over a local server.
     2. Set the theme you want to measure BEFORE loading a page:
          localStorage.setItem('orvanna-theme', 'light');
        then RELOAD. Never flip data-theme at runtime and read
        immediately: that returns mid-transition colours and
        invents defects that are not there. Both gates fell into
        that trap on 2026-08-17.
     3. Paste this file into the console and call:
          orvannaContrastSweep()            all rows
          orvannaContrastSweep({ max: 6 })  only rows under 6.0

   WHAT IT MEASURES
     Every element that carries its own text node. For each one
     it composites the ancestor chain down to an opaque backdrop,
     resolving both rgba() alpha and gradient backgrounds, then
     applies the Web Content Accessibility Guidelines (WCAG)
     relative-luminance and contrast formulas.

   WHAT IT EXCLUDES, deliberately and by name
     - invisible elements: display:none, visibility:hidden,
       zero opacity, zero-sized boxes
     - anything inside a disabled or aria-disabled ancestor,
       which WCAG success criterion 1.4.3 exempts
     - the third-party chat vendor's own markup
     - text painted with background-clip, which has no colour to
       read. index.html's hero title is the only one; its figures
       are recorded by hand in the report.

   Acronym key: WCAG (Web Content Accessibility Guidelines).
   ============================================================ */
window.orvannaContrastSweep = function (options) {
  'use strict';
  var opts = options || {};
  var cap = typeof opts.max === 'number' ? opts.max : Infinity;

  function parseColour(value) {
    var m = String(value).match(/rgba?\(([^)]+)\)/);
    if (!m) { return null; }
    var p = m[1].split(',').map(parseFloat);
    return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 };
  }

  /* A gradient has no single colour. Averaging its opaque stops
     is an approximation, and it is a far better one than ignoring
     the gradient and measuring against whatever sits behind it. */
  function gradientAverage(backgroundImage) {
    var stops = String(backgroundImage).match(/rgba?\([^)]+\)/g);
    if (!stops || !stops.length) { return null; }
    var cs = stops.map(parseColour).filter(function (c) { return c && c.a > 0.5; });
    if (!cs.length) { return null; }
    function mean(k) {
      return cs.reduce(function (a, c) { return a + c[k]; }, 0) / cs.length;
    }
    return { r: mean('r'), g: mean('g'), b: mean('b'), a: 1 };
  }

  /* Standard source-over compositing. */
  function over(fg, bg) {
    return {
      r: fg.r * fg.a + bg.r * (1 - fg.a),
      g: fg.g * fg.a + bg.g * (1 - fg.a),
      b: fg.b * fg.a + bg.b * (1 - fg.a),
      a: 1
    };
  }

  function backdrop(el) {
    var acc = null, node = el;
    while (node && node.nodeType === 1) {
      var cs = getComputedStyle(node);
      var layer = parseColour(cs.backgroundColor);
      if (cs.backgroundImage && cs.backgroundImage !== 'none') {
        var g = gradientAverage(cs.backgroundImage);
        if (g) { layer = (layer && layer.a > 0) ? over(layer, g) : g; }
      }
      if (layer && layer.a > 0) { acc = acc ? over(acc, layer) : layer; }
      if (acc && acc.a >= 0.999) { return acc; }
      node = node.parentElement;
    }
    /* Nothing opaque all the way up: the page sits on the
       browser's own white canvas. */
    return over(acc || { r: 0, g: 0, b: 0, a: 0 }, { r: 255, g: 255, b: 255, a: 1 });
  }

  function luminance(c) {
    function channel(v) {
      v = v / 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    }
    return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  }

  function contrast(a, b) {
    var la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }

  function hasOwnText(el) {
    for (var i = 0; i < el.childNodes.length; i++) {
      var n = el.childNodes[i];
      if (n.nodeType === 3 && n.textContent.trim()) { return true; }
    }
    return false;
  }

  function rgb(c) {
    return 'rgb(' + Math.round(c.r) + ',' + Math.round(c.g) + ',' + Math.round(c.b) + ')';
  }

  var rows = [];
  Array.prototype.forEach.call(document.querySelectorAll('body *'), function (el) {
    if (!hasOwnText(el)) { return; }
    if (el.matches('script, style, title, noscript')) { return; }
    if (el.closest('[disabled], [aria-disabled="true"], .bpFab, [class*="bp"]')) { return; }

    var cs = getComputedStyle(el);
    if (cs.display === 'none' || cs.visibility === 'hidden') { return; }
    if (parseFloat(cs.opacity) === 0) { return; }

    var box = el.getBoundingClientRect();
    if (box.width < 1 || box.height < 1) { return; }

    var fg = parseColour(cs.color);
    if (!fg || fg.a === 0) { return; }

    var bg = backdrop(el);
    var ink = fg.a < 1 ? over(fg, bg) : fg;

    var px = parseFloat(cs.fontSize);
    var bold = parseInt(cs.fontWeight, 10) >= 700;
    var large = px >= 24 || (bold && px >= 18.66);
    var floor = large ? 3 : 4.5;
    var ratio = contrast(ink, bg);

    rows.push({
      page: location.pathname.replace(/^\//, '') || 'index.html',
      theme: document.documentElement.getAttribute('data-theme') || 'dark',
      selector: el.tagName.toLowerCase() + (typeof el.className === 'string' && el.className.trim()
        ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : ''),
      text: (el.textContent || '').trim().slice(0, 40),
      foreground: rgb(ink),
      background: rgb(bg),
      fontPx: Number(px.toFixed(2)),
      largeText: large,
      ratio: Number(ratio.toFixed(3)),
      floor: floor,
      pass: ratio >= floor
    });
  });

  rows.sort(function (a, b) { return a.ratio - b.ratio; });
  var kept = rows.filter(function (r) { return r.ratio < cap; });
  var failures = rows.filter(function (r) { return !r.pass; });

  return {
    page: rows.length ? rows[0].page : location.pathname,
    theme: document.documentElement.getAttribute('data-theme') || 'dark',
    measured: rows.length,
    failures: failures.length,
    minimum: rows.length ? rows[0].ratio : null,
    failing: failures,
    rows: kept
  };
};
