# Coding Conventions

**Analysis Date:** 2026-04-19

## Naming Patterns

**Files:**
- Use one primary type per Swift file and name the file after that type, as in `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, and `Kubebar/Views/MenuBarRootView.swift`.
- Put SwiftUI views under `Kubebar/Views/` with `View` suffixes, such as `Kubebar/Views/WatchlistPickerView.swift`, `Kubebar/Views/StaleBannerView.swift`, and `Kubebar/Views/StatusSummaryView.swift`.
- Put core behavior under `KubebarCore/Models/` and `KubebarCore/Services/`, such as `KubebarCore/Models/MenuDisplayModel.swift` and `KubebarCore/Services/KubectlClusterReader.swift`.
- Put tests under `KubebarTests/Models/` and `KubebarTests/Services/`, mirroring the production area they cover, such as `KubebarTests/Models/MenuDisplayModelTests.swift` for `KubebarCore/Models/MenuDisplayModel.swift`.

**Functions:**
- Use lowerCamelCase verbs or verb phrases for functions and methods, as in `refreshNow()` in `Kubebar/MenuBarViewModel.swift`, `readSnapshot(contextName:watchTargets:now:)` in `KubebarCore/Services/KubectlClusterReader.swift`, and `listContexts()` in `KubebarCore/Services/ContextCatalog.swift`.
- Use domain-specific helper names for private transformations, as in `evaluateState(_:)`, `sortByAttention(_:)`, `healthSentence(for:visibleItems:)`, and `relativeAge(from:to:)` in `KubebarCore/Services/HealthEvaluator.swift`.
- Use behavior-oriented test function names that match `@Test` descriptions, as in `failedRefreshKeepsPreviousDataButMarksItStale()` in `KubebarTests/Models/MenuDisplayModelTests.swift`.

**Variables:**
- Use lowerCamelCase nouns for local values and stored properties, as in `visibleWatchItemLimit` in `KubebarCore/Services/HealthEvaluator.swift`, `warningEventCount` in `KubebarCore/Models/ClusterSnapshot.swift`, and `selectedTargets` in `KubebarCore/Models/WatchlistSelectionState.swift`.
- Use `let` by default for immutable state and `var` only for mutable state, as seen across value models in `KubebarCore/Models/ClusterSnapshot.swift` and `KubebarCore/Models/MenuDisplayModel.swift`.
- Use explicit user-facing names for presentation values, such as `healthSentence`, `staleBanner`, `accessibilityLabel`, and `symbolName` in `KubebarCore/Models/MenuDisplayModel.swift` and `KubebarCore/Models/MenuBarStatusPresentation.swift`.

**Types:**
- Use UpperCamelCase for structs, enums, protocols, classes, suites, and fakes, as in `MenuDisplayModel`, `ClusterHealthState`, `CommandRunning`, `ProcessCommandRunner`, and `FakeCommandRunner` in `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Models/ClusterHealthState.swift`, `KubebarCore/Services/CommandRunner.swift`, and `KubebarTests/Services/ContextCatalogTests.swift`.
- Prefer `struct` and `enum` for app state and domain rules, as in `AppConfig`, `WatchTarget`, `HealthEvaluator`, and `RefreshCoordinator` in `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Models/WatchTarget.swift`, `KubebarCore/Services/HealthEvaluator.swift`, and `KubebarCore/Services/RefreshCoordinator.swift`.
- Use `final class` only where reference semantics or framework integration require it, such as `MenuBarViewModel` in `Kubebar/MenuBarViewModel.swift`, `ProcessCommandRunner` in `KubebarCore/Services/CommandRunner.swift`, and lock-backed test doubles in `KubebarTests/Services/KubectlClusterReaderTests.swift`.

## Code Style

**Formatting:**
- Tool used: Not detected for a dedicated formatter. No `.swiftformat`, `.swiftlint.yml`, or `.editorconfig` file is present at the repository root; style is enforced through Swift compiler formatting conventions, local examples in `KubebarCore/` and `Kubebar/`, and the quality gate in `scripts/swift-quality-gate.sh`.
- Indent Swift with 4 spaces, as consistently used in `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, and `Kubebar/Views/SetupView.swift`.
- Break long initializers and calls over multiple lines with one argument per line, as in `MenuDisplayModel(...)` construction in `KubebarCore/Services/HealthEvaluator.swift` and `ClusterSnapshot(...)` setup in `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Keep SwiftUI view bodies declarative and extract subviews into private computed `some View` properties, as in `menuContent` and `actions` in `Kubebar/Views/MenuBarRootView.swift`, plus `header`, `contextPicker`, and `footer` in `Kubebar/Views/SetupView.swift`.

**Linting:**
- Tool used: Not detected for SwiftLint enforcement. `scripts/dev-setup.sh` treats `swiftlint` as optional, and `scripts/swift-quality-gate.sh` does not invoke it.
- Key rules from `AGENTS.md`: no force unwraps or `try!` in production without an adjacent safety comment, no production `fatalError` except for documented impossible states, explicit access control, thin views, dependency injection, and exhaustive enum switches.
- Existing production Swift under `Kubebar/` and `KubebarCore/` contains no `try!`, `as!`, `fatalError`, or panic-style constructs according to the scanned source paths.

## Import Organization

**Order:**
1. System and Apple frameworks first, as in `Foundation`, `AppKit`, and `SwiftUI` imports in `KubebarCore/Services/CommandRunner.swift`, `Kubebar/KubebarApp.swift`, and `Kubebar/MenuBarViewModel.swift`.
2. Project modules after system imports, as in `import KubebarCore` after `import SwiftUI` in `Kubebar/Views/MenuBarRootView.swift` and after `import Foundation` / `import SwiftUI` in `Kubebar/MenuBarViewModel.swift`.
3. Tests import `Foundation` only when needed, then `Testing`, then `@testable import KubebarCore`, as in `KubebarTests/Services/KubectlClusterReaderTests.swift` and `KubebarTests/Models/MenuDisplayModelTests.swift`.

**Path Aliases:**
- Not detected. Swift module boundaries come from `Package.swift` and `project.yml`: `Kubebar` depends on `KubebarCore`, and `KubebarTests` depends on `KubebarCore`.
- Do not introduce custom path aliases; add code to the existing Swift targets in `Package.swift` and `project.yml`.

## Error Handling

**Patterns:**
- Propagate service failures with typed Swift errors from boundary types, as in `CommandRunnerError` in `KubebarCore/Services/CommandRunner.swift`, `KubectlCommandError` in `KubebarCore/Services/ContextCatalog.swift`, and `AppConfigStoreError` in `KubebarCore/Services/AppConfigStore.swift`.
- Convert lower-level errors into product-specific errors before crossing core service boundaries, as `KubectlClusterReader` maps timeouts, launch failures, non-zero exits, and invalid JSON to `KubectlCommandError.failed(...)` in `KubebarCore/Services/KubectlClusterReader.swift`.
- Keep stale data explicit instead of silently discarding it. `RefreshCoordinator.refresh(...)` returns the previous snapshot and a stale display after failures in `KubebarCore/Services/RefreshCoordinator.swift`.
- Use `guard` for required preconditions and early exits, as in missing setup handling in `KubebarCore/Services/RefreshCoordinator.swift`, missing config files in `KubebarCore/Services/AppConfigStore.swift`, and invalid setup completion in `Kubebar/MenuBarViewModel.swift`.
- Avoid exposing raw implementation errors to the UI. `MenuBarViewModel.completeSetup()` turns save failures into `setupState.configurationMessage` in `Kubebar/MenuBarViewModel.swift`; `loadContexts()` treats context listing failure as an empty context list in the same file.

## Logging

**Framework:** None detected in production Swift.

**Patterns:**
- No `print`, `Logger`, or `os_log` usage is present in `Kubebar/` or `KubebarCore/`.
- Surface user-visible failures through display models and setup state rather than logs, as in `StaleBannerDisplay` from `KubebarCore/Models/MenuDisplayModel.swift`, `RefreshFailure` from `KubebarCore/Services/HealthEvaluator.swift`, and `configurationMessage` in `KubebarCore/Models/SetupFlowState.swift`.
- If logging is added, keep secrets and raw command output out of logs because `AGENTS.md` classifies secrets, config loading, persistence, and public or network-facing behavior as high-risk.

## Comments

**When to Comment:**
- Production Swift currently uses almost no inline comments in `Kubebar/` and `KubebarCore/`; prefer clear type, method, and property names over explanatory comments.
- Add comments only for non-obvious safety decisions, especially if using a rule exception from `AGENTS.md` such as a force unwrap, `try!`, `fatalError`, or `@unchecked Sendable`.
- Keep architecture-level explanations in docs rather than source comments. Use `docs/architecture/system-overview.md` for subsystem flow and `docs/architecture/runtime-invariants.md` for runtime guarantees.

**JSDoc/TSDoc:**
- Not applicable. This is a Swift codebase.
- Swift DocC comments are not currently used in `Kubebar/`, `KubebarCore/`, or `KubebarTests/`.

## Function Design

**Size:** Keep functions small and single-purpose.
- Use short pure helpers for domain transforms, as in `evaluateState(_:)`, `sortByAttention(_:)`, `makeDisplayItem(_:)`, and `shortened(_:)` in `KubebarCore/Services/HealthEvaluator.swift`.
- Keep longer boundary methods only when coordinating I/O and concurrency, as in `ProcessCommandRunner.run(_:)` in `KubebarCore/Services/CommandRunner.swift` and `readRawSnapshot(contextName:)` in `KubebarCore/Services/KubectlClusterReader.swift`.
- Keep SwiftUI `body` values thin and delegate sections to private computed properties, as in `Kubebar/Views/SetupView.swift` and `Kubebar/Views/WatchlistPickerView.swift`.

**Parameters:** Prefer explicit labels that describe domain meaning.
- Use labels such as `contextName`, `watchTargets`, `previousSnapshot`, and `now` in `KubebarCore/Services/KubectlClusterReader.swift` and `KubebarCore/Services/RefreshCoordinator.swift`.
- Pass `Date` as an explicit `now` parameter in deterministic core behavior, as in `HealthEvaluator.evaluate(...)` in `KubebarCore/Services/HealthEvaluator.swift` and tests in `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Inject boundaries through initializers with production defaults, as in `KubectlClusterReader(runner:)`, `ContextCatalog(runner:)`, `RefreshCoordinator(reader:evaluator:)`, and `MenuBarViewModel(configStore:refreshCoordinator:contextCatalog:now:)` in `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, and `Kubebar/MenuBarViewModel.swift`.

**Return Values:** Return app-owned value types instead of raw external data.
- UI-facing code should receive `MenuDisplayModel`, `MenuCounters`, `WatchItemDisplay`, and `StaleBannerDisplay` from `KubebarCore/Models/MenuDisplayModel.swift`.
- External command readers should return `ClusterSnapshot` and domain summaries, not raw `kubectl` JSON, as in `KubebarCore/Services/KubectlClusterReader.swift` and `KubebarCore/Models/ClusterSnapshot.swift`.
- Mutating setup and selection helpers update value state directly, as in `selectContext(_:)` in `KubebarCore/Models/SetupFlowState.swift` and `toggle(_:)` in `KubebarCore/Models/WatchlistSelectionState.swift`.

## Module Design

**Exports:** Use explicit public APIs in `KubebarCore` and internal app-only UI types in `Kubebar`.
- Public core models and services define `public` types, properties, and initializers in `KubebarCore/Models/*.swift` and `KubebarCore/Services/*.swift`.
- Keep helper details private or file-private within the same file, as in `KubectlRead`, `RawKubectlSnapshot`, `LockedKubectlResults`, `NodeRecord`, and `PodRecord` in `KubebarCore/Services/KubectlClusterReader.swift`.
- Keep SwiftUI views internal by default in `Kubebar/Views/*.swift`; app composition happens through `Kubebar/KubebarApp.swift` and `Kubebar/MenuBarViewModel.swift`.
- Mark concurrency-facing values `Sendable` when they cross detached tasks or service boundaries, as in `ClusterSnapshot`, `RefreshResult`, `CommandRequest`, `CommandResult`, and `KubectlClusterReader` in `KubebarCore/Models/ClusterSnapshot.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/CommandRunner.swift`, and `KubebarCore/Services/KubectlClusterReader.swift`.
- Use `@MainActor` for UI-bound state and side effects, as in `MenuBarViewModel` in `Kubebar/MenuBarViewModel.swift`.

**Barrel Files:** Not used.
- No aggregate export files are present in `KubebarCore/Models/` or `KubebarCore/Services/`.
- Add new types directly to the appropriate target path instead of introducing a barrel file.

---

*Convention analysis: 2026-04-19*
