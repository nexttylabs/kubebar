---
paths:
  - "src/**/*.py"
  - "tests/**/*.py"
---

# Python Review Discipline

## Type Safety

- All public functions and methods must have full type annotations (params + return)
- Use `TypeVar` and `Generic` properly for reusable typed abstractions
- No `Any` without an adjacent comment explaining why it is unavoidable
- Use `TypedDict` for dictionary shapes that cross module boundaries
- `# type: ignore` requires an adjacent comment and should be rare

## Error Handling

- No bare `except:` — always catch specific exception types
- Always log or re-raise — never silently swallow exceptions
- Use custom exception hierarchies for domain errors (inherit from a project base exception)
- Include context in error messages — what failed, with which inputs
- Use `raise ... from err` to preserve exception chains

## Resource Management

- Use context managers (`with` statements) for files, connections, locks, and transactions
- Close files and connections explicitly — never rely on garbage collection
- Use `contextlib.contextmanager` or `contextlib.asynccontextmanager` for custom resource wrappers

## Testing

- Every bug fix must include a regression test that fails without the fix
- Tests must not depend on execution order or shared mutable state

## Lint Policy

- Zero ruff warnings — treat warnings as errors
- No `# noqa` without an adjacent comment and a justifying reason
