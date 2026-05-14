---
title: Do Not Expand Pod Resource Readability Into History Or Alerts
date: "2026-05-14"
category: "docs/solutions/rejected-decisions"
module: "PodsTab"
problem_type: "scope_control"
component: "resource_usage_visualization"
rejected: true
rejection_reason: "This slice was about making existing current-snapshot Pod resource text easier to scan. Historical trends, new metrics storage, and resource-pressure alerting would expand Kubebar toward dashboard behavior and could blur Health category ownership."
resolution_type: "scope_rejection"
severity: "low"
related_components:
  - "CONTEXT.md"
  - "runtime-invariants"
  - "HealthEvaluator"
  - "PodsTabView"
tags:
  - "pod-resource"
  - "resource-usage-visualization"
  - "scope-boundary"
  - "rejected"
reusability: medium
next_reuse_scenarios:
  - "Brainstorming Pod resource charts or sparklines"
  - "Planning resource-pressure warning thresholds"
  - "Considering new metrics storage or external monitoring integration"
  - "Reviewing whether a Pods tab display change belongs in v1"
---

# Do Not Expand Pod Resource Readability Into History Or Alerts

## Rejected Decision

Do not use the Pod resource readability work as a doorway into historical
charts, sparklines, metrics storage, Prometheus/Grafana integration, or
resource-pressure alerting.

## Why It Was Rejected

Kubebar's current product contract is a glanceable menu bar health tool. Its
resource usage visualization is a lightweight current-snapshot display, not a
time-series dashboard. The Health category still belongs to `HealthEvaluator`,
and resource bars or percentages must not independently decide `OK`, `Watch`,
`Bad`, or `Stale`.

Expanding this slice into history or alerts would introduce new data ownership,
new verification surfaces, and new user semantics. That belongs in a separate
planner slice only if the product direction explicitly changes.

## Accepted Alternative

Keep resource display improvements inside the existing snapshot and display
model boundary:

- Make compact labels more readable.
- Make hover and accessibility details explicit.
- Preserve unavailable values as unavailable.
- Keep resource usage display-only.

## Evidence

The accepted plan `docs/plans/2026-05-14-002-feat-pod-resource-readability-plan.md`
closed with tests and QA evidence for readable labels, explicit unavailable
values, separate CPU/memory progress, and unchanged Health category behavior.
