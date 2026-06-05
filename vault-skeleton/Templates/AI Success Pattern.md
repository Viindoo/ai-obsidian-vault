---
title: <% tp.file.title %>
type: pattern
domain: engineering
status: evergreen
tags:
  - domain/engineering
  - activity/pattern
  - status/evergreen
summary: <% await tp.system.prompt("One-line description of this pattern") %>
related: []
parent: "[[MOC-AI-Memory]]"
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
owner: "<YOUR_NAME>"
scope: internal
confidence: <% await tp.system.suggester(["low","med","high"], ["low","med","high"]) %>
when_to_use: <% await tp.system.prompt("One-line trigger: when should an agent apply this pattern?") %>
evidence_count: 
---

# Pattern: <% tp.file.title %>

## When to use

*Describe the exact situation or signal that indicates this pattern should be applied. Be specific enough that an agent can match it automatically.*

## Steps

*Numbered sequence of actions. Each step should be atomic and verifiable.*

1. 
2. 
3. 

## Pitfalls

*Common mistakes when applying this pattern. State each as a concrete anti-signal.*

- 

## Evidence

*Links to session reports where this pattern was applied successfully. Format: `[[YYYY-MM-DD_agent_topic]]`.*

- 

## Anti-patterns

*What NOT to do. Describe the wrong alternative and why it fails.*

- 

## Variations

*Related patterns that apply in adjacent situations. Use wikilinks.*

- 
