---
date: 2026-04-22
topic: kubebar-nodes-item-display
---

# Kubebar Nodes Item Display Requirements

## Problem Frame

Kubebar's Nodes tab currently tells the operator how many nodes are ready, but
it does not make individual node health or resource pressure visible. The tab
should show each node as a compact item with its name, readiness, CPU usage,
and memory usage. When a node is not ready, the item should become visibly
error-like and explain the reason without turning the menu into a full
troubleshooting console.

## Visual Aid

```text
Nodes
3/4 ready

worker-03                                      Not Ready
DiskPressure: kubelet reports disk pressure
CPU 71%                                       Memory 82%

worker-01                                      Ready
CPU 34%                                       Memory 58%
```

## Requirements

**Node row content**
- R1. Each node item must show the node name.
- R2. Each node item must show a readiness label: `Ready` or `Not Ready`.
- R3. Each node item must show CPU usage and memory usage when metrics are
  available.
- R4. CPU and memory must be shown as percentages for quick scanning.
- R5. Missing CPU or memory data must show an unavailable value such as `-`;
  missing data must not be shown as `0`.

**Ready and Not Ready presentation**
- R6. Ready nodes should use the normal compact row style.
- R7. Not Ready nodes must use an error style that is visually stronger than a
  normal row.
- R8. Not Ready nodes must show a short error description below the primary row.
- R9. The error description should use the most useful available node condition
  reason and message.
- R10. Long error descriptions must stay to one visible line and preserve the
  full text through hover/help and accessibility text.

**Ordering and density**
- R11. Not Ready nodes should appear before Ready nodes.
- R12. Nodes with the same readiness state should be sorted by node name.
- R13. The Nodes tab should remain compact enough for a menu bar app and should
  not become a deep node dashboard.
- R14. When node data is available, the Nodes tab should include every node.
  If the list is too tall for the menu, scrolling is acceptable; silently
  hiding nodes is not acceptable.

**Unavailable and empty states**
- R15. If node data is unavailable, the Nodes tab must show the existing
  unavailable message rather than partial or misleading rows.
- R16. If metrics are unavailable but node readiness is available, node rows
  should still show readiness and names while CPU and memory show unavailable.

## Success Criteria

- The Nodes tab answers which nodes exist, which are ready, and which need
  attention.
- A Not Ready node is visually obvious before reading the text.
- A Not Ready node explains the likely reason in the row itself.
- CPU and memory values are quick to scan and cannot be confused with missing
  data.
- Normal Ready rows stay compact.
- All nodes remain reachable from the Nodes tab, even when scrolling is needed.
- The design remains appropriate for a menu bar utility rather than a full
  Kubernetes dashboard.

## Scope Boundaries

- This change does not add deep troubleshooting actions.
- This change does not add pod-level metrics.
- This change does not require Prometheus, Grafana, or any external monitoring
  dependency.
- This change does not change menu bar health categories.
- This change does not remove the Overview, Pods, or Events tabs.

## Key Decisions

- **Use the balanced node row design:** Normal nodes stay compact, while Not
  Ready nodes expand just enough to show the reason.
- **Prioritize Not Ready nodes:** The operator should see broken nodes before
  healthy nodes.
- **Treat missing metrics as unavailable:** Missing CPU or memory data is not a
  healthy value and must not be rendered as zero.
- **Keep diagnostic text shallow:** The row should explain the visible problem,
  but deeper investigation remains outside Kubebar's first version.

## Dependencies / Assumptions

- Existing Kubebar reads node readiness and cluster-level node metrics through
  `kubectl`.
- Planning should verify whether the current node data includes enough
  condition reason and message detail for the Not Ready description.
- Planning should verify whether the current metrics data can be matched to
  individual node names.

## Outstanding Questions

### Deferred to Planning

- [Affects R3][Technical] Confirm the available `kubectl` node metrics include
  stable node identity so CPU and memory can be shown per node.
- [Affects R9][Technical] Confirm which node condition fields should produce
  the best Not Ready description.

## Next Steps

-> `/ce:plan` for structured implementation planning
