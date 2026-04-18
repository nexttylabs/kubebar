---
paths:
  - "**/*.go"
---

# Go Review Discipline

## Error Handling

- Every error must be checked — no assigning errors to `_`
- Wrap errors with `fmt.Errorf("context: %w", err)` to preserve the error chain
- Use sentinel errors (`var ErrNotFound = errors.New("not found")`) for known conditions that callers switch on
- Use `errors.Is` and `errors.As` for inspection — never compare error strings

## Goroutine Safety

- Every goroutine must have a clear exit path — no fire-and-forget goroutines
- Use `context.Context` for cancellation and deadline propagation
- Use `sync.WaitGroup` or channels to coordinate goroutine lifetimes
- Defer `cancel()` immediately after creating a derived context

## Race Conditions

- All tests must pass with `-race` — treat race detector warnings as hard failures
- Protect shared mutable state with `sync.Mutex` or channels — never rely on "it usually works"
- Prefer channel-based communication over shared memory when design permits

## Testing

- Every bug fix must include a regression test that fails without the fix
- Tests must not depend on execution order — use `t.Parallel()` where possible

## Lint Policy

- Zero `go vet` warnings — treat every warning as a bug
- No `//nolint` directives without the specific linter name and justification comment
