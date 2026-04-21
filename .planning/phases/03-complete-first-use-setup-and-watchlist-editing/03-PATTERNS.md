# Phase 03: Complete first-use setup and watchlist editing - Patterns

**Date:** 2026-04-20
**Status:** Complete

## Closest Existing Patterns

| New responsibility | Closest existing analog | Pattern to reuse |
| --- | --- | --- |
| List watchlist candidates with `kubectl` | `KubebarCore/Services/ContextCatalog.swift` | Inject `CommandRunning`, return app-owned values, convert stderr to `KubectlCommandError.failed` |
| Decode Kubernetes JSON | `KubebarCore/Services/KubectlClusterReader.swift` | Private `Decodable` records, `JSONDecoder`, friendly parse failure messages |
| Store setup choices | `KubebarCore/Services/AppConfigStore.swift` | Keep persisted config app-owned and Codable |
| Preserve selected targets | `KubebarCore/Models/WatchlistSelectionState.swift` | Value state with `Set<WatchTarget>` and mutating selection helpers |
| Render setup sections | `Kubebar/Views/SetupView.swift` and `Kubebar/Views/WatchlistPickerView.swift` | SwiftUI view receives state and closures; no command reads in views |
| Verify command consumers | `KubebarTests/Services/KubectlClusterReaderTests.swift` | Fake command runner keyed by exact argument arrays |

## File-Level Guidance

### Core Models

- Add a `WorkloadKind` model under `KubebarCore/Models/`.
- Add candidate value types under `KubebarCore/Models/` so UI can render
  grouped candidates without raw Kubernetes JSON.
- Update `WatchTarget` carefully so saved targets remain Codable and tests can
  cover old workload config without a kind.

### Core Services

- Add `WatchTargetCatalog` under `KubebarCore/Services/`.
- Use exact command shape:
  - `kubectl --context <context> get namespaces -o json`
  - `kubectl --context <context> get deployments --all-namespaces -o json`
  - `kubectl --context <context> get statefulsets --all-namespaces -o json`
  - `kubectl --context <context> get daemonsets --all-namespaces -o json`
  - `kubectl --context <context> get cronjobs --all-namespaces -o json`
- Do not add a `jobs` command.

### App State and UI

- Keep `MenuBarViewModel` as the UI bridge. It can coordinate async target
  discovery, but discovery behavior should remain in core services.
- Keep setup layout in `SetupView` and `WatchlistPickerView`; add loading,
  failed, and grouped candidate rendering there.
- Use collapsed namespace groups for workload candidates.

### Tests

- Add service tests for command arguments, JSON decoding, no `jobs` command,
  parse errors, and stderr propagation.
- Add model tests for target kind identity, candidate grouping, selected target
  preservation, and failure/loading state.
- Add app-level behavior coverage through testable core state where direct
  `MenuBarViewModel` tests are not feasible.
