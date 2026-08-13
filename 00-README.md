# ORVANNA (Howard's personal venture root)

> As of 2026-08-13. Everything in this folder is Howard Koziara's PERSONAL property:
> his own time, his own accounts, his own domain (orvanna.io). It was separated out of
> the CLAUDE-WORK job workspace on 2026-08-13 so personal and employer material never
> share a folder tree or a git history again.
> Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\`

## What lives here

| Folder | What it is |
|---|---|
| `LIBRARY\` | **The front door to every document.** Start at `LIBRARY\00-INDEX.md`: company docs (profile, team), brand, all technical docs indexed with one canonical home each. |
| `PLATFORM\` | The Orvanna flagship: a universal payment-orchestration product concept. Charter, tracker, 14 model documents, roadmap, demos. Moved from the job workspace's orchestrator folder 2026-08-13. |
| `MLM-PILOT\` | Working direct-selling (multi-level marketing, MLM) prototype: 1,000 synthetic accounts, Supabase database, commission engine, demo portal. Deploys to orvanna.io. |
| `.claude\agents\` | The six-agent development team for the pilot (architect, database engineer, compensation engineer, site builder, verifier, quality assurance). |

## House rules (the fence)

1. Personal Claude sessions START IN THIS FOLDER, so notes, memory, and agents stay on
   the personal side automatically.
2. Zero employer material: no company data, documents, customer records, internal report
   names, or proprietary numbers anywhere in this tree. Public industry mechanics with
   generic naming only.
3. Built off the clock, on personal accounts (personal Supabase organization, personal
   GitHub repositories kept PRIVATE).
4. Never delete: archive or move with a pointer note, same as everywhere else.

## Git

This root is its own git repository (initialized 2026-08-13), separate from the job
workspace's repository. Remote: create a PRIVATE GitHub repository (for example
howkoz/orvanna) and push when ready; the GitHub command line tool is not installed on
this machine, so create it on github.com and wire it with:

```bash
git remote add origin https://github.com/howkoz/orvanna.git
```

```bash
git push -u origin main
```

## Where things were before the split

- `PLATFORM\` was `CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\`
- `MLM-PILOT\` was `CLAUDE-WORK\MLM-PILOT\`
- The agents were in `CLAUDE-WORK\.claude\agents\`

Pointer notes remain at each old location. Old copies also survive in the job
repository's git history (history was not rewritten; the fence matters going forward).
