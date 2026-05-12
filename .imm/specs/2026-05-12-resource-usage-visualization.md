---
title: Resource usage visualization
date: 2026-05-12
status: planned
origin: imm-brainstorm handoff
---

# Resource Usage Visualization

## Summary

Kubebar already reads CPU and memory usage for Overview cards, node rows, and
Pod rows, and the UI already has an `InlineProgressBar` component. The missing
piece is a complete display-model contract that consistently provides
current-snapshot progress values wherever resource usage is shown.

This feature adds lightweight resource visualization, meaning compact progress
bars or equivalent current-use indicators next to existing CPU and memory text.
It must improve scanability without turning Kubebar into a dashboard.

## Goals

- Overview CPU and Memory cards show visual usage alongside the existing text.
- Nodes tab rows show visual CPU and Memory usage for each node when metrics
  are available.
- Pods tab rows show CPU and Memory resource pressure clearly enough to scan
  without hiding readiness or issue text.
- Missing metrics remain explicit unavailable values and never look like `0`.
- Resource visualization remains informational and does not affect health
  categories.

## Non-Goals

- No historical charts, sparklines, trends, or time-series storage.
- No Prometheus, Grafana, or external monitoring dependency.
- No resource-pressure alerting.
- No changes to `OK`, `Watch`, `Bad`, or `Stale` evaluation.
- No per-container Pod resource breakdown.

## Requirements

- R1. `MenuDisplayModel` remains the only rendering input for resource
  visualization.
- R2. `HealthEvaluator` computes resource progress values from already-owned
  snapshot data.
- R3. Progress values are unavailable when either usage or comparison basis is
  missing or invalid.
- R4. Valid zero usage produces a real `0` progress value.
- R5. Progress values are clamped for rendering so over-basis usage does not
  break layout.
- R6. Overview CPU and Memory progress use node usage over allocatable values.
- R7. Node CPU and Memory progress use per-node usage over allocatable values.
- R8. Pod CPU progress follows the existing compact text basis order: request,
  then limit.
- R9. Pod Memory progress follows the existing compact text basis order: limit,
  then request.
- R10. Pods must not collapse CPU and Memory into one ambiguous pressure value
  unless the plan explicitly records why a single value is better.
- R11. Help and accessibility labels keep full resource text available.
- R12. UI layout preserves current row density: resource visuals may shrink or
  disappear before Pod names, readiness counts, or issue reasons are obscured.
- R13. Stale data continues to be marked stale; visualization must not make old
  resource numbers look current.

## Verification Expectations

- Display-model tests cover current, zero, missing, and over-basis progress
  values for Overview, Nodes, and Pods.
- UI code consumes display-model progress values without doing Kubernetes
  health logic in views.
- The local Swift quality gate passes before the implementation is considered
  complete.
- A visible-app smoke check confirms the bars render in the menu without text
  overlap or confusing unavailable states.
