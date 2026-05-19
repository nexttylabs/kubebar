---
module: app-settings
tags:
  - macos
  - settings
  - service-management
  - dependency-injection
problem_type: native-app-setting
reusability: medium
key_files:
  - Kubebar/Services/LoginItemController.swift
  - KubebarCore/Services/StartAtLoginSettingsCoordinator.swift
  - KubebarCore/Models/StartAtLoginState.swift
  - Kubebar/Views/SetupView.swift
  - KubebarTests/Services/StartAtLoginSettingsCoordinatorTests.swift
next_reuse_scenarios:
  - Adding another macOS-only app setting that mutates system state.
  - Testing native system integration without mutating the user's machine.
  - Keeping local app behavior separate from Kubernetes health and config.
---

# Start at Login Boundary

## Problem

Kubebar needed a Settings toggle for opening automatically after macOS login.
The setting mutates local macOS state, but the rest of Settings already owns
Kubernetes context, watchlist, and refresh cadence. Mixing the system call into
the view or persisted app config would make tests mutate the user's login items
or make local app behavior look like cluster configuration.

## Solution

Keep the production system call in the app target and keep the state transition
testable in `KubebarCore`.

- `SystemStartAtLoginController` wraps `SMAppService.mainApp`.
- `StartAtLoginSettingsCoordinator` depends on `StartAtLoginControlling` and
  returns display-ready `StartAtLoginState`.
- `MenuBarViewModel` refreshes Start at Login status when Settings opens and
  applies toggle changes through the coordinator.
- `SetupView` renders a native `Toggle` from `SetupFlowState.startAtLogin`.
- `AppConfigStore` remains focused on Kubernetes context, watchlist, and
  refresh cadence.

## Evidence

- Fake-controller tests cover current status, enable, disable, and failed
  update rollback.
- Runtime state tests confirm Start at Login does not affect completed cluster
  config.
- `swift-quality-gate.sh local` passed.
- `compile-and-run.sh` launched the app in `setup` QA state, opened Settings,
  and the accessibility tree exposed the Start at Login toggle.

## Reuse Notes

Use this shape for native macOS app settings that have side effects outside
Kubebar's Kubernetes model. Put platform APIs behind an injectable app-target
boundary, return plain value state to views, and keep `AppConfig` limited to
cluster-owned settings unless the setting must be persisted by Kubebar itself.
