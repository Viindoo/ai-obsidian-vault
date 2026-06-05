#!/usr/bin/env bash
# =============================================================================
# update-mechanism.sh - Cap nhat vault tu upstream (tag moi nhat)
# =============================================================================
# Chay: bash scripts/update-mechanism.sh
#
# Luong:
#   1. Kiem tra upstream remote ton tai
#   2. Fetch tag moi nhat tu upstream
#   3. In CHANGELOG diff giua tag hien tai vs tag moi (human-readable)
#   4. Tao backup branch
#   5. Merge tag moi (data duoc bao ve boi merge=ours)
#   6. Detect file mechanism member co the da sua (de nghi khoi phuc)
#   7. Re-render home config giu values tu .install-answers
#   8. Regen index + digest
#
# Yeu cau: .install-answers ton tai (da chay install.sh)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*" >&2; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
die()  { fail "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Doc .install-answers
# ---------------------------------------------------------------------------
ANSWERS_FILE="${REPO_ROOT}/.install-answers"
[[ -f "$ANSWERS_FILE" ]] || die ".install-answers khong tim thay. Chay install.sh truoc."

_read_answer() {
  local key="$1" default="${2:-}"
  local val
  val="$(grep "^${key}=" "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2- || echo "")"
  echo "${val:-$default}"
}

VAULT_PATH="$(_read_answer "VAULT_PATH")"
[[ -z "$VAULT_PATH" ]] && die "VAULT_PATH trong .install-answers trong. Chay install.sh truoc."

echo ""
echo -e "${BOLD}=== Update Mechanism ===${RESET}"
echo "Vault: $VAULT_PATH"
echo "Repo:  $REPO_ROOT"

# ---------------------------------------------------------------------------
# 1. Kiem tra upstream remote
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[1] Kiem tra upstream remote${RESET}"

cd "$REPO_ROOT"

UPSTREAM_URL="$(git remote get-url upstream 2>/dev/null || echo "")"
if [[ -z "$UPSTREAM_URL" ]]; then
  warn "Chua co upstream remote."
  echo -n "  Nhap URL upstream template repo (hoac Enter de bo qua): "
  read -r UPSTREAM_URL_INPUT
  if [[ -z "$UPSTREAM_URL_INPUT" ]]; then
    die "Khong co upstream - khong the update. Them bang: git remote add upstream <URL>"
  fi
  git remote add upstream "$UPSTREAM_URL_INPUT"
  ok "upstream added: $UPSTREAM_URL_INPUT"
else
  ok "upstream: $UPSTREAM_URL"
fi

# ---------------------------------------------------------------------------
# 2. Fetch tag moi nhat tu upstream
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[2] Fetch upstream tags${RESET}"

git fetch upstream --tags 2>/dev/null
ok "Fetch xong"

# Tim tag hien tai (latest local tag)
CURRENT_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
if [[ -z "$CURRENT_TAG" ]]; then
  CURRENT_TAG="(chua co tag)"
fi

# Tim tag moi nhat tu upstream (format semver v*.*.*)
LATEST_TAG="$(git tag -l 'v*' --sort=-version:refname | head -1 || echo "")"
if [[ -z "$LATEST_TAG" ]]; then
  die "Khong tim thay tag versioned (v*.*.*) tu upstream. Dam bao upstream co release tag."
fi

ok "Tag hien tai: $CURRENT_TAG"
ok "Tag moi nhat: $LATEST_TAG"

if [[ "$CURRENT_TAG" == "$LATEST_TAG" ]]; then
  echo ""
  ok "Da o version moi nhat ($LATEST_TAG). Khong can update."
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. Hien thi CHANGELOG diff
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[3] CHANGELOG tu ${CURRENT_TAG} -> ${LATEST_TAG}${RESET}"
echo ""

# Tim CHANGELOG file
CHANGELOG_FILE=""
for f in "CHANGELOG.md" "CHANGELOG" "CHANGES.md"; do
  if [[ -f "${REPO_ROOT}/$f" ]]; then
    CHANGELOG_FILE="$f"
    break
  fi
done

if [[ -n "$CHANGELOG_FILE" ]]; then
  # Hien thi phan CHANGELOG lien quan
  # Extract noi dung giua hai heading ## [version]
  if [[ "$CURRENT_TAG" == "(chua co tag)" ]]; then
    # Hien thi toan bo
    head -80 "${REPO_ROOT}/$CHANGELOG_FILE"
  else
    # Lay noi dung tu latest_tag den current_tag trong file
    awk "/^## \[${LATEST_TAG#v}\]/{p=1} p; /^## \[${CURRENT_TAG#v}\]/{exit}" \
      "${REPO_ROOT}/$CHANGELOG_FILE" 2>/dev/null || true
  fi
else
  # Fallback: hien thi git log
  info "CHANGELOG.md khong tim thay. Git log giua 2 tag:"
  git log --oneline "${CURRENT_TAG}..${LATEST_TAG}" 2>/dev/null || \
    git log --oneline "HEAD..${LATEST_TAG}" 2>/dev/null || \
    info "(Khong the lay log)"
fi

echo ""
echo -n "Tiep tuc update len $LATEST_TAG? (y/n) [y]: "
read -r CONFIRM
CONFIRM="${CONFIRM:-y}"
if [[ "$CONFIRM" != "y" ]]; then
  info "Da huy update."
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. Tao backup branch
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[4] Tao backup branch${RESET}"

BACKUP_BRANCH="backup/pre-update-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
ok "Backup branch tao: $BACKUP_BRANCH"
info "De rollback: git checkout $BACKUP_BRANCH"

# ---------------------------------------------------------------------------
# 5. Detect file mechanism co the bi sua boi member
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[5] Kiem tra file mechanism bi sua${RESET}"

# Danh sach file mechanism (upstream-owned, member KHONG nen sua)
MECHANISM_FILES=(
  "ETHOS.md"
  "CLAUDE.md"
  "AGENTS.md"
  "GEMINI.md"
  ".github/hooks/pre-commit"
  "_scripts/"
  "vault-skeleton/"
  "templates-home/"
  "scripts/"
  "install.sh"
  "bootstrap.sh"
  "doctor.sh"
)

MODIFIED_MECHANISM=()
for pattern in "${MECHANISM_FILES[@]}"; do
  # Kiem tra xem co thay doi local so voi upstream tag khong
  if git diff --name-only "upstream/${LATEST_TAG}" -- "$pattern" 2>/dev/null | grep -q .; then
    MODIFIED_MECHANISM+=("$pattern")
  elif git status --short -- "$pattern" 2>/dev/null | grep -q .; then
    MODIFIED_MECHANISM+=("$pattern (local unstaged)")
  fi
done

if [[ ${#MODIFIED_MECHANISM[@]} -gt 0 ]]; then
  warn "Phat hien thay doi tren file mechanism (upstream-owned):"
  for f in "${MODIFIED_MECHANISM[@]}"; do
    echo "    - $f"
  done
  echo ""
  warn "Khuyen nghi: KHONG sua file mechanism truc tiep."
  warn "Su dung override: ETHOS.local.md, CLAUDE.local.md, .claude/skills-local/"
  echo ""
  echo -n "Khoi phuc cac file nay ve ban upstream? (y/n) [n]: "
  read -r RESTORE_MECH
  RESTORE_MECH="${RESTORE_MECH:-n}"
  if [[ "$RESTORE_MECH" == "y" ]]; then
    for f in "${MODIFIED_MECHANISM[@]}"; do
      f_clean="${f% (local unstaged)}"
      git checkout "upstream/${LATEST_TAG}" -- "$f_clean" 2>/dev/null && \
        ok "  Restored: $f_clean" || \
        warn "  Khong the restore: $f_clean"
    done
  else
    info "Giu nguyen thay doi. Merge co the gap conflict - giai quyet thu cong neu can."
  fi
fi

# ---------------------------------------------------------------------------
# 6. Merge tag moi
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[6] Merge ${LATEST_TAG}${RESET}"

# Stash thay doi local chua commit
STASH_NEEDED=0
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  git stash push -m "update-mechanism auto-stash $(date +%Y%m%d-%H%M%S)"
  STASH_NEEDED=1
  ok "Local changes stashed"
fi

# Merge tag (merge=ours bao ve data files)
if git merge "$LATEST_TAG" --no-edit -m "chore: update to ${LATEST_TAG}" 2>/dev/null; then
  ok "Merge ${LATEST_TAG}: thanh cong"
else
  MERGE_EXIT=$?
  fail "Merge gap conflict (exit $MERGE_EXIT)!"
  echo ""
  echo "  Cac file conflict:"
  git diff --name-only --diff-filter=U 2>/dev/null || true
  echo ""
  echo "  De rollback ve truoc update:"
  echo "    git merge --abort"
  echo "    git checkout $BACKUP_BRANCH"
  echo ""
  echo "  Sau khi giai quyet conflict:"
  echo "    git add -A && git commit --no-edit"
  echo "    bash scripts/update-mechanism.sh  # (de re-render config)"
  [[ "$STASH_NEEDED" == "1" ]] && git stash pop 2>/dev/null || true
  exit 1
fi

# Pop stash
if [[ "$STASH_NEEDED" == "1" ]]; then
  git stash pop 2>/dev/null && ok "Stash restored" || warn "Stash pop gap loi - kiem tra thu cong"
fi

# ---------------------------------------------------------------------------
# 7. Re-render home config (giu values tu .install-answers)
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[7] Re-render home config${RESET}"

# Export bien tu .install-answers
export VAULT_PATH
export YOUR_NAME="$(_read_answer "YOUR_NAME")"
export YOUR_EMAIL="$(_read_answer "YOUR_EMAIL")"
export COMPANY_NAME="$(_read_answer "COMPANY_NAME")"
export OLLAMA_ENDPOINT="$(_read_answer "OLLAMA_ENDPOINT" "")"
export ENABLE_CODEX="$(_read_answer "ENABLE_CODEX" "y")"
export ENABLE_GEMINI="$(_read_answer "ENABLE_GEMINI" "y")"
export OS_TYPE

# Backup home config cu
BACKUP_DIR="${REPO_ROOT}/.backups/update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for f in \
  "$HOME/.claude/CLAUDE.md" \
  "$HOME/.claude/settings.json" \
  "$HOME/.codex/config.toml" \
  "$HOME/.gemini/settings.json"; do
  if [[ -f "$f" ]]; then
    fname="$(basename "$(dirname "$f")")-$(basename "$f")"
    cp "$f" "$BACKUP_DIR/$fname"
  fi
done
ok "Home config backup: $BACKUP_DIR"

# Re-render bang wire-runtimes.sh
bash "$SCRIPT_DIR/wire-runtimes.sh"
ok "Home config da re-render"

info "Backup cu tai: $BACKUP_DIR"

# ---------------------------------------------------------------------------
# 8. Regen index + digest
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}[8] Regen AI-Memory index + digest${RESET}"

AM_SCRIPTS="${VAULT_PATH}/_scripts"

if [[ -d "$AM_SCRIPTS" ]]; then
  if [[ -f "${AM_SCRIPTS}/regen-ai-memory-index.sh" ]]; then
    bash "${AM_SCRIPTS}/regen-ai-memory-index.sh" "$VAULT_PATH" 2>/dev/null && \
      ok "regen-ai-memory-index.sh: xong" || \
      warn "regen-ai-memory-index.sh: gap loi"
  fi
  if [[ -f "${AM_SCRIPTS}/gen-memory-digest.sh" ]]; then
    bash "${AM_SCRIPTS}/gen-memory-digest.sh" "$VAULT_PATH" 2>/dev/null && \
      ok "gen-memory-digest.sh: xong" || \
      warn "gen-memory-digest.sh: gap loi"
  fi
else
  warn "AM_SCRIPTS chua ton tai: $AM_SCRIPTS"
fi

# ---------------------------------------------------------------------------
# Tong ket
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Update hoan thanh ===${RESET}"
ok "Version moi: $LATEST_TAG"
ok "Backup branch: $BACKUP_BRANCH"
ok "Home config backup: $BACKUP_DIR"
echo ""
info "Nen chay doctor.sh de verify:"
echo "  bash doctor.sh"
