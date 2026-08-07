# 00 — Overview

> The whole model on one page. Every other doc in `docs/strategy/` expands one
> row of the tables below.

## The problem this solves

An agent that writes code is easy. An agent that writes code you can *trust
without reading every line* is the actual goal, and that requires structure
around the agent rather than better prompting of it.

Three failure modes recur, and the strategy is organized around defeating them:

| Failure | Looks like | Defeated by |
| --- | --- | --- |
| **Drift** | Docs, hooks, and CI disagree about how to run tests | One command surface (`Makefile`) |
| **Amnesia** | Every session re-learns the project; the same mistake recurs | Context engineering + the feedback loop |
| **Plausibility** | Work *looks* finished but was never verified | The Definition of Done ladder, machine-enforced |

## Idea 1: one command surface

The `Makefile` is the only vocabulary. `CLAUDE.md`, `.claude/hooks/*`, and
`.github/workflows/ci.yml` invoke `make check` — never `pytest` or `vitest`
directly.

This sounds like a small convention. It is the load-bearing decision. Because
the three consumers share one definition, they cannot silently diverge, and
swapping a tool is a one-line edit rather than an archaeology exercise.

The test of whether you've done this right: *changing your test runner should
require editing exactly one file.*

## Idea 2: guidance vs. enforcement

`CLAUDE.md` is context, not configuration. Claude reads it and tries to comply,
but compliance is probabilistic — it degrades with file length, competing
instructions, and long sessions. This is not a defect to prompt around; it is a
property to design around.

So every rule gets classified:

| If the rule… | Put it in | Because |
| --- | --- | --- |
| should hold *usually*, with judgment | `CLAUDE.md` or `.claude/rules/` | Claude can weigh it against context |
| must hold *every single time* | a hook | Hooks fire regardless of what Claude decides |
| is a procedure you repeat | a skill | Loads on demand, costs nothing until used |
| is knowledge for one task | a subagent | Isolated context, only the summary returns |

"Never edit `.env`" in `CLAUDE.md` is a request. The same rule in a `PreToolUse`
hook is a guarantee. Both exist here — the prose explains *why*, the hook makes
it *true*.

## Idea 3: the Definition of Done ladder

Lives verbatim in [`CLAUDE.md`](../../CLAUDE.md). Ten steps, three enforcement tiers:

| Steps | Tier | Mechanism |
| --- | --- | --- |
| 1–2 Planned, Written | Judgment | Plan mode, `.claude/rules/`, `/plan-change` |
| 3–5 Formatted, Typechecked, Tested | **Machine** | `PostToolUse` + `Stop` hooks, `make check`, CI |
| 6–9 Verified, Reviewed, Documented, Tracked | Prompted | `/ship-it` walks them |
| 10 Captured | Ritual | `/retro` |

Step 6 is the one people skip. `make test` proves the tests pass. `/verify`
proves the *app works*. These are different claims and the gap between them is
where most agent-written bugs live.

## The twelve pillars

| # | Doc | Question it answers |
| --- | --- | --- |
| 01 | [Context engineering](01-context-engineering.md) | What should Claude know, and when should it load? |
| 02 | [Planning](02-planning.md) | How does work get decomposed before code is written? |
| 03 | [Writing code](03-writing-code.md) | What makes an agent-written diff reviewable? |
| 04 | [Testing](04-testing.md) | How do you trust tests the agent also wrote? |
| 05 | [Review & security](05-review-and-security.md) | What must a human look at? |
| 06 | [Guardrails & permissions](06-guardrails-permissions.md) | What can the agent not do, ever? |
| 07 | [Tracking](07-tracking.md) | How is work traceable from idea to commit? |
| 08 | [Measurement](08-measurement.md) | How do you know any of this is working? |
| 09 | [Documentation](09-documentation.md) | What gets written down, and where? |
| 10 | [Session continuity](10-session-continuity.md) | How does knowledge survive a cold start? |
| 11 | [Recovery](../runbooks/recovery.md) | What do you do when it goes wrong? |
| 12 | [The feedback loop](12-feedback-loop.md) | How does the kit avoid rotting? |

## Which file implements which idea

| Idea | Implemented by |
| --- | --- |
| One command surface | `Makefile` |
| Always-on contract | `CLAUDE.md` (capped at 200 lines, enforced in CI) |
| Language-specific guidance | `.claude/rules/*.md` with `paths:` frontmatter |
| Hard limits | `.claude/settings.json` → `permissions.deny` |
| Edit-time enforcement | `.claude/hooks/protect-paths.sh`, `format-and-lint.sh` |
| Done-ness enforcement | `.claude/hooks/stop-gate.sh` |
| Cold-start orientation | `.claude/hooks/session-start.sh` + `/handoff` |
| Repeatable procedures | `.claude/skills/*/SKILL.md` |
| Independent verification | `.claude/agents/change-reviewer.md` |
| Decision history | `docs/adr/` |
| Outer verification loop | `.github/workflows/ci.yml` |

## Reading order

Start at [01 — Context engineering](01-context-engineering.md). It is the
highest-leverage pillar and the one most setups get wrong. Then
[04 — Testing](04-testing.md) and [12 — The feedback loop](12-feedback-loop.md),
which together determine whether the system improves or decays over time.

> **At scale:** a 50-engineer org changes three things. Permission denies move
> to *managed settings* so individuals cannot override them. `CLAUDE.md`
> ownership goes to CODEOWNERS, because an unowned instruction file accumulates
> contradictions and Claude resolves contradictions arbitrarily. And the
> feedback loop (pillar 12) gets a named owner and a recurring calendar slot —
> at solo scale it survives on discipline; at team scale, discipline alone
> reliably fails.
