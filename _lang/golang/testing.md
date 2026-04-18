---
paths:
  - "**/*.go"
  - "**/*_test.go"
---

# Go Testing Rules

## Test Tiers

| Tier        | Command                                    | Scope                                  |
|-------------|--------------------------------------------|----------------------------------------|
| Unit        | `go test ./...`                            | Pure functions, isolated packages      |
| Integration | `go test -tags integration ./...`          | Database, external services, APIs      |
| Race        | `go test -race ./...`                      | Concurrency correctness                |

## Patterns

- **Table-driven tests** — define `[]struct{ name string; input; want }` slices and loop with `t.Run(tc.name, ...)`
- **`t.Run` subtests** — use for every test case to get per-case names in output and parallel execution
- **`t.Helper()`** — call in every test helper function so failure messages point to the caller
- **`t.Parallel()`** — mark tests that don't share mutable state for parallel execution
- **`testdata/`** — store fixtures here; the `go` tool ignores this directory during builds
- **`t.TempDir()`** — use for temporary files; automatically cleaned up when the test completes

## Structure

- Test files live alongside the code they test: `foo.go` → `foo_test.go`
- Use the `_test` package suffix for black-box testing: `package foo_test`
- Use the same package name for white-box tests that need access to unexported symbols

## Assertions

- Use the standard `testing` package — no third-party assertion libraries required
- Compare structs with `reflect.DeepEqual` or `cmp.Diff` from `github.com/google/go-cmp`
- Fatal (`t.Fatal`/`t.Fatalf`) for setup failures; Error (`t.Error`/`t.Errorf`) for assertion failures

## Coverage

- Do not chase 100% coverage — cover business logic, edge cases, and error paths
- Generate coverage: `go test -coverprofile=coverage.out ./...`
- View coverage: `go tool cover -html=coverage.out`
