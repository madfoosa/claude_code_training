# ADR-0001: Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-08-07
- **Deciders:** Repository owner

## Context

This repository is developed largely through Claude Code sessions. Each session
starts with an empty context window, so the reasoning behind a decision is not
carried forward by the agent that made it — only the resulting code is.

That produces a specific failure: a later session sees an unusual choice, reads
it as an accident, and "fixes" it. The constraint that motivated the choice is
invisible in the diff, so the correction looks like an improvement right up
until it breaks something.

Git history helps less than it appears to. Commit messages record what changed
and usually why *that commit* was made, but they are hard to search by topic and
nobody reads them archaeologically. Decisions that span several commits have no
single home at all.

## Decision

We keep numbered Architecture Decision Records in `docs/adr/`, one file per
decision, created from `docs/adr/0000-template.md` via the `/adr` skill.

An ADR is written when a decision is expensive to reverse, when a reasonable
person would choose differently, or when an obvious alternative was rejected for
a non-obvious reason.

ADRs are immutable once accepted. A decision that changes gets a new ADR that
supersedes the old one, and both are updated to link to each other.

## Alternatives considered

### Put the reasoning in code comments

Rejected because comments explain the code they sit next to, and the decisions
worth recording are usually cross-cutting — a choice about how the whole package
handles time has no single line to attach to. Comments also rot: the code moves
and the comment does not follow.

### Rely on commit messages

Rejected because they are chronological, not topical. Answering "why is the
clock injected?" means bisecting history rather than opening a file. Commit
messages remain the right place for *why this change*; ADRs cover *why this
design*.

### Put decisions in `CLAUDE.md`

Rejected on context budget. `CLAUDE.md` is capped at 200 lines and loads on
every request; decision history grows without bound and is needed rarely. ADRs
sit on disk and are read on demand — the same progressive-disclosure argument
that governs the rest of the kit (see
[01 — Context engineering](../strategy/01-context-engineering.md)).

### Keep decisions in an external wiki

Rejected because it does not travel with the repository. The kit is meant to be
copied into other projects, and a decision record that lives elsewhere is one
nobody updates and Claude cannot read.

## Consequences

**Good**
- A later session encountering a surprising choice can find the reasoning by
  reading a file, rather than inferring intent from code.
- Rejected alternatives are recorded, so the same debate is not reopened
  repeatedly with the same outcome.
- ADRs are plain markdown in the repo, so Claude reads them with no extra tooling.

**Bad / accepted costs**
- Writing one costs real time at the moment you least want to spend it — just as
  a decision is finally settled.
- The judgement call about what deserves an ADR will sometimes be wrong in both
  directions. A directory full of trivia is one nobody reads, which is worse
  than a sparse one.
- ADRs can go stale. Immutability plus explicit supersession limits the damage
  but does not eliminate it.

**Neutral but worth knowing**
- Numbering is sequential and never reused, so two branches adding an ADR
  simultaneously will collide and one must be renumbered on merge.

## Revisit if

- The directory accumulates records nobody reads, suggesting the bar for writing
  one is set too low.
- Decisions are consistently being made *without* records despite meeting the
  bar, suggesting the `/adr` step is too heavy to reach for.
