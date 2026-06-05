---
title: Claude Instructions - Knowledge Vault
type: reference
domain: knowledge
status: active
tags: ["domain/knowledge", "status/active"]
summary: AI agent operating instructions for the vault - entry rule, schema v3, write boundaries, failure modes, and override layer.
created: 2026-01-01
updated: 2026-01-01
owner: "<owner>"
---

# Claude Instructions - Knowledge Vault

## Purpose

This vault is the canonical knowledge base for [YOUR ROLE] at [YOUR COMPANY]. It serves both human navigation and AI agent reasoning. The vault owner uses it to make strategic decisions; AI agents use it to provide grounded, evidence-based assistance.

## Work Ethos - luôn áp dụng (bắt buộc, mọi task, mọi domain)

11 nguyên tắc nền tảng cho mọi AI agent - engineering, sales, marketing, operations, strategy. SSOT đầy đủ (full version + examples): `[[ETHOS]]` (vault root) - MUST READ mỗi session. Claude Code nạp full ETHOS qua `@import` trong `~/.claude/CLAUDE.md`; KHÔNG còn TL;DR chép tay ở đây để tránh drift (sửa nội dung → sửa `[[ETHOS]]`).

Supersede mọi convention folder-specific khi có xung đột.

## Override layer

Members customize by creating `CLAUDE.local.md` and `ETHOS.local.md` at vault root. These files are gitignored (`*.local.md`) - local to each member's machine. They are loaded AFTER the mechanism files (`CLAUDE.md`, `ETHOS.md`). An example is provided in `CLAUDE.local.md.example` - copy and rename to get started.

**Rule:** NEVER modify `CLAUDE.md` or `ETHOS.md` for instance-specific config. Always use `*.local.md` files.

## Entry rule

ALWAYS read `Meta/Home.md` first when starting work in this vault. Home is the master MOC - it points to domain MOCs which point to specific notes. Do not random-search the vault.

## Folder structure

- `Meta/` - Home MOC, domain MOCs, schema, taxonomy, changelog, folder-mapping aid
- `Inbox/` - capture nhanh, chua phan loai
- `Projects/` - active projects co deadline
- `Strategy/` `Product/` `Sales/` `Marketing/` `Engineering/` `Operations/` `People/` - 7 lĩnh vực phụ trách (ongoing responsibilities), nay ở top-level (đã bỏ thư mục Areas bao ngoài)
- `Resources/` - reference (Competitors, Market, Tech, Documentation, Learning, Research)
- `Archive/` - deprecated/historical
- `Daily/` - daily/weekly/monthly/quarterly/yearly notes
- `Templates/` - Templater templates (do not edit unless asked)
- `_attachments/` - binary attachments (gitignored)

## MOC vs Hub convention

Each domain has TWO index notes - keep their roles distinct:

- **`Meta/MOC-<Domain>.md`** - machine-readable traversal index for AI agents. Lists notes by type with brief annotations. Lightweight Dataview only.
- **`<Domain>/<Domain> Hub.md`** - human-facing dashboard. Heavier Dataview blocks (OKR status, deal funnels, calendars). Agents may read but should not duplicate its queries.

When adding new content: write the note, then ensure the corresponding MOC lists it. Hub picks it up via Dataview automatically.

## Frontmatter contract (schema v3)

Canonical reference: `Meta/_system/_schema.md`. Required fields for any serious note:
`title`, `type`, `domain`, `status`, `tags`, `summary`, `created`, `updated`, `owner`. Optional: `aliases`, `related`, `parent`, `scope`, `confidence`.

## Tag namespaces

4 namespaces (canonical: `Meta/_system/_tag-taxonomy.md`):
- `domain/`: strategy, product, sales, marketing, engineering, operations, people, finance, knowledge
- `activity/`: decision, brief, deal, meeting, campaign, competitor, research, debug, failure
- `status/`: active, draft, archived, evergreen, deprecated
- `lifecycle/`: project, area, resource, archive

## Naming conventions

- Strategy/refined notes: Title Case (`[YOUR COMPANY] Strategy 2026.md`)
- Daily notes: ISO date (`2026-05-16.md`)
- Meeting notes: ISO date + title (`2026-05-20 Board Meeting.md`)
- Engineering logs (debug/decision): snake_case acceptable (log records)
- MOC files: `MOC-<Topic>.md`

## DO

- Read `Meta/Home.md` first to orient.
- Use frontmatter `summary` field to decide if a note is relevant before reading full body.
- When creating new notes, use Templater (right-click folder → New Note) - frontmatter auto-populated.
- Capture quick thoughts in `Inbox/` with tag → Auto Note Mover will file appropriately.

## DO NOT

- Do not create files at vault root (use `Inbox/` for unsorted).
- Do not edit files in `Archive/` (historical, frozen).
- Do not delete files outside the immediate task scope.
- Do not edit `.obsidian/workspace.json` (gitignored, user state).
- Do not change folder structure without updating `Meta/_system/_folder-mapping-old-to-new.md` and CLAUDE.md.
- Do not modify `CLAUDE.md` or `ETHOS.md` for instance-specific config - use `CLAUDE.local.md` / `ETHOS.local.md`.

## Common AI agent failure modes

- Random search instead of Home.md entry → use `Meta/Home.md` as starting point, traverse MOC hierarchy
- Ignore `summary` field → always check frontmatter `summary` before reading full body to filter relevance
- Hallucinate cross-links → only follow existing `related:` wikilinks; do not invent connections between notes
- Edit Archive content → `Archive/` is frozen, never modify
- Skip Auto Note Mover rules → respect 4-namespace tag taxonomy; wrong `activity/*` tag causes auto-relocation

## Update cycle

This CLAUDE.md updates quarterly OR after schema/folder changes.
Last updated: 2026-01-01. Next review: see frontmatter.

## External agent interaction

- Vault reads (CI, sub-agents): allowed read-only (Read, Grep, Glob, Bash read-only)
- Vault writes (future automation): append-only to note bodies, never overwrite frontmatter, include timestamp signature
- Skill `vault-research`: read-only - traverse Home → MOC → notes, cite with wikilinks
- Skill `vault-capture`: write to `Inbox/` only - let Auto Note Mover re-file by tag

## Dispatch & Routing

Full routing tree, plugin matrix, model tier, crash prevention, disambiguation pattern: see `~/.claude/CLAUDE.md` → "Dispatch & Routing Layer" section (member-specific, configured in `CLAUDE.local.md`).

### Memory Writeback Threshold

- `vault-session-end`: ≥3 non-trivial tool call AND outcome produced
- `vault-failure-log`: failed call cần rework HOẶC cùng error ≥2 lần
- `vault-pattern-extract`: approach reuse ≥3 session HOẶC explicit request
- `vault-orchestration-log`: multi-wave HOẶC multi-CLI pipeline success
- Floor: skip nếu session <5 min và read-only

## When in doubt

Read `Meta/Home.md` again, or ask the user.
