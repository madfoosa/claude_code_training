#!/usr/bin/env bash
# SessionStart -- orient Claude before it does anything.
#
# Every session starts cold. Without this, the first few turns are spent
# rediscovering which branch we're on and what was in flight. See
# docs/strategy/10-session-continuity.md.
#
# Output: JSON on stdout carrying additionalContext. Never blocks.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

STAMP=".make-check-stamp"
lines=()

branch=$(git branch --show-current 2>/dev/null || echo "detached")
lines+=("Branch: ${branch}")

dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "${dirty}" == "0" ]]; then
  lines+=("Working tree: clean")
else
  lines+=("Working tree: ${dirty} uncommitted change(s)")
  while IFS= read -r f; do
    lines+=("  ${f}")
  done < <(git status --porcelain 2>/dev/null | head -10)
  if (( dirty > 10 )); then
    lines+=("  ... and $(( dirty - 10 )) more")
  fi
fi

if [[ -f "${STAMP}" ]]; then
  lines+=("Last \`make check\`: $(date -r "${STAMP}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo unknown)")
else
  lines+=("Last \`make check\`: never in this working tree")
fi

recent=$(git log --oneline -3 2>/dev/null || true)
if [[ -n "${recent}" ]]; then
  lines+=("" "Recent commits:")
  while IFS= read -r c; do lines+=("  ${c}"); done <<<"${recent}"
fi

if [[ -f "HANDOFF.md" ]]; then
  lines+=("" "--- HANDOFF.md (from the previous session) ---")
  while IFS= read -r h; do lines+=("${h}"); done < <(head -60 HANDOFF.md)
  lines+=("--- end handoff ---")
  lines+=("Treat the Next Action above as the starting point unless told otherwise.")
fi

context=$(printf '%s\n' "${lines[@]}")

jq -n --arg ctx "${context}" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
