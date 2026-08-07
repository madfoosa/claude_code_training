---
description: Write a HANDOFF.md so the next session starts oriented instead of cold. Manual invocation only.
argument-hint: [optional note about where things stand]
disable-model-invocation: true
---

# Handoff

Every session starts with an empty context window. Whatever is only in this
conversation is lost the moment it ends. This writes down the part that matters.

Paired with `.claude/hooks/session-start.sh`, which reads `HANDOFF.md` back at
the start of the next session.

## Current state

Branch: !`git branch --show-current`

!`git status --short || echo "(clean)"`

Recent commits:
!`git log --oneline -5`

## Write `HANDOFF.md` at the repo root

Use exactly this structure. `HANDOFF.md` is gitignored — it is a note to the
next session, not a project artifact.

```markdown
# Handoff — <YYYY-MM-DD>

## Goal
What we are trying to achieve, in one or two sentences. Not the history — the
destination.

## Last state
What is actually true right now: what works, what is half-finished, what is
committed vs. still in the working tree. Name files by path.

## Next action
The single most useful next step, concrete enough to start on without asking a
question. "Add the backwards-clock case to the TypeScript suite to match
examples/python/tests/test_bucket.py" — not "continue testing".

## Open questions
Decisions that need the user, and what each one blocks. Omit the section if
there are none.

## Watch out for
Traps discovered this session: a failing check with a non-obvious cause, a
misleading API, an approach already tried and abandoned. This is the section
that saves the next session an hour — write it even when it feels obvious now.
```

## Rules

- **Be specific.** "Working on tests" is worthless. Name the file and the case.
- **Write what you learned, not what you did.** A list of completed steps is
  already in the git log. The value here is the things that are *not* recoverable
  from the repo.
- **Record dead ends.** An approach that failed, and why, is worth as much as
  the one that worked — without it the next session retries it.
- **Keep it under 60 lines.** The session-start hook reads the first 60.

## Also consider

If something you learned is durable rather than in-flight — a convention, a
build quirk, a recurring mistake — it belongs in `CLAUDE.md` or a rule, not in a
handoff that gets overwritten tomorrow. Run `/retro` for that.
