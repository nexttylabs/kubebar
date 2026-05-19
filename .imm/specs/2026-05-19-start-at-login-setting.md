---
title: Start at Login setting
date: 2026-05-19
status: planned
origin: user /prep request
---

# Start at Login Setting

## Summary

Kubebar should expose a Settings control for opening the app automatically when
the macOS user logs in. The setting is local app behavior and must stay
separate from Kubernetes context, watchlist, refresh cadence, and Health
category evaluation.

The smallest useful version is a visible Settings toggle backed by macOS
ServiceManagement login item registration, with recoverable failure feedback
when the system setting cannot be changed.

## Goals

- Settings shows a clear `Start at Login` toggle.
- The toggle reflects the current macOS login item status when Settings opens.
- Changing the toggle updates the system login item registration.
- Failed system updates leave the UI in the actual current state and show a
  short recoverable message.
- The setting remains independent from cluster setup completion.

## Non-Goals

- No new Kubernetes reads.
- No changes to `OK`, `Watch`, `Bad`, or `Stale` evaluation.
- No login helper app, daemon, LaunchAgent file, or background service.
- No change to selected context, watchlist, refresh cadence, or cluster config
  persistence.
- No deep troubleshooting UI for macOS login item failures.

## Requirements

- R1. `Start at Login` must be available from Settings for both first setup and
  existing configuration editing.
- R2. The displayed toggle state must be derived from the login item boundary,
  not guessed from Kubernetes configuration.
- R3. Turning the setting on must register Kubebar with the system login item
  API.
- R4. Turning the setting off must unregister Kubebar from the system login item
  API.
- R5. System API access must sit behind an injectable boundary so Settings
  behavior can be tested without mutating the user's login items.
- R6. A failed update must not leave the toggle showing a state that was not
  actually applied.
- R7. The setting must not be required to finish setup or save cluster
  settings.
- R8. The setting must not change refresh loops, stale data handling, or Health
  category decisions.
- R9. The Settings layout must keep existing context, watchlist, cadence, and
  save controls reachable.
- R10. The control must have native SwiftUI accessibility semantics.

## Verification Expectations

- Focused unit tests cover status reflection, successful enable/disable, and
  failed update rollback through a fake login item boundary.
- Existing config/runtime tests continue to prove Kubernetes setup state is
  unaffected by non-cluster settings.
- `./scripts/swift-quality-gate.sh local` passes.
- A visible Settings smoke check confirms the toggle appears and remains
  reachable in the Settings window.
