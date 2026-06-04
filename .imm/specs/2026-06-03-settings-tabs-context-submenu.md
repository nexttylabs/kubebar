---
title: Settings Tabs and Nested Context Menu
date: 2026-06-03
status: planned
origin: user clarification after per-context watchlists implementation
---

# Settings Tabs and Nested Context Menu

## Summary

Kubebar should reshape Settings into tabs where the first tab is fixed app-wide
settings and the remaining tabs are generated from local context information.
The menu Quick Context Selector should move from a standalone top-level row to
a nested menu item for selecting the active app-owned context.

The existing data model remains: one active selected context at a time, with
watchlists saved per context. This work is a Settings/menu interaction refactor,
not a new persistence migration.

## Goals

- Settings shows a fixed first `App Settings` tab.
- `App Settings` contains global app settings: refresh cadence, Start at Login,
  and Health State Shift Alerts.
- Context-specific tabs are generated from local context information rather
  than remote Kubernetes reads.
- Each context tab edits only that context's per-context watchlist.
- Switching context tabs preserves unsaved watchlist edits for other contexts.
- The main menu removes the standalone top-level context selector row.
- The main menu exposes context switching through one nested context submenu.
- The nested context submenu uses local context information and preserves the
  same app-owned context switching behavior.

## Non-Goals

- No `AppConfig` schema migration.
- No new Kubernetes cluster API reads to list contexts.
- No `kubectl config use-context` or terminal current-context mutation.
- No per-context refresh cadence.
- No per-context Start at Login setting.
- No per-context Health State Shift Alerts setting.
- No changes to `HealthEvaluator`.
- No automatic watchlist generation.

## Requirements

- R1. Settings must render `App Settings` as the first tab.
- R2. Settings must render one context tab per local context entry after
  `App Settings`.
- R3. Context list information must come from local machine sources, primarily
  the existing `ContextCatalog`/kubeconfig path, not from cluster APIs.
- R4. Locally saved per-context watchlists must remain preserved even when the
  current local context list changes.
- R5. The `App Settings` tab must not require or change a selected Kubernetes
  context.
- R6. The global settings in `App Settings` must continue saving to the existing
  global config fields.
- R7. Context tabs must reuse the per-context watchlist state and candidate
  loading boundary.
- R8. Long context names in tabs and menus must remain one-line truncated with
  full help/accessibility labels.
- R9. The menu must replace the standalone top-level context selector with one
  nested context submenu.
- R10. Selecting a context from the nested submenu must preserve the existing
  active-context switch behavior: save selected context, clear stale runtime
  state, reject old refresh results, and refresh when configured and network is
  available.
- R11. The menu layout budget must be updated after removing the top-level
  context selector row.
- R12. Runtime invariants and handoff notes must reflect the new Settings tabs
  and nested Quick Context Selector shape.

## Verification Expectations

- Settings/runtime state tests cover `App Settings` as the fixed first tab,
  dynamic context tabs, global settings staying global, and per-context
  watchlist preservation.
- Menu/runtime tests cover the nested submenu context list and active context
  switching behavior.
- Menu layout sizing tests cover the removed top-level context selector budget.
- Visible smoke covers Settings tab reachability and menu submenu reachability.
- `./scripts/swift-quality-gate.sh local` is the preferred full verification.
- If the local Swift/Xcode test runner hangs, or fails before any assertions due
  test-bundle loading, signing, or system-policy denial, record the attempted
  full gate and use focused fallback evidence for the affected step:
  `swift build`, `swift build --target KubebarCoreTests`,
  `rtk git diff --check`, and a visible menu smoke for the nested Quick Context
  Selector. This fallback is not valid if tests run and fail assertions.
