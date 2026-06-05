---
id: deal-<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: deal
domain: sales
status: active
tags:
  - domain/sales
  - activity/deal
  - status/active
summary: ""
related: []
parent: "[[MOC-Sales-Pipeline]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
customer: "[[customer:]]"
stage: lead
amount: 0
currency: ""
next_step: 
next_step_due: <% tp.date.now("YYYY-MM-DD", 7) %>
probability: 0.2
source: 
mentions: []
---

# Deal - <% tp.file.title %>

**Customer**: [[customer:]] · **Stage**: lead · **Amount**: 0 · **Next step due**: <% tp.date.now("YYYY-MM-DD", 7) %>

## Context

<% tp.file.cursor() %>

## Pain validated

- 

## Buying group

| Name | Role | Stance | Last contact |
|------|------|--------|-------------|
| | | | |

## Stage history (append-only)

| Date | Stage | Note | By |
|------|-------|------|----|
| <% tp.date.now("YYYY-MM-DD") %> | lead | Created | <YOUR_NAME> |

## Touches log

```dataview
TABLE type, file.mtime AS "When"
FROM "Sales"
WHERE contains(file.frontmatter.related, this.file.link)
   OR contains(file.frontmatter.mentions, this.file.link)
SORT file.mtime DESC
```

## Risk / blocker

- 

## Next step

> 1 hành động cụ thể, deadline rõ.

- **Action**: 
- **Owner**: 
- **Due**: 
