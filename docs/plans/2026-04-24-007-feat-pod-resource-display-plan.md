---
title: feat: Pod resource summary in Pods tab
status: complete
type: feat
date: 2026-04-24
origin: docs/brainstorms/2026-04-24-kubebar-pod-resource-display-requirements.md
---

# feat: Pod resource summary in Pods tab

## Overview

Add a compact Pod-level CPU and Memory signal to each visible Pod row in the Pods tab using local-safe numeric context and explicit availability markers. The detailed usage/request/limit values must still be accessible through help, focus, and accessibility text, while preserving existing row status and keeping current health category rules unchanged.

## Problem Frame

Operators need a fast signal for whether a visible Pod is under CPU or memory pressure before opening deeper tools. The Pod list already provides status, readiness, and scope; this feature extends row text without turning Kubebar into a dashboard. The existing constraint remains: no deep troubleshooting actions in this version.

## Requirements Trace

- R1-R12, R17-R24, R25-R27, R29-R31
- R28, R32
- R30
- Existing Pod row behavior from `docs/brainstorms/2026-04-22-kubebar-pod-item-menu-ui-requirements.md`

## Scope Boundaries

- No new resource alerting, no status model change (`OK/Watch/Bad/Stale` unchanged).
- No per-container row expansion in first version.
- No charts, trends, or external monitoring dependency.
- No Pod logs/events/drilldown actions in Pods tab.
- No change to completed Job inclusion rules beyond keeping current behavior.

## Context & Research

### Relevant Code and Patterns

- `KubebarCore/Models/MenuDisplayModel.swift`: row payload for Pods, Pod tab data shapes, and section availability patterns.
- `KubebarCore/Models/ClusterSnapshot.swift`: `PodDetail`, `PodSummary`, and section wiring.
- `KubebarCore/Services/KubectlClusterReader.swift`: concurrent `kubectl` reads, pod decoding, and watched-target filtering.
- `KubebarCore/Services/HealthEvaluator.swift`: row mapping, tab summaries, section notices, and status composition.
- `Kubebar/Views/PodsTabView.swift`: row-level rendering, help/accessibility hooks, and keyboard focus.
- `KubebarTests/Models/MenuDisplayModelTests.swift`: current expected row ordering and Pod detail mapping behavior.
- `KubebarTests/Services/KubectlClusterReaderTests.swift`: pod filtering, workload selector, and missing-data fallback coverage.
- `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`: fixture-level stability checks for Pods tab copy.
- `docs/architecture/runtime-invariants.md`: stale/unavailable and status invariants.

### Institutional Learnings

- No `docs/solutions/` entries in this repo for this pattern.
- Existing resource handling is done in health-only aggregates (nodes/overview); no Pod-level usage/request/limit path exists yet.

### External References

- Not used. Kubernetes API shapes are already handled in-repo for pods/nodes and metrics.

## Key Technical Decisions

- **Keep `HealthEvaluator` as health truth and UI status source** (`status` never driven by resource pressure in this version).
- **Compute Pod resource summary at source into `PodDetail`-level fields** so rows can render compact and full values consistently.
- **Add an optional pod metrics read** and map `k8s metrics.k8s.io/pods` only to Pod usage; request/limit remain from Pod spec.
- **Use per-column fallback logic**: CPU compares usage to request first, then limit, then falls back to raw; Memory compares to limit first, then request, then raw.
- **Preserve non-regression behavior by making unavailable values explicit `-`**, never implied zeros.
- **Only unavailable resource contexts are suppressed in compact rows**; issue text and Pod state remain full priority.

## Open Questions

### Resolved During Planning

- **Partial data handling:** show available usage/request/limit parts and mark unavailable components clearly.
- **Aggregation level:** Pod resource summary is across all containers in the Pod.
- **Health coupling:** resource pressure rows do not alter cluster, watchlist, or Overview state in this version.

### Deferred to Implementation

- **Malformed unit handling policy:** decide whether one invalid container request/limit unit should drop only that resource dimension or all containers for that Pod.
- **Compact unit format:** confirm whether CPU raw fallback should prefer m-core style or decimal with suffix for consistency.

## Implementation Units

- [x] **Unit 1: Extend Pod data contracts for resource context**

**Goal:** Store Pod usage, request, and limit context in snapshot/display model without changing health state logic.

**Requirements:** R1, R2, R17, R19, R20, R24

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/ClusterSnapshot.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Approach:**
- Add a dedicated Pod-level resource struct (usage, request, limit fields per CPU/memory, with safe optionals).
- Add that field to `PodDetail`, with default-safe init to avoid breaking fixtures and decoding call sites.
- Extend `PodItemDisplay` with compact and full resource text fields used by row rendering.
- Keep `HealthEvaluator` untouched in this unit; only data shape grows.

**Patterns to follow:**
- Existing `NodeDetail`/`NodeItemDisplay` patterns for value/summary/help/accessibility pairing.
- Existing equality semantics in model structs.

**Test scenarios:**
- Happy path: `PodDetail` can include all four resource values and remain `Equatable`.
- Edge case: snapshot with no resource payload still builds `PodDetail`/`PodItemDisplay` defaults safely.
- Error path: partial model fixture creation compiles without defaulting to fake zeros.

**Verification:**
- New model fields exist with safe optional values and no compile breakage in existing snapshots.

- [x] **Unit 2: Read pod metrics and compute Pod-level resource summaries**

**Goal:** Populate request/limit from Pod spec and usage from pod metrics for watched Pods only.

**Requirements:** R2, R7, R8, R9, R10, R17-R24, R25, R30

**Dependencies:** Unit 1

**Files:**
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Approach:**
- Add a pod-metrics read command (existing list endpoint) to the concurrent read set.
- Extend `PodRecord` decoding to include container resources and aggregate pod request/limit safely per container.
- Extend pod metrics decoding for pod-level entries and container usage, then aggregate to Pod totals.
- Update `makePodDetailsSection` to inject resource summary into each matched `PodDetail`.
- Keep pod-metrics failures as row-level unavailability (`-`) and avoid turning section availability into global `Watch`/`Bad`.

**Patterns to follow:**
- Existing `parseResourceQuantity` and scaling helpers in `KubectlClusterReader`.
- Existing watched target matching and de-duplication behavior in `makePodDetailsSection`.

**Test scenarios:**
- Happy path: watched Pod receives all CPU/memory usage/request/limit values and keeps matching namespace/scoping.
- Edge case: usage unavailable + request/limit present still shows known request/limit in full help context.
- Edge case: request/limit missing + usage present still shows raw usage without fabricated percent.
- Edge case: malformed pod metrics or disabled metrics endpoint does not fail snapshot and keeps tracked Pod rows.
- Integration: pod metrics/API failure does not affect `sectionFailures`-driven state transitions.

**Verification:**
- `readSnapshot` remains available for normal pods and preserves existing fallback behavior for unavailable resources.

- [x] **Unit 3: Map resource compact and full text in row model generation**

**Goal:** Build concise in-row resource labels plus complete accessibility/help payloads with explicit missing markers.

**Requirements:** R6-R16, R18, R20, R21, R22, R23, R24

**Dependencies:** Unit 2

**Files:**
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Add compact resource formatter for Pod rows with precedence per requirement: CPU request-first, Memory limit-first.
- Keep full help text include namespace/name, state, ready counts, full usage/request/limit with explicit `-` markers.
- Keep issue text priority unchanged; ensure accessibility/help includes both compact and expanded data.
- Ensure issue line remains above resource line in row assembly.

**Patterns to follow:**
- Existing help/accessibility construction for node rows and pod issue selection.
- Existing percentage formatting helpers where applicable.

**Test scenarios:**
- Edge case: usage missing -> `CPU - · Mem -` in compact row and matching explicit text in help.
- Edge case: CPU usage known, no CPU request/limit basis -> compact `CPU <raw>`.
- Edge case: mixed missing request/limit values show only available basis or raw fallback without fake percentages.
- Integration: Pod row with issue retains issue line priority above resource line.
- Integration: resource-only failures keep pod row state and overall cluster state unchanged.

**Verification:**
- `display.podTab.sections` rows include compact resource text and full help strings without impacting state logic.

- [x] **Unit 4: Render resource line and keyboard/help output in Pods tab rows**

**Goal:** Show compact resource line on pod rows while preserving issue order and density rules.

**Requirements:** R6, R9, R11, R12, R13, R14, R15, R16, R21, R30

**Dependencies:** Unit 3

**Files:**
- Modify: `Kubebar/Views/PodsTabView.swift`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` (indirect fixture expectations) if row copy expectations are updated

**Approach:**
- Add second text line in `PodRowView` for compact resource text.
- Keep ready label and issue line intact; issue remains higher priority than resource in layout.
- Ensure resource line truncates before issue line when constrained and help/focus still retains full values.
- Keep `.help` and `.accessibilityLabel` tied to full value strings from model.

**Patterns to follow:**
- Existing compact row patterns in `PodRowView` and existing `.help` / `.focusable()` usage.

**Test scenarios:**
- UI behavior: issue present row still displays issue first and resource text below.
- Integration: unavailable resource values render as `-` without widening row unexpectedly.
- Accessibility: focused/hover text retains full values for missing and complete cases.

**Verification:**
- Pod row UI can still scroll/fit existing Pods tab layout while keeping `Pods` tab usability.

- [x] **Unit 5: Expand regression coverage for read and display matrix**

**Goal:** Lock down resource-fallback behavior, partial/missing cases, and non-regression of existing Pod state classification.

**Requirements:** R17-R23, R25, R28, R30, R31

**Dependencies:** Units 1-4

**Files:**
- Test: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`

**Approach:**
- Add reader tests for: request-only, limit-only, mixed, and missing pod metrics; malformed resource units.
- Add model tests for compact formatter outcomes (`CPU req%`, `Memory limit%`, raw fallback, unavailable fallback).
- Add explicit regression tests that `Bad`/`Watch`/`OK` state remains unchanged when only resource data is unavailable.
- Add/adjust QA fixture tests if any visible pod-tab copy changes.

**Patterns to follow:**
- Existing fixture-driven test style in reader and menu model suites.

**Test scenarios:**
- Regression: failed/restarting/not-ready classification remains unchanged when resource data is missing.
- Regression: pods tab empty/no watched pods still keeps `podsTab.emptyMessage` path distinct from unavailable.
- Integration: resource text values are present in `help`/accessibility-derived model fields.

**Verification:**
- All existing Pod-related and overview tests pass alongside new resource-specific scenarios.

- [x] **Unit 6: Update runtime notes for pod resource failure behavior**

**Goal:** Document that resource display data can be unavailable without becoming a health failure.

**Requirements:** R24, R25

**Dependencies:** Unit 5

**Files:**
- Modify: `docs/architecture/runtime-invariants.md`

**Approach:**
- Add or refine wording for Pods-tab row context: missing resource numbers stay visible as unavailable, not fake healthy.
- Keep health vocabulary rules unchanged and cross-link resource-only failure handling to `sectionFailures` behavior.

**Test scenarios:**
- Test expectation: none (documentation only).

**Verification:**
- Runtime invariant file includes this behavior so follow-up changes preserve it.

## System-Wide Impact

- **Interaction graph:** `KubectlClusterReader` adds pod metrics/request-limit parsing into `PodDetail`; `HealthEvaluator` formats and injects resource text into `PodItemDisplay`; `PodsTabView` consumes new row fields.
- **Error propagation:** Pod metric or resource decode issues surface in row-level availability markers, not global cluster state changes.
- **State lifecycle risks:** partial data should not block `podDetailsSection` row generation; tracked-item health remains source-of-truth.
- **API surface parity:** no external API contract changes; only local types and UI behavior changes.
- **Integration coverage:** reader + model + QA coverage across filtered watched Pods and unavailable-data scenarios.
- **Unchanged invariants:** no health-state expansion, no container-level UI drilldown, no new external data dependencies.

## Risks & Dependencies

| Risk | Mitigation |
|---|---|
| Pod resource parsing fails for mixed or vendor-variant units | Keep per-dimension optional aggregation and explicit unavailable markers, avoid global failure.
| Added pod-metrics read increases read-time overhead | Keep concurrent read model and reuse existing command runner timeout and error handling.
| Layout crowding in Pods tab | Limit compact text to short format and enforce truncation while preserving issue-first priority.
