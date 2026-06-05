#!/usr/bin/env bash
# SessionStart context loader for Codex CLI + Gemini CLI.
#
# Emits a JSON `additionalContext` payload so each runtime injects the vault
# ETHOS + AI-Memory digest into model context on every session. This is the
# native equivalent of Claude Code's `@import ETHOS.md` + SessionStart digest
# hook -- needed because Codex has no @import at all, and Gemini rejects
# absolute-path @import ("Path traversal attempt"). Both runtimes DO honor a
# SessionStart command hook whose stdout is `{hookSpecificOutput.additionalContext}`.
#
# SSOT:
#   - ETHOS.md                         -> universal work ethos + output conventions
#   - Engineering/AI-Memory/_digest.md -> always-load curated memory (core + recent)
#
# Verify: Codex -> run `/hooks` in the TUI once to trust this hook.
#         Gemini -> `/memory show` (or `DEBUG=1 gemini -p ...`) should show the content.
set -euo pipefail

# Guard: exit cleanly if vault not yet set up (e.g. mid-install).
# Resolve VAULT dynamically: 3 levels up from _scripts/ = vault root.
# Override by setting VAULT_PATH env var before calling this script.
VAULT="${VAULT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -f "$VAULT/ETHOS.md" ] || exit 0

cat "$VAULT/ETHOS.md" "$VAULT/Engineering/AI-Memory/_digest.md" \
  | jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}'
