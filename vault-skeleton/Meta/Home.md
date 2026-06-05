---
title: "AI Vault - Home"
aliases: ["Home", "Dashboard"]
type: moc
domain: knowledge
status: active
tags:
  - domain/knowledge
  - lifecycle/area
  - status/active
summary: "Master MOC and live dashboard - daily note, pipeline, decisions, and competitor signals in one landing page. Entry point for both human navigation and AI agent reasoning."
related: []
parent: ""
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: "<YOUR_NAME>"
scope: internal
---

# AI Vault - Home

> [YOUR NAME] · [Role] · Vault = single source of truth · `Home` = landing dashboard
> Updated: <span>`= dateformat(date(today), "yyyy-MM-dd EEEE")`</span>

---

## Quick Navigation

| Need | MOC | Folder |
|------|-----|--------|
| Active projects (time-bounded) | [[MOC-Projects]] | `Projects/` |
| Strategy thinking | [[MOC-Strategy]] | `Strategy/` |
| Product roadmap | [[MOC-Product]] | `Product/` |
| Sales pipeline | [[MOC-Sales-Pipeline]] | `Sales/` |
| Marketing | [[MOC-Marketing]] | `Marketing/` |
| Engineering | [[MOC-Engineering]] | `Engineering/` |
| Operations | [[MOC-Operations]] | `Operations/` |
| People | [[MOC-People]] | `People/` |
| Knowledge (market, competitors, research) | [[MOC-Knowledge]] | `Resources/` |

---

## Today

```dataviewjs
const today = dv.date("today").toFormat("yyyy-MM-dd");
const yyyy = dv.date("today").toFormat("yyyy");
const mm = dv.date("today").toFormat("MM");
const todayPath = `Daily/${yyyy}/${mm}/${today}.md`;
const todayPage = dv.page(todayPath);
if (todayPage) {
  dv.paragraph(`[[${todayPath}|Daily note today]] - _${todayPage.summary || ""}_`);
} else {
  dv.paragraph(`Daily note today **not yet created** - press Cmd+Shift+D or use QuickAdd "Daily Note (today)"`);
}
```

### Recent daily notes (7 days)

```dataview
TABLE WITHOUT ID file.link AS "Day", summary AS "Summary"
FROM "Daily"
WHERE type = "daily"
SORT date_iso DESC
LIMIT 7
```

---

## OKR - current quarter

```dataview
TABLE quarter, owner, progress, status
FROM "Operations/OKRs"
WHERE type = "okr" AND status = "active"
SORT quarter DESC
```

---

## Top deals needing attention (next_step_due <= 3 days)

```dataview
TABLE customer AS "Customer", stage AS "Stage", amount AS "Amount", next_step_due AS "Due", owner
FROM "Sales/Pipeline"
WHERE type = "deal" AND status = "active" AND date(next_step_due) <= date(today) + dur(3 days)
SORT next_step_due ASC
LIMIT 10
```

### Pipeline by stage

```dataview
TABLE stage AS "Stage", length(rows) AS "# Deals", sum(rows.amount) AS "Total"
FROM "Sales/Pipeline"
WHERE type = "deal" AND status = "active"
GROUP BY stage
```

---

## Decisions pending (briefs with decision_required: yes)

```dataview
TABLE summary, due, file.ctime AS "Created"
FROM ""
WHERE type = "brief" AND decision_required = "yes" AND status != "decided" AND status != "archived"
SORT due ASC
```

### Decisions made in the last 7 days

```dataview
TABLE decided_on, decided_by, summary
FROM ""
WHERE type = "decision" AND date(decided_on) >= date(today) - dur(7 days)
SORT decided_on DESC
```

---

## Competitor signals (30 days)

```dataview
TABLE vendor, last_signal_date AS "Last signal", threat_level AS "Threat"
FROM "Resources/Competitors"
WHERE type = "competitor" AND date(last_signal_date) >= date(today) - dur(30 days)
SORT last_signal_date DESC
```

---

## Inbox - needs triage

```dataview
LIST file.link
FROM "Inbox"
WHERE type = "inbox" OR !type
SORT file.ctime DESC
```

---

## Customer health snapshot

```dataview
TABLE industry, size, health, acv
FROM "Sales/Customers"
WHERE type = "customer"
SORT health ASC, acv DESC
LIMIT 15
```

---

## AI Memory recent activity

### Recent sessions (last 5)

```dataview
TABLE file.name as Title, agent, outcome, file.cday as Created
FROM "Engineering/AI-Memory/sessions"
WHERE type = "session-report"
SORT file.cday DESC
LIMIT 5
```

### Recent failures (last 7 days)

```dataview
TABLE file.name as Title, agent, outcome, file.cday as Created
FROM "Engineering/AI-Memory/failures"
WHERE type = "failure-log" AND file.cday >= date(today) - dur(7 days)
SORT file.cday DESC
LIMIT 3
```

---

## Domain hubs

- [[MOC-Projects]] - active time-bounded projects (Projects/)
- [[Strategy Hub]] - vision, briefs, decisions
- [[Sales Hub]] - pipeline, customers, proposals
- [[Marketing Hub]] - campaigns, content, SEO
- [[Product Hub]] - roadmap, BRD, SRS
- [[Engineering Hub]] - debug, decisions, architecture
- [[Operations Hub]] - meetings, OKRs, processes
- [[MOC-Knowledge]] - competitors, markets, research
- [[People Hub]] - team, partners, investors

---

## System

- [[ETHOS|Work Ethos - MUST READ]] - universal principles for AI agents (any domain)
- [[Meta/_system/_schema|Frontmatter Schema v3]]
- Agent suite: see [[MOC-AI-Memory]] - skills at `.claude/skills/`
