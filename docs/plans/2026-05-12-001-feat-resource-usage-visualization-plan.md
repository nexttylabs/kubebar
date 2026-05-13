---
title: feat: Add resource usage visualization
type: feat
status: planned
date: 2026-05-12
origin: .imm/specs/2026-05-12-resource-usage-visualization.md
---

# feat: Add resource usage visualization

## Summary

- Summary: Resource usage becomes visually scannable.

Add lightweight current-snapshot CPU and memory visualization to the existing
Overview, Nodes, and Pods resource displays. The work completes the existing
progress-bar contract rather than adding a dashboard: users should be able to
scan usage pressure faster while health state, stale handling, and unavailable
metrics semantics stay unchanged.

## Task

- Type: feat
- Scope: resource usage visualization
- Owner: imm-work
- Verification: automated

## Origin

The user asked to analyze current usage display and add charts to improve user
experience. `imm-brainstorm` narrowed "charts" to lightweight resource usage
visualization because prior Pod resource requirements explicitly excluded
charts, trends, and external monitoring dependencies.

## Research

- `docs/architecture/runtime-invariants.md` requires UI to render
  `MenuDisplayModel`, keeps `HealthEvaluator` as the source of severity, and
  says missing CPU or memory values must not render as `0`.
- `docs/brainstorms/2026-04-24-kubebar-pod-resource-display-requirements.md`
  adds Pod resource text but explicitly excludes charts, history, trends, and
  sparklines.
- `docs/plans/2026-04-27-001-feat-ui-ux-improvements-plan.md` already planned
  resource progress bars, and the code now has `InlineProgressBar` plus progress
  fields on Overview, Node, and Pod display models.
- `KubebarCore/Services/HealthEvaluator.swift` currently formats CPU and memory
  text but does not consistently populate progress values.
- `Kubebar/Views/OverviewTabView.swift`, `Kubebar/Views/NodeDetailsView.swift`,
  and `Kubebar/Views/PodsTabView.swift` already contain conditional progress-bar
  rendering paths.
- `KubebarCore/Models/MenuDisplayModel.swift` has a single
  `PodItemDisplay.resourceProgress`, which is ambiguous because Pod resource
  text has separate CPU and Memory basis rules.
- No `docs/solutions/` entry with `rejected: true` was found for this approach.
- `CONTEXT.md` was added to make "resource usage visualization" the canonical
  term and prevent "chart" from expanding into trends or dashboards.

## Decisions

- Treat this as one outcome unit: resource usage becomes visually scannable
  across Overview, Nodes, and Pods.
- Reuse existing metrics reads and display strings; do not add Kubernetes reads.
- Compute progress in `HealthEvaluator` and pass it through `MenuDisplayModel`.
- Model Pod CPU and Memory progress separately unless implementation proves a
  single value is clearer and updates the spec before coding.
- Keep `InlineProgressBar` as the first implementation vehicle; any visual
  refinement must stay compact and native-feeling.
- Clamp progress for rendering, but preserve unavailable values as `nil`.
- Do not let resource progress affect health category decisions.

## Assumptions

- Existing node and pod metrics snapshots provide enough data to calculate all
  current-state progress values.
- A visual progress bar is sufficient for the requested "chart" improvement.
- The menu should favor scanability and density over richer analytical charts.
- No security-sensitive data is introduced because no new cluster resources or
  external services are read.

## Scope Boundaries

- In scope: display-model progress mapping, compact SwiftUI rendering, focused
  tests, and runtime documentation updates.
- Out of scope: historical charts, trend lines, metrics storage, new thresholds,
  alerting, external monitoring integrations, and health-state changes.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Resource usage appears visually scannable.
- Verification: ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: Overview progress values match metrics; missing metrics stay unavailable; node zero usage yields zero progress; pod CPU basis follows request then limit; pod memory basis follows limit then request; resource progress preserves health category

**Goal:** Make CPU and memory usage visually scannable in Overview, Nodes, and
Pods without changing health evaluation semantics.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1-R13

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Modify: `Kubebar/Views/NodeDetailsView.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `Kubebar/Views/InlineProgressBar.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-05-12-resource-usage-visualization.md`
- Reference: `CONTEXT.md`

**Approach:**
- Add or refine display-model fields so Overview, Node, and Pod rows can
  distinguish CPU and Memory progress where both are shown.
- Add a small progress calculation helper in `HealthEvaluator` that returns
  `nil` for missing or invalid basis, returns `0` for valid zero usage, and
  allows rendering to clamp high values.
- Populate Overview CPU and Memory progress from node metrics over allocatable.
- Populate node row CPU and Memory progress from per-node usage over
  allocatable.
- Populate Pod CPU progress using request then limit, and Pod Memory progress
  using limit then request, matching existing compact text semantics.
- Update SwiftUI rows to render compact CPU and Memory visuals without moving
  names, readiness labels, or issue text out of view.
- Keep help and accessibility text based on the existing complete resource
  labels.
- Update runtime invariants to record that resource visualization is
  informational and unavailable metrics remain explicit.

**Verification:**
- `./scripts/swift-quality-gate.sh local`
- `./scripts/compile-and-run.sh` for a visible-app smoke check when local macOS
  launch is available.

**failure_behavior:** If progress mapping is partially applied, affected rows
must continue to show text labels and `nil` progress rather than misleading
bars.

**security_considerations:** No new Kubernetes resource reads, no Secrets, no
external telemetry, and no command transcripts in UI.

## Validation Notes

- Use the system Immune-Brain CLI: `imm-plan
  docs/plans/2026-05-12-001-feat-resource-usage-visualization-plan.md --json`.
