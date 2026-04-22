---
phase: 07
slug: add-operator-facing-qa-and-app-verification
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-22
---

# Phase 07 - Validation Strategy

Per-phase validation contract for operator-facing QA and app verification.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Swift Testing |
| Config file | `Package.swift`, `project.yml` |
| Quick run command | `swift test --filter MenuStateFixtureCatalogTests` |
| Focused existing commands | `swift test --filter MenuDisplayModelTests`; `swift test --filter KubectlClusterReaderTests` |
| Full suite command | `./scripts/swift-quality-gate.sh local` |
| Estimated runtime | Full gate runtime depends on Xcode; quick fixture test should stay under 10 seconds |

---

## Sampling Rate

- After every fixture or model task: run `swift test --filter MenuStateFixtureCatalogTests`.
- After display-state changes: run `swift test --filter MenuDisplayModelTests`.
- After kubectl failure fixture changes: run `swift test --filter KubectlClusterReaderTests`.
- After script or final docs changes: run `./scripts/swift-quality-gate.sh local`.
- Before final verification: full gate must pass, `07-UAT.md` must contain every required state row, and any missing visible-menu screenshot must be marked `pending-human-verification`.
- Max automated feedback latency: 10 seconds for focused fixture tests.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | D-02, D-05, D-06, D-07, D-08, D-09 | T-07-01 | QA fixtures use app-owned display strings and no live cluster mutation. | unit | `swift test --filter MenuStateFixtureCatalogTests` | no | pending |
| 07-01-02 | 01 | 1 | D-04, D-09 | T-07-02 | kubectl failure evidence uses fake inputs and safe stale display. | unit | `swift test --filter MenuStateFixtureCatalogTests`; `swift test --filter KubectlClusterReaderTests` | partial | pending |
| 07-02-01 | 02 | 2 | D-13 | T-07-03 | Debug QA mode is not exposed as production menu controls. | unit/build | `swift test --filter MenuStateFixtureCatalogTests`; `swift build` | no | pending |
| 07-03-01 | 03 | 2 | D-01, D-03, D-10, D-12, D-17 | T-07-04 | QA generation writes temp artifacts and does not overwrite human evidence. | script | `./scripts/swift-quality-gate.sh local` | no | pending |
| 07-04-01 | 04 | 3 | D-11, D-14, D-15, D-16 | T-07-05 | UAT and docs avoid raw command transcripts, tokens, kubeconfig paths, and full JSON. | docs/manual | `rg -n "Healthy|Watch|Bad|Stale|first-use|empty-watchlist|kubectl failure|pending-human-verification" .planning/phases/07-add-operator-facing-qa-and-app-verification/07-UAT.md docs/qa/operator-verification.md` | no | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `KubebarCore/QA/MenuStateFixtureCatalog.swift` or equivalent stable fixture source exists.
- [ ] `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` exists and covers all required QA states.
- [ ] `Kubebar/QA/QALaunchMode.swift` or equivalent Debug-only adapter exists if the planner chooses an app-mode implementation.
- [ ] `scripts/generate-qa-evidence.sh` or equivalent non-GUI artifact generator exists.
- [ ] `scripts/swift-quality-gate.sh` includes the QA artifact generation check without removing Xcode build/test or SwiftPM build/test.
- [ ] `.planning/phases/07-add-operator-facing-qa-and-app-verification/07-UAT.md` exists.
- [ ] `docs/qa/operator-verification.md` exists.
- [ ] `docs/assets/qa/` exists for committed screenshot or equivalent visual evidence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible Healthy menu state | D-02, D-05 | Menu-bar extra inspection can be unreliable through automation. | Launch with the Healthy QA state, open the menu, capture or record evidence, and update `07-UAT.md`. |
| Visible Watch menu state | D-02, D-06 | Warning-state visual reading needs visible menu evidence. | Launch with the Watch QA state, open the menu, capture or record evidence, and update `07-UAT.md`. |
| Visible Bad menu state | D-02, D-07 | Bad-state visual reading needs visible menu evidence. | Launch with the Bad QA state, open the menu, capture or record evidence, and update `07-UAT.md`. |
| Visible Stale menu state | D-02, D-09 | Stale must not be mistaken for healthy in the actual menu. | Launch stale failure and stale age-out QA states, capture or record evidence, and update `07-UAT.md`. |
| Visible first-use and empty-watchlist states | D-08 | These are distinct trust states that need visible confirmation. | Launch each QA state, capture or record evidence, and update separate UAT rows. |
| Screenshot capture or equivalent visual evidence | D-01, D-12, D-15, D-17 | Screenshot capture may be blocked by local macOS state. | Store screenshots under `docs/assets/qa/`, or mark `pending-human-verification` with a written reason. |

---

## Validation Sign-Off

- [ ] All plans include automated checks where practical and manual-only checks where macOS menu inspection is required.
- [ ] Sampling continuity: no three consecutive implementation tasks lack an automated verification command.
- [ ] Wave 0 covers all missing fixture, harness, generator, UAT, and docs files.
- [ ] No watch-mode flags are required.
- [ ] Quick fixture feedback latency stays under 10 seconds.
- [ ] Full phase gate remains `./scripts/swift-quality-gate.sh local`.
- [ ] `nyquist_compliant: true` is set in frontmatter.

**Approval:** pending
