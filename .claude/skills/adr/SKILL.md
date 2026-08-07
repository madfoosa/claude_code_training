---
description: Record an architecture decision as a numbered ADR. Use when a choice is expensive to reverse, when rejecting a reasonable alternative, or when a future reader would otherwise ask "why is it like this?"
when_to_use: Invoked as /adr, or when the user asks to document, record, or write up a technical decision.
argument-hint: [decision title]
---

# Write an ADR

An Architecture Decision Record captures *why* a choice was made, at the moment
it was made, while the alternatives are still fresh. Code shows what was decided;
only an ADR shows what was rejected and on what grounds.

## Existing records

!`ls -1 docs/adr/ 2>/dev/null || echo "(none yet)"`

## When this is warranted

Write one when **any** of these is true:

- The decision is expensive to reverse (a data model, a public API, a dependency).
- A reasonable person would choose differently, and you want the reasoning on
  record rather than relitigated every quarter.
- You rejected an obvious alternative for a non-obvious reason.
- The choice constrains future work in a way the code does not make visible.

Do **not** write one for a decision that is cheap to change or that the code
already explains. An ADR directory full of trivia is one nobody reads.

## Steps

1. Read `docs/adr/0000-template.md`.
2. Find the next number: highest existing + 1, zero-padded to four digits.
3. Create `docs/adr/NNNN-kebab-case-title.md` from the template.
4. Fill every section. The two that carry the value:
   - **Alternatives considered** — each with the specific reason it lost. "It
     was worse" is not a reason; "it couples the limiter to wall-clock time,
     which makes the suite non-deterministic" is.
   - **Consequences** — including the bad ones. An ADR listing only benefits is
     marketing, and a future reader will not trust it.
5. Set status to `Accepted` (or `Proposed` if it still needs the user's sign-off).
6. If this supersedes an earlier ADR, mark that one `Superseded by NNNN` and link
   both ways.

## The decision

$ARGUMENTS

Draft the ADR, then show it and ask whether the reasoning is recorded accurately
before committing. You are writing down someone else's decision — check that you
got it right.
