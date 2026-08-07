---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript

Applies to `examples/typescript/`. Enforced by `make lint-ts` and
`make typecheck-ts` (eslint type-aware + `tsc --strict`), configured in
`examples/typescript/tsconfig.json` and `eslint.config.js`.

## Typing

- `strict` is on, plus `noUncheckedIndexedAccess` and
  `exactOptionalPropertyTypes`. Indexing an array yields `T | undefined` and you
  must handle it.
- `any` is an eslint error. `unknown` plus a narrowing check is the answer.
- Never add `@ts-expect-error` or `eslint-disable` to get past a check. If a rule
  is genuinely wrong for this codebase, change the rule in `eslint.config.js` and
  say why in the commit — do not silence it at the call site.
- Export types with `export type { … }` (`verbatimModuleSyntax` is on).

## Structure

- Source under `src/`, one concept per module, re-exported from `src/index.ts`.
- Use `.js` extensions in relative imports (`from './bucket.js'`) — required by
  ESM resolution even though the file on disk is `.ts`.
- Private class state uses `#field`, not `private`. It is enforced at runtime.

## Errors

- Throw `RangeError` for a numeric argument outside its valid domain,
  `TypeError` for the wrong shape. Reserve bare `Error` for genuinely
  unclassifiable failures.
- Validate integers explicitly: `Number.isInteger(n)`. TypeScript's `number`
  admits `1.5`, `NaN`, and `Infinity`, and the type system will not catch them.
- Error messages state the offending value.

## Style

- TSDoc on every exported symbol, with `@throws` where it applies.
- Prettier owns formatting (88 columns, single quotes) — do not hand-format.
