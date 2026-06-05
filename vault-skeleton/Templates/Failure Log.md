---
id: <% tp.file.title.toLowerCase().replace(/\s+/g, '-') %>
title: "<% tp.file.title %>"
type: failure-log
domain: engineering
status: active
tags:
  - domain/engineering
  - activity/debug
  - status/active
summary: ""
related: []
parent: "[[MOC-Engineering]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
category: ""
resolution: ""
resolved_on: ""
tool: ""
cwd: ""
exit_code: ""
app_version: ""
app_module: ""
---

# Failure: <% tp.file.title %>

## Context

- **Tool**: 
- **Working dir**: 
- **Command**: 
- **Exit code**: 
- **Time**: <% tp.date.now("YYYY-MM-DD HH:mm") %>

## Error Output

```
<% tp.file.cursor() %>
```

## Root Cause

## Resolution

## Lesson Learned

## References
