---
title: "refactor: Settings sidebar detail layout"
type: refactor
status: planned
date: 2026-07-01
origin: .imm/specs/2026-07-01-settings-sidebar-layout.md
---

# refactor: Settings sidebar detail layout

## Summary

- Summary: Redesign Kubebar Settings from a stacked tab/form surface into a native sidebar/detail layout with a dedicated `AI Assistant` page.

This plan is a UI structure refactor. It does not change AI provider behavior, Keychain behavior, Kubernetes reads, saved AppConfig semantics, Health category evaluation, or menu health display. It reorganizes Settings so App-level pages and Context watchlist pages have clearer hierarchy and local actions.

## Task

- Type: refactor
- Scope: Settings navigation state, Settings window layout, `SetupView`, `SettingsRootView`, Settings tests, and canonical Settings vocabulary docs
- Owner: imm-work
- Verification: focused Settings state tests, Swift build/tests, full Swift quality gate, and visible Settings smoke
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-REQ-004; BR-REQ-005; BR-REQ-006; BR-REQ-007; BR-REQ-008; BR-REQ-009; BR-REQ-010; BR-OUT-001; BR-OUT-002; BR-OUT-003; BR-OUT-004; BR-DEC-001; BR-DEC-002; BR-DEC-003

## Output Language

Spec and Plan prose are English. Schema fields, commands, file paths, Swift identifiers, canonical terms, and Immune-Brain fields stay literal.

## Origin

The user confirmed the design direction after noting that the current Settings layout feels like a simple stack of controls. The confirmed direction is:

- Keep a standard macOS Settings feel.
- Move from one long App Settings page to sidebar/detail navigation.
- Keep App pages separate from Context watchlist pages.
- Give `AI Diagnostic Assistant` a dedicated `AI Assistant` page instead of appending it under unrelated sections.
- Prioritize grouping, spacing, scroll behavior, and local action placement over decorative styling.

## Brainstorm Manifest

- `BR-REQ-001`: Settings uses a sidebar/detail layout instead of a stacked `TabView` page.
- `BR-REQ-002`: Sidebar groups App-level pages separately from Context pages.
- `BR-REQ-003`: App pages are `General`, `Kubernetes`, `Notifications`, and `AI Assistant`.
- `BR-REQ-004`: Context pages continue to edit exactly one per-context watchlist.
- `BR-REQ-005`: `AI Assistant` is a dedicated App page, not a bottom section on a long App Settings page.
- `BR-REQ-006`: `AI Assistant` groups Provider, Endpoint, Credentials, and Connection.
- `BR-REQ-007`: `AI Assistant` explains manual Test Connection, Keychain-backed API keys, and no Kubernetes data in Test Connection.
- `BR-REQ-008`: Detail content scrolls when needed while the footer remains reachable.
- `BR-REQ-009`: Form fields keep readable width limits instead of stretching across the whole detail pane.
- `BR-REQ-010`: Existing Settings save and state behavior is preserved.
- `BR-OUT-001`: No new AI diagnostic execution or automatic/background AI action.
- `BR-OUT-002`: No new provider choices, custom headers, OAuth, cloud sync, or chat surface.
- `BR-OUT-003`: No Kubernetes read/write behavior changes.
- `BR-OUT-004`: No custom visual theme, rich animation, or decorative redesign.
- `BR-DEC-001`: `AI Assistant` should be an App-level Settings page because it is app-wide helper configuration.
- `BR-DEC-002`: `Test Connection` remains a local action in the `AI Assistant` detail pane, not a footer action.
- `BR-DEC-003`: The window may become wider if needed to fit sidebar plus detail forms comfortably.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1, U2 | U1 creates page-oriented selection; U2 renders sidebar/detail layout. |
| BR-REQ-002 | covered_by_step | U1, U2 | U1 models App and Context pages; U2 renders the grouped sidebar. |
| BR-REQ-003 | covered_by_step | U1, U2 | U1 defines the App page choices; U2 renders each detail page. |
| BR-REQ-004 | covered_by_step | U1, U2 | U1 preserves context selection behavior; U2 keeps the watchlist detail page. |
| BR-REQ-005 | covered_by_step | U2 | U2 moves AI controls to the dedicated page. |
| BR-REQ-006 | covered_by_step | U2 | U2 structures the AI detail page groups. |
| BR-REQ-007 | covered_by_step | U2 | U2 adds AI page explanatory text without changing behavior. |
| BR-REQ-008 | covered_by_step | U2 | U2 owns ScrollView/detail/footer layout behavior. |
| BR-REQ-009 | covered_by_step | U2 | U2 owns form row width and detail layout bounds. |
| BR-REQ-010 | covered_by_step | U1, U2 | U1 state tests and U2 focused tests/quality gate guard behavior. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | This refactor only reorganizes Settings UI. |
| BR-OUT-002 | out_of_scope | Scope Boundaries | Provider/API feature scope remains unchanged. |
| BR-OUT-003 | out_of_scope | Scope Boundaries | Settings layout must not alter Kubernetes reads or writes. |
| BR-OUT-004 | out_of_scope | Scope Boundaries | The design tier is Standard and uses inherited native styling. |
| BR-DEC-001 | covered_by_step | U1, U2 | App-level page modeling and UI placement enforce this decision. |
| BR-DEC-002 | covered_by_step | U2 | The `Test Connection` action remains inside the AI detail page. |
| BR-DEC-003 | captured_as_decision | Decisions | U2 may adjust `SettingsWindowLayout.width` if the current width is cramped. |

## Research

- `CONTEXT.md` currently defines `App Settings tab` and `Context Settings tab`, which reflects the existing tab-based implementation and must be updated when the layout becomes page/sidebar-based.
- `SetupFlowState` owns Settings selection and currently exposes one `.appSettings` tab plus one tab per context.
- `MenuRuntimeState` owns Settings preparation, completed config generation, unsaved-change detection, and selection callbacks.
- `SetupView` currently renders a `TabView` and one long `appSettingsContent` stack with General, Kubeconfig, Launch, Alerts, and AI sections.
- `SettingsRootView` owns the fixed Settings window frame and passes callbacks into `SetupView`.
- `SettingsWindowLayout` is currently `640 x 560`; a sidebar/detail layout may need a wider width to avoid cramped controls.
- There is no root `DESIGN.md`; visual decisions should stay source-neutral and native-system inherited.
- The previous AI settings work already added provider config, Keychain credential storage, and manual Test Connection behavior. This plan must preserve that behavior rather than reopen the AI feature scope.
- Planner research dispatch was not needed because this is a single-domain Settings layout refactor with known files and verification paths.

## Decisions

- Use page-oriented Settings selection rather than continuing the `SettingsTabSelection` mental model.
- Keep App-level pages in a stable order: `General`, `Kubernetes`, `Notifications`, `AI Assistant`.
- Keep Context pages generated from local context names and preserve the existing selected-context/watchlist behavior.
- Keep the Settings footer as the global save area.
- Keep local actions inside their page: `Add Files` in `Kubernetes`, `Test Connection` in `AI Assistant`.
- Use native SwiftUI styling, inherited system colors, and the existing form-row pattern with better grouping.
- Allow a wider Settings window if 640pt cannot fit sidebar plus detail content cleanly.
- Prefer a mechanical state/UI refactor over introducing a custom design system.

## Assumptions

- macOS 14 support allows use of modern SwiftUI layout primitives, but a simple custom `HStack` sidebar/detail layout is acceptable if it better preserves existing callbacks.
- There are no automated SwiftUI snapshot tests, so visible Settings smoke remains HITL evidence for layout quality.
- Existing unit tests can be adapted to page-oriented Settings selection without changing AppConfig persistence semantics.
- The existing save button title and enabled/disabled rules remain based on configuration completeness.

## Devil's Advocate Audit

### Rollback resilience

The plan separates state navigation modeling from the visual sidebar/detail implementation. If U1 fails, revert Core selection model/test changes before touching UI layout. If U2 fails, revert `SetupView`/`SettingsRootView` layout changes while retaining any valid page-selection model only if tests prove it remains useful. No step changes Kubernetes access, Keychain access, provider HTTP behavior, or persisted config schema.

### Verification vanity

A sidebar label existing is not enough. U1 tests must fail if context watchlist selection or completed config behavior changes. U2 verification must include focused Settings tests, full build/quality gate, and HITL smoke that confirms actual layout hierarchy, conditional Base URL behavior, local Test Connection placement, and footer stability.

### Spec dilution detection

The plan covers the user's core complaint: Settings should stop feeling like a simple stack. It does not silently narrow the task to AI-only polish; it restructures the whole Settings surface enough to separate App pages and Context pages while keeping AI as one clear App-level page. It intentionally excludes rich visual theming and new AI behavior because the request is layout hierarchy, not feature expansion.

## Scope Boundaries

- In scope: Settings navigation model, sidebar/detail layout, App page grouping, AI page grouping/copy, field width/scroll/footer layout, Settings vocabulary docs, and focused tests.
- Out of scope: provider behavior changes, Keychain behavior changes, Kubernetes behavior changes, health-category behavior, menu dropdown redesign, new AI diagnostic execution, custom visual theme, and snapshot-test infrastructure.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Settings state exposes page-oriented navigation while preserving completed configuration behavior.
- Verification: swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && rtk git diff --check
- Depends on: None
- Test scenarios: App pages are available in stable order; context pages are generated from available contexts; selecting an App page preserves current watchlist edits; selecting a Context page loads that context's watchlist; completed config is unchanged by page navigation; `CONTEXT.md` Settings vocabulary matches page/sidebar navigation
- Discovery cache: KubebarCore/Models/SetupFlowState.swift (Settings selection model); KubebarCore/Models/MenuRuntimeState.swift (prepare/save/selection state); KubebarTests/Models/SetupFlowStateTests.swift (Settings state tests); KubebarTests/Models/MenuRuntimeStateTests.swift (runtime state tests); CONTEXT.md (canonical Settings vocabulary)

**Goal:** Replace tab-centric Settings state vocabulary with page-oriented App/Context selection while preserving existing save semantics.

**Verification type:** automated

**Execution note:** characterization-first

**failure_behavior:** If state tests show completed config, context selection, or watchlist preservation regresses, stop before changing UI layout.

### Step 2

- Step ID: U2
- Result: Settings renders a sidebar/detail layout with `AI Assistant` as a focused App page.
- Verification: swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && swift test --filter AIDiagnosticAssistant && swift build && /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: 1
- Test scenarios: sidebar shows App group and Context pages; `General` renders refresh cadence and Start at Login; `Kubernetes` renders kubeconfig source/files and Add Files action; `Notifications` renders Health State Shift Alerts; `AI Assistant` renders Provider/Endpoint/Credentials/Connection groups; Base URL appears only for `OpenAI-compatible`; Test Connection stays manual and local to AI page; footer save action remains visible; visible Settings smoke confirms hierarchy and spacing
- Discovery cache: Kubebar/Views/SetupView.swift (Settings layout); Kubebar/Views/SettingsRootView.swift (window frame and callbacks); Kubebar/MenuBarViewModel.swift (Settings callbacks and save/test behavior); KubebarCore/Models/AIDiagnosticAssistantState.swift (AI UI state); KubebarCore/Services/AIProviderConnectionTester.swift (manual Test Connection behavior); docs/architecture/runtime-invariants.md (AI and Settings runtime constraints)

**Goal:** Implement the confirmed layout contract in SwiftUI without changing Settings behavior.

**Verification type:** automated + hitl

**Execution note:** characterization-first

**failure_behavior:** If the layout builds but smoke shows cramped or unclear hierarchy, adjust layout bounds/spacing inside U2 rather than adding new behavior.

**security_considerations:** The AI page must keep Keychain/no-Kubernetes-data messaging and must not add raw key display, raw provider error display, automatic diagnosis, or any Kubernetes data submission path.
