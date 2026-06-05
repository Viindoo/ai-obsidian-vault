#!/usr/bin/env bash
# cc-session-start-memory.sh - SessionStart hook for Claude Code.
# Injects the single-source AI-Memory digest as additionalContext so every
# session starts with the latest curated facts + recent headlines.
# Best-effort: exits silently (no context) on machines without the vault.
set -uo pipefail

VAULT="${VAULT_PATH:-${HOME}/git/ai-obsidian-vault}"
AM="$VAULT/Engineering/AI-Memory"
DIGEST="$AM/_digest.md"

[ -d "$VAULT" ] || exit 0   # graceful on machines without the vault

# Self-heal: expose the vault's memory skills at personal scope (~/.claude/skills/)
# via symlink so they load in EVERY Claude Code session regardless of cwd. SSOT
# stays in the vault git repo; this only (re)creates symlinks. Idempotent + silent
# (MUST NOT write to stdout - that channel carries the digest JSON emitted below).
if [ -d "$VAULT/.claude/skills" ]; then
  mkdir -p "$HOME/.claude/skills" 2>/dev/null || true
  for _sk in "$VAULT"/.claude/skills/*/; do
    ln -sfn "${_sk%/}" "$HOME/.claude/skills/$(basename "$_sk")" 2>/dev/null || true
  done
fi

# Read the committed digest as-is - do NOT regenerate here (regen on every
# session would churn the timestamp header into a commit each time). Freshness
# is handled by the GitHub Actions regen on memory-file pushes + the write skills.
[ -f "$DIGEST" ] || exit 0

# Carryover check: prior sessions that ended without a vault-session-end capture.
CARRY=""
SENT="$VAULT/.local-state/last-session-stop.txt"
if [ -f "$SENT" ]; then
  N=$(grep -c "status:unprocessed" "$SENT" 2>/dev/null || echo 0)
  [ "$N" -gt 0 ] 2>/dev/null && \
    CARRY="NOTE: ${N} prior session(s) ended without vault-session-end capture - consider running it."
fi

# Emit JSON additionalContext (python for safe escaping; cap ~10000 chars).
DIGEST="$DIGEST" CARRY="$CARRY" python3 - <<'PY'
import json, os
digest = open(os.environ["DIGEST"], encoding="utf-8", errors="replace").read()[:10000]
carry = os.environ.get("CARRY", "")
ctx = digest + (("\n\n" + carry) if carry else "")
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ctx,
}}))
PY
exit 0
