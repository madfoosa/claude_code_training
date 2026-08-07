# The single command surface.
#
# CLAUDE.md, .claude/hooks/*, and .github/workflows/ci.yml invoke ONLY these
# verbs. Nothing else. When a tool changes, it changes here and nowhere else --
# that is the whole point. See docs/strategy/00-overview.md.

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

PY_DIR := examples/python
TS_DIR := examples/typescript

# Written by `make check` on success. .claude/hooks/stop-gate.sh compares this
# file's mtime against the newest tracked source file to decide whether the
# working tree has been verified since it was last edited.
STAMP := .make-check-stamp

.PHONY: help setup fmt lint typecheck test check clean fmt-file \
        setup-py fmt-py lint-py typecheck-py test-py check-py \
        setup-ts fmt-ts lint-ts typecheck-ts test-ts check-ts

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Per-stack variants exist for each verb: e.g. check-py, check-ts."

# ---------------------------------------------------------------- aggregate --

setup: setup-py setup-ts ## Install dependencies for both stacks

fmt: fmt-py fmt-ts ## Rewrite files to canonical format

lint: lint-py lint-ts ## Check style and format without rewriting

typecheck: typecheck-py typecheck-ts ## Run static type analysis

test: test-py test-ts ## Run the test suites

check: lint typecheck test ## The gate: lint + typecheck + test
	@touch $(STAMP)
	@echo "==> check passed"

clean: ## Remove build artifacts, caches, and the check stamp
	@rm -f $(STAMP)
	@rm -rf $(PY_DIR)/.pytest_cache $(PY_DIR)/.mypy_cache $(PY_DIR)/.ruff_cache
	@rm -rf $(TS_DIR)/node_modules/.vite $(TS_DIR)/coverage
	@find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "==> cleaned"

# ------------------------------------------------------------------- python --

setup-py: ## Install Python dependencies
	@cd $(PY_DIR) && uv sync --quiet

fmt-py:
	@cd $(PY_DIR) && uv run --quiet ruff format . && uv run --quiet ruff check --fix .

lint-py:
	@cd $(PY_DIR) && uv run --quiet ruff format --check . && uv run --quiet ruff check .

typecheck-py:
	@cd $(PY_DIR) && uv run --quiet mypy src tests

test-py:
	@cd $(PY_DIR) && uv run --quiet pytest -q

check-py: lint-py typecheck-py test-py ## The gate, Python only
	@echo "==> check-py passed"

# --------------------------------------------------------------- typescript --

setup-ts: ## Install TypeScript dependencies
	@cd $(TS_DIR) && pnpm install --silent

fmt-ts:
	@cd $(TS_DIR) && pnpm exec prettier --write --log-level warn . && pnpm exec eslint --fix .

lint-ts:
	@cd $(TS_DIR) && pnpm exec prettier --check --log-level warn . && pnpm exec eslint .

typecheck-ts:
	@cd $(TS_DIR) && pnpm exec tsc --noEmit

test-ts:
	@cd $(TS_DIR) && pnpm exec vitest run --silent

check-ts: lint-ts typecheck-ts test-ts ## The gate, TypeScript only
	@echo "==> check-ts passed"

# ----------------------------------------------------------------- one file --

fmt-file: ## Format a single file: make fmt-file FILE=path/to/file
	@if [ -z "$(FILE)" ]; then echo "fmt-file: FILE= is required" >&2; exit 2; fi
	@if [ ! -f "$(FILE)" ]; then exit 0; fi
	@set +e; \
	case "$(FILE)" in \
	  *.py) \
	    cd $(PY_DIR) 2>/dev/null && \
	    uv run --quiet ruff format "$(CURDIR)/$(FILE)" >/dev/null 2>&1; \
	    uv run --quiet ruff check --fix --quiet "$(CURDIR)/$(FILE)" 2>&1 | tail -20 ;; \
	  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.md|*.yml|*.yaml) \
	    cd $(TS_DIR) 2>/dev/null && \
	    pnpm exec prettier --write --log-level error "$(CURDIR)/$(FILE)" >/dev/null 2>&1 ;; \
	  *) exit 0 ;; \
	esac; \
	exit 0
