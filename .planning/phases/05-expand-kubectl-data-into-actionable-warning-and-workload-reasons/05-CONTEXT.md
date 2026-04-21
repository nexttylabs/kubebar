# Phase 05: Expand kubectl data into actionable warning and workload reasons - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Source issue:** https://github.com/nexttylabs/kubebar/issues/4

<domain>

## Phase Boundary

This phase makes Kubebar explain what needs attention instead of only showing
counts. It expands the existing `kubectl` snapshot into short, actionable
warning event summaries and workload health reasons.

This phase delivers:

- Warning event summaries with reason, namespace, involved object, and time
  where available.
- Watchlist row reasons for pending pods, restarting pods, failed pods, and
  missing pods.
- Short tracked-item details that confirm the problem without becoming a
  troubleshooting console.
- Safe behavior for empty, malformed, and partial `kubectl` JSON cases.
- Tests for event decoding and workload reason selection.

This phase does not deliver:

- Deep troubleshooting flows, shell handoff, or `Open in k9s`.
- A full Kubernetes dashboard.
- New watchlist setup behavior beyond using the already configured targets.
- Kubernetes Secrets reads.

</domain>

<decisions>

## Implementation Decisions

### Warning Event Display

- **D-01:** Keep compact warning event count in the counters, then show at most
  3 warning event summaries in the warning event section.
- **D-02:** Each warning event summary should show `Reason + namespace/object +
  age` when those fields are available.
- **D-03:** Repeated warning events should be grouped by `reason + involved
  object`, with the UI showing the occurrence count and most recent time.
- **D-04:** Warning event details should only confirm the problem: reason,
  object, namespace, age, and a short message.
- **D-05:** Do not show raw or full `kubectl` event output in the menu. Long
  messages should be shortened so the menu stays glanceable.

### Source Requirements From GitHub Issue #4

- Workload rows must explain the most important unhealthy reason in one short
  phrase, including pending pods, restarting pods, failed pods, and missing
  pods.
- Tracked item details must include enough context to decide whether to open a
  deeper tool.
- Empty, malformed, and partial `kubectl` JSON cases must remain safe and
  covered by tests.
- Stale state must keep showing failure reason when known.

### Workload Reason Priority

- **D-06:** When multiple workload problems exist, row reasons should prioritize
  `missing/failed > restarting > pending/unready > warning`.
- **D-07:** Restarting pods should be described by affected pod count, such as
  `2 pods restarting`, rather than leading with a single pod name.
- **D-08:** Pending and unready pods should be merged into one short reason,
  such as `3 pods not ready`.
- **D-09:** Workload row reasons should stay as one short phrase. Detailed pod
  examples belong in the tracked item detail view.

### Tracked Item Details

- **D-10:** A tracked item detail should show `state + reason + affected pod
  count + 1-3 example pod names + latest related warning` when those fields are
  available.
- **D-11:** The detail view should provide enough context to decide whether to
  open a deeper tool, but should not show full raw pod or event output.

### Partial and Malformed kubectl Data

- **D-12:** If one `kubectl` section fails while other sections succeed, keep
  the available fresh sections and mark the failed section as unavailable or
  stale with its reason.
- **D-13:** Do not silently hide section failures. The menu must make partial
  failure visible without making unavailable data look healthy.
- **D-14:** Empty JSON lists are valid empty states.
- **D-15:** Malformed JSON is a failure for that section and must be tested as a
  failure path.

### Carried Forward From Prior Phases

- Keep the menu watchlist-first.
- Keep first-screen watchlist rows capped at 3-5 items.
- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep stale data visibly marked as `Stale`; old data must never look current.
- Keep all external reads behind injectable boundaries.
- Keep UI rendering behind `MenuDisplayModel`; SwiftUI views must not decide
  cluster health directly.

### the agent's Discretion

- Exact warning message truncation length.
- Exact fallback wording when an event is missing namespace, object, reason, or
  timestamp.
- Exact ordering tie-breakers when multiple warning groups have the same latest
  timestamp.
- Concrete model names for richer warning event and workload reason data.
- Exact wording for section-unavailable states, as long as the failed section is
  visible and not mistaken for healthy data.

</decisions>

<specifics>

## Specific Ideas

- Warning event summaries should answer "what happened, where, and how recent
  is it?" without making the user read raw Kubernetes output.
- Repeated events should not flood the menu. Grouping keeps the menu useful
  when Kubernetes emits the same warning many times.
- The warning section may show fewer than 3 rows when there are fewer warning
  groups.
- Detail views should be confirmatory. They should help the operator decide
  whether to open a deeper tool, not replace that deeper tool.
- Workload rows should prefer a stable severity order over most-recent-first
  ordering so the row does not change meaning unpredictably.
- Detail examples should stay capped to 1-3 pod names.
- A successful empty event or pod list is not an error by itself; invalid JSON
  is an error for the section that produced it.

</specifics>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Product Scope

- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - Lists GitHub issue
  #4 and defines warning/workload reasons as the next operator-readiness step.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  Defines R3, R8, R9, R12, and the no-deep-troubleshooting V1 boundary.
- `docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md` - Original
  plan expectations for warning event decoding and short tracked details.

### Architecture

- `AGENTS.md` - Repo rules and Kubebar product guardrails.
- `docs/architecture/system-overview.md` - Runtime flow and UI/core/service
  ownership.
- `docs/architecture/runtime-invariants.md` - Watchlist, stale-state, privacy,
  and external-read invariants.
- `.planning/codebase/ARCHITECTURE.md` - Current app layers, data flow, and
  integration points.
- `.planning/codebase/CONVENTIONS.md` - Swift style, error handling, and
  dependency injection conventions.
- `.planning/codebase/TESTING.md` - Current test framework and fixture
  patterns.
- `.planning/codebase/CONCERNS.md` - Existing notes on coarse Kubernetes health
  parsing and actionable reason gaps.

### Prior Phase Context

- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-CONTEXT.md`
  - Watchlist target decisions and setup scope boundaries.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-CONTEXT.md`
  - Freshness, icon, reliability, and explicit deferral of full issue #4.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-VERIFICATION.md`
  - Current automated verification status and remaining manual UAT context.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `KubebarCore/Services/KubectlClusterReader.swift`: Already reads nodes, pods,
  and warning events through `CommandRunning` using the saved context.
- `KubebarCore/Models/ClusterSnapshot.swift`: Current snapshot shape stores
  only `warningEventCount`, so richer warning summaries need a model addition.
- `KubebarCore/Models/WatchTarget.swift`: Current `TrackedItemStatus` already
  carries `target`, `state`, and one short `reason`.
- `KubebarCore/Services/HealthEvaluator.swift`: Already owns severity,
  watchlist ordering, row cap, and conversion into `MenuDisplayModel`.
- `Kubebar/Views/WarningEventsView.swift`: Current warning section shows only a
  count-derived sentence.
- `Kubebar/Views/TrackedItemDetailView.swift`: Current detail view only shows
  state and the short reason.
- `KubebarTests/Services/KubectlClusterReaderTests.swift`: Existing fake
  `kubectl` JSON fixture pattern for parser coverage.

### Established Patterns

- UI renders app-owned display models and should not parse raw cluster data.
- External command reads go through `CommandRunning`.
- `KubectlClusterReader` must pass `--context` with the app-owned selected
  context.
- Core behavior should be covered with Swift Testing tests under
  `KubebarTests/`.
- Keep source comments rare; use clear value types and tests to explain
  behavior.

### Integration Points

- Add event fields in or near `ClusterSnapshot`, then map them through
  `HealthEvaluator` into `MenuDisplayModel`.
- Extend `WarningEventsView` only after the display model exposes already
  shortened event summaries.
- Improve workload reason selection in `KubectlClusterReader` or a focused
  helper below the reader boundary, then keep `HealthEvaluator` responsible for
  ordering and row visibility.
- Add malformed, empty, duplicate, and partial fixture tests beside current
  `KubectlClusterReaderTests`.

</code_context>

<deferred>

## Deferred Ideas

- Deep debugging handoff such as `Open in k9s`.
- Full event timeline or unlimited warning event list.
- Team-facing alert workflow or shared operational notes.
- AppKit `NSStatusItem` migration.
- Distribution packaging and notarization.

</deferred>

---

*Phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons*
*Context gathered: 2026-04-21*
