---
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
verified: 2026-04-21T16:36:54Z
status: human_needed
score: 6/6 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Opened menu state checks for OK, Watch, Bad, and Stale"
    expected: "The opened menu shows state text, a visible symbol, one short reason, and no color-only meaning for each state that can be exercised live."
    why_human: "The menu-bar extra could not be inspected reliably through automation; the UAT records Computer Use timeouts."
  - test: "Keyboard traversal through the visible menu"
    expected: "Full Keyboard Access can reach setup, Finish setup enabled and disabled, Retry now enabled and disabled, Edit watchlist, watchlist detail disclosures, warning events, secondary sections, and target-load retry."
    why_human: "Native SwiftUI controls and shortcuts exist in source, but actual macOS menu focus traversal requires visible-app testing."
  - test: "Long-name visual fallback checks"
    expected: "Long context, namespace, workload, warning summary, and setup picker names use middle truncation and expose full values through hover help or accessibility."
    why_human: "Source modifiers are present, but final visual truncation and assistive behavior depend on macOS rendering."
  - test: "Menu reading comfort and scope guard check"
    expected: "The first visible menu remains summary, stale signal, counters, watchlist, warning events, node details, refresh, and actions, without dashboard-style expansion."
    why_human: "Visual reading comfort is a human-only judgment even when source order is verified."
---

# Phase 06: Polish Menu Bar Icon States and Keyboard Navigation Verification Report

**Phase Goal:** Make the app readable from the menu bar and usable without a mouse.
**Verified:** 2026-04-21T16:36:54Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

Automated and source-level verification passed. The phase cannot be marked `passed` because the visible macOS menu and keyboard traversal remain pending in `06-UAT.md`.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The menu bar has exactly four categorical states, and OK uses the custom logo in the menu bar. | VERIFIED | `ClusterHealthState` has only `ok`, `watch`, `bad`, and `stale`; `MenuBarStatusPresentation` maps OK to `.custom("KubebarLogo")` and the other states to locked SF Symbols; `KubebarApp` renders `presentation.icon`. |
| 2 | The opened menu renders state text, a visible symbol, and one reason. | VERIFIED (source), HUMAN NEEDED (visible menu) | `StatusSummaryView` renders `presentation.symbolName`, `display.state.label`, and `display.primaryStatusReason`; model tests cover OK, Watch, Bad, and Stale reason cases. Visible menu rows remain pending in UAT. |
| 3 | Long names preserve full values and use middle truncation with fallback text. | VERIFIED (source), HUMAN NEEDED (visual/accessibility) | `HealthEvaluator` stores `item.target.displayTitle` as `WatchItemDisplay.title`; summary, watchlist, detail, warning, setup, and picker views use `.lineLimit(1)`, `.truncationMode(.middle)`, `.help(Text(...))`, and `.accessibilityLabel(...)`. |
| 4 | Keyboard reachability uses native controls and focusable sections. | VERIFIED (source), HUMAN NEEDED (real traversal) | Refresh, edit, setup completion, target retry, toggles, pickers, and disclosure groups are native SwiftUI controls with standard shortcuts where planned. UAT keeps real traversal pending. |
| 5 | UAT captures remaining human-only checks honestly. | VERIFIED | `06-UAT.md` is `pending-human-verification`, lists OK/Watch/Bad/Stale, keyboard paths, long-name checks, Full Keyboard Access guidance, and Computer Use inspection limits. |
| 6 | No Phase 06 scope creep into AppKit status item work, dashboard, k9s handoff, distribution, notarization, or new UI automation. | VERIFIED | Scope scan of Phase 06 source files found no `NSStatusItem`, `NSMenu`, `Open in k9s`, packaging/signing work, dashboard feature, custom key handling, or new menu automation stack. |

**Score:** 6/6 source and automated must-haves verified; human menu traversal still required.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `KubebarCore/Models/MenuBarStatusPresentation.swift` | Four-state icon and accessibility presentation | VERIFIED | OK maps to `KubebarLogo`; Watch/Bad/Stale map to the locked SF Symbols; accessibility labels are tested. |
| `KubebarCore/Models/MenuDisplayModel.swift` | Core display model exposes `primaryStatusReason` | VERIFIED | Field and initializer default are present and consumed by views. |
| `KubebarCore/Services/HealthEvaluator.swift` | Core computes one reason and preserves full watch titles | VERIFIED | `primaryStatusReason(for:...)` selects one reason; `makeDisplayItem` uses `item.target.displayTitle`. |
| `Kubebar/Views/StatusSummaryView.swift` | Opened menu status summary | VERIFIED | Renders context, symbol, state label, and primary reason, with middle truncation and accessibility label. |
| `Kubebar/Views/MenuBarRootView.swift` | Watchlist-first order and native refresh/edit actions | VERIFIED | Order is summary, stale signal, counters, watchlist, warning events, node details, refresh, actions; buttons include shortcuts/help. |
| `Kubebar/Views/WatchlistSectionView.swift` | One-line watchlist rows and disclosure details | VERIFIED | Rows use native `DisclosureGroup`; titles use middle truncation and full help/accessibility fallback. |
| `Kubebar/Views/TrackedItemDetailView.swift` | Detail text preserves full fallback where needed | VERIFIED | Examples, latest warning summary, and warning message include help/accessibility. |
| `Kubebar/Views/WarningEventsView.swift` | Warning section long-name fallback | VERIFIED | Section notices and warning summaries use middle truncation/help/accessibility; combined accessibility summary includes notices and rows. |
| `Kubebar/Views/SetupView.swift` | Setup controls remain native and keyboard reachable | VERIFIED | Context and cadence are native pickers; Finish setup has default keyboard action and disabled state. |
| `Kubebar/Views/WatchlistPickerView.swift` | Edit watchlist controls remain native | VERIFIED | Namespace/workload choices use native toggles; workloads use `DisclosureGroup`; target retry has shortcut/help. |
| `docs/architecture/runtime-invariants.md` | Phase 06 runtime rules documented | VERIFIED | Documents OK logo/opened OK text, symbol/text/reason, middle truncation, full fallback, and keyboard rules. |
| `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` | Automated and manual UAT evidence | VERIFIED | Automated checks are recorded as pass; manual menu, keyboard, and long-name checks remain explicitly pending. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `HealthEvaluator` | `MenuDisplayModel.primaryStatusReason` | `MenuDisplayModel(... primaryStatusReason: ...)` | WIRED | Reason is computed in core and passed into the display model. |
| `MenuDisplayModel.primaryStatusReason` | `StatusSummaryView` | `Text(display.primaryStatusReason)` | WIRED | SwiftUI renders the core-owned reason without deriving severity. |
| `MenuBarStatusPresentation.icon` | menu bar label | `KubebarApp` switch over `presentation.icon` | WIRED | OK uses custom image; other states use SF Symbol labels. |
| `WatchTarget.displayTitle` | watchlist row title | `WatchItemDisplay.title` then `Text(item.title)` | WIRED | Full names flow from core into view-level middle truncation and fallback text. |
| `MenuBarRootView` | native menu shell | existing `MenuBarExtra(...).menuBarExtraStyle(.window)` | WIRED | No AppKit status item rewrite was introduced. |
| `06-UAT.md` | remaining manual checks | pending-human-verification rows | WIRED | UAT maps D-17, D-18, D-19, D-20, and R21 to exact manual checks. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StatusSummaryView` | `display.primaryStatusReason` | `MenuBarViewModel.display` populated by `HealthEvaluator` / `RefreshCoordinator` | Yes | FLOWING |
| `KubebarApp` menu label | `viewModel.display.state` | `MenuBarViewModel.display`, initialized and refreshed from app config / cluster reads | Yes | FLOWING |
| `WatchlistSectionView` | `display.visibleWatchItems` | `HealthEvaluator.makeDisplayItem` from snapshot tracked item data | Yes | FLOWING |
| `WarningEventsView` | `display.warningEventSummaries` and `display.sectionNotices` | `HealthEvaluator` from warning event section and section failures | Yes | FLOWING |
| `SetupView` / `WatchlistPickerView` | `setupState` and available targets | `MenuBarViewModel.runtimeState`, context catalog, and watch target catalog | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Four icon-state presentation tests | `swift test --filter MenuBarStatusPresentationTests` | 1 Swift Testing test passed | PASS |
| Display model status/truncation tests | `swift test --filter MenuDisplayModelTests` | 18 Swift Testing tests passed | PASS |
| SwiftPM build | `swift build` | Build completed successfully | PASS |
| Full repo gate | `./scripts/swift-quality-gate.sh local` | Xcode build/test and SwiftPM build/test passed; 86 tests in 15 suites passed. CoreSimulator version warning was non-blocking. | PASS |
| Visible app smoke | `./scripts/compile-and-run.sh` | Not rerun by verifier to avoid launching/killing the visible app; UAT records a prior pass and still leaves menu traversal pending. | SKIPPED |

### Requirements Coverage

`gsd-sdk` and `.planning/REQUIREMENTS.md` are not available in this checkout, so requirement coverage was mapped from plan frontmatter and `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md`.

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| R1 | 06-01, 06-03 | Menu bar icon communicates OK, Watch, Bad, or Stale | VERIFIED | Four-state enum, presentation mapping, app label wiring, and tests. |
| R13 | 06-01, 06-02, 06-03 | Warning/failure states do not rely on color alone | VERIFIED (source), HUMAN NEEDED (visible menu) | Opened menu renders symbol, state text, and reason; UAT leaves live state inspection pending. |
| R18 | 06-02, 06-03 | Dropdown remains disciplined menu utility, not dashboard | VERIFIED (source), HUMAN NEEDED (visual feel) | Main menu order is preserved and no dashboard feature was added; visual judgment remains manual. |
| R19 | 06-02, 06-03 | First screen prioritizes typography, ordering, and spacing | VERIFIED (source), HUMAN NEEDED (visual feel) | Source order and compact section structure are intact; final readability remains manual. |
| R20 | 06-01, 06-02, 06-03 | Long object names truncate consistently | VERIFIED (source), HUMAN NEEDED (visual/accessibility) | Full names preserved in core and middle truncation/help/accessibility modifiers are present in views. |
| R21 | 06-02, 06-03 | Keyboard navigation works across top-level rows and submenus | VERIFIED (source), HUMAN NEEDED (real traversal) | Native controls/shortcuts exist; UAT lists exact Full Keyboard Access traversal checks still pending. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| None | - | No blocking stub, placeholder, custom key-handler, AppKit status item, k9s handoff, distribution/notarization, or dashboard feature found in Phase 06 source files. | - | - |

Notes:
- Default `nil` and empty-array initializer values in model constructors are source-compatible defaults, not user-visible stubs.
- No-op closure defaults in SwiftUI view initializers are preview/test convenience defaults, not runtime handler stubs; `KubebarApp` wires real handlers.
- `WatchlistPickerView` uses card-named private grouping helpers for setup/edit content, but no dashboard route, dashboard action, or dashboard surface was introduced, and the primary menu root remains uncarded and watchlist-first.

### Human Verification Required

#### 1. Opened Menu State Checks

**Test:** Launch the app, open the Kubebar menu, and verify OK, Watch, Bad, and Stale when each state can be exercised live.
**Expected:** State text, visible symbol, and one short reason are present; color is not the only meaning.
**Why human:** Automation could not inspect the menu-bar extra reliably.

#### 2. Keyboard Traversal

**Test:** Enable macOS Full Keyboard Access if needed, then traverse setup, Finish setup enabled/disabled, Retry now enabled/disabled, Edit watchlist, watchlist detail disclosures, warning events, secondary sections, and target-load retry.
**Expected:** Each path is reachable and usable through native keyboard navigation.
**Why human:** Source proves native controls exist; actual macOS menu focus behavior requires visible-app testing.

#### 3. Long-Name Rendering

**Test:** Use long context, namespace, workload, warning summary, and setup picker names.
**Expected:** Visible text uses middle truncation that preserves beginning and end, with full value available through hover help or accessibility.
**Why human:** Rendering and assistive exposure depend on live macOS behavior.

#### 4. Visual Reading Comfort

**Test:** Inspect the first visible menu.
**Expected:** It remains ordered as summary, stale signal, counters, watchlist, warning events, node details, refresh, and actions, without feeling like a dashboard.
**Why human:** Reading comfort and visual scope are judgment-based.

### Gaps Summary

No code or documentation gaps were found. The remaining work is human verification of the visible menu and keyboard traversal already documented in `06-UAT.md`.

---

_Verified: 2026-04-21T16:36:54Z_
_Verifier: Codex (gsd-verifier)_
