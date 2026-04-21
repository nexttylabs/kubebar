---
phase: 03-complete-first-use-setup-and-watchlist-editing
plan: "01"
subsystem: core
tags: [swift, kubectl, watchlist, setup]
requires: []
provides:
  - Workload kind model for Deployment, StatefulSet, DaemonSet, and CronJob
  - Watchlist candidate model for namespace and workload setup rows
  - Watch target catalog that discovers candidates through injected kubectl runner
affects: [setup, watchlist, kubectl, config]
tech-stack:
  added: []
  patterns: [injectable command boundary, typed watch target identity]
key-files:
  created:
    - KubebarCore/Models/WorkloadKind.swift
    - KubebarCore/Models/WatchlistCandidate.swift
    - KubebarCore/Services/WatchTargetCatalog.swift
    - KubebarTests/Models/WatchTargetTests.swift
    - KubebarTests/Services/WatchTargetCatalogTests.swift
  modified:
    - KubebarCore/Models/WatchTarget.swift
    - KubebarCore/Services/KubectlClusterReader.swift
key-decisions:
  - "Workload identity includes kind while menu display stays compact as namespace/name."
  - "Historical Job objects are excluded from default setup discovery."
patterns-established:
  - "Candidate discovery must use CommandRunning and explicit --context arguments."
  - "Setup rows can show kind names without changing compact menu labels."
requirements-completed: [GH-3, R14, R15, R16, R17]
duration: inline
completed: 2026-04-20
---

# Phase 03 Plan 01 Summary

**Kubectl-backed watch target discovery with typed workload candidates and backward-compatible saved workload targets**

## Performance

- **Duration:** inline
- **Started:** 2026-04-20T14:00:00Z
- **Completed:** 2026-04-20T14:18:12Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `WorkloadKind` for Deployment, StatefulSet, DaemonSet, and CronJob.
- Added `WatchlistCandidate` and `WatchlistCandidates` for setup candidate state.
- Added `WatchTargetCatalog` to read namespaces and supported workloads through injected `CommandRunning`.
- Preserved older saved workload config by defaulting missing kind to `.deployment`.

## Task Commits

No task commits were created in this run. Execution happened inline in the current detached worktree.

## Files Created/Modified

- `KubebarCore/Models/WorkloadKind.swift` - Supported workload kinds and kubectl resource names.
- `KubebarCore/Models/WatchlistCandidate.swift` - Namespace and workload candidate rows.
- `KubebarCore/Models/WatchTarget.swift` - Workload kind identity and backward-compatible coding.
- `KubebarCore/Services/WatchTargetCatalog.swift` - Candidate discovery from kubectl JSON.
- `KubebarCore/Services/KubectlClusterReader.swift` - Workload target matching ignores kind for current pod matching.
- `KubebarTests/Models/WatchTargetTests.swift` - Kind ordering, compact display, and old config decode coverage.
- `KubebarTests/Services/WatchTargetCatalogTests.swift` - Discovery command, sorting, JSON, and error coverage.

## Decisions Made

- Kept `WatchTarget.displayTitle` as `namespace/name` so existing menu rows stay compact.
- Used `WatchlistCandidate.displayTitle` for setup rows where kind names are useful.
- Did not query `jobs`, because historical Job objects would make setup noisy.

## Deviations from Plan

The original plan briefly proposed `namespace/kind/name` for `WatchTarget.displayTitle`. Execution kept the existing compact menu display and moved kind display to setup candidates instead. The plan file was updated to reflect this.

## Issues Encountered

- Xcode project initially did not include new Swift files. Regenerated `Kubebar.xcodeproj` with `xcodegen generate`.

## User Setup Required

None.

## Next Phase Readiness

Setup state can consume real namespace and workload candidates from the selected app-owned context.

---
*Phase: 03-complete-first-use-setup-and-watchlist-editing*
*Completed: 2026-04-20*
