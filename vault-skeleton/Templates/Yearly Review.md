<%*
const now = new Date();
const defaultYear = String(now.getFullYear());
const year = await tp.system.prompt("Year (vd 2026)", defaultYear);
const today = tp.date.now("YYYY-MM-DD");
const rangeStart = `${year}-01-01`;
const rangeEnd = `${year}-12-31`;
-%>
---
id: yearly-<% year %>
title: "Yearly Review - <% year %>"
type: area
domain: operations
status: active
tags:
  - domain/operations
  - activity/digest
  - status/active
summary: "Yearly review <% year %>"
related: []
parent: "[[MOC-Operations]]"
created: <% today %>
updated: <% today %>
owner: "<YOUR_NAME>"
scope: internal
period: yearly
range_start: <% rangeStart %>
range_end: <% rangeEnd %>
---

# Yearly Review - <% year %>

**Period**: <% rangeStart %> → <% rangeEnd %>

---

## Year snapshot

- **Theme for <% year %>**: 
- **Single biggest win**: 
- **Single biggest loss**: 

---

## Outcomes <% year %>

### What we shipped

| Item | Quarter | Impact |
|------|---------|--------|
| | | |

### Revenue and growth

| Metric | Target | Actual | vs Target |
|--------|--------|--------|-----------|
| ACV total | | | |
| New logos | | | |
| Churn | | | |
| Headcount end of year | | | |

### Strategy execution

> Compared to [[<YOUR_COMPANY> Strategy <YEAR>]] - did we move in the right direction?

- **[Strategic pillar 1]**: 
- **[Strategic pillar 2]**: 
- **[Strategic pillar 3]**: 
- **[Product evolution theme]**: 

---

## Biggest wins

1. 
2. 
3. 

## Biggest losses / failures

1. 
2. 
3. 

---

## Major decisions <% year %>

```dataview
LIST file.link
FROM ""
WHERE type = "decision"
  AND date(decided_on) >= date("<% rangeStart %>")
  AND date(decided_on) <= date("<% rangeEnd %>")
SORT decided_on ASC
```

---

## What to retire

Things we should stop doing in <% year + 1 %>:

- 
- 

## What to double down on

Things that worked and deserve more investment:

- 
- 

---

## Vision for <% year + 1 %>

### The one goal

> If we could only accomplish one thing in <% year + 1 %>, it would be:

### Top 3 priorities

1. 
2. 
3. 

### What success looks like (Dec 31, <% year + 1 %>)

- Revenue: 
- Product: 
- Team: 
- Market position: 

---

## OKR retrospective (all quarters)

```dataview
TABLE quarter, objective, progress, status
FROM "Operations/OKRs"
WHERE type = "okr" AND contains(quarter, "<% year %>")
SORT quarter ASC
```

---

## Quarterly review links

```dataview
LIST file.link
FROM "Daily/<% year %>"
WHERE type = "area" AND period = "quarterly"
SORT range_start ASC
```

<% tp.file.cursor() %>
