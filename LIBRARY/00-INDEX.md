# The Orvanna Library

> As of 2026-08-13. The single front door to every Orvanna document.
> Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\LIBRARY\`
>
> **The one rule:** every document has ONE canonical home. This index POINTS at
> canonical homes; it never holds copies, so nothing can drift out of date. Documents
> created at company level live here in `LIBRARY\`; documents that belong to a
> project's build stay with the project and are indexed from here.

## Company documents (canonical home: LIBRARY\company\)

| Document | What it is |
|---|---|
| `company\ORVANNA-COMPANY-PROFILE.md` | What Orvanna is: the venture, the two product lines, ownership, the fence |
| `company\TEAM-PROFILE.md` | The whole team: Howard + six specialist agents, their job skills, records, and hiring dates |

## Brand (canonical home: ..\brand\)

| Document | What it is |
|---|---|
| `..\brand\README.md` | Brand book: the decision, palette, file inventory |
| `..\brand\logo-final-primary.svg` (+ dark, header, icon, favicon) | The final logo kit, all lettering drawn as paths |

## MLM Pilot, member-facing (canonical home: ..\MLM-PILOT\docs\)

| Document | What it is |
|---|---|
| `..\MLM-PILOT\docs\ORVANNA-COMP-PLAN-BOOKLET.html` | THE compensation plan booklet, version 1.1: every number in text, full worked example, glossary, calendar, version log |

## MLM Pilot, technical (canonical home: ..\MLM-PILOT\docs\ and ..\MLM-PILOT\db\)

| Document | What it is |
|---|---|
| `..\MLM-PILOT\ROADMAP.md` | Phases, scope, gate status, next small step |
| `..\MLM-PILOT\docs\SCHEMA-SPEC.md` | Every table, key, security rule, view; the database contract |
| `..\MLM-PILOT\docs\COMP-PLAN-SPEC.md` | The plan's math, v1.1: rules, edge cases, the hand-computed ground truth |
| `..\MLM-PILOT\docs\decisions\2026-08-13-genealogy-representation.md` | Why adjacency list + per-run snapshot |
| `..\MLM-PILOT\docs\verification\PHASE-1-VERDICT.md` | Verifier gate report: PASS, 0 HIGH / 2 MEDIUM / 7 LOW |
| `..\MLM-PILOT\docs\qa\PHASE-1-QA.md` | Quality assurance gate report: PASS, 38 of 41 rows |
| `..\MLM-PILOT\docs\FIGMA-VISUAL-PACK.md` | The end-to-end "Whole Machine" board link |
| `..\MLM-PILOT\db\migrations\` | The five schema migrations (001 to 005) |
| `..\MLM-PILOT\db\seed\` | Deterministic seed generator + proof pack (seed 20260813) |

## Platform flagship (canonical home: ..\PLATFORM\)

| Document | What it is |
|---|---|
| `..\PLATFORM\_START-HERE-NEXT-CLAUDE.md` | One-door orientation for the payment-orchestration flagship |
| `..\PLATFORM\ROADMAP.md` | Flagship phase tracker (paused before Phase C) |
| `..\PLATFORM\00-CHARTER.md` + 14 model documents | The full system design library of the flagship |

## Filing rules for new documents

1. Company-wide (profiles, policies, brand statements): create in `LIBRARY\company\`, add a row here.
2. Project build material (specs, decisions, verdicts): create in that project's `docs\`, add a row here.
3. Member-facing pilot documents: `MLM-PILOT\docs\`, versioned in the document itself, row here.
4. Never duplicate a document into two homes; link to the canonical path instead.
5. Superseded documents get renamed with a `SUPERSEDED-` prefix, never deleted.
