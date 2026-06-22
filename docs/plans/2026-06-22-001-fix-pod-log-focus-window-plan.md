---
title: "fix: keep Pod logs focusable"
type: fix
status: planned
date: 2026-06-22
origin: .imm/specs/2026-06-22-pod-log-focus-window.md
---

# fix: keep Pod logs focusable

## Summary

- Summary: Replace the menu-attached Pod log Sheet with a focusable app-owned
  log window and native read-only log text view so search, copy, scrolling, and
  text selection stay usable.

This is a small repair slice for the already implemented Pod Micro-Logs
Drawer. The data path and product scope stay unchanged; only the presentation
host changes because the current Sheet can lose focus when launched from the
menu bar window.

## Current Slice

- Roadmap source: none
- Execution scope: Pod Micro-Logs presentation host, window lifecycle, focus
  behavior, native read-only log text view, ViewModel close/cancellation
  wiring, and focused verification
- Deferred phases: container picker, previous-container logs, saved history,
  richer search, and full log console behavior remain outside this plan
- This is not a redesign of Pod Micro-Logs.

## Task

- Type: fix
- Scope: menu log presentation, macOS window focus, tests/docs
- Owner: imm-work
- Verification: focused build/tests, full Swift quality gate, and HITL focus
  smoke

## Output Language

User-facing assistant replies remain Chinese per current conversation
preference. Project planning documents remain English by default to match this
repository's durable documentation convention. Code identifiers, commands,
schema fields, paths, `Step`, `Plan`, `Spec`, and `Verification` remain literal.

## Origin

The user reported that the current Pod log popup loses focus, making log
search and log-detail viewing unusable. The preceding implementation used a
SwiftUI `.sheet` attached to `MenuBarRootView`, which is a weak focus host
inside `MenuBarExtra(.window)`. The user confirmed the direction to fix this
with an independent focusable log window.

## Research

- `CONTEXT.md` now defines `Pod Micro-Logs Drawer` as a user-opened focusable
  log window rather than a menu-attached Sheet.
- `.imm/memory/current_iteration.json` shows the original Pod Micro-Logs plan
  is closed, so this must be a new repair plan rather than an append.
- `Kubebar/Views/MenuBarRootView.swift` currently attaches the log UI through
  `.sheet(isPresented:)` and hosts `PodLogDrawerView` from the menu root.
- `Kubebar/Views/MenuBarRootView.swift` currently renders the log body with
  `ScrollView([.vertical, .horizontal])` plus `Text`, which can vertically
  center short log output and recreates behavior that AppKit text components
  already provide.
- `Kubebar/KubebarApp.swift` owns the `MenuBarExtra(.window)` scene and passes
  log drawer state/actions into `MenuBarRootView`.
- `Kubebar/MenuBarViewModel.swift` owns `podLogDrawer`, `podLogSearchQuery`,
  `openPodLogDrawer(for:)`, `copyPodLogs()`, and `closePodLogDrawer()`.
- `Kubebar/Views/SettingsRootView.swift` already demonstrates the local window
  focus pattern through `SettingsWindowPresenter` and
  `SettingsWindowFocusBridge`, including `NSApplication.shared.activate`,
  `orderFrontRegardless()`, and `makeKeyAndOrderFront(nil)`.
- `KubebarCore/Services/PodLogStreamer.swift` owns the cancellable stream and
  should not need redesign for this focus fix.
- `docs/architecture/runtime-invariants.md` already states Pod logs are
  bounded, read-only, in-memory, and cancelled when closed or replaced.
- The repository has no existing reusable log or long-read-only-text component.
  `NSTextView` inside `NSScrollView`, wrapped narrowly with
  `NSViewRepresentable`, is the existing macOS component best suited for
  read-only log output because it supplies top-left text layout, selection,
  copy, and scrolling behavior without custom SwiftUI text-viewer logic.
- Planner subagent dispatch was not used: this is a small single-domain repair
  with enough local evidence.

## Decisions

- Use a new app-owned focusable log window/presenter instead of SwiftUI Sheet
  presentation from `MenuBarRootView`.
- Reuse the existing `PodLogDrawerView` content where practical so copy,
  search, status, and read-only log rendering do not drift.
- Keep `MenuBarViewModel` as the source of truth for log drawer state and
  stream lifecycle.
- Closing the window must flow through `closePodLogDrawer()` rather than only
  hiding AppKit chrome.
- Opening a new Pod log target may reuse the existing window, but the visible
  content must update to the current target and be brought to front.
- Use a thin SwiftUI wrapper around native AppKit text controls for the log
  body instead of extending the current `ScrollView` plus `Text` implementation.
- Keep search controls outside the native text view for this slice; search
  remains local to `PodLogBuffer` and `PodLogDrawerPresentation`.
- Do not broaden the feature into a persistent or multi-Pod log tool.

## Assumptions

- A standard `NSWindow` or narrowly scoped `NSPanel` hosted with SwiftUI content
  is acceptable for this app because Settings already uses AppKit focus bridge
  behavior.
- A HITL smoke check is the right evidence for real focus behavior because
  this repo does not currently have macOS UI automation around menu bar
  windows.
- Existing tests for stream construction, buffer bounds, copy text, and search
  behavior remain valid after changing only the presentation host.
- A read-only `NSTextView` wrapped in `NSScrollView` is acceptable here because
  Kubebar is a native macOS app and already uses AppKit bridges for window
  focus and environment-specific UI behavior.

## Devil's Advocate Audit

- Rollback resilience: The change can be rolled back by restoring the
  menu-attached Sheet and removing the new presenter/window bridge. Because the
  log stream and model contracts stay unchanged, partial failure should not
  require data migration or Kubernetes cleanup.
- Verification vanity: Build-only evidence would be too weak because the bugs
  are focus behavior and visible log body layout. The plan requires automated
  build/tests plus a HITL smoke that can fail if search typing, top-left short
  log layout, text selection, scrolling, or close cancellation do not work in
  the real app window.
- Spec dilution detection: The accepted requirement is not narrowed to merely
  opening a different visual shell. The plan preserves search, copy, scrolling,
  native read-only log viewing, top-left log layout, and close-triggered stream
  cancellation.

## Scope Boundaries

- In scope: replace Sheet host, focusable log window presenter, state updates,
  close-to-cancel lifecycle, native read-only log text view, copy/search/text
  interaction, focused tests, full quality gate, and HITL smoke evidence.
- Out of scope: log service redesign, Kubernetes command changes, persistence,
  health rules, alerting, multi-container UX, and advanced search.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Bad Pod logs remain interactive in a focusable native log window.
- Verification: swift test --filter PodLogStream && swift test --filter MenuDisplayModelTests && /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local && rtk git diff --check; HITL smoke: open a Bad Pod log window, confirm short log output starts at the top-left, type in search, select/copy log text, scroll vertically and horizontally, close the window, and verify the log stream stops
- Depends on: None
- Test scenarios: log action opens or updates a focusable app-owned window; short log output starts at the top-left instead of vertical center; search field accepts keyboard focus; native log text supports selection and vertical/horizontal scrolling; Copy uses current in-memory text; closing the window calls the ViewModel close path and cancels the stream; opening another Pod updates/replaces the window without orphaning the previous stream; no Sheet remains attached to the menu root; the log body is not implemented as primitive SwiftUI ScrollView plus Text

**Goal:** Repair the Pod Micro-Logs presentation so the existing troubleshooting
surface is actually interactive.

**Verification type:** hitl

**Execution note:** characterization-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10

**Dependencies:** None

**Discovery cache:**
- `Kubebar/Views/MenuBarRootView.swift` (current Sheet host, reusable `PodLogDrawerView`, and current ScrollView/Text log body)
- `Kubebar/KubebarApp.swift` (MenuBarExtra scene wiring and log state/actions)
- `Kubebar/MenuBarViewModel.swift` (log drawer source of truth and close cancellation)
- `Kubebar/Views/SettingsRootView.swift` (existing AppKit window focus pattern)
- `Kubebar/Views/PodsTabView.swift` (Bad Pod row log action entry point)
- `KubebarCore/Services/PodLogStreamer.swift` (stream cancellation contract)
- `docs/architecture/runtime-invariants.md` (Pod log lifecycle and product rules)

**Files:**
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Add/Modify: a small AppKit-backed read-only log text view under `Kubebar/Views/`
- Modify: `Kubebar/KubebarApp.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify/Add: focused tests if presenter/state logic is extracted
- Modify: `CONTEXT.md`
- Modify/Add: relevant docs only if runtime wording needs to change

**Approach:**
- Remove the `.sheet` presentation from `MenuBarRootView`.
- Introduce a focused Pod log window presenter that hosts the existing drawer
  SwiftUI content and brings its window key/frontmost when opened or updated.
- Bridge the presenter's close notification back to `closePodLogDrawer()`.
- Keep `podLogSearchQuery` as a binding into the hosted SwiftUI content so the
  existing local search behavior remains intact.
- Replace the log body with a thin native read-only text view wrapper around
  `NSTextView` in `NSScrollView`; configure it for monospaced read-only log
  output, top-left layout, selection, copy, and vertical/horizontal scrolling.
- Reuse the Settings window focus pattern where it fits, while keeping Pod log
  window ownership separate from Settings.
- Run focused tests/builds and complete a HITL smoke for the focus regression.

**failure_behavior:** If the window cannot reliably become key or cannot
deliver close events to the ViewModel, stop and replan before shipping another
non-interactive log presentation.

**security_considerations:** Logs may contain sensitive application data. The
fix must preserve the existing in-memory-only behavior, user-initiated copy,
no persistence, no telemetry, no Secret reads, and no command transcript
display.
