# What and why

<!-- What changed, and the problem it solves. The diff shows what; this should
     explain why. If there is an issue, link it: Closes #123 -->

## How this was verified

<!-- Specific commands and their result. "Ran the tests" is not evidence.
     "make check green; /verify exercised burst-then-refill by hand" is.
     If verification was not meaningful for this change, say so and why. -->

- [ ] `make check` passes
- [ ] Verified the behaviour beyond the tests (`/verify` or `/run`), or stated
      why that is not meaningful here

## Definition of Done

<!-- From CLAUDE.md. Tick what applies; delete rows that genuinely do not. -->

- [ ] **Planned** — non-trivial work was planned before coding
- [ ] **Tested** — new behaviour has a test that fails without the change
- [ ] **Reviewed** — `/code-review` run; `/security-review` if the diff touches
      auth, input parsing, file paths, subprocess calls, secrets, or dependencies
- [ ] **Documented** — docstrings and README updated; ADR written if the
      decision is expensive to reverse
- [ ] **Mirrored** — if one example stack changed, the other did too (or the
      change is genuinely stack-specific, explained below)
- [ ] No new suppressions (`# type: ignore`, `noqa`, `eslint-disable`,
      `@ts-expect-error`, `any`) — or each is justified in a comment

## Risks and scope

<!-- What could break. What was deliberately left out and why. Anything a
     reviewer should look at especially closely. -->

## Notes for the reviewer

<!-- Optional. Where to start, what the tricky part is, what you are unsure
     about. Saying "I'm not confident about X" gets you a better review than
     projecting certainty you don't have. -->
