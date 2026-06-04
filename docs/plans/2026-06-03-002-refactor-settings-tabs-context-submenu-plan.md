---
title: "refactor: Split Settings tabs and nest context switching"
type: refactor
status: planned
date: 2026-06-03
origin: .imm/specs/2026-06-03-settings-tabs-context-submenu.md
---

# refactor: Split Settings tabs and nest context switching

## Summary

- Summary: Settings separates global app settings from context watchlist tabs,
  and the menu switches context through a nested submenu instead of a top-level
  selector row.

This refactor keeps the existing per-context watchlist storage and app-owned
active context model. It changes the Settings and menu interaction shape only:
the first Settings tab is fixed for global app settings, context tabs are
generated from local context information, and the menu Quick Context Selector
becomes a nested submenu.

## Task

- Type: refactor
- Scope: Settings tab structure, menu context submenu, layout/docs updates
- Owner: imm-work
- Verification: automated plus visible Settings/menu smoke
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-REQ-004; BR-DEC-001; BR-DEC-002; BR-OUT-001; BR-OUT-002; BR-DEFER-001; BR-Q-001

## Origin

The user asked to rethink the previous per-context Settings/menu implementation:
Settings should distinguish app-wide settings from per-context settings, the
main menu should replace the standalone context switch row with a nested
submenu, and context list information must come from the local machine.

The user resolved the open Settings shape question by choosing tabs: one fixed
general settings tab first, then dynamic tabs based on context count.

Replan note: U1 was already implemented before the workflow captured RED-phase
test evidence. The plan therefore treats U1 as a test-backed recovery closure,
not as a strict TDD step. Closure must not require fabricated historical RED
evidence. The full Swift quality gate remains the preferred verification path,
but if the local Swift/Xcode test runner hangs, U1 may close on the focused
fallback commands listed in Step 1 with the hang recorded as an environment
verification limitation.

Replan note 2: U2 implementation reached verification, but the local
Swift/Xcode test runner failed before assertions because the generated test
bundle could not load under the current signing/system-policy behavior. U2 does
not need a separate product step for this environment issue. Closure may use the
explicit U2 fallback only when the failing test command never reaches
assertions, the failure is recorded as a test-bundle loading/signing/system
policy denial, the build/diff commands pass, and a visible menu smoke confirms
the nested Quick Context Selector is reachable. If tests run and fail
assertions, the fallback is invalid and U2 must return to implementation.

## Brainstorm Manifest

- `BR-REQ-001`: Settings needs to distinguish app-wide settings from
  per-context settings.
- `BR-REQ-002`: Per-context Settings must keep using the app-owned selected
  context model and saved per-context watchlists.
- `BR-REQ-003`: The main menu must replace the standalone context switch row
  with a nested submenu selection.
- `BR-REQ-004`: Context list information must come from the local machine.
- `BR-DEC-001`: Kubebar keeps a single active context at a time.
- `BR-DEC-002`: Refresh cadence, Start at Login, and Health State Shift Alerts
  remain global app settings.
- `BR-OUT-001`: Do not add remote Kubernetes reads to list contexts.
- `BR-OUT-002`: Do not change `HealthEvaluator` rules.
- `BR-DEFER-001`: Removal/cleanup of saved watchlists for missing local
  contexts is deferred; missing contexts are preserved in config but not shown
  as selectable entries.
- `BR-Q-001`: Settings structure uses tabs: fixed `App Settings` first, then
  dynamic context tabs.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 splits Settings into an app-wide tab and context tabs. |
| BR-REQ-002 | covered_by_step | U1 | U1 keeps the existing app-owned active context and per-context watchlist model. |
| BR-REQ-003 | covered_by_step | U2 | U2 replaces the standalone menu selector row with a nested submenu. |
| BR-REQ-004 | covered_by_step | U1 | U1 establishes local context information as the Settings tab source; U2 reuses the same boundary for the menu submenu. |
| BR-DEC-001 | captured_as_decision | Decisions | The plan keeps one active app-owned context at a time. |
| BR-DEC-002 | captured_as_decision | Decisions | Global settings stay in the fixed `App Settings` tab. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | Context discovery remains local; no cluster API reads are added. |
| BR-OUT-002 | out_of_scope | Scope Boundaries | Health category ownership remains unchanged. |
| BR-DEFER-001 | deferred | Scope Boundaries | Missing-context watchlist cleanup needs separate product behavior and deletion UX; display is still limited to local kubeconfig contexts. |
| BR-Q-001 | resolved_as_assumption | Assumptions | The user confirmed Settings uses tabs with fixed general tab first and dynamic context tabs after it. |

## Research

- `CONTEXT.md` now defines `App Settings tab`, `Context Settings tab`,
  `Per-context watchlist`, and `Quick Context Selector`.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`
  captures the active-context ownership pattern to preserve.
- `Kubebar/Views/SetupView.swift` currently renders a single vertical Settings
  form with context watchlist controls followed by global settings.
- `Kubebar/Views/SettingsRootView.swift` owns Settings window sizing and hosts
  `SetupView`.
- `KubebarCore/Models/SetupFlowState.swift` currently exposes `contextTabs` and
  a single editable `watchlist`; it needs enough UI state to represent the fixed
  app tab separately from a selected context tab.
- `Kubebar/Views/MenuBarRootView.swift` currently renders `ContextSelectorView`
  as a top-level row before menu tabs.
- `Kubebar/Views/MenuFooterView.swift` currently contains refresh, settings,
  and quit buttons; it is the likely home for a compact nested context submenu
  because the user wants the top-level context row removed.
- `KubebarCore/Services/ContextCatalog.swift` lists contexts through
  `kubectl config get-contexts -o name`, which is local kubeconfig data and not
  a Kubernetes cluster API read.
- `docs/architecture/runtime-invariants.md` already requires app-owned context
  switching, no terminal current-context mutation, stale-state invalidation, and
  per-context watchlist preservation.
- U2 verification in this environment has a known pre-assertion XCTest bundle
  loading blocker: full quality gate reaches Xcode test after build, but
  `KubebarTests.xctest` is denied by signing/system policy before test
  assertions can execute. Focused SwiftPM test execution hits the same
  pre-assertion denial.
- The rejected decision entry for Pod resource history/alerts is unrelated.
- Planner research dispatch was not used: the scope is narrow and existing
  local files provide concrete verification paths.

## Decisions

- Settings uses one top-level tab control.
- The first tab is fixed and named `App Settings`.
- `App Settings` contains refresh cadence, Start at Login, and Health State
  Shift Alerts.
- Context tabs appear after `App Settings` and are generated from local context
  information.
- "Local context information" means the existing local `ContextCatalog`
  boundary. Saved watchlist keys are preserved in config but do not create
  Settings tabs or menu selector entries.
- Context tabs edit per-context watchlists only.
- Saving from Settings keeps the existing behavior that the selected context tab
  can become the active selected context; saving while on `App Settings` keeps
  the current active context.
- U1 is a recovery closure for an already-implemented Settings refactor. It is
  test-backed, but not `test-first`, because the RED phase cannot be honestly
  reconstructed after implementation exists.
- Full quality gate evidence is preferred for every step. When the local
  Swift/Xcode test runner hangs, the executor must record the attempted command,
  termination, and focused fallback results instead of treating the hang as a
  product pass.
- For U2 only, a pre-assertion test-bundle loading, signing, or system-policy
  denial is treated like the existing runner-hang fallback: record the exact
  failure, require passing build/diff fallback commands, and require a visible
  menu smoke. This does not waive failures from tests that actually run
  assertions.
- The menu Quick Context Selector becomes a nested submenu, not a standalone
  top-level row.
- The nested submenu reuses the existing app-owned context switch action.

## Assumptions

- The fixed `App Settings` tab is always visible even when no contexts are
  available.
- Context tabs should preserve saved watchlists for contexts missing from the
  current kubeconfig list, but deletion or cleanup of those saved entries is out
  of scope.
- The nested context submenu can live in the menu footer toolbar unless the
  implementation discovers a clearer existing menu-command location.
- This refactor should not change the saved config schema.

## Devil's Advocate Audit

- Rollback resilience: U1 can be reverted to the existing vertical Settings
  form without changing persisted config. U2 can be reverted to the standalone
  top-level selector without changing context-switch semantics. Because the data
  schema stays unchanged, rollback does not need a migration.
- Verification vanity: U1 tests must assert actual tab ordering and state
  behavior, not only the presence of labels. U1 closure must not pretend that
  after-the-fact tests are RED-phase evidence. U2 prefers tests that assert the
  top-level context row is removed from layout budgeting and that submenu
  selection still drives the existing active-context switch behavior. When the
  local runner fails before assertions because of test-bundle loading/signing
  denial, U2 closure must pair build/diff evidence with visible menu smoke, and
  the fallback is invalid if assertion failures are observed.
- Spec dilution detection: the plan keeps all confirmed items: app/global vs
  context Settings split, fixed first tab, dynamic context tabs, local context
  source, nested menu selection, single active context, and global app settings.
  Cleanup of missing saved contexts is explicitly deferred rather than silently
  dropped.

## Planning Quality Gate

- Contract surface: `SetupFlowState`, `MenuRuntimeState`, `SetupView`,
  `SettingsRootView`, `MenuBarRootView`, `MenuFooterView`,
  `MenuLayoutSizing`, `MenuBarViewModel`, runtime state tests, layout sizing
  tests, and runtime invariants.
- Compatibility: no `AppConfig` schema change; existing saved per-context
  watchlists and global settings must survive.
- Interruption recovery: after U1, Settings may be tabbed while the menu still
  has the old selector. After U2, both Settings and menu match the new
  interaction shape.
- Rollback path: each step is UI/state wiring only and can revert independently
  because the data contract remains unchanged.
- Verification strength: U1 uses focused model/runtime assertions, `swift
  build`, `swift build --target KubebarCoreTests`, and `rtk git diff --check`
  as the non-hanging fallback when the full Swift quality gate's test runner
  hangs. U2 uses menu/layout tests plus the Swift quality gate and a visible
  menu smoke; if the runner hangs or fails before assertions because the test
  bundle is denied by signing/system policy, executor evidence must record the
  exact blocker, the passing fallback build/diff commands, and the visible menu
  smoke result.
- Brainstorm traceability: every `BR-*` item is mapped above.

## Scope Boundaries

- In scope: Settings top-level tabs, fixed `App Settings` tab, dynamic context
  tabs from local context information, nested menu context submenu, layout
  budget update, focused tests, and runtime invariant updates.
- Out of scope: config schema migration, remote context discovery, terminal
  current-context mutation, missing saved-context deletion UX, HealthEvaluator
  changes, automatic watchlist generation, and per-context global settings.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Settings uses an App/Context tab structure.
- Verification: swift build && swift build --target KubebarCoreTests && rtk git diff --check
- Depends on: None
- Test scenarios: App Settings is the first Settings tab; context tabs follow local context information; refresh cadence Start at Login and Health State Shift Alerts render only in App Settings; selecting context tabs preserves per-context watchlist edits; saving from App Settings preserves the current active context; saved watchlists survive when local context list changes

**Goal:** Make Settings visually and behaviorally distinguish app-wide settings
from per-context watchlist editing.

**Verification type:** automated fallback

**Closure note:** U1 is already implemented. Re-run and record focused
test-backed evidence; do not require or invent RED-phase TDD evidence for this
recovery closure.

**Requirements:** R1-R8, R12

**Dependencies:** None

**Discovery cache:**
- `KubebarCore/Models/SetupFlowState.swift` (Settings state and context tab model)
- `KubebarCore/Models/MenuRuntimeState.swift` (completed config and Settings save behavior)
- `Kubebar/Views/SetupView.swift` (Settings content layout)
- `Kubebar/Views/SettingsRootView.swift` (Settings window wrapper)
- `Kubebar/Views/WatchlistPickerView.swift` (context watchlist editor)
- `KubebarTests/Models/SetupFlowStateTests.swift` (Settings state tests)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (Settings save/runtime tests)
- `docs/architecture/runtime-invariants.md` (Settings tab invariants)

**Files:**
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-06-03-settings-tabs-context-submenu.md`
- Reference: `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`

**Approach:**
- Confirm state tests cover the fixed app tab and dynamic context tabs.
- Introduce a small Settings tab model that can represent `App Settings` and
  context tabs without changing `AppConfig`.
- Move global settings controls into the fixed app tab.
- Keep `WatchlistPickerView` only on context tabs.
- Preserve unsaved per-context watchlist edits while switching tabs.
- Attempt the full quality gate. If its test runner hangs, record the hang and
  use the focused fallback commands for U1 closure.

**Verification:**
- Preferred: `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Fallback when the local Swift/Xcode test runner hangs:
  - `swift build`
  - `swift build --target KubebarCoreTests`
  - `rtk git diff --check`

**failure_behavior:** If local context loading fails, `App Settings` remains
usable and existing saved watchlists remain preserved.

**security_considerations:** Context names remain local display strings. No
Secrets, raw JSON, or remote Kubernetes context discovery are introduced.

### Step 2

- Step ID: U2
- Result: The menu Quick Context Selector moves into a nested submenu.
- Verification: Preferred quality gate; fallback on pre-assertion test-bundle denial uses swift build, swift build --target KubebarCoreTests, rtk git diff --check, and visible menu smoke
- Depends on: 1
- Test scenarios: top-level Context selector row is removed; a nested context submenu lists local context information; current context is marked accessibly; selecting a configured context preserves existing active-context switch behavior; selecting an unconfigured context shows configuration-required state; selected tab height uses the no-top-selector budget; long context names keep full help/accessibility text

**Goal:** Move context switching out of the first scan area while keeping the
same safe app-owned switching behavior.

**Verification type:** hitl

**Closure note:** U2 implementation already exists. Re-run verification under
the revised fallback contract. Do not close U2 on source inspection alone. If
the quality gate or focused tests reach assertions and fail, treat that as a
product/test failure and return to implementation instead of using the fallback.

**Requirements:** R3-R4, R8-R12

**Dependencies:** 1

**Discovery cache:**
- `Kubebar/Views/MenuBarRootView.swift` (current top-level context selector and menu layout)
- `Kubebar/Views/MenuFooterView.swift` (footer toolbar and likely submenu home)
- `Kubebar/MenuBarViewModel.swift` (context list refresh and context switch action)
- `KubebarCore/Services/MenuLayoutSizing.swift` (selected tab height budget)
- `KubebarTests/Services/MenuLayoutSizingTests.swift` (menu height tests)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (context selector state tests)
- `KubebarTests/Models/AppConfigTests.swift` (context switch config tests)
- `docs/architecture/runtime-invariants.md` (menu context switch invariants)

**Files:**
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `Kubebar/Views/MenuFooterView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarCore/Services/MenuLayoutSizing.swift`
- Modify: `KubebarTests/Services/MenuLayoutSizingTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `KubebarTests/Models/AppConfigTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `.imm/specs/2026-06-03-settings-tabs-context-submenu.md`

**Approach:**
- Add or adjust tests for the menu context list and layout budget where the
  runner can produce bounded evidence.
- Remove the top-level `ContextSelectorView` row from `MenuBarRootView`.
- Add a compact nested context submenu, likely in `MenuFooterView`.
- Reuse `MenuBarViewModel.selectMenuContext` and local context refresh
  behavior.
- Revert selected tab height budgeting to the no-top-selector reserved height.
- Attempt the full quality gate. If its test runner hangs, record the hang and
  run the strongest non-hanging build/diff checks plus visible smoke.
- If the test runner fails before assertions because the test bundle cannot
  load under local signing/system-policy behavior, record the exact failure and
  use the same build/diff plus visible smoke fallback.

**Verification:**
- Preferred: `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Fallback when the local test runner hangs or fails before assertions because
  of test-bundle loading, signing, or system-policy denial:
  - `swift build`
  - `swift build --target KubebarCoreTests`
  - `rtk git diff --check`
  - `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=healthy ./scripts/compile-and-run.sh`, then open the menu and confirm context switching is reachable from the nested submenu without overlapping the tab bar or footer.
- Fallback is invalid if any test reaches assertions and fails.

**failure_behavior:** If context list loading returns empty, the submenu should
show a disabled or empty local-context state without changing the active
context.

**security_considerations:** The submenu displays local context names only. It
must not mutate kubeconfig current context or query Kubernetes Secrets.

## Validation Notes

- Validate with:
  `/Users/derek/.codex/plugins/cache/agent-skills/immune-brain/0.5.7/bin/imm-plan docs/plans/2026-06-03-002-refactor-settings-tabs-context-submenu-plan.md --json`
- Sync after validation with:
  `/Users/derek/.codex/plugins/cache/agent-skills/immune-brain/0.5.7/bin/imm-plan docs/plans/2026-06-03-002-refactor-settings-tabs-context-submenu-plan.md --sync`
