---
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
plan: "01"
subsystem: core-display
tags: [swift, macos, menu-bar, accessibility, watchlist]

requires:
  - phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons
    provides: actionable warning and workload reason data
provides:
  - Four-state menu bar icon source regression coverage
  - Core-owned primaryStatusReason display contract
  - Full watch target title preservation for later middle truncation
affects: [menu-bar-status, status-summary, watchlist-rows, keyboard-navigation]

tech-stack:
  added: []
  patterns:
    - HealthEvaluator owns status reason selection
    - MenuDisplayModel carries render-ready status reason data
    - WatchItemDisplay.title preserves full app-owned target names

key-files:
  created:
    - .planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-01-SUMMARY.md
  modified:
    - KubebarCore/Models/MenuDisplayModel.swift
    - KubebarCore/Services/HealthEvaluator.swift
    - KubebarTests/Models/MenuBarStatusPresentationTests.swift
    - KubebarTests/Models/MenuDisplayModelTests.swift

key-decisions:
  - "Kept OK as the custom KubebarLogo in the menu bar while preserving checkmark.circle for opened-menu summaries."
  - "Kept one top-level status reason in KubebarCore instead of deriving health in SwiftUI views."
  - "Stopped core tail truncation for watch target titles so views can apply middle truncation with full tooltip and accessibility values."

patterns-established:
  - "Status reason contract: MenuDisplayModel.primaryStatusReason is computed by HealthEvaluator and defaults to healthSentence for source compatibility."
  - "Full title contract: WatchItemDisplay.title stores WatchTarget.displayTitle without pre-truncation."

requirements-completed: [R1, R13, R20]

duration: 5 min
completed: 2026-04-21
---

# Phase 06 Plan 01: Core Presentation Contract Summary

**Four-state menu bar icons, core-owned status reasons, and full watch target names are locked by model tests.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-21T15:58:49Z
- **Completed:** 2026-04-21T16:03:42Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Locked all four menu bar icon sources in tests, including `OK` as `.custom("KubebarLogo")`.
- Added `primaryStatusReason` to `MenuDisplayModel` and derived one concise reason for `OK`, `Watch`, `Bad`, and `Stale`.
- Preserved full watch target titles in core display data so Phase 06 view work can apply middle truncation without losing suffixes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock four menu bar icon sources and accessibility labels** - `c6731d6` (test)
2. **Task 2 RED: Add failing primary status reason coverage** - `75cd407` (test)
3. **Task 2 GREEN: Add primary status reasons** - `aa519b0` (feat)
4. **Task 3 RED: Add failing full title coverage** - `9976be8` (test)
5. **Task 3 GREEN: Preserve full watch item titles** - `bfc45c0` (feat)

## Files Created/Modified

- `KubebarCore/Models/MenuDisplayModel.swift` - Adds `primaryStatusReason` with a source-compatible initializer default.
- `KubebarCore/Services/HealthEvaluator.swift` - Selects one primary status reason and passes full watch target names into `WatchItemDisplay`.
- `KubebarTests/Models/MenuBarStatusPresentationTests.swift` - Locks custom and SF Symbol icon sources plus accessibility labels.
- `KubebarTests/Models/MenuDisplayModelTests.swift` - Covers primary reasons and full-title preservation.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-01-SUMMARY.md` - Records plan results.

## Decisions Made

- Used the existing `MenuBarStatusPresentation.icon` contract for menu bar state assertions instead of adding view-level checks.
- Made `primaryStatusReason` optional in the initializer so any direct construction still falls back to `healthSentence`.
- Removed only watch target title shortening; warning message capping remains in place because it limits secondary warning detail copy.

## Deviations from Plan

### Verification Adjustments

**1. Task 3 negative grep pattern conflicted with a required full-name assertion**
- **Found during:** Task 3 acceptance checks
- **Issue:** The plan required the exact string `checkout-api-with-a-very-long-name`, but its negative regex `checkout-api-with-a-.` also matches that required string.
- **Fix:** Kept the required full-name test and verified the actual forbidden patterns with `shortened(item.target.displayTitle)`, `checkout-api-with-a-...`, and `prefix(limit - 1)`.
- **Files modified:** None for the adjustment
- **Verification:** `swift test --filter MenuDisplayModelTests` passed, and source checks confirmed full titles enter `WatchItemDisplay`.
- **Committed in:** No separate commit; code behavior is covered by `bfc45c0`.

### Auto-fixed Issues

None.

---

**Total deviations:** 1 verification adjustment, 0 auto-fixed code issues.
**Impact on plan:** No behavior scope changed. The implementation satisfies the intended full-name preservation contract.

## Issues Encountered

- Task 1's new tests passed immediately because production already mapped `OK` to `KubebarLogo`; no production edit was needed.
- `./scripts/swift-quality-gate.sh local` printed a non-blocking CoreSimulator version warning, but the macOS build/test and SwiftPM build/test completed successfully.

## Verification

- `swift test --filter MenuBarStatusPresentationTests` - passed.
- `swift test --filter MenuDisplayModelTests` - passed.
- `rg -n "primaryStatusReason|KubebarLogo|checkout-api-with-a-very-long-name" KubebarCore KubebarTests` - found the Phase 06 core contracts and tests.
- Negative deferred-scope grep for `NSStatusItem|NSMenu|Open in k9s|notarization|distribution|dashboard|raw kubectl` in `KubebarCore` and `KubebarTests/Models` - passed.
- `swift test` - passed, 86 tests.
- `./scripts/swift-quality-gate.sh local` - passed.

## Known Stubs

None. Default initializer values found during scan are existing source-compatible defaults, not UI stubs.

## Threat Flags

None. This plan added display-model fields and tests only; it did not add new endpoints, auth paths, file access, subprocess boundaries, or schema changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 06 Plan 02. The core now exposes the status reason and full watch target names that the SwiftUI views need for opened-menu rendering, middle truncation, tooltip, and accessibility work.

## Self-Check: PASSED

- Summary file exists.
- Task commits found: `c6731d6`, `75cd407`, `aa519b0`, `9976be8`, `bfc45c0`.
- No unexpected tracked file deletions were found in task commits.

---
*Phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation*
*Completed: 2026-04-21*
