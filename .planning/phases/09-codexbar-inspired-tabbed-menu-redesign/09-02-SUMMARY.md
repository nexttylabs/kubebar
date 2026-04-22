---
phase: 09-codexbar-inspired-tabbed-menu-redesign
plan: "02"
subsystem: ui
tags: [swiftui, macos, menu-bar, settings, quit, testing]

requires:
  - phase: 09-codexbar-inspired-tabbed-menu-redesign
    provides: Plan 01 tabbed menu foundation and fixed Overview/Nodes/Pods/Events shell
provides:
  - Independent SwiftUI Settings surface for local Kubebar configuration
  - Menu footer actions for Retry now, Settings..., and Quit Kubebar
  - Compact first-use/recovery prompt that routes users to Settings
  - Focused tests for Settings copy and prepareSettings runtime behavior
affects: [09-03, menu-ui, settings, app-actions]

tech-stack:
  added: []
  patterns:
    - SwiftUI Settings scene backed by the existing setup/save flow
    - Menu footer actions isolated in a small SwiftUI view
    - Settings preparation that loads candidates without changing menu surface

key-files:
  created:
    - Kubebar/Views/SettingsRootView.swift
    - Kubebar/Views/MenuFooterView.swift
    - Kubebar/Views/ConfigurationRequiredView.swift
  modified:
    - Kubebar.xcodeproj/project.pbxproj
    - Kubebar/KubebarApp.swift
    - Kubebar/MenuBarViewModel.swift
    - Kubebar/Views/MenuBarRootView.swift
    - Kubebar/Views/SetupView.swift
    - KubebarCore/Models/MenuRuntimeState.swift
    - KubebarCore/Models/SetupFlowState.swift
    - KubebarTests/Models/MenuRuntimeStateTests.swift
    - KubebarTests/Models/SetupFlowStateTests.swift

key-decisions:
  - "Use SwiftUI Settings for the independent local configuration surface."
  - "Keep first-use and recovery in the opened menu as a compact prompt instead of the full setup form."
  - "Wire Quit Kubebar only to NSApplication.shared.terminate(nil)."

patterns-established:
  - "Menu settings actions call prepareSettings before opening Settings."
  - "prepareSettings rebuilds setup state from AppConfig without opening setup, saving config, or refreshing Kubernetes state."
  - "The opened menu footer owns visible app actions and keeps Quit non-destructive."

requirements-completed: [REQ-09-02, REQ-09-07, REQ-09-08, REQ-09-09, REQ-09-10]

duration: 6min
completed: 2026-04-22
---

# Phase 09 Plan 02: Settings and App Actions Summary

**Independent Settings configuration plus visible Settings and Quit actions in the opened Kubebar menu.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-22T06:56:53Z
- **Completed:** 2026-04-22T07:03:20Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added a SwiftUI `Settings` scene that reuses the existing context, watchlist, refresh cadence, retry, and save controls.
- Added `prepareSettings()` so opening Settings loads contexts and watch targets without changing the opened menu into setup mode.
- Replaced the old menu setup/edit path with a compact `Settings...` prompt when configuration is missing.
- Added visible footer actions for `Retry now`, `Settings...`, and `Quit Kubebar`, with native shortcuts.
- Verified Quit is wired only to standard app termination and does not touch config mutation paths.

## Task Commits

1. **Task 1 RED: Add failing tests for Settings preparation** - `2c77465` (test)
2. **Task 1 GREEN: Add independent Settings preparation** - `6962ae8` (feat)
3. **Task 2: Add visible Settings and Quit menu actions** - `c9c919f` (feat)
4. **Task 3: Validate Settings and Quit scope** - `9cd01d3` (test)

## Files Created/Modified

- `Kubebar/Views/SettingsRootView.swift` - Independent Settings wrapper around `SetupView`.
- `Kubebar/Views/MenuFooterView.swift` - Footer controls for refresh cadence, retry, Settings, and Quit.
- `Kubebar/Views/ConfigurationRequiredView.swift` - Compact first-use/recovery prompt that routes to Settings.
- `Kubebar/KubebarApp.swift` - Settings scene and Quit wiring through `NSApplication.shared.terminate(nil)`.
- `Kubebar/MenuBarViewModel.swift` - `prepareSettings()` and updated settings save-failure copy.
- `Kubebar/Views/MenuBarRootView.swift` - Removes embedded setup body and uses footer/action components.
- `Kubebar/Views/SetupView.swift` - Adds configurable primary action title.
- `KubebarCore/Models/MenuRuntimeState.swift` - Adds Settings preparation state transition.
- `KubebarCore/Models/SetupFlowState.swift` - Adds Settings action copy and save failure copy.
- `KubebarTests/Models/MenuRuntimeStateTests.swift` - Covers `prepareSettings` preservation and no menu surface switch.
- `KubebarTests/Models/SetupFlowStateTests.swift` - Covers `Save Settings`, `Finish setup`, and save failure copy.
- `Kubebar.xcodeproj/project.pbxproj` - Regenerated from `project.yml` so Xcode includes new view files.

## Decisions Made

- Used SwiftUI `Settings` rather than adding Settings as a menu tab, matching the approved UI contract.
- Kept configuration persistence unchanged: Settings saves only the existing `AppConfig` fields through the existing save flow.
- Kept visible-app Settings/Quit UAT for Plan 03 because this repo has no reliable automated menu-bar traversal target.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodegen generate` was required after adding Swift files so the Xcode project includes the new Settings/footer views.
- A source check caught the old `if isShowingSetup` branch shape in `MenuBarRootView`; it was changed to a compact prompt switch before commit.
- Xcode emitted a non-blocking AppIntents metadata warning during the quality gate; the gate passed.

## Verification

- `swift test --filter SetupFlowStateTests` - passed
- `swift test --filter MenuRuntimeStateTests` - passed
- `swift build` - passed
- Required label/source checks for `Settings...`, `Quit Kubebar`, `Save Settings`, `prepareSettings()`, and `ConfigurationRequiredView` - passed
- Source check for removed `Edit watchlist` - passed
- Source check for no `SetupView` in `MenuBarRootView` - passed
- Source check for Quit not calling save/setup/cadence/runtime mutation paths - passed
- Out-of-scope source guard for dashboard/provider/account/cloud/raw-output concepts - passed
- `./scripts/swift-quality-gate.sh local` - passed, including Xcode build/test and SwiftPM build/test

## Known Stubs

None. Stub scan found only optional/default initializer values and expected nil resets in state management.

## Threat Flags

None. New Settings and Quit surfaces are covered by the plan threat model and verified by source checks.

## User Setup Required

None.

## Next Phase Readiness

Plan 03 can perform visible-app UAT for Settings opening independently, Quit preserving saved config, keyboard reachability, and long-name behavior.

## Self-Check: PASSED

- Summary file exists.
- New Settings, footer, and configuration prompt files exist.
- Task commits found: `2c77465`, `6962ae8`, `c9c919f`, `9cd01d3`.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/config.json` were not modified.

---
*Phase: 09-codexbar-inspired-tabbed-menu-redesign*
*Completed: 2026-04-22*
