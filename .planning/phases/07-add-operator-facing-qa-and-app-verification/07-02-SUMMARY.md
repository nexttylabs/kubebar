---
phase: 07-add-operator-facing-qa-and-app-verification
plan: "02"
subsystem: qa
tags: [swiftui, macos, menubarextra, qa-launch]

requires:
  - phase: 07-add-operator-facing-qa-and-app-verification
    provides: MenuStateFixtureCatalog and MenuStateFixture
provides:
  - Debug-only launch argument and environment selection for QA states
  - Real MenuBarExtra rendering path for selected fixtures
  - Visible app smoke script support for QA state launch evidence
affects: [07-04, visible-smoke, operator-verification]

tech-stack:
  added: []
  patterns:
    - Debug-only QA adapter outside production menu controls
    - One real menu shell with fixture or live data selected at app launch

key-files:
  created:
    - Kubebar/QA/QALaunchMode.swift
  modified:
    - Kubebar/KubebarApp.swift
    - scripts/compile-and-run.sh
    - Kubebar.xcodeproj/project.pbxproj

key-decisions:
  - "Accept `--kubebar-qa-state` first, then `KUBEBAR_QA_STATE`."
  - "Expose `--qa-state` only through the local smoke script, not as a menu control."
  - "Keep the menu-bar icon label driven by the selected fixture state."

patterns-established:
  - "QA launch state is read once at app startup."
  - "Visible smoke output records app path, PID, running state, and selected QA state."

requirements-completed: [D-02, D-05, D-06, D-07, D-08, D-09, D-11, D-13]

duration: 10min
completed: 2026-04-22
---

# Phase 07 Plan 02: QA Launch Mode Summary

**Debug builds can launch any required fixture through the real Kubebar menu shell while production menus stay free of QA controls.**

## Accomplishments

- Added `QALaunchMode` for `--kubebar-qa-state` and `KUBEBAR_QA_STATE`.
- Updated `KubebarApp` so selected fixtures render through the same `MenuBarExtra.window` shell.
- Extended `scripts/compile-and-run.sh` with `--qa-state` and visible smoke evidence output.

## Task Commits

1. **QA launch mode and smoke script support** - `e5f2f60` (feat)

## Files Created/Modified

- `Kubebar/QA/QALaunchMode.swift` - Debug-only fixture selection from launch input.
- `Kubebar/KubebarApp.swift` - Fixture-aware real menu shell and menu-bar status label.
- `scripts/compile-and-run.sh` - Optional QA state launch and evidence output.
- `Kubebar.xcodeproj/project.pbxproj` - Regenerated for Xcode source membership.

## Decisions Made

- Kept a single `MenuBarExtra` scene and switched only the rendered root view, matching SwiftUI `SceneBuilder` constraints.
- Adapted the plan to the current `MenuBarRootView` API, which no longer takes a setup-state binding.

## Deviations from Plan

### Auto-fixed Issues

**1. SwiftUI SceneBuilder rejected optional scene branching**
- **Found during:** `swift test --filter MenuStateFixtureCatalogTests`
- **Issue:** Conditional `if let` scene construction failed to compile.
- **Fix:** Kept one `MenuBarExtra` scene and moved QA/live switching into a `ViewBuilder`.
- **Verification:** Focused tests, full quality gate, and smoke launch all passed.
- **Committed in:** `e5f2f60`

## Verification

- `swift test --filter MenuStateFixtureCatalogTests` - passed.
- `./scripts/swift-quality-gate.sh local` - passed.
- `./scripts/compile-and-run.sh --qa-state healthy` - passed; launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID `13624`.

## User Setup Required

None.

## Next Phase Readiness

Plan 07-03 can generate repeatable evidence rows that reference the QA state launch commands.

---
*Phase: 07-add-operator-facing-qa-and-app-verification*
*Completed: 2026-04-22*
