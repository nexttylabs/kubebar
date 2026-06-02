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

## Vocabulary Guard

In this repository, "chart" for resource usage means lightweight current-state
visualization inside the menu. It does not mean historical trends, sparklines,
time-series storage, or an external monitoring dashboard unless a future plan
explicitly changes that scope.
