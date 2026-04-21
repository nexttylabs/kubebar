# Phase 03: Complete first-use setup and watchlist editing - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning
**Source issue:** https://github.com/nexttylabs/kubebar/issues/3

<domain>
## Phase Boundary

This phase completes the first-use setup loop for Kubebar. A user should be
able to choose an app-owned Kubernetes context, pick a useful watchlist from
real cluster data, save it, and later edit it without hand-editing config.

The discussion focused on how watchlist candidates are discovered and shown.
Other issue #3 areas remain open for planner discretion unless they conflict
with the locked decisions below.

</domain>

<decisions>
## Implementation Decisions

### Watchlist Candidate Source

- **D-01:** Watchlist candidates should include both namespaces and workloads.
  Namespaces support broad monitoring, while workloads support focused service
  monitoring.
- **D-02:** Workload candidates should include `Deployment`, `StatefulSet`,
  `DaemonSet`, and `CronJob`.
- **D-03:** Historical `Job` objects should not appear as default setup
  candidates because they can create a noisy, stale-looking list.
- **D-04:** `CronJob` should remain available because it represents an ongoing
  scheduled workload that a daily operator may reasonably watch.

### Candidate List Presentation

- **D-05:** Candidates should be grouped by namespace.
- **D-06:** Within each namespace group, workload candidates should show their
  kind and name so same-named resources stay distinguishable.
- **D-07:** Namespace groups should default to collapsed when candidate volume is
  high, keeping first-use setup calm and scannable.

### Candidate Loading and Failure Behavior

- **D-08:** Selecting or changing the context should automatically load
  watchlist candidates for that context.
- **D-09:** While candidates load, the context selector should remain visible
  and usable; only the watchlist area should show a loading state.
- **D-10:** If candidate discovery fails, the setup flow should show the failure
  reason and a retry action.
- **D-11:** Candidate discovery failure should preserve any already selected
  watchlist targets instead of clearing the user's work.

### the agent's Discretion

- Context switching rules beyond automatic candidate reload were not discussed.
  Use a conservative behavior that keeps app-owned context trustworthy and does
  not silently show targets from the wrong context.
- Exact empty-state copy and save timing were not discussed. Keep the wording
  direct, recovery-oriented, and consistent with existing setup copy.
- The planner may choose the concrete Swift type names and view split as long as
  the UI stays thin and candidate discovery remains testable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope

- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  Defines the first-use, watchlist-first, and no-deep-troubleshooting product
  constraints.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - Lists issue #3 as
  the next open product step after docs cleanup.
- `docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md` - Captures
  the original app scaffold decisions and requirement trace for R14-R17.

### Runtime Rules

- `docs/architecture/runtime-invariants.md` - Defines setup, watchlist,
  app-owned context, stale-state, and injectable boundary invariants.
- `docs/architecture/system-overview.md` - Defines the app/core/service
  boundaries used by the current macOS menu bar app.

### Current Code Map

- `.planning/codebase/ARCHITECTURE.md` - Summarizes the current app layers,
  data flow, and service boundaries.
- `.planning/codebase/CONVENTIONS.md` - Summarizes Swift naming, style,
  test, error handling, and dependency injection conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Kubebar/Views/SetupView.swift`: Existing setup screen with context selector,
  watchlist picker, and finish action.
- `Kubebar/Views/WatchlistPickerView.swift`: Existing namespace and workload
  toggle UI that can evolve to show discovered candidates.
- `KubebarCore/Models/SetupFlowState.swift`: Existing setup state, including
  selected context, available contexts, watchlist state, and configuration
  message.
- `KubebarCore/Models/WatchlistSelectionState.swift`: Existing selected target
  model with available namespace/workload lists.
- `KubebarCore/Models/WatchTarget.swift`: Existing durable watch target shape
  for namespaces and workloads.

### Established Patterns

- UI renders app-owned state and should not call `kubectl` directly.
- External command reads go through `CommandRunning`.
- App-owned Kubernetes context is the source of truth; reads must not depend on
  the terminal's active context.
- Core behavior is covered with Swift Testing tests under `KubebarTests/`.

### Integration Points

- `Kubebar/MenuBarViewModel.swift` currently loads contexts in `openSetup()`
  and saves setup in `completeSetup()`.
- `KubebarCore/Services/ContextCatalog.swift` currently lists Kubernetes
  contexts through `kubectl config get-contexts -o name`.
- `KubebarCore/Services/KubectlClusterReader.swift` already reads pods,
  nodes, and events using an injected command runner and the saved context.
- Candidate discovery should likely sit beside `ContextCatalog` or the
  Kubernetes reader boundary rather than inside SwiftUI views.

</code_context>

<specifics>
## Specific Ideas

- Candidate discovery should feel automatic after choosing a context, not like
  a separate manual import step.
- The setup page should not freeze completely during discovery. Context choice
  remains visible while the watchlist area reports loading.
- Failure handling should protect the user's partial selections.
- The candidate list should stay quiet for large clusters by grouping resources
  under namespaces and collapsing groups by default.

</specifics>

<deferred>
## Deferred Ideas

- Context switching cleanup policy remains undecided: clear all targets, keep
  matching targets, or require confirmation.
- Final empty-state copy remains undecided.
- Edit watchlist save timing remains undecided: immediate save or explicit
  finish action.
- GitHub issue #4 will handle richer unhealthy reasons and warning event
  details; do not expand issue #3 into deep status explanation work.

</deferred>

---

*Phase: 03-complete-first-use-setup-and-watchlist-editing*
*Context gathered: 2026-04-20*
