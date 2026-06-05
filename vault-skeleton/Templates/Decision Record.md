---
id: <% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: decision
domain: engineering
status: draft
tags:
  - domain/engineering
  - activity/decision
  - status/draft
summary: ""
related: []
parent: "[[MOC-Engineering]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
confidence: medium
decided_on: 
decided_by: "<YOUR_NAME>"
reversal_cost: med
blast_radius: medium
affects_modules: []
migration_required: no
mentions: []
---

# <% tp.file.title %>

## Context

<% tp.file.cursor() %>

## Options Considered

| # | Option | Pros | Cons | Cost |
|---|--------|------|------|------|
| 1 | | | | |
| 2 | | | | |
| 3 (do nothing) | | | | |

## Decision

> **Chosen**: Option N
> **Reason**: 

## Consequences

- **Positive**: 
- **Negative**: 
- **Reversal cost**: low / med / high

## Follow-up

- [ ] 

## References
