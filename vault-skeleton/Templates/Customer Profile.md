---
id: customer-<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: customer
domain: sales
status: active
tags:
  - domain/sales
  - activity/research
  - status/active
summary: ""
related: []
parent: "[[MOC-Sales-Pipeline]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
slug: <% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
industry: ""
size: sme
country: ""
health: green
acv: 0
go_live_date: ""
mentions: []
---

# <% tp.file.title %>

**Slug**: `customer:<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>` · **Industry**: · **Size**: · **Health**: 🟢

## Snapshot

- **Contract value (ACV)**: 
- **Contract start**: 
- **Renewal date**: 
- **Active modules**: 
- **Users (active / licensed)**: 

## Business context

<% tp.file.cursor() %>

## Key contacts

| Name | Role | Email/Phone | Decision power | Notes |
|------|------|-------------|----------------|-------|
| | | | | |

## Tech stack & integrations

- ERP modules: 
- 3rd-party: 
- Custom modules: 

## Pain points / use cases

1. 
2. 

## Customization & SOW history

| Date | Scope | Status |
|------|-------|--------|
| | | |

## Risks & flags

- 

## Recent touches (auto)

```dataview
TABLE type, file.mtime AS "When"
FROM "Sales"
WHERE contains(file.frontmatter.customer, this.file.link)
   OR contains(file.frontmatter.mentions, this.file.link)
SORT file.mtime DESC
LIMIT 10
```

## Open deals

```dataview
TABLE stage, amount, next_step_due
FROM "Sales/Pipeline"
WHERE contains(file.frontmatter.customer, this.file.link) AND status = "active"
```
