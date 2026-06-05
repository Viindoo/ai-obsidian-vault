---
name: vault-pattern-extract
description: Promote a successful, repeatable approach into a reusable pattern note so future sessions don't re-derive the same thing.
allowed-tools: Read Write Edit Glob Grep Bash
agent: gemini
---

# Vault Pattern Extract Skill

Promote a 1-off success into a reusable pattern note in `Engineering/AI-Memory/patterns/`. Patterns are evergreen - they encode "this approach works for class-of-problem X" so future agents do not re-derive.

## When to invoke

- A session just ended successfully AND the approach used seems reusable for similar future tasks.
- The user explicitly says "this approach works, save it as a pattern".
- The agent recognizes that 2+ past sessions have followed the same recipe.
- `vault-session-end` suggested promoting the session approach into a pattern.

## When NOT to invoke

- The approach is too specific to one problem (no reuse value).
- The "pattern" is just standard knowledge the agent should already have.
- The approach is unproven - only 1 session and the success was partly luck.
- The approach is an anti-pattern. Anti-patterns go in failure logs with prevention, not in patterns/.

## Workflow

### 1. Identify reusability

Ask: "Will a future agent benefit from this in 3+ similar future situations?" If unclear, decline and suggest re-running after the next confirming session.

### 2. Gather pattern inputs

Collect:

- **Pattern name** - kebab-case slug, 2-4 words. Examples: `worktree-parallel-fanout`, `frontmatter-validation-loop`, `inbox-then-route`, `moc-traverse-before-grep`.
- **When to use** - 1-line trigger statement. "Use when X AND Y." Sharp triggers keep patterns from misfiring.
- **Steps** - numbered, concrete, copy-pastable. Each step states what to do and what tool to use.
- **Pitfalls** - common ways the pattern goes wrong, with the symptom and fix.
- **Evidence** - wikilinks to the session-reports where this pattern was used successfully. Minimum 1, prefer 2+.
- **Anti-patterns** - what NOT to do that looks similar but fails.
- **Variations** - known variants for adjacent situations.

### 3. Determine filename

Pattern: `<slug>.md` in `Engineering/AI-Memory/patterns/<domain>/` - route by the pattern's `domain` frontmatter (default `engineering`). No date prefix - patterns are evergreen.

### 4. Compose frontmatter

```yaml
---
title: "<Pattern Name in Title Case>"
type: pattern
domain: engineering
status: evergreen
tags:
  - domain/engineering
  - activity/pattern
  - status/evergreen
  - lifecycle/area
summary: "<1-line: when to use + outcome>"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: <owner>
scope: internal
confidence: <low|med|high>
evidence_count: <int - number of sessions this has worked in>
related:
  - "[[<related pattern>]]"
  - "[[<related failure>]]"
---
```

`confidence` rubric:
- `low` - 1 session, may be lucky.
- `med` - 2-3 sessions, reproducible in similar conditions.
- `high` - 4+ sessions across different agents/contexts, well-validated.

### 5. Compose body

Sections (in order):

1. **When to use** - the trigger. State it as a conditional: "Use this pattern when X and Y, especially if Z."
2. **Why it works** - 1-2 sentences on the underlying principle.
3. **Steps** - numbered list of concrete actions. Reference tools/commands by name.
4. **Pitfalls** - bulleted list of common mistakes, each with the symptom and the fix.
5. **Evidence** - wikilinks to session-reports where this pattern succeeded. Format: `- [[YYYY-MM-DD_agent_slug]] - <1-line outcome>`.
6. **Anti-patterns** - approaches that look similar but fail. Cross-link to relevant failure logs.
7. **Variations** - known forks/specializations of the pattern.
8. **Last validated** - date + agent that most recently confirmed the pattern still works.

### 6. Confirm before writing

Show the composed note. Ask: "Write pattern to `<path>`? (y/n)".

### 7. Write the file

Use `Write` to the absolute path under `Engineering/AI-Memory/patterns/`.

### 8. Cross-link from evidence sessions

For each session in the Evidence section, suggest adding a back-link in the session-report Cross-links section pointing to this new pattern.

## Updating an existing pattern

If a pattern file already exists at the target slug:

1. Read it.
2. Increment `evidence_count`.
3. Append the new session link to the Evidence section.
4. Bump `updated:`.
5. If confidence threshold is crossed, update `confidence:`.
6. Update "Last validated" line.

Do not overwrite the file. Pattern history is value.

## Anti-patterns

- Do not create a pattern from a single session unless it is exceptionally clear-cut.
- Do not use generic slugs like `best-practice` or `tip`. Be specific.
- Do not include code that is project-specific (hard-coded paths, customer names).
- Do not promote anti-patterns into patterns/. Anti-patterns live in failure logs.
- Do not skip the Evidence section. Patterns without evidence are speculation, not patterns.
- Do not delete patterns when they become stale - set `status: deprecated` with a note pointing to the replacement.
