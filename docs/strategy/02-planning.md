# 02 — Planning

> Step 1 of the Definition of Done. The cheapest place to fix a mistake is
> before it becomes code.

## Why plan at all with an agent

The argument against planning is that an agent writes code fast enough that
throwing it away is cheap. That argument is wrong for a specific reason: the
expensive part is not writing the code, it is *reviewing* it. A wrong 300-line
diff costs you a careful read before you discover it was wrong.

Planning moves the decision point to where review is cheap — a paragraph you can
disagree with in five seconds.

There is a second, less obvious benefit. An agent asked to plan will explore
first, and exploration surfaces the thing that changes the approach: the helper
that already exists, the test that pins down behaviour you were about to break,
the second call site nobody mentioned.

## When to plan

| Plan first | Just do it |
| --- | --- |
| New feature or capability | Typo, comment, formatting |
| Anything touching 3+ files | Single-line fix with an obvious cause |
| A bug whose cause is not yet known | A bug you have already diagnosed |
| Refactors and renames across modules | Adding one test to an existing suite |
| Anything with more than one reasonable design | The user gave exact instructions |
| Changing a public API | Reverting a known-bad commit |

The bug row is the one to internalize. "Fix the failing test" is not a plan
until you know *why* it fails. Jumping to a fix before diagnosis produces changes
that make the symptom disappear without addressing the cause.

## What a plan must contain

`/plan-change` enforces this shape. A plan without these is a statement of
intent, not a plan:

| Section | Why it must be there |
| --- | --- |
| **Context** | Why now, what problem, what outcome. A plan without this cannot be evaluated — you can only check *how*, never *whether* |
| **Approach** | The chosen design. One approach, not a survey of four |
| **Files** | Every path to be created or modified, with what changes in each |
| **Reuse** | Existing functions you will call rather than rewrite, by path |
| **Verification** | The exact test to write and command to run |
| **Risks** | What could break; what is deliberately out of scope |

**Files** and **Verification** carry the most weight. A plan naming specific
paths proves exploration actually happened. A plan with no verification step
will produce a change nobody can confirm works.

## Exploration comes first

The failure mode is planning from assumption — proposing `src/utils/time.py`
without checking whether it exists, or what is already in it.

Order of operations:

1. **Search for existing implementations.** Reuse beats creation, always.
2. **Read the tests** covering the area. They define what must not break.
3. **Read the callers.** A signature change is only safe if you know who calls it.
4. **Check which `.claude/rules/` apply** to those paths.
5. *Then* decide.

For anything spanning more than a couple of files, delegate the search to the
Explore subagent. It reads widely and returns only conclusions, so the main
context stays clean for the actual reasoning — see
[01 — Context engineering](01-context-engineering.md).

## Decompose to reviewable units

A plan producing one enormous diff has failed even if the diff is correct,
because nobody will review it properly. Large diffs get approved on trust, which
defeats the purpose of review entirely.

Split along these seams:

- **Refactor, then change.** Move code in one commit, alter behaviour in the
  next. A diff doing both is unreviewable — you cannot tell moved lines from
  modified ones.
- **One behaviour per change.** If the summary needs "and", split it.
- **Mechanical separate from judgement.** A rename across forty files should not
  share a commit with the logic change that motivated it.

## Plans are artifacts, not conversation

A plan that exists only in chat evaporates at compaction. Write it to a file —
plan mode does this automatically. Then:

- You can re-read it mid-implementation when you have lost the thread.
- A future session can see what was intended, not just what was built.
- The gap between plan and result becomes visible, which is the raw material for
  [12 — The feedback loop](12-feedback-loop.md).

## Stop at the plan

`/plan-change` ends by presenting the plan and waiting. That pause is the entire
point — an agent that plans and then immediately implements has given you a
narration, not a decision point.

If two readings of the request would produce materially different work, ask
**before** coding. A question costs one turn. A wrong assumption costs the whole
change plus the review that catches it.

## When the plan turns out to be wrong

It will. Implementation surfaces things exploration missed.

- **Small deviation** (a different helper, an extra file): proceed, and say so in
  the final report.
- **The approach doesn't work**: stop. Do not improvise a second design mid-flight
  — that produces changes nobody agreed to. Say what you hit and re-plan.
- **The scope was wrong**: stop and say so. Silently expanding scope is how a
  one-file fix becomes an eleven-file diff nobody asked for.

> **At scale:** planning stops being about correctness and starts being about
> coordination. A solo developer's plan only has to convince themselves; a team's
> plan has to reach everyone whose code the change touches, which is why large
> orgs add design docs and RFC review for anything crossing a team boundary. The
> other shift is that agents working in parallel need *non-overlapping* plans —
> two sessions independently refactoring the same module produce a merge conflict
> neither anticipated. At solo scale the sequencing lives in your head; past that
> it has to be written down, which is what [07 — Tracking](07-tracking.md) is for.
