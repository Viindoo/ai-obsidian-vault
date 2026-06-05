#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - Entry point: curl-tai-xem-roi-chay
# =============================================================================
# Usage 1-lenh:
#   curl -fsSL https://raw.githubusercontent.com/Viindoo/ai-obsidian-vault/master/bootstrap.sh | bash
#
# Hoac neu da clone:
#   bash bootstrap.sh
#
# bootstrap.sh se:
#   1. In banner + URL repo de doc truoc khi chay install.sh
#   2. Kiem tra/clone repo
#   3. exec install.sh
#
# KHONG lam gi nguy hiem neu chay nhieu lan (idempotent).
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }

REPO_URL="https://github.com/Viindoo/ai-obsidian-vault"
REPO_GIT="https://github.com/Viindoo/ai-obsidian-vault.git"
DEFAULT_CLONE_DIR="$HOME/git/ai-obsidian-vault"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║         AI Vault - Multi-CLI AI Memory System         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "  Repository : $REPO_URL"
echo "  Docs       : $REPO_URL/blob/master/README.md"
echo ""
echo -e "${YELLOW}  Vui long doc README truoc khi tiep tuc:${RESET}"
echo "  $REPO_URL#readme"
echo ""
echo -n "  Tiep tuc cai dat? (y/n) [y]: "
read -r PROCEED
PROCEED="${PROCEED:-y}"
if [[ "$PROCEED" != "y" ]]; then
  info "Da huy. Doc README roi chay lai khi san sang."
  exit 0
fi

# ---------------------------------------------------------------------------
# Xac dinh REPO_DIR
# ---------------------------------------------------------------------------
# Truong hop 1: bootstrap.sh duoc chay tu trong repo (da clone)
SCRIPT_DIR=""
# Detect neu co BASH_SOURCE (khong co khi chay qua pipe curl|bash)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi

REPO_DIR=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/install.sh" ]]; then
  # Da chay tu trong repo
  REPO_DIR="$SCRIPT_DIR"
  ok "Dang chay tu repo hien co: $REPO_DIR"
else
  # Truong hop 2: chay qua curl|bash hoac tu ngoai repo - can clone
  echo ""
  echo -e "${BOLD}--- Clone repo ---${RESET}"

  echo -n "  Clone repo vao dau? [$DEFAULT_CLONE_DIR]: "
  read -r CLONE_DIR
  CLONE_DIR="${CLONE_DIR:-$DEFAULT_CLONE_DIR}"

  if [[ -d "$CLONE_DIR/.git" ]]; then
    ok "Repo da ton tai: $CLONE_DIR"
    # Pull de dam bao moi nhat
    if git -C "$CLONE_DIR" pull --rebase=false --autostash origin master 2>/dev/null; then
      ok "git pull: cap nhat thanh cong"
    else
      warn "git pull gap loi - tiep tuc voi version hien co"
    fi
    REPO_DIR="$CLONE_DIR"
  else
    # Kiem tra thu muc parent ton tai
    PARENT_DIR="$(dirname "$CLONE_DIR")"
    mkdir -p "$PARENT_DIR"

    info "Cloning $REPO_GIT -> $CLONE_DIR ..."
    if git clone "$REPO_GIT" "$CLONE_DIR"; then
      ok "Clone thanh cong: $CLONE_DIR"
      REPO_DIR="$CLONE_DIR"
    else
      echo ""
      warn "HTTPS clone that bai. Thu voi SSH (can GitHub account)..."
      SSH_GIT="git@github.com:Viindoo/ai-obsidian-vault.git"
      if git clone "$SSH_GIT" "$CLONE_DIR"; then
        ok "SSH clone thanh cong: $CLONE_DIR"
        REPO_DIR="$CLONE_DIR"
      else
        echo ""
        echo "Clone that bai. Cach thu cong:"
        echo "  1. Clone template (KHONG fork - vault phai private):"
        echo "     git clone $REPO_URL <thu-muc>"
        echo "  2. cd <thu-muc> && bash install.sh"
        echo "  (Installer se tao private repo rieng cho vault cua ban)"
        exit 1
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Verify install.sh ton tai
# ---------------------------------------------------------------------------
if [[ ! -f "$REPO_DIR/install.sh" ]]; then
  echo ""
  echo "Loi: install.sh khong tim thay trong $REPO_DIR"
  echo "Dam bao ban da clone dung repo va branch master."
  exit 1
fi

# ---------------------------------------------------------------------------
# Exec install.sh
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Bat dau install.sh ---${RESET}"
echo "  Repo: $REPO_DIR"
echo ""

exec bash "$REPO_DIR/install.sh"
