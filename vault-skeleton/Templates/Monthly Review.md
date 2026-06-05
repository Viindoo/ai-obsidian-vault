---
id: monthly-<% tp.date.now("YYYY-MM") %>
title: "Monthly Review - <% tp.date.now("MMMM YYYY") %>"
type: area
domain: operations
status: active
tags:
  - domain/operations
  - activity/digest
  - status/active
summary: "Monthly review <% tp.date.now("MMMM YYYY") %>"
related: []
parent: "[[MOC-Operations]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
period: monthly
range_start: <% tp.date.now("YYYY-MM-01") %>
range_end: <% tp.date.now("YYYY-MM-") + tp.date.now("DD", 0, tp.date.now("YYYY-MM"), "YYYY-MM") %>
mentions: []
---

# 📅 Monthly Review - <% tp.date.now("MMMM YYYY") %>

## Highlights / Lowlights

| Highlight | Lowlight |
|-----------|----------|
| | |

## OKR mid-quarter check

```dataview
TABLE quarter, progress, status
FROM "Operations/OKRs"
WHERE type = "okr" AND status = "active"
```

## Pipeline summary

| Metric | Value |
|--------|-------|
| New deals opened | |
| Deals closed-won | |
| Deals closed-lost | |
| ACV won (VND) | |
| ACV lost (VND) | |

```dataview
TABLE stage, count(rows) AS "count", sum(rows.amount) AS "ACV"
FROM "Sales/Pipeline"
WHERE type = "deal"
GROUP BY stage
```

## Marketing performance

| Channel | Leads | MQL | SQL | CAC |
|---------|-------|-----|-----|-----|
| | | | | |

## Hiring status

```dataview
TABLE role, seniority, status
FROM "Operations/Hiring"
WHERE type = "hiring"
```

## Competitor moves tháng này

```dataview
LIST file.link
FROM "Resources/Competitors"
WHERE date(file.frontmatter.last_signal_date) >= date(today) - dur(30 days)
SORT file.mtime DESC
```

## Decisions tháng này

```dataview
LIST file.link
FROM ""
WHERE type = "decision" AND date(decided_on) >= date(today) - dur(30 days)
```

## Themes & patterns

- 

## Carry forward

- 

<% tp.file.cursor() %>
