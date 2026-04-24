---
date: 2026-04-24
topic: kubebar-pod-resource-display
---

# Kubebar Pod Resource Display Requirements

## Problem Frame

Kubebar's Pods tab already helps an operator see which watched Pods are ready
and which ones need attention. The next useful scan is whether a Pod is under
resource pressure: current CPU and memory use only become meaningful when they
can be compared with requests and limits.

Without this, an operator has to open a deeper tool just to answer whether a
suspicious or unhealthy Pod is also resource-constrained. That slows down a
quick health check and makes Kubebar less useful at the exact moment when the
operator is deciding whether to investigate further.

The menu should surface Pod resource information without becoming a full
performance dashboard. It should help an operator decide whether a Pod is worth
opening in deeper tools, while preserving Kubebar's compact, watchlist-first
menu behavior.

This document extends the Pod row behavior described in
`docs/brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md`.

## Visual Aid

```text
Pods
5/7 ready

api
o checkout-7f9d                         1/1
  CPU 82% req · Mem 64% limit

o checkout-8a1b                         0/1
  CrashLoopBackOff: back-off restarting container
  CPU - · Mem -
```

`CPU - · Mem -` means resource usage is unavailable for that row. It is not a
generic rule for unhealthy Pods; issue rows should still show known resource
facts when they are available.

Complete help/accessibility text example:

```text
api/checkout-7f9d, Ready, 1/1 containers ready,
CPU 120m used / 150m request / 500m limit,
Memory 256Mi used / 400Mi request / 512Mi limit
```

## Requirements

**Displayed resource content**
- R1. Each visible active Pod row should include CPU and memory resource
  display, using known values or explicit unavailable markers.
- R2. Resource information must include current usage and the configured
  request/limit context when available.
- R3. The row-level display should be a Pod-level summary, not a per-container
  breakdown.
- R4. Hover/help and accessibility text must include the complete available
  resource values for CPU and memory: usage, request, and limit.
- R5. Missing values in hover/help and accessibility text must use explicit
  unavailable markers such as `usage -`, `request -`, or `limit -` rather than
  being silently omitted.

**Row display**
- R6. The visible row should show compact CPU and memory labels together when
  a visible active Pod row is shown.
- R7. The normal compact format is `CPU <value> <basis> · Mem <value> <basis>`,
  such as `CPU 82% req · Mem 64% limit`.
- R8. CPU should compare usage to request when request is available, and to
  limit only when request is unavailable.
- R9. Memory should compare usage to limit when limit is available, and to
  request only when limit is unavailable.
- R10. If usage exists but no comparison basis exists, the compact label should
  show raw usage, such as `CPU 120m` or `Mem 256Mi`, instead of inventing a
  percentage.
- R11. If usage is unavailable, the compact label should show an unavailable
  value, such as `CPU -` or `Mem -`.
- R12. Raw usage numbers should remain available through hover/help text rather
  than competing with the Pod name, readiness count, and issue text.
- R13. Resource text must not push the Pod name, ready count, or issue reason out
  of view.
- R14. If a Pod has an issue line, the issue line remains above resource text
  and remains more important than resource text.
- R15. When space is tight, resource text may truncate before the issue line
  does, while the full resource values remain available through help and
  accessibility text.
- R16. Complete resource values must be available through keyboard focus and
  accessibility, not only through pointer hover.

**Missing and partial data**
- R17. Missing current usage must show an unavailable value such as `-`; it must
  not be shown as `0`.
- R18. Missing requests or limits must be represented as unavailable or absent
  comparison context; Kubebar must not invent a percentage.
- R19. Partial resource data should still show the parts that are known, as long
  as unavailable parts are clearly marked.
- R20. Metrics API or resource-data failures must not make unavailable resource
  data look healthy, current, or normal.
- R21. Resource-only failures must not hide otherwise valid Pod rows.
- R22. If all current Pod usage is unavailable, visible rows should show
  unavailable usage labels such as `CPU - · Mem -`, and complete help text
  should include a safe unavailable reason.
- R23. If request/limit context is unavailable but current usage is available,
  visible rows should show raw usage without a percentage.
- R24. Stale snapshots must continue to be marked as stale; resource numbers
  from stale data must not look current.

**Health behavior**
- R25. Pod resource pressure must not change the menu bar state, Overview state,
  Pod row state, or OK/Watch/Bad categorization in the first version.
- R26. Resource display should support human judgment, not act as a resource
  alerting system.
- R27. Existing Pod readiness, failed state, restarting state, completed Job
  handling, and unavailable-data behavior remain authoritative for health
  status.
- R28. Any future change that lets resource pressure affect Watch or Bad must
  be handled as a separate product decision with explicit thresholds and
  false-positive expectations.

**Scope and density**
- R29. The Pods tab must remain a compact menu bar view, not a resource
  dashboard.
- R30. Resource labels should be short enough for repeated scanning across many
  Pod rows.
- R31. The existing namespace grouping and attention-first ordering should
  remain intact.
- R32. Completed Job Pods should keep the existing default behavior: they are
  not listed as active Pod rows by default, so they do not need resource display
  in this version.

## Success Criteria

- A user can scan the Pods tab and see whether visible Pods are under CPU or
  memory pressure.
- A user can inspect complete available usage, request, and limit values without
  leaving the menu.
- Resource information does not obscure readiness, namespace grouping, or
  issue reasons.
- Missing metrics or missing requests/limits are clearly unavailable rather
  than rendered as zero or normal.
- Resource pressure does not create new Watch or Bad states in the first
  version.
- The menu still feels like a quick health tool rather than a Kubernetes
  dashboard.

## Scope Boundaries

- This change does not add resource-based alerting.
- This change does not change menu bar health categories.
- This change does not change existing Pod readiness or completed Job rules.
- This change does not add per-container resource rows in the first version.
- This change does not add charts, history, trends, or sparklines.
- This change does not add Prometheus, Grafana, or any external monitoring
  dependency.
- This change does not add Pod logs, events drilldown, shell commands, or
  deeper troubleshooting controls.

## Key Decisions

- **Show both usage and request/limit context:** Usage alone is hard to judge,
  while requests and limits alone do not show current pressure.
- **Show compact pressure in-row and complete values through help and focus:**
  The visible list stays scannable, while full values remain available when
  needed.
- **Use request for CPU before limit:** CPU request is the better first scan for
  whether the Pod is using more CPU than it asked the scheduler to reserve.
- **Use limit for memory before request:** Memory limit is the better first scan
  for whether the Pod is approaching a hard cap.
- **Do not let resource pressure affect health state yet:** The first version
  should avoid noisy status changes until the display proves useful.
- **Start with Pod-level summaries:** This matches Kubebar's glanceable scope
  and avoids turning the Pods tab into a container-level debugging view.
- **Keep unavailable data explicit:** Resource data can be partial or missing,
  and missing data must never look like a healthy zero.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| Show only current usage | Simple and familiar | Hard to know whether usage is high or normal |
| Show only request/limit pressure | Fast to scan | Hides the underlying values unless complete help text is added |
| Show pressure in-row and complete values through help/focus | Best balance of scanning and detail | Requires careful copy and layout density |
| Let high pressure make Pods Watch | Makes pressure more visible | Adds alert-like behavior and threshold noise |
| Add per-container details immediately | More complete for debugging | Too dense for the first menu version |

Recommended option: show compact resource pressure in each visible active Pod
row, with full usage/request/limit values available through help, keyboard
focus, and accessibility text. Keep resource pressure informational in the first
version.

## Dependencies / Assumptions

- The existing Pods tab remains the primary home for Pod resource information.
- The existing Nodes tab resource display remains separate and continues to
  describe node-level CPU and memory.
- Current Pod usage should come from Kubernetes Pod metrics data, and
  request/limit context should come from Pod resource configuration.
- Planning should verify whether existing Kubernetes reads already include the
  needed request/limit context and add only the narrow local read needed for
  current Pod usage if it is absent.
- Planning should preserve the security boundary documented in
  `docs/PERMISSIONS.md`: Kubebar does not query Secrets and does not send
  cluster data to external services.

## Outstanding Questions

### Deferred to Planning

- [Affects R2, R4][Technical] Confirm how to aggregate multi-container Pod
  usage, requests, and limits into a Pod-level summary.
- [Affects R25-R28][Technical] Add regression coverage proving resource data
  display does not change health state.

## Next Steps

-> `/ce:plan` for structured implementation planning
