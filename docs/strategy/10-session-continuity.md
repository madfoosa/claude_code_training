# 10 — Session continuity

> Every session starts with an empty context window. This pillar is about what
> survives that, and how to make sure the right things do.

## The cold start

A Claude Code session has no memory of the previous one. It does not know what
you were doing yesterday, which approach you already tried and abandoned, or why
the obvious fix is wrong.

Left alone, this produces a recognisable pattern: the first several turns of
every session are spent re-establishing context, and the traps discovered
yesterday get rediscovered today at the same cost.

Three mechanisms carry knowledge across the gap, and they are for different
things.

| Mechanism | Written by | Holds | Lifetime |
| --- | --- | --- | --- |
| `CLAUDE.md`, `.claude/rules/` | You | Durable conventions | Until you change them |
| Auto memory | Claude | Learnings it picks up | Accumulates, machine-local |
| `HANDOFF.md` | `/handoff` | In-flight state | Until the next handoff |

The distinction that matters: **durable versus in-flight.** "We use `make check`"
is durable and belongs in `CLAUDE.md`. "The TypeScript suite is missing the
backwards-clock case" is in-flight and belongs in a handoff. Putting in-flight
state in `CLAUDE.md` pollutes every future session with stale facts.

## `HANDOFF.md`

Written by `/handoff` at the end of a session, read back by
`.claude/hooks/session-start.sh` at the start of the next. Gitignored — it is a
note to your next session, not a project artifact.

The structure exists because each section answers a question the next session
will otherwise ask:

| Section | Question it answers |
| --- | --- |
| **Goal** | What are we trying to achieve? |
| **Last state** | What is actually true right now? |
| **Next action** | What do I do first? |
| **Open questions** | What is blocked on a decision? |
| **Watch out for** | What will waste my time if I don't know it? |

**Next action** must be concrete enough to start on without a question. "Continue
testing" is worthless. "Add the backwards-clock case to
`examples/typescript/tests/bucket.test.ts` to match the Python suite" is a
starting point.

**Watch out for** is the section people skip and the one that pays. Dead ends,
misleading APIs, a check that fails for a non-obvious reason. Write it even when
it feels too obvious to bother with — obvious-right-now is exactly the knowledge
that does not survive.

## What the session-start hook does

`.claude/hooks/session-start.sh` surfaces, before the first turn:

- Current branch
- Uncommitted changes, by path
- When `make check` last passed
- Recent commits
- `HANDOFF.md`, if present

This is cheap — a few lines of context — and removes an entire category of
opening exchange. It also catches a real failure: starting work on the wrong
branch, or on top of uncommitted changes you had forgotten.

## Auto memory

Claude maintains its own notes per repository, in
`~/.claude/projects/<project>/memory/`. It decides what is worth keeping — build
quirks, debugging insights, preferences it observes.

Practical points:

- It is **machine-local**. It does not travel to a teammate or a cloud session.
  Anything the team needs belongs in `CLAUDE.md`, which is committed.
- Only the first ~200 lines of `MEMORY.md` load each session, so it stays an
  index with detail in topic files.
- It is plain markdown you can audit and edit. Run `/memory` and read it
  occasionally — a wrong memory is a persistent wrong assumption.

Auto memory complements `CLAUDE.md`; it does not replace it. Memory is what
Claude noticed. `CLAUDE.md` is what you decided.

## Compaction

When context fills, the conversation is compacted. What survives is not obvious:

| Survives | Does not |
| --- | --- |
| Project-root `CLAUDE.md` (re-read from disk) | Instructions given only in chat |
| Unscoped rules | Nested `CLAUDE.md`, until re-triggered |
| | Path-scoped rules, until a matching file is opened |

The operational consequence: **an instruction given in conversation is
temporary.** If you tell Claude something mid-session and it matters beyond this
turn, it goes in a file. That is not bureaucracy — it is the only mechanism that
works.

## Long sessions degrade

Even before compaction, a long session gets worse: more competing context, more
superseded decisions still present, more chances for an early misunderstanding to
persist.

Symptoms worth reacting to:

- Repeating work it already did
- Contradicting an earlier decision in the same session
- Ignoring a rule it followed an hour ago
- Increasingly confident answers about things it has not checked

The right response is usually not to push through. Run `/handoff`, start fresh,
and let the session-start hook reload clean state. A fresh session with a good
handoff outperforms a degraded one carrying two hours of noise.

## Practical rhythm

**Starting:** let the hook orient you. Read the handoff. Confirm the branch is
what you expect before making changes.

**During:** when you learn something durable, write it down *then*. The intention
to record it later does not survive either.

**Ending:** run `/handoff` if work is unfinished. Run `/retro` if something went
wrong in a way that will recur. Commit or explicitly stash — uncommitted work
plus a lost session is the one genuinely unrecoverable state.

> **At scale:** the problem stops being personal continuity and becomes shared
> context. Auto memory does not transfer between people, so anything a colleague
> needs has to be in committed files — which makes `CLAUDE.md` and
> `.claude/rules/` team infrastructure rather than personal notes. Orgs handle
> the in-flight half through the issue tracker and PR descriptions instead of a
> gitignored handoff file, since a note only you can read is not continuity for
> anyone else. The failure mode is a team where every individual's Claude setup
> works well and no knowledge moves between them.
