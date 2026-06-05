#!/usr/bin/env bash
# =============================================================================
# init-vault.sh - Lop A: Khoi tao noi dung vault tu vault-skeleton/
# =============================================================================
# Chay boi install.sh (khong chay truc tiep - can bien moi truong da export).
# Neu chay truc tiep: VAULT_PATH, YOUR_NAME, YOUR_EMAIL, COMPANY_NAME phai set.
#
# Lam gi:
#   1. Xac dinh VAULT_PATH (in-place neu = repo, hoac copy tu vault-skeleton/)
#   2. Render placeholder: <YOUR_NAME>, [YOUR COMPANY], <YOUR_EMAIL>
#   3. Cai pre-commit hook tu .github/hooks/pre-commit vao _local/hooks/
#   4. Set git core.hooksPath
#   5. Gen _digest.md + _index bang gen-memory-digest.sh + regen-ai-memory-index.sh
# Idempotent.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Mau sac helpers (khong phu thuoc install.sh)
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*" >&2; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
die()  { fail "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Lay bien moi truong hoac doc tu .install-answers
# ---------------------------------------------------------------------------
ANSWERS_FILE="${REPO_ROOT}/.install-answers"

_read_answer() {
  local key="$1" default="${2:-}"
  local val
  val="$(grep "^${key}=" "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2- || echo "")"
  echo "${val:-$default}"
}

VAULT_PATH="${VAULT_PATH:-$(_read_answer "VAULT_PATH" "$HOME/git/ai-obsidian-vault")}"
YOUR_NAME="${YOUR_NAME:-$(_read_answer "YOUR_NAME" "$(git config --global user.name 2>/dev/null || echo "Your Name")")}"
YOUR_EMAIL="${YOUR_EMAIL:-$(_read_answer "YOUR_EMAIL" "$(git config --global user.email 2>/dev/null || echo "you@example.com")")}"
COMPANY_NAME="${COMPANY_NAME:-$(_read_answer "COMPANY_NAME" "My Company")}"

[[ -z "$VAULT_PATH" ]] && die "VAULT_PATH khong duoc de trong. Chay install.sh truoc."

echo ""
echo -e "${BOLD}[init-vault] Khoi tao vault tai: $VAULT_PATH${RESET}"

# ---------------------------------------------------------------------------
# 1. Xac dinh mode: in-place hay copy-from-skeleton
# ---------------------------------------------------------------------------
SKELETON_DIR="${REPO_ROOT}/vault-skeleton"

if [[ ! -d "$SKELETON_DIR" ]]; then
  die "Khong tim thay vault-skeleton/ tai $SKELETON_DIR"
fi

# In-place: neu VAULT_PATH chinh la repo (hoac cung thu muc)
IN_PLACE=0
if [[ "$(realpath "$VAULT_PATH" 2>/dev/null || echo "")" == "$(realpath "$REPO_ROOT")" ]]; then
  IN_PLACE=1
fi

if [[ "$IN_PLACE" == "1" ]]; then
  ok "Mode: in-place (VAULT_PATH = repo root)"
else
  info "Mode: copy tu vault-skeleton/ vao $VAULT_PATH"
  mkdir -p "$VAULT_PATH"

  # Copy toan bo vault-skeleton vao VAULT_PATH
  # -n: khong ghi de file da ton tai (idempotent)
  if command -v rsync &>/dev/null; then
    rsync -a --ignore-existing "$SKELETON_DIR/" "$VAULT_PATH/"
    ok "rsync vault-skeleton/ -> $VAULT_PATH/"
  else
    # Fallback: cp -r + kiem tra tung file
    find "$SKELETON_DIR" -type f | while IFS= read -r src; do
      local_path="${src#$SKELETON_DIR/}"
      dest="$VAULT_PATH/$local_path"
      if [[ ! -f "$dest" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
      fi
    done
    ok "cp vault-skeleton/ -> $VAULT_PATH/ (idempotent)"
  fi

  # Khoi tao git repo neu chua co
  if [[ ! -d "$VAULT_PATH/.git" ]]; then
    git -C "$VAULT_PATH" init
    git -C "$VAULT_PATH" config init.defaultBranch master
    ok "git init $VAULT_PATH"
  else
    ok "$VAULT_PATH: da la git repo"
  fi
fi

# ---------------------------------------------------------------------------
# 2. Render placeholder trong vault content
# ---------------------------------------------------------------------------
info "Render placeholder trong vault content..."

# Ham render: thay the placeholder trong tat ca file .md
# Dung sed cho placeholder don gian (khong phai path, khong co dau cach nguy hiem)
_render_placeholder() {
  local dir="$1"
  # Tien xu ly: skip neu chua co file nao
  if ! find "$dir" -name "*.md" -type f 2>/dev/null | grep -q .; then
    return 0
  fi

  find "$dir" -name "*.md" -type f | while IFS= read -r f; do
    # Kiem tra nhanh xem co placeholder khong truoc khi sed
    if grep -qE '<YOUR_NAME>|\[YOUR COMPANY\]|<YOUR_EMAIL>' "$f" 2>/dev/null; then
      sed -i \
        -e "s|<YOUR_NAME>|${YOUR_NAME}|g" \
        -e "s|\[YOUR COMPANY\]|${COMPANY_NAME}|g" \
        -e "s|<YOUR_EMAIL>|${YOUR_EMAIL}|g" \
        "$f"
    fi
  done
}

_render_placeholder "$VAULT_PATH"
ok "Placeholder da render trong $VAULT_PATH"

# ---------------------------------------------------------------------------
# 3. Cai pre-commit hook tu .github/hooks/pre-commit
# ---------------------------------------------------------------------------
info "Cai pre-commit hook..."

# Tim .github/hooks/pre-commit trong repo hoac trong vault
PRECOMMIT_SRC=""
if [[ -f "${REPO_ROOT}/.github/hooks/pre-commit" ]]; then
  PRECOMMIT_SRC="${REPO_ROOT}/.github/hooks/pre-commit"
elif [[ -f "${VAULT_PATH}/.github/hooks/pre-commit" ]]; then
  PRECOMMIT_SRC="${VAULT_PATH}/.github/hooks/pre-commit"
fi

LOCAL_HOOKS_DIR="${VAULT_PATH}/_local/hooks"
mkdir -p "$LOCAL_HOOKS_DIR"

if [[ -z "$PRECOMMIT_SRC" ]]; then
  warn ".github/hooks/pre-commit khong tim thay - bo qua cai hook (co the setup sau)"
else
  LOCAL_PRECOMMIT="${LOCAL_HOOKS_DIR}/pre-commit"
  # Luon cap nhat (dedupe voi SSOT): copy moi khi src moi hon
  if [[ ! -f "$LOCAL_PRECOMMIT" ]] || [[ "$PRECOMMIT_SRC" -nt "$LOCAL_PRECOMMIT" ]]; then
    cp "$PRECOMMIT_SRC" "$LOCAL_PRECOMMIT"
    chmod +x "$LOCAL_PRECOMMIT"
    ok "_local/hooks/pre-commit cai tu .github/hooks/pre-commit"
  else
    ok "_local/hooks/pre-commit: da cap nhat"
  fi
fi

# Set core.hooksPath cho vault git repo
if [[ -d "${VAULT_PATH}/.git" ]]; then
  CURRENT_HOOKS_PATH="$(git -C "$VAULT_PATH" config --get core.hooksPath 2>/dev/null || echo "")"
  if [[ "$CURRENT_HOOKS_PATH" == "_local/hooks" ]]; then
    ok "core.hooksPath: da la _local/hooks"
  else
    git -C "$VAULT_PATH" config core.hooksPath _local/hooks
    ok "core.hooksPath set -> _local/hooks"
  fi
fi

# Tao thu muc _local/memory-mcp de khong lam mat cau truc
mkdir -p "${VAULT_PATH}/_local/memory-mcp" "${VAULT_PATH}/_local/backups"
# Tao _local/hooks/.gitkeep de dam bao thu muc ton tai neu vault moi
touch "${LOCAL_HOOKS_DIR}/.gitkeep"

# ---------------------------------------------------------------------------
# 4. Tao _local-state/ cho sentinel
# ---------------------------------------------------------------------------
mkdir -p "${VAULT_PATH}/.local-state"
if [[ ! -f "${VAULT_PATH}/.local-state/last-session-stop.txt" ]]; then
  touch "${VAULT_PATH}/.local-state/last-session-stop.txt"
  ok ".local-state/last-session-stop.txt tao moi"
else
  ok ".local-state/last-session-stop.txt: da ton tai"
fi

# ---------------------------------------------------------------------------
# 5. Gen _digest.md + _index/ lan dau
# ---------------------------------------------------------------------------
info "Tao AI-Memory _digest + _index..."

AM_SCRIPTS="${VAULT_PATH}/_scripts"

# Kiem tra thu muc AI-Memory co ton tai khong
if [[ ! -d "${VAULT_PATH}/Engineering/AI-Memory" ]]; then
  warn "Engineering/AI-Memory/ chua ton tai trong vault - bo qua gen digest (se gen sau khi co noi dung)"
else
  # Gen index truoc (regen-ai-memory-index.sh)
  if [[ -f "${AM_SCRIPTS}/regen-ai-memory-index.sh" ]]; then
    if bash "${AM_SCRIPTS}/regen-ai-memory-index.sh" "$VAULT_PATH" 2>/dev/null; then
      ok "regen-ai-memory-index.sh: xong"
    else
      warn "regen-ai-memory-index.sh: gap loi (co the bo qua neu AI-Memory con trong)"
    fi
  else
    warn "${AM_SCRIPTS}/regen-ai-memory-index.sh khong tim thay"
  fi

  # Gen digest sau (gen-memory-digest.sh)
  if [[ -f "${AM_SCRIPTS}/gen-memory-digest.sh" ]]; then
    if bash "${AM_SCRIPTS}/gen-memory-digest.sh" "$VAULT_PATH" 2>/dev/null; then
      ok "gen-memory-digest.sh: xong"
    else
      warn "gen-memory-digest.sh: gap loi (co the bo qua neu AI-Memory con trong)"
    fi
  else
    warn "${AM_SCRIPTS}/gen-memory-digest.sh khong tim thay"
  fi

  # Kiem tra _digest.md ton tai hay chua
  if [[ -f "${VAULT_PATH}/Engineering/AI-Memory/_digest.md" ]]; then
    ok "_digest.md ton tai"
  else
    # Tao _digest.md rong de hook khong crash
    echo "# AI Memory Digest\n\n> Digest se duoc tao sau khi co noi dung trong AI-Memory/." \
      > "${VAULT_PATH}/Engineering/AI-Memory/_digest.md"
    warn "_digest.md tao rong (chua co noi dung AI-Memory)"
  fi
fi

# ---------------------------------------------------------------------------
# Cai Obsidian community plugin tu NGUON CHINH THUC (khong bundle binary)
# Tai main.js/manifest.json/styles.css tu GitHub release cua tung plugin.
# data.json (config cua ta) da co san trong vault, duoc giu nguyen.
# Graceful: neu offline / loi, chi canh bao - member co the chay lai sau
# hoac cai tay qua Obsidian Community Plugins.
# ---------------------------------------------------------------------------
echo ""
info "Cai Obsidian community plugin tu nguon chinh thuc..."
PLUGIN_INSTALLER="${SCRIPT_DIR}/install-obsidian-plugins.sh"
if [[ -f "$PLUGIN_INSTALLER" ]]; then
  if bash "$PLUGIN_INSTALLER" "$VAULT_PATH"; then
    ok "Plugin da cai tu GitHub release chinh thuc"
  else
    warn "Mot so plugin chua tai duoc (offline?). Chay lai sau:"
    info "  bash ${PLUGIN_INSTALLER} \"$VAULT_PATH\""
    info "  hoac cai tay: Obsidian -> Settings -> Community plugins -> Browse"
  fi
else
  warn "Khong tim thay install-obsidian-plugins.sh - cai plugin tay qua Obsidian"
fi

echo ""
ok "[init-vault] Hoan thanh."
