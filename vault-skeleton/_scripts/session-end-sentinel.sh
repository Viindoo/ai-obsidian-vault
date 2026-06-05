#!/usr/bin/env bash
# session-end-sentinel.sh <agent> - shared SessionEnd/Stop reminder for all runtimes.
#
# Appends an "unprocessed session" sentinel line to the shared carryover file that
# vault-session-start (and the CC SessionStart hook) reads, so the NEXT session of
# ANY runtime is reminded that a prior session ended without a vault-session-end
# capture. A hook CANNOT summarize (no model) - this is the enforce-by-harness
# REMINDER half; the content capture itself is agent-driven via ai-memory-write.sh.
#
# Generalizes the original Claude-Code-only ~/.claude/hooks/session-end-prompt.sh so
# Codex (Stop hook) and Gemini (SessionEnd hook) write the SAME sentinel with their
# own agent tag. Wire it as the hook command, e.g.:
#   Gemini ~/.gemini/settings.json  hooks.SessionEnd -> "<vault>/_scripts/session-end-sentinel.sh gemini-cli"
#   Codex  plugin hooks.json        Stop             -> "<vault>/_scripts/session-end-sentinel.sh codex-cli"
AGENT="${1:-unknown}"

# Resolve VAULT dynamically: 3 levels up from _scripts/ = vault root.
# Override by setting VAULT_PATH env var before calling this script.
VAULT="${VAULT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

SENTINEL_DIR="${VAULT}/.local-state"
SENTINEL_FILE="${SENTINEL_DIR}/last-session-stop.txt"

[ -d "$VAULT" ] || exit 0   # graceful on machines without the vault
mkdir -p "$SENTINEL_DIR" 2>/dev/null || true

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SID="${CLAUDE_SESSION_ID:-${GEMINI_SESSION_ID:-${CODEX_SESSION_ID:-unknown}}}"
REL=$(git -C "$VAULT" log -1 --format="%ar" 2>/dev/null || echo unknown)
printf "%s\tagent:%s\tsession:%s\tlast-commit:%s\tcwd:%s\tstatus:unprocessed\n" \
  "$TS" "$AGENT" "$SID" "$REL" "${PWD:-unknown}" >> "$SENTINEL_FILE" 2>/dev/null || true
exit 0
