---
phase: 05
slug: expand-kubectl-data-into-actionable-warning-and-workload-reasons
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-21
---

# Phase 05 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Swift Testing via the Swift 6 toolchain |
| Config file | `Package.swift` and `project.yml` |
| Quick run command | `swift test --filter KubectlClusterReaderTests` for parser work; `swift test --filter MenuDisplayModelTests` for display mapping work |
| Full suite command | `./scripts/swift-quality-gate.sh local` |
| Estimated runtime | Focused tests under 30 seconds; full gate depends on local Xcode build time |

## Sampling Rate

- After every task commit: run the focused Swift test matching the touched area.
- After every plan wave: run `swift test`.
- Before `$gsd-verify-work`: `./scripts/swift-quality-gate.sh local` must pass.
- Max feedback latency: one focused test run per task.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | R3, R8, R12 | T-01, T-03 | Malformed and partial external JSON cannot appear healthy | unit | `swift test --filter KubectlClusterReaderTests` | yes | pending |
| 05-02-01 | 02 | 2 | R3, R8, R9, R12 | T-01, T-03 | Display model marks unavailable sections and caps detail data | unit | `swift test --filter MenuDisplayModelTests` | yes | pending |
| 05-03-01 | 03 | 3 | R3, R9 | T-02 | Views render prepared display fields without raw kubectl output | unit/full gate | `swift test --filter MenuDisplayModelTests` and `./scripts/swift-quality-gate.sh local` | yes | pending |

Status values: pending, green, red, flaky.

## Wave 0 Requirements

- Existing infrastructure covers the phase requirements.
- Add missing fixture cases in `KubebarTests/Services/KubectlClusterReaderTests.swift`.
- Add display mapping cases in `KubebarTests/Models/MenuDisplayModelTests.swift`.
- No new test framework installation is needed.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible menu remains short and confirmatory | R9 | No dedicated UI automation target exists | Optionally run `./scripts/compile-and-run.sh` after the full gate and inspect that warning/details stay short |

## Threat Model References

- T-01 information disclosure: raw `kubectl` stderr, paths, or kubeconfig details appear in user-facing text.
- T-02 scope creep: UI starts showing raw pod/event output and becomes a troubleshooting console.
- T-03 malformed data safety: invalid external JSON creates a fake healthy display.
- T-04 over-broad Kubernetes reads: phase expands into reads outside nodes, pods, warning events, and workload metadata.

## Validation Sign-Off

- [x] All planned areas have an automated verify command or existing test file.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Existing Swift Testing infrastructure covers this phase.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-04-21
