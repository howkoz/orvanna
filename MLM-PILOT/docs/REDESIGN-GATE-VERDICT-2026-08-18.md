# Redesign gates, 2026-08-18

Both gates run against the built artifact in `deploy/dist`, not the source.
Bundle **`sha256 5b4bfe891b253eb0`**.

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
