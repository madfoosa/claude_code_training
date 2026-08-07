# 03 — Writing code

> Step 2 of the Definition of Done. The goal is not code that works — it is code
> a human can verify works.

## The reviewability constraint

An agent can produce more code than you can carefully read. That asymmetry is the
central fact of agent-assisted development, and most of what follows is a
response to it.

If you cannot review it, you are not accepting *code* — you are accepting a
*claim* that the code is correct. Sometimes that is fine (a throwaway script).
For anything that persists, it is how unnoticed bugs accumulate.

So the target is not maximum output. It is the largest diff you will actually
read line by line.

## Read before editing

Never edit a file you have not read in this session. Not the whole file
necessarily, but enough surrounding context to know:

- What the code currently does, as opposed to what its name suggests.
- Who calls it, and what they rely on.
- What the tests already pin down.
- Which conventions the file follows — match the surrounding code's idiom,
  naming, and comment density rather than importing a different house style.

An edit made without reading is a guess that happens to be syntactically valid.

## Reuse before creating

Before writing a helper, search for it. This is the single most common source of
avoidable agent-written code: a `format_duration` that already exists three
modules over, now duplicated with slightly different rounding.

Duplication is not just wasteful — it is a correctness problem. Two
implementations of the same idea will drift, and the bug will be fixed in one.

The order:

1. Search the repo for the concept, not just the name you would have used.
2. Check the standard library. A new dependency is permanent, transitive, and
   someone else's supply chain.
3. Only then write it.

## Diff size discipline

| Guideline | Reason |
| --- | --- |
| One logical change per commit | A reviewer can hold one idea; a commit doing two things gets half-reviewed |
| Refactor and behaviour change go in separate commits | Otherwise moved lines are indistinguishable from modified ones |
| Mechanical changes stay separate from judgement calls | A 40-file rename should not hide a logic change |
| If the summary needs "and", split it | The word is a reliable signal of two changes |

When a change genuinely must be large — a migration, a codegen update — say so
explicitly and point at the parts that need real attention versus the parts that
are mechanical.

## Match the surrounding code

Code that reads like the code around it is easier to review, because a reviewer
scanning for differences is not distracted by stylistic ones. Concretely:

- Same naming conventions, same comment density, same error-handling idiom.
- Do not introduce a new pattern in a file that already has one, even a better
  pattern. If a change is warranted, that is a separate commit with a stated
  reason.
- Do not add a framework, abstraction layer, or dependency that the file did not
  already need.

## Comments explain why

The code states what it does. A comment restating that is noise that will go
stale. A comment worth writing captures what the code cannot:

```python
# A non-monotonic clock can step backwards. Credit nothing rather than
# debiting the caller for someone else's NTP correction.
if elapsed <= 0:
    return
```

The code shows the guard. Only the comment explains why the guard is not simply
a bug.

## Validate at the boundary

Check inputs where they enter — constructors, public entry points — not deep in
the call stack. Failing at construction points at the caller who got it wrong;
failing four frames down produces a stack trace nobody can act on.

Both example slices do this deliberately, and their error messages name the
offending value:

```
capacity must be positive, got -1
```

not `invalid capacity`. The first can be acted on without opening the source.

## Supervised versus unattended

Not all work needs the same oversight. Calibrate deliberately rather than by
default:

| Run unattended | Keep supervised |
| --- | --- |
| Mechanical refactors with test coverage | Anything touching auth, money, or user data |
| Adding tests to existing behaviour | Schema changes and migrations |
| Formatting, lint fixes, dependency bumps in a branch | Public API changes |
| Documentation | Anything where "works" is a judgement call, not a test result |

The guardrails in [06 — Guardrails & permissions](06-guardrails-permissions.md)
are what make unattended work safe: the blast radius is bounded by what the tools
permit, not by what the agent intends.

## Never route around a check

This is in `CLAUDE.md` as a hard rule and it is worth the space:

Do not add `# type: ignore`, `noqa`, `eslint-disable`, `@ts-expect-error`, or
`any` to get past a gate. Do not weaken a test. Do not narrow a check's scope.

A gate exists because someone decided that class of error was worth catching.
Suppressing it converts a caught error into an uncaught one and marks the change
as verified. If a rule is genuinely wrong for this codebase, change the *rule*,
in its config file, in a commit that says why — a decision anyone can see and
disagree with, rather than one hidden at a call site.

`.claude/rules/` for both languages state this, and `change-reviewer` treats
every new suppression as a finding.

> **At scale:** the reviewability constraint gets sharper, not softer. One person
> reviewing their own agent's output has full context on intent; a reviewer three
> time zones away has only the diff and the message. Large orgs respond with
> stricter size limits, mandatory linked issues, and CODEOWNERS routing so the
> reviewer is someone who knows the code. The deeper shift is *volume*: a team of
> fifty running agents can generate more diff than the team can review, and
> review capacity — not authoring capacity — becomes the binding constraint on
> how fast the codebase can safely change.
