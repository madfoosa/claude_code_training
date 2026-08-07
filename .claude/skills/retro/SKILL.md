---
description: Turn a mistake into a durable rule so it does not recur. Use after Claude gets something wrong a second time, after a review catches something Claude should have known, or when the same correction is being typed again.
when_to_use: Invoked as /retro, or when the user says "you did that wrong again", "I keep having to tell you", or "remember this for next time".
argument-hint: [what went wrong]
---

# Retro

The feedback loop. Without it, this kit is a snapshot that decays; with it, every
mistake makes the next session better. See `docs/strategy/12-feedback-loop.md`.

## What went wrong

$ARGUMENTS

## 1. Find the real cause

Do not fix the symptom. Ask what made the mistake *available*:

- Was the correct information written down anywhere? If not, that is the gap.
- Was it written down but **not loaded** — in a skill that never triggered, or a
  path-scoped rule that did not match? Then the problem is placement, not content.
- Was it loaded but **not followed**? Then it is too vague, too long, or it
  contradicts another instruction. Check for the contradiction before rewriting.
- Was it followed but **wrong**? Then the rule itself needs to change.

## 2. Choose the mechanism

Match the fix to the failure. Putting a fix in the wrong layer is why setups
stop working.

| If… | Then | Where |
| --- | --- | --- |
| A convention was got wrong twice | Add a rule | `CLAUDE.md`, or `.claude/rules/` if it's language- or path-specific |
| The same prompt keeps being typed | Capture it | a new `.claude/skills/<name>/SKILL.md` |
| A multi-step procedure was pasted a third time | Capture it | a skill |
| It **must** hold every time, no judgement | Enforce it | a hook in `.claude/hooks/` |
| A side task flooded the context | Isolate it | a subagent in `.claude/agents/` |
| A second repo needs the same fix | Package it | a plugin |

The distinction that matters most: **guidance vs. enforcement.** If the rule
admits judgement, write it down. If it must hold every single time, a hook is
the only thing that guarantees it.

## 3. Make the edit

- Be specific and verifiable. "Run `make check` before committing" beats "test
  your work".
- Put it where it will *load*. A Python rule belongs in `.claude/rules/python.md`
  (path-scoped, free until a `.py` file is opened), not in `CLAUDE.md` (loaded on
  every request, forever).
- **Check the budget.** `CLAUDE.md` is capped at 200 lines and CI enforces it. If
  the addition pushes it over, something else moves out to a rule or a skill —
  that is the correct outcome, not a problem.
- **Look for the contradiction.** If an existing instruction conflicts with the
  new one, resolve it. Two contradictory rules are worse than neither, because
  which one wins becomes arbitrary.

## 4. Prune while you are here

Every entry costs context on every request. Delete anything that is now obsolete,
duplicated, or derivable from the codebase. Growth without pruning is how a
context file becomes noise that nothing follows.

## 5. Report

Say what you changed, which file, and why that layer was the right one. If the
honest answer is that no durable rule would have prevented this — a genuine
one-off — say that instead of manufacturing a rule. Not every mistake has a
systemic fix, and pretending otherwise fills the file with noise.
