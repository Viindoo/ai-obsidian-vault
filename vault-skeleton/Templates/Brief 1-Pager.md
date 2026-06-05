---
id: brief-<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>-<% tp.date.now("YYYY-MM-DD") %>
title: "<% tp.file.title %>"
type: strategy
domain: strategy
status: draft
tags:
  - domain/strategy
  - activity/brief
  - status/draft
summary: ""
related: []
parent: "[[MOC-Strategy]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
confidence: medium
decision_required: yes
due: <% tp.date.now("YYYY-MM-DD", 7) %>
decided: ""
mentions: []
---

# Brief - <% tp.file.title %>

**Author**: <YOUR_NAME> · **Date**: <% tp.date.now("YYYY-MM-DD") %> · **Decision due**: <% tp.date.now("YYYY-MM-DD", 7) %>

## Tình hình

> 3-5 câu, fact-based, có số nếu có.

<% tp.file.cursor() %>

## Options

| # | Option | Pros | Cons | Cost / Effort |
|---|--------|------|------|---------------|
| A | Do nothing | | | 0 |
| B | | | | |
| C | | | | |

## Assumption (⚠ chưa verify)

- ⚠ 

## Recommend

> 1 option, 2-3 câu lý do.

**Chọn**: Option **\_\_** vì \_\_\_

## Next step nếu approve

- [ ] 
- [ ] 

## Risk & mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| | | | |
