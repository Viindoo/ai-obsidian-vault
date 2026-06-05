# Setup Guide - AI Obsidian Vault

Complete step-by-step installation guide. Every step includes the exact command to run
and a verify command to confirm success before moving on.

**Time estimate:** 20-30 minutes automated + 10 minutes for manual steps.

---

## Quick checklist

- [ ] 0. Prerequisites (OS, sudo, git, node)
- [ ] 1. Get the template (clone - do NOT fork; vault must be private)
- [ ] 2. Run bootstrap: `bash bootstrap.sh`
- [ ] 3. Plugins download from official releases (installer does this); open vault in Obsidian and trust/enable
- [ ] 4. Sign in with your AI subscriptions (`claude` /login, `codex`, `gemini`) - no API keys needed
- [ ] 5. Codex: run `/hooks` in TUI to trust the SessionStart hook
- [ ] 6. GitHub: add SSH public key to your account (if using SSH auth)
- [ ] 7. Run `bash doctor.sh` and confirm all checks PASS

---

## 0. Prerequisites

**Requirements:** Ubuntu 24.04 LTS or macOS 13+. sudo access. Internet connection.

```bash
# Check OS (Linux)
lsb_release -rs
# Expected: 24.04 or 26.04

# Check sudo
sudo -n true 2>/dev/null && echo "sudo OK" || echo "sudo needs password (OK)"

# Install base tools (Linux)
sudo apt-get update -qq && sudo apt-get install -y git curl wget unzip jq build-essential flock
```

**Verify:**
```bash
git --version   # git 2.x.x
curl --version  # curl 7.x.x or 8.x.x
jq --version    # jq-1.x
```

**macOS:** Install Homebrew first if not present, then `brew install git curl jq`.

---

## 1. Get the template (do NOT fork)

Your vault holds **private** notes/memory, so it must live in a **private** repo.
A fork of a public repo is **public**, so do not fork. Instead, just clone the
template - bootstrap does this for you. The installer will create your private
vault repo (step 6 below).

> If you prefer the GitHub UI: use **"Use this template" -> Create a new private
> repository** (this makes a standalone private repo, unlike Fork). Then clone that.

---

## 2. Run bootstrap

One command downloads and runs the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Viindoo/ai-obsidian-vault/master/bootstrap.sh)
```

The installer asks a few questions:

| Question | What to enter | Example |
|---|---|---|
| Local vault path | Where the vault lives (default: `~/git/ai-obsidian-vault`) | press Enter for default |
| Git user name | Your full name for git commits | `Jane Smith` |
| Git email | Your email for git commits | `jane@example.com` |
| Create private vault repo? | `Y` -> installer runs `gh repo create --private` | press Enter (Y) |
| Private repo name | Name for YOUR vault backup repo | default `obsidian-vault` |
| OS type | `linux` or `macos` | auto-detected |
| Codex CLI? | `y` / `n` | `y` |

After answering, the installer runs automatically (~10-15 min):
- Installs Node.js if needed
- Installs Claude Code, Codex CLI, Gemini CLI
- Clones the vault to your chosen path
- Installs the PII pre-commit hook
- Renders and installs `~/.claude/CLAUDE.md`, `~/.claude/settings.json`,
  `~/.codex/config.toml`, `~/.gemini/settings.json`, `~/.gemini/trustedFolders.json`
- Installs and enables the auto-backup timer (systemd on Linux, launchd on macOS)
- Enables user linger (Linux)

**Verify:**
```bash
# All three CLIs installed
claude --version && codex --version && gemini --version

# Vault cloned
ls ~/git/ai-obsidian-vault/ETHOS.md

# Config files rendered
ls ~/.claude/CLAUDE.md && ls ~/.claude/settings.json
ls ~/.codex/config.toml
ls ~/.gemini/settings.json
```

---

## 3. Open vault in Obsidian (manual)

The community plugins are **NOT bundled** in this repo. The installer downloads
each one from its **official GitHub release** (the same source Obsidian uses),
resolved via the official `obsidianmd/obsidian-releases` registry. Only the plugin
*settings* (`data.json` - Auto Note Mover rules, Templater maps) ship with the repo.

`install.sh` runs this automatically. To (re)run it yourself:
```bash
bash ~/git/ai-obsidian-vault/scripts/install-obsidian-plugins.sh ~/git/ai-obsidian-vault
# Downloads main.js/manifest.json/styles.css from each plugin's official release
```

Then open the vault:
1. Download Obsidian from https://obsidian.md/download
2. Launch Obsidian and choose **Open folder as vault**
3. Select your vault path (default: `~/git/ai-obsidian-vault`)
4. When Obsidian prompts "Trust author of this vault?" - click **Trust and enable plugins**

**Verify plugin code was downloaded:**
```bash
ls ~/git/ai-obsidian-vault/.obsidian/plugins/dataview/main.js   # should exist
```

**Manual fallback** (if offline or a plugin failed to download): in Obsidian go to
Settings > Community plugins > Browse, and install each plugin by name. The list of
required plugins is in `.obsidian/community-plugins.json`.

---

## 4. Sign in with your AI subscriptions (manual)

This package uses your **subscription plans**, NOT API keys. Sign in to each CLI
with its own account - there is nothing to paste into a `.env` file.

| CLI | How to sign in | Plan used |
|---|---|---|
| Claude Code | run `claude`, then type `/login` | Claude Pro / Max |
| Codex CLI | run `codex`, choose "Sign in with ChatGPT" | ChatGPT Plus / Pro |
| Gemini CLI | run `gemini`, sign in with your Google account | Gemini (Google account) |

> **Important:** do NOT set `ANTHROPIC_API_KEY`. If it is set, Claude Code bills
> per-API-call instead of using your Claude Pro/Max subscription.

**For GitHub**, use OAuth (no token to paste):
```bash
gh auth login
```

**Verify each CLI is signed in:**
```bash
claude --version    # then run `claude` and confirm it does not ask for an API key
codex --version
gemini --version
```

(Only if you deliberately use pay-per-use API keys instead of a subscription:
`cp ~/git/ai-obsidian-vault/.env.example ~/.env-ai`, fill it in, and
`echo 'source ~/.env-ai' >> ~/.bashrc`. Most users skip this entirely.)

---

## 5. Trust Codex hook (manual)

Codex CLI requires interactive trust for the SessionStart hook. This cannot be automated.

```bash
# Open Codex CLI
codex

# Inside Codex, type:
/hooks
# Press Enter

# Look for the hook entry for load-context-hook.sh
# Press the key to TRUST it (usually 't' or Enter - follow the on-screen prompt)
# Exit Codex: /quit or Ctrl+C
```

**Verify:**
```bash
# After trusting, config.toml will contain a trusted_hash entry
grep "trusted_hash" ~/.codex/config.toml
# Expected: trusted_hash = "sha256:..."
```

If this entry is absent, the hook is not trusted yet - repeat the steps above.

---

## 6. Add SSH key to GitHub (manual, if using SSH auth)

If you chose SSH auth during bootstrap (recommended for automation):

```bash
# Print your public key
cat ~/.ssh/id_ed25519.pub
```

1. Copy the output.
2. Go to https://github.com/settings/ssh/new
3. Title: your machine name + date (e.g., `laptop-2026-06-05`)
4. Paste the key and save.

**Verify:**
```bash
ssh -T git@github.com
# Expected: Hi YOUR_USERNAME! You've successfully authenticated...
```

---

## 7. Run doctor (verify everything)

```bash
bash ~/git/ai-obsidian-vault/doctor.sh
```

Expected output - all checks PASS:

```
AI Vault - Post-install Doctor
================================
[PASS] Vault directory exists
[PASS] ETHOS.md present
[PASS] AI-Memory digest present
[PASS] Claude @import path resolves
[PASS] Claude settings.json hooks wired
[PASS] load-context-hook.sh runs without error
[PASS] Codex hook trusted (trusted_hash found)
[PASS] Gemini settings.json hooks wired
[PASS] Auto-backup timer active (systemd)
[PASS] Digest not stale (< 7 days)
================================
All checks passed.
```

If any check shows `[FAIL]` or `[WARN]`, the doctor prints the exact fix command to run.

---

## Post-install: first session

Start Claude Code from inside the vault:

```bash
cd ~/git/ai-obsidian-vault/vault-skeleton
claude
```

Ask: "What's in Home.md?" - Claude should give a structured answer about the vault's
MOC hierarchy (not a generic answer). This confirms the digest and ETHOS are injected.

---

## Customization

**Add your own context to Claude:**

Create `vault-skeleton/CLAUDE.local.md` (gitignored). It loads after the upstream `CLAUDE.md`:

```markdown
## My custom routing rules

- Code reviews for Python: always run mypy and pytest first
- My projects live in ~/code/
```

**Add custom skills:**

Place skill folders in `vault-skeleton/.claude/skills-local/` - these are not touched
by upstream updates.

**Change vault path:**

If you cloned to a different path, set `VAULT_PATH` in `~/.env-ai` and re-run
`wire-runtimes.sh`:

```bash
export VAULT_PATH=/your/custom/path
bash ~/git/ai-obsidian-vault/scripts/wire-runtimes.sh
```

---

## Updating to a new version

When a new release is available:

```bash
# See what changed
bash ~/git/ai-obsidian-vault/scripts/update-mechanism.sh --preview

# Apply the update (your personal data is never overwritten)
bash ~/git/ai-obsidian-vault/scripts/update-mechanism.sh
```

The update script:
1. Fetches the new release tag
2. Shows the CHANGELOG diff between your current version and the new tag
3. Creates a backup branch of your current state
4. Merges mechanism files (ETHOS, skills, scripts, templates)
5. Protects your personal data (sessions, failures, notes) via `merge=ours`
6. Re-renders home config files preserving your answers from install

---

## Troubleshooting

### Claude Code not reading vault context

**Symptom:** Claude gives generic answers not grounded in vault content.

**Fix:** Run Claude from inside the vault directory:
```bash
cd ~/git/ai-obsidian-vault/vault-skeleton && claude
```

### Codex hook silently not working

**Symptom:** No "Loading ETHOS + AI-Memory digest" message on Codex startup.

**Check:**
```bash
grep "trusted_hash" ~/.codex/config.toml
```

If empty: repeat Step 5 (run `/hooks` in Codex TUI).

### Auto-backup not running

**Linux:**
```bash
systemctl --user status obsidian-vault-push.timer
journalctl --user -u obsidian-vault-push.service -n 20
```

Common fix: `sudo loginctl enable-linger $(whoami)`

**macOS:**
```bash
launchctl list | grep ai-vault
```

Common fix: `launchctl load ~/Library/LaunchAgents/com.ai-vault.autopush.plist`

### PII hook not firing

**Symptom:** `git commit` does not show "PII scan passed".

**Fix:**
```bash
git -C ~/git/ai-obsidian-vault config core.hooksPath _local/hooks
# Then ensure _local/hooks/pre-commit exists:
cp ~/git/ai-obsidian-vault/.github/hooks/pre-commit \
   ~/git/ai-obsidian-vault/_local/hooks/pre-commit
chmod +x ~/git/ai-obsidian-vault/_local/hooks/pre-commit
```

### Digest stale or missing

**Symptom:** doctor reports "Digest stale" or Claude has outdated knowledge.

**Fix:**
```bash
cd ~/git/ai-obsidian-vault/vault-skeleton
bash _scripts/gen-memory-digest.sh "$PWD"
git add Engineering/AI-Memory/_digest.md && git commit -m "chore: refresh digest"
git push
```

---

## Manual steps summary (15% not automated)

| Step | What to do | Verify command |
|---|---|---|
| Obsidian install | Download from obsidian.md, open vault, trust plugins | `ls .obsidian/plugins/` |
| Subscription sign-in | `claude` -> `/login`; `codex` -> Sign in with ChatGPT; `gemini` -> Google account | Run each CLI; it should not ask for an API key |
| Codex hook trust | Run `codex`, type `/hooks`, trust the hook | `grep trusted_hash ~/.codex/config.toml` |
| GitHub auth | `gh auth login` (OAuth) | `gh auth status` |
