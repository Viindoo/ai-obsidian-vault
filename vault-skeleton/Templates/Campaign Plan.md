---
id: campaign-<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: campaign
domain: marketing
status: draft
tags:
  - domain/marketing
  - activity/campaign
  - status/draft
summary: ""
related: []
parent: "[[MOC-Operations]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
goal: ""
kpi_target: ""
start: ""
end: ""
channels: []
budget: 0
mentions: []
---

# 📣 Campaign - <% tp.file.title %>

## Goal (ONE measurable)

> SMART goal - e.g. "50 demo booked from [target segment] by <date>".

## Persona target

- **Industry / size**: 
- **Role(s)**: 
- **Pain**: 

## Offer

- **What**: (demo / ebook / case study / webinar / trial)
- **Why now**: 
- **Friction**: 

## Channels & budget

| Channel | Budget | Owner | KPI |
|---------|--------------|-------|-----|
| LinkedIn ads | | | CPL |
| Google ads | | | CPL |
| SEO blog | | | Sessions |
| Webinar | | | Registrations |
| Email outbound | | | Reply rate |
| Referral | | | Booked demos |

## A/B test (chỉ 1 biến / lần)

| Variant | Hypothesis | Metric |
|---------|-----------|--------|
| A | | |
| B | | |

## Timeline

| Phase | Date | Milestone |
|-------|------|-----------|
| Prep | | Assets ready |
| Launch | | Live |
| Mid | | Optimize |
| Wrap | | Report |

## UTM convention

```
?utm_source=<channel>&utm_medium=<medium>&utm_campaign=<campaign-slug>&utm_content=<variant>
```

Campaign slug: `<% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>`

## Tracking dashboard

- Sheet: 
- GA4 segment: 

## Risk

- 

## Recap section (cuối campaign)

### Outcome vs target

### What worked / didn't

### Carry forward
