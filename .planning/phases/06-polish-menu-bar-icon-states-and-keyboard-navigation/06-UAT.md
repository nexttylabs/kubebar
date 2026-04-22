---
status: pending-human-verification
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
source:
  - 06-01-SUMMARY.md
  - 06-02-SUMMARY.md
started: 2026-04-21T16:13:52Z
updated: 2026-04-21T16:16:35Z
---

## Automated Verification

| Check | Result | Evidence |
| --- | --- | --- |
| `swift test --filter MenuBarStatusPresentationTests` | pass | The Menu bar status presentation suite passed 1 test, covering the four menu bar status labels and icon sources. |
| `swift test --filter MenuDisplayModelTests` | pass | The Menu display model suite passed 18 tests, including primary status reasons, stale state, warning summaries, watchlist caps, and full-name preservation. |
| `swift build` | pass | SwiftPM debug build completed successfully. |
| `./scripts/swift-quality-gate.sh local` | pass | Xcode build, Xcode test, SwiftPM build, and SwiftPM test passed; the full Swift test run reported 86 tests in 15 suites. The CoreSimulator version warning did not block the macOS checks. |
| `./scripts/compile-and-run.sh` | pass | The visible-app smoke path rebuilt and tested the app, then launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID 27388. |

## Manual Menu State Checks

| State | Status | Expected opened-menu behavior | Evidence |
| --- | --- | --- | --- |
| OK | pending-human-verification | Opened menu shows `OK` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic OK state presentation. |
| Watch | pending-human-verification | Opened menu shows `Watch` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Watch state reasons. |
| Bad | pending-human-verification | Opened menu shows `Bad` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Bad state reasons. |
| Stale | pending-human-verification | Opened menu shows `Stale` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Stale fallback reasons. |

Decision mapping: these rows cover D-18 and D-19. If the live cluster cannot force every state, keep the unavailable state rows as `pending-human-verification` and rely on model tests for deterministic state coverage.

## Manual Keyboard Checks

Enable macOS Full Keyboard Access if Tab traversal skips buttons, pickers, toggles, disclosures, or other non-text controls. Record only app-owned names or redacted observations.

| Path | Status | Expected behavior | Evidence |
| --- | --- | --- | --- |
| Setup screen | pending-human-verification | Keyboard traversal reaches setup header, context picker, watchlist picker, refresh cadence picker, and footer actions. | Requires visible menu keyboard traversal. |
| Finish setup enabled | pending-human-verification | `Finish setup` is reachable and activatable when context and watchlist are configured. | Requires a configured setup state in the visible app. |
| Finish setup disabled | pending-human-verification | Disabled `Finish setup` remains visible and skipped or announced as disabled by native navigation. | Requires an incomplete setup state in the visible app. |
| Refresh enabled | pending-human-verification | `Retry now` is reachable and activatable when no refresh is running. | Requires visible menu keyboard traversal. |
| Refresh disabled | pending-human-verification | Disabled refresh remains visible when refresh is in progress. | Requires a visible in-progress refresh state. |
| Edit watchlist | pending-human-verification | `Edit watchlist` is reachable and opens setup/watchlist editing through native controls. | Requires visible menu keyboard traversal. |
| Watchlist detail disclosure | pending-human-verification | Watchlist row disclosures are reachable and can expand/collapse details. | Requires a visible watchlist row. |
| Warning events | pending-human-verification | Warning event rows or their empty/unavailable state are reachable after the watchlist. | Requires visible menu keyboard traversal. |
| Node details or secondary sections | pending-human-verification | Node details or another secondary section remains reachable without disrupting watchlist-first order. | Requires visible menu keyboard traversal. |
| Target-load retry | pending-human-verification | Target loading failure or empty-target retry is reachable and activatable from setup. | Requires a target-load retry state. |

Decision mapping: these rows cover D-17, D-18, D-20, and R21.

## Long Name Checks

| Name type | Status | Expected result | Evidence |
| --- | --- | --- | --- |
| Context | pending-human-verification | Long context names use middle truncation that preserves beginning and end; the full value is present in hover help/accessibility. | Requires visible long context name inspection. |
| Namespace | pending-human-verification | Long namespace names use middle truncation that preserves beginning and end; the full value is present in hover help/accessibility. | Requires visible long namespace name inspection. |
| Workload | pending-human-verification | Long workload names use middle truncation that preserves beginning and end; the full value is present in hover help/accessibility. | Requires visible long workload name inspection. |
| Warning summary | pending-human-verification | Long warning summary text uses middle truncation where one-line display is required; the full value is present in hover help/accessibility. | Requires visible warning summary inspection. |
| Setup picker | pending-human-verification | Long setup picker names use middle truncation that preserves beginning and end; the full value is present in hover help/accessibility. | Requires visible setup picker inspection. |

## Scope Guards

| Guard | Result | Evidence |
| --- | --- | --- |
| No AppKit status-item rewrite | pass | Source review kept the existing SwiftUI `MenuBarExtra.window` path and did not add a custom status-item shell. |
| No packaging or signing scope | pass | This phase added runtime docs and UAT only; no packaging, signing, or release workflow was added. |
| No k9s handoff | pass | No deeper-debugging handoff action was added. |
| No dashboard surface | pass | The UAT preserves the native utility menu boundary and does not introduce a dashboard surface. |
| No command transcript exposure | pass | Runtime rules and UAT evidence require app-owned display strings or redacted observations only. |
| No added menu automation stack | pass | This phase records manual keyboard verification rather than adding a new automation target. |

## Computer Use Notes

- The visible app smoke command launched Kubebar successfully.
- Computer Use could not obtain an interactive app state for `com.nextty.kubebar`; it returned Apple event timeout `-10005`.
- Computer Use could not obtain an interactive state for `SystemUIServer`; it returned Apple event timeout `-10005`.
- Prior menu-bar extras may not be inspectable through automation; manual keyboard checks are the source of truth when automation cannot inspect SystemUIServer.
- Manual evidence must avoid raw command transcripts, token-like strings, kubeconfig paths, or full JSON.
