# 03-04 Summary: Menu Bar Window Visibility

## Completed

- Fixed the menu bar app startup path that could leave Kubebar visible only as
  an icon with no setup or menu window.
- Removed the redundant runtime activation-policy override from
  `Kubebar/KubebarApp.swift`.
- Kept the existing `LSUIElement` app setting in `project.yml`.
- Fixed the setup window height so first-use setup no longer opens as a thin
  horizontal strip.

## Verification

- `./scripts/swift-quality-gate.sh local` passed.
- `git diff --check` passed.
- The rebuilt app launched from the worktree build output.

## UAT Status

The code fixes are complete. Final confirmation still needs a manual menu bar
click because automated desktop access was blocked by macOS assistive-access
permissions.
