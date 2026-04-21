# Kubebar

Kubebar is a native macOS menu bar app for quickly checking Kubernetes health.

It is built for one daily operator who wants to know, at a glance, whether the
current cluster is healthy, which watched workloads need attention, and whether
the displayed data is fresh enough to trust.

Kubebar is not a replacement for `k9s`. It is the small status instrument you
look at before opening deeper troubleshooting tools.

## Current Status

The project now has a working macOS menu bar foundation:

- macOS SwiftUI menu bar entry
- core health states: `OK`, `Watch`, `Bad`, `Stale`
- watchlist-first display model
- stale-data handling rules
- local config persistence
- `kubectl` command boundary and JSON snapshot reader
- refresh coordination from config to display state
- first-use setup and watchlist editing views
- live menu content wired through a view model
- warning event summaries and workload reasons
- tests for the most important status behavior

The current roadmap focuses on making the setup loop, warning reasons,
freshness controls, and operator-facing verification ready for daily use.

## Local Reads and Privacy

Kubebar uses the saved context in its own config, not the terminal's current
context. It calls `kubectl` only for the status and setup reads needed by the
menu, such as namespaces, workload candidates, node/pod status, and warning
events.

Kubebar does not query Kubernetes Secrets. If a command fails, the menu keeps
old data only as a clearly marked stale state with a retry path.

## Build and Test

Open in Xcode:

```bash
open Kubebar.xcodeproj
```

Regenerate the Xcode project after changing targets or source folders:

```bash
xcodegen generate
```

```bash
./scripts/swift-quality-gate.sh local
```

This runs:

- Xcode build for the macOS menu bar app
- Xcode tests
- `swift build`
- `swift test`

Run the built menu bar app and verify that the process starts:

```bash
./scripts/compile-and-run.sh
```

This reuses the quality gate, opens the built Debug app, and prints the
running Kubebar process ID.

## Project Layout

```text
Kubebar/       SwiftUI menu bar app entry and views
KubebarCore/   Models, display mapping, health rules, and services
KubebarTests/  Unit tests for trusted product behavior
docs/          Requirements, plans, and architecture notes
project.yml    XcodeGen source for Kubebar.xcodeproj
scripts/       Local quality checks
```

## Product Direction

The current roadmap entry point is:

- [docs/plans/2026-04-19-002-kubebar-product-roadmap.md](docs/plans/2026-04-19-002-kubebar-product-roadmap.md)

The version-1 product direction is also captured in:

- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md`
- `docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md`
