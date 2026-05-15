---
title: "feat: Add k9s resource handoff"
type: feat
status: planned
date: 2026-05-15
origin: .imm/specs/2026-05-15-k9s-resource-handoff.md
---

# feat: Add k9s resource handoff

## Summary

- Summary: Resource rows can open the matching target in k9s.

Expand Kubebar's existing `Open in k9s` handoff from the Overview top status to
resource-level entry points on existing watchlist, Pod, and Node rows. The
change should reduce the jump from "I see the affected resource" to "inspect it
in k9s" while keeping Kubebar a glanceable Kubernetes health surface.

## Task

- Type: feat
- Scope: k9s resource handoff
- Owner: imm-work
- Verification: automated plus visible smoke
- Brainstorm manifest: BR-REQ-001, BR-REQ-002, BR-REQ-003, BR-REQ-004, BR-DEC-001, BR-DEC-002, BR-OUT-001, BR-DEFER-001, BR-Q-001

## Origin

The user asked to analyze the current k9s jump logic and expand it into entry
points from resources to viewing the corresponding resources in `k9s`.

`imm-brainstorm` found that the existing handoff is intentionally narrow: it is
computed in `HealthEvaluator`, stored as `OverviewDisplay.k9sHandoff`, rendered
only in `StatusSummaryView`, and launched by `K9sHandoffLauncher` with explicit
`--context` and `-n` values. The launcher currently targets only a namespace,
even for workload watch targets.

This is a new slice rather than an append to
`docs/plans/2026-04-23-004-feat-k9s-handoff-plan.md` because that prior plan
implemented the first namespace-level handoff and explicitly deferred exact
workload or pod positioning.

## Brainstorm Manifest

- `BR-REQ-001`: Expand k9s handoff target from `context+namespace` to express
  namespace, workload, Pod, and Node targets.
- `BR-REQ-002`: Add explicit external k9s entry points in Watchlist, Pods tab,
  and Nodes tab.
- `BR-REQ-003`: All entries must use app-owned context and must not depend on
  Terminal current context.
- `BR-REQ-004`: Stale, setup, and incomplete target states must not show
  misleading k9s entries.
- `BR-DEC-001`: Entry is a deliberate button or action, not automatic launch.
- `BR-DEC-002`: k9s remains the external deep inspection tool; Kubebar does not
  add deeper troubleshooting UI.
- `BR-OUT-001`: Logs, embedded terminal, command transcripts, watch streams,
  and resource mutation actions are out of scope.
- `BR-DEFER-001`: Recent Warnings handoff is deferred.
- `BR-Q-001`: Exact target positioning should prefer resource view plus filter;
  if k9s does not provide a stable shallow command, do not simulate keyboard
  navigation.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | Typed targets are represented in MenuDisplayModel. |
| BR-REQ-002 | covered_by_step | U3 | Row affordances are the UI outcome. |
| BR-REQ-003 | covered_by_step | U2 | The launcher keeps explicit app-owned context. |
| BR-REQ-004 | covered_by_step | U1 | Eligibility is represented before views render actions. |
| BR-DEC-001 | captured_as_decision | Decisions | Row entry remains deliberate. |
| BR-DEC-002 | captured_as_decision | Scope Boundaries | Kubebar stays glanceable and k9s remains external. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | This slice only opens k9s views and excludes deep actions. |
| BR-DEFER-001 | deferred | Scope Boundaries | Recent Warnings handoff stays deferred to avoid widening the first slice. |
| BR-Q-001 | resolved_as_assumption | Assumptions | Use stable k9s resource view plus filter when available. |

## Research

- `CONTEXT.md` defines Kubebar as a native macOS menu bar app for glanceable
  Kubernetes health, and Resource usage visualization as display-only current
  snapshot indicators.
- `docs/architecture/runtime-invariants.md` requires `MenuDisplayModel` as the
  only menu rendering input, app-owned context as source of truth, no raw
  command transcripts, and deep troubleshooting out of version 1.
- `docs/brainstorms/2026-04-23-kubebar-k9s-handoff-requirements.md` required
  namespace-level handoff first and allowed exact workload or pod positioning
  only if it stayed inside a shallow external handoff boundary.
- `docs/plans/2026-04-23-004-feat-k9s-handoff-plan.md` deferred exact
  workload or pod positioning after the initial namespace-level handoff.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  rejects expanding resource display work into dashboards, history, or alerts;
  this plan avoids that by adding only external handoff actions.
- `KubebarCore/Models/MenuDisplayModel.swift` currently has
  `K9sHandoffTarget` with only `contextName` and `namespace`.
- `KubebarCore/Services/K9sHandoffLauncher.swift` launches Terminal with
  `k9s --context <context> -n <namespace>` through an injectable
  `CommandRunning` boundary.
- `KubebarCore/Services/K9sHandoffCoordinator.swift` already models idle,
  opening, and failed launch state for a matching handoff target.
- `Kubebar/Views/StatusSummaryView.swift` is the only current handoff
  affordance.
- `Kubebar/Views/PodsTabView.swift` and `Kubebar/Views/NodeDetailsView.swift`
  render concrete Pod and Node rows from display-model data but have no action
  callbacks today.
- k9s command docs confirm `--context`, `-n`, and `-c` can launch into an
  explicit context, namespace, and resource view. The docs also describe
  resource filters in interactive command mode, so implementation should avoid
  brittle interactive keystroke automation unless a stable CLI form is proven:
  https://k9scli.io/topics/commands/

## Decisions

- Treat this as three outcome steps: typed target model, launcher and state
  support, then row-level UI affordances.
- Preserve the existing Overview handoff behavior while generalizing its target
  shape.
- Keep handoff targets as display-model values, not raw Kubernetes records or
  view-inferred command fragments.
- Add only deliberate icon/button actions on rows; row text remains primarily
  informational.
- Prefer stable `k9s` launch arguments: context, namespace when applicable,
  resource view, and optional safe filter. Do not simulate k9s keyboard input.
- Keep launch feedback state separate from Health category.
- Defer Recent Warnings handoff.

## Assumptions

- Existing display fixtures and unit tests can cover target eligibility without
  live Kubernetes access.
- k9s resource view aliases for supported built-in kinds are stable enough for
  launcher tests when represented as structured values.
- If exact name filtering is not reliable through launch arguments, opening the
  closest resource view is still a useful, safe handoff.
- Existing `CONTEXT.md` vocabulary is sufficient; no new canonical term is
  needed.

## Scope Boundaries

- In scope: typed k9s handoff targets, launcher argument construction,
  coordinator/view-model support for multiple row targets, Watchlist row
  actions, Pods tab row actions, Nodes tab row actions, focused tests, and
  runtime documentation updates.
- Out of scope: Recent Warnings handoff, embedded terminal, logs/describe/edit
  shortcuts, exec, delete, port-forward, restart, command transcript display,
  watch streams, resource alerting, metrics history, and external monitoring
  integrations.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Resource handoff targets are represented in MenuDisplayModel.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: Overview namespace handoff still works; workload target carries kind and name; Pod rows carry namespace and Pod name; Node rows carry Node name without namespace; stale and unavailable displays omit broken handoffs

**Goal:** Generalize the display-model handoff contract so views can render
safe row-level actions without deciding Kubernetes target semantics.

**Execution note:** test-first

**Requirements:** R1-R8, R10-R12

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Reference: `.imm/specs/2026-05-15-k9s-resource-handoff.md`
- Reference: `docs/architecture/runtime-invariants.md`

**Approach:**
- Replace the namespace-only handoff target with a typed target that can
  represent namespace, workload, Pod, and Node resources while preserving safe
  display labels.
- Keep `OverviewDisplay.k9sHandoff` compatible at the behavior level by
  mapping its current namespace target into the new target shape.
- Add optional handoff values to `WatchItemDisplay`, `PodItemDisplay`, and
  `NodeItemDisplay` only when the current display data is fresh and target
  fields are complete.
- Use `HealthEvaluator` to populate handoff targets; SwiftUI views should only
  render the provided actions.
- Keep raw command strings and executable details out of the display model.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** If adding targets to every row risks noisy UI or unclear
eligibility, keep the model support complete but gate visibility in U3 to the
least crowded rows first.

**security_considerations:** Handoff values are safe display strings and local
target identifiers only. No Secrets are queried, no raw command output is
stored, and no cluster data leaves the app.

### Step 2

- Step ID: U2
- Result: Typed resource handoffs open through the k9s launch flow.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: 1
- Test scenarios: namespace target launches with explicit context and namespace; workload target includes resource view and name when stable; Pod target opens pod view in namespace; Node target opens node view without namespace fallback; special characters stay safely quoted; launch failure message names the intended target without raw stderr

**Goal:** Extend the existing injectable launch boundary and coordinator so any
typed resource handoff target can be opened with safe feedback.

**Execution note:** characterization-first

**Requirements:** R2-R7, R10-R11

**Dependencies:** U1

**Files:**
- Modify: `KubebarCore/Services/K9sHandoffLauncher.swift`
- Modify: `KubebarCore/Services/K9sHandoffCoordinator.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarTests/Services/K9sHandoffLauncherTests.swift`
- Modify: `KubebarTests/Services/K9sHandoffCoordinatorTests.swift`
- Reference: `KubebarCore/Services/CommandRunner.swift`

**Approach:**
- Change the launcher protocol to accept the typed handoff target rather than
  separate context and namespace strings.
- Build k9s invocation from structured target values: explicit context,
  optional namespace, resource view, and optional resource name filter.
- Keep AppleScript or Terminal bridge details contained inside
  `K9sHandoffLauncher`.
- Preserve duplicate-activation protection and target-specific feedback in
  `K9sHandoffCoordinator`.
- Update failure copy to identify the intended resource target safely.
- Avoid interactive keystroke automation. If exact name filtering is unstable,
  omit the filter and open the closest stable resource view.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** If a target kind cannot be represented with stable k9s
arguments, launcher support must degrade to the closest safe context,
namespace, and resource view rather than inventing an interactive script.

**security_considerations:** The launcher must continue to pass user-controlled
context and resource names safely through structured arguments or focused
quoting. Failure output must not expose stderr, command lines, or kubeconfig
paths.

### Step 3

- Step ID: U3
- Result: Resource rows expose deliberate k9s handoff actions.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: 2
- Test scenarios: Watchlist workload action opens its target; Pod row action opens the Pod target; Node row action opens the Node target; actions are keyboard and accessibility reachable; rows without handoff targets show no broken action; visible smoke confirms row layout remains scannable

**Goal:** Render compact row-level handoff affordances that let users jump from
the resource they are looking at to the matching external `k9s` view.

**Verification type:** hitl

**Execution note:** test-first

**Requirements:** R1-R12

**Dependencies:** U2

**Files:**
- Modify: `Kubebar/Views/WatchlistSectionView.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `Kubebar/Views/NodeDetailsView.swift`
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`

**Approach:**
- Pass a single `onOpenK9sHandoff` action that accepts a handoff target through
  the menu view tree.
- Render small icon-button actions only when the row's display model contains a
  handoff target.
- Keep row text, ready counts, issue text, and resource usage visualization as
  the primary scan surface.
- Add help and accessibility labels that name the external action and target.
- Disable or ignore only the matching target while it is opening.
- Update QA fixture expectations and runtime invariants to document row-level
  handoff boundaries.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=watch ./scripts/compile-and-run.sh`
- Inspect Watchlist, Pods tab, and Nodes tab: action icons fit, keyboard focus
  can reach them, and row text remains readable.

**failure_behavior:** If adding actions to all row types crowds the menu, keep
the model and launcher support but hide the lowest-value visible affordance
behind a focused follow-up rather than degrading row readability.

**security_considerations:** UI actions only launch the user's local `k9s` with
safe target values already present in `MenuDisplayModel`. They must not expose
raw command output or add mutation shortcuts.

## Validation Notes

- Use the system Immune-Brain CLI:
  `imm-plan docs/plans/2026-05-15-001-feat-k9s-resource-handoff-plan.md --json`.
