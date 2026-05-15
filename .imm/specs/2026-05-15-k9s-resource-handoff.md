---
title: k9s resource handoff
date: 2026-05-15
status: planned
origin: imm-brainstorm handoff
---

# k9s Resource Handoff

## Summary

Kubebar already has a narrow `Open in k9s` action from the Overview top status
detail. That action only opens `k9s` for the app-owned context and namespace.
It does not help when the user is already looking at a concrete Pod, Node, or
watched workload row and wants to continue in `k9s`.

This feature expands the external handoff surface from a single Overview action
to resource-level entry points in existing rows. Kubebar remains the
glanceable status tool. `k9s` remains the deeper inspection tool.

## Goals

- Watchlist rows can open `k9s` for their namespace or workload target.
- Pods tab rows can open `k9s` for the corresponding Pod.
- Nodes tab rows can open `k9s` for the corresponding Node.
- All handoffs use Kubebar's app-owned Kubernetes context.
- Handoff feedback remains safe, short, and separate from Health category.

## Non-Goals

- No embedded terminal.
- No logs, describe, edit, exec, delete, port-forward, or restart actions.
- No raw command transcript display.
- No Kubernetes watch streams.
- No Recent Warnings handoff in this slice.
- No resource-pressure alerting or historical resource dashboard.
- No change to how `OK`, `Watch`, `Bad`, or `Stale` are evaluated.

## Requirements

- R1. `MenuDisplayModel` remains the only rendering input for k9s handoff
  affordances.
- R2. A handoff target must carry the app-owned context and enough safe target
  data to open `k9s` without the view inferring Kubernetes semantics.
- R3. Namespace handoff opens `k9s` with explicit context and namespace.
- R4. Workload handoff opens the matching workload kind in its namespace when a
  stable shallow `k9s` command shape exists.
- R5. Pod handoff opens the Pod view in the Pod namespace and filters or
  positions to the Pod name when supported by a stable shallow `k9s` command
  shape.
- R6. Node handoff opens the Node view and filters or positions to the Node
  name when supported by a stable shallow `k9s` command shape.
- R7. If exact filtering or positioning is not stable, the handoff must still
  land on the closest safe resource view instead of simulating interactive
  keystrokes.
- R8. Stale, setup, unavailable, or target-incomplete states must not show a
  broken or misleading handoff.
- R9. Handoff UI must be deliberate button-style action, not automatic launch
  or accidental primary-row activation.
- R10. Launch state and failures must not alter Health category.
- R11. Failure copy must identify the intended target using safe display text
  and must not expose stderr, shell text, kubeconfig paths, or command output.
- R12. Handoff affordances must be reachable by keyboard and understandable by
  accessibility labels.

## Verification Expectations

- Display-model tests cover namespace, workload, Pod, and Node handoff targets.
- Launcher tests cover explicit context, namespace, resource view, optional
  filter values, and special-character safety.
- Coordinator or view-model tests cover opening, duplicate activation, target
  changes, and failure feedback.
- UI or view-adjacent tests cover row-level deliberate actions and
  accessibility labels.
- `./scripts/swift-quality-gate.sh local` passes before implementation is
  complete.
- A visible-app smoke check confirms row affordances fit without crowding
  first-scan resource information when local macOS launch is available.
