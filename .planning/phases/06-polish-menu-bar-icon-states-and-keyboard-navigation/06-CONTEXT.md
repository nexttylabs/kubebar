# Phase 06: Polish Menu Bar Icon States and Keyboard Navigation - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Source issue:** https://github.com/nexttylabs/kubebar/issues/6

<domain>

## Phase Boundary

This phase polishes the existing Kubebar menu experience so the app is readable
from the macOS menu bar and usable without a mouse.

This phase delivers:

- Final menu bar icon treatment for `OK`, `Watch`, `Bad`, and `Stale`.
- Status presentation that does not rely on color alone.
- A CodexBar-inspired native menu feel: compact, ordered, and instrument-like,
  without becoming a dashboard.
- Consistent truncation for long context, namespace, and workload names.
- Keyboard navigation coverage for setup, refresh, edit watchlist, details, and
  secondary sections.
- Automatic tests where practical plus manual QA coverage for real menu
  interaction.

This phase does not deliver:

- New top-level health states beyond `OK`, `Watch`, `Bad`, and `Stale`.
- A full dashboard, unlimited primary menu, or deep troubleshooting surface.
- `Open in k9s`, shell handoff, or other deeper-debugging features.
- AppKit `NSStatusItem` migration.
- Local distribution, notarization, or release packaging.
- The broader operator-facing QA phase from issue #7.

</domain>

<decisions>

## Implementation Decisions

### Menu Bar Icon States

- **D-01:** Keep the healthy menu bar state as the brand logo. `OK` should use
  the existing custom `KubebarLogo` in the menu bar.
- **D-02:** Keep `Watch`, `Bad`, and `Stale` as explicit status symbols.
- **D-03:** Reuse the current symbol set:
  `Watch = exclamationmark.triangle`, `Bad = xmark.octagon`, and
  `Stale = clock.badge.exclamationmark`.
- **D-04:** When the menu opens, the top status area must explicitly show
  `OK` for a healthy cluster so the logo is not the only health signal.
- **D-05:** Preserve distinct accessibility labels for all four states, such as
  `Kubebar OK`, `Kubebar Watch`, `Kubebar Bad`, and `Kubebar Stale`.

### Non-Color Status Expression

- **D-06:** Warning and failure states must use symbol, status text, and a short
  reason. They must not rely on color alone.
- **D-07:** The top status area should show only the single most important
  reason, such as `2 pods restarting` or `kubectl timed out`.
- **D-08:** Detailed reasons stay in the watchlist row, tracked item detail,
  stale banner, or warning event sections. Do not turn the top status area into
  a multi-line incident summary.

### Menu Reading Experience

- **D-09:** Use CodexBar as a design reference for the menu's product logic:
  the menu bar icon is the first signal, the opened menu explains it, and the
  menu behaves like a reliable small instrument.
- **D-10:** Do not copy CodexBar's provider registry, widgets, update plumbing,
  keychain/cookie usage providers, CLI subproduct, or AppKit status-item
  architecture.
- **D-11:** Keep the menu order focused on status summary plus watchlist first.
  Warning events and node details remain lower-priority sections.
- **D-12:** Tighten spacing and typography, but do not compress the menu. The
  result should feel like native menu grouping, not cards or dashboard panels.

### Long-Name Truncation

- **D-13:** Long context, namespace, and workload names should use middle
  truncation that preserves the beginning and end of the name.
- **D-14:** Truncation should prioritize preserving tail differences for
  workload and resource names, because Kubernetes names often differ at the
  end.
- **D-15:** Full untruncated names should remain available through hover
  tooltip and accessibility text.
- **D-16:** Avoid multi-line list rows for long names on the primary menu
  surface. Multi-line names make menu height unstable and weaken quick reading.

### Keyboard Navigation and Verification

- **D-17:** Keyboard navigation must reach setup, refresh, edit watchlist,
  watchlist detail, warning events, and secondary sections.
- **D-18:** Verification should combine automatic tests with a manual QA
  checklist. Existing tests can cover model and state behavior; real menu
  keyboard behavior needs documented manual QA.
- **D-19:** QA must cover all four menu states: `OK`, `Watch`, `Bad`, and
  `Stale`.
- **D-20:** QA must also cover setup, edit watchlist, and refresh enabled or
  disabled paths.

### the agent's Discretion

- The planner may choose exact truncation length and helper type names.
- The planner may choose whether tooltip support lives directly in SwiftUI
  views or behind a small presentation helper, as long as full names are
  available without cluttering the menu.
- The planner may decide which keyboard-navigation behaviors are testable in
  unit tests versus documented in UAT.
- The planner may adjust exact copy if it keeps the same status meaning,
  remains short, and does not weaken watchlist-first reading.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Product Direction

- `AGENTS.md` - repo rules and Kubebar product guardrails.
- `https://github.com/nexttylabs/kubebar/issues/6` - source issue for menu bar
  icon states, reading polish, truncation, keyboard navigation, and acceptance
  criteria.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - lists issue #6 as
  the polish gate before operator QA and distribution work.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  defines R1, R13, and R18-R21.

### CodexBar Reference

- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-RESEARCH.md`
  - captures the CodexBar design lessons to adapt: icon as first signal, menu
  as explanation, local verification, and instrument-like menu behavior.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-CONTEXT.md`
  - locks the earlier decision to adapt CodexBar's useful lessons without
  copying CodexBar's product or architecture.

### Architecture and Runtime Rules

- `docs/architecture/runtime-invariants.md` - defines icon categories,
  watchlist-first rules, stale behavior, non-color failure rules, and
  truncation expectations.
- `docs/architecture/system-overview.md` - defines app, view model, core, and
  service ownership.
- `.planning/codebase/ARCHITECTURE.md` - maps current app layers and data flow.
- `.planning/codebase/STRUCTURE.md` - maps where menu, models, services, and
  tests live.
- `.planning/codebase/TESTING.md` - defines current test shape and quality
  gate.
- `.planning/codebase/CONCERNS.md` - records current gaps around UI behavior,
  keyboard navigation, visual stale states, and menu verification.

### Prior Phase Context

- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-CONTEXT.md`
  - locks first-use setup and watchlist editing decisions.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-CONTEXT.md`
  - locks freshness, stale-state, refresh control, and CodexBar adaptation
  boundaries.
- `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-CONTEXT.md`
  - locks warning and workload reason presentation boundaries.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `KubebarCore/Models/MenuBarStatusPresentation.swift`: Current menu bar state
  presentation already maps `OK` to `KubebarLogo` and the other states to
  status symbols.
- `Kubebar/KubebarApp.swift`: Builds the `MenuBarExtra` label from
  `MenuBarStatusPresentation`.
- `Kubebar/Views/StatusSummaryView.swift`: Top menu area already shows context,
  state label, and health sentence.
- `Kubebar/Views/MenuBarRootView.swift`: Existing menu order is status summary,
  stale banner, counters, watchlist, warning events, node details, refresh
  controls, and actions.
- `Kubebar/Views/WatchlistSectionView.swift`: Current watchlist rows already
  use one-line title and reason labels.
- `Kubebar/Views/WarningEventsView.swift`: Current warning section already
  renders short summaries and caps long messages.
- `KubebarTests/Models/MenuBarStatusPresentationTests.swift`: Existing tests
  cover state symbols and accessibility labels.

### Established Patterns

- SwiftUI views render `MenuDisplayModel`; they must not decide cluster health
  directly.
- `HealthEvaluator` remains the single source of truth for severity and display
  mapping.
- The menu stays watchlist-first with only 3-5 primary watchlist rows.
- `Stale` must remain visually and semantically distinct from `OK`.
- User-facing status copy should stay short and action-oriented.
- The full local quality gate is `./scripts/swift-quality-gate.sh local`.

### Integration Points

- Icon state changes belong in `MenuBarStatusPresentation` and its tests.
- Top status reason changes likely flow through `MenuDisplayModel` and
  `HealthEvaluator` before `StatusSummaryView` renders them.
- Truncation behavior should be centralized enough that context, namespace, and
  workload names stay consistent across summary, watchlist, details, and setup.
- Keyboard navigation and manual QA coverage should be documented in the phase
  UAT file once implementation is planned.

</code_context>

<specifics>

## Specific Ideas

- Keep the healthy menu bar quiet and branded, but make `OK` explicit when the
  menu opens.
- Use the existing current symbol set rather than spending the phase on icon
  redesign.
- The first status line answers "what state is this?" and "what is the most
  important reason?" without competing with the watchlist.
- CodexBar is a reference for discipline and instrument-like menu behavior, not
  a source of new Kubebar product scope.
- Middle truncation should keep Kubernetes names scannable, especially when
  resources share a long common prefix.
- Manual QA should prove real menu keyboard behavior for all four states and
  setup/edit/refresh paths.

</specifics>

<deferred>

## Deferred Ideas

- Full daily-loop operator QA belongs to GitHub issue #7.
- AppKit `NSStatusItem` migration remains deferred.
- Local distribution, notarization, and packaging remain deferred.
- Deep troubleshooting handoff such as `Open in k9s` remains deferred.

</deferred>

---

*Phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation*
*Context gathered: 2026-04-21*
