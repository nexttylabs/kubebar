# Kubebar Development Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- Kubebar is a native macOS menu bar app for quickly checking Kubernetes health.
- It is not a replacement for `k9s`; it is the glanceable status tool used before opening deeper debugging tools.
- If a deeper guide exists under `docs/architecture/`, treat that guide as authoritative for that area.
- For any feature work, read [docs/architecture/runtime-invariants.md](docs/architecture/runtime-invariants.md) first—it contains 50+ immutable rules about stale data, warning limits, node conditions, and pod completion handling.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

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

## Coding Rules

- No force unwraps (`!`) or `try!` in production code unless an adjacent comment explains why they are safe.
- No `fatalError` in production paths unless it protects an impossible state and the reason is documented.
- Prefer value types (`struct`, `enum`) unless reference semantics are required.
- Mark UI-bound state and side effects with `@MainActor` when they must stay on the main thread.
- Prefer `async` / `await` over callback pyramids for new asynchronous code.
- Use explicit access control; default to `private` or `fileprivate`.
- Make `switch` statements exhaustive for enums; avoid `default` when the enum is under your control.
- Prefer dependency injection over singletons for services, clients, and stores.
- Keep views thin; move formatting, mapping, and business logic into focused types.

## Build and Test

```bash
./scripts/swift-quality-gate.sh local
```

The same gate runs the macOS Xcode build, Xcode tests, `swift build`, and `swift test` when those project shapes are present.

Use the local visible-app smoke test when you need to confirm the built menu bar app can actually launch:

```bash
./scripts/compile-and-run.sh
```

If the repository has multiple workspaces, projects, or schemes, set `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, and `XCODE_DESTINATION` explicitly before running the quality gate.

## Project Layout

```text
Kubebar/       SwiftUI menu bar app entry and views
KubebarCore/   Models, display mapping, health rules, and services
KubebarTests/  Unit tests for trusted product behavior
docs/          Requirements, plans, and architecture notes
scripts/       Local quality checks
```

## Key Exemplar Files

- [KubebarCore/Services/HealthEvaluator.swift](KubebarCore/Services/HealthEvaluator.swift) — Pure evaluation logic, no side effects
- [KubebarCore/Services/KubectlClusterReader.swift](KubebarCore/Services/KubectlClusterReader.swift) — Concurrent JSON parsing, Sendable types
- [Kubebar/KubebarApp.swift](Kubebar/KubebarApp.swift) — App entry, DEBUG fixtures, thin view setup
- [KubebarCore/Models/MenuDisplayModel.swift](KubebarCore/Models/MenuDisplayModel.swift) — Display-ready data (no logic)

## Change Discipline

- Run the Swift quality gate before finishing.
- Update the relevant `docs/` file when product behavior changes.
- Add or update tests for behavior changes.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, build settings, CI, and public or network-facing APIs as high-risk changes.
