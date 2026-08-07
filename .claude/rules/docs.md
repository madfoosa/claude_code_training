---
paths:
  - "**/*.md"
---

# Writing docs in this repo

Full reasoning in `docs/strategy/09-documentation.md`.

## Audience

Docs here are read by two audiences with the same need: a person returning after
three months, and a Claude session starting cold. Both want the *why*. Neither
needs a restatement of what the code plainly says.

## Rules

- **State the reason, not just the rule.** "Keep CLAUDE.md under 200 lines"
  is forgettable; "adherence drops as the file grows, and it costs tokens on
  every single request" is not.
- **Prefer a table to a list of paragraphs** when the content is genuinely
  tabular — decision criteria, file-to-purpose maps, comparisons.
- **Link laterally.** Every strategy doc links to the files that implement it,
  by path. A doc that describes a mechanism without naming its file will drift
  away from the code silently.
- **No invented metrics or benchmarks.** Do not write "improves quality by 30%".
  If a claim cannot be traced to something in this repo or to linked
  documentation, either cut it or mark it explicitly as a judgement call.
- **Show the failure it prevents.** A rule whose motivating failure is not
  stated will be dropped by the first person in a hurry.

## Mechanics

- One `# H1` per file, matching the filename's intent.
- Fenced code blocks always carry a language tag.
- Relative links between docs (`../runbooks/recovery.md`), so they survive the
  kit being copied into another repo.
- Markdown is **not** auto-formatted — prettier is scoped to
  `examples/typescript/` on purpose, so prose tables are not reflowed under you.

## The `At scale` callout

Each `docs/strategy/*.md` ends with a blockquote starting `**At scale:**`. It
says what a large engineering org does differently and *why the reason changes*
— not merely "add more process". If a pillar genuinely does not change with
scale, say that instead of inventing a difference.
