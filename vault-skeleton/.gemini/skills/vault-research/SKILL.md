---
name: vault-research
description: Research the knowledge base for historical context, prior decisions, strategy, and memory.
context: fork
agent: gemini
allowed-tools: Read Grep Glob
---

# Vault Research Skill

## Workflow

1. Read `Meta/Home.md` to understand vault scope and available domains.
2. Identify which domain MOC matches the query (Strategy, Product, Sales, Engineering, Operations, People, Knowledge).
3. Read the matching MOC file from `Meta/MOC-*.md`.
4. Follow wikilinks from MOC to specific notes that match the query.
5. Read frontmatter `summary` field first; only read the full body if summary indicates relevance.
6. Synthesize answer with file paths cited.

## Domain MOC map

| Query topic | MOC file |
|-------------|----------|
| Strategy, GTM, vision, market position | `Meta/MOC-Strategy.md` |
| Product, roadmap, features, modules | `Meta/MOC-Product.md` |
| Sales, deals, customers, pipeline | `Meta/MOC-Sales-Pipeline.md` |
| Marketing, campaigns, content | `Meta/MOC-Marketing.md` |
| Engineering, code, architecture, debugging | `Meta/MOC-Engineering.md` |
| Operations, OKRs, meetings, board | `Meta/MOC-Operations.md` |
| People, team, advisors, investors | `Meta/MOC-People.md` |
| Competitors, market intel, research, tech reference | `Meta/MOC-Knowledge.md` |

## AI-Memory layer awareness

Beyond the standard MOC hierarchy, the vault has an AI agent memory layer at `Engineering/AI-Memory/` (entry: `MOC-AI-Memory.md`). When researching a topic, also check:

- **`failures/`** - past failure logs. Always check before attempting a task similar to one that previously failed. Filter by `domain:` matching current task, or grep for keywords from the task description.
- **`patterns/`** - reusable success patterns. Read top 5 most recent before starting non-trivial work.
- **`sessions/`** - session reports from prior runs. Useful when picking up incomplete work or understanding what was already tried.
- **`agent-profiles/`** - per-CLI behavioral notes. Read `shared-conventions.md` always; read your own profile for runtime-specific quirks.

This skill is READ-ONLY for AI-Memory. To WRITE memory, use dedicated skills: `vault-session-end`, `vault-failure-log`, `vault-pattern-extract`, `vault-orchestration-log`.

## Output format

Return a concise answer (200-500 words) with:
- Direct answer to the question.
- Citations as `[[wikilink]]` to source files, with the absolute file path noted.
- "See also" section with related notes for deeper reading.

## Anti-patterns

- Do not random-search the vault - use `Meta/Home.md` as entry point.
- Do not read the full body of every matching file - use the `summary` field first to filter.
- Do not invent facts or synthesize beyond what source notes contain.
- Do not modify any files (this skill is read-only).
