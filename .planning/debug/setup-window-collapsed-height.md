# Setup Window Collapsed Height

## Symptom

After the menu bar icon started opening a surface, the user reported that the
visible interface was only a very thin horizontal strip.

## Evidence

- `MenuBarRootView` wrapped first-use setup in `SetupView(...).frame(width: 560)`.
- `SetupView` uses a `ScrollView` as its root view.
- A `ScrollView` inside a window-style `MenuBarExtra` needs an explicit height
  from the parent. Width alone can leave the menu window with a collapsed
  vertical size.

## Root Cause

The setup branch had a fixed width but no height. The menu bar window could
therefore resolve the root scroll view to a near-zero height, producing the
thin horizontal strip reported during UAT.

## Fix

`MenuBarRootView` now gives setup a stable `560 x 560` frame. The setup content
still uses `ScrollView`, so larger context and workload lists remain scrollable.

## Verification

- `./scripts/swift-quality-gate.sh local` passed.
- `git diff --check` passed.
- The rebuilt app launched from
  `DerivedData/Build/Products/Debug/Kubebar.app`.

## Remaining Manual Check

The final check needs a user click on the Kubebar menu bar icon:

1. Confirm the window is no longer a thin strip.
2. Confirm setup content is visible and usable.
3. Continue Phase 03 UAT from the first-use setup test.
