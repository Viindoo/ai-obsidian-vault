---
title: "Tag Taxonomy v3"
aliases: ["tag-taxonomy", "tags"]
type: reference
domain: knowledge
status: evergreen
tags:
  - domain/knowledge
  - activity/process
  - status/evergreen
summary: "Canonical tag taxonomy for vault v3 - 8 namespaces (domain, activity, status, lifecycle, client, source, topic, kind) with enum values, usage examples, anti-patterns, and retirement guidance."
related: ["[[_schema]]"]
parent: "[[MOC-Knowledge]]"
created: 2026-05-16
updated: 2026-06-03
owner: "<YOUR_NAME>"
scope: internal
---

# Tag Taxonomy v3

> All tags in this vault use namespace prefixes. Unnamespaced tags are not permitted.
> Source of truth for Dataview queries, Templater defaults, and Auto Note Mover rules.

---

## Namespace 1: `domain/` - business domain

Every note must have exactly one `domain/` tag.

| Tag | Use for |
|-----|---------|
| `domain/strategy` | Corporate strategy, GTM, vision, competitive positioning |
| `domain/product` | Product management, roadmap, BRD, SRS, feature design |
| `domain/sales` | Sales pipeline, CRM, deal logs, customer profiles |
| `domain/marketing` | Campaigns, content, SEO, brand, events |
| `domain/engineering` | Code, architecture, debugging, tech decisions, tooling |
| `domain/operations` | OKRs, meetings, board, processes, cadence |
| `domain/people` | Team, advisors, investors, partners, org chart |
| `domain/finance` | Finance, budgeting, P&L (reserved - not yet active) |
| `domain/knowledge` | Research, competitors, market intel, learning, reference |

**Anti-patterns:**
- Do not use `domain/eng` or `domain/ops` (legacy - migrated to full names in v3)
- Do not tag a note with two `domain/` tags - pick the primary domain

---

## Namespace 2: `activity/` - activity type

What kind of work this note records. Zero or more `activity/` tags are allowed.

| Tag | Use for |
|-----|---------|
| `activity/decision` | Engineering or strategic decision records |
| `activity/brief` | CEO briefs, board briefs, 1-pager summaries |
| `activity/deal` | Deal log entries in sales pipeline |
| `activity/meeting` | Meeting notes with agenda and action items |
| `activity/campaign` | Marketing campaign plans and post-mortems |
| `activity/competitor` | Competitor profile updates, signal logs |
| `activity/research` | Market research, user research, literature review |
| `activity/debug` | Debug investigation notes |
| `activity/failure` | Failure post-mortems and incident logs |
| `activity/okr` | OKR planning, tracking, retrospective |
| `activity/digest` | Weekly/monthly digest or summary notes |
| `activity/process` | Process documentation, playbooks, SOPs |
| `activity/profile` | People/agent/company profiles (ratified - used by 3+ notes) |
| `activity/session-report` | AI agent session self-reports in `AI-Memory/sessions/` |
| `activity/pattern` | Reusable success patterns extracted from AI sessions |
| `activity/orchestration` | Multi-step AI pipeline records in `AI-Memory/orchestrations/` |
| `activity/reference` | Reference material: guides, specs, conventions (ratified - used by existing notes) |

**Anti-patterns:**
- Do not create `activity/note` or `activity/document` - too generic
- Do not use `activity/` tags for MOC/template files (they belong to no specific activity)

---

## Namespace 3: `status/` - note lifecycle status

Every note should have exactly one `status/` tag.

| Tag | Use for |
|-----|---------|
| `status/active` | Actively maintained, current, in use |
| `status/draft` | Work in progress, incomplete, not yet reliable |
| `status/archived` | Historical, frozen - do not edit |
| `status/evergreen` | Timeless reference - rarely changes, always valid |
| `status/deprecated` | Superseded by newer note, kept for traceability |

**Anti-patterns:**
- Do not use `status/wip` (use `status/draft`)
- Do not use `status/done` (use `status/archived` for completed work)
- `status/evergreen` is for taxonomy, schema, conventions - not for notes that are merely stable

**Consistency rule (enforced by `validate_frontmatter.py`):** the `status/` tag mirrors the canonical `status:` frontmatter field. Its value must be one of the five above AND must equal the `status:` field. When a note's status changes, update both the field and the tag together - CI rejects drift (e.g. `status: archived` + `status/done`).

---

## Namespace 4: `lifecycle/` - folder/MOC classification

Used only on MOC notes and area-level notes to classify what PARA category the folder belongs to. Do not add `lifecycle/` tags to content notes.

| Tag | Use for |
|-----|---------|
| `lifecycle/project` | Time-bounded projects with deliverables and deadlines |
| `lifecycle/area` | Ongoing responsibilities without end date |
| `lifecycle/resource` | Reference material (Resources/ content) |
| `lifecycle/archive` | Archived material (Archive/ content) |

---

## Namespace 5: `client/` - customer / engagement scope

Used on notes tied to a specific external client/engagement (delivery projects, customer-specific docs). Zero or one `client/` tag per note. Value is the client slug in kebab-case.

| Tag | Use for |
|-----|---------|
| `client/<slug>` | Replace `<slug>` with the client/project name in kebab-case, e.g. `client/acme-corp` |

**Anti-patterns:**
- Do not use `client/` for internal product work (that is `domain/` + `lifecycle/`)
- Do not put confidential client identifiers as the slug - use the short public project name only

---

## Namespace 6: `source/` - provenance / originating system

Used to record where a note's content originated - the product, project, or system it belongs to. Mostly applied to AI-Memory machine notes (orchestrations, patterns, specs) so memory can be filtered by source product. Value is a kebab-case slug.

| Tag | Use for |
|-----|---------|
| `source/<system-slug>` | Replace `<system-slug>` with the originating system/product in kebab-case, e.g. `source/my-mcp-server` |

**Anti-patterns:**
- Do not duplicate `domain/` with `source/` - `domain/` is the business area, `source/` is the originating system/product.

---

## Namespace 7: `topic/` - free-form subject tag

Used for cross-cutting subject keywords that do not fit the closed `domain/`/`activity/` vocabularies (e.g. a specific technology or theme). Keep values kebab-case and reuse existing values before inventing new ones.

| Tag | Use for |
|-----|---------|
| `topic/ci-cd` | CI/CD pipeline subject matter |
| `topic/market-research` | Market-research subject matter |
| `topic/<subject>` | Add your own subject tags following this pattern |

**Anti-patterns:**
- Do not use `topic/` as an escape hatch for a value that belongs in `domain/` or `activity/`.
- Respect the tag-explosion rule below: a `topic/` value used on fewer than 3 notes should not be created.

---

## Namespace 8: `kind/` - deliverable / artifact kind

Classifies a note by the KIND of artifact it is, within a structured set of deliverables (e.g. a consulting engagement's outputs). Distinct from `type:` (the schema note-type) - `kind/` is a finer, domain-specific artifact label. Value is kebab-case.

| Tag | Use for |
|-----|---------|
| `kind/roadmap` | A roadmap / sequencing deliverable |
| `kind/backlog` | A gap register / backlog deliverable |
| `kind/ssot` | A single-source-of-truth reference (e.g. golden numbers) |

**Anti-patterns:**
- Do not use `kind/` to restate the `type:` field - use it only for artifact kinds the type vocabulary does not capture.

---

## Tag explosion warning

> Aim for 3-5 tags per note maximum (1 domain + 0-2 activity + 1 status + optional lifecycle).

Tag explosion symptoms:
- More than 7 tags on a single note
- Inventing a new tag for a one-off note
- Using both `activity/meeting` and `activity/brief` on the same note

**Rule:** if a tag would appear on fewer than 3 notes ever, do not create it.

---

## Retiring a tag

A tag is retired when:
1. All notes using it have been re-tagged with the correct namespace tag, or
2. The concept it represented no longer exists in the vault.

Retirement process:
1. Search vault for the tag.
2. Re-tag affected notes.
3. Add a note in `_vault-changelog.md` under the relevant date.
4. Do not delete the tag entry from this file - mark it `(retired YYYY-MM-DD)`.

---

## Quick reference

Minimal correct tag set for a new note:
```yaml
tags:
  - domain/strategy
  - activity/decision
  - status/draft
```

MOC note tag set:
```yaml
tags:
  - domain/knowledge
  - lifecycle/area
  - status/active
```
