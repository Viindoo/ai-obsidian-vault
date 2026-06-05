---
id: weekly-<% tp.date.now("gggg-[W]ww") %>
title: "Week <% tp.date.now("ww") %> - <% tp.date.now("YYYY") %>"
type: area
domain: operations
status: active
tags:
  - domain/operations
  - activity/digest
  - status/active
summary: "Weekly review week <% tp.date.now("ww") %>, <% tp.date.now("YYYY") %>"
related: []
parent: "[[MOC-Operations]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
period: weekly
range_start: <% tp.date.now("YYYY-MM-DD", 0, tp.file.title, "gggg-[W]ww") %>
range_end: <% tp.date.now("YYYY-MM-DD", 6, tp.file.title, "gggg-[W]ww") %>
mentions: []
---

# 📊 Weekly Review - Week <% tp.date.now("ww") %>, <% tp.date.now("YYYY") %>

**Period**: <% tp.date.now("YYYY-MM-DD", 0, tp.file.title, "gggg-[W]ww") %> → <% tp.date.now("YYYY-MM-DD", 6, tp.file.title, "gggg-[W]ww") %>

## 🟢 Wins

- 

## 🔴 Blockers / Misses

- 

## 📈 OKR check

```dataview
TABLE quarter, progress, status
FROM "Operations/OKRs"
WHERE type = "okr" AND status = "active"
SORT progress ASC
```

## 💼 Pipeline status (deals needing touch)

```dataview
TABLE customer, stage, amount, next_step_due
FROM "Sales/Pipeline"
WHERE type = "deal" AND status = "active"
SORT next_step_due ASC
LIMIT 10
```

## 🔭 Competitor / market signals tuần này

```dataview
LIST
FROM "Resources/Competitors" OR "Resources/Market"
WHERE date(file.frontmatter.last_signal_date) >= date(today) - dur(7 days)
SORT file.mtime DESC
```

## ⚡ Decisions made

```dataview
LIST
FROM ""
WHERE type = "decision" AND date(decided_on) >= date(today) - dur(7 days)
```

## 🎯 Top 3 priorities cho tuần sau

1. 
2. 
3. 

## 🌙 Reflection

- **What worked**: 
- **What didn't**: 
- **What to change**: 

<% tp.file.cursor() %>
