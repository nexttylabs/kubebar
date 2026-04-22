---
phase: 09-codexbar-inspired-tabbed-menu-redesign
plan: "01"
subsystem: ui
tags: [swiftui, macos, menu-bar, tabs, kubebarcore, testing]

requires:
  - phase: 09-codexbar-inspired-tabbed-menu-redesign
    provides: approved Phase 09 context, UI spec, validation strategy, and pattern map
provides:
  - Core-owned display contracts for Overview, Nodes, Pods, and Events tabs
  - Fixed native menu tabs with Overview selected by default
  - Focused tests for tab summaries, unavailable copy, stale display, notice caps, event row caps, and pod examples
affects: [09-02, 09-03, menu-ui, display-model]

tech-stack:
  added: []
  patterns:
    - Core-generated tab display fields consumed by thin SwiftUI views
    - Menu-local tab selection with no refresh side effects

key-files:
  created:
    - Kubebar/Views/MenuTab.swift
    - Kubebar/Views/OverviewTabView.swift
    - Kubebar/Views/NodesTabView.swift
    - Kubebar/Views/PodsTabView.swift
    - Kubebar/Views/EventsTabView.swift
  modified:
    - Kubebar.xcodeproj/project.pbxproj
    - Kubebar/Views/MenuBarRootView.swift
    - Kubebar/Views/NodeDetailsView.swift
    - Kubebar/Views/WarningEventsView.swift
    - KubebarCore/Models/MenuDisplayModel.swift
    - KubebarCore/Services/HealthEvaluator.swift
    - KubebarTests/Models/MenuDisplayModelTests.swift

key-decisions:
  - "Use a segmented Picker for fixed local tabs: Overview, Nodes, Pods, Events."
  - "Keep tab display strings and capped rows in KubebarCore through MenuDisplayModel and HealthEvaluator."
  - "Leave Settings and Quit out of Plan 01; Wave 2 owns those actions."

patterns-established:
  - "Tab views render only MenuDisplayModel fields and do not trigger refresh or Kubernetes reads."
  - "Events tab uses grouped warning rows; Overview receives at most one compact notice."
  - "Pods tab reuses watchlist detail rows instead of showing all-namespace inventory."

requirements-completed: [REQ-09-01, REQ-09-02, REQ-09-03, REQ-09-04, REQ-09-05, REQ-09-06, REQ-09-09, REQ-09-10]

duration: 8min
completed: 2026-04-22
---

# Phase 09 Plan 01: Tabbed Menu Foundation Summary

**Core-owned tab display data plus a fixed Overview/Nodes/Pods/Events menu shell for Kubebar's watchlist-first menu.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-22T06:47:11Z
- **Completed:** 2026-04-22T06:54:56Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added `overviewNotice`, `nodeTab`, `podTab`, and `eventsTab` to `MenuDisplayModel`.
- Built tab summaries, safe unavailable copy, empty copy, and capped event/detail rows in `HealthEvaluator`.
- Replaced the single menu body with four fixed tabs and local `selectedTab` state that resets to Overview on menu appearance.
- Kept Overview watchlist-first while moving full warning rows to Events and workload detail rows to Pods.

## Task Commits

1. **Task 1 RED: Add failing tab display tests** - `4e12c8e` (test)
2. **Task 1 GREEN: Add core tab display contracts** - `8a32013` (feat)
3. **Task 2: Replace single-page menu body with fixed native tabs** - `efa9504` (feat)
4. **Task 3: Run focused Wave 1 validation and scope guards** - `0ae2059` (test)

## Files Created/Modified

- `Kubebar/Views/MenuTab.swift` - Fixed `Overview`, `Nodes`, `Pods`, and `Events` tab cases.
- `Kubebar/Views/OverviewTabView.swift` - Home tab with status, stale banner, counters, watchlist, and one compact notice.
- `Kubebar/Views/NodesTabView.swift` - Nodes tab wrapper with stale banner and aggregate node display.
- `Kubebar/Views/PodsTabView.swift` - Pods tab with aggregate readiness and watchlist/workload detail rows.
- `Kubebar/Views/EventsTabView.swift` - Events tab with stale banner and grouped warning rows.
- `Kubebar/Views/MenuBarRootView.swift` - Segmented tab shell, Overview reset, 360pt menu layout, and scrollable content.
- `Kubebar/Views/NodeDetailsView.swift` - Node tab-safe unavailable, empty, and aggregate copy.
- `Kubebar/Views/WarningEventsView.swift` - Events tab-safe unavailable, empty, and grouped warning rendering.
- `KubebarCore/Models/MenuDisplayModel.swift` - Core tab display value types and source-compatible defaults.
- `KubebarCore/Services/HealthEvaluator.swift` - Core mapping for tab summaries, notices, unavailable copy, and row caps.
- `KubebarTests/Models/MenuDisplayModelTests.swift` - Focused tab display regression tests.
- `Kubebar.xcodeproj/project.pbxproj` - Regenerated from `project.yml` so Xcode builds include new view files.

## Decisions Made

- Used a segmented `Picker` because it is native, compact, keyboard reachable, and matches the UI spec.
- Kept tab selection as local SwiftUI state; no persistence, no refresh hook, and no service calls are tied to tab switching.
- Did not add Settings or Quit in this plan because Plan 02 owns those actions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved warning-count copy when grouped event rows are unavailable**
- **Found during:** Task 2 (Replace single-page menu body with fixed native tabs)
- **Issue:** Legacy snapshots can carry a warning count without grouped warning rows. Rendering Events from rows alone would have shown `No current warning events` despite a nonzero count.
- **Fix:** Added dynamic `EventsTabDisplay.emptyMessage` construction from warning count and a regression test for the count-only case.
- **Files modified:** `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarTests/Models/MenuDisplayModelTests.swift`
- **Verification:** `swift test --filter MenuDisplayModelTests`, `swift build`, and `./scripts/swift-quality-gate.sh local`
- **Committed in:** `efa9504`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Correctness fix only. It preserves existing warning visibility and does not expand product scope.

## TDD Gate Compliance

- RED commit present: `4e12c8e`
- GREEN commit present after RED: `8a32013`
- REFACTOR commit: not needed

## Issues Encountered

- New Swift files required `xcodegen generate` so the committed Xcode project includes them. The project still uses `project.yml` as the source of truth.
- Task 3 produced no file changes, so it was recorded as an empty validation commit to keep one commit per task.

## Verification

- `swift test --filter MenuDisplayModelTests` - passed
- `swift build` - passed
- `./scripts/swift-quality-gate.sh local` - passed
- Fixed tab source check - passed
- No tab-selection refresh/service hook source check - passed
- Deferred scope guard for dashboards, raw output, providers, usage meters, `NSStatusItem`, live streams, and `Open in k9s` - passed

## Known Stubs

None. Stub scan found only optional/default initializer values and test helper defaults.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 can add independent Settings and visible Quit wiring on top of the fixed tab shell. Plan 03 still owns visible menu UAT and manual keyboard/truncation proof.

## Self-Check: PASSED

- Summary file exists.
- New tab view files exist.
- Task commits found: `4e12c8e`, `8a32013`, `efa9504`, `0ae2059`.

---
*Phase: 09-codexbar-inspired-tabbed-menu-redesign*
*Completed: 2026-04-22*
