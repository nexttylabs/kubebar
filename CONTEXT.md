# Kubebar Context

## Canonical Terms

- **Kubebar**: a native macOS menu bar app for glanceable Kubernetes health.
- **Health category**: one of `OK`, `Watch`, `Bad`, or `Stale`; only
  `HealthEvaluator` decides it.
- **Resource usage visualization**: lightweight current-snapshot CPU and memory
  indicators, such as inline progress bars, derived from existing app-owned
  metrics data.
- **Progress value**: an optional `Double` display-model value where `nil`
  means unavailable and numeric values are clamped by the view for rendering.
- **Unavailable resource data**: missing or invalid CPU or memory usage or
  comparison basis; it is shown as unavailable, never as healthy zero.
- **Start at Login setting**: a macOS app setting that controls whether
  Kubebar opens automatically after the user logs in. It is local app behavior,
  not Kubernetes configuration, and it must not affect Health category.
- **Health State Shift Alerts**: optional macOS notifications for true
  directionally worse Health category or watchlist attention changes. They are
  local app behavior, consume `MenuDisplayModel`, and must not add new health
  rules.
- **Per-context watchlist**: a saved set of watch targets keyed by Kubernetes
  context name. Kubebar still has one active selected context at a time, but
  each context may keep its own watchlist for refreshes and Settings editing.
- **Quick Context Selector**: the menu-surface control that switches Kubebar's
  active app-owned selected context. It must use the active context's
  per-context watchlist and must not change the terminal's current context.
- **Release build version**: the app bundle build number (`CFBundleVersion` /
  `CURRENT_PROJECT_VERSION`) used for release artifacts. It must move in sync
  with release publishing and stay distinct from the user-facing marketing
  version (`CFBundleShortVersionString` / `MARKETING_VERSION`).

## Vocabulary Guard

In this repository, "chart" for resource usage means lightweight current-state
visualization inside the menu. It does not mean historical trends, sparklines,
time-series storage, or an external monitoring dashboard unless a future plan
explicitly changes that scope.

## Architecture Map

- Release tooling: `scripts/build-release.sh` owns packaged app version
  metadata, `scripts/test-release-build-version.sh` guards release metadata
  regressions, `project.yml` provides XcodeGen defaults, and
  `docs/RELEASING.md` documents release-owner behavior.
