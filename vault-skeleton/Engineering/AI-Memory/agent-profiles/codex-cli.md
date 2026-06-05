---
title: Codex CLI agent profile
type: profile
domain: engineering
status: active
tags: [status/active, domain/engineering, activity/profile, lifecycle/area]
summary: OpenAI Codex CLI conventions for vault work.
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
scope: internal
related: ["[[shared-conventions]]", "[[claude-code]]", "[[gemini-cli]]"]
---

# Codex CLI Agent Profile

This profile documents Codex CLI-specific conventions for vault work. All rules in shared-conventions.md apply and are not repeated here. Read shared-conventions.md before this file.

---

## Runtime Info

| Field | Value |
|---|---|
| Package | `@openai/codex` (current version) |
| Binary | `/usr/local/bin/codex` |
| Primary model | `<current-openai-model>` |
| Global config | `~/.codex/config.toml` |
| Global instructions | `~/.codex/AGENTS.md` |
| Per-session sandbox | `~/.codex/sessions/` |

---

## Vault Trust Configuration

Register the vault directory as a trusted project in `~/.codex/config.toml`:

```toml
[projects."<absolute-vault-path>"]
trust_level = "trusted"
```

Without `trust_level = "trusted"`, Codex will request confirmation on every filesystem write.

---

## MCP Servers

<!-- Configure per team: list your active MCP servers here.
Example:
| Server | Transport | Purpose |
|---|---|---|
| `filesystem` | npx (lazy start) | Anthropic official filesystem MCP - scoped to vault root |
| `github` | curated plugin | GitHub issue/PR access |
[CONFIGURE: add your MCP servers here]
-->

The `filesystem` MCP is the primary vault access tool. Cross-runtime memory synchronization is via the vault's `AI-Memory/` folder (committed to git), not a memory MCP server.

---

## Skill Suite

Codex CLI has a skill system. Vault-specific skills are in `<vault>/.codex/skills/`. These are adapted versions of the Claude Code skills, simplified for the Codex runtime (no `disable-model-invocation` flag, shorter descriptions).

**Key difference from Claude Code**: Codex does not have the `Skill` tool. For vault memory operations (session logging, failure capture, pattern files), write the markdown file directly using Codex's native filesystem tool or a Bash heredoc, OR invoke `_scripts/ai-memory-write.sh` with the appropriate args.

---

## Vault Writes Without Skill Tool

Since Codex lacks Claude's `Skill` tool, vault memory operations are done via direct file write or via `ai-memory-write.sh`. Example pattern for a session log:

```bash
bash "<vault>/_scripts/ai-memory-write.sh" \
  --agent codex-cli \
  --type session \
  --domain engineering \
  --slug <task-slug> \
  --title "<session title>" \
  --summary "<one-line outcome>" \
  --outcome success
```

Or directly:

```bash
cat > Engineering/AI-Memory/sessions/engineering/$(date +%Y-%m-%d)_codex-cli_<slug>.md << 'EOF'
---
title: <session title>
type: session-report
domain: engineering
status: active
tags: [status/active, domain/engineering, activity/session-report, lifecycle/area]
summary: <one-line summary>
created: <date>
updated: <date>
owner: <owner>
agent: codex-cli
model: <current-model>
session_id: <timestamp>
outcome: <success|partial|failure>
tokens: <approx>
duration: <minutes>
scope: internal
---

# Session Log

<body>
EOF
```

Always include `agent: codex-cli` in the frontmatter.

---

## Limitations vs Claude Code

| Capability | Claude Code | Codex CLI |
|---|---|---|
| Subagent isolation | `isolation: "worktree"` native | Not available - manual `git worktree add` |
| Skill invocation | `Skill` tool | Not available - write files directly or call ai-memory-write.sh |
| Worktree management | Auto-managed | Manual git worktree commands |
| Multi-model routing | Multiple models per task | Single model per session |

For vault work requiring multi-step orchestration with subagent isolation, prefer Claude Code as the conductor. Codex is best suited for focused single-agent tasks: content creation, research queries, targeted file updates.

---

## Session Logging Identifiers

When writing session/failure/pattern logs, use:
```yaml
agent: codex-cli
model: <current-active-model>
```

Use the current active model version at session time.

---

## References

- shared-conventions.md - mandatory baseline for all runtimes
- claude-code.md - preferred conductor runtime for complex orchestration
- gemini-cli.md - peer runtime profile
