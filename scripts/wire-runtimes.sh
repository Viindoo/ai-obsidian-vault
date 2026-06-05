#!/usr/bin/env bash
# =============================================================================
# wire-runtimes.sh - Lop B: Wire context-loading cho 3 AI runtime
# =============================================================================
# Chay sau init-vault.sh (de _digest.md da ton tai).
# Cac bien VAULT_PATH, YOUR_NAME, YOUR_EMAIL, COMPANY_NAME, ENABLE_CODEX,
# ENABLE_GEMINI, OLLAMA_ENDPOINT, OS_TYPE phai duoc export truoc (qua install.sh)
# hoac co trong .install-answers.
#
# Lam gi:
#   [Claude] CLAUDE.md + cc-session-start-memory.sh + session-end-prompt.sh
#            + settings.json merge (hooks + autoMemoryDirectory)
#   [Codex]  config.toml merge (SessionStart + Stop hooks + mcp filesystem)
#   [Gemini] settings.json merge (SessionStart + SessionEnd)
#            + trustedFolders.json + projects.json
#   [systemd/launchd] auto-backup timer
# Idempotent.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Mau sac helpers
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*" >&2; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
die()  { fail "$*"; exit 1; }

# Timestamp dung cho moi backup trong lan chay nay
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"

# Backup 1 file/symlink TRUOC khi ghi de (chi khi file ton tai).
# Tao ban sao <file>.bak-<timestamp> de co the khoi phuc setup cu.
_backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local bak="${target}.bak-${BACKUP_TS}"
    cp -P "$target" "$bak" 2>/dev/null && info "Backup: $target -> $(basename "$bak")"
  fi
}

# ---------------------------------------------------------------------------
# Lay bien moi truong tu .install-answers neu chua co
# ---------------------------------------------------------------------------
ANSWERS_FILE="${REPO_ROOT}/.install-answers"

_read_answer() {
  local key="$1" default="${2:-}"
  local val
  val="$(grep "^${key}=" "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2- || echo "")"
  echo "${val:-$default}"
}

VAULT_PATH="${VAULT_PATH:-$(_read_answer "VAULT_PATH" "$HOME/git/ai-obsidian-vault")}"
YOUR_NAME="${YOUR_NAME:-$(_read_answer "YOUR_NAME")}"
YOUR_EMAIL="${YOUR_EMAIL:-$(_read_answer "YOUR_EMAIL")}"
ENABLE_CODEX="${ENABLE_CODEX:-$(_read_answer "ENABLE_CODEX" "y")}"
ENABLE_GEMINI="${ENABLE_GEMINI:-$(_read_answer "ENABLE_GEMINI" "y")}"
OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-$(_read_answer "OLLAMA_ENDPOINT" "")}"
OS_TYPE="${OS_TYPE:-linux}"

[[ -z "$VAULT_PATH" ]] && die "VAULT_PATH khong duoc de trong. Chay install.sh truoc."

TEMPLATES_DIR="${REPO_ROOT}/templates-home"

echo ""
echo -e "${BOLD}[wire-runtimes] Wire AI runtime config...${RESET}"
echo "  VAULT_PATH = $VAULT_PATH"

# ---------------------------------------------------------------------------
# PREFLIGHT: phat hien setup CU dang tro toi vault KHAC
# Config HOME (~/.claude, ~/.codex, ~/.gemini) dung CHUNG cho moi vault. Neu may
# da co setup tro toi vault khac, wire se redirect 3 runtime sang vault nay.
# Canh bao + xac nhan truoc khi dong gi (co backup, nhung redirect la co y).
# Bo qua xac nhan: AI_VAULT_ASSUME_YES=1 hoac stdin khong phai tty.
# ---------------------------------------------------------------------------
_existing_vault_of() {
  # In ra path vault ma 1 file config dang tro toi (best-effort), hoac rong.
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -oE '/[^[:space:]"]*/(ETHOS\.md|_scripts|Engineering/AI-Memory)' "$f" 2>/dev/null \
    | head -1 | sed -E 's#/(ETHOS\.md|_scripts|Engineering/AI-Memory)$##'
}

CONFLICTS=()
for cfg in "$HOME/.claude/CLAUDE.md" "$HOME/.claude/hooks/cc-session-start-memory.sh" \
           "$HOME/.codex/config.toml" "$HOME/.gemini/settings.json"; do
  ev="$(_existing_vault_of "$cfg")"
  if [[ -n "$ev" && "$(realpath -m "$ev" 2>/dev/null)" != "$(realpath -m "$VAULT_PATH" 2>/dev/null)" ]]; then
    CONFLICTS+=("$cfg -> $ev")
  fi
done
# systemd unit cu (ten khac: obsidian-vault-push) - chi canh bao, KHONG dong (unit moi ten rieng)
if [[ -f "$HOME/.config/systemd/user/obsidian-vault-push.service" ]]; then
  CONFLICTS+=("systemd obsidian-vault-push.service (giu nguyen - unit moi co ten rieng ai-vault-push)")
fi

if (( ${#CONFLICTS[@]} > 0 )); then
  echo ""
  warn "Phat hien setup AI-vault DA TON TAI tren may, dang tro toi vault KHAC:"
  for c in "${CONFLICTS[@]}"; do echo -e "    ${YELLOW}- ${c}${RESET}"; done
  echo ""
  echo -e "  ${BOLD}Tiep tuc se:${RESET}"
  echo "    - Backup file cu thanh *.bak-${BACKUP_TS} (co the khoi phuc)"
  echo "    - Redirect Claude/Codex/Gemini sang: $VAULT_PATH"
  echo "    - Tao systemd timer RIENG 'ai-vault-push' (KHONG dong 'obsidian-vault-push' cu)"
  echo ""
  if [[ "${AI_VAULT_ASSUME_YES:-}" == "1" ]] || [[ ! -t 0 ]]; then
    warn "Bo qua xac nhan (AI_VAULT_ASSUME_YES=1 hoac non-tty) - tiep tuc."
  else
    echo -n -e "  ${BOLD}Tiep tuc redirect sang vault moi? (y/N): ${RESET}"
    read -r _confirm
    [[ "$_confirm" == "y" || "$_confirm" == "Y" ]] || die "Da huy. Setup cu giu nguyen."
  fi
fi

# ---------------------------------------------------------------------------
# Helper: merge JSON vao file hien co (dung jq)
# Ghi de key bi thay the, cac key con lai giu nguyen.
# $1 = file.json, $2 = json_patch string
# ---------------------------------------------------------------------------
_jq_merge_file() {
  local target="$1" patch="$2"
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$target" ]]; then
    jq -s '.[0] * .[1]' "$target" <(echo "$patch") > "$tmp"
  else
    echo "$patch" | jq '.' > "$tmp"
  fi
  mv "$tmp" "$target"
}

# Helper: render file tu template.
# Ho tro 2 kieu placeholder:
#   ${VAULT_PATH}, ${HOME}  -> dung envsubst (templates-home cua agent khac)
#   __VAULT__, __HOME__     -> dung sed (systemd templates + .github/scripts/)
# Logic: neu template chua ${VAULT_PATH} dung envsubst, neu chua __VAULT__ dung sed, hieu ca hai.
_render_template_sed() {
  local src="$1" dest="$2"
  local tmp
  tmp="$(mktemp)"

  # Buoc 1: xu ly ${VAULT_PATH}/${HOME} bang envsubst (an toan voi path co ky tu dac biet)
  # Chi export cac bien can thiet de tranh envsubst replace bien khac
  VAULT_PATH="$VAULT_PATH" HOME="$HOME" \
    envsubst '${VAULT_PATH} ${HOME}' < "$src" > "$tmp"

  # Buoc 2: xu ly __VAULT__/__HOME__ bang sed (cho systemd templates)
  local vault_escaped home_escaped
  vault_escaped="$(printf '%s\n' "$VAULT_PATH" | sed 's|[&\\/]|\\&|g')"
  home_escaped="$(printf '%s\n' "$HOME" | sed 's|[&\\/]|\\&|g')"
  sed \
    -e "s|__VAULT__|${vault_escaped}|g" \
    -e "s|__HOME__|${home_escaped}|g" \
    "$tmp" > "$dest"
  rm -f "$tmp"
}

# ===========================================================================
# PHAN A: CLAUDE CODE
# ===========================================================================
echo ""
echo -e "${BOLD}--- Claude Code ---${RESET}"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR" "$CLAUDE_HOOKS_DIR"

# --- A1. ~/.claude/CLAUDE.md ---
# Render absolute @import path (khong expand env var, phai la absolute path)
CLAUDE_MD_DEST="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_MD_TMPL="${TEMPLATES_DIR}/claude/CLAUDE.md.tmpl"

_backup_if_exists "$CLAUDE_MD_DEST"
if [[ -f "$CLAUDE_MD_TMPL" ]]; then
  # CLAUDE.md.tmpl dung ${VAULT_PATH} cho @import - phai la absolute path sau render
  VAULT_PATH="$VAULT_PATH" HOME="$HOME" \
    envsubst '${VAULT_PATH} ${HOME}' < "$CLAUDE_MD_TMPL" > "$CLAUDE_MD_DEST"
  ok "~/.claude/CLAUDE.md: render tu template (envsubst VAULT_PATH)"
else
  # Fallback: tao CLAUDE.md co @import dong truc tiep
  warn "${CLAUDE_MD_TMPL} khong tim thay - tao CLAUDE.md toi gian"
  cat > "$CLAUDE_MD_DEST" <<HEREDOC
# Claude Code - AI Vault

## Vault path
VAULT_PATH=${VAULT_PATH}

## Mandatory context (auto-loaded moi session)

@${VAULT_PATH}/ETHOS.md

---

## Vault Instructions

See project-level CLAUDE.md at ${VAULT_PATH}/CLAUDE.md for vault-specific instructions.

## Override (optional)

If exists, loaded after mechanism context:
<!-- @${VAULT_PATH}/CLAUDE.local.md -->
HEREDOC
  # Note: dong CLAUDE.local.md comment out de khong loi neu file chua ton tai
  ok "~/.claude/CLAUDE.md: tao fallback (co @import ETHOS.md)"
fi

# Verify @import path ton tai
if [[ -f "${VAULT_PATH}/ETHOS.md" ]]; then
  ok "@import target ton tai: ${VAULT_PATH}/ETHOS.md"
else
  warn "ETHOS.md chua ton tai tai ${VAULT_PATH}/ETHOS.md - se can sau khi vault co noi dung"
fi

# --- A2. cc-session-start-memory.sh ---
# Hook nay dung runtime env var ${VAULT_PATH:-...} khong can render static
# Chi copy truc tiep (khong envsubst) de giu bash default syntax nguyen ven
CC_START_TMPL="${TEMPLATES_DIR}/claude/cc-session-start-memory.sh"
CC_START_DEST="${CLAUDE_HOOKS_DIR}/cc-session-start-memory.sh"

_backup_if_exists "$CC_START_DEST"
if [[ -f "$CC_START_TMPL" ]]; then
  cp "$CC_START_TMPL" "$CC_START_DEST"
  chmod +x "$CC_START_DEST"
  ok "~/.claude/hooks/cc-session-start-memory.sh: copy tu template (runtime env var)"
else
  warn "${CC_START_TMPL} khong tim thay - tao cc-session-start-memory.sh truc tiep"
  cat > "$CC_START_DEST" <<PYEOF
#!/usr/bin/env bash
# SessionStart hook cho Claude Code - inject _digest.md vao context
# Auto-generated boi wire-runtimes.sh - KHONG sua tay (se ghi de khi update)

set -uo pipefail

VAULT="${VAULT_PATH}"
AM="\$VAULT/Engineering/AI-Memory"
DIGEST="\$AM/_digest.md"

# Graceful exit neu vault khong ton tai
[ -d "\$VAULT" ] || exit 0

# Self-heal symlinks: vault/.claude/skills/* -> ~/.claude/skills/*
SKILLS_SRC="\$VAULT/.claude/skills"
SKILLS_DEST="\$HOME/.claude/skills"
if [ -d "\$SKILLS_SRC" ]; then
  mkdir -p "\$SKILLS_DEST"
  for skill_dir in "\$SKILLS_SRC"/*/; do
    [ -d "\$skill_dir" ] || continue
    skill_name="\$(basename "\$skill_dir")"
    ln -sfn "\$skill_dir" "\$SKILLS_DEST/\$skill_name" 2>/dev/null || true
  done
fi

# Graceful exit neu digest khong ton tai
[ -f "\$DIGEST" ] || exit 0

# Carryover check: dem session chua xu ly
SENTINEL_FILE="\$VAULT/.local-state/last-session-stop.txt"
CARRYOVER_NOTE=""
if [ -f "\$SENTINEL_FILE" ]; then
  N=\$(grep -c "status:unprocessed" "\$SENTINEL_FILE" 2>/dev/null || echo "0")
  if [ "\$N" -gt 0 ]; then
    CARRYOVER_NOTE="NOTE: \$N session(s) chua log vao AI-Memory. Chay vault-session-end hoac vault-failure-log neu can."
  fi
fi

# Doc digest (cap 10000 chars)
DIGEST_CONTENT=\$(head -c 10000 "\$DIGEST" 2>/dev/null || echo "")

# Emit JSON voi python3 (xu ly escape an toan)
python3 - <<PYSCRIPT
import json, sys
content = """
\$DIGEST_CONTENT
"""
if """
\$CARRYOVER_NOTE
""".strip():
    content += "\n\n---\n\${CARRYOVER_NOTE}\n"
output = {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": content}}
print(json.dumps(output))
PYSCRIPT
PYEOF
  chmod +x "$CC_START_DEST"
  ok "~/.claude/hooks/cc-session-start-memory.sh: tao truc tiep"
fi

# --- A3. session-end-prompt.sh ---
# Tuong tu cc-session-start-memory.sh: dung runtime env var, copy truc tiep
CC_END_TMPL="${TEMPLATES_DIR}/claude/session-end-prompt.sh"
CC_END_DEST="${CLAUDE_HOOKS_DIR}/session-end-prompt.sh"

_backup_if_exists "$CC_END_DEST"
if [[ -f "$CC_END_TMPL" ]]; then
  cp "$CC_END_TMPL" "$CC_END_DEST"
  chmod +x "$CC_END_DEST"
  ok "~/.claude/hooks/session-end-prompt.sh: copy tu template (runtime env var)"
else
  warn "${CC_END_TMPL} khong tim thay - tao session-end-prompt.sh truc tiep"
  cat > "$CC_END_DEST" <<'ENDSH'
#!/usr/bin/env bash
# SessionEnd/Stop hook cho Claude Code - ghi sentinel
# Auto-generated boi wire-runtimes.sh

set -uo pipefail
ENDSH
  # Them noi dung voi VAULT_PATH da expand
  cat >> "$CC_END_DEST" <<ENDSH2
VAULT="${VAULT_PATH}"
SENTINEL_DIR="\${VAULT}/.local-state"
SENTINEL_FILE="\${SENTINEL_DIR}/last-session-stop.txt"

[ -d "\$VAULT" ] || exit 0
mkdir -p "\$SENTINEL_DIR"

SESSION_ID="\${CLAUDE_SESSION_ID:-\${ANTHROPIC_SESSION_ID:-unknown}}"
LAST_COMMIT="\$(git -C "\$VAULT" log -1 --format='%cr' 2>/dev/null || echo 'no-commit')"
TIMESTAMP="\$(date -Iseconds)"

echo "\${TIMESTAMP}\tagent:claude-code\tsession:\${SESSION_ID}\tlast-commit:\${LAST_COMMIT}\tcwd:\${PWD}\tstatus:unprocessed" >> "\$SENTINEL_FILE"
ENDSH2
  chmod +x "$CC_END_DEST"
  ok "~/.claude/hooks/session-end-prompt.sh: tao truc tiep"
fi

# --- A4. ~/.claude/settings.json merge ---
CC_SETTINGS="$CLAUDE_DIR/settings.json"
CC_SETTINGS_TMPL="${TEMPLATES_DIR}/claude/settings.json.tmpl"

if [[ -f "$CC_SETTINGS_TMPL" ]]; then
  # Render template: chi expand VAULT_PATH va HOME. KHONG inject API key vao
  # settings.json - Claude Code dung goi subscription (login qua /login).
  RENDERED_SETTINGS="$(mktemp)"
  VAULT_PATH="$VAULT_PATH" HOME="$HOME" \
    envsubst '${VAULT_PATH} ${HOME}' < "$CC_SETTINGS_TMPL" > "$RENDERED_SETTINGS"
  # Merge vao settings hien co
  if [[ -f "$CC_SETTINGS" ]]; then
    _backup_if_exists "$CC_SETTINGS"
    jq -s '.[0] * .[1]' "$CC_SETTINGS" "$RENDERED_SETTINGS" > "${CC_SETTINGS}.tmp"
    mv "${CC_SETTINGS}.tmp" "$CC_SETTINGS"
    ok "~/.claude/settings.json: merged tu template"
  else
    cp "$RENDERED_SETTINGS" "$CC_SETTINGS"
    ok "~/.claude/settings.json: tao moi tu template"
  fi
  rm -f "$RENDERED_SETTINGS"
else
  warn "${CC_SETTINGS_TMPL} khong tim thay - merge hooks toi gian vao settings.json"
  # Tao patch JSON co hooks + autoMemoryDirectory
  HOOKS_PATCH="$(cat <<JSONPATCH
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_HOOKS_DIR}/cc-session-start-memory.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_HOOKS_DIR}/session-end-prompt.sh"
          }
        ]
      }
    ]
  },
  "autoMemoryDirectory": "${VAULT_PATH}/Engineering/AI-Memory/auto"
}
JSONPATCH
)"
  _jq_merge_file "$CC_SETTINGS" "$HOOKS_PATCH"
  ok "~/.claude/settings.json: hooks + autoMemoryDirectory merged"
fi

# ===========================================================================
# PHAN B: CODEX CLI (neu ENABLE_CODEX=y)
# ===========================================================================
if [[ "$ENABLE_CODEX" == "y" ]]; then
  echo ""
  echo -e "${BOLD}--- Codex CLI ---${RESET}"

  if ! command -v codex &>/dev/null; then
    warn "codex khong tim thay trong PATH - bo qua wire Codex. Cai: sudo npm install -g @openai/codex"
  else
    CODEX_DIR="$HOME/.codex"
    mkdir -p "$CODEX_DIR"

    CODEX_CONFIG="$CODEX_DIR/config.toml"
    _backup_if_exists "$CODEX_CONFIG"
    CODEX_HOOK_CMD="${VAULT_PATH}/_scripts/load-context-hook.sh"
    CODEX_SENTINEL_CMD="${VAULT_PATH}/_scripts/session-end-sentinel.sh codex-cli"

    # Kiem tra load-context-hook.sh ton tai
    if [[ ! -f "$CODEX_HOOK_CMD" ]]; then
      warn "load-context-hook.sh khong tim thay tai ${CODEX_HOOK_CMD}"
      warn "Se can sau khi vault co noi dung. Wire config truoc."
    fi

    CODEX_CONFIG_TMPL="${TEMPLATES_DIR}/codex/config.toml.tmpl"

    if [[ -f "$CODEX_CONFIG_TMPL" ]]; then
      # Codex template dung ${VAULT_PATH} va ${HOME} - dung envsubst
      RENDERED_CODEX="$(mktemp)"
      VAULT_PATH="$VAULT_PATH" HOME="$HOME" \
        envsubst '${VAULT_PATH} ${HOME}' < "$CODEX_CONFIG_TMPL" > "$RENDERED_CODEX"

      # Idempotent: chi append neu chua co [[hooks.SessionStart]]
      if [[ -f "$CODEX_CONFIG" ]] && grep -q '\[\[hooks\.SessionStart\]\]' "$CODEX_CONFIG"; then
        ok "~/.codex/config.toml: hooks da ton tai (skip)"
      else
        if [[ -f "$CODEX_CONFIG" ]]; then
          cat "$RENDERED_CODEX" >> "$CODEX_CONFIG"
          ok "~/.codex/config.toml: hooks appended tu template"
        else
          cp "$RENDERED_CODEX" "$CODEX_CONFIG"
          ok "~/.codex/config.toml: tao moi tu template"
        fi
      fi
      rm -f "$RENDERED_CODEX"
    else
      warn "${CODEX_CONFIG_TMPL} khong tim thay - ghi hooks truc tiep"

      # Ghi truc tiep bang heredoc double-quote (expand bien)
      CODEX_HOOKS_BLOCK="
# SessionStart hook - inject ETHOS + digest
[[hooks.SessionStart]]
matcher = \"startup|resume|clear|compact\"

[[hooks.SessionStart.hooks]]
type = \"command\"
command = \"${CODEX_HOOK_CMD}\"
statusMessage = \"Loading ETHOS + AI-Memory digest\"

# Stop hook - ghi sentinel session end
[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = \"command\"
command = \"${CODEX_SENTINEL_CMD}\"

# MCP filesystem cho vault
[mcp_servers.filesystem]
command = \"npx\"
args = [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"${VAULT_PATH}\"]

# Trust vault project
[projects.\"${VAULT_PATH}\"]
trust_level = \"trusted\"
"

      # Idempotent: chi ghi neu chua co
      if [[ -f "$CODEX_CONFIG" ]] && grep -q '\[\[hooks\.SessionStart\]\]' "$CODEX_CONFIG"; then
        ok "~/.codex/config.toml: SessionStart hook da ton tai (skip)"
      else
        echo "$CODEX_HOOKS_BLOCK" >> "$CODEX_CONFIG"
        ok "~/.codex/config.toml: hooks ghi truc tiep"
      fi
    fi

    # Nhac bat buoc: Codex TUI trust
    echo ""
    echo -e "${YELLOW}  [QUAN TRONG] Codex can trust hook bang tay:${RESET}"
    echo "  1. Chay: codex"
    echo "  2. Trong TUI, go: /hooks"
    echo "  3. Chon 'y' khi hoi 'Do you want to trust this hook?'"
    echo "  Neu bo qua buoc nay, Codex se KHONG nap AI memory (silent fail)!"
    echo ""
  fi
fi

# ===========================================================================
# PHAN C: GEMINI CLI (neu ENABLE_GEMINI=y)
# ===========================================================================
if [[ "$ENABLE_GEMINI" == "y" ]]; then
  echo ""
  echo -e "${BOLD}--- Gemini CLI ---${RESET}"

  if ! command -v gemini &>/dev/null; then
    warn "gemini khong tim thay trong PATH - bo qua wire Gemini. Cai: sudo npm install -g @google/gemini-cli"
  else
    GEMINI_DIR="$HOME/.gemini"
    mkdir -p "$GEMINI_DIR"

    GEMINI_SETTINGS="$GEMINI_DIR/settings.json"
    _backup_if_exists "$GEMINI_SETTINGS"
    GEMINI_HOOK_CMD="${VAULT_PATH}/_scripts/load-context-hook.sh"
    GEMINI_END_CMD="${VAULT_PATH}/_scripts/session-end-sentinel.sh gemini-cli"

    GEMINI_SETTINGS_TMPL="${TEMPLATES_DIR}/gemini/settings.json.tmpl"

    if [[ -f "$GEMINI_SETTINGS_TMPL" ]]; then
      RENDERED_GEMINI="$(mktemp)"
      VAULT_PATH="$VAULT_PATH" HOME="$HOME" \
        envsubst '${VAULT_PATH} ${HOME}' < "$GEMINI_SETTINGS_TMPL" > "$RENDERED_GEMINI"
      if [[ -f "$GEMINI_SETTINGS" ]]; then
        jq -s '.[0] * .[1]' "$GEMINI_SETTINGS" "$RENDERED_GEMINI" > "${GEMINI_SETTINGS}.tmp"
        mv "${GEMINI_SETTINGS}.tmp" "$GEMINI_SETTINGS"
        ok "~/.gemini/settings.json: merged tu template"
      else
        cp "$RENDERED_GEMINI" "$GEMINI_SETTINGS"
        ok "~/.gemini/settings.json: tao moi tu template"
      fi
      rm -f "$RENDERED_GEMINI"
    else
      warn "${GEMINI_SETTINGS_TMPL} khong tim thay - merge hooks toi gian"
      GEMINI_HOOKS_PATCH="$(cat <<GJSON
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${GEMINI_HOOK_CMD}"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${GEMINI_END_CMD}"
          }
        ]
      }
    ]
  }
}
GJSON
)"
      _jq_merge_file "$GEMINI_SETTINGS" "$GEMINI_HOOKS_PATCH"
      ok "~/.gemini/settings.json: hooks merged"
    fi

    # trustedFolders.json
    TRUSTED_FOLDERS="$GEMINI_DIR/trustedFolders.json"
    TRUSTED_TMPL="${TEMPLATES_DIR}/gemini/trustedFolders.json.tmpl"
    if [[ -f "$TRUSTED_TMPL" ]]; then
      _render_template_sed "$TRUSTED_TMPL" "$TRUSTED_FOLDERS"
      ok "~/.gemini/trustedFolders.json: render tu template"
    else
      if [[ ! -f "$TRUSTED_FOLDERS" ]]; then
        echo "{\"${HOME}\": \"TRUST_FOLDER\"}" > "$TRUSTED_FOLDERS"
        ok "~/.gemini/trustedFolders.json: tao moi"
      else
        # Them HOME neu chua co
        jq --arg h "$HOME" '. + {($h): "TRUST_FOLDER"}' "$TRUSTED_FOLDERS" > "${TRUSTED_FOLDERS}.tmp"
        mv "${TRUSTED_FOLDERS}.tmp" "$TRUSTED_FOLDERS"
        ok "~/.gemini/trustedFolders.json: $HOME added"
      fi
    fi

    # projects.json - them vault path
    GEMINI_PROJECTS="$GEMINI_DIR/projects.json"
    if [[ ! -f "$GEMINI_PROJECTS" ]]; then
      echo "[]" > "$GEMINI_PROJECTS"
    fi
    # Them vault path neu chua co
    VAULT_ALREADY=$(jq --arg v "$VAULT_PATH" 'map(select(. == $v)) | length' "$GEMINI_PROJECTS" 2>/dev/null || echo "0")
    if [[ "$VAULT_ALREADY" == "0" ]]; then
      jq --arg v "$VAULT_PATH" '. + [$v]' "$GEMINI_PROJECTS" > "${GEMINI_PROJECTS}.tmp"
      mv "${GEMINI_PROJECTS}.tmp" "$GEMINI_PROJECTS"
      ok "~/.gemini/projects.json: $VAULT_PATH added"
    else
      ok "~/.gemini/projects.json: vault path da co"
    fi
  fi
fi

# ===========================================================================
# PHAN D: SYSTEMD (Linux) / LAUNCHD (macOS) - auto-backup timer
# ===========================================================================
echo ""
echo -e "${BOLD}--- Auto-backup timer ---${RESET}"

# Ten unit RIENG (ai-vault-push) - KHONG trung 'obsidian-vault-push' cua setup cu,
# de KHONG bao gio de/cuop auto-backup vault khac da ton tai tren may.
SYSTEMD_TMPL_SVC="${TEMPLATES_DIR}/systemd/ai-vault-push.service.tmpl"
SYSTEMD_TMPL_TIMER="${TEMPLATES_DIR}/systemd/ai-vault-push.timer.tmpl"

if [[ "$OS_TYPE" == "linux" ]]; then
  SYSTEMD_DIR="$HOME/.config/systemd/user"
  mkdir -p "$SYSTEMD_DIR"

  SERVICE_DEST="$SYSTEMD_DIR/ai-vault-push.service"
  TIMER_DEST="$SYSTEMD_DIR/ai-vault-push.timer"
  _backup_if_exists "$SERVICE_DEST"
  _backup_if_exists "$TIMER_DEST"

  # Tao/render service file
  if [[ -f "$SYSTEMD_TMPL_SVC" ]]; then
    _render_template_sed "$SYSTEMD_TMPL_SVC" "$SERVICE_DEST"
    ok "ai-vault-push.service: render tu template"
  else
    warn "${SYSTEMD_TMPL_SVC} khong tim thay - tao service truc tiep"
    # Dung placeholder + sed (KHONG heredoc single-quote - de expand bien)
    # Viet ra file tam roi sed thay the
    SERVICE_TMP="$(mktemp)"
    cat > "$SERVICE_TMP" <<'SVCEOF'
[Unit]
Description=Auto-commit + push AI vault to GitHub (with flock)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=__VAULT__
Environment=HOME=__HOME__
Environment=GIT_SSH_COMMAND=/usr/bin/ssh
ExecStart=/usr/bin/flock -n /tmp/ai-vault-push.lock /bin/bash -c 'cd __VAULT__; if ! git diff --quiet --cached || ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then git add -A && git commit -m "vault: systemd auto-backup $(date +%%F-%%H%%M)" || true; fi; git pull --rebase=false --autostash origin master && git push origin master'
SuccessExitStatus=1
StandardOutput=journal
StandardError=journal
SVCEOF
    # Dung sed de thay __VAULT__ va __HOME__ (vua ghi ra file tam)
    sed -i \
      -e "s|__VAULT__|${VAULT_PATH}|g" \
      -e "s|__HOME__|${HOME}|g" \
      "$SERVICE_TMP"
    cp "$SERVICE_TMP" "$SERVICE_DEST"
    rm -f "$SERVICE_TMP"
    ok "ai-vault-push.service: tao truc tiep voi path ${VAULT_PATH}"
  fi

  # Timer
  if [[ -f "$SYSTEMD_TMPL_TIMER" ]]; then
    _render_template_sed "$SYSTEMD_TMPL_TIMER" "$TIMER_DEST"
    ok "ai-vault-push.timer: render tu template"
  else
    if [[ ! -f "$TIMER_DEST" ]]; then
      cat > "$TIMER_DEST" <<'TIMEREOF'
[Unit]
Description=Auto-push AI vault every 30 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=30min
Persistent=true
Unit=ai-vault-push.service

[Install]
WantedBy=timers.target
TIMEREOF
      ok "ai-vault-push.timer: tao moi"
    else
      ok "ai-vault-push.timer: da ton tai"
    fi
  fi

  # Enable + start (bo qua khi AI_VAULT_SKIP_SYSTEMD=1 - dung cho test cach ly)
  if [[ "${AI_VAULT_SKIP_SYSTEMD:-}" == "1" ]]; then
    warn "AI_VAULT_SKIP_SYSTEMD=1 - da render unit file, BO QUA enable/start + linger"
  elif systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable ai-vault-push.timer 2>/dev/null || true
    systemctl --user start ai-vault-push.timer 2>/dev/null || true
    TIMER_STATUS="$(systemctl --user is-active ai-vault-push.timer 2>/dev/null || echo "inactive")"
    if [[ "$TIMER_STATUS" == "active" ]]; then
      ok "systemd timer: active (ai-vault-push)"
    else
      warn "systemd timer: $TIMER_STATUS - kiem tra: journalctl --user -u ai-vault-push.timer"
    fi
  else
    warn "systemctl --user khong hoat dong (co the dang chay trong container/WSL) - bo qua timer"
  fi

  # User linger
  LINGER_STATUS="$(loginctl show-user "$(whoami)" 2>/dev/null | grep '^Linger=' | cut -d= -f2 || echo "no")"
  if [[ "${AI_VAULT_SKIP_SYSTEMD:-}" == "1" ]]; then
    :  # skip linger trong test mode
  elif [[ "$LINGER_STATUS" == "yes" ]]; then
    ok "loginctl linger: da bat"
  else
    if sudo loginctl enable-linger "$(whoami)" 2>/dev/null; then
      ok "loginctl linger: bat thanh cong"
    else
      warn "Khong the bat loginctl linger (can sudo). Chay tay: sudo loginctl enable-linger $(whoami)"
    fi
  fi

elif [[ "$OS_TYPE" == "macos" ]]; then
  LAUNCHD_DIR="$HOME/Library/LaunchAgents"
  LAUNCHD_PLIST="$LAUNCHD_DIR/ai.vault.push.plist"
  LAUNCHD_TMPL="${TEMPLATES_DIR}/launchd/ai.vault.push.plist.tmpl"

  mkdir -p "$LAUNCHD_DIR"

  if [[ -f "$LAUNCHD_TMPL" ]]; then
    _render_template_sed "$LAUNCHD_TMPL" "$LAUNCHD_PLIST"
    launchctl load -w "$LAUNCHD_PLIST" 2>/dev/null || true
    ok "launchd: ai.vault.push loaded tu template"
  else
    warn "launchd template khong tim thay tai ${LAUNCHD_TMPL}"
    warn "Tao plist truc tiep..."
    PLIST_TMP="$(mktemp)"
    cat > "$PLIST_TMP" <<'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.vault.push</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>cd __VAULT__ &amp;&amp; if ! git diff --quiet --cached || ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then git add -A &amp;&amp; git commit -m "vault: launchd auto-backup $(date +%F-%H%M)" || true; fi; git pull --rebase=false --autostash origin master &amp;&amp; git push origin master</string>
  </array>
  <key>WorkingDirectory</key>
  <string>__VAULT__</string>
  <key>StartInterval</key>
  <integer>1800</integer>
  <key>RunAtLoad</key>
  <false/>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>__HOME__</string>
    <key>PATH</key>
    <string>/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin</string>
  </dict>
</dict>
</plist>
PLISTEOF
    sed -i '' \
      -e "s|__VAULT__|${VAULT_PATH}|g" \
      -e "s|__HOME__|${HOME}|g" \
      "$PLIST_TMP"
    cp "$PLIST_TMP" "$LAUNCHD_PLIST"
    rm -f "$PLIST_TMP"
    launchctl load -w "$LAUNCHD_PLIST" 2>/dev/null || true
    ok "launchd: ai.vault.push.plist da tao tai $LAUNCHD_PLIST"
  fi

  echo ""
  info "macOS: Neu obsidian-git plugin hoat dong tot, launchd la fallback phu."
  info "  Obsidian -> Settings -> obsidian-git -> Auto backup interval: 30"
fi

echo ""
ok "[wire-runtimes] Hoan thanh."
