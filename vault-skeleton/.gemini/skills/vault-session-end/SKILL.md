---
name: vault-session-end
description: Document a completed work session to AI-Memory so future agents can learn what was done, why, and what's next.
allowed-tools: Read Write Edit Bash
agent: gemini
---

# Vault Session End Skill

Capture a meaningful work session into `Engineering/AI-Memory/sessions/` so future agents can learn from it. This skill needs reasoning to summarize - `disable-model-invocation` is intentionally NOT set.

## When to invoke

- A multi-step task just completed (success, partial, or failure).
- The user says "we are done", "wrap up", "save this session", or asks for a summary.
- A sprint, orchestration, or workitem chain finished.
- The conversation is about to end and substantive work occurred.

## When NOT to invoke

- Pure read-only lookups with no decision or change made.
- Trivial single-message exchanges (e.g., "what time is it").
- Sessions where the user explicitly says "do not save".

## Workflow

### 1. Gather session metadata

Collect (ask user if unclear):

- **Task description** - 1-2 sentence "what we tried to do".
- **Files touched** - run `git status` and `git diff --stat` in the working directory to enumerate.
- **Outcome** - one of `success`, `partial`, `failure`. Ask user if ambiguous.
- **Agent** - `claude-code`, `codex-cli`, `gemini-cli` (from runtime).
- **Model** - exact model id.
- **Session id** - timestamp `YYYYMMDD-HHMMSS` from `date +%Y%m%d-%H%M%S`.
- **Tokens** - best estimate. If unknown, mark `tokens: unknown`.
- **Duration** - wall-clock minutes. If unknown, mark `duration: unknown`.
- **Key findings** - 3-7 bullet list of insights worth remembering.
- **Follow-ups** - open threads, deferred decisions, "next time look at X".

### 2. Reference the template

Use `Templates/AI Session Report.md` as the structural reference. If that template does not exist, compose with the frontmatter block shown below.

### 3. Determine filename

Pattern: `<YYYY-MM-DD>_<agent>_<task-slug>.md`

- `YYYY-MM-DD` from today date.
- `<agent>` matches the frontmatter `agent` field.
- `<task-slug>` is kebab-case, 2-5 words, no stop words.

Target folder: `Engineering/AI-Memory/sessions/<domain>/` - route by the session's `domain` frontmatter (default `engineering`). Create the `<domain>/` subfolder if it does not exist.

### 4. Compose frontmatter

```yaml
---
title: "<task description, capitalized>"
type: session-report
domain: engineering
status: evergreen
tags:
  - domain/engineering
  - activity/session-report
  - status/evergreen
  - lifecycle/area
summary: "<1-line outcome + most important finding>"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: <owner>
scope: internal
agent: <claude-code|codex-cli|gemini-cli>
model: <exact model id>
session_id: <YYYYMMDD-HHMMSS>
outcome: <success|partial|failure>
tokens: <int or "unknown">
duration: <int minutes or "unknown">
files_touched: <int>
---
```

### 5. Compose body

Sections (in order):

1. **Task** - what was attempted, 1-2 sentences.
2. **Context** - links to relevant notes (`[[wikilink]]`), commits, PRs, or upstream sessions.
3. **Approach** - what was tried, in order. Bullet list.
4. **Outcome** - result, with concrete evidence (file paths, commit SHAs, test results).
5. **Files touched** - bulleted list, each with a 1-line "why touched".
6. **Key findings** - 3-7 bullets, each a discrete insight.
7. **Follow-ups** - open items, deferred work, "next time" notes.
8. **Cross-links** - link to any pattern, failure, or orchestration this session relates to.

### 6. Confirm before writing

Show the user the full composed note (frontmatter + body). Ask: "Write to `<full path>`? (y/n)". Do not write until user confirms.

### 7. Write the file

Use `Write` with the absolute path under `Engineering/AI-Memory/sessions/`.

### 7.5. Mark session-stop sentinel as processed

After write succeeds, mark every `status:unprocessed` entry in the session-stop sentinel as processed.

```bash
VAULT="${VAULT_PATH:-$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/git/obsidian-vault")}"
SENTINEL="$VAULT/.local-state/last-session-stop.txt"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if [ -f "$SENTINEL" ]; then
  sed -i "s|status:unprocessed$|status:processed\tprocessed:${NOW}|g" "$SENTINEL"
fi
```

Skip silently if the file does not exist.

### 8. Suggest follow-up skills

After write succeeds:

- If `outcome: failure` -> suggest `vault-failure-log` to capture root cause + prevention.
- If `outcome: success` AND the approach used was novel or reusable -> suggest `vault-pattern-extract`.
- If the session was a multi-wave / multi-agent orchestration -> suggest `vault-orchestration-log`.

## Anti-patterns

- Do not write without showing the composed note first. The user must confirm.
- Do not skip the `tokens` and `duration` fields by inventing numbers - write `unknown` if you do not have a clock or counter.
- Do not write into `Inbox/` - sessions go directly to `AI-Memory/sessions/`.
- Do not exceed 7 key findings - past that, the note becomes a dump rather than a synthesis.
- Do not include sensitive credentials, customer PII, or full email threads.
- Do not invent files_touched - derive from `git status` / `git diff --stat`.
