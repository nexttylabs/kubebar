---
title: Explicit Kubeconfig Path List
date: 2026-06-04
status: planned
origin: user confirmed App Settings should configure kubeconfig paths explicitly
---

# Explicit Kubeconfig Path List

## Summary

Kubebar should let users configure a global kubeconfig file list in App
Settings. When the list is empty, Kubebar keeps the current automatic detection
behavior: inherited `KUBECONFIG` first, then login-shell lookup. When the list
has one or more files, Kubebar builds the effective `KUBECONFIG` value from
that app-owned list and uses it for all `kubectl` reads.

Kubebar still delegates kubeconfig merging to `kubectl`. The app stores paths,
not parsed kubeconfig contents, and still uses the app-owned selected context
with explicit `--context` for cluster reads.

## Goals

- Add a persisted, app-owned kubeconfig path list to App Settings.
- Let users add kubeconfig files through a native file picker.
- Let users remove and reorder configured kubeconfig paths.
- Use explicit configured paths for context discovery, watch target discovery,
  and cluster refreshes.
- Preserve automatic environment detection when no explicit paths are saved.
- Keep saved per-context watchlists even when a context is missing from the
  current effective kubeconfig list.
- Keep kubeconfig contents, tokens, and raw command transcripts out of UI and
  logs.

## Non-Goals

- No custom kubeconfig YAML parser or merger.
- No kubeconfig file content editor.
- No `kubectl config use-context` or terminal current-context mutation.
- No automatic file watching for kubeconfig changes.
- No advanced validation beyond enough user feedback to distinguish an empty
  list, a failed context load, and a saved explicit path list.
- No Windows path-list delimiter support.

## Requirements

- R1. `AppConfig` must persist an ordered `[String]` of explicit kubeconfig
  file paths and load older configs as an empty list.
- R2. Empty explicit path list means automatic detection remains enabled.
- R3. Non-empty explicit path list takes precedence over inherited or shell
  `KUBECONFIG`.
- R4. The effective `KUBECONFIG` value for explicit paths must join paths with
  `:` on Linux/macOS and pass that value unchanged to `kubectl`.
- R5. `ContextCatalog`, `WatchTargetCatalog`, and `KubectlClusterReader` must
  use the same app-owned effective kubeconfig source.
- R6. Settings must expose kubeconfig paths in the fixed App Settings tab, not
  per-context tabs.
- R7. Settings must support adding files through a native file picker, removing
  paths, and reordering paths.
- R8. Changing and saving the explicit path list must refresh local context
  discovery and must not display contexts that are no longer present in the
  effective kubeconfig list.
- R9. Saved watchlists for missing contexts must remain in local config.
- R10. Cluster reads must continue using explicit `--context` for the app-owned
  selected context.
- R11. Failure messages must remain safe and must not expose kubeconfig file
  contents, tokens, raw JSON, or command transcripts.

## Verification Expectations

- App config tests prove old configs load with an empty explicit path list and
  new configs round-trip ordered paths.
- Runtime state tests prove Settings preserves, edits, and completes config
  with kubeconfig paths without losing per-context watchlists.
- Command environment tests prove explicit paths override automatic detection,
  join with `:`, and keep empty-list fallback behavior.
- Catalog and reader tests prove all kubectl-backed reads receive the same
  app-owned environment.
- Settings UI smoke verification proves App Settings exposes add, remove, and
  reorder controls and uses a native file picker entry point.
- Full quality gate remains the preferred final verification.
