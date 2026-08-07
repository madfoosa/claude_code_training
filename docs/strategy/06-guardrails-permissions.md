# 06 — Guardrails and permissions

> The distinction this pillar rests on: **a rule you write down is a request; a
> rule the machine enforces is a guarantee.** Both belong in a working setup, and
> confusing them is how setups fail.

## Why prose is not enough

`CLAUDE.md` is loaded as context. Claude reads it, weighs it against everything
else in the window, and complies — usually. Compliance degrades with file length,
competing instructions, long sessions, and unusual situations.

This is not a defect to prompt harder around. It is a property of the mechanism,
and the correct response is to stop relying on it for things that must always
hold.

"Never edit `.env`" in `CLAUDE.md` is a request that will be honoured almost
always. The same rule in a `PreToolUse` hook is honoured every time, including
the session where the model has convinced itself there is a good reason.

**Both exist in this repo.** The prose explains *why*, which helps Claude make
good decisions in adjacent situations the hook does not cover. The hook makes it
*true*, which is what you need when reasoning fails.

## The enforcement layers

| Layer | Mechanism | Enforced by | Overridable |
| --- | --- | --- | --- |
| Guidance | `CLAUDE.md`, `.claude/rules/` | Claude's judgement | Implicitly, by reasoning |
| Permission rules | `permissions.deny` in settings | The client, before the tool runs | Only by editing settings |
| Hooks | `PreToolUse` scripts | Shell script, exit code 2 | Only by an explicit env var |
| Managed policy | Org-deployed settings | The client; users cannot override | No |

Choose by asking: *what happens if this is violated?* If the answer is "a
slightly worse commit", guidance is fine. If it is "a leaked credential" or
"deleted data", it needs a layer that does not depend on judgement.

## What this repo denies

`permissions.deny` in `.claude/settings.json` — checked before a tool runs:

```jsonc
"Read(./.env)", "Read(./.env.*)",       // secrets
"Read(./secrets/**)", "Read(~/.ssh/**)", "Read(~/.aws/**)",
"Bash(git push --force *)",              // unrecoverable for collaborators
"Bash(git reset --hard *)",              // silently destroys uncommitted work
"Bash(curl * | sh)", "Bash(wget * | bash)"  // remote code execution
```

Each is there because the failure is **unrecoverable or invisible**, not merely
undesirable. `git reset --hard` earns its place by destroying uncommitted work
with no undo and no output.

`permissions.ask` holds operations that are legitimate but consequential — `git
push`, merging a PR. These are not blocked, only surfaced.

`permissions.allow` matters as much as the denies, for a reason that is easy to
miss: **a setup that prompts constantly gets approved reflexively.** Allowlisting
`make *` and read-only git commands keeps prompts rare enough that you actually
read them. Prompt fatigue is a security failure, not an ergonomics complaint.

## What the hooks enforce

Permission rules match tool calls. Hooks run arbitrary logic, so they cover what a
pattern cannot express.

**`protect-paths.sh`** (`PreToolUse` on `Edit|Write|NotebookEdit`) blocks:

| Path | Why |
| --- | --- |
| `.env`, `.env.*` | Secrets. `.env.example` is explicitly carved out — the template is meant to be edited |
| `secrets/**` | Same, by directory |
| Lockfiles | Generated artifacts. Hand-editing produces a resolution no resolver would |
| `.github/workflows/**` | CI is the check on the agent's own work. It changing that check unprompted is a conflict of interest |

The last one is the interesting case, and it generalises: **an agent should not
be able to silently weaken the thing that verifies it.**

**`stop-gate.sh`** (`Stop`) is the unusual one. It blocks the *end of a turn*
when tracked source has changed since the last passing `make check`. Without it,
the Definition of Done is advisory — a ladder nobody is obliged to climb. With
it, "I've finished" requires having actually run the gate.

## Escape hatches must be explicit

Every guardrail needs a documented way past it, or people route around it in ways
you cannot see.

`protect-paths.sh` honours `CLAUDE_ALLOW_PROTECTED=1`. That is deliberate: a
visible, deliberate, session-scoped act you can find in your shell history.

The failure mode to avoid is a guardrail so rigid that the workaround becomes
"turn off the hooks" — which disables every other guardrail at the same time.

## Permission modes

| Mode | Behaviour | Safe when |
| --- | --- | --- |
| `default` | Prompts for anything not allowlisted | Normal work |
| `plan` | Read-only; cannot edit | Exploration, planning |
| `acceptEdits` | Auto-accepts file edits | Mechanical refactors with test coverage |
| `bypassPermissions` | No prompts at all | **Only** in a disposable sandbox |

`bypassPermissions` in a container you can throw away is reasonable. On a machine
with your SSH keys and production credentials it is not, regardless of the task.

Note what the modes do and do not affect: `deny` rules and `PreToolUse` hooks
still apply in `acceptEdits`. That is why the important limits live there rather
than depending on which mode you happened to be in.

## Bounding the blast radius

Guardrails constrain what an agent *can* do; the environment constrains how much
that matters.

- **Git is the undo.** Commit before anything risky. See
  [11 — Recovery](../runbooks/recovery.md).
- **Worktrees isolate experiments.** A branch in a separate directory cannot
  disturb your main checkout.
- **Containers and cloud sessions** have no access to your local credentials —
  which is what makes looser permission settings defensible there.

## Testing your guardrails

An untested guardrail is a guardrail you believe in. Every hook here was driven
with the exact JSON payload it receives:

```bash
jq -nc '{tool_input:{file_path:"/repo/.env"}}' | .claude/hooks/protect-paths.sh
# -> {"hookSpecificOutput":{"permissionDecision":"deny", ...}}
```

Test the **allow** cases too. A hook that denies everything passes a
deny-only test and makes the repo unusable.

> **At scale:** the mechanics are the same; what changes is who controls them.
> Project settings are editable by anyone who can commit, which makes them
> guidance again at team scale — an engineer who finds a deny rule inconvenient
> can simply delete it. Orgs move real limits to *managed settings*, deployed by
> MDM or Group Policy and not overridable by users, and set
> `allowManagedPermissionRulesOnly` so local settings cannot widen them. The
> underlying question is unchanged and only becomes more pointed: which rules must
> survive contact with someone who disagrees with them?
