# macOS UI Pattern Polish

## User Request

Reference macOS design patterns and Liquid Glass guidance to adjust Kubebar's
menu and Settings user interface.

## Product Intent

Kubebar remains a glanceable macOS menu-bar utility. The UI should use native
desktop controls and adaptive system surfaces rather than custom heavy chrome.

## Requirements

- Settings uses native tab structure with `App Settings` first and context tabs
  generated from local/saved context information.
- App-wide Settings content uses preference-style sections for refresh cadence,
  launch behavior, and health shift alerts.
- Context Settings content keeps watchlist editing scoped to the selected
  context and uses standard grouped surfaces.
- Menu footer actions read as a compact native toolbar group while preserving
  the nested quick context selector, refresh, settings, and quit actions.
- No business logic, health evaluation, persistence, or Kubernetes command
  behavior changes.

## Verification

- `swift test --filter SetupFlowStateTests`
- `swift test --filter MenuRuntimeStateTests`
- `swift test --filter MenuLayoutSizingTests`
- `rtk git diff --check`
- Accessibility smoke for Settings with local `dev` and `prod` contexts:
  context tab -> App Settings tab still exposes refresh cadence, Start at Login,
  and Health State Shift Alerts.

## Non-Goals

- No new primary app window.
- No screenshot-based evidence requirement.
- No macOS 26-only `glassEffect` adoption while deployment target remains
  macOS 14.
