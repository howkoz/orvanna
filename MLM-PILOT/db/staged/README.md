# Staged, not applied

Everything in this folder is written, reviewed and **deliberately not run**.

## Why anything is here

`032_attention_queue_consequence.sql` was written on 2026-08-19 during a
session where the owner was asleep and had said to finish the redesign and
deploy without waiting. Every presentation change in that session was built,
gated and deployed. This one was not, and the line is worth stating plainly:

- It touches a **live payment rail**. The subscription engine bills real
  sandbox cards on this database.
- It **cannot be verified from the container it was written in.** There is no
  access to the live database, so nothing here has been run against real
  data — only read against migrations 024 and 026 in this repository.
- The standing rule is **both gates on the exact artifact before deploy**
  (`BRAIN/decisions/2026-08-16-both-gates-before-deploy`), and the project
  already carries a debt of five ungated deploys to this rail from 08-17
  night. That debt is the reason to be careful, not a precedent for skipping.

A page that renders wrong can be looked at and fixed. A migration that runs
wrong against billing data cannot be un-run by looking.

## What it does

Adds `amount_at_stake`, `deadline_at` and `decline_class` to
`app.v_staff_attention_queue`, all nullable, and an `app.attention_cleared`
audit table. Full reasoning in `docs/OPERATIONS-QUEUE-SERVER-SPEC.md`.

## What is already true without it

The operations console ranks its queue by consequence today, using a policy
map over reason classes in `staff-operations.html`. What it does **not** show
is money at stake and one-click actions, and it says so on the page in a line
the reader cannot miss, rather than leaving the absence to be read as nothing
being owed.

## Two drafting errors caught before this was staged

Both are the reason to read a migration against the schema rather than trust
the prose that describes it:

1. The first draft selected `ba.amount`. **`app.billing_attempts` has no
   amount column.** The money is on `app.renewal_periods.amount_cents`,
   "priced at billing time, frozen" — which is the better source anyway,
   because it is what this renewal was going to charge rather than what the
   plan costs today.
2. The first draft read `app.v_cycle_accounting`. The cycle-gap branch
   actually reads `app.v_cycle_audit ... where not accounted`.

## To apply

Read `BEFORE THIS RUNS` at the foot of the SQL file. In short: run the view's
SELECT on its own first, then both gates, then the Edge Function change that
returns the new columns — the migration alone changes nothing on screen.
