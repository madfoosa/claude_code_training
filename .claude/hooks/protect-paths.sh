#!/usr/bin/env bash
# PreToolUse (Edit|Write|NotebookEdit) -- refuse edits to protected paths.
#
# CLAUDE.md asks Claude not to touch these files. This makes it true. The
# difference between a request and a guarantee is the whole reason this file
# exists -- see docs/strategy/06-guardrails-permissions.md.
#
# Escape hatch: set CLAUDE_ALLOW_PROTECTED=1 in the environment for a session
# that genuinely needs to edit these. That is a deliberate, visible act; routing
# around the hook by other means is not.

set -uo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"${input}")
[[ -n "${file}" ]] || exit 0

if [[ "${CLAUDE_ALLOW_PROTECTED:-0}" == "1" ]]; then
  exit 0
fi

root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${file#"${root}/"}"

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

case "${rel}" in
  .env.example | *.env.example)
    # The documented template is safe and is meant to be edited.
    ;;
  .env | .env.* | */.env | */.env.*)
    deny "Blocked: ${rel} holds environment secrets. Edit it yourself, or add the key to .env.example instead and tell the user what to set."
    ;;
  secrets/* | */secrets/*)
    deny "Blocked: ${rel} is under a secrets directory. Nothing there should be read or written by an agent."
    ;;
  uv.lock | pnpm-lock.yaml | package-lock.json | yarn.lock | */uv.lock | */pnpm-lock.yaml | */package-lock.json | */yarn.lock)
    deny "Blocked: ${rel} is a lockfile. Lockfiles are generated, never hand-edited -- change the manifest and run 'make setup' so the resolver regenerates it."
    ;;
  .github/workflows/*)
    deny "Blocked: ${rel} defines CI, which is the check on your own work. Changing it needs an explicit request from the user. Say what you would change and why, then wait."
    ;;
esac

exit 0
