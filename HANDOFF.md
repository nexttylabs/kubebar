# Kubebar Handoff

## Current State

- Plan: `docs/plans/2026-06-03-001-feat-per-context-watchlists-context-selector-plan.md`
- Status: complete
- Completed steps:
  - U1 `App config supports compatible per-context watchlist storage.`
  - U2 `Settings edits separate watchlists through context tabs.`
  - U3 `The menu Quick Context Selector switches active context safely with the matching watchlist.`
- Latest review: code-review follow-ups fixed; menu layout reserves the
  top-level Context selector height, and runtime invariants now document
  per-context watchlists plus Quick Context Selector behavior.

## Verification

- `rtk swift test --filter 'AppConfigTests|MenuRuntimeStateTests|MenuBarRootViewTests'`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Passed with 240 tests in 28 suites after the layout follow-up.
- `rtk git diff --check`
  - Passed.

## Notes

- App config now stores `watchlistsByContext` and keeps legacy `watchTargets`
  decode compatibility by migrating the old list under `selectedContext`.
- `watchTargets` remains the active-context view of the config, so refreshes
  use only the selected context's watchlist.
- Settings now uses a segmented context control and preserves a separate
  namespace watchlist per context.
- The menu now shows a top-level `Context` selector. It lists saved and
  available contexts, marks the current context, truncates long names, and keeps
  full help/accessibility text.
- The selected tab height budget now includes the Context selector so long tab
  content stays capped within the visible menu height.
- Selecting a configured context saves Kubebar's app-owned context, clears old
  snapshot/freshness/handoff/alert state, rejects stale refresh results, restarts
  the refresh loop, and refreshes with that context's watchlist.
- Selecting a context without a watchlist saves that selected context and shows
  the configuration-required state.
- Refresh cadence, Start at Login, and Health State Shift Alerts remain global.
- The selector does not call `kubectl config use-context` or otherwise mutate
  the terminal/current kubeconfig context.
- `docs/architecture/runtime-invariants.md` now records the new per-context
  watchlist ownership, context-switch invalidation, and Settings tab rules.
- No known blockers.

## Compaction Handoff

- Active plan: `docs/plans/2026-06-03-001-feat-per-context-watchlists-context-selector-plan.md`
- Active step: none; U1, U2, and U3 are closed.
- Priority files:
  - `KubebarCore/Services/AppConfigStore.swift`
  - `KubebarCore/Models/SetupFlowState.swift`
  - `KubebarCore/Models/MenuRuntimeState.swift`
  - `Kubebar/MenuBarViewModel.swift`
  - `Kubebar/Views/SetupView.swift`
  - `Kubebar/Views/MenuBarRootView.swift`
  - `KubebarCore/Services/MenuLayoutSizing.swift`
  - `KubebarTests/Services/MenuLayoutSizingTests.swift`
  - `docs/architecture/runtime-invariants.md`
  - `Kubebar/KubebarApp.swift`
- Uncommitted work summary: per-context watchlist persistence, Settings
  context tabs, menu Quick Context Selector, menu layout budget follow-up,
  runtime invariants follow-up, tests, spec/plan/context docs, workflow state,
  skill registry support, and this handoff update.
- Session decisions: per-context watchlists are namespace-only for this task;
  cadence/start-at-login/alerts stay global; the menu changes only Kubebar's
  app-owned selected context and never the terminal current context.
- Verification note: a focused SwiftPM `MenuLayoutSizingTests` filter hung in
  `swiftpm-xctest-helper` and was killed; the full quality gate subsequently
  passed the same test suite.
- Next boundary skill: optional `imm-compounder` for reusable learning capture.
