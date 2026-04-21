# Phase 03: Complete first-use setup and watchlist editing - UI Spec

**Date:** 2026-04-20
**Status:** Ready for planning
**Surface:** macOS SwiftUI setup flow

## UI Boundary

This phase updates the existing setup surface. It must not add a dashboard,
full troubleshooting view, or multi-cluster switcher.

## Required States

| State | Required behavior |
| --- | --- |
| No context available | Keep setup visible and show recovery copy in the context area |
| Context selected, candidates loading | Keep the context selector visible; show loading only in the watchlist area |
| Candidates loaded | Show namespaces and namespace-grouped workloads |
| Candidate load failed | Show failure reason and Retry in the watchlist area; keep selected targets |
| No candidates found | Show empty watchlist state with a clear next action/retry path |
| Editing existing watchlist | Reuse setup flow shape and show saved selections checked |

## Candidate Presentation

- Namespaces appear as selectable namespace targets.
- Workloads are grouped by namespace.
- Namespace groups default to collapsed when candidate volume is high.
- Workload rows show kind and name, for example `Deployment checkout`.
- `Job` rows are not shown by default.
- `CronJob` rows are shown.

## Interaction Rules

- Selecting or changing context automatically loads candidates for that context.
- Retry re-runs candidate discovery for the selected context.
- Selected targets remain selected if discovery fails.
- Finish setup remains disabled until both context and at least one target are
  selected.
- UI must not read `kubectl` directly.

## Copy Tone

Copy should be short and recovery-oriented. Avoid explaining Kubernetes concepts
inside the setup flow.

## Manual Visual Checks

- Long context, namespace, and workload names remain readable or truncate
  predictably.
- Loading and failure states do not hide the selected context.
- Grouped candidates are scannable on a 560px-wide setup surface.
