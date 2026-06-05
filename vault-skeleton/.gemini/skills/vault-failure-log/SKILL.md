---
name: vault-failure-log
description: Capture a non-trivial failure as a failure-log note (root cause + lesson + prevention recipe) so the same trap is not repeated.
allowed-tools: Read Write Edit Bash
agent: gemini
---

# Vault Failure Log Skill

Capture a failure into `Engineering/AI-Memory/failures/` while it is fresh. The point is not the stack trace - it is the **lesson learned** and **prevention recipe** that stops the same class of failure from recurring.

## When to invoke

- A tool call, command, build, test, or deploy fails non-trivially.
- The agent enters a loop, repeats a bad pattern, or hits a hard wall.
- A user-flagged failure: "you got that wrong", "that broke", "wrong tool".
- A permission, MCP, or environment error blocks progress.
- A model over-cautiousness or hallucination derails the task.

Capture even if the failure was eventually resolved - the resolution path is the value.

## When NOT to invoke

- A trivial typo or one-line syntax error self-corrected within the same turn.
- A user-side mistake the agent did not contribute to (no lesson for the agent).
- A test failure that is part of normal TDD red-green-refactor (not a "surprise" failure).

## Workflow

### 1. Gather failure metadata

Collect quickly while the failure is fresh:

- **Context** - what was being attempted, 1-2 sentences.
- **What failed** - specific error, symptom, or undesired behavior. Quote the error message verbatim if available.
- **Root cause** - why it failed. If unknown, mark "Unknown - to investigate".
- **Resolution** - one of `resolved`, `workaround`, `open`.
- **Lesson learned** - the take-away. What does a future agent need to know?
- **Prevention** - concrete steps to avoid recurrence (a checklist, a tool preference, a guardrail).
- **Pattern keyword** - short slug for cross-session search. Examples: `mcp-config`, `permission-denied`, `tool-loop`, `model-overcaution`, `frontmatter-drift`, `git-worktree-confusion`, `path-relative-vs-absolute`.
- **Severity** - `low` (annoyance), `med` (cost time), `high` (broke production / lost data / blocked work).

### 2. Determine filename

Pattern: `<YYYY-MM-DD-HHMMSS>_<agent>_<pattern-slug>.md`

- Timestamp must include seconds so multiple failures per day do not collide.
- `<agent>` is `claude-code`, `codex-cli`, or `gemini-cli`.
- `<pattern-slug>` is the pattern keyword from step 1.

Target folder: `Engineering/AI-Memory/failures/<domain>/` - route by the failure's `domain` frontmatter (default `engineering`). Create the `<domain>/` subfolder if absent.

### 3. Compose frontmatter

```yaml
---
title: "<one-line failure summary>"
type: failure-log
domain: engineering
status: evergreen
tags:
  - domain/engineering
  - activity/failure
  - status/evergreen
  - lifecycle/area
summary: "<1-line: what failed + root cause>"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: <owner>
scope: internal
agent: <claude-code|codex-cli|gemini-cli>
pattern: <kebab-case keyword>
severity: <low|med|high>
resolution: <resolved|workaround|open>
session: <link to session-report note if any>
---
```

The `pattern` field is the JOIN key - future agents grep by pattern to find related failures.

### 4. Compose body

Sections (in order, all required):

1. **Context** - what was being attempted and why.
2. **What failed** - exact symptom or error message (quote verbatim). Include the failing command/tool call.
3. **Root cause** - the actual underlying reason. If unknown, say so.
4. **Resolution** - how it was resolved (or "open" if still blocked). Include the fix command/code if applicable.
5. **Lesson learned** - the durable insight. **This is the highest-value section.** Write it for a future agent who has never seen this failure.
6. **How to prevent recurrence** - a concrete checklist or rule.
7. **Related** - links to other failures with the same `pattern` keyword, or to patterns that should have prevented this.

### 5. Confirm before writing

Show the user the composed note. Ask: "Write failure log to `<path>`? (y/n)". Do not write until confirmed.

### 6. Write the file

Use `Write` to the absolute path under `Engineering/AI-Memory/failures/`.

### 7. Suggest follow-ups

- If `severity: high`, suggest mentioning in today `Daily/` note.
- If the same `pattern` has 3+ failures already, suggest promoting prevention into a `vault-pattern-extract`.
- If the failure occurred inside a multi-agent pipeline, link to the relevant `vault-orchestration-log`.

## Anti-patterns

- Do not log a failure without a "Lesson learned" + "Prevention" section - those are the value.
- Do not speculate about root cause as if certain. Mark unknowns honestly.
- Do not use generic pattern slugs like `error` or `bug` - be specific. Generic slugs defeat cross-session search.
- Do not write the failure log into `Inbox/` - failures route directly to `AI-Memory/failures/`.
- Do not skip the timestamp on the filename - same-day collisions will overwrite.
- Do not blame the user. If the root cause is a user-side mistake, capture only the agent-side lesson.
