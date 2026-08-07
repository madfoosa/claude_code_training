#!/usr/bin/env bash
# Documentation gate. Run via `make lint-docs`; also runs in CI.
#
# Checks the invariants the strategy depends on but that no linter knows about:
#   1. CLAUDE.md stays under its line cap (adherence drops as it grows)
#   2. the always-on context budget is reported, so growth is visible
#   3. every relative link between docs resolves
#   4. every strategy doc carries its "At scale" callout

set -uo pipefail
cd "$(dirname "$0")/.."

CLAUDE_MD_MAX=200
fail=0

note() { printf '  %s\n' "$*"; }
bad() { printf '  FAIL: %s\n' "$*"; fail=1; }

# ---------------------------------------------------------------- line cap --
echo "==> CLAUDE.md line cap"
lines=$(wc -l < CLAUDE.md | tr -d ' ')
if (( lines > CLAUDE_MD_MAX )); then
  bad "CLAUDE.md is ${lines} lines, over the ${CLAUDE_MD_MAX}-line cap."
  note "Move content to .claude/rules/ (path-scoped) or .claude/skills/"
  note "(on-demand). See docs/strategy/01-context-engineering.md."
else
  note "CLAUDE.md: ${lines}/${CLAUDE_MD_MAX} lines"
fi

# ----------------------------------------------------------- context budget --
echo "==> Always-on context budget"
always_on=$lines
for f in .claude/rules/*.md; do
  [[ -f "$f" ]] || continue
  # A rule with `paths:` frontmatter loads only on matching files, so it does
  # not count against the every-request budget.
  if ! grep -q '^paths:' "$f"; then
    n=$(wc -l < "$f" | tr -d ' ')
    always_on=$(( always_on + n ))
    note "$(printf '%-34s %4s lines (unscoped)' "$f" "$n")"
  fi
done
note "total always-on: ${always_on} lines"

# -------------------------------------------------------------------- links --
echo "==> Relative links"
checked=0
broken=0
while IFS= read -r hit; do
  file="${hit%%:*}"
  rest="${hit#*:}"
  while read -r target; do
    [[ -n "$target" ]] || continue
    case "$target" in http*|'#'*) continue ;; esac
    target="${target%%#*}"
    [[ -n "$target" ]] || continue
    resolved=$(cd "$(dirname "$file")" && realpath -m "$target")
    checked=$(( checked + 1 ))
    if [[ ! -e "$resolved" ]]; then
      bad "${file} -> ${target}"
      broken=$(( broken + 1 ))
    fi
  done < <(grep -oP '\]\(\K[^)]+' <<<"$rest")
done < <(grep -rn '\](' --include='*.md' docs/ CLAUDE.md README.md 2>/dev/null)
note "${checked} links checked, ${broken} broken"

# ------------------------------------------------------------ scale callout --
echo "==> 'At scale' callouts"
missing=0
for f in docs/strategy/*.md docs/runbooks/*.md; do
  [[ -f "$f" ]] || continue
  if ! grep -q '^> \*\*At scale:\*\*' "$f"; then
    bad "${f} has no '> **At scale:**' callout"
    missing=$(( missing + 1 ))
  fi
done
(( missing == 0 )) && note "all present"

echo
if (( fail )); then
  echo "==> lint-docs FAILED"
  exit 1
fi
echo "==> lint-docs passed"
