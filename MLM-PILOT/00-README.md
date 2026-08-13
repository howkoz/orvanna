# MLM Pilot (personal project)

> **As of 2026-08-13.** Howard's personal prototype: a working direct-selling
> (multi-level marketing, MLM) function model with 1,000 synthetic accounts, a real
> database, and a public website on Howard's own domain.
> Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\` (moved out of the job
> workspace 2026-08-13; the ORVANNA root is the personal umbrella, see its 00-README.md)

## Ownership guardrails (non-negotiable, same as Orvanna)

- **Personal IP.** Built on Howard's own time, accounts, and domain.
- **Brand persona: Globex Wellness** (the established generic persona). No Unicity
  name, data, customer records, or proprietary numbers anywhere in schema, seed data,
  site copy, or commits.
- Generic industry terms only: "sales volume" and "team volume" (not Unicity's internal
  report names), "rank", "sponsor", "enrollment".
- Hosting and database on a PERSONAL Supabase organization (new free org under
  Howard's personal email), not the org that serves Unicity work.

## What v1 proves (Council-scoped)

A visitor to the domain sees a working member portal for a fake wellness company:
1,000 members in a realistic unilevel tree, monthly sales volume rolling up the
genealogy, ranks earned by rules, and a commission run that pays levels with an
auditable statement per member. All numbers synthetic, all math real.

## The stack ($0/month beyond the domain Howard already owns)

| Piece | Choice | Cost |
|---|---|---|
| Database + API + auth | Supabase free tier (Postgres, row-level security) | $0 |
| Website hosting | GitHub Pages or Cloudflare Pages (both free, custom domain free) | $0 |
| Seed + analytics | Python + DuckDB locally | $0 |
| Domain | **orvanna.io** (Howard's, received 2026-08-13; apex vs subdomain decided at Phase 5) | already owned |

## The development team (agents)

Six role agents live in `ORVANNA\.claude\agents\` with the `mlm-` prefix, built on
the five-teams model (start Claude sessions in the ORVANNA folder to register them):

| Agent | Team | Owns |
|---|---|---|
| mlm-architect | Planner | Schema design, comp-plan rules spec, decisions log |
| mlm-db-engineer | Builder | Supabase SQL migrations, row-level security, seed generator (1,000 accounts) |
| mlm-comp-engineer | Builder | Volume rollup, rank qualification, commission run engine |
| mlm-site-builder | Builder | The portal website (static + Supabase client) |
| mlm-verifier | Verifier | CORRECTNESS: recomputes the math independently, tree integrity, security review. Never the builder of what it grades. |
| mlm-qa | Verifier | COMPLETENESS: acceptance checklist per phase, requirements traceability, end-to-end functional testing. Added 2026-08-13 at Howard's request. |

Every phase needs BOTH verifier-team signatures to close: mlm-verifier proves the
numbers are right, mlm-qa proves everything promised was delivered and works.

The Council (seven-persona vetting) runs inline before each phase; verdicts file in
`ROADMAP.md`.

## Key documents

- `ROADMAP.md`: phases, v1 scope, council verdict, next small step (protect momentum)
- `db\` : migrations and seed scripts (created in Phase 1)
- `site\` : the website (created in Phase 3)
- `docs\decisions\` : one file per decision, dated
