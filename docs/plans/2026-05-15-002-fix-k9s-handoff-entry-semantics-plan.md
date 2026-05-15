---
title: "fix: Correct k9s handoff entry semantics"
type: fix
status: planned
date: 2026-05-15
origin: .imm/specs/2026-05-15-k9s-handoff-entry-corrections.md
---

# fix: Correct k9s handoff entry semantics

## Summary

- Summary: k9s handoff entries follow the corrected landing contract.

Correct the resource handoff slice after manual validation: Overview error
details must keep the `Open in k9s` entry, Node actions must be honest that
they open the Nodes view/list, and Pod actions must be honest that they open a
namespace Pods view/list. The change keeps Kubebar focused on glanceable
Kubernetes health and uses `k9s` only as an external handoff.

## Task

- Type: fix
- Scope: k9s handoff entry semantics
- Owner: imm-work
- Verification: automated plus visible smoke
- Brainstorm manifest: BR-REQ-001, BR-REQ-002, BR-REQ-003, BR-REQ-004, BR-REQ-005, BR-DEC-001, BR-OUT-001, BR-DEFER-001, BR-Q-001

## Origin

The user manually validated the previous k9s resource handoff work and found
three follow-up problems:

- Overview error information can lose the k9s handoff entry.
- Node row handoff opens the Nodes list, not a specific Node, so the entry
  point should be adjusted.
- Pod row handoff opens all Pods under the namespace, so the namespace Pods
  entry is more accurate than a Pod-specific entry.

This is a new slice rather than an append to
`docs/plans/2026-05-15-001-feat-k9s-resource-handoff-plan.md` because the
runtime ledger shows that plan's steps as closed. The new slice corrects the
visible semantics and QA contract without rewriting completed history.

## Brainstorm Manifest

- `BR-REQ-001`: Overview error/detail area must retain a usable k9s handoff
  entry.
- `BR-REQ-002`: Node handoff entry semantics change to Nodes view/list, not
  exact Node positioning.
- `BR-REQ-003`: Pod row handoff changes to a namespace-level Pods view/list
  entry, not exact Pod positioning.
- `BR-REQ-004`: All entries continue to use app-owned context and do not rely
  on Terminal current context.
- `BR-REQ-005`: UI copy, help text, and accessibility labels must accurately
  describe the actual landing point.
- `BR-DEC-001`: Do not use k9s interactive keyboard automation to simulate
  exact positioning.
- `BR-OUT-001`: Logs, describe, edit, exec, delete, port-forward, and other
  deep troubleshooting actions are out of scope.
- `BR-DEFER-001`: Recent Warnings handoff remains deferred.
- `BR-Q-001`: Planner must confirm the Overview state that loses the entry and
  put that state into a verification fixture or test.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 requires an Overview Watch or Bad error-detail state to keep a visible handoff. |
| BR-REQ-002 | covered_by_step | U1 | U1 corrects Node target semantics and copy to Nodes view/list. |
| BR-REQ-003 | covered_by_step | U1 | U1 corrects Pod target semantics and copy to namespace Pods view/list. |
| BR-REQ-004 | covered_by_step | U1 | U1 preserves explicit app-owned context and namespace launch arguments. |
| BR-REQ-005 | covered_by_step | U1 | U1 covers labels, help, accessibility text, and failure copy. |
| BR-DEC-001 | captured_as_decision | Decisions | Stable launch arguments are allowed; interactive keyboard automation is not. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | This slice only corrects existing handoff entries and excludes deep actions. |
| BR-DEFER-001 | deferred | Scope Boundaries | Recent Warnings remains deferred to avoid adding a new entry surface. |
| BR-Q-001 | covered_by_step | U1 | U1 starts by capturing the Overview lost-entry state in a fixture or test before closing. |

## Research

- `CONTEXT.md` defines Kubebar as a native macOS menu bar app for glanceable
  Kubernetes health and uses `Health category` for `OK`, `Watch`, `Bad`, and
  `Stale`.
- `IMMUNE.md` requires plan before code and small independently verifiable
  steps.
- `.imm/memory/current_iteration.json` shows the previous k9s resource handoff
  plan is closed through U3, so this correction is a new slice.
- `docs/architecture/runtime-invariants.md` requires menu rendering to use
  `MenuDisplayModel`, app-owned context as source of truth, no raw command
  transcripts, and external k9s handoffs only.
- `KubebarCore/Models/MenuDisplayModel.swift` currently represents resource
  targets that include Pod and Node names.
- `KubebarCore/Services/K9sHandoffLauncher.swift` currently launches Pod
  targets with `-c pods` in a namespace and Node targets with `-c nodes`; it
  does not pass exact Pod or Node positioning through a stable CLI argument.
- `Kubebar/Views/StatusSummaryView.swift` renders the Overview handoff inside
  the top status region, which is the likely surface for the lost-entry
  Overview state.
- `KubebarCore/QA/MenuStateFixtureCatalog.swift` already has Watch and Bad QA
  states that mention Overview and row-level k9s actions; those states are the
  right place to pin the visible behavior.

## Decisions

- Treat the correction as one outcome step because all three findings share
  one user-visible result: every handoff entry remains present and truthful.
- Do not add interactive k9s search, filtering, or keyboard automation.
- Prefer stable entry targets over exact positioning claims: Nodes view/list
  for Node rows and namespace Pods view/list for Pod rows.
- Keep handoff eligibility and target semantics in display-model or evaluator
  code, not in SwiftUI row views.
- Preserve existing stale, setup, unavailable, and incomplete-state gating.
- Update runtime invariants and QA expectations when behavior copy changes.

## Assumptions

- A Watch or Bad QA fixture can reproduce or protect the Overview error-detail
  state that lost the handoff entry.
- The current launcher behavior is the source of truth for actual landing
  points: `-c nodes` opens a Nodes view/list, and `-c pods` with namespace
  opens the namespace Pods view/list.
- Existing tests can cover launcher arguments and display-copy semantics
  without a live Kubernetes cluster.

## Scope Boundaries

- In scope: Overview handoff visibility in error-detail states, Node list-level
  handoff semantics, namespace Pods list-level handoff semantics, user-facing
  handoff copy, accessibility labels, failure feedback, QA fixture metadata,
  tests, and runtime documentation updates.
- Out of scope: Recent Warnings handoff, exact k9s resource positioning,
  interactive keyboard automation, embedded terminal, logs/describe/edit
  shortcuts, exec, delete, port-forward, restart, raw command transcript
  display, resource mutation, Health category changes, resource usage
  visualization changes, historical trends, and alerting.

## Implementation Units

### Step 1

- Step ID: U1
- Result: k9s handoff entries follow the corrected landing contract.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Verification type: hitl
- Depends on: None
- Test scenarios: Overview Watch or Bad error detail keeps a visible Open in k9s entry; Node row action and failure copy describe the Nodes view/list instead of an exact Node; Pod row action and failure copy describe the namespace Pods view/list instead of an exact Pod; app-owned context and namespace arguments remain explicit; stale setup unavailable or incomplete states omit misleading handoffs; QA smoke checks Overview Pods and Nodes wording in a Watch or Bad fixture

**Goal:** Correct the handoff contract so users see an entry where they need it
and the entry accurately describes the stable `k9s` view it opens.

**Execution note:** test-first

**Requirements:** R1-R9

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `KubebarCore/Services/K9sHandoffLauncher.swift`
- Modify: `KubebarCore/Services/K9sHandoffCoordinator.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/Views/StatusSummaryView.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `Kubebar/Views/NodesTabView.swift`
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `KubebarTests/Services/K9sHandoffLauncherTests.swift`
- Modify: `KubebarTests/Services/K9sHandoffCoordinatorTests.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-05-15-k9s-handoff-entry-corrections.md`

**Approach:**
- Add or adjust characterization tests for the Overview Watch or Bad error
  state before changing the view so the lost-entry regression is pinned.
- Change Pod and Node target semantics to represent stable list-level entry
  points instead of exact resource positioning promises.
- Update action labels, help text, accessibility labels, and failure messages
  so the copy says what `k9s` actually opens.
- Keep launcher arguments structured around app-owned context, namespace when
  applicable, and stable resource views.
- Ensure SwiftUI views render handoff actions from `MenuDisplayModel` values
  and do not infer Kubernetes semantics locally.
- Update QA fixture expected behavior and runtime invariants to match the
  corrected handoff contract.
- Run the Swift quality gate and a visible-app smoke check for a Watch or Bad
  QA state before review.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/compile-and-run.sh --qa-state bad`

**failure_behavior:** If exact Overview loss cannot be reproduced in an
existing fixture, add the smallest QA fixture or test variant that represents
the error-detail state before applying the UI correction.

**security_considerations:** The fix only changes local handoff metadata,
labels, and launch arguments. It must not expose command output, kubeconfig
paths, stderr, or Secrets.
