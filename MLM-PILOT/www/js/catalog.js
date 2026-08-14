/* ============================================================
   Orvanna catalog: the single source of truth for every item
   the shop sells. Loaded by shop.html and product.html; nothing
   else defines a price, a Personal Volume (PV) figure, or an
   icon. Round 4 (Phase 4C.2).

   Billing modes, per Howard's rule:
   - Subscription is the DEFAULT mode on every item.
   - The one-time alternative uses the 10x rule: the one-time
     price shows what the product is WORTH without subscription.
     Domain agents: $100.00 / month becomes $1,000.00 once.
     Support agents: $50.00 / month becomes $500.00 once.
     Bundles and packs follow the same 10x rule.
   - PV always equals dollars, in both modes.

   Cart storage: localStorage key "orvannaCart", entries keyed
   "sku|mode" where mode is "sub" or "one". Old round-3 carts
   used bare sku keys; loadCart migrates those to "sku|sub".
   ============================================================ */

window.ORVANNA = (function () {
  'use strict';

  /* ---------- icon builders (brand hexagon, inline SVG) ---------- */

  var HEX = '<polygon points="32,6 54.5,19 54.5,45 32,58 9.5,45 9.5,19" fill="none" stroke="#818CF8" stroke-width="3.5" stroke-linejoin="round"/>';

  function hexIcon(inner) {
    return '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">' + HEX + inner + '</svg>';
  }

  /* ---------- the catalog ---------- */
  /* Each item:
     sku       stable identifier, used in product.html?sku=
     tier      domain | support | bundle | pack
     name      display name
     blurb     one-line card description
     sub       { price, pv }  monthly subscription (default mode)
     once      { price, pv }  one-time purchase (10x rule)
     includes  array of child skus (bundles and packs only)
     icon      inline SVG string                                 */

  var PRODUCTS = [

    /* ----- Domain agents: $100.00 / month, 100 PV ----- */
    { sku: 'payment', tier: 'domain', name: 'Payment Agent',
      blurb: 'Runs checkout, retries, and settlement without a break.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<rect x="20" y="24" width="24" height="17" rx="2.5" fill="none" stroke="#818CF8" stroke-width="2.4"/><line x1="20" y1="30" x2="44" y2="30" stroke="#818CF8" stroke-width="2.4"/><circle cx="26" cy="35.5" r="2" fill="#22D3EE"/>') },
    { sku: 'shipping', tier: 'domain', name: 'Shipping Agent',
      blurb: 'Books carriers, tracks parcels, and clears delays.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<path d="M 20 36 h 14 v -9 h -14 z" fill="none" stroke="#818CF8" stroke-width="2.4" stroke-linejoin="round"/><path d="M 34 30 h 6 l 4 4 v 2 h -10 z" fill="none" stroke="#818CF8" stroke-width="2.4" stroke-linejoin="round"/><circle cx="25" cy="39.5" r="2.4" fill="#22D3EE"/><circle cx="38" cy="39.5" r="2.4" fill="#818CF8"/>') },
    { sku: 'pricing', tier: 'domain', name: 'Pricing Agent',
      blurb: 'Watches the market and keeps every price sharp.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<line x1="24" y1="41" x2="40" y2="23" stroke="#818CF8" stroke-width="2.4" stroke-linecap="round"/><circle cx="25.5" cy="26.5" r="3.4" fill="none" stroke="#818CF8" stroke-width="2.2"/><circle cx="38.5" cy="38.5" r="3.4" fill="none" stroke="#22D3EE" stroke-width="2.2"/>') },
    { sku: 'inventory', tier: 'domain', name: 'Inventory Agent',
      blurb: 'Counts stock and reorders before shelves go bare.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<rect x="21" y="33" width="9.5" height="9.5" fill="none" stroke="#818CF8" stroke-width="2.2" stroke-linejoin="round"/><rect x="33.5" y="33" width="9.5" height="9.5" fill="none" stroke="#818CF8" stroke-width="2.2" stroke-linejoin="round"/><rect x="27" y="21.5" width="9.5" height="9.5" fill="none" stroke="#22D3EE" stroke-width="2.2" stroke-linejoin="round"/>') },
    { sku: 'marketing', tier: 'domain', name: 'Marketing Agent',
      blurb: 'Writes, schedules, and measures every campaign.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<circle cx="26" cy="32" r="2.6" fill="#22D3EE"/><path d="M 32 24 a 10.5 10.5 0 0 1 0 16" fill="none" stroke="#818CF8" stroke-width="2.4" stroke-linecap="round"/><path d="M 37 19.5 a 16.5 16.5 0 0 1 0 25" fill="none" stroke="#818CF8" stroke-width="2.4" stroke-linecap="round"/>') },
    { sku: 'tax', tier: 'domain', name: 'Tax Agent',
      blurb: 'Files on time in every region you sell.',
      sub: { price: 100, pv: 100 }, once: { price: 1000, pv: 1000 }, includes: null,
      icon: hexIcon('<line x1="24" y1="40" x2="40" y2="24" stroke="#818CF8" stroke-width="2.4" stroke-linecap="round"/><circle cx="26" cy="26" r="2.6" fill="#818CF8"/><circle cx="38" cy="38" r="2.6" fill="#22D3EE"/><line x1="21" y1="45.5" x2="43" y2="45.5" stroke="#818CF8" stroke-width="2.2" stroke-linecap="round"/>') },

    /* ----- Support agents: $50.00 / month, 50 PV ----- */
    { sku: 'engineer', tier: 'support', name: 'Software Engineer',
      blurb: 'Ships fixes and features on request.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<path d="M 26 25 L 19.5 32 L 26 39" fill="none" stroke="#818CF8" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M 38 25 L 44.5 32 L 38 39" fill="none" stroke="#818CF8" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/><line x1="34" y1="23" x2="30" y2="41" stroke="#22D3EE" stroke-width="2.4" stroke-linecap="round"/>') },
    { sku: 'qa', tier: 'support', name: 'Quality Assurance',
      blurb: 'Tests everything twice before customers see it.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<path d="M 22 32.5 L 29.5 40 L 42 25" fill="none" stroke="#22D3EE" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>') },
    { sku: 'secretary', tier: 'support', name: 'Secretary',
      blurb: 'Keeps the calendar, notes, and follow-ups straight.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<rect x="21" y="23" width="22" height="19" rx="2.5" fill="none" stroke="#818CF8" stroke-width="2.4"/><line x1="21" y1="29.5" x2="43" y2="29.5" stroke="#818CF8" stroke-width="2.2"/><line x1="27" y1="20" x2="27" y2="25" stroke="#818CF8" stroke-width="2.2" stroke-linecap="round"/><line x1="37" y1="20" x2="37" y2="25" stroke="#818CF8" stroke-width="2.2" stroke-linecap="round"/><circle cx="27" cy="35.5" r="2" fill="#22D3EE"/>') },
    { sku: 'executive', tier: 'support', name: 'Chief Executive',
      blurb: 'Sets direction and keeps every agent aligned.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<circle cx="32" cy="24.5" r="3.2" fill="#22D3EE"/><circle cx="23" cy="39" r="3" fill="#818CF8"/><circle cx="41" cy="39" r="3" fill="#818CF8"/><line x1="32" y1="27.5" x2="24" y2="36.5" stroke="#818CF8" stroke-width="2.2"/><line x1="32" y1="27.5" x2="40" y2="36.5" stroke="#818CF8" stroke-width="2.2"/>') },
    { sku: 'accounting', tier: 'support', name: 'Accounting',
      blurb: 'Balances books to the cent, month after month.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<line x1="24" y1="42" x2="24" y2="33" stroke="#818CF8" stroke-width="3" stroke-linecap="round"/><line x1="32" y1="42" x2="32" y2="26" stroke="#22D3EE" stroke-width="3" stroke-linecap="round"/><line x1="40" y1="42" x2="40" y2="29.5" stroke="#818CF8" stroke-width="3" stroke-linecap="round"/>') },
    { sku: 'care', tier: 'support', name: 'Customer Care',
      blurb: 'Answers customers day and night, in any tone.',
      sub: { price: 50, pv: 50 }, once: { price: 500, pv: 500 }, includes: null,
      icon: hexIcon('<path d="M 23 36 v -3.5 a 9 9 0 0 1 18 0 V 36" fill="none" stroke="#818CF8" stroke-width="2.4" stroke-linecap="round"/><rect x="20.5" y="34" width="5" height="8" rx="2.4" fill="#818CF8"/><rect x="38.5" y="34" width="5" height="8" rx="2.4" fill="#22D3EE"/>') },

    /* ----- Bundle: the Manager Agent ----- */
    /* A parent item whose children are three support agents. Priced
       above the sum of its parts ($150.00) because the management
       layer itself is the product: one agent that runs the trio. */
    { sku: 'manager', tier: 'bundle', name: 'Manager Agent',
      blurb: 'One agent that runs your back office: engineering, scheduling, and the books, coordinated as a single team.',
      sub: { price: 200, pv: 200 }, once: { price: 2000, pv: 2000 },
      includes: ['engineer', 'secretary', 'accounting'],
      icon: hexIcon('<circle cx="32" cy="22.5" r="3.6" fill="#22D3EE"/><circle cx="21.5" cy="40" r="3" fill="#818CF8"/><circle cx="32" cy="42.5" r="3" fill="#818CF8"/><circle cx="42.5" cy="40" r="3" fill="#818CF8"/><line x1="32" y1="26" x2="22.5" y2="37.5" stroke="#818CF8" stroke-width="2.2"/><line x1="32" y1="26" x2="32" y2="39" stroke="#818CF8" stroke-width="2.2"/><line x1="32" y1="26" x2="41.5" y2="37.5" stroke="#818CF8" stroke-width="2.2"/>') },

    /* ----- Digital packs: curated teams, even pricing, PV = dollars ----- */
    { sku: 'ignition', tier: 'pack', name: 'Ignition Pack',
      blurb: 'The first-storefront trio: take payments, answer customers, keep the calendar straight.',
      sub: { price: 200, pv: 200 }, once: { price: 2000, pv: 2000 },
      includes: ['payment', 'care', 'secretary'],
      icon: hexIcon('<path d="M 32 42 V 25" stroke="#818CF8" stroke-width="2.6" stroke-linecap="round"/><path d="M 25 32 L 32 24 L 39 32" fill="none" stroke="#818CF8" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/><circle cx="32" cy="44" r="2.6" fill="#22D3EE"/>') },
    { sku: 'momentum', tier: 'pack', name: 'Momentum Pack',
      blurb: 'Five agents tuned for growth: sell it, promote it, price it, build it, test it.',
      sub: { price: 400, pv: 400 }, once: { price: 4000, pv: 4000 },
      includes: ['payment', 'marketing', 'pricing', 'engineer', 'qa'],
      icon: hexIcon('<path d="M 21 24 L 30 32 L 21 40" fill="none" stroke="#818CF8" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M 33 24 L 42 32 L 33 40" fill="none" stroke="#22D3EE" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>') },
    { sku: 'constellation', tier: 'pack', name: 'Constellation Pack',
      blurb: 'The full formation: every domain agent, plus the Manager Agent running support behind them.',
      sub: { price: 800, pv: 800 }, once: { price: 8000, pv: 8000 },
      includes: ['payment', 'shipping', 'pricing', 'inventory', 'marketing', 'tax', 'manager'],
      icon: hexIcon('<circle cx="32" cy="32" r="3.4" fill="#22D3EE"/><circle cx="23" cy="25" r="2.4" fill="#818CF8"/><circle cx="41" cy="25" r="2.4" fill="#818CF8"/><circle cx="23" cy="39" r="2.4" fill="#818CF8"/><circle cx="41" cy="39" r="2.4" fill="#818CF8"/><line x1="32" y1="32" x2="23.8" y2="25.8" stroke="#818CF8" stroke-width="1.8"/><line x1="32" y1="32" x2="40.2" y2="25.8" stroke="#818CF8" stroke-width="1.8"/><line x1="32" y1="32" x2="23.8" y2="38.2" stroke="#818CF8" stroke-width="1.8"/><line x1="32" y1="32" x2="40.2" y2="38.2" stroke="#818CF8" stroke-width="1.8"/>') }
  ];

  var BY_SKU = {};
  PRODUCTS.forEach(function (p) { BY_SKU[p.sku] = p; });

  /* ---------- shared formatting ---------- */

  function fmtMoney(n) {
    return '$' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function fmtPv(n) {
    return n.toLocaleString('en-US') + ' PV';
  }

  /* price and pv for an item in a given mode */
  function priceOf(p, mode) { return mode === 'one' ? p.once.price : p.sub.price; }
  function pvOf(p, mode)    { return mode === 'one' ? p.once.pv    : p.sub.pv; }

  /* ---------- cart (localStorage, shared by every page) ---------- */

  var CART_KEY = 'orvannaCart';

  function loadCart() {
    try {
      var raw = localStorage.getItem(CART_KEY);
      if (!raw) return {};
      var data = JSON.parse(raw);
      var clean = {};
      Object.keys(data).forEach(function (key) {
        var q = parseInt(data[key], 10);
        if (!(q > 0)) return;
        /* migrate round-3 keys (bare sku) to sku|sub */
        var parts = key.indexOf('|') >= 0 ? key.split('|') : [key, 'sub'];
        var sku = parts[0];
        var mode = parts[1] === 'one' ? 'one' : 'sub';
        if (BY_SKU[sku]) {
          var k = sku + '|' + mode;
          clean[k] = Math.min((clean[k] || 0) + q, 99);
        }
      });
      return clean;
    } catch (err) { return {}; }
  }

  function saveCart(cart) {
    try {
      if (Object.keys(cart).length === 0) {
        localStorage.removeItem(CART_KEY);
      } else {
        localStorage.setItem(CART_KEY, JSON.stringify(cart));
      }
    } catch (err) { /* storage unavailable: cart lives for the session */ }
  }

  function keyParts(key) {
    var parts = key.split('|');
    return { sku: parts[0], mode: parts[1] === 'one' ? 'one' : 'sub' };
  }

  /* totals across the cart:
     subMoney  monthly money (subscription lines)
     oneMoney  billed-today money (one-time lines)
     pv        total PV regardless of mode (the meter counts everything)
     count     unit count for the nav badge */
  function cartTotals(cart) {
    var subMoney = 0, oneMoney = 0, pv = 0, count = 0;
    Object.keys(cart).forEach(function (key) {
      var kp = keyParts(key);
      var p = BY_SKU[kp.sku];
      if (!p) return;
      var q = cart[key];
      if (kp.mode === 'one') { oneMoney += p.once.price * q; } else { subMoney += p.sub.price * q; }
      pv += pvOf(p, kp.mode) * q;
      count += q;
    });
    return { subMoney: subMoney, oneMoney: oneMoney, pv: pv, count: count };
  }

  /* ---------- public surface ---------- */

  return {
    PRODUCTS: PRODUCTS,
    bySku: BY_SKU,
    get: function (sku) { return BY_SKU[sku] || null; },
    hexIcon: hexIcon,
    HEX: HEX,
    fmtMoney: fmtMoney,
    fmtPv: fmtPv,
    priceOf: priceOf,
    pvOf: pvOf,
    loadCart: loadCart,
    saveCart: saveCart,
    keyParts: keyParts,
    cartTotals: cartTotals
  };
})();
