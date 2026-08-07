# ADR-NNNN: <short decision title>

- **Status:** Proposed | Accepted | Superseded by `ADR-NNNN` (link it when superseded)
- **Date:** YYYY-MM-DD
- **Deciders:** <who>

## Context

What forced a decision here? The constraints, the pressures, and the state of
the world at the time. Write this so it makes sense to someone who was not in
the room and does not know what happened next.

Facts, not conclusions. If a constraint was assumed rather than verified, say so
— a future reader needs to know which premises to re-check.

## Decision

What was decided, stated plainly and in the active voice: "We inject the clock
as a constructor argument."

## Alternatives considered

The section that carries the value. For each alternative, state what it was and
the **specific** reason it lost.

### <Alternative A>

Rejected because: <concrete reason>. "It was worse" is not a reason. "It couples
the limiter to wall-clock time, so the suite becomes non-deterministic and CI
flakes" is.

### <Alternative B>

Rejected because: ...

## Consequences

What becomes true now that this is decided — the good and the bad.

**Good**
- ...

**Bad / accepted costs**
- ... (An ADR that lists only benefits is marketing. If there is genuinely no
  cost, the decision probably did not need an ADR.)

**Neutral but worth knowing**
- Constraints this places on future work.

## Revisit if

The conditions that would make this decision wrong. This is what turns an ADR
from a historical record into something actionable — without it, nobody knows
when to reopen the question.

- ...
