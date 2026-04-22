---
phase: 09-codexbar-inspired-tabbed-menu-redesign
plan: "04"
subsystem: menu-refinement
tags: [swiftui, menu-bar, overview, watching, quality-gate]

requires:
  - phase: 09-codexbar-inspired-tabbed-menu-redesign
    provides: Plan 01 tabbed menu foundation, Plan 02 Settings/Quit actions, and Plan 03 verification baseline
provides:
  - Content-driven menu shell with selected-tab scrolling and always-visible footer
  - Attention-aware `Watching` ordering, caps, overflow, and conditional details
  - Concise footer language and refreshed verification evidence
affects: [menu-shell, overview-tab, watched-rows, footer, phase-09-verification]

tech-stack:
  added: []
  patterns:
    - Watched row caps and urgency ordering live in core display shaping
    - Overview ordering changes according to whether watched rows need attention
    - Verification distinguishes automated proof from visible menu inspection

key-files:
  created:
    - .planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-04-SUMMARY.md
  modified:
    - KubebarCore/Models/MenuDisplayModel.swift
    - KubebarCore/Services/HealthEvaluator.swift
    - KubebarTests/Models/MenuDisplayModelTests.swift
    - Kubebar/Views/MenuBarRootView.swift
    - Kubebar/Views/OverviewTabView.swift
    - Kubebar/Views/WatchlistSectionView.swift
    - Kubebar/Views/WatchlistPickerView.swift
    - Kubebar/Views/MenuFooterView.swift
    - .planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-04-PLAN.md
    - .planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md
    - .planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-VERIFICATION.md

key-decisions:
  - "Healthy watched rows show up to 3 rows; attention states may show up to 5."
  - "Rows show disclosure only when detail content adds information beyond the row summary."
  - "`Watching` replaces visible `Watchlist` copy in menu and related settings picker heading."
  - "Visible footer text is `Last checked {age}`; cadence remains help/accessibility copy only."

requirements-completed: [REQ-09-01, REQ-09-02, REQ-09-03, REQ-09-07, REQ-09-08, REQ-09-09, REQ-09-10]

duration: 18min
completed: 2026-04-22
---

# Phase 09 Plan 04: Menu Refinement Summary

**Overview now behaves like a glanceable home tab: content height is natural, attention rows come forward, and the footer is simpler.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-22T08:59:00Z
- **Completed:** 2026-04-22T09:17:43Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Updated core watched-row ordering so `Bad`, `Watch`, `Stale`, and `OK` sort by operator urgency.
- Capped healthy watched rows at 3 while allowing up to 5 attention rows with accurate overflow count.
- Added detail-content detection so rows without extra information no longer show disclosure affordances.
- Removed the fixed minimum menu content height, kept the footer outside selected-tab scrolling, and hid scroll indicators where supported.
- Changed Overview order so attention `Watching` rows appear before counters, while healthy states show counters before `Watching`.
- Replaced visible `Watchlist` copy with `Watching`, including the related settings picker heading.
- Simplified footer language to `Last checked {age}` and `Refresh every {cadence}` for timer help/accessibility.
- Refreshed UAT and verification docs with Plan 04 evidence and manual-only visual checks.

## Task Commits

1. **Task 1: Update watched item ranking and caps** - `0d88385` (test), `18dd6c3` (feat)
2. **Task 2: Apply auto-height shell, Watching section, and footer language** - `f2a7679` (feat)
3. **Task 3: Refresh Phase 09 evidence** - included in the Plan 04 documentation completion commit

## Files Created/Modified

- `KubebarCore/Models/MenuDisplayModel.swift` - Added watched detail-content signal.
- `KubebarCore/Services/HealthEvaluator.swift` - Added urgency ordering and healthy/attention watched row caps.
- `KubebarTests/Models/MenuDisplayModelTests.swift` - Added watched priority, cap, hidden count, and detail-content tests.
- `Kubebar/Views/MenuBarRootView.swift` - Removed fixed minimum content height and kept footer outside selected-tab scrolling.
- `Kubebar/Views/OverviewTabView.swift` - Added attention-first or counters-first Overview ordering.
- `Kubebar/Views/WatchlistSectionView.swift` - Changed visible copy to `Watching`, adjusted overflow copy, and made disclosure conditional.
- `Kubebar/Views/WatchlistPickerView.swift` - Changed related heading copy to `Watching`.
- `Kubebar/Views/MenuFooterView.swift` - Simplified freshness and cadence language.
- `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-04-PLAN.md` - Recorded the additional copy file and summary artifact.
- `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md` - Added auto-height/footer rows and refreshed Plan 04 expectations.
- `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-VERIFICATION.md` - Replaced old verification baseline with Plan 04 evidence.
- `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-04-SUMMARY.md` - Recorded execution summary.

## Verification Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter MenuDisplayModelTests` | pass | 31 tests passed. |
| `swift test --filter MenuBarStatusPresentationTests` | pass | 1 test passed. |
| `swift build` | pass | SwiftPM debug build succeeded. |
| `./scripts/swift-quality-gate.sh local` | pass | Xcode build/test and SwiftPM build/test passed; full test run reported 113 tests in 16 suites. |
| `./scripts/compile-and-run.sh` | pass | Built and launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID `46332`; QA state reported `live`. |
| Source guard checks | pass | Found Plan 04 copy/height markers and no old `Watchlist`, `Updated (`, `Refresh cadence:`, or fixed minimum height markers in the checked views. |

## Human-Needed Items

These remain `pending-human-verification` by design:

- Open menu from OK, Watch, Bad, and Stale icons.
- Confirm healthy/common warning menu states avoid unnecessary visible scrollbars.
- Confirm footer stays visible and reads `Last checked {age}`.
- Confirm timer tooltip/accessibility says `Refresh every {cadence}`.
- Switch tabs without refresh.
- Reopen menu resets to Overview.
- Empty `Watching` opens Settings path.
- `Settings...` opens an independent dialog/window.
- `Quit Kubebar` exits and preserves saved config.
- Keyboard navigation reaches tabs, refresh, settings, quit, details, and sections.
- Long names use middle truncation with full help/accessibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Consistency] Updated settings picker heading copy**
- **Found during:** Task 2 source guard.
- **Issue:** `WatchlistPickerView.swift` still contained visible `Watchlist` copy after the opened menu had moved to `Watching`.
- **Fix:** Changed the heading to `Watching` and updated `09-04-PLAN.md` to record the file.
- **Files modified:** `Kubebar/Views/WatchlistPickerView.swift`, `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-04-PLAN.md`
- **Verification:** Negative source check found no remaining `Text("Watchlist")` in `Kubebar/Views`.
- **Committed in:** `f2a7679` for source, Plan 04 documentation completion commit for plan metadata.

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Copy consistency only. No product scope expansion.

## Issues Encountered

- Current automation can launch Kubebar but cannot reliably inspect the opened menu, Settings window, keyboard traversal, footer tooltip/accessibility, or Quit flow. The UAT rows remain pending instead of being overstated as passed.

## Known Stubs

None. Stub scan found no temporary-marker content in Plan 04 source or verification docs.

## Threat Flags

None. This plan did not introduce new network endpoints, auth paths, file access patterns, schema changes, or trust-boundary source code.

## User Setup Required

None.

## Next Phase Readiness

Phase 09 Plan 04 automated verification is complete. Remaining work is human UAT for the visible macOS menu and app-shell flows listed above.

## Self-Check: PASSED

- Summary file exists.
- Created/updated verification files exist: `09-UAT.md`, `09-VERIFICATION.md`, `09-04-SUMMARY.md`.
- Task commits found: `0d88385`, `18dd6c3`, `f2a7679`.
- Focused tests, build, full quality gate, and visible app smoke passed.
- Manual-only rows stay `pending-human-verification`.

---
*Phase: 09-codexbar-inspired-tabbed-menu-redesign*
*Completed: 2026-04-22*
