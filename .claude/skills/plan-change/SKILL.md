---
description: Plan a non-trivial change before writing code -- explore the codebase, name the files, and define how the result gets verified. Use when starting a feature, a refactor, or a bug fix whose cause is not yet known.
when_to_use: Invoked as /plan-change, or when the user asks to plan, design, or scope a change before implementing it.
argument-hint: [issue number or description of the change]
---

# Plan a change

Step 1 of the Definition of Done. The output is a written plan, not code.

## Current state

Branch: !`git branch --show-current`

Uncommitted changes:
!`git status --short || echo "(clean)"`

## What to do

**The request:** $ARGUMENTS

### 1. Explore before deciding

Do not plan from assumption. Find out:

- Where does this behaviour live now? Search for it — do not guess a path.
- **Is there already something that does this?** Reuse beats creation. Check
  `examples/*/src/` for an existing helper before proposing a new one.
- What tests currently cover the area? They define the behaviour you must not
  break.
- Which of `.claude/rules/` apply to the files you will touch?

Use the Explore subagent if this spans more than a couple of files — it keeps
the search output out of the main context.

### 2. Write the plan

A plan is not a summary of intent. It must contain:

| Section | Content |
| --- | --- |
| **Context** | Why this change, what problem it solves, what the outcome is |
| **Approach** | The chosen design in a few sentences — one approach, not a survey |
| **Files** | Every file to be created or modified, by path, with what changes in each |
| **Reuse** | Existing functions and utilities you will call rather than rewrite |
| **Verification** | Exactly how you will know it worked — the test to write, the command to run |
| **Risks** | What could break, and what is deliberately out of scope |

### 3. Mirror check

If the change touches `examples/python/`, the matching change in
`examples/typescript/` is part of the same plan (and vice versa). Say so
explicitly, or state why the change is genuinely stack-specific.

### 4. Stop and confirm

Present the plan and wait. Do not begin implementing.

If two readings of the request would produce materially different work, ask
now — a question before coding costs one turn; a wrong assumption costs the
whole change.

## Then

Once the plan is approved, implement it and run `/ship-it` to walk the change
through the rest of the Definition of Done.
