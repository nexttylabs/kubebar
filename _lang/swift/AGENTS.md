# {{PROJECT_NAME}} Swift Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- If a deeper guide exists in a subdirectory or under `docs/architecture/`, treat that guide as authoritative for that area.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

## Architecture Mental Model

- Keep app entry points and scene wiring thin; move feature logic into the target or module that owns it.
- Keep domain logic separate from UI, persistence, and external service adapters.
- Extend existing feature modules, protocols, and dependency seams before adding one-off flows.

## Where to Work

- App and feature code: `App/`, `Sources/`, or target-owned source folders
- Shared modules: `Sources/` or framework targets
- Unit tests: `Tests/`
- UI tests: `UITests/`
- Tooling and automation: `scripts/`
- Architecture notes and longer specs: `docs/`

## Build & Quality Gate

```bash
./scripts/swift-quality-gate.sh local
```

For Swift Package-only repositories, the same script runs `swift build` and `swift test`.
For Xcode-based iOS repositories, it runs `xcodebuild build` and `xcodebuild test`.

## Coding Rules

- No force unwraps (`!`) or `try!` in production code unless an adjacent comment explains why they are safe
- No `fatalError` in production paths unless it protects an impossible state and the reason is documented
- Prefer value types (`struct`, `enum`) unless reference semantics are required
- Mark UI-bound state and side effects with `@MainActor` when they must stay on the main thread
- Prefer `async` / `await` over callback pyramids for new asynchronous code
- Use explicit access control; default to `private` or `fileprivate`
- Make `switch` statements exhaustive for enums; avoid `default` when the enum is under your control
- Prefer dependency injection over singletons for services, clients, and stores
- Keep views and view controllers thin; move formatting, mapping, and business logic into focused types

## Project Structure

```text
App/            App target sources when present
Sources/        Shared modules or package sources
Tests/          Unit and integration tests
UITests/        UI or end-to-end tests
Resources/      Bundled assets and fixtures
scripts/        Tooling and automation
```

## Dependencies

```bash
swift package resolve
```

- Commit `Package.resolved` when your project uses Swift Package Manager
- Treat `SwiftLint` as optional unless the project explicitly adopts it

## Change Discipline

- If behavior changes, update the relevant docs, specs, README, or changelog in the same branch.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, build settings, CI, and public or network-facing APIs as high-risk changes. Call out compatibility and rollback risk when they move.

## Before Finishing

Run and confirm all pass cleanly:

```bash
./scripts/swift-quality-gate.sh local
```

Also confirm whether the change requires updates in `docs/`, `README.md`, or `CHANGELOG.md`.

If your repository has multiple workspaces, projects, or schemes, set `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, and `XCODE_DESTINATION` explicitly before running the quality gate.
