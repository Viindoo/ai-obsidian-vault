---
title: "MOC - People"
aliases: ["People MOC"]
type: moc
domain: people
status: active
tags:
  - domain/people
  - lifecycle/area
  - status/active
summary: "Map of Content for people - team profiles, advisors, and investor/partner relationships."
related: ["[[MOC-Operations]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - People

## Team

```dataview
LIST file.link + " - " + summary
FROM "People/Team"
SORT file.ctime DESC
```

## Partners & Investors

```dataview
LIST file.link + " - " + summary
FROM "People/Partners"
SORT file.ctime DESC
```

## Advisors

```dataview
LIST file.link + " - " + summary
FROM "People/Advisors"
SORT file.ctime DESC
```

## Related MOCs

[[MOC-Operations]] | [[MOC-Strategy]]
