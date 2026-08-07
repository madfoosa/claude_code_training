# 12 — The feedback loop

> Step 10 of the Definition of Done. Without this pillar the other eleven are a
> snapshot that decays. With it, every mistake makes the next session better.

## Why this is the pillar that matters most

Everything else in this kit was written at one moment, by someone with a
particular set of assumptions, against a codebase in a particular state. All
three change.

A setup with no feedback loop degrades in a predictable way: rules accumulate
without pruning, contradictions creep in, instructions describe a codebase that
has moved on, and adherence drops as the files grow. Eventually people stop
trusting the config and start working around it — at which point it is worse than
having none, because it is still consuming context.

A setup **with** a feedback loop compounds instead. Each mistake, converted into a
rule, is a mistake that does not recur.

The difference is not the quality of the initial setup. It is whether there is a
mechanism for updating it.

## The trigger table

Each row is a signal you can actually notice, paired with the layer that fixes
it. `/retro` walks this.

| Trigger | Add | Where |
| --- | --- | --- |
| Claude got a convention wrong **twice** | A rule | `CLAUDE.md`, or `.claude/rules/` if path-specific |
| A review caught something Claude should have known | A rule | Same |
| You typed the same correction you typed last session | A rule | Same |
| You keep typing the same prompt to start a task | A skill | `.claude/skills/<name>/SKILL.md` |
| You pasted the same playbook a third time | A skill | Same |
| It **must** happen every time, no judgement | A hook | `.claude/hooks/` |
| A side task flooded the context with output | A subagent | `.claude/agents/` |
| A second repo needs the same setup | A plugin | Package it |

### Why "twice"

Once is noise. An agent makes a wrong call for many reasons — an ambiguous
prompt, an unusual file, ordinary variance. Writing a rule for every single
miss fills your context budget with over-fitted responses to one-offs.

Twice is a pattern. It means the information genuinely is not available, or is
available in a form that does not work.

## Diagnose before fixing

The most common mistake in this loop is fixing the symptom. Before writing
anything, work out which failure you actually had:

| Failure | Symptom | Fix |
| --- | --- | --- |
| **Not written down** | The information exists only in your head | Write it |
| **Not loaded** | It is in a skill that never triggered, or a path-scoped rule that did not match | Fix the *placement*, not the content |
| **Not followed** | It loaded, and was ignored | Make it specific, or find the contradiction |
| **Wrong** | It was followed, and the result was bad | Change the rule |

The second row is the one people get wrong. Rewriting a rule that never entered
context will not help. **Run `/context` and check whether the file loaded before
you edit a word of it.**

## Guidance or enforcement?

The single most important choice in this loop.

Ask: *what happens when this is violated?*

- "A slightly worse commit" → guidance is fine. Write it down.
- "A leaked credential", "deleted data", "an unverified change shipped" →
  guidance is **not enough**. It needs a hook.

The mistake is putting a must-hold-every-time rule in `CLAUDE.md` and treating
the job as done. Prose is a request; a hook is a guarantee. See
[06 — Guardrails & permissions](06-guardrails-permissions.md).

The reverse mistake also exists: making something a hook that genuinely requires
judgement. A hook cannot weigh context, so it will block legitimate work and get
disabled — taking every other hook with it.

## Prune while you are there

Every entry costs context on every request, forever. Growth without pruning is
exactly how a config file becomes noise that nothing follows.

When you add something, delete something that is:

- **Obsolete** — describes a tool or layout that has changed
- **Duplicated** — the same rule in `CLAUDE.md` and a rule file
- **Derivable** — a directory listing or dependency list Claude can just read
- **Unenforced** — a rule routinely ignored with no consequence. These are
  actively harmful: they teach the model that this file is advisory

The line cap on `CLAUDE.md` forces this. When an addition pushes it over 200
lines, something has to move down the ladder or come out. That is the mechanism
working, not an obstacle to route around.

## Watch for contradictions

Two conflicting instructions are worse than neither, because Claude picks one and
which one is not stable across sessions. Behaviour becomes unpredictable rather
than merely absent.

Contradictions accumulate silently — a rule added in March quietly conflicts with
one from January, and nobody re-reads the whole file. So `/retro` includes an
explicit check, and keeping total volume low is what makes that check feasible.

## Not every mistake has a systemic fix

Worth stating plainly, because the pressure runs the other way: sometimes an
agent just gets something wrong, and no rule would have prevented it without
adding noise that costs more than the mistake did.

`/retro` is instructed to say so rather than manufacture a rule. A config file
padded with over-fitted responses to one-off errors is a config file nobody
reads.

## The rhythm

**Continuous.** When you notice a repeat correction, run `/retro` then — not
later. The intention to do it later does not survive the session.

**Monthly.** Twenty minutes:

```bash
/doctor                     # config checkup; proposes CLAUDE.md trims
/context                    # what is actually loading
wc -l CLAUDE.md             # against the 200-line cap
```

Then read `CLAUDE.md` and `.claude/rules/` end to end. Delete what is obsolete.
Look for contradictions. Check that each rule still describes reality.

**Per change.** Step 10 of the ladder. `/ship-it` ends by asking what was learned.

## Signals that the loop is working

- Repeat corrections trending down — the direct measure
- `CLAUDE.md` staying near its cap rather than growing past it, because things are
  moving down the ladder
- Review findings per diff falling
- `stop-gate.sh` blocking less often

And that it is not:

- The same correction three sessions running
- Rules nobody follows and nobody removes
- A `CLAUDE.md` you have not read in months
- Hooks disabled "temporarily"

> **At scale:** this pillar fails differently, and worse. Solo, the loop runs on
> noticing and discipline, and its worst case is that you skip it for a month. On
> a team, nobody owns it by default — everyone notices the same repeat correction,
> assumes someone else will write it down, and nobody does. Meanwhile the config
> grows by accretion, because adding is easy and deleting requires knowing why
> something was added. Orgs that keep this working give the loop a named owner and
> a recurring slot, put `CLAUDE.md` under CODEOWNERS so changes get reviewed, and
> enforce the size cap in CI. The pattern is general: mechanisms that survive on
> individual discipline at small scale need an explicit owner at large scale, or
> they quietly stop happening.
