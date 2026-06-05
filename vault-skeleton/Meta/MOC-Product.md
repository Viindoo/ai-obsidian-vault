---
title: "MOC - Product"
aliases: ["Product MOC"]
type: moc
domain: product
status: active
tags:
  - domain/product
  - lifecycle/area
  - status/active
summary: "Map of Content for product management - architecture, module inventory, product ladder, roadmap, BRD, SRS, and release notes."
related: ["[[MOC-Engineering]]", "[[MOC-Strategy]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Product

## Overview

> Replace with your product context (platform, stack, tiers, roadmap summary).

## BRDs

```dataview
LIST file.link + " - " + summary
FROM "Product/BRD"
SORT file.ctime DESC
```

## SRSs

```dataview
LIST file.link + " - " + summary
FROM "Product/SRS"
SORT file.ctime DESC
```

## Roadmap

```dataview
LIST file.link + " - " + summary
FROM "Product/Roadmap"
SORT file.ctime DESC
```

## Releases

```dataview
LIST file.link + " - " + summary
FROM "Product/Releases"
SORT file.ctime DESC
LIMIT 10
```

## Related MOCs

[[MOC-Engineering]] | [[MOC-Strategy]] | [[MOC-Knowledge]]
