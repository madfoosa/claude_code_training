# 04 — Testing

> Steps 5 and 6 of the Definition of Done. The pillar with the sharpest
> agent-specific problem: the same author writes the code *and* the thing that
> checks it.

## The self-confirmation problem

Ordinary software testing assumes some independence between the code and its
tests. Even when one person writes both, time passes and attention shifts.

With an agent, that independence largely disappears. The same model, in the same
context window, holding the same misunderstanding, writes both. If it
misunderstands the requirement, it will write a test that confirms the
misunderstanding — and the suite will be green.

**A passing suite written by the same agent that wrote the code is weaker
evidence than a passing suite generally is.** Everything below is a response to
that.

### Mitigation 1 — the test comes first, and must fail

Write the test, run it, and confirm it fails **for the reason you expect**.

This is not ceremony. A test that passes before the fix proves nothing about the
fix. A test that fails for the wrong reason — an import error, a typo in the
fixture — proves less than nothing, because it looks like evidence.

The failing test is the specification. Once written down and *observed failing*,
it constrains the implementation rather than being shaped by it.

### Mitigation 2 — test the boundary, never the internals

Assert on what a caller can observe. Never reach into private state.

```python
# Wrong -- passes through a refactor that breaks every real caller
assert bucket._tokens == 5.0

# Right -- pins down what a caller actually depends on
assert bucket.available() == 5
```

A test coupled to internals has two failure modes and both are bad: it breaks on
harmless refactors (training you to ignore it) and it passes when the public
behaviour breaks.

### Mitigation 3 — aim at the inconvenient cases

An agent writing tests for its own code will naturally cover the paths it was
thinking about. The value is in the ones it was not:

- Boundaries: zero, one, empty, exactly-at-capacity, one past capacity.
- Invalid input: negative, non-integer, `NaN`, `Infinity`, wrong type.
- **State after a failed operation** — the most commonly missed class.
- Time: no elapsed time, fractional, enormous, and *backwards*.

Two cases in this repo exist purely because a naive implementation gets them
wrong:

`refuses rather than partially granting` — a bucket with 2 tokens asked for 5
must refuse *and leave the 2 alone*. The obvious implementation decrements first
and checks after.

`ignores a backwards clock` — an NTP correction must not silently debit the
caller. The obvious implementation computes `elapsed` and trusts it.

### Mitigation 4 — a separate agent

`.claude/agents/test-writer.md` has no permission to edit implementation code.
That constraint is the point: an agent that *can* change the implementation will,
when its test fails, be tempted to adjust the code to match the test it just
wrote. One that cannot must report the failure instead.

## Determinism is not optional

No wall-clock time, no randomness, no network, no sleeps.

Both suites inject a `FakeClock` the test drives by hand:

```python
clock.advance(0.5)
assert bucket.available() == 0      # fractional credit is held...
clock.advance(0.5)
assert bucket.available() == 1      # ...not rounded away
```

That test is impossible to write reliably against a real clock, and it pins down
behaviour that a plausible implementation gets wrong.

A test that fails intermittently is a broken test. Fix it or delete it — never
retry around it. A suite with known flakes trains everyone to ignore red, which
costs you the entire value of having tests.

## `make test` is not `/verify`

The most-skipped step in the whole ladder is step 6, and it is skipped because
step 5 feels like it already covered it.

| | Proves |
| --- | --- |
| `make test` | The code does what the tests say |
| `/verify`, `/run` | The code does what it is *for* |

The gap between those holds: wiring mistakes, config that only breaks at
startup, an API contract that both the code and its tests get wrong together,
and anything the tests do not know to ask about.

For a library slice like this repo's, "verify" means exercising the public API as
a caller would. For an application it means starting it and driving it. When
verification genuinely is not meaningful for a change — a docs-only diff — say
so explicitly rather than skipping it silently.

## Never soften a test to get green

In `CLAUDE.md` as a hard rule:

- Never edit a test to make a suite pass.
- Never `skip`, `xfail`, or delete a failing test to unblock yourself.
- Never loosen an assertion (`assertEqual` → `assertAlmostEqual`) without saying
  why in the commit.

When a test and the implementation disagree, the test is right until a human says
otherwise. A test that looks wrong is a conversation, not a refactor — the whole
reason it exists is to object when the code changes.

## Naming

Test names state the behaviour, not the method:

- `does not refill past capacity` — describes a guarantee
- `test_refill_2` — describes nothing

The payoff is at 3am when CI is red: a failure report that reads like a sentence
tells you what broke before you open a single file.

## The mirror rule

`examples/python/tests/` and `examples/typescript/tests/` cover the same cases in
the same order. Adding a case to one means adding it to the other.

This is not tidiness. The two slices exist to demonstrate the strategy is
stack-independent; if their suites diverge, they stop proving the same thing and
the demonstration is worthless.

> **At scale:** the self-confirmation problem gets worse before it gets better,
> because the volume of agent-written tests makes spot-checking impractical. Large
> orgs respond with signals that do not depend on trusting the test author:
> mutation testing (does the suite actually detect an injected bug?), coverage
> *deltas* rather than absolutes, and required human review on test files
> specifically. The counterintuitive one: coverage percentage becomes actively
> misleading, since an agent can drive it to 95% with tests that assert almost
> nothing. What matters is whether a suite *fails when the code breaks*, and only
> mutation testing measures that directly.
