---
title: Per-context Watchlists and Quick Context Selector
date: 2026-06-03
status: planned
origin: user brainstorm plus per-context Settings clarification
---

# Per-context Watchlists and Quick Context Selector

## Summary

Kubebar should let the user configure a separate watchlist for each Kubernetes
context in Settings, then switch the active app-owned selected context directly
from the menu. The menu switch must use the newly active context's saved
watchlist, clear stale runtime state from the previous context, and refresh the
new context without depending on the terminal's current Kubernetes context.

The smallest useful version keeps refresh cadence, Start at Login setting, and
Health State Shift Alerts global. It changes only the Kubernetes context and
watchlist ownership model, Settings editing surface, and menu context selector.

## Goals

- Persist watchlists keyed by Kubernetes context name.
- Keep one active selected context at a time.
- Load old single-watchlist config files without losing the saved watchlist.
- Settings shows context tabs so each context's watchlist can be edited
  separately.
- Settings tabs include contexts returned by kubectl and contexts already saved
  in local config.
- Saving Settings preserves watchlists for contexts that are not currently
  active.
- The menu shows the active context as an independent Quick Context Selector.
- Selecting a different context from the menu saves it as the active context,
  uses that context's watchlist, clears old snapshot/freshness/handoff state,
  and triggers a refresh when network is available.
- A context with no saved watchlist is shown as needing configuration, not as a
  healthy cluster.

## Non-Goals

- No automatic watchlist generation.
- No per-context refresh cadence.
- No per-context Start at Login setting.
- No per-context Health State Shift Alerts setting.
- No changes to `HealthEvaluator` health rules.
- No terminal current-context mutation.
- No new Kubernetes reads beyond context listing, setup candidate discovery,
  and the existing refresh reads.
- No deep troubleshooting or k9s handoff behavior changes.

## Requirements

- R1. `AppConfig` must persist a per-context watchlist map keyed by context
  name while keeping one active `selectedContext`.
- R2. Existing config files with top-level `watchTargets` must decode
  successfully and migrate those targets under the decoded `selectedContext`.
- R3. Missing or empty watchlist for the active context must make the active
  configuration incomplete and show a setup/configuration-required state.
- R4. Existing code that asks for the active watch targets must receive only
  the active context's saved watchlist.
- R5. Saving Settings must preserve watchlists for contexts other than the
  currently edited tab.
- R6. Settings must expose context tabs using the union of available kubectl
  contexts and saved per-context watchlist keys.
- R7. Selecting a Settings context tab must load setup candidates for that
  context through the existing app-owned context boundary.
- R8. Candidate loading failure for one context must preserve that context's
  saved watchlist and must not erase other contexts' watchlists.
- R9. Settings remains keyboard reachable through native SwiftUI controls.
- R10. The menu must show the active context as a separate Quick Context
  Selector near the top status surface.
- R11. The Quick Context Selector must list available kubectl contexts plus
  saved contexts that have local watchlist config.
- R12. Selecting a different menu context must save the new active selected
  context without changing the terminal's current context.
- R13. Context switching from the menu must invalidate in-flight refreshes,
  clear old snapshots/freshness/k9s handoff/alert baseline state, and start the
  new context from a safe waiting or setup-required display.
- R14. Context switching from the menu must trigger a refresh when the new
  active context has a watchlist and network is available.
- R15. Long context names must remain one-line middle-truncated in the menu and
  Settings while preserving full names in help and accessibility labels.
- R16. Health category decisions must remain owned by `HealthEvaluator`; the
  selector and Settings views must not infer cluster health directly.
- R17. Runtime invariants and docs must be updated to describe per-context
  watchlists and Quick Context Selector behavior.

## Verification Expectations

- Config tests cover missing config, old single-watchlist decoding, new
  per-context round trip, active watch target lookup, incomplete active context
  with no watchlist, and preservation of global settings.
- Runtime state tests cover opening Settings with multiple saved contexts,
  switching Settings tabs, preserving per-context watchlists, candidate success
  and failure per context, and completing config from the active tab.
- Refresh or view-model tests cover menu context switching clearing old
  snapshots, rejecting old in-flight refresh results, using the target
  context's watchlist, and showing configuration-required state when no
  watchlist exists.
- View tests or visible smoke cover Settings context tabs and the menu Quick
  Context Selector for reachability and label behavior.
- `./scripts/swift-quality-gate.sh local` passes.

