# Plan: macOS UI Pattern Polish

## Summary

Make Kubebar's menu footer and Settings scene more native to macOS while
preserving the existing menu-bar utility workflow and runtime invariants.

## Devil's Advocate Audit

- Risk: A broad visual redesign could break the compact menu-bar surface.
  Mitigation: keep changes scoped to layout/control structure in existing
  views.
- Risk: Native `TabView` could regress context tab selection.
  Mitigation: keep stable `SettingsTabID` selection and rerun the 2-context
  smoke.
- Risk: Liquid Glass APIs may not compile on macOS 14.
  Mitigation: use standard controls, adaptive materials, and `GroupBox` instead
  of macOS 26-only custom glass APIs.

## Steps

### U1: Settings uses native preference tabs and sections

Result: Settings presents `App Settings` as the fixed first native tab, dynamic
context tabs after it, and preference-style sections for global and context
settings.

Verification: `swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && rtk git diff --check` plus Settings accessibility smoke with `dev` and `prod`.

### U2: Menu footer uses compact native toolbar grouping

Result: The menu footer keeps last-checked text and the nested quick context
selector, while refresh/settings/quit actions read as a compact native macOS
tool group.

Verification: `swift test --filter MenuLayoutSizingTests && rtk git diff --check` plus menu accessibility smoke that footer controls remain reachable.
