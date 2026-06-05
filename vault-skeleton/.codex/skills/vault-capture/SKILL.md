---
name: vault-capture
description: Capture an insight, decision, meeting note, or research finding into the knowledge base.
allowed-tools: Read Write Edit
agent: codex
---

# Vault Capture Skill

Saves a thought, decision, or meeting note to the vault with correct frontmatter v3 schema. Default target is `Inbox/`. For AI-Memory captures (session-report, failure-log, pattern, orchestration, profile), this skill also routes to the matching `Engineering/AI-Memory/` subfolder.

> For AI-Memory captures, prefer the dedicated skills (`vault-session-end`, `vault-failure-log`, `vault-pattern-extract`, `vault-orchestration-log`) - they have type-specific guidance. Use `vault-capture` for ad-hoc Inbox captures or when you only have raw content and need quick routing.

## Workflow

1. Ask the user (or infer from context) what type of note to create:
   - `decision` - engineering or strategic decision record
   - `meeting` - meeting note with agenda and action items
   - `brief` - CEO brief or board brief
   - `research` - market or user research note
   - `session-report` - AI agent session summary (prefer `vault-session-end`)
   - `failure-log` - AI agent failure capture (prefer `vault-failure-log`)
   - `pattern` - reusable AI agent pattern (prefer `vault-pattern-extract`)
   - `orchestration` - multi-agent pipeline record (prefer `vault-orchestration-log`)
   - `profile` - agent profile note (claude-code, codex-cli, gemini-cli, shared-conventions)
   - `note` - general insight or inbox item (default)

2. Pick the matching template from `Templates/`:
   - `decision` -> `Templates/Decision Record.md`
   - `meeting` -> `Templates/Meeting Note.md`
   - `brief` -> `Templates/Board Brief.md`
   - `research` -> `Templates/Research.md`
   - `session-report` -> `Templates/AI Session Report.md` (if present)
   - `failure-log` -> `Templates/Failure Log.md`
   - `pattern` / `orchestration` / `profile` -> no template; compose with frontmatter shown below
   - `note` / default -> write directly with v3 frontmatter

3. Determine the target path based on `type:`:

   **Routing table**

   | type | target folder |
   |------|---------------|
   | `note` (default) | `Inbox/` (Auto Note Mover re-files by tag) |
   | `decision` (engineering) | `Engineering/Decisions/` |
   | `decision` (strategy) | `Strategy/Decisions/` |
   | `meeting` | `Operations/Meetings/` |
   | `brief` | `Strategy/Briefs/` |
   | `research` | `Resources/Research/` |
   | `session-report` | `Engineering/AI-Memory/sessions/` |
   | `failure-log` | `Engineering/AI-Memory/failures/` |
   | `pattern` | `Engineering/AI-Memory/patterns/` |
   | `orchestration` | `Engineering/AI-Memory/orchestrations/` |
   | `profile` | `Engineering/AI-Memory/agent-profiles/` |

   If `type` is unclear, default to `Inbox/` and let Auto Note Mover route by tag.

4. Read the matching template (if any) to understand frontmatter fields required.

5. Compose the note with:
   - Full v3 frontmatter (title, type, domain, status, tags, summary, created, updated, owner, scope)
   - For AI-Memory types, also include the type-specific fields (`agent`, `model`, `outcome`, `pattern`, etc.)
   - Body content from user input
   - Appropriate wikilinks to related notes

6. Confirm the composed note with the user before writing. Show the full content.

7. Write the file only after user confirms.

## Frontmatter minimums

Every note must have at minimum:
```yaml
title: "..."
type: note
domain: knowledge
status: draft
tags:
  - domain/knowledge
  - status/draft
summary: "..."
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: <owner>
scope: internal
```

## File naming

- General note: `YYYY-MM-DD <short-title>.md` (kebab-case for slug)
- Decision: `YYYY-MM-DD decision-<topic>.md`
- Meeting: `YYYY-MM-DD <Meeting Name>.md`
- Session report: `YYYY-MM-DD_<agent>_<task-slug>.md`
- Failure log: `YYYY-MM-DD-HHMMSS_<agent>_<pattern-slug>.md`
- Pattern / orchestration: `<slug>.md` (no date prefix - evergreen)
- Agent profile: `<agent-name>.md`
- No emoji in filenames

## Anti-patterns

- Do not write to `Archive/` (frozen)
- Do not write to vault root
- Do not skip the confirmation step before writing
- Do not invent content - only write what the user provided
- Do not use `vault-capture` when a type-specific skill exists
- Do not route AI-Memory types to `Inbox/` - those have explicit target folders
