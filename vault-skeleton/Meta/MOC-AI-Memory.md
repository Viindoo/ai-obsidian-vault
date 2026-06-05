---
title: MOC - AI Memory
type: moc
domain: engineering
status: active
tags: [status/active, domain/engineering, lifecycle/area]
summary: Navigation index for AI agent memory layer - sessions, failures, success patterns, orchestrations, and agent profiles.
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
parent: "[[Home]]"
related: ["[[MOC-Engineering]]"]
---

# MOC - AI Memory

## Overview

This MOC indexes the AI agent memory layer. Three AI runtimes (Claude Code, Codex CLI, Gemini CLI) all read/write here. Vault is canonical; per-runtime working memory is short-term.

All notes in this layer live under `Engineering/AI-Memory/` and use schema v3 with the AI Memory optional fields (`agent`, `model`, `session_id`, `outcome`, `tokens`, `duration`, `parallelism_factor`). See [[Meta/_system/_schema|_schema]] for field definitions.

---

## Sessions

Agent self-reports after meaningful work sessions. Each captures what was done, what worked, and approximate cost.

```dataview
TABLE agent, model, outcome, duration, file.cday AS "Created"
FROM "Engineering/AI-Memory/sessions"
WHERE type = "session-report"
SORT file.cday DESC
```

---

## Failures

Failure captures with root cause analysis and lessons learned. Read these before starting similar tasks.

```dataview
TABLE agent, outcome, summary, file.cday AS "Created"
FROM "Engineering/AI-Memory/failures"
WHERE type = "failure-log"
SORT file.cday DESC
```

---

## Patterns

Reusable success patterns extracted from sessions. These are distilled best practices - prefer applying a known pattern over improvising.

```dataview
TABLE agent, summary, file.cday AS "Created"
FROM "Engineering/AI-Memory/patterns"
WHERE type = "pattern"
SORT file.cday DESC
```

---

## Orchestrations

Multi-step pipelines that worked end-to-end, including sub-agent prompts and parallelism configuration. Use as blueprints for similar tasks.


```dataview
TABLE agent, parallelism_factor, outcome, duration, file.cday AS "Created"
FROM "Engineering/AI-Memory/orchestrations"
WHERE type = "orchestration"
SORT file.cday DESC
```

---

## Agent profiles

Reference profiles for each AI runtime in use - capabilities, constraints, preferred patterns.

- [[claude-code]]
- [[codex-cli]]
- [[gemini-cli]]

---

## See also

- [[shared-conventions]] - cross-agent conventions (naming, tagging, writeback rules)
- [[vault-navigation]] - how agents should traverse this vault
- [[MOC-Engineering]] - parent engineering MOC
