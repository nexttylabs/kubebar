---
phase: 04-codexbar-inspired-menu-reliability-and-freshness
plan: "05"
subsystem: reliability
tags: [freshness, stale-state, refresh-cadence, kubectl, timeout]
requires:
  - phase: 04-04
    provides: visible refresh cadence controls and Phase 04 UAT checklist
provides:
  - 2x saved-cadence stale age-out
  - Always-visible last updated text
  - Distinct safe refresh failure reasons
  - Single in-flight refresh gate
  - Config-change-safe refresh result invalidation
  - Issue #5 UAT and runtime invariant updates
affects: [menu-bar, refresh, kubectl-reader, uat, runtime-invariants]
tech-stack:
  added: []
  patterns: [display-level freshness contract, main-actor refresh gate]
key-files:
  created:
    - KubebarCore/Services/RefreshGate.swift
    - KubebarTests/Services/RefreshGateTests.swift
  modified:
    - KubebarCore/Models/MenuDisplayModel.swift
    - KubebarCore/Services/HealthEvaluator.swift
    - KubebarCore/Services/RefreshCoordinator.swift
    - KubebarCore/Services/KubectlClusterReader.swift
    - Kubebar/MenuBarViewModel.swift
    - Kubebar/Views/MenuBarRootView.swift
    - KubebarTests/Models/MenuDisplayModelTests.swift
    - KubebarTests/Services/KubectlClusterReaderTests.swift
    - KubebarTests/Services/RefreshCoordinatorTests.swift
    - docs/architecture/runtime-invariants.md
    - .planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-UAT.md
key-decisions:
  - "Successful snapshots older than 2x the saved refresh cadence are Stale."
  - "Refresh failures preserve the last successful snapshot only as stale data."
  - "Refresh work is guarded by one in-flight operation shared by manual and automatic refresh."
patterns-established:
  - "MenuDisplayModel carries lastUpdated so views render freshness without computing health."
  - "RefreshGate makes retry availability testable without adding a fifth menu state."
  - "Refresh tickets prevent old async results from overwriting newer config state."
requirements-completed: [R10, R11, R12, GH-5]
duration: inline
completed: 2026-04-21
---

# Phase 04 Plan 05 Summary

**Issue #5 freshness rules with stale age-out, safe failure reasons, and guarded refresh work**

## Performance

- **Duration:** inline
- **Started:** 2026-04-21T10:46:00Z
- **Completed:** 2026-04-21T14:41:29Z
- **Tasks:** 4
- **Files modified:** 13

## Accomplishments

- Added `lastUpdated` to the display model and rendered `Last updated <age>` in the menu controls.
- Made successful data older than `2x` the saved refresh cadence show as `Stale` with `Last refresh is too old`.
- Locked timeout, empty/unsafe command failure, malformed JSON, and no-previous-data reasons into code and tests.
- Added a refresh gate so `Retry now` and automatic refresh share one in-flight guard.
- Invalidated old in-flight refresh results when setup or cadence changes, and queued a follow-up refresh for the new config.
- Updated runtime invariants and UAT checks for issue #5 behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add always-visible last update and age-out stale policy** - `40cddff` (feat)
2. **Task 2: Lock distinct safe failure reasons** - `4915392` (fix)
3. **Task 3: Serialize refresh work and disable retry while refreshing** - `2791542` (feat)
4. **Task 4: Update operator-facing docs and UAT for issue #5** - `133bf48` (docs)
5. **Review fix: Prevent stale refresh overwrite** - `7b92cae` (fix)

## Files Created/Modified

- `KubebarCore/Services/RefreshGate.swift` - Small guard for one in-flight refresh plus config-generation tickets.
- `KubebarTests/Services/RefreshGateTests.swift` - Covers begin/finish behavior, stale ticket rejection, and queued refresh handoff.
- `KubebarCore/Models/MenuDisplayModel.swift` - Adds display-level `lastUpdated`.
- `KubebarCore/Services/HealthEvaluator.swift` - Applies stale age-out and freshness text.
- `KubebarCore/Services/RefreshCoordinator.swift` - Passes saved-cadence threshold and no-previous-data reason.
- `KubebarCore/Services/KubectlClusterReader.swift` - Keeps timeout, malformed JSON, and safe command failure reasons distinct.
- `Kubebar/MenuBarViewModel.swift` - Guards refresh work and publishes `isRefreshing`.
- `Kubebar/Views/MenuBarRootView.swift` - Shows last update and disables `Retry now` while refreshing.
- `KubebarTests/Models/MenuDisplayModelTests.swift` - Covers old successful data becoming stale.
- `KubebarTests/Services/KubectlClusterReaderTests.swift` - Covers timeout and safe command failure reasons.
- `KubebarTests/Services/RefreshCoordinatorTests.swift` - Covers no previous data, repeated failures, and injected-time stale age.
- `docs/architecture/runtime-invariants.md` - Documents issue #5 freshness rules.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-UAT.md` - Adds manual checks for issue #5.

## Decisions Made

- Kept the four status categories: `OK`, `Watch`, `Bad`, and `Stale`.
- Kept repeated failures quiet: stale reason updates, but counters and watchlist rows remain from the last success.
- Did not add a countdown or persistent progress panel.

## Deviations from Plan

Code review found two warning-level refresh ordering issues after the planned tasks:

- Existing display freshness could remain visually current until another refresh completed.
- A setup/cadence change during an in-flight refresh could be overwritten by the older result.

Both were fixed in `7b92cae` by adding freshness re-evaluation, refresh tickets, and pending refresh handoff.

## Issues Encountered

`gsd-sdk` and `.planning/STATE.md` were unavailable in this checkout, so tracking updates were handled from local plan artifacts and git state.

## Verification

- `swift test --filter MenuDisplayModelTests` passed.
- `swift test --filter RefreshGateTests` passed.
- `swift test --filter RefreshCoordinatorTests` passed.
- `swift test --filter KubectlClusterReaderTests` passed.
- `./scripts/swift-quality-gate.sh local` passed with 84 tests in 15 suites.
- `./scripts/compile-and-run.sh` passed and launched `DerivedData/Build/Products/Debug/Kubebar.app`.
- `rg -n "2x|No previous cluster data|malformed JSON|Retry now" docs/architecture/runtime-invariants.md .planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-UAT.md` returned the expected contract lines.

## User Setup Required

None.

## Next Phase Readiness

Issue #5 is covered by deterministic tests and UAT checks. Manual visible-app UAT remains available for confirming menu interaction details such as `Retry now` disabled state while a refresh is in progress.

---
*Phase: 04-codexbar-inspired-menu-reliability-and-freshness*
*Completed: 2026-04-21*
