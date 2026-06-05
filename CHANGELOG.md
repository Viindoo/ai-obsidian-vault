# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Tu tao PRIVATE repo backup cho vault cua member.** install.sh nay offer
  `gh repo create <ten> --private --source --push` (default ten `obsidian-vault`,
  cho xac nhan/doi) -> member co private repo rieng + auto-backup giong setup vault
  ca nhan, KHONG can tao tay tu truoc. Tu set `upstream = Viindoo/ai-obsidian-vault`
  de `update-mechanism.sh` nhan update co che. Neu origin dang tro template cong
  khai -> tu chuyen thanh 'upstream' (khong day vault private len repo public).
  Bo huong dan "fork" trong README/SETUP-GUIDE/bootstrap (fork cua public repo
  cung public -> lo ghi chu ca nhan); thay bang clone + installer-tao-private hoac
  "Use this template -> private".

### Changed

- **Obsidian plugin: cai theo CO CHE CHINH THUC, khong bundle binary.** Truoc day
  repo bundle ~20MB code plugin (main.js/manifest.json/styles.css x 11) copy tu may
  owner - vua la "hack" vua redistribute code ben thu 3. Nay: code plugin tai tu
  GitHub RELEASE CHINH THUC cua tung plugin (resolve id -> repo qua registry chinh
  thuc obsidianmd/obsidian-releases) bang `scripts/install-obsidian-plugins.sh`
  (chay tu dong trong install.sh, graceful neu offline). Repo chi giu
  `community-plugins.json` (danh sach) + `data.json` (config cua ta). Plugin code
  duoc gitignore. doctor.sh kiem code plugin da tai chua + goi y cai lai.

### Added

- **Collision-safety khi may da co setup AI-vault khac.** Config HOME (~/.claude,
  ~/.codex, ~/.gemini) dung chung moi vault nen cai dat co the de/redirect setup
  cu. Nay `wire-runtimes.sh`: (1) PREFLIGHT phat hien config dang tro vault khac
  -> canh bao + liet ke + yeu cau xac nhan (bo qua: `AI_VAULT_ASSUME_YES=1` /
  non-tty); (2) BACKUP `*.bak-<timestamp>` truoc moi overwrite (CLAUDE.md, hooks,
  settings.json, codex/gemini config, systemd unit) - khoi phuc duoc; (3) systemd
  unit doi ten `obsidian-vault-push` -> `ai-vault-push` (+ lock rieng) de KHONG
  bao gio de/cuop auto-backup vault khac dang chay; (4) `AI_VAULT_SKIP_SYSTEMD=1`
  bo qua enable/start systemd (dung cho test cach ly).

### Changed

- Default `VAULT_PATH`: `~/git/ai-vault` -> `~/git/ai-obsidian-vault` (install.sh,
  init-vault.sh, wire-runtimes.sh, doctor.sh).

- **Auth model: subscription-based, not API keys.** Setup now signs in to each CLI
  with its subscription account (Claude Pro/Max via `/login`, Codex via "Sign in
  with ChatGPT", Gemini via Google account). Removed the `env` block injecting
  `ANTHROPIC_API_KEY` from `templates-home/claude/settings.json.tmpl` - injecting
  it forced per-API-call billing instead of using the subscription. `.env.example`,
  `install.sh`, `doctor.sh`, `README.md`, and `docs/SETUP-GUIDE.md` updated; API
  keys are now an explicitly optional path for pay-per-use users only.

---

## [1.0.0] - 2026-06-05

### Added

- **Vault skeleton** (`vault-skeleton/`): pre-structured Obsidian vault with PARA-LYT hybrid
  folder layout (Strategy, Product, Sales, Marketing, Engineering, Operations, People, Resources,
  Inbox, Daily, Projects, Archive, Templates, Meta).
- **AI-Memory system** (`vault-skeleton/Engineering/AI-Memory/`): cross-session memory bridge
  for Claude Code, Codex CLI, and Gemini CLI. Includes digest injection, sentinel carryover
  detection, and GitHub Actions auto-regen workflow.
- **ETHOS.md**: 11 universal work principles for AI agents (Boil the Lake, Think Before Acting,
  Keep Simple, Outcomes over Procedures, Search Before Building, Iron Law of Root Cause,
  See Something Say Something, Completion Status, Build for Audience, Artifact Production
  Principles, Test the Behavior Not the Code).
- **Home config templates** (`templates-home/`): parameterized templates for all three AI
  runtimes:
  - Claude Code: `CLAUDE.md.tmpl`, `settings.json.tmpl`, `cc-session-start-memory.sh`,
    `session-end-prompt.sh`
  - Codex CLI: `config.toml.tmpl` with SessionStart + Stop hooks
  - Gemini CLI: `settings.json.tmpl`, `trustedFolders.json.tmpl`
  - Linux systemd: `obsidian-vault-push.service.tmpl`, `obsidian-vault-push.timer.tmpl`
  - macOS launchd: `com.ai-vault.autopush.plist.tmpl`
- **PII pre-commit hook** (`.github/hooks/pre-commit`): blocks commits containing CCCD/CMND,
  bulk phone numbers, IBAN, bank accounts, API keys, GitHub tokens, private keys,
  personal emails. Configurable company/customer denylist via `VAULT_PII_DENYLIST` env var.
  Drift warning when critical infrastructure files change without updating the setup guide.
- **GitHub Actions**:
  - `regen-ai-memory-index.yml`: auto-regenerates `_index/` + `_digest.md` after memory pushes.
  - `publish-gate.yml`: CI denylist check - blocks merges containing confidential terms.
- **Bootstrap entry point** (`bootstrap.sh`): single-command setup via `bash bootstrap.sh`.
- **Install scripts** (`install.sh`, `scripts/init-vault.sh`, `scripts/wire-runtimes.sh`):
  guided 6-question prompt, idempotent install, separate vault-layer and home-config-layer.
- **Doctor script** (`doctor.sh`): post-install verification with PASS/FAIL table for Claude
  `@import` path, Codex trusted_hash, `load-context-hook.sh` smoke test, systemd/launchd
  timer status, and digest freshness.
- **`.env.example`**: documented environment variable template with auth guidance.
- **`.gitattributes`**: LF normalization for all scripts and config files.
- **`docs/SETUP-GUIDE.md`**: step-by-step installation guide with per-step verify commands
  and 15% manual checklist.

[1.0.0]: https://github.com/your-org/ai-obsidian-vault/releases/tag/v1.0.0
