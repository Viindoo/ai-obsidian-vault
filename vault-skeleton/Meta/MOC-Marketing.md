---
title: "MOC - Marketing"
aliases: ["Marketing MOC"]
type: moc
domain: marketing
status: active
tags:
  - domain/marketing
  - lifecycle/area
  - status/active
summary: "Map of Content for marketing - campaigns, content, SEO, and brand."
related: ["[[MOC-Sales-Pipeline]]", "[[MOC-Strategy]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Marketing

## Overview

> Describe your marketing strategy, channels, and brand here.

## Active campaigns

```dataview
LIST file.link + " - " + summary
FROM "Marketing/Campaigns"
WHERE type = "campaign" AND status = "active"
SORT file.ctime DESC
```

## Brand assets

> Link to your brand assets SSOT here: [[Brand Assets]]

## Related MOCs

[[MOC-Sales-Pipeline]] | [[MOC-Strategy]]
