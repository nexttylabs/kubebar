---
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
plan: "02"
subsystem: ui
tags: [swift, macos, menu-bar, accessibility, keyboard, truncation, watchlist]

requires:
  - phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
    provides: core status reason and full watch target title contracts from Plan 01
provides:
  - Opened-menu status summary with symbol, state text, and one primary reason
  - One-line middle truncation plus full help and accessibility fallback for long menu names
  - Native keyboard shortcuts for refresh, edit watchlist, retry target loading, and setup completion
affects: [menu-bar-status, watchlist-rows, setup-flow, warning-events, keyboard-navigation]

tech-stack:
  added: []
  patterns:
    - SwiftUI views render MenuDisplayModel without deciding health
    - Full app-owned names stay in display data while views apply middle truncation
    - Keyboard reachability uses native Button, Picker, Toggle, and DisclosureGroup controls

key-files:
  created:
    - .planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-02-SUMMARY.md
  modified:
    - Kubebar/Views/StatusSummaryView.swift
    - Kubebar/Views/MenuBarRootView.swift
    - Kubebar/Views/WatchlistSectionView.swift
    - Kubebar/Views/TrackedItemDetailView.swift
    - Kubebar/Views/WarningEventsView.swift
    - Kubebar/Views/SetupView.swift
    - Kubebar/Views/WatchlistPickerView.swift

key-decisions:
  - "Kept the MenuBarExtra.window shell and watchlist-first menu order unchanged."
  - "Used view-level middle truncation with help and accessibility text instead of changing core display strings."
  - "Added standard SwiftUI keyboard shortcuts only, with no custom key handlers or AppKit menu rewrite."

patterns-established:
  - "Opened status summary: state symbol, exact state label, and MenuDisplayModel.primaryStatusReason explain the menu bar signal."
  - "Long-name rendering: lineLimit(1), truncationMode(.middle), help(Text(fullValue)), and accessibilityLabel(fullValue)."
  - "Action reachability: Retry now uses Command-R, Edit watchlist uses Command-E, Finish setup uses the default action."

requirements-completed: [R13, R18, R19, R20, R21]

duration: 4 min
completed: 2026-04-21
---

# Phase 06 Plan 02: Menu Readability and Keyboard Polish Summary

**Opened menu status, long-name fallbacks, and native keyboard shortcuts now make the menu readable without expanding scope.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-21T16:06:24Z
- **Completed:** 2026-04-21T16:10:33Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- The opened menu now explains the compressed menu bar signal with a status symbol, exact state text, and one primary reason.
- Long context, namespace, workload, warning, and detail names stay one-line with middle truncation while preserving full values for hover help and accessibility.
- Refresh, edit watchlist, setup completion, retry target loading, and detail disclosure remain native keyboard-reachable controls.

## Task Commits

Each task was committed atomically:

1. **Task 1: Render explicit opened-menu status summary** - `2b3505c` (feat)
2. **Task 2: Apply middle truncation and full-name fallbacks** - `1cbb00e` (feat)
3. **Task 3: Add native keyboard affordances without changing scope** - `fb15ba6` (feat)

## Files Created/Modified

- `Kubebar/Views/StatusSummaryView.swift` - Renders the opened-menu state symbol, state text, primary reason, and full context fallback.
- `Kubebar/Views/MenuBarRootView.swift` - Preserves menu order and adds native refresh/edit shortcuts with help text.
- `Kubebar/Views/WatchlistSectionView.swift` - Keeps watchlist rows behind DisclosureGroup and applies full-title fallback to row titles.
- `Kubebar/Views/TrackedItemDetailView.swift` - Adds full help and accessibility fallback for example pods, latest warning summary, and warning messages.
- `Kubebar/Views/WarningEventsView.swift` - Adds one-line middle truncation and full fallback for warning summaries, notices, and messages.
- `Kubebar/Views/SetupView.swift` - Keeps native setup controls and adds context-name fallback plus default setup action.
- `Kubebar/Views/WatchlistPickerView.swift` - Keeps native toggles/disclosures and adds full fallback plus retry shortcuts.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-02-SUMMARY.md` - Records plan execution.

## Decisions Made

- Kept `MenuBarExtra.window`, the 340-point menu width, and the existing order: summary, stale signal, counters, watchlist, warning events, node details, refresh, and actions.
- Kept all health meaning in `MenuDisplayModel` and only rendered `primaryStatusReason` in SwiftUI.
- Used standard SwiftUI controls and shortcuts instead of custom key events or AppKit bridges.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `./scripts/swift-quality-gate.sh local` printed the existing CoreSimulator version warning, but the macOS Xcode build/test and SwiftPM build/test completed successfully.
- `gsd-sdk`, `.planning/STATE.md`, and `.planning/ROADMAP.md` were unavailable in this worktree. Per user instruction, no STATE or ROADMAP files were created or updated.

## Verification

- `swift build` - passed.
- `swift test --filter MenuDisplayModelTests` - passed, 18 tests.
- `rg -n "primaryStatusReason|truncationMode\\(\\.middle\\)|help\\(Text\\(|keyboardShortcut" Kubebar/Views` - found the Phase 06 rendering and keyboard affordances.
- Negative grep for `NSStatusItem|NSMenu|Open in k9s|notarization|distribution|dashboard|raw kubectl|JSONDecoder` in `Kubebar/Views` - passed.
- `./scripts/swift-quality-gate.sh local` - passed, including Xcode build/test and SwiftPM build/test with 86 Swift tests.

## Known Stubs

None. Stub-pattern scan only found existing default no-op callback closures in view initializers; those are intentional preview/test defaults, not UI data stubs.

## Threat Flags

None. This plan only changed SwiftUI rendering and native shortcuts; it added no new network endpoints, auth paths, file access, subprocess boundaries, or schema changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 06 Plan 03. The SwiftUI menu now consumes the Plan 01 display contract directly, keeps watchlist-first order, preserves full names for assistive use, and uses native controls for keyboard reachability.

---
*Phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation*
*Completed: 2026-04-21*

## Self-Check: PASSED

- Summary file exists.
- Task commits found: `2b3505c`, `1cbb00e`, `fb15ba6`.
- Key modified files exist.
- No unexpected tracked file deletions were found in task commits.
