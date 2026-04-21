# Menu Bar Window Not Opening

## Symptom

The user reported that Kubebar only showed the menu bar icon. Clicking the
icon did not show setup or any menu content.

## Evidence

- `ps aux` showed a running `Kubebar` process, so the app was not failing to
  launch.
- `project.yml` already declares `INFOPLIST_KEY_LSUIElement: YES`, so the app
  is already configured as a menu bar app.
- `Kubebar/KubebarApp.swift` also called
  `NSApplication.shared.setActivationPolicy(.accessory)` during app startup.

## Root Cause

Kubebar had two separate mechanisms trying to place the app in menu-bar-only
mode: the app plist declaration and a runtime activation-policy override. The
plist declaration is enough for a SwiftUI `MenuBarExtra` app. The extra runtime
override can interfere with the window-style menu bar surface and left the app
visible only as an icon.

## Fix

Removed the runtime activation-policy override and the now-unused `AppKit`
import from `Kubebar/KubebarApp.swift`. Kubebar now relies on the plist
`LSUIElement` setting as the single source of truth for menu bar behavior.

## Verification

- `./scripts/swift-quality-gate.sh local` passed.
- `git diff --check` passed.
- The fixed app launched from
  `DerivedData/Build/Products/Debug/Kubebar.app` and appeared as a running
  `Kubebar` process.

## Remaining Manual Check

macOS denied automated assistive access for clicking the menu bar item through
`osascript`, so the final check still needs a user click:

1. Click the Kubebar menu bar icon.
2. Confirm setup or the main Kubebar window appears.
3. Continue the Phase 03 UAT tests.
