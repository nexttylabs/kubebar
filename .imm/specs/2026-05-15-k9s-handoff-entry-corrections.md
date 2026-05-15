---
title: k9s handoff entry corrections
date: 2026-05-15
status: planned
origin: imm-brainstorm manual validation feedback
---

# k9s Handoff Entry Corrections

## Summary

Manual validation found three mismatches in the new `Open in k9s` surface:
the Overview error area can lose the handoff entry, Node rows open the Nodes
view rather than a specific Node, and Pod rows open the Pods view for a
namespace rather than a specific Pod.

This correction keeps the handoff valuable while making the UI honest about
where `k9s` lands. Kubebar remains a glanceable Kubernetes health tool.
`k9s` remains the external deep inspection tool.

## Goals

- Overview error or abnormal status copy keeps a visible, reachable k9s handoff
  entry when a valid fresh target exists.
- Node row handoff is described and modeled as a Nodes view/list entry, not an
  exact Node jump.
- Pod row handoff is described and modeled as a namespace Pods view/list entry,
  not an exact Pod jump.
- All handoffs continue to use Kubebar's app-owned Kubernetes context.
- Button labels, help text, accessibility labels, and failure feedback match
  the actual `k9s` landing point.

## Non-Goals

- No k9s interactive keyboard automation for exact positioning.
- No logs, describe, edit, exec, delete, port-forward, restart, or mutation
  actions.
- No Recent Warnings handoff in this slice.
- No change to Health category evaluation.
- No embedded terminal or command transcript display.

## Requirements

- R1. `MenuDisplayModel` remains the source of truth for every handoff
  affordance.
- R2. Overview must not hide a valid handoff action when the top status area
  shows Watch or Bad error details.
- R3. Node row handoff targets must not carry or expose copy that promises
  exact Node positioning.
- R4. Pod row handoff targets must not carry or expose copy that promises exact
  Pod positioning.
- R5. Pod row handoff copy must make the namespace-level Pods view/list landing
  point clear.
- R6. All handoffs must launch with app-owned context and namespace arguments
  when applicable.
- R7. Stale, setup, unavailable, or incomplete target states must continue to
  omit misleading handoff actions.
- R8. Failure copy must identify the intended stable entry point and must not
  expose stderr, command lines, kubeconfig paths, or command output.
- R9. QA fixtures or tests must cover the Overview state that previously lost
  the handoff entry.

## Verification Expectations

- Display-model or evaluator tests prove Node and Pod row handoff targets use
  stable list-level semantics.
- Launcher tests prove app-owned context and namespace arguments are preserved
  while Node and Pod commands no longer imply exact resource positioning.
- View, view-model, or QA fixture tests prove Overview Watch or Bad error
  detail states keep a visible handoff entry.
- QA metadata describes the corrected Node and Pod landing points.
- `./scripts/swift-quality-gate.sh local` passes before the correction is
  complete.
- Visible-app smoke checks the Overview, Pods, and Nodes handoff copy in a Bad
  or Watch QA state.
