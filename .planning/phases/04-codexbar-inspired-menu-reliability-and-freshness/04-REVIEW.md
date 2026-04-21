---
phase: 04-codexbar-inspired-menu-reliability-and-freshness
reviewed: 2026-04-21T14:41:29Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-05-SUMMARY.md
  - .planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-UAT.md
  - Kubebar.xcodeproj/project.pbxproj
  - Kubebar/KubebarApp.swift
  - Kubebar/MenuBarViewModel.swift
  - Kubebar/Views/MenuBarRootView.swift
  - KubebarCore/Models/MenuDisplayModel.swift
  - KubebarCore/Services/HealthEvaluator.swift
  - KubebarCore/Services/RefreshCoordinator.swift
  - KubebarCore/Services/RefreshGate.swift
  - KubebarCore/Services/KubectlClusterReader.swift
  - KubebarTests/Models/MenuDisplayModelTests.swift
  - KubebarTests/Services/KubectlClusterReaderTests.swift
  - KubebarTests/Services/RefreshCoordinatorTests.swift
  - KubebarTests/Services/RefreshGateTests.swift
  - docs/architecture/runtime-invariants.md
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 04: Code Review Report

**Reviewed:** 2026-04-21T14:41:29Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** clean

## Summary

Reviewed commits `40cddff`, `4915392`, `2791542`, `133bf48`, review fix `7b92cae`, plus the current `04-05-SUMMARY.md`. Existing tests and `./scripts/swift-quality-gate.sh local` pass with 84 tests.

No critical security issue was found in the safe kubectl error display path. Timeout, empty or unsafe stderr, malformed JSON, and no-previous-data cases are covered by tests.

## Findings

None.

## Resolved Warnings

### WR-01: Freshness can remain visually current until another refresh completes

**File:** `Kubebar/MenuBarViewModel.swift:96-101`

**Issue:** The stale age-out rule only runs when `refreshNow()` completes a new refresh and assigns `display`. `MenuDisplayModel.lastUpdated` is a precomputed string, so the menu does not recompute age or state as time passes. A normal sequence can violate the "old data never looks current" rule: a successful refresh publishes `OK` and `Last updated 0s ago`; the Mac sleeps, the app is suspended, or a refresh is delayed; when the menu is opened later, the old display can still look current until kubectl finishes another refresh.

**Resolution:** Fixed in `7b92cae`. `MenuBarViewModel` now re-evaluates existing snapshot freshness before refresh work and schedules a lightweight freshness timer after applying a snapshot.

### WR-02: A config change during an in-flight refresh can be dropped and overwritten by old data

**File:** `Kubebar/MenuBarViewModel.swift:80-101`

**Issue:** `refreshNow()` captures the current `config` and then the gate rejects any later refresh while the first one is running. `completeSetup()` replaces `config` and calls `refreshNow()`, but that call returns immediately if an older refresh is still in flight. The older task can then assign `snapshot` and `display` for the previous context or watchlist. Result: after editing setup, the menu can show stale content from the old configuration until the next automatic refresh.

**Resolution:** Fixed in `7b92cae`. `RefreshGate` now issues config-bound tickets, invalidates older generations, rejects results for stale configs, and records a pending refresh for config changes during in-flight work. `RefreshGateTests` cover stale ticket rejection and pending refresh handoff.

---

_Reviewed: 2026-04-21T14:41:29Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
