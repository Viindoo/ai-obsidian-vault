---
title: "vault-onboarding-sync"
type: skill
domain: knowledge
status: active
tags: [domain/knowledge, activity/reference, status/active]
summary: "Skill to detect and patch drift between SETUP-NEW-MACHINE.md and the canonical infrastructure files (ETHOS.md, CLAUDE.md, AGENTS.md, GEMINI.md, hooks, skills, systemd units). Proposes targeted section updates and bumps last-verified when user confirms."
created: 2026-01-01
updated: 2026-01-01
owner: <owner>
agent: codex
---

# vault-onboarding-sync

## Description

Detects drift between `Meta/SETUP-NEW-MACHINE.md` and the canonical vault infrastructure files. Proposes targeted patch suggestions for stale sections and updates the `last-verified` frontmatter field after user confirmation.

## When to trigger

Use this skill when:
- User says "setup guide outdated" / "sync setup" / "verify setup" / "check onboarding" / "guide bị lạc hậu"
- User says "update the setup guide" / "setup guide needs update" / "check if guide is stale"
- After significant infrastructure changes (CLI version bumps, new skills added, systemd unit changed, hook patterns updated)
- GitHub Actions `setup-guide-drift.yml` flags a warning or failure
- `last-verified` in `SETUP-NEW-MACHINE.md` frontmatter is > 30 days old

Do NOT trigger for: general vault research, writing new notes, session-end capture.

## Workflow

### Step 1: Load current state of SETUP-NEW-MACHINE.md

Read `Meta/SETUP-NEW-MACHINE.md` fully. Note the current values of:
- `last-verified:` (date)
- `updated:` (date)
- `verified-on-os:` (OS version)

Calculate days since `last-verified` using today's date.

### Step 2: Read all canonical source files

Read each file in full and note key facts (version numbers, paths, commands, config blocks):

| File | Section to verify in guide |
|---|---|
| `ETHOS.md` (vault root) | Work ethos section + critical files list |
| `CLAUDE.md` (vault root) | Claude Code config, vault-specific instructions |
| `AGENTS.md` (vault root) | Codex CLI config, skill list |
| `GEMINI.md` (vault root) | Gemini CLI config, skill list |
| `.github/hooks/pre-commit` | PII hook patterns, bypass method |
| `.claude/skills/` directory listing | Skill names referenced |
| `.codex/skills/` directory listing | Skill names referenced |
| `.gemini/skills/` directory listing | Skill names referenced |

For the systemd units, check if the machine files exist:
```bash
cat ~/.config/systemd/user/obsidian-vault-push.service 2>/dev/null
cat ~/.config/systemd/user/obsidian-vault-push.timer 2>/dev/null
```

### Step 3: Diff each guide section against its source

For each section, identify one of three states:
- **IN-SYNC**: Commands, paths, versions match the canonical source
- **STALE**: A specific command, path, or version has changed
- **MISSING**: A canonical feature exists but is not documented in the guide

Build a diff report in this format:
```
SECTION: <section number and name>
STATUS: STALE | IN-SYNC | MISSING
ISSUE: <specific what changed>
PATCH: <exact replacement text or new content>
```

### Step 4: Present findings

Present the full diff report to the user. Include:
1. Summary: N sections in-sync, M stale, K missing
2. For each STALE/MISSING: the section name, issue, and proposed patch text
3. Proposed new `last-verified` date (today)
4. Proposed new `updated` date (today)

Ask the user: "Apply these patches? (yes/no/selective)"

### Step 5: Apply patches after confirmation

If user confirms (yes or selective):

For each approved patch:
1. Read `Meta/SETUP-NEW-MACHINE.md`
2. Apply the specific text replacement using Edit
3. After all patches applied, update the frontmatter:
   - `last-verified: <today>`
   - `updated: <today>`

### Step 6: Verify

After all patches are applied:
1. Re-read the `last-verified` field to confirm it was updated
2. Run a quick sanity check: `grep "last-verified" Meta/SETUP-NEW-MACHINE.md`
3. Report: "Setup guide is now in sync. last-verified: <today>"

## Output format

```
=== vault-onboarding-sync ===
Last verified: YYYY-MM-DD (N days ago)
Status: GREEN | YELLOW | RED

Sections checked: N
  IN-SYNC:  K
  STALE:    M  <- requires update
  MISSING:  P  <- new content needed

--- STALE sections ---
[1] Section name
    Issue: specific what changed
    Patch: exact replacement text

Apply all N patches? [yes/no/selective]
```

## Pitfalls

- Do not update `last-verified` without actually checking the canonical files - the date is a trust signal for future agents
- Do not batch-apply patches without user confirmation - the guide contains commands that are run on real machines
- If the guide version of a command is more specific (e.g., pinned version number), prefer the canonical source's current state unless the user says to keep the pin
- Skip sections that reference machine-local state - those cannot be verified from the vault alone

## Related

- `Meta/SETUP-NEW-MACHINE.md` - the document this skill maintains
- `.github/workflows/setup-guide-drift.yml` - CI version of drift detection
- `.github/hooks/pre-commit` - triggers drift warning on commit
