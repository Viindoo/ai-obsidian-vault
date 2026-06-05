---
title: "MOC - Projects"
aliases: ["Projects MOC"]
type: moc
domain: knowledge
status: active
tags:
  - domain/knowledge
  - lifecycle/project
  - status/active
summary: "Map of Content for active time-bounded projects with deliverables and deadlines."
related: ["[[MOC-Strategy]]", "[[MOC-Engineering]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Projects

## Active projects

```dataview
TABLE summary, status, file.ctime AS "Started"
FROM "Projects"
WHERE status = "active"
SORT file.ctime DESC
```

## Completed projects

```dataview
LIST file.link + " - " + summary
FROM "Projects"
WHERE status = "archived"
SORT file.ctime DESC
LIMIT 10
```

## Related MOCs

[[MOC-Strategy]] | [[MOC-Engineering]] | [[MOC-Operations]]
