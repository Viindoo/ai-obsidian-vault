---
title: "MOC - Knowledge"
aliases: ["Knowledge MOC", "Resources MOC"]
type: moc
domain: knowledge
status: active
tags:
  - domain/knowledge
  - lifecycle/area
  - status/active
summary: "Map of Content for knowledge base - competitors, market research, tech references, and learning resources."
related: ["[[MOC-Strategy]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Knowledge

## Overview

Reference material organized by category.

## Competitors

```dataview
LIST file.link + " - " + summary
FROM "Resources/Competitors"
WHERE type = "competitor"
SORT file.mtime DESC
```

## Market Research

```dataview
LIST file.link + " - " + summary
FROM "Resources/Market"
WHERE type = "research"
SORT file.ctime DESC
```

## Tech References

```dataview
LIST file.link + " - " + summary
FROM "Resources/Tech"
SORT file.ctime DESC
```

## Learning

```dataview
LIST file.link + " - " + summary
FROM "Resources/Learning"
SORT file.ctime DESC
```

## Related MOCs

[[MOC-Strategy]] | [[MOC-Engineering]]
