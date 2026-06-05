---
title: "MOC - Operations"
aliases: ["Operations MOC"]
type: moc
domain: operations
status: active
tags:
  - domain/operations
  - lifecycle/area
  - status/active
summary: "Map of Content for operations - OKRs, board briefs, meeting notes, and recurring processes."
related: ["[[MOC-Strategy]]", "[[MOC-People]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Operations

## OKRs

```dataview
TABLE quarter, progress, status
FROM "Operations/OKRs"
WHERE type = "okr"
SORT quarter DESC
```

## Recent meetings

```dataview
LIST file.link + " - " + summary
FROM "Operations/Meetings"
WHERE type = "meeting"
SORT file.ctime DESC
LIMIT 10
```

## Processes

```dataview
LIST file.link + " - " + summary
FROM "Operations/Processes"
WHERE type = "area"
SORT file.ctime DESC
```

## Related MOCs

[[MOC-Strategy]] | [[MOC-People]]
