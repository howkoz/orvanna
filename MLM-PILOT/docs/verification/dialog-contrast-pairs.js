/* Read every rendered text node in the wallet and Plaid dialogs, take its
   COMPUTED colour against its nearest painted background, and report any pair
   under the floor. Computed, not parsed: a stylesheet cannot tell you which
   rule won. */
const { chromium } = require('/opt/node22/lib/node_modules/playwright');

const PROBE = `(() => {
  function lum(rgb) {
    const f = v => { v /= 255; return v <= 0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); };
    return 0.2126*f(rgb[0]) + 0.7152*f(rgb[1]) + 0.0722*f(rgb[2]);
  }
  function parse(c) {
    const m = c.match(/rgba?\\(([^)]+)\\)/); if (!m) return null;
    const p = m[1].split(',').map(s => parseFloat(s));
    return { rgb: [p[0],p[1],p[2]], a: p.length > 3 ? p[3] : 1 };
  }
  function bgOf(el) {
    let n = el;
    while (n && n !== document.documentElement) {
      const c = parse(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0.85) return c.rgb;
      n = n.parentElement;
    }
    return [255,255,255];
  }
  function ratio(a, b) {
    const la = lum(a), lb = lum(b), hi = Math.max(la,lb), lo = Math.min(la,lb);
    return (hi + 0.05) / (lo + 0.05);
  }
  const out = [];
  document.querySelectorAll('#walletPanel *, #plaidPanel *').forEach(el => {
    const text = Array.from(el.childNodes)
      .filter(n => n.nodeType === 3 && n.textContent.trim())
      .map(n => n.textContent.trim()).join(' ');
    if (!text) return;
    const cs = getComputedStyle(el);
    if (cs.display === 'none' || cs.visibility === 'hidden') return;
    const fg = parse(cs.color); if (!fg) return;
    const bg = bgOf(el);
    const size = parseFloat(cs.fontSize);
    const bold = (parseInt(cs.fontWeight,10) || 400) >= 700;
    const large = size >= 24 || (size >= 18.66 && bold);
    const floor = large ? 3 : 4.5;
    const r = ratio(fg.rgb, bg);
    if (r < floor) out.push({
      text: text.slice(0, 44),
      fg: cs.color, bg: 'rgb(' + bg.join(',') + ')',
      ratio: Math.round(r*100)/100, floor
    });
  });
  return out;
})()`;

(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const p = await b.newPage({ viewport: { width: 1280, height: 950 } });
  await p.goto('http://127.0.0.1:8099/shop.html', { waitUntil: 'domcontentloaded' });
  await p.waitForTimeout(1200);
  await p.evaluate(() => document.querySelector('[data-add]').click());
  await p.waitForTimeout(400);
  await p.evaluate(() => Array.from(document.querySelectorAll('button,a')).find(x => /checkout/i.test(x.textContent || '')).click());
  await p.waitForTimeout(700);
  await p.click('#chooseGuest'); await p.waitForTimeout(300);
  await p.click('[data-ck-go="2"]'); await p.waitForTimeout(250);
  await p.click('[data-ck-go="3"]'); await p.waitForTimeout(1100);

  for (const method of ['googlepay', 'paypal']) {
    await p.click(`[data-pay="${method}"]`); await p.waitForTimeout(600);
    await p.click('#placeOrderBtn').catch(() => {});
    await p.waitForTimeout(1400);
    const bad = await p.evaluate(PROBE);
    console.log(`\n=== ${method} ===`);
    if (!bad.length) console.log('  every visible text pair clears its floor');
    bad.forEach(f => console.log(`  ${String(f.ratio).padStart(5)} to 1 (floor ${f.floor})  ${f.fg} on ${f.bg}  "${f.text}"`));
    await p.screenshot({ path: `/tmp/claude-0/-home-user-Claude-Code/be884c3a-7367-52e3-b456-3ceeb1738f6e/scratchpad/shots/pairs-${method}.png` });
    await p.click('#walletCancel').catch(() => p.click('#walletClose').catch(() => {}));
    await p.waitForTimeout(500);
  }
  await b.close();
})();
