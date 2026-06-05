#!/usr/bin/env bash
# =============================================================================
# install-obsidian-plugins.sh - Cai community plugin theo CO CHE CHINH THUC
# =============================================================================
# KHONG bundle/copy binary plugin tu may khac. Thay vao do, tai tung plugin tu
# GitHub RELEASE CHINH THUC cua chinh plugin do - dung nguon ma Obsidian tu tai.
#
# Luong:
#   1. Doc danh sach id tu .obsidian/community-plugins.json
#   2. Resolve id -> repo qua registry chinh thuc obsidianmd/obsidian-releases
#   3. Tai manifest.json + main.js (+ styles.css) tu release moi nhat cua repo
#      vao .obsidian/plugins/<id>/  (giu nguyen data.json config cua ta)
#
# Config plugin (data.json: Auto Note Mover rules, Templater maps...) la cua ta,
# duoc ship trong repo va GIU NGUYEN - chi code plugin moi tai tu upstream.
#
# Usage: bash install-obsidian-plugins.sh [VAULT_PATH]
#   VAULT_PATH mac dinh = vault-skeleton trong repo (cho maintainer test),
#   hoac truyen path vault that cua member.
# Yeu cau: gh (uu tien, tranh rate-limit) hoac curl. jq.
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'
ok()   { echo -e "  ${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*" >&2; }
info() { echo -e "  ${CYAN}[INFO]${RESET} $*"; }

VAULT_PATH="${1:-${VAULT_PATH:-$REPO_ROOT/vault-skeleton}}"
PLUGINS_DIR="$VAULT_PATH/.obsidian/plugins"
CP_LIST="$VAULT_PATH/.obsidian/community-plugins.json"

echo ""
echo -e "${BOLD}[install-obsidian-plugins] Cai plugin tu nguon CHINH THUC${RESET}"
echo "  Vault: $VAULT_PATH"

command -v jq >/dev/null 2>&1 || { fail "Can 'jq'. Cai roi chay lai."; exit 1; }
[[ -f "$CP_LIST" ]] || { fail "Khong tim thay $CP_LIST"; exit 1; }

# Xac dinh phuong thuc tai: gh (uu tien) hoac curl
HAVE_GH=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then HAVE_GH=1; fi
if [[ "$HAVE_GH" -eq 0 ]] && ! command -v curl >/dev/null 2>&1; then
  fail "Can 'gh' (da auth) hoac 'curl' de tai plugin."
  exit 1
fi

# --- Lay registry chinh thuc (id -> repo) ---
REGISTRY="$(mktemp)"
REG_URL="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json"
if curl -fsSL "$REG_URL" -o "$REGISTRY" 2>/dev/null && [[ -s "$REGISTRY" ]]; then
  info "Registry chinh thuc: $(jq length "$REGISTRY") plugin"
else
  fail "Khong tai duoc registry chinh thuc. Kiem tra mang."
  rm -f "$REGISTRY"; exit 1
fi

# --- Tai 1 asset tu release moi nhat cua repo ---
# $1=repo  $2=asset_name  $3=dest_file  -> return 0 neu tai duoc
_download_asset() {
  local repo="$1" asset="$2" dest="$3"
  if [[ "$HAVE_GH" -eq 1 ]]; then
    gh release download --repo "$repo" --pattern "$asset" --output "$dest" --clobber >/dev/null 2>&1
  else
    curl -fsSL "https://github.com/${repo}/releases/latest/download/${asset}" -o "$dest" 2>/dev/null
  fi
}

TOTAL=0; DONE=0; FAILED=()
for id in $(jq -r '.[]' "$CP_LIST"); do
  TOTAL=$((TOTAL+1))
  repo="$(jq -r --arg id "$id" '.[] | select(.id==$id) | .repo' "$REGISTRY" | head -1)"
  if [[ -z "$repo" || "$repo" == "null" ]]; then
    warn "$id: khong co trong registry chinh thuc - bo qua (co the la plugin rieng/BRAT)"
    FAILED+=("$id"); continue
  fi
  dest="$PLUGINS_DIR/$id"
  mkdir -p "$dest"
  # manifest.json + main.js la BAT BUOC; styles.css TUY CHON
  if _download_asset "$repo" "manifest.json" "$dest/manifest.json" \
     && _download_asset "$repo" "main.js" "$dest/main.js"; then
    _download_asset "$repo" "styles.css" "$dest/styles.css" || true
    ver="$(jq -r '.version // "?"' "$dest/manifest.json" 2>/dev/null)"
    ok "$id v$ver  (tu $repo, giu data.json config)"
    DONE=$((DONE+1))
  else
    fail "$id: tai that bai tu $repo"
    FAILED+=("$id")
  fi
done
rm -f "$REGISTRY"

echo ""
echo -e "  ${BOLD}Ket qua: ${DONE}/${TOTAL} plugin tai tu nguon chinh thuc.${RESET}"
if (( ${#FAILED[@]} > 0 )); then
  warn "Khong tai duoc: ${FAILED[*]}"
  info "Cai tay: mo Obsidian -> Settings -> Community plugins -> Browse -> tim ten plugin -> Install"
  exit 1
fi
ok "Tat ca plugin da cai tu GitHub release chinh thuc."
