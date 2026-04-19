# Kubebar Development Guide

## Purpose

Kubebar is a native macOS menu bar app for quickly checking Kubernetes health.
It is not a replacement for `k9s`; it is the glanceable status tool used before
opening deeper debugging tools.

## Product Rules

- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep the dropdown watchlist-first.
- Keep first-screen watchlist rows capped at `3-5` items.
- Never let stale data look healthy or current.
- Keep deep troubleshooting out of version 1.

## Architecture Rules

- UI renders `MenuDisplayModel`; it must not decide cluster health directly.
- `HealthEvaluator` is the single source of truth for severity.
- External reads must go through an injectable boundary.
- App-owned context is the source of truth, not the terminal's current context.
- Prefer small value types and explicit dependency seams.

## Build and Test

```bash
./scripts/swift-quality-gate.sh local
```

The same gate runs `swift build` and `swift test`.

## Project Layout

```text
Kubebar/       SwiftUI menu bar app entry and views
KubebarCore/   Models, display mapping, health rules, and services
KubebarTests/  Unit tests for trusted product behavior
docs/          Requirements, plans, and architecture notes
scripts/       Local quality checks
```

## Before Finishing

- Run the Swift quality gate.
- Update the relevant `docs/` file when product behavior changes.
- Add or update tests for behavior changes.
