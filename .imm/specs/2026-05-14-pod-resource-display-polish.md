---
title: Pod resource display polish
date: 2026-05-14
status: planned
origin: imm-brainstorm handoff
---

# Pod Resource Display Polish

## Summary

Kubebar already shows Pod CPU and memory metrics in the Pods tab through
compact labels and lightweight progress bars. The next improvement is to make
that display easier to scan and harder to misread as alerting.

This feature polishes Pod resource display without expanding Kubebar into a
resource dashboard. Pod readiness and issue text remain the primary Pod row
signal, while resource usage visualization stays informational.

## Goals

- Pod rows show issue text before resource usage when both are present.
- Pod CPU and memory progress values are distinguishable in the compact row.
- Resource usage visualization does not imply a new Health category.
- Unavailable resource data remains explicit and accessible.
- Existing help and accessibility labels keep complete resource context.

## Non-Goals

- No new Kubernetes reads.
- No historical charts, sparklines, trends, or time-series storage.
- No Prometheus, Grafana, or external monitoring dependency.
- No resource-pressure alerting.
- No changes to `OK`, `Watch`, `Bad`, or `Stale` evaluation.
- No per-container Pod resource breakdown.

## Requirements

- R1. `MenuDisplayModel` remains the only rendering input for Pod resource
  display.
- R2. Pod issue text is visually ordered before resource text when a row needs
  attention.
- R3. CPU and memory progress values remain separate display-model values.
- R4. Any legacy single `resourceProgress` path must not become the primary Pod
  rendering contract.
- R5. Compact progress rendering must make CPU and memory distinguishable
  without adding dense explanatory text.
- R6. Color must not be the only signal for resource interpretation.
- R7. High resource usage must not change any Health category.
- R8. Missing usage or missing comparison basis renders as unavailable, not as
  zero.
- R9. Help and accessibility labels include complete available usage,
  request, limit, and unavailability reason text.
- R10. Layout must preserve Pod name, ready count, and issue text before
  resource visuals.

## Verification Expectations

- Display-model tests cover CPU and memory progress as separate values.
- Model or view-adjacent tests cover issue-before-resource ordering where a row
  has both.
- Regression tests prove high or unavailable Pod resource values do not change
  the Health category.
- `./scripts/swift-quality-gate.sh local` passes before the change is complete.
- A visible-app smoke check with `./scripts/compile-and-run.sh` is used when
  local macOS launch is available.
