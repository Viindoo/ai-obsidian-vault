---
title: "Vault Frontmatter Schema v3"
aliases: []
type: reference
domain: knowledge
status: evergreen
tags:
  - domain/knowledge
  - activity/process
  - status/evergreen
summary: "Schema v3 canonical reference - mọi note trong vault phải tuân thủ. Dataview queries, AI agents, và Templater đều dựa vào spec này để filter relevance và sinh frontmatter chuẩn."
related: []
parent: "[[MOC-Knowledge]]"
created: 2026-04-10
updated: 2026-05-16
owner: "<YOUR_NAME>"
scope: internal
---

# Frontmatter Schema v3

> Canonical reference. Lưu tại `Meta/_system/_schema.md`. Được moved từ `Templates/_schema.md` ngày 2026-05-16.
> Mọi note trong vault phải tuân thủ schema này. Templater sinh các trường tự động; note viết tay phải bổ sung thủ công.
> Lý do tồn tại: vault là single source of truth cho cả human + AI; AI/Dataview không thể phân loại note nếu thiếu frontmatter.

---

## 1. Universal fields (BẮT BUỘC trên mọi note nghiêm túc)

| Field | Type | Mô tả | Ví dụ |
|-------|------|-------|-------|
| `title` | string (<60 chars) | Tên hiển thị ngắn gọn | `"<Your Org> Strategy 2026"` |
| `aliases` | list | Tên thay thế để tìm kiếm | `["strategy-2026", "chiến lược 2026"]` |
| `type` | enum | Loại note - quyết định folder + dashboard | xem §3 |
| `domain` | enum | Vùng business chính | xem §4 |
| `status` | enum | Trạng thái hiện tại | `active`, `draft`, `archived`, `evergreen`, `deprecated` |
| `tags` | list | 4-namespace taxonomy (xem §5) | `[domain/strategy, activity/decision, status/evergreen]` |
| `summary` | string (1-3 câu) | AI đọc field này để filter relevance trước khi đọc body | không copy-paste body - phải synthesis ngắn |
| `related` | list of wikilinks | Links tới các note liên quan | `["[[Strategy Guardrails]]"]` |
| `parent` | wikilink | MOC owner note này thuộc về | `"[[MOC-Strategy]]"` |
| `created` | YYYY-MM-DD | Ngày tạo, không đổi sau khi set | `2026-05-16` |
| `updated` | YYYY-MM-DD | Ngày cập nhật gần nhất | `2026-05-16` |
| `owner` | string | Người sở hữu/phụ trách | `<your-handle>` |
| `scope` | enum | Phạm vi chia sẻ | `internal`, `team`, `public` |

---

## 2. Conditional fields (theo `type`)

### Strategy / Decision

| type | Thêm field |
|------|------------|
| `strategy` | `confidence: high/medium/low`, `source_repo`, `source_path` (nếu migrate) |
| `decision` | `confidence`, `decided_on`, `decided_by`, `reversal_cost: low/med/high`, `blast_radius: small/medium/large`, `affects_modules: []` |

### Engineering

| type | Thêm field |
|------|------------|
| `debug` | `app_version`, `app_module`, `resolution` |
| `failure-log` | `category`, `resolution`, `resolved_on`, `tool`, `exit_code` |
| `reference` | `language` (nếu code snippet) |

### Sales

| type | Thêm field |
|------|------------|
| `customer` | `slug`, `industry`, `size: micro/sme/mid/enterprise`, `health: green/yellow/red`, `acv` |
| `deal` | `customer`, `stage: lead/qualified/proposal/closed-won/closed-lost`, `amount`, `next_step_due`, `probability` |

### Cadence

| type | Thêm field |
|------|------------|
| `daily` | `period: daily`, `date_iso` |
| `area` (weekly/monthly/quarterly) | `period`, `range_start`, `range_end`, `quarter` (nếu quarterly) |

### AI Memory (session-report / failure-log / pattern / orchestration)

| type | Thêm field |
|------|------------|
| `session-report` | `agent`, `model`, `session_id`, `outcome`, `tokens`, `duration`, `parallelism_factor` |
| `failure-log` | `agent`, `model`, `session_id`, `outcome`, `duration` |
| `pattern` | `agent` (agent that discovered the pattern) |
| `orchestration` | `agent`, `model`, `parallelism_factor`, `duration`, `outcome` |

**Optional fields applicable to AI Memory types:**

| Field | Type | Values / notes |
|-------|------|----------------|
| `agent` | enum | `claude-code`, `codex-cli`, `gemini-cli` |
| `model` | string | e.g. `haiku`, `sonnet`, `opus`, `gpt-4o`, `gemini-2.5-pro` |
| `session_id` | string | Unique session identifier (timestamp-slug or UUID) |
| `outcome` | enum | `success`, `partial`, `failure` |
| `tokens` | int | Total tokens consumed (input + output) |
| `duration` | string | Human-readable elapsed time, e.g. `"30m"`, `"1h 15m"` |
| `parallelism_factor` | int | Number of parallel sub-agents or tool calls used |

---

## 3. Type vocabulary

| Value | Dùng cho |
|-------|---------|
| `strategy` | Strategy notes, refined documents, vision/direction |
| `decision` | Engineering decision records, architectural choices |
| `meeting` | Meeting notes với agenda + action items |
| `reference` | Coding conventions, user guides, tech references |
| `moc` | Map of Content - index/hub notes |
| `template` | Template definitions (các file trong Templates/) |
| `project` | OKR, product notes với deadline/milestone |
| `area` | Ongoing responsibilities - weekly/monthly/quarterly reviews, processes |
| `daily` | Daily notes |
| `debug` | Debug investigation notes |
| `failure-log` | Failure log entries - canonical type (replaces deprecated `failure`). Non-AI engineering failures: `Engineering/Failure-Log/`. AI agent failures: `Engineering/AI-Memory/failures/`. |
| `competitor` | Competitor profiles |
| `customer` | Customer profiles |
| `session-report` | Agent self-report after a meaningful session. Path: `Engineering/AI-Memory/sessions/` |
| `failure-log` | Agent failure capture with root cause and lesson learned. Path: `Engineering/AI-Memory/failures/` |
| `pattern` | Reusable success pattern extracted from sessions. Path: `Engineering/AI-Memory/patterns/` |
| `orchestration` | Multi-step pipeline that worked, complete with sub-agent prompts. Path: `Engineering/AI-Memory/orchestrations/` |
| `profile` | Agent profile note. Describes a specific AI runtime's (Claude Code, Codex CLI, Gemini CLI) behavior, conventions, capabilities, and model-specific quirks. Used in `Engineering/AI-Memory/agent-profiles/`. |
| `research` | Research findings / survey notes - market scans, technical investigations. Path: `Resources/Research/`. |
| `design-spec` | Engineering design specification for a milestone or feature. Path: `Engineering/Specs/`. |
| `architecture-decision` | Architecture Decision Record (ADR) - a reconciled design choice with rationale and alternatives. Path: `Engineering/`. |
| `doc` | General reference document that is not a coding convention or guide (catch-all for prose docs). |
| `brief` | Strategy / decision brief prepared for a decision-maker. Path: `Strategy/Briefs/`. |

---

## 4. Domain vocabulary

| Value | Vùng |
|-------|------|
| `strategy` | Corporate strategy, GTM, vision |
| `product` | Product management, roadmap, features |
| `sales` | Sales pipeline, customers, deals |
| `marketing` | Campaigns, content, brand |
| `engineering` | Code, architecture, debugging, decisions |
| `operations` | OKRs, meetings, processes, board |
| `people` | Team, advisors, investors, partners |
| `finance` | Finance, budgeting (reserved) |
| `knowledge` | Research, competitors, market, learning |

---

## 5. Tag taxonomy v3 - 4 namespace

Mọi tag dùng tiền tố namespace. Thứ tự convention: `domain/` → `activity/` → `status/`.

### `domain/` - vùng business
`domain/strategy`, `domain/product`, `domain/sales`, `domain/marketing`, `domain/engineering`, `domain/operations`, `domain/people`, `domain/finance`, `domain/knowledge`

### `activity/` - loại hoạt động
`activity/decision`, `activity/brief`, `activity/deal`, `activity/meeting`, `activity/campaign`, `activity/competitor`, `activity/research`, `activity/debug`, `activity/failure`, `activity/okr`, `activity/digest`, `activity/process`

### `status/` - trạng thái
`status/evergreen`, `status/draft`, `status/archived`, `status/evergreen`, `status/deprecated`

### `lifecycle/` - vòng đời folder (chỉ dùng cho MOC/area notes)
`lifecycle/area`, `lifecycle/project`, `lifecycle/resource`, `lifecycle/archive`

---

## 6. Parent MOC mapping

| Note location / type | parent |
|---------------------|--------|
| Strategy files | `"[[MOC-Strategy]]"` |
| Engineering decisions/debug/failure | `"[[MOC-Engineering]]"` |
| Documentation (user guides) | `"[[MOC-Knowledge]]"` |
| Templates | `"[[MOC-Templates]]"` |
| AI Memory (session-report / failure-log / pattern / orchestration) | `"[[MOC-AI-Memory]]"` |
| Sales/deals/customers | `"[[MOC-Sales-Pipeline]]"` |
| Operations/meetings/OKRs | `"[[MOC-Operations]]"` |
| People/team/advisors | `"[[MOC-People]]"` |
| Competitors/market/research | `"[[MOC-Knowledge]]"` |

---

## 7. Scope rules

- `internal`: hầu hết files - không chia sẻ ra ngoài
- `team`: có thể share nội bộ team mở rộng
- `public`: chỉ documentation hướng dẫn sử dụng (vd `user_guide_en.md`)

---

## 8. Confidence field

Chỉ dùng cho `type: decision` và `type: strategy`:
- `high`: đã verified, dựa trên data/evidence rõ ràng
- `medium`: reasonable inference, có thể cần review
- `low`: hypothesis/draft, cần validate thêm

---

## 9. Migration notes

### Từ schema v2 (pre-2026-05-16)
- `date` → `created` (giữ giá trị gốc)
- Thêm `updated: 2026-05-16`
- Thêm `title`, `aliases`, `domain`, `parent`, `owner`, `scope`
- Tags: flat/lifecycle namespace → 4-namespace v3
- `domain/eng` → `domain/engineering`, `domain/ops` → `domain/operations`
- `lifecycle/active` → `status/evergreen` (lifecycle tag dùng riêng cho MOC)
- `summary`: rewrite thành 1-3 câu synthesis (không copy heading)

### Từ schema v1 (pre-2026-04-10)
- Như v2 + thêm `id: <slug từ filename>`
- `status: active` mặc định nếu không có field này
