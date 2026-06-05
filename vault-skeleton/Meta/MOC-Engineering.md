---
title: "MOC - Engineering"
aliases: ["Engineering MOC"]
type: moc
domain: engineering
status: active
tags:
  - domain/engineering
  - lifecycle/area
  - status/active
summary: "Map of Content for engineering - tech stack, architecture references, coding conventions, decision records, debug/failure logs, and AI agent memory."
related: ["[[MOC-AI-Memory]]", "[[MOC-Knowledge]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Engineering

## Overview

> Replace this section with your engineering context (tech stack, primary languages, key repos, dev environment).

See [[Engineering Hub]] for the human-facing dashboard with active projects and recent activity.

---

## Hub

- [[Engineering Hub]] - Human-facing dashboard: active projects, recent debug/decision activity, open tasks.

---

## Architecture

```dataview
LIST file.link
FROM "Engineering"
WHERE type = "reference" OR type = "architecture-decision"
SORT file.ctime DESC
```

---

## Decision Records

```dataview
LIST file.link + " - " + summary
FROM "Engineering"
WHERE type = "decision"
SORT file.ctime DESC
```

---

## Debug Notes

```dataview
LIST file.link + " - " + summary
FROM "Engineering"
WHERE type = "debug"
SORT file.ctime DESC
LIMIT 10
```

---

## AI Memory (sub-MOC)

The AI agent memory layer (`Engineering/AI-Memory/`) has its own dedicated MOC due to volume.

- [[MOC-AI-Memory]] - Master index for all AI memory: sessions, failures, patterns, orchestrations, agent profiles.

---

## Related MOCs

[[MOC-AI-Memory]] | [[MOC-Knowledge]] | [[MOC-Strategy]]
