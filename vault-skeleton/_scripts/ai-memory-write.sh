#!/usr/bin/env bash
# ai-memory-write.sh - runtime-agnostic AI-Memory writer (SSOT for all 3 AI CLIs).
#
# Any agent (Claude Code skill, Codex CLI, Gemini CLI) invokes this via its shell
# tool to capture a structured memory into
#   <vault>/Engineering/AI-Memory/{type}s/<domain>/
# with valid v3 frontmatter, then regenerates the grep indexes + digest.
#
# WHY a script (not per-runtime logic): "skills" are Claude-Code-only and a hook
# cannot summarize (no model). The summary CONTENT is composed by the calling
# MODEL; this script only standardizes FORMAT + placement + index identically for
# all runtimes, so memory written by Codex/Gemini matches the CC skills' output.
#
# Usage:
#   ai-memory-write.sh --agent <claude-code|codex-cli|gemini-cli> \
#     --type <session|pattern|failure|orchestration> --domain <d> \
#     --slug <kebab> --title "<t>" [--summary "<s>"] \
#     [--outcome success|partial|failure] [--severity low|medium|high] \
#     [--pattern <p>] [--shape <s>] [--agents "<list>"] \
#     [--when-to-use "<w>"] [--confidence low|medium|high] [--evidence-count N] \
#     [--scope <s>] [--model <m>] [--body-file <f> | body on stdin] [--force]
set -uo pipefail

# Resolve VAULT dynamically: 3 levels up from _scripts/ = vault root.
# Override by setting VAULT_PATH env var before calling this script.
VAULT="${VAULT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AM="$VAULT/Engineering/AI-Memory"
SCRIPTS="$VAULT/Engineering/AI-Memory/_scripts"
[ -d "$AM" ] || { echo "ai-memory-write: AI-Memory not found at $AM" >&2; exit 1; }

agent="" type="" domain="" slug="" title="" summary="" outcome="success"
severity="medium" pattern="" shape="" agents="" when_to_use="" confidence="medium"
evidence_count="1" scope="internal" body_file="" force=0 model=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) agent="$2"; shift 2;;
    --type) type="$2"; shift 2;;
    --domain) domain="$2"; shift 2;;
    --slug) slug="$2"; shift 2;;
    --title) title="$2"; shift 2;;
    --summary) summary="$2"; shift 2;;
    --outcome) outcome="$2"; shift 2;;
    --severity) severity="$2"; shift 2;;
    --pattern) pattern="$2"; shift 2;;
    --shape) shape="$2"; shift 2;;
    --agents) agents="$2"; shift 2;;
    --when-to-use) when_to_use="$2"; shift 2;;
    --confidence) confidence="$2"; shift 2;;
    --evidence-count) evidence_count="$2"; shift 2;;
    --scope) scope="$2"; shift 2;;
    --model) model="$2"; shift 2;;
    --body-file) body_file="$2"; shift 2;;
    --force) force=1; shift;;
    *) echo "ai-memory-write: unknown arg '$1'" >&2; exit 2;;
  esac
done

for v in agent type domain slug title; do
  eval "val=\${$v}"
  [ -n "$val" ] || { echo "ai-memory-write: --$v is required" >&2; exit 2; }
done
case "$type" in
  session|pattern|failure|orchestration) ;;
  *) echo "ai-memory-write: --type must be session|pattern|failure|orchestration" >&2; exit 2;;
esac

if [ -n "$body_file" ]; then
  [ -f "$body_file" ] || { echo "ai-memory-write: --body-file not found: $body_file" >&2; exit 2; }
  body="$(cat "$body_file")"
elif [ ! -t 0 ]; then
  body="$(cat)"
else
  body=""
fi

# Portability/PII guard - WARN only (the vault pre-commit hook is the hard gate).
guard="$(printf '%s\n%s\n' "$title $summary" "$body" \
  | grep -nE '/home/[A-Za-z0-9_]+/|/Users/|/root/|[A-Za-z0-9._%+-]+@(gmail|googlemail)\.com' || true)"
[ -n "$guard" ] && { echo "ai-memory-write: WARNING possible local-path/PII (not blocked):" >&2; echo "$guard" >&2; }

DATE="$(date +%F)"; TS="$(date +%Y-%m-%d-%H%M)"
DIR="$AM/${type}s/$domain"; mkdir -p "$DIR"
case "$type" in
  session)       file="$DIR/${DATE}_${agent}_${slug}.md"; ftype="session-report";     status="active";   atag="session-report";;
  pattern)       file="$DIR/${slug}.md";                   ftype="pattern";            status="evergreen"; atag="pattern";;
  failure)       file="$DIR/${TS}_${slug}.md";             ftype="failure-log";        status="evergreen"; atag="failure";;
  orchestration) file="$DIR/${DATE}_${agent}_${slug}.md";  ftype="orchestration-log";  status="active";   atag="orchestration-log";;
esac
[ -e "$file" ] && [ "$force" -ne 1 ] && { echo "ai-memory-write: refusing to overwrite $file (use --force)" >&2; exit 3; }

esc() { printf '%s' "$1" | sed 's/"/'"'"'/g'; }
{
  echo "---"
  echo "title: \"$(esc "$title")\""
  echo "type: $ftype"
  echo "domain: $domain"
  echo "status: $status"
  echo "tags: [domain/$domain, activity/$atag, status/$status, lifecycle/area]"
  [ -n "$summary" ] && echo "summary: \"$(esc "$summary")\""
  echo "created: $DATE"
  echo "updated: $DATE"
  echo "agent: $agent"
  [ -n "$model" ] && echo "model: $model"
  echo "scope: $scope"
  case "$type" in
    session)       echo "outcome: $outcome";;
    orchestration) echo "outcome: $outcome"; [ -n "$shape" ]  && echo "shape: $shape"; [ -n "$agents" ] && echo "agents: \"$(esc "$agents")\"";;
    failure)       [ -n "$pattern" ] && echo "pattern: $pattern"; echo "severity: $severity";;
    pattern)       [ -n "$when_to_use" ] && echo "when_to_use: \"$(esc "$when_to_use")\""; echo "confidence: $confidence"; echo "evidence_count: $evidence_count";;
  esac
  echo "---"
  echo ""
  printf '%s\n' "$body"
} > "$file"
echo "ai-memory-write: wrote $file"

# Regenerate indexes + digest from frontmatter (SSOT - the indexes are DO-NOT-EDIT
# generated files; never hand-append). Best-effort: a regen failure never loses the
# written file.
[ -x "$SCRIPTS/regen-ai-memory-index.sh" ] && { "$SCRIPTS/regen-ai-memory-index.sh" >/dev/null 2>&1 \
  && echo "ai-memory-write: indexes regenerated" || echo "ai-memory-write: WARN index regen failed" >&2; }
[ -x "$SCRIPTS/gen-memory-digest.sh" ] && { "$SCRIPTS/gen-memory-digest.sh" >/dev/null 2>&1 \
  && echo "ai-memory-write: digest regenerated" || echo "ai-memory-write: WARN digest regen failed" >&2; }
echo "ai-memory-write: done -> ${type}/${domain}/$(basename "$file")"
