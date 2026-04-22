---
phase: 09
slug: codexbar-inspired-tabbed-menu-redesign
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-22
---

# Phase 09 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Swift Testing with `import Testing`, `@Suite`, `@Test`, and `#expect` |
| Config file | `Package.swift` test target `KubebarCoreTests`; `project.yml` Xcode target `KubebarTests` |
| Quick run command | `swift test --filter MenuDisplayModelTests` |
| Full suite command | `./scripts/swift-quality-gate.sh local` |
| Visible app smoke command | `./scripts/compile-and-run.sh` |
| Estimated runtime | focused tests under 30 seconds; full gate depends on Xcode build/test runtime |

---

## Sampling Rate

- After display-model or core state task commits: run `swift test --filter MenuDisplayModelTests` and any new focused test filter added by the task.
- After app-shell or Settings task commits: run `swift build` plus the focused model tests affected by the task.
- After each plan wave: run `./scripts/swift-quality-gate.sh local`.
- Before final verification: run `./scripts/swift-quality-gate.sh local`, run `./scripts/compile-and-run.sh`, and update `09-UAT.md`.
- Max automated feedback latency: use focused Swift tests before the full gate whenever a task changes only core/model behavior.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | REQ-09-01 fixed tabs and Overview default | T-09-02 | Tab state remains UI-local and does not read Kubernetes. | unit | `swift test --filter MenuDisplayModelTests` plus any new tab-state filter | partial | pending |
| 09-01-02 | 01 | 1 | REQ-09-03 Overview watchlist-first, stale, counters, notices | T-09-03 | Stale data cannot look healthy; unavailable sections stay visible. | unit | `swift test --filter MenuDisplayModelTests` | yes | pending |
| 09-01-03 | 01 | 1 | REQ-09-04/05/06 Nodes, Pods, Events explicit states | T-09-01/T-09-03 | Tabs render safe app-owned strings and no raw command output. | unit | `swift test --filter MenuDisplayModelTests` | partial | pending |
| 09-02-01 | 02 | 2 | REQ-09-07 Settings independent dialog/window | T-09-04 | Settings saves local app config only and introduces no account/cloud sync. | build + UAT | `swift build` and `./scripts/compile-and-run.sh` | no UI automation | pending |
| 09-02-02 | 02 | 2 | REQ-09-08 visible Quit Kubebar preserves config | T-09-05 | Quit terminates the app without mutating `AppConfigStore`. | build + UAT | `swift build` and `./scripts/compile-and-run.sh` | no UI automation | pending |
| 09-03-01 | 03 | 3 | REQ-09-09/10 keyboard, truncation, and UAT evidence | T-09-06 | UAT evidence avoids raw transcripts, tokens, kubeconfig paths, and full JSON. | docs/manual | `rg -n "Overview|Nodes|Pods|Events|Settings\\.\\.\\.|Quit Kubebar|pending-human-verification" .planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md` | no | pending |

Status: pending, green, red, flaky.

---

## Wave 0 Requirements

- [ ] Add focused tests to `KubebarTests/Models/MenuDisplayModelTests.swift` for any new tab-specific display fields or notice caps.
- [ ] Add `KubebarTests/Models/MenuTabStateTests.swift` only if tab selection is extracted into a testable value type.
- [ ] Add `KubebarTests/Models/MenuRuntimeStateTests.swift` coverage only if Settings or setup/edit mode moves into core runtime state.
- [ ] Create `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md` with rows for OK, Watch, Bad, Stale, tab switching, reopen reset, empty watchlist, Settings, Quit, keyboard navigation, and long names.
- [ ] Keep app-shell automation optional; this repo currently has no UI automation target for `MenuBarExtra.window`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible tab switching in the menu bar window | REQ-09-01, REQ-09-02 | Prior evidence shows menu-bar extras may not be inspectable through automation. | Run `./scripts/compile-and-run.sh`, open the menu, switch `Overview`, `Nodes`, `Pods`, and `Events`, and record `09-UAT.md` with screenshot path or `pending-human-verification`. |
| Settings opens independently | REQ-09-07 | SwiftUI Settings presentation is app-shell behavior, not covered by current model tests. | Open menu, activate `Settings...`, confirm a separate settings dialog/window appears, and record `09-UAT.md`. |
| Quit exits without config loss | REQ-09-08 | Actual app termination and post-quit config preservation need visible app evidence. | Record config before launching, activate `Quit Kubebar`, relaunch, confirm context/watchlist/cadence remain present, and summarize in `09-UAT.md`. |
| Keyboard reaches tabs, refresh, settings, quit, details, and sections | REQ-09-09 | Native macOS keyboard traversal depends on visible controls and system settings. | Enable Full Keyboard Access if needed, traverse controls, and record `09-UAT.md`; leave `pending-human-verification` if not completed. |
| Long-name truncation and tooltip/accessibility behavior | REQ-09-10 | Visual truncation and hover help require visible UI inspection. | Use long context/namespace/workload/event names, confirm middle truncation and full help/accessibility labels, and record `09-UAT.md`. |

---

## Threat References

| Threat | Risk | Required Mitigation |
|--------|------|---------------------|
| T-09-01 | UI leaks raw `kubectl` output, kubeconfig path, token-like strings, or JSON. | Render only app-owned display strings and safe short reasons. |
| T-09-02 | Tab switching triggers refresh or direct `kubectl` reads. | Keep tabs as UI navigation; reads remain explicit/cadence-driven through existing services. |
| T-09-03 | Stale or unavailable data appears healthy. | Keep `Stale` banner and section notices visible on Overview and relevant tabs. |
| T-09-04 | Settings expands product scope into accounts, cloud sync, or multi-cluster switching. | Settings saves local app configuration only. |
| T-09-05 | Quit action clears saved app configuration. | Quit only requests app termination; it must not call config mutation paths. |
| T-09-06 | UAT evidence leaks sensitive cluster details. | Use safe summaries, screenshot paths, and redacted observations only. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or an explicit manual UAT reason.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers missing focused tests and `09-UAT.md`.
- [ ] No watch-mode flags.
- [ ] Full gate remains `./scripts/swift-quality-gate.sh local`.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-04-22
