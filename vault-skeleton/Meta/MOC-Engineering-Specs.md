---
title: "MOC - Engineering Specs"
aliases: ["Engineering Specs MOC"]
type: moc
domain: engineering
status: active
tags:
  - domain/engineering
  - lifecycle/area
  - status/active
summary: "Master index for engineering design specs (per milestone or system). Specs answer 'what + why + tradeoffs' - distinct from orchestrations (execution plans) and sessions (post-task reports)."
related: ["[[MOC-Engineering]]", "[[MOC-AI-Memory]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Engineering Specs

## Overview

Design specs live in `Engineering/Specs/`. A spec documents **what a system/milestone is supposed to do, why, and the tradeoffs considered**, written BEFORE implementation. Specs typically transition to `status: archived` once the milestone they describe has shipped - they remain as historical reference.

Distinct from sibling MOCs:

| MOC | Folder | Answers |
|---|---|---|
| [[MOC-Engineering-Specs]] | `Engineering/Specs/` | "What + why + tradeoffs" (design intent) |
| [[MOC-AI-Memory]] → orchestrations | `AI-Memory/orchestrations/` | "Step 1 / step 2 / ..." (execution plan) |
| [[MOC-AI-Memory]] → sessions | `AI-Memory/sessions/` | "What happened in task X" (post-mortem) |
| [[MOC-AI-Memory]] → patterns | `AI-Memory/patterns/` | "How to repeat success Y" (reusable recipe) |

## Index - all specs

```dataview
TABLE
  status AS Status,
  created AS Created,
  summary AS Summary
FROM "Engineering/Specs"
WHERE type = "design-spec"
SORT created DESC
```

> Start adding design specs here as you create them.

## Naming

`<YYYY-MM-DD>_<slug>.md` - date-prefixed, no agent slug (specs are vendor-neutral design docs, often co-authored across runtimes).

## Authoring workflow

1. **Draft as `status: active`** while design is in flight.
2. **Promote to `status: archived`** once milestone ships - keep file as historical reference.
3. **Supersede via frontmatter `superseded_by: "[[new-spec]]"`** if a later spec replaces this design.

## Related

- [[MOC-Engineering]] - parent engineering MOC (architecture, conventions, decisions, debug)
- [[MOC-AI-Memory]] - sibling MOC for AI agent execution memory
- [[_Index|Engineering Specs _Index]] - folder breadcrumb at `Engineering/Specs/_Index.md`
