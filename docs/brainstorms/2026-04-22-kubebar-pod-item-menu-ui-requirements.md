---
date: 2026-04-22
topic: kubebar-pod-item-menu-ui
---

# Kubebar Pod Item Menu UI Requirements

## Problem Frame

Kubebar's Pods tab should let an operator quickly answer which Pods are healthy,
which namespace they belong to, and why a Pod needs attention. The current menu
already has Pod readiness summary data, but the Pods tab should become a
scannable Pod item list rather than only a watchlist-style summary. The design
must stay compact enough for a menu bar app and must not become a full
Kubernetes dashboard.

Completed Job Pods create a special case for readiness. They are no longer
expected to become Ready because their work already finished successfully, so
Kubebar should not count them as unready active Pods or use them to push the
cluster into Watch or Bad.

## Visual Aid

```text
Pods
5/7 ready

api
o checkout-7f9d                              1/1
o checkout-8a1b                              0/1
  CrashLoopBackOff: back-off restarting container

monitoring
o prometheus-0                               2/2
o alertmanager-0                             1/2
  ContainersReady False
```

Color intent:

| Dot | Meaning | Use |
|---|---|---|
| Green | Ready | All expected containers are ready |
| Yellow | Watch | Pod is pending, unknown, partially ready, or warning-like |
| Red | Bad | Pod failed or is restarting/crash-looping |

## Requirements

**Namespace grouping**
- R1. The Pods tab must group Pod items by namespace.
- R2. Namespace headers must be visually lighter than Pod names but still easy
  to scan.
- R3. The default scope should be watched namespaces, preserving Kubebar's
  watchlist-first behavior.
- R3a. If a saved workload target exists without its namespace selected, the
  Pods tab should show only the matching Pods for that workload under its
  namespace group, not every Pod in that namespace.
- R4. If multiple namespaces are visible, namespaces with attention-needed Pods
  should appear before namespaces where all visible Pods are ready.
- R5. Within the same namespace priority, namespaces should sort by name.

**Pod row content**
- R6. Each Pod item must show a circular status dot before the Pod name.
- R7. Each Pod item must show the Pod name as the primary text.
- R8. Each Pod item must show ready count / all count on the trailing side,
  formatted as `<ready>/<all>`.
- R9. The ready count must represent containers ready, and the all count must
  represent expected containers for that Pod.
- R10. If per-container totals are unavailable, the row must use a safe
  unavailable value rather than pretending the Pod is fully ready.

**Status meaning**
- R11. A Ready Pod should use the normal row style and a green dot.
- R12. A partially ready, pending, or unknown Pod should use a Watch style and a
  yellow dot.
- R13. A failed, actively restarting, or crash-looping Pod should use a Bad
  style and a red dot.
- R14. Dot color must not be the only status signal; hover/help and
  accessibility text must include the status in words.

**Completed Job Pods**
- R14a. A successfully completed Job Pod must be treated as a normal completed
  outcome, not as an unready active Pod.
- R14b. Completed Job Pods must not reduce active Pod ready/all counts in the
  Pods tab summary or Overview Pods card.
- R14c. Completed Job Pods must not move the menu state to Watch or Bad by
  themselves.
- R14d. If the watched scope contains only completed Job Pods and no active
  Pods, Kubebar should remain OK and show `No active pods; completed jobs are
  OK` rather than a readiness warning.
- R14e. Failed Job Pods remain Bad. Only successful completion gets the normal
  completed treatment.
- R14f. The default Pods tab should not list completed Job Pods as active Pod
  rows. If a later design surfaces completed Pods, they need a separate neutral
  completed presentation rather than reusing Ready, Watch, or Bad.

**Error and secondary text**
- R15. A Pod with an error, warning, or not-ready reason must show a short
  secondary line below the Pod name.
- R16. The secondary line must use small gray text.
- R17. The secondary line should prefer the most useful available reason, such
  as container waiting reason, terminated reason, Pod status reason/message, or
  not-ready condition.
- R18. Long error text must stay to one visible line with truncation, while the
  full text remains available through hover/help and accessibility text.
- R19. Ready Pods should not show a secondary line unless there is a meaningful
  warning associated with that Pod.

**Ordering and density**
- R20. Pods needing attention should appear before Ready Pods within each
  namespace.
- R21. Pods with the same attention level should sort by Pod name.
- R22. The Pods tab may scroll when there are many Pods; silently hiding Pods is
  not acceptable.
- R23. Row spacing should be compact, but error rows may be slightly taller to
  fit the secondary line.
- R24. The design must remain appropriate for a menu bar utility and avoid deep
  troubleshooting controls.

**Unavailable and empty states**
- R25. If Pod data is unavailable, the Pods tab must show the existing safe
  unavailable message instead of partial or misleading rows.
- R26. If the watched scope contains no Pods, the tab must show a short empty
  message that distinguishes no Pods from failed data.
- R27. Stale data must continue to be marked as stale and must not look current
  or healthy.

## Success Criteria

- The Pods tab answers which Pods are visible, which namespace they are in, and
  which Pods need attention.
- A user can spot failed or partially ready Pods before reading every row.
- Ready count / all count is visible on every Pod row and cannot be confused
  with the overall tab summary.
- Completed Job Pods do not appear as unready active Pods and do not create a
  false Watch or Bad state.
- Error information is present without making the menu feel like a log viewer.
- Namespace grouping improves scanning without hiding Pods.
- Stale or unavailable Pod data is visibly not current.

## Scope Boundaries

- This change does not add deep troubleshooting actions.
- This change does not add Pod logs, events drilldown, shell commands, or links
  into external tools.
- This change does not change menu bar health categories.
- This change does not add a historical Job dashboard or completed-run history.
- This change does not replace the Overview, Nodes, or Events tabs.
- This change does not require Prometheus, Grafana, or any external monitoring
  dependency.

## Key Decisions

- **Use grouped Pod rows instead of watchlist-style Pod rows:** The user's goal
  is to inspect Pod items directly, and namespace grouping gives the fastest
  mental map.
- **Show ready/all on each Pod row:** The row should expose readiness locally,
  not only in the tab summary.
- **Exclude completed Job Pods from active readiness:** Successful completion is
  a terminal normal outcome, not an active readiness failure.
- **Use dots plus text support:** Dots make the list scannable, while
  accessibility and hover text prevent color-only meaning.
- **Keep error text shallow:** The row should explain the visible problem, but
  deeper investigation remains outside Kubebar's first version.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| Keep current watchlist-style rows and add ready/all | Smallest visual change | Does not satisfy direct Pod item browsing or namespace grouping |
| Group all visible Pods by namespace | Best match for the requested UI and easiest to scan | Needs careful ordering and scroll behavior for large clusters |
| Collapse each namespace by default | Reduces height for large clusters | Hides problems unless attention groups auto-expand, adding behavior complexity |
| Count completed Job Pods as ready | Keeps totals simple | Misleads because completed Pods are not actively ready |
| Show completed Job Pods as a separate neutral state | Preserves more history | Adds UI complexity and historical Job semantics to a glanceable menu |

Recommended option: group all visible Pods by namespace. It best matches the
requested design while keeping the interaction simple. For completed Job Pods,
exclude them from active readiness by default so successful completion does not
look like a health problem.

## Dependencies / Assumptions

- Existing Pod data includes namespace, Pod name, phase, status reason/message,
  container readiness, restart count, and container waiting/terminated reasons.
- Planning should verify whether the current snapshot keeps enough per-Pod data
  after decoding, or whether the display model needs a Pod item shape.
- The watched namespace scope should remain the default display scope unless
  the product later adds an explicit "all namespaces" mode.
- Planning should treat Kubernetes `Succeeded` phase and successful
  `Completed` container termination as signals for completed Job Pods, while
  preserving failed Job Pods as Bad.

## Outstanding Questions

### Deferred to Planning

- [Affects R8, R9][Technical] Confirm the best fallback when Kubernetes omits
  container status totals for a Pod.
- [Affects R17][Technical] Confirm the exact priority order for choosing one
  short Pod error message when several reasons are present.
- [Affects R13][Technical] Confirm how to distinguish active restarting or
  crash-looping from historical restart count so old restarts do not look like
  current failures.

## Next Steps

-> `/ce:plan` for structured implementation planning
