---
module: architecture
tags:
  - kubebar
  - macos
  - menu-bar
  - pod-logs
  - appkit
problem_type: focusable-troubleshooting-window
reusability: medium
key_files:
  - Kubebar/KubebarApp.swift
  - Kubebar/MenuBarViewModel.swift
  - Kubebar/Views/PodLogWindowPresenter.swift
  - Kubebar/Views/ReadOnlyLogTextView.swift
  - Kubebar/Views/MenuBarRootView.swift
  - KubebarCore/Services/PodLogStreamer.swift
  - docs/architecture/runtime-invariants.md
next_reuse_scenarios:
  - Adding another menu-launched troubleshooting surface that must remain interactive after the menu closes.
  - Replacing SwiftUI menu-attached presentation when focus, text selection, or search input must survive live updates.
  - Reviewing native macOS text output surfaces for bounded, read-only command output.
---

# Menu-Launched Logs Need a Focusable App-Owned Window

## Problem

Kubebar's Pod Micro-Logs Drawer first used a SwiftUI Sheet attached to the
`MenuBarExtra(.window)` menu surface. That presentation streamed the right log
data, but it could lose focus once launched from the menu. The result was a
debugging surface where search, text selection, and detail inspection were not
reliable enough for the feature's purpose.

The log body also started as a SwiftUI `ScrollView` plus `Text`, which meant
Kubebar was rebuilding behavior that native macOS text controls already
provide: top-left text layout, selection, copy, and two-axis scrolling.

## Solution

For menu-launched troubleshooting UI that must remain interactive, host the
surface in an app-owned focusable window and keep the data lifecycle in the
ViewModel.

- `MenuBarViewModel` owns the active Pod log target, stream session, bounded
  in-memory buffer, copy action, and close-to-cancel behavior.
- `PodLogWindowPresenter` owns only window presentation: create or reuse an
  `NSWindow`, host the existing SwiftUI drawer content, bring the window key
  and front only when the target changes or the window is first opened, and
  route user close events back to `closePodLogDrawer()`.
- Same-target log buffer updates should not recreate the hosting controller or
  refocus the window. Let the observed ViewModel refresh the hosted SwiftUI
  content naturally.
- Use a narrow AppKit `NSTextView` inside `NSScrollView` for read-only log
  output. Preserve selection and scroll position across live text updates, and
  only tail-follow when the user was already near the bottom and has no active
  text selection.
- Keep the log feature bounded: no persistence, no telemetry, no Secret reads,
  no health-category input, and no stored command transcript.

## Evidence

- The active repair plan closed after automated verification and HITL smoke.
- `swift test --filter PodLogStream` passed with 9 tests.
- `swift test --filter MenuDisplayModelTests` passed with 72 tests.
- `./scripts/swift-quality-gate.sh local` passed with 278 tests in 29 suites.
- `rtk git diff --check` passed.
- `./scripts/compile-and-run.sh` built, signed, and launched the visible app.
- HITL smoke confirmed the Bad Pod log window stayed focusable, short output
  started top-left, search accepted typing, log text could be selected/copied,
  vertical and horizontal scrolling stayed usable during live updates, and
  closing the window stopped the stream.

## Reuse Notes

Use this pattern when a menu-triggered macOS tool surface needs sustained
keyboard and text interaction after the menu disappears. Keep ownership split:
the ViewModel owns target state and side effects, while the AppKit presenter
owns focus and window lifecycle. Prefer native text components for log-like
output before building custom SwiftUI text scrollers.

Do not generalize this into "all menu popups need separate windows." Small
ephemeral confirmations can stay in the menu or use SwiftUI presentation. The
window pattern is justified when focus, selection, search, and live updates are
core to the user workflow.

## Rejected Alternative

Keeping the log drawer as a menu-attached SwiftUI Sheet was rejected for this
workflow. It was simpler, but the menu window was the wrong focus host for a
long-lived troubleshooting surface that needs search, selectable text, and
scrolling after the menu loses focus.

## Reusability Critique

- Falsifiability: this lesson is too local if future Kubebar versions replace
  `MenuBarExtra(.window)` with a different app shell, or if a future macOS
  SwiftUI presentation reliably preserves focus for this exact interaction.
- Evidence trail: the guidance is supported by focused log-stream tests, menu
  display tests, full quality gate, visible app launch, code review, and a
  user-confirmed HITL smoke. It is not supported by automated UI tests.
- Architecture entropy resistance: this belongs in `docs/solutions/architecture`
  because it captures an ownership and presentation boundary. It should not be
  promoted into a broad rule that every secondary UI must use AppKit.
