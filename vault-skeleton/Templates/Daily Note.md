---
id: daily-<% tp.date.now("YYYY-MM-DD") %>
title: "<% tp.date.now("YYYY-MM-DD") %>"
type: daily
domain: operations
status: active
tags:
  - domain/operations
  - activity/digest
  - status/active
summary: "Daily plan & log <% tp.date.now("YYYY-MM-DD") %>"
related: []
parent: "[[MOC-Operations]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
period: daily
date_iso: <% tp.date.now("YYYY-MM-DD") %>
mentions: []
---

# 🗓️ <% tp.date.now("dddd, DD MMMM YYYY") %>

> **Hôm qua**: [[<% tp.date.yesterday("YYYY-MM-DD") %>|Daily yesterday]] · **Ngày mai**: [[<% tp.date.tomorrow("YYYY-MM-DD") %>|Daily tomorrow]] · **Tuần**: [[<% tp.date.now("gggg-[W]ww") %>|This week]]

## 🎯 Top 3 priorities hôm nay

1. [ ] 
2. [ ] 
3. [ ] 

## 📥 Inbox / Signal capture

> Quick dump email/CRM/news/idea - sẽ triage sau.

- 

## 📅 Calendar

| Time | Event | With | Notes |
|------|-------|------|-------|
| | | | |

## ⚡ Decisions / Actions taken

- 

## 🤖 Agent runs hôm nay

> Auto-link bởi `vault_write.py`. Tạo manual ở đây nếu run agent từ CLI.

- 

## 📓 Notes / Ideas

<% tp.file.cursor() %>

## 🌙 EOD reflection (15 phút cuối ngày)

- **Tốt**: 
- **Chưa**: 
- **Học được**: 
- **Cho mai**: 

```dataview
TABLE WITHOUT ID file.link AS "Note", type, status
FROM ""
WHERE contains(file.frontmatter.mentions, "[[daily-<% tp.date.now("YYYY-MM-DD") %>]]")
   OR contains(file.frontmatter.related, "[[daily-<% tp.date.now("YYYY-MM-DD") %>]]")
SORT file.mtime DESC
```
