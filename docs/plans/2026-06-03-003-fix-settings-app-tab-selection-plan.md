---
title: "fix: Settings App Settings tab selection"
type: fix
status: planned
date: 2026-06-03
origin: .imm/specs/2026-06-03-settings-app-tab-selection.md
---

# fix: Settings App Settings tab selection

## Summary

- Summary: Fix Settings so selecting the fixed `App Settings` tab responds
  immediately after the user is on a Context Settings tab.

The user confirmed the regression occurs with 2 contexts, so the failing path
is the segmented Settings tab selector. The plan keeps the fix narrow: make tab
selection use a stable tab identity and publish the `App Settings` transition
through the same runtime state boundary used for context tab selection.

## Task

- Type: fix
- Scope: Settings tab selector state and regression tests
- Owner: imm-work
- Verification: automated focused tests plus 2-context visible Settings smoke
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-DEC-001; BR-Q-001

## Origin

The user reported that after switching Settings from a context tab back to app
settings, the tab does not respond. The user then clarified that this happens
when the context count is 2, which means the segmented picker path is affected.

## Brainstorm Manifest

- `BR-REQ-001`: From any Context Settings tab, selecting `App Settings` must
  immediately update the Settings content.
- `BR-REQ-002`: Switching back to `App Settings` must preserve unsaved
  per-context watchlist edits.
- `BR-REQ-003`: The fix must cover the 2-context segmented Settings tab
  selector path.
- `BR-DEC-001`: Use stable Settings tab identity and route state through
  runtime/ViewModel publishing instead of relying only on direct view-local
  enum tag mutation.
- `BR-Q-001`: Whether the issue was menu-only or segmented too.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 fixes App Settings selection from context tabs. |
| BR-REQ-002 | covered_by_step | U1 | U1 preserves the current context watchlist before switching tabs. |
| BR-REQ-003 | covered_by_step | U1 | U1 explicitly verifies the 2-context segmented selector path. |
| BR-DEC-001 | captured_as_decision | Decisions | The plan chooses stable tab identity plus runtime/ViewModel publishing. |
| BR-Q-001 | resolved_as_assumption | Assumptions | The user confirmed the issue appears when context count is 2. |

## Research

- `CONTEXT.md` defines `App Settings tab`, `Context Settings tab`, and
  `Per-context watchlist`; the plan uses those terms.
- `docs/architecture/runtime-invariants.md` requires `App Settings` to remain
  fixed first and Settings tab switching to preserve each context's watchlist.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`
  captures the app-owned active context and per-context watchlist ownership
  pattern that this fix must preserve.
- `Kubebar/Views/SetupView.swift` currently drives the Settings tab picker with
  `SettingsTabSelection` enum tags and handles `App Settings` inside the view.
- `KubebarCore/Models/SetupFlowState.swift` already has
  `selectAppSettingsTab()` and preserves the current context watchlist before
  switching tabs.
- `KubebarCore/Models/MenuRuntimeState.swift` already exposes
  `selectAppSettingsTab()` and clears the configuration message.
- `Kubebar/MenuBarViewModel.swift` publishes runtime state through
  `publishRuntimeState()`, but Settings currently has no explicit ViewModel
  callback for selecting `App Settings`.
- Planner research dispatch was not used: this is a single-domain, small-scope
  UI/state bugfix with concrete local file pointers.

## Decisions

- Keep `App Settings` as the fixed first Settings tab.
- Use a stable Settings tab identity for picker tags instead of relying on
  associated-value enum tags in SwiftUI segmented Picker.
- Add an explicit `App Settings` selection callback from `SetupView` to
  `SettingsRootView` and `MenuBarViewModel`.
- Preserve the existing `SetupFlowState.selectAppSettingsTab()` behavior that
  stores the current context watchlist before changing tabs.
- Do not change `AppConfig`, context discovery, Quick Context Selector, or
  health evaluation behavior.

## Assumptions

- The 2-context reproduction is sufficient to prove the segmented selector path
  is affected.
- The menu-style picker path should benefit from the same stable tab identity,
  but the visible smoke priority is the confirmed 2-context segmented case.
- If the local machine cannot provide exactly 2 contexts during verification,
  the executor may use a temporary local kubeconfig with 2 context entries for
  the visible Settings smoke.

## Devil's Advocate Audit

- Rollback resilience: The fix is UI/state wiring only. If it fails midway,
  reverting the affected Settings selector and callback changes restores the
  previous Settings implementation without a config migration or data cleanup.
- Verification vanity: Model tests alone could pass while SwiftUI's segmented
  Picker still ignores the `App Settings` click. U1 therefore requires a
  visible Settings smoke with 2 contexts in addition to focused automated
  tests. The smoke must confirm the content actually changes back to app-wide
  controls, not just that the `App Settings` label exists.
- Spec dilution detection: The plan keeps the confirmed regression narrow but
  does not omit the important preservation requirement: switching tabs must
  keep each context's watchlist independently. Menu Quick Context Selector and
  persistence changes are intentionally out of scope because the reported bug
  is Settings tab selection.

## Scope Boundaries

- In scope: Settings tab picker identity, App Settings selection action,
  runtime/ViewModel publishing for App Settings selection, focused state tests,
  and 2-context visible Settings smoke.
- Out of scope: `AppConfig` schema, remote context discovery, terminal current
  context mutation, Quick Context Selector behavior, HealthEvaluator rules, and
  per-context app-wide settings.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Settings App Settings tab responds when selected from context tabs.
- Verification: swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && rtk git diff --check plus visible Settings smoke with 2 contexts
- Depends on: None
- Test scenarios: 2-context segmented selector switches from a Context Settings tab to App Settings; switching to App Settings preserves the edited context watchlist; App Settings content shows refresh cadence Start at Login and Health State Shift Alerts; context tabs remain generated from local and saved context information; menu-style selector path still uses stable tab identity

**Goal:** Make Settings tab selection deterministic and publish the `App
Settings` transition through the same state boundary as other Settings actions.

**Verification type:** automated plus hitl

**Requirements:** R1-R6

**Dependencies:** None

**Discovery cache:**
- `Kubebar/Views/SetupView.swift` (Settings tab picker and tab content switch)
- `Kubebar/Views/SettingsRootView.swift` (Settings callback wiring)
- `Kubebar/MenuBarViewModel.swift` (runtime state publication boundary)
- `KubebarCore/Models/SetupFlowState.swift` (Settings tab state and watchlist preservation)
- `KubebarCore/Models/MenuRuntimeState.swift` (App Settings tab selection action)
- `KubebarTests/Models/SetupFlowStateTests.swift` (state preservation tests)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (runtime Settings tests)
- `docs/architecture/runtime-invariants.md` (Settings tab invariants)

**Files:**
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Reference: `KubebarCore/Models/MenuRuntimeState.swift`
- Reference: `docs/architecture/runtime-invariants.md`

**Approach:**
- Add or expose stable tab identifiers for `App Settings` and context tabs.
- Drive the Settings `Picker` selection with stable tab identifiers, mapping
  selected IDs back to `SettingsTabSelection`.
- Route `App Settings` selection through an explicit callback so the ViewModel
  calls `runtimeState.selectAppSettingsTab()` and publishes runtime state.
- Keep context tab selection on the existing `selectSetupContext` path.
- Add focused tests for preserving watchlist edits when returning to
  `App Settings`.
- Run focused tests and a visible Settings smoke with 2 contexts.
- Run the full Swift quality gate before final closure when feasible.

**Verification:**
- Focused:
  - `swift test --filter SetupFlowStateTests`
  - `swift test --filter MenuRuntimeStateTests`
  - `rtk git diff --check`
- Visible smoke:
  - Launch Kubebar with 2 local contexts available.
  - Open Settings.
  - Select a Context Settings tab.
  - Select `App Settings`.
  - Confirm the selected content changes to refresh cadence, Start at Login,
    and Health State Shift Alerts.
- Preferred full gate:
  - `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** If the visible smoke cannot access 2 local contexts from
the user's kubeconfig, use a temporary local kubeconfig with 2 context entries
and record that verification setup.

**security_considerations:** The fix only changes local UI state and local
context names. It must not read Kubernetes Secrets, mutate kubeconfig current
context, or add remote Kubernetes reads.
