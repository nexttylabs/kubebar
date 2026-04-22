# Phase 09: CodexBar-Inspired Tabbed Menu Redesign - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source request:** Analyze CodexBar menu design and redesign Kubebar with
settings in an independent dialog, a tabbed menu, Overview as the home tab,
dedicated Nodes, Pods, and Events tabs, and a quit button.

<domain>

## Phase Boundary

This phase redesigns Kubebar's opened menu from a single vertical status page
into a CodexBar-inspired tabbed menu while preserving Kubebar's lightweight
menu-bar purpose.

This phase delivers:

- A tabbed menu structure with `Overview`, `Nodes`, `Pods`, and `Events`.
- `Overview` as the default home tab for the current cluster state.
- Settings moved out of the menu body into an independent settings dialog or
  window.
- A visible `Quit Kubebar` action from the opened menu.
- A clearer division between high-level status and resource-specific detail.
- Tests and UAT updates for the redesigned menu structure and app actions.

This phase does not deliver:

- A full Kubernetes dashboard.
- Deep troubleshooting, shell handoff, watch streams, or `Open in k9s`.
- New health states beyond `OK`, `Watch`, `Bad`, and `Stale`.
- Provider-style CodexBar features such as usage meters, provider registries,
  widgets, browser-cookie flows, or update infrastructure.
- A change from `MenuBarExtra.window` to an AppKit `NSStatusItem`.

</domain>

<decisions>

## Implementation Decisions

### CodexBar Adaptation

- **D-01:** Use CodexBar as a menu-organization reference: the menu bar icon is
  the first signal, the opened menu explains the state, and tabs keep related
  details separate.
- **D-02:** Adapt CodexBar's `Overview` idea, not its AI-provider product model.
  Kubebar tabs represent Kubernetes resource views, not providers.
- **D-03:** Preserve Kubebar's small-instrument feel. The redesign should make
  information easier to scan, not expand the app into a dashboard.
- **D-04:** Keep the app dockless and native menu-bar-first.

### Tab Structure

- **D-05:** The opened menu uses four top-level tabs: `Overview`, `Nodes`,
  `Pods`, and `Events`.
- **D-06:** `Overview` is the default selected tab whenever the menu opens.
- **D-07:** The tab control should be compact and native-feeling, using a
  segmented or tab-style control that is keyboard reachable.
- **D-08:** Switching tabs must not trigger a Kubernetes read by itself. Refresh
  remains explicit or cadence-driven through the existing refresh model.
- **D-09:** The selected tab is menu-local UI state. It should not be persisted
  unless the implementation naturally needs it for accessibility or testing.

### Overview Tab

- **D-10:** `Overview` keeps the main daily-use answer: current context, health
  state, primary reason, stale banner when needed, compact counters, and the
  first-screen watchlist.
- **D-11:** Watchlist remains first-class in `Overview`; the tabbed design must
  not bury the operator's tracked namespaces or workloads.
- **D-12:** Keep first-screen watchlist rows capped at 3-5 items. Overflow may
  stay behind a secondary row or a later detail affordance.
- **D-13:** Overview may show only the most important event or section notice
  summary when space is tight; fuller warning detail belongs in `Events`.
- **D-42:** Refine `Overview` into a "stability first, attention next" home tab.
  It should answer whether the cluster is stable, then immediately show the
  watched object or condition that deserves attention.
- **D-43:** The preferred Overview order is: status summary, stale banner when
  present, prioritized watchlist/attention objects, compact counters, and one
  notice. This refines the earlier generic list when implementing the Overview
  redesign.
- **D-44:** Watchlist rows in Overview are ranked by urgency: `Bad`, `Watch`,
  and `Stale` items before healthy items. When everything is healthy, Overview
  may show 3-5 compact healthy tracked rows so the operator still sees what is
  being watched.
- **D-45:** Empty watchlist is a configuration problem, not a healthy state.
  Overview must point to Settings instead of showing an all-good surface.
- **D-46:** Counters stay in Overview, but they are supporting context rather
  than the main visual focus. If there are attention items, counters appear
  after those items; if everything is healthy, counters may sit before the
  watchlist as a fast scan summary.
- **D-47:** Overview shows at most one notice. Notice priority is: unavailable
  or partial section data first, then a `Bad` or `Watch` related warning, then
  any other warning.
- **D-48:** Full warning detail remains owned by `Events`; Overview must not
  duplicate the event list or become a dashboard-style event feed.

### Nodes Tab

- **D-14:** `Nodes` focuses on node readiness and node-section availability. It
  should answer whether node data is current, unavailable, or unhealthy.
- **D-15:** If the existing model only has aggregate node readiness, the first
  version may show aggregate readiness plus safe unavailable-state copy.
- **D-16:** If richer node rows are added, they must come through the core
  display model and remain short. Do not show raw `kubectl` output or a full
  troubleshooting table.

### Pods Tab

- **D-17:** `Pods` focuses on pod readiness, workload health, affected pod
  counts, and 1-3 example pod names.
- **D-18:** The tab should reuse existing watchlist/workload detail behavior
  where possible, because that already carries actionable pod reasons.
- **D-19:** A future implementation may add safe pod status buckets such as
  running, not ready, restarting, pending, or failed if they are shaped in
  `MenuDisplayModel`.
- **D-20:** Do not turn `Pods` into an all-namespace pod inventory. The tab
  should help decide whether to open deeper tools, not replace them.

### Events Tab

- **D-21:** `Events` owns warning event details that are too much for the
  overview tab.
- **D-22:** Event rows should keep the existing shape: reason, location, age,
  occurrence count, and a shortened message when useful.
- **D-23:** Repeated warnings remain grouped by reason plus involved object.
- **D-24:** The Events tab may show more rows than Overview, but it still needs
  a cap so the menu stays readable.
- **D-25:** Empty, unavailable, and partial event data states must be explicit
  and must not look healthy.

### Settings Dialog

- **D-26:** Move setup/edit configuration out of the menu body into a separate
  settings dialog or window.
- **D-27:** Settings should contain context selection, watchlist editing,
  refresh cadence, and any kubectl path or recovery controls that already
  belong to app configuration.
- **D-28:** The menu should expose a concise `Settings...` action that opens the
  dialog instead of replacing the menu content with the setup screen.
- **D-29:** First-use and recovery states should guide the user to Settings
  without making stale or missing configuration look like healthy cluster data.
- **D-30:** Settings remains local-app configuration. It must not introduce
  cloud sync, account concepts, or multi-cluster switching for this phase.

### Quit Action

- **D-31:** Add a visible `Quit Kubebar` button or menu-row action at the bottom
  of the opened menu.
- **D-32:** Quitting exits the app without changing saved context, watchlist, or
  refresh cadence.
- **D-33:** The app should also preserve the standard macOS `Quit Kubebar`
  command behavior where available.

### Architecture and State

- **D-34:** Keep `MenuDisplayModel` as the only render contract for cluster
  status. Views may choose which tab renders which fields, but they must not
  decide cluster health.
- **D-35:** `HealthEvaluator` remains the single source of truth for `OK`,
  `Watch`, `Bad`, and `Stale`.
- **D-36:** Any new tab-specific display fields should be shaped in
  `KubebarCore` before SwiftUI renders them.
- **D-37:** Keep external reads behind existing injectable boundaries. The
  redesign must not make SwiftUI views call `kubectl`.
- **D-38:** Preserve native keyboard reachability for tabs, refresh, settings,
  watchlist details, warning events, and quit.

### Verification

- **D-39:** Add or update model/view-model tests for new tab display data,
  settings-opening behavior, and quit-action wiring where practical.
- **D-40:** Update UAT expectations so manual checks cover the tabbed menu,
  first-use settings path, keyboard tab navigation, and the quit action.
- **D-41:** Run `./scripts/swift-quality-gate.sh local` before completing
  implementation.

### the agent's Discretion

- The planner may choose the exact SwiftUI control used for tabs if it remains
  compact, native-feeling, and keyboard reachable.
- The planner may choose exact section titles and microcopy as long as
  `Overview`, `Nodes`, `Pods`, `Events`, `Settings...`, and `Quit Kubebar`
  remain recognizable.
- The planner may decide whether settings opens as a SwiftUI `Window`, panel,
  or app-modal dialog based on what fits the existing `MenuBarExtra.window`
  shell best.
- The planner may decide exact caps for Events rows and pod/node detail rows,
  as long as the menu remains glanceable.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Product Direction

- `AGENTS.md` - repo rules and Kubebar product guardrails.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - current roadmap and
  daily operator promise.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  watchlist-first requirements and V1 boundaries.
- `docs/architecture/runtime-invariants.md` - runtime rules for icon states,
  stale data, watchlist, keyboard behavior, and failure visibility.
- `docs/architecture/system-overview.md` - app, view model, core, and service
  ownership.

### CodexBar Reference

- `https://github.com/steipete/CodexBar` - public README describing CodexBar's
  small macOS menu-bar app shape, optional Overview tab, Settings-driven
  configuration, and minimal UI.
- `https://github.com/steipete/CodexBar/blob/main/docs/ui.md` - CodexBar UI
  notes for menu bar behavior, Overview tab, menu card, icon behavior, and
  Preferences notes.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-CONTEXT.md`
  - prior Kubebar decision to adapt CodexBar's useful menu lessons without
  copying its product or architecture.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-CONTEXT.md`
  - prior Kubebar decision that CodexBar is a reference for instrument-like
  menu behavior, not a source of new product scope.

### Existing App Structure

- `.planning/codebase/ARCHITECTURE.md` - current app layers and data flow.
- `.planning/codebase/STRUCTURE.md` - file ownership for app shell, views,
  models, services, and tests.
- `.planning/codebase/TESTING.md` - current test patterns and quality gate.
- `.planning/codebase/CONCERNS.md` - known UI, menu, verification, and
  watchlist concerns.
- `Kubebar/KubebarApp.swift` - `MenuBarExtra.window` scene and status icon
  wiring.
- `Kubebar/MenuBarViewModel.swift` - menu state, setup state, refresh, and
  config actions.
- `Kubebar/Views/MenuBarRootView.swift` - current single-page menu composition
  root.
- `KubebarCore/Models/MenuDisplayModel.swift` - current render contract for
  menu UI.
- `KubebarCore/Models/ClusterSnapshot.swift` - current node, pod, warning
  event, workload, and section availability data.
- `KubebarCore/Services/HealthEvaluator.swift` - severity, counters,
  watchlist ordering, event summaries, and stale mapping.

### Prior Phase Context

- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-CONTEXT.md`
  - setup and watchlist editing decisions.
- `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-CONTEXT.md`
  - warning event and workload reason boundaries.
- `.planning/phases/07-add-operator-facing-qa-and-app-verification/07-CONTEXT.md`
  - UAT and visible app verification expectations.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `Kubebar/Views/StatusSummaryView.swift`: Existing top status presentation can
  stay in Overview and likely remain above or inside the Overview tab.
- `Kubebar/Views/StaleBannerView.swift`: Existing stale banner should remain
  visible in Overview and any tab where stale context would otherwise be
  misleading.
- `Kubebar/Views/CompactCountersView.swift`: Existing compact node, pod, and
  warning counters fit the Overview tab.
- `Kubebar/Views/WatchlistSectionView.swift`: Existing watchlist section should
  remain central to Overview and can help populate Pods.
- `Kubebar/Views/TrackedItemDetailView.swift`: Existing workload/pod detail
  shape can be reused in Pods.
- `Kubebar/Views/WarningEventsView.swift`: Existing warning event list can move
  into Events, with Overview using a lighter summary.
- `Kubebar/Views/NodeDetailsView.swift`: Existing node details can become the
  start of Nodes.
- `Kubebar/Views/SetupView.swift` and `Kubebar/Views/WatchlistPickerView.swift`:
  Existing setup/watchlist editing UI can be moved or reused inside Settings.

### Established Patterns

- SwiftUI views render data; they do not read Kubernetes or calculate health.
- Configuration is app-owned through `AppConfigStore`.
- Refresh remains explicit or cadence-driven; tab changes are UI navigation.
- Stale data must remain visibly stale across the redesigned menu.
- Keyboard support uses native SwiftUI controls and shortcuts.
- The local quality gate is `./scripts/swift-quality-gate.sh local`.

### Integration Points

- `Kubebar/KubebarApp.swift` likely needs an additional settings scene or
  settings dialog trigger plus quit action wiring.
- `Kubebar/MenuBarViewModel.swift` likely needs state/actions for opening
  settings while keeping refresh and display ownership unchanged.
- `Kubebar/Views/MenuBarRootView.swift` is the primary menu composition point
  for tabs, footer actions, and removal of embedded setup as the normal edit
  path.
- `KubebarCore/Models/MenuDisplayModel.swift` may need tab-specific display
  fields if Nodes, Pods, or Events require richer safe summaries than today's
  aggregate counters.
- `KubebarTests/` should cover any new display fields, state transitions, and
  preserved runtime invariants.

</code_context>

<specifics>

## Specific Ideas

- The redesigned menu should feel closer to CodexBar's disciplined menu card:
  compact top status, clear navigation, and settings kept out of the main
  reading surface.
- `Overview` answers "Is the cluster okay, what matters first, and what am I
  watching?"
- `Overview` should not look like a miniature dashboard. Its main job is to
  make the next operational glance obvious: stable or not, what needs
  attention, and which watched namespaces are involved.
- Watchlist rows should carry the primary reading load in Overview. Counters
  explain the state, but they should not push the watched objects down.
- If Overview has a notice, it should feel like the single most important
  heads-up, not a repeated Events preview.
- `Nodes`, `Pods`, and `Events` are drill-in reading surfaces, not command
  centers.
- Settings should feel like an app-level configuration surface, not another
  status tab.
- The quit action should be easy to find, but separated from refresh/settings
  so it is not clicked accidentally.

</specifics>

<deferred>

## Deferred Ideas

- Full Kubernetes dashboard and arbitrary resource browsing.
- Filters, search, sorting controls, and user-customizable tabs.
- Multi-cluster switching beyond the existing saved context.
- Deep debugging handoff such as `Open in k9s`.
- Live watch streams or real-time event feeds.
- CodexBar-style widgets, status polling, provider toggles, or usage meters.

</deferred>

---

*Phase: 09-codexbar-inspired-tabbed-menu-redesign*
*Context gathered: 2026-04-22*
