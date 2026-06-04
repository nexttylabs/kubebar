---
module: architecture
tags:
  - kubebar
  - context-switching
  - watchlist
  - settings
  - menu
problem_type: context-state-ownership
reusability: medium
key_files:
  - KubebarCore/Services/AppConfigStore.swift
  - KubebarCore/Models/SetupFlowState.swift
  - KubebarCore/Models/MenuRuntimeState.swift
  - Kubebar/MenuBarViewModel.swift
  - Kubebar/Views/SetupView.swift
  - Kubebar/Views/MenuBarRootView.swift
  - docs/architecture/runtime-invariants.md
  - KubebarTests/Models/AppConfigTests.swift
  - KubebarTests/Models/MenuRuntimeStateTests.swift
  - KubebarTests/Services/RefreshCoordinatorTests.swift
next_reuse_scenarios:
  - Adding another menu or settings selector that switches between saved scopes.
  - Preserving per-context or per-tenant state while one active scope drives refresh.
  - Reviewing whether a context switch should invalidate stale runtime state before refresh.
---

# Per-Context Watchlists Need an App-Owned Active Context

## Problem

Kubebar needed to let users keep a separate watchlist for each Kubernetes
context, then switch the active context from the menu without showing stale or
wrong cluster state. The hard part was keeping the app-owned selected context as
the source of truth while still preserving saved watchlists for contexts that
are not currently active.

## Solution

Treat the active context as app-owned state, and store watchlists in a context
keyed map.

- `AppConfig` stores `watchlistsByContext` and exposes `watchTargets` as the
  active selected context's watchlist only.
- Settings and the menu context selector use context entries reported by the
  local kubeconfig context list. Saved watchlists for missing contexts remain in
  local config, but those missing contexts are not displayed as selectable
  context entries.
- `SetupFlowState` preserves each context's watchlist independently while the
  user edits a different tab.
- `MenuBarViewModel` owns the menu selector flow: save the new active context,
  clear stale runtime state, reject old refresh results, and refresh only when
  the new context is configured.
- `MenuBarRootView` surfaces the Quick Context Selector near the top of the
  menu and keeps long context names one-line truncated with full help text.
- A selected context with no saved watchlist is configuration-required, not a
  healthy cluster.

## Evidence

- U1 tests cover compatible config migration and active-watchlist lookup.
- U2 tests cover context tabs, per-context Settings edits, and preserved saved
  selections.
- U3 tests cover menu context switching, stale-state invalidation, and
  selection of unconfigured contexts.
- `./scripts/swift-quality-gate.sh local` passed with 240 tests in 28 suites.
- `rtk git diff --check` passed.

## Reuse Notes

Use this pattern whenever the UI needs to switch among saved scopes while only
one scope is active at a time. Keep the active scope app-owned, persist other
scopes in a keyed map, and invalidate stale runtime state before the next
refresh so old data never looks current.

## Reusability Critique

- Falsifiability: this lesson stops being useful if Kubebar no longer uses one
  active context at a time, or if per-context storage moves outside the app's
  local config boundary.
- Evidence trail: the guidance is supported by U1-U3 tests, the runtime
  invariants update, and the full quality gate. It is not a broad claim about
  all Kubernetes UIs.
- Architecture entropy resistance: this belongs in `docs/solutions/` because
  it captures a reusable ownership pattern, not a permanent architecture
  decision or a rejected alternative that needs ADR treatment.
