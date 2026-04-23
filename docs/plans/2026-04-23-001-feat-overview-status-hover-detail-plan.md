---
title: "feat: Add Overview status hover detail"
type: feat
status: active
date: 2026-04-23
origin: docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md
---

# feat: Add Overview status hover detail

## Overview

Add detailed hover and accessibility text to the Overview top cluster/status
description. The visible top-row text stays short and scan-friendly, while the
hover/help text explains the most specific known reason behind the current
status: tracked object issue, node or pod condition detail, warning event
detail, section-unavailable reason, metrics-unavailable detail, or stale refresh
reason.

This is an incremental plan for the newly added hover-detail requirements in
the Overview requirements document. The broader Overview cards redesign is
already covered by `docs/plans/2026-04-22-001-feat-overview-cluster-cards-plan.md`.

## Problem Frame

The current Overview top-row status already shows a compact status phrase and
uses hover/help, but the hover text repeats the same short phrase. That leaves
the operator without the concrete error context they expected from hovering:
which object is affected, which node or pod condition caused the state, which
warning was most relevant, or why data is stale or unavailable.

The fix should keep the menu glanceable while making hover and accessibility
text useful enough to answer "why is this status showing?" without opening a
deeper tab first.

## Requirements Trace

- R15. Keep the visible top-row health description readable and one-line.
- R15a. Hover over the top-row cluster status must include the most specific
  known reason for the current status, not only repeat the visible text.
- R15b. Hover detail should include concrete context when available: affected
  tracked object, node readiness reason/message, pod condition or container
  reason/message, warning event detail, section-unavailable reason, or stale
  refresh reason.
- R15c. Hover detail must stay safe: no raw command output, tokens, file paths,
  or kubectl transcripts.
- R15d. The same detailed status information must be available through
  accessibility text.
- R23. Visible top-row status remains concise and exposes full detail through
  tooltip/accessibility text.

## Scope Boundaries

- No visible long-form status text in the top row.
- No new troubleshooting actions or links.
- No changes to health severity categories: `OK`, `Watch`, `Bad`, and `Stale`
  remain unchanged.
- No raw kubectl output, JSON, file paths, tokens, or command transcripts in
  hover or accessibility text.
- No changes to Nodes, Pods, CPU, Memory, or Recent Warnings layout.

## Context & Research

### Relevant Code and Patterns

- `KubebarCore/Models/MenuDisplayModel.swift` defines `OverviewDisplay` with
  `statusText` and `statusAccessibilityLabel`; it does not currently carry a
  separate detailed status/help value.
- `KubebarCore/Services/HealthEvaluator.swift` computes the current
  `primaryStatusReason`, overview display fields, stale banner, section
  notices, node row help text, pod row help text, and warning row help text.
- `Kubebar/Views/StatusSummaryView.swift` renders the top row and currently
  applies `.help` using the short `statusText`.
- `WarningEventDisplay.helpText`, `NodeItemDisplay.helpText`, and
  `PodItemDisplay.helpText` already show the expected pattern: short visible
  row text plus more complete hover/accessibility text.
- `docs/architecture/runtime-invariants.md` already requires tooltips and
  accessibility labels to avoid command transcripts and JSON.
- `KubebarTests/Models/MenuDisplayModelTests.swift` covers status priority,
  stale reasons, section failures, warning rows, node/pod issue detail, and
  metrics-unavailable behavior.
- `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` verifies fixture
  metadata and safe display strings for representative menu states.

### Institutional Learnings

- Keep Overview scan-first; detailed information belongs in hover/help,
  accessibility, dedicated tabs, or detail views rather than expanding the
  first row.
- Preserve `MenuDisplayModel` as the UI rendering boundary and keep
  `HealthEvaluator` responsible for deciding status meaning.
- Stale, unavailable, and warning details must be operator-facing and safe, not
  raw command output.

### External References

- External research is not needed. This is a native SwiftUI display-model
  enhancement with strong local patterns in existing hover/help and
  accessibility text.

## Key Technical Decisions

- **Add a dedicated detailed status field to `OverviewDisplay`:** The short
  `statusText` remains the visible one-line value. A separate display-model
  field carries hover/help detail so the view does not infer diagnostic meaning.
- **Compute status detail in `HealthEvaluator`:** The evaluator already owns
  severity, status priority, stale handling, section availability, and warning
  summarization. Keeping detail assembly there preserves the existing boundary.
- **Follow existing priority order:** The detailed status should explain the
  same condition that drove the visible top-row status: stale first, then bad
  tracked object, node deficit, pod deficit, warning/tracked warning, section
  unavailability, metrics unavailability, and finally all-clear state.
- **Prefer existing safe display facts:** Reuse already-sanitized reasons and
  existing row help text patterns where possible instead of introducing raw
  command output or Kubernetes transcripts.
- **Make accessibility at least as informative as hover:** The accessibility
  label should include the detailed status context, not only the short visible
  text.

## Open Questions

### Resolved During Planning

- **Update existing completed Overview plan or create a new one?** Create a new
  incremental plan. The existing Overview plan is already complete and should
  stay as the record for the broader redesign.
- **Does this require external research?** No. The change follows local
  SwiftUI, display-model, and safe-help-text patterns.

### Deferred to Implementation

- **Exact field/helper names:** Keep names consistent with the surrounding
  implementation once the display shape is updated.
- **Exact wording for all-clear hover text:** It may safely mirror the visible
  OK text when no deeper issue exists; the requirement matters most when the
  status reflects attention, stale, or unavailable data.

## Implementation Units

- [x] **Unit 1: Extend Overview status detail in the display model**

**Goal:** Add a display-model value for detailed Overview status help text and
populate it with the most specific safe reason available for the current status.

**Requirements:** R15a, R15b, R15c, R15d, R23

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Extend the Overview display contract with a dedicated status detail/help
  value while preserving existing initializer compatibility where needed.
- Build the detail from display-safe facts already available to
  `HealthEvaluator`.
- For tracked object attention, include the tracked object title and row/detail
  reason; include affected pod count, example pod names, or latest warning only
  when that display detail already exists.
- For node attention, prefer a specific not-ready node and its issue text when
  node details exist; otherwise fall back to the node deficit summary.
- For pod attention, prefer a specific affected pod and its issue text when pod
  details exist; otherwise fall back to the pod deficit summary.
- For warning-only states, include the top relevant warning row help text,
  preserving reason, object, age, repeat count, and latest message.
- For stale states, include the stale reason and last-known timing context when
  available.
- For unavailable sections and metrics-unavailable states, include the
  sanitized unavailable reason that is already shown in section/card display.
- Fall back to the short visible status text when no more specific detail is
  available.

**Execution note:** Start with focused display-model tests for the new status
detail before wiring the view.

**Patterns to follow:**
- `primaryStatusReason` in `KubebarCore/Services/HealthEvaluator.swift`
- `nodeHelpText` and `podHelpText` in `KubebarCore/Services/HealthEvaluator.swift`
- `WarningEventDisplay.helpText` in `KubebarCore/Models/MenuDisplayModel.swift`
- Existing safe section reason handling in `HealthEvaluator`

**Test scenarios:**
- Happy path: bad tracked workload with affected pod detail -> status detail
  names the tracked object and includes the concrete reason behind the Bad
  state.
- Happy path: not-ready node with reason and message -> visible status remains
  short while status detail includes the node name and condition detail.
- Happy path: not-ready pod with container or condition reason -> status detail
  includes pod scope and the specific pod issue text.
- Happy path: warning-only state -> status detail includes the top warning
  reason, object scope, age/repeat metadata, and latest useful message.
- Edge case: metrics unavailable while cluster is otherwise OK -> status detail
  explains metrics unavailability without changing the OK state.
- Edge case: stale refresh with previous data -> status detail includes the
  stale/failure reason and does not imply the retained data is current.
- Error path: unavailable section reason contains unsafe raw-looking content ->
  status detail uses the safe reason path and does not expose raw command
  output.
- Regression: healthy all-clear state still has a non-empty status detail and
  does not introduce long visible Overview text.

**Verification:**
- `OverviewDisplay` carries both short visible status and detailed status help.
- The detail matches the same priority decision as the visible status.
- Tests cover tracked, node, pod, warning, stale, and unavailable cases.

- [x] **Unit 2: Wire the top-row hover and accessibility text**

**Goal:** Make the Overview top-row cluster status use the detailed status value
for hover/help and accessibility while keeping visible text compact.

**Requirements:** R15, R15a, R15c, R15d, R23

**Dependencies:** Unit 1

**Files:**
- Modify: `Kubebar/Views/StatusSummaryView.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Keep the visible top-row status rendering unchanged: state label plus
  one-line `statusText`.
- Change the status row help text to use the detailed status value from
  `OverviewDisplay`.
- Update the Overview status accessibility label so it includes the detailed
  status context.
- Preserve context-name hover behavior; context hover can remain focused on
  the full context name, while the status row hover explains status cause.
- Do not make `StatusSummaryView` inspect snapshot facts or choose fallback
  messages.

**Patterns to follow:**
- Existing `.help(Text(...))` usage in `StatusSummaryView`
- Full-text hover patterns in `WarningEventRowView`, `NodeDetailsView`, and
  `PodsTabView`
- Existing accessibility labels in `WarningEventDisplay`, `NodeItemDisplay`,
  and `PodItemDisplay`

**Test scenarios:**
- Integration: display model for a warning state provides short visible text and
  more detailed accessibility text.
- Integration: display model for stale state provides detailed accessibility
  text that includes stale reason.
- Regression: top-row visible status text remains the existing short value and
  does not duplicate full detail.

**Verification:**
- Hover over the status row exposes detailed status context.
- Accessibility text includes the same detailed context.
- The visible top-row status remains one line.

- [x] **Unit 3: Update QA fixtures and runtime docs for the hover contract**

**Goal:** Record the new hover/accessibility contract in QA expectations and
runtime invariants so future changes do not regress it.

**Requirements:** R15a, R15b, R15c, R15d

**Dependencies:** Unit 1

**Files:**
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `docs/qa/operator-verification.md`

**Approach:**
- Update fixture expected behavior or limitations where representative states
  should explicitly mention status hover/accessibility detail.
- Add fixture-level checks that representative display states carry detailed
  status context and do not expose sensitive or raw command-like strings.
- Update runtime invariants to state that the Overview top status row keeps
  short visible text and uses hover/accessibility for concrete status detail.
- Update operator verification notes so human QA knows to hover the Overview
  status row for warning, bad, stale, and unavailable examples.

**Patterns to follow:**
- Existing fixture metadata tests in `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Existing safe-string checks for metadata and failure displays
- Existing operator verification wording for visible menu inspection

**Test scenarios:**
- Happy path: watch/bad/stale/metrics-unavailable fixtures contain detailed
  status help or accessibility text that goes beyond the visible one-liner.
- Error path: fixture safety checks fail if status detail includes unsafe raw
  command-like content.
- Regression: fixture copy still avoids reintroducing the `Watching` section.

**Verification:**
- QA fixtures describe and test the hover/accessibility behavior.
- Runtime and operator docs preserve the short-visible/detail-on-hover contract.

- [x] **Unit 4: Final validation**

**Goal:** Confirm the new status hover behavior is complete without changing the
rest of the Overview design.

**Requirements:** R15, R15a, R15b, R15c, R15d, R23

**Dependencies:** Units 1-3

**Files:**
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/qa/operator-verification.md`

**Approach:**
- Confirm display-model tests cover every status category with meaningful detail
  where data exists.
- Confirm view usage reads the display-model detail rather than inferring from
  raw state.
- Confirm no changes accidentally alter Overview cards, Recent Warnings caps,
  health categories, or warning ordering.
- Record any human-only verification needed for hover behavior in QA docs.

**Patterns to follow:**
- Existing final verification expectations in `AGENTS.md`
- Existing model-first test coverage for Overview display behavior

**Test scenarios:**
- Integration: Bad tracked object -> visible status stays short, hover detail
  gives concrete object/reason context.
- Integration: Stale refresh -> visible status stays short, hover detail gives
  stale reason.
- Integration: Metrics unavailable -> OK state remains possible, hover/detail
  explains unavailable metrics.
- Regression: Overview still renders the same four cards and capped Recent
  Warnings.

**Verification:**
- Focused display-model and QA fixture tests pass.
- Full local quality gate passes before implementation is considered complete.
- Manual QA notes clearly identify hover checks that automated tests cannot
  visually prove.

## System-Wide Impact

- **Interaction graph:** `HealthEvaluator` computes short status and detailed
  status display fields; `MenuDisplayModel` carries them; `StatusSummaryView`
  renders the short text and exposes the detailed text through help and
  accessibility.
- **Error propagation:** Status detail must use safe reasons and existing
  display facts. Raw command output remains behind reader/evaluator boundaries.
- **State lifecycle risks:** Stale displays may retain previous data only with
  stale marking; hover detail should reinforce, not weaken, that distinction.
- **API surface parity:** This is an app-internal display model change. It does
  not change kubectl reads, saved config, menu bar icon categories, or tab
  availability.
- **Integration coverage:** Model tests prove detail selection; QA fixture tests
  protect representative menu states; human QA confirms actual macOS hover
  behavior.
- **Unchanged invariants:** UI still renders `MenuDisplayModel`; `HealthEvaluator`
  remains the source of severity; Overview remains scan-first.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Hover detail repeats the short text and does not solve the operator need | Add tests where the detailed value must include object/reason context beyond the visible one-liner |
| Detail exposes unsafe command output or paths | Reuse sanitized section/failure reasons and add fixture safety checks |
| Views start deciding health detail | Keep detail selection in `HealthEvaluator` and have `StatusSummaryView` only render display-model fields |
| Visible top row becomes too verbose | Preserve `statusText` as the only visible status phrase; keep full detail in hover/accessibility |
| Accessibility falls behind hover behavior | Make accessibility label include the same detailed status context and cover it in model tests |

## Documentation / Operational Notes

- Update `docs/architecture/runtime-invariants.md` with the new top-row
  hover/accessibility invariant.
- Update `docs/qa/operator-verification.md` so manual QA hovers the top status
  row in Bad, Watch, Stale, and unavailable-data states.
- No operator setup change is required.

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md](../brainstorms/2026-04-22-kubebar-overview-design-requirements.md)
- Related completed plan: [docs/plans/2026-04-22-001-feat-overview-cluster-cards-plan.md](2026-04-22-001-feat-overview-cluster-cards-plan.md)
- Display model: `KubebarCore/Models/MenuDisplayModel.swift`
- Status mapping: `KubebarCore/Services/HealthEvaluator.swift`
- Top row view: `Kubebar/Views/StatusSummaryView.swift`
- Overview view: `Kubebar/Views/OverviewTabView.swift`
- Display-model tests: `KubebarTests/Models/MenuDisplayModelTests.swift`
- QA fixture tests: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
