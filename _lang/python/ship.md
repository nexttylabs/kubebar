---
description: Run the Python quality gate (format, lint, typecheck, test) before shipping.
allowed-tools:
  - Bash(ruff:*)
  - Bash(mypy:*)
  - Bash(pytest:*)
---

# Ship

Run the Python quality gate. Stop on the first failure and fix it before continuing.

1. **Format**: `ruff format --check .`
2. **Lint**: `ruff check .`
3. **Typecheck**: `mypy .`
4. **Test**: `pytest`

All four steps must pass with zero warnings before committing or opening a PR.
