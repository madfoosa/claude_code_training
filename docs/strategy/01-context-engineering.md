# 01 — Context engineering

> The highest-leverage pillar, and the one most setups get wrong. Everything
> else in this kit depends on Claude actually having the right information at
> the right moment.

## The core constraint

Every session starts with an empty context window. Everything Claude knows about
this project arrives by being loaded into that window, and the window is finite.

This produces a tension that has no clean resolution, only a trade-off to
manage:

- Load **too little** and Claude works from assumption — inventing conventions,
  rewriting helpers that already exist, breaking rules nobody told it about.
- Load **too much** and two things degrade at once. The window fills, and —
  more insidiously — adherence drops. A 600-line `CLAUDE.md` is followed *less*
  reliably than a 150-line one, because the instruction that matters is buried
  among forty that don't.

The second effect is the counterintuitive one. Adding a rule can make Claude
follow your rules *less* often. This is why the kit has a hard line cap rather
than a soft suggestion.

## The loading ladder

Each mechanism loads at a different moment and costs a different amount. Choose
by *when the information is needed*, not by what feels tidiest.

| Mechanism | Loads | Cost | Use for |
| --- | --- | --- | --- |
| `CLAUDE.md` | Every session, in full | Every request, forever | Facts every session needs: commands, conventions, "never do X" |
| `.claude/rules/` unscoped | Every session, in full | Every request | Cross-cutting rules that genuinely always apply |
| `.claude/rules/` with `paths:` | When a matching file is opened | Zero until matched | Language- and directory-specific guidance |
| Skills | Description at start; body when invoked | Description only | Procedures, reference material, workflows |
| Skills with `disable-model-invocation` | Only when you type `/name` | **Zero** | Workflows with side effects |
| Subagents | When spawned, in isolation | None in the main window | Work whose *output* matters but whose *process* doesn't |
| Hooks | Never — they run outside the model | **Zero** unless they return output | Anything mechanical |

The pattern to internalize: **push information as far down this table as it will
go.** Most things people put in `CLAUDE.md` belong in a path-scoped rule or a
skill.

## How this repo applies it

| Content | Where it lives | Why there |
| --- | --- | --- |
| `make` verbs, Definition of Done, "never" list | `CLAUDE.md` (99 lines) | Needed in every single session regardless of task |
| Secrets and untrusted-input handling | `.claude/rules/security.md`, unscoped | Applies to every file; too important to load conditionally |
| mypy/ruff conventions | `.claude/rules/python.md`, `paths: **/*.py` | Useless in a TypeScript-only session; free until a `.py` file is opened |
| Test discipline | `.claude/rules/testing.md`, four path patterns | Only relevant while writing tests |
| The `/ship-it` procedure | Skill, `disable-model-invocation: true` | Long, and it commits code — Claude should never invoke it unprompted |
| "Format after every edit" | `.claude/hooks/format-and-lint.sh` | Mechanical. No reasoning required, so it should not cost a token |

Always-on total: **139 lines.** That number is the budget, and it is checked in
CI. When something new needs to be always-on, something else moves down the
ladder.

## The decision tree

When you have a new piece of knowledge to place:

1. **Must it hold every single time, with no judgement?** → Hook. Not a
   document. A rule in prose is a request; a hook is a guarantee.
2. **Is it needed only when working with certain files?** → Path-scoped rule.
3. **Is it a procedure with steps?** → Skill.
4. **Is it reference material consulted occasionally?** → Skill, or a doc the
   skill points at.
5. **Would a session be wrong without it, whatever the task?** → `CLAUDE.md`.
6. **None of the above?** → It probably doesn't need to be written down. Not
   everything does.

## Specificity beats volume

A rule Claude can verify it has followed works. A rule it must interpret does
not.

| Weak | Strong |
| --- | --- |
| "Write good tests" | "New behaviour ships with a test that fails without the change" |
| "Format properly" | "Line length 88, enforced by ruff" |
| "Be careful with secrets" | "Never write a credential into a tracked file; use `.env.example` with an empty value" |
| "Keep functions small" | *(delete it — you will not enforce this, and an unenforced rule teaches Claude that rules are optional)* |

That last row matters more than it looks. Rules that are routinely ignored
without consequence train the model that this file is advisory.

## Contradictions are worse than gaps

If two instructions conflict, Claude picks one — and which one it picks is not
stable across sessions. That is worse than having neither, because the behaviour
becomes unpredictable rather than merely absent.

Contradictions accumulate silently as a project grows: a rule added in March
quietly contradicts one from January, and nobody re-reads the whole file. The
`/retro` skill therefore includes an explicit "look for the contradiction" step,
and the prune step exists to keep total volume low enough that reading the whole
file stays feasible.

## What survives `/compact`

When context fills, the conversation is compacted. Not everything comes back:

| Survives | Does not survive |
| --- | --- |
| Project-root `CLAUDE.md` — re-read from disk | Instructions given only in chat |
| Unscoped rules | Nested `CLAUDE.md` in subdirectories, until re-triggered |
| | Path-scoped rules, until a matching file is opened again |

The practical consequence: **an instruction given in conversation is temporary.**
If it matters beyond this turn, it goes in a file. This is the mechanical reason
behind `/retro`, and behind the `HANDOFF.md` convention in
[10 — Session continuity](10-session-continuity.md).

## Diagnosing it

| Symptom | Check |
| --- | --- |
| "Claude ignored my rule" | `/context` — did the file even load? |
| Rules not loading | `/memory` to see locations; `/doctor` for a config checkup |
| `CLAUDE.md` feels bloated | `wc -l CLAUDE.md`; `/doctor` proposes trims |
| A rule loads but is ignored | Look for a contradiction, or make it more specific |

Check that a file loaded **before** rewriting it. A rule that never entered
context is a placement bug, and rewording it will not help.

> **At scale:** the mechanics are identical; what changes is ownership. One
> person keeps a coherent `CLAUDE.md` by remembering what is in it. Fifty people
> cannot — the file grows by accretion, nobody deletes anything, contradictions
> multiply, and adherence collapses. Large orgs respond by putting `CLAUDE.md`
> under CODEOWNERS, moving team-specific content into path-scoped rules owned by
> those teams, and enforcing the line cap in CI as this repo does. Hard limits
> that a solo developer could keep by discipline become the only thing that
> works once discipline is distributed across many people.
