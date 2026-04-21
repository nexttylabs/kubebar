---
phase: 06
slug: polish-menu-bar-icon-states-and-keyboard-navigation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-21
---

# Phase 06 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Swift Testing via the Swift 6 toolchain |
| Config file | `Package.swift` and `project.yml` |
| Quick run command | `swift test --filter MenuBarStatusPresentationTests` for icon state work; `swift test --filter MenuDisplayModelTests` for display mapping and truncation work |
| Full suite command | `./scripts/swift-quality-gate.sh local` |
| Visible app smoke command | `./scripts/compile-and-run.sh` |
| Estimated runtime | Focused tests under 30 seconds; full gate depends on local Xcode build time |

## Sampling Rate

- After every task commit: run the focused Swift test matching the touched area.
- After every plan wave: run `swift test`.
- Before `$gsd-verify-work`: `./scripts/swift-quality-gate.sh local` must pass.
- Visible menu confidence: run `./scripts/compile-and-run.sh` before final UAT sign-off.
- Max feedback latency: one focused test run per task.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | R1, R13 | T-06-01-01, T-06-01-02 | Four state icons and accessibility labels stay explicit, and opened-menu status has one reason | unit | `swift test --filter MenuBarStatusPresentationTests && swift test --filter MenuDisplayModelTests` | yes | pending |
| 06-02-01 | 02 | 2 | R18, R19, R20 | T-06-02-01, T-06-02-02 | Long names preserve full values for tooltip/accessibility while visual rows use middle truncation | unit + source review | `swift test --filter MenuDisplayModelTests` | yes | pending |
| 06-03-01 | 03 | 3 | R21 | T-06-03-01 | Native controls remain keyboard reachable and manual QA records the real menu traversal | manual QA + full gate | `./scripts/swift-quality-gate.sh local && ./scripts/compile-and-run.sh` | no Phase 06 UAT yet | pending |

Status values: pending, green, red, flaky.

## Wave 0 Requirements

- Existing Swift Testing infrastructure covers model and presentation checks.
- Add missing icon-source assertions in `KubebarTests/Models/MenuBarStatusPresentationTests.swift`.
- Add `primaryStatusReason` and full-name preservation cases in `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Add `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` for four states, setup, edit watchlist, refresh enabled/disabled, disclosure groups, warning events, secondary sections, long-name tooltip/accessibility, and Full Keyboard Access.
- No new test framework installation is needed.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real menu keyboard traversal reaches setup, refresh, edit watchlist, watchlist detail, warning events, and secondary sections | R21 | No dedicated UI automation target exists for the macOS menu bar extra | Run `./scripts/compile-and-run.sh`, enable Full Keyboard Access if needed, open Kubebar, and tab through all listed controls and expandable rows |
| Opened menu keeps a native utility feel rather than card/dashboard layout | R18, R19 | The repo has no visual snapshot test target | Run `./scripts/compile-and-run.sh` and compare the opened menu against the `06-UAT.md` checklist |
| Tooltip/accessibility full-name fallback is present for long context, namespace, workload, and warning names | R20 | Hover and assistive output are not covered by existing unit tests | Use long fixture/config names when possible; inspect hover help and accessibility labels during visible app QA |

## Threat Model References

- T-06-01-01 misleading healthy icon: `OK` uses the brand logo in the menu bar, so the opened menu must explicitly show `OK`.
- T-06-01-02 color-only failure signal: `Watch`, `Bad`, and `Stale` must use symbol, status text, and one reason.
- T-06-02-01 truncated-name ambiguity: tail-only truncation can hide Kubernetes suffix differences.
- T-06-02-02 raw output disclosure: tooltip/accessibility full names must use app-owned context/resource names, not raw `kubectl` output.
- T-06-03-01 mouse-only workflow: setup, refresh, edit, detail, warning, and secondary sections can work by mouse while failing keyboard traversal.

## Validation Sign-Off

- [x] All planned areas have an automated verify command or documented manual QA.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify or UAT.
- [x] Existing Swift Testing infrastructure covers model-level phase behavior.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-04-21
