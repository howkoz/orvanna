# Patch Launch Advisory: start here, next Claude

> Written 2026-09-08 at the end of the session that built the playbook. This is the one door
> for the engagement. Read it, then the README in this folder, then the two HTML files. Do not
> go looking through the rest of the ORVANNA tree or the job workspace; nothing else is in
> scope for this engagement.
> Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\ADVISORY\PATCH-LAUNCH\_START-HERE-NEXT-CLAUDE.md`

## Scope, in one paragraph

Howard is advising a founding group who have a nicotine patch product and want to build a
multi-level marketing (MLM) company in the US, start to finish. This is his personal
consulting, on his own time, unrelated to his employer. He has twenty years in the industry
and his frame is the spine of everything here: **the products and the comp plan are the
business; everything else is plumbing.** Your job in this session is this engagement only.
Not the Orvanna site, not the payment orchestrator, not anything from the job workspace.

## Hard rules that apply here (Howard's, not negotiable)

1. **No em dashes, no en dashes.** Commas, colons, ASCII hyphens only. Check every file
   before it leaves your hands: `grep -n -e '—' -e '–' <file>` must return nothing.
2. **Spell out every acronym the first time**, or add an acronym key. PV is Personal
   Volume, CV is Commissionable Volume, FDA, FTC, PACT Act, DSA all get expanded.
3. **Never delete.** Supersede with a `SUPERSEDED-` prefix, or move with a pointer note.
4. **Print plain absolute Windows paths** when pointing Howard at a file, so he can paste
   them. On his machine Python is `py`, not `python`.
5. **The fence.** This folder is on the personal side. No employer material, no company
   names from his job, no proprietary numbers. Public industry mechanics with generic
   naming only. See the brain decision `2026-08-13-personal-work-separation` if you need
   the reasoning.
6. **Short replies, no permission-asking for reversible work.** Howard is a visual
   learner: pair words with a table or a diagram whenever the content allows it.

## What exists right now

| File | What it is |
|---|---|
| `patch-launch-playbook.html` | The full twelve-section speaking guide used for the 2026-09-08 briefing. Self-contained, opens in any browser. Canonical copy. |
| `patch-launch-cheat-sheet.html` | The same content as one card per section, for the room. |
| `README.md` | Section map and the stance on comp plan ownership. |
| This file | The handoff. |

Both HTML files are also private Claude artifacts, useful for phone reading:

- Playbook: https://claude.ai/code/artifact/75945cc4-dc57-4036-b3c6-1f697ef02844
- Cheat sheet: https://claude.ai/code/artifact/de47b5d5-e484-452a-a213-6274c884d4fa

If an artifact and the file here ever differ, the file here wins. Republishing an artifact
from a new session needs its URL passed as `url`; publishing without it creates a duplicate.

**Git state at handoff:** the folder lives on branch `claude/patch-launch-playbook` in the
personal repository (howkoz/orvanna), draft pull request #5, not yet merged to main. Howard
may have merged it by the time you read this; check with `git branch -a` and `git log`. If
it is still a branch, continue on it. Do not rebase or force-push.

## The stance that must not drift

The founders choose the compensation plan. Howard does not pick it for them. His role:

1. Teach the five shapes (unilevel, binary, matrix, stairstep breakaway, hybrid) and what
   each pays for.
2. Recommend a starting point with reasons. The standing recommendation is a **unilevel or
   a lean unilevel hybrid with a hard per-order ceiling**, because it is easiest to explain,
   easiest to audit, and hardest to overpay.
3. Run a two-to-three-hour **plan design workshop** where the founders answer six questions:
   who gets paid most in year one (customer-seller, team-builder, leader); payout budget as a
   share of every dollar in; how simple it must be for their field; exciting versus durable;
   the ranks and titles they want; the shape to launch with.
4. Model the one or two candidate plans they leave with, against their real inputs.

The script, verbatim, if they push: "I'm not going to pick your plan for you, and you
shouldn't want me to. The plan is the promise you make to your field, and you're the ones
who'll stand behind it. What I'll do is make it a decision you can actually make. Your job
is the choice. Mine is making sure it's an informed one, and then proving the math."

Recorded as a brain decision: `BRAIN\decisions\2026-09-08-founders-own-the-comp-plan.md`
in the job workspace repository (the brain lives there; the material lives here).

## The numbers the documents use (illustrative, keep them consistent)

| Item | Value |
|---|---|
| Pricing flow | $14 landed, $60 distributor, $75 retail, 60 PV, 48 CV (CV is 80 percent of PV) |
| Landed cost ceiling | 15 to 25 percent of retail; above a quarter is a deal-breaker |
| Payout budget | 35 to 45 percent of CV, roughly 28 to 36 percent of money in |
| Retail dollar split | product 18, commissions 32, fulfillment and payments 9, operations 20, regulatory 6, retained 15 (percent) |
| Qualification gate | one monthly gate, 100 PV is the common figure |
| Buy-back | 90 percent of resalable product for twelve months |
| Retention scenarios | model at 70, 80 and 90 percent monthly autoship retention |
| State MLM registration | Georgia, Louisiana, Maryland, Massachusetts, Montana, Wyoming |
| Roadmap | five phases, 0 to 18 months, one gate each (see section 09) |

## What happened on 2026-09-08

Howard had two hours' notice. The playbook was built, one layout defect was fixed (list items
had broken one word per line because a grid was used as a bullet), the comp plan ownership
block was added at his request, the cheat sheet followed, and everything was filed here and
recorded in the brain. **The outcome of the briefing itself is not recorded yet.** That is
the first thing to ask.

## Your first move

Ask Howard, in one short message, for three things:

1. How the briefing went, and what the founders answered on the gating question: is the
   patch FDA-approved for cessation, licensed, or neither? Everything downstream depends
   on this answer.
2. Anything they said on the six workshop questions, even partial.
3. Whether the engagement continues, and if so which deliverable he wants first.

Then record the answers: update `README.md` here with a short "Where it stands" block, and
update the brain (`BRAIN\projects\patch-launch-advisory.md` and a journal entry) in the job
workspace repository. Do that before building anything.

## The deliverables, in the order the playbook promises them

Build only what Howard asks for, but this is the sequence section 11 commits to:

1. **Regulatory counsel session prep**: the questions to settle the product category, the
   two paths drawn side by side, what each one does to shipping, claims, and launch date.
2. **Pricing and payout-budget workbook**: landed cost, PV and CV, the ceiling, three
   retention scenarios. Needs the founders' real inputs; do not build it on guesses. Excel
   with a `py` builder script, per Howard's usual pattern.
3. **Plan design workshop kit**: the six questions as a facilitator's guide with the
   trade-offs spelled out, and a one-page template for each candidate plan.
4. **Plan design brief**: type, ranks, qualification, ceiling, modeled on a simulated
   mature tree, with the payout report that tree would produce.
5. **Platform shortlist** with the payment and payout architecture drawn out.
6. **The 18-month plan** with dates and owners against every gate.

Inputs the workbook and the model cannot proceed without: landed cost per unit, retail and
distributor prices, expected customer-to-distributor mix, the retention they believe in,
and the regulatory path.

## Resume prompt (Howard pastes this to start the next session)

```
Read C:\Users\howar\Desktop\Desktop\ORVANNA\ADVISORY\PATCH-LAUNCH\_START-HERE-NEXT-CLAUDE.md
first and follow it. This session is the patch launch advisory only; do not touch the
Orvanna site or anything in the job workspace except the brain. Start by asking me how the
briefing went and what the founders answered on the product's regulatory status, then
record the answers before building anything.
```
