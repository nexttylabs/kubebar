---
title: feat: Polish Pod resource display
type: feat
status: planned
date: 2026-05-14
origin: .imm/specs/2026-05-14-pod-resource-display-polish.md
---

# feat: Polish Pod resource display

## Summary

- Summary: Pod resource display becomes clearer.

Improve the existing Pods tab resource usage visualization so operators can
scan CPU and memory context without confusing resource pressure with Kubebar's
Health category. This is a display polish slice over the current Pod metrics
pipeline, not a new data collection or alerting feature.

## Task

- Type: feat
- Scope: pod resource display polish
- Owner: imm-work
- Verification: automated

## Origin

The user asked for further analysis of Pod metrics information and display.
`imm-brainstorm` found that the data path is already present: Pod metrics are
read, request and limit context are aggregated, and Pods tab rows already show
compact labels plus CPU and memory progress values. The remaining value is
display clarity and semantic guardrails.

This is a new slice rather than an append to
`docs/plans/2026-05-12-001-feat-resource-usage-visualization-plan.md` because
that prior iteration is closed and passed in `.imm/memory/current_iteration.json`.

## Research

- `CONTEXT.md` defines Resource usage visualization as lightweight
  current-snapshot CPU and memory indicators, not historical charts or a
  dashboard.
- `docs/architecture/runtime-invariants.md` says resource usage visualization
  is display-only and must not decide `OK`, `Watch`, `Bad`, or `Stale`.
- `KubebarCore/Services/KubectlClusterReader.swift` reads Pod metrics from
  `/apis/metrics.k8s.io/v1beta1/pods` and combines usage with Pod request and
  limit data into `PodResourceSummary`.
- `KubebarCore/Services/HealthEvaluator.swift` maps Pod resource summaries into
  compact text, full help text, and separate CPU and memory progress values.
- `KubebarCore/Models/MenuDisplayModel.swift` already has separate
  `cpuProgress` and `memoryProgress` on `PodItemDisplay`, but still exposes a
  legacy aggregate `resourceProgress`.
- `Kubebar/Views/PodsTabView.swift` currently renders resource text before
  issue text, which conflicts with the earlier Pod resource requirement that
  issue text stays more important than resource text.
- `Kubebar/Views/InlineProgressBar.swift` uses color thresholds that can look
  alert-like even though resource pressure does not affect Health category.
- No `docs/solutions/` entry with `rejected: true` was found for this approach.

## Decisions

- Treat this as one outcome unit: Pod resource display becomes clearer.
- Keep the existing Pod metrics pipeline and resource aggregation untouched
  unless a display bug requires a tiny model adjustment.
- Preserve CPU and memory as separate progress values.
- Prefer compact labels or visual affordances over explanatory in-app text.
- Keep Health category semantics unchanged.
- Keep unavailable resource data explicit through text, help, and
  accessibility.

## Assumptions

- Existing tests and fixtures are sufficient to add regression coverage around
  display ordering and health non-coupling.
- A small visual polish can be verified by the Swift quality gate plus a local
  visible-app smoke check when macOS launch is available.
- No new domain term is needed in `CONTEXT.md`; existing Resource usage
  visualization and Unavailable resource data vocabulary cover this slice.

## Scope Boundaries

- In scope: Pods tab row ordering, compact CPU and memory resource visual
  affordances, display-model cleanup where necessary, focused tests, and
  runtime documentation updates.
- Out of scope: new Kubernetes API reads, metrics storage, thresholds that
  affect state, alerting, per-container rows, historical visualization, and
  external monitoring integration.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Pod resource display becomes clearer.
- Verification: ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: issue text appears before resource text for attention Pods; CPU and memory progress remain separate; high Pod resource progress preserves Health category; unavailable Pod resource data remains explicit; compact rows preserve Pod name and ready count priority

**Goal:** Polish Pods tab resource usage visualization so it is easier to scan
and cannot be mistaken for a Health category decision.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1-R10

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `Kubebar/Views/InlineProgressBar.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-05-14-pod-resource-display-polish.md`
- Reference: `CONTEXT.md`

**Approach:**
- Add or adjust tests first for the Pod row contract: attention issue text has
  priority over resource text, CPU and memory progress stay separate, and
  resource-only pressure does not affect `OK`, `Watch`, `Bad`, or `Stale`.
- Reorder Pods tab row rendering so issue text appears above resource text.
- Make CPU and memory progress bars distinguishable without relying only on
  color or verbose explanatory text.
- If needed, de-emphasize alert-like color thresholds so resource usage remains
  informational.
- Keep unavailable resource data as `nil` progress and explicit `-` text.
- Keep help and accessibility labels aligned with complete resource details.
- Update runtime invariants to record the polished Pod resource display
  contract.

**Verification:**
- `./scripts/swift-quality-gate.sh local`
- `./scripts/compile-and-run.sh` for a visible-app smoke check when local macOS
  launch is available.

**failure_behavior:** If visual polish cannot be completed cleanly, Pod rows
must continue to show the existing compact resource text and omit misleading
new progress affordances rather than showing ambiguous indicators.

**security_considerations:** No new Kubernetes resources are read, no Secrets
are queried, no command transcripts are displayed, and no cluster data leaves
the app.

## Validation Notes

- Use the system Immune-Brain CLI: `imm-plan docs/plans/2026-05-14-001-feat-pod-resource-display-polish-plan.md --json`.
