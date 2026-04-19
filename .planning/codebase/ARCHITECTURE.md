# Architecture

**Analysis Date:** 2026-04-19

## Pattern Overview

**Overall:** Thin SwiftUI menu bar shell over a testable core domain and service layer.

**Key Characteristics:**
- Keep product rules in `KubebarCore/`, not in SwiftUI views under `Kubebar/Views/`.
- Render the menu from `MenuDisplayModel`; views in `Kubebar/Views/` must not infer cluster health from raw data.
- Route external process reads through injectable protocols in `KubebarCore/Services/CommandRunner.swift` and `KubebarCore/Services/KubectlClusterReader.swift`.
- Treat app-owned configuration as authoritative through `KubebarCore/Services/AppConfigStore.swift`; do not use the terminal's current Kubernetes context as implicit state.
- Preserve stale-state guarantees through `KubebarCore/Services/RefreshCoordinator.swift` and `KubebarCore/Services/HealthEvaluator.swift`.

## Layers

**macOS App Shell:**
- Purpose: Start the menu bar app, hold the root view model, and present the current status icon.
- Location: `Kubebar/`
- Contains: `Kubebar/KubebarApp.swift`, `Kubebar/MenuBarViewModel.swift`, and SwiftUI views under `Kubebar/Views/`.
- Depends on: `SwiftUI`, `AppKit`, and public models/services from `KubebarCore/`.
- Used by: The macOS application target defined in `project.yml` and `Package.swift`.
- Use this layer for scene wiring, user actions, bindings, and UI-only state. Do not put health scoring, kubectl parsing, config persistence, or display-model construction here.

**View Model Boundary:**
- Purpose: Bridge UI events to core services while keeping UI-bound state on the main actor.
- Location: `Kubebar/MenuBarViewModel.swift`
- Contains: `@MainActor final class MenuBarViewModel`, published `display`, `setupState`, and `isShowingSetup` state.
- Depends on: `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/ContextCatalog.swift`, and `KubebarCore/Services/HealthEvaluator.swift`.
- Used by: `Kubebar/KubebarApp.swift` and `Kubebar/Views/MenuBarRootView.swift`.
- Use this boundary to load/save setup, trigger refresh, and call background work with `Task.detached`. Keep long-running or blocking reads out of the main actor.

**SwiftUI Menu Views:**
- Purpose: Render setup and menu content from already-shaped model data.
- Location: `Kubebar/Views/`
- Contains: `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `Kubebar/Views/StatusSummaryView.swift`, `Kubebar/Views/CompactCountersView.swift`, `Kubebar/Views/WatchlistSectionView.swift`, `Kubebar/Views/StaleBannerView.swift`, `Kubebar/Views/WarningEventsView.swift`, `Kubebar/Views/NodeDetailsView.swift`, and `Kubebar/Views/TrackedItemDetailView.swift`.
- Depends on: `SwiftUI` and display/setup models from `KubebarCore/Models/`.
- Used by: `Kubebar/Views/MenuBarRootView.swift` as the menu composition root.
- Use this layer for layout and simple presentation. Pass closures for actions and bindings for setup state; do not read files, call `kubectl`, or calculate severity.

**Core Models:**
- Purpose: Define app-owned data shapes shared by services, view model, and tests.
- Location: `KubebarCore/Models/`
- Contains: `ClusterSnapshot`, `NodeSummary`, `PodSummary`, `WatchTarget`, `TrackedItemStatus`, `ClusterHealthState`, `MenuDisplayModel`, `MenuCounters`, `WatchItemDisplay`, `StaleBannerDisplay`, `MenuBarStatusPresentation`, `SetupFlowState`, and `WatchlistSelectionState`.
- Depends on: `Foundation` only.
- Used by: `KubebarCore/Services/`, `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/`, and `KubebarTests/`.
- Use value types here. Add model-derived labels and summaries only when they are stable product concepts, not one-off view formatting.

**Core Services:**
- Purpose: Own persistence, refresh orchestration, external reads, JSON conversion, and health evaluation.
- Location: `KubebarCore/Services/`
- Contains: `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, and `KubebarCore/Services/HealthEvaluator.swift`.
- Depends on: `Foundation` and core models from `KubebarCore/Models/`.
- Used by: `Kubebar/MenuBarViewModel.swift` and service/model tests under `KubebarTests/`.
- Use this layer for behavior. Keep service dependencies injectable through protocols or initializer parameters so tests can use fakes instead of shelling out.

**External Command Boundary:**
- Purpose: Isolate subprocess execution and make `kubectl` reads testable.
- Location: `KubebarCore/Services/CommandRunner.swift`
- Contains: `CommandRequest`, `CommandResult`, `CommandRunning`, `CommandRunnerError`, and `ProcessCommandRunner`.
- Depends on: `Foundation.Process`, `Pipe`, `DispatchSemaphore`, `DispatchGroup`, and a private locked data buffer.
- Used by: `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, and fake runners in `KubebarTests/Services/`.
- Use `CommandRunning` for all new shell boundaries. Do not call `Process` directly from unrelated services or UI files.

**Kubernetes Reader:**
- Purpose: Convert `kubectl` JSON output into app-owned `ClusterSnapshot` data.
- Location: `KubebarCore/Services/KubectlClusterReader.swift`
- Contains: `ClusterReading`, `KubectlClusterReader`, private kubectl read cases, raw snapshot storage, and private `Decodable` records for nodes, pods, and events.
- Depends on: `CommandRunning`, `WatchTarget`, `ClusterSnapshot`, and `JSONDecoder`.
- Used by: `KubebarCore/Services/RefreshCoordinator.swift`.
- Use this service for new Kubernetes reads. Always pass the saved context as `--context`; never rely on the process environment's active kube context.

**Health and Display Mapping:**
- Purpose: Convert snapshots and failures into the only UI render shape.
- Location: `KubebarCore/Services/HealthEvaluator.swift`
- Contains: `RefreshFailure` and `HealthEvaluator`.
- Depends on: `ClusterSnapshot`, `ClusterHealthState`, and `MenuDisplayModel`.
- Used by: `KubebarCore/Services/RefreshCoordinator.swift`, `Kubebar/MenuBarViewModel.swift`, and `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Use this service for severity, watchlist ordering, visible watchlist limits, stale banner values, and health sentences. Do not duplicate these decisions in views.

**Configuration Persistence:**
- Purpose: Save and load the selected context, watchlist, and refresh interval as local app configuration.
- Location: `KubebarCore/Services/AppConfigStore.swift`
- Contains: `AppConfig`, `AppConfigStore`, and `AppConfigStoreError`.
- Depends on: `Foundation.FileManager`, `JSONEncoder`, and `JSONDecoder`.
- Used by: `Kubebar/MenuBarViewModel.swift` and `KubebarTests/Services/AppConfigStoreTests.swift`.
- Use this service for app-owned saved state. Keep corrupt config recoverable by throwing `AppConfigStoreError.corruptConfig`.

**Tests:**
- Purpose: Lock core product behavior and injectable service boundaries.
- Location: `KubebarTests/`
- Contains: model tests under `KubebarTests/Models/` and service tests under `KubebarTests/Services/`.
- Depends on: Swift Testing through `import Testing` and `@testable import KubebarCore`.
- Used by: `Package.swift`, `project.yml`, and `scripts/swift-quality-gate.sh`.
- Add tests close to the model or service being changed. UI files currently have no dedicated test target.

## Data Flow

**App Launch and Initial State:**

1. `Kubebar/KubebarApp.swift` creates `MenuBarViewModel` and configures the app as an accessory menu bar utility.
2. `Kubebar/MenuBarViewModel.swift` loads `AppConfig` from `KubebarCore/Services/AppConfigStore.swift`.
3. If config is missing or incomplete, `MenuBarViewModel` builds a stale "Not configured" display through `KubebarCore/Services/HealthEvaluator.swift` and shows setup.
4. If config is complete, `MenuBarViewModel.refreshNow()` starts a refresh and publishes the resulting `MenuDisplayModel`.
5. `Kubebar/Views/MenuBarRootView.swift` renders either `SetupView` or the menu content from `display`.

**Manual or Automatic Refresh:**

1. `Kubebar/Views/MenuBarRootView.swift` invokes `onRefresh`.
2. `Kubebar/MenuBarViewModel.swift` calls `KubebarCore/Services/RefreshCoordinator.swift` on a detached task with the current `AppConfig` and previous `ClusterSnapshot`.
3. `RefreshCoordinator.refresh(config:previousSnapshot:now:)` rejects incomplete setup before any cluster read.
4. `RefreshCoordinator` calls `ClusterReading.readSnapshot(contextName:watchTargets:now:)`.
5. `KubebarCore/Services/KubectlClusterReader.swift` runs independent `kubectl get nodes`, `kubectl get pods`, and `kubectl get events` reads through `CommandRunning`.
6. `KubectlClusterReader` decodes JSON into `NodeSummary`, `PodSummary`, warning event count, and tracked item status.
7. `RefreshCoordinator` calls `HealthEvaluator.evaluate(...)`.
8. `MenuBarViewModel` publishes the new `snapshot` and `display` on the main actor.

**Failed Refresh and Stale Data:**

1. `KubebarCore/Services/CommandRunner.swift` or `KubebarCore/Services/KubectlClusterReader.swift` throws a command, timeout, launch, nonzero-exit, or parse error.
2. `KubebarCore/Services/RefreshCoordinator.swift` keeps the previous snapshot instead of clearing it.
3. `KubebarCore/Services/HealthEvaluator.swift` returns a `MenuDisplayModel` with `.stale` state and a `StaleBannerDisplay`.
4. `Kubebar/Views/StaleBannerView.swift` shows the last update age and failure reason.
5. The menu bar icon uses `KubebarCore/Models/MenuBarStatusPresentation.swift` so stale data cannot look healthy.

**Setup and Watchlist Editing:**

1. `Kubebar/Views/MenuBarRootView.swift` invokes `onEditWatchlist`.
2. `Kubebar/MenuBarViewModel.swift` sets `isShowingSetup` and calls `ContextCatalog.listContexts()`.
3. `KubebarCore/Services/ContextCatalog.swift` runs `kubectl config get-contexts -o name` through `CommandRunning`.
4. `Kubebar/Views/SetupView.swift` binds context selection and watchlist selection to `SetupFlowState`.
5. `Kubebar/Views/WatchlistPickerView.swift` mutates `WatchlistSelectionState` through bindings.
6. `MenuBarViewModel.completeSetup()` writes `AppConfig` through `AppConfigStore.save(_:)`, hides setup, and refreshes.

**State Management:**
- UI-bound state lives in `@MainActor` `Kubebar/MenuBarViewModel.swift`.
- Persisted app state lives in `AppConfig` and `config.json` written by `KubebarCore/Services/AppConfigStore.swift`.
- Last successful cluster data lives in `MenuBarViewModel.snapshot` and may be reused only through stale display handling.
- Domain state uses immutable `let` properties in value types under `KubebarCore/Models/`.
- Setup state uses mutable value types: `SetupFlowState` and `WatchlistSelectionState`.

## Key Abstractions

**MenuDisplayModel:**
- Purpose: Single render contract for the menu.
- Examples: `KubebarCore/Models/MenuDisplayModel.swift`, `Kubebar/Views/MenuBarRootView.swift`, `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Pattern: Core-built view model. Views consume this shape directly and should not reconstruct counters, stale state, health sentences, or severity.

**ClusterHealthState:**
- Purpose: Categorical app health state: `OK`, `Watch`, `Bad`, or `Stale`.
- Examples: `KubebarCore/Models/ClusterHealthState.swift`, `KubebarCore/Models/MenuBarStatusPresentation.swift`, `KubebarCore/Services/HealthEvaluator.swift`.
- Pattern: Exhaustive enum with display label and menu bar presentation mapping.

**HealthEvaluator:**
- Purpose: Single source of truth for severity, first-screen watchlist ordering, visible watchlist cap, stale banner construction, and health sentence.
- Examples: `KubebarCore/Services/HealthEvaluator.swift`, `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Pattern: Pure value service. Keep inputs explicit and deterministic by passing `Date`.

**RefreshCoordinator:**
- Purpose: Orchestrate config validation, cluster reads, previous snapshot retention, and display evaluation.
- Examples: `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarTests/Services/RefreshCoordinatorTests.swift`.
- Pattern: Small coordinating service with injected `ClusterReading` and `HealthEvaluator`.

**ClusterReading:**
- Purpose: Injectable boundary for reading Kubernetes state.
- Examples: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarTests/Services/RefreshCoordinatorTests.swift`.
- Pattern: Protocol-backed dependency. Use fake readers in tests and keep `kubectl` details inside `KubectlClusterReader`.

**CommandRunning:**
- Purpose: Injectable subprocess boundary for shell commands.
- Examples: `KubebarCore/Services/CommandRunner.swift`, `KubebarTests/Services/KubectlClusterReaderTests.swift`, `KubebarTests/Services/ContextCatalogTests.swift`.
- Pattern: Protocol-backed adapter around `Process`. Use fake runners to test command consumers.

**AppConfig and AppConfigStore:**
- Purpose: App-owned persisted context, watch targets, and refresh interval.
- Examples: `KubebarCore/Services/AppConfigStore.swift`, `Kubebar/MenuBarViewModel.swift`, `KubebarTests/Services/AppConfigStoreTests.swift`.
- Pattern: Codable config plus store. Keep config persistence separate from UI state.

**WatchTarget and TrackedItemStatus:**
- Purpose: Represent watched namespaces and workloads, then summarize their current health.
- Examples: `KubebarCore/Models/WatchTarget.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`.
- Pattern: Value enum for durable selection, value struct for runtime status.

**SetupFlowState and WatchlistSelectionState:**
- Purpose: Model first-run setup and watchlist editing state.
- Examples: `KubebarCore/Models/SetupFlowState.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`.
- Pattern: Bindable value state with derived labels and validation flags.

## Entry Points

**macOS Application:**
- Location: `Kubebar/KubebarApp.swift`
- Triggers: App launch.
- Responsibilities: Set accessory activation policy, create `MenuBarExtra`, instantiate `MenuBarViewModel`, pass actions into `MenuBarRootView`, and map `display.state` to a menu bar status icon through `MenuBarStatusPresentation`.

**Menu Composition Root:**
- Location: `Kubebar/Views/MenuBarRootView.swift`
- Triggers: SwiftUI rendering from the menu bar scene.
- Responsibilities: Choose setup vs menu content, render status, stale banner, counters, watchlist, warning events, node details, and actions.

**View Model:**
- Location: `Kubebar/MenuBarViewModel.swift`
- Triggers: App initialization, retry button, edit watchlist button, finish setup button.
- Responsibilities: Load config, maintain current display and setup state, start refresh work, load contexts, save setup, and publish UI state on the main actor.

**Refresh Coordinator:**
- Location: `KubebarCore/Services/RefreshCoordinator.swift`
- Triggers: `MenuBarViewModel.refreshNow()`.
- Responsibilities: Validate config, invoke cluster reader, preserve previous snapshot on failure, and produce `RefreshResult`.

**Kubernetes Snapshot Reader:**
- Location: `KubebarCore/Services/KubectlClusterReader.swift`
- Triggers: `RefreshCoordinator.refresh(config:previousSnapshot:now:)`.
- Responsibilities: Run `kubectl` with the saved context, decode node/pod/event JSON, compute tracked item status, and return `ClusterSnapshot`.

**Context Catalog:**
- Location: `KubebarCore/Services/ContextCatalog.swift`
- Triggers: `MenuBarViewModel.openSetup()`.
- Responsibilities: List available Kubernetes contexts for setup.

**Quality Gate:**
- Location: `scripts/swift-quality-gate.sh`
- Triggers: Local development, CI, and the `skills/ship/SKILL.md` workflow.
- Responsibilities: Detect Xcode project/workspace, run Xcode build/test, then run `swift build` and `swift test` when `Package.swift` exists.

## Error Handling

**Strategy:** Convert external and persistence failures into typed or user-safe errors at service boundaries, then render stale or setup state instead of silently showing healthy data.

**Patterns:**
- Use typed service errors: `CommandRunnerError` in `KubebarCore/Services/CommandRunner.swift`, `KubectlCommandError` in `KubebarCore/Services/ContextCatalog.swift` and `KubebarCore/Services/KubectlClusterReader.swift`, and `AppConfigStoreError` in `KubebarCore/Services/AppConfigStore.swift`.
- In `KubebarCore/Services/KubectlClusterReader.swift`, map timeout and launch failures to operator-readable `KubectlCommandError.failed(...)` reasons.
- In `KubebarCore/Services/RefreshCoordinator.swift`, keep `previousSnapshot` on read failure and pass `RefreshFailure` into `HealthEvaluator`.
- In `Kubebar/MenuBarViewModel.swift`, recover corrupt or missing config by using `AppConfig()` and showing setup/unavailable state.
- In `Kubebar/MenuBarViewModel.swift`, display save failure through `SetupFlowState.configurationMessage`.
- In `KubebarCore/Services/ContextCatalog.swift`, throw `KubectlCommandError.failed(...)` for nonzero `kubectl config get-contexts` results; `MenuBarViewModel.loadContexts()` currently degrades to an empty context list.

## Cross-Cutting Concerns

**Logging:** Not detected. No logging framework or shared logger appears in `Kubebar/`, `KubebarCore/`, or `KubebarTests/`.

**Validation:** Setup validity is modeled by `AppConfig.needsSetup` in `KubebarCore/Services/AppConfigStore.swift` and `SetupFlowState.isConfigured` in `KubebarCore/Models/SetupFlowState.swift`. Refresh validation happens before cluster reads in `KubebarCore/Services/RefreshCoordinator.swift`.

**Authentication:** Not applicable in app code. Kubernetes access is delegated to the user's local `kubectl` configuration through `KubebarCore/Services/CommandRunner.swift` and `KubebarCore/Services/KubectlClusterReader.swift`.

**Freshness:** Stale-state rules live in `docs/architecture/runtime-invariants.md`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/HealthEvaluator.swift`, and `Kubebar/Views/StaleBannerView.swift`.

**Concurrency:** UI state is confined to `@MainActor` in `Kubebar/MenuBarViewModel.swift`. Blocking refresh and context listing work runs in `Task.detached`. `KubebarCore/Services/KubectlClusterReader.swift` reads nodes, pods, and events concurrently with `DispatchGroup`; `KubebarCore/Services/CommandRunner.swift` reads stdout/stderr concurrently with `DispatchGroup`.

**Dependency Injection:** Service boundaries use initializer defaults backed by protocols: `CommandRunning` in `KubebarCore/Services/CommandRunner.swift`, `ClusterReading` in `KubebarCore/Services/KubectlClusterReader.swift`, and injectable stores/coordinators/catalogs in `Kubebar/MenuBarViewModel.swift`.

**Architecture Documentation:** `docs/architecture/system-overview.md` and `docs/architecture/runtime-invariants.md` are authoritative for subsystem behavior beyond `AGENTS.md`. Update these files when changing request flow, runtime guarantees, or ownership boundaries.

---

*Architecture analysis: 2026-04-19*
