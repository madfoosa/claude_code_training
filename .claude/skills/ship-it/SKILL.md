---
description: Walk a finished change through the rest of the Definition of Done -- verify, review, document, and commit. Manual invocation only.
argument-hint: [optional note about what changed]
disable-model-invocation: true
---

# Ship it

Walks Definition of Done steps 3–9. Steps 1–2 (planned, written) are assumed
done; if they aren't, stop and say so.

Manual-only by design: this commits code. Claude should never decide on its own
that a change is ready to ship.

## What changed

!`git status --short || echo "(clean)"`

!`git diff --stat HEAD || true`

## The ladder

Work through these **in order**. Do not skip a step because it seems likely to
pass — the point of a ladder is that each rung is actually stood on. If a step
fails, stop there, fix the cause, and restart from that step.

### 3–5. Formatted, typechecked, tested

```bash
make check
```

If it fails: fix the cause. Do **not** weaken a test, loosen a type, add a
suppression comment, or narrow the check's scope to get past it.

If the change adds behaviour, confirm there is a test that **fails without the
change**. If there isn't, the change is not tested — write one now.

### 6. Verified

`make check` proves the tests pass. It does not prove the code works. Run
`/verify` (or `/run`) to exercise the actual behaviour, or state plainly why
that is not meaningful for this change — for a docs-only diff, say so.

These are different claims. Most agent-written bugs live in the gap.

### 7. Reviewed

Run `/code-review` on the diff.

Additionally run `/security-review` if the diff touches any of: authentication,
authorization, input parsing, file paths, subprocess or shell invocation,
secrets or credentials, serialization, or dependency manifests.

Fix what the review finds, or say why a finding is a false positive. Do not
silently ignore one.

### 8. Documented

- Public API changed → docstrings/TSDoc updated.
- Behaviour a user would notice changed → `README.md` updated.
- A decision that is expensive to reverse → run `/adr`.
- Something a future session must know to avoid a mistake → it belongs in
  `CLAUDE.md` or a rule, not in this conversation.

### 9. Tracked

Check the mirror rule first: if this touched one example stack and not the
other, either make the matching change or state why it is stack-specific.

Then commit:

- Conventional Commits: `type(scope): subject`, imperative, ≤72 chars.
- The body explains **why**. The diff already shows what.
- Reference the issue if there is one.
- One logical change per commit. If the diff does two things, split it.

## Report

Finish with a short status: what shipped, what each step returned, and anything
you deliberately skipped **with the reason**. If a step failed and you could not
fix it, say that plainly rather than reporting success.
