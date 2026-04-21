# Phase 04 Patterns

**Date:** 2026-04-21
**Status:** Ready

## Existing Patterns to Reuse

| Concern | Existing Pattern | Files |
| --- | --- | --- |
| Quality gate | One script detects Xcode/SPM shapes and runs build/test | `scripts/swift-quality-gate.sh` |
| App target | XcodeGen app target, bundle id, LSUIElement | `project.yml` |
| Menu shell | SwiftUI `MenuBarExtra.window` rendering `MenuBarRootView` | `Kubebar/KubebarApp.swift`, `Kubebar/Views/MenuBarRootView.swift` |
| Display input | Views render `MenuDisplayModel` | `KubebarCore/Models/MenuDisplayModel.swift` |
| Severity | `HealthEvaluator` owns `OK`, `Watch`, `Bad`, `Stale` | `KubebarCore/Services/HealthEvaluator.swift` |
| Refresh | `RefreshCoordinator` turns config + snapshot into display | `KubebarCore/Services/RefreshCoordinator.swift` |
| Config | `AppConfigStore` persists context, watchlist, interval | `KubebarCore/Services/AppConfigStore.swift` |
| Setup state | Value models describe setup/watchlist selection | `KubebarCore/Models/SetupFlowState.swift`, `KubebarCore/Models/WatchlistSelectionState.swift` |
| Discovery | Catalogs use injected command runners | `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/WatchTargetCatalog.swift` |
| Icon | Core presentation maps state to symbol/accessibility label | `KubebarCore/Models/MenuBarStatusPresentation.swift` |

## New Work Placement

### 04-01 Local Run Verification

- Add `scripts/compile-and-run.sh`.
- Reuse `scripts/swift-quality-gate.sh local` instead of duplicating build/test
  logic.
- Use `project.yml` values for app name and bundle id.
- Document in `README.md` and `AGENTS.md`.

### 04-02 Testable Menu/Setup Runtime State

- Prefer a new value model under `KubebarCore/Models/`.
- Keep `MenuBarViewModel` as the UI-bound async coordinator.
- Add tests under `KubebarTests/Models/`.
- Do not make views decide whether contexts or targets should load.

### 04-03 Refresh Cadence and Freshness

- Reuse `AppConfig.refreshIntervalSeconds`.
- Add a small cadence model if needed, instead of changing config shape.
- Keep refresh failure semantics in `RefreshCoordinator` and `HealthEvaluator`.
- Add any timer loop to `MenuBarViewModel`, with pure model tests for cadence
  mapping and visible state.

### 04-04 Icon, Docs, and QA

- Extend `MenuBarStatusPresentation` instead of hard-coding icon decisions in
  `KubebarApp`.
- Keep icon categories stable.
- Update `docs/architecture/runtime-invariants.md` and `README.md`.
- Add `04-UAT.md` for real app verification.

## Risks to Avoid

- Do not make Phase 04 a dashboard redesign.
- Do not query Kubernetes secrets.
- Do not let stale data reuse the healthy icon/message.
- Do not duplicate build/test behavior outside the quality gate.
- Do not introduce provider abstractions before Kubebar has more than one data
  domain.
