---
title: "fix: Move k9s list entries to group level"
type: fix
status: planned
date: 2026-05-15
origin: .imm/specs/2026-05-15-k9s-handoff-entry-placement.md
---

# fix: Move k9s list entries to group level

## Summary

- Summary: k9s list-level handoffs use group-level entries.

Move Pods and Nodes k9s affordances to the UI level that matches their actual
`k9s` landing point. Pods should expose namespace-level entries on namespace
sections, and Nodes should expose one list-level entry near the Nodes tab
summary. Concrete Pod and Node rows should stop implying exact resource
positioning.

## Task

- Type: fix
- Scope: k9s handoff entry placement
- Owner: imm-work
- Verification: automated plus Computer Use visible check
- Brainstorm manifest: BR-REQ-001, BR-REQ-002, BR-REQ-003, BR-REQ-004, BR-REQ-005, BR-DEC-001, BR-OUT-001, BR-OUT-002, BR-Q-001

## Origin

The user manually validated the corrected k9s handoff semantics and found a
remaining mismatch: Pods and Nodes buttons are still positioned on specific
rows, but their targets open list-level `k9s` resources. The entry placement
should match the actual landing point.

This is a new slice rather than an append to
`docs/plans/2026-05-15-002-fix-k9s-handoff-entry-semantics-plan.md` because
that plan is closed in `.imm/memory/current_iteration.json` with QA pass
evidence. This slice preserves that closed history and narrows only the
placement issue found during the next validation pass.

## Brainstorm Manifest

- `BR-REQ-001`: Pods k9s entry must move from Pod row level to namespace group
  level.
- `BR-REQ-002`: Nodes k9s entry must move from Node row level to Nodes tab
  summary/header level.
- `BR-REQ-003`: Entry position, button copy, help text, and accessibility
  labels must match the actual `k9s` landing point.
- `BR-REQ-004`: All entries continue to use app-owned context.
- `BR-REQ-005`: Row-level Pod and Node entries must no longer imply exact
  resource jumps.
- `BR-DEC-001`: Match entry level to existing stable `k9s` list landing
  points instead of simulating exact positioning.
- `BR-OUT-001`: Logs, describe, edit, exec, delete, port-forward, and other
  deep troubleshooting actions are out of scope.
- `BR-OUT-002`: Health category and resource health judgment are out of scope.
- `BR-Q-001`: Planner must confirm whether automated view/accessibility
  coverage is available; otherwise include Bad QA Computer Use validation.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 moves Pods affordances to namespace section scope. |
| BR-REQ-002 | covered_by_step | U1 | U1 moves Nodes affordance to tab summary/header scope. |
| BR-REQ-003 | covered_by_step | U1 | U1 updates visible copy, help, accessibility labels, and QA metadata. |
| BR-REQ-004 | covered_by_step | U1 | U1 keeps the existing display-model targets and launcher contract app-owned. |
| BR-REQ-005 | covered_by_step | U1 | U1 removes misleading row-level Pod and Node affordances. |
| BR-DEC-001 | captured_as_decision | Decisions | The fix changes entry placement, not k9s positioning mechanics. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | This slice only moves handoff entry points and excludes deep actions. |
| BR-OUT-002 | out_of_scope | Scope Boundaries | Health category logic remains owned by HealthEvaluator and is unchanged. |
| BR-Q-001 | covered_by_step | U1 | U1 requires automated/fixture checks where practical plus Bad QA Computer Use validation. |

## Research

- `CONTEXT.md` defines Kubebar as a native macOS menu bar app for glanceable
  Kubernetes health and defines Health category as `OK`, `Watch`, `Bad`, or
  `Stale`.
- `.imm/memory/current_iteration.json` shows the previous handoff semantics
  plan closed with QA pass evidence.
- Computer Use validation of the Bad QA fixture showed Overview has
  `Open qa-payments in k9s`, Pods rows have `Open qa-payments Pods in k9s` or
  `Open qa-api Pods in k9s`, and Nodes rows have `Open Nodes in k9s`.
- `Kubebar/Views/PodsTabView.swift` currently renders the k9s button inside
  each `PodRowView`, after row content.
- `Kubebar/Views/NodeDetailsView.swift` currently renders the k9s button
  inside each `NodeRowView`, after node content.
- `K9sResourceTarget` already has list-level targets:
  `.podList(namespace:)` and `.nodeList`.
- `K9sHandoffLauncher` already maps `.podList` to `-c pods` with namespace and
  `.nodeList` to `-c nodes` without namespace.
- The rejected decision
  `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  does not conflict; it rejected history/alert/dashboard expansion, while this
  slice only moves existing external handoff entry placement.

## Decisions

- Treat this as one outcome step because the user-visible result is one
  placement contract: list-level handoffs appear at group/list level.
- Do not change the launcher target semantics introduced by the previous
  slice.
- Pods tab should expose namespace-level k9s entry near each namespace header.
- Nodes tab should expose a single Nodes list-level entry near the summary or
  header.
- Pod and Node rows should not render k9s arrows while their target is a
  list-level view.
- Keep Overview handoff behavior unchanged.

## Assumptions

- Existing Swift tests can cover display-model and QA fixture expectations for
  entry scope without live Kubernetes.
- SwiftUI view layout for menu bar content still needs a visible check; use
  the Bad QA fixture with Computer Use because it includes both Pods and Nodes
  handoffs.
- The current list-level launcher contract is correct and should be preserved.

## Scope Boundaries

- In scope: Pods namespace section entry placement, Nodes tab summary/header
  entry placement, row-level handoff removal for Pods and Nodes, display-model
  shape needed for those placements, copy/help/accessibility updates, QA
  fixture metadata, tests, and runtime invariant updates.
- Out of scope: Overview handoff changes, Recent Warnings handoff, exact k9s
  Pod or Node positioning, keyboard automation, embedded terminal,
  logs/describe/edit/exec/delete/port-forward/restart actions, resource
  mutation, Health category changes, resource usage visualization changes,
  history, and alerting.

## Implementation Units

### Step 1

- Step ID: U1
- Result: k9s list-level handoffs use group-level entries.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Verification type: hitl
- Depends on: None
- Test scenarios: Pods namespace section exposes one k9s action for that namespace; Pod rows do not expose k9s actions; Nodes summary or header exposes one k9s action; Node rows do not expose k9s actions; Overview handoff remains visible in Bad QA state; app-owned context and resource view launcher tests remain green; Computer Use bad QA check confirms entry placement

**Goal:** Align Pods and Nodes handoff affordance placement with the stable
list-level `k9s` resource views they open.

**Execution note:** test-first

**Requirements:** R1-R8

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `Kubebar/Views/NodeDetailsView.swift`
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `KubebarCore/Services/K9sHandoffLauncher.swift`
- Reference: `.imm/specs/2026-05-15-k9s-handoff-entry-placement.md`

**Approach:**
- Add failing tests or fixture assertions that encode section/header-level
  handoff ownership and absence of row-level Pod/Node actions.
- Move Pod list handoff data from rows to namespace section displays, or add a
  section-level handoff while clearing row-level handoffs.
- Move Node list handoff data from rows to the Nodes tab display, or add a
  tab-level handoff while clearing row-level handoffs.
- Render compact k9s buttons beside the namespace section label and Nodes
  readiness summary/header.
- Update help text, accessibility labels, QA expected behavior, and runtime
  invariants to state that Pods and Nodes handoffs are group/list entries.
- Preserve existing launcher behavior and stale/unavailable gating.
- Run the Swift quality gate and a Bad QA visible check with Computer Use.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/compile-and-run.sh --qa-state bad`
- Computer Use visible check on the Bad QA fixture: Overview keeps its action,
  Pods actions appear on namespace sections, and Nodes action appears on the
  Nodes summary/header.

**failure_behavior:** If SwiftUI view-level assertions cannot directly inspect
the final button positions, keep automated display-model and QA fixture tests
for ownership and require Computer Use evidence before QA pass.

**security_considerations:** The change only moves local UI affordances and
does not add data transmission, Secrets access, raw command output, or
Kubernetes mutation.
