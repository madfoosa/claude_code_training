# 09 — Documentation

> Step 8 of the Definition of Done. In an agent-assisted codebase, documentation
> stops being a courtesy to future humans and becomes *machine-readable context*.

## The shift

Traditionally, docs are a cost paid for someone else's benefit later — which is
why they are the first thing dropped under pressure.

With an agent in the loop, that changes: documentation is loaded into context and
directly shapes the next change. A convention written down is followed. A
convention that lives only in your head is violated by every session.

This gives docs an immediate, self-interested payoff. The `CLAUDE.md` you write
today is what stops tomorrow's session inventing its own directory layout.

It also raises the cost of *bad* docs. A stale comment used to mislead an
occasional reader. Now it misleads every session that loads it, confidently.

## Where things go

| Content | Home | Read by |
| --- | --- | --- |
| What this line does and why it is odd | Code comment | Anyone at that line |
| What this function promises | Docstring / TSDoc | Callers, type checkers, agents |
| How to run and use the project | `README.md` | Newcomers |
| Conventions every session needs | `CLAUDE.md` | Every session, every request |
| Language- or path-specific rules | `.claude/rules/` | Sessions touching those files |
| A repeatable procedure | `.claude/skills/` | On invocation |
| Why a decision was made, and what lost | `docs/adr/` | Anyone asking "why is it like this?" |
| Why the whole setup is shaped this way | `docs/strategy/` | Anyone extending the kit |
| What to do when it breaks | `docs/runbooks/` | You, at the worst moment |
| In-flight state for the next session | `HANDOFF.md` (gitignored) | The next session |

The placement question is always the same: **who needs this, and when?** That is
the same question as [01 — Context engineering](01-context-engineering.md),
because it is the same problem.

## Comments explain why

The single most common documentation defect is restating the code.

```python
# Bad -- says what the next line already says
# Set tokens to capacity
self._tokens = float(capacity)

# Good -- says what the code cannot
# A non-monotonic clock can step backwards. Credit nothing rather than
# debiting the caller for someone else's NTP correction.
if elapsed <= 0:
    return
```

The second earns its keep because without it, the guard reads like a bug and the
next person deletes it.

Write a comment when: the code is surprising, a constraint is invisible, an
alternative was rejected, or a bug is being worked around. Otherwise let the code
speak.

## Docstrings are contracts

Every public function documents its arguments, return, and — critically — what it
**raises**. The raises clause is the most-omitted and most-needed part: a caller
cannot handle an exception they do not know about.

Both slices carry this:

```python
Raises:
    ValueError: If ``tokens`` is not positive, or exceeds ``capacity``
        and so could never succeed no matter how long the caller waits.
```

That second clause encodes a real design decision — an unsatisfiable request is a
bug, not a rate-limit answer — where a caller will actually encounter it.

## Docs go stale, and stale is worse than absent

Absent documentation makes you read the code. Stale documentation makes you trust
something false. The second is strictly worse, and agents amplify it: they will
follow a confidently-wrong docstring rather than verify it against the code.

Countermeasures:

- **Update docs in the same commit as the code.** A follow-up commit is a
  follow-up commit that does not happen.
- **Prefer docs that cannot drift.** Types and tests are executable
  documentation, checked on every run. A test showing usage will never be stale.
- **Delete rather than let rot.** A deleted doc is honest.
- **Do not document what the code shows.** A directory listing in `CLAUDE.md`
  goes stale the first time a file moves — and Claude can just look.

That last point is why `CLAUDE.md` here contains no architecture overview: it
would be a maintenance liability, and the agent can read the tree.

## ADRs

The one form of documentation that *cannot* go stale, because it records what was
true at a moment in time. See
[ADR-0001](../adr/0001-record-architecture-decisions.md), which is itself the
worked example.

The two sections carrying the value are **alternatives considered** (with the
specific reason each lost) and **consequences including the bad ones**. An ADR
listing only benefits is marketing, and a reader who notices that stops trusting
the rest.

## No invented numbers

Do not write "reduces bugs by 40%" or "3x faster" unless you can point at the
measurement. Fabricated precision is worse than an honest judgement call, and it
propagates — a number in a doc gets quoted in a slide, then a decision.

Where something is a judgement call, say so. `.claude/rules/docs.md` enforces
this, and [08 — Measurement](08-measurement.md) explains why most of the
plausible numbers here would be misleading anyway.

## Write for the returning reader

The target reader is you in three months, or a session starting cold. Both have
the same profile: full technical competence, zero memory of the decisions.

That reader does not need to be taught Python. They need to know that the clock
is injected *because a real clock makes the suite non-deterministic*, and that
this was a deliberate trade rather than an accident.

> **At scale:** the economics invert. Solo, docs are a cost you pay for a benefit
> you might get; on a team, they are the mechanism by which anyone but the author
> can change the code at all — so the cost is paid whether or not it is written
> down, just distributed as interruptions. Orgs formalise this with doc ownership
> in CODEOWNERS, docs-as-code review, and generated API references. The
> agent-specific change is that `CLAUDE.md` and `.claude/rules/` become *shared
> infrastructure*: one person's addition changes every colleague's sessions,
> which is why those files need review as much as source does.
