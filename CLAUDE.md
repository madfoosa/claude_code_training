# CLAUDE.md

This repo is a **software development strategy for Claude Code**: a portable kit
(`CLAUDE.md` + `.claude/` + `Makefile`) plus two small example slices that prove
the kit actually works. Full reasoning lives in `docs/strategy/`.

<!-- HARD CAP: 200 lines. CI fails past it. This file loads on EVERY request,
     so anything derivable from the codebase must not be here. Language rules
     go to .claude/rules/ (path-scoped). Procedures go to .claude/skills/. -->

## Command surface

`make` is the only vocabulary. Never invoke `pytest`, `ruff`, `vitest`, `eslint`,
or `tsc` directly — if a command you need isn't a `make` target, add it to the
`Makefile` rather than working around it.

| Command | Does |
| --- | --- |
| `make help` | List targets |
| `make setup` | Install dependencies for both stacks |
| `make fmt` | Rewrite files to canonical format |
| `make lint` | Style + format check, no rewriting |
| `make typecheck` | mypy / tsc |
| `make test` | pytest / vitest |
| `make check` | **The gate.** lint + typecheck + test |

Append `-py` or `-ts` to any verb to scope it to one stack (`make check-py`).

## Definition of Done

Every change climbs this ladder. Steps 3–5 are machine-enforced; do not treat
them as optional, and do not report a change as finished below step 6.

1. **Planned** — non-trivial work enters plan mode first. The plan names the
   files it will touch and how the result gets verified.
2. **Written** — smallest coherent diff. Read before editing. Reuse before
   creating: search for an existing helper before writing a new one.
3. **Formatted** — automatic via `PostToolUse` hook. Never a manual step.
4. **Typechecked** — `make typecheck`.
5. **Tested** — `make test`. New behavior ships with a test that *fails without
   the change*. Write the failing test first, watch it fail, then fix it.
6. **Verified** — `/verify` or `/run`. "Tests pass" and "it works" are different
   claims; step 5 is the first, step 6 is the second.
7. **Reviewed** — `/code-review`. Add `/security-review` when the diff touches
   auth, input parsing, secrets, file paths, subprocess calls, or dependencies.
8. **Documented** — docstrings and README updated. Write an ADR
   (`/adr`) when the decision is expensive to reverse.
9. **Tracked** — conventional commit on a branch, PR referencing an issue.
10. **Captured** — `/retro`. Anything I got wrong twice becomes a durable rule.

Run `/ship-it` to walk steps 3–9.

## Conventions

**Commits** — Conventional Commits: `type(scope): subject`, imperative mood,
subject ≤ 72 chars. Types: `feat` `fix` `docs` `test` `refactor` `chore` `ci`.
The body explains *why*; the diff already shows *what*.

**Branches** — `type/short-slug` (`feat/rate-limiter`, `fix/null-config`).

**Both stacks mirror each other.** `examples/python/` and `examples/typescript/`
implement the same logic deliberately. A behavior change in one needs the
matching change in the other, or the strategy stops being stack-independent.

**Tests are the specification.** When a test and the implementation disagree,
the test is right until a human says otherwise. Never edit a test to make it
pass — if a test is genuinely wrong, say so and ask.

**Docs are context, not decoration.** Anything a future session must know to
avoid a mistake belongs in a file, not in a chat message that disappears.

## Never

- **Never** edit `.env`, lockfiles, or `.github/workflows/` without being asked
  explicitly. A `PreToolUse` hook blocks these; do not try to route around it.
- **Never** commit secrets, tokens, or credentials — not even placeholders that
  look real.
- **Never** use `git push --force` on a shared branch, or `git commit --amend`
  on anything already pushed.
- **Never** weaken a test, loosen a type, add `# type: ignore` / `any` /
  `eslint-disable`, or skip a check to make the gate pass. Fix the cause or
  explain why it can't be fixed.
- **Never** report work as done when a step failed. State plainly what failed
  and show the output.

## Where things live

| Path | Holds |
| --- | --- |
| `docs/strategy/` | The twelve pillars — why the setup is shaped this way |
| `docs/adr/` | Architecture decision records |
| `docs/runbooks/recovery.md` | When a session goes off the rails |
| `.claude/rules/` | Path-scoped rules; load only for matching files |
| `.claude/skills/` | Invocable workflows (`/ship-it`, `/handoff`, `/adr`, …) |
| `.claude/hooks/` | Enforcement — runs whether or not I remember to |
| `.claude/settings.json` | Permissions and hook wiring |
| `examples/` | The live slices the kit is exercised against |

New to this repo? Read `docs/strategy/00-overview.md` first.
