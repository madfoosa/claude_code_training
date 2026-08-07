# 07 — Tracking

> Step 9 of the Definition of Done. Making work traceable from "why did this
> change?" back to the reasoning, months later, without the person who did it.

## What tracking is actually for

Not process for its own sake. Tracking answers questions you will genuinely ask:

- Why does this line exist? (`git blame` → commit → issue → discussion)
- What shipped last week? (commit log, PR list)
- Is this a regression or intended? (the commit that introduced it)
- What was in flight when I stopped? (branch, PR, `HANDOFF.md`)

Every convention below earns its place by answering one of those. Anything that
answers none should be dropped.

Agent-assisted work raises the stakes: more changes land, faster, and the author
has no memory of writing them. The trail *is* the memory.

## The chain

```
issue  →  branch  →  commits  →  pull request  →  merge
```

Each link references the previous. Given any point you can walk back to the
original reasoning.

## Issues

An issue captures a problem or intent *before* the solution exists. It is the
only artifact whose job is to record what someone wanted, as opposed to what got
built.

Two templates in `.github/ISSUE_TEMPLATE/`:

- **Bug** — expected behaviour, actual behaviour, reproduction. The gap between
  the first two *is* the bug; a report with only "it's broken" is unactionable
  for a human and worse for an agent.
- **Feature** — the problem, not the solution. "Users can't tell why a request
  was throttled" leaves the design open. "Add a `retry_after` field" has quietly
  decided it.

Not everything needs an issue. A typo fix does not. The test: *would anyone ever
ask why this changed?*

## Branches

`type/short-slug` — `feat/rate-limiter`, `fix/backwards-clock`.

Never commit to `main` directly. Not because a solo developer needs the
ceremony, but because a branch is a cheap boundary you can abandon. When an agent
session goes sideways, `git checkout main` throws away the whole attempt with no
cleanup — see [11 — Recovery](../runbooks/recovery.md).

## Commits

Conventional Commits, enforced by convention rather than a hook:

```
type(scope): subject

Body explaining WHY. The diff already shows what.

Refs #123
```

| Rule | Reason |
| --- | --- |
| `feat` `fix` `docs` `test` `refactor` `chore` `ci` | Scannable log; machine-readable for changelogs |
| Imperative mood, ≤72 chars | Matches git's own convention; readable in `--oneline` |
| Body explains **why** | The single highest-value line in the whole system |
| One logical change per commit | A commit doing two things cannot be reverted cleanly |

The "why" rule deserves emphasis. Six months on, `git blame` lands on a line and
the question is always the same: *why is it like this?* A message saying "add
backwards-clock guard" restates the diff. One saying "NTP corrections were
debiting callers for time that never elapsed" answers the question.

This is where agent-written commits most often fall short — they describe the
diff fluently and omit the motivation, because the motivation was in a
conversation that no longer exists.

## Pull requests

Even solo. A PR is where CI reports, where the diff is readable, and where the
change is reviewable as a unit rather than as a stream of commits.

`.github/pull_request_template.md` asks for:

- **What and why** — the summary a reviewer reads first
- **How it was verified** — the specific commands run, and their result
- **Definition of Done checklist** — the ladder, made visible
- **Risks and out-of-scope** — what might break, what was deliberately left

The verification section is the one that matters. "Ran the tests" is not
evidence. "`make check` green; `/verify` exercised burst-then-refill by hand" is.

## Task lists within a session

For multi-step work, a task list keeps the sequence visible and survives a
context compaction that would otherwise lose it. It is working state, not a
project artifact — durable tracking belongs in issues and commits.

## CODEOWNERS

At solo scale this is a placeholder that documents intent. It becomes load-bearing
the moment a second person appears, and costs nothing to establish now.

## What not to track

- Do not open an issue for work you are about to do in the next ten minutes.
- Do not write a PR description that restates the diff — link the issue and
  explain what the diff cannot show.
- Do not maintain a `TODO.md` alongside an issue tracker. Two systems means
  neither is trusted.

## Where the agent-specific risk sits

A session can produce a large, coherent, well-tested change and describe it in a
commit message that omits the one thing a future reader needs. Agents are fluent
about *what* changed and weak on *why*, because "why" lived in a conversation
that is now gone.

`/ship-it` therefore makes "the body explains why" an explicit step, and
[10 — Session continuity](10-session-continuity.md) covers capturing the
reasoning before it evaporates.

> **At scale:** tracking shifts from personal memory aid to coordination
> mechanism. Solo, the trail is for you; on a team, it is how someone who was not
> there reconstructs intent, and how you find out that two people are changing the
> same module this week. Orgs add automated linking between commits and tickets,
> required review via CODEOWNERS, merge queues to keep `main` green, and release
> notes generated from commit types — which is where the Conventional Commits
> convention stops being tidiness and starts being machine-read. Worth noting:
> most of these become *necessary* well before they become *pleasant*, which is
> why establishing the format early costs nothing and retrofitting it costs a lot.
