# AI Obsidian Vault - Second Brain for AI Agents

Turn your Obsidian vault into a persistent memory layer shared across three AI coding
assistants: Claude Code, Codex CLI, and Gemini CLI. Every session starts with your
curated knowledge. Every important decision, pattern, and failure gets captured and
surfaced the next time you need it.

---

## What you get

- **Obsidian vault** with a structured knowledge layout (strategy, engineering, sales, etc.)
- **AI-Memory system**: cross-session digest injected automatically into all three AI runtimes
- **11 work principles (ETHOS)** loaded into every AI session to guide behavior
- **Auto-backup** to GitHub every 30 minutes (systemd on Linux, launchd on macOS)
- **PII protection** via pre-commit hook blocking secrets, tokens, and personal data
- **Single setup command** - one script wires everything

---

## Quick start

```bash
# 1. Clone the template (do NOT fork - a fork of a public repo is public; your
#    vault holds private notes). The installer creates a PRIVATE repo for you.
bash <(curl -fsSL https://raw.githubusercontent.com/Viindoo/ai-obsidian-vault/master/bootstrap.sh)

# 2. Follow the guided prompt. The installer will offer to create a PRIVATE GitHub
#    repo for your vault (gh repo create --private) and set the template as 'upstream'
#    for mechanism updates - same setup as a personal second-brain vault.

# 3. Verify everything works:
bash ~/git/ai-obsidian-vault/doctor.sh

# 4. Complete the 15% manual steps (see docs/SETUP-GUIDE.md):
#    - Community plugins are downloaded from their official GitHub releases by the
#      installer (not bundled); then open the vault in Obsidian and enable them when prompted
#    - Run `codex` and type /hooks to trust the SessionStart hook
#    - Sign in with your AI subscriptions (no API keys needed):
#        claude -> /login (Claude Pro/Max) | codex -> Sign in with ChatGPT | gemini -> Google account
```

For full instructions with per-step verify commands, see **[docs/SETUP-GUIDE.md](docs/SETUP-GUIDE.md)**.

---

## Architecture

```
ai-obsidian-vault/
+-- vault-skeleton/          # Your Obsidian vault content (pre-structured)
|   +-- ETHOS.md             # 11 AI agent work principles (upstream-owned)
|   +-- Engineering/
|   |   +-- AI-Memory/       # Cross-session memory (sessions, failures, patterns)
|   |       +-- _digest.md   # Injected into every AI session at startup
|   +-- Meta/Home.md         # Entry point for AI traversal
|   +-- Inbox/               # Quick capture, auto-filed by tag
|   +-- [7 domain folders]   # Strategy, Product, Sales, Marketing, Ops, People, Resources
+-- templates-home/          # Config templates rendered during setup
|   +-- claude/              # CLAUDE.md, settings.json, hooks
|   +-- codex/               # config.toml with SessionStart + Stop hooks
|   +-- gemini/              # settings.json, trustedFolders.json
|   +-- systemd/             # Linux auto-backup timer
|   +-- launchd/             # macOS auto-backup launchd plist
+-- scripts/                 # init-vault.sh, wire-runtimes.sh, sanitize-template.sh
+-- .github/
|   +-- hooks/pre-commit     # PII scan hook (install to _local/hooks/)
|   +-- workflows/           # regen-ai-memory-index, publish-gate CI
+-- bootstrap.sh             # Entry point: download + launch install.sh
+-- install.sh               # Orchestrator: guided prompt + calls init + wire
+-- doctor.sh                # Post-install verification: PASS/FAIL table
+-- docs/SETUP-GUIDE.md      # Full manual with per-step verify commands
```

### How context injection works

| Runtime | Mechanism | What gets injected |
|---|---|---|
| **Claude Code** | `@import` in `~/.claude/CLAUDE.md` | ETHOS.md (every turn) |
| **Claude Code** | SessionStart hook | AI-Memory digest (cap 10,000 chars) |
| **Codex CLI** | SessionStart hook (`load-context-hook.sh`) | ETHOS + digest combined |
| **Gemini CLI** | SessionStart hook (`load-context-hook.sh`) | ETHOS + digest combined |

All three runtimes write a sentinel entry on session end. The next session detects
unprocessed sessions and prompts you to run `vault-session-end`.

---

## Supported runtimes

| Runtime | Install | Version tested |
|---|---|---|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | Latest |
| Codex CLI | `npm install -g @openai/codex` | 0.125.0+ |
| Gemini CLI | `npm install -g @google/gemini-cli` | Latest |

---

## Keeping your vault up to date

When a new version of this template is released:

```bash
bash ~/git/ai-obsidian-vault/scripts/update-mechanism.sh
```

This fetches the new tag, shows the changelog diff, and merges mechanism files
(ETHOS, skills, scripts, hooks). Your personal data (sessions, failures, notes)
is protected by `.gitattributes merge=ours` and is never overwritten.

---

## Customization

- **Override ETHOS/CLAUDE for your context**: create `vault-skeleton/CLAUDE.local.md`
  (gitignored). It is loaded after the upstream CLAUDE.md.
- **Add custom skills**: place them in `vault-skeleton/.claude/skills-local/`
  (not touched by upstream updates).
- **Add custom routing rules**: add them to `CLAUDE.local.md` - they append to
  the dispatch tree without conflicting with upstream updates.

---

## License

See [LICENSE](LICENSE).
