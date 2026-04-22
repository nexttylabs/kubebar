# System Overview

Kubebar is split into a thin macOS menu bar shell and a small core that owns
the product rules.

## Top-Level Flow

1. `Kubebar/KubebarApp.swift` starts the app as a menu bar utility.
2. The app loads the current display state and passes it to
   `Kubebar/Views/MenuBarRootView.swift`.
3. `KubebarCore/Services/RefreshCoordinator.swift` owns refresh timing and
   decides whether the app can read fresh cluster data.
4. `KubebarCore/Services/KubectlClusterReader.swift` reads cluster state through
   `kubectl` using the app-owned selected context.
5. `KubebarCore/Services/HealthEvaluator.swift` turns the latest snapshot into a
   `MenuDisplayModel`.
6. `MenuDisplayModel` is the only shape the menu uses to render the screen.

## Core Modules

- `KubebarApp` sets the menu bar scene and maps the current state to the menu
  bar icon.
- `KubebarCore/Models` holds the app-owned data types:
  `ClusterSnapshot`, `WatchTarget`, `ClusterHealthState`,
  `MenuBarStatusPresentation`, and `MenuDisplayModel`.
- `KubebarCore/Services/AppConfigStore.swift` saves the chosen context,
  watchlist, and refresh interval.
- `KubebarCore/Services/ContextCatalog.swift` lists available contexts for the
  setup flow.
- `KubebarCore/Services/CommandRunner.swift` is the injectable subprocess
  boundary.
- `KubebarCore/Services/KubectlClusterReader.swift` converts `kubectl` JSON
  output into app-owned cluster data. It reads nodes, pods, warning events,
  workload metadata, and node metrics from the Metrics API through `kubectl`.
- `KubebarCore/Services/RefreshCoordinator.swift` ties config, reader, and
  evaluator together.

## Request Flow

The menu never asks Kubernetes directly. It reads a display model that already
includes:

- the selected context name,
- the top-row state text,
- Overview cards for Nodes, Pods, CPU, and Memory,
- capped reason-first `Recent Warnings` rows with object scope, age, repeat
  count, and secondary message text,
- compact node, pod, and warning counts for secondary tabs,
- visible watchlist rows,
- overflow count for hidden watched items,
- stale banner content when the last refresh is no longer fresh.

When refresh succeeds, the coordinator stores the new snapshot and the
evaluator produces a current display model. When refresh fails, the last
snapshot can still be shown, but only as stale state.

CPU and Memory cards use the node metrics section when it is available. If the
Metrics API is unavailable, those cards show unavailable while valid node, pod,
warning, and tracked-object data stays visible.

## Where The UI Stops

The menu is allowed to show state and actions. It is not allowed to:

- decide cluster health on its own,
- read raw `kubectl` output,
- infer the terminal context,
- expand into a troubleshooting console.
