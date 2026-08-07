# claude_code_training

A complete, opinionated strategy for doing software development **with** Claude
Code — and a working repo that proves it runs.

Most agent setups are a `CLAUDE.md` file and good intentions. This one is built
around a claim: *instructions you merely write down will be followed
inconsistently; instructions the machine enforces will be followed every time.*
So the strategy is split accordingly — guidance where guidance is enough,
enforcement where it isn't.

## Two things at once

**A portable kit.** `CLAUDE.md`, `.claude/`, and `Makefile` lift into any repo.
Fill in the Makefile verbs for your stack and the rest works unchanged.

**A live demonstration.** `examples/python/` and `examples/typescript/` are small
but real — they lint, typecheck, and test. Every rule and hook in the kit is
exercised against them, so nothing here is aspirational.

## Start here

```bash
make setup    # install dependencies for both stacks
make check    # lint + typecheck + test -- the gate
```

Then read [`docs/strategy/00-overview.md`](docs/strategy/00-overview.md). It
explains the whole model in one page and maps each idea to the file implementing
it.

## The shape of it

```
CLAUDE.md              The always-on contract. Hard cap: 200 lines.
Makefile               The single command surface. One vocabulary, no drift.
.claude/
  settings.json        Permissions and hook wiring
  rules/               Path-scoped guidance -- loads only for matching files
  skills/              Invocable workflows: /ship-it /handoff /adr /retro
  hooks/               Enforcement -- runs whether or not Claude cooperates
  agents/              Subagents for isolated work
docs/
  strategy/            The twelve pillars: why it is shaped this way
  adr/                 Architecture decision records
  runbooks/            Recovery procedures
examples/              The live slices, mirrored across two stacks
```

## The two load-bearing ideas

**One command surface.** The usual failure is drift: `CLAUDE.md` says `npm test`,
the hook runs `vitest`, CI runs `pnpm test:ci`, and they diverge without anyone
noticing. Here the `Makefile` is the only vocabulary. Claude, the hooks, and CI
all call the same verbs, so changing a tool means editing one line.

**A Definition of Done ladder.** Ten steps from *planned* to *captured*. Steps
3–5 are enforced by hooks, 6–9 are walked by `/ship-it`, and step 10 is the
feedback loop that keeps the kit from rotting. It lives in `CLAUDE.md` and is
re-checked by CI.

## Lifting the kit into another repo

```bash
cp -r CLAUDE.md .claude Makefile /path/to/your-repo/
```

Then:

1. Rewrite the `Makefile` bodies for your stack. Keep the target *names* —
   everything else depends on them.
2. Trim `CLAUDE.md` to your project. Keep the Definition of Done and the
   `## Never` section; replace the rest.
3. Delete the `.claude/rules/` files for languages you don't use.
4. Run `/doctor`, then `/context`, and confirm your files actually loaded.

Hooks in project settings require accepting the workspace trust dialog the first
time you open the repo. That is expected.

## A note on scale

This repo is operated by one person but shaped like a production engineering
org — CI matrices, CODEOWNERS, ADRs, telemetry. That is deliberate. Each
strategy doc carries an **At scale** callout explaining what a large team does
differently and why, so the reasoning is visible even where the ceremony isn't
warranted yet.
