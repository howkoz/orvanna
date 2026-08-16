# 023_refund_guard_fix (pointer)

Same convention as the `008` and `009` pointers beside this file, and written for
the same reason: the live ledger holds an entry that the repository could not
otherwise account for. Written 2026-08-16 during the documentation truth reset
(Step 0 of `..\..\docs\STABILIZATION-PLAN-2026-08-16.md`); this closes finding
N-M2 in `DOCUMENTATION\06-QA-AND-VERIFICATION.md` section 4.1b.

## Is 023 real?

Yes. It is a genuine, separately applied migration, not a numbering gap.

- Live ledger entry: version `20260816012057`, name `refund_guard_fix_023`.
- Status: **APPLIED** to production on 2026-08-16, minutes after migration 022.

## What 023 did, and why

Migration 022 widened the `payment_status` CHECK constraint on `app.demo_orders`
to admit `refunded` and `partially_refunded`. Migration 010's transition-guard
trigger had only ever tested where a row was coming FROM, and relied on that
CHECK constraint to reject any destination value it had never heard of. Widening
the constraint silently removed the thing that was doing the work, so
`processing -> refunded` and `created -> refunded` became legal transitions:
the guard fell through to `return new` for both.

Migration 023 closed that: a refund state may now be entered ONLY from a paid
state (`succeeded` or `partially_refunded`). The defect was caught by migration
022's own section 9 guard tests on 2026-08-16, AFTER 022 was applied and BEFORE
any refund existed, so no data was ever affected. The Edge Function never
attempts the transition, because `refund-rules.ts` requires `succeeded` first;
this was a missing database backstop rather than a live hole.

The general lesson, recorded in 022 as well: when you widen a CHECK constraint,
re-read every trigger that was relying on it to be narrow.

## Where the source lives

The Structured Query Language (SQL) text of 023 was folded into
`022_refunds.sql`, section 2, inside the function
`app.demo_orders_guard_status_transition()`. The block is marked in place with
the comment "ADDED BY MIGRATION 023, AND THE REASON IS WORTH READING" (around
line 199 of that file). So the SQL that 023 applied is not missing from this
repository. What was missing is any record connecting the ledger entry to that
file. This pointer is that record.

## The rebuild consequence, stated plainly

One migration file maps to two ledger entries, exactly as `comp\001_comp_engine.sql`
maps to entries 008 and 009. A rebuild from this repository applies
`022_refunds.sql` once, with the 023 fix already inside it, and never passes
through the broken intermediate state where `processing -> refunded` was legal.
The resulting schema and the resulting function body are correct and identical
to production. Only the ledger row count differs, and the broken intermediate
state is deliberately not reproducible.

If an exact ledger reproduction is ever needed, the applied bodies are
recoverable from `supabase_migrations.schema_migrations` at versions
`20260816011917` (`refunds_022`) and `20260816012057` (`refund_guard_fix_023`).
Both versions were read back from the live ledger on 2026-08-16 while writing
this pointer, not assumed.

## Run order

Migrations 001 through 007, then `..\comp\001_comp_engine.sql`, then the data
loaders, then the runs, then migrations 010 onward; `022_refunds.sql` carries
the 023 fix inside it. See `..\README.md`.
