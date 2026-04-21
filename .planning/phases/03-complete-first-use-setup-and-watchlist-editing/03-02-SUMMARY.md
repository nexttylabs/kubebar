---
phase: 03-complete-first-use-setup-and-watchlist-editing
plan: "02"
subsystem: app-flow
tags: [swiftui, setup, watchlist, persistence]
requires:
  - phase: 03-01
    provides: Watch target catalog and candidate models
provides:
  - Setup target loading state
  - Context selection path that loads candidates for the selected context
  - Retry path that preserves selected watchlist targets
affects: [setup, menu-bar-view-model, watchlist]
tech-stack:
  added: []
  patterns: [main actor view model coordination, retryable setup loading state]
key-files:
  created: []
  modified:
    - KubebarCore/Models/SetupFlowState.swift
    - KubebarCore/Models/WatchlistSelectionState.swift
    - Kubebar/MenuBarViewModel.swift
    - Kubebar/Views/MenuBarRootView.swift
    - Kubebar/Views/SetupView.swift
    - KubebarTests/Models/SetupFlowStateTests.swift
    - KubebarTests/Models/WatchlistSelectionStateTests.swift
key-decisions:
  - "Changing context clears available candidates but preserves selected targets until the user changes them."
  - "Loading failures show a retryable state and do not make a saved setup incomplete."
patterns-established:
  - "SetupView routes context changes through MenuBarViewModel instead of mutating context silently."
  - "WatchlistSelectionState separates available candidates from saved selected targets."
requirements-completed: [GH-3, R14, R15, R16, R17]
duration: inline
completed: 2026-04-20
---

# Phase 03 Plan 02 Summary

**Setup state now loads watch targets from the chosen context and preserves saved selections through failures**

## Performance

- **Duration:** inline
- **Started:** 2026-04-20T14:00:00Z
- **Completed:** 2026-04-20T14:18:12Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `WatchTargetLoadingState` with idle, loading, and failed states.
- Added candidate replacement and clearing helpers that do not erase selected targets.
- Wired context selection and retry actions through `MenuBarViewModel`.
- Ensured opening setup reloads candidates for the saved context.
- Covered failure preservation and candidate replacement in tests.

## Task Commits

No task commits were created in this run. Execution happened inline in the current detached worktree.

## Files Created/Modified

- `KubebarCore/Models/SetupFlowState.swift` - Loading state and setup copy behavior.
- `KubebarCore/Models/WatchlistSelectionState.swift` - Candidate replacement, clearing, and empty copy.
- `Kubebar/MenuBarViewModel.swift` - Candidate loading, retry, save, and refresh wiring.
- `Kubebar/Views/MenuBarRootView.swift` - Passes context and retry callbacks.
- `Kubebar/Views/SetupView.swift` - Routes picker changes through the view model.
- `KubebarTests/Models/SetupFlowStateTests.swift` - Setup completion and failure preservation coverage.
- `KubebarTests/Models/WatchlistSelectionStateTests.swift` - Candidate state mutation coverage.

## Decisions Made

- Preserved selected targets during discovery failure so a transient kubectl problem does not erase user choices.
- Cleared only available candidates when context changes so stale candidates are not presented as current.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

The UI can render loading, failure, retry, and candidate-loaded states from one setup model.

---
*Phase: 03-complete-first-use-setup-and-watchlist-editing*
*Completed: 2026-04-20*
