---
paths:
  - "**/tests/**"
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/test_*.py"
---

# Tests

The full reasoning is in `docs/strategy/04-testing.md`. This is the operational
part.

## The test is the specification

- Write the failing test **first**, run it, and confirm it fails *for the reason
  you expect*. A test that passes before the fix proves nothing, and a test that
  fails for the wrong reason is worse than none.
- Never edit a test to make a suite go green. If a test looks wrong, stop and
  say so — that is a conversation, not a refactor.
- Never delete or `skip` a failing test to unblock yourself.

## Guarding against self-confirmation

I write both the implementation and the tests, which means both can be wrong in
the same direction. Two habits mitigate it:

- **Test behaviour at the boundary, not the implementation.** Assert on what a
  caller observes. A test that reaches into private state (`_tokens`, `#tokens`)
  will pass through a refactor that breaks every real caller.
- **Cover the cases the implementation would find inconvenient**: empty, zero,
  negative, off-by-one, non-integer, backwards clocks, and the state *after* a
  failed operation. The `refuses rather than partially granting` case exists
  precisely because a naive implementation gets it wrong.

## Determinism

- No wall-clock time, no randomness, no network, no sleeps. Inject a fake — see
  `FakeClock` in both suites.
- A test that fails intermittently is a broken test. Fix or delete it; never
  retry around it.

## Shape

- One behaviour per test. If the name needs "and", split it.
- Test names state the behaviour, not the method: `does not refill past capacity`
  beats `test_refill_2`.
- Group related cases (`describe` / `class Test…`) so a failure report reads like
  a sentence.
- Parametrise over inputs that share an assertion rather than copy-pasting.

## Mirroring

`examples/python/tests/` and `examples/typescript/tests/` cover the same cases in
the same order. Adding a case to one means adding it to the other — a divergence
here means the two slices no longer prove the same thing.
