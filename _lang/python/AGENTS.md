# {{PROJECT_NAME}} Python Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- If a deeper guide exists in a subdirectory or under `docs/architecture/`, treat that guide as authoritative for that area.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

## Architecture Mental Model

- Keep entry points and startup wiring thin; move module-owned logic into the module that owns it.
- Keep domain logic separate from transport, persistence, and external service adapters.
- Extend existing types, service layers, and registries before adding one-off integration paths.

## Where to Work

- Application source: `src/`
- Tests: `tests/`
- Tooling and automation: `scripts/`
- Documentation and longer specs: `docs/`

## Build & Quality Gate

```bash
ruff format --check .
ruff check .
mypy .
pytest
```

Use `python -m build` before shipping a package or release artifact.

## Coding Rules

- Type hints on all public functions — parameters and return types, no exceptions
- `from __future__ import annotations` at the top of every module
- No bare `except:` — always catch specific exception types
- Use structured logging (`logging.getLogger(__name__)`) — never bare `print` in library code
- Prefer composition over inheritance — small, focused classes composed together
- Use `pathlib.Path` for all filesystem operations — never `os.path`
- Use context managers (`with` statements) for files, sockets, database connections, and locks
- Import order: stdlib → third-party → local (enforced by ruff `I` rules)
- Use `dataclasses` or `pydantic` for structured data — not plain dicts
- f-strings for string formatting — not `.format()` or `%`

## Project Structure

```text
src/<package>/  Application source
tests/          Unit, integration, and end-to-end tests
scripts/        Utility and migration scripts
docs/           Documentation
pyproject.toml  Project metadata and tool config
```

## Dependencies

```bash
uv add <package>
uv add --dev <package>
```

- Keep dependencies declared in `pyproject.toml`
- Commit the lock file you choose to use

## Change Discipline

- If behavior changes, update the relevant docs, specs, README, API references, or changelog in the same branch.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, migrations, CI, and public or network-facing APIs as high-risk changes. Call out compatibility and rollback risk when they move.

## Before Finishing

Run and confirm all pass with zero warnings:

```bash
ruff format --check .
ruff check .
mypy .
pytest
```

Also confirm whether the change requires updates in `docs/`, `README.md`, or `CHANGELOG.md`.

If any command fails, fix the issue before marking the task complete. Do not suppress warnings with `# noqa` or `# type: ignore` unless the suppression itself is the agreed-upon fix and includes a justifying comment.
