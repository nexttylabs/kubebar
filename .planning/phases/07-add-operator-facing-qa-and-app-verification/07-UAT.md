---
status: pending-human-verification
phase: 07-add-operator-facing-qa-and-app-verification
sources:
  - 07-01-SUMMARY.md
  - 07-02-SUMMARY.md
  - 07-03-SUMMARY.md
  - 07-04-SUMMARY.md
updated: 2026-04-22
---

# Phase 07 UAT

Operator-facing QA evidence for required menu states.

## Automated Verification

| Check | Result | Evidence |
|-------|--------|----------|
| `swift test --filter MenuStateFixtureCatalogTests` | pass | Menu QA fixture suite passed with all eight states. |
| `./scripts/swift-quality-gate.sh local` | pass | Xcode build/test, Swift build/test, and QA artifact generation passed. |
| `scripts/generate-qa-evidence.sh --output <tmpdir>` | pass | Generated `07-UAT.generated.md` with all state rows and `pending-human-verification`. |
| `./scripts/compile-and-run.sh --qa-state healthy` | pass | App path: `DerivedData/Build/Products/Debug/Kubebar.app`; PID: `13624`; running: yes; QA state: healthy. |

## Issue #7 State Evidence

| State | Status | Reproduction steps | Expected behavior | Observed behavior | Evidence path | Limitations | Follow-up risk |
|-------|--------|--------------------|-------------------|-------------------|---------------|-------------|----------------|
| Healthy | pending-human-verification | `./scripts/compile-and-run.sh --qa-state healthy` | Menu shows OK with healthy counters and watched namespaces. | App starts in healthy QA state; menu screenshot not captured. | `docs/assets/qa/phase-07-healthy.png` | Visible menu check still requires human confirmation. | Do not mark complete without screenshot or equivalent visible evidence. |
| Watch | pending-human-verification | `./scripts/compile-and-run.sh --qa-state watch` | Menu shows Watch with warning context and non-healthy attention. | pending-human-verification | `docs/assets/qa/phase-07-watch.png` | Visible menu check still requires human confirmation. | Watch copy could drift without visual evidence. |
| Bad | pending-human-verification | `./scripts/compile-and-run.sh --qa-state bad` | Menu shows Bad and prioritizes the broken watched target. | pending-human-verification | `docs/assets/qa/phase-07-bad.png` | Visible menu check still requires human confirmation. | Bad state could be missed if only model tests are trusted. |
| Stale refresh failure | pending-human-verification | `./scripts/compile-and-run.sh --qa-state stale-refresh-failure` | Menu shows Stale while preserving last known status. | pending-human-verification | `docs/assets/qa/phase-07-stale-refresh-failure.png` | Visible menu check still requires human confirmation. | Stale data must not look current. |
| Stale age-out | pending-human-verification | `./scripts/compile-and-run.sh --qa-state stale-age-out` | Menu shows Stale because the last successful refresh is too old. | pending-human-verification | `docs/assets/qa/phase-07-stale-age-out.png` | Visible menu check still requires human confirmation. | Old data must not look healthy. |
| first-use | pending-human-verification | `./scripts/compile-and-run.sh --qa-state first-use` | Menu shows setup before any saved context exists. | pending-human-verification | `docs/assets/qa/phase-07-first-use.png` | Visible menu check still requires human confirmation. | First-use could be confused with empty watchlist without visual proof. |
| empty-watchlist | pending-human-verification | `./scripts/compile-and-run.sh --qa-state empty-watchlist` | Menu shows setup because the QA fixture context has no selected namespaces. | pending-human-verification | `docs/assets/qa/phase-07-empty-watchlist.png` | Visible menu check still requires human confirmation. | Empty watchlist must not be interpreted as healthy. |
| kubectl failure | pending-human-verification | `./scripts/compile-and-run.sh --qa-state kubectl-failure` | Menu shows Stale with a safe failure message and retained prior status. | pending-human-verification | `docs/assets/qa/phase-07-kubectl-failure.png` | Visible menu check still requires human confirmation. | Failure details must stay safe and not expose sensitive data. |

## Scope Guards

| Guard | Status | Notes |
|-------|--------|-------|
| No packaging | pass | Phase 07 does not add distribution packaging. |
| No signing | pass | Phase 07 does not change signing behavior. |
| No notarization | pass | Phase 07 does not add notarization. |
| No k9s | pass | No `Open in k9s` flow added. |
| No dashboard | pass | QA remains menu-bar focused. |
| No broad menu automation | pass | Generator is non-GUI and deterministic. |
| No real-cluster mutation | pass | Fixtures are app-owned data and do not call cluster mutation paths. |
| No command transcript | pass | Evidence records short outcomes only. |

## Human Needed

Screenshots or equivalent visible-menu observations are still required for each state row before changing the phase status away from `pending-human-verification`.
