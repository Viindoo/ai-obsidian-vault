---
name: vault-orchestration-log
description: Archive a successful multi-agent / multi-wave / multi-CLI pipeline as a reusable recipe so the same workflow shape can be replayed next time. Trigger AGGRESSIVELY whenever a multi-step coordination just finished successfully - user does NOT need to say "orchestration" or "pipeline" for this to activate. Intent triggers (English + Vietnamese, all should activate this skill) - Multi-step completion signals: "the pipeline worked end-to-end", "wave 1 then 2 then 3 all passed", "all 5 subagents finished", "the workflow finally ran clean", "pipeline xong xuôi", "3 wave xong cả", "fan-out đã chạy hết", "workflow 5 bước done", "đa CLI đã sync xong"; Multi-CLI coordination: "claude-code + codex worked together", "gemini handed off to claude-code", "claude-code và codex phối hợp", "gemini chuyển qua claude"; Save-the-recipe intent: "let's keep this workflow", "capture how we did this", "save the wave structure", "log this multi-step approach", "lần sau làm lại không muốn nhớ", "giữ lại workflow này", "ghi lại cấu trúc wave", "save lại cách phối hợp"; Reproducibility need: "I'll need to do this again", "team should be able to replay this", "make this repeatable", "lần sau làm lại được không", "team nên replay được", "tái sử dụng được". Archives workflow architecture - wave structure, dependency graph, sub-agent prompts, parallelism / serialization choice, model tier per stage - to AI-Memory/orchestrations/. NEVER trigger for: Docker/Airflow/k8s orchestration, cron scheduling, single-agent task summaries (use vault-session-end instead), or external CI/CD pipeline configs.
allowed-tools: Read Write Edit Bash
---

# Vault Orchestration Log Skill

Capture a multi-step pipeline that worked end-to-end into `Engineering/AI-Memory/orchestrations/`. The point is reusability of the *pipeline shape* - wave structure, dependency graph, model-tier choices - not the specific outputs of the run.

## When to invoke

- A multi-wave orchestration just completed (e.g., a fan-out of sub-agents that converged).
- The user ran a sprint or pipeline with 2+ waves and the structure proved useful.
- A multi-agent workflow (mixing claude-code + codex-cli + gemini-cli, or different model tiers) succeeded.
- The pipeline shape itself was novel and worth re-applying to a similar problem.

## When NOT to invoke

- A single-agent linear task (capture as `vault-session-end` instead).
- A failed pipeline (capture the failures via `vault-failure-log`, do not enshrine a broken pipeline shape).
- A pipeline so domain-specific it has no reuse value.

## Workflow

### 1. Gather orchestration inputs

Collect:

- **Goal** - what the pipeline was designed to accomplish (1-2 sentences).
- **Pre-conditions** - what must be true before running this pipeline.
- **Wave breakdown** - for each wave: workitems, model tier, parallel/serial, duration, agent.
- **Sub-agent prompts** - the verbatim prompt for each sub-agent.
- **Dependency graph** - which waves depend on which (text or simple ASCII diagram).
- **Lessons learned** - what worked, what almost did not, what to change next time.
- **Re-usability score** - 1-5 (1 = one-off, 5 = template-worthy).
- **Agents used** - list of agent identities (claude-code/codex-cli/gemini-cli) + model tiers.
- **Total tokens** - sum across all agents/waves.
- **Duration** - wall-clock minutes from start to merge.
- **Parallelism factor** - peak number of sub-agents running concurrently.

### 2. Determine filename

Pattern: `<slug>.md` in `Engineering/AI-Memory/orchestrations/<domain>/` - route by the orchestration's `domain` frontmatter (default `engineering`). No date prefix - orchestrations are evergreen templates.

### 3. Compose frontmatter

```yaml
---
title: "<Orchestration Name in Title Case>"
type: orchestration
domain: engineering
status: evergreen
tags:
  - domain/engineering
  - activity/orchestration-log
  - status/evergreen
  - lifecycle/area
summary: "<1-line: goal + outcome + parallelism>"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
owner: <owner>
scope: internal
agents_used:
  - claude-code
  - codex-cli
total_tokens: <int or "unknown">
duration: <int minutes>
parallelism_factor: <int - peak concurrent sub-agents>
reusability: <1-5>
confidence: <low|med|high>
---
```

### 4. Compose body

Sections (in order):

1. **Goal** - what this pipeline accomplishes. State it as "given X, produce Y".
2. **Pre-conditions** - bulleted checklist.
3. **Wave breakdown** - markdown table:

   | Wave | Workitems | Model tier | Parallel? | Duration | Agent |
   |------|-----------|------------|-----------|----------|-------|
   | 1 | A, B, C | Sonnet | yes | 5m | claude-code |

4. **Dependency graph** - ASCII or text description of which waves block which.

5. **Sub-agent prompts** - for each unique sub-agent role, the prompt template used.

6. **Run metrics** - total tokens, total duration, peak parallelism, success rate per wave.

7. **Lessons learned** - what worked, what was risky, what to change.

8. **Re-usability score + rationale** - 1-5 with a sentence explaining why.

9. **Adjacent patterns** - links to pattern notes that apply within this orchestration.

10. **Re-run recipe** - copy-pastable invocation template to run this pipeline again on a new input.

### 5. Confirm before writing

Show the composed note. Ask: "Write orchestration log to `<path>`? (y/n)".

### 6. Write the file

Use `Write` to the absolute path under `Engineering/AI-Memory/orchestrations/`.

### 7. Cross-link

- Link to each `vault-session-end` session-report from the waves.
- Link to any `vault-pattern-extract` patterns that were applied inside waves.
- If a wave produced a failure, link to its `vault-failure-log`.

## Anti-patterns

- Do not capture an orchestration that failed end-to-end. Failures go in failure logs.
- Do not include real customer data in sub-agent prompts - abstract to placeholders.
- Do not omit the dependency graph - the graph is the most reusable part.
- Do not skip the "Re-run recipe" section. The recipe is the value.
- Do not invent token/duration numbers. Mark `unknown` if not measured.
- Do not use this skill for single-agent linear sessions - use `vault-session-end` instead.
