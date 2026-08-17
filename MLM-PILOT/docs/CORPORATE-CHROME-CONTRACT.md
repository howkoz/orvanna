# The corporate chrome contract

**Written:** 2026-08-17, by the coordinator, from Howard's instruction:

> "if you go to https://orvanna.io/index.html and then you go to other top navigation
> links the option change on the top navigation i want the entire corporate pages but
> does have to apply the Sign in Areas to look the same site. can you scan the pages
> and fix those excep the sign in areas"
>
> "I also just want a theme icon not saying light or dark on all pages"

This document is the LAW for the top navigation on every corporate page. Two builders
work from it in parallel on disjoint files, so it must be followed to the character.

Acronym key: Cascading Style Sheets (CSS), JavaScript (JS), Scalable Vector Graphics
(SVG), Hypertext Markup Language (HTML), Quality Assurance (QA).

---

## 1. What is broken today (measured, not assumed)

Nine corporate pages carry nine hand-written navigations. Every one was pasted and then
edited separately, so they drifted. Measured 2026-08-17:

| Page | Navigation items present | Theme control | Support |
|---|---|---|---|
| index.html | Learn Shop Library Plan Conductors Team Support Enroll SignIn | **none** | yes |
| shop.html | same nine, plus cart | **none** | yes |
| product.html | same nine, plus cart | **none** | yes |
| team.html | same nine | **none** | yes |
| faq.html | Learn Shop **Team** Support Enroll SignIn | text button "Dark" | yes |
| comp-plan.html | Learn Shop **Plan** Team Enroll SignIn | text button "Dark" | **no** |
| conductor.html | Learn Shop **Conductors** Team Enroll SignIn | icon **plus** the words Light/Dark | **no** |
| library.html | Learn Shop **Library** Team Enroll SignIn | trio: Theme / Auto / Light / Dark | **no** |
| library-agent.html | Learn Shop **Library** Team Enroll SignIn | trio: Theme / Auto / Light / Dark | **no** |

So: four different theme controls, four pages with no theme control at all, and the
Library, Plan and Conductors links vanish from exactly the pages a reader reaches them
from. That is what Howard saw.

Underneath it is the same disease the payment engine had before `payments.js`: **there is
no shared site chrome.** Each page hand-rolls the navigation, the theme toggle, and the
support widget (the support widget is copy-pasted inline into six pages). Fixing the
markup alone would drift again within a week, so this contract also creates the single
source and the build lint that keeps it single.

---

## 2. The canonical navigation

Exactly this markup, in this order, inside `<nav class="nav-links" aria-label="Primary">`,
on all nine corporate pages:

```html
<nav class="nav-links" aria-label="Primary">
  <a class="nav-link" href="index.html">Learn</a>
  <a class="nav-link" href="shop.html">Shop</a>
  <a class="nav-link" href="library.html">Library</a>
  <a class="nav-link" href="comp-plan.html">Plan</a>
  <a class="nav-link" href="conductor.html">Conductors</a>
  <a class="nav-link" href="team.html">Team</a>
  <button class="nav-link nav-support" type="button" data-orvanna-support>Support</button>
  <span class="nav-link is-soon" aria-disabled="true">Enroll<span class="soon-pill">soon</span></span>
  <a class="nav-signin" href="login.html">Sign In</a>
  <button class="nav-theme" type="button" data-theme-toggle
          aria-label="Switch to the light theme">
    <svg class="icon-sun" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <circle cx="12" cy="12" r="4.6" fill="none" stroke="currentColor" stroke-width="1.8"/>
      <g stroke="currentColor" stroke-width="1.8" stroke-linecap="round">
        <line x1="12" y1="2.5" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="21.5"/>
        <line x1="2.5" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="21.5" y2="12"/>
        <line x1="5.4" y1="5.4" x2="7.2" y2="7.2"/><line x1="16.8" y1="16.8" x2="18.6" y2="18.6"/>
        <line x1="18.6" y1="5.4" x2="16.8" y2="7.2"/><line x1="7.2" y1="16.8" x2="5.4" y2="18.6"/>
      </g>
    </svg>
    <svg class="icon-moon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path d="M 19 15.2 A 8.4 8.4 0 0 1 8.8 5 a 8.6 8.6 0 1 0 10.2 10.2 z"
            fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
    </svg>
  </button>
</nav>
```

**Rules that go with it.**

1. **The current page** takes `class="nav-link is-active"` and `aria-current="page"` on its
   own item, and nothing else changes. On `index.html` the active item is Learn. On
   `product.html` the active item is Shop (a product page is inside the shop).
2. **The brand block above it is unchanged** on every page except that its `href` is
   `index.html` everywhere (index.html itself may keep `#top`).
3. **The cart is the only permitted addition**, on `shop.html` and `product.html` only,
   placed immediately AFTER the theme button, keeping each page's existing cart markup and
   identifiers untouched. A cart is a function of those pages, not chrome drift.
4. **No page may add, remove, reorder, or rename any other item.** The Theme trio, the
   text-labelled Dark buttons, and the Light/Dark words all disappear.

---

## 3. The theme control

**Howard's words: an icon, not the words Light or Dark.** Therefore:

- One button, two SVG icons (sun and moon) already given above. CSS shows exactly one at a
  time. **No visible text, ever.**
- The `aria-label` carries the meaning for screen readers and MUST track state: it reads
  "Switch to the light theme" while dark is active, and "Switch to the dark theme" while
  light is active. An icon-only control with no accessible name is a QA failure.
- Minimum hit target 40 by 40 pixels (Howard uses this on a laptop trackpad).

**Default and storage, decided deliberately:**

- **The default stays DARK on every corporate page.** Orvanna's identity is the dark
  starfield. A visitor who never clicks the icon must see exactly what they see today, so
  this change cannot alter the live site's appearance for anyone by surprise. This means
  the `:root` tokens keep the current dark values and `:root[data-theme="light"]` carries
  the light values. (This is a deliberate departure from `library.css`, which currently
  follows the operating system by default; the library pages change to dark-default so the
  site behaves as one site. Note it in the verdict, do not treat it as a defect.)
- **One storage key for the whole site: `orvanna-theme`**, values `dark` or `light`. It
  replaces `orvannaLibraryTheme` and `orvanna-conductor-theme`. The consequence is the
  point: a reader who picks light on the library still has light on the plan page.
- The choice applies before first paint (an inline snippet in `<head>`, not a deferred
  script) so there is no flash of the wrong theme.

---

## 4. Shared chrome, so this cannot drift again

Create `www/js/site-chrome.js`, loaded by all nine corporate pages, owning:

1. The theme toggle behaviour (read storage, set `data-theme`, swap `aria-label`, persist).
2. The support widget, **extracted from the six inline copies** that exist today in
   `index.html`, `shop.html`, `product.html`, `team.html`, `faq.html`. Delete those inline
   copies as part of this work. This is the `payments.js` lesson applied to the chrome.
   **`staff.html` keeps its own copy and is not touched** (it is a sign-in area, section 6).

Create `www/_partials/nav.html` holding the canonical block from section 2 as the single
source, and add a **navigation drift lint to `deploy/build_dist.py`** that compares each
corporate page's `<nav class="nav-links">…</nav>` against the partial, ignoring only the
permitted `is-active` / `aria-current` difference and the permitted cart addition, and
**fails the build** on any other difference. The build already lints asset stamps, page
names and secrets; this joins that family. A build that cannot drift is worth more than a
navigation that is correct today.

---

## 5. The light palette (the real work)

`corporate.css` and `shop.css` have one palette today, and it is dark. The theme icon on
`index`, `shop`, `product` and `team` is only honest if a light theme actually exists, so
authoring it is part of this job, not a follow-up.

- Both files already lean on custom properties (57 and 111 uses of `var(--…)`), so the
  route is: keep every existing token name and value as the dark default, then restate the
  token values inside `:root[data-theme="light"]`. Do not rename tokens site-wide in this
  round; that is a refactor and it is not what was asked for.
- Hardcoded hex values that fight the light theme must move to tokens. `corporate.css` has
  roughly thirty-seven such occurrences; handle the ones that break, leave the rest.
- **Every text-on-background pair must be computed and reported at 4.5 to 1 or better in
  BOTH themes**, per the standing lesson that a remedy has to be measured, not eyeballed.
- If any surface genuinely cannot be made presentable in light (the starfield hero is the
  candidate), **say so in the report rather than shipping something ugly.** The fallback is
  named: that surface keeps its dark treatment inside the light theme, deliberately and
  documented, the way a hero image stays dark on a light page.

---

## 6. Out of scope, explicitly

**The sign-in areas are not touched.** Howard excluded them by name:

- `login.html`
- `staff.html`
- `staff-operations.html`

They keep their own chrome, their own inline support widget, and their own look. No
navigation lint applies to them. Anyone who edits them in this round has broken the brief.

The member portal under `portal/` is likewise untouched.

---

## 7. Definition of done

1. All nine corporate pages carry the canonical navigation, character for character except
   the permitted active-state and cart differences.
2. One icon-only theme control on all nine, no visible Light or Dark text anywhere, working
   in both directions, remembered across pages by one storage key, no flash on load.
3. A light theme that genuinely renders on all nine, with contrast computed and reported.
4. The support button works on all nine (it currently does nothing on four of them because
   the widget is not there).
5. `build_dist.py` fails on navigation drift, and passes on the current tree.
6. The three sign-in pages are byte-identical to their state before this round, except
   where they were already being changed by other work.
7. Both gates (`mlm-verifier` and `mlm-qa`) PASS on the exact artifact before any deploy,
   per the standing rule.
