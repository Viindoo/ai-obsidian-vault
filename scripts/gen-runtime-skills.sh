#!/usr/bin/env bash
# =============================================================================
# gen-runtime-skills.sh - Maintainer-side: gen Codex + Gemini skills tu Claude
# =============================================================================
# SSOT: vault-skeleton/.claude/skills/*/SKILL.md (source day du)
# Output:
#   vault-skeleton/.codex/skills/*/SKILL.md  (Claude fields stripped)
#   vault-skeleton/.gemini/skills/*/SKILL.md (Claude fields stripped)
#
# Rules strip co dinh:
#   - Xoa frontmatter field: disable-model-invocation
#   - Xoa Templater reference: dong chua "<% ... %>" hoac "tp.system"
#   - Rut gon description: lay 1 dong dau tien (den dau ".")
#   - Them/thay field "agent:" voi gia tri cung theo runtime
#
# Chay boi maintainer khi build template, KHONG phai end-user member.
#
# Usage: bash scripts/gen-runtime-skills.sh [--dry-run]
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

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]"
      echo "  Render Codex + Gemini skill variants tu Claude SSOT."
      echo "  --dry-run: chi hien thi, khong ghi file."
      exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

CLAUDE_SKILLS_DIR="${REPO_ROOT}/vault-skeleton/.claude/skills"
CODEX_SKILLS_DIR="${REPO_ROOT}/vault-skeleton/.codex/skills"
GEMINI_SKILLS_DIR="${REPO_ROOT}/vault-skeleton/.gemini/skills"

echo ""
echo -e "${BOLD}=== gen-runtime-skills (Maintainer) ===${RESET}"

if [[ ! -d "$CLAUDE_SKILLS_DIR" ]]; then
  fail "Claude skills dir khong ton tai: $CLAUDE_SKILLS_DIR"
  fail "Chac chan vault-skeleton/.claude/skills/ da co noi dung chua?"
  exit 1
fi

# ---------------------------------------------------------------------------
# Ham strip SKILL.md cho 1 runtime cu the
# $1 = source SKILL.md path
# $2 = dest SKILL.md path
# $3 = runtime: "codex" hoac "gemini"
# ---------------------------------------------------------------------------
_strip_skill() {
  local src="$1" dest="$2" runtime="$3"
  local dir
  dir="$(dirname "$dest")"
  [[ "$DRY_RUN" == "1" ]] || mkdir -p "$dir"

  # Dung Python3 de xu ly YAML frontmatter + body
  python3 - "$src" "$runtime" <<'PYEOF'
import sys, re

src_path = sys.argv[1]
runtime = sys.argv[2]

with open(src_path, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')

# Tach frontmatter va body
frontmatter_lines = []
body_lines = []
in_frontmatter = False
frontmatter_done = False
fm_delim_count = 0

for i, line in enumerate(lines):
    if i == 0 and line.strip() == '---':
        in_frontmatter = True
        fm_delim_count = 1
        frontmatter_lines.append(line)
        continue
    if in_frontmatter:
        if line.strip() == '---':
            fm_delim_count += 1
            frontmatter_lines.append(line)
            if fm_delim_count >= 2:
                in_frontmatter = False
                frontmatter_done = True
        else:
            frontmatter_lines.append(line)
    else:
        body_lines.append(line)

# Xu ly frontmatter
new_fm_lines = []
skip_next = False
for line in frontmatter_lines:
    if skip_next:
        # Skip dong tiep theo neu la gia tri multiline (bat dau bang khoang trang)
        if re.match(r'^\s+', line):
            continue
        else:
            skip_next = False

    # Strip field: disable-model-invocation
    if re.match(r'^disable-model-invocation\s*:', line):
        skip_next = False
        continue

    # Thay/them field: agent
    if re.match(r'^agent\s*:', line):
        new_fm_lines.append(f'agent: {runtime}')
        continue

    # Rut gon description: lay 1 cau dau (den dau ". ")
    if re.match(r'^description\s*:', line):
        # Lay phan sau "description:"
        m = re.match(r'^(description\s*:\s*)(.*)', line)
        if m:
            desc = m.group(2).strip()
            # Lay den dau ". " dau tien
            first_sentence = re.split(r'\.\s', desc)[0]
            if first_sentence and not first_sentence.endswith('.'):
                first_sentence += '.'
            new_fm_lines.append(f'description: {first_sentence}')
            continue

    new_fm_lines.append(line)

# Them agent field neu chua co
has_agent = any(re.match(r'^agent\s*:', l) for l in new_fm_lines)
if not has_agent and frontmatter_done:
    # Chen truoc dong "---" dong
    insert_idx = len(new_fm_lines) - 1
    new_fm_lines.insert(insert_idx, f'agent: {runtime}')

# Xu ly body: xoa dong Templater
new_body_lines = []
for line in body_lines:
    # Xoa dong chua Templater syntax
    if re.search(r'<%[^%]+%>', line):
        continue
    # Xoa dong chua tp.system (Templater API)
    if re.search(r'\btp\.system\b', line):
        continue
    new_body_lines.append(line)

result = '\n'.join(new_fm_lines + new_body_lines)
print(result, end='')
PYEOF
}

# ---------------------------------------------------------------------------
# Scan va gen tung skill
# ---------------------------------------------------------------------------
SKILL_COUNT=0
ERROR_COUNT=0

for claude_skill_dir in "$CLAUDE_SKILLS_DIR"/*/; do
  [[ -d "$claude_skill_dir" ]] || continue
  skill_name="$(basename "$claude_skill_dir")"
  src_file="${claude_skill_dir}/SKILL.md"

  if [[ ! -f "$src_file" ]]; then
    warn "Skill $skill_name: SKILL.md khong tim thay, bo qua"
    continue
  fi

  info "Gen skill: $skill_name"

  for runtime in "codex" "gemini"; do
    case "$runtime" in
      codex)  dest_dir="$CODEX_SKILLS_DIR/$skill_name" ;;
      gemini) dest_dir="$GEMINI_SKILLS_DIR/$skill_name" ;;
    esac
    dest_file="$dest_dir/SKILL.md"

    if [[ "$DRY_RUN" == "1" ]]; then
      info "  [DRY-RUN] would write: $dest_file"
    else
      mkdir -p "$dest_dir"
      if _strip_skill "$src_file" "$dest_file" "$runtime" > "$dest_file" 2>/dev/null; then
        ok "  $runtime: $dest_file"
      else
        fail "  $runtime: loi khi gen $dest_file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
      fi
    fi
  done

  SKILL_COUNT=$((SKILL_COUNT + 1))
done

# ---------------------------------------------------------------------------
# Tong ket
# ---------------------------------------------------------------------------
echo ""
if [[ "$ERROR_COUNT" -eq 0 ]]; then
  ok "Gen xong: $SKILL_COUNT skill(s) -> 2 runtime (codex + gemini)"
  if [[ "$DRY_RUN" == "0" ]]; then
    info "Nen commit cac file da gen:"
    echo "  git add ${CODEX_SKILLS_DIR} ${GEMINI_SKILLS_DIR}"
    echo "  git commit -m 'chore(skills): regen codex/gemini variants from claude SSOT'"
  fi
else
  fail "Hoan thanh voi $ERROR_COUNT loi. Kiem tra output ben tren."
  exit 1
fi
