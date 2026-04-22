---
phase: 07-add-operator-facing-qa-and-app-verification
plan: "01"
subsystem: qa
tags: [swift, testing, fixtures, menu-state]

requires:
  - phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
    provides: menu display states, status labels, stale behavior, and watchlist display contracts
provides:
  - Stable fixture catalog for all eight required operator-facing menu states
  - Focused Swift Testing coverage for fixture completeness, state mapping, setup-state separation, lookup, and sensitive-string safety
affects: [07-02, 07-03, 07-04, menu-qa, operator-verification]

tech-stack:
  added: []
  patterns:
    - App-owned QA fixtures built through HealthEvaluator where cluster-derived
    - Parameterized Swift Testing coverage over MenuQAState.allCases

key-files:
  created:
    - KubebarCore/QA/MenuStateFixtureCatalog.swift
    - KubebarTests/QA/MenuStateFixtureCatalogTests.swift
  modified:
    - Kubebar.xcodeproj/project.pbxproj

key-decisions:
  - "Keep fixtures in KubebarCore so app, tests, and scripts share one state catalog."
  - "Represent kubectl failure through a safe stale display with no raw command detail."
  - "Keep first-use and empty-watchlist as separate setup fixtures."

patterns-established:
  - "Use fixed dates and app-owned snapshots for repeatable QA state generation."
  - "Treat visible screenshot evidence as separate from automated model proof."

requirements-completed: [D-02, D-04, D-05, D-06, D-07, D-08, D-09, D-13]

duration: 12min
completed: 2026-04-22
---

# Phase 07 Plan 01: QA Fixture Catalog Summary

**Stable menu-state fixtures now cover Healthy, Watch, Bad, Stale, first-use, empty-watchlist, and kubectl failure without live cluster dependence.**

## Accomplishments

- Added `MenuQAState`, `MenuStateFixture`, and `MenuStateFixtureCatalog`.
- Covered all locked Phase 07 states with deterministic display/setup data and screenshot paths.
- Added `MenuStateFixtureCatalogTests` for state coverage, setup distinction, lookup, and sensitive-string safety.

## Task Commits

1. **QA fixture catalog and tests** - `e5f2f60` (feat)

## Files Created/Modified

- `KubebarCore/QA/MenuStateFixtureCatalog.swift` - Shared fixture catalog for required menu states.
- `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` - Parameterized fixture tests and safety assertions.
- `Kubebar.xcodeproj/project.pbxproj` - Regenerated so Xcode includes the new QA files.

## Decisions Made

- Used `HealthEvaluator` for cluster-derived states to avoid duplicated health logic.
- Kept setup-only states backed by `SetupFlowState` with stale display data, so they cannot be mistaken for healthy.
- Kept failure messages safe and short; no kubeconfig paths, raw stderr, tokens, or command transcripts are fixture evidence.

## Deviations from Plan

None. The plan was implemented against the current model names and source layout.

## Verification

- `swift test --filter MenuStateFixtureCatalogTests` - passed.
- `./scripts/swift-quality-gate.sh local` - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 07-02 can use the shared fixture catalog to render deterministic states through the real menu shell.

---
*Phase: 07-add-operator-facing-qa-and-app-verification*
*Completed: 2026-04-22*
