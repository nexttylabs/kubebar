---
title: feat: Improve Pod resource readability
type: feat
status: planned
date: 2026-05-14
origin: .imm/specs/2026-05-14-pod-resource-readability.md
---

# feat: Improve Pod resource readability

## Summary

- Summary: Pods tab resource details are easier to scan.

Improve the existing Pods tab resource usage visualization so current CPU and
memory context reads naturally in compact rows and hover details. This is a
display readability slice over the current Pod metrics pipeline, not a new data
collection, charting, or health evaluation feature.

## Task

- Type: feat
- Scope: pod resource readability
- Owner: imm-work
- Verification: automated plus visible smoke

## Origin

The user provided a screenshot of the current Pods tab and asked how to further
improve Pod information display. `imm-brainstorm` found that the data is useful
but dense: row labels such as `CPU 338% req`, compact progress bars, ready
counts, namespace headers, and hover text all compete for attention.

This is a new slice rather than an append to
`docs/plans/2026-05-14-001-feat-pod-resource-display-polish-plan.md` because
that prior plan is closed and passed in `.imm/memory/current_iteration.json`.

## Research

- `CONTEXT.md` defines Resource usage visualization as lightweight
  current-snapshot CPU and memory indicators, not historical charts or an
  external dashboard.
- `docs/architecture/runtime-invariants.md` says resource usage visualization
  is display-only and must not decide `OK`, `Watch`, `Bad`, or `Stale`.
- The screenshot shows useful Pod resource data but also reveals high scanning
  cost from terse basis labels and dense inline accessories.
- `Kubebar/Views/PodsTabView.swift` renders Pod name, ready count, issue text,
  resource text, and separate CPU/memory progress indicators from
  `PodItemDisplay`.
- `KubebarCore/Services/HealthEvaluator.swift` currently produces compact
  resource labels such as `CPU 50% req · Mem 25% limit` and help text using
  slash triples for usage, request, and limit.
- `KubebarCore/Models/MenuDisplayModel.swift` already keeps CPU and memory
  progress separate, so this slice should preserve that contract.
- `KubebarTests/Models/MenuDisplayModelTests.swift` already covers Pod
  resource label, help text, progress, and health non-coupling behavior.
- No `docs/solutions/` entry with `rejected: true` was found for this approach.

## Decisions

- Treat this as one outcome unit: Pods tab resource details are easier to scan.
- Keep the existing Pod metrics reader and resource aggregation unchanged.
- Improve resource wording and help/accessibility text before considering any
  new visual surface.
- Keep issue text above resource text.
- Keep resource progress informational and separate from Health category.
- Prefer compact row text plus richer hover detail over adding visible
  explanatory text to every row.

## Assumptions

- The current test fixture surface can cover the resource label and help text
  wording changes.
- A visible smoke check can confirm that revised labels and resource
  accessories fit in the menu without occluding ready counts.
- Existing `CONTEXT.md` vocabulary is sufficient; no new canonical term is
  needed for this slice.

## Scope Boundaries

- In scope: Pod row resource wording, Pod help/accessibility text formatting,
  compact resource accessory spacing if needed, focused tests, and runtime
  documentation updates.
- Out of scope: new Kubernetes API reads, metrics storage, historical
  visualization, resource alerting, per-container detail rows, and external
  monitoring integration.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Pods tab resource details are easier to scan.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: request and limit resource labels use readable basis wording; unavailable resource help text avoids zero-like triples; high Pod resource usage preserves Health category; CPU and memory progress remain separate; visible Pods tab smoke check confirms compact row layout

**Goal:** Make existing Pod resource usage visualization easier to read in row
text, hover help, and accessibility labels without changing health semantics.

**Verification type:** hitl

**Execution note:** test-first

**Requirements:** R1-R10

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-05-14-pod-resource-readability.md`
- Reference: `CONTEXT.md`

**Approach:**
- Add tests first for the desired resource label and help/accessibility
  contract.
- Replace abbreviation-only basis wording with compact readable wording that
  still fits Pod rows.
- Reformat Pod resource help text so CPU and memory details are inspectable
  without ambiguous slash triples or fake zero values.
- Keep unavailable values explicit and avoid rendering missing data as `0`.
- Adjust Pods tab spacing only if the clearer labels need small layout support.
- Update runtime invariants with the resource readability contract.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=watch ./scripts/compile-and-run.sh`
- Inspect the launched Pods tab against the provided screenshot concern: row
  labels fit, ready counts stay aligned, and hover text is readable.

**failure_behavior:** If the clearer wording cannot fit cleanly in compact Pod
rows, keep the row label shorter and move the full explanation into help and
accessibility text rather than crowding the first scan.

**security_considerations:** No new Kubernetes resources are read, no Secrets
are queried, no command transcripts are displayed, and no cluster data leaves
the app.

## Validation Notes

- Use the system Immune-Brain CLI: `imm-plan docs/plans/2026-05-14-002-feat-pod-resource-readability-plan.md --json`.
