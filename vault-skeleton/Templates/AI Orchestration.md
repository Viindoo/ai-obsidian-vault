---
title: <% tp.file.title %>
type: orchestration
domain: engineering
status: active
tags:
  - domain/engineering
  - activity/orchestration
  - status/active
summary: <% await tp.system.prompt("One-line description of this orchestration pipeline") %>
related: []
parent: "[[MOC-AI-Memory]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
agents_used:
  - 
total_tokens: 
duration: 
parallelism_factor: 
---

# Orchestration: <% tp.file.title %>

## Goal

*What was the end-to-end objective? State it as a deliverable, not a process.*

## Pre-conditions

*What must be true before running this pipeline? List environment, permissions, data, and tooling requirements.*

- 

## Wave breakdown

*One row per wave. Waves are sequential; work within a wave may be parallel.*

| Wave | Work items | Model tier | Parallel? | Duration |
|------|-----------|------------|-----------|----------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

## Sub-agent prompts

*One collapsed code block per distinct agent invocation. Label each block with wave and work item.*

<details>
<summary>Wave 1 - Work item A</summary>

```
Paste the exact prompt or task description sent to the sub-agent here.
```

</details>

<details>
<summary>Wave 2 - Work item B</summary>

```
Paste the exact prompt or task description sent to the sub-agent here.
```

</details>

## Dependency graph

*Show which work items depend on outputs from earlier items. Use a simple list or ASCII diagram.*

```
Wave 1: [A] [B] [C]  (parallel)
Wave 2: [D] depends on A+B; [E] depends on C
Wave 3: [F] depends on D+E
```

## Lessons learned

*What would you change about this pipeline on the next run? One bullet per lesson.*

- 

## Re-usability score

*Rate 1-5: how directly can this pipeline be reused for a similar future task?*

**Score**: /5

*Reasoning: describe what is specific to this run vs. what is generic.*
