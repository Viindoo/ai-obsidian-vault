---
name: vault-session-start
description: Load vault context (Home, recent daily notes, recent patterns, agent profile) at the start of non-trivial work to maintain cross-session continuity.
allowed-tools: Read Glob Bash
agent: codex
---

# Vault Session Start Skill

Soft-load context at the start of any non-trivial work session so the agent does not act as a "stranger" to the vault. This skill is pure context-load (no reasoning, no writes). Invoke early, before the first substantive action.

## When to invoke

- The user opens a new conversation and the task touches strategy, product, sales, or engineering decisions.
- The user gives a task that will likely span multiple files or require historical context.
- The user references "what we discussed before", "last week", "yesterday's note", or similar continuity cues.
- The user starts an orchestration, sprint, or any multi-step workflow.

Do NOT invoke for trivial single-file edits or pure code execution where vault context is irrelevant.

## When NOT to invoke

- A pure code-only task with no strategy/decision component.
- A read-only lookup the user clearly framed as a one-shot question (use `vault-research` instead).
- A capture-only task where the user already supplied all content (use `vault-capture` instead).

## Workflow

Execute the reads in this order. Each step is mandatory unless the file does not exist.

### 0. Check session-stop sentinel (carryover detection)

Before loading any vault context, check whether a prior session ended without a vault-session-end capture.

Read `<vault>/.local-state/last-session-stop.txt` (if it exists). Each line is a tab-separated stop event. Find lines ending in `status:unprocessed`.

```bash
VAULT="${VAULT_PATH:-$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/git/obsidian-vault")}"
grep "status:unprocessed" "$VAULT/.local-state/last-session-stop.txt" 2>/dev/null | tail -5
```

Then find the timestamp of the most recent session-report in AI-Memory:

```bash
ls -tc "$VAULT/Engineering/AI-Memory/sessions"/**/*.md 2>/dev/null | head -1
```

**Decision logic:**
- If unprocessed sentinel entries exist AND their timestamps are newer than the most recent session-report -> inform the user:
  `"Prior session(s) stopped without vault-session-end capture. Suggest running vault-session-end for: <timestamp(s)>. Proceed anyway? (y/n)"`
- If user confirms to skip, proceed. If user wants to capture, pause and invoke `vault-session-end` first.
- If no unprocessed entries, or all entries predate the latest session-report -> proceed silently.

### 1. Read entry MOC

Read `Meta/Home.md`. This is the master MOC. Note the current domain MOCs available and the date of last update.

### 2. Skim navigation rules

Read `.claude/rules/vault-navigation.md` (if present). Skim to keep folder layout, naming conventions, and DO-NOT list fresh.

### 3. Read latest 3 daily notes

Find the most recent daily notes in `Daily/`. Use:

```bash
ls -t Daily/**/*.md 2>/dev/null | head -3
```

Read each one. These contain the freshest context - meeting outcomes, decisions made today/this week, open threads.

### 4. Read the AI-Memory digest (efficient single read)

Read `Engineering/AI-Memory/_digest.md` first - it is the generated always-load file (core facts + headline recent patterns/failures/sessions). One read replaces most of the per-folder scanning below.

### 5. Read top recent patterns + failures (drill-down if digest insufficient)

If the digest is stale/absent, or the task needs more than the headlines, pull recent items from the indexes:

```bash
# Recent patterns (domain | date | evidence | path) - sort by date desc
sort -t'|' -k2 -r Engineering/AI-Memory/_index/patterns-by-domain.txt 2>/dev/null | grep -v '^#' | head -5
# Recent failures (pattern | domain | severity | date | agent | path) - sort by date desc
sort -t'|' -k4 -r Engineering/AI-Memory/_index/failures-by-pattern.txt 2>/dev/null | grep -v '^#' | head -3
```

Fallback if `_index` absent (recurse subfolders): `ls -tc Engineering/AI-Memory/patterns/**/*.md`. If a folder does not exist yet (early bootstrap), skip - do not error.

### 6. Read self agent profile

Read `Engineering/AI-Memory/agent-profiles/claude-code.md` (or the profile matching your runtime). This contains agent-specific quirks, preferred tools, and guardrails.

If the file does not exist, skip without error.

### 7. Read shared conventions

Read `Engineering/AI-Memory/agent-profiles/shared-conventions.md`. This is the cross-agent contract.

## Output

After all reads complete, emit a single 3-line summary to confirm context is loaded. Format:

```
Loaded: Home.md, <N> daily notes, <P> patterns, <F> failures, <self>.md, shared-conventions.md.
Latest daily: <YYYY-MM-DD>. Latest pattern: <slug>.
Ready.
```

If any file was skipped (folder absent), say so explicitly in the summary.

## Cross-skill references

- After a session, run `vault-session-end` to capture what was done.
- For ad-hoc topic lookup mid-session, prefer `vault-research` (cheaper than re-loading session-start).
- If a failure occurs during the session, immediately invoke `vault-failure-log`.

## Anti-patterns

- Do not skip the Home.md read even if you "remember" it from a prior session - sessions are isolated.
- Do not synthesize or summarize the loaded notes in the output - just confirm the load.
- Do not read more than 3 daily notes, 5 patterns, 3 failures - past that, token cost outweighs value.
- Do not write any file during this skill. It is strictly read-only.
- Do not error out if AI-Memory folders are absent (early bootstrap state) - skip silently with a note in the summary.
- Do not skip Step 0 even if the sentinel file is absent - the absence itself is a valid (no carryover) state.
