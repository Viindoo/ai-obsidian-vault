#!/usr/bin/env bash
# =============================================================================
# sanitize-template.sh - Maintainer-side CI publish gate
# =============================================================================
# Chay truoc khi publish template repo. Scan tat ca file trong repo cho
# DENYLIST stopwords. Exit 1 neu co hit (block publish).
#
# Usage:
#   bash scripts/sanitize-template.sh [--check-only] [--allowlist-file path] [--denylist-file path]
#
# Allowlist exception: file .sanitize-allowlist (1 ERE/dong) hoac --allowlist-file.
#
# DENYLIST 2 lop:
#   1. SHIP cong khai (trong script): chi pattern GENERIC - secret/token regex,
#      duong dan /home/<user> bat ky, email ca nhan gmail/yahoo/... (regex, khong
#      liet ke dia chi cu the). Khong lo ten nguoi/cong ty/customer/codename.
#   2. RIENG (file .sanitize-denylist, GITIGNORED): stopword cu the cua to chuc -
#      ten cong ty, customer, project codename, ten/email ca nhan. Maintainer giu
#      local, KHONG publish. Script tu nap them tu file nay neu ton tai.
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

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
ALLOWLIST_FILE="${REPO_ROOT}/.sanitize-allowlist"
DENYLIST_FILE="${REPO_ROOT}/.sanitize-denylist"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --allowlist-file) ALLOWLIST_FILE="$2"; shift 2 ;;
    --denylist-file)  DENYLIST_FILE="$2"; shift 2 ;;
    # --check-only: alias mac dinh (chi scan, exit 1 neu co hit). Dung boi CI publish-gate.
    --check-only) shift ;;
    -h|--help)
      echo "Usage: $0 [--check-only] [--allowlist-file <path>] [--denylist-file <path>]"
      echo "  --check-only      : chi scan + exit code (hanh vi mac dinh), dung cho CI"
      echo "  --allowlist-file  : exception (mac dinh .sanitize-allowlist, 1 ERE/dong)"
      echo "  --denylist-file   : stopword rieng to chuc/ca nhan (mac dinh .sanitize-denylist,"
      echo "                      file nay GITIGNORED - khong ship cong khai)"
      exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# DENYLIST - moi phan tu la pattern grep ERE
# Phan SHIP cong khai chi chua pattern GENERIC (khong lo ten nguoi/cong ty/email
# cu the). Stopword rieng (ten cong ty, customer, codename, email ca nhan) dat
# trong file .sanitize-denylist (GITIGNORED) - maintainer giu local, khong publish.
# ---------------------------------------------------------------------------
DENYLIST=(
  # Tokens / secrets (generic)
  "ghp_[A-Za-z0-9]{36}"
  "gh[opsu]_[A-Za-z0-9]{36}"
  "github_pat_[A-Za-z0-9_]{20,}"
  "AKIA[0-9A-Z]{16}"
  "sk-ant-[A-Za-z0-9_-]{20,}"
  "AIza[A-Za-z0-9_-]{30,}"
  "BEGIN (RSA |OPENSSH |EC |PGP )?PRIVATE KEY"

  # Duong dan home lo username (generic - bat moi /home/<user>)
  "/home/[a-zA-Z0-9_.-]+/"
  "/Users/[a-zA-Z0-9_.-]+/"

  # Email ca nhan (generic - bat gmail/yahoo/... ma khong can liet ke dia chi cu the)
  "[a-zA-Z0-9._%+-]+@(gmail|yahoo|hotmail|outlook|icloud|proton(mail)?)\\.(com|me)"
)

# Nap stopword rieng to chuc/ca nhan tu file gitignored (neu co)
if [[ -f "$DENYLIST_FILE" ]]; then
  while IFS= read -r dl_line; do
    [[ -z "$dl_line" || "$dl_line" =~ ^[[:space:]]*# ]] && continue
    DENYLIST+=("$dl_line")
  done < "$DENYLIST_FILE"
fi

# ---------------------------------------------------------------------------
# Doc allowlist exception
# ---------------------------------------------------------------------------
ALLOWLIST_PATTERNS=()
if [[ -f "$ALLOWLIST_FILE" ]]; then
  while IFS= read -r line; do
    # Bo qua dong trong va comment
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    ALLOWLIST_PATTERNS+=("$line")
  done < "$ALLOWLIST_FILE"
  info "Allowlist: ${#ALLOWLIST_PATTERNS[@]} exception(s) tu $ALLOWLIST_FILE"
fi

# Ham kiem tra xem 1 line co nam trong allowlist khong
_is_allowed() {
  local line="$1"
  for pat in "${ALLOWLIST_PATTERNS[@]}"; do
    if [[ "$line" =~ $pat ]]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Sanitize Template - PII/Private Scan ===${RESET}"
echo "Repo: $REPO_ROOT"
echo ""

# Files can bao gom (text, skip binary + .git)
# Dung git ls-files de chi scan file trong repo
cd "$REPO_ROOT"

TOTAL_HITS=0
declare -A PATTERN_HITS

for pattern in "${DENYLIST[@]}"; do
  PATTERN_HITS["$pattern"]=0
done

# Lay danh sach file text tu git (exclude .git/ va binary)
# Them cac phan mo rong de skip
SKIP_EXTENSIONS="jpg|jpeg|png|gif|svg|ico|pdf|zip|gz|tar|mp4|mov|mp3|ttf|woff|woff2|eot|otf|exe|bin|lock"

while IFS= read -r filepath; do
  # Skip file binary va cac extension khong can scan
  if [[ "$filepath" =~ \.($SKIP_EXTENSIONS)$ ]]; then
    continue
  fi
  # Skip .git/
  [[ "$filepath" =~ ^\.git/ ]] && continue
  # Skip vendored third-party plugin code (minified JS, khong phai noi dung cua ta)
  [[ "$filepath" =~ ^vault-skeleton/\.obsidian/plugins/ ]] && continue
  # Skip ban than script nay (de tranh false positive)
  [[ "$filepath" == "scripts/sanitize-template.sh" ]] && continue
  # Skip PII hook (chua chinh cac regex pattern dinh nghia: ghp_, AKIA, ...)
  [[ "$filepath" == ".github/hooks/pre-commit" ]] && continue
  # Skip allowlist file
  [[ "$filepath" == ".sanitize-allowlist" ]] && continue

  # Scan tung pattern
  for pattern in "${DENYLIST[@]}"; do
    # grep -n: so dong, -E: extended regex, -i: case sensitive (bo -i de chinh xac)
    # Mot so pattern la case-sensitive (AKIA, ghp_, ...) nen khong dung -i
    while IFS= read -r hit_line; do
      # Kiem tra allowlist
      if _is_allowed "$hit_line"; then
        continue
      fi
      TOTAL_HITS=$((TOTAL_HITS + 1))
      PATTERN_HITS["$pattern"]=$((PATTERN_HITS["$pattern"] + 1))
      fail "${filepath}: ${hit_line}"
    done < <(grep -nE "$pattern" "$filepath" 2>/dev/null || true)
  done
done < <(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')

# ---------------------------------------------------------------------------
# Tong ket
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Ket qua ---${RESET}"

if [[ "$TOTAL_HITS" -eq 0 ]]; then
  ok "PASS: Khong tim thay stopword nao trong $TOTAL_HITS kiem tra."
  exit 0
else
  echo ""
  echo -e "${RED}FAIL: Tim thay ${TOTAL_HITS} hit(s) chua lam sach.${RESET}"
  echo ""
  echo "Chi tiet theo pattern:"
  for pattern in "${DENYLIST[@]}"; do
    count="${PATTERN_HITS[$pattern]}"
    if [[ "$count" -gt 0 ]]; then
      echo -e "  ${RED}${count} hit(s)${RESET}: $pattern"
    fi
  done
  echo ""
  warn "Sua cac hit tren truoc khi publish."
  warn "De them exception: them pattern ERE vao .sanitize-allowlist (1 dong/pattern)"
  echo ""
  exit 1
fi
