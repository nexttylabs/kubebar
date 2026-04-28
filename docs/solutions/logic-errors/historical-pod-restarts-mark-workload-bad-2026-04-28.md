---
title: Historical Pod Restarts Mark Watched Workloads Bad
date: "2026-04-28"
category: "docs/solutions/logic-errors"
module: "KubectlClusterReader"
problem_type: "logic_error"
component: "service_object"
symptoms:
  - "Watched workload stayed Bad after a restarted Pod recovered"
  - "Cluster health stayed Bad even when current Pod state was healthy"
  - "Historical restartCount values were treated as active restart failures"
root_cause: "logic_error"
resolution_type: "code_fix"
severity: "medium"
related_components:
  - "HealthEvaluator"
  - "MenuDisplayModel"
  - "KubebarTests"
tags:
  - "kubectl-cluster-reader"
  - "pod-health"
  - "restart-count"
  - "crashloopbackoff"
  - "false-bad-state"
---

# Historical Pod Restarts Mark Watched Workloads Bad

## Problem

Kubebar kept a watched workload and the overall cluster in `Bad` after a Pod had already recovered from a restart. The health logic treated a cumulative Kubernetes restart counter as if it described a current failure.

## Symptoms

- A Pod that was currently `Running` and `Ready` could still make its watched target `Bad`.
- Any container with `restartCount > 0` was treated as actively restarting.
- A one-time past restart could keep the menu bar status unhealthy indefinitely.

## What Didn't Work

- Treating `restartCount` as active restart detection did not work because Kubernetes restart counts are cumulative history, not current state.
- Session history did not show a previous fix attempt for this exact issue, but it did show the same product rule recurring elsewhere: old or historical state must not be presented as current health. (session history)

Before:

```swift
var isRestarting: Bool {
    status.containerStatuses?.contains { status in
        (status.restartCount ?? 0) > 0 ||
            status.state?.waiting?.reason == "CrashLoopBackOff"
    } ?? false
}
```

That code incorrectly classified recovered Pods as still restarting.

## Solution

Base active restart detection on the current container waiting state only. A Pod counts as restarting when a container is currently waiting with reason `CrashLoopBackOff`.

After:

```swift
var isRestarting: Bool {
    status.containerStatuses?.contains { status in
        normalizedReason(status.state?.waiting?.reason) == "crashloopbackoff"
    } ?? false
}
```

Tests should cover both sides of the rule:

- Pods with nonzero historical `restartCount`, `Ready=True`, and no current waiting state stay `OK`.
- Pods currently waiting with `CrashLoopBackOff` still make the watched target `Bad`.
- Crash-loop fixtures should model the current failure state realistically: not ready and waiting with `CrashLoopBackOff`.

## Why This Works

`restartCount` records past restarts. `CrashLoopBackOff` is a current container state. Separating those signals keeps recovered Pods from poisoning health while preserving the important failure case where a container is actively crash-looping.

This matches the product invariant in `docs/architecture/runtime-invariants.md`: historical restart count alone must not make a Pod item `Bad`, while current failed, waiting, or crash-looping state may.

## Prevention

- Keep health decisions based on current Pod and container state, not cumulative counters alone.
- Add regression tests for recovered Pods with nonzero restart counts.
- Model failing Pod fixtures with realistic current status, including `Ready=False` and a waiting reason when testing `CrashLoopBackOff`.
- When adding new Kubernetes health signals, decide whether each signal describes current state, historical state, terminal state, or unavailable data before mapping it to `OK`, `Watch`, `Bad`, or `Stale`.

## Related Issues

- `docs/architecture/runtime-invariants.md` defines the authoritative runtime rule.
- `docs/plans/2026-04-22-004-feat-pod-item-menu-ui-plan.md` records the intended Pod row behavior.
- `docs/brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md` called out the need to distinguish active restarts from historical restart count.
- `docs/plans/2026-04-23-002-fix-completed-job-pods-readiness-plan.md` is an adjacent false-health-state fix that separates terminal historical Pod state from active health.
- `docs/plans/2026-04-22-005-fix-no-matching-pods-health-plan.md` is an adjacent logic fix where missing Pods should not be treated as active failure.
- GitHub issue #4 is broadly related to actionable workload reasons, including restarting Pods.

## Verification

- `swift test --filter KubectlClusterReaderTests` passed with 42 tests.
- `./scripts/swift-quality-gate.sh local` passed.
