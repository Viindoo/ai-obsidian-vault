---
id: competitor-<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: competitor
domain: strategy
status: active
tags:
  - domain/strategy
  - activity/competitor
  - status/active
summary: ""
related: []
parent: "[[MOC-Knowledge]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
vendor: <% tp.file.title %>
country: ""
last_signal_date: <% tp.date.now("YYYY-MM-DD") %>
threat_level: medium
mentions: []
---

# 🎯 Competitor - <% tp.file.title %>

**Country**: · **Threat level**: 🟡 medium · **Last signal**: <% tp.date.now("YYYY-MM-DD") %>

## Profile

- **Founded**: 
- **HQ**: 
- **Customers (claimed)**: 
- **Pricing tier(s)**: 
- **Market segment**: 

## Positioning vs [YOUR PRODUCT]

| Aspect | <% tp.file.title %> | [YOUR PRODUCT] |
|--------|---------------------|---------|
| Target segment | | [your segment] |
| Pricing | | |
| Localization | | [your localization] |
| AI integration | | [your AI features] |
| Module breadth | | [your module count] |

## Strengths

- 

## Weaknesses (for your target customers)

- 

## Signals timeline

| Date | Signal | Source | Implication |
|------|--------|--------|-------------|
| <% tp.date.now("YYYY-MM-DD") %> | | | |

## Pricing snapshot

| Tier | Price (/user/month) | Modules | Source URL | Date |
|------|-----------------------|---------|------------|------|
| | | | | |

## Hiring signals (LinkedIn / job board)

- 

## Customer overlap / battle stories

- 

## Counter-positioning talking points

> Cách đáp trả khi khách hỏi "có giống X không?" - fact-based, không FUD.

- 

## Sources

```dataview
LIST file.link
FROM "Resources/Competitors"
WHERE contains(file.path, "/<% tp.file.title.toLowerCase() %>/")
SORT file.ctime DESC
```
