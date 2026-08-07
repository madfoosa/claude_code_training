#!/usr/bin/env bash
# PostToolUse (Edit|Write) -- format the touched file, feed back what's left.
#
# Step 3 of the Definition of Done ("Formatted") is machine-enforced here so it
# never costs a turn. Anything the formatter cannot fix on its own comes back as
# additionalContext, which lands in Claude's next turn -- so lint errors get
# corrected immediately rather than at the end of the change.
#
# Never blocks: a formatter failure must not stop work.

set -uo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"${input}")
[[ -n "${file}" ]] || exit 0
[[ -f "${file}" ]] || exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${file#"${root}/"}"

case "${rel}" in
  *.py | *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.json) ;;
  *) exit 0 ;;
esac

cd "${root}" 2>/dev/null || exit 0

output=$(make fmt-file FILE="${rel}" 2>&1) || true

# Strip make's own noise; only real diagnostics should reach the model.
output=$(grep -v -e '^make\[' -e '^make:' <<<"${output}" || true)
output=$(sed -e 's/[[:space:]]*$//' <<<"${output}" | sed -e '/^$/d')

[[ -n "${output}" ]] || exit 0

jq -n --arg ctx "${rel} was auto-formatted. Remaining lint diagnostics the formatter could not fix:

${output}

Fix these now, in this file, before moving on. Do not suppress them with a noqa, eslint-disable, or type-ignore comment." \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
