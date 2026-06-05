#!/usr/bin/env bash
# =============================================================================
# doctor.sh - Verify cai dat AI vault sau install
# =============================================================================
# In bang PASS/FAIL cho tung hang muc:
#   1. Claude @import resolve (ETHOS.md ton tai tai path trong CLAUDE.md)
#   2. Codex [hooks.state] trusted_hash ton tai (neu chua: BAO DO)
#   3. load-context-hook.sh smoke-test (emit JSON hop le)
#   4. systemd timer active (Linux) / launchd (macOS)
#   5. _digest.md ton tai + freshness (<= 7 ngay)
#   6. Vault skeleton folders day du (cac path Dataview/Templater)
#   7. _local/hooks/pre-commit ton tai + executable
#   8. Nhac GUI: "Mo vault trong Obsidian -> Trust plugins"
# =============================================================================

# Khong set -e de tiep tuc kiem tra du co loi
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

PASS=0; FAIL=0; WARN=0

_pass() { echo -e "  ${GREEN}[PASS]${RESET} $*"; PASS=$((PASS+1)); }
_fail() { echo -e "  ${RED}[FAIL]${RESET} $*"; FAIL=$((FAIL+1)); }
_warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; WARN=$((WARN+1)); }
_info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }

# ---------------------------------------------------------------------------
# Lay VAULT_PATH tu .install-answers hoac env
# ---------------------------------------------------------------------------
ANSWERS_FILE="${REPO_ROOT}/.install-answers"
_read_answer() {
  local key="$1" default="${2:-}"
  local val
  val="$(grep "^${key}=" "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2- || echo "")"
  echo "${val:-$default}"
}

VAULT_PATH="${VAULT_PATH:-$(_read_answer "VAULT_PATH" "")}"
ENABLE_CODEX="${ENABLE_CODEX:-$(_read_answer "ENABLE_CODEX" "y")}"
ENABLE_GEMINI="${ENABLE_GEMINI:-$(_read_answer "ENABLE_GEMINI" "y")}"

# Detect OS
OS_TYPE="linux"
[[ "$(uname -s)" == "Darwin" ]] && OS_TYPE="macos"

echo ""
echo -e "${BOLD}=== Doctor - Kiem tra cai dat AI Vault ===${RESET}"
echo "Thoi gian: $(date)"
[[ -n "$VAULT_PATH" ]] && echo "VAULT_PATH: $VAULT_PATH" || echo "VAULT_PATH: (chua ro - se doc tu config)"
echo ""

# ===========================================================================
# 1. Claude @import resolve
# ===========================================================================
echo -e "${BOLD}[1] Claude @import ETHOS.md${RESET}"

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [[ ! -f "$CLAUDE_MD" ]]; then
  _fail "~/.claude/CLAUDE.md khong ton tai. Chay: bash install.sh"
else
  # Tim dong @import (bat dau bang @, khong phai @import keyword - Claude dung @/path)
  IMPORT_LINE="$(grep -E '^@/' "$CLAUDE_MD" 2>/dev/null | head -1 || echo "")"
  if [[ -z "$IMPORT_LINE" ]]; then
    _fail "~/.claude/CLAUDE.md khong co dong @import (bat dau bang @/)"
    _info "  Can co dong: @/path/to/ETHOS.md trong ~/.claude/CLAUDE.md"
  else
    # Lay path tu dong @import (bo '@' o dau)
    IMPORT_PATH="${IMPORT_LINE#@}"
    if [[ -f "$IMPORT_PATH" ]]; then
      _pass "@import resolve: $IMPORT_PATH"
    else
      _fail "@import path KHONG TON TAI: $IMPORT_PATH"
      _info "  Re-render: bash install.sh (giu cau tra loi cu)"
    fi
  fi
fi

# Kiem tra cc-session-start-memory.sh
CC_START="$HOME/.claude/hooks/cc-session-start-memory.sh"
if [[ -f "$CC_START" && -x "$CC_START" ]]; then
  _pass "cc-session-start-memory.sh: ton tai + executable"
else
  _fail "~/.claude/hooks/cc-session-start-memory.sh: khong ton tai hoac khong executable"
fi

# Kiem tra autoMemoryDirectory trong settings.json
CC_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CC_SETTINGS" ]]; then
  AUTO_MEM="$(jq -r '.autoMemoryDirectory // empty' "$CC_SETTINGS" 2>/dev/null || echo "")"
  if [[ -n "$AUTO_MEM" ]]; then
    if [[ -d "$AUTO_MEM" ]] || [[ -d "$(dirname "$AUTO_MEM")" ]]; then
      _pass "autoMemoryDirectory: $AUTO_MEM"
    else
      _warn "autoMemoryDirectory trong settings.json tro toi path chua ton tai: $AUTO_MEM"
    fi
  else
    _warn "~/.claude/settings.json khong co autoMemoryDirectory"
  fi
else
  _warn "~/.claude/settings.json khong ton tai"
fi

# ===========================================================================
# 2. Codex [hooks.state] trusted_hash
# ===========================================================================
if [[ "$ENABLE_CODEX" == "y" ]]; then
  echo ""
  echo -e "${BOLD}[2] Codex hook trust${RESET}"

  CODEX_CONFIG="$HOME/.codex/config.toml"
  if [[ ! -f "$CODEX_CONFIG" ]]; then
    _fail "~/.codex/config.toml khong ton tai. Chay: bash install.sh"
  else
    # Kiem tra SessionStart hook co trong config
    if grep -q '\[\[hooks\.SessionStart\]\]' "$CODEX_CONFIG" 2>/dev/null; then
      _pass "~/.codex/config.toml: [[hooks.SessionStart]] co mat"
    else
      _fail "~/.codex/config.toml: [[hooks.SessionStart]] CHUA CO"
      _info "  Chay: bash install.sh de wire lai"
    fi

    # Kiem tra [hooks.state] trusted_hash - day la dau hieu da chay /hooks
    if grep -q '\[hooks\.state\]' "$CODEX_CONFIG" 2>/dev/null && \
       grep -q 'trusted_hash' "$CODEX_CONFIG" 2>/dev/null; then
      _pass "Codex hook: da trust (trusted_hash ton tai)"
    else
      _fail "${RED}Codex hook CHUA TRUST!${RESET}"
      echo ""
      echo -e "  ${YELLOW}[QUAN TRONG] Codex dang chay nhung KHONG NAP AI memory (silent fail)!${RESET}"
      echo "  Cach sua:"
      echo "    1. Chay: codex"
      echo "    2. Go: /hooks"
      echo "    3. Nhan 'y' khi hoi 'Do you want to trust this hook?'"
      echo ""
    fi

    # Kiem tra Stop hook (sentinel)
    if grep -q '\[\[hooks\.Stop\]\]' "$CODEX_CONFIG" 2>/dev/null; then
      _pass "Codex Stop hook: co mat (sentinel se ghi)"
    else
      _warn "~/.codex/config.toml: [[hooks.Stop]] chua co (sentinel Codex se khong ghi)"
    fi
  fi
fi

# ===========================================================================
# 3. load-context-hook.sh smoke-test
# ===========================================================================
echo ""
echo -e "${BOLD}[3] load-context-hook.sh smoke-test${RESET}"

if [[ -n "$VAULT_PATH" && -d "$VAULT_PATH" ]]; then
  HOOK_SCRIPT="${VAULT_PATH}/_scripts/load-context-hook.sh"
  if [[ ! -f "$HOOK_SCRIPT" ]]; then
    _warn "load-context-hook.sh khong tim thay: $HOOK_SCRIPT"
    _info "  Se co sau khi vault co noi dung day du"
  else
    if [[ ! -x "$HOOK_SCRIPT" ]]; then
      _fail "$HOOK_SCRIPT khong executable. Chay: chmod +x $HOOK_SCRIPT"
    else
      # Smoke test: chay va kiem tra JSON output hop le
      HOOK_OUT="$(bash "$HOOK_SCRIPT" 2>/dev/null || echo "")"
      if [[ -z "$HOOK_OUT" ]]; then
        _fail "load-context-hook.sh: khong emit output (crash hoac rong)"
        _info "  Kiem tra: ETHOS.md va _digest.md ton tai tai vault"
      else
        # Validate JSON
        if echo "$HOOK_OUT" | jq -e '.hookSpecificOutput.additionalContext' > /dev/null 2>&1; then
          _pass "load-context-hook.sh: emit JSON hop le (hookSpecificOutput.additionalContext)"
        else
          _fail "load-context-hook.sh: output khong phai JSON hop le"
          _info "  Output thu nhung 200 chars: ${HOOK_OUT:0:200}"
        fi
      fi
    fi
  fi
else
  _warn "VAULT_PATH khong xac dinh hoac chua ton tai - bo qua smoke-test hook"
fi

# ===========================================================================
# 4. Auto-backup timer
# ===========================================================================
echo ""
echo -e "${BOLD}[4] Auto-backup timer${RESET}"

if [[ "$OS_TYPE" == "linux" ]]; then
  TIMER_STATUS="$(systemctl --user is-active ai-vault-push.timer 2>/dev/null || echo "inactive")"
  if [[ "$TIMER_STATUS" == "active" ]]; then
    NEXT_RUN="$(systemctl --user status ai-vault-push.timer 2>/dev/null | grep 'Trigger:' | head -1 | sed 's/.*Trigger: //' || echo "")"
    _pass "systemd timer: active${NEXT_RUN:+ | Next: $NEXT_RUN}"
  else
    _warn "systemd timer: $TIMER_STATUS"
    _info "  Kich hoat: systemctl --user enable --now ai-vault-push.timer"
    _info "  Debug: journalctl --user -u ai-vault-push.service"
  fi

  # Kiem tra linger
  LINGER="$(loginctl show-user "$(whoami)" 2>/dev/null | grep '^Linger=' | cut -d= -f2 || echo "no")"
  if [[ "$LINGER" == "yes" ]]; then
    _pass "loginctl linger: enabled (timer chay sau logout)"
  else
    _warn "loginctl linger: chua bat. Chay: sudo loginctl enable-linger $(whoami)"
  fi

elif [[ "$OS_TYPE" == "macos" ]]; then
  LAUNCHD_LABEL="ai.vault.push"
  if launchctl list "$LAUNCHD_LABEL" &>/dev/null 2>&1; then
    _pass "launchd: $LAUNCHD_LABEL loaded"
  else
    _warn "launchd: $LAUNCHD_LABEL CHUA LOADED"
    PLIST="$HOME/Library/LaunchAgents/ai.vault.push.plist"
    if [[ -f "$PLIST" ]]; then
      _info "  Chay: launchctl load -w $PLIST"
    else
      _info "  Plist chua co. Chay: bash install.sh"
    fi
    _info "  Hoac dung obsidian-git plugin (Obsidian -> Settings -> obsidian-git -> Auto backup: 30min)"
  fi
fi

# ===========================================================================
# 5. _digest.md ton tai + freshness
# ===========================================================================
echo ""
echo -e "${BOLD}[5] AI Memory digest${RESET}"

if [[ -n "$VAULT_PATH" ]]; then
  DIGEST_FILE="${VAULT_PATH}/Engineering/AI-Memory/_digest.md"
  if [[ ! -f "$DIGEST_FILE" ]]; then
    _fail "_digest.md khong ton tai: $DIGEST_FILE"
    _info "  Gen: bash ${VAULT_PATH}/_scripts/gen-memory-digest.sh ${VAULT_PATH}"
  else
    _pass "_digest.md ton tai"

    # Kiem tra freshness: cảnh bao neu mtime > 7 ngay
    DIGEST_AGE_DAYS=0
    if [[ "$OS_TYPE" == "linux" ]]; then
      DIGEST_MTIME="$(stat -c %Y "$DIGEST_FILE" 2>/dev/null || echo "0")"
    else
      DIGEST_MTIME="$(stat -f %m "$DIGEST_FILE" 2>/dev/null || echo "0")"
    fi
    NOW_EPOCH="$(date +%s)"
    if [[ "$DIGEST_MTIME" -gt 0 ]]; then
      DIGEST_AGE_DAYS=$(( (NOW_EPOCH - DIGEST_MTIME) / 86400 ))
      if [[ "$DIGEST_AGE_DAYS" -le 7 ]]; then
        _pass "_digest.md freshness: ${DIGEST_AGE_DAYS} ngay truoc"
      else
        _warn "_digest.md stale: ${DIGEST_AGE_DAYS} ngay chua cap nhat"
        _info "  Regen: bash ${VAULT_PATH}/_scripts/gen-memory-digest.sh ${VAULT_PATH}"
        _info "  Hoac push vault len GitHub de trigger Actions auto-regen"
      fi
    fi
  fi
else
  _warn "VAULT_PATH chua xac dinh - bo qua kiem tra digest"
fi

# ===========================================================================
# 6. Vault skeleton folders
# ===========================================================================
echo ""
echo -e "${BOLD}[6] Vault folder structure${RESET}"

if [[ -n "$VAULT_PATH" && -d "$VAULT_PATH" ]]; then
  # Cac folder can thiet cho Dataview + Templater hoat dong
  REQUIRED_FOLDERS=(
    "Meta"
    "Inbox"
    "Engineering"
    "Engineering/AI-Memory"
    "Templates"
    ".obsidian/plugins/dataview"
    ".obsidian/plugins/templater-obsidian"
    ".obsidian/plugins/auto-note-mover"
  )

  FOLDER_FAIL=0
  for folder in "${REQUIRED_FOLDERS[@]}"; do
    if [[ -d "${VAULT_PATH}/$folder" ]]; then
      _pass "Folder: $folder"
    else
      _fail "Folder thieu: $folder"
      FOLDER_FAIL=$((FOLDER_FAIL + 1))
    fi
  done

  if [[ "$FOLDER_FAIL" -gt 0 ]]; then
    _info "  Chay: bash install.sh de tao lai structure tu vault-skeleton/"
  fi

  # Kiem tra CODE plugin da tai tu nguon chinh thuc chua (main.js)
  # (plugin code KHONG bundle trong repo - tai qua install-obsidian-plugins.sh)
  CP_LIST="${VAULT_PATH}/.obsidian/community-plugins.json"
  if [[ -f "$CP_LIST" ]]; then
    PLUG_MISSING=0; PLUG_TOTAL=0
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      PLUG_TOTAL=$((PLUG_TOTAL+1))
      [[ -f "${VAULT_PATH}/.obsidian/plugins/${pid}/main.js" ]] || PLUG_MISSING=$((PLUG_MISSING+1))
    done < <(jq -r '.[]' "$CP_LIST" 2>/dev/null)
    if [[ "$PLUG_MISSING" -eq 0 && "$PLUG_TOTAL" -gt 0 ]]; then
      _pass "Obsidian plugins: ${PLUG_TOTAL}/${PLUG_TOTAL} da tai code tu nguon chinh thuc"
    elif [[ "$PLUG_TOTAL" -gt 0 ]]; then
      _warn "Obsidian plugins: $((PLUG_TOTAL-PLUG_MISSING))/${PLUG_TOTAL} co code (${PLUG_MISSING} thieu)"
      _info "  Tai tu nguon chinh thuc: bash $(dirname "$0")/scripts/install-obsidian-plugins.sh \"$VAULT_PATH\""
    fi
  fi
else
  _warn "VAULT_PATH chua xac dinh hoac chua ton tai - bo qua kiem tra folders"
fi

# ===========================================================================
# 7. _local/hooks/pre-commit
# ===========================================================================
echo ""
echo -e "${BOLD}[7] PII pre-commit hook${RESET}"

if [[ -n "$VAULT_PATH" ]]; then
  PRECOMMIT="${VAULT_PATH}/_local/hooks/pre-commit"
  if [[ -f "$PRECOMMIT" ]]; then
    if [[ -x "$PRECOMMIT" ]]; then
      _pass "_local/hooks/pre-commit: ton tai + executable"

      # Kiem tra core.hooksPath da set
      HOOKS_PATH="$(git -C "$VAULT_PATH" config --get core.hooksPath 2>/dev/null || echo "")"
      if [[ "$HOOKS_PATH" == "_local/hooks" ]]; then
        _pass "git core.hooksPath: _local/hooks"
      else
        _warn "git core.hooksPath chua set hoac sai: '$HOOKS_PATH'"
        _info "  Chay: git -C $VAULT_PATH config core.hooksPath _local/hooks"
      fi
    else
      _fail "_local/hooks/pre-commit KHONG executable"
      _info "  Chay: chmod +x ${PRECOMMIT}"
    fi
  else
    _fail "_local/hooks/pre-commit chua co"
    _info "  Chay: bash install.sh (step init-vault.sh)"
  fi
else
  _warn "VAULT_PATH chua xac dinh - bo qua kiem tra pre-commit hook"
fi

# ===========================================================================
# 8. Nhac Gemini (neu enabled)
# ===========================================================================
if [[ "$ENABLE_GEMINI" == "y" ]]; then
  echo ""
  echo -e "${BOLD}[8] Gemini wiring${RESET}"

  GEMINI_SETTINGS="$HOME/.gemini/settings.json"
  if [[ -f "$GEMINI_SETTINGS" ]]; then
    # Kiem tra SessionStart hook
    if jq -e '.hooks.SessionStart' "$GEMINI_SETTINGS" > /dev/null 2>&1; then
      HOOK_CMD="$(jq -r '.hooks.SessionStart[0].hooks[0].command // empty' "$GEMINI_SETTINGS" 2>/dev/null || echo "")"
      if [[ -n "$HOOK_CMD" && -f "$HOOK_CMD" ]]; then
        _pass "Gemini SessionStart hook: $HOOK_CMD"
      else
        _warn "Gemini SessionStart hook script chua ton tai: $HOOK_CMD"
      fi
    else
      _warn "~/.gemini/settings.json: SessionStart hook chua co"
    fi
  else
    _warn "~/.gemini/settings.json chua ton tai"
  fi
fi

# ===========================================================================
# 9. Nhac GUI (luon hien thi)
# ===========================================================================
echo ""
echo -e "${BOLD}[9] Nhac thao tac thu cong${RESET}"

echo ""
echo -e "  ${YELLOW}Cac buoc can lam tay (khong tu dong hoa duoc):${RESET}"
echo ""
echo "  A. Mo vault trong Obsidian:"
echo "     Obsidian -> Open folder as vault -> ${VAULT_PATH:-(chua ro)}"
echo "     Khi hoi: chon 'Trust author and enable plugins'"
echo "     (Bat buoc de Auto Note Mover + Dataview + Templater hoat dong)"
echo ""

if [[ "$ENABLE_CODEX" == "y" ]]; then
  echo "  B. Trust Codex hook (NEU CHUA TRUST):"
  echo "     Chay: codex"
  echo "     Go: /hooks"
  echo "     Nhan 'y' de trust SessionStart + Stop hook"
  echo ""
fi

echo "  C. Dang nhap bang GOI SUBSCRIPTION (KHONG can API key):"
echo "     Claude Code : chay 'claude' -> go '/login' -> dang nhap Claude Pro/Max"
echo "     Codex CLI   : chay 'codex' -> chon 'Sign in with ChatGPT' (ChatGPT Plus/Pro)"
echo "     Gemini CLI  : chay 'gemini' -> dang nhap tai khoan Google"
echo "     (Luu y: KHONG dat ANTHROPIC_API_KEY - se ep Claude tinh tien API thay vi subscription)"
echo ""

# ===========================================================================
# Tong ket
# ===========================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}PASS: ${PASS}${RESET}  |  ${YELLOW}WARN: ${WARN}${RESET}  |  ${RED}FAIL: ${FAIL}${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo -e "${RED}[FAIL] $FAIL hang muc can xu ly truoc khi su dung.${RESET}"
  echo "  Chay lai: bash install.sh"
  echo ""
  exit 1
elif [[ "$WARN" -gt 0 ]]; then
  echo -e "${YELLOW}[WARN] $WARN canh bao - he thong hoat dong nhung chua hoan chinh.${RESET}"
  echo ""
  exit 0
else
  echo -e "${GREEN}[PASS] Tat ca kiem tra deu OK! He thong san sang.${RESET}"
  echo ""
  exit 0
fi
