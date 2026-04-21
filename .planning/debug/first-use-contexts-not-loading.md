# First-Use Contexts Not Loading

## Symptom

During Phase 03 UAT, the setup window opened but the user could only see the
`Cluster context` and `Watchlist` sections. The first-use flow did not progress
to usable context selection and target loading.

## Evidence

- `MenuBarViewModel` set `isShowingSetup = config.needsSetup` during startup.
- `loadContexts()` was only called by `openSetup()`.
- First launch does not call `openSetup()`; it starts directly in setup mode.
- The local environment has a `kubectl` context named `default`, so an empty
  context list was not explained by missing local cluster configuration.

## Root Cause

The first-use setup path displayed setup without starting context discovery.
Context discovery only ran when a user opened setup from the already-configured
menu via `Edit watchlist`.

## Fix

When startup detects that setup is needed, `MenuBarViewModel` now immediately
loads contexts. If a partially saved config already has a selected context, it
also loads watch targets for that context.

## Verification

- `./scripts/swift-quality-gate.sh local` passed.
- The local `kubectl config get-contexts -o name` command returned `default`.
- The rebuilt app was relaunched from
  `DerivedData/Build/Products/Debug/Kubebar.app`.

## Remaining Manual Check

Retest the first Phase 03 UAT checkpoint:

1. Open Kubebar from the menu bar.
2. Confirm the context picker offers the local context.
3. Select the context and confirm watch targets load.
