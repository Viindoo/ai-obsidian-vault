---
title: Gemini CLI agent profile
type: profile
domain: engineering
status: active
tags: [status/active, domain/engineering, activity/profile, lifecycle/area]
summary: Google Gemini CLI conventions for vault work.
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
scope: internal
related: ["[[shared-conventions]]", "[[claude-code]]", "[[codex-cli]]"]
---

# Gemini CLI Agent Profile

This profile documents Gemini CLI-specific conventions for vault work. All rules in shared-conventions.md apply and are not repeated here. Read shared-conventions.md before this file.

---

## Runtime Info

| Field | Value |
|---|---|
| Package | `@google/gemini-cli` (current version) |
| Binary | `/usr/local/bin/gemini` |
| Auth method | OAuth personal (configure per user) |
| OAuth credentials | `~/.gemini/oauth_creds.json` |
| Global config | `~/.gemini/settings.json` |
| Global instructions | `~/.gemini/GEMINI.md` |
| Per-session sandbox | `~/.gemini/sessions/` |

<!-- Note: configure your own OAuth email in ~/.gemini/settings.json. Do not store email addresses in this file. -->

---

## Model Configuration

| Scenario | Model |
|---|---|
| Default (most tasks) | `gemini-2.0-flash-exp` (or current Gemini default at session time) |
| Deep reasoning, complex analysis | `gemini-2.5-pro` (invoke explicitly) |

Check `~/.gemini/settings.json` at session start if uncertain about the current default.

---

## Vault Project Registration

Register the vault in `~/.gemini/projects.json` to give Gemini context about the vault's root path and trust level. Without this registration, filesystem tool calls to vault paths may require manual confirmation.

---

## MCP Servers

<!-- Configure per team: list your active MCP servers here.
Example:
| Server | Transport | Purpose |
|---|---|---|
| `filesystem` | npx (lazy start) | Anthropic official filesystem MCP - scoped to vault root |
[CONFIGURE: add your MCP servers here]
-->

The `filesystem` MCP is the primary vault access tool. Cross-runtime memory synchronization is via the vault's `AI-Memory/` folder (committed to git), not a memory MCP server.

---

## Skill Suite

Gemini CLI has a skill and extension system. Vault-specific skills are in `<vault>/.gemini/skills/`. These are adapted versions of the Claude Code skills, simplified for the Gemini runtime.

Like Codex, Gemini does not have Claude's `Skill` tool - vault memory operations are performed via direct file writes using Gemini's native filesystem tools or via `ai-memory-write.sh`.

---

## Vault Writes Without Skill Tool

Since Gemini lacks Claude's `Skill` tool, write vault memory notes directly or via `ai-memory-write.sh`. Example for a failure log:

```bash
bash "<vault>/_scripts/ai-memory-write.sh" \
  --agent gemini-cli \
  --type failure \
  --domain engineering \
  --slug <pattern-slug> \
  --title "<failure title>" \
  --summary "<what failed + root cause>" \
  --severity med
```

Or directly:

```bash
cat > Engineering/AI-Memory/failures/engineering/$(date +%Y-%m-%d-%H%M)_gemini-cli_<slug>.md << 'EOF'
---
title: <failure title>
type: failure-log
domain: <domain>
status: active
tags: [status/active, domain/<domain>, activity/failure, lifecycle/area]
summary: <one-line description>
created: <date>
updated: <date>
owner: <owner>
agent: gemini-cli
model: gemini-2.0-flash-exp
session_id: <timestamp>
scope: internal
---

## Symptom
<what was observed>

## Root Cause
<why it actually happened>

## Lesson
<what future agents should do differently>

## Impact
<files affected, decisions contaminated, rollback required>
EOF
```

Always include `agent: gemini-cli` and the current `model:` value. Root cause is mandatory.

---

## Hook Configuration

Gemini CLI supports 7 hook events. Wire session sentinel:

```json
{
  "hooks": {
    "SessionEnd": "<vault>/_scripts/session-end-sentinel.sh gemini-cli"
  }
}
```

**DO NOT use `save_memory`** (it writes hard into `~/.gemini/GEMINI.md`, not the vault).

---

## Gemini's Strengths in the Vault

- **Long-document summarization**: effective at condensing large docs into `summary` fields
- **Research synthesis**: strong at cross-referencing multiple notes
- **Multilingual content**: handles mixed-language content well

Use Gemini as a **specialist worker** (research, summarization, content drafting) when Claude Code is orchestrating a multi-agent task.

---

## Limitations vs Claude Code

| Capability | Claude Code | Gemini CLI |
|---|---|---|
| Subagent isolation | `isolation: "worktree"` native | Not available - manual `git worktree add` |
| Skill invocation | `Skill` tool | Not available - write files directly |
| Multi-step orchestration | Native `Agent` tool | Single agent; use as worker |

For multi-step orchestration with isolation requirements, use Claude Code as conductor. Gemini is optimal as a specialist worker receiving focused tasks with clear inputs and outputs.

---

## Session Logging Identifiers

When writing session/failure/pattern logs, use:
```yaml
agent: gemini-cli
model: gemini-2.0-flash-exp   # or gemini-2.5-pro if explicitly invoked
```

---

## References

- shared-conventions.md - mandatory baseline for all runtimes
- claude-code.md - preferred conductor runtime for complex orchestration
- codex-cli.md - peer runtime profile
