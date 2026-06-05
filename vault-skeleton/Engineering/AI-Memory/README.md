---
title: "AI-Memory - Single-Source Layout & Mechanics"
type: reference
domain: engineering
status: active
tags: [domain/engineering, status/active, lifecycle/area]
summary: "Single-source memory for 3 AI runtimes. Describes layout by domain, load mechanism (@import digest + SessionStart hook), write mechanism (skill user-confirm), and capability matrix per-runtime."
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
scope: internal
---

# AI-Memory - Single-Source Layout & Mechanics

This is the **single source of memory** for all 3 AI CLI runtimes (Claude Code, Codex CLI, Gemini CLI). No runtime keeps a private memory store - all reads/writes go to this folder (committed to git, cross-runtime, cross-machine, with history).

## Two content types

| Type | Location | Who writes | When |
|---|---|---|---|
| **Curated (long-term)** | `{sessions,failures,patterns,orchestrations}/<domain>/` | Agent via `vault-*` skill, **user-confirm** | When user confirms (decision/outcome) |
| **Raw (auto)** | `auto/<project>/` | Claude Code auto-memory (redirect) | Automatically during session |

`auto/` is a machine-written inbox; periodic curation promotes durable facts to `{type}/<domain>/`. Both live in the vault - "1 source".

## By domain

8 domains (schema v3): `engineering` (default) - `marketing` - `operations` - `people` - `product` - `sales` - `strategy` - `knowledge`. Route via `domain` field in frontmatter to the correct subfolder. Cross-domain filter via `_index/*.txt` (grep) or Dataview `WHERE domain = "..."` (Obsidian UI only).

## Load mechanism (read) - efficient, every agent

1. **`@import _digest.md`** - all 3 control files (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`) import `_digest.md`. Always-on, every turn. Digest is small (<= ~6-8K chars): core facts + headline recent. Auto-refreshes via auto-commit + GitHub Actions.
2. **SessionStart hook (Claude Code only)** - `~/.claude/hooks/cc-session-start-memory.sh` reads `_digest.md` + sentinel + `_index`, injects `additionalContext` at session start. Codex/Gemini do NOT support this hook type - they use `@import` only (sufficient for core).
3. **On-demand** - agent greps `_index/*.txt` or reads a specific note in `{type}/<domain>/` when task needs deeper context.

## Write mechanism - by user decision

- Curated: skills `vault-session-end` / `vault-failure-log` / `vault-pattern-extract` / `vault-orchestration-log` - **always confirm with user before writing**, route by domain.
- Core durable facts: edit `_core-memory.md` by hand when user confirms - digest picks up on regen.
- Claude auto-memory: writes raw to `auto/<project>/` (redirect via `autoMemoryDirectory`).
- Gemini: **DO NOT use `save_memory`** (it writes hard into `~/.gemini/GEMINI.md`, not the vault) - write vault via MCP filesystem per instructions in GEMINI.md.

## Capability matrix per runtime

| | Read digest | SessionStart hook | Auto-write redirect | Write curated |
|---|---|---|---|---|
| Claude Code | `@import` + hook | yes | yes `auto/<project>/` | skill user-confirm |
| Codex CLI | `@import` | no (not supported) | native memory off | MCP filesystem / skill, instruction-driven |
| Gemini CLI | `@import` | no (not supported) | save_memory blocked | MCP filesystem, instruction-driven |

## Generated files (DO NOT hand-edit)

- `_digest.md` <- `_scripts/gen-memory-digest.sh`
- `_index/*.txt` <- `_scripts/regen-ai-memory-index.sh`

Edit by hand: `_core-memory.md` (core facts) + curated notes.

## Folder structure

```
Engineering/AI-Memory/
├── _core-memory.md          # Durable facts edited by hand. Source of digest.
├── _digest.md               # AUTO-GENERATED. Always-load for all runtimes.
├── README.md                # This file.
├── _index/                  # Grep-friendly flat indexes (AUTO-GENERATED)
│   ├── patterns-by-domain.txt
│   ├── sessions-by-agent.txt
│   ├── failures-by-pattern.txt
│   └── orchestrations-by-shape.txt
├── sessions/                # Session reports (type: session-report)
│   └── <domain>/            # Route by domain. Naming: YYYY-MM-DD_agent_slug.md
├── patterns/                # Reusable success patterns (type: pattern)
│   └── <domain>/
├── failures/                # Failure logs (type: failure-log)
│   └── <domain>/
├── orchestrations/          # Multi-step pipeline records (type: orchestration)
│   └── <domain>/
├── auto/                    # Raw auto-memory inbox (Claude Code redirect target)
│   ├── MEMORY.md            # Index 1-line-per-memory. Raw machine-written.
│   └── README.md
└── agent-profiles/          # Per-runtime conventions
    ├── shared-conventions.md
    ├── claude-code.md
    ├── codex-cli.md
    └── gemini-cli.md
```

Scripts live at `Engineering/AI-Memory/_scripts/`:

```
_scripts/
├── ai-memory-write.sh          # Runtime-agnostic writer
├── gen-memory-digest.sh        # Build _digest.md
├── regen-ai-memory-index.sh    # Rebuild _index/*.txt
├── session-end-sentinel.sh     # SessionEnd reminder (shared 3 runtimes)
└── load-context-hook.sh        # SessionStart loader for Codex + Gemini
```

## Regen index + digest manually

```bash
bash Engineering/AI-Memory/_scripts/regen-ai-memory-index.sh
bash Engineering/AI-Memory/_scripts/gen-memory-digest.sh
```

Run after bulk-importing notes or after a machine clone (before wiring hooks).
