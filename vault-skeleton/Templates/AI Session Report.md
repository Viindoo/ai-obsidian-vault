---
title: <% tp.file.title %>
type: session-report
domain: engineering
status: active
tags:
  - domain/engineering
  - activity/session-report
  - status/active
summary: <% await tp.system.prompt("One-line session summary") %>
related: []
parent: "[[MOC-AI-Memory]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
agent: <% await tp.system.suggester(["claude-code","codex-cli","gemini-cli"], ["claude-code","codex-cli","gemini-cli"]) %>
model: <% await tp.system.prompt("Model used (e.g., opus-4-7, sonnet-4-6)") %>
session_id: <% tp.date.now("YYYY-MM-DD-HHmmss") %>
outcome: <% await tp.system.suggester(["success","partial","failure"], ["success","partial","failure"]) %>
tokens: 
duration: 
---

# <% tp.file.title %>

## Task

*Brief: 1-2 sentences on what the agent was asked to do and the scope of the work.*

<% tp.file.cursor() %>

## Files touched

*List every file the agent read, edited, or created. Use wikilinks where the file lives in the vault; use plain paths for external files.*

- 

## What worked

*Describe approaches, tools, or patterns that produced correct results.*

- 

## What didn't / blockers

*Describe dead ends, tool errors, permission issues, or scope limits that slowed progress.*

- 

## Key findings

*Facts, data points, or architectural observations the agent surfaced that are worth preserving.*

- 

## Follow-ups

*Action items or open questions for the next session or the human. Use checkboxes.*

- [ ] 

## Cross-refs

*Link to related sessions, extracted patterns, or failure logs using wikilinks. Format: `[[YYYY-MM-DD_agent_topic]]`.*

- 
