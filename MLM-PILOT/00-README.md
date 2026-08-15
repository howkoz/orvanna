# MLM Pilot (personal project)

> **As of 2026-08-13.** Howard's personal prototype: a working direct-selling
> (multi-level marketing, MLM) function model with 1,000 synthetic accounts, a real
> database, and a public website on Howard's own domain.
> Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\MLM-PILOT\` (moved out of the job
> workspace 2026-08-13; the ORVANNA root is the personal umbrella, see its 00-README.md)

## Ownership guardrails (non-negotiable, same as Orvanna)

- **Personal IP.** Built on Howard's own time, accounts, and domain.
- **Brand: Orvanna** (decided 2026-08-13; Howard's own brand, matching orvanna.io).
  No earlier placeholder brand survives anywhere in the code, the site, or the
  schema. No Unicity name, data, customer
  records, or proprietary numbers anywhere in schema, seed data, site copy, or commits.
- Generic industry terms only: "sales volume" and "team volume" (not Unicity's internal
  report names), "rank", "sponsor", "enrollment".
- Hosting and database on a PERSONAL Supabase organization (new free org under
  Howard's personal email), not the org that serves Unicity work.

## What v1 proves (Council-scoped)

A visitor to the domain sees a working member portal for a fictional AI-agent
marketplace under the Orvanna brand: members subscribe to digital AI agents (domain
agents $100 / 100 volume points, support agents $50 / 50), 1,000 members in a
realistic unilevel tree, subscriptions generating monthly orders, volume rolling up
the genealogy, ranks earned by rules, and a commission run that pays levels with an
auditable statement per member. All numbers synthetic, all math real.

## The stack ($0/month beyond the domain Howard already owns)

| Piece | Choice | Cost |
|---|---|---|
| Database + API + auth | Supabase, Orvanna org on PRO plan (Howard's deliberate choice 2026-08-13; free tier would also carry v1) | $25/month |
| Website hosting | **GitHub Pages** (chosen and live since 2026-08-14). Serves the built output from the PUBLIC repository github.com/howkoz/orvanna.io; the private repository github.com/howkoz/orvanna holds the source. Custom domain free, HTTPS enforced. | $0 |
| Seed + analytics | Python + DuckDB locally | $0 |
| Domain | **orvanna.io** (Howard's, received 2026-08-13; apex vs subdomain decided at Phase 5) | already owned |

## The development team (agents)

EIGHT role agents live in `ORVANNA\.claude\agents\`, built on the five-teams model
(start Claude sessions in the ORVANNA folder to register them). Six carry the
`mlm-` prefix; the designer and the writer were hired later, at Phase 4B, and
carry the `orvanna-` prefix:

| Agent | Team | Owns |
|---|---|---|
| mlm-architect | Planner | Schema design, comp-plan rules spec, decisions log |
| mlm-db-engineer | Builder | Supabase SQL migrations, row-level security, seed generator (1,000 accounts) |
| mlm-comp-engineer | Builder | Volume rollup, rank qualification, commission run engine |
| mlm-site-builder | Builder | The portal website (static + Supabase client) |
| mlm-verifier | Verifier | CORRECTNESS: recomputes the math independently, tree integrity, security review. Never the builder of what it grades. |
| mlm-qa | Verifier | COMPLETENESS: acceptance checklist per phase, requirements traceability, end-to-end functional testing. Added 2026-08-13 at Howard's request. |
| orvanna-designer | Builder | The visual system: the corporate site, the shop, the glow design language. Hired at Phase 4B. |
| orvanna-writer | Builder | The words on screen: framing, decline copy, receipts, test-mode notices. Hired at Phase 4B. |

Every phase needs BOTH verifier-team signatures to close: mlm-verifier proves the
numbers are right, mlm-qa proves everything promised was delivered and works.

The Council (seven-persona vetting) runs inline before each phase; verdicts file in
`ROADMAP.md`.

## Key documents

- `ROADMAP.md`: phases, v1 scope, council verdict, next small step (protect momentum)
- `docs\FIGMA-VISUAL-PACK.md`: the end-to-end "Whole Machine" Figma board (how everything fits, 16 numbered steps)
- `docs\decisions\` : one file per decision, dated

## Folder structure (updated 2026-08-15)

The list above named only two folders and was written at Phase 1, when only two
existed. What is actually here now:

| Folder | What it holds | Arrived |
|---|---|---|
| `db\` | Migrations, the commission engine SQL, and the seed generator | Phase 1 and 2 |
| `site\` | The MEMBER PORTAL, the office a member signs into. Published at /portal/ | Phase 4 |
| `www\` | The PUBLIC SITE: corporate home, shop, product pages, team page, sign-in, and the staff call console. Published at the domain root | Phase 4B |
| `functions\` | The SERVER: seven Supabase Edge Functions written in TypeScript on the Deno runtime, plus three shared modules. Everything holding a secret or writing to the database lives here and nowhere else | Phase 6 |
| `deploy\` | `build_dist.py`, which assembles `www\` and `site\` into the folder that gets published, and the built output under `deploy\dist\` | Phase 5 |
| `docs\` | Specifications, decisions, research, and the two-gate records under `docs\verification\` and `docs\qa\` | throughout |

A full architecture description, including every language in use, the purchase
path hop by hop, and the security rails, lives one level up at
`..\DOCUMENTATION\01-ARCHITECTURE.md`
(plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\01-ARCHITECTURE.md`).
