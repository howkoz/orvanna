/* ============================================================
   ORVANNA SHARED SITE CHROME
   www/js/site-chrome.js

   One file owns the two behaviours that every corporate page
   needs and that every corporate page used to hand-roll:

     1. The theme control. One icon-only button, one storage
        key, one default. Dark is the default everywhere.
     2. The Support control. One copy of the chat wiring,
        instead of the five inline copies that used to sit in
        index, shop, product, team and faq.

   WHY THIS FILE EXISTS. Nine corporate pages each carried their
   own navigation, their own theme toggle and their own support
   script. They were pasted, then edited separately, and they
   drifted: four different theme controls, four pages with no
   theme control, and a Support button that did nothing on four
   pages. This is the same disease the payment engine had before
   payments.js, and it gets the same cure: a single module the
   pages consume, plus a build lint that fails when the shared
   markup drifts. See docs/CORPORATE-CHROME-CONTRACT.md.

   NOT LOADED BY the three sign-in pages (login.html,
   staff.html, staff-operations.html). Those keep their own
   chrome by explicit instruction and are out of scope.

   Acronym key: Cascading Style Sheets (CSS), Scalable Vector
   Graphics (SVG), Hypertext Markup Language (HTML).
   ============================================================ */
(function () {
  'use strict';

  /* ----------------------------------------------------------
     1. THEME
     ----------------------------------------------------------
     The stored choice is applied by a small inline snippet in
     each page's <head>, BEFORE first paint, so nothing flashes
     the wrong palette. This file does not repeat that job; it
     owns the button, the accessible name, and persistence.

     Storage key: 'orvanna-theme', values 'dark' or 'light'.
     It replaces the four keys the pages used to use
     (orvannaLibraryTheme, orvanna-conductor-theme,
     orvanna-comp-plan-theme, orvanna-faq-theme), which is the
     point: a reader who picks light on the library still has
     light on the plan page.
     ---------------------------------------------------------- */

  var STORAGE_KEY = 'orvanna-theme';
  var root = document.documentElement;

  function storage() {
    try { return window.localStorage; } catch (err) { return null; }
  }

  function currentTheme() {
    /* Dark is the default. Anything that is not the literal
       string 'light' is dark, including a missing attribute. */
    return root.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
  }

  function paintToggles() {
    var theme = currentTheme();
    var label = theme === 'dark'
      ? 'Switch to the light theme'
      : 'Switch to the dark theme';
    var buttons = document.querySelectorAll('[data-theme-toggle]');
    Array.prototype.forEach.call(buttons, function (button) {
      /* The control is icon-only, so the accessible name is the
         only name it has. It has to track state or the button
         lies to a screen reader in one of its two states. */
      button.setAttribute('aria-label', label);
      button.setAttribute('title', label);
    });
  }

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme === 'light' ? 'light' : 'dark');
    var store = storage();
    if (store) {
      try { store.setItem(STORAGE_KEY, currentTheme()); }
      catch (err) { /* private browsing: the choice lasts this page only */ }
    }
    paintToggles();
  }

  function initTheme() {
    /* Belt and braces: if the inline head snippet was blocked,
       set the attribute now so the CSS selectors are explicit. */
    if (root.getAttribute('data-theme') !== 'light') {
      root.setAttribute('data-theme', 'dark');
    }
    paintToggles();

    var buttons = document.querySelectorAll('[data-theme-toggle]');
    Array.prototype.forEach.call(buttons, function (button) {
      button.addEventListener('click', function () {
        applyTheme(currentTheme() === 'dark' ? 'light' : 'dark');
      });
    });

    /* A second tab of the same site may change the choice. Keep
       this tab honest rather than letting the two disagree. */
    window.addEventListener('storage', function (event) {
      if (event.key !== STORAGE_KEY) { return; }
      root.setAttribute('data-theme', event.newValue === 'light' ? 'light' : 'dark');
      paintToggles();
    });
  }

  /* ----------------------------------------------------------
     2. SUPPORT
     ----------------------------------------------------------
     The chat is Botpress, a third party, and it is the second
     sanctioned external script on the property after the
     payment loader. Its own floating action button is hidden in
     the stylesheet, so the panel opens only from the Support
     item in the navigation and nothing can float over the cart
     control on a phone or over the card form at checkout.

     The two vendor scripts are appended here rather than being
     written into nine pages. async is set to false so the two
     execute in the order they are inserted: the configuration
     file calls into the loader and must run second.
     ---------------------------------------------------------- */

  var BOTPRESS_LOADER = 'https://cdn.botpress.cloud/webchat/v5.0/inject.js';
  var BOTPRESS_CONFIG = 'https://files.bpcontent.cloud/2026/08/14/20/20260814201237-9JS9TWQ7.js';

  function loadSupportWidget() {
    if (document.querySelector('script[data-orvanna-support-script]')) { return; }
    [BOTPRESS_LOADER, BOTPRESS_CONFIG].forEach(function (src) {
      var el = document.createElement('script');
      el.src = src;
      el.async = false;   /* preserves insertion order */
      el.setAttribute('data-orvanna-support-script', '');
      document.head.appendChild(el);
    });
  }

  function initSupport() {
    var triggers = document.querySelectorAll('[data-orvanna-support]');
    if (!triggers.length) { return; }

    loadSupportWidget();

    var wantOpen = false;
    var listening = false;

    function openNow() {
      if (window.botpress && typeof window.botpress.open === 'function') {
        try { window.botpress.open(); return true; }
        catch (err) { return false; }
      }
      return false;
    }

    /* The widget arrives asynchronously. Watch for it, and if
       someone pressed Support before it was ready, open the
       moment it reports ready. */
    var waited = 0;
    var poll = window.setInterval(function () {
      if (!listening && window.botpress && typeof window.botpress.on === 'function') {
        listening = true;
        window.clearInterval(poll);
        window.botpress.on('webchat:ready', function () {
          if (wantOpen) { wantOpen = false; openNow(); }
        });
      } else if ((waited += 250) > 20000) {
        window.clearInterval(poll);
      }
    }, 250);

    Array.prototype.forEach.call(triggers, function (trigger) {
      trigger.addEventListener('click', function (event) {
        event.preventDefault();
        if (!openNow()) { wantOpen = true; }
      });
    });
  }

  /* ----------------------------------------------------------
     3. START
     ---------------------------------------------------------- */

  function start() {
    initTheme();
    initSupport();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
