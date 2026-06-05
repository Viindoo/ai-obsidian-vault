<%*
// Prompt 1 lần, gán biến local rồi reuse trong frontmatter và body
const now = new Date();
const defaultQ = "Q" + Math.ceil((now.getMonth() + 1) / 3) + "-" + now.getFullYear();
const q = await tp.system.prompt("Quarter (vd Q2-2026)", defaultQ);
const qSlug = q.toLowerCase().replace(/\s+/g, '-');

// Tính range_start / range_end từ Q-YYYY
const [qPart, yPart] = q.split('-');
const qNum = parseInt(qPart.replace(/[^0-9]/g, ''), 10) || 1;
const year = parseInt(yPart, 10) || now.getFullYear();
const startMonth = (qNum - 1) * 3 + 1;
const endMonth = startMonth + 2;
const lastDay = new Date(year, endMonth, 0).getDate();
const pad = n => String(n).padStart(2, '0');
const rangeStart = `${year}-${pad(startMonth)}-01`;
const rangeEnd = `${year}-${pad(endMonth)}-${pad(lastDay)}`;
const today = tp.date.now("YYYY-MM-DD");
-%>
---
id: quarterly-<% qSlug %>
title: "Quarterly Review - <% q %>"
type: area
domain: operations
status: active
tags:
  - domain/operations
  - activity/okr
  - status/active
summary: "Quarterly review <% q %>"
related: []
parent: "[[MOC-Operations]]"
created: <% today %>
updated: <% today %>
owner: "<YOUR_NAME>"
scope: internal
period: quarterly
quarter: <% q %>
range_start: <% rangeStart %>
range_end: <% rangeEnd %>
mentions: []
---

# 🎯 Quarterly Review - <% q %>

**Period**: <% rangeStart %> → <% rangeEnd %>

## Quarter snapshot

- **Theme**: 
- **Top wins**: 
- **Top losses**: 

## OKR retrospective

```dataview
TABLE objective, progress, status
FROM "Operations/OKRs"
WHERE type = "okr" AND quarter = "<% q %>"
```

For each KR - final score, what worked, what didn't:

| KR | Target | Actual | Score 0-1 | Why |
|----|--------|--------|-----------|-----|
| | | | | |

## Strategic theme review

> Compare with [[<YOUR_COMPANY> Strategy <YEAR>]] - did this quarter move in the right direction?

- **[Strategic pillar 1]**: 
- **[Strategic pillar 2]**: 
- **[Strategic pillar 3]**: 
- **[Product evolution theme]**: 

## Major decisions quý này

```dataview
LIST file.link
FROM ""
WHERE type = "decision"
  AND date(decided_on) >= date("<% rangeStart %>")
  AND date(decided_on) <= date("<% rangeEnd %>")
```

## Pipeline outcome

| Metric | Q-1 | This Q | Δ |
|--------|-----|--------|---|
| ACV won | | | |
| Win rate | | | |
| Avg deal cycle (days) | | | |
| New logos | | | |

## Top 3 priorities cho quý sau

1. 
2. 
3. 

## OKR proposals cho quý sau

> Soạn brief riêng nếu cần consensus team. Link tại đây:

- 

<% tp.file.cursor() %>
