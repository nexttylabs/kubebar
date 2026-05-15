---
title: k9s handoff entry placement
date: 2026-05-15
status: planned
origin: imm-brainstorm manual validation feedback
---

# k9s Handoff Entry Placement

## Summary

Manual validation confirmed that Pod and Node handoff targets now describe
stable list-level `k9s` landing points, but their buttons still sit on concrete
Pod and Node rows. That placement makes the user expect a specific resource
jump even though `k9s` opens the namespace Pods view/list or the global Nodes
view/list.

This correction moves list-level handoff affordances to list-level UI
locations. Kubebar remains a glanceable Kubernetes health tool. `k9s` remains
the external inspection tool.

## Goals

- Pods tab exposes one k9s entry per namespace section, near the namespace
  header.
- Pod rows no longer show a k9s button that implies exact Pod positioning.
- Nodes tab exposes one k9s entry near the Nodes readiness summary.
- Node rows no longer show a k9s button that implies exact Node positioning.
- Button labels, help text, accessibility labels, and QA expectations match
  the stable list-level `k9s` landing point.
- All entries continue to use Kubebar's app-owned Kubernetes context.

## Non-Goals

- No k9s interactive keyboard automation for exact Pod or Node positioning.
- No logs, describe, edit, exec, delete, port-forward, restart, or mutation
  actions.
- No Recent Warnings handoff.
- No change to Health category evaluation.
- No change to resource usage visualization.

## Requirements

- R1. `MenuDisplayModel` remains the source of truth for k9s handoff
  affordances.
- R2. Namespace Pods handoff must be rendered at the namespace section level,
  not on each Pod row.
- R3. Nodes handoff must be rendered at the Nodes tab summary or header level,
  not on each Node row.
- R4. Row-level Pod and Node k9s buttons must be removed or hidden when the
  target is list-level.
- R5. User-facing copy and accessibility labels must describe `namespace Pods`
  or `Nodes`, not a concrete Pod or Node.
- R6. App-owned context and namespace/resource view launch arguments must be
  preserved.
- R7. Stale, setup, unavailable, or incomplete target states must not expose a
  misleading handoff.
- R8. QA fixtures or visible validation must cover the Bad state for Overview,
  Pods, and Nodes entry placement.

## Verification Expectations

- Tests or fixture checks prove Pod handoff metadata appears at namespace
  section scope and no longer appears as row-level actions.
- Tests or fixture checks prove Node handoff metadata appears at tab summary
  scope and no longer appears as row-level actions.
- Existing launcher tests continue to prove app-owned context and resource
  view arguments.
- `./scripts/swift-quality-gate.sh local` passes.
- A `bad` QA visible check verifies the Overview action remains visible, Pods
  section-level action is near the namespace header, and Nodes action is near
  the summary/header rather than on each row.
