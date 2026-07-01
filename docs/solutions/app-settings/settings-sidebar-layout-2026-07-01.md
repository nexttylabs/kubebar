---
module: app-settings
tags:
  - macos
  - settings
  - sidebar
  - navigation
  - page-oriented
  - refactor
problem_type: settings-layout
reusability: medium
key_files:
  - KubebarCore/Models/SetupFlowState.swift
  - KubebarCore/Models/MenuRuntimeState.swift
  - Kubebar/Views/SetupView.swift
  - Kubebar/Views/SettingsRootView.swift
  - KubebarTests/Models/SetupFlowStateTests.swift
next_reuse_scenarios:
  - Adding a new App-level Settings page to the sidebar.
  - Refactoring a single-page settings form into grouped navigation.
  - Expanding an enum-based selection model without breaking callers.
---

# Settings Sidebar Layout Refactor

## Problem

App Settings was a single long `TabView` page with General, Kubeconfig, Launch,
Alerts, and AI Diagnostic Assistant sections stacked vertically. Unrelated
concerns had equal visual weight, and AI configuration was appended at the
bottom without its own information hierarchy. This created a "simple stack of
controls" feel.

## Solution

Split the Settings surface into a **sidebar/detail layout**:

- Left sidebar: `List(selection:)` with `.sidebar` style, grouped into `App`
  and `Contexts` sections.
- Right detail: `ScrollView` rendering the selected page's content.
- Footer: global Save action, always visible at the bottom.

App pages are stable in order: `General`, `Kubernetes`, `Notifications`,
`AI Assistant`. Context pages are generated from local context names.

### Enum expansion without breaking callers

The core insight: `SettingsTabSelection` was expanded from
`.appSettings | .context(String)` to four App pages plus `.context(String)`,
while keeping a backward-compatible `static var appSettings` that returns
`.general`. This let existing call sites (`selectAppSettingsTab()`, test
assertions, `SettingsTabID.appSettings`) continue compiling without a
sweeping rename, while the new page model was available immediately.

### Navigation reset bug

When wiring the new `onSelectAppPage` callback, the initial implementation
called `onSelectAppSettings()` (which maps to `viewModel.selectAppSettingsTab()`
→ `runtimeState.selectAppSettingsTab()` → `selectAppPage(.general)`). This
silently reset any App page selection back to `.general`, making it impossible
to navigate to Kubernetes/Notifications/AI Assistant.

Fix: add a dedicated `selectAppPage(_:)` callback chain
(`SetupView` → `SettingsRootView` → `MenuBarViewModel.selectAppPage(_:)` →
`MenuRuntimeState.selectAppPage(_:)`) that preserves the selected page instead
of forcing `.general`.

## Evidence

- 318 tests pass across 31 suites including 6 new tests for App page
  navigation behavior.
- `swift build` and `swift-quality-gate.sh local` both pass.
- `rtk git diff --check` clean.
- App launches cleanly via `compile-and-run.sh`.

## UI Polish Applied After Initial Implementation

- Replaced invalid `k.stack` SF Symbol with `square.3.layers.3d`.
- Added keyboard shortcuts (`Cmd+1`..`Cmd+4`) for App pages.
- Merged AI Assistant sections into "Provider configuration" and
  "Connection"; Base URL is hidden unless the provider is
  `OpenAI-compatible`.
- App pages now show their own descriptive subtitles instead of the active
  Kubernetes context.
- Removed unnecessary `maxHeight: .infinity` from the detail content pane
  now that it scrolls.
- Widened `SettingsRow` content area from 280pt to 360pt for long paths and
  keys.
- Raised Settings window height from 560pt to 620pt.
- Added a warning icon next to contexts that have no watchlist selected.
- Unified App page and Context sidebar rows to a single `HStack` helper
  with a fixed 20pt icon width, identical spacing, and a trailing warning
  icon, so icons and text align consistently regardless of section.

## Reusability Critique

- **Falsifiability**: This pattern works for macOS SwiftUI Settings windows
  with a small number of grouped pages. It would not apply to iOS settings
  where `NavigationSplitView` or `Form` sections are idiomatic.
- **Evidence trail**: SetupFlowStateTests, MenuRuntimeStateTests, and the
  compile-and-run smoke test confirm the model and build are correct. Layout
  quality is HITL-verified (no automated SwiftUI snapshot tests exist).
- **Architecture entropy**: This appends to the `app-settings` hub without
  duplicating the per-context-watchlists pattern in `architecture/`.
