---
title: "MOC - Sales Pipeline"
aliases: ["Sales MOC", "Pipeline MOC"]
type: moc
domain: sales
status: active
tags:
  - domain/sales
  - lifecycle/area
  - status/active
summary: "Map of Content for sales - active deal pipeline, customer profiles, proposal tracking, and discovery notes."
related: ["[[MOC-Strategy]]", "[[MOC-Marketing]]"]
parent: "[[Home]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# MOC - Sales Pipeline

## Overview

> Describe your sales pipeline stages, customer segments, and typical deal cycle.

## Active deals (Dataview)

```dataview
TABLE customer, stage, amount, next_step_due
FROM "Sales/Pipeline"
WHERE type = "deal" AND status = "active"
SORT next_step_due ASC
```

## Customer profiles

```dataview
LIST file.link + " - " + summary
FROM "Sales/Customers"
WHERE type = "customer"
SORT file.ctime DESC
```

## Related MOCs

[[MOC-Strategy]] | [[MOC-Marketing]]
