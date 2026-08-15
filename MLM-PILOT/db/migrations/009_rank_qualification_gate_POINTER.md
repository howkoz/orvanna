# 009_rank_qualification_gate_v13 (pointer)

Same convention as the `008` pointer beside this file, and written for the same
reason: the live ledger holds an entry that the repository could not otherwise
account for.

## Is 009 real?

Yes. It is a genuine, separately applied migration, not a numbering gap.

- Live ledger entry: version `20260813192404`, name
  `009_rank_qualification_gate_v13`, roughly 8,300 characters of body.
- It is distinct from `008_comp_engine_v12` (version `20260813185042`), which is
  a different body of roughly 9,700 characters.
- Both entries redefine `app.fn_run_commission`. 008 stamps `spec_version`
  `v1.2`; 009 stamps `v1.3`.

The earlier note in `db\README.md`, which said 009 "stays unassigned until its
owner claims it", was wrong. It has an owner and it is applied to production.
That note is corrected in the rewritten README beside this file.

## What 009 did, and why

Howard's ruling of 2026-08-13, taken from the Phase 3 verifier's finding: a
member must be QUALIFIED, meaning Sales Volume (SV) of at least 100, in order to
HOLD any rank above Member. Before 009, only `builder_flag` carried the
qualified test. After 009, `leader_flag`, `director_flag` and `executive_flag`
carry it too.

The engine stamps `spec_version` `v1.3` from that point on. Reruns under v1.3
supersede the v1.2 finalized runs, and the superseded statements stay frozen,
because migration 006 treats `final` and `superseded` as equally immutable.

## Where the source lives

`..\comp\001_comp_engine.sql` is the canonical engine source and **already
carries the v1.3 text**. Its header says so explicitly:

> Spec: docs\COMP-PLAN-SPEC.md version v1.3 ... qualification (SV >= 100) is
> required to HOLD any rank above Member, so leader_flag, director_flag, and
> executive_flag all carry the qualified test.

So the SQL (Structured Query Language) that 009 applied is not missing from this
repository. What was missing is any record connecting the ledger entry to that
file. This pointer is that record.

## The rebuild consequence, stated plainly

One engine file maps to two ledger entries. A rebuild from this repository
therefore produces a ledger with one row where production has two: it applies
the v1.3 engine once and never passes through the v1.2 state. The resulting
SCHEMA and the resulting FUNCTION BODY are correct and identical to production.
Only the ledger row count differs.

That is an acceptable difference and it is deliberate, because keeping a second
copy of a 9,000 character engine file purely to reproduce a ledger row would
mean two files to keep in step forever, which is a worse failure mode than a
missing row in a history table.

If an exact ledger reproduction is ever needed, the v1.2 body is recoverable
from `supabase_migrations.schema_migrations` at version `20260813185042`.

## Run order

Migrations 001 through 007, then `..\comp\001_comp_engine.sql`, then the data
loaders, then the runs, then migrations 010 onward. See `..\README.md`.
