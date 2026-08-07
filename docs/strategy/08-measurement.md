# 08 — Measurement

> How you know any of this is working — and, more importantly, how to avoid
> optimising the number instead of the outcome.

## Start with the honest part

Most measurement of agent-assisted development is bad. It is easy to count tokens
and lines; it is hard to count whether the software got better. The metrics that
are cheap to collect are mostly the ones that do not matter, and a few of them
actively mislead.

So this pillar is organised around a warning as much as a method: **be clear what
question a number answers before you collect it, and be clearer about what it
cannot answer.**

## What Claude Code emits

Telemetry ships **off**. Turn it on in `.claude/settings.local.json` — see
`.claude/settings.local.json.example`.

```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER=console          # start here: prints locally, sends nothing
```

Graduating to a collector you run:

```bash
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

The metrics available:

| Metric | Honestly measures | Commonly misread as |
| --- | --- | --- |
| `claude_code.session.count` | Sessions started | Productivity |
| `claude_code.lines_of_code.count` | Lines changed | Output, value |
| `claude_code.commit.count` | Commits created | Throughput |
| `claude_code.pull_request.count` | PRs opened | Delivery |
| `claude_code.cost.usage` | USD spent | — (this one is what it says) |
| `claude_code.token.usage` | Tokens consumed | Efficiency |
| `claude_code.code_edit_tool.decision` | Edits accepted vs rejected | Quality |
| `claude_code.active_time.total` | Active seconds | Effort |

**Content logging is off by default and should stay off** unless you own the
collector and understand its retention policy. `OTEL_LOG_USER_PROMPTS` and
`OTEL_LOG_RAW_API_BODIES` ship your prompts and source code to wherever the
endpoint points.

## The metrics that mislead

**Lines of code.** An agent can produce a great deal of it. A change that deletes
200 lines is usually better than one that adds 200. As a productivity measure it
is worse than useless because it is *invertible* — optimise for it and you get
verbose code.

**Token usage and cost.** Real, and worth watching for budget. But low cost is
not a goal in itself: a session that burned tokens exploring before making a
correct change beats a cheap one that guessed wrong. Cost is only interpretable
alongside an outcome.

**Edit acceptance rate.** Sounds like quality. Mostly measures whether you were
paying attention — it goes *up* when you stop reading diffs carefully.

**Test coverage percentage.** The most dangerous one in this context. An agent
can drive coverage to 95% with tests that assert almost nothing. Coverage
measures which lines executed, not whether a failure would have been caught. See
[04 — Testing](04-testing.md).

## The signals worth tracking

These are harder to collect and actually answer the question. Most need no
tooling.

| Signal | How to read it | Where it comes from |
| --- | --- | --- |
| **Rework rate** | How often a change is followed within days by a fix to the same code. Rising = quality falling, whatever the other numbers say | `git log` on the same paths |
| **Revert rate** | Changes backed out entirely. The bluntest quality signal there is | `git log --grep=revert` |
| **Review findings per diff** | Real findings from `/code-review` or `change-reviewer`. Trending down = the rules are working | Review output |
| **Gate failure rate** | How often `make check` fails after Claude declares done. High = the ladder is being skipped | `stop-gate.sh` blocks |
| **Plan adherence** | Did the change match the plan? Frequent divergence means planning is too shallow | Plan file vs. diff |
| **Repeat corrections** | Same correction typed twice = a missing rule, by definition | Your own memory, or `/retro` |

**Repeat corrections is the one to watch above all others.** It is the direct
input to [12 — The feedback loop](12-feedback-loop.md), and it needs no
instrumentation — only noticing.

## Solo-scale proxies

You do not need a collector to answer the useful questions:

```bash
# Rework: files changed most often in the last month
git log --since=1.month --name-only --pretty=format: | sort | uniq -c | sort -rn | head

# Reverts and follow-up fixes
git log --oneline --since=1.month --grep='revert\|fix.*regression' -i

# Commit type mix -- lots of fix relative to feat is a signal
git log --since=1.month --pretty=%s | cut -d: -f1 | sort | uniq -c | sort -rn
```

A file appearing at the top of the first list every month is telling you
something — either it is genuinely central, or changes to it keep being wrong.

## The counterfactual problem

The question everyone wants answered is "is Claude Code making me faster?" and it
is close to unanswerable honestly. You cannot run the counterfactual: you do not
know how long the same change would have taken you alone, and self-reported
estimates of that are unreliable in a known direction.

Be suspicious of any confident number here, including one you produce yourself.
What you *can* measure is whether **quality is holding** as volume changes —
rework, reverts, and gate failures. If those stay flat while output rises,
something good is happening. If they climb, the extra output is borrowed against
future debugging.

## What to actually do

1. Turn telemetry on with `console` for a week. Look at cost and token usage to
   calibrate what things cost. This is the one place the built-in metrics are
   straightforwardly useful.
2. Track **repeat corrections** — no tooling, just noticing. Feed each into
   `/retro`.
3. Once a month, run the git one-liners above. Look for files that keep coming
   back.
4. Ignore lines of code entirely.

> **At scale:** the failure mode changes character. Solo, the risk is measuring
> nothing; at org scale, the risk is measuring the wrong thing *and attaching
> consequences to it*. Once agent metrics reach a performance review, they get
> optimised — lines of code and commit counts are trivially gameable, and the
> gaming looks like productivity. Orgs that do this well aggregate at team level
> rather than individual, pair every volume metric with a quality metric (DORA
> change-failure rate is the usual anchor), and keep content logging off by
> default for a reason that is legal as much as technical. The counterfactual
> problem does not go away with sample size — it just becomes easier to paper over.
