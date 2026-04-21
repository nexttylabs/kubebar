---
phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons
plan: "02"
subsystem: kubectl-display
tags: [kubebar, health-evaluator, warning-events, section-failures, swift-testing]

requires:
  - phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons
    provides: Section-aware snapshots, warning event records, tracked item detail facts
provides:
  - Display-ready warning event summaries capped at three rows
  - Tracked item detail display fields capped to three pod examples
  - Section unavailable notices and dash counters for partial kubectl failures
  - Tests preserving whole-refresh stale behavior
affects: [05-03-warning-ui-rendering, MenuDisplayModel, HealthEvaluator]

tech-stack:
  added: []
  patterns: [TDD RED-GREEN commits, HealthEvaluator-only display mapping, section notice display contracts]

key-files:
  created:
    - .planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-02-SUMMARY.md
  modified:
    - KubebarCore/Models/MenuDisplayModel.swift
    - KubebarCore/Services/HealthEvaluator.swift
    - KubebarTests/Models/MenuDisplayModelTests.swift
    - KubebarTests/Services/RefreshCoordinatorTests.swift

key-decisions:
  - "Keep SwiftUI out of health and grouping logic by exposing display-ready warning summaries, details, and section notices through MenuDisplayModel."
  - "Use HealthEvaluator as the single place for warning grouping, caps, message shortening, dash counters, and partial-failure severity."
  - "Treat partial section failures as current Watch state, not whole-refresh Stale state."
  - "Preserve old initializer call sites with default display fields."

patterns-established:
  - "WarningEventDisplay.summary formats grouped occurrences before UI rendering."
  - "WatchItemDisplay.detail defaults to the row reason while richer details are supplied by HealthEvaluator."
  - "SectionAvailabilityDisplay surfaces unavailable kubectl sections without changing whole-refresh stale handling."

requirements-completed: [R3, R8, R9, R12]

duration: 8min
completed: 2026-04-21
---

# Phase 05 Plan 02: Warning Display Mapping Summary

**Display-ready warning summaries, tracked item details, and visible partial kubectl failures**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-21T09:24:52Z
- **Completed:** 2026-04-21T09:32:29Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added display contracts for warning summaries, tracked item details, and unavailable-section notices.
- Grouped duplicate warning events by reason and object, summed occurrences, kept the newest short message, sorted newest first, and capped display to three summaries.
- Mapped tracked item detail fields from `TrackedItemStatus`, including affected pod count, up to three pod examples, and latest warning.
- Made unavailable sections visible through dash counters and section notices while keeping successful partial snapshots fresh.
- Preserved whole-refresh failure behavior: previous data remains visible only as `Stale` with a stale banner.

## Task Commits

Each task was committed through its TDD RED/GREEN steps:

1. **Task 1: Add display-ready warning and detail contracts**
   - `59f8ec5` test(05-02): add failing display contract coverage
   - `3e31e04` feat(05-02): add menu display warning contracts
2. **Task 2: Map warning grouping, caps, and tracked details**
   - `f15a30b` test(05-02): add failing warning display mapping coverage
   - `80ad7e7` feat(05-02): map warning summaries and item details
3. **Task 3: Surface unavailable sections without fake healthy state**
   - `e1e20c5` test(05-02): add failing unavailable section coverage
   - `de64987` feat(05-02): surface unavailable snapshot sections

## Files Created/Modified

- `KubebarCore/Models/MenuDisplayModel.swift` - Adds warning event, tracked detail, and section notice display contracts with compatible defaults.
- `KubebarCore/Services/HealthEvaluator.swift` - Builds warning summaries, tracked details, dash counters, section notices, and partial-failure state.
- `KubebarTests/Models/MenuDisplayModelTests.swift` - Covers constructor defaults, warning summary grouping/caps, shortened messages, detail caps, and unavailable counters.
- `KubebarTests/Services/RefreshCoordinatorTests.swift` - Covers successful partial section failure without stale banner and preserves whole-refresh stale behavior.
- `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-02-SUMMARY.md` - Records execution results.

## Decisions Made

- Warning event message shortening stays at 96 characters in `HealthEvaluator`.
- Section notices use the snapshot section id, display name, and sanitized reason already stored in app-owned snapshot data.
- Warning event summaries are omitted when the event section is unavailable; the unavailable state is shown through `sectionNotices` and `counters.warningEvents == "-"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added explicit warning group initializer**
- **Found during:** Task 2 (Map warning grouping, caps, and tracked details)
- **Issue:** The first GREEN build failed because Swift made the synthesized `WarningEventGroup` initializer inaccessible after adding private state.
- **Fix:** Added a narrow initializer for the grouping value type.
- **Files modified:** `KubebarCore/Services/HealthEvaluator.swift`
- **Verification:** `swift test --filter MenuDisplayModelTests` passed after the fix.
- **Committed in:** `80ad7e7`

---

**Total deviations:** 1 auto-fixed Rule 3 issue
**Impact on plan:** No scope expansion. The fix was required for the planned display mapping to compile.

## Issues Encountered

- `gsd-sdk` was unavailable in this worktree, as stated in the execution request.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/config.json` were absent. State, roadmap, and requirement updates were not run through GSD; this summary records the fallback.
- One attempted parallel focused test run waited on SwiftPM's `.build` lock. The tests were then handled sequentially and passed.

## Verification

Required checks passed:

- `swift test --filter MenuDisplayModelTests`
- `swift test --filter RefreshCoordinatorTests`
- `swift test`
- `./scripts/swift-quality-gate.sh local`
- `git diff --check`
- `rg -n "warningEventSummaries|sectionNotices|affectedPodCount|examplePodNames|latestWarning" KubebarCore/Models/MenuDisplayModel.swift KubebarCore/Services/HealthEvaluator.swift KubebarTests`
- Negative grep passed: no `Open in k9s`, `dashboard`, `raw pod`, `raw event`, or `full kubectl` in `MenuDisplayModel.swift` or `HealthEvaluator.swift`.

## TDD Gate Compliance

- RED commits present: `59f8ec5`, `f15a30b`, `e1e20c5`
- GREEN commits present after RED: `3e31e04`, `80ad7e7`, `de64987`
- No REFACTOR commit was needed.

## Known Stubs

None. Stub scan found only intentional default initializer values and nil assertions in tests.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were introduced.

## User Setup Required

None. No external service configuration is required.

## Next Phase Readiness

Plan 03 can render `warningEventSummaries`, `sectionNotices`, and `WatchItemDisplay.detail` directly without parsing raw kubectl output or deciding health in SwiftUI.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-02-SUMMARY.md`.
- All six TDD task commits are present: `59f8ec5`, `3e31e04`, `f15a30b`, `80ad7e7`, `e1e20c5`, `de64987`.
- Existing untracked Phase 05 planning files were preserved and not staged.

---
*Phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons*
*Completed: 2026-04-21*
