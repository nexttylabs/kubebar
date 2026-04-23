---
title: fix: Size menu dynamically for short content
type: fix
status: completed
date: 2026-04-23
origin: docs/brainstorms/2026-04-22-kubebar-menu-polish-freshness-requirements.md
---

# fix: Size menu dynamically for short content

## Overview

Keep clear spacing between short menu content and the footer without forcing the
whole menu to a fixed normal height. The previous footer/freshness work keeps
long content from pushing the footer away; this follow-up closes the opposite
case where short content can make the footer sit too close to the main content.

## Problem Frame

The origin requirements now include R13, which states that short menu content
must keep clear spacing before the footer while the menu height still follows
content. `MenuBarRootView` already keeps the footer outside selected tab
scrolling and caps the menu with `maxHeight`, but short content can still shrink
the main content area until the footer hugs it. The fix should give the main
content area a minimum height without changing cluster health behavior, footer
actions, or freshness semantics.

## Requirements Trace

- R13. When selected tab or setup content is short, the main content area keeps
  a minimum height so the footer has clear spacing below it, while the overall
  menu height remains content-driven.
- R1-R3. Footer remains visible and keeps latest checked, refresh, settings,
  and quit actions.
- R2. Long content still scrolls above the footer instead of moving actions out
  of reach.
- R4-R5. Tab bar alignment remains visually balanced.
- R6-R12. Refresh cadence placement and freshness behavior remain unchanged
  from the completed footer/freshness work.

## Scope Boundaries

- No redesign of tab content, warning rows, setup copy, or footer actions.
- No change to `OK`, `Watch`, `Bad`, and `Stale` menu-bar states.
- No change to refresh cadence, stale-data meaning, or Kubernetes read behavior.
- No new automated SwiftUI snapshot harness in this task.
- No reopening of the completed R1-R12 implementation except for regression
  protection needed by this layout fix.

### Deferred to Separate Tasks

- Any broader menu redesign or new visual theme belongs in a separate
  requirements pass.

## Context & Research

### Relevant Code and Patterns

- `Kubebar/Views/MenuBarRootView.swift` owns the menu width, max height, selected
  tab content measurement, scroll container, divider, and `MenuFooterView`
  placement.
- `MenuBarRootView` currently applies `.frame(maxHeight: menuMaxHeight,
  alignment: .topLeading)`, which caps tall content but does not give short
  content a minimum main-content area.
- `Kubebar/Views/ConfigurationRequiredView.swift` is the short setup-required
  menu content used by first-use and empty-watchlist QA states.
- `KubebarCore/Services/FreshnessDisplaySchedule.swift` currently also exposes
  `ScreenVisibleHeightUpdate`, which shows the project already keeps small
  menu-related sizing helpers testable in `KubebarCore`.
- `KubebarTests/Services/RefreshGateTests.swift` currently houses the small
  `MenuBarRootViewTests` suite for visible-height helper behavior, but new menu
  layout sizing should get a clearer dedicated test file.
- `KubebarCore/QA/MenuStateFixtureCatalog.swift`,
  `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`,
  `docs/qa/operator-verification.md`, and `scripts/generate-qa-evidence.sh`
  provide the existing QA fixture and evidence language for visible menu checks.
- `docs/architecture/runtime-invariants.md` already says long content must
  scroll above the footer and the footer must stay visible.

### Institutional Learnings

- No `docs/solutions/` directory exists, so there are no recorded institutional
  learnings for this layout issue.

### External References

- Not used. The work follows existing SwiftUI layout structure and local QA
  conventions.

## Key Technical Decisions

- **Use a minimum main-content height:** Short content should get enough
  vertical room before the footer, while the menu still shrinks and grows with
  content.
- **Keep the footer outside scrollable content:** Preserve the current structure
  where main content, divider, and footer are siblings, and make the main
  content area absorb extra height above the footer.
- **Keep height math testable without SwiftUI view tests:** Put reusable menu
  layout sizing in a dedicated `KubebarCore` helper so package tests can cover
  the numeric boundary behavior without adding a SwiftUI snapshot harness.
- **Use QA fixtures for visible proof:** Automated tests can cover helper math
  and fixture wording, while final footer placement still needs visible app
  verification.

## Open Questions

### Resolved During Planning

- **Should this update the completed footer/freshness plan in place?** No.
  That plan is marked completed, so this follow-up gets a new active plan and
  references the same origin requirements.
- **Is external research needed?** No. The relevant behavior is local SwiftUI
  layout inside an existing app-specific structure.

### Deferred to Implementation

- **Exact minimum main-content height:** Choose the final value while viewing
  the current menu so short states have breathing room without becoming
  oversized on small screens.
- **Whether `ScreenVisibleHeightUpdate` should move into the new helper file:**
  Decide while editing. Prefer a small cohesive file, but avoid unrelated churn
  if moving the existing helper adds no value.

## Implementation Units

- [x] **Unit 1: Define bounded dynamic height behavior**

**Goal:** Keep the menu content-driven while preserving the visible-screen cap.

**Requirements:** R13, R1-R3

**Dependencies:** None

**Files:**
- Create: `KubebarCore/Services/MenuLayoutSizing.swift`
- Test: `KubebarTests/Services/MenuLayoutSizingTests.swift`

**Approach:**
- Add a small layout helper that derives the safe maximum menu height from the
  visible screen height.
- Keep selected-tab scroll height bounded by the safe maximum and a preferred
  content cap so long tabs scroll above the footer.
- Preserve the existing visible-height update helper behavior.

**Patterns to follow:**
- Existing `ScreenVisibleHeightUpdate` boundary style and tests.
- Existing `MenuBarRootView.Layout` constants for menu height budgets.

**Test scenarios:**
- Happy path: a normal visible screen returns the safe maximum menu height.
- Edge case: a short visible screen returns a height no larger than the safe
  visible menu maximum.
- Edge case: a tiny or invalid visible height still returns at least the
  minimum usable menu height.
- Regression: existing visible-height update tests continue to pass if any
  shared helper code is moved.

**Verification:**
- The height helper gives implementation code one clear maximum height for
  dynamic menu sizing.

- [x] **Unit 2: Anchor footer in the menu root**

**Goal:** Give the main content area a minimum height so short content leaves
clear spacing before the footer.

**Requirements:** R13, R1-R5

**Dependencies:** Unit 1

**Files:**
- Modify: `Kubebar/Views/MenuBarRootView.swift`

**Approach:**
- Remove the fixed normal menu height and keep only the existing
  maximum-height cap.
- Give `mainContent` a minimum height so the divider and `MenuFooterView` do
  not hug short content.
- Keep selected tab overflow behavior unchanged: only tall selected tab content
  should scroll above the divider/footer.
- Keep the setup-required state using the same bottom-footer behavior as normal
  tabs.
- Avoid moving cluster-health, freshness, or footer-action logic into views.

**Patterns to follow:**
- Existing `VStack` structure in `MenuBarRootView`.
- Existing selected-tab measurement and scroll-container pattern.
- Existing `ConfigurationRequiredView` setup-required path.

**Test scenarios:**
- Test expectation: none -- this unit is SwiftUI layout in the app target and
  the current test suite does not include a SwiftUI snapshot or view-inspection
  harness. Numeric sizing behavior is covered in Unit 1, and visible behavior
  is covered in Unit 3.

**Verification:**
- Short setup states and short tabs keep clear spacing before the footer
  without forcing a tall menu.
- Long Events, Pods, Nodes, or Overview content still scrolls above the footer.
- The tab picker remains horizontally balanced.

- [x] **Unit 3: Update QA wording and visible checks**

**Goal:** Make the new short-content footer contract visible in QA docs and
fixture metadata.

**Requirements:** R13, R1-R5

**Dependencies:** Unit 2

**Files:**
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `docs/qa/operator-verification.md`
- Modify: `scripts/generate-qa-evidence.sh`
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`

**Approach:**
- Update runtime invariants to cover both long-content overflow and
  short-content footer spacing.
- Update operator verification to check first-use or empty-watchlist as the
  short-content proof case.
- Update generated QA evidence text so short-content evidence is not lost when
  evidence docs are regenerated.
- Strengthen fixture metadata tests to require wording that covers short setup
  content keeping clear footer spacing without a fixed tall menu.

**Patterns to follow:**
- Existing `warning-heavy` wording and tests for long-content footer behavior.
- Existing first-use and empty-watchlist fixture tests.
- Existing generated UAT evidence table format.

**Test scenarios:**
- Happy path: first-use or empty-watchlist fixture expected behavior mentions
  that short setup content keeps clear spacing before the footer.
- Happy path: warning-heavy fixture still mentions long-content overflow and
  visible footer behavior.
- Regression: fixture copy still keeps refresh cadence out of the menu footer.
- Regression: generated QA evidence includes the short-content footer check.

**Verification:**
- QA guidance covers both footer extremes: too much content and too little
  content.
- Fixture tests protect the expected visible behavior language.

## System-Wide Impact

- **Interaction graph:** Menu rendering remains display-model driven. Only menu
  shell layout and QA wording change.
- **Error propagation:** No change. Refresh failures and stale reasons keep the
  existing behavior.
- **State lifecycle risks:** The layout must react to visible screen height
  changes without causing footer jumps during tab switching.
- **API surface parity:** No user-facing controls, settings, or shortcuts are
  added or removed.
- **Integration coverage:** Core helper tests cover sizing math; visible app QA
  covers the actual menu placement.
- **Unchanged invariants:** Health categories, freshness timing, Settings-only
  cadence, and Kubernetes read boundaries remain unchanged.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Menu feels too tall for setup-required states | Use a main-content minimum instead of a fixed menu height and verify first-use/empty-watchlist visually. |
| Small displays clip the menu | Keep sizing derived from visible screen height and existing edge inset. |
| Long-content scroll behavior regresses | Preserve selected tab scroll container and verify `warning-heavy`. |
| Layout-only fix lacks automated visual proof | Cover sizing math in unit tests and require visible QA evidence for first-use/empty-watchlist and warning-heavy. |

## Documentation / Operational Notes

- Update runtime invariants and operator verification because footer anchoring is
  now a product contract.
- No migration, rollout flag, or external operational work is needed.

## Sources & References

- **Origin document:** `docs/brainstorms/2026-04-22-kubebar-menu-polish-freshness-requirements.md`
- Related completed plan: `docs/plans/2026-04-22-006-fix-menu-footer-freshness-plan.md`
- Related code: `Kubebar/Views/MenuBarRootView.swift`
- Related code: `Kubebar/Views/MenuFooterView.swift`
- Related code: `KubebarCore/Services/FreshnessDisplaySchedule.swift`
- Related planned code: `KubebarCore/Services/MenuLayoutSizing.swift`
- Related QA: `docs/qa/operator-verification.md`
- Related planned tests: `KubebarTests/Services/MenuLayoutSizingTests.swift`
- Related tests: `KubebarTests/Services/RefreshGateTests.swift`
- Related tests: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
