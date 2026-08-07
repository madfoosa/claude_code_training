#!/usr/bin/env bash
# Stop -- refuse to end a turn on unverified source changes.
#
# This is what makes the Definition of Done a ladder rather than a wish. If
# tracked source has been modified but `make check` has not run since, the turn
# is blocked with an instruction to run it.
#
# `make check` touches .make-check-stamp on success; that file's mtime is the
# entire state this hook depends on.
#
# Honours stop_hook_active so a block cannot loop forever.

set -uo pipefail

input=$(cat)

if [[ "$(jq -r '.stop_hook_active // false' <<<"${input}")" == "true" ]]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

STAMP=".make-check-stamp"

# Uncommitted source files. Committed work has already been through the gate;
# this is about what is in flight right now.
changed=()
while IFS= read -r line; do
  [[ -n "${line}" ]] || continue
  path="${line:3}"
  path="${path##* -> }"     # renames arrive as "old -> new"
  path="${path%\"}"
  path="${path#\"}"
  case "${path}" in
    *.py | *.ts | *.tsx | *.js | *.jsx) changed+=("${path}") ;;
  esac
done < <(git status --porcelain 2>/dev/null)

(( ${#changed[@]} )) || exit 0

stale=0
unverified=()
if [[ ! -f "${STAMP}" ]]; then
  stale=1
  unverified=("${changed[@]}")
else
  for f in "${changed[@]}"; do
    [[ -f "${f}" ]] || continue
    if [[ "${f}" -nt "${STAMP}" ]]; then
      stale=1
      unverified+=("${f}")
    fi
  done
fi

(( stale )) || exit 0

list=$(printf '  %s\n' "${unverified[@]}")

jq -n --arg reason "Source changed but \`make check\` has not run since:

${list}
Run \`make check\` now (or \`make check-py\` / \`make check-ts\` to scope it).

If it fails, fix the cause -- do not weaken a test, loosen a type, or add a
suppression comment to get past it. If you believe the change genuinely does not
need verifying, say so explicitly and explain why rather than ending silently." \
  '{decision: "block", reason: $reason}'
