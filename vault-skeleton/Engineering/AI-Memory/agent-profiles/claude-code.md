---
title: Claude Code agent profile
type: profile
domain: engineering
status: active
tags: [status/active, domain/engineering, activity/profile, lifecycle/area]
summary: Claude Code (Anthropic CLI) conventions for vault work.
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
scope: internal
related: ["[[shared-conventions]]", "[[codex-cli]]", "[[gemini-cli]]"]
---

# Claude Code Agent Profile

This profile documents Claude Code-specific conventions for vault work. All rules in shared-conventions.md apply and are not repeated here. Read shared-conventions.md before this file.

---

## Runtime Info

| Field | Value |
|---|---|
| CLI | Claude Code (Anthropic) |
| Primary model | `<primary-model>` (see current version) |
| Default subagent model | `<subagent-model>` |
| Mechanical / cheap tasks | `<haiku-model>` - **see caution below** |
| Global config | `~/.claude/CLAUDE.md` |
| Project config | `<vault>/CLAUDE.md` |
| Vault skills directory | `<vault>/.claude/skills/` |

**Haiku caution**: Haiku-tier models can refuse filesystem mutations under certain prompt conditions. Do not dispatch Haiku subagents for write tasks in the vault; use Sonnet minimum.

---

## Tools Available in Vault Context

Core file tools:
- `Read` - single file, with line-range support
- `Write` - full file creation or overwrite (requires prior Read on existing files)
- `Edit` - targeted string-replace diff (preferred over Write for existing files)
- `Bash` - shell commands
- `Grep` / `Glob` - search across vault

MCP servers (configure per team):
<!-- Configure: list your active MCP servers here.
Example:
| Server | Transport | Purpose |
|---|---|---|
| `filesystem` | npx | Anthropic official filesystem MCP, vault-scoped |
| `github` | OAuth | GitHub issue/PR access |
[CONFIGURE: add your MCP servers here]
-->

---

## Memory Architecture - SINGLE SOURCE

This vault folder (`Engineering/AI-Memory/`) is the **single source of memory** for Claude Code (and Codex/Gemini). No private per-project store. Full layout: `README.md`.

**Read (load):**
- `@import _digest.md` in `~/.claude/CLAUDE.md` (always-load: core facts + recent headlines).
- SessionStart hook `~/.claude/hooks/cc-session-start-memory.sh` injects the digest as `additionalContext` each session.
- Drill-down: `_index/*.txt` (domain-aware grep) or `{type}/<domain>/` notes.

**Write:**
- Curated: `vault-session-end` / `vault-failure-log` / `vault-pattern-extract` / `vault-orchestration-log` skills (user-confirm), routed by `domain` into `{type}/<domain>/`.
- Raw auto-memory: redirected to `auto/<project>/` via `autoMemoryDirectory` in `settings.json`.
- Durable always-load facts: hand-edit `_core-memory.md` -> flows into `_digest.md`.

See shared-conventions.md - Single-Source Memory Model + End-of-Session Writeback.

---

## Subagent Dispatch

Claude Code supports native subagents via the `Agent` tool. Vault-specific guidance:

| Subagent type | Use for |
|---|---|
| `Explore` | Read-only research across vault files |
| `general-purpose` | File writes, note creation, pattern extraction |
| `Plan` | Architecture design, MOC restructuring proposals |

**Parallel work**: dispatch multiple Agent tool calls in a single message for independent subtasks.

**Principal Branch Lock** (applies to every git repo - see shared-conventions.md for full rules). The branch the user is on at session start is the principal branch; main agent and subagents both must NOT `checkout`/`switch`/`commit` to another branch without explicit instruction.

**Worktree-based subagent isolation**: when a subagent task might produce commits, use `isolation: "worktree"`.

---

## Vault Skills Available

Invoke with the `Skill` tool:

| Skill | Purpose |
|---|---|
| `vault-research` | Read-only traversal: Home -> MOC -> notes, returns cited findings |
| `vault-capture` | Write to `Inbox/` only; Auto Note Mover handles routing |
| `vault-session-start` | Run anti-stranger checklist; populate working context |
| `vault-session-end` | Write session log; bridge short-term -> long-term memory |
| `vault-failure-log` | Structured failure capture with root cause |
| `vault-pattern-extract` | Promote repeated approach to `patterns/<slug>.md` |
| `vault-orchestration-log` | Log multi-agent orchestration run |
| `vault-onboarding-sync` | Detect and patch drift in setup documentation |

When in doubt whether a task needs a skill: prefer skills over raw tool calls for memory and vault-structure tasks. Skills enforce schema compliance automatically.

---

## Session Logging Identifiers

When writing session/failure/pattern logs, use:
```yaml
agent: claude-code
model: <exact-model-id>   # e.g. claude-opus-4-7, claude-sonnet-4-6
```

Consistency is required for pattern queries across logs.

---

## Cost Awareness

- Reuse memory aggressively - if the answer is in `patterns/` or a recent session log, read it; do not re-research from scratch.
- Prefer lighter subagent models (Sonnet) over main agent (Opus) for read-heavy research tasks.
- Use local/team model (if configured via a code-assist MCP or equivalent) for mechanical code generation before escalating to Opus.

---

## Hook Configuration

<!-- Configure per vault: document your hook setup here.
Example:
- SessionStart: `~/.claude/hooks/cc-session-start-memory.sh` - injects digest + sentinel check
- SessionEnd: `~/.claude/hooks/session-end-prompt.sh` - writes sentinel, reminds to run vault-session-end
[CONFIGURE: document your hooks here]
-->

---

## References

- shared-conventions.md - mandatory baseline for all runtimes
- codex-cli.md - peer runtime profile
- gemini-cli.md - peer runtime profile
