---
title: AI agent shared conventions (Claude/Codex/Gemini)
type: profile
domain: engineering
status: active
tags: [status/active, domain/engineering, activity/profile, lifecycle/area]
summary: Conventions every AI runtime must follow when reading/writing this vault. Applies to Claude Code, Codex CLI, Gemini CLI.
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
scope: internal
related: ["[[claude-code]]", "[[codex-cli]]", "[[gemini-cli]]"]
---

# AI Agent Shared Conventions

This document defines mandatory conventions for every AI runtime operating inside this vault. All profiles - claude-code, codex-cli, gemini-cli - inherit these rules. Per-runtime overrides appear only in the individual profiles. When this file and a per-runtime profile conflict, the per-runtime profile wins only for that runtime.

---

## Entry Rule

**ALWAYS read `Meta/Home.md` first.** Do not random-search the vault. The vault is a PARA-LYT hybrid with a MOC hierarchy: Home -> domain MOCs -> individual notes. Random keyword search produces stale or out-of-scope results. The MOC hierarchy is the intended traversal path.

Procedure:
1. Read `Meta/Home.md` to locate the relevant domain MOC.
2. Open the domain MOC (e.g., `Meta/MOC-Engineering.md`).
3. Follow wikilinks from the MOC to specific notes.
4. Use the `summary` frontmatter field to decide if a note is worth reading in full before opening the body.

Never skip step 1 even if you believe you already know where the target file is. The vault changes; Home reflects current structure.

---

## Company Brand Assets

<!-- Configure per team: add a pointer to your company's brand assets file here.
Example: "When task involves design/frontend/UI/marketing for [COMPANY] -> read SSOT first: [[Brand Assets]] (`Resources/Brand/Brand Assets.md`)."
-->
[CONFIGURE: add pointer to your company brand assets here]

---

## Single-Source Memory Model

`Engineering/AI-Memory/` is the **single source of memory for all 3 runtimes** (Claude Code / Codex / Gemini). No runtime keeps a private memory store. Full layout + mechanics: `AI-Memory/README.md`.

- **Read** = `@import _digest.md` (all 3 control files) + SessionStart hook (Claude Code only; Codex/Gemini do not support hooks -> `@import` only).
- **Write** = skills below (user-confirm), routed by `domain` into `{type}/<domain>/`. Claude auto-memory redirects raw into `auto/<project>/`.
- **Curated long-term** lives in `{sessions,failures,patterns,orchestrations}/<domain>/`; **raw machine-written** in `auto/<project>/`; **always-load** in `_core-memory.md` -> `_digest.md`.

## Write Boundaries

Agents may write **only** to these paths:

| Allowed write paths | Notes |
|---|---|
| `Inbox/` | Quick captures; Auto Note Mover re-files by tag |
| `Engineering/AI-Memory/sessions/<domain>/` | Session logs (route by domain) |
| `Engineering/AI-Memory/failures/<domain>/` | Failure logs (route by domain) |
| `Engineering/AI-Memory/patterns/<domain>/` | Extracted patterns (route by domain) |
| `Engineering/AI-Memory/orchestrations/<domain>/` | Multi-agent orchestration logs (route by domain) |
| `Engineering/AI-Memory/auto/<project>/` | Raw auto-memory (Claude redirect target) |
| `Engineering/AI-Memory/_core-memory.md` | Curated always-load facts (hand-edited) |
| `Daily/` | Daily/weekly/monthly notes |

> `_digest.md` and `_index/*.txt` are GENERATED (`_scripts/gen-memory-digest.sh`, `_scripts/regen-ai-memory-index.sh`) - never hand-edit.

Agents **must NOT** write to:

- `Strategy/Briefs/` - human-authored strategic briefs
- `Strategy/Decisions/` - formal decision records
- `Archive/` - frozen historical content; never modify
- `Templates/` - Templater templates; editing breaks automation
- `Meta/` - schema, taxonomy, Home MOC; only update with explicit owner instruction
- Vault root (`.md` at root level) - all new notes go inside named folders

---

## Frontmatter Contract (Schema v3)

Schema v3 is mandatory. Canonical reference: `Meta/_system/_schema.md`.

Required fields for every note:
```
title, type, domain, status, tags, summary, created, updated, owner
```

Additional required fields for AI-authored memory notes:
```
agent: <runtime-slug>   # claude-code | codex-cli | gemini-cli
model: <model-version>  # e.g. claude-opus-4-7, gpt-5.5, gemini-2.5-pro
session_id: <id>        # ISO timestamp or UUID
```

Use templates from `Templates/AI *.md` where they exist. Do not invent new `type` values - use `type: session-report` for sessions, `type: failure-log` for failures, `type: pattern` for reusable patterns, `type: orchestration` for multi-step pipelines, `type: profile` for agent profile notes.

Tag namespaces (4 only):
- `domain/`: engineering, strategy, product, sales, marketing, operations, people, finance, knowledge
- `activity/`: brief, campaign, competitor, deal, debug, decision, digest, failure, meeting, okr, orchestration, pattern, process, profile, reference, research, session-report
- `status/`: active, draft, archived, evergreen, deprecated
- `lifecycle/`: project, area, resource, archive

---

## Anti-Stranger Checklist

Run this checklist at the start of every non-trivial session (anything that will produce writes or influence real decisions):

1. **Read `Meta/Home.md`** - orient to current vault state.
2. **Read your own profile** - `Engineering/AI-Memory/agent-profiles/<self>.md`.
3. **Read 5 most recent files in `patterns/`** - filter `type=pattern, status in {active, evergreen}`. Internalize what the vault considers proven approaches.
4. **Read 5 most recent `failures/`** matching the task domain - avoid repeating known traps.
5. **Read the 3 most recent `Daily/` notes** - understand current focus and context.

This checklist costs ~10 minutes but prevents the most common agent failure modes: contradicting established patterns, repeating logged failures, operating on stale context.

---

## PII Handling

The vault is committed to a **private** git repository, but private != safe. A pre-commit hook at `_local/hooks/pre-commit` blocks sensitive patterns automatically.

Agent obligations:
- Never write raw customer names into vault notes. Use aliases: `<customer-A>`, `<prospect-2026-Q2>`.
- Never write salary numbers, equity splits, or compensation ranges inline.
- Never write internal conflict details as plain text. Summarize as `<sensitivity: high - see private record>`.
- Use `<deal-of-2026-Q3>` style placeholders for deals in progress not yet publicly disclosed.
- If the hook fires and blocks a commit, fix the offending content before retrying - do NOT bypass the hook.

---

## End-of-Session Writeback

For sessions producing real strategic, engineering, or knowledge value, write a session log to `Engineering/AI-Memory/sessions/`. This is mandatory for:

- Sessions that change more than 5 vault files
- Sessions that produce a decision record or strategy brief
- Sessions that uncover a new pattern or failure mode
- Any session with `duration > 30 minutes` or `tokens > 50k`

Minimum session log frontmatter:
```yaml
agent: <self>
model: <model-version>
session_id: <timestamp-or-uuid>
outcome: <one-line summary>
tokens: <approximate>
duration: <minutes>
```

Claude Code agents: invoke the `vault-session-end` skill. Codex CLI and Gemini CLI agents: write the file directly using native filesystem tools.

---

## Failure Logging

Any non-trivial failure (wrong output, contradicted decision, schema violation, broken cross-link, incomplete task) must be logged immediately in `Engineering/AI-Memory/failures/`.

Filename convention: `<ISO-datetime>_<slug>.md` (e.g., `2026-05-16-1855_tool-loop.md`).

Failure logs must include:
- **Symptom**: what went wrong observably
- **Root cause**: why it actually happened (not just the immediate trigger)
- **Lesson**: what future agents should do differently
- **Impact**: files affected, decisions contaminated, rollback required

Do not write failure logs that only describe the symptom - root cause is mandatory.

---

## Pattern Extraction

If the same approach solved the same category of problem in 3 or more sessions, promote it to a pattern note in `Engineering/AI-Memory/patterns/<slug>.md`. Pattern notes use `type: pattern` and `status: active`.

Pattern promotion is a write to `patterns/` - allowed for all runtimes. Pattern notes must cross-link to the session logs that evidence the pattern.

---

## Repo Capability Discovery (Phase 0) - always-first

At the start of every session touching git code (before minting a worktree), probe **base branch / verify commands / commit format / lang hard-rules / confidentiality class** FROM the repo at runtime - probe `CLAUDE.md`/`Makefile`/`package.json`/`pyproject.toml`/CI. Do NOT hardcode commands per-repo.

**Output = "Repo Capability Card"** - embed in every Phase 4 subagent brief replacing hardcoded placeholders.

---

## Worktree-Based Edit Isolation - always-on

**Worktree isolation is mandatory whenever the agent modifies any file** (code, config, doc) in a git repo. Since the agent cannot commit to the user's principal branch, every file edit must dispatch to a new branch - mint a **worktree** (isolated working dir), not just a branch in the main repo.

**True skip conditions (no worktree needed):**

- Pure read-only task (research, audit, investigation - no file edits)
- Vault `Inbox/` write via `vault-capture` skill - Auto Note Mover routes, vault auto-commit timer handles git
- Vault `Daily/` append - vault auto-commit timer handles
- AI-Memory writes (sessions/failures/patterns/orchestrations) - vault auto-commit timer handles

For every other file modification -> at minimum mint a worktree and work there. Do NOT edit files directly on the user's principal branch.

---

## Git Discipline - Principal Branch Lock

> **SSOT CANONICAL** for Git Discipline.

The **principal branch** is whatever branch the user is on when the session starts (read it via `git rev-parse --abbrev-ref HEAD`). Treat it as the user's working context: they may have uncommitted changes, may be mid-feature, may have dirty working tree. **Both main agent and subagents are bound by this rule.**

**Mandatory rules:**

- **DO NOT `git checkout` / `git switch` to any other branch** unless the user explicitly instructs. Applies in both directions.
- **What counts as explicit branch instruction:** the user names a branch verbatim. A **task instruction** ("fix issue 144") is **not** a branch instruction - even when it logically implies new branch work. The correct response to a task instruction is to mint a worktree, not to `git checkout -b` on the principal branch.
- **DO NOT auto-rebase / auto-merge / auto-pull / `reset --hard`** on the principal branch.
- **DO NOT commit to the principal branch** unless: (a) user explicitly instructs commit, OR (b) you created the branch yourself in this session.
- **Need a different branch state?** -> use `git worktree add <path> <branch>` to mint an isolated worktree.
- **Subagents inherit this rule.** Include in prompt: `DO NOT git checkout/switch/commit unless explicitly instructed; use worktree if you need a different branch state.`
- **Discovery before any git op:** before the first git mutation, run `git status --short` and `git rev-parse --abbrev-ref HEAD`.

**Hard rule recap (copy-paste into subagent prompts):**

```
- DO NOT `git checkout` / `git switch` to another branch (in any direction)
- A task instruction ("fix issue X") is NOT a branch instruction. Only a named branch ("checkout fix/X") is.
- DO NOT `git checkout -b new-branch` on the principal repo - use `git worktree add` instead
- DO NOT `git commit` to the current branch
- DO NOT `git rebase` / `git merge` / `git pull` / `git reset --hard`
- For different branch state: `git worktree add` to a session-scoped path
- For read-only inspection: `git log`, `git diff`, `git show` are OK
```

---

## Conflict Avoidance (Multi-CLI Concurrency)

When multiple AI runtimes are active on the vault simultaneously:

- **Prefer `Inbox/` writes** - Auto Note Mover routes captures without MOC conflicts.
- **Do not simultaneously edit MOC files** (`_MOC.md`, `Home.md`) - last-write-wins in obsidian-git.
- **obsidian-git auto-commits every 15 minutes** - stay within 15-minute windows for your own writes.
- **Wave-dir naming convention** (multi-session no-conflict): `/tmp/<repo>-wt-<epoch>-<RANDOM>/` + branch `feat/m<N>-w<X>-<topic>`; collision detect at push (`--force-with-lease`).

---

## Pre-flight Checklist - before parallel write subagent

Mandatory check before dispatching >= 2 parallel subagents with write:

- [ ] **RAM**: `free -g` >= 8GB / Opus subagent (max 3 concurrent Opus)
- [ ] **Model tier**: write task >= Sonnet (NOT Haiku - over-caution risk). Read-only OK with Haiku.
- [ ] **File ownership**: `{agent: [files]}` map disjoint. No 2 agents touching the same file.
- [ ] **Worktree topology**: independent / linear-stack / mixed / diamond - explicit choice.
- [ ] **Hard-rules embed**: subagent prompt has block "May use appropriate skill IF skill does not spawn sub-agent; MUST NOT spawn sub-agent". (NOT a blanket skill ban - only ban skills that spawn agents.)
- [ ] **Nesting check**: ceiling = 2 spawn tiers (main->subagent->subagent). Subagent calling non-spawning skill does NOT count as a tier. Banned: subagent calls skill that spawns agent (-> tier 3). When unsure if skill spawns -> treat as if it does.

---

## Model Tier Policy

| Task type | Min model | Max model | Notes |
|---|---|---|---|
| Read-only lookup, simple grep, classification | Haiku | Sonnet | Cheap fan-out OK |
| Write code, edit doc, single-file refactor | **Sonnet** | Opus | **Floor for write task** (Haiku over-caution will fail) |
| Cross-file refactor, multi-file design | Opus | Opus | Max 3 concurrent (RAM 8GB/proc) |
| Orchestration parent (multi-wave coordinator) | Opus | Opus | Single parent, no parallel parent |

---

## Plugin Routing Decisions

<!-- Configure per team: document your active plugins and routing decisions here.
This section should list which plugins are enabled, disabled, and why.
Update after infrastructure changes.

Example format:
**KEEP (N plugins)**:
- `skill-creator` - meta-skill, high value
- `code-review` - slash /review + /security-review, standard workflow
- `chrome-devtools-mcp` - deep browser debugging

**DISABLE (N plugins)** - rollback via settings.json when needed:
- `plugin-name` - reason for disabling

[CONFIGURE: document your plugin routing decisions here]
-->

---

## References

- Per-runtime profiles: claude-code.md, codex-cli.md, gemini-cli.md
- Schema reference: `Meta/_system/_schema.md`
- Tag taxonomy: `Meta/_system/_tag-taxonomy.md`
