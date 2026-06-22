---
title: Pod Log Focus Window
date: 2026-06-22
status: planned
origin: user reported Pod log popup loses focus and cannot support search/detail use
---

# Pod Log Focus Window

## Summary

The existing Pod Micro-Logs Drawer streams the right data, but its current
SwiftUI Sheet presentation from the `MenuBarExtra(.window)` menu surface can
lose focus. That makes the search field, log text selection, scrolling, and
detail inspection unreliable.

Kubebar should keep the same bounded log behavior and move the presentation
host to an independent focusable macOS window. The log UI should remain clean
and read-only, while search, copy, scrolling, and text interaction stay usable
after the menu loses focus.

## Goals

- Open Bad Pod logs in a focusable app-owned log window instead of a
  menu-attached SwiftUI Sheet.
- Preserve the existing `kubectl logs --tail=100 -f` stream behavior,
  app-owned context, effective kubeconfig, bounded buffer, search, and copy.
- Reuse the existing log drawer SwiftUI content where practical.
- Keep one active log target presentation driven by `MenuBarViewModel`.
- Closing the log window must call `closePodLogDrawer()` so the streaming
  process is cancelled.
- Opening logs for another Pod should update or replace the existing log
  window without leaving an orphaned stream.
- The log window should be brought forward and made key so text input and
  selection work immediately.
- Log output should use a native read-only macOS text surface so logs start at
  the top-left and keep expected selection, copy, vertical scrolling, and
  horizontal scrolling behavior.

## Non-Goals

- No redesign of the Pod Micro-Logs feature.
- No stored log history, multi-Pod aggregation, advanced search, or container
  picker.
- No change to Health category evaluation.
- No new persisted app settings.
- No Kubernetes API behavior change beyond the existing log stream.

## Requirements

- R1. Bad Pod row log buttons continue to call the existing ViewModel log-open
  path for a `PodLogTarget`.
- R2. `MenuBarRootView` must not attach the log UI through `.sheet` on the
  menu content.
- R3. A focusable AppKit-backed window or panel must host the log drawer
  content and become key/frontmost when opened.
- R4. The hosted log content must keep copy, search, scrolling, and text
  selection usable after the menu surface closes or loses focus.
- R5. The window close path must call `closePodLogDrawer()` exactly as the
  Sheet close path did, so `kubectl logs -f` is cancelled.
- R6. The window must reflect updates to the current `PodLogDrawerPresentation`
  and search binding without needing to reopen the app menu.
- R7. Log data remains in-memory only and must not feed health evaluation,
  alerts, persistence, telemetry, or command transcript display.
- R8. Existing runtime invariants for app-owned context, effective kubeconfig,
  bounded log buffers, and read-only troubleshooting behavior remain intact.
- R9. The log output body must not be rebuilt from primitive `ScrollView` plus
  `Text` when a native AppKit text view can provide the expected log viewer
  behavior with less custom layout.
- R10. Empty, short, and long log output must render from the top-left of the
  text area rather than appearing vertically centered.

## Verification Expectations

- Focused tests should cover any newly extracted presenter/state logic where
  it can be tested without AppKit UI automation.
- Build verification must prove the SwiftUI/AppKit bridge compiles.
- The full Swift quality gate remains required.
- Because focus behavior is macOS-window behavior, the implementation should
  include a manual or HITL smoke check: open logs from a Bad Pod row, type in
  search, select/copy log text, scroll, close the window, and confirm the stream
  stops.
- Log body verification should include short output that would previously
  expose vertical centering, plus enough long output to confirm horizontal and
  vertical scrolling remain usable.
