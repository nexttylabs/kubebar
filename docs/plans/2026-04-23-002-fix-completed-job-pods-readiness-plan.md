---
title: "fix: Exclude completed Job Pods from active readiness"
type: fix
status: active
date: 2026-04-23
origin: docs/brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md
---

# fix: Exclude completed Job Pods from active readiness

## Overview

Treat successfully completed Job Pods as a normal terminal outcome rather than
an active readiness problem. Completed Job Pods should not reduce Pod ready/all
counts, should not appear as active Pod rows by default, and should not push the
menu state to `Watch` or `Bad` on their own.

This is an incremental plan for the completed Job Pod rules added to the Pod UI
requirements. The broader grouped Pods tab work is already covered by
`docs/plans/2026-04-22-004-feat-pod-item-menu-ui-plan.md`.

## Problem Frame

Kubebar currently derives Pod readiness from active readiness signals such as
phase, readiness conditions, and container ready flags. That works for running
workloads, but completed Job Pods are different: they are expected to stop being
Ready after successful completion. Counting them as unready active Pods creates
false `Watch` states and misleading ready/all totals.

The fix should preserve Kubebar's glanceable health model while separating
active workload readiness from successful completed Job history.

## Requirements Trace

- R14a. A successfully completed Job Pod is a normal completed outcome, not an
  unready active Pod.
- R14b. Completed Job Pods do not reduce active Pod ready/all counts in the
  Pods tab summary or Overview Pods card.
- R14c. Completed Job Pods do not move the menu state to `Watch` or `Bad` by
  themselves.
- R14d. If the watched scope contains only completed Job Pods and no active
  Pods, Kubebar remains `OK` and shows `No active pods; completed jobs are OK`.
- R14e. Failed Job Pods remain `Bad`; only successful completion gets the
  completed treatment.
- R14f. The default Pods tab does not list completed Job Pods as active Pod
  rows. A future completed view would need separate neutral presentation.
- R13. Failed, actively restarting, or crash-looping Pods still use `Bad`.
- R25-R27. Unavailable, empty, and stale Pod states stay distinct.

## Scope Boundaries

- No completed Job history view.
- No new health category beyond `OK`, `Watch`, `Bad`, and `Stale`.
- No change to warning event collection or warning rows.
- No change to Kubernetes reads, selectors, setup, or saved watchlist data.
- No deep troubleshooting actions, logs, links, or shell commands.
- No change to failed, pending, unknown, crash-looping, or active unready Pod
  behavior except where a Pod is successfully completed.

## Context & Research

### Relevant Code and Patterns

- `KubebarCore/Services/KubectlClusterReader.swift` decodes Pod phase,
  readiness conditions, container ready flags, and container terminated reasons.
- `makePodSummary(from:)` currently builds `PodSummary` from all decoded Pods.
- `trackedStatus(for:pods:warningEvents:workloadSelectors:)` currently evaluates
  matching Pods without a separate completed/active split.
- `makePodDetailsSection(...)` currently emits watched Pod details for every
  matching Pod.
- `KubebarCore/Services/HealthEvaluator.swift` maps `PodDetail` into active
  `Ready`, `Watch`, and `Bad` rows and builds the Pods tab summary.
- Existing tests in `KubebarTests/Services/KubectlClusterReaderTests.swift`
  cover failed, restarting, pending, unknown, unready, no matching, and matched
  workload Pod behavior.
- Existing tests in `KubebarTests/Models/MenuDisplayModelTests.swift` cover
  Overview Pod ready/all semantics, Pods tab empty/unavailable behavior, and
  Pod row state mapping.

### External References

External research is not needed. The behavior is defined by the local product
requirements and existing Kubernetes fields are already decoded in the reader.

## Key Technical Decisions

- **Introduce an active-vs-completed split at the reader boundary:** The reader
  already owns raw Pod facts and watch-target matching, so it is the right
  place to decide which matched Pods are active for summaries and rows.
- **Use completed Pod facts for empty-state meaning:** If a watched scope has
  completed Pods but no active Pods, the display needs enough information to
  show the completed-friendly empty message instead of generic no-Pod copy.
- **Keep completed Pods out of active rows by default:** Listing them as Ready
  or Watch would mislead; listing them as a new neutral row state is out of
  scope.
- **Preserve failed Job behavior:** `Failed` phase and non-Completed terminated
  reasons continue to count as attention/failure.
- **Do not suppress warning events globally:** A completed Pod alone is normal,
  but existing warning event behavior can still surface real warning events.

## Open Questions

### Resolved During Planning

- **Update the completed Pod behavior in the old Pod UI plan or create a new
  plan?** Create a new incremental plan. The original grouped Pods UI plan is
  completed and should remain as historical context.
- **Should completed Pods count as ready?** No. They are not active Ready Pods;
  they are excluded from active readiness instead.
- **Should completed Pods be shown as a third row state now?** No. The default
  Pods tab should stay focused on active Pods.

### Deferred to Implementation

- **Exact data shape for completed-only watched scopes:** Choose the smallest
  display-model or snapshot addition that lets `HealthEvaluator` distinguish
  completed-only scope from truly empty scope.
- **Exact completion helper names:** Keep names close to existing
  `PodRecord`/`PodDetail` conventions.

## Implementation Units

- [x] **Unit 1: Detect successfully completed Pod records**

**Goal:** Give the reader a reliable way to identify successfully completed Job
Pods separately from active and failed Pods.

**Requirements:** R14a, R14e

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Approach:**
- Add a local Pod-record classification for successful completion.
- Treat Kubernetes `Succeeded` phase as completed.
- Treat successful `Completed` container termination as completed when the Pod
  has no failed, waiting, or non-Completed terminated container state. Do not
  require Ready conditions or container ready flags to remain true after
  successful completion.
- Preserve `Failed` phase and non-Completed terminated reasons as failure.
- Keep the helper local to the reader unless implementation shows a broader
  display-model value is needed.

**Patterns to follow:**
- Existing `PodRecord.isFailed`, `isPending`, `isUnknown`, `isNotReady`, and
  `currentTerminatedState` helpers in `KubectlClusterReader.swift`.
- Existing reader tests for failed, restarting, pending, unknown, and workload
  matching in `KubebarTests/Services/KubectlClusterReaderTests.swift`.

**Test scenarios:**
- Happy path: Pod with `phase: Succeeded` is classified as completed.
- Happy path: Pod whose containers are terminated with `reason: Completed` is
  classified as completed.
- Regression: Pod with `phase: Failed` and terminated `reason: Error` remains
  failure.
- Regression: Pending, Unknown, CrashLoopBackOff, and unready Running Pods are
  not classified as completed.

**Verification:**
- Completed Pod detection is explicit and does not weaken failed or active
  attention states.

- [x] **Unit 2: Exclude completed Pods from active summaries and rows**

**Goal:** Make cluster and watched-scope Pod readiness count only active Pods by
default.

**Requirements:** R14b, R14c, R14f, R25-R27

**Dependencies:** Unit 1

**Files:**
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Approach:**
- Build `PodSummary` from active Pods, excluding successfully completed Pods
  from both numerator and denominator.
- Build watched Pod details from active matching Pods, excluding successfully
  completed Pods from default Pods tab rows.
- Use active matching Pods when deciding tracked item failure or watch state.
- Preserve a completed-only signal for watched scopes so display mapping can
  show the completed-specific empty message.
- Leave invalid Pod JSON and workload selector failure behavior unchanged.

**Patterns to follow:**
- `makePodSummary(from:)` in `KubectlClusterReader.swift`
- `makePodDetailsSection(...)` in `KubectlClusterReader.swift`
- `trackedStatus(for:pods:warningEvents:workloadSelectors:)` in
  `KubectlClusterReader.swift`
- Existing no-matching and workload-only tests in
  `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Test scenarios:**
- Happy path: one Running ready Pod plus one Succeeded Job Pod -> summary is
  `1/1`, not `1/2` or `2/2`.
- Happy path: watched namespace with one active Pod and one completed Job Pod
  produces one default Pod detail row.
- Happy path: watched workload with only completed Job Pods produces no active
  Pod detail rows and does not create a `Watch` tracked item by itself.
- Regression: failed Job Pod still contributes to Bad tracked item behavior.
- Regression: pending, unknown, and unready active Pods still contribute to
  Watch behavior.
- Regression: invalid Pod data still becomes unavailable, not empty.

**Verification:**
- Completed Job Pods no longer distort active ready/all counts or active rows.

- [x] **Unit 3: Display completed-only watched scopes clearly**

**Goal:** Show a completed-friendly OK empty message when the watched scope has
completed Jobs but no active Pods.

**Requirements:** R14c, R14d, R14f, R26, R27

**Dependencies:** Unit 2

**Files:**
- Modify: `KubebarCore/Models/ClusterSnapshot.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Carry the minimal completed-only watched-scope fact needed by
  `HealthEvaluator`.
- Keep `HealthEvaluator` responsible for the display text and state mapping.
- Use `No active pods; completed jobs are OK` for completed-only watched scope.
- Keep the existing `No watched pods found` message for truly empty watched
  scope with no matching active or completed Pods.
- Ensure completed-only state remains `OK` unless another signal such as a
  warning event, failed Pod, stale data, or unavailable section changes the
  status.

**Patterns to follow:**
- Existing `podTabEmptyMessage(from:podDetails:)` in `HealthEvaluator.swift`
- Existing `PodTabDisplay` empty and unavailable display contract in
  `MenuDisplayModel.swift`
- Existing stale and unavailable tests in
  `KubebarTests/Models/MenuDisplayModelTests.swift`

**Test scenarios:**
- Happy path: completed-only watched scope -> menu state is `OK`, Pod tab has no
  active rows, empty message is `No active pods; completed jobs are OK`.
- Happy path: truly empty watched scope -> existing no-watched-pods copy remains
  distinct.
- Regression: stale completed-only display still shows stale marking.
- Regression: warning events can still produce Watch when warning data exists.
- Regression: unavailable Pod data still shows unavailable copy rather than the
  completed-only empty message.

**Verification:**
- The user can tell completed-only scope from no matches and from failed data.

- [x] **Unit 4: Update QA fixtures and runtime documentation**

**Goal:** Preserve the completed Job Pod contract in deterministic QA and docs.

**Requirements:** R14a-R14f

**Dependencies:** Units 1-3

**Files:**
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `docs/qa/operator-verification.md`
- Modify: `scripts/generate-qa-evidence.sh`
- Modify: `scripts/swift-quality-gate.sh`

**Approach:**
- Add completed Job Pod coverage to an existing fixture if it can be done
  without obscuring the fixture's primary purpose; otherwise add focused model
  tests and document the manual check.
- Update runtime invariants to say active Pod readiness excludes successfully
  completed Job Pods.
- Update operator verification so humans know completed Job Pods should not
  create a readiness warning.
- Keep QA copy short and avoid adding a historical Jobs workflow.

**Patterns to follow:**
- Existing fixture metadata checks in
  `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Existing Pod runtime invariants in `docs/architecture/runtime-invariants.md`
- Existing operator verification sections in `docs/qa/operator-verification.md`

**Test scenarios:**
- Happy path: QA or model coverage proves completed Job Pods do not create
  Watch/Bad status.
- Regression: safe metadata checks still reject raw kubectl output, JSON,
  kubeconfig paths, and tokens.
- Regression: existing healthy, watch, bad, stale, and metrics-unavailable
  fixture expectations remain valid.

**Verification:**
- QA and docs describe completed Job Pod behavior consistently.

- [x] **Unit 5: Final validation**

**Goal:** Confirm completed Job Pod handling is complete without weakening real
Pod failure detection.

**Requirements:** R13, R14a-R14f, R25-R27

**Dependencies:** Units 1-4

**Files:**
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`

**Approach:**
- Run focused reader and display-model tests for completed, failed, and active
  unready Pod cases.
- Run the full local Swift quality gate before marking the implementation done.
- Confirm no raw Pod facts leak into SwiftUI as health decisions.

**Test scenarios:**
- Completed Job Pods excluded from active ready/all.
- Completed-only watched scope stays `OK`.
- Failed Job Pods still become Bad.
- Pending, Unknown, partially ready, and CrashLoopBackOff Pods still become
  Watch or Bad according to existing rules.
- Metrics-unavailable and stale states stay distinct.

**Verification:**
- Focused tests and `./scripts/swift-quality-gate.sh local` pass.

## System-Wide Impact

- **Interaction graph:** `KubectlClusterReader` separates completed Pods from
  active Pod facts; `HealthEvaluator` maps the resulting snapshot into
  user-facing `MenuDisplayModel`; SwiftUI still only renders the display model.
- **Error propagation:** Completed Pod handling must not hide Pod read failures
  or failed Job Pods. Unavailable sections still use safe messages.
- **State lifecycle risks:** Stale completed-only displays may preserve old
  facts only through the existing stale path.
- **API surface parity:** No external API, setup, saved config, Kubernetes
  read set, or menu health vocabulary changes.
- **Integration coverage:** Reader tests protect classification; display tests
  protect status and copy; QA/docs protect operator-facing expectations.
- **Unchanged invariants:** Kubernetes Secrets are not queried; stale data does
  not look current; UI does not decide cluster health directly.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Completed Pods accidentally hide failed Jobs | Keep Failed phase and non-Completed termination regression tests |
| Active readiness totals become confusing when all watched Pods completed | Use explicit completed-only empty copy |
| Completed Pods vanish without explanation | Preserve completed-only scope signal and documented operator behavior |
| Warning events from completed Jobs are unexpectedly hidden | Do not suppress warning event handling globally |
| Display model grows more than needed | Carry only the minimal completed-scope fact needed for copy and state |

## Documentation / Operational Notes

- Update runtime invariants with the active-readiness rule.
- Update operator verification with a completed Job Pod check.
- No migration or operator setup change is required.

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md](../brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md)
- Related completed plan: [docs/plans/2026-04-22-004-feat-pod-item-menu-ui-plan.md](2026-04-22-004-feat-pod-item-menu-ui-plan.md)
- Reader: `KubebarCore/Services/KubectlClusterReader.swift`
- Snapshot model: `KubebarCore/Models/ClusterSnapshot.swift`
- Display model: `KubebarCore/Models/MenuDisplayModel.swift`
- Display mapping: `KubebarCore/Services/HealthEvaluator.swift`
- Reader tests: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Display tests: `KubebarTests/Models/MenuDisplayModelTests.swift`
- QA tests: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Runtime rules: `docs/architecture/runtime-invariants.md`
- Operator QA: `docs/qa/operator-verification.md`
