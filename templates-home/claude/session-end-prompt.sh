#!/usr/bin/env bash
# session-end-prompt.sh - SessionStop hook for Claude Code
# Appends a sentinel entry to <vault>/.local-state/last-session-stop.txt
# Used by vault-session-start to detect unprocessed sessions from prior runs.
# All fields: ISO 8601 timestamp | session-id | last-vault-commit-rel | cwd
#
# Shared sentinel file: also written by Codex/Gemini equivalent hooks.
# Session-start skill reads this file to prompt carryover.

VAULT="${VAULT_PATH:-${HOME}/git/ai-obsidian-vault}"
SENTINEL_DIR="${VAULT}/.local-state"
SENTINEL_FILE="${SENTINEL_DIR}/last-session-stop.txt"

# Idempotent: silently exit if vault path does not exist
if [ ! -d "${VAULT}" ]; then
  exit 0
fi

# Ensure sentinel dir exists
mkdir -p "${SENTINEL_DIR}" 2>/dev/null || true

# Gather fields
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${CLAUDE_SESSION_ID:-${ANTHROPIC_SESSION_ID:-unknown}}"
CWD="${PWD:-unknown}"

# Last vault commit relative time (e.g. "3 hours ago") - graceful fallback
LAST_COMMIT_REL=$(git -C "${VAULT}" log -1 --format="%ar" 2>/dev/null || echo "unknown")

# Append sentinel line (format: tab-separated for easy parsing)
printf "%s\tagent:claude-code\tsession:%s\tlast-commit:%s\tcwd:%s\tstatus:unprocessed\n" \
  "${TIMESTAMP}" \
  "${SESSION_ID}" \
  "${LAST_COMMIT_REL}" \
  "${CWD}" \
  >> "${SENTINEL_FILE}" 2>/dev/null || true

exit 0
