---
date: 2026-04-22
topic: kubebar-overview-design
---

# Kubebar Overview Design Requirements

## Problem Frame

Kubebar's Overview should match the provided design direction more closely: a compact visual cluster snapshot with a top cluster/status row, nodes, pods, metrics, and recent warnings. The current Overview is still shaped around a visible "Watching" section and long health-description sentences, which makes the first screen feel more like a status explanation than a quick operational glance.

The change should make Overview answer: what cluster is this, what are the main resource and node signals, and what warnings appeared recently?

## Visual Aid

```text
Tabs: Overview | Nodes | Pods | Events

Overview
  Cluster/context + health icon + one-line status text
  Nodes card                Pods card
  CPU card                  Memory card
  Recent Warnings
    [reason] object scope                         age / repeats
    latest message, shortened only when needed
    [reason] object scope                         age / repeats
    latest message, shortened only when needed
```

## Requirements

**Overview layout**
- R1. Overview must start with one top row showing cluster/context information, a health-state icon, and a short status text.
- R2. Overview must use four required cards below the top row: Nodes, Pods, CPU, and Memory.
- R3. Overview must keep the existing top tabs: `Overview`, `Nodes`, `Pods`, and `Events`.
- R4. Overview must stay readable in the current menu width of about 360 points and must not become a full dashboard surface.
- R5. Overview's required first-screen areas are top cluster/status row, Nodes card, Pods card, CPU card, Memory card, and Recent Warnings.
- R6. The card layout should use a compact two-column rhythm where it fits, with section heights constrained so Recent Warnings remains visible without turning the menu into a scrolling dashboard.
- R6a. The top row and four cards must remain visible ahead of warning overflow; Recent Warnings should cap visible rows on Overview and leave deeper browsing to Events.

**Metrics and data trust**
- R7. Cluster CPU and memory metrics must come from actual current usage values read through `kubectl`, not requests, limits, static placeholder values, or a separate monitoring dependency.
- R8. If `kubectl` has never provided a metric, the metric card must show an unavailable state.
- R9. If a previous real metric exists but the latest refresh fails or ages out, the metric card may keep the old value only when clearly marked stale.
- R10. A `0` value is valid only when it came from a successful real metric read; missing metrics must not be rendered as `0`.
- R11. Planning must account for a new kubectl-backed metrics read for CPU and memory values.
- R12. Trend rendering is out of the required Overview layout unless explicitly added later with real historical samples.
- R13. Stale, unavailable, and neutral empty states must look different enough to avoid misreading: stale means old real data, unavailable means no usable data, neutral empty means no warning rows.

**Language and warnings**
- R14. Overview must remove the `Watching` label and long health-description sentences such as "Cluster looks healthy" or "needs watching".
- R15. Overview must still provide a readable one-line top-row health description for scanability and accessibility, paired with the health-state icon.
- R16. Overview must show warning events under the section title `Recent Warnings`.
- R17. Recent warning rows must show the warning reason, affected object, and age in a compact format.
- R18. When there are no warning events, the empty state must stay neutral and must not become a health claim.
- R18a. Recent warning rows must make the warning reason the primary visible label because it is usually the operator's fastest clue about the failure mode.
- R18b. Each visible warning row must show the affected object in a stable object-scope format, including namespace when available, so similarly named resources are not confused.
- R18c. Each visible warning row must show recency and repeat count when available; repeat count should clarify whether this is a single event or an ongoing repeated symptom.
- R18d. Each visible warning row should include the latest warning message when it adds diagnostic value, but the message must remain secondary to reason, object, and recency.
- R18e. Long warning messages must be shortened in the visible row without losing access to the full text through hover/help or accessibility text.
- R18f. Recent Warnings must visually distinguish tracked-object warnings from ordinary cluster warnings without reintroducing `Watching` wording.
- R18g. If warning events are unavailable, the section must explain that warning data could not be read; it must not look like a no-warning state.
- R18h. If warning rows overflow the Overview cap, the overflow indicator must clearly tell the user that additional warnings are available in the Events tab.
- R18i. Recent warning accessibility text must preserve the same information priority as the visual row: reason, affected object, age, repeat count, and latest message.

**Preserved product behavior**
- R19. User-selected tracked objects must remain first-screen signals through the top-row status and pinned warning priority, but Overview must not show a separate `Watching` label, section, or tracked-focus card.
- R20. Overview must prioritize tracked objects that need attention when choosing the top-row health text and Recent Warnings ordering.
- R21. Deeper node, pod, and event details remain in their dedicated tabs.

## Success Criteria

- Overview visually resembles the provided design direction with one top status row and four core cards.
- Nodes show `<ready count>/<all count>` on Overview without opening the Nodes tab.
- Pods show `<ready count>/<all count>` on Overview without opening the Pods tab.
- CPU and memory values are traceable to `kubectl` data or clearly marked unavailable.
- Overview no longer contains `Watching` or long health prose such as "Cluster looks healthy" or "needs watching".
- Warning events appear as `Recent Warnings`.
- Each recent warning row answers, in order: what happened, where it happened, how recent it is, whether it repeated, and the latest useful message.
- Tracked-object warnings are recognizable without using `Watching` language.
- No-warning, unavailable-warning, and overflow-warning states are visually and textually distinct.
- User-selected tracked objects influence the top-row status text and warning ordering without appearing as a `Watching` section.
- Recent Warnings cannot push the top row or four cards out of the first scan area.
- Missing or stale data cannot be mistaken for a normal current reading.

## Scope Boundaries

- This change does not add a Prometheus, Grafana, custom metrics pipeline, or external monitoring dependency.
- This change does not turn Kubebar into a full cluster dashboard.
- This change does not remove the existing Nodes, Pods, or Events tabs.
- This change does not remove watchlist behavior from Kubebar; it changes Overview so tracked objects influence the top status and pinned warnings instead of appearing as a separate `Watching` section.
- This change does not add deep troubleshooting actions.

## Key Decisions

- **Overview becomes scan-first, not generic metrics-first:** The provided design is best served by a top cluster/status row plus four core cards.
- **Watchlist wording changes, not the product role:** This honors the request to remove `Watching` wording while still letting the user's selected objects influence the top health description and warning priority on the first screen.
- **Recent warnings replaces the single notice pattern:** A list of recent warning rows is more useful than one generic Overview notice for the visual direction.
- **Warning rows lead with cause, then scope:** Operators scan warnings to find the failure mode first, then confirm which object is affected. Reason-first rows should still show object and namespace clearly enough to avoid ambiguity.
- **Message text is secondary context:** Kubernetes event messages can be noisy or long. They should help when useful, but they should not bury reason, object, age, or repeat count.
- **Kubectl remains the data boundary:** CPU, memory, nodes, pods, and warnings should all be derived from `kubectl`-backed reads so Kubebar continues to use the operator's existing cluster access.

## Alternatives Considered

- **Object-first rows:** Leading with object name can help when the operator already knows which workload is failing, but it makes mixed cluster warnings harder to scan because common reasons are no longer visually aligned.
- **Message-first rows:** Leading with the full event message carries the most detail, but it is too verbose for a menu-bar Overview and makes repeated warnings look inconsistent.
- **Severity badges per warning:** Warning events already share the Warning event type in this section; adding another severity badge would add visual weight without clarifying the immediate operator question.

## Dependencies / Assumptions

- Existing Kubebar cluster reads already use `kubectl` for nodes, pods, workloads, and warning events.
- CPU and memory availability may depend on whether the target cluster exposes real usage metrics through data that `kubectl` can read.
- The design mockup is directional: spacing, hierarchy, and content priority matter more than exact pixel matching.

## Outstanding Questions

None.

## Next Steps

-> `/ce:plan` for structured implementation planning
