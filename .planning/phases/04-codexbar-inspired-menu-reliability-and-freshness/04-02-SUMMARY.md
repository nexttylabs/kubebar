---
phase: 04-codexbar-inspired-menu-reliability-and-freshness
plan: "02"
subsystem: core
tags: [swift, setup, menu-state, tests]
requires:
  - phase: 04-01
    provides: local app launch verification
provides:
  - Testable setup and menu runtime state model
  - First-use and edit-watchlist transition coverage
affects: [setup, watchlist, menu-bar]
tech-stack:
  added: []
  patterns: [pure runtime state model, thin view model]
key-files:
  created:
    - KubebarCore/Models/MenuRuntimeState.swift
    - KubebarTests/Models/MenuRuntimeStateTests.swift
  modified:
    - Kubebar/MenuBarViewModel.swift
key-decisions:
  - "MenuRuntimeState owns setup/menu decisions while MenuBarViewModel owns async work."
  - "Target-load failures preserve selected context and watchlist selections."
patterns-established:
  - "Use pure model tests for setup transitions that are hard to verify through menu UI alone."
requirements-completed: [P04-MODEL-SEAM, GH-3, GH-7]
duration: inline
completed: 2026-04-21
---

# Phase 04 Plan 02 Summary

**Pure setup/menu runtime model covering first-use, edit, context change, and target-load failure paths**

## Performance

- **Duration:** inline
- **Started:** 2026-04-21
- **Completed:** 2026-04-21
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `MenuRuntimeState` and `MenuSurface`.
- Moved setup/menu transition decisions out of `MenuBarViewModel`.
- Added tests for fresh config, partial config, configured menu, edit setup, context change, failure, and completion.

## Task Commits

No task commits were created in this run. Execution happened inline in the current worktree.

## Files Created/Modified

- `KubebarCore/Models/MenuRuntimeState.swift` - Pure runtime state for setup/menu decisions.
- `KubebarTests/Models/MenuRuntimeStateTests.swift` - Transition coverage.
- `Kubebar/MenuBarViewModel.swift` - Uses runtime state while keeping async catalog/refresh work.

## Decisions Made

- Kept direct SwiftUI binding to `setupState`, but syncs it back to runtime state.
- Kept async context and target catalog calls in the view model.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

Refresh cadence work can build on a tested runtime state instead of adding more decisions to the view model.

---
*Phase: 04-codexbar-inspired-menu-reliability-and-freshness*
*Completed: 2026-04-21*
