---
title: "feat: Add per-context watchlists and Quick Context Selector"
type: feat
status: planned
date: 2026-06-03
origin: .imm/specs/2026-06-03-per-context-watchlists-context-selector.md
---

# feat: Add per-context watchlists and Quick Context Selector

## Summary

- Summary: Settings stores a watchlist per Kubernetes context, and the menu can
  switch Kubebar's active context with the matching watchlist.

Add per-context watchlist storage, Settings context tabs, and a menu Quick
Context Selector. Kubebar still monitors one active app-owned selected context
at a time, but each context can keep its own saved watchlist. Switching context
must clear previous-context runtime state before refresh so old data never
looks current.

## Task

- Type: feat
- Scope: per-context watchlists, Settings tabs, menu context switching
- Owner: imm-work
- Verification: automated plus visible Settings/menu smoke
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-REQ-004; BR-REQ-005; BR-REQ-006; BR-REQ-007; BR-DEC-001; BR-DEC-002; BR-OUT-001; BR-OUT-002

## Origin

The user first requested a menu Quick Context Selector, then clarified that
Settings must configure each context's watchlist with multiple tabs. The latest
brainstorm changed the earlier conservative decision: per-context watchlists
are now in scope, while refresh cadence, Start at Login, and Health State Shift
Alerts remain global settings.

## Brainstorm Manifest

- `BR-REQ-001`: Settings supports per-context watchlist.
- `BR-REQ-002`: Settings uses context tabs to distinguish contexts.
- `BR-REQ-003`: Quick Context Selector switches the active context.
- `BR-REQ-004`: Context switching uses that context's own watchlist.
- `BR-REQ-005`: Context switching clears old snapshot data.
- `BR-REQ-006`: Existing single-watchlist config must migrate compatibly.
- `BR-REQ-007`: Contexts with no watchlist show configuration-required state.
- `BR-DEC-001`: Per-context watchlist is in scope and supersedes the earlier
  deferral.
- `BR-DEC-002`: Refresh cadence, Start at Login, and Health State Shift Alerts
  remain global.
- `BR-OUT-001`: No automatic watchlist generation.
- `BR-OUT-002`: No `HealthEvaluator` rule changes.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 adds persisted per-context watchlist data before U2 exposes it in Settings. |
| BR-REQ-002 | covered_by_step | U2 | U2 builds Settings context tabs. |
| BR-REQ-003 | covered_by_step | U3 | U3 adds the menu Quick Context Selector. |
| BR-REQ-004 | covered_by_step | U1 | U1 defines active-context watchlist lookup before U3 uses it during switching. |
| BR-REQ-005 | covered_by_step | U3 | U3 invalidates refresh state and clears old snapshot data on switch. |
| BR-REQ-006 | covered_by_step | U1 | U1 adds old config decoding and migration tests. |
| BR-REQ-007 | covered_by_step | U1 | U1 makes empty active watchlist incomplete; U3 verifies menu switch to unconfigured context. |
| BR-DEC-001 | captured_as_decision | Decisions | This plan scopes per-context watchlists as the central feature. |
| BR-DEC-002 | captured_as_decision | Decisions | Global settings stay global and are verified in U1/U2 tests. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | Watchlists remain explicitly user-selected. |
| BR-OUT-002 | out_of_scope | Scope Boundaries | Health category ownership remains unchanged per runtime invariants. |

## Research

- `CONTEXT.md` now defines `Per-context watchlist` and `Quick Context Selector`
  as canonical terms.
- `docs/architecture/runtime-invariants.md` currently says `AppConfigStore`
  owns saved context and watchlist, setup candidate discovery uses the
  app-owned selected context, empty watchlists are real states, and
  `HealthEvaluator` owns Health category.
- `KubebarCore/Services/AppConfigStore.swift` currently persists one
  `selectedContext` plus one `watchTargets` array; this is the compatibility
  and migration surface.
- `KubebarCore/Services/RefreshCoordinator.swift` already reads
  `config.selectedContext` and `config.watchTargets`, so a computed
  active-watchlist surface can keep refresh logic narrow.
- `KubebarCore/Models/MenuRuntimeState.swift` and `SetupFlowState.swift`
  currently model one selected context and one watchlist; they need an editing
  model that can preserve watchlists for multiple contexts.
- `Kubebar/Views/SetupView.swift` currently renders one menu-style context
  picker plus one namespace watchlist picker; U2 should replace that editing
  shape with native context tabs while reusing `WatchlistPickerView`.
- `Kubebar/MenuBarViewModel.swift` already centralizes Settings actions,
  refresh invalidation, context catalog loading, watch target loading, network
  refresh gating, k9s handoff clearing, and Health State Shift Alert baselines.
  It is the right place to wire menu context switching.
- `KubebarCore/Services/ContextCatalog.swift` already lists kubectl contexts
  through an injectable command boundary.
- `RefreshGate` already rejects old in-flight refresh tickets when config
  changes; U3 should reuse this behavior for context switching.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  is unrelated. No rejected decision entry blocks per-context watchlists.
- Planner research dispatch was not used: existing local evidence was
  sufficient to decompose concrete steps, and extra readonly subagents would
  not change the plan boundaries.

## Decisions

- Use one persisted active selected context plus a persisted
  `watchlistsByContext` map.
- Keep a computed or compatibility `watchTargets` surface that returns the
  active selected context's watchlist so existing refresh-oriented code can
  remain simple.
- Preserve the existing `AppConfig(selectedContext:watchTargets:...)`
  initializer as a compatibility convenience that stores targets under the
  selected context.
- Decode old top-level `watchTargets` into `watchlistsByContext[selectedContext]`
  when the new map is absent.
- Encode new configs with per-context watchlists as the durable shape.
- Settings tabs use only contexts returned by the local kubeconfig context
  list. Saved watchlist keys for missing contexts remain preserved in config but
  do not create visible tabs.
- Selecting a Settings tab selects the context being edited and, after save, the
  active selected context.
- A context without a watchlist can still be selected, but it is incomplete and
  must show setup/configuration-required state until the user saves a watchlist.
- Keep current watchlist picker scope to namespaces because the current UI only
  exposes namespace selection.

## Assumptions

- Context names are stable enough to be dictionary keys; if a context is
  renamed in kubeconfig, the old saved watchlist remains preserved in config but
  is not displayed as a selectable context tab.
- Saving Settings from a context tab makes that tab the active selected context.
- Saved watchlists for contexts not returned by kubectl are preserved in config
  but omitted from the menu selector and Settings tabs.
- Per-context watchlists may initially include only namespaces through the
  existing Settings picker, while old workload targets remain decodable and can
  continue to refresh if already stored.

## Devil's Advocate Audit

- Rollback resilience: U1 is the risky compatibility boundary. The rollback
  path is to revert config/runtime model changes and keep the old top-level
  `watchTargets` path; tests must prove old configs decode before UI changes
  depend on the new shape. U3 must invalidate in-flight refreshes so a failed or
  partial context switch cannot apply old-context data.
- Verification vanity: tests must assert active-context watchlist lookup,
  old-config migration, context-specific Settings edits, and refresh reader
  arguments after switching. A test that only checks a tab label or menu label
  exists is not enough.
- Spec dilution detection: every brainstorm item is mapped. The expensive
  migration work is not hidden behind a UI-only plan; automatic watchlist
  generation and Health rule changes are explicitly out of scope.

## Planning Quality Gate

- Contract surface: `AppConfig`, `AppConfigStore`, `RefreshCoordinator`,
  `RefreshGate`, `SetupFlowState`, `MenuRuntimeState`, `WatchlistSelectionState`,
  `SetupView`, `SettingsRootView`, `MenuBarRootView`, `StatusSummaryView`,
  `MenuBarViewModel`, config tests, runtime state tests, refresh/view-model
  tests, `CONTEXT.md`, `.imm/specs`, plan docs, and runtime invariants.
- Compatibility: existing config files with `selectedContext` and
  `watchTargets` decode and migrate; existing configs without
  `healthShiftAlertsEnabled` still default off; global settings survive
  round-trip.
- Interruption recovery: if execution stops after U1, the app should still
  compile with old Settings behavior using the active-context watchlist
  compatibility surface. If execution stops after U2, Settings can save
  per-context data even before the menu selector is added.
- Rollback path: U1 can be reverted as one config/runtime slice; U2 can be
  reverted to the old Settings picker if needed; U3 can be reverted without
  removing per-context storage.
- Verification strength: each step uses focused tests plus the Swift quality
  gate. U3 additionally requires visible menu smoke because it changes the menu
  surface.
- Brainstorm traceability: every `BR-*` item above is mapped.

## Scope Boundaries

- In scope: per-context persisted watchlists, old config migration, Settings
  context tabs, Quick Context Selector, active-context switch state invalidation,
  focused tests, runtime invariant documentation, and visible smoke guidance.
- Out of scope: automatic watchlist generation, per-context global settings,
  terminal context mutation, new health rules, deep troubleshooting, k9s handoff
  behavior changes, and new Kubernetes read categories.

## Implementation Units

### Step 1

- Step ID: U1
- Result: App config supports compatible per-context watchlist storage.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: missing config remains setup-required; old config with selectedContext and watchTargets migrates targets under that context; new per-context config round trips multiple context watchlists; active watchTargets returns only selectedContext targets; selected context with no watchlist is incomplete; refresh uses the active context and active watchlist; refresh cadence and Health State Shift Alerts remain global

**Goal:** Establish the persisted data contract before changing user-facing
editing or switching surfaces.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1-R4, R16

**Dependencies:** None

**Discovery cache:**
- `KubebarCore/Services/AppConfigStore.swift` (persisted config and compatibility decoding)
- `KubebarCore/Services/RefreshCoordinator.swift` (active context/watchlist consumer)
- `KubebarTests/Services/AppConfigStoreTests.swift` (config compatibility coverage)
- `KubebarTests/Services/RefreshCoordinatorTests.swift` (refresh active-watchlist coverage)
- `KubebarTests/Services/RefreshGateTests.swift` (config-change ticket behavior)

**Files:**
- Modify: `KubebarCore/Services/AppConfigStore.swift`
- Modify: `KubebarCore/Services/RefreshCoordinator.swift`
- Modify: `KubebarTests/Services/AppConfigStoreTests.swift`
- Modify: `KubebarTests/Services/RefreshCoordinatorTests.swift`
- Reference: `.imm/specs/2026-06-03-per-context-watchlists-context-selector.md`
- Reference: `CONTEXT.md`

**Approach:**
- Add tests first for old and new config decoding, active watchlist lookup, and
  incomplete active context behavior.
- Introduce `watchlistsByContext` while preserving existing initializer and
  active `watchTargets` access.
- Keep global refresh cadence and Health State Shift Alerts fields unchanged.
- Make `needsSetup` depend on selected context plus that context's active
  watchlist.
- Keep `RefreshCoordinator` consuming `config.selectedContext` and active
  `config.watchTargets`.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** A corrupt config remains recoverable as
`AppConfigStoreError.corruptConfig`. A selected context without a watchlist
returns setup-required display instead of refreshing or showing healthy data.

**security_considerations:** Config remains local app data. No Secrets, raw
command transcripts, credentials, or new Kubernetes reads are introduced.

### Step 2

- Step ID: U2
- Result: Settings edits separate watchlists through context tabs.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: 1
- Test scenarios: Settings opens with tabs for available local kubeconfig contexts only; selecting a tab loads candidates for that context; each tab preserves its own namespace selections; failed candidate loading preserves the selected context watchlist and other context watchlists; saving Settings writes all per-context watchlists and makes the active tab the selected context; existing global Settings toggles and cadence remain unchanged

**Goal:** Let users configure per-context watchlists in Settings without losing
saved watchlists for other contexts.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R5-R9, R15-R16

**Dependencies:** 1

**Discovery cache:**
- `KubebarCore/Models/SetupFlowState.swift` (Settings state copy and labels)
- `KubebarCore/Models/MenuRuntimeState.swift` (Settings save and candidate loading state)
- `KubebarCore/Models/WatchlistSelectionState.swift` (per-tab selection values)
- `Kubebar/Views/SetupView.swift` (Settings tab UI)
- `Kubebar/Views/SettingsRootView.swift` (Settings window/callback plumbing)
- `Kubebar/Views/WatchlistPickerView.swift` (reused namespace picker)
- `Kubebar/MenuBarViewModel.swift` (context/catalog/watch-target loading)
- `KubebarTests/Models/SetupFlowStateTests.swift` (Settings labels/configuration)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (Settings runtime behavior)

**Files:**
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarCore/Models/WatchlistSelectionState.swift`
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`

**Approach:**
- Add tests first for local-only context tab display, per-context preservation,
  candidate loading success/failure, and completed config output.
- Extend setup runtime state with an editing context and per-context watchlist
  map.
- Make context list loading use local kubeconfig contexts for visible tabs while
  preserving saved watchlist keys in config.
- Replace the single Settings context picker with native context tabs or a
  tab-equivalent SwiftUI control that is keyboard reachable.
- Reuse `WatchlistPickerView` for the active tab's namespace selection.
- Keep Start at Login, Health State Shift Alerts, and refresh cadence controls
  as global rows below the per-context watchlist editor.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** Candidate discovery failure for a context shows retry
feedback for that tab and preserves all saved selections. Saving failure keeps
Settings open with the existing concise save failure message.

**security_considerations:** Settings displays safe context and namespace names
only. It must not expose command transcripts, raw JSON, Secrets, or
credentials.

### Step 3

- Step ID: U3
- Result: The menu Quick Context Selector switches active context safely with the matching watchlist.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: 2
- Test scenarios: menu selector lists available local kubeconfig contexts only; current context is visually identifiable and accessible; selecting another configured context saves it, clears previous snapshot/freshness/handoff/alert state, rejects old in-flight refresh results, and refreshes with that context's watchlist; selecting a context without a watchlist shows configuration-required state; selector does not mutate terminal current context; long context names truncate in the menu with full help/accessibility text

**Goal:** Complete the user-facing quick switch flow from menu action to fresh
active-context monitoring.

**Verification type:** hitl

**Execution note:** test-first

**Requirements:** R10-R17

**Dependencies:** 2

**Discovery cache:**
- `Kubebar/Views/MenuBarRootView.swift` (menu composition)
- `Kubebar/Views/StatusSummaryView.swift` (top status context display)
- `Kubebar/Views/MenuFooterView.swift` (footer height constraints reference)
- `Kubebar/MenuBarViewModel.swift` (switch action, save, refresh invalidation)
- `Kubebar/KubebarApp.swift` (menu callback wiring)
- `KubebarCore/Services/ContextCatalog.swift` (available contexts)
- `KubebarCore/Services/RefreshGate.swift` (old refresh rejection)
- `KubebarTests/Services/RefreshGateTests.swift` (refresh invalidation coverage)
- `docs/architecture/runtime-invariants.md` (updated runtime rules)

**Files:**
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `Kubebar/Views/StatusSummaryView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/KubebarApp.swift`
- Modify: `KubebarTests/Services/RefreshGateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `.imm/specs/2026-06-03-per-context-watchlists-context-selector.md`
- Modify: `docs/plans/2026-06-03-001-feat-per-context-watchlists-context-selector-plan.md`

**Approach:**
- Add focused tests for view-model context switching and refresh invalidation
  before UI wiring where practical.
- Add a menu selector model/action surface that lists saved plus available
  contexts and marks the active one.
- Save the selected active context without changing terminal current context.
- Reuse `invalidateRefreshState(clearSnapshot: true)` and refresh gate
  invalidation so old refresh results cannot apply after a switch.
- Show a safe initial display for the new context before refresh result
  arrives, or setup-required state when that context has no watchlist.
- Update runtime invariants for per-context watchlists and Quick Context
  Selector behavior.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Optional visible smoke: `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=healthy ./scripts/compile-and-run.sh`, then open the menu and confirm the Quick Context Selector is visible, keyboard reachable, and does not overlap the tab bar or footer.
- Optional visible smoke: `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=setup ./scripts/compile-and-run.sh`, then open Settings and confirm context tabs are reachable.

**failure_behavior:** If saving the new active context fails, keep the previous
active config and show recoverable feedback instead of clearing the display. If
refresh fails after a successful switch, show the new context's stale/no
previous data state and never reuse old-context snapshot data.

**security_considerations:** The selector displays safe context names and uses
existing local config plus `kubectl config get-contexts -o name`. It must not
query Secrets, expose raw command output, or mutate Kubernetes resources.

## Validation Notes

- Use the system Immune-Brain CLI:
  `/Users/derek/.codex/plugins/cache/agent-skills/immune-brain/0.5.7/bin/imm-plan docs/plans/2026-06-03-001-feat-per-context-watchlists-context-selector-plan.md --json`.
