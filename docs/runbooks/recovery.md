# 11 — Recovery

> A runbook, not an essay. When a session has gone wrong, you want steps.

## First: stop making it worse

The instinct when an agent has produced a mess is to ask it to fix the mess. That
often compounds it — the same context that produced the wrong change is still
loaded, and the "fix" is written from the same misunderstanding.

**Interrupt first. Assess second. Then decide whether to steer or abandon.**

## Steer or abandon?

| Steer | Abandon |
| --- | --- |
| One wrong decision, recently, clearly identified | Multiple compounding wrong decisions |
| The approach is right, execution slipped | The approach itself is wrong |
| You can name the correction in one sentence | You would be describing the whole task again |
| Session is otherwise coherent | Session is repeating itself or contradicting earlier turns |

Abandoning feels wasteful and usually is not. A fresh session with a good plan
beats a confused one carrying an hour of wrong turns. The work is not lost — it
is in git, or it was not worth keeping.

---

## Situations

### Uncommitted changes you want to discard

```bash
git diff                          # look before you delete
git checkout -- path/to/file      # one file
git checkout -- .                 # everything tracked
git clean -n                      # DRY RUN: what untracked files would go
git clean -fd                     # actually remove them
```

Always `git diff` and `git clean -n` first. `git clean -fd` deletes untracked
files with no undo.

### Changes you might want later

```bash
git stash push -m "half-finished refactor"
git stash list
git stash show -p stash@{0}       # inspect without applying
git stash pop                     # restore and drop
```

Stash rather than discard when you are not sure. It costs nothing and buys a
reversible decision.

### A bad commit, not yet pushed

```bash
git reset --soft HEAD~1     # undo commit, keep changes staged
git reset HEAD~1            # undo commit, keep changes unstaged
git reset --hard HEAD~1     # undo commit AND destroy the changes
```

`--hard` is denied in `.claude/settings.json` for exactly this reason: it
destroys uncommitted work silently. Run it yourself, deliberately, having read
the diff.

### A bad commit, already pushed

```bash
git revert <sha>            # a NEW commit undoing the old one
```

Revert, do not rewrite. Force-pushing a shared branch breaks every checkout of
it, which is why `git push --force` is denied outright.

### Work lost — a reset or a bad rebase

Almost nothing committed is truly gone:

```bash
git reflog                  # every HEAD position, including "lost" commits
git checkout <sha>          # go look
git branch recovered <sha>  # rescue it
```

The reflog keeps entries for around 90 days by default. If it was ever committed,
it is probably still there.

### The gate will not go green

```bash
make check                  # read the FIRST failure, not the last
make check-py               # narrow it
make check-ts
```

Fix the first failure and re-run — later failures are frequently caused by it.

If it fails on `main` too, the failure predates your change and is a separate
problem. Say so rather than trying to fix both at once.

**Do not** reach for `# type: ignore`, `eslint-disable`, `skip`, or a weakened
assertion. That converts a caught error into an uncaught one and marks the change
verified. `CLAUDE.md` forbids it and `change-reviewer` flags every instance.

### A hook is blocking you and you believe it is wrong

Test it directly rather than guessing:

```bash
jq -nc '{tool_input:{file_path:"'"$PWD"'/.env"}}' | .claude/hooks/protect-paths.sh
echo '{"stop_hook_active":false}' | .claude/hooks/stop-gate.sh
```

If it is genuinely wrong, fix the hook — in a commit that says why. If it is
right and you need past it once:

```bash
CLAUDE_ALLOW_PROTECTED=1 claude
```

Do not disable hooks wholesale. That turns off every other guardrail at the same
time, including the ones you were not thinking about.

### Claude edited something it should not have

```bash
git diff --stat             # what actually changed
git checkout -- <path>      # revert that file
```

Then ask why the guardrail did not catch it. An edit that should have been
blocked is a gap in `protect-paths.sh` or `permissions.deny` — run `/retro` and
close it. This is exactly the trigger the feedback loop exists for.

### The session is confused

Symptoms: repeating completed work, contradicting itself, ignoring rules it
followed earlier, increasingly confident about things it has not checked.

1. `/handoff` — capture state while it is still coherent
2. Commit or stash
3. Start a fresh session
4. Let `session-start.sh` reload clean state

Also worth checking: `/context` to see what actually loaded, `/doctor` for a
config checkup.

### Risky work you want isolated

```bash
git worktree add ../repo-experiment -b experiment/risky
cd ../repo-experiment
# ... a separate directory; your main checkout is untouched
git worktree remove ../repo-experiment
```

Better than a branch switch when you want to keep working in the main tree, and
better than trusting an agent not to wander.

---

## Prevention

| Habit | Prevents |
| --- | --- |
| Commit before anything risky | Losing work with no undo |
| Never work on `main` | Needing surgery instead of `git checkout main` |
| `/handoff` before a long break | Rediscovering yesterday's traps |
| `make check` often, not just at the end | A pile of failures with no obvious first cause |
| Small commits | Reverts that take unrelated work with them |
| Read `git diff` before committing | Committing something you did not intend |

The first two cover most of it. An agent working on a branch, with a clean commit
behind it, cannot do damage that `git checkout main` will not undo.

> **At scale:** individual recovery matters less; blast radius matters more. One
> person can `git reset` their own mistake, but a bad merge to a shared `main`
> blocks everyone. Orgs respond with protected branches, merge queues that verify
> before landing, mandatory review, and staged rollout so a bad change is caught
> by a fraction of traffic rather than all of it. The shift is from *undo* to
> *containment* — at team scale you assume mistakes will land and design so they
> are survivable, rather than assuming they can be caught first.
