---
paths:
  - "**/*.py"
---

# Python

Applies to `examples/python/`. Enforced by `make lint-py` and `make typecheck-py`
(ruff + mypy `strict`), configured in `examples/python/pyproject.toml`.

## Typing

- Every function annotates its parameters and return type. `mypy strict` is on;
  an unannotated function is an error, not a style preference.
- `from __future__ import annotations` at the top of every module.
- Prefer `X | None` over `Optional[X]`, `list[str]` over `List[str]`.
- Never add `# type: ignore` to get past the checker. If a third-party stub is
  genuinely wrong, narrow the ignore to the rule (`# type: ignore[attr-defined]`)
  and add a comment saying why.

## Structure

- Source lives under `src/<package>/`; the package is importable only after
  `make setup-py`. Tests import the installed package (`from ratelimit import …`),
  never via a relative path out of `tests/`.
- Public API is re-exported from `__init__.py` and listed in `__all__`.
- One concept per module. `bucket.py` holds the bucket and nothing else.

## Errors

- Raise `ValueError` for a caller passing something impossible; reserve custom
  exceptions for conditions a caller might reasonably want to catch separately.
- Error messages state the offending value: `f"capacity must be positive, got
  {capacity}"`, not `"invalid capacity"`.
- Validate in the constructor, not on first use. Failing at construction points
  at the caller who got it wrong.

## Style

- Docstrings on every public module, class, and function. Google style, with an
  `Args:`/`Returns:`/`Raises:` block where there is anything to say.
- Comments explain *why*. The code already says what.
- Line length 88, enforced by ruff — do not fight the formatter by hand.
