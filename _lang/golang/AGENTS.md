# {{PROJECT_NAME}} Go Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- If a deeper guide exists in a subdirectory or under `docs/architecture/`, treat that guide as authoritative for that area.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

## Architecture Mental Model

- Keep entry points and startup wiring thin; move module-owned logic into the package that owns it.
- Keep domain logic separate from delivery layers, persistence code, and external integrations.
- Extend existing interfaces, factories, and registries before adding one-off integration paths.

## Where to Work

- Binary entry points: `cmd/`
- Private packages: `internal/`
- Public packages: `pkg/`
- Integration and end-to-end tests: `tests/`
- Tooling and automation: `scripts/`
- Architecture notes and longer specs: `docs/`

## Build & Quality Gate

```bash
gofmt -l .
go vet ./...
golangci-lint run
go test -race ./...
```

Treat any output from `gofmt -l .` as a failure that must be fixed before review.

## Coding Rules

- Follow Effective Go and Go Code Review Comments
- Handle every error — never assign an error to `_`
- Wrap errors with context: `fmt.Errorf("operation failed: %w", err)`
- Use `errors.New` for sentinel errors, `fmt.Errorf` with `%w` for wrapping
- `context.Context` is always the first parameter when present
- Keep functions under ~60 lines — extract helpers when complexity grows
- No naked returns — always specify return values explicitly
- Use `t.Helper()` in every test helper function
- Use `t.Parallel()` for tests that don't share mutable state
- Prefer table-driven tests with `t.Run` subtests
- Define interfaces at the consumption site, not the implementation site
- No `init()` functions unless absolutely necessary — prefer explicit initialization

## Project Structure

```text
cmd/       Binary entry points
internal/  Private packages
pkg/       Public library packages
api/       Protocol definitions
tests/     Integration or end-to-end suites
testdata/  Fixtures ignored by the Go tool
```

## Dependencies

```bash
go get <package>
go mod tidy
```

- Commit `go.sum`
- Run `go mod tidy` after dependency changes

## Change Discipline

- If behavior changes, update the relevant docs, specs, README, API references, or changelog in the same branch.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, migrations, CI, and public or network-facing APIs as high-risk changes. Call out compatibility and rollback risk when they move.

## Before Finishing

Run and confirm all pass with zero warnings:

```bash
gofmt -l .
go vet ./...
golangci-lint run
go test -race ./...
```

Also confirm whether the change requires updates in `docs/`, `README.md`, or `CHANGELOG.md`.

If any command fails, fix the issue before marking the task complete. Do not suppress warnings with `//nolint` directives unless the suppression itself is the agreed-upon fix, and always include the specific linter name and a justification comment.
