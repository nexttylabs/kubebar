# Phase 04: CodexBar-Inspired Menu Reliability and Freshness - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Source:** `$gsd-discuss-phase` update for GitHub issue #5

<domain>

## Phase Boundary

This phase adapts the useful design logic from CodexBar into Kubebar without
turning Kubebar into CodexBar or a Kubernetes dashboard.

The phase delivers:
- A local run script that builds, tests, relaunches, and verifies the menu bar
  app process.
- Testable setup/menu state so first-use regressions are caught before manual
  testing.
- Refresh cadence and freshness behavior that make current, stale, and failed
  states predictable.
- Clearer menu bar icon semantics, privacy docs, and an operator-facing QA
  checklist.

This phase does not deliver:
- Migration from `MenuBarExtra.window` to a full AppKit `NSStatusItem`.
- CodexBar's provider registry, usage providers, widgets, update flow, cookies,
  keychain access, or bundled CLI.
- Full issue #4 warning/event reason expansion.
- Local distribution, notarization, Sparkle, or `Open in k9s` handoff.

</domain>

<decisions>

## Implementation Decisions

### Preserve Kubebar's Product Shape

- Keep the first screen watchlist-first.
- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep stale data visible only when it is clearly marked stale.
- Keep app-owned saved context as the source of truth.
- Keep `kubectl` reads behind injectable boundaries.

### Adapt CodexBar's Best Lessons

- Treat the menu bar app as an instrument: the icon gives the first signal, the
  menu explains it, and actions close the loop.
- Add a build-and-run script because menu bar bugs often survive unit tests.
- Move setup/menu transitions into small value models where possible.
- Make refresh cadence and last-updated state visible rather than implicit.
- Use docs to state privacy and read-boundary guarantees clearly.

### Refresh Freshness Rules

- **D-01:** A successful snapshot becomes stale when it is older than two times
  the saved refresh cadence. For the default 1 minute cadence, the freshness
  window is 2 minutes.
- **D-02:** Freshness is tied to the saved cadence, not to a separate hidden
  threshold.
- **D-03:** Old data must not remain in `OK`, `Watch`, or `Bad` once the
  freshness window has expired.

### Failed Refresh Handling

- **D-04:** Consecutive failed refreshes keep the last successful snapshot
  visible only as `Stale`.
- **D-05:** Repeated failures should update the stale reason and last successful
  update age without adding extra noisy prompts or escalating into a new visual
  state.
- **D-06:** A refresh failure with no previous successful snapshot shows a safe
  unavailable state, not empty healthy data.

### Failure Reason Boundaries

- **D-07:** Timeout, command failure, malformed JSON, and no previous data must
  produce distinct short reasons.
- **D-08:** These reasons all use the same `Stale` presentation. Do not add new
  top-level icon categories beyond `OK`, `Watch`, `Bad`, and `Stale`.
- **D-09:** User-facing reasons should be short and actionable, such as
  `kubectl timed out`, `kubectl failed`, `Invalid kubectl JSON`, or
  `No previous cluster data`.

### Refresh Concurrency

- **D-10:** Only one refresh may run at a time.
- **D-11:** Disable `Retry now` while a refresh is already running.
- **D-12:** Automatic refresh and manual retry must not start overlapping
  `kubectl` reads, and older refresh results must not overwrite newer state.

### Menu Refresh Controls

- **D-13:** The menu should show the refresh cadence picker, last successful
  update age, failure reason when stale, and `Retry now`.
- **D-14:** Do not add a persistent next-refresh countdown or extra progress
  panel in this phase.
- **D-15:** Keep the refresh controls compact so the menu remains an operator
  glance tool rather than a monitoring dashboard.

### the agent's Discretion

- Exact model names may change if the same boundaries are preserved.
- The launch script may use `open`, `osascript`, `pgrep`, or other standard
  macOS tools as long as it avoids broad destructive process matching.
- UI copy may be adjusted for clarity, but the product meaning must stay the
  same.
- Exact sanitization wording for failure reasons may vary if the four distinct
  safe states above remain clear to the user.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before implementing.

### Product Direction

- `AGENTS.md` - repo rules and Kubebar product guardrails.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - issue ordering and
  completion bar.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  original watchlist-first requirements.

### Architecture

- `docs/architecture/system-overview.md` - runtime flow and component ownership.
- `docs/architecture/runtime-invariants.md` - icon, freshness, config, and
  stale-state invariants.
- `.planning/codebase/ARCHITECTURE.md` - codebase map of current architecture.
- `.planning/codebase/TESTING.md` - available quality gates and test shape.

### Current Phase Inputs

- `https://github.com/nexttylabs/kubebar/issues/5` - Refresh cadence, timeout,
  freshness controls, and acceptance criteria for this phase.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-RESEARCH.md`
  - CodexBar comparison and lessons.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-PATTERNS.md`
  - local code patterns to reuse.

### Prior Phase

- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-CONTEXT.md`
  - setup/watchlist decisions.
- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-VERIFICATION.md`
  - issue #3 verification state and remaining manual UAT context.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `KubebarCore/Models/RefreshCadence.swift` already defines supported saved
  cadences: 30 seconds, 1 minute, 2 minutes, and 5 minutes.
- `KubebarCore/Services/AppConfigStore.swift` already persists
  `refreshIntervalSeconds`; keep using this shape.
- `Kubebar/MenuBarViewModel.swift` already starts a refresh loop after setup
  and exposes refresh cadence selection.
- `KubebarCore/Services/RefreshCoordinator.swift` already preserves the
  previous snapshot on refresh failure.
- `KubebarCore/Services/HealthEvaluator.swift` already builds stale banner
  display from previous snapshots and failure reasons.
- `Kubebar/Views/MenuBarRootView.swift` already shows the cadence picker and
  `Retry now` action.

### Established Patterns

- UI views render `MenuDisplayModel`; they should not decide freshness or
  failure severity directly.
- Time-based decisions should take injected `Date` values so tests can assert
  deterministic stale ages.
- External command behavior stays behind `CommandRunning` and
  `ClusterReading`.

### Integration Points

- Add freshness age-out near `HealthEvaluator` or the refresh result mapping so
  expired snapshots cannot look current.
- Add one in-flight refresh guard in `MenuBarViewModel` so manual and automatic
  refreshes cannot overlap.
- Expose any needed refresh-in-progress display state through the menu render
  model or view model without adding a new top-level health state.

</code_context>

<specifics>

## Specific Ideas

- Add a `scripts/compile-and-run.sh` command similar in spirit to CodexBar's
  run loop: build/test, stop stale app process, launch the built `.app`, and
  confirm it is running.
- Add a pure setup/menu runtime state model so first launch, partial config,
  edit watchlist, and target-loading failure behavior are covered by tests.
- Use existing `AppConfig.refreshIntervalSeconds` instead of replacing config
  storage.
- Show refresh cadence, last successful update age, stale failure reason, and
  `Retry now` in the menu without making the menu feel like a dashboard.
- Treat "older than 2x cadence" as stale even if the last successful snapshot
  was healthy.
- Keep repeated failures quiet: stale state remains visible and useful, but the
  app does not add extra prompts for every failed poll.
- Add or update UAT docs for menu states that cannot be fully proven by unit
  tests.

</specifics>

<deferred>

## Deferred Ideas

- AppKit `NSStatusItem` migration.
- WidgetKit, update checks, provider registry, and usage-provider concepts.
- Distribution packaging and notarization.
- Full event/actionable reason expansion for issue #4.
- Deep debugging handoff such as `Open in k9s`.
- Persistent next-refresh countdown and richer refresh progress UI.

</deferred>

---

*Phase: 04-codexbar-inspired-menu-reliability-and-freshness*
*Context gathered: 2026-04-21*
