#!/usr/bin/env bash
# =============================================================================
# AI Vault - Installer orchestrator (1-lenh)
# =============================================================================
# Chay: bash install.sh
#
# Luong:
#   1. Prereq check (bash, git, jq, node, gh)
#   2. Guided prompt 6 cau, input validation
#   3. Luu .install-answers
#   4. scripts/init-vault.sh  (lop A: noi dung vault + digest)
#   5. scripts/wire-runtimes.sh (lop B: wire home config)
#   6. gh auth login + set remote
#   7. Goi y chay ./doctor.sh
#
# Idempotent: chay lai an toan (moi script con tu kiem tra trang thai).
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Mau sac va helper
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*" >&2; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
hdr()  { echo -e "\n${BOLD}=== $* ===${RESET}"; }
die()  { fail "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}AI Vault - Cai dat he thong AI memory da-CLI${RESET}"
echo "Repo: https://github.com/Viindoo/ai-obsidian-vault"
echo "Xem README.md truoc khi tiep tuc."
echo ""

# ---------------------------------------------------------------------------
# 1. Phat hien OS
# ---------------------------------------------------------------------------
hdr "1. Kiem tra moi truong"

OS_TYPE="linux"
if [[ "$(uname -s)" == "Darwin" ]]; then
  OS_TYPE="macos"
  ok "OS: macOS"
elif [[ "$(uname -s)" == "Linux" ]]; then
  OS_TYPE="linux"
  ok "OS: Linux"
else
  die "He dieu hanh khong ho tro: $(uname -s). Chi ho tro Linux va macOS."
fi

# Kiem tra bash >= 4
BASH_MAJOR="${BASH_VERSINFO[0]}"
if [[ "$BASH_MAJOR" -lt 4 ]]; then
  die "Yeu cau bash >= 4 (hien tai: $BASH_VERSION). Tren macOS: brew install bash"
fi
ok "bash $BASH_VERSION"

# Kiem tra prereq: git, jq, node, gh
MISSING_TOOLS=()
for tool in git jq node gh; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool: $(command -v "$tool")"
  else
    MISSING_TOOLS+=("$tool")
    fail "$tool: khong tim thay"
  fi
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  echo ""
  warn "Cac cong cu sau day can duoc cai dat truoc:"
  for t in "${MISSING_TOOLS[@]}"; do
    case "$t" in
      git)
        if [[ "$OS_TYPE" == "linux" ]]; then
          info "  sudo apt-get install git"
        else
          info "  brew install git  (hoac cai Xcode Command Line Tools)"
        fi ;;
      jq)
        if [[ "$OS_TYPE" == "linux" ]]; then
          info "  sudo apt-get install jq"
        else
          info "  brew install jq"
        fi ;;
      node)
        if [[ "$OS_TYPE" == "linux" ]]; then
          info "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
        else
          info "  brew install node  hoac  nvm install --lts"
        fi ;;
      gh)
        if [[ "$OS_TYPE" == "linux" ]]; then
          info "  (Ubuntu) curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list && sudo apt-get update && sudo apt-get install gh"
        else
          info "  brew install gh"
        fi ;;
    esac
  done
  die "Cai dat cac cong cu tren roi chay lai install.sh"
fi

# ---------------------------------------------------------------------------
# 2. Doc answers hien tai (neu co) de pre-fill
# ---------------------------------------------------------------------------
ANSWERS_FILE="${SCRIPT_DIR}/.install-answers"
_prev() { grep "^${1}=" "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2- || echo ""; }

hdr "2. Cau hinh (guided prompt)"
echo "Nhan Enter de giu gia tri mac dinh [trong ngoac]."
echo ""

# Ham validate va prompt
# $1 = ten bien, $2 = cau hoi, $3 = gia tri default, $4 = validator (optional)
prompt_val() {
  local varname="$1" question="$2" default="$3" validator="${4:-}"
  local prev_val; prev_val="$(_prev "$varname")"
  local effective_default="${prev_val:-$default}"
  local val
  while true; do
    echo -n "  $question [${effective_default}]: "
    read -r val
    val="${val:-$effective_default}"
    # Validate neu co validator
    if [[ -n "$validator" ]]; then
      if ! eval "$validator '$val'"; then
        warn "Gia tri khong hop le, vui long nhap lai."
        continue
      fi
    fi
    printf -v "$varname" '%s' "$val"
    break
  done
}

# Validator: khong co dau cach, ky tu dac biet nguy hiem
_validate_path() {
  local p="$1"
  # Tu choi path co dau cach
  if [[ "$p" =~ [[:space:]] ]]; then
    fail "Path khong duoc chua dau cach. Nhap lai."
    return 1
  fi
  # Tu choi ky tu de gay loi shell injection
  if [[ "$p" =~ [\$\`\;\|\&\<\>\(\)\{\}] ]]; then
    fail "Path chua ky tu dac biet khong duoc phep. Nhap lai."
    return 1
  fi
  return 0
}

_validate_email() {
  local e="$1"
  if [[ ! "$e" =~ ^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$ ]]; then
    fail "Email khong hop le. Nhap lai."
    return 1
  fi
  return 0
}

_validate_nonempty() {
  local v="$1"
  if [[ -z "$v" ]]; then
    fail "Gia tri nay bat buoc. Nhap lai."
    return 1
  fi
  return 0
}

_validate_yn() {
  local v="$1"
  if [[ "$v" != "y" && "$v" != "n" ]]; then
    fail "Chi nhap 'y' hoac 'n'."
    return 1
  fi
  return 0
}

# Cau 1: VAULT_PATH
DEFAULT_VAULT_PATH="$HOME/git/ai-obsidian-vault"
prompt_val "VAULT_PATH" "Thu muc vault (tuyet doi, khong dau cach)" "$DEFAULT_VAULT_PATH" "_validate_path"
# Normalize voi realpath (neu thu muc da ton tai)
if [[ -d "$VAULT_PATH" ]]; then
  VAULT_PATH="$(realpath "$VAULT_PATH")"
else
  # Neu chua ton tai: normalize phan parent
  PARENT_DIR="$(dirname "$VAULT_PATH")"
  BASE_NAME="$(basename "$VAULT_PATH")"
  if [[ -d "$PARENT_DIR" ]]; then
    VAULT_PATH="$(realpath "$PARENT_DIR")/$BASE_NAME"
  fi
fi
info "VAULT_PATH = $VAULT_PATH"

# Cau 2: YOUR_NAME
DEFAULT_NAME="$(git config --global user.name 2>/dev/null || echo "")"
prompt_val "YOUR_NAME" "Ten cua ban (cho git commit)" "$DEFAULT_NAME" "_validate_nonempty"

# Cau 3: YOUR_EMAIL
DEFAULT_EMAIL="$(git config --global user.email 2>/dev/null || echo "")"
prompt_val "YOUR_EMAIL" "Email cua ban (cho git + SSH key)" "$DEFAULT_EMAIL" "_validate_email"

# Cau 4: COMPANY_NAME
DEFAULT_COMPANY="$(_prev "COMPANY_NAME")"
[[ -z "$DEFAULT_COMPANY" ]] && DEFAULT_COMPANY="My Company"
prompt_val "COMPANY_NAME" "Ten cong ty / to chuc (cho placeholder trong vault)" "$DEFAULT_COMPANY" "_validate_nonempty"

# Cau 5: OLLAMA_ENDPOINT (optional)
DEFAULT_OLLAMA="$(_prev "OLLAMA_ENDPOINT")"
[[ -z "$DEFAULT_OLLAMA" ]] && DEFAULT_OLLAMA=""
echo -n "  Ollama endpoint (de trong neu khong co) [${DEFAULT_OLLAMA}]: "
read -r OLLAMA_ENDPOINT
OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-$DEFAULT_OLLAMA}"

# Cau 6a: Enable Codex?
DEFAULT_CODEX="$(_prev "ENABLE_CODEX")"
[[ -z "$DEFAULT_CODEX" ]] && DEFAULT_CODEX="y"
prompt_val "ENABLE_CODEX" "Wire Codex CLI? (y/n)" "$DEFAULT_CODEX" "_validate_yn"

# Cau 6b: Enable Gemini?
DEFAULT_GEMINI="$(_prev "ENABLE_GEMINI")"
[[ -z "$DEFAULT_GEMINI" ]] && DEFAULT_GEMINI="y"
prompt_val "ENABLE_GEMINI" "Wire Gemini CLI? (y/n)" "$DEFAULT_GEMINI" "_validate_yn"

# ---------------------------------------------------------------------------
# Xac nhan truoc khi thuc hien
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Xac nhan cai dat ---${RESET}"
echo "  VAULT_PATH    : $VAULT_PATH"
echo "  YOUR_NAME     : $YOUR_NAME"
echo "  YOUR_EMAIL    : $YOUR_EMAIL"
echo "  COMPANY_NAME  : $COMPANY_NAME"
echo "  OLLAMA        : ${OLLAMA_ENDPOINT:-(bo qua)}"
echo "  Wire Codex    : $ENABLE_CODEX"
echo "  Wire Gemini   : $ENABLE_GEMINI"
echo ""
echo -n "Tiep tuc cai dat? (y/n) [y]: "
read -r CONFIRM
CONFIRM="${CONFIRM:-y}"
if [[ "$CONFIRM" != "y" ]]; then
  info "Da huy. Chay lai install.sh khi san sang."
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. Luu .install-answers
# ---------------------------------------------------------------------------
hdr "3. Luu cau hinh"
cat > "$ANSWERS_FILE" <<EOF
VAULT_PATH=$VAULT_PATH
YOUR_NAME=$YOUR_NAME
YOUR_EMAIL=$YOUR_EMAIL
COMPANY_NAME=$COMPANY_NAME
OLLAMA_ENDPOINT=$OLLAMA_ENDPOINT
ENABLE_CODEX=$ENABLE_CODEX
ENABLE_GEMINI=$ENABLE_GEMINI
EOF
ok "Da luu $ANSWERS_FILE"

# Export cho cac script con su dung
export VAULT_PATH YOUR_NAME YOUR_EMAIL COMPANY_NAME OLLAMA_ENDPOINT ENABLE_CODEX ENABLE_GEMINI OS_TYPE

# ---------------------------------------------------------------------------
# 4. Lop A: init-vault.sh (phai chay TRUOC wire-runtimes de _digest.md ton tai)
# ---------------------------------------------------------------------------
hdr "4. Khoi tao vault noi dung (lop A)"
bash "$SCRIPT_DIR/scripts/init-vault.sh"
ok "init-vault.sh hoan thanh"

# ---------------------------------------------------------------------------
# 5. Lop B: wire-runtimes.sh (wire hook sau khi _digest.md da co)
# ---------------------------------------------------------------------------
hdr "5. Wire 3 AI runtime (lop B)"
bash "$SCRIPT_DIR/scripts/wire-runtimes.sh"
ok "wire-runtimes.sh hoan thanh"

# ---------------------------------------------------------------------------
# 6. GitHub auth + set remote
# ---------------------------------------------------------------------------
hdr "6. GitHub auth"

# Kiem tra xem da auth chua
if gh auth status &>/dev/null 2>&1; then
  ok "gh: da dang nhap GitHub"
else
  info "Dang nhap GitHub qua OAuth (gh auth login)..."
  info "Chon: GitHub.com -> HTTPS -> Authenticate via browser"
  gh auth login
fi

# Set git identity
git config --global user.name "$YOUR_NAME"
git config --global user.email "$YOUR_EMAIL"
ok "git identity: $YOUR_NAME <$YOUR_EMAIL>"

# ---------------------------------------------------------------------------
# Remote backup: tao PRIVATE repo rieng cho vault cua member
# Vault chua memory/ghi chu ca nhan -> PHAI private. KHONG dung fork template
# (fork cua public repo cung public -> lo du lieu). Template chi de o 'upstream'
# de nhan update co che.
# ---------------------------------------------------------------------------
if [[ -d "$VAULT_PATH/.git" ]]; then
  CURRENT_REMOTE=$(git -C "$VAULT_PATH" remote get-url origin 2>/dev/null || echo "")

  # Neu origin dang tro TEMPLATE cong khai -> chuyen thanh 'upstream', KHONG luu
  # vault private vao do.
  if [[ "$CURRENT_REMOTE" == *"Viindoo/ai-obsidian-vault"* ]]; then
    warn "origin dang tro template CONG KHAI: $CURRENT_REMOTE"
    info "Khong nen luu vault private vao day - chuyen thanh 'upstream'."
    git -C "$VAULT_PATH" remote rename origin upstream 2>/dev/null \
      || { git -C "$VAULT_PATH" remote remove origin 2>/dev/null; \
           git -C "$VAULT_PATH" remote add upstream "$CURRENT_REMOTE"; }
    CURRENT_REMOTE=""
    ok "Template -> remote 'upstream' (nhan update co che)"
  fi

  if [[ -n "$CURRENT_REMOTE" ]]; then
    ok "git remote origin (backup private): $CURRENT_REMOTE"
  else
    echo ""
    echo -n "  Tao private repo GitHub de backup vault? (Y/n) [Y]: "
    read -r CREATE_REPO; CREATE_REPO="${CREATE_REPO:-y}"
    if [[ "$CREATE_REPO" == "y" || "$CREATE_REPO" == "Y" ]]; then
      GH_USER="$(gh api user --jq .login 2>/dev/null || echo "")"
      echo -n "  Ten private repo [obsidian-vault]: "
      read -r REPO_NAME; REPO_NAME="${REPO_NAME:-obsidian-vault}"
      # Dam bao co commit dau tien de push (PII hook chay khi commit)
      if ! git -C "$VAULT_PATH" rev-parse --verify HEAD &>/dev/null \
         || [[ -n "$(git -C "$VAULT_PATH" status --porcelain)" ]]; then
        git -C "$VAULT_PATH" add -A
        git -C "$VAULT_PATH" commit -q -m "init: AI vault" || \
          warn "Commit dau that bai (PII hook chan?) - kiem tra roi commit tay"
      fi
      if gh repo create "$REPO_NAME" --private --source="$VAULT_PATH" --remote=origin --push; then
        ok "Da tao private repo + push: ${GH_USER:+$GH_USER/}$REPO_NAME"
        git -C "$VAULT_PATH" remote get-url upstream &>/dev/null \
          || git -C "$VAULT_PATH" remote add upstream https://github.com/Viindoo/ai-obsidian-vault.git
        ok "upstream = Viindoo/ai-obsidian-vault (de 'update-mechanism.sh' nhan update)"
      else
        warn "Khong tao duoc repo (co the da ton tai ${GH_USER:+$GH_USER/}$REPO_NAME)."
        info "  Tao tay: gh repo create <ten> --private --source=\"$VAULT_PATH\" --remote=origin --push"
      fi
    else
      echo -n "  Hoac nhap URL private repo da co (Enter de bo qua): "
      read -r GIT_REMOTE
      if [[ -n "$GIT_REMOTE" ]]; then
        git -C "$VAULT_PATH" remote add origin "$GIT_REMOTE"
        ok "Da them remote origin: $GIT_REMOTE"
      else
        warn "Chua set remote - vault se khong tu dong backup len GitHub"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 7. Tong ket va goi y doctor
# ---------------------------------------------------------------------------
hdr "7. Hoan thanh"
echo ""
ok "Cai dat xong! Tiep theo:"
echo ""
echo "  1. Mo vault trong Obsidian:"
echo "     Obsidian -> Open folder as vault -> $VAULT_PATH"
echo "     -> 'Trust author and enable plugins' (bat buoc)"
echo ""
echo "  2. Kiem tra toan bo cai dat:"
echo "     bash $SCRIPT_DIR/doctor.sh"
echo ""
echo "  3. (Codex) Neu su dung Codex CLI, chay: codex"
echo "     Roi go: /hooks  -> 'y' de trust SessionStart hook"
echo ""
echo "  4. Dang nhap bang goi subscription (KHONG can API key):"
echo "     claude  -> /login (Claude Pro/Max)  |  codex -> Sign in with ChatGPT  |  gemini -> tai khoan Google"
echo ""
echo -e "${YELLOW}Chay ./doctor.sh ngay bay gio de kiem tra?${RESET}"
echo -n "  (y/n) [y]: "
read -r RUN_DOCTOR
RUN_DOCTOR="${RUN_DOCTOR:-y}"
if [[ "$RUN_DOCTOR" == "y" ]]; then
  bash "$SCRIPT_DIR/doctor.sh"
fi
