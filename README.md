# Kubebar

Kubebar is a native macOS menu bar app for quickly checking Kubernetes health.

It is built for one daily operator who wants to know, at a glance, whether the
current cluster is healthy, which watched workloads need attention, and whether
the displayed data is fresh enough to trust.

Kubebar is not a replacement for `k9s`. It is the small status instrument you
look at before opening deeper troubleshooting tools.

## Current Status

The project now has the first Swift foundation:

- macOS SwiftUI menu bar entry
- core health states: `OK`, `Watch`, `Bad`, `Stale`
- watchlist-first display model
- stale-data handling rules
- local config persistence
- `kubectl` command boundary and JSON snapshot reader
- refresh coordination from config to display state
- tests for the most important status behavior

First-use setup screens and full live menu wiring are planned next.

## Build and Test

```bash
./scripts/swift-quality-gate.sh local
```

This runs:

- `swift build`
- `swift test`

## Project Layout

```text
Kubebar/       SwiftUI menu bar app entry and views
KubebarCore/   Models, display mapping, health rules, and services
KubebarTests/  Unit tests for trusted product behavior
docs/          Requirements, plans, and architecture notes
scripts/       Local quality checks
```

## Product Direction

The version-1 direction is captured in:

- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md`
- `docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md`
