---
title: Settings App Tab Selection Regression
date: 2026-06-03
status: planned
origin: user-reported regression after Settings tab refactor
---

# Settings App Tab Selection Regression

## Summary

Kubebar Settings must let users switch from any generated Context Settings tab
back to the fixed App Settings tab. The regression is visible when the local
context count is 2, so it affects the segmented Settings tab selector and is
not limited to the overflow menu-style selector.

This is a Settings tab selection bugfix. It should keep the existing
per-context watchlist model, app-owned active context, and saved config schema.

## Goals

- Selecting `App Settings` from a Context Settings tab updates the tab
  selection immediately.
- The fixed `App Settings` tab remains first and shows only app-wide controls.
- Switching tabs preserves unsaved per-context watchlist edits.
- The fix covers the segmented selector path used when there are 2 contexts.
- The fix does not regress the menu-style selector path used with more
  contexts.

## Non-Goals

- No `AppConfig` schema changes.
- No changes to Quick Context Selector behavior.
- No new context discovery behavior.
- No changes to `HealthEvaluator`.
- No per-context app-wide settings.

## Requirements

- R1. `App Settings` must be selectable from any Context Settings tab.
- R2. With 2 local contexts, the segmented Settings tab selector must respond
  when `App Settings` is selected.
- R3. Tab switching must preserve each context's watchlist independently.
- R4. The implementation must avoid relying on fragile SwiftUI Picker tags for
  associated-value enum selections when a stable tab ID is available.
- R5. State changes must continue flowing through `MenuRuntimeState` /
  `MenuBarViewModel` so Settings updates publish consistently.
- R6. Context tabs must remain generated from local context information plus
  saved context watchlists.

## Verification Expectations

- Focused state tests cover selecting a context tab, editing that watchlist,
  switching back to `App Settings`, and preserving both the tab selection and
  watchlist state.
- Runtime tests cover the ViewModel/runtime action that switches to
  `App Settings`.
- A visible Settings smoke uses 2 contexts and confirms the segmented selector
  switches from a Context Settings tab back to `App Settings`.
- Preferred full verification remains `./scripts/swift-quality-gate.sh local`
  after the focused fix passes.
