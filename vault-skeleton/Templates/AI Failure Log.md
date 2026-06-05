---
title: <% tp.file.title %>
type: failure-log
domain: engineering
status: active
tags:
  - domain/engineering
  - activity/failure
  - status/active
summary: <% await tp.system.prompt("One-line description of what failed") %>
related: []
parent: "[[MOC-AI-Memory]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
agent: <% await tp.system.suggester(["claude-code","codex-cli","gemini-cli"], ["claude-code","codex-cli","gemini-cli"]) %>
model: <% await tp.system.prompt("Model used (e.g., opus-4-7, sonnet-4-6)") %>
session_id: <% await tp.system.prompt("Session ID where failure occurred (YYYY-MM-DD-HHmmss or leave blank)") %>
pattern: <% await tp.system.prompt("One-word failure category (e.g., mcp-config, permission-denied, tool-loop)") %>
severity: <% await tp.system.suggester(["low","med","high"], ["low","med","high"]) %>
resolution: <% await tp.system.suggester(["resolved","workaround","open"], ["resolved","workaround","open"]) %>
---

# Failure: <% tp.file.title %>

## Context

*What was the agent trying to do? Include the task, working directory, and relevant environment details.*

- **Agent**: 
- **Task**: 
- **Time**: <% tp.date.now("YYYY-MM-DD HH:mm") %>
- **Environment**: 

## What failed

*Exact error message, unexpected output, or wrong behavior. Paste verbatim output where possible.*

```
<% tp.file.cursor() %>
```

## Root cause

*Why did this fail? Distinguish between agent error, tool bug, misconfiguration, or environmental issue.*

## Resolution

*What was done to fix or work around the failure. If still open, describe investigation steps taken.*

## Lesson learned

*One clear takeaway. Should be actionable - state it as a rule or heuristic.*

## How to prevent recurrence

*Specific change to process, config, prompt, or tooling that prevents this class of failure.*

- [ ] 

## Related

*Links to other failure logs with the same `pattern` field. Format: `[[AI Failure Log - topic]]`.*

- 
