---
paths:
  - "**/*.swift"
---

# Swift Review Discipline

## Safety

- No force unwraps, `try!`, or `as!` in production code without an adjacent justification comment
- No `fatalError` on recoverable paths
- Prefer typed errors or explicit result mapping over stringly-typed failure handling

## Architecture

- Keep UI layers thin; feature logic should live in focused models, stores, reducers, or services
- Prefer protocol-backed seams at integration boundaries, not everywhere by default
- Avoid singleton sprawl; inject collaborators explicitly
- Keep side effects isolated behind small interfaces

## Concurrency

- Prefer `async` / `await` for new asynchronous flows
- Use `@MainActor` for UI-bound state mutations
- No detached tasks without explicit lifecycle ownership and cancellation handling

## Testing

- Every bug fix must include a regression test that fails without the fix
- Prefer unit tests first, UI tests only when the behavior cannot be proven lower in the stack
- Snapshot tests are optional and should focus on stable, user-visible states

## Lint Policy

- Keep build and test output free of warnings that indicate real defects
- If the project adopts `SwiftLint`, treat warnings as failures unless the team documents an exception
