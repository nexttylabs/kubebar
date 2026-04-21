---
phase: 04-codexbar-inspired-menu-reliability-and-freshness
verified: 2026-04-21T14:41:29Z
status: human_needed
score: "7/7 must-haves verified"
overrides_applied: 0
human_verification:
  - test: "Fresh setup and saved menu flow"
    expected: "Setup is readable, contexts and targets load, setup completes into a watchlist-first menu."
    why_human: "Requires visible menu interaction with local Kubernetes contexts."
  - test: "Refresh controls in the live menu"
    expected: "Cadence and Last updated are visible, Retry now works when idle, and Retry now is disabled during refresh."
    why_human: "Disabled button behavior during an in-flight refresh is best confirmed in the running macOS menu."
  - test: "Live stale and failure states"
    expected: "Old or failed data is shown only as Stale with last-updated text and a safe reason."
    why_human: "Requires live or simulated kubectl failure timing in the visible app."
  - test: "No countdown or extra refresh panel in the visible app"
    expected: "The menu stays compact and does not show a next-refresh countdown or progress panel."
    why_human: "Code scan confirms no refresh countdown text; final appearance still needs visible UAT."
---

# Phase 04: CodexBar-Inspired Menu Reliability and Freshness Verification Report

**Phase Goal:** Make current, stale, and failed states predictable and visible.
**Verified:** 2026-04-21T14:41:29Z
**Status:** human_needed
**Re-verification:** No - previous report had no structured gaps; this replaces it after 04-05.

## Goal Achievement

Phase 04 meets the automated R10, R11, R12, and GH-5 requirements. The only remaining work is manual UAT of visible macOS menu interactions documented in `04-UAT.md`.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Successful data older than 2x the saved refresh cadence displays as Stale. | VERIFIED | `AppConfig.refreshIntervalSeconds` stays persisted in `AppConfigStore.swift:6-21`; `RefreshCoordinator.swift:30` passes `config.refreshIntervalSeconds * 2`; `HealthEvaluator.swift:69-100` converts expired snapshots to `.stale`; tests cover this in `MenuDisplayModelTests.swift:123-148` and `RefreshCoordinatorTests.swift:127-153`. |
| 2 | Last updated text is carried by the display model and rendered in the menu. | VERIFIED | `MenuDisplayModel.swift:103-130` includes `lastUpdated`; `HealthEvaluator.swift:73-80` derives it from `capturedAt`; `MenuBarRootView.swift:68` renders `Last updated \(display.lastUpdated)`; stale banner also shows it in `StaleBannerView.swift:13`. |
| 3 | Timeout, command failure, malformed JSON, and no previous data produce distinct short safe reasons. | VERIFIED | Timeout and command failure are mapped in `KubectlClusterReader.swift:87-95`; malformed section reasons are mapped in `KubectlClusterReader.swift:129-166`; unsafe output falls back to `kubectl failed` in `KubectlClusterReader.swift:409-435`; no previous data is set in `RefreshCoordinator.swift:48`. Tests cover these in `KubectlClusterReaderTests.swift:80-103`, `KubectlClusterReaderTests.swift:123-138`, and `RefreshCoordinatorTests.swift:53-67`. |
| 4 | Repeated failures preserve the last successful snapshot only when clearly stale. | VERIFIED | Failed refresh returns `snapshot: previousSnapshot` while evaluating stale display in `RefreshCoordinator.swift:47-59`; `HealthEvaluator.swift:37-45` forces `.stale` for previous data; `RefreshCoordinatorTests.swift:69-99` proves the second failure keeps counters/watchlist rows and updates the reason. |
| 5 | Manual and automatic refreshes share one in-flight guard and cannot overlap. | VERIFIED | `RefreshGate.swift` blocks a second begin until finish, invalidates older refresh tickets after config changes, and records pending refresh handoff; `MenuBarViewModel.swift` gates `refreshNow`, rejects stale async results, and auto-refresh calls the same guarded path; `RefreshGateTests.swift` covers the guard, stale ticket rejection, and pending refresh handoff. |
| 6 | Retry now is disabled while refresh work is running. | VERIFIED | `MenuBarViewModel.swift:20` publishes `isRefreshing`; `MenuBarViewModel.swift:85-94` toggles it around refresh work; `KubebarApp.swift:10-16` passes it to the root view; `MenuBarRootView.swift:79-80` disables the button. |
| 7 | The menu does not add a fifth status state, countdown, or refresh progress panel. | VERIFIED | `ClusterHealthState.swift:3-7` has only `ok`, `watch`, `bad`, and `stale`; production UI scan found no `next refresh` or countdown refresh UI. The only `ProgressView` is setup watch-target loading in `WatchlistPickerView.swift:96-103`, not refresh progress. |

**Score:** 7/7 automated truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `KubebarCore/Models/MenuDisplayModel.swift` | Freshness render contract | VERIFIED | `lastUpdated` is a required display field, so views do not compute freshness themselves. |
| `KubebarCore/Services/HealthEvaluator.swift` | Severity and stale policy | VERIFIED | Applies stale age-out, stale banner reason, and last-updated formatting. |
| `KubebarCore/Services/RefreshCoordinator.swift` | Refresh outcome mapping | VERIFIED | Uses saved cadence threshold and preserves previous snapshot on failure. |
| `KubebarCore/Services/KubectlClusterReader.swift` | Safe failure categories | VERIFIED | Maps timeout, command failure, malformed JSON, redacted unsafe errors, and section failures. |
| `KubebarCore/Services/RefreshGate.swift` | Refresh serialization | VERIFIED | Small in-flight guard with tests. |
| `Kubebar/MenuBarViewModel.swift` | Refresh orchestration | VERIFIED | Manual and auto refresh share `refreshNow()` and the same gate. |
| `Kubebar/Views/MenuBarRootView.swift` | Refresh UI | VERIFIED | Renders cadence, last updated, and disabled retry state. |
| `KubebarTests/*` | Deterministic coverage | VERIFIED | Focused tests and full quality gate pass. |
| `docs/architecture/runtime-invariants.md` | Runtime contract | VERIFIED | Documents 2x stale age-out, repeated failure behavior, failure reasons, and no Secrets reads. |
| `04-UAT.md` | Manual visible-app checklist | VERIFIED | Covers setup/menu/cadence/stale/retry/countdown/icon checks; manual statuses remain pending. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `AppConfig.refreshIntervalSeconds` | stale threshold | `RefreshCoordinator.refresh` | WIRED | `RefreshCoordinator.swift:30` computes `staleAfterSeconds = config.refreshIntervalSeconds * 2`. |
| `RefreshCoordinator` | `HealthEvaluator` | `staleAfterSeconds` parameter | WIRED | Success and failure paths both pass the threshold to evaluation. |
| `HealthEvaluator` | `MenuDisplayModel` | `lastUpdated` and `staleBanner` | WIRED | Display model receives derived age and stale reason. |
| `MenuDisplayModel` | `MenuBarRootView` | `display.lastUpdated` | WIRED | Refresh controls render `Last updated <age>`. |
| `MenuBarViewModel.isRefreshing` | `Retry now` button | `KubebarApp` to `MenuBarRootView` | WIRED | Button is disabled with `.disabled(isRefreshing)`. |
| `KubectlClusterReader` | stale reason display | `RefreshCoordinator` failure mapping | WIRED | Safe reasons flow into `RefreshFailure` and then stale banner display. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `MenuBarRootView.swift` | `display.lastUpdated` | `HealthEvaluator.relativeAge(snapshot.capturedAt, now)` through `RefreshCoordinator` | Yes | VERIFIED |
| `StaleBannerView.swift` | `banner.reason` | `KubectlClusterReader` or coordinator no-previous-data reason through `RefreshFailure` | Yes | VERIFIED |
| `MenuBarRootView.swift` | `isRefreshing` | `MenuBarViewModel.refreshNow()` sets true before async work and false in defer | Yes | VERIFIED |
| `MenuBarViewModel.swift` | refresh execution | auto loop and manual action call the same `refreshNow()` path guarded by `RefreshGate` | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Menu display freshness and stale rules | `swift test --filter MenuDisplayModelTests` | 16 tests passed | PASS |
| Refresh gate serialization | `swift test --filter RefreshGateTests` | 4 tests passed | PASS |
| Refresh coordinator failure and stale age behavior | `swift test --filter RefreshCoordinatorTests` | 7 tests passed | PASS |
| kubectl failure categories and safe redaction | `swift test --filter KubectlClusterReaderTests` | 19 tests passed | PASS |
| Full local gate | `./scripts/swift-quality-gate.sh local` | Xcode build/test, Swift build/test passed with 84 tests | PASS |
| Visible app smoke test | `./scripts/compile-and-run.sh` | Built, tested, launched `DerivedData/Build/Products/Debug/Kubebar.app`; PID 96714 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| R10 | 04-05 | The app must never make stale data look healthy or current. | SATISFIED | Successful snapshots older than 2x cadence become `.stale`; partial unavailable data becomes `.watch`, not `.ok`. |
| R11 | 04-05 | Failed refresh keeps old data only when clearly marked Stale. | SATISFIED | Failure path evaluates previous snapshot with `stateOverride: .stale`; tests preserve rows/counters only under stale display. |
| R12 | 04-05 | Stale state shows last successful update, failure reason when known, and Retry now. | SATISFIED | Last updated and reason render through display/stale banner; Retry now remains present and is disabled only while refreshing. |
| GH-5 | 04-05 | Add refresh cadence, timeout, and freshness controls. | SATISFIED | Cadence persists, 2x stale age-out exists, failure categories are distinct, refreshes are serialized, and docs/UAT were updated. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No blocking stub, placeholder, force unwrap, `try!`, `fatalError`, or refresh countdown/progress-panel pattern found in the verified path. | - | - |

### Human Verification Required

#### 1. Fresh Setup And Saved Menu Flow

**Test:** Launch the app with a fresh config, select a context, select watch targets, finish setup, and open the menu.
**Expected:** Setup is readable, targets load, and the normal menu is watchlist-first.
**Why human:** Requires visible macOS menu interaction with local Kubernetes contexts.

#### 2. Live Refresh Controls

**Test:** Open the running menu and use `Retry now`; observe the button while refresh is in progress.
**Expected:** Cadence and `Last updated <age>` are visible; `Retry now` is enabled when idle and disabled while refreshing.
**Why human:** Code wiring is verified, but the visible disabled state should be confirmed in the live menu.

#### 3. Live Stale And Failure States

**Test:** Use old data or force a kubectl failure and inspect the menu.
**Expected:** The menu shows `Stale`, keeps last good rows only as stale data, shows last-updated text, and uses a safe short reason.
**Why human:** The timing and failure behavior is tested deterministically, but the final visible state needs manual confirmation.

#### 4. Compact Menu Check

**Test:** Inspect the menu during idle and refresh states.
**Expected:** No next-refresh countdown, fifth state, or persistent refresh progress panel appears.
**Why human:** Code scan confirms the absence; final appearance still belongs in UAT.

### Gaps Summary

No automated gaps found. Phase 04 should remain `human_needed` until the pending visible UAT checks in `04-UAT.md` are completed.

---

_Verified: 2026-04-21T14:41:29Z_
_Verifier: Claude (gsd-verifier)_
