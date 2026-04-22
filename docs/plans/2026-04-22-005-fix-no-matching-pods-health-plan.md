---
title: fix: Reclassify no matching Pods health
type: fix
status: completed
date: 2026-04-22
---

# fix: Reclassify no matching Pods health

## Overview

Change Kubebar so a watched namespace or workload with no matching Pods is not
classified as `Bad`. The app should still make the condition visible, but it
should not treat "no matching pods" as the same class of failure as failed,
restarting, or crash-looping Pods.

## Problem Frame

`KubectlClusterReader` currently returns a watched item with state `Bad` when a
watch target has no matching Pods. `HealthEvaluator` then promotes any bad
tracked item to a `Bad` cluster status. That makes an empty watched scope look
like a failing cluster even though no failed Pod exists. This conflicts with
the product rule that `Bad` should represent actual attention-worthy failure,
while empty or unavailable data should be visibly distinct.

## Requirements Trace

- R1. A watch target with no matching Pods must not make the cluster state
  `Bad`.
- R2. The watch target should still remain visible with a clear
  "no matching pods" reason.
- R3. Actual failed, restarting, or crash-looping Pods must still produce
  `Bad`.
- R4. Pending, unknown, not-ready, and warning-like Pod states must continue to
  produce `Watch`.
- R5. The Pods tab empty state must remain distinct from unavailable Pod data.
- R6. Runtime documentation must state that no matching Pods is a visible
  watch condition, not a bad Pod failure.

## Scope Boundaries

- No changes to Kubernetes reads, selectors, setup, or saved watchlist data.
- No change to the `OK`, `Watch`, `Bad`, and `Stale` status vocabulary.
- No UI redesign beyond the existing state and reason output driven by the
  display model.
- No change to failed, restarting, crash-looping, pending, unknown, or
  not-ready Pod classification.

## Context & Research

### Relevant Code and Patterns

- `AGENTS.md` requires `HealthEvaluator` to be the single source of truth for
  severity and stale or unavailable data to never look falsely healthy.
- `KubebarCore/Services/KubectlClusterReader.swift` creates
  `TrackedItemStatus` values for watch targets and currently assigns `Bad` to
  no matching Pods.
- `KubebarCore/Services/HealthEvaluator.swift` promotes any tracked item with
  state `Bad` to a bad cluster state.
- `KubebarTests/Services/KubectlClusterReaderTests.swift` has coverage for no
  matching Pods, failed Pods, restarting Pods, and not-ready Pods.
- `KubebarTests/Models/MenuDisplayModelTests.swift` has coverage for Pods tab
  empty and unavailable states, plus overall health-state mapping.
- `docs/architecture/runtime-invariants.md` already distinguishes unavailable
  data from health failure and states that only current failed, waiting, or
  crash-looping Pods may make Pod rows Bad.

### Institutional Learnings

- No `docs/solutions/` directory exists in this repo.
- Recent plans keep Kubebar glanceable: states should communicate severity
  without turning empty or missing data into fake failures.

### External References

- Not used. The behavior is repo-specific and local code already contains the
  relevant health classification patterns.

## Key Technical Decisions

- **Classify no matching Pods as `Watch`:** This keeps the condition visible
  without using the failure severity reserved for actual bad Pods or bad nodes.
- **Keep the reason string stable:** Preserve "no matching pods" so existing UI
  copy and operator meaning remain clear.
- **Avoid fake affected Pod counts:** No matching Pods should not report `0`
  affected Pods as if there were affected Pod objects. Details can still expand
  if a related warning exists.
- **Add regression coverage at both source and display layers:** The reader
  test proves the tracked item state, while the display test proves the cluster
  state is not promoted to `Bad`.

## Open Questions

### Resolved During Planning

- **Should no matching Pods be `OK` or `Watch`?** Use `Watch`. The target is in
  the user's watchlist and the missing match is still useful to notice, but it
  is not a hard failure.

### Deferred to Implementation

- **Exact test placement:** Keep changes near existing no matching Pod and Pods
  tab empty tests unless implementation reveals a more focused location.

## Implementation Units

- [x] **Unit 1: Reclassify no matching Pods at the tracked-item source**

**Goal:** Make no matching Pods produce a visible non-bad tracked item.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Approach:**
- Change the no matching Pods branch so it returns `Watch` instead of `Bad`.
- Preserve the "no matching pods" reason.
- Remove the fake `affectedPodCount: 0` value unless a test reveals existing UI
  needs it for a specific reason.
- Leave failed, restarting, not-ready, warning-only, and all-running branches
  unchanged.

**Patterns to follow:**
- Existing `trackedStatus` ordering in `KubectlClusterReader.swift`.
- Existing tests for failed, restarting, and not-ready Pods in
  `KubebarTests/Services/KubectlClusterReaderTests.swift`.

**Test scenarios:**
- Happy path: workload target with zero matching Pods -> tracked item state is
  `Watch`, reason is "no matching pods", and example Pod names are empty.
- Regression: failed Pods still return `Bad`.
- Regression: restarting Pods still return `Bad`.
- Regression: pending or unknown Pods still return `Watch`.

**Verification:**
- No matching Pods no longer originate as a bad tracked item.
- Existing failure-state tests continue to pass.

- [x] **Unit 2: Lock display-level health behavior**

**Goal:** Ensure the full display model does not report a bad cluster solely
because a watched target has no matching Pods.

**Requirements:** R1, R2, R5

**Dependencies:** Unit 1

**Files:**
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Extend the existing Pods tab empty-state coverage or add a nearby focused test
  using a snapshot with no Pod details and a tracked item reason of
  "no matching pods".
- Assert the display state is `Watch`, not `Bad`.
- Assert the primary status reason stays useful and the Pods tab remains empty,
  not unavailable.

**Patterns to follow:**
- Existing `podTabDistinguishesUnavailableAndEmptyWatchedPods` coverage.
- Existing `HealthEvaluator().evaluate(snapshot:now:)` model tests.

**Test scenarios:**
- Happy path: empty Pod details plus no matching Pods tracked item -> display
  state is `Watch`, primary reason is "no matching pods", and Pods tab empty
  message is "No watched pods found".
- Regression: unavailable Pod data still shows a Pod unavailable message rather
  than the empty watched Pods message.

**Verification:**
- Display-level behavior matches the intended severity distinction.

- [x] **Unit 3: Update runtime invariant documentation**

**Goal:** Record the new severity rule so future changes do not reclassify no
matching Pods as a hard failure.

**Requirements:** R6

**Dependencies:** Unit 1

**Files:**
- Modify: `docs/architecture/runtime-invariants.md`

**Approach:**
- Add a concise invariant near the Pod data rules: no matching Pods is a visible
  watch condition, not a Bad Pod failure.
- Keep wording aligned with existing rules about unavailable data and current
  failed or crash-looping Pods.

**Patterns to follow:**
- Existing Pod status invariants in `docs/architecture/runtime-invariants.md`.

**Test scenarios:**
- Test expectation: none -- documentation-only change.

**Verification:**
- Documentation describes the new product contract clearly.

## System-Wide Impact

- **Interaction graph:** `KubectlClusterReader` shapes tracked-item state;
  `HealthEvaluator` consumes that state when choosing menu status and reason.
- **Error propagation:** No matching Pods remains visible as a watch reason;
  real Pod read failures still surface through unavailable section messages.
- **State lifecycle risks:** Empty watched scope must not be confused with
  stale data or unavailable data.
- **API surface parity:** No public API, setup, config, or UI control changes.
- **Integration coverage:** Reader and model tests together prove the source
  classification and final menu state.
- **Unchanged invariants:** Actual failed, restarting, crash-looping, not-ready,
  warning, stale, and unavailable states keep their current behavior.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Empty watched scope becomes too quiet | Use `Watch`, not `OK`, and preserve the visible reason text. |
| Real bad Pod states are weakened by accident | Keep failed and restarting regression tests passing. |
| Empty and unavailable Pod states become blurred | Keep model coverage for both empty watched Pods and unavailable Pod data. |

## Documentation / Operational Notes

- Update runtime invariants because this is a user-visible severity rule.
- No operator action or migration is required.

## Sources & References

- Related code: `KubebarCore/Services/KubectlClusterReader.swift`
- Related code: `KubebarCore/Services/HealthEvaluator.swift`
- Related tests: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Related tests: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Related docs: `docs/architecture/runtime-invariants.md`
