# Redesign gates, 2026-08-18

Both gates run against the built artifact in `deploy/dist`, not the source.
Bundle **`sha256 60c3971ef1f6150f`** — the bundle that is live. Both gates
were also run, and passed identically, on `5b4bfe891b253eb0`, the bundle
published first; the only difference between them is the home page's meta
description, corrected after the deploy because it still carried the retired
headline. Re-gated rather than waved through: a new bundle is a new artifact.

> **Correction, 2026-08-19.** This document first recorded the bundle as
> `9c3abe96cb48b2e0`. That was wrong, and the way it was wrong is worth
> keeping: it was a real hash from a real build, taken two edits before the
> gates actually ran. The gates ran after the deepest-scroll sweep and the
> 2.5-second deadline went in, so they tested a bundle this file did not
> name. Caught at publish time by rebuilding and finding the hash did not
> match. A hash copied from an earlier build reads exactly like a hash from
> the gated one, which is what makes it worth catching: it is a claim of
> provenance that looks identical whether or not it is true. Both gates were
> re-run against `5b4bfe891b253eb0` before anything was published, and the
> results below are that run. The build is deterministic: two clean builds
> from a clean tree produced the same hash.

## Gate one — the verifier

Ten pages loaded and measured. Checks: HTTP status; bar height identical on
every page; no theme control anywhere; the pinwheel mark present in the bar;
five footer columns; exactly one primary action and the right one for the
page; no sideways scroll; and, after a full scroll of the page, nothing large
left invisible.

```
index.html          pass
shop.html           pass
product.html        pass
team.html           pass
faq.html            pass
comp-plan.html      pass
conductor.html      pass
library.html        pass
library-agent.html  pass
login.html          pass
```

**Round one failed on two pages**, and both findings were real.

`team.html` left four reveal containers permanently invisible after a
viewport-sized scroll: "How it was built", the gate figure, the phase rail
and the closing call to action. This is the same defect class the last
session found on the live site and believed fixed. The fix then made the
reveal fail VISIBLE, which was right and is why the home page and every
other page passes. What survived was narrower: the observer and the scroll
sweep both SAMPLE, and a jump of a whole viewport can outrun a sample. A
section that loses that race never gets another one. Two things changed: the
sweep now measures against the deepest scroll of the session rather than the
current viewport, and the unconditional deadline dropped from ten seconds to
2.5. The deadline is what actually carries the guarantee, so it is stated
that way in the code rather than described as a fallback.

`shop.html` reported one block, and that one was my check being wrong: the
closed cart overlay is meant to be invisible. The check now ignores anything
that takes no pointer events, which is what a closed overlay is.

Two more first-round failures were also the check, not the pages: counting
distinct child offsets called a correctly centred one-row bar "two rows", and
`login.html` has no shared bar at all because it is a sign-in area the chrome
contract excludes by name.

## Gate two — quality assurance

Every claim made in a commit message this session, traced to behaviour.

```
pass  disclosure hides links from tab order          [shut=0 open=7]
pass  Escape closes and returns focus
pass  one bar height across all nine pages           [69px on all nine]
pass  rail checkout carries the cart                 [$200.00 / mo]
pass  no errors adding to cart / entering checkout
pass  working log advances
pass  working log stays at five rows
pass  mark turns in quarters                         [rotate(180deg)]
pass  reduced motion leaves the log still
pass  readable with scripting off
pass  the bar does not print
```

"Readable with scripting off" is the one worth keeping: every page was loaded
with JavaScript disabled entirely and checked for blank content. Nothing on
the corporate site needs a script to be read.

## What these gates did NOT cover

Stated so the pass is not read as wider than it is.

- **The member office and the operations console** were verified against a
  synthetic fixture with `fetch` stubbed, because both sit behind real
  sign-in on a live database. Their layout, ranking and derived figures were
  checked; their behaviour against real data was not.
- **The panel internals of the member office** are still the old card
  treatment inside the new shell.
- **Money at stake and the row actions on the operations console** are not
  built, and need the server change in
  `OPERATIONS-QUEUE-SERVER-SPEC.md`.
- **Nothing here touched a payment rail**, so this run does not discharge the
  standing debt from 08-17: five deploys to a live rail with neither gate
  run.


---

# Second run, 2026-08-19: the panels, the console, and four unreadable surfaces

Bundle **`sha256 05a1b77f9afa33d9`**. Both gates pass on all fourteen pages.

## What gate one grew

**Design system** (radius, shadow, gradient) — restored after being deleted by
accident, and widened to every page. See
[[a-check-removed-while-fixing-another-is-never-missed]].

**Contrast** — new, and it found four surfaces that were shipped unreadable:

| Surface | Was | Ratio |
| --- | --- | --- |
| `.btn-addline` — the console's three primary buttons | ink label on an ink fill | **1:1** |
| The console's member-number and schedule fields | ink text on 70% ink | ~1.2:1 |
| The 3-D Secure bank approval panel, mid-checkout | `--shop-text` on 70% ink | ~1.3:1 |
| **Every paragraph of the 35-page plan brochure** | `--body` set to `#F1EDE6` on white | **1.09:1** |

All four are the same fault: a dark inset from the old site whose BACKGROUND
was remapped to ink while its TEXT stayed ink. The brochure is the sharpest
case — one hex value meant "body text" in two documents at once, light-on-dark
on the site and dark-on-light in the brochure, and a global remap cannot tell
those apart because a colour does not carry which side of the contrast it was
on. One token restored 35 pages.

No token-level check would have caught any of them: `--indigo` and the label
were two different NAMES that had become one colour, and a rule comparing names
sees two. The check resolves both to pixels and divides.

## One accepted exception, named rather than silenced

`#8A8278` on `#EAE4D9` measures **2.99:1**. That is the handoff's own `--faint`
token — "column headings, kickers, metadata" — on its own `--paper`. It is
below AA for small text.

It is listed in gate one as an accepted pair with its reason, not hidden by
moving the threshold. Anything that is not that exact pair still fails.

**This is an open decision for the owner.** The arithmetic: reaching 4.5:1 on
paper needs a luminance of about 0.134, which lands on `#6B645A` — and that is
already `--quiet`, the next step down. So the design's three-step ink scale has
no room between "meets AA" and "distinct from quiet". Fixing it means either
accepting two steps instead of three, or lightening the paper. Both are design
calls, and both repaint every kicker, stat label and column head on the site.

## Also in this run

- The member office's panels went from bordered stat-cards to ruled cells,
  34px numerals, one heading per section instead of two.
- The operations console became one column ordered by consequence: queue,
  retry, seven days, run now, history, schedule. The two-up grids paired
  unrelated panels by height, and on a console whose argument IS an order, a
  grid shuffles the argument.
- Two more rounds of old-palette survivors, both in `rgba()` form, which is why
  the hex-and-triple sweeps missed them: `rgba(2,6,23,…)` and
  `rgba(148,163,184,…)` in the portal, `rgba(124,138,160,…)` in the console.

## Still not covered

Unchanged from the first run: the member office and the operations console are
verified against a synthetic fixture with `fetch` stubbed, because both sit
behind sign-in on a live database. The operations queue's money column and row
actions still need the server change in `OPERATIONS-QUEUE-SERVER-SPEC.md`,
which has NOT been applied.


---

# Third run, 2026-08-19: the last two items closed

Bundle **`sha256 a032e0544e325708`**. Both gates pass on all fourteen pages,
and gate one now has **no accepted-exception list at all**.

## The contrast decision was made, not tolerated

`#8A8278` on `#EAE4D9` was 2.99:1. It is now `#6B645A` at **4.62:1**.

The arithmetic is why there was no third option: 4.5:1 on this paper needs a
luminance at or below `0.1344`, and `--quiet` at `#6B645A` is already
`0.1298`. The entire headroom between "passes AA" and "is already --quiet" is
**0.0046 of luminance** — invisible. So the three-step ink scale is two steps
now, deliberately.

Nothing was lost that was doing work. A kicker was never separated from a
caption by colour alone: 10.5px / 700 / 0.2em / uppercase against 12.5px /
400 / untracked. The colour step was redundant differentiation bought at the
price of readability.

**Not changed:** `--shop-disabled-bg`, the same hex used as a *background*
with `#1B1917` on it at 5.10:1. Darkening a disabled button's fill would push
its own label the wrong way.

**The exception was deleted from gate one**, not left behind. An exception
list is for decisions somebody made on purpose; leaving one after the decision
went the other way turns it into a blind spot with a comment attached.

## The migration is applied

Migration 032 ran against the live database, verified first against the live
schema rather than the repo. Membership unchanged — **33 rows before and 33
after** — which was the thing to prove. What changed is that those 33 now
carry **$3,300.00** of money the console could not previously see: 26 orphaned
attempts at $2,600 and 7 unmapped decline codes at $700.

Both drafting errors caught earlier were real: `app.billing_attempts` has no
`amount` column (confirmed live), and the cycle-gap branch reads
`app.v_cycle_audit`.

## The console is truthful in both server states

The Edge Function change is committed but **not deployed** — that needs the
Supabase CLI with an access token, which the build container does not have.
So the console asks the payload rather than assuming:

| Server shape | Headline | Amounts | Note |
| --- | --- | --- | --- |
| old (7 columns) | "2 things need a human today." | `—` | shown, explains why |
| new (10 columns) | "2 things need a human today, holding $100.00." | `$100.00` | hidden |

The test is `hasOwnProperty('amount_at_stake')`, not truthiness: a cycle gap
legitimately carries null, and null must read as "none" rather than "the
service is behind". Verified in both states with no page errors.

## Still not done

`functions/billing-console/index.ts` needs deploying. One command, from a
machine with the CLI logged in:

```
git pull origin main
supabase functions deploy billing-console --project-ref oiyibdczkokegaxkwulv
```

It typechecks clean under Deno 2.9.5. Until it ships the console shows dashes
and says why, which is the honest state rather than a broken one.
