---
status: testing
phase: 03-complete-first-use-setup-and-watchlist-editing
source:
  - 03-01-SUMMARY.md
  - 03-02-SUMMARY.md
  - 03-03-SUMMARY.md
  - 03-04-SUMMARY.md
  - 03-05-SUMMARY.md
started: 2026-04-20T14:28:06Z
updated: 2026-04-21T10:43:25Z
---

## Current Test

number: 3
name: Edit watchlist updates saved choices
expected: |
  Click Edit watchlist from the menu, change the selected namespace/workload choices, finish setup again, and see the menu refresh using the updated watchlist.
awaiting: user response

## Tests

### 1. First-use setup loads real watch targets
expected: Open setup, choose a Kubernetes context, and see loading followed by namespace choices plus namespace-grouped workload choices.
result: issue
reported: "不能，看到cluster context和 watchlist"
severity: major

### 2. Finish setup saves selected watchlist and refreshes
expected: Select at least one namespace or workload. Finish setup becomes enabled. Clicking Finish setup closes setup and the menu refreshes using the saved context and selected watchlist.
result: blocked
blocked_by: other
reason: Computer Use could not access or operate the Kubebar menu bar extra.
evidence:
  - "./scripts/compile-and-run.sh completed successfully and launched DerivedData/Build/Products/Debug/Kubebar.app"
  - "Swift test run passed with 74 tests in 14 suites"
  - "Computer Use timed out reading Kubebar, com.nextty.kubebar, SystemUIServer, and com.apple.controlcenter"
  - "Computer Use could read Finder normally, so the blocker is the menu bar extra accessibility path"

### 3. Edit watchlist updates saved choices
expected: Click Edit watchlist from the menu, change the selected namespace/workload choices, finish setup again, and see the menu refresh using the updated watchlist.
result: [pending]

### 4. Loading failure or empty targets shows recovery copy
expected: If target loading fails or the context has no supported targets, the watchlist area shows a clear empty/failure message and a Retry button. Already selected targets remain selected instead of being erased.
result: [pending]

## Summary

total: 4
passed: 0
issues: 1
pending: 2
skipped: 0
blocked: 1

## Gaps

- truth: "Open setup, choose a Kubernetes context, and see loading followed by namespace choices plus namespace-grouped workload choices."
  status: fixed
  reason: "User reported: 没有看到setup"
  severity: major
  test: 1
  root_cause: "Kubebar declared LSUIElement in the generated app plist and also changed NSApplication activation policy at runtime. After that was fixed, setup still opened as a thin strip because the setup branch gave a ScrollView a fixed width but no height inside a window-style MenuBarExtra."
  fix: "Removed the runtime setActivationPolicy(.accessory) call and gave the setup view a stable 560 x 560 frame while keeping the setup content scrollable."
  artifacts:
    - "Kubebar/KubebarApp.swift"
    - "Kubebar/Views/MenuBarRootView.swift"
    - ".planning/debug/menu-bar-window-not-opening.md"
    - ".planning/debug/setup-window-collapsed-height.md"
    - ".planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-04-SUMMARY.md"
  verification:
    - "./scripts/swift-quality-gate.sh local passed"
    - "git diff --check passed"
    - "Fixed app launched from DerivedData/Build/Products/Debug/Kubebar.app"
    - "User confirmed the menu window now expands"
  missing:
    - "Continue the four Phase 03 UAT checkpoints now that the menu window opens."
  debug_session: ".planning/debug/menu-bar-window-not-opening.md"

- truth: "Open setup, choose a Kubernetes context, and see loading followed by namespace choices plus namespace-grouped workload choices."
  status: fixed_pending_confirmation
  reason: "User reported: 不能，看到cluster context和 watchlist"
  severity: major
  test: 1
  root_cause: "The first-use setup path set isShowingSetup during app startup but did not call loadContexts(). Context discovery only ran when setup was opened later from Edit watchlist."
  fix: "When config.needsSetup is true during startup, MenuBarViewModel now loads contexts immediately and loads watch targets if a selected context already exists."
  artifacts:
    - "Kubebar/MenuBarViewModel.swift"
    - ".planning/debug/first-use-contexts-not-loading.md"
    - ".planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-05-SUMMARY.md"
  verification:
    - "./scripts/swift-quality-gate.sh local passed"
    - "Local kubectl context discovery returned default"
    - "Fixed app launched from DerivedData/Build/Products/Debug/Kubebar.app"
  missing:
    - "User retest: first-use setup shows context options, then loads namespace and workload choices after selecting a context."
  debug_session: ".planning/debug/first-use-contexts-not-loading.md"

## Reverification

2026-04-21T01:23:49Z:
- GitHub issue #3 was re-read from `nexttylabs/kubebar`.
- The implementation still covers context-owned target discovery, saved watchlist completion, edit setup, empty/failure retry states, and the supported test areas.
- `./scripts/swift-quality-gate.sh local` passed with 35 tests.
- The previous window blocker is fixed and manually confirmed by the user.
