---
description: Run the Go quality gate (fmt, vet, lint, test) before shipping.
allowed-tools:
  - Bash(gofmt:*)
  - Bash(go:*)
  - Bash(golangci-lint:*)
---

# Ship

Run the Go quality gate. Stop on the first failure and fix it before continuing.

1. **Format**: `gofmt -l .` (must produce no output)
2. **Vet**: `go vet ./...`
3. **Lint**: `golangci-lint run`
4. **Test**: `go test -race ./...`

All four steps must pass with zero warnings before committing or opening a PR.
